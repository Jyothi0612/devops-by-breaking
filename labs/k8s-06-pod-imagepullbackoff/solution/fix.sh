# shellcheck shell=bash
k -n web set image deploy/frontend nginx=nginx:1.29-alpine
k -n web rollout status deploy/frontend --timeout=120s
