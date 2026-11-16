#!/usr/bin/env bash
# Agent commands run in a container, never in a host shell.
# shellcheck disable=SC2153,SC2317,SC2329 # lab_load sets RUNTIME; traps invoke cleanup.
set -eu
DBB_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export DBB_ROOT
for runtime in core check server k8s terraform docker ansible; do
  # shellcheck source=/dev/null
  . "$DBB_ROOT/lib/$runtime.sh"
done
MAX_CMDS="${AGENT_MAX_CMDS:-30}"
TIMEOUT_SECS="${AGENT_TIMEOUT:-300}"
AGENT_IMAGE="${AGENT_IMAGE:-$IMG_ANSIBLE_BASE}"
AGENT_NETWORK="${AGENT_NETWORK:-none}"
[ $# -ge 3 ] || die 'usage: tools/agent-run.sh <lab-id> -- <container-command...>'
id="$1"; shift
[ "$1" = -- ] || die 'expected -- before agent command'
shift
printf '%s' "$id" | grep -Eq '^[a-z0-9]+-[0-9]{2}$' || die 'invalid lab id'
for limit in "$MAX_CMDS" "$TIMEOUT_SECS"; do
  case "$limit" in ''|*[!0-9]*) die 'agent limits must be positive integers' ;; esac
  if ! { [ "$limit" -gt 0 ] && [ "$limit" -le 86400 ]; } 2>/dev/null; then
    die 'agent limits must be between 1 and 86400'
  fi
done
case "$AGENT_NETWORK" in none|bridge) ;; *) die 'AGENT_NETWORK must be none or bridge' ;; esac
case "$AGENT_IMAGE" in *@sha256:*) ;; *) die 'AGENT_IMAGE must be pinned by digest' ;; esac
lab_load "$id"
[ "$RUNTIME" != docker ] || die 'agent mode does not yet support Docker-runtime labs: host-shell access is refused'
[ ! -f "$DBB_DIR/current" ] || die 'a learner lab is active; stop it before running an agent'
docker info >/dev/null 2>&1 || die 'Docker is not running'
endpoint="${DOCKER_HOST:-$(docker context inspect --format '{{.Endpoints.docker.Host}}')}"
case "$endpoint" in unix://*) ;; *) die 'agent mode requires a local Unix-socket Docker context' ;; esac
mkdir -p "$DBB_DIR"
mkdir "$DBB_DIR/agent.lock" 2>/dev/null || die 'another agent run holds .dbb/agent.lock'
RUN_DIR=""
owned=0
cleanup() {
  if [ "$owned" = 1 ]; then
    lab_destroy
    if [ "$(cat "$DBB_DIR/current" 2>/dev/null || true)" = "$LAB_ID" ]; then rm -f "$DBB_DIR/current"; fi
  fi
  [ -z "$RUN_DIR" ] || rm -rf "$RUN_DIR"
  rmdir "$DBB_DIR/agent.lock" 2>/dev/null || true
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
# Recheck after acquiring the lock, before taking ownership of any resources.
[ ! -f "$DBB_DIR/current" ] || die 'a learner lab became active'
for image in "$IMG_ANSIBLE_BASE" "$AGENT_IMAGE"; do
  docker image inspect "$image" >/dev/null 2>&1 || docker pull "$image" >/dev/null
done
RUN_DIR="$(mktemp -d "$DBB_DIR/agent-run.XXXXXX")"
mkdir "$RUN_DIR/inputs"
chmod 755 "$RUN_DIR/inputs"
cp "$LAB_DIR/README.md" "$RUN_DIR/inputs/TICKET.md"
cp "$DBB_ROOT/tools/agent/client.py" "$RUN_DIR/inputs/dbb"
chmod 644 "$RUN_DIR/inputs/TICKET.md"
chmod 755 "$RUN_DIR/inputs/dbb"
python_tool() {
  docker run --rm --network none --label "dbb.lab=$LAB_ID" \
    -v "$DBB_ROOT/tools/agent:/runner:ro" -v "$RUN_DIR:/run" \
    "$IMG_ANSIBLE_BASE" python /runner/manage.py "$@"
}
rpc="dbb-$LAB_ID-agent-rpc"
python_tool config "$LAB_ID" "$RUNTIME" "$DBB_ROOT" "$rpc" "$AGENT_IMAGE" \
  "$AGENT_NETWORK" "$MAX_CMDS" "$TIMEOUT_SECS" "$DBB_TERRAFORM_IMAGE" \
  "$DBB_ANSIBLE_IMAGE" "$RUN_DIR" "$(id -u)" "$(id -g)" "$@"
owned=1
printf '%s\n' "$LAB_ID" > "$DBB_DIR/current"
lab_up
# lab_up removes resources by label, so create the broker volume afterwards.
docker volume create --label "dbb.lab=$LAB_ID" "$rpc" >/dev/null
# /var/run/docker.sock is the daemon-side socket on Docker Desktop; Linux/rootless
# uses the local endpoint path. The agent itself never receives this mount.
socket_path="${endpoint#unix://}"
case "$(uname -s)" in Darwin) socket_path=/var/run/docker.sock ;; esac
supervisor_rc=0
docker run --rm --name "dbb-$LAB_ID-agent-supervisor" --network none \
  --label "dbb.lab=$LAB_ID" \
  -v "$socket_path:/var/run/docker.sock" \
  -v "$DBB_ROOT/tools/agent:/runner:ro" -v "$rpc:/rpc" \
  -v "$RUN_DIR:/report" -v "$RUN_DIR/config.json:/config.json:ro" \
  "$IMG_ANSIBLE_BASE" python /runner/supervisor.py || supervisor_rc=$?
[ -f "$RUN_DIR/agent.json" ] || die "agent supervisor failed without a report (exit $supervisor_rc)"
check_rc=skipped
: > "$RUN_DIR/objectives.tsv"
# Never check a lab while a timed-out or unfinished command might still mutate it.
if [ "$supervisor_rc" = 0 ] && python_tool eligible; then
  check_rc=0
  lab_check || check_rc=$?
  cp "$DBB_RESULTS" "$RUN_DIR/objectives.tsv"
fi
result_rc=0
python_tool report "$LAB_ID" "$MAX_CMDS" "$check_rc" || result_rc=$?
mkdir -p "$DBB_ROOT/results"
cp "$RUN_DIR/result.json" "$DBB_ROOT/results/$LAB_ID.json"
printf 'Result written to results/%s.json\n' "$LAB_ID"
exit "$result_rc"
