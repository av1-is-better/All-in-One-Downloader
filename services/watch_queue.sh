#!/bin/bash

QUEUE_FILE="/app/.temp/queue.txt"
FINISHED_FILE="/app/.temp/finished.txt"
LOG_FILE="/app/.temp/logs.txt"

RCLONE_USERNAME="admin"
RCLONE_PASSWORD="${GLOBAL_PASSWORD}"

REMOTE_PATH="Google:"

# create log file if it doesn't exist
if [[ ! -f "$LOG_FILE" ]]; then
    touch "$LOG_FILE"
fi

# creating QUEUE file if not exist
if [[ ! -f "$QUEUE_FILE" ]]; then
    touch "$QUEUE_FILE"
fi

# creating FINISHED file if not exist
if [[ ! -f "$FINISHED_FILE" ]]; then
    touch "$FINISHED_FILE"
fi

echo "[Queue Watchdog] Started :-)" >> $LOG_FILE

check_rclone_activity() {
    echo "[Queue Watchdog] Rclone Status Checker Started" >> "$LOG_FILE"
    local COUNT=0
    while true; do
        local RESPONSE=$(curl -s -u "${RCLONE_USERNAME}:${RCLONE_PASSWORD}" -X POST "http://127.0.0.1:61801/core/stats")
        local ACTIVE_TRANSFERS=$(echo "$RESPONSE" | jq '.transferring | length')

        if [[ "$ACTIVE_TRANSFERS" -gt 0 ]]; then
            if [[ $COUNT -eq 0 ]]; then
                ((COUNT++))
                echo "[Queue Watchdog] Rclone Transfer in Progress..." >> "$LOG_FILE"
            fi
        else
            echo "[Queue Watchdog] Rclone Job Completed" >> "$LOG_FILE"
            break
        fi
        sleep 10
    done
}


while true; do

    difference=$(($(cat $QUEUE_FILE | wc -l)-$(cat $FINISHED_FILE | wc -l)))

    # Check if queue file exists and is not empty
    if [[ $difference -gt 0 ]]; then
        cat $QUEUE_FILE | tail -n${difference} | while IFS= read -r line; do
            echo "[Queue Watchdog] Processing: $line" >> $LOG_FILE

            # uploading file
            if [[ -f "$line" ]]; then
                echo "[Queue Watchdog] File Detected: $line" >> $LOG_FILE
                BASE_DIR=$(dirname "$line")
                FILE_NAME=$(basename "$line")
                # Make API request
                curl -u "${RCLONE_USERNAME}:${RCLONE_PASSWORD}" -X POST "http://127.0.0.1:61801/operations/movefile" \
                    -H "Content-Type: application/json" \
                    -d @- <<EOF
{
  "srcFs": "$BASE_DIR",
  "srcRemote": "$FILE_NAME",
  "dstFs": "$REMOTE_PATH",
  "dstRemote": "$FILE_NAME",
  "opt": {
    "drive-upload-cutoff": "1000T",
    "buffer-size": "4M",
    "ignoreExisting": true,
    "sizeOnly": true
  }
}
EOF
                sleep 2
                echo "[Queue Watchdog] Rclone Job Created For: $line" >> $LOG_FILE
                check_rclone_activity
            
            # uploading directory
            elif [[ -d "$line" ]];  then
                echo "[Queue Watchdog] Folder Detected: $line" >> $LOG_FILE
                DIR_PATH="$line"
                BASE_NAME=$(basename "${line}")
                MODE="move"

                # Make API request
                curl -u "${RCLONE_USERNAME}:${RCLONE_PASSWORD}" -X POST "http://127.0.0.1:61801/sync/${MODE}" \
                    -H "Content-Type: application/json" \
                    -d @- <<EOF
{
  "srcFs": "$DIR_PATH",
  "dstFs": "${REMOTE_PATH}${BASE_NAME}/",
  "opt": {
    "drive-upload-cutoff": "1000T",
    "buffer-size": "4M",
    "ignoreExisting": true,
    "sizeOnly": true,
    "transfers": 3,
    "checkers": 4
  }
}
EOF
                sleep 2
                echo "[Queue Watchdog] Rclone Job Created For: $line" >> $LOG_FILE
                check_rclone_activity

            else
                echo "[Queue Watchdog] Error Invalid Path: $line" >> $LOG_FILE
            fi


            # Remove the processed file from the queue list
            echo "[Queue Watchdog] Task Completed: $line" >> $LOG_FILE
            echo "$line" >> $FINISHED_FILE
        done
    fi

    # Wait for 5 seconds before the next iteration
    sleep 5
done