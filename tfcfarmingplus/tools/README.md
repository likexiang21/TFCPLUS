# A tfcfarmingplus tools

> 这是新版 A 模块的活动工具目录。入口脚本已分组到 [scripts/](scripts/README.md)，根目录保留同名兼容 wrapper；旧树 `../../moddev/tfcfarmingplus/tools` 保持原样。

## 目录

- [scripts/generate](scripts/README.md)：`gen-*` / `generate-*` 生成器；
- [scripts/audit](scripts/README.md)：`audit-*` 只读审计；
- [scripts/verify](scripts/README.md)：`verify*.ps1` / `healthcheck.ps1`；
- 根目录：同名兼容 wrapper、共享策略/规则 helper、localize/preview/polish 等工具；
- [contracts/](contracts/)：13 个保护合同/策略/清单；
- [data/](data/)：18 个审计输入/贴图任务；
- [java/](java/README.md)：Java 辅助工具；
- [archive/](archive/README.md)：旧生成器归档。

## 构建前后

| 入口 | 用途 |
|---|---|
| `verify.ps1` | A 资源交叉引用、资源数量与尺寸校验 |
| `healthcheck.ps1` | 综合静态体检入口 |
| `gen-crops.ps1` | 作物模型/方块状态/掉落/种子/食品等资源生成器（只在隔离输出根目录运行） |
| `preview-model.ps1` | 离线模型预览 |
| `audit-*.ps1` | 各物种/形态的只读源资源审计 |

## 保护合同

`contracts/` 下存放 `*-contract.json` / `*-policy.json` / `*-manifest.json` 和评审路由合同；`data/` 下存放 `*-display-files.json`、`texture-jobs*.json`、`fruit-texture-jobs*.json` 等审计输入。

生成器保护、源码/资源哈希、物种清单和评审合同在源码重构后已经重新基线；新增/修改生成器时仍要跑对应 `audit-*` 与合同检查。

## 待整理

- 已完成 `gen-batch2` / `gen-batch2x-wild` / `fix-batch1-food-models` / `fix-wild-single-placed` / `finalize` / `polish-book` / `TexAvg` 的语义化重命名；
- 已完成 `java/`、`archive/`、`contracts/`、`data/`、`scripts/{generate,audit,verify}` 分组；
- 根目录同名 `.ps1` 是兼容 wrapper，实际实现已移入 `scripts/`；后续可删除 wrapper；
- 保护合同已按 `contracts/` 与 `data/` 分类，后续补统一索引。
