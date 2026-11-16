# shellcheck shell=bash
k_apply app.yaml
k -n checkout rollout status deploy/api --timeout=120s || die "healthy v1 rollout failed"
# Release v2 bumped APP_VERSION and accidentally changed the readinessProbe port to 8080.
k -n checkout patch deploy api --type='json' \
  -p='[{"op":"replace","path":"/spec/template/spec/containers/0/env/0/value","value":"v2"},{"op":"replace","path":"/spec/template/spec/containers/0/readinessProbe/httpGet/port","value":8080}]'
wait_for 30 bash -c "[ \"\$(docker exec $(k8s_name) kubectl -n checkout get pods -l app=api --no-headers | wc -l | tr -d ' ')\" -ge 3 ]" || true
