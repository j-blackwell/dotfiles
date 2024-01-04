#!/usr/bin/bash

sudo apt install fonts-powerline
git clone --recursive https://github.com/andresgongora/synth-shell.git
chmod +x synth-shell/setup.sh
cd synth-shell
./setup.sh
cd ..
rm -rf synth-shell
