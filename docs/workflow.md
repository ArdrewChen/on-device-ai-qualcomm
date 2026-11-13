# 工作流

## 1. 模型设计与真实数据

实验代码在 `nn/tiny_cnn/python/hvx_nn_tiny_cnn`。默认 TinyCNN 只用于
跑通环境；接入真实任务时：

1. 在 `data.py` 实现真实 Dataset。
2. 在 `models.py` 或独立模块实现 teacher/student。
3. 在 `nn/tiny_cnn/configs/*.yaml` 固定输入 shape、dtype、颜色空间、
   归一化和校准策略。
4. 在 `/data/datasets` 和 `/data/models` 保存数据与权重。

## 2. 蒸馏和轻量化

默认入口：

```bash
cmake --build build --target hvx_nn_tiny_cnn_distill
cmake --build build --target hvx_nn_tiny_cnn_inspect
```

生成：

```text
artifacts/nn/tiny_cnn/
  teacher.pt
  student.pt
  teacher.onnx
  student.onnx
  metrics.json
  model_summary.json
  calibration/
  calibration_list.txt
```

后续可以在 student 训练阶段加入：

- structured pruning / channel pruning
- QAT fake quant
- layer replacement
- attention / feature distillation
- latency-aware loss

任何结构改变都应保持 ONNX 输入输出契约可追踪。

## 3. QNN conversion 和量化

QNN 工具必须运行在 WSL 原生环境：

```bash
cmake --build build --target hvx_deploy_tiny_cnn_qnn_convert
cmake --build build --target hvx_deploy_tiny_cnn_qnn_context
```

产物：

```text
artifacts/deploy/tiny_cnn/qnn/
  student.dlc
  student_quantized.dlc
  context/student_quantized.bin
```

校准输入是 little-endian float32 raw，默认按 NCHW 保存。真实模型的校准集必须
使用与部署一致的预处理。

## 4. 板端部署

```bash
cmake --build build --target hvx_deploy_tiny_cnn_qnn_bundle
cmake --build build --target hvx_deploy_tiny_cnn
```

`deploy/tiny_cnn/model/scripts/qnn-bundle.sh` 会复制：

- `qnn-net-run`
- ARM64 `libQnnHtp.so` 和 V68 stub
- V68 HTP skel
- context binary
- 校准输入

板端日志写入 `artifacts/deploy/tiny_cnn/logs/qnn-target.log`。

## 5. DSP 前后算子

先用已验证的 QAIC calculator 检查工具链：

```bash
cmake --build build --target hvx_deploy_tiny_cnn_dsp_build
cmake --build build --target hvx_deploy_tiny_cnn_dsp_run
```

自定义前后算子开发见 [DSP 算子开发](dsp-ops.md)。

