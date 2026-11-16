# shellcheck shell=bash
k -n vault delete pods -l app=agent --wait=true
k -n vault rollout status deploy/agent --timeout=120s
