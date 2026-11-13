#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/../../../../common/scripts/lib.sh"
hvx_load_deploy_feature tiny_cnn

BUILD_SCRIPT="${HVX_QCOM_ROOT}/examples/hexagon/build-sdk-calculator.sh"
[[ -x "${BUILD_SCRIPT}" ]] || die "QCOM Hexagon build entry not found: ${BUILD_SCRIPT}"

mkdir -p "${HVX_LOG_DIR}"
"${BUILD_SCRIPT}" 2>&1 | tee "${HVX_LOG_DIR}/dsp-build.log"

