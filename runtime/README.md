# Shared Runtime

项目级共享 runtime，负责 Docker 镜像、容器入口和主机/容器/板端环境诊断。
它不属于可选模型特性，所有使用容器的 feature 都共用这一份实现。

镜像基于已有：

```text
nvcr.io/nvidia/pytorch:25.12-py3
```

项目派生镜像为 `hvx-pytorch:25.12`，只增加 ONNX Runtime 和 YAML。

CMake targets：

- `hvx_runtime_image`
- `hvx_runtime_shell`
- `hvx_doctor`

构建和诊断：

```bash
cmake --preset default
cmake --build build --target hvx_runtime_image
cmake --build build --target hvx_doctor
```

