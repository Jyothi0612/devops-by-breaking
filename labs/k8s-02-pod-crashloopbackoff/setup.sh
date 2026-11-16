# shellcheck shell=bash
k_apply billing.yaml
k -n billing rollout status deploy/worker --timeout=120s || die "healthy worker did not become ready"
# A ConfigMap refactor renamed QUEUE_URL to QUEUE_URI.
k -n billing patch configmap worker-config --type=json -p='[{"op":"remove","path":"/data/QUEUE_URL"},{"op":"add","path":"/data/QUEUE_URI","value":"amqp://mq.billing.svc:5672"}]'
k -n billing delete pods -l app=worker --wait=true
wait_for 60 bash -c "docker exec $(k8s_name) kubectl -n billing get pods -l app=worker -o jsonpath='{.items[0].status.containerStatuses[0].state.waiting.reason}' 2>/dev/null | grep -Eq 'CrashLoopBackOff|Error'" || die "expected the broken pod state was not observed"
