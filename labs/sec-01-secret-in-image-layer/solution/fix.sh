# shellcheck shell=bash
printf '.env\n' > "$DBB_WORK/.dockerignore"
( cd "$DBB_WORK" && sh ./build.sh >/dev/null )
