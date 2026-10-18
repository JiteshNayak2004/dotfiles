#!/usr/bin/env python3
"""Local daily checklists and desktop reminders. Markdown is the task store."""

import argparse
from contextlib import contextmanager
from dataclasses import dataclass, replace
from datetime import datetime, time, timedelta, timezone
import fcntl
import html
import json
import os
from pathlib import Path
import re
import shlex
import subprocess
import sys
import tempfile
import threading
import time as clock

from tzlocal import get_localzone


ROW = re.compile(r"^\s*(?:(\d+)\.\s*|-\s*)?\[([ xX])\]\s+(.+?)\s*$")
STAMP = re.compile(r"^(.*?) — (\d{4}-\d{2}-\d{2} \d{2}:\d{2}(?::\d{2})?(?:[+-]\d{2}:\d{2})?)$")
CLOCK = r"(?:[01]\d|2[0-3]):[0-5]\d"
DURATION_PART = r"(\d+)\s*(seconds?|secs?|s|minutes?|mins?|m|hours?|hrs?|h)"
TIME_HELP = "Use @300s, @10m, @2h, @1d [HH:MM], or @DD-MM-YY [HH:MM] (for example @05-11-26 14:30)."


def now_local():
    return datetime.now(get_localzone()).replace(microsecond=0)


def parse_reminder(phrase, now):
    phrase = phrase.strip().lower()
    try:
        day_match = re.fullmatch(rf"(\d+)\s*(?:days?|d)(?:\s+({CLOCK}))?", phrase)
        date_match = re.fullmatch(rf"(\d{{2}})-(\d{{2}})-(\d{{2}})(?:\s+({CLOCK}))?", phrase)
        compact_match = re.fullmatch(rf"(\d{{2}})(\d{{2}})(\d{{2}})(?:\s+({CLOCK}))?", phrase)
        if day_match or date_match or compact_match:
            if day_match:
                target = now.date() + timedelta(days=int(day_match[1]))
                clock = day_match[2]
            else:
                match = date_match or compact_match
                target = datetime(2000 + int(match[3]), int(match[2]), int(match[1])).date()
                clock = match[4]
            hour, minute = map(int, clock.split(':')) if clock else (9, 0)
            due = datetime.combine(target, time(hour, minute), now.tzinfo)
            # Reject ambiguous/nonexistent local times around daylight-saving changes.
            back = due.astimezone(timezone.utc).astimezone(now.tzinfo)
            if back.replace(tzinfo=None) != due.replace(tzinfo=None) or due.utcoffset() != due.replace(fold=1).utcoffset():
                raise ValueError("That local time is ambiguous or does not exist. Choose another time.")
        elif re.fullmatch(rf"(?:{DURATION_PART}\s*)+", phrase):
            seconds = sum(int(count) * {'s': 1, 'm': 60, 'h': 3600}[unit[0]] for count, unit in re.findall(DURATION_PART, phrase))
            due = (now.astimezone(timezone.utc) + timedelta(seconds=seconds)).astimezone(now.tzinfo)
        else:
            raise ValueError(TIME_HELP)
        if due.timestamp() <= now.timestamp():
            raise ValueError("Reminder time must be in the future. " + TIME_HELP)
        return due
    except (OverflowError, ValueError) as exc:
        if isinstance(exc, OverflowError):
            raise ValueError("Reminder time is out of range. " + TIME_HELP) from exc
        raise ValueError(str(exc) + ('' if 'Use @' in str(exc) else ' ' + TIME_HELP)) from exc


def parse_sentence(sentence, now):
    sentence = sentence.strip()
    if len(sentence) >= 2 and sentence[0] == sentence[-1] and sentence[0] in ('"', "'"):
        sentence = sentence[1:-1].strip()
    if not sentence or "\n" in sentence or "\r" in sentence:
        raise ValueError("Write a nonempty task on one line.")
    markers = list(re.finditer(r"(?<!\S)@", sentence))
    if not markers:
        return sentence, None
    if len(markers) != 1:
        raise ValueError("Use one @ time marker after the task title. " + TIME_HELP)
    marker = markers[0]
    title = sentence[:marker.start()].strip()
    if not title:
        raise ValueError("Write a task title before @. " + TIME_HELP)
    return title, parse_reminder(sentence[marker.end():], now)


@dataclass
class Task:
    id: int
    title: str
    due: datetime | None
    done: bool
    day: str

    @property
    def reminder(self):
        return self.due.isoformat() if self.due else None

    def line(self):
        when = f" — {self.due.isoformat(sep=' ', timespec='seconds')}" if self.due else ""
        return f"{self.id}. [{'x' if self.done else ' '}] {self.title}{when}"


def atomic_write(path, text):
    fd, name = tempfile.mkstemp(prefix=".tasks-", dir=path.parent)
    try:
        with os.fdopen(fd, "w") as stream:
            stream.write(text)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(name, path)
    finally:
        if os.path.exists(name):
            os.unlink(name)


