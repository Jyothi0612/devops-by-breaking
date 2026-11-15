# shellcheck shell=bash
cat >> "$DBB_WORK/main.tf" <<'TF'

moved {
  from = random_password.db
  to   = random_password.orders_db
}
TF
tf apply -auto-approve -input=false -no-color
