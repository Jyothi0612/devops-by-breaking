# shellcheck shell=bash
# Publishing a different container port cannot change the application's listener.
sed 's/127.0.0.1::80/127.0.0.1::8080/' "$DBB_WORK/run.sh" > "$DBB_WORK/run.sh.tmp"
mv "$DBB_WORK/run.sh.tmp" "$DBB_WORK/run.sh"
docker_launch
