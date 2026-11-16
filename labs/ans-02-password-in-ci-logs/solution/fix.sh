# shellcheck shell=bash
cat > "$DBB_WORK/deploy.yml" <<'EOF'
---
- name: Deploy database credentials
  hosts: app
  gather_facts: false
  vars:
    db_password: "DBB_DEMO_ANSIBLE_PW_NOT_REAL_02"
  tasks:
    - name: Write database env file
      ansible.builtin.lineinfile:
        path: /etc/orders-db.env
        create: true
        regexp: "^DB_PASS="
        line: "DB_PASS={{ db_password }}"
        mode: "0600"
      no_log: true
      register: db_cfg

    - name: Log deployment result
      ansible.builtin.debug:
        var: db_cfg
      no_log: true
EOF
ans ansible-playbook -i inventory.ini deploy.yml >/dev/null
