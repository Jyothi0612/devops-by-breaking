# shellcheck shell=bash
k -n ops delete pods -l app=watcher --wait=true
k -n ops rollout status deploy/watcher --timeout=120s
