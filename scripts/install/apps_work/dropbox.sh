#!/usr/bin/bash

wget https://linux.dropboxstatic.com/packages/ubuntu/dropbox_2020.03.04_amd64.deb

sudo dpkg -i dropbox_*_amd64.deb
sudo apt --fix-broken install

rm dropbox_*_amd64.deb
