# shellcheck shell=bash
k -n billing patch configmap worker-config --type=json -p='[{"op":"remove","path":"/data/QUEUE_URI"},{"op":"add","path":"/data/QUEUE_URL","value":"amqp://mq.billing.svc:5672"}]'
k -n billing delete pods -l app=worker --wait=true
k -n billing rollout status deploy/worker --timeout=120s
