# k8s-04 · Rollout stuck, old pods never replaced

Kubernetes · Level 2 · about 20 min · Maps to: CKA (workloads and scheduling, troubleshooting), CKAD (application deployment)

## The ticket

> **Ticket — checkout — `api` v2 rollout stalled**
>
> Release v2 of `deploy/api` in namespace `checkout` was applied, but the new pod
> stays `0/1 Running` and the old v1 pods are never terminated.

## What you see

```
$ kubectl -n checkout get pods
NAME                   READY   STATUS    RESTARTS   AGE
api-5d45d8b887-xnt54   0/1     Running   0          1s
api-76d49884f6-rt6lh   1/1     Running   0          5s
api-76d49884f6-vq7hn   1/1     Running   0          5s

$ kubectl -n checkout get deploy api
NAME   READY   UP-TO-DATE   AVAILABLE   AGE
api    2/2     1            2           5s
```

## Your goal

`./dbb check` verifies each of these:

- [ ] Deployment `api` in namespace `checkout` has rolled out all 2 updated replicas as Ready
- [ ] Deployment `api` keeps an HTTP `readinessProbe` on port `80`

## Predict first

Before you type anything: the new pod is `Running` (`0/1`), yet Kubernetes refuses
to terminate the old pods. What check must pass before a Deployment replaces old
pods during a rolling update?

## Skills you'll practise

Stalled rolling updates · `readinessProbe` debugging · `kubectl describe pod` · `kubectl rollout status` · `kubectl patch`
