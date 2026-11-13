# Operator / tiny_cnn

`templates/` 保存可复用的接口和开发约定，`projects/` 用于实际前后算子。

初始环境先通过 SDK 自带 QAIC calculator 验证：

```bash
cmake --build build --target hvx_deploy_tiny_cnn_dsp_build
cmake --build build --target hvx_deploy_tiny_cnn_dsp_run
```

该 smoke 使用：

- Hexagon SDK `6.4.0.2`
- Hexagon Tools `19.0.04`
- QAIC `01.00.49`
- V68 ISA
- cDSP domain 3 / unsigned PD

新算子建议从 `templates/op-contract.md` 开始，不要直接修改 SDK 安装目录中的
示例。创建 `deploy/tiny_cnn/operator/projects/<name>` 后，可以逐步把它接入
本特性的构建和部署脚本。

