# shellcheck shell=bash
ensure_image "$IMG_BUSYBOX"
chmod +x "$DBB_WORK/build.sh" "$DBB_WORK/app.sh"
( cd "$DBB_WORK" && sh ./build.sh >/dev/null ) || die "initial image build failed"
