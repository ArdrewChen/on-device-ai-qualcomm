# Model Deployment

`tiny_cnn` 的 QNN 模型转换和 bundle 构建。

## CMake targets

- `hvx_deploy_tiny_cnn_qnn_convert`
- `hvx_deploy_tiny_cnn_qnn_context`
- `hvx_deploy_tiny_cnn_qnn_bundle`

默认输入来自 `artifacts/nn/tiny_cnn`，输出位于
`artifacts/deploy/tiny_cnn/qnn` 和 `artifacts/deploy/tiny_cnn/bundle`。

也可以直接传外部模型：

```bash
deploy/tiny_cnn/model/scripts/qnn-build.sh model_name /path/to/model.onnx
deploy/tiny_cnn/model/scripts/qnn-context.sh model_name
deploy/tiny_cnn/model/scripts/qnn-bundle.sh model_name
```

外部模型的校准列表和输入 shape 必须与 `config/feature.env` 一致。

