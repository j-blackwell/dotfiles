DOTFILES=$(pwd -P)

# mv $HOME/$1 $DOTFILES/config/$1
echo "ln -s \$DOTFILES/config/$1 \$HOME/$1" >> ./scripts/bootstrap.sh