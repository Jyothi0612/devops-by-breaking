# Security

## What runs on your machine

Every lab runs in Docker containers that `./dbb` creates and labels `dbb.lab=<id>`.
`./dbb stop` removes them. `./dbb nuke` removes everything dbb ever created.

**Privileged containers.** Two kinds of lab start a container with `--privileged`:

| Labs | Why |
|---|---|
| Linux and networking (`lnx-*`, `net-*`) | They run real systemd as PID 1, mount filesystems and set firewall rules |
| Kubernetes (`k8s-*`) | A Kubernetes node (k3s) has to manage containers and networking itself |

A privileged container can do almost anything root can do on the Docker host. On macOS
and Windows that host is Docker's Linux virtual machine, not your computer. On Linux it
is your machine. What limits the exposure:

- These containers use a **private cgroup namespace** and do **not** mount the host's
  `/sys/fs/cgroup`, the Docker socket, or any host directory except a read-only image archive.
- No lab publishes a port on anything other than `127.0.0.1`.
- Lab scripts are short and readable: `labs/<id>/setup.sh` is everything a lab does.

Terraform labs run unprivileged, as your own user, with `--network none`.

If you are not comfortable running privileged containers on a work laptop, run the labs
in a virtual machine or a cloud development environment.

## Fake secrets

Some labs contain passwords or keys on purpose. They are generated for the lab, grant
access to nothing, and are written so they cannot be mistaken for real credentials.

## Reporting a problem

Open a GitHub issue, or use GitHub's private vulnerability reporting on this repository
for anything you would rather not post publicly.
