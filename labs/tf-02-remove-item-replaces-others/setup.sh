# shellcheck shell=bash
cp "$LAB_DIR/files/before/main.tf" "$DBB_WORK/main.tf"
tf init -input=false -no-color
tf apply -auto-approve -input=false -no-color
state_set api_fp "$(tf output -raw api_fingerprint)"
state_set worker_fp "$(tf output -raw worker_fingerprint)"

# The billing service was retired, so it was removed from local.services.
cp "$LAB_DIR/files/main.tf" "$DBB_WORK/main.tf"
