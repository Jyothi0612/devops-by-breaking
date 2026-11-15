# shellcheck shell=bash
srv_sh 'kill -9 "$(systemctl show -p MainPID --value orders-api)"'
