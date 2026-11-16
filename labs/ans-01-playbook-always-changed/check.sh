# shellcheck shell=bash
no_changed_when_cheat() {
  ! grep -qE 'changed_when:[[:space:]]*false' "$DBB_WORK/site.yml"
}

converges_and_idempotent() {
  local out
  node_sh 'rm -rf /opt/catalogue' || return 1
  ans ansible-playbook -i inventory.ini site.yml >/dev/null 2>&1 || return 1
  node_sh 'test -d /opt/catalogue && grep -qx "env=prod" /opt/catalogue/app.conf && [ "$(stat -c %a /opt/catalogue/app.conf)" = "644" ]' || return 1
  out="$(ans ansible-playbook -i inventory.ini site.yml 2>&1)" || return 1
  printf '%s\n' "$out" | grep -q 'changed=0' && ! printf '%s\n' "$out" | grep -qE 'changed=[1-9]'
}

check "site.yml uses idempotent modules (no changed_when: false)" no_changed_when_cheat
check "First run creates /opt/catalogue/app.conf and second run reports changed=0" converges_and_idempotent
