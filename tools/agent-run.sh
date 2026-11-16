#!/usr/bin/env bash
# agent-run.sh — run an external AI/ops agent against a lab with solutions out of reach.
# Usage: tools/agent-run.sh <lab-id> -- <agent-command...>
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MAX_CMDS="${AGENT_MAX_CMDS:-30}"
TIMEOUT_SECS="${AGENT_TIMEOUT:-300}"

die() { printf 'agent-run: %s\n' "$*" >&2; exit 2; }

[ $# -ge 3 ] || die "usage: tools/agent-run.sh <lab-id> -- <agent-command...>"
LAB_ID="$1"; shift
[ "$1" = "--" ] || die "usage: tools/agent-run.sh <lab-id> -- <agent-command...>"
shift
[ $# -ge 1 ] || die "missing agent command after --"

LAB_DIR=""
for d in "$ROOT"/labs/"$LAB_ID"-*/; do
  [ -d "$d" ] && { LAB_DIR="${d%/}"; break; }
done
[ -n "$LAB_DIR" ] || die "unknown lab '$LAB_ID'"

ISOLATED="$(mktemp -d)"
META_DIR="$(mktemp -d)"
cleanup() {
  "$ROOT/dbb" stop >/dev/null 2>&1 || true
  rm -rf "$ISOLATED" "$META_DIR"
}
trap cleanup EXIT INT TERM

"$ROOT/dbb" start "$LAB_ID" >/dev/null || die "could not start $LAB_ID"

cp "$LAB_DIR/README.md" "$ISOLATED/TICKET.md"
if [ -d "$ROOT/workspace/$LAB_ID" ]; then
  ln -s "$ROOT/workspace/$LAB_ID" "$ISOLATED/workspace"
fi

printf '0\n' > "$META_DIR/count"
cat > "$ISOLATED/dbb" <<EOF
#!/usr/bin/env bash
set -u
COUNT_FILE="$META_DIR/count"
MAX="$MAX_CMDS"
if [ "\${1:-}" != "exec" ]; then
  echo "agent shim: only './dbb exec -- <command>' is permitted" >&2
  exit 2
fi
n="\$(cat "\$COUNT_FILE")"
if [ "\$n" -ge "\$MAX" ]; then
  echo "agent shim: command budget exceeded (\$MAX)" >&2
  exit 2
fi
printf '%s\n' "\$((n + 1))" > "\$COUNT_FILE"
exec "$ROOT/dbb" "\$@"
EOF
chmod +x "$ISOLATED/dbb"

start_ts="$(date +%s)"
(
  cd "$ISOLATED" || exit 2
  DBB_AGENT_DIR="$ISOLATED" DBB_TICKET="$ISOLATED/TICKET.md" "$@" &
  agent_pid=$!
  elapsed=0
  while kill -0 "$agent_pid" 2>/dev/null; do
    if [ "$elapsed" -ge "$TIMEOUT_SECS" ]; then
      kill "$agent_pid" 2>/dev/null || true
      break
    fi
    sleep 1
    elapsed=$((elapsed + 1))
  done
  wait "$agent_pid" 2>/dev/null || true
)
end_ts="$(date +%s)"
duration=$((end_ts - start_ts))
cmds_used="$(cat "$META_DIR/count")"

mkdir -p "$ROOT/results"
check_json="$("$ROOT/dbb" check --json 2>/dev/null || true)"
check_rc=$?
passed=false
if printf '%s' "$check_json" | grep -q '"passed":true'; then
  passed=true
fi

cat > "$ROOT/results/$LAB_ID.json" <<EOF
{
  "lab": "$LAB_ID",
  "passed": $passed,
  "seconds": $duration,
  "commands_used": $cmds_used,
  "max_commands": $MAX_CMDS,
  "check_exit_code": $check_rc,
  "check": ${check_json:-null}
}
EOF

printf 'Result written to results/%s.json (passed=%s, commands=%s/%s, seconds=%s)\n' \
  "$LAB_ID" "$passed" "$cmds_used" "$MAX_CMDS" "$duration"
[ "$passed" = true ]
