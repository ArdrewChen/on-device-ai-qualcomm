# 特性目录规范

一个业务特性由两个同名目录表示：

```text
nn/<feature>/       模型轻量化算法
deploy/<feature>/   模型部署与 DSP 前后处理
```

例如：

```text
nn/face/
deploy/face/
```

## NN 侧职责

- 数据与训练
- 知识蒸馏
- pruning、QAT 等轻量化算法
- ONNX 导出
- 校准样本和参考输出
- 模型结构和参数量分析

路径约定：

```text
nn/<feature>/
  CMakeLists.txt
  README.md
  config/feature.env
  configs/
  python/
  scripts/
  tests/
```

NN 输出：

```text
artifacts/nn/<feature>/
```

## Deploy 侧职责

- ONNX -> QNN DLC
- 静态量化和 context binary
- board runtime bundle
- 模型同步和实机执行
- 前后处理 IDL、skel、HVX、QAIC
- signed/unsigned PD 策略

路径约定：

```text
deploy/<feature>/
  CMakeLists.txt
  README.md
  config/feature.env
  model/
  operator/
  scripts/
```

Deploy 输出：

```text
artifacts/deploy/<feature>/
```

## 自动发现

`nn/CMakeLists.txt` 和 `deploy/CMakeLists.txt` 会扫描各自目录下包含
`CMakeLists.txt` 的子目录，所以新增 `nn/face` 或 `deploy/face` 后重新 configure
即可，不需要修改顶层 CMake。

推荐 target：

```text
hvx_nn_<feature>_distill
hvx_nn_<feature>_calibration
hvx_nn_<feature>_inspect
hvx_nn_<feature>_test
hvx_deploy_<feature>_qnn_convert
hvx_deploy_<feature>_qnn_context
hvx_deploy_<feature>_qnn_bundle
hvx_deploy_<feature>_dsp_build
hvx_deploy_<feature>_dsp_run
hvx_deploy_<feature>
hvx_pipeline_<feature>
```

## 共享边界

- `runtime/`：共享 Docker 和诊断。
- `common/scripts/`：共享路径和环境解析。
- `config/project.env`：主机、板端和 SDK 的共享配置。
- `nn/<feature>/config/feature.env`：NN 侧模型契约。
- `deploy/<feature>/config/feature.env`：Deploy 侧模型契约和输出路径。

NN 和 Deploy 只通过 `artifacts/nn/<feature>` 中的模型、校准数据和 metrics 交互。

