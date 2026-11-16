# lnx-05 · SSH key login rejected

Linux · Level 1 · about 15 min · Maps to: RHCSA / LFCS (service administration and troubleshooting) · Tags: security

## The ticket

> **Ticket — prod-web-01 — deploy key login failing**
>
> CI/CD deploys to `prod-web-01` as `deploy` started failing with
> `Permission denied (publickey).` The SSH key in `/home/deploy/.ssh/authorized_keys`
> has not changed, and passwordless key login worked earlier today before a deployment
> script ran.

## What you see

Captured from the broken lab; timestamps and process IDs vary.

```text
$ /usr/local/bin/lab-ssh
deploy@127.0.0.1: Permission denied (publickey).

$ ls -ld /home/deploy/.ssh /home/deploy/.ssh/authorized_keys
drwx------ 2 deploy deploy 4096 Nov 16 02:45 /home/deploy/.ssh
-rw------- 1 deploy deploy   92 Nov 16 02:45 /home/deploy/.ssh/authorized_keys
```

## Your goal

`./dbb check` verifies each of these:

- [ ] `/usr/local/bin/lab-ssh` logs in as `deploy` with the supplied key
- [ ] Effective `sshd` configuration keeps `StrictModes yes` for `deploy`
- [ ] `sshd` remains enabled and active

## Predict first

Before you type anything: `.ssh` is `0700` and `authorized_keys` is `0600`, both owned
by `deploy`. What else does `sshd` check before trusting `authorized_keys`?

## Skills you'll practise

`sshd` server-side logging · `journalctl -u sshd` · `StrictModes` semantics · directory permissions · `sshd -T` effective config inspection
