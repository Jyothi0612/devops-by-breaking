#!/usr/bin/env bash
# gen-index.sh — rebuild the lab table in README.md from labs/*/lab.env.
#   tools/gen-index.sh           rewrite README.md
#   tools/gen-index.sh --check   fail if README.md is out of date
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp)"; out="$(mktemp)"
{
  echo "| Lab | Track | Level | Time | The symptom |"
  echo "|---|---|---|---|---|"
  for dir in "$ROOT"/labs/*/; do
    dir="${dir%/}"; name="${dir##*/}"
    [ -f "$dir/lab.env" ] || continue
    ( . "$dir/lab.env"
      id="$(printf '%s' "$name" | cut -d- -f1-2)"
      printf '| [%s](labs/%s/) | %s | L%s | %s min | %s |\n' "$id" "$name" "$TRACK" "$LEVEL" "$MINUTES" "$TITLE" )
  done
} > "$tmp"
awk -v table="$tmp" '
  /<!-- catalog:start -->/ { print; while ((getline line < table) > 0) print line; skip=1; next }
  /<!-- catalog:end -->/   { skip=0 }
  !skip { print }
' "$ROOT/README.md" > "$out"
if [ "${1:-}" = "--check" ]; then
  cmp -s "$out" "$ROOT/README.md" || { echo "README.md lab table is out of date. Run tools/gen-index.sh"; rm -f "$tmp" "$out"; exit 1; }
  echo "gen-index: README.md is up to date"
else
  cat "$out" > "$ROOT/README.md"; echo "gen-index: README.md updated"
fi
rm -f "$tmp" "$out"
