# shellcheck shell=bash
# check.sh — helpers used inside a lab's check.sh.
#
#   check "what must be true" command [args...]
#   wait_for <seconds> command [args...]      retry until it succeeds
#
# A check never prints a hint about the fix. It only says what is not true yet.

check() {
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then
    printf 'PASS\t%s\n' "$desc" >> "$DBB_RESULTS"
  else
    printf 'FAIL\t%s\n' "$desc" >> "$DBB_RESULTS"
  fi
}

wait_for() {
  local secs="$1"; shift
  local end=$(( $(date +%s) + secs ))
  while :; do
    "$@" >/dev/null 2>&1 && return 0
    [ "$(date +%s)" -ge "$end" ] && return 1
    sleep 1
  done
}
