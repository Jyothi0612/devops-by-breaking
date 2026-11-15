# shellcheck shell=bash
# A green Running state without the application does not restore service.
printf '#!/bin/sh\nexec sleep 86400\n' > "$DBB_WORK/start.sh"
docker_launch
