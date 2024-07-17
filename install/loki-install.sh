#!/usr/bin/env bash

# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/tteck/Proxmox/raw/main/LICENSE

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y curl
$STD apt-get install -y sudo
$STD apt-get install -y mc
$STD apt-get install -y unzip
msg_ok "Installed Dependencies"

msg_info "Installing Loki"
RELEASE=$(curl -s https://api.github.com/repos/grafana/loki/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
$STD wget https://github.com/grafana/loki/releases/download/v${RELEASE}/loki-linux-amd64.zip
$STD unzip loki-linux-amd64.zip
chmod a+x loki-linux-amd64
mv loki-linux-amd64 /usr/local/bin/
msg_ok "Installed Loki"

msg_info "Creating Configuration"
mkdir -p /etc/loki
config_path="/etc/loki/config-loki.yml"
echo "auth_enabled: false

server:
  http_listen_port: 3100
  grpc_listen_port: 9096

common:
  path_prefix: /tmp/loki
  storage:
    filesystem:
      chunks_directory: /tmp/loki/chunks
      rules_directory: /tmp/loki/rules
  replication_factor: 1
  ring:
    kvstore:
      store: inmemory

schema_config:
  configs:
    - from: 2020-10-24
      store: boltdb-shipper
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h

ruler:
  alertmanager_url: http://localhost:9093" > $config_path

msg_ok "Created Configuration"

msg_info "Creating Service"
sudo useradd --system loki

service_path="/etc/systemd/system/loki.service"
echo "[Unit]
Description=Loki
Wants=network-online.target
After=network-online.target

[Service]
User=loki
Restart=always
Type=simple
ExecStart=/usr/local/bin/loki-linux-amd64 \
    -config.file /usr/local/bin/config-loki.yml

[Install]
WantedBy=multi-user.target" >$service_path
$STD sudo systemctl enable --now loki
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
rm -rf loki-linux-amd64.zip
msg_ok "Cleaned"
