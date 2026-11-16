# shellcheck shell=bash
rollout_complete() {
  [ "$(k -n checkout get deploy api -o jsonpath='{.status.updatedReplicas}')" = 2 ] \
    && [ "$(k -n checkout get deploy api -o jsonpath='{.status.readyReplicas}')" = 2 ] \
    && [ "$(k -n checkout get deploy api -o jsonpath='{.status.availableReplicas}')" = 2 ]
}

probe_present() {
  local port
  port="$(k -n checkout get deploy api -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.httpGet.port}')"
  [ "$port" = 80 ]
}

check "Deployment api has rolled out all 2 updated replicas as Ready" rollout_complete
check "Deployment api keeps an HTTP readinessProbe on port 80"       probe_present
