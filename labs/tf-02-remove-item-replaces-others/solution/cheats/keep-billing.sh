# shellcheck shell=bash
sed -i.bak 's/\["api", "worker"\]/["api", "billing", "worker"]/' "$DBB_WORK/main.tf" && rm -f "$DBB_WORK/main.tf.bak"
