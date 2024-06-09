#!/usr/bin/bash
wget https://github.com/ytmdesktop/ytmdesktop/releases/download/v2.0.0-rc.4/youtube-music-desktop-app_2.0.0.rc.4_amd64.deb

sudo dpkg -i youtube-music-desktop-app_*_amd64.deb
sudo apt --fix-broken install

rm youtube-music-desktop-app_*_amd64.deb
