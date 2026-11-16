# ctr-02 · Solution

## Root cause

nginx listens on `127.0.0.1:80` inside the container. That is the container's own
loopback interface. Docker publishes a port that forwards to the container's network
interface, where no listener accepts the request. Host-side publication does not
change the address on which the application listens.

## How to find it

Compare the two paths before changing a firewall:

```sh
docker port dbb-ctr-02-web
docker exec dbb-ctr-02-web wget -qO- http://127.0.0.1
docker exec dbb-ctr-02-web cat /etc/nginx/nginx.conf
```

The captured internal response is `catalogue: ready`, while the captured host curl
request receives `curl: (52) Empty reply from server`. See `captures/symptom.txt`.
A different Docker host may report a reset or refusal instead. The configuration
shows `listen 127.0.0.1:80;`. Distinguish the container listener from the host binding.

## Fix

In `workspace/ctr-02/nginx.conf`, change `listen 127.0.0.1:80;` to `listen 80;`.
Run `./run.sh` from that workspace, then `./dbb check` from the repository root.

Keep `run.sh` publishing to `127.0.0.1`. Listening on all interfaces inside the
container and limiting the host publication to loopback serve different purposes.
After recreating, use `docker port dbb-ctr-02-web` to find the newly assigned host port.

## Why the obvious fix is wrong

The `change-published-port` shortcut maps the host to container port 8080. The
application still listens only on its loopback interface at port 80. Changing a
mapping does not repair the listener. Host networking would also abandon the lab's
isolation requirement; it is not needed to solve this problem.

## Prevention

Test both the internal application endpoint and the published endpoint. An internal
health check alone would have passed throughout this incident. Configure an external
blackbox exporter probe and a rule such as:

```yaml
- alert: CataloguePublishedEndpointDown
  expr: probe_success{job="catalogue-published-http"} == 0
  for: 2m
  labels:
    severity: page
  annotations:
    summary: Catalogue cannot be reached through its published endpoint
```

This assumes a configured probe job and monitoring for missing exporter metrics.
The lab does not deploy Prometheus. Test the externally reachable path in CI too.

## In production this looks like

An application passes its localhost health check but a load balancer cannot reach it.
A framework's development defaults may bind to loopback even though the deployment
publishes the correct port. Trace the listener address and the traffic path before
opening broader firewall rules.

## Say it in an interview

Author gate pending: write your own 15-second answer after solving blind. Explain
which loopback was involved, how the two request paths differed and what you changed.

## Further reading

- [Docker: port publishing](https://docs.docker.com/engine/network/port-publishing/)
- [nginx: listen directive](https://nginx.org/en/docs/http/ngx_http_core_module.html#listen)
- [Prometheus blackbox exporter](https://github.com/prometheus/blackbox_exporter)
