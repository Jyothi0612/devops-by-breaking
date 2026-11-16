# ans-01 · Solution

## Root cause

All three tasks in `site.yml` use `ansible.builtin.command` (`mkdir`, `sh -c echo`,
`chmod`). `command` has no awareness of desired state and reports `changed` on every
execution here. This is not a universal limitation: `creates`/`removes` guards or
accurate `changed_when` conditions can make appropriate command tasks report changes
correctly. Declarative modules are the simplest fit for this configuration.

## How to find it

Run `ansible-playbook -i inventory.ini site.yml` twice in `workspace/ans-01` and
inspect `site.yml`. The captured output in `captures/symptom.txt` shows `changed=3`
even after `setup.sh` already ran the playbook.

## Fix

Replace the `command` tasks with declarative `ansible.builtin.file` and
`ansible.builtin.copy` tasks:

```yaml
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
```

Run `./dbb check`.

## Why the obvious fix is wrong

- `changed-when-false`: adding `changed_when: false` to `command` tasks silences the
  counter, but also hides real drift if `/opt/catalogue/app.conf` is modified or
  missing. A read-only diagnostic task may legitimately use `changed_when: false`;
  the problem is suppressing reports from tasks that actually change configuration.
- `hide-config-changes`: reporting directory creation while hiding file repairs
  still gives a misleading drift report. The check alters an existing file too.
- `delete-tasks`: removing tasks reports `changed=0`, but fails to configure the
  target host.

## Prevention

Run `ansible-lint` in CI (which flags `command-instead-of-module`) and include an
idempotency test (`molecule idempotence` or two consecutive playbook runs asserting
`changed=0`).

## In production this looks like

Drift detection alerts fire on every Ansible cron run, training operators to ignore
`changed` counts and hiding real configuration changes.

## Say it in an interview

*AI-drafted practice answer — review and adapt to your own understanding.*

“I'd compare two runs and check which tasks keep reporting changes. Here, raw commands
report changed even when the desired state is already there. I'd use file and copy
modules, then test creation, drift repair, and a second run with zero changes. Hiding
changes isn't the same as being idempotent.”

## Further reading

- [Ansible: Idempotency](https://docs.ansible.com/ansible/latest/reference_appendices/glossary.html#term-Idempotency)
- [Ansible: ansible.builtin.copy](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/copy_module.html)

- [Ansible: command module guards](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/command_module.html)
