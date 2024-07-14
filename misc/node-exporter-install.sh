#!/usr/bin/env bash

# Copyright (c) 2024 pbleisch
# Author: pbleisch (pbleisch)
# License: MIT
# https://github.com/tteck/Proxmox/raw/main/LICENSE

RD=$(echo "\033[01;31m")
YW=$(echo "\033[33m")
GN=$(echo "\033[1;92m")
CL=$(echo "\033[m")
BFR="\\r\\033[K"
HOLD="-"
CM="${GN}✓${CL}"
CROSS="${RD}✗${CL}"

set -euo pipefail
shopt -s inherit_errexit nullglob

msg_info() {
  local msg="$1"
  echo -ne " ${HOLD} ${YW}${msg}..."
}

msg_ok() {
  local msg="$1"
  echo -e "${BFR} ${CM} ${GN}${msg}${CL}"
}

msg_error() {
  local msg="$1"
  echo -e "${BFR} ${CROSS} ${RD}${msg}${CL}"
}


msg_info "Installing Dependencies"
$STD apt-get install -y curl
$STD apt-get install -y sudo
msg_ok "Installed Dependencies"

msg_info "Installing Node Exporter"
RELEASE=$(curl -s https://api.github.com/repos/prometheus/node_exporter/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
$STD wget https://github.com/prometheus/node_exporter/releases/download/v${RELEASE}/node_exporter-${RELEASE}.linux-amd64.tar.gz
$STD tar -xvf node_exporter-${RELEASE}.linux-amd64.tar.gz
cd node_exporter-${RELEASE}.linux-amd64
mv node_exporter /usr/local/bin/
msg_ok "Installed Node Exporter"

msg_info "Creating Service"
service_path="/etc/systemd/system/node_exporter.service"
echo "[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=root
Restart=always
Type=simple
ExecStart=/usr/local/bin/node_exporter 

[Install]
WantedBy=multi-user.target" >$service_path
$STD sudo systemctl enable --now node_exporter
msg_ok "Created Service"

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
rm -rf ../node_exporter-${RELEASE}.linux-amd64 ../node_exporter-${RELEASE}.linux-amd64.tar.gz
msg_ok "Cleaned"
