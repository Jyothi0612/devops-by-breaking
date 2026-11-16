# lnx-05 · Solution

## Root cause

`/home/deploy` has mode `0777` (world-writable). With `StrictModes yes` enabled in
`/etc/ssh/sshd_config`, `sshd` refuses public-key authentication if the user's home
directory, `.ssh` directory, or `authorized_keys` file is writable by group or others,
because another local user could rename `.ssh` and substitute their own `authorized_keys`.

## How to find it

Reproduce the failure and check the `sshd` journal and directory modes:

```sh
/usr/local/bin/lab-ssh
journalctl -u sshd -n 10 --no-pager
ls -ld /home/deploy /home/deploy/.ssh /home/deploy/.ssh/authorized_keys
```

The captured output in `captures/symptom.txt` shows:

```
Authentication refused: bad ownership or modes for directory /home/deploy
```

And `ls -ld /home/deploy` shows `drwxrwxrwx`.

## Fix

Remove group and world write permissions from `/home/deploy`:

```sh
chmod 755 /home/deploy
```

Then run `./dbb check` from the repository root, and verify `sshd -T` still reports
`strictmodes yes`.

## Why the obvious fix is wrong

- `disable-strict-modes`: setting `StrictModes no` in `/etc/ssh/sshd_config` lets the
  key log in, but leaves `/home/deploy` world-writable so any local user can replace
  `deploy`'s `.ssh/authorized_keys`.

## Prevention

Never run `chmod -R 777` or `chmod 777` on home directories in deploy scripts, and
audit home directory permissions in configuration management or host hardening checks.
The following is a **custom log-derived metric**, not a built-in sshd or node_exporter
metric. Configure a journal/log collector to count sshd messages matching
`Authentication refused: bad ownership or modes`, expose a cumulative counter named
`sshd_auth_refused_bad_modes_total` per host, and scrape it with Prometheus. Initialize
the counter to zero and monitor collector/scrape health separately. Only after that
instrumentation exists can this rule detect new bad-permission refusals:

```yaml
- alert: SshAuthRefusedBadModes
  expr: increase(sshd_auth_refused_bad_modes_total[5m]) > 0
  labels:
    severity: warning
  annotations:
    summary: sshd is refusing publickey logins due to file or directory permissions
```

## In production this looks like

An Ansible play, cloud-init script, or manual troubleshooting step loosens permissions
on a service account's home directory, immediately breaking SSH-based CI/CD deployments
while `.ssh` and `authorized_keys` still look intact.

## Say it in an interview

*AI-drafted practice answer — review and adapt to your own understanding.*

“I'd read the sshd log before replacing keys. Here it reports unsafe permissions on the
user's home directory. I'd remove group and world write access and retry the key login
with StrictModes still enabled. Disabling that check would hide the problem while
leaving the account vulnerable to local tampering.”

## Further reading

- [sshd_config(5) — StrictModes](https://man.openbsd.org/sshd_config#StrictModes)
- [sshd(8) — OpenSSH daemon](https://man.openbsd.org/sshd)
