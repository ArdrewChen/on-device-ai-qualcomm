"""Small NCHW teacher and student models."""

from __future__ import annotations

import torch
from torch import nn


class TinyCNN(nn.Module):
    """A deterministic QNN-friendly CNN."""

    def __init__(self, widths: tuple[int, int], num_classes: int = 10) -> None:
        super().__init__()
        width1, width2 = widths
        self.features = nn.Sequential(
            nn.Conv2d(3, width1, kernel_size=3, padding=1, bias=True),
            nn.ReLU(inplace=True),
            nn.MaxPool2d(kernel_size=2, stride=2),
            nn.Conv2d(width1, width2, kernel_size=3, padding=1, bias=True),
            nn.ReLU(inplace=True),
            nn.AdaptiveAvgPool2d((1, 1)),
        )
        self.classifier = nn.Linear(width2, num_classes)

    def forward(self, inputs: torch.Tensor) -> torch.Tensor:
        features = self.features(inputs)
        features = torch.flatten(features, start_dim=1)
        return self.classifier(features)


def build_teacher(class_names: int) -> TinyCNN:
    return TinyCNN((16, 32), class_names)


def build_student(class_names: int) -> TinyCNN:
    return TinyCNN((8, 16), class_names)

