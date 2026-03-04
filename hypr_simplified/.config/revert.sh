#!/bin/bash

# 1. Remove the simplified symlinks
cd ~/dotfiles
stow -D hypr_simplified

# 2. Stop services unique to the simplified config
pkill kanshi

# 3. Restore your original folders if they exist
if [ -d "$HOME/.config/hypr.ml4w.bak" ]; then
    rm -rf ~/.config/hypr # Ensure any leftover symlink is gone
    mv ~/.config/hypr.ml4w.bak ~/.config/hypr
    echo "Restored Hyprland config."
fi

if [ -d "$HOME/.config/waybar.ml4w.bak" ]; then
    rm -rf ~/.config/waybar
    mv ~/.config/waybar.ml4w.bak ~/.config/waybar
    echo "Restored Waybar config."
fi

if [ -d "$HOME/.config/rofi.ml4w.bak" ]; then
    rm -rf ~/.config/rofi
    mv ~/.config/rofi.ml4w.bak ~/.config/rofi
    echo "Restored Rofi config."
fi

# 4. Reload Hyprland and launch the original Waybar
hyprctl reload
# Original ML4W setup often launches waybar via xdg.sh or scripts
# But launch.sh is the most direct way to ensure it's up.
if [ -f "$HOME/.config/waybar/launch.sh" ]; then
    bash ~/.config/waybar/launch.sh
fi

echo "Revert complete."