class Store:
    def __init__(self, root):
        self.root = Path(root)

    @contextmanager
    def locked(self):
        self.root.mkdir(parents=True, exist_ok=True, mode=0o700)
        with (self.root / ".lock").open("a") as lock:
            fcntl.flock(lock, fcntl.LOCK_EX)
            yield

    def read(self, now):
        state_path = self.root / ".state.json"
        state = json.loads(state_path.read_text()) if state_path.exists() else {"next_id": 1, "notified": {}}
        if not isinstance(state.get("next_id"), int) or not isinstance(state.get("notified"), dict):
            raise ValueError("Invalid .state.json; restore it from backup before continuing.")
        originals, extras, entries = {}, {}, []
        for path in sorted(self.root.glob("????-??-??.md")):
            datetime.strptime(path.stem, "%Y-%m-%d")
            if path.is_symlink():
                raise ValueError(f"Task files must be regular files: {path}")
            text = path.read_text()
            originals[path.stem] = text
            extras[path.stem] = []
            for number, line in enumerate(text.splitlines(), 1):
                match = ROW.match(line)
                if not match:
                    if re.match(r"^\s*(?:\d+\.\s*|-\s*)?\[", line):
                        raise ValueError(f"{path.name}:{number}: use '[ ] title' or '[x] title'.")
                    extras[path.stem].append(line)
                    continue
                ident, check, content = match.groups()
                try:
                    stamp = STAMP.match(content)
                    if stamp:
                        title = stamp[1].strip()
                        due = datetime.fromisoformat(stamp[2])
                        due = due.astimezone(now.tzinfo) if due.tzinfo else due.replace(tzinfo=now.tzinfo)
                    elif " — " in content:
                        title, phrase = content.rsplit(" — ", 1)
                        due = parse_reminder(phrase.removeprefix('@'), now)
                    else:
                        title, due = parse_sentence(content, now)
                except ValueError as exc:
                    raise ValueError(f"{path.name}:{number}: {exc}") from exc
                done = check.lower() == "x"
                day = path.stem if done else max(now.date().isoformat(), due.date().isoformat() if due else path.stem)
                entries.append(Task(int(ident) if ident else 0, title, due, done, day))
        next_id = max([state['next_id'], *(t.id + 1 for t in entries)])
        tasks, seen = [], {}
        for task in entries:
            if not task.id:
                task.id, next_id = next_id, next_id + 1
            if task.id in seen:
                # A crash during rollover can leave identical copies in two daily files.
                if task == seen[task.id]:
                    continue
                raise ValueError(f"Duplicate task number {task.id}. Remove the number from the new line; keep '[ ] title'.")
            seen[task.id] = task
            tasks.append(task)
        state['next_id'] = next_id
        state['notified'] = {key: value for key, value in state['notified'].items() if int(key) in seen}
        return tasks, originals, extras, state

    def write(self, tasks, originals, extras, state, now):
        days = set(originals) | {t.day for t in tasks} | {now.date().isoformat()}
        changes = {}
        for day in days:
            prefix = "\n".join(extras.get(day, [f"# Tasks — {day}"])).rstrip()
            rows = "\n".join(t.line() for t in tasks if t.day == day)
            text = prefix + ("\n\n" if prefix and rows else "") + rows + "\n"
            if text != originals.get(day):
                changes[day] = text
        # Do not overwrite a file edited externally while this transaction was reading it.
        for day in days:
            path = self.root / f"{day}.md"
            current = path.read_text() if path.exists() else None
            if current != originals.get(day):
                raise ValueError(f"{path.name} changed during sync; retry after saving your edits.")
        # Write destinations before removing yesterday's copy; identical copies recover on restart.
        for day in sorted(changes, reverse=True):
            atomic_write(self.root / f"{day}.md", changes[day])
        state_path = self.root / ".state.json"
        text = json.dumps(state, indent=2, sort_keys=True) + "\n"
        if not state_path.exists() or state_path.read_text() != text:
            atomic_write(state_path, text)

    def sync(self, now):
        with self.locked():
            tasks, originals, extras, state = self.read(now)
            self.write(tasks, originals, extras, state, now)
            return tasks

    def add(self, sentence, now):
        title, due = parse_sentence(sentence, now)
        with self.locked():
            tasks, originals, extras, state = self.read(now)
            day = max(now.date().isoformat(), due.date().isoformat()) if due else now.date().isoformat()
            task = Task(state['next_id'], title, due, False, day)
            state['next_id'] += 1
            tasks.append(task)
            self.write(tasks, originals, extras, state, now)
            return task

    def due(self, now):
        with self.locked():
            tasks, originals, extras, state = self.read(now)
            self.write(tasks, originals, extras, state, now)
            return [t for t in tasks if not t.done and t.due and t.due.timestamp() <= now.timestamp() and state['notified'].get(str(t.id)) != t.reminder]

    def upcoming(self, now):
        with self.locked():
            tasks, originals, extras, state = self.read(now)
            self.write(tasks, originals, extras, state, now)
            today = now.date()
            end = (today + timedelta(days=7)).isoformat()
            groups = {}
            for task in sorted(tasks, key=lambda t: (t.due.timestamp() if t.due else float('inf'), t.id)):
                if task.done or task.day > end:
                    continue
                overdue = task.due is not None and task.due.timestamp() <= now.timestamp()
                key = 'overdue' if overdue else task.day
                when = task.due.strftime('%H:%M') if task.due else 'No reminder'
                if overdue:
                    day = task.due.date()
                    prefix = 'Today' if day == today else 'Yesterday' if day == today - timedelta(days=1) else task.due.strftime('%d %b %Y')
                    when = f'{prefix} {when}'
                groups.setdefault(key, []).append({
                    'id': task.id, 'title': task.title, 'time': when,
                    'path': str(self.root / f'{task.day}.md'),
                })
            result = []
            for key in sorted(groups, key=lambda key: (key != 'overdue', key)):
                if key == 'overdue':
                    label = 'Overdue'
                else:
                    date = datetime.strptime(key, '%Y-%m-%d').date()
                    prefix = 'Today · ' if date == today else 'Tomorrow · ' if date == today + timedelta(days=1) else ''
                    label = prefix + date.strftime('%a %d %b')
                result.append({'key': key, 'label': label, 'tasks': groups[key]})
            return {'groups': result}

    def action(self, ident, reminder, action, now):
        if action not in ("done", "snooze", "dismiss"):
            raise ValueError("Unknown notification action.")
        with self.locked():
            tasks, originals, extras, state = self.read(now)
            for i, task in enumerate(tasks):
                if task.id != ident or task.done or task.reminder != reminder:
                    continue  # Ignore stale notifications after an edit, completion, or deletion.
                if action == "done":
                    tasks[i] = replace(task, done=True)
                elif action == "snooze":
                    due = (now.astimezone(timezone.utc) + timedelta(minutes=15)).astimezone(now.tzinfo)
                    tasks[i] = replace(task, due=due, day=due.date().isoformat())
                state['notified'][str(ident)] = reminder
                break
            self.write(tasks, originals, extras, state, now)


