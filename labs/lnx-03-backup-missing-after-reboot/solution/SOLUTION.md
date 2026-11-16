# lnx-03 · Solution

## Root cause

`/opt/catalogue/backup.sh` relies on two assumptions from an interactive session:
that `/usr/local/bin` is on `PATH` (for `archive-catalogue`) and that the working
directory is `/opt/catalogue` (for `./data`). `crond` runs `/etc/cron.d/catalogue-backup`
with `PATH=/usr/bin:/bin` and `/root` as the working directory, so the scheduled run
fails with `archive-catalogue: command not found` and would also miss `./data`.

## How to find it

Check the archive directory, the cron job log, the cron definition, and the script:

```sh
ls -la /var/backups/
cat /var/log/catalogue-backup.log
cat /etc/cron.d/catalogue-backup
cat /opt/catalogue/backup.sh
```

The captured log in `captures/symptom.txt` shows:

```
/opt/catalogue/backup.sh: line 3: archive-catalogue: command not found
```

Comparing `/etc/cron.d/catalogue-backup` (`PATH=/usr/bin:/bin`) with `command -v archive-catalogue`
(`/usr/local/bin/archive-catalogue`) and `/opt/catalogue/backup.sh` (`./data`) shows
both the missing `PATH` entry and the relative source path.

## Fix

Edit `/opt/catalogue/backup.sh` to use absolute paths for both the binary and the data
directory:

```sh
#!/bin/sh
set -eu
/usr/local/bin/archive-catalogue /opt/catalogue/data /var/backups/catalogue.tgz
```

Then run `./dbb check` from the repository root, and verify survival across a `crond`
restart (`systemctl restart crond`).

## Why the obvious fix is wrong

- `run-manually`: running `./backup.sh` from `/opt/catalogue` writes one archive now,
  but `crond` still fails on the next boot or service restart.
- `path-only`: adding `/usr/local/bin` to `PATH` in `/etc/cron.d/catalogue-backup`
  lets `crond` find `archive-catalogue`, but `./data` still fails because `crond` does
  not run with `/opt/catalogue` as its working directory.

## Prevention

Write scheduled scripts to be self-contained with absolute paths, and monitor backup
freshness rather than assuming a cron entry succeeded. Example Prometheus alert rule
using a textfile collector timestamp:

```yaml
- alert: CatalogueBackupStale
  expr: time() - catalogue_backup_last_success_timestamp_seconds > 86400
  for: 5m
  labels:
    severity: page
  annotations:
    summary: Catalogue backup has not succeeded in the last 24 hours
```

## In production this looks like

A cron job or systemd timer works during manual testing by an engineer over SSH, then
silently fails in production after a deploy or reboot because the script relied on user
shell `PATH`, `$HOME`, or `PWD`.

## Say it in an interview

*AI-drafted practice answer — review and adapt to your own understanding.*

“I'd compare the scheduled environment with the interactive one. Here cron can't find
the helper, and the script also assumes a working directory. I'd use absolute paths for
both, then verify an actual scheduled run produces the backup. I'd monitor backup
freshness so a silent cron failure doesn't go unnoticed.”

## Further reading

- [crontab(5) — Linux manual page](https://man7.org/linux/man-pages/man5/crontab.5.html)
- [crond(8) — cronie daemon manual page](https://man7.org/linux/man-pages/man8/crond.8.html)
