# shellcheck shell=bash
k_apply shop.yaml
k -n shop rollout status deploy/web --timeout=120s
k -n shop rollout status deploy/client --timeout=120s
