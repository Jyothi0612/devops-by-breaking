# lnx-03 · Backup works by hand, never from cron

Linux · Level 1 · about 15 min · Maps to: RHCSA / LFCS (service administration and troubleshooting) · Tags: sre

## The ticket

> **Alert — prod-web-01 — catalogue backup missing after reboot**
>
> On-call handover: "After yesterday's release, `/var/backups/catalogue.tgz` was
> missing following a reboot. I ran `/opt/catalogue/backup.sh` by hand from
> `/opt/catalogue` and it worked, so I closed the ticket. This morning after another
> reboot, the archive is missing again."

## What you see

Captured from the broken lab; timestamps and process IDs vary.

```text
$ cat /var/log/catalogue-backup.log
/opt/catalogue/backup.sh: line 3: archive-catalogue: command not found

$ ls -la /var/backups
total 12
drwxr-xr-x 2 root root 4096 Nov 16 02:45 .
drwxr-xr-x 1 root root 4096 Nov 16 02:45 ..

$ cat /etc/cron.d/catalogue-backup
SHELL=/bin/sh
PATH=/usr/bin:/bin
@reboot root /opt/catalogue/backup.sh >> /var/log/catalogue-backup.log 2>&1
```

## Your goal

`./dbb check` verifies each of these:

- [ ] A fresh `crond` invocation archives `/opt/catalogue/data/orders.txt` into `/var/backups/catalogue.tgz`
- [ ] `crond` remains enabled and active

The check restarts the lab's cron daemon with its boot marker cleared to trigger
the real `@reboot` job. It refreshes the source file and removes the previous test
archive before each attempt. This affects only the disposable lab container.

## Predict first

Before you type anything: the same script succeeds when you run it interactively from
`/opt/catalogue`, yet fails when `crond` runs it at boot. What two assumptions in a
shell script break under `crond`?

## Skills you'll practise

`cron` environment vs interactive shell · `PATH` in `/etc/cron.d` · working directory assumptions · reading cron logs · `systemctl` service checks
