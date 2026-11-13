# Deploy / tiny_cnn

`tiny_cnn` 特性的部署侧实现，和 `nn/tiny_cnn` 使用同一个特性名。

## 结构

```text
config/feature.env          部署侧模型契约和输出路径
model/                      QNN 转换、量化、context 和 bundle
operator/                   DSP 前后处理算子、QAIC 和 HVX 开发区
scripts/deploy.sh           板端同步和运行
```

## CMake targets

- `hvx_deploy_tiny_cnn_qnn_convert`
- `hvx_deploy_tiny_cnn_qnn_context`
- `hvx_deploy_tiny_cnn_qnn_bundle`
- `hvx_deploy_tiny_cnn_dsp_build`
- `hvx_deploy_tiny_cnn_dsp_run`
- `hvx_deploy_tiny_cnn`
- `hvx_pipeline_tiny_cnn`

## 输入

模型部署默认消费：

```text
artifacts/nn/tiny_cnn/student.onnx
artifacts/nn/tiny_cnn/calibration_list.txt
artifacts/nn/tiny_cnn/calibration/*.raw
```

## 输出

```text
artifacts/deploy/tiny_cnn/qnn/
artifacts/deploy/tiny_cnn/bundle/
artifacts/deploy/tiny_cnn/logs/
```

前后处理算子放在 `deploy/tiny_cnn/operator/projects/<operator>/`，每个算子保持
独立 IDL、skel、host app 和构建脚本。

