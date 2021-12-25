#!/bin/bash

# Name: Cloudflare DDNS Updater
# Author: Håvard O. Nordstrand (HON95)
# Version: 1.0.0
# Description: DDNS updater for Cloudflare using the Cloudflare API v4.
# License: MIT
# Requirements: curl jq
# Type: Script
# Usage: cloudflare-ddns.sh <config>
# Example cron job: */5 * * * * /opt/scripts/cloudflare-ddns.sh /root/setup/cloudflare-ddns.conf

set -u

# Load config
if [[ $# != 1 ]]; then
    echo "Cloudflare DDNS Updater by HON95"
    echo "Usage: cloudflare-ddns.sh <config>"
    exit 1
fi

CONFIG_PATH="$1"
source "$CONFIG_PATH"

# The config must contain all the variables below
errors=0
[[ -z $ZONE_ID ]] && echo "ZONE_ID missing." >&2 && errors=1
[[ -z $AUTH_KEY ]] && echo "AUTH_KEY missing." >&2 && errors=1
[[ -z $DOMAIN ]] && echo "DOMAIN missing." >&2 && errors=1
[[ -z $TTL ]] && echo "TTL missing." >&2 && errors=1
[[ -z $UPDATE_A ]] && echo "UPDATE_A missing." >&2 && errors=1
[[ -z $UPDATE_AAAA ]] && echo "UPDATE_AAAA missing." >&2 && errors=1
[[ -z $DEBUG ]] && echo "DEBUG missing." >&2 && errors=1
if [[ $errors = "1" ]]; then
    exit 1
fi

# Check dependencies
DEPS="curl jq"
errors=0
for dep in $DEPS; do
    if ! command -v "$dep" >/dev/null 2>&1; then
        echo "Dependency \"$dep\" was not found." >&2
        errors=1
    fi
done
if [[ $errors = "1" ]]; then
    exit 1
fi

declare -A record_ids
declare -A old_addrs
declare -A new_addrs

# Fetch existing records from Cloudflare
fetch_records() {
    endpoint="https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records?name=${DOMAIN}"
    raw_results=$(curl --silent --fail -X GET "${endpoint}" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer ${AUTH_KEY}")
    retval=$?
    [[ $DEBUG = "1" ]] && echo "Raw results: $raw_results"
    if [[ $retval != 0 ]]; then
        echo "Failed to get record ID." >&2
        echo "Endpoint: $endpoint"
        echo "cURL error code: $retval"
        echo "Output: $raw_results"
        exit 1
    fi

    # Get type and ID for all records
    split_results=$(<<<"$raw_results" jq ".result" | jq -c ".[]")
    while IFS= read -r line; do
        record_type=$(<<<"$line" jq -j ".type")
        record_ids[$record_type]=$(<<<"$line" jq -j ".id")
        old_addrs[$record_type]=$(<<<"$line" jq -j ".content")
        [[ $DEBUG = "1" ]] && echo "Found: type=$record_type id=${record_ids[$record_type]} content=${old_addrs[$record_type]}"
    done <<<"$split_results"
}

# Fetches the public address for the specified type (A or AAAA).
fetch_address() {
    # Parameters
    # A or AAAA
    local type=$1

    # Get public IPv4 address
    if [[ $type = "A" ]]; then
        addr_raw=$(dig +tries=3 +time=5 +noall +answer -4 @1.1.1.1 whoami.cloudflare CH TXT)
    else
        addr_raw=$(dig +tries=3 +time=5 +noall +answer -6 @2606:4700:4700::1111 whoami.cloudflare CH TXT)
    fi
    addr=$(<<<$addr_raw egrep "whoami.cloudflare.\s+[^\s]+\s+CH\s+TXT" | cut -f5 | tr -d \")
    if [[ -z $addr ]]; then
        echo "Failed to get public $type address."
        echo "Full output: + $addr_raw"
        return 1
    fi

    [[ $DEBUG = "1" ]] && echo "Public $type address: $addr"
    new_addrs[$type]=$addr
}

# Fetches the public address and then updates the record for the specified type (A or AAAA).
update_record() {
    # Parameters
    # A or AAAA
    local type=$1

    [[ $DEBUG = "1" ]] && echo "Updating $type record ..."

    # Check that record exists in Cloudflare
    if [[ ! -v record_ids[$type] ]]; then
        echo "Record $type for domain \"$DOMAIN\" is set to be updated but does not exist in zone \"$ZONE_ID\"." >&2
        return 1
    fi

    # Check that the public IP address was acquired
    fetch_address $type
    if [[ $? != 0 ]]; then
        return 1
    fi

    [[ $DEBUG = "1" ]] && echo "Updating $type record using id=${record_ids[$type]} old_addr=${old_addrs[$type]} new_addr=${new_addrs[$type]}."

    if [[ ${new_addrs[$type]} == ${old_addrs[$type]} ]]; then
        [[ $DEBUG = "1" ]] && echo "Old and new addresses are equal. Skipping."
        return 0
    fi

    # New record
    new_record=$(cat <<EOF
{
    "type": "$type",
    "name": "$DOMAIN",
    "content": "${new_addrs[$type]}",
    "ttl": $TTL,
    "proxied": false
}
EOF
)
    [[ $DEBUG = "1" ]] && echo "New record: $new_record"

    # Publish
    endpoint="https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records/${record_ids[$type]}"
    output=$(curl --silent --fail -X PUT "${endpoint}" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer ${AUTH_KEY}" \
        -d "$new_record")
    retval=$?
    [[ $DEBUG = "1" ]] && echo "Publish output: $output"
    if [[ $retval != 0 ]]; then
        echo "Failed to publish record." >&2
        echo "Endpoint: $endpoint"
        echo "cURL error code: $retval"
        echo "Output: $output"
        exit 1
    fi
}

fetch_records
[[ $UPDATE_A = "1" ]] && update_record "A"
[[ $UPDATE_AAAA = "1" ]] && update_record "AAAA"
