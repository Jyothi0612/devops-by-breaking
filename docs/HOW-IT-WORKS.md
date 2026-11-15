# How it works

`./dbb` is one bash script plus a small library in `lib/`. It has no dependencies
beyond Docker.

## A lab's life

```
./dbb start <id>
   └─ lib/<runtime>.sh   starts the environment (a server, a cluster, a Terraform workspace)
   └─ labs/<id>/setup.sh builds a healthy system, then breaks it the way production would

./dbb check
   └─ labs/<id>/check.sh runs each objective and reports PASS or FAIL

./dbb stop
   └─ removes every container, network and volume labelled dbb.lab=<id>
```

Facts a check needs later (a process id, a fingerprint) are stored on your machine in
`.dbb/state/<id>/`, outside the lab, so they cannot be edited from inside it.

## Runtimes

| Runtime | What it is | Why |
|---|---|---|
| `server` | Rocky Linux 9 with real systemd as PID 1 | Services, cron, ssh and logs behave as they do on a real server |
| `k8s` | k3s, a certified Kubernetes distribution, in one container | A real API server, scheduler and kubelet in about 15 seconds |
| `docker` | An unprivileged nginx container, a labelled network and editable host files | Learn process lifecycle and port publishing with the Docker CLI |
| `terraform` | The official Terraform image with providers baked in | Real plans against real state, with no cloud account |

## Offline by design

`images.lock` pins every image by tag and digest. The Kubernetes runtime saves the
images a cluster needs into `.dbb/cache/` once and loads them at start, so the cluster
never pulls. The Terraform image contains a provider mirror, and Terraform containers
run with no network at all.

## The proof

`./dbb verify <id>` is what CI runs. See the README for what it checks. The point is
that a lab cannot quietly rot: if an upstream image changes behaviour and a lab stops
being broken, or stops being fixable, the weekly run fails.

## Docker lab workspace

`./dbb shell` for `ctr-*` opens a host Bash shell in `workspace/<id>/`; it does
not enter the container. Edit `nginx.conf` or `start.sh`, then run `./run.sh` to
recreate only that lab's labelled container. `./dbb exec -- <command>` uses the
same workspace. The generated `.lab.env` contains the lab ID and pinned image.

Each container is unprivileged, limited to 128 MB and 128 processes, and publishes
a dynamically assigned port on `127.0.0.1`. `docker port dbb-<id>-web` shows the
current port. Files are mounted read-only inside the container; edit them on the
host and recreate. No Docker socket is mounted. The host HTTP check uses Bash TCP
support with a bounded wait, so curl and Compose are not extra prerequisites.

The new Docker labs prove a healthy response before introducing their failure.
Verification also restarts the repaired container and checks the published endpoint
again. Every container and network is labelled for normal cleanup.
