#!/usr/bin/env bash
# Docker integration regression: legitimate read-only tasks must remain valid.
set -eu
DBB_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export DBB_ROOT
for runtime in core check server k8s terraform docker ansible; do
  # shellcheck source=/dev/null
  . "$DBB_ROOT/lib/$runtime.sh"
done
# Never reset or stop an existing learner session.
[ ! -f "$DBB_DIR/current" ] || { echo 'Stop the active lab before this integration test.' >&2; exit 2; }
started=0
cleanup() {
  if [ "$started" = 1 ]; then "$DBB_ROOT/dbb" stop; fi
}
trap cleanup EXIT
"$DBB_ROOT/dbb" start ans-01 >/dev/null
started=1
lab_load ans-01
# shellcheck source=/dev/null
. "$LAB_DIR/solution/fix.sh"
cat >> "$DBB_WORK/site.yml" <<'PLAY'

    - name: Inspect the configured file without changing it
      ansible.builtin.command: cat /opt/catalogue/app.conf
      changed_when: false
PLAY
# Use the checker directly so automated validation never records a learner solve.
rc=0
lab_check || rc=$?
cat "$DBB_RESULTS"
[ "$rc" = 0 ]
printf 'PASS valid read-only changed_when false task is accepted\n'
