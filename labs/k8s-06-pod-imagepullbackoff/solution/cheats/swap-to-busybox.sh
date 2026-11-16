# shellcheck shell=bash
k -n web set image deploy/frontend nginx=busybox:1.37
k -n web patch deploy frontend --type='json' -p='[{"op":"add","path":"/spec/template/spec/containers/0/command","value":["sh","-c","httpd -f -p 80 -h /tmp"]},{"op":"remove","path":"/spec/template/spec/containers/0/readinessProbe"}]'
k -n web rollout status deploy/frontend --timeout=120s
