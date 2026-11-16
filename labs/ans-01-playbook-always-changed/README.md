# ans-01 · Playbook reports `changed` on every run

Ansible · Level 1 · about 15 min · Maps to: RHCE-style (Ansible playbooks and idempotency)

## The ticket

> **CI Drift Alert — `site.yml` — playbook never converges to `changed=0`**
>
> Every scheduled Ansible run against `managed-node` reports `changed=3`, even when
> nothing on the host has changed.

## What you see

```
$ ansible-playbook -i inventory.ini site.yml

PLAY [Configure catalogue app] *************************************************

TASK [Ensure /opt/catalogue directory exists] **********************************
changed: [managed-node]

TASK [Write app configuration] *************************************************
changed: [managed-node]

TASK [Set config permissions] **************************************************
changed: [managed-node]

PLAY RECAP *********************************************************************
managed-node               : ok=3    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

## Your goal

`./dbb check` verifies each of these:

- [ ] Missing `/opt/catalogue/app.conf` is created with `env=prod`, mode `0644`, and the run reports a change
- [ ] Content and permission drift is repaired and reported; the following run reports `changed=0`

The check deliberately removes and alters this lab's configuration to test repair.
Read-only tasks may use `changed_when: false`; actual configuration changes must
still be reported.

## Predict first

Before you type anything: why does running `site.yml` twice in a row still report
`changed=3` on the second run?

## Skills you'll practise

Ansible idempotency · `ansible.builtin.file` · `ansible.builtin.copy` · replacing `command` tasks with declarative modules
