# ctr-01 · Container exits immediately with code 0

Containers · Level 1 · about 10 min · Maps to: container operations (no certification affiliation)

## The ticket

The catalogue deployment completed without an error, but the page never became available. The container exits with code 0 every time it is started. Restore the catalogue and keep it available after a container restart.

## What you see

Captured on macOS with Docker Desktop. Timestamps and assigned host ports vary.
A failed host request may report an empty reply, reset or refusal depending on Docker's networking implementation.

```text
$ docker inspect -f 'state={{.State.Status}} exit_code={{.State.ExitCode}}' dbb-ctr-01-web
state=exited exit_code=0

$ docker logs dbb-ctr-01-web
2026/11/15 21:29:15 [notice] 1#1: using the "epoll" event method
2026/11/15 21:29:15 [notice] 1#1: nginx/1.29.8
2026/11/15 21:29:15 [notice] 1#1: built by gcc 15.2.0 (Alpine 15.2.0) 
2026/11/15 21:29:15 [notice] 1#1: OS: Linux 6.12.76-linuxkit
2026/11/15 21:29:15 [notice] 1#1: getrlimit(RLIMIT_NOFILE): 1048576:1048576
2026/11/15 21:29:15 [notice] 7#7: start worker processes
2026/11/15 21:29:15 [notice] 7#7: start worker process 8
```

## Your goal

`./dbb check` verifies these outcomes:

- The catalogue container stays running.
- Its published localhost port returns HTTP 200 and the original catalogue page.
- It remains unprivileged, on its lab network, with ports published only to `127.0.0.1`.

The repair must survive `docker restart dbb-ctr-01-web`.
Edit files in `workspace/ctr-01/`, then run `./run.sh` there to recreate the container.
`./dbb shell` opens a **host shell** in that directory; `./dbb exec -- <command>`
runs a host command there. Use `docker exec` when you want to inspect inside the container.
Docker assigns a free host port each time; find it with `docker port dbb-ctr-01-web`.
The captured curl command is optional: `./dbb check` probes HTTP using Bash without requiring curl.

## Predict first

Can a process finish successfully while its service is still unavailable? What determines the lifetime of a container?

## Skills you'll practise

Container lifecycle · exit codes · docker inspect and logs · foreground processes

Use `./dbb hint` for the three hints, one at a time.
