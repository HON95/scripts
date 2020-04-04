#!/usr/bin/env bash

# Name: Game Backup Restorer
# Description:
# Restores a specified backup file to the game save file.
# If no file is specified, it restores a pre-determined file.
# The current game save is optionally backed up first.
# Type: User script
# Version: 1.0.0
# Author: HON

DST="DS2SOFS0000.sl2"
LAST_SRC="backup/last.sl2"
PRE_RESTORE_ENABLE="true" # Only "true" means true
PRE_RESTORE_DST="backup/pre-restore.sl2"

src=$LAST_SRC
if [ ! -z "$1" ]; then
  src="$1"
fi

if [ "$PRE_RESTORE_ENABLE" = "true" ]; then
  echo "Backing up to $PRE_RESTORE_DST ..."
  cp -f "$DST" "$PRE_RESTORE_DST"
fi
echo "Restoring backup $src ..."
cp -f "$src" "$DST"