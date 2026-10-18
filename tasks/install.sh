#!/usr/bin/env bash
set -euo pipefail

task_repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
task_data_home=${XDG_DATA_HOME:-$HOME/.local/share}
task_config_home=${XDG_CONFIG_HOME:-$HOME/.config}

for task_dependency in python3 notify-send systemctl gdbus; do
    command -v "$task_dependency" >/dev/null || {
        printf 'Missing dependency: %s\n' "$task_dependency" >&2
        exit 1
    }
done
[[ $(notify-send --help) == *--action* ]] || {
    printf 'notify-send must support --action (install a recent libnotify-bin).\n' >&2
    exit 1
}
task_capabilities=$(gdbus call --session --dest org.freedesktop.Notifications \
    --object-path /org/freedesktop/Notifications \
    --method org.freedesktop.Notifications.GetCapabilities)
[[ "$task_capabilities" == *"'actions'"* ]] || {
    printf 'The desktop notification server must support action buttons. Run setup in a supported desktop session.\n' >&2
    exit 1
}
systemctl --user show-environment >/dev/null

task_targets=("$HOME/.local/bin/task" "$task_config_home/nvim/plugin/dotfiles-tasks.lua" "$task_config_home/systemd/user/dotfiles-tasks.service")
task_sources=("$task_repo_dir/task" "$task_repo_dir/../nvim/plugin/tasks.lua" "$task_repo_dir/dotfiles-tasks.service")
for task_index in "${!task_targets[@]}"; do
    task_target=${task_targets[$task_index]}
    task_source=${task_sources[$task_index]}
    if [[ -e "$task_target" || -L "$task_target" ]]; then
        if [[ ! -L "$task_target" || "$(readlink -f -- "$task_target")" != "$(readlink -f -- "$task_source")" ]]; then
            printf 'Refusing to replace existing path: %s\n' "$task_target" >&2
            exit 1
        fi
    fi
done

python3 -m venv "$task_data_home/dotfiles-tasks/venv"
"$task_data_home/dotfiles-tasks/venv/bin/python" -m pip install -r "$task_repo_dir/requirements.txt"

for task_index in "${!task_targets[@]}"; do
    task_target=${task_targets[$task_index]}
    task_source=${task_sources[$task_index]}
    mkdir -p -- "$(dirname -- "$task_target")"
    ln -sfn -- "$(readlink -f -- "$task_source")" "$task_target"
done

# Give the user service the same data directory and desktop session as this installer.
task_session_vars=(XDG_DATA_HOME XDG_CONFIG_HOME TASKS_DIR DISPLAY WAYLAND_DISPLAY DBUS_SESSION_BUS_ADDRESS XDG_CURRENT_DESKTOP)
for task_var in "${task_session_vars[@]}"; do
    if [[ -v "$task_var" ]]; then
        systemctl --user import-environment "$task_var"
    fi
done
systemctl --user daemon-reload
systemctl --user enable --now dotfiles-tasks.service
systemctl --user restart dotfiles-tasks.service
systemctl --user is-active --quiet dotfiles-tasks.service
printf '\nInstalled. Restart Neovim, then use :Task or :Task check simulation @10m\n'
