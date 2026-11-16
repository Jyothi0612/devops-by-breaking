# ans-02 · Database password appears in CI logs

Ansible · Level 2 · about 20 min · Maps to: RHCE-style (Ansible secrets and security), DevSecOps · Tags: security

## The ticket

> **Security Alert — `deploy.yml` — database password leaked in CI output**
>
> A verbose CI run (`ansible-playbook -i inventory.ini deploy.yml -vvv`) printed
> `DBB_DEMO_ANSIBLE_PW_NOT_REAL_02` in the job logs.

## What you see

```
$ ansible-playbook -i inventory.ini deploy.yml

PLAY [Deploy database credentials] *********************************************

TASK [Write database env file] *************************************************
ok: [managed-node]

TASK [Log deployment result] ***************************************************
ok: [managed-node] => {
    "db_cfg": {
        ...
    }
}
```

(With `-vvv`, Ansible's `invocation.module_args.line` prints `DB_PASS=DBB_DEMO_ANSIBLE_PW_NOT_REAL_02`.)

## Your goal

`./dbb check` verifies each of these:

- [ ] Verbose playbook run (`-vvv`) does not leak `DBB_DEMO_ANSIBLE_PW_NOT_REAL_02`
- [ ] `/etc/orders-db.env` is deployed with `DB_PASS=DBB_DEMO_ANSIBLE_PW_NOT_REAL_02` and mode `0600`

## Predict first

Before you type anything: why does Ansible suppress module arguments only when a
task explicitly sets `no_log: true`, even if a variable looks like a password?

## Skills you'll practise

Ansible `no_log: true` · `-vvv` invocation logging · `register` + `debug` secret leakage · secret hygiene in CI
