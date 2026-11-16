# shellcheck shell=bash
srv_sh 'useradd -m deploy && passwd -d deploy >/dev/null && mkdir -p /home/deploy/.ssh && ssh-keygen -q -t ed25519 -N "" -C lab-client -f /root/lab-client && ssh-keygen -A && cp /root/lab-client.pub /home/deploy/.ssh/authorized_keys && chown -R deploy:deploy /home/deploy/.ssh && chmod 700 /home/deploy/.ssh && chmod 600 /home/deploy/.ssh/authorized_keys && chmod 755 /home/deploy' || die "could not prepare the SSH fixture"
srv_put sshd_config /etc/ssh/sshd_config
srv_put lab-ssh /usr/local/bin/lab-ssh
srv_sh 'chmod 755 /usr/local/bin/lab-ssh; systemctl enable -q --now sshd' || die "sshd failed to start"
srv_sh 'awk "{print \"127.0.0.1 \" \$1 \" \" \$2}" /etc/ssh/ssh_host_ed25519_key.pub > /root/lab-known-hosts'
wait_for 10 srv /usr/local/bin/lab-ssh || die "healthy SSH key login failed"
# An overly broad permissions change during deployment.
srv chmod 777 /home/deploy
