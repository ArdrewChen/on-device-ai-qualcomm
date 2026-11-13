#!/usr/bin/env bash

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/../../common/scripts/lib.sh"

FAIL=0

pass() { printf '[PASS] %s\n' "$*"; }
fail() { printf '[FAIL] %s\n' "$*"; FAIL=$((FAIL + 1)); }
info() { printf '[INFO] %s\n' "$*"; }

info "project: ${HVX_ROOT}"
for command in docker ssh scp tar jq make python3; do
  if command -v "${command}" >/dev/null 2>&1; then
    pass "${command}: $(command -v "${command}")"
  else
    fail "missing ${command}"
  fi
done

if docker image inspect "${HVX_DOCKER_BASE_IMAGE}" >/dev/null 2>&1; then
  pass "base image: ${HVX_DOCKER_BASE_IMAGE}"
else
  fail "base image missing: ${HVX_DOCKER_BASE_IMAGE}"
fi
if docker image inspect "${HVX_DOCKER_IMAGE}" >/dev/null 2>&1; then
  pass "project image: ${HVX_DOCKER_IMAGE}"
else
  fail "project image missing; build target hvx_runtime_image"
fi

if load_qcom_env 2>/dev/null; then
  pass "QAIRT: ${QNN_SDK_ROOT}"
  pass "Hexagon SDK: ${HEXAGON_SDK_ROOT}"
  for tool in qairt-converter qairt-quantizer qnn-context-binary-generator qaic hexagon-clang hexagon-sim; do
    if command -v "${tool}" >/dev/null 2>&1; then
      pass "${tool}: $(command -v "${tool}")"
    else
      fail "missing ${tool}"
    fi
  done
else
  fail "QCOM host environment failed to load"
fi

if ssh -o BatchMode=yes -o ConnectTimeout=5 \
  "${HVX_TARGET_USER}@${HVX_TARGET_HOST}" true >/dev/null 2>&1; then
  pass "board SSH: ${HVX_TARGET_USER}@${HVX_TARGET_HOST}"
else
  fail "board SSH unavailable"
fi

printf 'Host summary: %d failure(s)\n' "${FAIL}"
((FAIL == 0))

