#!/usr/bin/bash

## flathub & flatpak
sudo apt install flatpak
flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo


## snap
sudo apt update
sudo apt install snapd

## .bashrc
ln $DOTFILES/config/.bashrc $HOME/.bashrc
