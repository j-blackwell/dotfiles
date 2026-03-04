#!/bin/bash
# Simplified Waybar Launch Script
# Strictly uses ml4w-modern light theme (unified)

killall waybar
pkill waybar
sleep 0.5

# Paths to the specific configuration and style
CONFIG="$HOME/.config/waybar/themes/ml4w-modern/config"
STYLE="$HOME/.config/waybar/themes/ml4w-modern/style.css"

if [ ! -f $HOME/.config/ml4w/settings/waybar-disabled ]; then
    waybar -c "$CONFIG" -s "$STYLE" &
else
    echo ":: Waybar disabled"
fi
