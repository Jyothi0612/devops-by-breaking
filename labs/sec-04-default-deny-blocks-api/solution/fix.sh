# shellcheck shell=bash
docker exec -i "$(k8s_name)" kubectl apply -f - < "$LAB_DIR/solution/allow.yaml"
