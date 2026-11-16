# shellcheck shell=bash
k_apply vault-healthy.yaml
k -n vault rollout status deploy/agent --timeout=120s || die "healthy restricted pod failed"
# Replace with a deployment missing PodSecurity restricted fields.
k -n vault delete deploy agent --wait=true
k_apply vault-broken.yaml
wait_for 15 bash -c "docker exec $(k8s_name) kubectl -n vault describe rs -l app=agent 2>/dev/null | grep -q 'violates PodSecurity'" || true
