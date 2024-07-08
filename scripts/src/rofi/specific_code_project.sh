#! /usr/bin/env bash
CODE_PROJECT=$1
TMUX_NAME=$(basename $CODE_PROJECT)

if [[ -z "$CODE_PROJECT" ]]; then
    echo "No project set"
else
    i3-sensible-terminal -e tmux new-session -A -s $TMUX_NAME "cd $CODE_PROJECT && nvim .; bash" &
fi
