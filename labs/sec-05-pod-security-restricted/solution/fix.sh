# shellcheck shell=bash
k_apply vault-healthy.yaml
k -n vault rollout status deploy/agent --timeout=120s
