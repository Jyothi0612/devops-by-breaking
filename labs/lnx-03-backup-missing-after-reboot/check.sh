# shellcheck shell=bash
. "$LAB_DIR/probe.sh"
check "A fresh cron invocation archives the current source data" force_backup
check "crond remains enabled and active" srv_sh 'systemctl is-enabled -q crond && systemctl is-active -q crond'
