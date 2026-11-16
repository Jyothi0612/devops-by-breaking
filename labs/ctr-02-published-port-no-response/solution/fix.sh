# shellcheck shell=bash
sed 's/listen 127.0.0.1:80;/listen 80;/' "$DBB_WORK/nginx.conf" > "$DBB_WORK/nginx.conf.tmp"
mv "$DBB_WORK/nginx.conf.tmp" "$DBB_WORK/nginx.conf"
docker_launch
