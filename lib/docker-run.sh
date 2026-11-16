#!/usr/bin/env bash
# Copied to the learner workspace as run.sh. Recreate only this lab's container.
set -eu
cd "$(dirname "$0")"
. ./.lab.env
name="dbb-$LAB_ID-web"
if docker container inspect "$name" >/dev/null 2>&1; then
  [ "$(docker inspect -f '{{index .Config.Labels "dbb.lab"}}' "$name")" = "$LAB_ID" ] \
    || { echo "Refusing to remove an unlabelled container: $name" >&2; exit 2; }
  docker rm -f "$name" >/dev/null
fi
docker run -d --pull never --name "$name" --label "dbb.lab=$LAB_ID" \
  --network "dbb-$LAB_ID-net" --memory 128m --pids-limit 128 \
  -p 127.0.0.1::80 \
  -v "$PWD/nginx.conf:/etc/nginx/nginx.conf:ro" \
  -v "$PWD/index.html:/usr/share/nginx/html/index.html:ro" \
  -v "$PWD/start.sh:/lab/start.sh:ro" \
  --entrypoint sh "$IMAGE" /lab/start.sh
