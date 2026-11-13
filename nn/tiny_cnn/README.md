# NN / tiny_cnn

`tiny_cnn` 特性的模型轻量化算法和 ONNX 导出实现。

## 结构

```text
config/feature.env          特性名称、模型 IO 契约
configs/tiny_cnn.yaml       训练和蒸馏配置
python/hvx_nn_tiny_cnn/     模型、数据、蒸馏、导出和分析
tests/                      模型输入输出契约测试
scripts/                    CMake 调用的入口
```

## CMake targets

- `hvx_nn_tiny_cnn_distill`
- `hvx_nn_tiny_cnn_calibration`
- `hvx_nn_tiny_cnn_inspect`
- `hvx_nn_tiny_cnn_test`

## 输出

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

`deploy/tiny_cnn` 通过上述 ONNX 和校准数据契约接收本特性的输出。

