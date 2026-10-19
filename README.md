# dotfiles
collection of all my dotfiles to replicate setup 

gnome extensions i use actively
1. arcmenu
2. focus changer
3. improved workspace indicator
4. no overview at startup
5. remove alt+tab delay v2
6. awesome tiles
7. auto move windows
8. focus
9. go to last workspace
10. switcher
11. wintile


## Live configuration links

The active configs on this machine are symlinked to these repository files:

| Active path | Repository file |
| --- | --- |
| `~/.zshrc` | `backup_zshrc` |
| `~/.tmux.conf` | `.tmux.conf` |
| `~/.config/kitty/kitty.conf` | `kitty/kitty.conf` |
| `~/.config/nvim/init.lua` | `nvim/init.lua` |
| `~/.config/nvim/lua/lsp.lua` | `nvim/lua/lsp.lua` |
| `~/.config/nvim/plugin` | `nvim/plugin` |
| `~/.config/rofi/config.rasi` | `rofi/config.rasi` |
| `~/.config/rofi/powermenu.sh` | `rofi/powermenu.sh` |
| `~/.config/Code/User/keybindings.json` | `code_keybinds.json` |

Edits through either path update the tracked file. Review with `git diff`, then
commit and push as usual. If an application replaces a symlink when saving,
restore that link before making further edits. Neovim session files are not linked.

Original live files are backed up under
`~/.local/state/dotfiles-backups/`.
The repository versions before importing live configs are preserved in commit
`cc2a0f7`. These links are local to this machine; cloning the repo does not create them.

Machine-local license keys are loaded from `~/.config/zsh/dotfiles-secrets.zsh`
and are not stored in this repository.

## Per-machine zsh settings

`backup_zshrc` holds only the shared shell config (prompts, plugins, aliases).
Machine-specific PATHs and environment variables live in `machines/<hostname>.zsh`
(tracked, never secrets). At startup the shell sources the file matching
`hostname`, falling back to `machines/default.zsh` when no match exists, so a
fresh clone keeps working before any machine file is added. Secrets (tokens,
license keys) go in the untracked `~/.config/zsh/dotfiles-secrets.zsh`, which
is sourced last. To onboard a machine, add `machines/<hostname>.zsh` with its
PATHs and create a local `~/.config/zsh/dotfiles-secrets.zsh` if needed.

The Neovim Notebook path is fixed at `~/Desktop/Notebook` on every machine.

## Local tasks and reminders

On a Linux desktop with systemd, Python 3.10+, `python3-venv`, `notify-send`
(`libnotify-bin` on Ubuntu), and `gdbus`, run:

```sh
./tasks/install.sh
```

The installer creates a private Python environment, links `~/.local/bin/task`
and the Neovim plugin to this checkout, and enables the user reminder service.
It refuses to replace existing unrelated files. Keep the checkout at its installed
location; if you move it, remove the three old symlinks before rerunning setup.
Your Neovim must support
`vim.system` (0.10+). Restart Neovim after installing.

```vim
:Task check simulation @300s
:Task review DMA @1d 10:00
:Task buy groceries @2d
:Task read AXI documentation
:Task
:TaskStatus
```

With no sentence, `:Task` opens today's numbered Markdown checklist. From a
terminal, use `task 'check simulation @10m'`; `task` alone opens today's
file using `$VISUAL`, `$EDITOR`, or Neovim.

`:TaskStatus` opens a read-only agenda in the current window: overdue tasks,
today's unfinished tasks, and the following seven days, sorted by time. Empty
days and completed tasks are hidden; unscheduled tasks appear after timed tasks.
Use normal `j`/`k` movement and `/` search. **Enter** opens the selected task's
original daily file at its line. Edit and save there as usual, then **Ctrl-o**
returns to the agenda and refreshes it. **r** refreshes manually, and **q** closes
the agenda. It also refreshes when Neovim regains focus. The agenda is a temporary
buffer, not another task file, and repeated `:TaskStatus` calls reuse it.

Tasks live in `~/.local/share/tasks/YYYY-MM-DD.md` (or `$XDG_DATA_HOME/tasks`),
outside Git. There is no cross-machine sync. Run the installer on each machine to
share the tool, with independent task lists. `TASKS_DIR` can select another local
task directory; set it consistently for the editor and service if you use it.

You can edit the files normally. Add a line such as `[ ] review DMA @1d 10:00` or `- [ ] read AXI`, then save. The tool assigns a stable task number and
resolves the reminder into a date/time. Leave existing task numbers unchanged;
they are identifiers, so they do not restart at 1 each day. Mark `[x]` to complete
a task, or delete its line to remove it. Edit the time after `—` to reschedule;
remove the separator and time to remove the reminder. Ordinary headings and notes
are retained above the checklist. Invalid task lines are reported without
rewriting files; fix them to resume task processing. Errors from saved Neovim
edits appear in the editor; background errors appear in the service journal.

Reminders require a space followed by `@time`; text without a marker is a literal
unscheduled task title. There is no automatic English time detection.

| Marker | Meaning |
| --- | --- |
| `@300s` or `@300 seconds` | 300 seconds from now |
| `@10m` or `@10 minutes` | 10 minutes from now |
| `@2h` or `@2 hours` | 2 hours from now |
| `@1h30m` | 90 minutes from now |
| `@1d` | Tomorrow at 9am |
| `@2d 14:30` | Day after tomorrow at 2:30pm |
| `@0d 18:00` | Today at 6pm |
| `@05-11-26` or `@051126` | 5 November 2026 at 9am |
| `@05-11-26 10:00` or `@051126 10:00` | 5 November 2026 at 10am |

Date input is always **day-month-year**, and two-digit years mean **2000–2099**.
The clock must use 24-hour `HH:MM`, including the leading zero (`09:00`).
Dates and day offsets without a clock use **9am** in the laptop's timezone.
`s`, `m`, and `h` are elapsed durations; `d` is a calendar-day offset, so `@24h`
and `@1d` intentionally differ. Counts are whole numbers; elapsed durations must
be positive. Invalid, ambiguous, or past selected times are rejected without
saving the task. A past time is never silently moved to tomorrow.
Use `@1d` instead of `@tomorrow`, and an explicit date for a specific month.
Existing saved reminder timestamps remain valid, including overdue reminders.
The generated reminder timestamp after `—` includes its UTC offset; this avoids
losing the exact instant across timezone changes. You can replace the timestamp
with a marker expression such as `1d 10:00` when editing a reminder.

Unfinished tasks move into today's file automatically. Completed tasks stay in
their daily history. Rollover preserves the original reminder time and never
restarts dismissed reminders. The background service checks every five seconds,
including when Neovim is closed. After sleep, restart, or login, every missed
reminder is shown individually. Notification delivery requires an active desktop
session with notification actions enabled (including your desktop's notification
preferences / Do Not Disturb settings).

Notifications offer **Done**, **Snooze 15 min**, and **Dismiss**. Done checks the
task in its file; snooze schedules 15 minutes from the click; dismiss (or closing
the notification) leaves the task unfinished without repeating it. Reminders
still open when the service restarts may reappear. When an editor buffer has
unsaved changes, it cannot safely merge a simultaneous external update; the
Neovim integration prevents overwriting a newer disk version and asks you to
reload and reapply your edits.

```sh
systemctl --user status dotfiles-tasks.service
journalctl --user -u dotfiles-tasks.service
systemctl --user disable --now dotfiles-tasks.service  # stop reminders
~/.local/share/dotfiles-tasks/venv/bin/python -m unittest discover -s tasks/tests -v
```
