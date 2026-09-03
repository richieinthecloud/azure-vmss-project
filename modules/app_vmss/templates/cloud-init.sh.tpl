#!/bin/bash
set -euo pipefail

apt-get -o DPkg::Lock::Timeout=600 update -y
apt-get -o DPkg::Lock::Timeout=600 install -y nginx

cat > /var/www/html/index.html <<HTML
{"tier": "app", "status": "ok", "host": "$(hostname)"}
HTML

# Route nginx logs to syslog (facility local7) for the Azure Monitor Agent.
cat > /etc/nginx/conf.d/syslog.conf <<NGINX
access_log syslog:server=unix:/dev/log,facility=local7,tag=nginx,severity=info combined;
error_log  syslog:server=unix:/dev/log,facility=local7,tag=nginx,severity=error;
NGINX

systemctl enable nginx
systemctl restart nginx