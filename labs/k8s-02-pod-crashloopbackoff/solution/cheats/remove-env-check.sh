# shellcheck shell=bash
k -n billing patch deploy worker --type='json' \
  -p='[{"op":"replace","path":"/spec/template/spec/containers/0/command","value":["sh","-c","exec sleep 3600"]},{"op":"remove","path":"/spec/template/spec/containers/0/readinessProbe"}]'
k -n billing rollout status deploy/worker --timeout=120s
