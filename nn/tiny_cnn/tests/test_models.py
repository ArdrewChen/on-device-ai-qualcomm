from __future__ import annotations

import unittest

import torch

from hvx_nn_tiny_cnn.data import SyntheticClassDataset
from hvx_nn_tiny_cnn.models import build_student, build_teacher


class ModelContractTest(unittest.TestCase):
    def test_student_io_contract(self) -> None:
        model = build_student(10).eval()
        with torch.no_grad():
            output = model(torch.randn(1, 3, 32, 32))
        self.assertEqual(tuple(output.shape), (1, 10))

    def test_teacher_io_contract(self) -> None:
        model = build_teacher(10).eval()
        with torch.no_grad():
            output = model(torch.randn(1, 3, 32, 32))
        self.assertEqual(tuple(output.shape), (1, 10))

    def test_synthetic_dataset_contract(self) -> None:
        dataset = SyntheticClassDataset(
            samples=4,
            input_shape=(1, 3, 32, 32),
            num_classes=10,
            seed=1,
        )
        inputs, labels = dataset[0]
        self.assertEqual(tuple(inputs.shape), (3, 32, 32))
        self.assertEqual(inputs.dtype, torch.float32)
        self.assertEqual(labels.ndim, 0)


if __name__ == "__main__":
    unittest.main()

