#!/usr/bin/env bash

# Name: Netif No-Address Conditional Resetter
# Description:
# Checks if the network interface has any IPv4 address, and resets it if it does not.
# For network interfaces with dhclient enabled,
# but for some reason does not manage to run dhclient properly if the connection was temporary lost.
# Type: Manual or cron-triggered script
# Version: 1.0.0
# Author: HON

# Cron example: */5 * * * * root bash /opt/misc/netif-reset.sh enp0s8

[ -z "$1" ] && echo "No netif provided"
result=$(ip a sh "$1" | grep -e "^\s*inet ")
if [ -z "$result" ]; then
        ip link set "$1" down
        ip link set "$1" up
fi
