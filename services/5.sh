#!/bin/bash

# rclone rcd

while true; do
    /usr/bin/PKpA10 rcd --rc-web-gui --rc-user=admin --rc-pass="${GLOBAL_PASSWORD}" --rc-addr=:61801 --buffer-size=96M --transfers=2 --drive-chunk-size=512M --checkers=2 --ignore-existing --size-only --drive-upload-cutoff=1000T --retries=999 --rc-allow-origin="127.0.0.1" --config=/app/config/rclone.conf
done