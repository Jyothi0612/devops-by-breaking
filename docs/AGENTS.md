# Agent mode

`tools/agent-run.sh` runs a containerized troubleshooting command and records a
score in `results/<lab-id>.json`. It is a local smoke-test harness, not a hardened
hostile-code benchmark or evidence of a human blind solve.

## Quickstart

```sh
AGENT_MAX_CMDS=15 AGENT_TIMEOUT=120 \
  tools/agent-run.sh lnx-01 -- sh -c './dbb exec -- "systemctl reload orders-api"'
```

This is a scripted reference repair to test the harness, not an AI evaluation.
The command after `--` runs **inside the agent container**, not on the host.
The default image is the digest-pinned Python image already in `images.lock`.
Docker, Bash and Git remain the host prerequisites; Python runs in a container.

For an actual agent, provide `AGENT_IMAGE=registry/name@sha256:<digest>` containing
its CLI and Python 3 (required by the `dbb` shim). The image must support UID 65534
and a read-only root filesystem, with writable `/tmp`. Use `AGENT_NETWORK=bridge`
only if the agent needs network access; the default is `none`. Host environment
variables, API credentials, home directories and agent configuration are not
forwarded. A credential-provider interface is not implemented yet. Never bake
credentials or reference solutions into an agent image.

## Supported labs

Server, Kubernetes, Terraform and Ansible runtimes are supported (16 current labs).
The four Docker-runtime labs (`ctr-01`, `ctr-02`, `sec-01`, `sec-02`) are explicitly
rejected before startup. Their existing `dbb exec` runs a host shell and/or needs
Docker daemon access. A restricted Docker-operation interface is still needed;
agent mode never falls back to those host-shell commands.

## What the agent receives

- `/agent/TICKET.md`: the ticket, read-only.
- `/agent/dbb`: a read-only Python shim accepting `./dbb exec -- <command>`.
- `/rpc/broker.sock`: a connection to the broker; its directory is read-only.
- A writable `/tmp` with a 128 MiB limit.

The repository, solutions, `.git`, host home, workspace, supervisor source and
Docker socket are **not mounted into the agent container**. There is no host
workspace symlink. Inspect and edit lab files through `./dbb exec`: Terraform and
Ansible commands run at `/work` in a separate tool container that mounts only the
lab workspace. Server and Kubernetes commands run in the existing lab container.

The agent runs as UID/GID 65534, with dropped capabilities, no-new-privileges,
a read-only root filesystem, a 512 MiB memory limit and a 128-process limit.
The trusted supervisor has the Docker socket and is a separate container. It
accepts only command requests, and chooses the target container itself. Requests
cannot name a different target, mount or Docker API operation.

## Limits, scoring and cleanup

- `AGENT_MAX_CMDS`: default 30; counts accepted lab command requests, including
  failures and queued requests. Reservations are atomic in broker memory. Parallel
  calls cannot reset or exceed the counter; execution is serialized.
- `AGENT_TIMEOUT`: default 300 seconds; starts when the supervisor starts (after
  lab/image setup). It covers agent execution and lab command requests. Teardown
  may take additional seconds for Docker calls and broker shutdown.
- Both limits accept integers from 1 to 86400.
- Agent calls made directly to the socket use the same budget as shim calls.
  Agent reasoning and local commands do not consume lab-tool invocations.
- Command input is bounded to 64 KiB and Docker response data to 1 MiB per call.
- On exit or timeout, the entire agent container is forcibly removed, including
  detached or TERM-ignoring children. Tool containers are removed too.
- Timeout, budget exhaustion, nonzero agent exit or broker errors fail the run and
  **skip lab scoring**. This prevents unfinished lab commands from racing a check.
- Otherwise the trusted host runs the checker. Only exit 0 with passing objectives
  produces a successful result; checker errors remain distinct from an unsolved lab.
- Cleanup removes the lab resources. No learner progress is recorded.
- An active learner session or another agent runner causes refusal before startup.
  Do not run interactive `dbb` commands concurrently with agent mode.

The runner needs a local Unix-socket Docker context (Docker Desktop on macOS or a
local Linux daemon). Remote Docker contexts are not supported. After an uncatchable
SIGKILL or machine crash, inspect resources and the `.dbb/agent.lock` directory;
normal exit, INT and TERM run cleanup, but SIGKILL cannot run shell traps.

## Result format

```json
{
  "lab": "lnx-01",
  "passed": true,
  "seconds": 0.836,
  "commands_used": 1,
  "max_commands": 30,
  "agent_exit_code": 0,
  "timed_out": false,
  "budget_exceeded": false,
  "broker_error": null,
  "check_exit_code": 0,
  "check": {
    "lab": "lnx-01",
    "passed": true,
    "objectives": [{"name": "Example objective", "passed": true}]
  }
}
```

`agent_output` contains the last 200 lines of container output (up to 1 MiB), or
an unavailable/truncated notice. Treat it as untrusted text; it may contain secrets
printed by an agent, so review it before sharing results.

`check` and `check_exit_code` are null when scoring was skipped. The runner exits
0 for a passing run, 1 for a scored/agent failure, or 2 for invocation/startup errors.
The result file is written only once a supervisor report is available; startup
errors may produce no new file. Results overwrite the previous run for that lab.

## Security scope and remaining work

This removes ordinary filesystem access to reference solutions from the agent.
It is **not a security boundary against malicious lab commands**: server and k3s
labs deliberately expose powerful access inside privileged containers. Container
escapes, mounting host devices from privileged labs, or exploiting the Docker
kernel/daemon are outside this harness's protection. Use a disposable VM for
untrusted/adversarial agents. Custom images must also be trusted and must not
contain answer keys. See [SECURITY.md](../SECURITY.md).

Before calling agent mode complete for v0.3: implement constrained Docker-runtime
operations, define credential handling for real AI clients, review privileged-lab
isolation, and run the new CI tests on both architectures. No leaderboard claims
should be based on these scripted repair tests.
