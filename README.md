# devops-by-breaking

**Every lab starts broken. You fix it. A script proves you really did.**

Real production failures, running on your laptop, organised by the error you would
actually see at 2 a.m. No cloud account, no cost. You need Docker, bash and git.

```
git clone https://github.com/Jyothi0612/devops-by-breaking && cd devops-by-breaking
./dbb doctor          # is this machine ready?
./dbb start lnx-01    # a server with a disk at 100% ... and du says it is empty
./dbb shell           # go and look
./dbb check           # did you really fix it?
```

```
  PASS  /var/log/app is below 80% used
  FAIL  orders-api is still the same running process (it was never restarted or killed)
  PASS  /var/log/app/orders.log exists again and new lines are arriving
  PASS  /var/log/app is still the same 64M volume (not unmounted or resized)

Not fixed yet. Stuck? ./dbb hint
```

Restarting the service made the alert go away. It also killed the batch job the ticket
told you not to touch. **The check knows the difference.**

## Why this is different

| Most "learn DevOps" repos | devops-by-breaking |
|---|---|
| Notes you read | Broken systems you repair |
| Organised by tool | Organised by symptom: the error message is the title |
| "It should work" | CI proves every lab is broken, rejects the shortcuts, and can be fixed |
| Explains commands | Teaches the order to debug in, how to prevent it, and how to say it in an interview |
| Needs servers or a cloud bill | Docker, bash, git. Runs offline after the first start |

## The labs

Five labs are implemented on this development branch. The two container labs await
the [author solve-through gate](docs/AUTHOR-CHECKLIST.md). See [build progress](docs/PROGRESS.md) for completed
work, verification evidence and the remaining release gates.

<!-- catalog:start -->
| Lab | Track | Level | Time | The symptom |
|---|---|---|---|---|
| [ctr-01](labs/ctr-01-container-exits-zero/) | containers | L1 | 10 min | Container exits immediately with code 0 |
| [ctr-02](labs/ctr-02-published-port-no-response/) | containers | L1 | 10 min | Port published, but the catalogue is unreachable |
| [k8s-01](labs/k8s-01-service-no-endpoints/) | kubernetes | L1 | 15 min | Service has no endpoints, curl times out |
| [lnx-01](labs/lnx-01-disk-full-du-empty/) | linux | L1 | 15 min | Disk 100% full, but du finds nothing |
| [tf-01](labs/tf-01-rename-plans-destroy/) | terraform | L1 | 15 min | Renamed a resource, plan wants to destroy the database password |
<!-- catalog:end -->

More are on the way: Linux, networking, containers, Kubernetes, Terraform, Ansible, a
security track (secrets, RBAC, NetworkPolicy, Pod Security) and multi-cause incidents.

## What a lab gives you

1. **A ticket**, written like a real page: who noticed, what is impacted, what you must not do.
2. **Real output** captured from the broken system, not typed from memory.
3. **Goals that are outcomes**, not steps. Any correct fix passes.
4. **Three hints**, one at a time: where to look, which command, almost the answer.
5. **A solution** with the root cause, how a senior engineer would find it, why the
   obvious fix is wrong, a concrete prevention (an alert rule, a CI check, a config),
   what the same failure looks like in the cloud, and a 15-second interview answer.

## All commands

```
./dbb doctor              is this machine ready?
./dbb list                all labs   [--track T] [--level N] [--tag T] [--json]
./dbb next                the next lab you have not solved
./dbb start <id>          start a lab in its broken state and show the ticket
./dbb shell               open a shell where the problem is
./dbb exec -- <command>   run one command there
./dbb hint                show the next hint
./dbb check               is it really fixed?   [--json]
./dbb reset               put the lab back to its broken state
./dbb solution            root cause, fix and prevention
./dbb status              current lab, time spent, hints used
./dbb stop                remove everything the lab created
./dbb nuke                remove everything dbb ever created on this machine
```

## How every lab is proven

`./dbb verify <id>` runs on every push, on both amd64 and arm64:

```
verify lnx-01  Disk 100% full, but du finds nothing
  starts broken                                        yes
  rejects shortcut: kill-the-process                   yes
  rejects shortcut: restart-the-service                yes
  rejects shortcut: truncate-only                      yes
  fix passes the check                                 yes
  cleans up                                            yes
```

If a lab stops being broken, stops being fixable, or starts accepting a shortcut, the
build goes red.

## Requirements

- Docker (Docker Desktop on macOS, Docker Engine on Linux, Docker inside WSL2 on Windows)
- bash 3.2 or newer, git
- About 4 GB of memory for Docker if you run the Kubernetes labs

Terraform, kubectl and everything else run inside pinned containers. Nothing is
installed on your machine. The first start of each kind of lab downloads images; after
that the labs run without a network.

Some labs run a privileged container, because they need a real init system or a real
Kubernetes node. [SECURITY.md](SECURITY.md) explains exactly what that means.

## Contributing

A lab is a folder with a setup script, a check, a fix, and at least one shortcut that
must fail. See [CONTRIBUTING.md](CONTRIBUTING.md).

## Credits and licence

Built with [Claude Code](https://claude.com/claude-code). Every lab is verified by CI
rather than by trust. MIT licence.
