#!/usr/bin/env bash
# lint-lab.sh — every lab must meet the same bar. Run: tools/lint-lab.sh
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
bad=0
err() { printf '  %s: %s\n' "$1" "$2"; bad=1; }

for dir in "$ROOT"/labs/*/; do
  dir="${dir%/}"; name="${dir##*/}"
  [ -f "$dir/lab.env" ] || { err "$name" "missing lab.env"; continue; }

  printf '%s' "$name" | grep -Eq '^[a-z0-9]+-[0-9]{2}-[a-z0-9-]+$' \
    || err "$name" "folder must be <track>-<nn>-<symptom-slug>"

  for key in TITLE TRACK LEVEL MINUTES RUNTIME MAPS_TO RELEASE; do
    grep -q "^$key=" "$dir/lab.env" || err "$name" "lab.env is missing $key"
  done
  grep -q '^TAGS=' "$dir/lab.env" || err "$name" "lab.env is missing TAGS (may be empty)"

  for f in README.md setup.sh check.sh hints.txt solution/SOLUTION.md solution/fix.sh; do
    [ -s "$dir/$f" ] || err "$name" "missing or empty $f"
  done

  for h in "## The ticket" "## What you see" "## Your goal" "## Predict first" "## Skills you'll practise"; do
    grep -qF "$h" "$dir/README.md" 2>/dev/null || err "$name" "README.md is missing section: $h"
  done

  for h in "## Root cause" "## How to find it" "## Fix" "## Why the obvious fix is wrong" \
           "## Prevention" "## In production this looks like" "## Say it in an interview" "## Further reading"; do
    grep -qF "$h" "$dir/solution/SOLUTION.md" 2>/dev/null || err "$name" "SOLUTION.md is missing section: $h"
  done

  if [ -f "$dir/hints.txt" ]; then
    [ "$(grep -c '^---$' "$dir/hints.txt")" = 2 ] || err "$name" "hints.txt must hold exactly 3 hints separated by ---"
  fi

  ls "$dir"/solution/cheats/*.sh >/dev/null 2>&1 || err "$name" "needs at least one solution/cheats/*.sh"
  ls "$dir"/captures/* >/dev/null 2>&1 || err "$name" "needs real captured output in captures/"

  [ "$(grep -c 'check "' "$dir/check.sh" 2>/dev/null)" -ge 2 ] || err "$name" "check.sh needs at least 2 objectives"

  # The README must not give the answer away.
  grep -qiE 'root cause|## fix' "$dir/README.md" 2>/dev/null && err "$name" "README.md mentions the root cause or fix"
done

if [ "$bad" = 0 ]; then echo "lint-lab: all labs meet the bar"; fi
exit "$bad"
