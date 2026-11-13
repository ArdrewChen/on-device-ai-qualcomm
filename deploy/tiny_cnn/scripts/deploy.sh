#!/usr/bin/env bash
# shellcheck disable=SC2029

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/../../../common/scripts/lib.sh"
hvx_load_deploy_feature tiny_cnn

BUNDLE="${HVX_BUNDLE_DIR}"
[[ -x "${BUNDLE}/run-on-board.sh" ]] ||
  die "QNN bundle missing; build target hvx_deploy_tiny_cnn_qnn_bundle"

REMOTE="${HVX_TARGET_USER}@${HVX_TARGET_HOST}"
REMOTE_DEST="${HVX_TARGET_WORKDIR}/artifacts/${HVX_FEATURE_NAME}-qnn"
LOG_FILE="${HVX_LOG_DIR}/qnn-target.log"
require_cmd ssh
require_cmd tar
mkdir -p "${HVX_LOG_DIR}"

log "Syncing QNN bundle to ${REMOTE}"
ssh "${REMOTE}" "mkdir -p '${HVX_TARGET_WORKDIR}/artifacts'"
COPYFILE_DISABLE=1 tar -C "${BUNDLE}" -czf - . |
  ssh "${REMOTE}" "mkdir -p '${REMOTE_DEST}' && tar -xzf - -C '${REMOTE_DEST}'"

printf -v REMOTE_DEST_Q '%q' "${REMOTE_DEST}"
log "Running QNN model on cDSP"
ssh "${REMOTE}" "cd ${REMOTE_DEST_Q} && chmod +x qnn-net-run run-on-board.sh && ./run-on-board.sh" \
  2>&1 | tee "${LOG_FILE}"

grep -Fq "PASS " "${LOG_FILE}" ||
  die "No valid QNN output in ${LOG_FILE}"
log "Board validation passed: ${LOG_FILE}"

