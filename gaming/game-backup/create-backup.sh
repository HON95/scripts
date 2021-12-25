#!/usr/bin/env bash

# Name: Game Backup Creator
# Description:
# Copies the game save file into a backup directry,
# with date and optional user string in the file name.
# The game save is optionally backed to a pre-determined
# file name as well, to allow quickly restoring the last backup.
# Type: User script
# Version: 1.0.0
# Author: HON

# Changelog:
# 1.0.0: Release

SRC="DS2SOFS0000.sl2"
DST_PREFIX="backup/"
DST_SUFFIX=".sl2"
LAST_ENABLE="true" # Only "true" means true
LAST_DST="${DST_PREFIX}last${DST_SUFFIX}"

DST="$DST_PREFIX$(date +%Y-%m-%d)"
if [ ! -z "$1" ]; then
  DST="$DST-$1"
fi
DST="$DST$DST_SUFFIX"

echo "Backing up to $DST ..."
cp -i "$SRC" "$DST"
if [ "$LAST_ENABLE" = "true" ]; then
  echo "Backing up to $LAST_DST ..."
  cp -f "$SRC" "$LAST_DST"
fi
