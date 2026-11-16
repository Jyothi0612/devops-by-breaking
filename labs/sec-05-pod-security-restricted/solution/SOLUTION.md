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

*AI-drafted practice answer — review and adapt to your own understanding.*

“I'd check ReplicaSet events when a Deployment exists but creates no pods. Here
restricted Pod Security rejects the pod template. I'd add the required security settings
and use a non-root UID that works with the image, then verify the workload starts while
the namespace remains restricted. Weakening enforcement isn't the workload fix.”

## Further reading

- [Kubernetes: Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [Kubernetes: Pod Security Admission](https://kubernetes.io/docs/concepts/security/pod-security-admission/)
