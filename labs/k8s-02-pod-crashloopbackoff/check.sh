# shellcheck shell=bash
pod_ready() {
  [ "$(k -n billing get deploy worker -o jsonpath='{.status.readyReplicas}')" = 1 ] \
    && k -n billing wait --for=condition=Ready pod -l app=worker --timeout=5s >/dev/null 2>&1
}

configmap_has_key() {
  [ "$(k -n billing get configmap worker-config -o jsonpath='{.data.QUEUE_URL}')" = "amqp://mq.billing.svc:5672" ]
}

env_in_pod() {
  k -n billing exec deploy/worker -- sh -c '[ "${QUEUE_URL:-}" = "amqp://mq.billing.svc:5672" ]'
}

check "Deployment worker has 1 Ready pod"                                   pod_ready
check "ConfigMap worker-config defines QUEUE_URL"                           configmap_has_key
check "Running worker container receives QUEUE_URL=amqp://mq.billing.svc:5672" env_in_pod

window_elapsed() { [ "$(date +%s)" -ge "$1" ]; }
restarts_stable() {
  local before after
  before="$(k -n billing get pods -l app=worker -o jsonpath='{.items[0].metadata.uid}/{.items[0].status.containerStatuses[0].restartCount}')" || return 1
  wait_for 7 window_elapsed "$(( $(date +%s) + 5 ))" || return 1
  after="$(k -n billing get pods -l app=worker -o jsonpath='{.items[0].metadata.uid}/{.items[0].status.containerStatuses[0].restartCount}')" || return 1
  [ "$before" = "$after" ] && pod_ready
}
check "The worker remains Ready without new restarts during the observation window" restarts_stable
