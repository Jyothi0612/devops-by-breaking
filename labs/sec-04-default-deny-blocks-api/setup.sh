# shellcheck shell=bash
k_apply payments.yaml
k -n payments rollout status deploy/api --timeout=120s || die "api failed to start"
k -n payments rollout status deploy/frontend --timeout=120s || die "frontend failed to start"
k -n payments rollout status deploy/rogue --timeout=120s || die "rogue failed to start"
wait_for 15 k -n payments exec deploy/frontend -- wget -qO- -T 3 http://api >/dev/null || die "healthy frontend could not reach api"
# Security team applied default-deny-all without allow rules for frontend -> api or DNS.
k_apply default-deny.yaml
