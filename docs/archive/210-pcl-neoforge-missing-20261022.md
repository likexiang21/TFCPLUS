# PCL 导入后 NeoForge 缺失错误记录（2026-10-22）

## 报告结论

用户提供的 `错误报告-2026-10-22_8.49.10` 显示，PCL 已经找到并加载模组目录，但启动阶段报告大量：

```text
Mod ID: 'neoforge' ... Actual version: '[MISSING]'
Mod ID: 'minecraft' ... Actual version: '[MISSING]'
```

随后 NeoForge 在 `DisplayWindow.updateModuleReads` 抛出 `NoSuchElementException`，进程以返回值 1 退出。

这不是 TFCAgriculturePlus、养蚕或面团代码错误，而是客户端压缩包中的版本 JSON 没有声明 NeoForge 21.1.248 本体。PCL 因此只补全了 JSON 中已有的 FML 支持库，没有下载 NeoForge 通用包。

## 修复包

已生成修复版：

- 文件：`D:\TFC农业重置\TFCAgriculturePlus-PCL-Client-20261022-v2.zip`
- SHA-256：`19CC67AA8CB9102A3D1B85DE70B2BB2C7E226C0A62CDA5C3A7C09AF80BFE1817`
- 版本 JSON 已加入：`net.neoforged:neoforge:21.1.248`
- 下载地址：`https://maven.neoforged.net/releases/net/neoforged/neoforge/21.1.248/neoforge-21.1.248-universal.jar`
- 437 个条目；无超长路径；无非 ASCII 内部路径。

## 使用方式

请在 PCL 中使用 v2 压缩包导入到一个新的空实例目录，不要覆盖已经启动失败的旧实例。首次启动时保持网络连接，让 PCL 下载 NeoForge 通用包；启动成功后再进行实机功能验证。

旧的 `TFCAgriculturePlus-PCL-Client-20261022.zip` 和 `TFCAgriculturePlus-PCL-Instance-20261021.zip` 均保留作回滚参考，不再作为正式测试包。
