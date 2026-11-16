# shellcheck shell=bash
srv_sh "sed -i 's/StrictModes yes/StrictModes no/' /etc/ssh/sshd_config && systemctl restart sshd"
