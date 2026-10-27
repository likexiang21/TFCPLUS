# A tool scripts

活动入口脚本按职责分组；原始 `tools/*.ps1` 文件名保留为**兼容包装**（wrapper），wrapper 会设置 `TFC_TOOLS_ROOT` 并调用这里的实际脚本。

| 目录 | 内容 |
|---|---|
| `generate/` | `gen-*`、`generate-*` 资源/数据/模型/贴图/手册生成器 |
| `audit/` | `audit-*` 只读审计脚本 |
| `verify/` | `verify*.ps1`、`healthcheck.ps1` 验证入口 |

仍在 `tools/` 根目录的共享项：

- `cocoa-data-policy.ps1`、`shared-dead-model-policy.ps1`：dot-source 策略函数；
- `crop-*-contracts.ps1`：作物审计共用的规则函数；
- `localize-*`、`preview-*`、`polish-*`、`sync-*`：本地化/预览/收尾工具；
- `contracts/`、`data/`、`java/`、`archive/`。

兼容 wrapper 不是实际实现；修改逻辑请改 `scripts/<category>/` 下的脚本。全部迁移完成后可删除根 wrapper。
