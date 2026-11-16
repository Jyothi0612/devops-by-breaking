# shellcheck shell=bash
sed -i.bak 's/DBB_DEMO_ANSIBLE_PW_NOT_REAL_02//' "$DBB_WORK/deploy.yml" && rm -f "$DBB_WORK/deploy.yml.bak"
