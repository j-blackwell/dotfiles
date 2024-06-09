# utils
sudo pacman -S wl-clipboard reflector pacman-contrib xdg-desktop-portal xdg-desktop-portal-wlr grim

sudo systemctl enable reflector.service && sudo systemctl start reflector.service
sudo systemctl enable fstrim.timer
sudo systemctl enable paccache.timer

# apps
sudo pacman -S firefox flameshot nautilus neovim steam tmux
yay -S ytmdesktop-bin albert

# programming
sudo pacman -S npm python3 python-pip python-virtualenv rust

# fonts
sudo pacman -S ttf-martian-mono-nerd
fc-cache -fv

# symlinks
sudo pacman -S stow
ln -sf /home/james/code/dotfiles/ /path/to/symlink

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
