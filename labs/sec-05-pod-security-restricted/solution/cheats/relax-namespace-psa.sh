# shellcheck shell=bash
k label namespace vault pod-security.kubernetes.io/enforce=privileged --overwrite
k -n vault rollout status deploy/agent --timeout=120s
