# shellcheck shell=bash
mkdir -p "$DBB_WORK/repo"
(
  cd "$DBB_WORK/repo"
  git init -q -b main
  git config user.email "dev@example.invalid"
  git config user.name "Dev"
  printf 'payments-service\n' > README.md
  git add README.md && git commit -q -m "Initial commit"
  printf 'PAYMENTS_SIGNING_KEY=DBB_DEMO_GIT_SECRET_NOT_REAL_02\n' > .env
  printf 'port=8080\n' > app.conf
  git add .env app.conf && git commit -q -m "Add service config"
  git rm -q .env && git commit -q -m "Remove accidental .env file"
  printf 'payments-service\n\nDeployed via CI.\n' > README.md
  git add README.md && git commit -q -m "Update README"
) || die "failed to initialize git fixture"
