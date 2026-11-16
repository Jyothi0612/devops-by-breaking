# k8s-06 · Solution

## Root cause

`deploy/frontend` was updated to `nginx:1.29-alpin` (a typo missing the trailing `e`
on `alpine`). Because that tag is neither preloaded on the node nor valid, kubelet
fails to pull it (`ErrImagePull` / `ImagePullBackOff`), and the Deployment controller
keeps the previous ReplicaSet's pod running.

For this local lab, Docker Hub pulls are redirected to an unavailable loopback
endpoint and upstream fallback is disabled. The correct pinned image is preloaded;
the misspelled tag is not. This reproduces the pull failure without internet access.
The registry connection error is deliberate lab plumbing, not a second repair task.

## How to find it

List pods in `web` and inspect the failing pod's `Image` field and `Events`:

```sh
kubectl -n web get pods
kubectl -n web describe pod -l app=frontend
kubectl -n web get deploy frontend -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'
```

The captured output in `captures/symptom.txt` shows the new pod `frontend-5565569fdd-zz76r`
in `ErrImagePull` while the old pod remains `Running`.

## Fix

Set the container image back to the pinned `nginx:1.29-alpine` tag and wait for the
rollout:

```sh
kubectl -n web set image deploy/frontend nginx=nginx:1.29-alpine
kubectl -n web rollout status deploy/frontend --timeout=120s
```

Then run `./dbb check` from the repository root.

## Why the obvious fix is wrong

- `use-latest`: switching to `nginx:latest` violates immutable pinned-tag policy (and
  is not preloaded in this offline cluster).
- `swap-to-busybox`: replacing nginx with `busybox:1.37` gets a pod Running, but it is
  not the `nginx:1.29-alpine` application image.

## Prevention

Validate container image references against an allowlist or registry existence check in
CI before merging manifests, and alert on stalled deployments:

```yaml
- alert: KubeDeploymentRolloutStuck
  expr: kube_deployment_status_replicas_unavailable > 0
  for: 10m
  labels:
    severity: warning
  annotations:
    summary: Deployment {{ $labels.namespace }}/{{ $labels.deployment }} has unavailable replicas
```

## In production this looks like

A release PR has a typo in an image tag or digest, or references a tag that CI failed to
push. Kubernetes halts the rolling update at `maxUnavailable` / `maxSurge`, leaving the
new pod in `ImagePullBackOff`.

## Say it in an interview

*AI-drafted practice answer — review and adapt to your own understanding.*

“I'd read the pod events and check the exact image reference before changing credentials
or networking. Here the tag is wrong. I'd use the intended pinned image, wait for the
pod to become Ready, and verify it survives recreation. Switching to latest makes the
deployment less reproducible and doesn't establish that it's the right application.”

## Further reading

- [Kubernetes: Images](https://kubernetes.io/docs/concepts/containers/images/)
- [Kubernetes: Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)

- [K3s: registry mirrors and disabling upstream fallback](https://docs.k3s.io/installation/private-registry)
