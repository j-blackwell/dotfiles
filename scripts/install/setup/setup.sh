#!/usr/bin/bash

## flathub & flatpak
sudo apt install flatpak
flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo


## automatic updates
sudo apt install unattended-upgrades
sudo dpkg-reconfigure unattended-upgrades


## snap
sudo apt update
sudo apt install snapd

## .bashrc
ln $DOTFILES/config/.bashrc $HOME/.bashrc
ln $DOTFILES/config/.gitconfig $HOME/.gitconfig
ln $DOTFILES/config/.config/Code/User/settings.json $HOME/.config/Code/User/settings.json
ln $DOTFILES/config/.ipython/profile_default/ipython_config.py $HOME/.ipython/profile_default/ipython_config.py
ln $DOTFILES/config/.ipython/profile_default/startup/disable-warnings.py $HOME/.ipython/profile_default/startup/disable-warnings.py



## TODO: folders
#ln $DOTFILES/config/.config/synth-shell
