#!/usr/bin/bash

wget https://zoom.us/client/5.17.1.1840/zoom_amd64.deb
sudo dpkg -i zoom_amd64.deb
sudo apt --fix-broken install
rm zoom_amd64.deb
