#!/usr/bin/env bash

BUCKET_ROOT_DIR="/media/alpha/s3/"
LOG_DIR="/media/alpha/s3-sync-logs/"

if [ "$#" -ne 1 ]; then
        echo "Name: hon-aws-s3-sync"
        echo "Version: 1.0.0-SNAPSHOT"
        echo "Syntax: hon-aws-s3-sync <name>"
        echo "Description:"
        echo "Synchronizes S3 bucket <name> with folder ${BUCKET_ROOT_DIR}<name>, using AWS-CLI profile <name>."
        echo "Logs are stored in ${LOG_DIR}."
        echo
        exit 0
fi

NAME="$1"
BUCKET_DIR="${BUCKET_ROOT_DIR}${NAME}"
TIMESTAMP="$(date +%Y-%m-%dT%H%M%z)"
LOG_FILE="${LOG_DIR}$NAME-$TIMESTAMP"

function run {
        set -e

        echo "Profile: $NAME"
        echo "S3 bucket: $NAME"
        echo "Local directory: $BUCKET_DIR"
        echo "Log file: $LOG_FILE"
        echo

        mkdir -p "$BUCKET_ROOT_DIR"
        cd "$BUCKET_ROOT_DIR"
        mkdir -p "$BUCKET_DIR"

        echo "Files to download:"
        aws s3 sync --profile "$NAME" --dryrun "s3://$NAME" "$BUCKET_DIR"
        echo

        echo "Files to upload:"
        aws s3 sync --profile "$NAME" --dryrun "$BUCKET_DIR" "s3://$NAME"
        echo

        read -p "Press enter to continue or CTRL+C to cancel"
        echo

        echo "Downloading ..."
        aws s3 sync --profile "$NAME" "s3://$NAME" "$BUCKET_DIR"
        echo

        echo "Uploading ..."
        aws s3 sync --profile "$NAME" "$BUCKET_DIR" "s3://$NAME"
        echo

        echo "Done."
}

[[ $(aws configure --profile "$NAME" list) && $? -ne 0 ]] && exit 1

mkdir -p "$LOG_DIR"
touch "$LOG_FILE"
run |& tee "$LOG_FILE"
