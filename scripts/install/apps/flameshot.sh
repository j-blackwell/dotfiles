#!/usr/bin/bash


sudo apt install flameshot


# The command to be executed by the shortcut
CMD="/usr/bin/flameshot gui"

# The custom keyboard shortcut key combination
KEYBINDING="<Super><Shift>s"

# The name of the shortcut
NAME="Flameshot"

# Get the current list of custom keybindings
EXISTING_KEYBINDINGS=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)

# If the existing keybindings do not end with a comma and closing bracket, add them
if [[ $EXISTING_KEYBINDINGS != *"],'" ]]; then
    EXISTING_KEYBINDINGS=${EXISTING_KEYBINDINGS::-1},
fi

# The new keybinding path (increment the custom keybinding index)
NEW_BINDING="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$(($(echo $EXISTING_KEYBINDINGS | tr -cd '/' | wc -c)))"

# Add the new keybinding path to the list
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "${EXISTING_KEYBINDINGS}'${NEW_BINDING}/']"

# Set the name, command, and keybinding for the new shortcut
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${NEW_BINDING}/ name "$NAME"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${NEW_BINDING}/ command "$CMD"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${NEW_BINDING}/ binding "$KEYBINDING"

echo "Custom keyboard shortcut for $NAME set to $KEYBINDING."
