# Shared tools

> 新版共享工具，位于 `mod_rebuild/tools/`；与 `mod_rebuild/tfcfarmingplus`、`mod_rebuild/tfcagricultureplus` 同级。

| 入口 | 用途 |
|---|---|
| `launch-client.ps1` | 启动自建客户端/验证实例 |
| `stop-own-client.ps1` | 只停止自建实例并还原选项 |
| `launch-validation-client.ps1` / `stop-validation-client.ps1` | 验证实例启动/停止 |
| `ingame-verify.ps1` | 实机窗口/日志验证辅助 |
| `readjar.ps1` | 在 jar 中读取/列/搜索文件 |
| `ascii-texture.ps1` | 贴图 ASCII 输出辅助 |
| `prepare-refs.ps1` | 参考清单生成（`inventory`/`src-ref` 未复制，按需运行） |
| `verify-k1-runtime.ps1` | K1 运行时验证辅助 |

`rename-mod-id.ps1` 是旧项目改名工具，已归档到 `../_refactor/legacy/rename-mod-id.ps1`，不属于新版活动工具链。
