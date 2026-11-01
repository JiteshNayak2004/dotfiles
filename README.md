# Dotfiles

Shared Linux configuration with a repository-local setup tool. No Stow required.

## Set up another machine

Supported baseline: Ubuntu 24.04, GNOME Shell 46, system Python 3.12+.
File-only components can also be applied on other Linux systems with dependencies
installed manually. Windows/macOS and newer GNOME settings are not validated.

Clone the repo, sync your Notebook directory separately, launch Firefox once to
create its profile, then close Firefox and run from a GNOME terminal:

```sh
git clone https://github.com/JiteshNayak2004/dotfiles.git
cd dotfiles
./dotfiles setup --install-packages
```

Setup asks for the Notebook directory and which Firefox profile to manage. Press
Enter at the Firefox prompt to skip Firefox. GNOME is deselected automatically
when setup is run outside a detected GNOME session.

`--install-packages` uses sudo for Ubuntu apt dependencies, then bootstraps pinned
shell/tmux/Neovim plugins, a checksum-verified Neovim 0.11.7 build, JetBrains Nerd
Font, Pyright, available VS Code extensions, compatible GNOME extensions, and
Firefox add-on packages. It sets up the task reminder service after applying files.
Third-party GUI applications (Code, Doom Emacs, Zed, Lazygit, Qutebrowser, etc.)
need their own installation; their captured configs are deployed by `editors`.
`doctor` reports missing applications. Proprietary EDA tools/licenses are local.

New GNOME extensions may require logging out/in, followed by `./dotfiles apply`.
Firefox add-ons are downloaded to `~/.local/share/dotfiles/firefox-addons/`;
open `about:addons` and use the gear menu → Install Add-on From File to approve
them. Ordinary Firefox does not provide a reliable per-user silent-install flow. Vimium/Sidebery settings,
Tampermonkey scripts, and other extension-specific data still need reviewed exports;
see [the capture inventory](docs/configuration-inventory.md).

For existing dependencies, omit `--install-packages` and run `./dotfiles deps`
separately when needed. Dependency installations, downloaded tools, apt packages,
and service enablement are outside configuration rollback. The setup tool never
changes your login shell; launch `zsh`, or use `chsh -s /usr/bin/zsh` yourself.

## Machine-local paths

Answers live in `~/.config/dotfiles/machine.json`, outside Git. Use
`./dotfiles configure` to change them. For unattended setup, copy and edit
[config/machine.example.json](config/machine.example.json), then run:

```sh
./dotfiles setup --config /path/to/machine.json --non-interactive --install-packages
```

Keep that external JSON file at its chosen location; subsequent commands need
`--config /path/to/machine.json`. The generated shell and Neovim path files live
under `$XDG_CONFIG_HOME/dotfiles/`; Neovim reads them even from GUI launchers.
`path_dirs` prepends existing tool directories; `env` supplies tool variables.
`tasks_dir` selects local task storage. Shared config never copies Notebook or
task contents. Credentials remain in `~/.config/zsh/dotfiles-secrets.zsh`.
Shell-only customizations may go in `$XDG_CONFIG_HOME/dotfiles/local.zsh`.

Components: `shell`, `terminal`, `nvim`, `editors`, `desktop`, `tasks`, `gnome`,
`firefox`. All are selected by default. Select a subset for a headless machine:

```sh
./dotfiles setup --non-interactive --notebook /path/to/Notebook \
  --components shell,terminal,nvim
```

Hardware preferences and the LG input shortcut are opt-in through
`hardware_settings` and `lg_monitor`. The double-Ctrl listener/autostart is X11
only and skipped on Wayland. The ordinary Rofi shortcut remains available, but
Rofi's window-switching mode depends on desktop/display-server support.
Legacy `machines/laptop.zsh` is retained as reference and is not automatically
sourced. The old workstation fallback was preserved locally on the source machine;
new machines receive portable defaults only.

## Apply, update, and refresh

```sh
./dotfiles apply --dry-run   # inspect planned replacements/settings
./dotfiles apply             # back up conflicts, link files, apply settings
./dotfiles update            # fast-forward from upstream, then apply
./dotfiles refresh           # reload tmux/restart an already-active task service
./dotfiles doctor            # report missing dependencies and file drift
./dotfiles deps              # install missing locked plugins/tools/add-ons
./dotfiles tasks-setup       # create task venv and enable reminder service
./dotfiles firefox-addons    # download verified packages for browser-side installation
```

`config_update` runs the update command from Zsh. Updates refuse a dirty checkout
or a diverged branch. Changed plugin/add-on manifests trigger dependency setup
before apply; changed system-package lists are reported for explicit apt setup. Commit/push intentional shared-config edits before updating
other machines. Existing plugins at a different revision or with local edits are
left alone with an actionable error; dependency versions are changed deliberately.

Files are linked individually from [config/files.json](config/files.json).
Existing files/symlinks are backed up before replacement. Directory conflicts or
writes through symlinked parent directories stop preflight; migrate such directory
links to individual files first. Unrelated files are retained. Git identity and
other Git settings are preserved via a managed include. Zed settings are generated
from shared preferences while preserving existing machine-local SSH connections. Firefox user.js and CSS
are merged using delimited managed blocks; the rest of each file is preserved.
Firefox must be closed before applying browser files.

GNOME settings are applied only from a GNOME 46 session. Available enabled
extensions are restored; unavailable extensions are reported. Monitor preferences,
experimental scaling, and the LG shortcut are excluded unless opted in. App IDs
for Auto Move Windows/favorites are captured from the source installation and may
need adjustment when switching between Snap and native applications.

Apply reloads a running tmux server and restarts an already-active task service.
Open a new terminal after applying shell changes; reopen editors/Firefox. Log
out/in for extensions and autostart changes. Active applications are not killed.

## Recovery and verification

Each changed apply prints a backup ID. Backups are private and live under
`$XDG_STATE_HOME/dotfiles/backups/` (default `~/.local/state/dotfiles/backups/`).
They record replaced files, original symlinks, and previous values for changed
GNOME keys. An apply failure attempts to restore that run automatically.

```sh
./dotfiles rollback BACKUP-ID
```

Rollback refuses to overwrite subsequent edits; inspect them before using
`--force`. It restores configuration, not the Git revision or installed packages.
For multiple runs, roll back newest first. Empty directories may remain.
A dry run writes no files, settings, backups, or local configuration. An unchanged
apply makes no new backup. Keep the checkout at its installed path; reapply after
moving it to update links and generated paths.

```sh
/usr/bin/python3 -m unittest discover -s tests -v
```

Tests use temporary homes and a private D-Bus/dconf session, never live GNOME
settings. [The capture inventory](docs/configuration-inventory.md) lists source
files, destinations, dependencies, and remaining browser export gaps.

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
