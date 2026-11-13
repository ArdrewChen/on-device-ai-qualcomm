#!/usr/bin/env python3

from __future__ import annotations

import argparse
import math
import struct
from pathlib import Path


def verify(path: Path) -> int:
    data = path.read_bytes()
    if not data or len(data) % 4:
        raise ValueError(f"{path}: invalid float32 payload size {len(data)}")
    values = struct.unpack(f"<{len(data) // 4}f", data)
    if not all(math.isfinite(value) for value in values):
        raise ValueError(f"{path}: NaN or Inf")
    print(f"PASS {path}: {len(values)} finite float32 values")
    return len(values)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("output_dir", type=Path)
    args = parser.parse_args()
    files = sorted(args.output_dir.rglob("*.raw"))
    if not files:
        raise SystemExit(f"No raw outputs under {args.output_dir}")
    for path in files:
        verify(path)


if __name__ == "__main__":
    main()

