# shellcheck shell=bash
k -n ops patch deploy watcher --type='json' -p='[{"op":"remove","path":"/spec/template/spec/serviceAccountName"}]'
k -n ops rollout status deploy/watcher --timeout=120s
