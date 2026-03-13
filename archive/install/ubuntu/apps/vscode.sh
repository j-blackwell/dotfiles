#!/usr/bin/bash

## add repo
wget -qO - https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg \
    | gpg --dearmor \
    | sudo dd of=/usr/share/keyrings/vscodium-archive-keyring.gpg

echo 'deb [ signed-by=/usr/share/keyrings/vscodium-archive-keyring.gpg ] https://download.vscodium.com/debs vscodium main' \
    | sudo tee /etc/apt/sources.list.d/vscodium.list

## install
sudo apt update && sudo apt install codium

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
    tamasfe.even-better-toml
    vscodevim.vim
)

# Get a list of all currently installed extensions.
installed_extensions=$(codium --list-extensions)

for extension in "${extensions[@]}"; do
    if echo "$installed_extensions" | grep -qi "^$extension$"; then
        echo "$extension is already installed. Skipping..."
    else
        echo "Installing $extension..."
        codium --install-extension "$extension"
    fi
done

echo "VS Code extensions have been installed."


# config
ln $DOTFILES/config/.vscode/settings.json $HOME/.config/Code/User/settings.json
