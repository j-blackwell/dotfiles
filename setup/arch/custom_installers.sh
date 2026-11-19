#!/bin/bash

echo ":: Running Custom Installers..."

# OpenCode
if ! command -v opencode &>/dev/null; then
	echo ":: Installing OpenCode..."
	curl -fsSL https://opencode.ai/install | bash
else
	echo ":: OpenCode is already installed."
fi

# Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
	echo ":: Installing Oh My Zsh..."
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
	echo ":: Oh My Zsh is already installed."
fi

# ZSH Plugins
ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}
if [ -d "$HOME/.oh-my-zsh" ]; then
	echo ":: Installing ZSH Plugins..."
	[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] && git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
	[ ! -d "$ZSH_CUSTOM/plugins/fast-syntax-highlighting" ] && git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git "$ZSH_CUSTOM/plugins/fast-syntax-highlighting"
fi

# Global npm packages, installed under ~/.local (bin/ is on PATH) rather than npm's
# default /usr prefix, which needs sudo and is pacman's territory.
NPM_GLOBAL_PKGS=(
	"@googleworkspace/cli" # gws: Google Tasks for the scratch call note (scratchnote_actions.py)
)
echo ":: Installing global npm packages..."
npm install -g --prefix "$HOME/.local" --allow-scripts="$(IFS=,; echo "${NPM_GLOBAL_PKGS[*]}")" "${NPM_GLOBAL_PKGS[@]}"

# Add other custom/curl-based installers here as needed
# Example:
# if ! command -v some-tool &> /dev/null; then
#    curl -sS https://example.com/install.sh | bash
# fi
