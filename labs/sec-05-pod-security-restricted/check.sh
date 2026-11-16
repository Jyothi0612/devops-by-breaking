# shellcheck shell=bash
ns_is_restricted() {
  [ "$(k get ns vault -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}')" = restricted ]
}

agent_ready() {
  [ "$(k -n vault get deploy agent -o jsonpath='{.status.readyReplicas}')" = 1 ] \
    && [ "$(k -n vault get pods -l app=agent --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l | tr -d ' ')" -ge 1 ] \
    && k -n vault wait --for=condition=Ready pod -l app=agent --timeout=5s >/dev/null 2>&1
}

check "Namespace vault still enforces PodSecurity restricted" ns_is_restricted
check "Deployment agent has 1 Ready pod"                     agent_ready
