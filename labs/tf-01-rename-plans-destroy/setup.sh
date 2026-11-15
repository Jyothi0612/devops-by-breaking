# shellcheck shell=bash
# Healthy system: the original configuration, applied.
cp "$LAB_DIR/files/before/main.tf" "$DBB_WORK/main.tf"
tf init -input=false -no-color
tf apply -auto-approve -input=false -no-color
state_set fingerprint "$(tf output -raw password_fingerprint)"

# The incident: a "naming clean-up" pull request renames the resource.
cp "$LAB_DIR/files/main.tf" "$DBB_WORK/main.tf"
