# 初始环境验证

验证日期：2026-11-14

## 环境版本

| 组件 | 版本 |
|---|---|
| NGC PyTorch | `25.12-py3` / PyTorch `2.10.0a0` |
| GPU | RTX 5070 / 12 GB / CUDA capability 12.0 |
| ONNX Runtime（容器） | `1.23.2` |
| QAIRT | `2.42.0.251225` |
| Hexagon SDK | `6.4.0.2` |
| Hexagon Tools | `19.0.04` |
| QAIC | `01.00.49` |
| 目标板 | Radxa Dragon Q6A / QCS6490 / V68 |

## 已验证命令

```bash
cmake --preset default
cmake --build build --target hvx_runtime_image
cmake --build build --target hvx_doctor
cmake --build build --target hvx_nn_tiny_cnn_test
cmake --build build --target hvx_nn_tiny_cnn_distill
cmake --build build --target hvx_nn_tiny_cnn_inspect
cmake --build build --target hvx_deploy_tiny_cnn_qnn_convert
cmake --build build --target hvx_deploy_tiny_cnn_qnn_context
cmake --build build --target hvx_deploy_tiny_cnn_qnn_bundle
cmake --build build --target hvx_deploy_tiny_cnn
cmake --build build --target hvx_deploy_tiny_cnn_dsp_build
cmake --build build --target hvx_deploy_tiny_cnn_dsp_run
```

结果：

- Host / Container doctor：0 failure
- Python model contract tests：3/3 PASSED
- 教师蒸馏学生：GPU 完成
- ONNX 导出：`student.onnx`，opset 17
- QNN：float DLC、INT8 DLC、V68 context 全部生成
- 板端 QNN：8 个校准输入完成 HTP 推理，输出均为 10 个有限 float32
- QAIC calculator：cDSP unsigned PD 输出 `499500` / `999` / `Success`

## 默认示例数据

TinyCNN 使用合成数据，仅用于验证完整工具链：

```text
teacher validation accuracy: 0.4258
student validation accuracy: 0.4043
student parameter count: 1562
student ONNX size: 7784 bytes
```

这些数值不代表真实视觉任务指标。真实项目应替换 Dataset、模型和校准集。

## 当前边界

- 已验证 cDSP unsigned PD；signed PD/签名流程尚未纳入默认流水线。
- DSP 自定义算子目录和接口模板已建立，但首个真实前/后算子尚未实现。
- QAT/pruning 接口位置已预留，当前默认只运行 FP32 蒸馏和 QNN PTQ。
- `onnxsim` 不在基础镜像中，需要时可单独安装。

