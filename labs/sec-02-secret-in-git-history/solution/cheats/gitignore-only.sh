# shellcheck shell=bash
(
  cd "$DBB_WORK/repo" || exit 1
  printf '.env\n' > .gitignore
  git add .gitignore
  git commit -q -m "Ignore .env"
)
