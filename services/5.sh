#!/bin/bash

# rclone rcd

while true; do
    # Old Command (Explicitly Set Username and Password)
    # /usr/bin/PKpA10 rcd --rc-web-gui --rc-htpasswd /app/config/.rclone_htpasswd --rc-addr=:61801 --buffer-size=96M --transfers=2 --drive-chunk-size=512M --checkers=2 --ignore-existing --size-only --drive-upload-cutoff=1000T --retries=999 --rc-allow-origin="127.0.0.1" --config=/app/config/rclone.conf
    # New Command (Caddy Will Provide Security Layer)
    /usr/bin/PKpA10 rcd --rc-web-gui --rc-no-auth --rc-addr=127.0.0.1:61801 --buffer-size=96M --transfers=2 --drive-chunk-size=512M --checkers=2 --ignore-existing --size-only --drive-upload-cutoff=1000T --retries=999 --rc-allow-origin="127.0.0.1" --config=/app/config/rclone.conf
done