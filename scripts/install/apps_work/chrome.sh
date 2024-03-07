#!/usr/bin/bash
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i google-chrome-stable_current_amd64.deb
sudo apt -f install
rm google-chrome-stable_current_amd64.deb

## rest is achieved using google accounts
