# lnx-01 · Solution

## Root cause

`rm` does not delete a file's data. It removes the file's **name** from the directory.
The data is freed only when the name is gone **and** no process has the file open.

`orders-api` still had `orders.log` open, so the 64 MB stayed allocated. `du` adds up
files it can find by name, so it saw nothing. `df` asks the filesystem how many blocks
are in use, so it saw everything. Both were right.

## How to find it

```
# 1. Confirm the disagreement
df -h /var/log/app          # 100% used
du -sh /var/log/app         # 0

# 2. df and du disagree → look for deleted files that are still open
lsof +L1
COMMAND   PID USER   FD   TYPE DEVICE SIZE/OFF NLINK NODE NAME
orders-ap  74 root    3w   REG  0,103 67108864     0    2 /var/log/app/orders.log (deleted)

# 3. No lsof on the box? /proc shows the same thing
ls -l /proc/74/fd | grep deleted

# 4. Before touching the process, read how it wants to be handled
systemctl cat orders-api    # → ExecReload=/bin/kill -HUP $MAINPID
```

`NLINK 0` means "no name left". `SIZE/OFF 67108864` is the 64 MB you were looking for.

## Fix

```
systemctl reload orders-api
```

The service closes its log and opens it again. Closing the last handle lets the kernel
free the blocks. Opening it again creates a new, visible `orders.log`. Same process, same
PID, the batch keeps running.

If a service has no reload, `: > /proc/<pid>/fd/<n>` empties the deleted file and gives
the space back without a restart. Use it to stop the bleeding, then plan a restart,
because the service is still writing to a file nobody can read.

## Why the obvious fix is wrong

- **Restart the service:** frees the space, and throws away the running batch. The
  ticket told you the cost. Always ask what a restart costs before you do it.
- **Kill the process:** same as a restart, but unplanned. systemd brings it back with
  empty state.
- **Truncate through `/proc` and walk away:** the alert clears, but the service now logs
  into a file with no name. At the next incident there are no logs.

## Prevention

The real bug is that nothing rotates this log. Add a logrotate rule that tells the
service to re-open its file, instead of deleting the file under it:

```
# /etc/logrotate.d/orders-api
/var/log/app/orders.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
    postrotate
        systemctl reload orders-api
    endscript
}
```

And alert before the volume is full, not when it is (Prometheus node_exporter):

```
- alert: LogVolumeFillingUp
  expr: predict_linear(node_filesystem_avail_bytes{mountpoint="/var/log/app"}[1h], 4 * 3600) < 0
  for: 10m
  annotations:
    summary: "/var/log/app will be full within 4 hours"
```

Team rule worth writing down: to empty a live log use `truncate -s 0 file` or `: > file`,
never `rm`.

## In production this looks like

- An EBS or managed-disk volume at 100% where the monitoring agent and `du` disagree.
- A container whose writable layer keeps growing after a log was "cleaned up": the
  process inside still holds the file.
- A Kubernetes node under `DiskPressure` evicting pods, while `du` on the node finds
  nothing large. Same cause, usually a container runtime or log shipper holding files.
- Java and Python services are frequent offenders because they open the log once at
  start and never re-open it unless told to.

## Say it in an interview

"`df` showed the volume full but `du` showed it empty, which told me a deleted file was
still held open. `lsof +L1` showed the service holding a 64 MB deleted log. The service
could not be restarted, so I reloaded it to make it re-open its log, which released the
space. The real fix was a logrotate rule with a reload in `postrotate`, plus an alert
that predicts the disk filling instead of firing at 100%."

## Further reading

- `man 2 unlink` — "the file remains in existence until the last file descriptor referring to it is closed"
- `man 8 lsof` — the `+L1` option
- `man 8 logrotate` — `postrotate` and `copytruncate`
- `man 5 systemd.service` — `ExecReload=`
