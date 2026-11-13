"""Deterministic synthetic data for validating the distillation pipeline."""

from __future__ import annotations

import torch
from torch.utils.data import Dataset


class SyntheticClassDataset(Dataset[tuple[torch.Tensor, torch.Tensor]]):
    """Generate ten visually separable 32x32 NCHW classes.

    This dataset is intentionally small and synthetic. Replace it with a real
    Dataset implementation when starting a model task.
    """

    def __init__(
        self,
        samples: int,
        input_shape: tuple[int, int, int, int],
        num_classes: int,
        seed: int,
    ) -> None:
        if input_shape[0] != 1:
            raise ValueError("The starter dataset expects batch-1 input_shape")
        if input_shape[1] != 3:
            raise ValueError("The starter dataset expects three input channels")
        if num_classes > 12:
            raise ValueError("The starter pattern supports at most 12 classes")

        self.inputs: torch.Tensor
        self.labels: torch.Tensor
        generator = torch.Generator().manual_seed(seed)
        labels = torch.arange(samples) % num_classes
        inputs = torch.randn((samples, *input_shape[1:]), generator=generator) * 0.25

        for index, label_tensor in enumerate(labels):
            label = int(label_tensor)
            channel = label % 3
            row = 5 + (label // 3) * 7
            column = 5 + ((label * 2) % 7) * 3
            inputs[index, channel, row : row + 4, column : column + 4] += 2.5

        self.inputs = inputs.contiguous()
        self.labels = labels.to(dtype=torch.long)

    def __len__(self) -> int:
        return self.inputs.shape[0]

    def __getitem__(self, index: int) -> tuple[torch.Tensor, torch.Tensor]:
        return self.inputs[index], self.labels[index]

