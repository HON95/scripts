#!/usr/bin/env bash

# Name: Disk Space Checker
# Description:
# Checks if any disks are running out of free space, and sends an email notification if so.
# Type: Manual or cron script
# Version: 1.0.0
# Author: HON

EMAIL_ADMIN="root"
ALERT_PERCENT=90
# "|"-separated list of excluded partitions.
# Example: EXTRA_EXCLUDE_LIST="/dev/hdd1|/dev/hdc5"
EXTRA_EXCLUDE_LIST=""

exclude_list="^(?:Filesystem|tmpfs|udev|cdrom"
[ ! -z "$EXTRA_EXCLUDE_LIST" ] && exclude_list+="|${EXTRA_EXCLUDE_LIST}"
exclude_list+=")\s"

df_output=$(df -H | grep -vP "$exclude_list" | awk '{print $5 " " $1  " " $6}')
alerts=""
if [ ! -z "$df_output" ]; then
  while read line ; do
    percent=$(echo $line | awk '{print $1}' | cut -d'%' -f1)
    partition=$(echo $line | awk '{print $2}')
    mountpoint=$(echo $line | awk '{print $3}')
    if [ "$percent" -ge "$ALERT_PERCENT" ] ; then
      alerts+="Partition $partition mounted on $mountpoint is $percent% full.\n"
    fi
  done <<< "$df_output"

fi

if [ ! -z "$alerts" ]; then
  echo -e "Server: $(hostname)\nTime: $(date)\n\n$alerts" | \
  mail -s "[Alert] Disk(s) on $(hostname) running out of space" $EMAIL_ADMIN
fi
