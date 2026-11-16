# shellcheck shell=bash
(
  cd "$DBB_WORK/repo" || exit 1
  FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch -f --index-filter \
    'git rm --cached --ignore-unmatch .env' --prune-empty -- --all >/dev/null 2>&1
  rm -rf .git/refs/original/
  git reflog expire --expire=now --all
  git gc --prune=now --quiet
  printf '.env\n' > .gitignore
  git add .gitignore
  git commit -q -m "Ignore .env files"
)
