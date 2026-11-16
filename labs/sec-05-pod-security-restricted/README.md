# sec-05 · Deployment creates no pods: violates PodSecurity "restricted"

Security · Level 2 · about 20 min · Maps to: CKS (cluster hardening — Pod Security Standards) · Tags: security

## The ticket

> **Ticket — vault — `deploy/agent` creates no pods**
>
> After a manifest cleanup in namespace `vault`, `deploy/agent` shows `0/1` ready and
> creates no new pods. Namespace `vault` enforces Pod Security Standards `restricted`.

## What you see

```
$ kubectl -n vault describe rs -l app=agent | grep -A 3 Events:
Events:
  Type     Reason        Age   From                   Message
  ----     ------        ----  ----                   -------
  Warning  FailedCreate  1s    replicaset-controller  Error creating: pods "agent-6fdcc4f44d-sm95v" is forbidden: violates PodSecurity "restricted:latest": allowPrivilegeEscalation != false (container "agent" must set securityContext.allowPrivilegeEscalation=false), unrestricted capabilities (container "agent" must set securityContext.capabilities.drop=["ALL"]), runAsNonRoot != true (pod or container "agent" must set securityContext.runAsNonRoot=true), seccompProfile (pod or container "agent" must set securityContext.seccompProfile.type to "RuntimeDefault" or "Localhost")

$ kubectl get ns vault --show-labels
NAME    STATUS   AGE   LABELS
vault   Active   2s    kubernetes.io/metadata.name=vault,pod-security.kubernetes.io/enforce-version=latest,pod-security.kubernetes.io/enforce=restricted
```

## Your goal

`./dbb check` verifies each of these:

- [ ] Namespace `vault` still enforces PodSecurity `restricted`
- [ ] Deployment `agent` has 1 Ready pod

## Predict first

Before you type anything: `kubectl get deploy` succeeds without error, yet no pod
exists. Which controller tries to create the pod and records the admission error?

## Skills you'll practise

Pod Security Admission (`restricted`) · `kubectl describe rs` · `securityContext` (`runAsNonRoot`, `allowPrivilegeEscalation`, `capabilities.drop`, `seccompProfile`)
