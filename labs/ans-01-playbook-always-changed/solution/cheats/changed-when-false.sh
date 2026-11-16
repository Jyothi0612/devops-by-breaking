# shellcheck shell=bash
cat > "$DBB_WORK/site.yml" <<'EOF'
---
- name: Configure catalogue app
  hosts: app
  gather_facts: false
  tasks:
    - name: Ensure /opt/catalogue directory exists
      ansible.builtin.command: mkdir -p /opt/catalogue
      changed_when: false

    - name: Write app configuration
      ansible.builtin.command: sh -c 'echo "env=prod" > /opt/catalogue/app.conf'
      changed_when: false

    - name: Set config permissions
      ansible.builtin.command: chmod 0644 /opt/catalogue/app.conf
      changed_when: false
EOF
