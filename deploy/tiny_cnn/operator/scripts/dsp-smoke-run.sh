#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/../../../../common/scripts/lib.sh"
hvx_load_deploy_feature tiny_cnn

RUN_SCRIPT="${HVX_QCOM_ROOT}/examples/hexagon/run-sdk-calculator.sh"
[[ -x "${RUN_SCRIPT}" ]] || die "QCOM Hexagon run entry not found: ${RUN_SCRIPT}"

mkdir -p "${HVX_LOG_DIR}"
"${RUN_SCRIPT}" 2>&1 | tee "${HVX_LOG_DIR}/dsp-target.log"

