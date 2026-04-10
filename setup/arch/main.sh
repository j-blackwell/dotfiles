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

echo ":: Setup complete! Please restart your session."
