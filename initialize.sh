#!/bin/bash
# Setting up Password

# qBit WebUI
QBIT_CONFIG_FILE="/app/config/qBittorrent_qbittorrent/config/qBittorrent.conf"
# Check if "HASHPASSWORDHERE" exists in the file
if grep -q "HASHPASSWORDHERE" "$QBIT_CONFIG_FILE"; then
    # Generate hashed password
    QBIT_WEBUI_HASHED_PASSWORD=$(/usr/local/bin/python3.11 "/usr/bin/generate_qbit_hash.py")

    # Ensure it is not empty (avoid corrupting config)
    if [ -n "$QBIT_WEBUI_HASHED_PASSWORD" ]; then
        sed -i "s|HASHPASSWORDHERE|$(printf "%q" "$QBIT_WEBUI_HASHED_PASSWORD")|g" "$QBIT_CONFIG_FILE"
        echo "Password updated successfully in qBittorrent config."
    else
        echo "Error: Failed to generate hashed password."
        exit 1
    fi
fi

# aria RPC config
ARIA_CONFIG_FILE="/app/config/aria2.conf"
# Check if "GLOBALPASSWORDHERE" exists in the file
if grep -q "GLOBALPASSWORDHERE" "$ARIA_CONFIG_FILE"; then
    # Generate hashed password
    RPC_SECRET="rpc-secret=${GLOBAL_PASSWORD}"

    # Ensure it is not empty (avoid corrupting config)
    if [ -n "$RPC_SECRET" ]; then
        sed -i "s|GLOBALPASSWORDHERE|$(printf "%q" "$RPC_SECRET")|g" "$ARIA_CONFIG_FILE"
        echo "Password updated successfully in aria config."
    else
        echo "Error: Failed to generate hashed password."
        exit 1
    fi
fi

# ariang html (replacing port and RPC token in js file)
ARIANG_JS_FILE="/var/www/aria/js/aria-ng-ff0f4540ce.min.js"
if [[ -f $ARIANG_JS_FILE ]]; then
    # Setting PORT
    if grep -q "YOURPORTHERE" "$ARIANG_JS_FILE"; then
        if [ -n "$PORT" ]; then
            sed -i "s|YOURPORTHERE|$(printf "%q" "$PORT")|g" "$ARIANG_JS_FILE"
            echo "PORT updated successfully in aria config."
        else
            echo "[Error] PORT environment variable is not set."
            echo "Please Set PORT env in docker-compose.yml"
            exit 1
        fi
    fi

    # Setting RPC SECRET
    if grep -q "YOURRPCSECRETHERE" "$ARIANG_JS_FILE"; then
        if [ -n "$GLOBAL_PASSWORD" ]; then
            BASE64_ENCODED_PASSWORD=$(echo -n "$GLOBAL_PASSWORD" | base64 | tr -d '\n')
            sed -i "s|YOURRPCSECRETHERE|$BASE64_ENCODED_PASSWORD|g" "$ARIANG_JS_FILE"
            echo "RPC Secret updated successfully in aria config."
        else
            echo "[Error] GLOBAL_PASSWORD environment variable is not set."
            echo "Please Set GLOBAL_PASSWORD env in docker-compose.yml"
            exit 1
        fi
    fi
else
    echo "Ariang js file does not exist: ${ARIANG_JS_FILE}"
    exit 1
fi

# filebrowser
FILEBROWSER_DB="/app/config/filebrowser.db"
FILEBROWSER_CONFIG="/app/config/filebrowser.json"
# Hash the password using bcrypt (Filebrowser requires bcrypt)
HASHED_PASSWORD=$(/usr/bin/tR2TdY hash "$GLOBAL_PASSWORD")
# Initialize Filebrowser database if it doesn't exist
if [ ! -f "$FILEBROWSER_DB" ]; then
    echo "Initializing Filebrowser database..."
    /usr/bin/tR2TdY config init --config "$FILEBROWSER_CONFIG"
    # Set up the admin user with the hashed password
    /usr/bin/tR2TdY users add admin "$GLOBAL_PASSWORD" --perm.admin --config "$FILEBROWSER_CONFIG"
else
    echo "Updating Filebrowser admin password..."
    /usr/bin/tR2TdY users update admin "$GLOBAL_PASSWORD" --config "$FILEBROWSER_CONFIG"
fi