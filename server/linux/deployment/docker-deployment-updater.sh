#!/bin/bash

# Name: Docker Deployment Updater
# Description:
#   Checks if the ID for a Docker Hub image differs from the image used by a container,
#   and runs a script of so.
#   Logs to file instead of outputting errors.
# Type: Script
# Dependencies: docker jq
# Comments:
# - Suggested crontab line: "*/5 * * * * root /srv/app/updater.sh"
# Version: 1.0.1
# Author: HON

# Changelog:
# 1.0.1: Set correct workdir
# 1.0.0: Release

WORKDIR="/srv/app"
CONTAINER="app"
SCRIPT="./deploy.sh"
LOG_FILE="updater.log"
LOCK_DIR="updater.lock"

set -eu

timestamp="$(date "+%Y-%m-%d %H:%M:%S")"

function log {
    echo "$timestamp $1" >> $LOG_FILE
}

cd $WORKDIR

# Lock (mkdir uses atomic check-and-create)
if ! mkdir $LOCK_DIR 2>/dev/null; then
    log "Another update already running"
    exit -1
fi
trap "rm -rf $LOCK_DIR" EXIT

# Check if container is running
if ! docker inspect -f '{{.State.Running}}' $CONTAINER &> /dev/null; then
    log "Container not running"
    exit -1
fi

# Get image repo and tag
repo_plus_tag=$(docker inspect $CONTAINER | jq -r .[0].Config.Image)
if [[ -z $repo_plus_tag ]]; then
    log "Failed to get image repo and tag"
    exit -1
elif ! [[ $repo_plus_tag == *":"* ]]; then
    log "Failed to get image repo and tag, got this instead: $repo_plus_tag"
    exit -1
fi

# Get image ID from running container
current_id=$(docker inspect $CONTAINER | jq -r .[0].Image)
if [[ -z $current_id ]]; then
    log "Failed to get image ID from container"
    exit -1
fi

# Pull image
pull_output=$(docker pull $repo_plus_tag 2>&1)
if (( $? != 0 )); then
    log "Failed to pull image:"
    log "$pull_output"
    exit -1
fi

# Get newest image ID
new_id=$(docker images $repo_plus_tag --quiet --no-trunc)
if [[ -z $new_id ]]; then
    log "Failed to get new ID, image not found locally"
    exit -1
fi

# Compare IDs
if [[ $current_id != $new_id ]]; then
    log "New ID, updating"
else
    exit 0
fi

# Call update script
script_output=$($SCRIPT 2>&1)
if (( $? != 0 )); then
    log "Script failed:"
    log "$script_output"
    exit -1
fi
