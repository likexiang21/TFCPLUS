# mod_rebuild — 新版模组开发树

> 记录日期：2026-10-27
> 状态：**重构进行中，A/B 均已构建成功，旧文档库已完整归档**。本目录是与 `moddev/` 并行的新版开发树；`moddev/` 旧树保持原样，未移动、未删除。
> 目标：把命名称呼、Java 包结构、构建配置和新工具引用整理成可直接继续开发的新版本。

## 0. 许可证与第三方来源

- 项目代码/原创资源：**EUPL-1.2**（根目录 `LICENSE`，全文 `LICENSES/EUPL-1.2.txt`）；
- A/B 的 `neoforge.mods.toml` 与 JAR 内 `META-INF/licenses/` 均已同步为 EUPL-1.2；
- 第三方来源、许可证与修改说明：`THIRD_PARTY_NOTICES.md`；
- 第三方资源登记：`docs/THIRD-PARTY-ASSETS.md`；
- 代码来源/相似度审查：`docs/CODE-PROVENANCE.md`；
- 许可证门禁：`tools/check-license-compliance.ps1`（校验 LICENSE、模板、JAR 内许可与第三方通知一致）。

## 1. 当前包含什么

```text
mod_rebuild/
├── README.md                 # 本文件
├── LICENSE                   # EUPL-1.2
├── LICENSES/                 # EUPL-1.2 与第三方 MIT 文本
├── THIRD_PARTY_NOTICES.md    # 第三方来源/许可登记
├── DEVELOPMENT_RULES.md      # 从旧工作区复制
├── docs/                     # 当前入口 + archive/ 完整旧文档 + 索引
├── tools/                    # 共享启动/验证/参考工具
├── artifacts/                # 已构建的 A/B 模组 jar
├── _refactor/                # 重构脚本、旧→新映射、检查脚本
├── tfcfarmingplus/           # A：农业作物/果树/资源
│   ├── build.gradle.kts
│   ├── gradle.properties
│   ├── settings.gradle
│   ├── src/main/java/        # 已重构为新包名与新目录
│   ├── src/main/resources/   # models/textures 已按 275 分层；blockstate/资源 ID 未动
│   └── tools/                # 原工具复制并更新旧路径/类名
└── tfcagricultureplus/       # B：木工/养蚕/厨具/加工
    ├── build.gradle.kts
    ├── gradle.properties
    ├── settings.gradle
    ├── src/main/java/        # 已重构为新包名与新目录
    ├── src/main/resources/   # models/textures 已按 275 分层；blockstate/资源 ID 未动
    ├── tools/                # 原工具复制并更新旧路径/类名
    └── OVERRIDE-REGISTRY.md  # 跨命名空间台账，类名引用已更新
```

## 2. 新包名（临时决策）

`com.example.*` 和 B 的 `com.example.tfcfarmingplus.expansion.*` 已移除。当前使用：

```text
A: io.github.likexiang21.tfcplus.farming
B: io.github.likexiang21.tfcplus.agriculture
```

该根包是**临时选择**（按 GitHub 用户名反推），可在后续统一替换为项目正式域名；替换时只需要改包声明、import、`build.gradle.kts` 的 `group` 和 mixin 配置，mod id 不变。

**没有改变的内容**：

- mod id：`tfcfarmingplus` / `tfcagricultureplus`
- 方块/物品/配方/数据包 ID
- 资源命名空间
- NBT/序列化字段
- 旧存档兼容

## 3. Java 结构调整摘要

A：

```text
io.github.likexiang21.tfcplus.farming
├── TFCFarmingPlus.java
├── client/
└── common/
    ├── api/
    ├── block/
    ├── blockentity/
    ├── crop/
    ├── debug/
    ├── item/
    ├── registry/
    ├── support/
    └── tree/
```

B：

```text
io.github.likexiang21.tfcplus.agriculture
├── TFCAgriculturePlus.java
├── client/{renderer,screen}/
├── common/
│   ├── block/
│   ├── blockentity/
│   ├── debug/
│   ├── interaction/
│   ├── item/
│   ├── kitchen/
│   ├── menu/
│   ├── recipe/
│   ├── recipe/inworld/
│   ├── registry/
│   ├── silkworm/
│   └── timber/
├── compat/jei/
└── mixin/
```

已完成：

- 43 个 `My*` 类/文件全部改名（A 32 / B 11）；
- `KnifeBlockBlock`/`KnifeBlockBlockEntity` → `KnifeRackBlock`/`KnifeRackBlockEntity`；
- `SawdustSoupBowl` → `SawdustSoupBowlItem`；
- B 的 `MyBlocks` 内嵌 `KnifeBlockBlock` 已同步改名；
- 泛化类型 `Tree`/`Kind`/`Input`/`Action`/`Motion`/`SoundInstance` 已改为 `FruitTreeDefinition`/`StorageKind`/`CuttingBoardInput`/`MeltingInput`/`PanInput`/`InWorldInput`/`InWorldAction`/`InWorldMotion`/`SoundSpec`；
- 包声明、import、B mixin 配置、`build.gradle.kts` 的 `group` 已同步；
- A/B tools 中指向旧 Java 路径/旧类名的引用已批量更新；
- 工具合同 JSON 中的源码路径和源码哈希已按新文件重新基线。

## 4. 静态检查结果

在 `mod_rebuild` 上执行的静态检查：

```text
python _refactor/check_java.py
=> errors = 0, warnings = 0
```

检查内容：文件/类型名一致、包声明与目录一致、无旧 `com.example`、无旧 `My*` 标识符、项目 import 目标存在、工具合同源码哈希与当前新源码一致。

