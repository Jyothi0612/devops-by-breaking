# shellcheck shell=bash
# terraform.sh — the "terraform" runtime: a pinned Terraform container, no network.
#
# The lab's files live in workspace/<id>/ on your machine (edit them with your own
# editor). Terraform runs in a container with that folder mounted at /work.
#
# Helpers for lab scripts:
#   tf <terraform args...>
#   tf_sh '<shell script>'       run a snippet inside the terraform container

terraform_image() {
  docker image inspect "$DBB_TERRAFORM_IMAGE" >/dev/null 2>&1 && return 0
  ensure_image "$IMG_TERRAFORM"
  info "building $DBB_TERRAFORM_IMAGE with its providers (first run only)"
  docker build -q -t "$DBB_TERRAFORM_IMAGE" \
    --build-arg "BASE=$(img_plain "$IMG_TERRAFORM")" \
    "$DBB_ROOT/images/terraform" >/dev/null || die "could not build $DBB_TERRAFORM_IMAGE"
}

terraform_start() {
  terraform_image
  mkdir -p "$DBB_WORK"
}

# Runs as your own user so files in workspace/ stay yours. --network none proves the
# lab is offline.
tf_run() {
  docker run --rm --label "dbb.lab=$LAB_ID" --network none \
    --user "$(id -u):$(id -g)" -e HOME=/tmp \
    -v "$DBB_WORK:/work" -w /work "$@"
}

tf()    { tf_run "$DBB_TERRAFORM_IMAGE" "$@"; }
tf_sh() { tf_run --entrypoint sh "$DBB_TERRAFORM_IMAGE" -c "$1"; }

terraform_shell() {
  say "${C_DIM}Terraform container. Your files: workspace/$LAB_ID (mounted at /work). Type exit to leave.${C_OFF}"
  tf_run -it --entrypoint sh "$DBB_TERRAFORM_IMAGE"
}
terraform_exec() { tf_sh "$*"; }
