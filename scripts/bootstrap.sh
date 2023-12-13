DOTFILES=$(pwd -P)

ln -s $DOTFILES/config/.gitconfig $HOME/.gitconfig
ln -s $DOTFILES/config/.vscode $HOME/.vscode
ln -s $DOTFILES/config/.ipython $HOME/.ipython
ln -s $DOTFILES/config/.zshrc $HOME/.zshrc
