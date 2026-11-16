# shellcheck shell=bash
frontend_reaches_api() {
  k -n payments exec deploy/frontend -- wget -qO- -T 3 http://api | grep -q 'Welcome to nginx'
}

rogue_is_blocked() {
  ! k -n payments exec deploy/rogue -- wget -qO- -T 2 http://api >/dev/null 2>&1
}

default_deny_kept() {
  local types
  types="$(k -n payments get networkpolicy default-deny-all -o jsonpath='{.spec.policyTypes[*]}' 2>/dev/null)" || return 1
  printf '%s' "$types" | grep -q 'Ingress' && printf '%s' "$types" | grep -q 'Egress'
}

check "frontend can reach http://api"                       frontend_reaches_api
check "rogue pod is still blocked from http://api"          rogue_is_blocked
check "default-deny-all NetworkPolicy remains in place"     default_deny_kept
