#!/usr/bin/bash

## save passwords in vault
sudo apt install gnome-keyring
## kde uses ksecretservice

## add repo
wget https://dev.mysql.com/get/Downloads/MySQLGUITools/mysql-workbench-community_8.0.34-1ubuntu22.04_amd64.deb # find version from https://dev.mysql.com/downloads/workbench/

## install
sudo dpkg -i mysql-workbench-community_*_amd64.deb
sudo apt --fix-broken install
rm mysql-workbench-community_*_amd64.deb
