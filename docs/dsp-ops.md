# DSP 前后算子开发

## 目标边界

DSP 前后算子通常处理：

- 图像 layout 转换
- resize / crop / normalize
- NCHW/NHWC packing
- int8/uint8/float32 转换
- 量化边界和 embedding
- 后处理中的 argmax、NMS 前置筛选、输出重排

## 工作目录

```text
deploy/tiny_cnn/operator/
  templates/      IDL、stub/skel 和构建约定
  projects/       实际算子工程；每个工程独立
```

建议每个算子包含：

```text
deploy/tiny_cnn/operator/projects/<operator>/
  inc/<operator>.idl
  src/<operator>_imp.c
  src/app.c
  scripts/build.sh
  scripts/run-on-board.sh
  README.md
```

## 开发顺序

1. 写 C reference，并在 x86 上验证数学结果。
2. 用 QAIC 生成 stub/skel，确认函数签名和 buffer 长度。
3. 用 `hexagon-clang -mv68` 构建 scalar skel。
4. 在 `hexagon-sim -mv68` 运行边界用例。
5. 编译 ARM64 host app，通过 FastRPC 在 cDSP unsigned PD 上运行。
6. 加 HVX intrinsic，与 C reference 逐元素比较。
7. 最后并入模型 pre/post graph 或 QNN op package。

## HVX 规则

- 输入和输出分别处理 128B 对齐主路径与非对齐尾部。
- 不要假设 host 传来的指针天然 128B 对齐。
- 先测 VTCM/局部内存需求，再决定 tiling。
- 保持 scalar fallback，便于定位 HVX 与内存错误。
- 调试时先用小 shape，再做真实分辨率 benchmark。
- unsigned PD 能运行不代表 signed PD 能运行；安全启动和签名策略单独验证。

## 当前 smoke

Hexagon SDK 6.4 / QAIC calculator 已验证：

```bash
cmake --build build --target hvx_deploy_tiny_cnn_dsp_build
cmake --build build --target hvx_deploy_tiny_cnn_dsp_run
```

实机结果应为 `Sum = 499500`、`Max value = 999`、`Success`。

