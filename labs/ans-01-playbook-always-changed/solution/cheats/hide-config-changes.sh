# shellcheck shell=bash
# Directory creation still reports changed, but configuration repairs are hidden.
cat > "$DBB_WORK/site.yml" <<'PLAY'
---
- name: Configure catalogue app
  hosts: app
  gather_facts: false
  tasks:
    - name: Ensure directory exists
      ansible.builtin.file:
        path: /opt/catalogue
        state: directory
        mode: "0755"
    - name: Write configuration
      ansible.builtin.copy:
        dest: /opt/catalogue/app.conf
        content: "env=prod\n"
        mode: "0644"
      changed_when: false
PLAY
