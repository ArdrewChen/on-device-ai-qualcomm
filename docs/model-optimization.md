# 模型轻量化与量化

## 推荐阶段

1. **基线模型**：固定输入输出契约、数据预处理和参考精度。
2. **教师蒸馏**：先确认教师精度，再训练 student。
3. **结构优化**：通道裁剪、层替换、算子融合；每步保存 ONNX 和精度。
4. **QAT**：在 student 中用 fake quant 模拟 QNN 定点误差。
5. **导出**：静态 batch 1，显式输入输出名，opset 17 起步。
6. **QNN 静态量化**：用真实校准集生成 INT8 DLC。
7. **实机误差评估**：与 FP32 ONNX 参考输出比较 top-k、余弦相似度和最大误差。

## 模型契约

默认示例：

```text
input:  float32[1,3,32,32]  NCHW
logits: float32[1,10]
```

QNN HTP 常见 NHWC 数据格式由 converter/backend 处理。不要在训练、校准和板端
raw 输入之间隐式改变 layout；如果需要 layout transform，必须把变换定义为模型
图的一部分，或在 board harness 中显式执行。

## 校准数据

- 使用真实部署样本，不要用随机噪声判断最终精度。
- 覆盖典型场景、长尾类别和边界亮度。
- 同时保存 calib raw、参考 ONNX 输出和样本 ID。
- 每次模型或预处理变化都重新生成校准集。

## 实验记录

`metrics.json` 是初始记录格式。建议继续增加：

- 参数量和 MACs
- FP32/INT8 top-1、top-5
- 每层量化误差
- cDSP/V68 latency 和 VTCM 占用
- 使用的 QAIRT、Hexagon SDK 和板端版本

模型简化工具 `onnxsim` 没有放进基础镜像，因为当前 NGC 镜像的 CMake 包装器在
PEP 517 构建隔离环境中需要额外配置。需要时可在派生实验镜像中单独安装：

```bash
python3 -m pip install cmake
python3 -m pip install onnxsim
```

