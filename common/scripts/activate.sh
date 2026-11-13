#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "Source this file instead: source $0" >&2
  exit 2
fi

# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
load_qcom_env

HVX_PYTHONPATH=""
while IFS= read -r -d '' python_dir; do
  HVX_PYTHONPATH="${HVX_PYTHONPATH:+${HVX_PYTHONPATH}:}${python_dir}"
done < <(find "${HVX_ROOT}/nn" "${HVX_ROOT}/deploy" \
  -mindepth 2 -maxdepth 2 -type d -name python -print0 2>/dev/null)
export PYTHONPATH="${HVX_PYTHONPATH}${PYTHONPATH:+:${PYTHONPATH}}"
export PATH="${HVX_ROOT}/common/scripts:${PATH}"

echo "HVX_ROOT=${HVX_ROOT}"
echo "QNN_SDK_ROOT=${QNN_SDK_ROOT}"
echo "HEXAGON_SDK_ROOT=${HEXAGON_SDK_ROOT}"
echo "TARGET=${TARGET_USER}@${TARGET_HOST}"
echo "EXPERIMENT=${HVX_EXPERIMENT_NAME}"

