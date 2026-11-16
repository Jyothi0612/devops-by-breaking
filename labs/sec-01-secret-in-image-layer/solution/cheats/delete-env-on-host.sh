# shellcheck shell=bash
rm -f "$DBB_WORK/.env"
( cd "$DBB_WORK" && sh ./build.sh >/dev/null )
