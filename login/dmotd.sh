#!/usr/bin/env bash

# Name: DMOTD
# Description:
# Prints optional static MOTD, neofetch info and logged in users.
# Does not print if sudo environment is detected,
# or if the UID is less than or equal to SYS_UID_MAX.
# Type: profile.d script
# Dependencies: neofetch lolcat
# Version: 1.1.6
# Author: HON

# Changelog:
# 1.1.6: Added screen clearing option.
# 1.1.5: Added excluded groups .
# 1.1.4: Added check for required shell features and list of excluded users.
# 1.1.3: Added list of dependencies and change some variables.
# 1.1.2: Added last login.
# 1.1.1: Changed users format (and remove tabs in src).
# 1.1.0: Added static MOTD and make more customizable.
# 1.0.2: Changed to not run for system users.
# 1.0.1: Fixed "exit" commands, which break profile.d.
# 1.0.0: Initial release.

################################################################################

# For boolean options, "yes" (not "YES", 1, true) is the only recognized value for true

# Enable screen clearing before DMOTD
USE_CLEAR="yes"
# Enable MOTD header
USE_MOTD_HEADER="yes"
# Path to logo
MOTD_HEADER_PATH="/etc/logo"
# Enable lolcat for MOTD header
USE_MOTD_HEADER_LOLCAT="yes"
# Enable MOTD footer
USE_MOTD_FOOTER="yes"
# Path to MOTD footer
MOTD_FOOTER_PATH="/etc/motd"
# Enable Neofetch
USE_NEOFETCH="yes"
# Enable Neofetch image
USE_NEOFETCH_IMAGE="no"
# Enable print last login
USE_LAST_LOGIN="yes"
# Enable print logged-in users
USE_USERS="yes"
# Max system UID, UIDs equal to or below this value don't run the script
SYS_UID_MAX=999
# Users that cannot run this (space separated list)
EXCLUDED_USERS=""
# Groups that cannot run this (space separated list)
EXCLUDED_GROUPS="no-dmotd"

################################################################################

# Check some required shell feature is missing
! type "[[" >/dev/null && return

# Check if in sudo
[[ ! -z "$SUDO_USER" ]] && return

# Check if system user
[[ $(id -u) -le $SYS_UID_MAX ]] && return

# Check if excluded user
regex="(.* )?$(id -un)( .*)?"
[[ $EXCLUDED_USERS =~ $regex ]] && return

# Check if in any excluded group
for group in $(id -Gn); do
    regex="(.* )?${group}( .*)?"
    [[ $EXCLUDED_GROUPS =~ $regex ]] && return
done

# Clear
if [[ $USE_CLEAR = "yes" ]]; then
  clear
fi
  
# Pre MOTD
if [[ $USE_MOTD_HEADER = "yes" ]] && [[ -f $MOTD_HEADER_PATH ]]; then
  if [[ $USE_MOTD_HEADER_LOLCAT = "yes" ]]; then
  cat "$MOTD_HEADER_PATH" | lolcat
else
  cat "$MOTD_HEADER_PATH"
fi
  echo
fi

# Neofetch
if [[ $USE_NEOFETCH = "yes" ]]; then
  if [[ $USE_NEOFETCH_IMAGE = "yes" ]]; then
    neofetch
  else
    neofetch --off
  fi
fi

# Last login
if [[ $USE_LAST_LOGIN = "yes" ]]; then
  echo -n "Last login: "
  last_out=$(last -n1 | head -n1)
  if [[ ! -z $last_out ]]; then
    echo "$last_out" | sed -E 's/^([^ ]+ +){2}//' | sed -E 's/^([^ ]+)[ ]+/\1,  /'
  else
    echo "(never)"
  fi
  echo
fi

# Users
if [[ $USE_USERS = "yes" ]]; then
  echo "Users"
  echo "-----"
  who
  echo
fi

# Post MOTD
if [[ $USE_MOTD_FOOTER = "yes" ]] && [[ -f $MOTD_FOOTER_PATH ]]; then
  cat "$MOTD_FOOTER_PATH"
echo
fi
