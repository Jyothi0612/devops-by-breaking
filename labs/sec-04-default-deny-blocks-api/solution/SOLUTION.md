# sec-04 · Solution

## Root cause

`NetworkPolicy/default-deny-all` isolates every pod in `payments` for both `Ingress`
and `Egress`. Without explicit allow rules, `frontend` cannot resolve `api` via
CoreDNS (UDP/TCP 53 in `kube-system`) and `api` rejects incoming TCP 80 traffic.

## How to find it

Test connectivity from `frontend` and inspect the active NetworkPolicies:

```sh
kubectl -n payments exec deploy/frontend -- wget -qO- -T 3 http://api
kubectl -n payments get networkpolicy
kubectl -n payments describe networkpolicy default-deny-all
```

## Fix

Keep `default-deny-all` and add two scoped policies:
1. `allow-frontend-egress`: allow `app: frontend` egress to `kube-system` on UDP/TCP 53
   and to `app: api` on TCP 80.
2. `allow-api-ingress`: allow `app: api` ingress from `app: frontend` on TCP 80.

Apply `solution/allow.yaml` and run `./dbb check`.

## Why the obvious fix is wrong

- `delete-default-deny`: removing `default-deny-all` lets `frontend` reach `api`, but
  also lets `rogue` reach `api`.
- `allow-all`: adding an allow-all policy opens `api` to `rogue` and defeats
  zero-trust segmentation.

## Prevention

Ship service-specific allow policies alongside `default-deny` in the same Helm chart
or Kustomize base, and test allowed + denied paths in CI.

## In production this looks like

Applying a namespace default-deny egress policy breaks service discovery (`could not
resolve host`) until UDP/TCP 53 to CoreDNS is explicitly allowed.

## Say it in an interview

Author gate pending: write your own 15-second answer after solving blind. Cover why
NetworkPolicies are additive, why DNS egress (port 53) is needed alongside port 80,
and how `rogue` stays blocked.

## Further reading

- [Kubernetes: Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
