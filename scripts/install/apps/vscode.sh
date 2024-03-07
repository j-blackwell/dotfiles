#!/usr/bin/bash

## add repo
sudo apt install software-properties-common apt-transport-https wget -y
wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main"

## install
sudo apt install code

## extensions / config
extensions=(
    charliermarsh.ruff
    eamodio.gitlens
    horla.horla-light-theme
    ms-python.debugpy
    ms-python.python
    ms-python.vscode-pylance
    ms-toolsai.jupyter
    ms-toolsai.jupyter-keymap
    ms-toolsai.jupyter-renderers
    ms-toolsai.vscode-jupyter-cell-tags
    ms-toolsai.vscode-jupyter-slideshow
    qwtel.sqlite-viewer
    shd101wyy.markdown-preview-enhanced
    vscode-icons-team.vscode-icons
    rust-lang.rust-analyzer
)

# Get a list of all currently installed extensions.
installed_extensions=$(code --list-extensions)

for extension in "${extensions[@]}"; do
    if echo "$installed_extensions" | grep -qi "^$extension$"; then
        echo "$extension is already installed. Skipping..."
    else
        echo "Installing $extension..."
        code --install-extension "$extension"
    fi
done

echo "VS Code extensions have been installed."


# config
ln $DOTFILES/config/.vscode/settings.json $HOME/.config/Code/User/settings.json