# shellcheck shell=bash
srv_sh 'systemctl stop nginx && sed -i "s/8081/80/" /opt/orders-backend/server.py && sed -i "s/User=nobody/User=root/" /etc/systemd/system/orders-backend.service && systemctl daemon-reload && systemctl restart orders-backend'
