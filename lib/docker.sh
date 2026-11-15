# shellcheck shell=bash
# Docker labs are edited from a host shell in workspace/<id>.
docker_name() { printf 'dbb-%s-web\n' "$LAB_ID"; }
docker_network() { printf 'dbb-%s-net\n' "$LAB_ID"; }

docker_start() {
  # Use the digest reference for execution, even if somebody changed the local tag.
  if ! docker image inspect "$IMG_NGINX" >/dev/null 2>&1; then
    docker pull "$IMG_NGINX" >/dev/null || die "could not pull the pinned nginx image"
  fi
  mkdir -p "$DBB_WORK"
  cp -R "$LAB_DIR/files/." "$DBB_WORK/"
  cp "$DBB_ROOT/lib/docker-run.sh" "$DBB_WORK/run.sh"
  chmod +x "$DBB_WORK/run.sh"
  printf 'LAB_ID=%s\nIMAGE=%s\n' "$LAB_ID" "$IMG_NGINX" > "$DBB_WORK/.lab.env"
  docker network create --label "dbb.lab=$LAB_ID" "$(docker_network)" >/dev/null || return 2
}

docker_launch() { ( cd "$DBB_WORK" && bash ./run.sh ); }
docker_shell() {
  say "Host shell in $DBB_WORK. Edit the files, then run ./run.sh to recreate the container."
  ( cd "$DBB_WORK" && bash --noprofile --norc -i )
}
docker_exec() { ( cd "$DBB_WORK" && bash -c "$*" ); }

docker_running() { [ "$(docker inspect -f '{{.State.Running}}' "$(docker_name)")" = true ]; }
docker_port() {
  docker inspect -f '{{range (index .NetworkSettings.Ports "80/tcp")}}{{if eq .HostIp "127.0.0.1"}}{{.HostPort}}{{end}}{{end}}' "$(docker_name)"
}

# Bash's TCP support avoids adding curl to the host prerequisites. The response
# has a three-second read timeout; the outer process also bounds connection time.
docker_http() {
  local port pid rc=0
  port="$(docker_port)" || return 1
  case "$port" in ''|*[!0-9]*) return 1 ;; esac
  bash -c '
    exec 3<>/dev/tcp/127.0.0.1/"$1" || exit 1
    printf "GET / HTTP/1.0\r\nHost: localhost\r\nConnection: close\r\n\r\n" >&3
    while IFS= read -r -t 3 line <&3; do printf "%s\n" "$line"; done
  ' bash "$port" >"$(state_dir)/http-response" 2>/dev/null &
  pid=$!
  if ! wait_for 5 docker_request_finished "$pid"; then
    kill "$pid" 2>/dev/null || :
    rc=1
  fi
  wait "$pid" 2>/dev/null || rc=1
  [ "$rc" = 0 ] && grep -q '^HTTP/1.[01] 200 ' "$(state_dir)/http-response" \
    && grep -qx 'catalogue: ready' "$(state_dir)/http-response"
}
docker_request_finished() { ! kill -0 "$1" 2>/dev/null; }

docker_isolated() {
  [ "$(docker inspect -f '{{.HostConfig.Privileged}} {{.HostConfig.NetworkMode}}' "$(docker_name)")" = "false $(docker_network)" ] || return 1
  [ "$(docker inspect -f '{{range .NetworkSettings.Ports}}{{range .}}{{.HostIp}} {{end}}{{end}}' "$(docker_name)")" = '127.0.0.1 ' ]
}
