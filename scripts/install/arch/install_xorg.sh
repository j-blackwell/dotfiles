# utils
sudo pacman -S wl-clipboard reflector pacman-contrib xdg-desktop-portal xdg-desktop-portal-wlr grim ripgrep amd-ucode jq fd btop alsa-utils playerctl

# dotfiles
cd ~/dotfiles
stow --adopt polybar
stow --adopt rofi
stow --adopt alacritty
stow --adopt flameshot
stow --adopt i3
stow --adopt dunst

# desktop
sudo pacman -S rofi polybar rofi-emoji

# apps
sudo pacman -S flameshot
