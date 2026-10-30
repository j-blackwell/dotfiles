#!/bin/bash

SETUPSCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# Run package installation
bash "$SETUPSCRIPT_DIR/packages.sh"

# Run custom installers (OpenCode, etc.)
bash "$SETUPSCRIPT_DIR/custom_installers.sh"

# Run system configuration
bash "$SETUPSCRIPT_DIR/system.sh"

# Run stow
bash "$SETUPSCRIPT_DIR/stow.sh"

# Post-stow: Yazi package installation
if command -v ya &>/dev/null; then
	echo ":: Installing Yazi packages..."
	ya pkg install
fi

# Post-stow: hyprwhspr (dictation) backend venv + model. Runs after stow so it
# writes into the stowed config rather than one stow would then --adopt.
if command -v hyprwhspr &>/dev/null; then
	echo ":: Setting up hyprwhspr..."
	hyprwhspr setup auto --backend onnx-asr --no-waybar --no-mic-osd --no-systemd --hypr-bindings
fi

echo ":: Setup complete! Please restart your session."
