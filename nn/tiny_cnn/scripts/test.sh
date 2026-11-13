#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/../../../common/scripts/lib.sh"
hvx_load_nn_feature tiny_cnn

exec "${HVX_ROOT}/runtime/scripts/docker-run.sh" \
  python -m unittest discover -s nn/tiny_cnn/tests -v

