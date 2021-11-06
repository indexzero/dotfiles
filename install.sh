#!/bin/zsh

SCRIPT_PATH=${0%/*}
TFILES="$SCRIPT_PATH/dotfiles"
TSCRIPTS="$SCRIPT_PATH/scripts"
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

if [ ! -d $TBACK ]; then
  mkdir -p $TBACK
fi

move_files "files"
move_files "scripts" ".scripts"
echo "Sourcing ~/.zshrc"
source $HOME/.zshrc
