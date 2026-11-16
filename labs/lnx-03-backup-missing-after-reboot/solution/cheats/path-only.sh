# shellcheck shell=bash
srv_sh "sed -i 's|PATH=/usr/bin:/bin|PATH=/usr/local/bin:/usr/bin:/bin|' /etc/cron.d/catalogue-backup"
