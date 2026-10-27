# Minecraft 自动操作修复尝试（2026-10-08）

## 已尝试

- 重置并重新初始化当前 CUA 会话。
- 重新读取应用状态；结果仍为 `apps: []`，只暴露浏览器面板。
- 检查运行时实际 API；当前对象没有 `listApps`、`getApp`、`listWindows` 或 `computer` 原生控制入口。
- 直接加载 `@oai/sky` 后复核，仍返回 `Trusted RPC service is not configured: sky`。

## 结论

重置会话没有修复问题。当前 Codex 窗口没有挂载 Windows 原生 Computer Use/`sky` 受信任 RPC 服务，无法由项目脚本或 Minecraft 模组自行修复。

## 需要用户手动完成的步骤

请在 Codex 桌面应用中重新启动一个启用了 Windows 原生 Computer Use 的会话（必要时完全退出并重新打开 Codex），然后重新启动验证客户端。恢复后应能看到 Minecraft 窗口，并能取得窗口截图；届时才能继续自动鼠标交互。

在用户完成上述操作前，本项目不再尝试猜测坐标或修改游戏文件来绕过控制桥接问题。
