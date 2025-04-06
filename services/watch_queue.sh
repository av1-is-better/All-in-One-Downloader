#!/bin/bash

LOG_FILE="/app/.temp/logs.txt"
DB_PATH="/app/config/paths.db"

RCLONE_USERNAME="admin"
RCLONE_PASSWORD="${GLOBAL_PASSWORD}"

REMOTE_PATH="Google:"

# create log file if it doesn't exist
if [[ ! -f "$LOG_FILE" ]]; then
    touch "$LOG_FILE"
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
        sleep 20
    done
}

call_upload_file_api() {
    local RCLONE_USERNAME="$1"
    local RCLONE_PASSWORD="$2"
    local BASE_DIR="$3"
    local FILE_NAME="$4"
    local REMOTE_PATH="$5"

    # Make API request
    curl -u "${RCLONE_USERNAME}:${RCLONE_PASSWORD}" -X POST "http://127.0.0.1:61801/operations/movefile" \
        -H "Content-Type: application/json" \
        -d @- <<EOF
{
  "srcFs": "$BASE_DIR",
  "srcRemote": "$FILE_NAME",
  "dstFs": "$REMOTE_PATH",
  "dstRemote": "$FILE_NAME",
  "_async": true,
  "_config": {
    "BufferSize": "96M",
    "IgnoreExisting": true,
    "SizeOnly": true,
    "Retries": 999
  }
}
EOF
}

call_upload_folder_api() {
    local RCLONE_USERNAME="$1"
    local RCLONE_PASSWORD="$2"
    local DIR_PATH="$3"
    local REMOTE_PATH="$4"
    local BASE_NAME="$5"
    

    curl -u "${RCLONE_USERNAME}:${RCLONE_PASSWORD}" -X POST "http://127.0.0.1:61801/sync/move" \
        -H "Content-Type: application/json" \
        -d @- <<EOF
{
  "srcFs": "$DIR_PATH",
  "dstFs": "${REMOTE_PATH}${BASE_NAME}/",
  "_async": true,
  "_config": {
    "BufferSize": "96M",
    "IgnoreExisting": true,
    "SizeOnly": true,
    "Retries": 999,
    "Transfers": 2,
    "Checkers": 4
  }
}
EOF
}


while true; do
    # Check if paths exists and is not empty
    if (( $( /usr/bin/sqlite3 "$DB_PATH" "SELECT COUNT(path) FROM paths" ) != 0 )); then
        /usr/bin/sqlite3 "$DB_PATH" "SELECT path FROM paths LIMIT 1" | while IFS= read -r line; do
            echo "[Queue Watchdog] Processing: $line" >> $LOG_FILE

            # uploading file
            if [[ -f "$line" ]]; then
                echo "[Queue Watchdog] File Detected: $line" >> $LOG_FILE
                BASE_DIR=$(dirname "$line")
                FILE_NAME=$(basename "$line")
                # Checking Whether it's a TV Show or Movie
                if echo $FILE_NAME | tr '[:upper:]' '[:lower:]' | grep -E '480p|720p|1080p|2160p|web(-dl|rip)?|bluray|ddp2\.0|ddp5\.1|x265|h\.264|hevc|h264|remux|h 264|h265'; then
                    if echo $FILE_NAME | grep -q -E 'S[0-9]{1,3}E' || echo $FILE_NAME | grep -q -E 'S[0-9]{1,3}'; then
                        # This is a TV Show (Uploading in a Folder Named T)
                        REMOTE_PATH="Google:T"
                    elif echo $FILE_NAME | grep -q -E '\.[0-9]{1,4}\.' || echo $FILE_NAME | grep -q -E '\.[0-9]{1,4}' || echo $FILE_NAME | grep -q -E ' [0-9]{1,4} ' || echo $FILE_NAME | grep -q -E ' [0-9]{1,4}'; then
                        # This is a Movie (Uploading in a Folder Named M)
                        REMOTE_PATH="Google:M"
                    else
                        # Uploading in Root Path
                        REMOTE_PATH="Google:"
                    fi
                else
                    # Uploading in Root Path
                    REMOTE_PATH="Google:"
                fi

                # Make API request
                call_upload_file_api "$RCLONE_USERNAME" "$RCLONE_PASSWORD" "$BASE_DIR" "$FILE_NAME" "$REMOTE_PATH"
                sleep 5
                echo "[Queue Watchdog] Rclone Job Created For: $line" >> $LOG_FILE
                check_rclone_activity
            
            # uploading directory
            elif [[ -d "$line" ]];  then
                echo "[Queue Watchdog] Folder Detected: $line" >> $LOG_FILE
                DIR_PATH="$line"
                BASE_NAME=$(basename "${line}")
                MODE="move"
                # Checking Whether it's a TV Show or Movie
                if echo $BASE_NAME | tr '[:upper:]' '[:lower:]' | grep -E '480p|720p|1080p|2160p|web(-dl|rip)?|bluray|ddp2\.0|ddp5\.1|x265|h\.264|hevc|h264|remux|h 264|h265'; then
                    if echo $BASE_NAME | grep -q -E 'S[0-9]{1,3}E' || echo $BASE_NAME | grep -q -E 'S[0-9]{1,3}'; then
                        # This is a TV Show (Uploading in a Folder Named T)
                        REMOTE_PATH="Google:T/"
                    elif echo $BASE_NAME | grep -q -E '\.[0-9]{1,4}\.' || echo $BASE_NAME | grep -q -E '\.[0-9]{1,4}' || echo $BASE_NAME | grep -q -E ' [0-9]{1,4} ' || echo $BASE_NAME | grep -q -E ' [0-9]{1,4}'; then
                        # This is a Movie (Uploading in a Folder Named M)
                        REMOTE_PATH="Google:M/"
                    else
                        # Uploading in Root Path
                        REMOTE_PATH="Google:"
                    fi
                else
                    # Uploading in Root Path
                    REMOTE_PATH="Google:"
                fi

                # Make API request
                call_upload_folder_api "$RCLONE_USERNAME" "$RCLONE_PASSWORD" "$DIR_PATH" "$REMOTE_PATH" "$BASE_NAME"
                sleep 5
                echo "[Queue Watchdog] Rclone Job Created For: $line" >> $LOG_FILE
                check_rclone_activity

            else
                echo "[Queue Watchdog] Error Invalid Path: $line" >> $LOG_FILE
            fi


            # Remove the processed path from the database
            safe_name=$(printf "%s" "$line" | sed "s/'/''/g")
            /usr/bin/sqlite3 "$DB_PATH" "DELETE FROM paths WHERE path='${safe_name}'"
        done
    fi

    # Wait for 5 seconds before the next iteration
    sleep 5
done
