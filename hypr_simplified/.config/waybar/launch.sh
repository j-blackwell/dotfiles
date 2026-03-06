#!/bin/bash
# Simplified Waybar Launch Script
# Strictly uses ml4w-modern light theme (unified)

killall waybar
pkill waybar
sleep 0.5

# Paths to the specific configuration and style
THEME="ml4w-modern"
if [ -f "$HOME/.config/waybar/current_theme" ]; then
	THEME=$(cat "$HOME/.config/waybar/current_theme")
fi

CONFIG="$HOME/.config/waybar/themes/$THEME/config"
STYLE="$HOME/.config/waybar/themes/$THEME/style.css"

if [ ! -f $HOME/.config/ml4w/settings/waybar-disabled ]; then
	waybar -c "$CONFIG" -s "$STYLE" &
else
	echo ":: Waybar disabled"
fi
