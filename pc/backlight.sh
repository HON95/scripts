#!/bin/bash

# Set display backlight brightness.

# Usage:
# - Without an argument: Get the current brightness.
# - With an integer: Set to the provided value (limited by min/max).
# - With a relative integer (+/-<n>): Increment/decrement the value (limited by min/max).

# Make sure the current user has write access to the backlight (e.g. using the video group and udev rules).

set -u -o pipefail

BACKLIGHT_DIR="/sys/class/backlight/$(ls -1 /sys/class/backlight)"

if [[ ! -d $BACKLIGHT_DIR ]]; then
    echo "Backlight device does not exist: $BACKLIGHT_DIR" >&2
    exit 1
fi

bright_current=$(cat "$BACKLIGHT_DIR/brightness")
bright_max=$(cat "$BACKLIGHT_DIR/max_brightness")

if [[ $# == 0 ]]; then
    echo "$((100 * $bright_current / $bright_max))%"
elif [[ $1 =~ ^[\+\-]?[0-9]+%?$ ]]; then
    prefix=$(egrep -o '[+-]' <<<$1)
    suffix=$(egrep -o '%' <<<$1)
    value=$(egrep -o '[0-9]+' <<<$1)

    # Calculate percentage
    if [[ $suffix == "%" ]]; then
        value=$(($value * $bright_max / 100))
    fi

    # Calculate relative
    if [[ $prefix != "" ]]; then
        value=$(($bright_current $prefix $value))
    fi

    # Limit
    if (( $value > $bright_max )); then
        value=$bright_max
    elif (( $value < 0 )); then
        value=0
    fi

    # Update
    echo $value > $BACKLIGHT_DIR/brightness
else
    echo "Unknown argument." >&2
    exit 1
fi
