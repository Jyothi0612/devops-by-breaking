# shellcheck shell=bash
# verify.sh — the proof. For one lab:
#
#   1. start it                        → check must FAIL   (it really is broken)
#   2. for every solution/cheats/*.sh  → check must FAIL   (shortcuts are rejected)
#   3. run solution/fix.sh             → check must PASS   (it really can be fixed)
#   4. run survive.sh if the lab has one → check must PASS (the fix lasts)
#   5. stop it                         → nothing may be left behind
#
# Any deviation fails the run. CI runs this for every lab on every push.

v_line() { printf '  %-52s %s\n' "$1" "$2"; }

verify_one() {
  local id="$1" cheat name bad=0 t0 rc
  t0="$(date +%s)"
  lab_load "$id"
  say "${C_BLD}verify $id${C_OFF}  $TITLE"

  lab_up
  rc=0; lab_check || rc=$?
  case "$rc" in
    1) v_line "starts broken" "${C_GRN}yes${C_OFF}" ;;
    0) v_line "starts broken" "${C_RED}NO: check passes on a fresh lab${C_OFF}"; bad=1 ;;
    *) v_line "starts broken" "${C_RED}NO: checker error${C_OFF}"; bad=1 ;;
  esac

  local found=0
  for cheat in "$LAB_DIR"/solution/cheats/*.sh; do
    [ -f "$cheat" ] || continue
    found=1
    name="${cheat##*/}"; name="${name%.sh}"
    lab_up
    if ! ( . "$cheat" ) >"$(state_dir)/cheat.log" 2>&1; then
      v_line "rejects shortcut: $name" "${C_RED}NO: shortcut script failed${C_OFF}"
      cat "$(state_dir)/cheat.log" >&2; bad=1
      continue
    fi
    # A shortcut must stay rejected, not just fail while things settle.
    sleep 3
    rc=0; lab_check || rc=$?
    if [ "$rc" = 1 ]; then
      sleep 8
      rc=0; lab_check || rc=$?
    fi
    case "$rc" in
      1) v_line "rejects shortcut: $name" "${C_GRN}yes${C_OFF}" ;;
      0) v_line "rejects shortcut: $name" "${C_RED}NO: the shortcut passes${C_OFF}"; bad=1 ;;
      *) v_line "rejects shortcut: $name" "${C_RED}NO: checker error${C_OFF}"; bad=1 ;;
    esac
    [ -z "${DBB_VERBOSE:-}" ] || grep '^FAIL' "$DBB_RESULTS" | sed 's/^FAIL./      fails: /'
  done
  [ "$found" = 1 ] || { v_line "has at least one cheat" "${C_RED}NO${C_OFF}"; bad=1; }

  lab_up
  if ! ( set -e; . "$LAB_DIR/solution/fix.sh" ) >"$(state_dir)/fix.log" 2>&1; then
    v_line "fix.sh runs" "${C_RED}NO${C_OFF}"; cat "$(state_dir)/fix.log" >&2; bad=1
  fi
  if wait_for 60 lab_check; then v_line "fix passes the check" "${C_GRN}yes${C_OFF}"
  else
    v_line "fix passes the check" "${C_RED}NO${C_OFF}"; bad=1
    sed 's/^/      /' "$DBB_RESULTS" >&2
  fi

  if [ -f "$LAB_DIR/survive.sh" ]; then
    if ! ( . "$LAB_DIR/survive.sh" ) >"$(state_dir)/survive.log" 2>&1; then
      v_line "restart script runs" "${C_RED}NO${C_OFF}"
      cat "$(state_dir)/survive.log" >&2; bad=1
    elif wait_for 90 lab_check; then v_line "fix survives a restart" "${C_GRN}yes${C_OFF}"
    else
      v_line "fix survives a restart" "${C_RED}NO${C_OFF}"; bad=1
      sed 's/^/      /' "$DBB_RESULTS" >&2
    fi
  fi

  lab_destroy
  if [ -n "$(lab_leftovers)" ]; then v_line "cleans up" "${C_RED}NO: resources left behind${C_OFF}"; bad=1
  else v_line "cleans up" "${C_GRN}yes${C_OFF}"; fi

  say "  ${C_DIM}$(( $(date +%s) - t0 )) s${C_OFF}"
  return $bad
}

cmd_verify() {
  [ $# -gt 0 ] || die "usage: ./dbb verify <id> [<id>...] | all"
  need_docker
  [ -f "$DBB_DIR/current" ] && die "a lab is running ($(cat "$DBB_DIR/current")). ./dbb stop first"
  local ids="" id failed=""
  if [ "$1" = all ]; then ids="$(lab_ids)"; else ids="$*"; fi
  for id in $ids; do
    ( verify_one "$id" ) || failed="$failed $id"
  done
  say ""
  if [ -n "$failed" ]; then say "${C_RED}FAILED:${C_OFF}$failed"; return 1; fi
  say "${C_GRN}All verified.${C_OFF}"
}
