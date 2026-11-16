# shellcheck shell=bash
ans ansible-playbook -i inventory.ini site.yml >/dev/null || die "initial playbook run failed"
