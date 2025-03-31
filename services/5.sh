#!/bin/bash

# rclone rcd

while true; do
    /usr/bin/PKpA10 rcd --rc-web-gui --rc-user=admin --rc-pass="${GLOBAL_PASSWORD}" --rc-addr=:61801 --rc-allow-origin="127.0.0.1" --config=/app/config/rclone.conf
done