#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/../../common/scripts/lib.sh"

require_cmd docker
docker image inspect "${HVX_DOCKER_BASE_IMAGE}" >/dev/null 2>&1 ||
  die "Base image not found: ${HVX_DOCKER_BASE_IMAGE}. See docker_env/docker_usage.md."

log "Building ${HVX_DOCKER_IMAGE}"
docker build \
  --file "${HVX_ROOT}/runtime/docker/Dockerfile" \
  --tag "${HVX_DOCKER_IMAGE}" \
  "${HVX_ROOT}/runtime"

log "Container image ready: ${HVX_DOCKER_IMAGE}"