def send_notification(task):
    result = subprocess.run([
        "notify-send", "--app-name=Tasks", "--urgency=critical", "--expire-time=0",
        "--action=done=Done", "--action=snooze=Snooze 15 min", "--action=dismiss=Dismiss",
        "--", html.escape(task.title), f"Due {task.due.strftime('%a %d %b, %H:%M')}",
    ], text=True, capture_output=True)
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or "Desktop notification failed.")
    action = result.stdout.strip() or "dismiss"
    if action not in ("done", "snooze", "dismiss"):
        raise RuntimeError(f"Unexpected notification response: {action!r}")
    return action


def daemon(store):
    store.root.mkdir(parents=True, exist_ok=True, mode=0o700)
    with (store.root / ".daemon.lock").open("a") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            raise ValueError("The task reminder service is already running.")
        active, retry_after = {}, {}

        def remind(task):
            try:
                action = send_notification(task)
                store.action(task.id, task.reminder, action, now_local())
            except Exception as exc:
                print(f"task: {exc}", file=sys.stderr, flush=True)
                retry_after[(task.id, task.reminder)] = clock.monotonic() + 60

        while True:
            try:
                for task in store.due(now_local()):
                    key = (task.id, task.reminder)
                    if key in active and active[key].is_alive():
                        continue
                    if retry_after.get(key, 0) > clock.monotonic():
                        continue
                    thread = threading.Thread(target=remind, args=(task,), daemon=True)
                    active[key] = thread
                    thread.start()
                active = {key: thread for key, thread in active.items() if thread.is_alive()}
            except Exception as exc:
                print(f"task: {exc}", file=sys.stderr, flush=True)
            clock.sleep(5)


def main():
    parser = argparse.ArgumentParser(description="Daily local tasks. Example: task 'check simulation @10m'")
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--path", action="store_true", help="Print today's checklist path")
    mode.add_argument("--sync", action="store_true", help="Apply saved checklist edits and roll unfinished tasks forward")
    mode.add_argument("--daemon", action="store_true", help="Run the background reminder service")
    mode.add_argument("--upcoming", action="store_true", help="Print unfinished tasks through the next seven days as JSON")
    parser.add_argument("sentence", nargs="*", help="Task title, optionally followed by @time")
    args = parser.parse_args()
    if args.sentence and (args.path or args.sync or args.daemon or args.upcoming):
        parser.error("Do not combine a task sentence with a service option.")
    root = Path(os.environ.get("TASKS_DIR", Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share")) / "tasks"))
    store, now = Store(root.expanduser().resolve()), now_local()
    try:
        if args.daemon:
            daemon(store)
        elif args.upcoming:
            print(json.dumps(store.upcoming(now)))
        elif args.sentence:
            task = store.add(" ".join(args.sentence), now)
            print(f"Added #{task.id}: {task.title}")
            print(f"Reminder: {task.due.strftime('%a %d %b %Y, %H:%M:%S %Z')}" if task.due else "No reminder.")
        else:
            store.sync(now)
            path = store.root / f"{now.date().isoformat()}.md"
            if args.path:
                print(path)
            elif not args.sync:
                return subprocess.call(shlex.split(os.environ.get("VISUAL") or os.environ.get("EDITOR") or "nvim") + [str(path)])
    except (ValueError, OSError, RuntimeError) as exc:
        print(f"task: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
