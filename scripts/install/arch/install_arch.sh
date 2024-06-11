# utils
sudo pacman -S wl-clipboard reflector pacman-contrib xdg-desktop-portal xdg-desktop-portal-wlr grim ripgrep amd-ucode jq

sudo systemctl enable reflector.service && sudo systemctl start reflector.service
sudo systemctl enable fstrim.timer
sudo systemctl enable paccache.timer

# network
sudo pacman -S ldns ufw
sudo ufw enable
sudo systemctl enable ufw.service

# graphics
sudo pacman -S xdg-desktop-portal xdg-desktop-portal-wlr
systemctl --user start xdg-desktop-portal-wlr.service

# power
sudo pacman -S upower

# programming
sudo pacman -S npm python3 python-pip python-virtualenv rust

# fonts
sudo pacman -S ttf-martian-mono-nerd
fc-cache -fv

# symlinks
sudo pacman -S stow
cd ~
git clone git@github.com:jrstats/dotfiles.git
cd dotfiles
stow --adopt .

# backups
sudo pacman -S timeshift
sudo -E timeshift-gtki

# bluetooth
sudo pacman -S bluez bluez-utils
sudo systemctl enable bluetooth.service && sudo systemctl start bluetooth.service
yay -S bluetui

# sound
sudo pacman -S pulseaudio lib32-libpulse lib32-alsa-plugins
sudo systemctl --user enable dbus
sudo systemctl --user enable pulseaudio

# desktop
sudo pacman -S rofi

# apps
sudo pacman -S firefox flameshot lazygit nautilus neovim steam tmux
yay -S ytmdesktop-bin albert

# work
sudo pacman -S docker mysql-workbench r
yay -S google-chrome dropbox duckdb-bin google-cloud-cli slack-desktop

## edit google-chrome desktop entry for wayland (--ozone-platform=wayland)
