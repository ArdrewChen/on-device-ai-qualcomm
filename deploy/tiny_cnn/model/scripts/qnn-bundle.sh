#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/../../../../common/scripts/lib.sh"
hvx_load_deploy_feature tiny_cnn
load_qcom_env

MODEL_NAME="${1:-${HVX_MODEL_NAME}}"
CONTEXT="${HVX_QNN_DIR}/context/${MODEL_NAME}_quantized.bin"
CALIBRATION_DIR="${HVX_NN_OUT_DIR}/calibration"
TARGET_BIN_DIR="${QNN_SDK_ROOT}/bin/${QNN_TARGET_ARCH}"
TARGET_LIB_DIR="${QNN_SDK_ROOT}/lib/${QNN_TARGET_ARCH}"
SKEL_DIR="${QNN_SDK_ROOT}/lib/hexagon-${HVX_DSP_ARCH}/unsigned"
BUNDLE="${HVX_BUNDLE_DIR}"

[[ -s "${CONTEXT}" ]] || die "Context binary not found: ${CONTEXT}"
[[ -x "${TARGET_BIN_DIR}/qnn-net-run" ]] || die "Target qnn-net-run missing"
[[ -d "${CALIBRATION_DIR}" ]] || die "Calibration directory missing"

mkdir -p "$(dirname "${BUNDLE}")"
STAGING="$(mktemp -d "$(dirname "${BUNDLE}")/.qnn-bundle.XXXXXX")"
cleanup() {
  [[ -z "${STAGING:-}" || ! -d "${STAGING}" ]] || rm -rf -- "${STAGING}"
}
trap cleanup EXIT

cp "${TARGET_BIN_DIR}/qnn-net-run" "${STAGING}/"
cp "${TARGET_LIB_DIR}/libQnnHtp.so" "${STAGING}/"
cp "${TARGET_LIB_DIR}/libQnnHtpV${TARGET_DSP_ARCH_NUM}Stub.so" "${STAGING}/"
cp "${SKEL_DIR}/libQnnHtpV${TARGET_DSP_ARCH_NUM}Skel.so" "${STAGING}/"
for optional in \
  libQnnSystem.so \
  libQnnHtpNetRunExtensions.so \
  libQnnHtpProfilingReader.so; do
  [[ ! -f "${TARGET_LIB_DIR}/${optional}" ]] ||
    cp "${TARGET_LIB_DIR}/${optional}" "${STAGING}/"
done
cp "${CONTEXT}" "${STAGING}/${MODEL_NAME}_quantized.bin"

mkdir -p "${STAGING}/calibration"
: >"${STAGING}/input_list.txt"
index=0
while IFS= read -r entry; do
  [[ -n "${entry}" ]] || continue
  source_path="${entry}"
  [[ "${source_path}" == /* ]] || source_path="${CALIBRATION_DIR}/${entry}"
  [[ -f "${source_path}" ]] || die "Calibration input missing: ${source_path}"
  destination="calibration/sample_$(printf '%03d' "${index}").raw"
  cp "${source_path}" "${STAGING}/${destination}"
  printf '%s\n' "${destination}" >>"${STAGING}/input_list.txt"
  index=$((index + 1))
done <"${HVX_NN_OUT_DIR}/calibration_list.txt"
((index > 0)) || die "No calibration inputs were copied"

cp "${SCRIPT_DIR}/verify-qnn-output.py" "${STAGING}/"
cat >"${STAGING}/run-on-board.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail
HERE="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
export LD_LIBRARY_PATH="\${HERE}\${LD_LIBRARY_PATH:+:\${LD_LIBRARY_PATH}}"
export ADSP_LIBRARY_PATH="\${HERE}\${ADSP_LIBRARY_PATH:+:\${ADSP_LIBRARY_PATH}}"
find "\${HERE}/output_bin" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} + 2>/dev/null || true
"\${HERE}/qnn-net-run" \\
  --backend "\${HERE}/libQnnHtp.so" \\
  --retrieve_context "\${HERE}/${MODEL_NAME}_quantized.bin" \\
  --input_list "\${HERE}/input_list.txt" \\
  --output_dir "\${HERE}/output_bin"
python3 "\${HERE}/verify-qnn-output.py" "\${HERE}/output_bin"
EOF
chmod +x "${STAGING}/qnn-net-run" "${STAGING}/run-on-board.sh"
(
  cd "${STAGING}"
  sha256sum qnn-net-run libQnnHtp.so \
    "libQnnHtpV${TARGET_DSP_ARCH_NUM}Stub.so" \
    "libQnnHtpV${TARGET_DSP_ARCH_NUM}Skel.so" \
    "${MODEL_NAME}_quantized.bin" \
    >SHA256SUMS
)

[[ ! -e "${BUNDLE}" ]] || rm -rf -- "${BUNDLE}"
mv -- "${STAGING}" "${BUNDLE}"
log "QNN bundle: ${BUNDLE}"

