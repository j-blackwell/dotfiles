#! /usr/bin/env bash

function code_projects() {
    find ~/code ~/code-personal ~/dotfiles/nvim/.config -mindepth 1 -maxdepth 1 -type d | xargs -I {} basename {} | xargs -I {} echo {}
    echo dotfiles
}

CODE_PROJECT=$( (code_projects) | rofi -dmenu -p "Select code project")

if [[ -z "${CODE_PROJECT}" ]]; then
    echo "Cancel"
else
    FULL_PATH=$(find ~/code ~/code-personal ~/dotfiles/nvim/.config -mindepth 1 -maxdepth 1 -type d | grep "/${CODE_PROJECT}$" || echo ~/dotfiles)
    rofi-sensible-terminal -e tmux new-session -A -s $CODE_PROJECT "cd $FULL_PATH && source ~/.bashrc && /opt/nvim-linux64/bin/nvim .; bash" &
fi
