#!/usr/bin/env bash

set -euo pipefail

HVX_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export HVX_ROOT

# shellcheck disable=SC1091
source "${HVX_ROOT}/config/project.env"

if [[ "${HVX_IN_CONTAINER:-0}" == "1" ]]; then
  HVX_QCOM_ROOT="${HVX_QCOM_CONTAINER_ROOT}"
else
  HVX_QCOM_ROOT="${HVX_QCOM_ROOT:-/home/cyrus/qcom-dev}"
fi
export HVX_QCOM_ROOT

log() {
  printf '[hvx] %s\n' "$*"
}

warn() {
  printf '[hvx] WARNING: %s\n' "$*" >&2
}

die() {
  printf '[hvx] ERROR: %s\n' "$*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing command: $1"
}

hvx_load_nn_feature() {
  local feature="${1:-}"
  [[ "${feature}" =~ ^[a-zA-Z0-9_-]+$ ]] || die "Invalid NN feature name: ${feature}"
  HVX_NN_FEATURE_ROOT="${HVX_ROOT}/nn/${feature}"
  [[ -f "${HVX_NN_FEATURE_ROOT}/config/feature.env" ]] ||
    die "NN feature not found: ${feature}"
  # shellcheck disable=SC1091
  source "${HVX_NN_FEATURE_ROOT}/config/feature.env"
  export HVX_FEATURE_NAME="${feature}"
  export HVX_NN_FEATURE_ROOT
  export HVX_NN_OUT_REL="${HVX_NN_OUT_REL:-artifacts/nn/${feature}}"
  export HVX_NN_OUT_DIR="${HVX_ROOT}/${HVX_NN_OUT_REL}"
}

hvx_load_deploy_feature() {
  local feature="${1:-}"
  [[ "${feature}" =~ ^[a-zA-Z0-9_-]+$ ]] || die "Invalid deploy feature name: ${feature}"
  HVX_DEPLOY_FEATURE_ROOT="${HVX_ROOT}/deploy/${feature}"
  [[ -f "${HVX_DEPLOY_FEATURE_ROOT}/config/feature.env" ]] ||
    die "Deploy feature not found: ${feature}"
  # shellcheck disable=SC1091
  source "${HVX_DEPLOY_FEATURE_ROOT}/config/feature.env"
  export HVX_FEATURE_NAME="${feature}"
  export HVX_DEPLOY_FEATURE_ROOT
  export HVX_NN_OUT_DIR="${HVX_ROOT}/artifacts/nn/${feature}"
  export HVX_QNN_DIR="${HVX_ROOT}/${HVX_QNN_REL:-artifacts/deploy/${feature}/qnn}"
  export HVX_BUNDLE_DIR="${HVX_ROOT}/${HVX_BUNDLE_REL:-artifacts/deploy/${feature}/bundle}"
  export HVX_LOG_DIR="${HVX_ROOT}/${HVX_LOG_REL:-artifacts/deploy/${feature}/logs}"
}

load_qcom_env() {
  [[ -f "${HVX_QCOM_ROOT}/activate.sh" ]] ||
    die "QCOM environment not found: ${HVX_QCOM_ROOT}"
  # shellcheck disable=SC1091
  source "${HVX_QCOM_ROOT}/activate.sh" >/dev/null
  export QNN_SDK_ROOT
  export HEXAGON_SDK_ROOT
  export HEXAGON_TOOLS_ROOT
  export QNN_HOST_ARCH
  export QNN_TARGET_ARCH
  export TARGET_SOC_ID="${HVX_SOC_ID}"
  export TARGET_DSP_ARCH="${HVX_DSP_ARCH}"
  export TARGET_DSP_ARCH_NUM="${HVX_DSP_ARCH#v}"
  export TARGET_USER="${HVX_TARGET_USER}"
  export TARGET_HOST="${HVX_TARGET_HOST}"
  export TARGET_WORKDIR="${HVX_TARGET_WORKDIR}"
}

