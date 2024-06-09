sudo apt install tmux
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

mkdir -p $HOME/.config/tmux/
ln $DOTFILES/config/.config/tmux/tmux.conf $HOME/.config/tmux/tmux.conf
