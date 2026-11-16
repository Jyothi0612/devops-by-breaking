# shellcheck shell=bash
srv_sh 'printf "apiworker soft nofile 4096\napiworker hard nofile 4096\n" > /etc/security/limits.d/apiworker.conf; systemctl restart connection-api'
