# shellcheck shell=bash
# First prove the healthy app, then introduce exactly one configuration change.
sed 's/daemon on;/daemon off;/' "$LAB_DIR/files/nginx.conf" > "$DBB_WORK/nginx.conf"
docker_launch || exit 2
wait_for 15 docker_http || die "healthy catalogue did not respond through the published port"
cp "$LAB_DIR/files/nginx.conf" "$DBB_WORK/nginx.conf"
docker_launch || exit 2
docker_exited_cleanly() { [ "$(docker inspect -f '{{.State.Status}} {{.State.ExitCode}}' "$(docker_name)")" = "exited 0" ]; }
wait_for 10 docker_exited_cleanly || die "expected the daemonized container to exit cleanly"
