#!/usr/bin/env python3
"""Train a teacher, distill a student and export a QNN-ready ONNX graph."""

from __future__ import annotations

import argparse
import json
import random
from pathlib import Path
from typing import Any

import numpy as np
import onnx
import torch
import torch.nn.functional as functional
from torch import nn
from torch.utils.data import DataLoader

from .config import load_config
from .data import SyntheticClassDataset
from .models import build_student, build_teacher


def seed_everything(seed: int) -> None:
    random.seed(seed)
    np.random.seed(seed)
    torch.manual_seed(seed)
    if torch.cuda.is_available():
        torch.cuda.manual_seed_all(seed)


def resolve_device(requested: str) -> torch.device:
    if requested == "auto":
        return torch.device("cuda" if torch.cuda.is_available() else "cpu")
    return torch.device(requested)


def make_loader(
    config: dict[str, Any],
    split: str,
    device: torch.device,
) -> DataLoader[tuple[torch.Tensor, torch.Tensor]]:
    data_config = config["data"]
    samples = int(data_config["train_samples"] if split == "train" else data_config["val_samples"])
    seed = int(config["experiment"]["seed"]) + (0 if split == "train" else 100_000)
    dataset = SyntheticClassDataset(
        samples=samples,
        input_shape=tuple(int(value) for value in data_config["input_shape"]),
        num_classes=int(data_config["num_classes"]),
        seed=seed,
    )
    return DataLoader(
        dataset,
        batch_size=int(data_config["batch_size"]),
        shuffle=split == "train",
        num_workers=int(data_config["num_workers"]),
        pin_memory=device.type == "cuda",
    )


@torch.no_grad()
def evaluate(model: nn.Module, loader: DataLoader[Any], device: torch.device) -> float:
    model.eval()
    correct = 0
    total = 0
    for inputs, labels in loader:
        inputs = inputs.to(device, non_blocking=True)
        labels = labels.to(device, non_blocking=True)
        predictions = model(inputs).argmax(dim=1)
        correct += int((predictions == labels).sum())
        total += labels.numel()
    return correct / max(total, 1)


def train_classifier(
    model: nn.Module,
    train_loader: DataLoader[Any],
    val_loader: DataLoader[Any],
    epochs: int,
    learning_rate: float,
    weight_decay: float,
    device: torch.device,
) -> float:
    model.to(device)
    optimizer = torch.optim.AdamW(
        model.parameters(), lr=learning_rate, weight_decay=weight_decay
    )
    criterion = nn.CrossEntropyLoss()
    for epoch in range(epochs):
        model.train()
        total_loss = 0.0
        for inputs, labels in train_loader:
            inputs = inputs.to(device, non_blocking=True)
            labels = labels.to(device, non_blocking=True)
            optimizer.zero_grad(set_to_none=True)
            loss = criterion(model(inputs), labels)
            loss.backward()
            optimizer.step()
            total_loss += float(loss.detach())
        accuracy = evaluate(model, val_loader, device)
        print(
            f"teacher epoch={epoch + 1}/{epochs} "
            f"loss={total_loss / max(len(train_loader), 1):.4f} "
            f"val_acc={accuracy:.4f}",
            flush=True,
        )
    return evaluate(model, val_loader, device)


def train_student(
    teacher: nn.Module,
    student: nn.Module,
    train_loader: DataLoader[Any],
    val_loader: DataLoader[Any],
    config: dict[str, Any],
    device: torch.device,
) -> float:
    student.to(device)
    teacher.to(device).eval()
    optimizer = torch.optim.AdamW(
        student.parameters(),
        lr=float(config["student"]["learning_rate"]),
        weight_decay=float(config["student"]["weight_decay"]),
    )
    temperature = float(config["distillation"]["temperature"])
    alpha = float(config["distillation"]["alpha"])
    epochs = int(config["student"]["epochs"])

    for epoch in range(epochs):
        student.train()
        total_loss = 0.0
        for inputs, labels in train_loader:
            inputs = inputs.to(device, non_blocking=True)
            labels = labels.to(device, non_blocking=True)
            optimizer.zero_grad(set_to_none=True)
            student_logits = student(inputs)
            with torch.no_grad():
                teacher_logits = teacher(inputs)
            hard_loss = functional.cross_entropy(student_logits, labels)
            soft_loss = functional.kl_div(
                functional.log_softmax(student_logits / temperature, dim=1),
                functional.softmax(teacher_logits / temperature, dim=1),
                reduction="batchmean",
            ) * (temperature * temperature)
            loss = alpha * soft_loss + (1.0 - alpha) * hard_loss
            loss.backward()
            optimizer.step()
            total_loss += float(loss.detach())
        accuracy = evaluate(student, val_loader, device)
        print(
            f"student epoch={epoch + 1}/{epochs} "
            f"loss={total_loss / max(len(train_loader), 1):.4f} "
            f"val_acc={accuracy:.4f}",
            flush=True,
        )
    return evaluate(student, val_loader, device)


def export_onnx(
    model: nn.Module,
    path: Path,
    input_shape: tuple[int, int, int, int],
    graph_name: str,
    opset: int,
    input_name: str,
    output_name: str,
) -> None:
    model = model.to("cpu").eval()
    dummy = torch.randn(input_shape)
    path.parent.mkdir(parents=True, exist_ok=True)
    torch.onnx.export(
        model,
        dummy,
        path,
        input_names=[input_name],
        output_names=[output_name],
        opset_version=opset,
        do_constant_folding=True,
        dynamo=False,
    )
    exported = onnx.load(path)
    exported.graph.name = graph_name
    onnx.checker.check_model(exported)
    onnx.save(exported, path)


