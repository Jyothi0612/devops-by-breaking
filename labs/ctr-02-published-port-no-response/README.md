# ctr-02 · Port published, but the catalogue is unreachable

Containers · Level 1 · about 10 min · Maps to: container operations (no certification affiliation)

## The ticket

The catalogue container stays Running and its port is published. A request made inside the container returns the expected page, but a request from the laptop fails. Restore access through the published port while keeping it private to this laptop.

## What you see

Captured on macOS with Docker Desktop. Timestamps and assigned host ports vary.
A failed host request may report an empty reply, reset or refusal depending on Docker's networking implementation.

```text
$ docker port dbb-ctr-02-web
80/tcp -> 127.0.0.1:49235

$ docker exec dbb-ctr-02-web wget -qO- http://127.0.0.1
catalogue: ready

$ curl --max-time 3 http://127.0.0.1:49235
curl: (52) Empty reply from server
```

## Your goal

`./dbb check` verifies these outcomes:

- The catalogue container stays running.
- Its published localhost port returns HTTP 200 and the original catalogue page.
- It remains unprivileged, on its lab network, with ports published only to `127.0.0.1`.

The repair must survive `docker restart dbb-ctr-02-web`.
Edit files in `workspace/ctr-02/`, then run `./run.sh` there to recreate the container.
`./dbb shell` opens a **host shell** in that directory; `./dbb exec -- <command>`
runs a host command there. Use `docker exec` when you want to inspect inside the container.
Docker assigns a free host port each time; find it with `docker port dbb-ctr-02-web`.
The captured curl command is optional: `./dbb check` probes HTTP using Bash without requiring curl.

## Predict first

The port number matches on both sides. What other part of a listening socket decides which connections it can accept?

## Skills you'll practise

Container network namespaces · loopback addresses · port publishing · inside/outside probes

Use `./dbb hint` for the three hints, one at a time.
