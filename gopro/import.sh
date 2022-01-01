#!/bin/bash

# Usage and example: See below.
# Description: Import the MP4 files (only!) from the specified GoPro SD card device
#   to the specified directory. The directory is created if it doesn't exist.
# Requirements: rsync

set -eu

if [[ $# != 2 ]]; then
    echo "Usage: $0 <card-dev> <dst-dir>"
    echo "Example: $0 /dev/mmcblk0p1 ~/Desktop/lol"
    exit 0
fi

input_dev="$1"
output_dir="$2"
tmp_mount_dir="/tmp$1"

echo "Input device: $input_dev"
echo "Output directory: $output_dir"
echo "Temporary mountpoint: $tmp_mount_dir"

function cleanup {
    # Unmount device
    if grep -qs " $tmp_mount_dir " /proc/mounts; then
        sudo umount "$tmp_mount_dir"
    fi

    # Remove tmp mountpoint
    if [[ -e $tmp_mount_dir ]]; then
        rmdir "$tmp_mount_dir"
    fi
}
trap cleanup EXIT

# Preconditions

if [[ $input_dev != /dev/* ]]; then
    echo
    echo "Invalid device path, use absolute device path please." >&2
    exit 1
fi

if [[ ! -e $input_dev ]]; then
    echo
    echo "Input device doesn't exist." >&2
    exit 1
fi

if [[ -e $output_dir ]]; then
    echo
    echo "Output directory already exists." >&2
    exit 1
fi

if [[ -e $tmp_mount_dir ]]; then
    echo
    echo "Temporary mountpoint already exists." >&2
    exit 1
fi

# Main

echo
echo "Creating temporary mounting directory ..."
mkdir -p "$tmp_mount_dir"

echo
echo "Mounting input device ..."
sudo mount "$input_dev" "$tmp_mount_dir"

echo
echo "Creating output directory ..."
mkdir -p "$output_dir"

echo
echo "Finding video files ..."
# GoPro and video specific
src_files=("$tmp_mount_dir/DCIM/100GOPRO/"*.MP4)
echo "Found ${#src_files[@]} video files:"
for x in "${src_files[@]}"; do
    echo "- $(basename "$x") [$(du -h "$x" | cut -f1)B]"
done

echo
echo "Copying video files ..."
rsync -a --progress "${src_files[@]}" "$output_dir"

echo
echo "Success!"
