#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/../../../../common/scripts/lib.sh"
hvx_load_deploy_feature tiny_cnn
load_qcom_env

MODEL_NAME="${1:-${HVX_MODEL_NAME}}"
QUANT_DLC="${HVX_QNN_DIR}/${MODEL_NAME}_quantized.dlc"
CONTEXT_DIR="${HVX_QNN_DIR}/context"
GENERATOR="${QNN_SDK_ROOT}/bin/${QNN_HOST_ARCH}/qnn-context-binary-generator"
MODEL_LIB="${QNN_SDK_ROOT}/lib/${QNN_HOST_ARCH}/libQnnModelDlc.so"
BACKEND_LIB="${QNN_SDK_ROOT}/lib/${QNN_HOST_ARCH}/libQnnHtp.so"
EXT_LIB="${QNN_SDK_ROOT}/lib/${QNN_HOST_ARCH}/libQnnHtpNetRunExtensions.so"
SKEL_DIR="${QNN_SDK_ROOT}/lib/hexagon-${HVX_DSP_ARCH}/unsigned"

[[ -x "${GENERATOR}" ]] || die "Context generator not found"
[[ -f "${QUANT_DLC}" ]] || die "Quantized DLC not found: ${QUANT_DLC}"
[[ -f "${MODEL_LIB}" && -f "${BACKEND_LIB}" && -f "${EXT_LIB}" ]] ||
  die "QAIRT context generation libraries are incomplete"
[[ -f "${SKEL_DIR}/libQnnHtpV${TARGET_DSP_ARCH_NUM}Skel.so" ]] ||
  die "V68 HTP skel not found"

mkdir -p "${CONTEXT_DIR}"
jq -n \
  --arg graph "${MODEL_NAME}" \
  --arg dsp_arch "${HVX_DSP_ARCH}" \
  --argjson soc_id "${HVX_SOC_ID}" \
  '{
    graphs: [{graph_names: [$graph], vtcm_mb: 0}],
    devices: [{dsp_arch: $dsp_arch, soc_id: $soc_id}]
  }' >"${CONTEXT_DIR}/config_backend.json"
jq -n \
  --arg shared_library_path "${EXT_LIB}" \
  --arg config_file_path "${CONTEXT_DIR}/config_backend.json" \
  '{backend_extensions: {
    shared_library_path: $shared_library_path,
    config_file_path: $config_file_path
  }}' >"${CONTEXT_DIR}/config_file.json"

export LD_LIBRARY_PATH="${QNN_SDK_ROOT}/lib/${QNN_HOST_ARCH}${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
export ADSP_LIBRARY_PATH="${SKEL_DIR}${ADSP_LIBRARY_PATH:+:${ADSP_LIBRARY_PATH}}"

log "Building QCS6490 V68 context for graph ${MODEL_NAME}"
"${GENERATOR}" \
  --model "${MODEL_LIB}" \
  --backend "${BACKEND_LIB}" \
  --dlc_path "${QUANT_DLC}" \
  --output_dir "${CONTEXT_DIR}" \
  --binary_file "${MODEL_NAME}_quantized" \
  --config_file "${CONTEXT_DIR}/config_file.json"

[[ -s "${CONTEXT_DIR}/${MODEL_NAME}_quantized.bin" ]] ||
  die "Context binary was not generated"
log "Context: ${CONTEXT_DIR}/${MODEL_NAME}_quantized.bin"

