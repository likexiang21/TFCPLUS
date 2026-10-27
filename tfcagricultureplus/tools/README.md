# B tfcagricultureplus tools

> 这是新版 B 模块的活动工具目录。旧树 `../../moddev/tfcagricultureplus/tools` 保持原样。

## 入口

| 入口 | 用途 |
|---|---|
| `check-boundaries.ps1` | 六条依赖/许可红线门禁 |
| `verify-registry.ps1` | 资源↔注册一致性 |
| `verify-coverage-ledger.ps1` | 覆盖/跨命名空间台账 |
| `verify-container-contract.ps1` | 容器方块/BE 契约 |
| `verify-fruit-processing.ps1` | 水果/整派食品信息 |
| `verify-grain-food-processing.ps1` | 谷物/豆类/油料食品处理 |
| `verify-in-world-codec.ps1` | in-world 配方 codec 形状 |
| `verify-silkworm-chain.ps1` / `verify-silkworm-lifecycle.ps1` | 养蚕链 |
| `verify-drying-batch.ps1` | 干燥架 |
| `verify-kitchenware-ledger.ps1` | 厨具台账 |
| `verify-agricultural-materials.ps1` | 农业材料 |
| `verify-vegetable-beverage-processing.ps1` | 蔬菜/饮品用途 |
| `verify-workbench-recipes.ps1` / `verify-woodwork-flow.ps1` | 木工流程 |
| `build-local.ps1` | 本机构建辅助 |

## 目录

- [scripts/verify](scripts/README.md)：实际验证脚本；
- `tools/*.ps1`：同名兼容 wrapper，负责设置 `TFC_TOOLS_ROOT` 并调用 `scripts/verify/`；
- `build-local.ps1`：本机构建辅助（仍在根目录）；
- `generate-timber-resources.py`：唯一 Python 生成器（仍在根目录）。

## 待整理

- `scripts/verify` 已完成，根目录 wrapper 为兼容层；后续可删除 wrapper；
- B 暂未单独拆分 `data/`、`archive/`（B 没有对应 JSON 数据/旧归档）。
