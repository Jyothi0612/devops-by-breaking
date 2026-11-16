# shellcheck shell=bash
srv_sh 'mkdir -p /opt/orders-backend'
srv_put server.py /opt/orders-backend/server.py
srv_put orders-backend.service /etc/systemd/system/orders-backend.service
srv_put orders.conf /etc/nginx/conf.d/orders.conf
srv_sh 'chmod 644 /etc/nginx/conf.d/orders.conf /etc/systemd/system/orders-backend.service; systemctl daemon-reload; systemctl enable -q --now orders-backend nginx'
wait_for 10 srv_sh 'curl -fsS http://127.0.0.1/ | grep -q "orders-backend: checkout ready"' || die "healthy site did not respond"
# Simulated release: nginx upstream port was changed to 8080, while backend still listens on 8081.
srv_sh "sed -i 's|127.0.0.1:8081|127.0.0.1:8080|' /etc/nginx/conf.d/orders.conf && systemctl reload nginx"
