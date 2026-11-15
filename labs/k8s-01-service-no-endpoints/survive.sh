# shellcheck shell=bash
# A node drain, an upgrade, a crash: pods get replaced. The fix must still hold.
k -n shop delete pods -l app=web --wait=true
k -n shop rollout status deploy/web --timeout=120s
