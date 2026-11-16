# lnx-07 · Too many open files under load

Linux · Level 2 · about 20 min · Maps to: RHCSA / LFCS (service administration and troubleshooting) · Tags: sre

## The ticket

> **Page — prod-web-01 — connection-api dropping concurrent requests**
>
> `connection-api` stays running, but concurrent load tests fail after ~60 connections.
> The previous on-call added `apiworker soft/hard nofile 256` in
> `/etc/security/limits.d/apiworker.conf` and restarted the service, yet the error
> persists.

## What you see

Captured from the broken lab; timestamps and process IDs vary.

```text
$ python3 /opt/connection-api/load.py
FAIL: only 60 of 96 connections received ready (timed out)

$ journalctl -u connection-api -n 8 --no-pager
Nov 16 02:45:29 prod-web-01 python3[199]: accept failed: Too many open files
Nov 16 02:45:29 prod-web-01 python3[199]: accept failed: Too many open files
Nov 16 02:45:29 prod-web-01 python3[199]: accept failed: Too many open files
Nov 16 02:45:30 prod-web-01 python3[199]: accept failed: Too many open files
Nov 16 02:45:30 prod-web-01 python3[199]: accept failed: Too many open files
Nov 16 02:45:30 prod-web-01 python3[199]: accept failed: Too many open files
Nov 16 02:45:30 prod-web-01 python3[199]: accept failed: Too many open files
Nov 16 02:45:30 prod-web-01 python3[199]: accept failed: Too many open files

$ cat /etc/security/limits.d/apiworker.conf
apiworker soft nofile 256
apiworker hard nofile 256

$ grep "Max open files" /proc/$(systemctl show -p MainPID --value connection-api)/limits
Max open files            64                   64                   files
```

## Your goal

`./dbb check` verifies each of these:

- [ ] `python3 /opt/connection-api/load.py` succeeds for 96 simultaneous connections
- [ ] `connection-api` still runs as `apiworker`, not `root`
- [ ] The running service has a bounded open-file limit (`Max open files`) between 128 and 4096
- [ ] `connection-api` remains enabled and active

## Predict first

Before you type anything: `/etc/security/limits.d/apiworker.conf` already sets `nofile`
to 256, and `connection-api` was restarted after that edit. Why would the running
process still hit `Too many open files` at 64?

## Skills you'll practise

`systemd` resource limits vs PAM `limits.conf` · `/proc/<pid>/limits` · `systemctl cat` · systemd drop-in overrides · `daemon-reload`
