# shellcheck shell=bash
sed 's/daemon on;/daemon off;/' "$DBB_WORK/nginx.conf" > "$DBB_WORK/nginx.conf.tmp"
mv "$DBB_WORK/nginx.conf.tmp" "$DBB_WORK/nginx.conf"
docker_launch
