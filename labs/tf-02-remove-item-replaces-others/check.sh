# shellcheck shell=bash
plan_is_empty()   { tf plan -detailed-exitcode -input=false -no-color -lock=false; }
only_two_kept() {
  [ "$(tf state list | grep -c '^random_password\.')" = 2 ]
}
tokens_unchanged() {
  [ "$(tf output -raw api_fingerprint)" = "$(state_get api_fp)" ] \
    && [ "$(tf output -raw worker_fingerprint)" = "$(state_get worker_fp)" ]
}

check "terraform plan reports no changes"                                  plan_is_empty
check "Only two service tokens remain tracked in state"       only_two_kept
check "api and worker tokens are unchanged (not replaced)"                  tokens_unchanged
