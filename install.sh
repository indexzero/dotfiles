#!/bin/bash

SCRIPT_PATH=${0%/*}
TFILES="$SCRIPT_PATH/files"
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

  for file in `ls -a $sdir | egrep "^\.\w|^\w"`; do
    if [ -f "$tdir/$file" ]; then
      cp -f "$tdir/$file" "$bdir/$file"
    fi

    if [ -z $DRY_RUN ]; then
      echo "Installing $1/$file"
      cp -f "$sdir/$file" "$tdir/$file"
    fi
  done
}

if [ ! -d $TBACK ]; then
  mkdir -p $TBACK
fi

move_files "files"
move_files "scripts" ".scripts"
echo "Sourcing ~/.profile"
source $HOME/.profile