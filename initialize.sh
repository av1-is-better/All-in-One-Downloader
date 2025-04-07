#!/bin/bash
# Setting up Password

# Initializing paths.db file
/usr/bin/sqlite3 "/app/config/paths.db" "CREATE TABLE IF NOT EXISTS paths(path TEXT)"

# Checking Google config
if grep -q '^\[Google\]' /app/config/rclone.conf; then
    echo "Google: remote present in rclone config"
else
    echo "[Error] Google: remote not found in rclone config"
    exit 1
fi

# Checking Access token in rclone config
if grep -q '{"access_token"' /app/config/rclone.conf; then
    echo 'Rclone config is ok.'
else
    echo 'Error: access_token not present in rclone.conf'
    echo "Please modify rclone.conf before creating a container"
    exit 1
fi

# Creating .htpasswd file in /app/config directory
# Recreating .rclone_htpasswd
if [[ -f "/app/config/.rclone_htpasswd" ]]; then
    rm "/app/config/.rclone_htpasswd"
fi
/usr/bin/htpasswd -bc /app/config/.rclone_htpasswd admin "${GLOBAL_PASSWORD}"

# qBit WebUI
QBIT_CONFIG_FILE="/app/config/qBittorrent_qbittorrent/config/qBittorrent.conf"
# Resetting Password in config file
grep -q '^WebUI\\Password_PBKDF2=' "$QBIT_CONFIG_FILE" && sed -i 's|^WebUI\\Password_PBKDF2=.*|HASHPASSWORDHERE|' "$QBIT_CONFIG_FILE"
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
# Resetting Password in config file
grep -q '^rpc-secret=' $ARIA_CONFIG_FILE && sed -i 's|^rpc-secret=.*|GLOBALPASSWORDHERE|' $ARIA_CONFIG_FILE
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
ARIANG_JS_FILE="/var/www/aria/js/aria-ng-c4c1cf5975.min.js"
UNTOUCHED_FILE="/var/www/aria/js/aria-ng-untouched.js"
if [[ -f "$ARIANG_JS_FILE" ]]; then
    if [[ -f "$UNTOUCHED_FILE" ]]; then
        rm "$ARIANG_JS_FILE"
        cp "$UNTOUCHED_FILE" "$ARIANG_JS_FILE"
    fi
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
    /usr/bin/tR2TdY users update admin --password "$GLOBAL_PASSWORD" --config "$FILEBROWSER_CONFIG"
fi

# caddy
echo "Setting Caddy Password"
CADDY_FILE="/app/config/Caddyfile"
UNTOUCHED_CADDY_FILE="/app/config/Untouched_Caddyfile"

if [[ -f "$UNTOUCHED_CADDY_FILE" ]]; then
    if [[ -f "$CADDY_FILE" ]]; then
        rm "$CADDY_FILE"
    fi
    cp "$UNTOUCHED_CADDY_FILE" "$CADDY_FILE"
    HASHED_CADDY_PASSWORD=$(echo $GLOBAL_PASSWORD | /usr/sbin/caddy hash-password)
    sed -i "s|HASHED_PASSWORD|${HASHED_CADDY_PASSWORD//|/\\|}|g" "$CADDY_FILE"
    #BASE64_ENCODED_PASSWORD=$(echo $GLOBAL_PASSWORD | base64 | tr -d '=')
    #sed -i "s|BASE64_ENCODED_PASSWORD_HERE|${BASE64_ENCODED_PASSWORD//|/\\|}|g" "$CADDY_FILE"
else
    echo "[Error] Caddy Untouched File Missing."
    exit 1
fi



