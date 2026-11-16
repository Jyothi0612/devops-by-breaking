# shellcheck shell=bash
k -n billing set env deploy/worker QUEUE_URL="amqp://mq.billing.svc:5672"
k -n billing rollout status deploy/worker --timeout=120s
