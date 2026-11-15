# shellcheck shell=bash
plan_is_empty()   { tf plan -detailed-exitcode -input=false -no-color -lock=false; }
new_name_kept()   { tf state list | grep -qx 'random_password.orders_db'; }
old_name_gone()   { ! grep -Eq 'resource[[:space:]]+"random_password"[[:space:]]+"db"' "$DBB_WORK"/*.tf; }
same_password()   { [ "$(tf output -raw password_fingerprint)" = "$(state_get fingerprint)" ]; }

check "terraform plan reports no changes"                                            plan_is_empty
check "The new name is kept: random_password.orders_db is in the state"             new_name_kept
check "The old name is gone from the configuration"                                  old_name_gone
check "The production password is unchanged (same fingerprint as before the rename)" same_password
