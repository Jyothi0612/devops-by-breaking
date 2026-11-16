# shellcheck shell=bash
catalogue_correct() {
  node_sh 'test -d /opt/catalogue && grep -qx "env=prod" /opt/catalogue/app.conf && [ "$(stat -c %a /opt/catalogue/app.conf)" = "644" ]'
}

# Only the managed host's recap counts, not task names or diagnostic output.
reported_changes() {
  printf '%s\n' "$1" | awk '
    /^PLAY RECAP / { recap=1; next }
    recap && /^managed-node[[:space:]]*:/ {
      for (i=1; i<=NF; i++) if ($i ~ /^changed=[0-9]+$/) {
        sub(/^changed=/, "", $i); print $i; exit
      }
    }'
}

creates_and_reports() {
  local out count
  node_sh 'rm -rf /opt/catalogue' || return 1
  out="$(ans ansible-playbook -i inventory.ini site.yml 2>&1)" || return 1
  catalogue_correct || return 1
  count="$(reported_changes "$out")"
  [ -n "$count" ] && [ "$count" -gt 0 ]
}

repairs_drift_and_converges() {
  local out count
  node_sh 'mkdir -p /opt/catalogue; printf "env=broken\n" > /opt/catalogue/app.conf; chmod 0600 /opt/catalogue/app.conf' || return 1
  out="$(ans ansible-playbook -i inventory.ini site.yml 2>&1)" || return 1
  catalogue_correct || return 1
  count="$(reported_changes "$out")"
  [ -n "$count" ] && [ "$count" -gt 0 ] || return 1
  out="$(ans ansible-playbook -i inventory.ini site.yml 2>&1)" || return 1
  catalogue_correct || return 1
  [ "$(reported_changes "$out")" = 0 ]
}

check "Missing configuration is created correctly and reports a change" creates_and_reports
check "Content and permission drift is repaired and reported; the next run reports changed=0" repairs_drift_and_converges
