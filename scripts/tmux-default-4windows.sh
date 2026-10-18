#!/usr/bin/env bash

set -euo pipefail

session_name=${1:?session name is required}

tmux rename-window -t "${session_name}:" primary
tmux new-window -d -t "${session_name}:" -n terminal
tmux new-window -d -t "${session_name}:" -n llm
tmux new-window -d -t "${session_name}:" -n misc
