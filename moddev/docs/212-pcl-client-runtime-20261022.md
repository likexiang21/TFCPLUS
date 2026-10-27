# PCL NeoForge 客户端运行库修复记录（2026-10-22）

> 更正：本记录中的 v4 包后来被证实仍会触发普通 NeoForge JAR 的 404；原因是打包时沿用了缺少 universal `size` 的 v2 JSON。v4 已废弃，请以 [213-pcl-v5-runtime-repair-20261022.md](213-pcl-v5-runtime-repair-20261022.md) 为准。

## 1. 新报告结论

新报告显示，v3 已经把 NeoForge 通用包下载到了：

`libraries/net/neoforged/neoforge/21.1.248/neoforge-21.1.248-universal.jar`

因此先前的 NeoForge 404 和普通 `neoforge-21.1.248.jar` 回退路径已经修复。新的崩溃发生在启动后续阶段：

`ClassNotFoundException: net.minecraft.client.gui.screens.LoadingOverlay`

这说明整合包只有通用 NeoForge 本体和原始 Minecraft 客户端，没有同版本 NeoForge 生成的客户端映射运行库。

## 2. 工作区中的可用运行库

工作区工具链已经存在 NeoForge 21.1.248 对应文件：

- 文件：`neoforge-21.1.248-client.jar`
- 大小：5,675,624 字节
- SHA-1：`BAB98816CFDBCCC1E9076872771EF81F39AFBCC9`
- 已核对包含：`net/minecraft/client/gui/screens/LoadingOverlay.class`

它与项目版本 JSON 的 Minecraft 1.21.1、NeoForm 20240808.144430 和 NeoForge 21.1.248 相匹配。

## 3. v4 修复内容

已生成：

`D:\TFC农业重置\TFCAgriculturePlus-PCL-Client-20261022-v4.zip`

压缩包 SHA-256：

`EAC8ADA36B4DB8A6BA0D2BC43FE4412F35D2673C45E23A64FF056FD6CA7662A0`

v4 做了两项运行时修复：

1. 把客户端运行库内置到 `.minecraft/libraries/net/neoforged/neoforge/21.1.248/neoforge-21.1.248-client.jar`。
2. 在客户端版本 JSON 中加入 `net.neoforged:neoforge:21.1.248:client`，登记正确的 `path`、`size`、`sha1` 和官方 URL，使 PCL 能识别并复用该文件。

原有的 `neoforge-21.1.248-universal.jar` 声明仍保留，用于 NeoForge 通用启动组件。

## 4. 使用与验证

请用 v4 导入一个新的空实例，避免沿用已经失败过的实例缓存。首次启动时保持网络可用，让 PCL 补齐其他普通依赖。重点检查启动日志中是否出现：

- `neoforge-21.1.248-client.jar`
- 不再出现 `LoadingOverlay` 的 `ClassNotFoundException`
- 能进入主菜单并加载测试存档

本次修改只处理客户端整合包运行库，不修改模组源码、配方或存档。
