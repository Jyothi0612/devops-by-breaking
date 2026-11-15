# lnx-01 · Disk 100% full, but `du` finds nothing

Linux · Level 1 · about 15 min · Maps to: RHCSA (manage files and storage), LFCS (troubleshooting)

## The ticket

> **PAGE 02:14 — prod-orders-01 — disk /var/log/app at 100%**
>
> On-call note from the previous shift: "Debug logging was left on and filled the log
> volume. I deleted the big log file but the alert did not clear. `du` says the
> directory is empty. I don't understand where the space went."
>
> `orders-api` is in the middle of the nightly settlement batch. **Do not restart it.**
> If it restarts, the batch starts again from zero and finance misses the 06:00 cut-off.

## What you see

```
[root@prod-orders-01 ~]# df -h /var/log/app
Filesystem      Size  Used Avail Use% Mounted on
tmpfs            64M   64M     0 100% /var/log/app

[root@prod-orders-01 ~]# du -sh /var/log/app
0	/var/log/app

[root@prod-orders-01 ~]# ls -la /var/log/app
total 8
drwxrwxrwt 2 root root   40 Nov 15 13:24 .
drwxr-xr-x 1 root root 4096 Nov 15 13:24 ..
```

## Your goal

`./dbb check` verifies each of these:

- [ ] `/var/log/app` is below 80% used
- [ ] `orders-api` is still the same running process (never restarted, never killed)
- [ ] `/var/log/app/orders.log` exists again and new lines are arriving
- [ ] `/var/log/app` is still the same 64M volume

## Predict first

Before you type anything: `df` says 64M is used and `du` says 0 is used. Both are
telling the truth. Write down one sentence that explains how both can be right.

## Skills you'll practise

`df` vs `du` · open file handles · `lsof` · `/proc/<pid>/fd` · `systemctl reload` vs `restart` · reading a unit file
