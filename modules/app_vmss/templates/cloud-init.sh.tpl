#!/bin/bash
set -euo pipefail

apt-get update -y
apt-get install -y nginx

cat > /var/www/html/index.html <<HTML
{"tier": "app", "status": "ok", "host": "$(hostname)"}
HTML

systemctl enable nginx
systemctl restart nginx