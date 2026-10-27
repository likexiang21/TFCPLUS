# 第 7 步：受控实机回归记录（2026-10-07）

## 测试范围

- 使用 `moddev/tools/launch-validation-client.ps1` 启动工作区自带 NeoForge 1.21.1 客户端。
- 使用隔离存档 `codex-validation-20261007`，不修改原始 `tfctest` 存档。
- 本轮检查：客户端启动、集成服务器进入世界、模组注册、JEI 配方注册与启动日志。
- 封窑功能按用户要求跳过；案板、石臼、干燥架的鼠标交互保留给用户手动验证。

## 已确认

1. 模组列表包含 `TFC Agriculture Plus 0.1.0` 与 `TFC Farming Plus 0.1.0`。
2. 集成服务器成功启动，测试世界完成加载；日志记录总加载时间约 37.28 秒。
3. TFC Agriculture Plus 的注册自检完成，日志记录 310 个方块 ID，并完成案板、刀具架、石臼和木材材质数量检查。
4. JEI 注册完成：239 条 in-world 配方、15 条案板配方、3 条干燥架配方。
5. JEI 可见性自检完成：`visible cutting=15`、`in_world=239`，wheat slice source matches 为 1。
6. 客户端在隐藏验证模式下未因本项目模组崩溃；退出前能正常保存并暂停世界。
7. 验证脚本结束后，`options.txt` 与启动前备份的 SHA-256 完全一致，测试启动参数已恢复。

## 未完成与限制

- 当前 CUA 环境没有返回 Windows 原生窗口清单，无法绑定 Minecraft 窗口执行鼠标和键盘操作。
- 为尝试恢复可操作窗口，验证脚本新增了可选的 `-Visible` 参数；可见模式在图形初始化阶段退出，因此没有把它作为通过依据。
- 因此本轮不能把案板切割、石臼敲击、干燥架户外/雨天/取出/保存加载等交互标记为自动通过。请使用隔离存档或用户自己的测试存档手动验证这些项目。
- 日志中仍有 Firmalife 的 `crafting/spoon` JEI 警告、Patchouli 缺失配方提示，以及一个野生葱贴图回退提示；它们没有指向本项目新增配方的异常。

## 证据位置

- 成功启动的压缩调试日志：实例 `logs/debug-1.log.gz`。
- 当前验证启动脚本：`moddev/tools/launch-validation-client.ps1`。
- 停止与恢复脚本：`moddev/tools/stop-validation-client.ps1`。
- 本记录对应发布交接：`moddev/docs/136-release-integration-handoff-20261007.md`。

## 结论

启动、世界进入、模组注册和 JEI 注册已通过日志证据确认。交互层回归需要在能操作 Minecraft 窗口的环境中由用户手动完成；封窑测试按要求不在本轮范围内。
