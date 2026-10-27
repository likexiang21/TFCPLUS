# B tool scripts

活动验证脚本按职责分组；原始 `tools/*.ps1` 文件名保留为**兼容包装**（wrapper），wrapper 会设置 `TFC_TOOLS_ROOT` 并调用这里的实际脚本。

| 目录 | 内容 |
|---|---|
| `verify/` | `verify-*.ps1`、`check-boundaries.ps1` |
| `generate/` | `migrate-tfcwoodwork.ps1` |

仍在 `tools/` 根目录：

- `build-local.ps1`：本机构建辅助；
- `generate-timber-resources.py`：唯一的 Python 生成器。

兼容 wrapper 不是实际实现；修改逻辑请改 `scripts/<category>/` 下的脚本。全部迁移完成后可删除根 wrapper。
