# net-01 · Solution

## Root cause

`/etc/nginx/conf.d/orders.conf` was updated to `proxy_pass http://127.0.0.1:8080;`,
but `orders-backend` is listening on `127.0.0.1:8081`. Nothing listens on port
`8080`, so nginx's upstream TCP connect fails with `Connection refused` and nginx
returns `502 Bad Gateway`.

## How to find it

Reproduce the `502`, read nginx's error log, and compare against listening sockets:

```sh
curl -i http://127.0.0.1/
tail -n 3 /var/log/nginx/error.log
ss -tlnp | grep -E "80|808"
```

The captured output in `captures/symptom.txt` shows:

```
connect() failed (111: Connection refused) while connecting to upstream, ..., upstream: "http://127.0.0.1:8080/"
```

while `ss -tlnp` shows `python3` (`orders-backend`) listening on `127.0.0.1:8081`.

## Fix

Update `proxy_pass` in `/etc/nginx/conf.d/orders.conf` back to `http://127.0.0.1:8081`,
validate the config, and reload nginx:

```sh
sed -i 's|127.0.0.1:8080|127.0.0.1:8081|' /etc/nginx/conf.d/orders.conf
nginx -t
systemctl reload nginx
```

Then run `./dbb check` from the repository root.

## Why the obvious fix is wrong

- `static-200`: replacing `proxy_pass` with `return 200 ...` makes nginx answer `200`,
  but it no longer proxies to `orders-backend` (each request does not reach the
  backend).
- `bypass-nginx`: stopping nginx and binding `orders-backend` directly to port 80
  bypasses the reverse proxy and fails the nginx check.

## Prevention

Run an end-to-end HTTP smoke check through nginx in CI/deploy pipelines before
marking a release complete, and alert on `5xx` responses at the proxy:

```yaml
- alert: NginxUpstream502Spike
  expr: sum(rate(nginx_http_requests_total{status="502"}[2m])) > 0
  for: 1m
  labels:
    severity: page
  annotations:
    summary: nginx is returning 502 Bad Gateway from upstream
```

## In production this looks like

A reverse proxy or ingress controller points at the wrong targetPort or upstream port
after a service refactor, returning `502 Bad Gateway` even though both the proxy and
the backend pods/processes report healthy.

## Say it in an interview

Author gate pending: write your own 15-second answer after solving blind. Cover what
`502` means, how `/var/log/nginx/error.log` and `ss -tlnp` proved the port mismatch,
and how you prevent it on deploy.

## Further reading

- [nginx: ngx_http_proxy_module](https://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_pass)
- [MDN: 502 Bad Gateway](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status/502)
