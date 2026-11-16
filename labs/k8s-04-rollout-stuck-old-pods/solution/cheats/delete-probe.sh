# shellcheck shell=bash
k -n checkout patch deploy api --type='json' \
  -p='[{"op":"remove","path":"/spec/template/spec/containers/0/readinessProbe"}]'
k -n checkout rollout status deploy/api --timeout=120s