def write_calibration(
    model_path: Path,
    run_dir: Path,
    input_shape: tuple[int, int, int, int],
    samples: int,
    seed: int,
    input_name: str,
) -> None:
    try:
        import onnxruntime as ort
    except ImportError as exc:
        raise SystemExit("onnxruntime is required to generate reference outputs") from exc

    calibration_dir = run_dir / "calibration"
    calibration_dir.mkdir(parents=True, exist_ok=True)
    dataset = SyntheticClassDataset(samples, input_shape, 10, seed + 200_000)
    session = ort.InferenceSession(str(model_path), providers=["CPUExecutionProvider"])
    entries: list[str] = []
    for index in range(min(samples, len(dataset))):
        sample, _ = dataset[index]
        array = sample.numpy().astype(np.float32, copy=False)
        raw_path = calibration_dir / f"calib_{index:03d}.raw"
        array.tofile(raw_path)
        reference = session.run(None, {input_name: array[None, ...]})[0]
        np.save(calibration_dir / f"reference_{index:03d}.npy", reference)
        entries.append(raw_path.name)
    (run_dir / "calibration_list.txt").write_text(
        "".join(f"{name}\n" for name in entries), encoding="utf-8"
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--config",
        type=Path,
        default=Path("nn/tiny_cnn/configs/tiny_cnn.yaml"),
    )
    parser.add_argument("--calibration-only", action="store_true")
    parser.add_argument("--device", default=None)
    parser.add_argument("--teacher-epochs", type=int, default=None)
    parser.add_argument("--student-epochs", type=int, default=None)
    args = parser.parse_args()

    config = load_config(args.config)
    if args.teacher_epochs is not None:
        config["teacher"]["epochs"] = args.teacher_epochs
    if args.student_epochs is not None:
        config["student"]["epochs"] = args.student_epochs

    seed = int(config["experiment"]["seed"])
    seed_everything(seed)
    device = resolve_device(args.device or str(config["experiment"]["device"]))
    run_dir = Path(str(config["experiment"]["output_dir"]))
    run_dir.mkdir(parents=True, exist_ok=True)
    input_shape = tuple(int(value) for value in config["data"]["input_shape"])
    num_classes = int(config["data"]["num_classes"])
    input_name = "input"
    output_name = "logits"
    opset = int(config["export"]["opset"])

    student = build_student(num_classes)
    teacher = build_teacher(num_classes)
    student_path = run_dir / "student.onnx"
    teacher_path = run_dir / "teacher.onnx"
    student_checkpoint = run_dir / "student.pt"
    teacher_checkpoint = run_dir / "teacher.pt"
    metrics_path = run_dir / "metrics.json"

    if args.calibration_only:
        if not student_path.is_file():
            raise SystemExit(f"{student_path} does not exist")
        write_calibration(
            student_path,
            run_dir,
            input_shape,
            int(config["export"]["calibration_samples"]),
            seed,
            input_name,
        )
        print(f"calibration: {run_dir / 'calibration_list.txt'}")
        return

    train_loader = make_loader(config, "train", device)
    val_loader = make_loader(config, "val", device)

    if teacher_checkpoint.is_file():
        teacher.load_state_dict(torch.load(teacher_checkpoint, map_location="cpu", weights_only=True))
        teacher_accuracy = evaluate(teacher.to(device), val_loader, device)
        print(f"teacher restored val_acc={teacher_accuracy:.4f}")
    else:
        teacher_accuracy = train_classifier(
            teacher,
            train_loader,
            val_loader,
            int(config["teacher"]["epochs"]),
            float(config["teacher"]["learning_rate"]),
            float(config["teacher"]["weight_decay"]),
            device,
        )
        torch.save(teacher.cpu().state_dict(), teacher_checkpoint)

    student_accuracy = train_student(teacher, student, train_loader, val_loader, config, device)
    torch.save(student.cpu().state_dict(), student_checkpoint)
    export_onnx(student, student_path, input_shape, "student", opset, input_name, output_name)
    export_onnx(teacher, teacher_path, input_shape, "teacher", opset, input_name, output_name)
    write_calibration(
        student_path,
        run_dir,
        input_shape,
        int(config["export"]["calibration_samples"]),
        seed,
        input_name,
    )

    metrics = {
        "experiment": config["experiment"]["name"],
        "device": str(device),
        "teacher": {"validation_accuracy": teacher_accuracy, "onnx": str(teacher_path)},
        "student": {
            "validation_accuracy": student_accuracy,
            "onnx": str(student_path),
            "input": {"name": input_name, "shape": list(input_shape), "dtype": "float32"},
        },
        "distillation": config["distillation"],
    }
    metrics_path.write_text(json.dumps(metrics, indent=2) + "\n", encoding="utf-8")
    print(f"student: {student_path}")
    print(f"teacher: {teacher_path}")
    print(f"metrics: {metrics_path}")
    print(f"calibration list: {run_dir / 'calibration_list.txt'}")


if __name__ == "__main__":
    main()

