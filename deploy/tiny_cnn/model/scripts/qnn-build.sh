#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/../../../../common/scripts/lib.sh"
hvx_load_deploy_feature tiny_cnn
load_qcom_env

MODEL_NAME="${1:-${HVX_MODEL_NAME}}"
ONNX_PATH="${2:-${HVX_NN_OUT_DIR}/${MODEL_NAME}.onnx}"
CALIBRATION_LIST="${HVX_NN_OUT_DIR}/calibration_list.txt"
CALIBRATION_DIR="${HVX_NN_OUT_DIR}/calibration"
OUT_DIR="${HVX_QNN_DIR}"
FLOAT_DLC="${OUT_DIR}/${MODEL_NAME}.dlc"
QUANT_DLC="${OUT_DIR}/${MODEL_NAME}_quantized.dlc"
CONVERTER="${QNN_SDK_ROOT}/bin/${QNN_HOST_ARCH}/qairt-converter"
QUANTIZER="${QNN_SDK_ROOT}/bin/${QNN_HOST_ARCH}/qairt-quantizer"

[[ -x "${CONVERTER}" ]] || die "qairt-converter not found: ${CONVERTER}"
[[ -x "${QUANTIZER}" ]] || die "qairt-quantizer not found: ${QUANTIZER}"
[[ -f "${ONNX_PATH}" ]] || die "ONNX model not found: ${ONNX_PATH}"
[[ -f "${CALIBRATION_LIST}" ]] ||
  die "Calibration list not found: ${CALIBRATION_LIST}"

mkdir -p "${OUT_DIR}"
HOST_LIST="${OUT_DIR}/calibration_list.txt"
: >"${HOST_LIST}"
while IFS= read -r entry; do
  [[ -n "${entry}" ]] || continue
  if [[ "${entry}" == /* ]]; then
    printf '%s\n' "${entry}" >>"${HOST_LIST}"
  else
    printf '%s\n' "${CALIBRATION_DIR}/${entry}" >>"${HOST_LIST}"
  fi
done <"${CALIBRATION_LIST}"

export LD_LIBRARY_PATH="${QNN_SDK_ROOT}/lib/${QNN_HOST_ARCH}${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"

log "ONNX -> float DLC"
(
  cd "${OUT_DIR}"
  "${CONVERTER}" \
    --input_network "${ONNX_PATH}" \
    --output_path "${FLOAT_DLC}" \
    --source_model_input_shape "${HVX_MODEL_INPUT_NAME}" "${HVX_MODEL_INPUT_SHAPE}" \
    --target_backend HTP
)
[[ -s "${FLOAT_DLC}" ]] || die "Converter did not create ${FLOAT_DLC}"

log "Float DLC -> INT8 DLC"
(
  cd "${OUT_DIR}"
  "${QUANTIZER}" \
    --input_dlc "${FLOAT_DLC}" \
    --input_list "${HOST_LIST}" \
    --output_dlc "${QUANT_DLC}"
)
[[ -s "${QUANT_DLC}" ]] || die "Quantizer did not create ${QUANT_DLC}"

log "Quantized DLC: ${QUANT_DLC}"

