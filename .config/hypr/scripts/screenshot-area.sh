#!/bin/bash
#  ____                               _           _
# / ___|  ___ _ __ ___  ___ _ __  ___| |__   ___ | |_
# \___ \ / __| '__/ _ \/ _ \ '_ \/ __| '_ \ / _ \| __|
#  ___) | (__| | |  __/  __/ | | \__ \ | | | (_) | |_
# |____/ \___|_|  \___|\___|_| |_|___/_| |_|\___/ \__|
#
# Based on https://github.com/hyprwm/contrib/blob/main/grimblast/screenshot.sh
# -----------------------------------------------------

# Screenshots will be stored in $HOME by default.
# The screenshot will be moved into the screenshot directory

# Add this to ~/.config/user-dirs.dirs to save screenshots in a custom folder:
# XDG_SCREENSHOTS_DIR="$HOME/Screenshots"

# Screenshot Editor
export GRIMBLAST_EDITOR="$(cat ~/.config/ml4w/settings/screenshot-editor.sh)"

hyprctl keyword decoration:active_opacity 1.0
hyprctl keyword decoration:inactive_opacity 1.0
grimblast --notify edit area
hyprctl reload  # Restores original opacity settings

