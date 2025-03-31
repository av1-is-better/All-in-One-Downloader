#!/bin/bash

GID="$1"
RPC_SECRET="${GLOBAL_PASSWORD}"
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

# logging file_path to the list
echo "$FILE_PATH" >> "/app/.temp/queue.txt"