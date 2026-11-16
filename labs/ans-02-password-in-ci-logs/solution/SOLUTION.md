# ans-02 · Solution

## Root cause

`deploy.yml` writes `db_password` using `ansible.builtin.lineinfile` and registers
the result into `db_cfg` without `no_log: true`. Under verbose CI logging (`-vvv`),
Ansible prints `invocation.module_args.line`, exposing `DBB_DEMO_ANSIBLE_PW_NOT_REAL_02`
in stdout.

## How to find it

Run the playbook with `-vvv` in `workspace/ans-02`:

```sh
ansible-playbook -i inventory.ini deploy.yml -vvv | grep DBB_DEMO_ANSIBLE_PW_NOT_REAL_02
```

## Fix

**Rotate first, then clean up:** if a real password was printed in CI logs, rotate it
and purge the CI job logs.

Add `no_log: true` to both the `lineinfile` task and the `debug` task (or remove the
`debug` task) in `workspace/ans-02/deploy.yml`, then run `./dbb check`.

## Why the obvious fix is wrong

- `remove-deploy-task`: deleting the `lineinfile` task stops the leak, but never
  deploys `/etc/orders-db.env`.
- `empty-password`: clearing `db_password` breaks the deployed application config.

## Prevention

Enforce `no_log: true` on every task that handles credentials (`ansible-lint`
`no-log-password` rule) and scan CI logs for secret patterns.

## In production this looks like

An engineer enables `-vvv` in a CI pipeline to debug an unrelated SSH issue, and
every database password or API token in `lineinfile`/`uri`/`command` tasks is
archived in build logs.

## Say it in an interview

Author gate pending: write your own 15-second answer after solving blind. Cover why
`no_log: true` is needed on secret tasks, why `register` + `debug` amplifies leaks,
and why you rotate first when a secret hits CI logs.

## Further reading

- [Ansible: Protecting sensitive data with no_log](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_filters.html)
