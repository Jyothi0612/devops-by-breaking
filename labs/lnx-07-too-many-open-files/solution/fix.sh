# shellcheck shell=bash
srv_sh 'mkdir -p /etc/systemd/system/connection-api.service.d; printf "[Service]\nLimitNOFILE=256\n" > /etc/systemd/system/connection-api.service.d/limits.conf; systemctl daemon-reload; systemctl restart connection-api'
