#!/usr/bin/env bash

if [ ! -f /etc/patroni.yml ]; then
    echo "Configuration file /etc/patroni.yml not found!"
    exit 1
fi

JQ_PATH=$(command -v jq)
if [[ -z "$JQ_PATH" || ! -x "$JQ_PATH" ]]; then
    echo "jq is not installed or not executable!"
    exit 1
fi

if [[ ! -x /usr/local/bin/patronictl ]]; then
    echo "patronictl not found or not executable!"
    exit 1
fi

NODENAME=$(grep -E "^name:" /etc/patroni.yml | cut -d: -f2 | tr -d '[:blank:]')

if [ -z "$NODENAME" ]; then
    echo "Nodename is blank!"
    exit 1
fi

PATRONICTL_OUT=$(/usr/local/bin/patronictl -c /etc/patroni.yml list --format json 2>/dev/null)

if [ -z "$PATRONICTL_OUT" ]; then
    echo "No patronictl output or command failed!"
    exit 1
fi

LEADER=$(echo "$PATRONICTL_OUT" | jq --raw-output ".[] | select((.Role == \"Leader\") and (.State == \"running\")) | .Member")

if [ "$NODENAME" == "$LEADER" ]; then
    echo "Is leader!"
    exit 0
else
    echo "Is not leader!"
    exit 1
fi