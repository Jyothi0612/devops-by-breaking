# shellcheck shell=bash
k -n checkout patch deploy api --type='json' \
  -p='[{"op":"replace","path":"/spec/template/spec/containers/0/readinessProbe/httpGet/port","value":80}]'
k -n checkout rollout status deploy/api --timeout=120s
