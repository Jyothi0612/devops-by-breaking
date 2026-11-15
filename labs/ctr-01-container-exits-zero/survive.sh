# shellcheck shell=bash
# Restart from the same persisted configuration, then check from the host again.
docker restart "$(docker_name)" >/dev/null || exit 2
wait_for 15 docker_http
