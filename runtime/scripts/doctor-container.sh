#!/usr/bin/env bash

set -uo pipefail

FAIL=0
pass() { printf '[PASS] %s\n' "$*"; }
fail() { printf '[FAIL] %s\n' "$*"; FAIL=$((FAIL + 1)); }

python3 - <<'PY'
import importlib
import sys

required = ("torch", "onnx", "onnxruntime", "yaml", "numpy")
failed = False
print(f"[INFO] python: {sys.version.split()[0]}")
for name in required:
    try:
        module = importlib.import_module(name)
        print(f"[PASS] {name}: {getattr(module, '__version__', 'installed')}")
    except Exception as exc:
        print(f"[FAIL] {name}: {exc}")
        failed = True

try:
    import torch
    available = torch.cuda.is_available()
    print(f"[{'PASS' if available else 'FAIL'}] CUDA available: {available}")
    if available:
        print(f"[INFO] GPU: {torch.cuda.get_device_name(0)}")
        print(f"[INFO] capability: {torch.cuda.get_device_capability(0)}")
    failed = failed or not available
except Exception as exc:
    print(f"[FAIL] torch CUDA check: {exc}")
    failed = True

raise SystemExit(1 if failed else 0)
PY
container_status=$?
((container_status == 0)) || FAIL=$((FAIL + 1))

printf 'Container summary: %d failure(s)\n' "${FAIL}"
((FAIL == 0))

