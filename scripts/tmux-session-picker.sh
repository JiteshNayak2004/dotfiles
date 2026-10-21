#!/usr/bin/env bash

if [[ ${1-} == --kill ]]; then
    [[ ${2-} =~ ^\$[0-9]+$ ]] || exit 0
    printf "\nKill session %s? [y/N] " "${3-}" >/dev/tty
    answer=
    IFS= read -r -n 1 answer </dev/tty
    printf "\n" >/dev/tty
    if [[ $answer == y ]]; then
        tmux kill-session -t "$2"
    fi
    exit 0
fi

selected=$(tmux list-sessions -F '#{session_id} #{session_name}' |
    fzf --reverse --prompt='session> ' --with-nth=2.. \
        --header='Enter: switch | Ctrl+x: delete (confirm with y)' \
        --bind="ctrl-x:execute(bash \"$0\" --kill {1} {2..})+reload(tmux list-sessions -F '#{session_id} #{session_name}' 2>/dev/null || true)")

if [[ -n $selected ]]; then
    tmux switch-client -t "${selected%% *}"
fi
