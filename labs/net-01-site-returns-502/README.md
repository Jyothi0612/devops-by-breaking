# net-01 · Site returns `502 Bad Gateway`

Networking · Level 1 · about 15 min · Maps to: LFCS (networking)

## The ticket

> **Alert — prod-web-01 — http://127.0.0.1/ returning 502 Bad Gateway**
>
> Immediately after a routine config release, checkout requests to `http://127.0.0.1/`
> started failing with `502 Bad Gateway`. `nginx` and `orders-backend` are both
> reported as `active (running)` by systemd.

## What you see

Captured from the broken lab; generated values and timestamps vary.

```text
$ curl -i http://127.0.0.1/
HTTP/1.1 200 OK
Server: nginx/1.20.1
Date: Mon, 16 Nov 2026 02:45:56 GMT
Content-Type: text/plain
Content-Length: 37
Connection: keep-alive

orders-backend: checkout ready req=2

$ systemctl is-active nginx orders-backend
active
active
```

## Your goal

`./dbb check` verifies each of these:

- [ ] HTTP requests to `http://127.0.0.1/` return `200` from the live `orders-backend`
- [ ] `nginx` is enabled, active, and configured with `proxy_pass`
- [ ] `orders-backend` remains enabled and active

## Predict first

Before you type anything: both `nginx` and `orders-backend` are `active (running)`,
yet `nginx` returns `502 Bad Gateway`. What does `502` tell you about where the
connection failed?

## Skills you'll practise

`502 Bad Gateway` diagnosis · `/var/log/nginx/error.log` · `ss -tlnp` · `nginx -t` · `systemctl reload nginx`
