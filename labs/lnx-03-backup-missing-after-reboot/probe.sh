# shellcheck shell=bash
backup_matches() {
  srv_sh 'test -s /var/backups/catalogue.tgz && tar -xOf /var/backups/catalogue.tgz ./orders.txt | cmp -s - /opt/catalogue/data/orders.txt'
}
force_backup() {
  # A fresh source and absent archive reject a manual run or stale backup.
  srv_sh 'systemctl stop crond && date +%s%N > /opt/catalogue/data/orders.txt && rm -f /var/backups/catalogue.tgz /run/cron.reboot && : > /var/log/catalogue-backup.log && systemctl start crond' || return 1
  wait_for 10 backup_matches
}
