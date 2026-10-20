#!/bin/zsh

SCRIPT_PATH=${0%/*}
TBACK="$HOME/.backup"

if [ ! -d $TBACK ]; then
  mkdir -p $TBACK
fi

# Clone main into ~/.local/share/dotfiles and symlink dotfiles/, scripts/ and
# fns/ from there into $HOME. Honors DRY_RUN. Later updates: `dotfiles pull`.
zsh "$SCRIPT_PATH/dotfiles" install

echo "Sourcing ~/.zshrc"
source $HOME/.zshrc
