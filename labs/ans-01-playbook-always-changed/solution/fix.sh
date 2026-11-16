# shellcheck shell=bash
cat > "$DBB_WORK/site.yml" <<'EOF'
---
- name: Configure catalogue app
  hosts: app
  gather_facts: false
  tasks:
    - name: Ensure /opt/catalogue directory exists
      ansible.builtin.file:
        path: /opt/catalogue
        state: directory
        mode: "0755"

    - name: Write app configuration
      ansible.builtin.copy:
        dest: /opt/catalogue/app.conf
        content: "env=prod\n"
        mode: "0644"
EOF
ans ansible-playbook -i inventory.ini site.yml >/dev/null
