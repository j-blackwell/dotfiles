#!/usr/bin/bash

sudo add-apt-repository ppa:mikhailnov/pulseeffects
sudo apt update
sudo apt install pop-pipewire
sudo apt install pulseaudio pulseeffects --install-recommends
