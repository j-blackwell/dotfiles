# utils
sudo pacman -S wl-clipboard reflector pacman-contrib xdg-desktop-portal xdg-desktop-portal-wlr grim ripgrep amd-ucode jq fd btop alsa-utils playerctl

sudo pacman -S xdg-desktop-portal xdg-desktop-portal-wlr
systemctl --user start xdg-desktop-portal-wlr.service

cd ~/dotfiles
stow --adopt .
stow --adopt flameshot
stow --adopt hypr
stow --adopt waybar
