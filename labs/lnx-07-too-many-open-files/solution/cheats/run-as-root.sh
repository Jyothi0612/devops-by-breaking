# shellcheck shell=bash
srv_sh 'sed -i "s/User=apiworker/User=root/; s/LimitNOFILE=64/LimitNOFILE=256/" /etc/systemd/system/connection-api.service; systemctl daemon-reload; systemctl restart connection-api'
