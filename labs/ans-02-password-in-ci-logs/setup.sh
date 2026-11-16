# shellcheck shell=bash
ans ansible-playbook -i inventory.ini deploy.yml >/dev/null || die "initial playbook run failed"
