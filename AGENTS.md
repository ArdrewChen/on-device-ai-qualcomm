# Project Instructions

## Environment boundaries

- Run GPU training, distillation and ONNX export in the NGC PyTorch container.
- Run QAIRT conversion, QNN context generation and Hexagon DSP builds on the WSL
  host. Do not call host QAIRT binaries from the CUDA container.
- The authoritative QAIRT and Hexagon SDK trees are under
  `/home/cyrus/qcom-dev/sdk`; do not copy or vendor them into this repository.
- Board access is `radxa@192.168.1.64` with the existing SSH key.

## Model contract

- Keep model input NCHW until the QNN conversion boundary unless a model-specific
  layout change is explicitly documented.
- The default example uses `input: float32[1,3,32,32]`.
- Save one model per ONNX graph and prefer static batch 1 for Q6A contexts.
- Store calibration inputs as little-endian raw float32 in NCHW order.

## Commands

- Configure with `cmake --preset default`.
- `hvx_doctor`: validate host, container, board and toolchains.
- `hvx_nn_tiny_cnn_distill`: produce `artifacts/nn/tiny_cnn/student.onnx`.
- `hvx_nn_tiny_cnn_inspect`: report ONNX operator mix and parameter count.
- `hvx_deploy_tiny_cnn_qnn_*`: build QNN artifacts.
- `hvx_deploy_tiny_cnn_dsp_*`: run QAIC/V68 on cDSP.
- Validate shell changes with `shellcheck`; validate Python with
  `python -m unittest discover -s nn/tiny_cnn/tests -v`.

Build a target with:

```bash
cmake --build build --target <target>
```

## Feature boundaries

- Lightweighting features live under `nn/<feature>/`.
- Model deployment and DSP operators live under `deploy/<feature>/`.
- The same feature name links its NN and Deploy directories.
- Shared Docker/runtime code lives under top-level `runtime/` and is always added
  before optional features.
- Shared environment/path logic belongs in `common/scripts`; do not put feature
  implementation into the top-level CMake file.

## Generated content

- Do not commit `artifacts/`, model checkpoints, Docker layers, SDK trees,
  datasets or calibration datasets.
- Keep experiment metadata in YAML/JSON so generated binaries can be reproduced.
- Update `docs/validation.md` when changing a verified toolchain version or
  deployment path.

