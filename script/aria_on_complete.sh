#!/bin/bash

GID="$1"
RPC_SECRET=$(cat "/app/config/.rpc_secret")
RPC_URL="http://localhost:61805/jsonrpc"

# Make the RPC API call to AriaRPC
RESPONSE=$(curl -s -X POST "$RPC_URL" \
  -H "Content-Type: application/json" \
  --data @- <<EOF
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "aria2.tellStatus",
  "params": ["token:$RPC_SECRET", "$GID"]
}
EOF
)

# Extracting File Path from API Response
FILE_PATH=$(echo "$RESPONSE" | jq -r '.result.files[0].path')

if [ -z "$FILE_PATH" ] || [ "$FILE_PATH" = "null" ]; then
  exit 1
fi

# processing path if it contains ' single quote replacing it with '' 2x single quote
# this is needed for the insert command to work
DIR_PATH=$(printf "%s" "$FILE_PATH" | sed "s/'/''/g")

# random delay from 1 to 5 sec
sleep $((RANDOM % 5 + 1))

while true; do
    # logging dir_path to paths.db
    /usr/bin/sqlite3 "/app/config/paths.db" "INSERT INTO paths(path) VALUES('$DIR_PATH');"
    if [[ $? -eq 0 ]]; then
        break
    fi
    sleep 5
done