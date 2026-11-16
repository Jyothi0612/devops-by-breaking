# shellcheck shell=bash
check "The API answers 96 simultaneous connections" srv python3 /opt/connection-api/load.py
check "The API still runs as apiworker, not root" srv_sh 'pid=$(systemctl show -p MainPID --value connection-api); test "$(ps -o user= -p "$pid" | tr -d " ")" = apiworker'
check "The running service has a bounded open-file limit between 128 and 4096" srv_sh 'pid=$(systemctl show -p MainPID --value connection-api); n=$(awk "/Max open files/ {print \$4}" /proc/$pid/limits); test "$n" -ge 128 && test "$n" -le 4096'
check "The API remains enabled and active" srv_sh 'systemctl is-enabled -q connection-api && systemctl is-active -q connection-api'
