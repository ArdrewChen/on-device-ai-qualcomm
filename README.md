# Hvx

Q6A / QCS6490 的模型轻量化、QNN 部署和 Hexagon DSP 前后处理算子开发框架。

项目使用 CMake 和特性名目录组织：

```text
nn/<feature>/       该特性的模型轻量化算法
deploy/<feature>/   同一特性的模型部署和 DSP 前后处理算子
```

`nn/tiny_cnn` 和 `deploy/tiny_cnn` 表示同一个 `tiny_cnn` 特性的算法侧与部署侧。
以后新增 `nn/face`、`deploy/face` 时，CMake 会自动发现，不需要修改顶层 CMake。

## 顶层结构

```text
CMakeLists.txt
CMakePresets.json
runtime/            所有特性共享的 Docker、诊断和容器入口
common/             共享 shell 环境和路径解析
cmake/              CMake 辅助函数
config/project.env  共享主机、板端和 SDK 配置
nn/                 模型轻量化特性
deploy/             对应特性的部署与 DSP 算子
docs/
artifacts/          唯一生成产物区
build/              CMake/Ninja 生成目录
```

## tiny_cnn 特性

### NN 侧

```text
nn/tiny_cnn/
  config/feature.env
  configs/tiny_cnn.yaml
  python/hvx_nn_tiny_cnn/
  scripts/
  tests/
```

包含：

- 教师训练和学生知识蒸馏
- 模型轻量化实验入口
- ONNX 导出
- 校准 raw 和参考输出生成
- ONNX 算子和参数量分析

### Deploy 侧

```text
deploy/tiny_cnn/
  config/feature.env
  model/          QNN 转换、INT8、context 和 bundle
  operator/       QAIC、HVX、DSP 前后处理工程
  scripts/        板端同步和运行
```

## 配置

```bash
cd /home/cyrus/code/Hvx
cmake --preset default
```

当前自动发现结果：

```text
NN feature: tiny_cnn
Deploy feature: tiny_cnn
```

查看所有 target：

```bash
cmake --build build --target help | grep hvx_
```

## 共享 Runtime

```text
runtime/
```

由顶层 CMake 无条件加入。Docker 模型特性显式依赖 `hvx_runtime_image`：

```text
hvx_nn_tiny_cnn_distill
hvx_nn_tiny_cnn_calibration
hvx_nn_tiny_cnn_inspect
hvx_nn_tiny_cnn_test
```

因此它们共享同一套 PyTorch、ONNX Runtime 和容器入口。

## 常用命令

构建模型环境：

```bash
cmake --build build --target hvx_runtime_image
cmake --build build --target hvx_doctor
```

NN 算法：

```bash
cmake --build build --target hvx_nn_tiny_cnn_test
cmake --build build --target hvx_nn_tiny_cnn_distill
cmake --build build --target hvx_nn_tiny_cnn_inspect
```

模型部署：

```bash
cmake --build build --target hvx_deploy_tiny_cnn_qnn_convert
cmake --build build --target hvx_deploy_tiny_cnn_qnn_context
cmake --build build --target hvx_deploy_tiny_cnn_qnn_bundle
cmake --build build --target hvx_deploy_tiny_cnn
```

DSP 前后处理算子 smoke：

```bash
cmake --build build --target hvx_deploy_tiny_cnn_dsp_build
cmake --build build --target hvx_deploy_tiny_cnn_dsp_run
```

完整流水线：

```bash
cmake --build build --target hvx_pipeline_tiny_cnn
```

`hvx_pipeline` 是默认特性 `tiny_cnn` 的别名。可通过 CMake cache 修改：

```bash
cmake --preset default -DHVX_DEFAULT_FEATURE=face
```

## 输出

NN 产物：

```text
artifacts/nn/tiny_cnn/
  student.onnx
  teacher.onnx
  student.pt
  teacher.pt
  metrics.json
  model_summary.json
  calibration/
  calibration_list.txt
```

部署产物：

```text
artifacts/deploy/tiny_cnn/
  qnn/
  bundle/
  logs/
```

## 新增特性

```text
nn/face/CMakeLists.txt
nn/face/config/feature.env
deploy/face/CMakeLists.txt
deploy/face/config/feature.env
```

约定和示例见 [特性目录规范](docs/features.md)。

