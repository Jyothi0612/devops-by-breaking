# shellcheck shell=bash
svc_selector() { k -n shop get svc web -o go-template='{{range $k,$v := .spec.selector}}{{$k}}={{$v}},{{end}}' | sed 's/,$//'; }

endpoints_ready() {
  [ "$(k -n shop get endpointslices -l kubernetes.io/service-name=web \
        -o jsonpath='{range .items[*].endpoints[*]}{.addresses[0]}{"\n"}{end}' | grep -c .)" -ge 2 ]
}

request_works() {
  k -n shop exec deploy/client -- wget -qO- -T 3 http://web | grep -q 'shop-web: catalogue page OK'
}

# Every pod the Service selects must belong to the web Deployment's ReplicaSet.
backends_owned_by_deployment() {
  local sel owners
  sel="$(svc_selector)"; [ -n "$sel" ] || return 1
  owners="$(k -n shop get pods -l "$sel" \
    -o jsonpath='{range .items[*]}{.metadata.ownerReferences[0].kind}/{.metadata.labels.app}{"\n"}{end}')"
  [ "$(printf '%s\n' "$owners" | grep -c .)" = 2 ] && ! printf '%s\n' "$owners" | grep -qv '^ReplicaSet/web$'
}

selector_is_stable() {
  local sel; sel="$(svc_selector)"
  [ -n "$sel" ] && ! printf '%s' "$sel" | grep -q 'pod-template-hash'
}

check "Service web has at least 2 ready endpoints"                       endpoints_ready
check "A request from the client pod to http://web returns the page"     request_works
check "The Service's backends are exactly the 2 pods of Deployment web"  backends_owned_by_deployment
check "The Service selector does not depend on one ReplicaSet's hash"    selector_is_stable
check "Deployment web still has 2 ready replicas" \
  test "$(k -n shop get deploy web -o jsonpath='{.status.readyReplicas}')" = 2
