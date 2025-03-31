#!/bin/bash
# qbit

# Set the user and config directory
directory="/app/config"
configuration="qbittorrent"
port=61804

while true; do
    /usr/bin/zeDA1p --webui-port=$port --sequential --profile="$directory" --configuration="$configuration"
done