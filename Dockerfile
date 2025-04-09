FROM kunu89/aio-alpine

# Copy all bin files to /usr/bin/
COPY bin/ /usr/bin/

# Creating Symbolic Link with Obfuscated Names
RUN ln -s "/usr/bin/qbittorrent-nox" "/usr/bin/zeDA1p" #qb
RUN ln -s "/usr/local/bin/filebrowser" "/usr/bin/tR2TdY" #fb
RUN ln -s "/usr/bin/rclone" "/usr/bin/PKpA10" #rc
RUN ln -s "/usr/bin/aria2c" "/usr/bin/MUw428" #ar
RUN ln -s "/usr/bin/ttyd" "/usr/bin/uG37Yq" #tty

RUN chmod +x /usr/bin/zeDA1p #qb
RUN chmod +x /usr/bin/tR2TdY #fb
RUN chmod +x /usr/bin/PKpA10 #rc
RUN chmod +x /usr/bin/MUw428 #ar
RUN chmod +x /usr/bin/uG37Yq #tty

RUN chmod +x /usr/bin/generate_qbit_hash.py #py

# Create a directory for the application
WORKDIR /app
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Copying Script (Bash Scripts)
RUN mkdir -p "/app/script"
COPY script/ /app/script/
RUN chmod -R +x /app/script/*

# Copying Services (nohup bash files)
RUN mkdir -p "/app/services"
COPY services/ /app/services/
RUN chmod -R +x /app/services/*

# Copying Config Files
RUN mkdir -p /app/config
COPY config/ /app/config/
RUN mkdir -p /app/downloads/.torrent

# Copying VueTorrent HTML
COPY web-ui/vue-torrent.zip /app/vue-torrent.zip
RUN unzip /app/vue-torrent.zip -d /var/www/
RUN rm /app/vue-torrent.zip

# Copying AriaNG-HTML
COPY web-ui/aria.zip /app/aria.zip
RUN unzip /app/aria.zip -d /var/www/
RUN rm /app/aria.zip

# Copying Rclone_RCD_WebUI-HTML
COPY web-ui/rcd-webui.zip /app/rcd-webui.zip
RUN unzip /app/rcd-webui.zip -d /var/www/
RUN rm /app/rcd-webui.zip

# Copying Pixel-HTML
COPY web-ui/pixel.zip /app/pixel.zip
RUN unzip /app/pixel.zip -d /var/www/
RUN rm /app/pixel.zip

# Copying Pixel-HTML
COPY web-ui/google.zip /app/google.zip
RUN unzip /app/google.zip -d /var/www/
RUN rm /app/google.zip

# Copying homer
RUN mkdir -p /var/www/homer
COPY homer/ /var/www/homer/

# Crating /app/.temp dir for temporary purposes like storing
# links and list of files/folders that needs to be uploaded
RUN mkdir -p /app/.temp

# Create a directory for the application
COPY initialize.sh /app/initialize.sh
RUN chmod +x /app/initialize.sh

# Installing Node Modules For API Server
RUN chmod +x /app/script/api/install.sh
RUN /bin/bash /app/script/api/install.sh

# Use entrypoint to start services and keep container alive
ENTRYPOINT ["/bin/bash", "/app/entrypoint.sh"]
