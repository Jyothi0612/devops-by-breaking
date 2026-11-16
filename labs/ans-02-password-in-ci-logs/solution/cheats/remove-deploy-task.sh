# shellcheck shell=bash
cat > "$DBB_WORK/deploy.yml" <<'EOF'
---
- name: Deploy database credentials
  hosts: app
  gather_facts: false
  tasks:
    - name: Log deployment result
      ansible.builtin.debug:
        msg: "deployed"
EOF
