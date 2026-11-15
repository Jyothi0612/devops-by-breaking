# shellcheck shell=bash
# Healthy system: orders-api logging to a small dedicated log volume.
srv_sh 'mkdir -p /var/log/app /opt/orders && mount -t tmpfs -o size=64m tmpfs /var/log/app'
srv_put orders-api /opt/orders/orders-api
srv_put orders-api.service /etc/systemd/system/orders-api.service
srv_sh 'chmod 755 /opt/orders/orders-api && systemctl daemon-reload && systemctl enable -q --now orders-api'
wait_for 20 srv test -s /var/log/app/orders.log

# The incident: debug logging fills the volume ...
srv_sh 'yes "2026-11-14T02:13:07 DEBUG order payload dump: {\"customer\":\"redacted\",\"items\":[...],\"trace\":\"0f3a9c\"}" | head -c 80M >> /var/log/app/orders.log 2>/dev/null || true'
# ... and the on-call engineer "frees space" the obvious way.
srv_sh 'rm -f /var/log/app/orders.log; printf "%s\n" "df -h" "du -sh /var/log/app/*" "rm -f /var/log/app/orders.log" "df -h" >> /root/.bash_history'

state_set pid "$(srv systemctl show -p MainPID --value orders-api)"
