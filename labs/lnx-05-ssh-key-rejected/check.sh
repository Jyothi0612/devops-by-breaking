# shellcheck shell=bash
check "The supplied key logs in as deploy" srv_sh '[ "$(/usr/local/bin/lab-ssh)" = deploy ]'
check "Effective SSH configuration keeps StrictModes enabled for deploy" srv_sh '/usr/sbin/sshd -T -C user=deploy,host=localhost,addr=127.0.0.1 | grep -qx "strictmodes yes"'
check "sshd is enabled and active" srv_sh 'systemctl is-enabled -q sshd && systemctl is-active -q sshd'
