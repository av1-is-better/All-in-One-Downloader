FROM python:3.11-alpine

# Install required packages
RUN apk update && apk add --no-cache \
    bash \
    build-base \
    p7zip \
    zip \
    unzip \
    curl \
    ttyd \
    caddy \
    jq \
    rclone \
    qbittorrent-nox \
    aria2

# Installing File Browser
RUN curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash