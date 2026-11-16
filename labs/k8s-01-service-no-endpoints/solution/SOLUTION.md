# k8s-01 · Solution

## Root cause

A Service finds its pods with a **label selector**. The "tidy up labels" change set the
Service selector to `app=web-frontend`, but the pods are labelled `app=web`. Nothing
matches, so the Service has no backend endpoints. The ClusterIP still exists, but
there is no backend to forward to. This lab captures a timeout; other network proxy
implementations or rules may produce an immediate rejection instead. A ClusterIP
is not itself an application listening socket.

Kubernetes reports no error for this. A selector that matches nothing is valid.

## How to find it

```
# 1. Pods are fine. Is the Service connected to them?
kubectl -n shop get endpointslices
NAME        ADDRESSTYPE   PORTS     ENDPOINTS   AGE
web-vbv9r   IPv4          <unset>   <unset>     2s      ← no endpoints

# 2. What is the Service looking for?
kubectl -n shop describe svc web | grep -E "Selector|Endpoints"
Selector:                 app=web-frontend
Endpoints:

# 3. What do the pods actually have?
kubectl -n shop get pods --show-labels
web-5695cf7879-498xs   1/1   Running   app=web,pod-template-hash=5695cf7879,tier=frontend

# 4. Prove the pods themselves work, so you know the only problem is the Service
kubectl -n shop exec deploy/client -- wget -qO- -T 3 http://<pod-ip>
```

The order matters: **endpoints first**. Empty endpoints means a selector or readiness
problem. Endpoints present but requests failing means a port or network problem.

## Fix

Change the Service to select the label the pods really have:

```
kubectl -n shop patch svc web --type merge -p '{"spec":{"selector":{"app":"web"}}}'
```

or `kubectl -n shop edit svc web`. In real life, fix the manifest in git and re-apply,
otherwise the next deploy brings the bug back.

## Why the obvious fix is wrong

- **Relabel the running pods to `app=web-frontend`:** the Deployment selects `app=web`,
  so it stops recognising those pods, starts two new ones, and leaves the relabelled
  pods as orphans that nothing updates or replaces. It works until the next rollout.
- **Delete the Service and `kubectl expose` a pod:** the generated selector includes
  `pod-template-hash`, which changes with every new ReplicaSet. The next deploy breaks it.

A Deployment's `spec.selector` is immutable, and pod labels come from its template. The
Service selector is the thing that was changed, so it is the thing to change back.

## Prevention

Catch it before merge. A CI step that fails when a Service selects nothing:

```
# after applying the manifests and waiting for pods in a preview namespace
for svc in $(kubectl -n "$NS" get svc -o name); do
  sel=$(kubectl -n "$NS" get "$svc" -o go-template='{{range $k,$v := .spec.selector}}{{$k}}={{$v}},{{end}}' | sed 's/,$//')
  [ -z "$sel" ] && continue
  [ -n "$(kubectl -n "$NS" get pods -l "$sel" -o name)" ] || { echo "$svc selects no pods"; exit 1; }
done
```

For production, configure a blackbox exporter HTTP probe from a location that can
reach the Service. For example, with a scrape job named `shop-web-http` and an HTTP
module accepting 2xx responses:

```yaml
- alert: ShopWebUnavailable
  expr: probe_success{job="shop-web-http"} == 0
  for: 5m
```

This is an availability alert, not a diagnosis of empty endpoints. Investigate
EndpointSlices, selectors and readiness after it fires. Monitor exporter health
and missing targets separately; this lab does not install monitoring.

Server-side dry-run validates a request but does not create the candidate pods or
Services. The selection check above needs an applied preview environment.
Generating related labels and selectors from shared values reduces drift; it does
not remove the need to test them.

## In production this looks like

- A load balancer or Ingress returning 503 with "no healthy upstream", while every pod is green.
- A blue/green switch where the Service was pointed at a `version` label that no pod has yet.
- A Helm chart upgrade that renamed a label in the Deployment template but not in the Service.
- On a managed cluster (EKS, GKE, AKS) the cloud load balancer shows zero registered targets.

## Say it in an interview

*AI-drafted practice answer — review and adapt to your own understanding.*

“If pods look healthy but a Service fails, I'd check its EndpointSlices and compare its
selector with the pod labels. Here they don't match. I'd correct the Service manifest
and test through the Service again. Relabelling individual pods is fragile because their
controller recreates them from its template.”

## Further reading

- Kubernetes docs: Service — "Defining a Service" and selectors
- Kubernetes docs: EndpointSlices
- Kubernetes docs: Debug Services
- Kubernetes docs: Labels and Selectors

- [Prometheus blackbox exporter](https://github.com/prometheus/blackbox_exporter)
