# sec-05 · Solution

## Root cause

`deploy/agent` has no `securityContext`, so its ReplicaSet's pod template runs as
root with default capabilities and no `seccompProfile`. Namespace `vault` enforces
`pod-security.kubernetes.io/enforce: restricted`, so Pod Security Admission rejects
every pod creation attempt from the ReplicaSet.

## How to find it

Inspect the Deployment, ReplicaSet events, and namespace labels:

```sh
kubectl -n vault get pods
kubectl -n vault describe rs -l app=agent
kubectl get ns vault --show-labels
```

The captured `FailedCreate` event in `captures/symptom.txt` lists all four missing
`restricted` requirements.

## Fix

Keep `vault` at `restricted` and add the required `securityContext` fields to
`deploy/agent` (see `files/vault-healthy.yaml`), including `runAsUser: 1000` because
`busybox:1.37` defaults to root (`UID 0`):

```yaml
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    seccompProfile:
      type: RuntimeDefault
  containers:
    - name: agent
      securityContext:
        allowPrivilegeEscalation: false
        capabilities:
          drop: ["ALL"]
```

Apply and run `./dbb check`.

## Why the obvious fix is wrong

- `relax-namespace-psa`: changing `enforce` to `privileged` lets the root pod run,
  but weakens the namespace's security policy.
- `delete-psa-label`: removing the PodSecurity label disables enforcement for the
  entire namespace.

## Prevention

Enforce `restricted` Pod Security Admission on application namespaces, and run
policy checks (`kubescape` / `kyverno` / `kube-linter`) in CI before applying
manifests.

## In production this looks like

A new Deployment applies cleanly (`kubectl apply` succeeds) because the Deployment
controller creates pods asynchronously, and the failure only appears in ReplicaSet
events (`FailedCreate`).

## Say it in an interview

Author gate pending: write your own 15-second answer after solving blind. Cover why
`kubectl apply` on a Deployment succeeds while the ReplicaSet fails, the four
`restricted` fields, and why relaxing the namespace label is the wrong fix.

## Further reading

- [Kubernetes: Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [Kubernetes: Pod Security Admission](https://kubernetes.io/docs/concepts/security/pod-security-admission/)
