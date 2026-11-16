# shellcheck shell=bash
# ansible.sh — the "ansible" runtime: controller container + Rocky managed node over SSH.
#
# Editable playbooks live in workspace/<id>/ (mounted at /work in the controller).
#
# Helpers for lab scripts:
#   ans <command> [args...]        run a command in the ansible controller
#   ans_sh '<shell script>'        run a shell snippet in the ansible controller
#   node <command> [args...]       run a command on the managed node
#   node_sh '<shell script>'       run a bash snippet on the managed node

ansible_net()  { printf 'dbb-%s-net\n' "$LAB_ID"; }
ansible_node() { printf 'dbb-%s-node\n' "$LAB_ID"; }

ansible_image() {
  docker image inspect "$DBB_ANSIBLE_IMAGE" >/dev/null 2>&1 && return 0
  ensure_image "$IMG_ANSIBLE_BASE"
  info "building $DBB_ANSIBLE_IMAGE (first run only, about a minute)"
  docker build -q -t "$DBB_ANSIBLE_IMAGE" \
    --build-arg "BASE=$(img_plain "$IMG_ANSIBLE_BASE")" \
    "$DBB_ROOT/images/ansible" >/dev/null || die "could not build $DBB_ANSIBLE_IMAGE"
}

ansible_node_booted() {
  case "$(docker exec "$(ansible_node)" systemctl is-system-running 2>/dev/null)" in
    running|degraded) return 0 ;;
    *) return 1 ;;
  esac
}

ansible_start() {
  ansible_image
  server_image
  mkdir -p "$DBB_WORK/.ssh"
  cp -R "$LAB_DIR/files/." "$DBB_WORK/"
  docker network create --label "dbb.lab=$LAB_ID" "$(ansible_net)" >/dev/null || return 2
  docker run -d --name "$(ansible_node)" --hostname managed-node \
    --network "$(ansible_net)" --network-alias managed-node \
    --label "dbb.lab=$LAB_ID" \
    --privileged --cgroupns=private --tmpfs /run --tmpfs /tmp \
    "$DBB_SERVER_IMAGE" >/dev/null
  wait_for 60 ansible_node_booted || die "managed node did not finish booting"

  # Generate an ephemeral SSH keypair for this lab and authorize it on managed-node.
  if [ ! -f "$DBB_WORK/.ssh/id_ed25519" ]; then
    ssh-keygen -q -t ed25519 -N "" -f "$DBB_WORK/.ssh/id_ed25519"
  fi
  chmod 700 "$DBB_WORK/.ssh"
  chmod 600 "$DBB_WORK/.ssh/id_ed25519"
  docker exec "$(ansible_node)" bash -c \
    'mkdir -p /root/.ssh && chmod 700 /root/.ssh && ssh-keygen -A && systemctl enable -q --now sshd'
  docker cp -q "$DBB_WORK/.ssh/id_ed25519.pub" "$(ansible_node):/root/.ssh/authorized_keys"
  docker exec "$(ansible_node)" bash -c \
    'chown root:root /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys'

  cat > "$DBB_WORK/inventory.ini" <<'EOF'
[app]
managed-node ansible_user=root ansible_ssh_private_key_file=/work/.ssh/id_ed25519 ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
EOF
}

ans_run() {
  docker run --rm --label "dbb.lab=$LAB_ID" --network "$(ansible_net)" \
    -e ANSIBLE_HOST_KEY_CHECKING=False -e ANSIBLE_NOCOLOR=1 \
    -v "$DBB_WORK:/work" -w /work "$@"
}

ans()     { ans_run "$DBB_ANSIBLE_IMAGE" "$@"; }
ans_sh()  { ans_run --entrypoint sh "$DBB_ANSIBLE_IMAGE" -c "$1"; }
node()    { docker exec "$(ansible_node)" "$@"; }
node_sh() { docker exec "$(ansible_node)" bash -c "$1"; }

# Print managed-node SSH diagnostics after a failed controller run.
ansible_diag() {
  {
    printf -- '--- managed-node sshd log ---\n'
    docker exec "$(ansible_node)" journalctl -u sshd --no-pager -n 40 2>&1 || true
    printf -- '--- managed-node state ---\n'
    docker exec "$(ansible_node)" sh -c 'systemctl is-system-running; systemctl --failed --no-legend; ls -l /run/nologin /etc/nologin; journalctl -u systemd-user-sessions --no-pager -n 15' 2>&1 || true
    printf -- '--- sshd -d on port 2222 ---\n'
    docker exec -d "$(ansible_node)" sh -c '/usr/sbin/sshd -d -o LogLevel=DEBUG3 -p 2222 >/tmp/sshd-debug.log 2>&1'
    sleep 2
    ans_run --entrypoint ssh "$DBB_ANSIBLE_IMAGE" -p 2222 -i /work/.ssh/id_ed25519 \
      -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes \
      root@managed-node true 2>&1 || true
    sleep 1
    docker exec "$(ansible_node)" sh -c 'grep -iE "pam|account|denied|selinux|shadow|expire|fatal|error" /tmp/sshd-debug.log | head -40; grep ^root: /etc/shadow; cat /etc/pam.d/password-auth | grep -v "^#"; ls -l /etc/shadow /usr/sbin/unix_chkpwd; journalctl --no-pager -n 300 | grep -iE "pam|chkpwd|sshd-session|audit" | tail -25' 2>&1 || true
    printf -- '--- /root/.ssh ---\n'
    docker exec "$(ansible_node)" ls -lan /root/.ssh 2>&1 || true
  } >&2
}

ansible_shell() {
  say "${C_DIM}Ansible controller. Playbooks: workspace/$LAB_ID (at /work). Target: managed-node. Type exit to leave.${C_OFF}"
  ans_run -it --entrypoint sh "$DBB_ANSIBLE_IMAGE"
}
ansible_exec() { ans_sh "$*"; }
