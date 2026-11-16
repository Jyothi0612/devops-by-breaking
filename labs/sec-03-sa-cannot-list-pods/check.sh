# shellcheck shell=bash
can_list_ops_pods() {
  [ "$(k -n ops auth can-i list pods --as=system:serviceaccount:ops:pod-watcher)" = yes ]
}

not_cluster_admin() {
  [ "$(k auth can-i list pods -A --as=system:serviceaccount:ops:pod-watcher)" = no ] \
    && [ "$(k auth can-i '*' '*' --as=system:serviceaccount:ops:pod-watcher)" = no ]
}

watcher_uses_sa() {
  [ "$(k -n ops get deploy watcher -o jsonpath='{.spec.template.spec.serviceAccountName}')" = pod-watcher ] \
    && [ "$(k -n ops get deploy watcher -o jsonpath='{.status.readyReplicas}')" = 1 ]
}

check "pod-watcher can list pods in namespace ops"           can_list_ops_pods
check "pod-watcher is least-privilege (not cluster-admin)"    not_cluster_admin
check "Deployment watcher runs with pod-watcher SA and Ready" watcher_uses_sa
