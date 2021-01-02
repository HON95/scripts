#!/bin/bash

# Name: Cable Tester
# Description:
#   Waits for a cable to be connected to the specified enabled interface,
#   then runs ping and an iPerf3 client test towards the specified server address.
#   If using multiple interfaces, you may spin up a multiple iPerf3 servers and cable tester scripts
#   to test with all interfaces concurrently.
# Type: Script
# Dependencies: iperf3
# Version: 1.0.0
# Author: HON

# Changelog:
# 1.0.0: Initial release.

set -eu

# Disabled localized decimal points etc.
export LC_ALL=C

PING_INTERVAL=0.001
PING_TIMEOUT=0.01
PING_TEST_COUNT=1000
IPERF_TEST_DURATION=1
IPERF_THROUGHPUT_MIN_TOLERANCE=0.9

# Check for deps
dep_errors=0
deps="iperf3"
for dep in $deps; do
if ! command -v "$dep" >/dev/null 2>&1; then
    echo "Dependency \"$dep\" was not found." >&2
        dep_errors=1
    fi
done
if [[ $dep_errors = "1" ]]; then
    exit 1
fi

# Parse args
if [[ $# -lt 4 ]]; then
    echo "Usage: $0 <interface> <speed> <duplex> <server> [--no-repeat]" >&2
    exit 1
fi
interface="$1"
interface_dir="/sys/class/net/$interface"
speed="$2"
duplex="$3"
server="$4"
no_repeat=0
if [[ $# -ge 5 && $5 = "--no-repeat" ]]; then
    no_repeat=1
fi

# Check if root
if [[ $EUID != 0 ]]; then
    echo "Root privileges required." >&2
    exit 1
fi

# Check if interface exists
if [[ ! -d $interface_dir ]]; then
    echo "Interface $interface does not exist." >&2
    exit 1
fi

run_ping() {
    # Run ping $1 times
    count=$1
    # "LANG=C" to disable localized decimal point
    ping -I"$interface" -i"$PING_INTERVAL" -W"$PING_TIMEOUT" -c"$count" -q "$server" 2>/dev/null
}

parse_ping_loss() {
    # Parse ping output from STDIN and print packet loss w/o unit
    tail -n2 | head -n1 | grep -Po '[0-9]+(?=% packet loss)'
}

run_iperf() {
    # Run unidirectional iPerf3 test for $1 seconds, in reverse if $2=="reverse"
    time=$1
    extra_opts=""
    if [[ $# -ge 2 && $2 = "reverse" ]]; then
        extra_opts="$extra_opts --reverse"
    fi
    iperf3 --client="$server" --format=m --time="$time" $extra_opts 2>/dev/null
}

parse_iperf_speed() {
    # Print Mb/s throughput as speed w/o unit
    tail -n3 | head -n1 | grep -Po '[0-9]+(\.[0-9]*)?(?= Mbits/sec)'
}

while true; do
    failure=0

    # Clear and print info
    clear
    echo -e "\e[45m\e[1mCABLE TESTER\e[0m"
    echo
    printf '\e[100m%-20s\e[104m%-20s\e[0m\n' "Interface:" "$interface"
    printf '\e[100m%-20s\e[104m%-20s\e[0m\n' "Speed:" "$speed"
    printf '\e[100m%-20s\e[104m%-20s\e[0m\n' "Duplex:" "$duplex"
    printf '\e[100m%-20s\e[104m%-20s\e[0m\n' "Server:" "$server"
    echo

    # Wait for L2 up, L3 up, speed and duplex
    echo
    echo -e "\e[44mLink\e[0m"
    echo "Waiting for link ..."

    while [[ $(cat "$interface_dir/operstate") != "up" ]]; do
        sleep 0.1
    done
    echo "L2 up."

    while [[ $(run_ping 1 | parse_ping_loss) != 0 ]]; do
        sleep 0.1
    done
    echo "L3 up."

    actual_speed="$(cat "$interface_dir/speed")"
    if [[ $actual_speed = $speed ]]; then
        echo "Speed OK."
    else
        echo -e "\e[31mError: Wrong speed: $actual_speed\e[0m"
        failure=1
    fi

    actual_duplex="$(cat "$interface_dir/duplex")"
    if [[ $actual_duplex = $duplex ]]; then
        echo "Duplex OK."
    else
        echo -e "\e[31mError: Wrong duplex: $actual_duplex\e[0m"
        failure=1
    fi

    # Run ping test
    echo
    echo -e "\e[44mPing\e[0m"
    raw_ping_output=$(run_ping $PING_TEST_COUNT)
    echo "$raw_ping_output" | tail -n2
    ping_loss="$(echo "$raw_ping_output" | parse_ping_loss)"
    if (( $ping_loss == 0 )); then
        echo "No packet loss."
    else
        echo -e "\e[31mError: Non-zero packet loss: $ping_loss%\e[0m"
        failure=1
    fi

    # Run iPerf3 test
    echo
    echo -e "\e[44miPerf3\e[0m"
    min_speed=$(awk -v x="$speed" -v y="$IPERF_THROUGHPUT_MIN_TOLERANCE" 'BEGIN{print x * y}')
    raw_iperf_tx_output=$(run_iperf $IPERF_TEST_DURATION)
    echo "$raw_iperf_tx_output" | tail -n3 | head -n1
    iperf_tx_speed="$(echo "$raw_iperf_tx_output" | parse_iperf_speed)"
    if (( iperf_tx_speed >= min_speed )); then
        echo "Transmit throughput OK."
    else
        echo -e "\e[31mError: Transmit throughput too low: ${iperf_tx_speed}Mb/s\e[0m"
        failure=1
    fi
    raw_iperf_rx_output=$(run_iperf $IPERF_TEST_DURATION reverse)
    echo "$raw_iperf_rx_output" | tail -n3 | head -n1
    iperf_rx_speed="$(echo "$raw_iperf_rx_output" | parse_iperf_speed)"
    if (( iperf_tx_speed >= min_speed )); then
        echo "Recive throughput OK."
    else
        echo -e "\e[31mError: Receive throughput too low: ${iperf_tx_speed}Mb/s\e[0m"
        failure=1
    fi

    # Print summary
    echo
    echo
    if [[ $failure = 0 ]]; then
        echo -e "\e[5m\e[1m\e[42m               \e[0m"
        echo -e "\e[5m\e[1m\e[42m    Success    \e[0m"
        echo -e "\e[5m\e[1m\e[42m               \e[0m"
    else
        echo -e "\e[5m\e[1m\e[41m               \e[0m"
        echo -e "\e[5m\e[1m\e[41m    Failure    \e[0m"
        echo -e "\e[5m\e[1m\e[41m               \e[0m"
    fi
    echo

    # Exit if no repeat
    if [[ $no_repeat = 1 ]]; then
        break
    fi

    # Wait for L2 down
    echo
    echo -e "\e[2mWaiting for cable to be disconnected before repeating ...\e[0m"
    while [[ $(cat "$interface_dir/operstate") = "up" ]]; do
        sleep 0.1
    done

done
