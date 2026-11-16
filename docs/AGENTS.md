# Agent Mode (`tools/agent-run.sh`)

Run any CLI or AI ops agent against any `devops-by-breaking` lab and record a
machine-readable score in `results/<id>.json`.

This is a **laptop-scale smoke test** for troubleshooting agents, not a full
microservice research benchmark (see SREGym, ITBench, or AIOpsLab for those).

## How it works

```sh
tools/agent-run.sh <lab-id> -- <agent-command...>
```

1. Starts `<lab-id>` with `./dbb start <lab-id>`.
2. Creates a temporary directory containing **only**:
   - `TICKET.md` (the lab's `README.md`)
   - `./dbb` (a shim that allows **only** `./dbb exec -- <command>`)
   - `workspace/` (symlinked only if the lab uses a host workspace)
   - No `labs/`, no `solution/`, and no `.git/` history are exposed.
3. Enforces `AGENT_TIMEOUT` (default `300` seconds) and `AGENT_MAX_CMDS` (default
   `30` invocations of `./dbb exec`).
4. Runs `./dbb check --json` and writes `results/<lab-id>.json`.
5. Stops and cleans up the lab environment.

## Worked example

```sh
AGENT_MAX_CMDS=15 AGENT_TIMEOUT=120 \
  tools/agent-run.sh lnx-01 -- sh -c './dbb exec -- "systemctl reload orders-api"'
```

## Output schema (`results/<id>.json`)

```json
{
  "lab": "lnx-01",
  "passed": true,
  "seconds": 3,
  "commands_used": 1,
  "max_commands": 15,
  "check_exit_code": 0,
  "check": {
    "lab": "lnx-01",
    "passed": true,
    "objectives": [
      { "name": "...", "passed": true }
    ]
  }
}
```
