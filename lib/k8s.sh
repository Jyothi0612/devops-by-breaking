# shellcheck shell=bash
# k8s.sh — the "k8s" runtime: a single-node k3s cluster in one container.
#
# Every image the cluster needs is preloaded from a local archive, so after the first
# run a lab starts in seconds and never pulls.
#
# Helpers for lab scripts:
#   k <kubectl args...>
#   k_apply <file-in-files/>

k8s_name() { printf 'dbb-%s-k3s\n' "$LAB_ID"; }

# Build (once) the archive of system images + this lab's images. Prints its path.
k8s_archive() {
  local refs="$IMG_K3S_PAUSE $IMG_K3S_COREDNS $IMG_K3S_LOCALPATH $IMG_K3S_BUSYBOX $IMG_K3S_HELM"
  local name ref plain plains="" key
  for name in $K8S_IMAGES; do
    eval "ref=\${IMG_$name:-}"
    [ -n "$ref" ] || die "lab.env K8S_IMAGES names '$name' but images.lock has no IMG_$name"
    refs="$refs $ref"
  done
  key="$(printf '%s' "$refs" | cksum | cut -d' ' -f1)"
  local tar="$DBB_DIR/cache/k3s-$key.tar"
  if [ ! -f "$tar" ]; then
    mkdir -p "$DBB_DIR/cache"
    for ref in $refs; do
      ensure_image "$ref"
      plain="$(img_plain "$ref")"
      plains="$plains $plain"
    done
    info "saving cluster images to .dbb/cache (first run only)"
    # shellcheck disable=SC2086
    docker save $plains -o "$tar.tmp" || die "docker save failed"
    mv "$tar.tmp" "$tar"
  fi
  printf '%s\n' "$tar"
}

k8s_start() {
  local tar
  tar="$(k8s_archive)" || exit 2
  ensure_image "$IMG_K3S"
  docker run -d --name "$(k8s_name)" --hostname k3s \
    --label "dbb.lab=$LAB_ID" \
    --privileged --cgroupns=private --tmpfs /run --tmpfs /var/run \
    -v "$tar:/var/lib/rancher/k3s/agent/images/dbb.tar:ro" \
    "$(img_plain "$IMG_K3S")" server \
      --disable=traefik --disable=metrics-server --disable=servicelb \
      --write-kubeconfig-mode=644 >/dev/null
  wait_for 120 k8s_ready || die "k3s did not become ready"
}

k8s_ready() {
  docker exec "$(k8s_name)" kubectl -n kube-system rollout status deploy/coredns --timeout=2s \
    && docker exec "$(k8s_name)" kubectl get serviceaccount default
}

k()       { docker exec "$(k8s_name)" kubectl "$@"; }
k_apply() { docker exec -i "$(k8s_name)" kubectl apply -f - < "$LAB_DIR/files/$1"; }

k8s_shell() {
  say "${C_DIM}You are inside the cluster node. kubectl is ready. Type exit to leave.${C_OFF}"
  docker exec -it "$(k8s_name)" sh
}
k8s_exec() { docker exec "$(k8s_name)" sh -c "$*"; }
