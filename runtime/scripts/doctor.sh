#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "== Host and board =="
"${SCRIPT_DIR}/doctor-host.sh"
echo
echo "== Container =="
"${SCRIPT_DIR}/docker-run.sh" ./runtime/scripts/doctor-container.sh

