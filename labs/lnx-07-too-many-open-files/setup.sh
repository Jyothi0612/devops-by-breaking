# shellcheck shell=bash
srv_sh 'useradd -r apiworker; mkdir -p /opt/connection-api'
srv_put connection-api.py /opt/connection-api/server.py
srv_put load.py /opt/connection-api/load.py
srv_put connection-api.service /etc/systemd/system/connection-api.service
# A PAM limit change from an earlier debugging attempt is already present.
srv_sh 'printf "apiworker soft nofile 256\napiworker hard nofile 256\n" > /etc/security/limits.d/apiworker.conf; sed -i "s/LimitNOFILE=64/LimitNOFILE=256/" /etc/systemd/system/connection-api.service; systemctl daemon-reload; systemctl enable -q --now connection-api'
wait_for 10 srv python3 /opt/connection-api/load.py || die "healthy load test failed"
srv_sh 'sed -i "s/LimitNOFILE=256/LimitNOFILE=64/" /etc/systemd/system/connection-api.service; systemctl daemon-reload; systemctl restart connection-api'
wait_for 10 srv systemctl is-active -q connection-api || die "broken service did not start"
