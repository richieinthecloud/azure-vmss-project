#!/bin/bash
set -euo pipefail

apt-get -o DPkg::Lock::Timeout=600 update -y
apt-get -o DPkg::Lock::Timeout=600 install -y nginx

cat > /var/www/html/index.html <<HTML
{"tier": "app", "status": "ok", "host": "$(hostname)"}
HTML

systemctl enable nginx
systemctl restart nginx