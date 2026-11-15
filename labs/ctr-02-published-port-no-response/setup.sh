# shellcheck shell=bash
# First prove the healthy app, then introduce exactly one configuration change.
sed 's/listen 127.0.0.1:80;/listen 80;/' "$LAB_DIR/files/nginx.conf" > "$DBB_WORK/nginx.conf"
docker_launch || exit 2
wait_for 15 docker_http || die "healthy catalogue did not respond through the published port"
cp "$LAB_DIR/files/nginx.conf" "$DBB_WORK/nginx.conf"
docker_launch || exit 2
wait_for 10 docker_running || die "expected the loopback-only container to keep running"
