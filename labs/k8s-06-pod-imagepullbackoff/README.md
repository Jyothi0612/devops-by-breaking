# k8s-06 · `ImagePullBackOff`

Kubernetes · Level 1 · about 15 min · Maps to: CKA (workloads and scheduling, troubleshooting), CKAD (application deployment)

## The ticket

> **Ticket — web — `frontend` rollout stuck in `ErrImagePull` / `ImagePullBackOff`**
>
> A release bumped the `frontend` deployment in namespace `web`. The new pod cannot
> pull its image and the rollout is stalled.

## What you see

Captured from the broken lab; pod names and ages vary. The registry is intentionally
unavailable in this offline exercise. Keep its configuration unchanged; the correct
image is already cached on the node.

```text
$ kubectl -n web get pods
NAME                        READY   STATUS         RESTARTS   AGE
frontend-5565569fdd-dvvvj   0/1     ErrImagePull   0          1s
frontend-6947476699-5czx9   1/1     Running        0          3s

$ kubectl -n web get events --field-selector reason=Failed
LAST SEEN   TYPE      REASON   OBJECT                          MESSAGE
1s          Warning   Failed   pod/frontend-5565569fdd-dvvvj   Failed to pull image "nginx:1.29-alpin": failed to pull and unpack image "docker.io/library/nginx:1.29-alpin": failed to resolve reference "docker.io/library/nginx:1.29-alpin": failed to do request: Head "http://127.0.0.1:1/v2/library/nginx/manifests/1.29-alpin?ns=%5BREDACTED%5D": dial tcp 127.0.0.1:1: connect: connection refused
1s          Warning   Failed   pod/frontend-5565569fdd-dvvvj   Error: ErrImagePull
0s          Warning   Failed   pod/frontend-5565569fdd-dvvvj   Error: ImagePullBackOff
```

## Your goal

`./dbb check` verifies each of these:

- [ ] Deployment `frontend` in namespace `web` has 1 Ready pod
- [ ] Deployment `frontend` runs the pinned `nginx:1.29-alpine` image (not `latest`)

## Predict first

Before you type anything: the old pod is still `Running` while the new ReplicaSet
pod is in `ErrImagePull` / `ImagePullBackOff`. Why did Kubernetes keep the old pod up,
and where do you find the exact image name that failed?

## Skills you'll practise

`ErrImagePull` / `ImagePullBackOff` triage · `kubectl describe pod` · rolling update behaviour · `kubectl set image` · pinned image tags
