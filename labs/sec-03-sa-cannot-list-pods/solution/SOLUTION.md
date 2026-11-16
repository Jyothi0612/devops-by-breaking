# sec-03 · Solution

## Root cause

`Role/pod-reader` exists in namespace `ops`, but its `RoleBinding` to
`ServiceAccount/pod-watcher` was deleted. Without a `RoleBinding`, `pod-watcher` has
no permissions and the API server rejects `list pods` with `403 Forbidden`.

## How to find it

Test the ServiceAccount's permissions and list RBAC objects in `ops`:

```sh
kubectl -n ops auth can-i list pods --as=system:serviceaccount:ops:pod-watcher
kubectl -n ops get role,rolebinding
```

The captured output in `captures/symptom.txt` shows `Role/pod-reader` present with
no `RoleBinding`.

## Fix

Create a namespace-scoped `RoleBinding` connecting `Role/pod-reader` to
`ServiceAccount/pod-watcher`:

```sh
kubectl -n ops create rolebinding pod-watcher-read \
  --role=pod-reader \
  --serviceaccount=ops:pod-watcher
```

Then run `./dbb check` from the repository root.

## Why the obvious fix is wrong

- `grant-cluster-admin`: binding `cluster-admin` grants full control over the entire
  cluster, violating least privilege.
- `use-default-sa`: removing `serviceAccountName: pod-watcher` from `deploy/watcher`
  leaves `pod-watcher` broken.

## Prevention

Keep `Role` and `RoleBinding` manifests together in GitOps, review RBAC changes with
`kubectl auth can-i` in CI, and alert on `403 Forbidden` spikes in API server audit
logs.

## In production this looks like

A controller or sidecar starts failing with `403 Forbidden` after an RBAC refactor
deleted a `RoleBinding` or renamed a `ServiceAccount`.

## Say it in an interview

Author gate pending: write your own 15-second answer after solving blind. Cover how
`kubectl auth can-i --as` confirms RBAC, why `RoleBinding` (not `ClusterRoleBinding`
to `cluster-admin`) is the right fix, and how you enforce least privilege.

## Further reading

- [Kubernetes: Using RBAC Authorization](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [Kubernetes: Checking API Access](https://kubernetes.io/docs/reference/access-authn-authz/authorization/#checking-api-access)
