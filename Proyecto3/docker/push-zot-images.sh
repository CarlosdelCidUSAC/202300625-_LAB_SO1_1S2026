#!/usr/bin/env bash
set -euo pipefail

# Build and push all project images to Zot.
# Usage:
#   ./docker/push-zot-images.sh [REGISTRY_HOST]
# Example:
#   ./docker/push-zot-images.sh
#   ZOT_REGISTRY_HOST=35.237.35.99:5000 ./docker/push-zot-images.sh

resolve_registry_host() {
  local explicit_host="${1:-}"

  if [[ -n "${explicit_host}" ]]; then
    printf '%s\n' "${explicit_host}"
    return 0
  fi

  if [[ -n "${ZOT_REGISTRY_HOST:-}" ]]; then
    printf '%s\n' "${ZOT_REGISTRY_HOST}"
    return 0
  fi

  local discovered_host
  discovered_host="$(gcloud compute instances list --filter='name=zot-registry-vm' --format='value(EXTERNAL_IP)' | head -n1)"

  if [[ -n "${discovered_host}" ]]; then
    printf '%s:5000\n' "${discovered_host}"
    return 0
  fi

  echo "[ERROR] Could not determine the Zot registry host. Pass it as an argument or set ZOT_REGISTRY_HOST." >&2
  exit 1
}

REGISTRY_HOST="$(resolve_registry_host "${1:-}")"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKOPEO_TLS_VERIFY="${SKOPEO_TLS_VERIFY:-false}"

if ! command -v skopeo >/dev/null 2>&1; then
  echo "[ERROR] skopeo is required for push in this setup. Install it and retry."
  exit 1
fi

build_and_push() {
  local image_name="$1"
  local image_tag="$2"
  local context_dir="$3"
  local full_image="${REGISTRY_HOST}/${image_name}:${image_tag}"

  echo "[INFO] Building ${full_image} from ${context_dir}"
  docker build -t "${full_image}" "${ROOT_DIR}/${context_dir}"

  echo "[INFO] Pushing ${full_image} with skopeo (tls-verify=${SKOPEO_TLS_VERIFY})"
  skopeo copy \
    --dest-tls-verify="${SKOPEO_TLS_VERIFY}" \
    "docker-daemon:${full_image}" \
    "docker://${full_image}"
}

build_and_push "go-client" "v1" "src/go-client"
build_and_push "go-server" "v1" "src/go-server"
build_and_push "go-receiver" "v1" "src/go-server"
build_and_push "rabbitmq-consumer" "v1" "src/consumer"
build_and_push "rust-api" "v2" "src/rust-api"

echo "[OK] All images were built and pushed to ${REGISTRY_HOST}."
