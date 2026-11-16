# shellcheck shell=bash
cat > "$DBB_WORK/site.yml" <<'EOF'
---
- name: Configure catalogue app
  hosts: app
  gather_facts: false
  tasks: []
EOF
