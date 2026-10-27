# PCL 客户端运行时重建与 14:47 崩溃报告复盘（2026-10-22）

## 输入与边界

- 用户报告：`D:\TFC农业重置\实机测试文件夹\新建文件夹\新建文件夹 (2)\错误报告-2026-10-22_14.47.30.zip`。
- 本轮只重建客户端版本定义、运行时文件和 PCL 导入包，没有改动任何模组 Java 源码或模组配方。
- 用户此前要求避免超长路径、木工不依赖原 TFC Woodworking、其他模组代码不得照抄示例模组；这些要求仍有效。

## 错误日志结论

14:47 报告里的 404 已不再是当前崩溃点。PCL 成功启动 Java 21 与 NeoForge 加载器，随后在 `DisplayWindow.updateModuleReads` 中抛出 `NoClassDefFoundError: net/minecraft/client/gui/screens/Overlay`。PCL 崩溃分析出现大量 `minecraft [MISSING]`，属于游戏模块没有正确组成后的连带症状。

当时的 PCL `-cp` 包含 NeoForge universal、NeoForge client 和实例主 JAR，却没有安装器生成的 `client-1.21.1-20240808.144430-srg.jar`。该 SRG JAR 中确实含有 `Overlay.class`；NeoForge client JAR 仅有部分修改类。之前把 NeoForge 的处理器输出当普通运行库写入版本 JSON，导致 PCL 放错加载层，先后触发 404、缺类和重复模块。这个结论同时由以下受控启动结果证实：

1. 四个产物都写入 JSON libraries：`Module autowalk reads more than one module named neoforge`。
2. 只从 JSON 移去 NeoForge client：`Modules client and minecraft export package ...`。
3. 四个产物保留在标准 Maven 路径、均不写入 JSON libraries：NeoForge 自带的 `ProductionClientProvider` 定位并合并 SRG、extra 和 client，游戏成功进入渲染与主菜单加载阶段。

本地 NeoForge 4.0.43 `ProductionClientProvider` 的字节码明确要求按 Maven 路径查找 `net.minecraft:client:...:srg`、`...:extra`，再加入 `net.neoforged:neoforge:21.1.248:client`，通过 `JarContents.of(...)` 组成一个 Minecraft 模块。NeoForge universal 由另一定位器读取。四个产物必须存在于 `libraries` 目录，但不应被 PCL 再作为四个独立运行库加到 classpath。

## 重建方式

`D:\TFC农业重置\rebuild-pcl-client.ps1` 从工作区中已由安装器生成的 Minecraft 1.21.1 JSON、NeoForge 21.1.248 JSON 和运行文件构建新实例。它合并原版与 NeoForge 的常规运行库和启动参数，去掉重复坐标，把安装器四个产物复制到标准 Maven 位置但不列入 JSON libraries。包内保留当前模组、配置、完整 assets、资源包、着色器与 `tfctest` 存档，并保留 PCL 的版本隔离设置，使游戏继续使用根目录的 mods。

这遵循了 PCL 官方源码的两条实际规则：普通客户端 ZIP 根据 `versions/<版本名>/<版本名>.json` 定位 `.minecraft` 根目录；启动器按版本 JSON 的 libraries 组装 classpath，并额外加入版本主 JAR。源码：

- [PCL `ModModpack.vb` 普通压缩包导入](https://github.com/Meloong-Git/PCL/blob/main/Plain%20Craft%20Launcher%202/Modules/Minecraft/ModModpack.vb)
- [PCL `ModMinecraft.vb` 运行库与版本 JAR 处理](https://github.com/Meloong-Git/PCL/blob/main/Plain%20Craft%20Launcher%202/Modules/Minecraft/ModMinecraft.vb)
- [PCL `ModLaunch.vb` 启动流程](https://github.com/Meloong-Git/PCL/blob/main/Plain%20Craft%20Launcher%202/Modules/Minecraft/ModLaunch.vb)

## 验证与交付

- 独立目录 `D:\TFC农业重置\pcl_rebuild_20261022\TFC\.minecraft` 用 Java 21 和不含真实账号令牌的离线参数启动。日志识别 Minecraft 1.21.1、NeoForge 21.1.248、TFCAgriculturePlus、TFCFarmingPlus；渲染线程完成资源加载，ModernFix 记录启动用时 35.427 秒。之后只终止了本轮创建的诊断进程。
- 离线诊断期间 Mojang/Realms 网络请求失败、I18nUpdateMod 的本机缓存写入被拒绝，均未阻断游戏启动。不能由此证明在线账号功能或存档内交互。
- 已逐项检查 JSON 声明的 Windows 运行库，缺失数 0；ZIP 中四个安装器产物、主 JSON、PCL 版本设置均存在。
- PCL 官方普通压缩包正则对 ZIP 内版本路径只匹配一次。最长相对文件路径 159 字符；在此前失败实例的完整目录下，最长提取路径约 217 字符。
- ZIP 4439 个条目，全部可以读取；SHA-256 为 `6D7E57FDD3814104C89E4898EF9560F8C0E25E6EF72F7F2D157AAD97BBA94971`。
- 新交付文件：`D:\TFC农业重置\TFCAgriculturePlus-PCL-Client-20261022-v6.zip`。v1～v5 不再作为可用交付版本。

本记录写成时，PCL 图形界面的实际导入与用户账号启动尚待验证；当时验证的是独立离线启动和 PCL 源码静态导入规则。随后用户已反馈 v6 在 PCL 中可以正常运行。完整打包流程和历次失误见 [215 号打包前必读记录](215-pcl-packaging-playbook-and-failure-lessons-20261022.md)。
