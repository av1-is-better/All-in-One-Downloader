#!/bin/bash

# processing path if it contains ' single quote replacing it with '' 2x single quote
# this is needed for the insert command to work
DIR_PATH=$(printf "%s" "$1" | sed "s/'/''/g")

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