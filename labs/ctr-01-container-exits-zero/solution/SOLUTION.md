# ctr-01 · Solution

## Root cause

The custom nginx configuration enables daemon mode. The startup script uses `exec`,
so nginx initially replaces the shell as the container's main process. It then
forks into the background and the original process exits successfully. Docker stops
the container when that main process exits; a successful exit is not service health.

## How to find it

Start with state rather than repeatedly restarting:

```sh
docker inspect -f 'state={{.State.Status}} exit_code={{.State.ExitCode}}' dbb-ctr-01-web
docker logs dbb-ctr-01-web
```

The recorded result in `captures/symptom.txt` is `state=exited exit_code=0`.
The captured logs contain nginx startup notices, not a configuration error.
In `./dbb shell`, inspect `start.sh` and `nginx.conf`. The script executes nginx,
and the configuration says `daemon on;`. Follow the lifetime of that process.

## Fix

In `workspace/ctr-01/nginx.conf`, change `daemon on;` to `daemon off;`.
Then, from that workspace:

```sh
./run.sh
```

From the repository root run `./dbb check`. Restart the container and check again.
Keeping nginx in the foreground ties the container's lifetime to the service.
A proper supervisor is another possible design, but is unnecessary for this single service.

## Why the obvious fix is wrong

The `keep-empty-container-alive` shortcut runs only a long sleep. Docker reports
Running, but no application answers HTTP. The check requires the catalogue response,
not just a green process state. A restart policy alone also cannot make this command
become a persistent web service.

## Prevention

Run an HTTP smoke check from outside the container after deployment and after a
restart. In production, configure a blackbox exporter probe against the actual
catalogue URL, and alert on sustained probe failure:

```yaml
- alert: CatalogueUnavailable
  expr: probe_success{job="catalogue-http"} == 0
  for: 2m
  labels:
    severity: page
  annotations:
    summary: Catalogue HTTP probe is failing
```

This example assumes a configured `catalogue-http` probe job; it is not installed
by this lab. Also monitor the probe exporter itself so missing metrics are visible.

## In production this looks like

A task repeatedly stops immediately after a release that introduced a custom
entrypoint or configuration. An orchestrator may retry it, but retries do not repair
the command's lifecycle. Compare the previous startup command and process model
before adding restart policies.

## Say it in an interview

Author gate pending: write your own 15-second answer after solving blind. Cover the
symptom, the main process exiting, the evidence you checked and an external health probe.

## Further reading

- [Docker: running containers](https://docs.docker.com/engine/containers/run/)
- [nginx: daemon directive](https://nginx.org/en/docs/ngx_core_module.html#daemon)
- [Prometheus blackbox exporter](https://github.com/prometheus/blackbox_exporter)
