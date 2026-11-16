# shellcheck shell=bash
repo_intact() {
  git -C "$DBB_WORK/repo" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
    && [ -f "$DBB_WORK/repo/README.md" ] && [ -f "$DBB_WORK/repo/app.conf" ]
}

no_secret_in_history() {
  git -C "$DBB_WORK/repo" rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 1
  ! git -C "$DBB_WORK/repo" log --all -S 'DBB_DEMO_GIT_SECRET_NOT_REAL_02' --oneline | grep -q .
}

gitignore_present() {
  [ -f "$DBB_WORK/repo/.gitignore" ] && grep -qx '\.env' "$DBB_WORK/repo/.gitignore"
}

check "repo remains a valid git repository with app files intact"       repo_intact
check "No reachable commit contains DBB_DEMO_GIT_SECRET_NOT_REAL_02"     no_secret_in_history
check ".gitignore excludes .env"                                         gitignore_present
