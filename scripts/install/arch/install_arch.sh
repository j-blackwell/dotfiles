# utils
sudo pacman -S wl-clipboard reflector pacman-contrib xdg-desktop-portal xdg-desktop-portal-wlr grim ripgrep amd-ucode jq fd btop alsa-utils playerctl

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
sudo pacman -S npm python3 python-pip python-virtualenv rust pyenv helm
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(pyenv init -)"' >> ~/.bashrc

# fonts
sudo pacman -S ttf-martian-mono-nerd ttf-font-awesome noto-fonts-emoji
fc-cache -fv

# symlinks
sudo pacman -S stow
cd ~
git clone git@github.com:jrstats/dotfiles.git
cd dotfiles
stow --adopt .
stow --adopt nvim
stow --adopt polybar
stow --adopt rofi
stow --adopt alacritty
stow --adopt flameshot
stow --adopt i3
stow --adopt tmux
stow --adopt dunst

# backups
sudo pacman -S timeshift
sudo -E timeshift-gtki

# bluetooth
sudo pacman -S bluez bluez-utils
sudo systemctl enable bluetooth.service && sudo systemctl start bluetooth.service
yay -S bluetui

# sound
sudo pacman -S pulseaudio lib32-libpulse lib32-alsa-plugins mpv
sudo systemctl --user enable dbus
sudo systemctl --user enable pulseaudio

pactl set-default-sink alsa_output.pci-0000_26_00.1.hdmi-stereo-extra4

# desktop
sudo pacman -S rofi polybar rofi-emoji

# apps
sudo pacman -S firefox flameshot lazygit nautilus neovim tmux gimp obsidian syncthing
yay -S ytmdesktop-bin noson-app zen-browser-bin
sudo systemctl enable syncthing@$USER.service
sudo systemctl start syncthing@$USER.service

# work
sudo pacman -S docker docker-buildx mysql-workbench r libreoffice-fresh
yay -S google-chrome dropbox duckdb-bin google-cloud-cli slack-desktop dropbox-cli

