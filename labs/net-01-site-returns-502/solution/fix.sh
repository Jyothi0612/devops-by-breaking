# shellcheck shell=bash
srv_sh "sed -i 's|127.0.0.1:8080|127.0.0.1:8081|' /etc/nginx/conf.d/orders.conf && nginx -t && systemctl reload nginx"
