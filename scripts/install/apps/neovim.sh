#!/usr/bin/bash

# dependencies
sudo apt-get install ripgrep
sudo apt install xclip

# dependencies - lazygit
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xf lazygit.tar.gz lazygit
sudo install lazygit /usr/local/bin
rm lazygit
rm lazygit.tar.gz

# dependencies - npm
curl -fsSL https://deb.nodesource.com/setup_21.x | sudo -E bash - &&
	sudo apt-get install -y nodejs

curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz
sudo rm -rf /opt/nvim
sudo tar -C /opt -xzf nvim-linux64.tar.gz
echo 'export PATH="$PATH:/opt/nvim-linux64/bin"' >>~/.bashrc
rm nvim-linux64.tar.gz

git clone git@github.com:jrstats/neovim-config.git ~/.config/nvim/
echo 'alias nv-dotfiles="cd ~/code/dotfiles/ && nvim . -S Session.vim"' >>~/.bashrc
echo 'alias nv-config="cd ~/.config/nvim/ && nvim . -S Session.vim"' >>~/.bashrc
echo 'alias nv-bashrc="nvim ~/.bashrc"' >>~/.bashrc
