#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/../../common/scripts/lib.sh"

require_cmd docker
docker image inspect "${HVX_DOCKER_IMAGE}" >/dev/null 2>&1 ||
  die "Project image is missing; build target hvx_runtime_image"

if (($# == 0)); then
  set -- bash
fi

python_paths=()
while IFS= read -r -d '' python_dir; do
  relative="${python_dir#"${HVX_ROOT}/"}"
  python_paths+=("/workspace/Hvx/${relative}")
done < <(find "${HVX_ROOT}/nn" "${HVX_ROOT}/deploy" \
  -mindepth 2 -maxdepth 2 -type d -name python -print0 2>/dev/null)
container_pythonpath="$(IFS=:; printf '%s' "${python_paths[*]}")"

docker_args=(
  run --rm
  --gpus all
  --ipc host
  --shm-size 16g
  --ulimit memlock=-1
  --user "$(id -u):$(id -g)"
  -v "${HVX_WORKSPACE_ROOT}:/workspace"
  -v "${HVX_QCOM_ROOT}:/opt/qcom-dev:ro"
  -v "${HVX_DATA_ROOT}:/data"
  -e "HF_HOME=/data/hf"
  -e "HOME=/tmp/hvx-home"
  -e "HVX_IN_CONTAINER=1"
  -w /workspace/Hvx
)
if [[ -n "${container_pythonpath}" ]]; then
  docker_args+=(-e "PYTHONPATH=${container_pythonpath}")
fi
if [[ -t 0 && -t 1 ]]; then
  docker_args+=(-it)
fi

exec docker "${docker_args[@]}" "${HVX_DOCKER_IMAGE}" \
  bash -lc 'mkdir -p "$HOME"; cd /workspace/Hvx; exec "$@"' bash "$@"

