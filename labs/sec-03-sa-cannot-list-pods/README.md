# sec-03 · Forbidden: cannot list resource "pods"

Security · Level 1 · about 15 min · Maps to: CKA (RBAC), CKS (cluster hardening — least privilege) · Tags: security

## The ticket

> **Ticket — ops — `pod-watcher` receives `Forbidden` listing pods**
>
> After an RBAC cleanup in namespace `ops`, `deploy/watcher` (running as
> `ServiceAccount/pod-watcher`) can no longer list pods in `ops`.

## What you see

```
$ kubectl -n ops get pods --as=system:serviceaccount:ops:pod-watcher
Error from server (Forbidden): pods is forbidden: User "system:serviceaccount:ops:pod-watcher" cannot list resource "pods" in API group "" in the namespace "ops"

$ kubectl -n ops auth can-i list pods --as=system:serviceaccount:ops:pod-watcher
no
```

## Your goal

`./dbb check` verifies each of these:

- [ ] `pod-watcher` can list pods in namespace `ops`
- [ ] `pod-watcher` is least-privilege (not `cluster-admin`, cannot list pods cluster-wide)
- [ ] Deployment `watcher` runs with `pod-watcher` ServiceAccount and is Ready

## Predict first

Before you type anything: `ServiceAccount/pod-watcher` exists in `ops`. What two RBAC
objects are needed for a ServiceAccount to hold permissions inside a single namespace?

## Skills you'll practise

Kubernetes RBAC · `kubectl auth can-i --as` · `Role` vs `RoleBinding` · least privilege
