#!/bin/zsh

SCRIPT_PATH=${0%/*}
TFILES="$SCRIPT_PATH/../dotfiles"
TSCRIPTS="$SCRIPT_PATH/../scripts"
TBACK="$HOME/.backup"

function move_files () {
  sdir="$SCRIPT_PATH/$1"
  [ -z "$2" ] && tdir="$HOME" || tdir="$HOME/$2"
  [ -z "$2" ] && bdir="$HOME/.backup" || bdir="$HOME/.backup/$2"

  echo "Installing $sdir into $tdir"
  echo "All existing files will be moved to $bdir"

  if [ ! -z "$2" ]; then
    if [ -z $DRY_RUN ] && [ ! -d "$tdir" ]; then
      mkdir -p "$tdir"
    fi

    if [ ! -d "$bdir" ]; then
      mkdir -p "$bdir"
    fi
  fi

  for source in `find $sdir`; do
    if [ -z $DRY_RUN ] && [ ! -d $source ]; then
      file=${source##*/}

      if [ -f "$tdir/$file" ]; then
        cp -f "$tdir/$file" "$bdir/$file"
      fi

      echo "Installing $1/$file"
      rm "$tdir/$file"
      cp -f "$source" "$tdir/$file"
    fi
  done
}

function link_scripts () {
  # Symlink the whole scripts dir as ~/.scripts so PATH lookups (and edits) are
  # live without re-running setup. Backs up any prior real directory.
  src="$(cd "$SCRIPT_PATH/../scripts" && pwd)"
  dst="$HOME/.scripts"

  if [ -L "$dst" ]; then
    [ "$(readlink "$dst")" = "$src" ] && { echo "Linked $dst -> $src (already)"; return; }
    [ -z $DRY_RUN ] && rm "$dst"
  elif [ -d "$dst" ]; then
    echo "Backing up existing $dst to $TBACK/.scripts"
    [ -z $DRY_RUN ] && mv "$dst" "$TBACK/.scripts"
  elif [ -e "$dst" ]; then
    echo "Backing up existing $dst to $TBACK/.scripts"
    [ -z $DRY_RUN ] && mv "$dst" "$TBACK/.scripts"
  fi

  echo "Linking $dst -> $src"
  [ -z $DRY_RUN ] && ln -s "$src" "$dst"
}

if [ ! -d $TBACK ]; then
  mkdir -p $TBACK
fi

move_files "../dotfiles"
link_scripts
move_files "../fns" ".fns"

echo "Sourcing ~/.zshrc"
source $HOME/.zshrc
