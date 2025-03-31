#!/bin/sh

# Initializing Password For qbit, aria, filebrowser
# Check if GLOBAL_PASSWORD is set
if [ -z "$GLOBAL_PASSWORD" ]; then
    echo "Error: GLOBAL_PASSWORD environment variable is not set."
    exit 1
fi

# Check if PORT is set
if [ -z "$PORT" ]; then
    echo "Error: PORT environment variable is not set."
    exit 1
fi

/bin/bash /app/initialize.sh

if [[ $? -ne 0 ]]; then
    echo "initialize.sh exited with code $?"
    exit 1
fi

# Start all services
# Directory containing the scripts (change if needed)
SCRIPT_DIR="/app/services"

# Loop through all .sh files in the directory
for script in "$SCRIPT_DIR"/*.sh; do
    # Check if any .sh files exist to avoid errors
    [ -e "$script" ] || continue

    # Make the script executable (if not already)
    chmod +x "$script"

    # Execute the script with nohup
    nohup "$script" >/dev/null 2>&1 &
done

# Keep the container alive
while true; do
    sleep 600
done
