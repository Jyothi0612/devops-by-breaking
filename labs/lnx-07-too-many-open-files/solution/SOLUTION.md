# lnx-07 · Solution

## Root cause

`/etc/systemd/system/connection-api.service` sets `LimitNOFILE=64`. `systemd`
launches services directly rather than through a PAM login session, so
`/etc/security/limits.d/apiworker.conf` is ignored by the service. With `LimitNOFILE=64`,
standard descriptors plus the listening socket leave room for only ~60 concurrent
client sockets before `accept()` fails with `EMFILE` (`Too many open files`).

## How to find it

Run the load test, check the service journal, and inspect the live process limits and
unit file:

```sh
python3 /opt/connection-api/load.py
journalctl -u connection-api -n 8 --no-pager
pid=$(systemctl show -p MainPID --value connection-api)
grep "Max open files" /proc/"$pid"/limits
systemctl cat connection-api
```

The captured output in `captures/symptom.txt` shows:

```
Max open files            64                   64                   files
```

even though `/etc/security/limits.d/apiworker.conf` specifies `256`.

## Fix

Create a systemd drop-in override with a bounded `LimitNOFILE` (e.g., `256`), reload
systemd, and restart the service:

```sh
mkdir -p /etc/systemd/system/connection-api.service.d
printf '[Service]\nLimitNOFILE=256\n' > /etc/systemd/system/connection-api.service.d/limits.conf
systemctl daemon-reload
systemctl restart connection-api
```

Then run `./dbb check` from the repository root and verify the service survives a
restart.

## Why the obvious fix is wrong

- `pam-limits-only`: raising `nofile` in `/etc/security/limits.d/apiworker.conf` only
  affects PAM login sessions; `systemd` services still use the unit's `LimitNOFILE=64`.
- `run-as-root`: changing `User=apiworker` to `User=root` violates least privilege and
  fails the non-root check.

## Prevention

Set `LimitNOFILE=` explicitly in the systemd unit or drop-in for network services, and
alert when open file descriptors approach the process limit:

```yaml
- alert: ProcessOpenFilesNearLimit
  expr: process_open_fds / process_max_fds > 0.8
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: Process is using more than 80% of its open file descriptor limit
```

## In production this looks like

An engineer edits `/etc/security/limits.conf` during an incident and restarts a
daemon via `systemctl`, sees no change, and assumes the OS limit did not take effect
until checking `/proc/<pid>/limits` and the unit's `LimitNOFILE=`.

## Say it in an interview

*AI-drafted practice answer — review and adapt to your own understanding.*

“I'd check the running process's limits in /proc and compare them with the systemd unit.
Here the service gets LimitNOFILE from systemd, not the PAM limits file. I'd set an
appropriate limit in a drop-in, reload systemd, restart the service, and repeat the load
test without changing its non-root user.”

## Further reading

- [systemd.exec(5) — LimitNOFILE](https://www.freedesktop.org/software/systemd/man/latest/systemd.exec.html#LimitCPU=)
- [systemd.unit(5) — Drop-in directories](https://www.freedesktop.org/software/systemd/man/latest/systemd.unit.html)
