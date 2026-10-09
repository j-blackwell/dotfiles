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

# Chrome Update-Nag Policy
# google-chrome-stable (AUR) has no GoogleUpdater service, so Chrome's built-in
# update checker perpetually fails and nags with a "Can't update" notification.
# Updates are handled by pacman instead; disabling the checker via managed
# policy replaces the nag with "Updates are disabled by your administrator"
# in chrome://settings/help.
sudo mkdir -p /etc/opt/chrome/policies/managed
sudo tee /etc/opt/chrome/policies/managed/policy.json >/dev/null <<'EOF'
{
    "UpdateDisabled": true
}
EOF

# Graphics Portals
systemctl --user enable --now dbus.service

# Fonts
echo ":: Refreshing font cache..."
fc-cache -fv

echo ":: System configuration complete."
