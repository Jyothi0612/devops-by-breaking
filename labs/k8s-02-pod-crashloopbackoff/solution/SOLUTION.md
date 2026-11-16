# k8s-02 · Solution

## Root cause

`ConfigMap/worker-config` has the key `QUEUE_URI` instead of `QUEUE_URL`. Because
`deploy/worker` loads environment variables via `envFrom: configMapRef`, Kubernetes
starts the container as long as the ConfigMap exists, even when an expected key is
missing. The entrypoint then exits with `FATAL: QUEUE_URL is not set`, triggering
`CrashLoopBackOff`.

## How to find it

Check pod status, previous container logs, deployment env config, and the ConfigMap:

```sh
kubectl -n billing get pods
kubectl -n billing logs -l app=worker --previous
kubectl -n billing get deploy worker -o yaml
kubectl -n billing get configmap worker-config -o yaml
```

The captured output in `captures/symptom.txt` shows `FATAL: QUEUE_URL is not set` in
the container logs and `QUEUE_URI: amqp://mq.billing.svc:5672` in `worker-config`.

## Fix

Rename `QUEUE_URI` back to `QUEUE_URL` in `ConfigMap/worker-config` and recreate the
pod so it picks up the updated environment:

```sh
kubectl -n billing patch configmap worker-config --type=json \
  -p='[{"op":"remove","path":"/data/QUEUE_URI"},{"op":"add","path":"/data/QUEUE_URL","value":"amqp://mq.billing.svc:5672"}]'
kubectl -n billing delete pods -l app=worker --wait=true
kubectl -n billing rollout status deploy/worker --timeout=120s
```

Then run `./dbb check` from the repository root.

## Why the obvious fix is wrong

- `remove-env-check`: deleting the `QUEUE_URL` check from the deployment command lets
  the pod stay Running, but `worker-config` is still broken and the worker has no
  queue URL.
- `hardcode-in-deployment`: setting `QUEUE_URL` directly on `deploy/worker` bypasses
  `worker-config` instead of fixing the shared ConfigMap.

## Prevention

Validate required ConfigMap keys in CI (or use explicit `configMapKeyRef` with
`optional: false` where missing keys should fail fast at pod creation), and alert on
pod crash loops:

```yaml
- alert: KubePodCrashLooping
  expr: rate(kube_pod_container_status_restarts_total[5m]) > 0
  for: 5m
  labels:
    severity: page
  annotations:
    summary: Pod {{ $labels.namespace }}/{{ $labels.pod }} is crash looping
```

## In production this looks like

A Helm chart or Kustomize overlay renames a key in a ConfigMap while the application
deployment still expects the old variable name, causing an immediate `CrashLoopBackOff`
on the next pod restart.

## Say it in an interview

*AI-drafted practice answer — review and adapt to your own understanding.*

“I'd start with the previous container logs. Here they show QUEUE_URL is missing because
the ConfigMap key was renamed. envFrom loads the keys that exist; it doesn't know what
the application requires. I'd correct the key, recreate the pods to refresh their
environment, and check that restarts stop.”

## Further reading

- [Kubernetes: Configure a Pod to Use a ConfigMap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/)
- [Kubernetes: Debug Pods](https://kubernetes.io/docs/tasks/debug/debug-application/debug-pods/)
