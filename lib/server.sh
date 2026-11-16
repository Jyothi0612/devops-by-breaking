# shellcheck shell=bash
# server.sh — the "server" runtime: Rocky Linux 9 with real systemd, in one container.
#
# Helpers for lab scripts:
#   srv <command> [args...]        run a command on the server
#   srv_sh '<shell script>'        run a bash snippet on the server
#   srv_put <file-in-files/> <path-on-server>

server_name() { printf 'dbb-%s-server\n' "$LAB_ID"; }

server_image() {
  docker image inspect "$DBB_SERVER_IMAGE" >/dev/null 2>&1 && return 0
  if [ -n "${DBB_SERVER_GHCR:-}" ] && docker pull -q "$DBB_SERVER_GHCR" >/dev/null 2>&1; then
    docker tag "$DBB_SERVER_GHCR" "$DBB_SERVER_IMAGE" >/dev/null 2>&1 && return 0
  fi
  ensure_image "$IMG_SERVER_BASE"
  info "building $DBB_SERVER_IMAGE (first run only, about a minute)"
  docker build -q -t "$DBB_SERVER_IMAGE" \
    --build-arg "BASE=$(img_plain "$IMG_SERVER_BASE")" \
    "$DBB_ROOT/images/server" >/dev/null || die "could not build $DBB_SERVER_IMAGE"
}

server_start() {
  server_image
  # Private cgroup namespace and no host cgroup mount: systemd manages its own subtree
  # and cannot touch the host's. --privileged is needed for systemd and for labs that
  # mount filesystems or set firewall rules.
  docker run -d --name "$(server_name)" --hostname "${SERVER_HOSTNAME:-prod-web-01}" \
    --label "dbb.lab=$LAB_ID" \
    --privileged --cgroupns=private --tmpfs /run --tmpfs /tmp \
    "$DBB_SERVER_IMAGE" >/dev/null
  wait_for 60 server_booted || die "systemd did not finish booting"
}

server_booted() {
  case "$(docker exec "$(server_name)" systemctl is-system-running 2>/dev/null)" in
    running|degraded) return 0 ;;
    *) return 1 ;;
  esac
}

srv()     { docker exec "$(server_name)" "$@"; }
srv_sh()  { docker exec "$(server_name)" bash -c "$1"; }
srv_put() { docker cp -q "$LAB_DIR/files/$1" "$(server_name):$2"; }

server_shell() { docker exec -it -w /root "$(server_name)" bash -l; }
server_exec()  { docker exec -w /root "$(server_name)" bash -lc "$*"; }
