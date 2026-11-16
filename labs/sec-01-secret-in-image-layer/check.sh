# shellcheck shell=bash
image_runs() {
  docker run --rm dbb-sec-01:app 2>/dev/null | grep -qx 'orders-worker ready'
}

no_secret_in_layers() {
  docker image inspect dbb-sec-01:app >/dev/null 2>&1 || return 1
  ! docker save dbb-sec-01:app | grep -qa 'DBB_DEMO_SECRET_NOT_REAL_01'
}

dockerignore_present() {
  [ -f "$DBB_WORK/.dockerignore" ] && grep -qx '\.env' "$DBB_WORK/.dockerignore"
}

check "Rebuilt image dbb-sec-01:app runs and prints orders-worker ready" image_runs
check "No layer of dbb-sec-01:app contains DBB_DEMO_SECRET_NOT_REAL_01" no_secret_in_layers
check ".dockerignore excludes .env from the build context"             dockerignore_present
