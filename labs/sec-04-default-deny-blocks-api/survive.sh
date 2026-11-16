# shellcheck shell=bash
k -n payments delete pods -l app=frontend --wait=true
k -n payments delete pods -l app=api --wait=true
k -n payments rollout status deploy/api --timeout=120s
k -n payments rollout status deploy/frontend --timeout=120s
