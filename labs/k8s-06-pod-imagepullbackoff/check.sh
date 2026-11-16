# shellcheck shell=bash
pod_ready() {
  [ "$(k -n web get deploy frontend -o jsonpath='{.status.readyReplicas}')" = 1 ] \
    && k -n web rollout status deploy/frontend --timeout=5s >/dev/null 2>&1 \
    && k -n web wait --for=condition=Ready pod -l app=frontend --timeout=5s >/dev/null 2>&1
}

pinned_tag() {
  [ "$(k -n web get deploy frontend -o jsonpath='{.spec.template.spec.containers[0].image}')" = "nginx:1.29-alpine" ]
}

check "Deployment frontend has 1 Ready pod"                                 pod_ready
check "Deployment frontend runs the pinned nginx:1.29-alpine image"         pinned_tag
