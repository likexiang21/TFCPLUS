# 第 10 步：第 9 步内容实机回归（2026-10-08）

## 验证方式

- 使用 `launch-validation-client.ps1` 启动隔离存档 `codex-validation-20261008d`。
- 使用当前部署的 A/B jar；封窑测试继续跳过。
- 首次受限运行被 Windows 环境禁止 loopback 通道，随后使用本地运行权限重试。

## 自动证据

- 两个模组都进入运行时模组列表。
- TFC 数据重载完成：记录 201 个 climate range、444 个 food 数据。
- 集成服务器成功启动，世界完成加载；总加载时间约 33.93 秒。
- JEI 注册完成：239 条 in-world 配方、16 条案板配方、4 条干燥架配方。
- JEI 可见性自检：`visible cutting=16`、`in_world=239`，wheat slice source matches 为 1。
- 验证错误输出为空；结束后 `options.txt` 与备份哈希一致。

## 交互限制

当前 CUA 环境仍不能绑定 Windows 原生 Minecraft 窗口，因此没有自动完成鼠标操作、可可树视觉检查、案板切豆、干燥等待和石臼敲击。上述项目保留给用户手动验收；封窑不在本轮范围内。

## 证据

- `moddev/backups/phase10-runtime-phase11-cocoa-20261008/validation-client-20261008.log`
- A/B jar 哈希与第 11 步内容见 `moddev/docs/141-phase11-cocoa-processing-20261008.md`。
