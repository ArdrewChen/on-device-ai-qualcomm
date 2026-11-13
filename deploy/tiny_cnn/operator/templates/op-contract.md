# DSP 算子接口约定模板

## 功能

- 算子名：
- 前置/后置位置：
- 参考实现：
- 输入 layout：
- 输入 dtype：
- 输出 layout：
- 输出 dtype：

## 尺寸与对齐

- 输入 shape：
- 输出 shape：
- 最大 buffer：
- 128B 对齐要求：
- 尾部处理：
- 溢出/饱和规则：

## FastRPC / IDL

```text
interface <operator> : remote_handle64 {
    long process(in sequence<...> input, ...);
};
```

必须记录：

- IDL 版本
- stub/skel 版本检查
- 输出长度由谁分配
- remote handle 生命周期
- DMA/rpcmem buffer 生命周期

## 验证

- C reference：
- simulator：
- cDSP unsigned PD：
- signed PD：
- 最大绝对误差：
- 最大相对误差：
- 边界用例：
- V68 指令/HVX 使用：
- VTCM/周期：

