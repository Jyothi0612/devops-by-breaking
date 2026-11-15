# shellcheck shell=bash
pid="$(state_get pid)"

check "/var/log/app is below 80% used" \
  srv_sh '[ "$(df --output=pcent /var/log/app | tail -1 | tr -dc 0-9)" -lt 80 ]'

check "orders-api is still the same running process (it was never restarted or killed)" \
  srv_sh "[ \"\$(systemctl show -p MainPID --value orders-api)\" = \"$pid\" ] && systemctl is-active -q orders-api"

check "/var/log/app/orders.log exists again and new lines are arriving" \
  srv_sh 'f=/var/log/app/orders.log; [ -f "$f" ] && a=$(stat -c %s "$f") && sleep 2 && [ "$(stat -c %s "$f")" -gt "$a" ]'

check "/var/log/app is still the same 64M volume (not unmounted or resized)" \
  srv_sh '[ "$(findmnt -no FSTYPE,SIZE /var/log/app | tr -s " ")" = "tmpfs 64M" ]'
