# k8s-04 · Solution

## Root cause

Release v2 changed `deploy/api`'s `readinessProbe.httpGet.port` from `80` to `8080`,
while nginx still listens on port `80`. Because the new pod never becomes Ready, the
Deployment controller keeps the old v1 ReplicaSet's pods running to preserve
availability.

## How to find it

Inspect pods, deployment rollout status, and pod probe events:

```sh
kubectl -n checkout get pods
kubectl -n checkout get deploy api
kubectl -n checkout describe pod -l app=api
```

The captured output in `captures/symptom.txt` shows the new pod probing `http://:8080/`
while the old pods probe `http://:80/`.

## Fix

Restore `readinessProbe.httpGet.port` to `80` on `deploy/api` and wait for the rollout:

```sh
kubectl -n checkout patch deploy api --type='json' \
  -p='[{"op":"replace","path":"/spec/template/spec/containers/0/readinessProbe/httpGet/port","value":80}]'
kubectl -n checkout rollout status deploy/api --timeout=120s
```

Then run `./dbb check` from the repository root.

## Why the obvious fix is wrong

- `delete-probe`: removing `readinessProbe` lets pods become Ready immediately, but
  removes readiness gating so traffic can hit unready pods.
- `scale-to-one`: scaling replicas down hides the rollout without fixing the broken
  v2 pods and breaks the 2-replica availability requirement.

## Prevention

Set `progressDeadlineSeconds` on Deployments, wait on `kubectl rollout status` in CD,
and alert when a Deployment's updated replicas lag behind desired replicas:

```yaml
- alert: KubeDeploymentRolloutStalled
  expr: kube_deployment_status_replicas_updated != kube_deployment_spec_replicas
  for: 10m
  labels:
    severity: warning
  annotations:
    summary: Deployment {{ $labels.namespace }}/{{ $labels.deployment }} rollout is stalled
```

## In production this looks like

A release updates a container port or probe port in one manifest file and forgets the
other, leaving the old version serving traffic while the new ReplicaSet sits at `0/1`
indefinitely.

## Say it in an interview

*AI-drafted practice answer — review and adapt to your own understanding.*

“I'd compare the old and new pods and inspect readiness events. Here the new probe
points at the wrong port, so the rollout can't progress safely. I'd fix the probe and
wait for rollout completion. Removing the probe might clear the symptom, but it also
removes the protection against sending traffic to unready pods.”

## Further reading

- [Kubernetes: Configure Liveness, Readiness and Startup Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
- [Kubernetes: Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
