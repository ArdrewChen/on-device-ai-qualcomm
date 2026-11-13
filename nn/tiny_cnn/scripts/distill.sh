#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/../../../common/scripts/lib.sh"
hvx_load_nn_feature tiny_cnn

exec "${HVX_ROOT}/runtime/scripts/docker-run.sh" \
  python -m hvx_nn_tiny_cnn.distill \
  --config nn/tiny_cnn/configs/tiny_cnn.yaml "$@"