**构建结果（2026-10-28）**：A、B 均已构建成功；A/B 各自带 `gradlew`，无需 B 先构建 A：

```text
A: artifacts/TFCFarmingPlus-NeoForge-1.21.1-0.1.0.jar        2,425,696 bytes
   SHA-256 A860974F40B559A7967AC3C1469D78A34DA904D697426068FB6FA3A9AC49BA94
B: artifacts/TFCAgriculturePlus-NeoForge-1.21.1-0.1.0.jar    1,513,040 bytes
   SHA-256 7E0521F2C268BD6E43C690368E2136C44BA3B58C57166D1B6811B3FA99458374
```

```text
cd mod_rebuild\tfcfarmingplus
.\gradlew.bat build --console=plain --offline   # 或 gradle build ...

cd ..\tfcagricultureplus
.\gradlew.bat build --console=plain --offline
```

依赖目录由 `TFC_MODS_DIR` 指定；未设置时自动尝试 `../../mods`、`../mods`、`mods/`。B 不再依赖 A 的 `build/libs`（B 对 A 没有 Java import）；A 仍是 B 的运行时必需依赖（`mods.toml` 声明）。未启动游戏、未做视觉/实机验收；B 的 `verify-container-contract`、`verify-grain-food-processing`、`verify-in-world-codec`、`check-boundaries`、`verify-kitchenware-ledger`、`verify-drying-batch`、`verify-silkworm-chain`、`verify-silkworm-lifecycle` 已通过；A 的 `audit-crop-contracts`、`audit-rosette-dead-consumers` 已通过。A 的 `verify.ps1` 需要 PowerShell 7 和 workspace tooling 的 Minecraft client asset jar，当前 Windows PowerShell 5.1 + 缺 asset jar 会在审计阶段报错。

## 5. 尚未完成的批次

1. **变量级命名清理**：已完成多批高置信度改名，`DebugValidation` 已清理；剩余少量脚本局部短变量，按 [273 号需求](docs/273-naming-and-file-structure-requirements-20261027.md) §4 继续；
2. **资源路径分层**：A 顶层 `models/block` 已归入 `melon/`、`plant/`，顶层 `textures/block` 已归入 `melon/`；B 顶层 18 个方块模型已归入各自族目录。**blockstate 文件路径与注册 ID 绑定**，仍保持原路径；资源引用检查 0 缺失；详见 [275 号](docs/275-resource-path-taxonomy-20261027.md)；
3. **工具文件名/目录分组**：已完成 `gen-batch2` / `gen-batch2x-wild` / `fix-batch1` / `fix-wild-single-placed` / `finalize` / `polish-book` / `TexAvg` 的语义化重命名，以及 `java/`、`archive/`、`contracts/`、`data/`、`scripts/{generate,audit,verify}` 分组；根目录保留同名兼容 wrapper；
4. **共享 `tools` 的参考生成脚本**：仍按新根目录路径更新，但 `inventory`/`src-ref` 未复制，属于可选的参考材料；
5. **文档/证据目录迁移**：`mod_rebuild/docs` 已包含当前入口、`archive/` 完整旧文档（244 份 + README）和 `INVENTORY.md` 旧证据索引；证据本体仍在 `moddev/inventory`；
6. **实机/视觉验收**：A/B 已构建成功，但未启动游戏、未做视觉/实机验收，不能把本树当成已验收版本；A 的 `verify.ps1` 需要 PowerShell 7。

## 6. 与旧树的关系

- `moddev/` 是重构前的旧树，保持原样，作为回滚和差异对照；
- `mod_rebuild/` 是新树，修改只发生在这里；
- 两边资源目录当前内容相同；Java/工具路径不同；
- 后续要比较时，用 `_refactor/java-mapping.csv` 对照旧→新类/路径。

## 7. 入口文档

- [273 号：命名与文件结构整理需求](docs/273-naming-and-file-structure-requirements-20261027.md)
- [274 号：本次重构记录](docs/274-rebuild-log-20261027.md)
- [275 号：资源路径分层](docs/275-resource-path-taxonomy-20261027.md)
- [276 号：全量内容审查报告](docs/276-full-content-audit-20261028.md)
- [277 号：计划实现与开源协议审查](docs/277-plan-implementation-and-license-compliance-20261028.md)
- [278 号：工作区清理清单](docs/278-cleanup-inventory-20261028.md)
- [279 号：协议/代码修复记录](docs/279-protocol-code-fixes-20261028.md)
- [280 号：B 实现与技术文档差距分析](docs/280-b-implementation-gap-vs-tech-docs-20261028.md)
- [281 号：清理 B 遗留干燥物品](docs/281-remove-legacy-dried-items-20261028.md)
- [282 号：清理 B 旧厨房/旧可可内容](docs/282-cleanup-legacy-kitchen-content-20261028.md)
- [283 号：炒锅内容扩展与“完成”表述更正](docs/283-pan-content-expansion-20261028.md)
- [第三方资源登记](docs/THIRD-PARTY-ASSETS.md)
- [代码来源审查](docs/CODE-PROVENANCE.md)
- [贴图全面重绘计划](docs/TEXTURE-REDRAW-PLAN.md)
- [旧文档归档索引](docs/ARCHIVE-INDEX.md)
- [旧证据 inventory 索引](docs/INVENTORY.md)
- [233 号：工程可读性计划](docs/233-final-code-readability-and-structure-plan-20261024.md)
- [A 的 build 配置](tfcfarmingplus/build.gradle.kts)
- [B 的 build 配置](tfcagricultureplus/build.gradle.kts)
- [重构脚本目录](_refactor/)
