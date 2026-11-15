# shellcheck shell=bash
# core.sh — output helpers, lab lookup, state, images. bash 3.2 compatible.

DBB_DIR="$DBB_ROOT/.dbb"
# shellcheck source=/dev/null
. "$DBB_ROOT/images.lock"

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  C_RED=$'\033[31m'; C_GRN=$'\033[32m'; C_YEL=$'\033[33m'
  C_BLD=$'\033[1m'; C_DIM=$'\033[2m'; C_OFF=$'\033[0m'
else
  C_RED=""; C_GRN=""; C_YEL=""; C_BLD=""; C_DIM=""; C_OFF=""
fi

say()  { printf '%s\n' "$*"; }
info() { printf '%s\n' "${C_DIM}$*${C_OFF}" >&2; }
warn() { printf '%s\n' "${C_YEL}warning:${C_OFF} $*" >&2; }
die()  { printf '%s\n' "${C_RED}error:${C_OFF} $*" >&2; exit 2; }

# Read stdin, print it as the inside of a JSON string.
json_escape() {
  sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/	/\\t/g' | awk 'BEGIN{ORS=""} NR>1{print "\\n"} {print}'
}

# ---------- labs ----------

lab_ids() {
  local d
  for d in "$DBB_ROOT"/labs/*/; do
    [ -f "$d/lab.env" ] || continue
    d="${d%/}"; d="${d##*/}"
    printf '%s\n' "$(printf '%s' "$d" | cut -d- -f1-2)"
  done
}

lab_path() {
  local d
  for d in "$DBB_ROOT"/labs/"$1"-*/; do
    [ -f "$d/lab.env" ] && { printf '%s\n' "${d%/}"; return 0; }
  done
  return 1
}

# Sets LAB_ID LAB_DIR DBB_WORK and the lab.env variables.
lab_load() {
  [ -n "${1:-}" ] || die "which lab? try: ./dbb list"
  LAB_DIR="$(lab_path "$1")" || die "no lab called '$1'. try: ./dbb list"
  LAB_ID="$1"
  TITLE=""; TRACK=""; LEVEL=""; MINUTES=""; RUNTIME=""; TAGS=""; MAPS_TO=""
  RELEASE=""; K8S_IMAGES=""; SERVER_HOSTNAME=""
  # shellcheck source=/dev/null
  . "$LAB_DIR/lab.env"
  DBB_WORK="$DBB_ROOT/workspace/$LAB_ID"
  export LAB_ID LAB_DIR DBB_WORK
}

current_lab() {
  [ -f "$DBB_DIR/current" ] || die "no lab is running. start one: ./dbb start <id>"
  cat "$DBB_DIR/current"
}

# ---------- per-lab state (kept on the host, outside the lab) ----------

state_dir() { printf '%s\n' "$DBB_DIR/state/$LAB_ID"; }
state_set() { mkdir -p "$(state_dir)"; printf '%s\n' "$2" > "$(state_dir)/$1"; }
state_get() { cat "$(state_dir)/$1" 2>/dev/null; }

# ---------- images ----------

# "name:tag@sha256:..." -> "name:tag"
img_plain() { printf '%s\n' "${1%%@*}"; }

# Make sure name:tag exists locally, pulled by digest.
ensure_image() {
  local ref="$1" plain
  plain="$(img_plain "$ref")"
  docker image inspect "$plain" >/dev/null 2>&1 && return 0
  info "pulling $plain (first run only)"
  local try
  for try in 1 2 3; do
    if docker pull -q "$ref" >/dev/null 2>&1; then
      # name:tag@digest pulls leave the tag unset; set it so the plain name works.
      docker tag "${plain%%:*}@${ref##*@}" "$plain" 2>/dev/null \
        || docker tag "$ref" "$plain" 2>/dev/null || true
      docker image inspect "$plain" >/dev/null 2>&1 && return 0
    fi
    sleep $((try * 3))
  done
  die "could not pull $ref"
}

# ---------- runtime dispatch ----------

rt() {
  local verb="$1"; shift
  case "$RUNTIME" in
    server|k8s|terraform|docker) "${RUNTIME}_${verb}" "$@" ;;
    *) die "lab $LAB_ID has unknown RUNTIME '$RUNTIME'" ;;
  esac
}

# Remove every container, network and volume this lab created.
lab_destroy() {
  local ids
  ids="$(docker ps -aq --filter "label=dbb.lab=$LAB_ID")"
  # shellcheck disable=SC2086
  [ -z "$ids" ] || docker rm -f -v $ids >/dev/null 2>&1
  ids="$(docker network ls -q --filter "label=dbb.lab=$LAB_ID")"
  # shellcheck disable=SC2086
  [ -z "$ids" ] || docker network rm $ids >/dev/null 2>&1
  ids="$(docker volume ls -q --filter "label=dbb.lab=$LAB_ID")"
  # shellcheck disable=SC2086
  [ -z "$ids" ] || docker volume rm -f $ids >/dev/null 2>&1
  rm -rf "$DBB_WORK" "$(state_dir)"
}

lab_leftovers() {
  docker ps -aq --filter "label=dbb.lab=$LAB_ID"
  docker network ls -q --filter "label=dbb.lab=$LAB_ID"
  docker volume ls -q --filter "label=dbb.lab=$LAB_ID"
}

# Bring a lab up in its broken state. Output goes to setup.log.
lab_up() {
  lab_destroy
  mkdir -p "$(state_dir)"
  local log; log="$(state_dir)/setup.log"
  if ! ( set -e; rt start; . "$LAB_DIR/setup.sh" ) >"$log" 2>&1; then
    cat "$log" >&2
    die "lab $LAB_ID failed to start (log above)"
  fi
  date +%s > "$(state_dir)/started_at"
  echo 0 > "$(state_dir)/hints"
}

# Run check.sh: 0 = all pass, 1 = failed objectives, 2 = checker error.
# A crashed or empty checker is never evidence that a lab is broken.
lab_check() {
  DBB_RESULTS="$(state_dir)/results"
  : > "$DBB_RESULTS"
  export DBB_RESULTS
  if ! ( . "$LAB_DIR/check.sh" ) >"$(state_dir)/check.log" 2>&1; then
    printf 'FAIL\tCheck script failed; inspect .dbb/state/%s/check.log\n' "$LAB_ID" >> "$DBB_RESULTS"
    return 2
  fi
  if [ ! -s "$DBB_RESULTS" ]; then
    printf 'FAIL\tCheck script produced no objectives\n' >> "$DBB_RESULTS"
    return 2
  fi
  ! grep -q '^FAIL' "$DBB_RESULTS"
}
