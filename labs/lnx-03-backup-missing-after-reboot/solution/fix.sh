# shellcheck shell=bash
srv_sh "sed -i 's|archive-catalogue ./data|/usr/local/bin/archive-catalogue /opt/catalogue/data|' /opt/catalogue/backup.sh"
