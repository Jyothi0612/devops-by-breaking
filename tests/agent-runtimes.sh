#!/usr/bin/env bash
# Real repair through each non-server broker route. Server is covered separately.
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
case "${1:-}" in
  tf-01)
    command="$(cat <<'COMMAND'
cat >> main.tf <<'HCL'
moved {
  from = random_password.db
  to = random_password.orders_db
}
HCL
terraform apply -auto-approve
COMMAND
)" ;;
  ans-01)
    command="$(cat <<'COMMAND'
cat > site.yml <<'PLAY'
---
- hosts: app
  gather_facts: false
  tasks:
    - ansible.builtin.file:
        path: /opt/catalogue
        state: directory
        mode: "0755"
    - ansible.builtin.copy:
        dest: /opt/catalogue/app.conf
        content: "env=prod\n"
        mode: "0644"
PLAY
ansible-playbook -i inventory.ini site.yml
COMMAND
)" ;;
  k8s-01)
    command='kubectl -n shop patch svc web --type merge -p '\''{"spec":{"selector":{"app":"web"}}}'\''' ;;
  *) echo 'usage: tests/agent-runtimes.sh tf-01|ans-01|k8s-01' >&2; exit 2 ;;
esac
"$ROOT/tools/agent-run.sh" "$1" -- python -c \
  'import subprocess,sys; sys.exit(subprocess.call(["./dbb", "exec", "--", sys.argv[1]]))' "$command"
# shellcheck source=/dev/null
. "$ROOT/images.lock"
docker run --rm --network none -v "$ROOT/results:/results:ro" "$IMG_ANSIBLE_BASE" python -c \
  'import json,sys; r=json.load(open("/results/"+sys.argv[1]+".json")); assert r["passed"] and r["commands_used"] == 1, r' "$1"
[ -z "$(docker ps -aq --filter "label=dbb.lab=$1")" ]
[ -z "$(docker network ls -q --filter "label=dbb.lab=$1")" ]
[ -z "$(docker volume ls -q --filter "label=dbb.lab=$1")" ]
printf 'PASS %s broker repair and cleanup\n' "$1"
