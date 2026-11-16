# shellcheck shell=bash
if ! out=$(ans ansible-playbook -i inventory.ini deploy.yml 2>&1); then
  printf '%s\n' "$out" >&2
  ansible_diag
  die "initial playbook run failed"
fi
