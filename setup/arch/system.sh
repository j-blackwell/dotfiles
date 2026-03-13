#!/bin/bash

echo ":: Configuring System Services..."

# Reflectors and Maintenance
sudo systemctl enable --now reflector.service
sudo systemctl enable fstrim.timer
sudo systemctl enable paccache.timer

# Network & Bluetooth
sudo systemctl enable --now bluetooth.service
sudo ufw enable
sudo systemctl enable --now ufw.service

# Synchronization
sudo systemctl enable --now systemd-timesyncd

# Graphics Portals
systemctl --user enable --now dbus.service

# Fonts
echo ":: Refreshing font cache..."
fc-cache -fv

echo ":: System configuration complete."
