#!/bin/bash
# tmux-default-4windows.sh — 4 named windows, plain, no extra UI:
#   1: primary | 2: terminal | 3: llm | 4: misc
# Focus ends on primary. Idempotent: only runs if session has 1 window
# (protects resurrect/continuum restores).
SESSION="${1:-}"
if [ -z "$SESSION" ]; then
  SESSION="$(tmux display-message -p '#{session_id}' 2>/dev/null)"
fi
[ -n "$SESSION" ] || exit 0
# hook_session expands to bare digits (e.g. "5"); normalize to "$5" session ID
if [[ "$SESSION" =~ ^[0-9]+$ ]]; then
  SESSION="\$$SESSION"
fi
sleep 0.2
WIN_COUNT="$(tmux list-windows -t "$SESSION" 2>/dev/null | wc -l)"
if [ "$WIN_COUNT" -ne 1 ]; then
  exit 0
fi
# Rename first window to primary
tmux rename-window -t "${SESSION}:1" "primary" >/dev/null 2>&1
tmux set-window-option -t "${SESSION}:1" automatic-rename off >/dev/null 2>&1
# Create the other three
tmux new-window -t "$SESSION" -n "terminal" >/dev/null 2>&1
tmux set-window-option -t "${SESSION}:2" automatic-rename off >/dev/null 2>&1
tmux new-window -t "$SESSION" -n "llm" >/dev/null 2>&1
tmux set-window-option -t "${SESSION}:3" automatic-rename off >/dev/null 2>&1
tmux new-window -t "$SESSION" -n "misc" >/dev/null 2>&1
tmux set-window-option -t "${SESSION}:4" automatic-rename off >/dev/null 2>&1
# Back to primary
tmux select-window -t "${SESSION}:1" >/dev/null 2>&1
exit 0
