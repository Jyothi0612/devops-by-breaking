# sec-04 · Default-deny applied, frontend cannot reach the API

Security · Level 2 · about 20 min · Maps to: CKA (services and networking), CKS (cluster hardening — NetworkPolicy) · Tags: security

## The ticket

> **Page — payments — `frontend` cannot reach `http://api`**
>
> Security applied a `default-deny-all` NetworkPolicy to namespace `payments`.
> `frontend` can no longer reach `http://api`, and `rogue` pods in the same
> namespace must remain blocked.

## What you see

```
$ kubectl -n payments get networkpolicy
NAME               POD-SELECTOR   AGE
default-deny-all   <none>         1s

$ kubectl -n payments describe networkpolicy default-deny-all
Name:         default-deny-all
Namespace:    payments
Spec:
  PodSelector:     <none> (Allowing the specific traffic to all pods in this namespace)
  Allowing ingress traffic:
    <none> (Selected pods are isolated for ingress connectivity)
  Allowing egress traffic:
    <none> (Selected pods are isolated for egress connectivity)
  Policy Types: Ingress, Egress
```

## Your goal

`./dbb check` verifies each of these:

- [ ] `frontend` can reach `http://api`
- [ ] `rogue` pod is still blocked from `http://api`
- [ ] `default-deny-all` NetworkPolicy remains in place

## Predict first

Before you type anything: `frontend` calls `http://api` by Service DNS name. If you
only allow egress from `frontend` to `app: api` on port 80, why will `http://api`
still fail?

## Skills you'll practise

Kubernetes `NetworkPolicy` · default-deny + allowlists · egress DNS (UDP/TCP 53) · pod-to-pod least privilege
