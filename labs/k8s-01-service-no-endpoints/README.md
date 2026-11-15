# k8s-01 · Service has no endpoints, curl times out

Kubernetes · Level 1 · about 15 min · Maps to: CKA (services and networking, troubleshooting), CKAD (services and networking)

## The ticket

> **INC-4471 — shop catalogue unreachable inside the cluster**
>
> Reported by the checkout team: "Since last night every call from our service to
> `http://web` in the `shop` namespace times out. Your pods look healthy to us."
>
> Last change: a merge request titled "tidy up labels" was applied yesterday evening.
> Nobody remembers exactly what it touched.

## What you see

```
$ kubectl -n shop get pods,svc
NAME                         READY   STATUS    RESTARTS   AGE
pod/client-b5c548988-vbdsm   1/1     Running   0          2s
pod/web-5695cf7879-498xs     1/1     Running   0          2s
pod/web-5695cf7879-dxtdv     1/1     Running   0          2s

NAME          TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/web   ClusterIP   10.43.176.249   <none>        80/TCP    2s

$ kubectl -n shop exec deploy/client -- wget -qO- -T 3 http://web
wget: download timed out
command terminated with exit code 1
```

Everything is `Running`. Nothing is restarting. And it does not work.

## Your goal

`./dbb check` verifies each of these:

- [ ] Service `web` has at least 2 ready endpoints
- [ ] A request from the `client` pod to `http://web` returns the page
- [ ] The Service's backends are exactly the 2 pods of Deployment `web`
- [ ] The Service selector does not depend on one ReplicaSet's hash
- [ ] Deployment `web` still has 2 ready replicas

## Predict first

The pods are healthy and the Service exists. Name the one Kubernetes object that connects
a Service to its pods, and say what you expect to find in it.

## Skills you'll practise

Services and selectors · EndpointSlices · labels · `kubectl describe` · testing from inside the cluster
