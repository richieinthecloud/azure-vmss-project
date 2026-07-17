#!/bin/bash
set -euo pipefail

apt-get update -y
apt-get install -y nginx

cat > /var/www/html/index.html <<HTML 
<!DOCTYPE html>
<html>
<head>
    <title>${resume_name} - Azure Resume Project </title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background: #f4f7fb;
            margin: 0;
            padding: 40px;
            color: #222;
        }
        .card {
            background: white;
            padding: 32px;
            border-radius: 12px;
            max-width: 800px;
            margin: 40px auto;
            box-shadow: 0 8px 30px rgba(0,0,0,0.08);
        }
        h1 {
            color: #0078d4;
        }
    </style>
</head>
<body>
    <div class="card">
        <h1>${resume_name}</h1>
        <h2>Azure Cloud Engineering Portfolio</h2>
        <p>This resume website is running on an Azure Virtual Machine Scale Set behind an Application Gateway WAF.</p>
        <p>The infrastructure was deployed using Terraform.</p>
        <p>Backend instances are private and reachable administratively through Azure Bastion.</p>
    </div>
</body>
</html>
HTML

mkdir -p /etc/nginx/snippets
cat > /etc/nginx/snippets/app-proxy.conf <<NGINX
location /api/ {
    proxy_pass http://${internal_lb_frontend_ip}:80/;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
}
NGINX

# nginx only auto-loads *.conf from conf.d at the http block, so the
# location block above must be pulled in explicitly inside the server block.
sed -i '/location \/ {/i\    include /etc/nginx/snippets/app-proxy.conf;' /etc/nginx/sites-available/default

systemctl enable nginx
systemctl restart nginx