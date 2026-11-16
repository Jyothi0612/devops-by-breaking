# shellcheck shell=bash
srv_sh 'printf "server {\n  listen 80 default_server;\n  server_name _;\n  location / { return 200 \"orders-backend: checkout ready req=1\\n\"; }\n}\n" > /etc/nginx/conf.d/orders.conf && systemctl reload nginx'
