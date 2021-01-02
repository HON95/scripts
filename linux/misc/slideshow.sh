#!/bin/bash
 
# Install fbi and start slideshow in sequential order.
# Must be run as root from a console terminal (not inside a desktop environment).
# Hint: Press Ctrl+Alt+F1 and run "sudo ./slideshow.sh".
 
IMAGES="/home/pi/Pictures/ads/*"
INTERVAL=30
 
if (( $UID != 0 )); then
    echo "Must be run as root."
    exit 1
fi
 
if ! hash fbi 2>/dev/null; then
    apt-get install fbi
fi
 
fbi --noverbose --readahead --autozoom --timeout $INTERVAL $IMAGES
