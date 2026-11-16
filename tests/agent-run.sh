#!/usr/bin/env bash
# Fail-closed input checks do not require Docker or touch learner state.
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
expect_error() {
  local rc=0
  "$@" >/dev/null 2>&1 || rc=$?
  [ "$rc" = 2 ] || { echo "expected exit 2, got $rc"; exit 1; }
}
for limit in 0 -1 invalid 999999999999999999999999; do
  expect_error env AGENT_MAX_CMDS="$limit" bash "$ROOT/tools/agent-run.sh" lnx-01 -- true
  expect_error env AGENT_TIMEOUT="$limit" bash "$ROOT/tools/agent-run.sh" lnx-01 -- true
  printf 'PASS invalid agent limit %s rejected\n' "$limit"
done
expect_error bash "$ROOT/tools/agent-run.sh" '../lnx-01' -- true
expect_error env AGENT_IMAGE=python:latest bash "$ROOT/tools/agent-run.sh" lnx-01 -- true
expect_error env AGENT_NETWORK=host bash "$ROOT/tools/agent-run.sh" lnx-01 -- true
expect_error bash "$ROOT/tools/agent-run.sh" ctr-01 -- true
printf 'PASS invalid IDs, unpinned images, host networking and host-shell labs rejected\n'
