# shellcheck shell=bash
no_secret_in_logs() {
  local out
  node_sh 'rm -f /etc/orders-db.env' || return 1
  out="$(ans ansible-playbook -i inventory.ini deploy.yml -vvv 2>&1)" || return 1
  ! printf '%s\n' "$out" | grep -q 'DBB_DEMO_ANSIBLE_PW_NOT_REAL_02'
}

file_deployed() {
  node_sh 'test -f /etc/orders-db.env && grep -qx "DB_PASS=DBB_DEMO_ANSIBLE_PW_NOT_REAL_02" /etc/orders-db.env && [ "$(stat -c %a /etc/orders-db.env)" = "600" ]'
}

check "Verbose playbook run (-vvv) does not leak DBB_DEMO_ANSIBLE_PW_NOT_REAL_02" no_secret_in_logs
check "/etc/orders-db.env is deployed with the secret and mode 0600"                 file_deployed
