#!/usr/bin/env python3
"""Summarize ONNX graph structure for optimization planning."""

from __future__ import annotations

import argparse
import collections
import json
from pathlib import Path

import onnx
from onnx import numpy_helper


def tensor_value_info(value: onnx.ValueInfoProto) -> dict[str, object]:
    tensor = value.type.tensor_type
    dimensions: list[int | str | None] = []
    for dimension in tensor.shape.dim:
        if dimension.HasField("dim_value"):
            dimensions.append(int(dimension.dim_value))
        elif dimension.HasField("dim_param"):
            dimensions.append(dimension.dim_param)
        else:
            dimensions.append(None)
    return {
        "name": value.name,
        "elem_type": int(tensor.elem_type),
        "shape": dimensions,
    }


def summarize(path: Path) -> dict[str, object]:
    model = onnx.load(path)
    onnx.checker.check_model(model)
    operators = collections.Counter(node.op_type for node in model.graph.node)
    domains = collections.Counter(node.domain or "ai.onnx" for node in model.graph.node)
    initializers = [
        {
            "name": initializer.name,
            "dtype": int(initializer.data_type),
            "shape": list(initializer.dims),
        }
        for initializer in model.graph.initializer
    ]
    parameter_count = sum(
        numpy_helper.to_array(initializer).size for initializer in model.graph.initializer
    )
    return {
        "model": str(path),
        "size_bytes": path.stat().st_size,
        "ir_version": model.ir_version,
        "producer": f"{model.producer_name} {model.producer_version}".strip(),
        "graph": model.graph.name,
        "opset": [{"domain": item.domain or "ai.onnx", "version": item.version} for item in model.opset_import],
        "inputs": [tensor_value_info(value) for value in model.graph.input],
        "outputs": [tensor_value_info(value) for value in model.graph.output],
        "operators": dict(sorted(operators.items())),
        "domains": dict(sorted(domains.items())),
        "parameter_count": parameter_count,
        "initializers": initializers,
        "nodes": [
            {"name": node.name, "op_type": node.op_type, "domain": node.domain or "ai.onnx"}
            for node in model.graph.node
        ],
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--model", type=Path, required=True)
    parser.add_argument("--output", type=Path, default=None)
    args = parser.parse_args()
    summary = summarize(args.model.resolve())
    text = json.dumps(summary, indent=2) + "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(text, encoding="utf-8")
        print(args.output)
    else:
        print(text, end="")


if __name__ == "__main__":
    main()

