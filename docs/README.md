# mod_rebuild 文档索引

> 新版开发树文档入口。旧树完整历史已归档到 `docs/archive/`，证据目录索引见 `INVENTORY.md`。

## 当前入口

| 文档 | 内容 |
|---|---|
| [274-rebuild-log-20261027.md](274-rebuild-log-20261027.md) | 本次从旧树复制到 `mod_rebuild` 的重构记录、已完成项、检查结果和剩余批次 |
| [275-resource-path-taxonomy-20261027.md](275-resource-path-taxonomy-20261027.md) | A/B `models/block`、`textures/block` 分层结果与 blockstate ID 约束 |
| [273-naming-and-file-structure-requirements-20261027.md](273-naming-and-file-structure-requirements-20261027.md) | 严格命名与文件结构要求、全量改名映射、门禁规则 |
| [272-github-snapshot-and-development-pause-20261027.md](272-github-snapshot-and-development-pause-20261027.md) | 重构前的暂停/上传记录 |
| [271-ar4ag-rhubarb-native16-display-20261027.md](271-ar4ag-rhubarb-native16-display-20261027.md) | 重构前最后一片功能交接 |
| [233-final-code-readability-and-structure-plan-20261024.md](233-final-code-readability-and-structure-plan-20261024.md) | 全部既定工作完成后的工程可读性整理计划 |
| [190-kitchenware-k0-ledger-20261018.md](190-kitchenware-k0-ledger-20261018.md) | B 厨具台账脚本引用的历史台账 |
| [219-ar1a-strawberry-guide-20261023.md](219-ar1a-strawberry-guide-20261023.md) | 草莓手册修复策略引用的历史记录 |
| [220-ar1b-cocoa-canonical-20261023.md](220-ar1b-cocoa-canonical-20261023.md) | 可可规范化策略引用的历史记录 |

## 历史文档库

| 索引 | 内容 |
|---|---|
| [ARCHIVE-INDEX.md](ARCHIVE-INDEX.md) | `moddev/docs` 完整归档副本的分类索引（226 个文件） |
| [INVENTORY.md](INVENTORY.md) | 旧 `moddev/inventory` 53 个证据目录的文件数/大小索引；证据本体仍在旧树 |

归档目录 [archive/](archive/) 是 `moddev/docs` 的字节级副本，用于保留历史上下文。归档文档中的旧类名、旧路径和相对链接未逐篇重写；**当前规范以根目录 273/274 和本索引为准**。

## 新树状态

- 状态：**Java/包/文件结构重构完成静态检查，A/B 均已构建成功；未实机、未视觉验收**。
- 当前根包：A `io.github.likexiang21.tfcplus.farming`，B `io.github.likexiang21.tfcplus.agriculture`。
- A/B jar 在 `../artifacts/`。
- 资源目录当前为原样复制，资源 ID 未改；资源路径分层仍待单独批次。
- 旧树 `../../moddev/` 保持原样，用于回滚和差异对照。

## 后续文档要求

- 新交接/修复文档使用 `NNN-stage-topic-YYYYMMDD.md`，编号从 275 之后继续；
- 每份文档顶部写清编号、阶段、状态（static/visual/runtime）和证据路径；
- 新文档进入本目录后再更新本索引；
- 历史文档只追加到 `archive/` 并更新 `ARCHIVE-INDEX.md`，不再混入当前入口。
