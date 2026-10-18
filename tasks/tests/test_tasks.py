import importlib.util
import json
import os
import shutil
import subprocess
import tempfile
import time
import unittest
from datetime import datetime, timedelta
from pathlib import Path
from zoneinfo import ZoneInfo


SPEC = importlib.util.spec_from_file_location("tasktool", Path(__file__).parents[1] / "tasks.py")
tool = importlib.util.module_from_spec(SPEC)
import sys
sys.modules[SPEC.name] = tool
SPEC.loader.exec_module(tool)

NOW = datetime(2026, 10, 18, 14, 20, 30, tzinfo=ZoneInfo("Asia/Kolkata"))


class ParsingTests(unittest.TestCase):
    def test_elapsed_durations(self):
        for phrase, seconds in [('300s', 300), ('300 seconds', 300), ('10m', 600), ('10 minutes', 600), ('2h', 7200), ('2 hours', 7200), ('1h30m', 5400)]:
            with self.subTest(phrase=phrase):
                title, due = tool.parse_sentence('check tomorrow in simulator @' + phrase, NOW)
                self.assertEqual(title, 'check tomorrow in simulator')
                self.assertEqual(due, NOW + timedelta(seconds=seconds))

    def test_calendar_day_offsets(self):
        for phrase, expected in [
            ('1d', NOW.replace(day=19, hour=9, minute=0, second=0)),
            ('2d', NOW.replace(day=20, hour=9, minute=0, second=0)),
            ('1d 14:30', NOW.replace(day=19, hour=14, minute=30, second=0)),
            ('0d 18:00', NOW.replace(hour=18, minute=0, second=0)),
            ('24h', NOW + timedelta(hours=24)),
        ]:
            with self.subTest(phrase=phrase):
                _, due = tool.parse_sentence('review @' + phrase, NOW)
                self.assertEqual(due, expected)

    def test_dates_are_day_month_year(self):
        for phrase, expected in [
            ('05-11-26', NOW.replace(month=11, day=5, hour=9, minute=0, second=0)),
            ('051126', NOW.replace(month=11, day=5, hour=9, minute=0, second=0)),
            ('05-11-26 14:30', NOW.replace(month=11, day=5, hour=14, minute=30, second=0)),
            ('051126 14:30', NOW.replace(month=11, day=5, hour=14, minute=30, second=0)),
            ('11-05-27', NOW.replace(year=2027, month=5, day=11, hour=9, minute=0, second=0)),
            ('31-12-99', NOW.replace(year=2099, month=12, day=31, hour=9, minute=0, second=0)),
        ]:
            with self.subTest(phrase=phrase):
                title, due = tool.parse_sentence('review @' + phrase, NOW)
                self.assertEqual(title, 'review')
                self.assertEqual(due, expected)

    def test_invalid_marker_never_becomes_unscheduled(self):
        for text in ['review @', 'review @banana', 'review @tomorrow', 'review @0s', 'review @-5m', 'review @11/05', 'review @November', 'review @31-04-27', 'review @29-02-26', 'review @1d 25:00', 'review @1d 09:60', 'review @1d 9:00', 'review @1d 10am', 'review @10m @2h', '@10m']:
            with self.subTest(text=text), self.assertRaises(ValueError):
                tool.parse_sentence(text, NOW)

    def test_past_or_current_selected_time_is_rejected(self):
        for phrase in ['0d', '0d 10:00', '17-10-26 18:00', '18-10-26 14:20']:
            with self.subTest(phrase=phrase), self.assertRaises(ValueError):
                tool.parse_sentence('review @' + phrase, NOW)
        _, due = tool.parse_sentence('review @0d', NOW.replace(hour=8))
        self.assertEqual(due, NOW.replace(hour=9, minute=0, second=0))

    def test_without_marker_title_is_literal(self):
        for title in ['read AXI', 'check tomorrow', 'check in 10 minutes', 'email alice@example.com', 'read the docs!']:
            self.assertEqual(tool.parse_sentence(title, NOW), (title, None))
        title, due = tool.parse_sentence('email alice@example.com @300s', NOW)
        self.assertEqual(title, 'email alice@example.com')
        self.assertEqual(due, NOW + timedelta(seconds=300))

    def test_elapsed_hours_across_daylight_saving_transition(self):
        now = datetime(2026, 3, 28, 12, tzinfo=ZoneInfo('Europe/Berlin'))
        _, due = tool.parse_sentence('review @24h', now)
        self.assertEqual(due.timestamp() - now.timestamp(), 86400)
        self.assertEqual(due.hour, 13)
        _, day_due = tool.parse_sentence('review @1d', now)
        self.assertEqual(day_due.hour, 9)

    def test_elapsed_time_during_repeated_clock_hour(self):
        now = datetime(2026, 10, 25, 2, 45, tzinfo=ZoneInfo('Europe/Berlin'))
        _, due = tool.parse_sentence('review @30m', now)
        self.assertEqual(due.timestamp() - now.timestamp(), 1800)

    def test_ambiguous_or_nonexistent_calendar_time_is_rejected(self):
        for now, phrase in [
            (datetime(2026, 3, 28, 12, tzinfo=ZoneInfo('Europe/Berlin')), '29-03-26 02:30'),
            (datetime(2026, 10, 24, 12, tzinfo=ZoneInfo('Europe/Berlin')), '25-10-26 02:30'),
        ]:
            with self.subTest(phrase=phrase), self.assertRaises(ValueError):
                tool.parse_sentence('review @' + phrase, now)

    def test_empty_and_multiline_titles_rejected(self):
        for title in ['', '  ', 'hello\nworld', "''", '""']:
            with self.assertRaises(ValueError):
                tool.parse_sentence(title, NOW)


class StoreTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name) / "tasks"
        self.store = tool.Store(self.root)

    def tearDown(self):
        self.temp.cleanup()

    def test_add_routes_to_due_day_and_undated_goes_to_today(self):
        a = self.store.add("check @1d", NOW)
        b = self.store.add("read AXI", NOW)
        self.assertIn("check", (self.root / "2026-10-19.md").read_text())
        self.assertIn("read AXI", (self.root / "2026-10-18.md").read_text())
        self.assertNotEqual(a.id, b.id)
        self.assertIsNone(b.due)

    def test_invalid_input_saves_nothing(self):
        with self.assertRaises(ValueError):
            self.store.add('review @0d', NOW)
        self.assertFalse(self.root.exists())

    def test_existing_timestamp_without_offset_still_delivers(self):
        self.root.mkdir()
        (self.root / '2026-10-18.md').write_text('1. [ ] existing reminder — 2026-10-18 13:00:00\n')
        rows = self.store.due(NOW)
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0].due, NOW.replace(hour=13, minute=0, second=0))

    def test_manual_lines_normalize_once_and_preserve_notes(self):
        self.root.mkdir()
        p = self.root / "2026-10-18.md"
        p.write_text("# My tasks\n\nSome notes.\n- [ ] check @15m\n[ ] read AXI\n")
        rows = self.store.sync(NOW)
        self.assertEqual(len(rows), 2)
        self.assertEqual(rows[0].due, NOW + timedelta(minutes=15))
        before = p.read_text()
        self.store.sync(NOW + timedelta(minutes=2))
        self.assertEqual(p.read_text(), before)
        self.assertIn("Some notes.", before)

    def test_rollover_moves_unfinished_and_keeps_completed_history(self):
        a = self.store.add("unfinished @1m", NOW)
        b = self.store.add("finished", NOW)
        p = self.root / "2026-10-18.md"
        p.write_text(p.read_text().replace(f"{b.id}. [ ]", f"{b.id}. [x]"))
        self.store.sync(NOW + timedelta(days=3))
        self.assertNotIn("unfinished", p.read_text())
        self.assertIn("finished", p.read_text())
        today = (self.root / "2026-10-21.md").read_text()
        self.assertIn("unfinished", today)
        self.assertEqual(today.count(f"{a.id}. [ ]"), 1)

    def test_dismiss_survives_restart_and_rollover(self):
        a = self.store.add("check @1m", NOW)
        later = NOW + timedelta(minutes=2)
        self.assertEqual(len(self.store.due(later)), 1)
        self.store.action(a.id, a.due.isoformat(), "dismiss", later)
        restarted = tool.Store(self.root)
        self.assertEqual(restarted.due(later + timedelta(days=1)), [])

    def test_snooze_is_fifteen_minutes_from_click(self):
        a = self.store.add("check @1m", NOW)
        click = NOW + timedelta(minutes=10)
        self.store.action(a.id, a.due.isoformat(), "snooze", click)
        rows = self.store.sync(click)
        self.assertEqual(rows[0].due, click + timedelta(minutes=15))
        self.assertEqual(self.store.due(click + timedelta(minutes=14)), [])
        self.assertEqual(len(self.store.due(click + timedelta(minutes=15))), 1)

    def test_elapsed_reminder_survives_repeated_hour_in_file(self):
        now = datetime(2026, 10, 25, 2, 45, tzinfo=ZoneInfo('Europe/Berlin'))
        self.store.add('check @30m', now)
        self.assertEqual(self.store.due(now), [])
        later = datetime.fromtimestamp(now.timestamp() + 1800, now.tzinfo)
        tasks = self.store.due(later)
        self.assertEqual(len(tasks), 1)
        self.assertEqual(tasks[0].due.timestamp(), later.timestamp())

    def test_done_button_updates_checkbox_and_cancels_reminder(self):
        a = self.store.add("check @1m", NOW)
        self.store.action(a.id, a.due.isoformat(), "done", NOW + timedelta(minutes=2))
        self.assertIn(f"{a.id}. [x]", (self.root / "2026-10-18.md").read_text())
        self.assertEqual(self.store.due(NOW + timedelta(hours=1)), [])

    def test_direct_checkbox_edit_cancels_notification(self):
        a = self.store.add("check @1m", NOW)
        p = self.root / "2026-10-18.md"
        p.write_text(p.read_text().replace("[ ]", "[x]"))
        self.assertEqual(self.store.due(NOW + timedelta(minutes=2)), [])
        self.store.action(a.id, a.due.isoformat(), "snooze", NOW + timedelta(minutes=3))
        self.assertTrue(self.store.sync(NOW)[0].done)

    def test_rescheduling_reenables_dismissed_task(self):
        a = self.store.add("check @1m", NOW)
        self.store.action(a.id, a.due.isoformat(), "dismiss", NOW)
        p = self.root / "2026-10-18.md"
        p.write_text(p.read_text().replace("2026-10-18 14:21:30", "2026-10-18 16:00:00"))
        self.assertEqual(len(self.store.due(NOW.replace(hour=17))), 1)

    def test_reminder_can_be_edited_to_a_relative_phrase(self):
        self.store.add("check @1m", NOW)
        p = self.root / "2026-10-18.md"
        p.write_text(p.read_text().replace("2026-10-18 14:21:30+05:30", "1d 10:00"))
        task = self.store.sync(NOW)[0]
        self.assertEqual(task.title, "check")
        self.assertEqual(task.due, NOW.replace(day=19, hour=10, minute=0, second=0))

    def test_invalid_canonical_time_does_not_remove_reminder(self):
        self.store.add("check @1m", NOW)
        p = self.root / "2026-10-18.md"
        p.write_text(p.read_text().replace("14:21:30", "25:21:30"))
        with self.assertRaises(ValueError):
            self.store.sync(NOW)

    def test_stale_notification_cannot_override_reschedule(self):
        a = self.store.add("check @1m", NOW)
        p = self.root / "2026-10-18.md"
        p.write_text(p.read_text().replace("2026-10-18 14:21:30", "2026-10-18 16:00:00"))
        self.store.action(a.id, a.due.isoformat(), "done", NOW)
        self.assertFalse(self.store.sync(NOW)[0].done)

    def test_duplicate_ids_fail_without_rewriting_files(self):
        self.root.mkdir()
        p = self.root / "2026-10-18.md"
        text = "1. [ ] first\n1. [ ] second\n"
        p.write_text(text)
        with self.assertRaises(ValueError):
            self.store.sync(NOW)
        self.assertEqual(p.read_text(), text)

    def test_bad_time_in_file_does_not_rewrite_any_files(self):
        self.root.mkdir()
        p = self.root / "2026-10-18.md"
        text = "- [ ] check @1d 25:00\n"
        p.write_text(text)
        with self.assertRaises(ValueError):
            self.store.sync(NOW)
        self.assertEqual(p.read_text(), text)

    def test_each_missed_reminder_is_returned_individually(self):
        for title in ["one @1m", "two @2m", "three @3m"]:
            self.store.add(title, NOW)
        self.assertEqual(len(self.store.due(NOW + timedelta(days=1))), 3)

    def test_deleting_task_cancels_pending_reminder(self):
        self.store.add("check @1m", NOW)
        (self.root / "2026-10-18.md").write_text("# Tasks\n")
        self.assertEqual(self.store.due(NOW + timedelta(minutes=2)), [])

    def test_upcoming_groups_overdue_today_and_future_without_completed(self):
        overdue = self.store.add('overdue @1m', NOW - timedelta(days=1))
        today = self.store.add('today unscheduled', NOW)
        future = self.store.add('future @1d 10:00', NOW)
        done = self.store.add('finished', NOW)
        path = self.root / '2026-10-18.md'
        path.write_text(path.read_text().replace(f'{done.id}. [ ]', f'{done.id}. [x]'))
        agenda = self.store.upcoming(NOW)
        self.assertEqual([g['key'] for g in agenda['groups']], ['overdue', '2026-10-18', '2026-10-19'])
        items = [item for group in agenda['groups'] for item in group['tasks']]
        self.assertEqual([item['id'] for item in items], [overdue.id, today.id, future.id])
        for item in items:
            self.assertIn(f"{item['id']}. [ ]", Path(item['path']).read_text())
        self.assertEqual(agenda['groups'][1]['tasks'][0]['time'], 'No reminder')

    def test_upcoming_has_seven_future_days_and_sorts_by_time(self):
        self.store.add('later @0d 18:00', NOW)
        self.store.add('earlier @0d 15:00', NOW)
        self.store.add('no time', NOW)
        edge = self.store.add('day seven @7d', NOW)
        outside = self.store.add('day eight @8d', NOW)
        agenda = self.store.upcoming(NOW)
        self.assertEqual([item['title'] for item in agenda['groups'][0]['tasks']], ['earlier', 'later', 'no time'])
        ids = [item['id'] for group in agenda['groups'] for item in group['tasks']]
        self.assertIn(edge.id, ids)
        self.assertNotIn(outside.id, ids)

    def test_upcoming_empty_store_has_no_groups_or_extra_agenda_file(self):
        self.assertEqual(self.store.upcoming(NOW)['groups'], [])
        self.assertEqual([p.name for p in self.root.glob('*.md')], ['2026-10-18.md'])

    def test_upcoming_same_day_past_time_is_overdue(self):
        self.store.add('past today @1m', NOW - timedelta(hours=1))
        agenda = self.store.upcoming(NOW)
        self.assertEqual(agenda['groups'][0]['key'], 'overdue')


class IntegrationTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name) / "tasks"
        self.env = dict(os.environ, TASKS_DIR=str(self.root))
        self.command = [sys.executable, str(Path(tool.__file__))]

    def tearDown(self):
        self.temp.cleanup()

    def test_cli_add_and_path_share_the_same_store(self):
        result = subprocess.run(self.command + ["review @1d 10:00"], env=self.env, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("review", result.stdout)
        result = subprocess.run(self.command + ["--path"], env=self.env, text=True, capture_output=True, check=True)
        self.assertEqual(Path(result.stdout.strip()).parent, self.root)
        self.assertEqual(len(tool.Store(self.root).sync(tool.now_local())), 1)

    def test_cli_upcoming_returns_source_paths_and_ids(self):
        task = tool.Store(self.root).add('agenda item @1d', tool.now_local())
        result = subprocess.run(self.command + ['--upcoming'], env=self.env, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        agenda = json.loads(result.stdout)
        item = agenda['groups'][0]['tasks'][0]
        self.assertEqual(item['id'], task.id)
        self.assertIn('agenda item', Path(item['path']).read_text())

    def test_concurrent_adds_do_not_lose_tasks_or_reuse_numbers(self):
        jobs = [subprocess.Popen(self.command + [f"work item {i}"], env=self.env, stdout=subprocess.PIPE, stderr=subprocess.PIPE) for i in range(6)]
        for job in jobs:
            out, err = job.communicate(timeout=15)
            self.assertEqual(job.returncode, 0, err)
        rows = tool.Store(self.root).sync(tool.now_local())
        self.assertEqual(len(rows), 6)
        self.assertEqual(len({t.id for t in rows}), 6)

    @unittest.skipUnless(shutil.which('nvim') and (Path.home() / '.local/bin/task').is_file(), 'Install the task command and Neovim for editor integration tests')
    def test_nvim_capture_and_file_edits(self):
        self.root.mkdir()
        repo = str(Path(tool.__file__).parents[1])
        env = dict(self.env, TASKS_REPO=repo)
        result = subprocess.run(['nvim', '--headless', '-u', 'NONE', '-i', 'NONE', '-c', "lua dofile(vim.env.TASKS_REPO .. '/tasks/tests/nvim.lua')"], env=env, text=True, capture_output=True, timeout=30)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('PASS:', result.stdout + result.stderr)

    @unittest.skipUnless(shutil.which('nvim') and (Path.home() / '.local/bin/task').is_file(), 'Install the task command and Neovim for editor integration tests')
    def test_nvim_status_view_and_source_navigation(self):
        self.root.mkdir()
        env = dict(self.env, TASKS_REPO=str(Path(tool.__file__).parents[1]))
        result = subprocess.run(['nvim', '--headless', '-u', 'NONE', '-i', 'NONE', '-c', "lua dofile(vim.env.TASKS_REPO .. '/tasks/tests/status.lua')"], env=env, text=True, capture_output=True, timeout=30)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('PASS:', result.stdout + result.stderr)

    def test_daemon_delivers_each_notification_and_applies_actions(self):
        fake_bin = Path(self.temp.name) / "bin"
        fake_bin.mkdir()
        log = Path(self.temp.name) / "notifications.log"
        executable = fake_bin / "notify-send"
        executable.write_text(f'''#!{sys.executable}
import json, os, sys
with open(os.environ['TASK_TEST_LOG'], 'a') as f:
    f.write(json.dumps(sys.argv[1:]) + '\\n')
title = sys.argv[-2]
print('done' if title.startswith('complete') else 'snooze' if title.startswith('delay') else 'dismiss')
''')
        executable.chmod(0o700)
        env = dict(self.env, PATH=str(fake_bin) + os.pathsep + os.environ['PATH'], TASK_TEST_LOG=str(log))
        store, now = tool.Store(self.root), tool.now_local()
        for title in ["complete", "delay", "ignore"]:
            store.add(title + " @1s", now - timedelta(minutes=1))
        daemon = subprocess.Popen(self.command + ["--daemon"], env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        try:
            deadline = time.monotonic() + 12
            while time.monotonic() < deadline:
                state_path = self.root / ".state.json"
                if state_path.exists() and len(json.loads(state_path.read_text())['notified']) == 3:
                    break
                self.assertIsNone(daemon.poll(), 'Daemon unexpectedly exited')
                time.sleep(0.05)
            else:
                self.fail('Notification actions were not applied')
            tasks = {t.title: t for t in store.sync(tool.now_local())}
            self.assertTrue(tasks['complete'].done)
            self.assertFalse(tasks['ignore'].done)
            seconds = (tasks['delay'].due - tool.now_local()).total_seconds()
            self.assertGreater(seconds, 880)
            self.assertLessEqual(seconds, 900)
            self.assertEqual(store.due(tool.now_local()), [])
            calls = [json.loads(line) for line in log.read_text().splitlines()]
            self.assertEqual(len(calls), 3)
            for call in calls:
                self.assertIn('--action=done=Done', call)
                self.assertIn('--action=snooze=Snooze 15 min', call)
                self.assertIn('--action=dismiss=Dismiss', call)
        finally:
            daemon.terminate()
            daemon.communicate(timeout=5)


if __name__ == "__main__":
    unittest.main()
