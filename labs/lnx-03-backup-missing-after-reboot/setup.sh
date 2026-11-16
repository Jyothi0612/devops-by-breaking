# shellcheck shell=bash
. "$LAB_DIR/probe.sh"
srv_sh 'systemctl stop crond; mkdir -p /opt/catalogue/data /var/backups'
srv_put archive-catalogue /usr/local/bin/archive-catalogue
srv_put backup.sh /opt/catalogue/backup.sh
srv_put catalogue-backup /etc/cron.d/catalogue-backup
srv_sh 'chmod 755 /usr/local/bin/archive-catalogue /opt/catalogue/backup.sh; chown root:root /etc/cron.d/catalogue-backup; chmod 644 /etc/cron.d/catalogue-backup; systemctl enable -q crond'
# First demonstrate a healthy scheduled job.
srv_sh "sed -i 's|archive-catalogue ./data|/usr/local/bin/archive-catalogue /opt/catalogue/data|' /opt/catalogue/backup.sh"
force_backup || die "healthy cron backup did not run"
# A release assumes an interactive PATH and working directory.
srv_put backup.sh /opt/catalogue/backup.sh
srv_sh 'chmod 755 /opt/catalogue/backup.sh; cd /opt/catalogue && PATH=/usr/local/bin:/usr/bin:/bin ./backup.sh' || die "manual backup should work"
if force_backup; then die "expected the cron backup to fail"; fi
