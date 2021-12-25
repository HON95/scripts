#!/usr/bin/env bash

# Name: Google Auth Config Prompter
# Description:
# Checks if the user has configured Google Authenticator MFA,
# and prompts it to do so if it is not.
# Type: profile.d script
# Version: 1.0.5
# Author: HON

# Changelog:
# 1.0.5: Add excluded users and groups
# 1.0.4: Don't run for system users
# 1.0.3: Add prompt to widen terminal, as narrow terminals will mess up QR code
# 1.0.2: Don't run if SUDO
# 1.0.1: Avoid "exit", it breaks profile.d
# 1.0.0: Release

DIR="$HOME/.google_authenticator"
# Arguments:
# t: Time-based tokens
# d: Don't allow token reuse
# u: Don't rate limit
# W: Allow one code before and one after current code
CONFIGURE_CMD="google-authenticator -tduW"
# Max system UID, UIDs equal to or below this value don't run the script
SYS_UID_MAX=999
# Users that cannot run this (space separated list)
EXCLUDED_USERS=""
# Groups that cannot run this (space separated list)
EXCLUDED_GROUPS="no-mfa"

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

# Check dependencies
command -v "google-authenticator" >/dev/null 2>&1 || {
  echo >&2 "Google Authenticator not found."
  return
}

# Exit successfully if it exists
[ ! -f "$DIR" ] || return

# Ask to configure
echo "You have not yet configured Google Authenticator MFA."
while :; do
  read -p "Configure it now? [Y/n] " choice
  case "$choice" in
    "" ) continue=0 ; break ;;
    y|Y ) continue=0 ; break ;;
    n|N ) continue=1 ; break ;;
    * ) ;;
  esac
done

# Exit successfully if user said no
[ $continue -eq 0 ] || return

# Configure
echo "Please add the account to your authenticator app and store the secret key and codes somewhere safe BEFORE saving here."
echo "Also, please widen your terminal window to make the QR code render properly."
read -p "Press enter to continue or CTRL+C to cancel."

$CONFIGURE_CMD
