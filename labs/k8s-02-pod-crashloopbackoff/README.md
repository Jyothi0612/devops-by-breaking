# k8s-02 · Pod in `CrashLoopBackOff`

Kubernetes · Level 1 · about 15 min · Maps to: CKA (workloads and scheduling, troubleshooting), CKAD (application environment, configuration and security)

## The ticket

> **Page — billing — `worker` pod in `CrashLoopBackOff`**
>
> After a ConfigMap update in the `billing` namespace, the `worker` deployment
> stopped becoming Ready and its pod is cycling in `CrashLoopBackOff`.

## What you see

Captured from the broken lab; pod names and ages vary.

```text
$ kubectl -n billing get pods
NAME                      READY   STATUS             RESTARTS     AGE
worker-6b69659bf5-5k4xr   0/1     CrashLoopBackOff   1 (3s ago)   4s

$ kubectl -n billing logs deploy/worker --previous
FATAL: QUEUE_URL is not set
```

## Your goal

`./dbb check` verifies each of these:

- [ ] Deployment `worker` in namespace `billing` has 1 Ready pod
- [ ] ConfigMap `worker-config` defines `QUEUE_URL`
- [ ] The running `worker` container receives `QUEUE_URL=amqp://mq.billing.svc:5672`

The check also observes the repaired worker for five seconds and rejects a new
restart or a replacement pod during that window.

## Predict first

Before you type anything: `worker` uses `envFrom` with `configMapRef: worker-config`.
Why did the container start and crash at runtime instead of failing at pod creation?

## Skills you'll practise

`CrashLoopBackOff` triage · `kubectl logs --previous` · `envFrom` vs `configMapKeyRef` · ConfigMap inspection · pod rollout recovery
