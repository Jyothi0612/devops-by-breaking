# shellcheck shell=bash
# Empties the deleted file through /proc. Space comes back, but the service is still
# writing to a file nobody can see: there are no logs to read during the next incident.
srv_sh 'pid=$(systemctl show -p MainPID --value orders-api); : > /proc/$pid/fd/3'
