#!/bin/bash

# caddy

while true; do
    /usr/sbin/caddy run --config /app/config/Caddyfile --adapter caddyfile
done