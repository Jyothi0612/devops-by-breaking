# shellcheck shell=bash
k -n checkout delete pods -l app=api --wait=true
k -n checkout rollout status deploy/api --timeout=120s
