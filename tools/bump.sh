#!/usr/bin/env bash
# bump.sh — re-resolve the digest of every tag in images.lock.
# To move to a new version: edit the TAG in images.lock, then run this.
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp)"
while IFS= read -r line; do
  case "$line" in
    IMG_*=*)
      key="${line%%=*}"; ref="${line#*=}"; ref="${ref%\"}"; ref="${ref#\"}"
      plain="${ref%%@*}"
      digest="$(docker buildx imagetools inspect "$plain" --format '{{.Manifest.Digest}}')"
      printf '%s="%s@%s"\n' "$key" "$plain" "$digest" >> "$tmp"
      echo "$plain -> $digest" >&2
      ;;
    *) printf '%s\n' "$line" >> "$tmp" ;;
  esac
done < "$ROOT/images.lock"
cat "$tmp" > "$ROOT/images.lock"; rm -f "$tmp"
