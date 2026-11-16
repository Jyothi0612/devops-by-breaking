#!/usr/bin/env bash
# Real Docker boundary tests. Runs short server labs, never records learner progress.
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=/dev/null
. "$ROOT/images.lock"
assert_report() {
  docker run --rm --network none -v "$ROOT/results:/results:ro" "$IMG_ANSIBLE_BASE" \
    python -c 'import json,sys; r=json.load(open("/results/lnx-01.json")); assert eval(sys.argv[1], {"r":r}), r' "$1"
}
run_status() {
  local expected="$1" actual=0; shift
  "$@" || actual=$?
  [ "$actual" = "$expected" ] || { echo "expected $expected, got $actual" >&2; exit 1; }
}
# Prove the agent cannot see source, solutions, its broker's files, or host Docker.
# Also prove a valid repair passes through the broker.
run_status 0 "$ROOT/tools/agent-run.sh" lnx-01 -- sh -c '
  test "$(id -u)" = 65534 &&
  test ! -e /var/run/docker.sock && test ! -e /runner && test ! -e /report &&
  test ! -e /agent/labs && test ! -e /agent/.git && test ! -e /agent/workspace &&
  test -f /agent/TICKET.md &&
  ! touch /agent/forbidden 2>/dev/null &&
  ./dbb exec -- "systemctl reload orders-api"'
assert_report 'r["passed"] and r["commands_used"] == 1 and r["check_exit_code"] == 0'
echo 'PASS isolated agent repairs a lab without repository or Docker mounts'

# Concurrent calls go directly through the socket so the shim cannot hide a race.
run_status 1 env AGENT_MAX_CMDS=3 "$ROOT/tools/agent-run.sh" lnx-01 -- python -c '
import concurrent.futures,json,socket

def call(_):
    with socket.socket(socket.AF_UNIX) as s:
        s.connect("/rpc/broker.sock")
        s.sendall(b"{\"command\":\"true\"}\n")
        data=b""
        while b"\n" not in data:
            data += s.recv(65536)
        return json.loads(data)["exit_code"]
with concurrent.futures.ThreadPoolExecutor(max_workers=12) as pool:
    codes=list(pool.map(call,range(12)))
assert codes.count(0) == 3, codes
'
assert_report 'not r["passed"] and r["commands_used"] == 3 and r["budget_exceeded"] and r["check"] is None'
echo 'PASS concurrent requests cannot exceed the broker budget'

# Even a repaired lab cannot pass once the agent exceeds its wall-clock deadline.
run_status 1 env AGENT_TIMEOUT=2 "$ROOT/tools/agent-run.sh" lnx-01 -- python -c '
import os,signal,subprocess,time
subprocess.run(["./dbb","exec","--","systemctl reload orders-api"],check=True)
if os.fork() == 0:
    os.setsid()
    signal.signal(signal.SIGTERM,signal.SIG_IGN)
    time.sleep(1000)
time.sleep(1000)
'
assert_report 'not r["passed"] and r["timed_out"] and r["check"] is None'
echo 'PASS timeout fails scoring and destroys detached TERM-ignoring agent children'

run_status 1 "$ROOT/tools/agent-run.sh" lnx-01 -- sh -c './dbb exec -- "systemctl reload orders-api"; exit 7'
assert_report 'not r["passed"] and r["agent_exit_code"] == 7 and r["check"] is None'
echo 'PASS failed agent cannot turn a repaired lab into a successful run'

# Refuse to take over an existing learner session, even the same lab.
"$ROOT/dbb" start lnx-01 >/dev/null
trap '"$ROOT/dbb" stop >/dev/null' EXIT
run_status 2 "$ROOT/tools/agent-run.sh" lnx-01 -- true
[ "$(cat "$ROOT/.dbb/current")" = lnx-01 ]
[ "$(docker inspect -f '{{.State.Running}}' dbb-lnx-01-server)" = true ]
"$ROOT/dbb" stop >/dev/null
trap - EXIT
echo 'PASS existing learner session is preserved'
[ -z "$(docker ps -aq --filter label=dbb.lab=lnx-01)" ]
[ -z "$(docker network ls -q --filter label=dbb.lab=lnx-01)" ]
[ -z "$(docker volume ls -q --filter label=dbb.lab=lnx-01)" ]
echo 'PASS all agent containers, networks and volumes cleaned up'
