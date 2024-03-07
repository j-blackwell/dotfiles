#!/usr/bin/bash

## upgrade all packages
sudo apt update && sudo apt upgrade


target="./apps"
cd $target

for script in *; do
    if [ -f "$script" ] && [ -x "$script" ]; then
    echo "Installing $script"
        ./"$script"
    fi
done
