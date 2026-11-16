# shellcheck shell=bash
k -n web delete pods -l app=frontend --wait=true
k -n web rollout status deploy/frontend --timeout=120s
