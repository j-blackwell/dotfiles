#! /usr/bin/env bash
CODE_PROJECT=$1

if [[ -z "$CODE_PROJECT" ]]; then
    echo "No project set"
else
    i3-sensible-terminal -e tmux new-session -A -s $CODE_PROJECT "cd $CODE_PROJECT && /opt/nvim-linux64/bin/nvim .; bash" &
fi
