#!/bin/bash

# Core Utilities
CORE_PKGS=(
	"reflector" "pacman-contrib" "ripgrep" "fd" "btop" "jq"
	"alsa-utils" "playerctl" "ldns" "ufw" "upower"
)

# Desktop (Wayland/Hyprland)
GUI_PKGS=(
	"hyprland" "hyprpaper" "hyprlock" "hypridle" "hyprshade"
	"waybar" "swaync" "waypaper" "wlogout" "grim" "slurp"
	"swappy" "wl-clipboard" "kanshi" "nwg-dock-hyprland"
	"rofi-wayland" "rofi-emoji" "qt6ct" "calibre"
)

# Development
DEV_PKGS=(
	"neovim" "tmux" "git" "github-cli" "lazygit"
	"npm" "python" "python-pip" "python-virtualenv"
	"rustup" "helm" "docker" "docker-buildx" "pyenv" "uv"
)

# Applications
APP_PKGS=(
	"firefox" "kitty" "nautilus" "gimp" "obsidian"
	"syncthing" "libreoffice-fresh" "mpv" "timeshift"
)

# Fonts
FONT_PKGS=(
	"ttf-martian-mono-nerd" "ttf-font-awesome" "noto-fonts-emoji"
)

# AUR Packages
AUR_PKGS=(
	"paru-bin" "wttrbar" "gcalcli" "bluetui" "zen-browser-bin"
	"slack-desktop" "google-chrome" "dropbox" "duckdb-bin"
)

echo ":: Installing Core Packages..."
sudo pacman -S --needed --noconfirm "${CORE_PKGS[@]}"

echo ":: Installing Desktop Packages..."
sudo pacman -S --needed --noconfirm "${GUI_PKGS[@]}"

echo ":: Installing Development Packages..."
sudo pacman -S --needed --noconfirm "${DEV_PKGS[@]}"

echo ":: Installing Applications..."
sudo pacman -S --needed --noconfirm "${APP_PKGS[@]}"

echo ":: Installing Fonts..."
sudo pacman -S --needed --noconfirm "${FONT_PKGS[@]}"

# Helper for AUR
if ! command -v paru &>/dev/null && ! command -v yay &>/dev/null; then
	echo ":: Installing paru..."
	git clone https://aur.archlinux.org/paru-bin.git /tmp/paru-bin
	cd /tmp/paru-bin && makepkg -si --noconfirm
	cd - && rm -rf /tmp/paru-bin
fi

AUR_HELPER=$(command -v paru || command -v yay)

echo ":: Installing AUR Packages..."
$AUR_HELPER -S --needed --noconfirm "${AUR_PKGS[@]}"
