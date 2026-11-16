# shellcheck shell=bash
k_apply frontend.yaml
k -n web rollout status deploy/frontend --timeout=120s || die "healthy frontend did not become ready"
# A release PR introduced a typo in the image tag (alpin instead of alpine).
k -n web set image deploy/frontend nginx=nginx:1.29-alpin
wait_for 60 bash -c "docker exec $(k8s_name) kubectl -n web get pods -l app=frontend -o jsonpath='{.items[*].status.containerStatuses[*].state.waiting.reason}' 2>/dev/null | grep -Eq 'ImagePullBackOff|ErrImagePull'" || die "expected the broken pod state was not observed"
