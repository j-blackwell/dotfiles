#!/bin/bash

DOTFILES_DIR=$(cd "$(dirname "$0")/../.." && pwd)
cd "$DOTFILES_DIR"

echo ":: Stowing dotfiles from $DOTFILES_DIR..."

# List of modules to stow (excluding setup, install, archive, and hidden dirs)
MODULES=$(ls -d */ | grep -vE 'setup|install|archive|target' | sed 's/\///')

for module in $MODULES; do
	echo ":: Stowing $module..."
	stow --adopt "$module"
done

# Ensure git doesn't track adoption changes if we don't want them
# git checkout .

echo ":: Dotfiles stowed successfully."
