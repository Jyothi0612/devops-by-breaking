#!/usr/bin/env bash
# shellcheck disable=SC2317,SC2329 # Runtime overrides are invoked by sourced verify_one.
# Regression tests for false-green proofs. No Docker or learner state is touched.
set -u
DBB_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export DBB_ROOT
# shellcheck source=/dev/null
. "$DBB_ROOT/lib/core.sh"
# shellcheck source=/dev/null
. "$DBB_ROOT/lib/check.sh"
# shellcheck source=/dev/null
. "$DBB_ROOT/lib/verify.sh"
TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT
DBB_DIR="$TEST_DIR/state"
LAB_DIR="$TEST_DIR/lab"
LAB_ID=test-01
mkdir -p "$(state_dir)" "$LAB_DIR/solution/cheats"
bad=0
expect_status() {
  local expected="$1" description="$2" rc=0; shift 2
  "$@" >"$TEST_DIR/output" 2>&1 || rc=$?
  if [ "$rc" = "$expected" ]; then printf 'PASS %s\n' "$description"
  else
    printf 'FAIL %s: expected %s, got %s\n' "$description" "$expected" "$rc"
    cat "$TEST_DIR/output"; bad=1
  fi
}

printf 'check "healthy" true\n' > "$LAB_DIR/check.sh"
expect_status 0 'healthy objectives pass' lab_check
printf 'check "broken" false\n' > "$LAB_DIR/check.sh"
expect_status 1 'failed objective is a normal lab failure' lab_check
printf 'check "healthy" true\nexit 7\n' > "$LAB_DIR/check.sh"
expect_status 2 'crash after PASS is a checker error' lab_check
: > "$LAB_DIR/check.sh"
expect_status 2 'empty checker is an error' lab_check
printf 'check "broken" false\nexit 7\n' > "$LAB_DIR/check.sh"
expect_status 2 'crash after FAIL is still a checker error' lab_check

# Exercise the actual verifier with a small file-backed lab and instant retries.
lab_load() { TITLE='proof fixture'; }
lab_up() { echo broken > "$TEST_DIR/mode"; }
lab_destroy() { :; }
lab_leftovers() { :; }
sleep() { :; }
wait_for() { shift; "$@"; }
cat > "$LAB_DIR/check.sh" <<'CHECK'
check "fixture repaired" test "$(cat "$TEST_DIR/mode")" = fixed
CHECK
printf 'echo fixed > "$TEST_DIR/mode"\n' > "$LAB_DIR/solution/fix.sh"
printf ':\n' > "$LAB_DIR/solution/cheats/noop.sh"
printf ':\n' > "$LAB_DIR/survive.sh"
expect_status 0 'valid broken/cheat/fix/restart sequence passes' verify_one test-01
printf 'exit 7\n' > "$LAB_DIR/solution/cheats/noop.sh"
expect_status 1 'failed cheat execution cannot prove rejection' verify_one test-01
printf ':\n' > "$LAB_DIR/solution/cheats/noop.sh"
printf 'exit 7\n' > "$LAB_DIR/survive.sh"
expect_status 1 'failed restart cannot prove durability' verify_one test-01
printf ':\n' > "$LAB_DIR/survive.sh"
cat > "$LAB_DIR/check.sh" <<'CHECK'
if [ "$(cat "$TEST_DIR/mode")" = broken ]; then exit 7; fi
check "fixture repaired" true
CHECK
expect_status 1 'checker errors cannot prove broken or cheat states' verify_one test-01
# Exercise the public CLI as well: error status must survive JSON formatting and
# must never record a solve. The fake Docker executable only satisfies readiness.
mkdir -p "$TEST_DIR/cli/lib" "$TEST_DIR/cli/labs/test-01-fixture" \
  "$TEST_DIR/cli/.dbb/state/test-01" "$TEST_DIR/bin"
cp "$DBB_ROOT/dbb" "$DBB_ROOT/images.lock" "$TEST_DIR/cli/"
cp "$DBB_ROOT"/lib/*.sh "$TEST_DIR/cli/lib/"
printf '#!/usr/bin/env bash\nexit 0\n' > "$TEST_DIR/bin/docker"
chmod +x "$TEST_DIR/bin/docker"
printf 'test-01\n' > "$TEST_DIR/cli/.dbb/current"
printf 'RUNTIME=server\n' > "$TEST_DIR/cli/labs/test-01-fixture/lab.env"
printf 'check "healthy" true\nexit 7\n' > "$TEST_DIR/cli/labs/test-01-fixture/check.sh"
expect_status 2 'check --json preserves checker error exit code' \
  env PATH="$TEST_DIR/bin:$PATH" bash "$TEST_DIR/cli/dbb" check --json
# Save the output before expect_status overwrites its capture file.
cp "$TEST_DIR/output" "$TEST_DIR/json"
expect_status 0 'checker error JSON reports passed false' \
  grep -q '"passed":false' "$TEST_DIR/json"
expect_status 0 'checker error never marks lab solved' \
  test ! -f "$TEST_DIR/cli/.dbb/progress"
exit "$bad"
