# shellcheck shell=bash
site_proxies_backend() {
  local first second
  first="$(srv_sh 'curl -fsS http://127.0.0.1/' 2>/dev/null)" || return 1
  second="$(srv_sh 'curl -fsS http://127.0.0.1/' 2>/dev/null)" || return 1
  printf '%s\n' "$first" | grep -q 'orders-backend: checkout ready req=' || return 1
  printf '%s\n' "$second" | grep -q 'orders-backend: checkout ready req=' || return 1
  [ "$first" != "$second" ]
}

check "HTTP requests to http://127.0.0.1/ return 200 from the live orders-backend" site_proxies_backend
check "nginx is enabled, active, and configured with proxy_pass" \
  srv_sh 'systemctl is-enabled -q nginx && systemctl is-active -q nginx && nginx -T 2>/dev/null | grep -q "proxy_pass"'
check "orders-backend remains enabled and active" \
  srv_sh 'systemctl is-enabled -q orders-backend && systemctl is-active -q orders-backend'
