# shellcheck shell=bash
k_apply ops.yaml
k -n ops rollout status deploy/watcher --timeout=120s || die "healthy watcher did not start"
[ "$(k -n ops auth can-i list pods --as=system:serviceaccount:ops:pod-watcher)" = yes ] || die "healthy RBAC failed"
# A cleanup PR removed the RoleBinding for pod-watcher.
k -n ops delete rolebinding pod-watcher-read
