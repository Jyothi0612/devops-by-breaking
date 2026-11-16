# shellcheck shell=bash
k -n billing delete pods -l app=worker --wait=true
k -n billing rollout status deploy/worker --timeout=120s
