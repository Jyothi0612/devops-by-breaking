# shellcheck shell=bash
if ! out=$(ans ansible-playbook -i inventory.ini site.yml 2>&1); then
  printf '%s\n' "$out" >&2
  die "initial playbook run failed"
fi
