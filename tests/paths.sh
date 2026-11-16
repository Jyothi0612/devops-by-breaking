#!/usr/bin/env bash
# Learning paths must use real lab lookup and exact names, with isolated progress.
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT
cp "$ROOT/dbb" "$ROOT/images.lock" "$TEST_DIR/"
cp -R "$ROOT/lib" "$ROOT/docs" "$ROOT/labs" "$TEST_DIR/"
mkdir "$TEST_DIR/.dbb"
bash "$TEST_DIR/dbb" next --path first-10 | grep -q 'Next: lnx-01 '
printf 'PASS fresh learning path suggests its first lab\n'
printf 'lnx-01 20 0\n' > "$TEST_DIR/.dbb/progress"
bash "$TEST_DIR/dbb" next --path first-10 | grep -q 'Next: lnx-03 '
printf 'PASS learning path skips a solved lab\n'
actual=0
bash "$TEST_DIR/dbb" next --path '.*' > /dev/null 2>&1 || actual=$?
[ "$actual" = 2 ]
printf 'PASS path names are matched literally\n'
for id in lnx-03 lnx-05 net-01 ctr-01 ctr-02 k8s-01 k8s-02 k8s-06 tf-01; do
  printf '%s 20 0\n' "$id" >> "$TEST_DIR/.dbb/progress"
done
bash "$TEST_DIR/dbb" next --path first-10 | grep -q 'solved every available lab'
printf 'PASS completed path reports completion\n'
