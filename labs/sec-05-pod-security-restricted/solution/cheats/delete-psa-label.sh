# shellcheck shell=bash
k label namespace vault pod-security.kubernetes.io/enforce-
k -n vault rollout status deploy/agent --timeout=120s
