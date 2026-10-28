# 278 工作区无用内容归类与清理清单

> 日期：2026-10-28
> 状态：**已完成第一批高置信度清理**；本文件保留为分类记录和后续批次依据。
> 依据：`mod_rebuild/docs/277-...`、D2 资源审查、D3 工具审计、工作区目录实测。
> 重要前提：**所有现有贴图都要全面重绘；此前声称“已完成/已验收”的贴图一律视为不合格。** 因此本清单不把“当前已引用”当作“最终资产”。

---

## 1. 总览（以下为清理前基线）

> 清理前工作区约 **1.5 GB** 文件；2026-10-28 第一批已释放约 **1,001 MB**，执行结果见 §9。

真正与 mod 源码/分支直接相关的只有：

- `mod_rebuild/`：41.4 MB / 9,675 文件（清理前）；
  - 其中 docs 20.88 MB（含 audit 14.49 MB、archive 6.21 MB）、artifacts 3.65 MB、A 11.51 MB、B 5.19 MB；
- `moddev/`：45.5 MB / 10,185 文件（旧树，回滚/对照用）；
- `_refactor`/`tools` 很小。

最大的可清理项不在分支，而在工作区的开发过程目录：

| 目录 | 文件数 | 大小 | 性质 |
|---|---:|---:|---|
| `.probe/` | 70,796 | 695.8 MB | 贴图设计/渲染/审查工作区；`texture-design/px` 单项 654.7 MB |
| `de_moddev/` | 40,192 | 358.6 MB | 旧反编译/构建/演示/备份；含 `src-ref` 21.5 MB、`jar-extract` 16.1 MB |
| `simplebackups/` | 5 个目录 | 331.5 MB | **游戏世界存档**，不是项目备份，不能当“废弃备份”直接删 |
| `moddev/` | 10,185 | 45.5 MB | 旧开发树；含 inventory 32.5 MB、docs 6.2 MB |
| `mod_rebuild/` | 9,675 | 41.4 MB | 当前开发树（分支内容） |
| `deliverables/` | 2 | 3.6 MB | 旧交付 JAR |

**结论：如果目标是“工作区简洁 + 文件整体尺寸”，最大收益在 `.probe/texture-design/px` 和 `de_moddev`，不是当前分支资源；分支内部应以“工具/死资源/重复归档”为主。**

---

## 2. 贴图分析/预览类（最大优先清理）

### 2.1 `.probe/texture-design/px`（P0 清理候选，但需先留参考）

| 项 | 值 |
|---|---:|
| 路径 | `.probe/texture-design/px` |
| 文件数 | 26,924 |
| 大小 | **654.72 MB** |
| 内容 | 历轮贴图审查的 2D/3D 预览、接触表、对比图、AI/放大稿 |
| 是否源码 | **否**；不是游戏资源，不是分支交付物 |
| 建议 | 保留 1~3 张最终参考接触表 → **其余按批次删除** |
| 风险 | 低；删后不能复现历史视觉评审，但源码 PNG 仍在 |

> 与 `AGENTS.md` 的“不要删除 lab-assets/lab-old/lab-new”不冲突：`px` 是**预览输出**，不是 lab 源图；但删除前应确认没有唯一证据图。

### 2.2 `.probe/texture-design/out`（P1）

- 322 文件 / 6.31 MB；历史渲染输出、接触表。
- 建议：保留当前有效参考；其余删除/归档。
- 风险：低。

### 2.3 `.probe/texture-design/backup-*`、`bak-*`（P1）

- 多个历史批次备份（`backup-GENREDRAW-*`、`backup-pk-designs-*`、`bak-src-20260927`、`bak-lab-20260927` 等）。
- 其中 `bak-src-20260927`/`bak-lab-20260927` 是**旧图恢复依据**，AGENTS 明确要求保留；不能当普通备份删。
- 其余 `backup-*` 批次目录可按“最后成功版本”保留一份，其余删除。
- 建议：先做 SHA/时间清单，保留 `bak-src-20260927` + `bak-lab-20260927` + 最终版本；其余清理。

### 2.4 `.probe/ref-tfc`、`tfc-crop`、`lab-assets`、`lab-old`、`lab-new`（保留）

| 路径 | 大小 | 理由 |
|---|---:|---|
| `.probe/ref-tfc` | 7.79 MB | TFC 原版参考，重绘/风格判断需要 |
| `.probe/tfc-crop` | 0.62 MB | TFC 作物参考 |
| `.probe/lab-assets` | 0.54 MB | 旧版/活版对照源；AGENTS 明确保护 |
| `.probe/lab-old` / `lab-new` | 0.69/0.74 MB | 3D 新旧对照；保留 |

### 2.5 其它 `.probe` 目录（P2）

- `skill-review/` 7.54 MB：审查/技能产物，非源码；可归档删除。
- `gen-crops-ab/` 2.44 MB：旧生成输出；可删除。
- `_w2assets-old/` 0.71 MB、`removed-dead-2026/` 0.15 MB：历史旧资源；可归档。
- `ingame-verify-20260923/` 2.35 MB：历史实机日志/截图，非必要；可归档。

---

## 3. 旧树/反编译/备份类

### 3.1 `de_moddev/`（P0 工作区体积候选，但先做许可证取证）

| 子目录 | 大小 | 性质 | 建议 |
|---|---:|---|---|
| `tfcfarmingplus/` | 136.84 MB | 旧构建/资源/备份 | 旧树保留到分支稳定；之后归档/删 |
| `demo-mymod/` | 78.64 MB | 示例/演示工程 | 不参与本项目；可删 |
| `tfcagricultureplus/` | 75.14 MB | 旧构建/资源 | 同上 |
| `src-ref/` | 21.51 MB | TFC/Firmalife 反编译源 | **许可证取证需要，保留到代码合规结论落盘** |
| `jar-extract/` | 16.07 MB | 依赖 JAR 解包 | 许可证/资源比对用；之后可删 |
| `docs/` | 8.43 MB | 旧文档 | 与 `mod_rebuild/docs/archive` 重复；保留一份 |
| `backups/` | 7.74 MB | 旧备份 | 清理 |
| `inventory/` | 6.25 MB | 旧证据 | 清理/归档 |
| `_archive/` | 1.24 MB | 历史归档 | 归档 |

**建议：`src-ref` 与 `jar-extract` 在许可证审查/来源登记完成前不要删；`demo-mymod`、旧备份、重复 inventory 可先清。**

### 3.2 `moddev/`（保留）

- 旧开发树，用于回滚/差异对照；
- `inventory/` 32.53 MB 是历史证据（其中很多是大型 PNG/截图）；
- `docs/` 6.21 MB 与 `mod_rebuild/docs/archive` 重复；
- 建议：分支稳定并确认无需回滚后，旧树整体归档/移出工作区，不在当前删除。

### 3.3 `simplebackups/`（不删）

- 331.5 MB / 5 个 **游戏世界存档**（test/tfctest/新的世界）；
- 不是本项目备份，不能用“废弃备份”理由删除；需要用户确认。

### 3.4 `deliverables/`（保留）

- 3.64 MB 旧交付 JAR；保留回滚点，不删。

### 3.5 `mod_rebuild/docs/audit`（报告完成后可清）

| 项 | 文件数 | 大小 |
|---|---:|---:|
| `d2-index.json` | 1 | 9.2 MB |
| D2/D3 CSV/日志 | 60+ | 约 5 MB |
| D1/D2/D3 报告/脚本 | 少量 | 约 0.3 MB |

- 建议：保留 `D1/D2/D3/*.md` 和 276/277 报告；
- `d2-index.json`、明细 CSV、脚本、日志在报告定稿后删除/移出工作区；
- 可减约 **14 MB**。

---

## 4. 分支工具脚本清理分类

> 当前 A tools 169 文件/1.25 MB，B tools 38 文件/0.11 MB；`.ps1` 共 161 个，其中 wrapper 66 个、实际脚本 95 个。
> 清理原则：**先迁移外部调用，再删 wrapper；先确认重绘替换，再删生成器。**

### 4.1 可删除/归档（高置信度）

| 路径/类别 | 数量/大小 | 原因 | 备注 |
|---|---:|---|---|
| A `tools/_tags-baseline/` | 14 文件 | 全树零引用 | 基线已过时；保留一份归档即可 |
| A `tools/data/texture-jobs-*` 中无引用项 | 约 7 文件 | 零脚本引用 | 需逐文件确认；有引用的 `texture-jobs.json`/items/trees 保留 |
| A `tools/java/TextureAverage.java`、`TextureStats.java` | 2 文件 | 零脚本引用 | 仅分析工具；可归档 |
| A `tools/archive/` | 1 文件 | 历史脚本 | 归档 |
| A wrapper 49 个 / B wrapper 17 个 | 66 文件 | 兼容层 | 先把外部调用迁到 `scripts/`，再删 |
| `_refactor/` | 21 文件 / 0.12 MB | 重构期一次性脚本 | 重构结束后归档 |
| B `migrate-tfcwoodwork.ps1` | 1 文件 | 一次性迁移脚本 | **保留**用于 MIT 来源追溯；不删 |
| 模板/空目录/临时文件 | 待扫 | `build/`、`.gradle/` 不在分支；本地 build 已清 | 本地 `.gradle`/build 不进分支 |

### 4.2 全面重绘后才会过时（不要现在删）

这些脚本是当前贴图/模型生成链；全面重绘后可能被新管线替代：

- A `gen-crop-textures.ps1`、`gen-double-crop-textures.ps1`、`gen-food-textures.ps1`、`gen-item-textures.ps1`、`gen-leafball-textures.ps1`、`gen-pixelart-textures.ps1`、`gen-plant-textures.ps1`、`gen-rosette-textures.ps1`、`gen-seed-textures.ps1`、`gen-sunflower-disc.ps1`、`gen-melon-skins.ps1`；
- A `gen-crops.ps1`、`gen-leafball-models.ps1`、`gen-rosette-models.ps1`、`generate-vegetable-crop-models.ps1`、`generate-wild-crop-patches.ps1`、`gen-branch-fruits.ps1`、`gen-fruit-trees.ps1`、`gen-high-bushes.ps1`、`gen-dead-and-wild-bushes.ps1`；
- A `localize-*.ps1`、`finalize-resource-set.ps1`、`repair-*.ps1`、`polish-patchouli-book.ps1`、`preview-model.ps1`、`healthcheck.ps1`；
- **原因**：这些脚本的输出与“旧贴图/旧模型”绑定；在新贴图验收前删掉会失去回退/对照能力。

### 4.3 保留（当前维护/验收需要）

- A `audit-*` 现代审计脚本（crop/tree/bush/soil/branch/leafball/display 等）；
- A `verify.ps1`、`verify-book.ps1`；
- A `gen-tags.ps1`、`gen-wild-injection.ps1`、`gen-patchouli-book.ps1`（数据/手册生成仍需）；
- A `cocoa-data-policy.ps1`、`sync-cocoa-data.ps1`、`sync-strawberry-guide.ps1`、`shared-dead-model-policy.ps1`；
- A `contracts/` 13 个、`data/` 18 个（审计合同）；
- B `scripts/verify/*`、`check-boundaries.ps1`、`build-local.ps1`；
- B `verify-*.ps1` 全部（验收需要）。

### 4.4 含绝对路径、必须重写/删除的脚本（P1）

来自 D3 `D3-stale-paths.csv`：

- `A\tools\archive\20260923-generate-trunk-fruit-models.ps1`（旧 JDK 绝对路径）；
- `A\tools\finalize-resource-set.ps1`；
- `A\tools\gen-high-bushes.ps1`；
- `A\tools\localize-all-models.ps1`；
- `A\tools\localize-fruit-tree-models.ps1`；
- `A\tools\localize-textures.ps1`；
- `A\tools\repair-food-item-models.ps1`；
- `A\tools\repair-wild-crop-placement.ps1`；
- `A\tools\scripts\generate\generate-wild-crop-patches.ps1`；
- shared `tools\readjar.ps1`、`tools\stop-own-client.ps1`、`tools\verify-k1-runtime.ps1`。

建议：**先改成相对路径/参数，再决定保留或归档**；当前直接运行会指向不存在的旧 JDK/旧工作区。

---

## 5. 分支死资源/贴图分类

> 用户已明确：**所有贴图全面重绘，此前声称完成的内容不合格。**
> 所以“当前已引用”不等于“最终合格”；下面按“是否当前被引用”分类，而不是按“是否美观”分类。

### 5.1 A 贴图总账

| 类别 | 数量 | 大小/占比 | 处置建议 |
|---|---:|---|---|
| A 全部 PNG | 1,817 | — | 全部进入重绘计划 |
| 被模型引用（block） | 522 | — | 替换前保留 |
| 被模型引用（item） | 165 | — | 替换前保留 |
| 未被引用（block） | **965** | — | 重绘后清理/归档 |
| 未被引用（item） | **165** | — | 重绘后清理/归档 |
| 死贴图合计 | **1,130** | 约 241 KB | 重绘后清理 |
| 其中旧 JAR 曾用、当前未引用 | **949** | — | **暂留作参考**，不是最终资产；重绘后可删 |
| 其余历史遗留 | 181 | — | 低风险清理候选 |
| 低色数/透明占位 | 6 低色数 + 2 全透明 | — | 明确占位；重绘 |
| 重复贴图 | 26 组 | — | 重绘时统一 |

### 5.2 分类说明

- **A1 旧 JAR 自有贴图（949）**：当前模型已改为 TFC 借用；这些贴图不是运行时依赖，但可作为重绘参考。**不能当作“正式资产”验收，也不能按“已引用”保护。**
- **A2 melon 12 张**：模型丢失 `textures` 覆盖；重绘/修复模型后可用；当前是死文件。
- **A3 5 张 plant 历史图**：与旧 branch-fruit 方案有关；归档。
- **A4 其余 food/seeds/fiber 历史图**：无模型/无配方/无 Java 引用；重绘计划下可清理。
- **B 贴图**：B 没有自有 `textures/block`；57 张 item 贴图都被引用，但同样属于待重绘/未验收，不能标记合格。

### 5.3 死模型 / lang

- A 3 个死模型：`block/plant/branch_fruit.json`、`block/plant/cocoa_branch_fruit_ripe.json`、`block/plant/cocoa_branch_fruit_unripe.json`；
- A 5 个 `dead_crop.*` 孤儿 lang key；
- A 106 个技术方块缺 block lang（branch/cane 等，优先级低）；
- B 2 个空 lang、4 个缺 lang；
- 这些都不影响当前构建，但属于清理/收尾项。

---

## 6. 文档归档与重复

| 项 | 大小 | 处理 |
|---|---:|---|
| `mod_rebuild/docs/archive` | 6.21 MB / 244 旧文档 + README | 历史归档；若工作区要极简，可移出分支/保留外链 |
| `moddev/docs` | 6.21 MB / 244 | 与上面重复；旧树保留一份即可 |
| `moddev/inventory` | 32.53 MB / 722 文件 | 历史证据（PNG 多）；归档/压缩后移出 |
| `mod_rebuild/docs/audit` | 14.49 MB | 报告定稿后删明细，保留报告 |
| `de_moddev/docs` | 8.43 MB | 旧文档重复；归档 |

**注意**：`archive` 不是“垃圾”；它是历史证据。若用户要删，建议整体移到外部归档，不要逐文件删。

---

## 7. 建议清理批次（后续执行）

### 批次 1：低风险、无源码价值（可先做）

1. `.probe/texture-design/px` 中除最终参考外的 **26,924 张预览图**（最大 654.7 MB）；
2. `.probe/texture-design/out`、`skill-review`、`gen-crops-ab`、旧 `backup-*`（保留 AGENTS 保护的 `bak-src-20260927`/`bak-lab-20260927`）；
3. `de_moddev/demo-mymod`、`de_moddev/backups`、`de_moddev/inventory`、`de_moddev/_archive`；
4. `mod_rebuild/docs/audit` 的明细 CSV/JSON/脚本（保留 D1-D3/276/277 报告）；
5. A `_tags-baseline`、无引用 `texture-jobs-*`、`TextureAverage/Stats`、`tools/archive`。

### 批次 2：需先确认

6. `.probe` 的 `ref-tfc`/`lab-*` 保留；确认不再重绘后再清；
7. `de_moddev/src-ref`/`jar-extract` 在许可证来源登记完成后再清；
8. `moddev/` 旧树在分支稳定后整体归档；
9. `mod_rebuild/docs/archive` 是否随分支保留由用户决定；
10. `simplebackups` 是游戏存档，必须用户确认，不能当项目备份删。

### 批次 3：重绘完成后

11. A/B 旧贴图按“已被新图替换 + 新图验收通过 + 无回退需要”删除；
12. 旧生成器/本地化脚本按新管线替换后归档；
13. wrapper 在外部调用迁移后删除；
14. 死模型、孤儿 lang、重复文件清理。

---

## 8. 安全边界

- **本轮已按“批次 1”执行高置信度清理**；详细清单见 §9 与 `docs/audit/cleanup-execution-20261028*.csv`。
- 删除前已核对解析后的绝对路径；本轮未删除受保护目录。
- `AGENTS.md` 明确保护的 `.probe/lab-assets`、`lab-old`、`lab-new`、`bak-src-20260927`、`bak-lab-20260927` 均保留。
- `simplebackups`、`saves`、`screenshots` 是游戏数据/用户数据，没有删除。
- 全量贴图重绘完成前，没有删除当前仍被模型引用的贴图；旧贴图/旧生成器留到重绘验收后处理。
- `moddev/` 旧树、`de_moddev/src-ref`、`de_moddev/jar-extract` 仍保留，供回滚/许可证审计。

---

## 9. 本次执行结果（2026-10-28）

### 9.1 总量

| 批次 | 文件数 | 释放空间 |
|---|---:|---:|
| 第一批：贴图预览/旧构建/旧备份/审计明细/死工具 | 50,448 | **992.18 MB** |
| 第二批：根 `px/`、`.probe/backup-*` 旧备份 | 7,567 | **8.82 MB** |
| **合计** | **58,015** | **1,001.01 MB** |

### 9.2 目录变化

| 目录 | 清理前 | 清理后 |
|---|---:|---:|
| `.probe/` | 695.8 MB | **18.91 MB** |
| `de_moddev/` | 358.6 MB | **49.63 MB** |
| `mod_rebuild/` | 41.4 MB | **27.07 MB** |
| 工作区 `px/` | 6.77 MB | **已删除** |

### 9.3 已删除（摘要）

- `.probe/texture-design/px/`：26,924 个贴图预览/分析图，654.7 MB；
- `.probe/texture-design/out/`、`skill-review/`、`gen-crops-ab/`、`ingame-verify-20260923/`、`_w2assets-old/`、`removed-dead-2026/`；
- `.probe/texture-design/backup-*` 与 `.probe/backup-*` 旧批次备份（保留 `bak-src-20260927`、`bak-lab-20260927`）；
- `de_moddev/` 的旧 `build`/`.gradle`、`demo-mymod`、`backups`、`inventory`、`_archive`；
- `mod_rebuild/docs/audit/` 的原始 CSV/JSON/日志/脚本（保留 D1–D3、README、cleanup 清单、代码相似度证据）；
- A 工具：`_tags-baseline`、`tools/archive`、无引用 `texture-jobs-*`、`TextureAverage.java`、`TextureStats.java`；
- 根 `px/` 旧 2D/3D 预览。

### 9.4 保留

- `.probe/texture-design/reference-redraw/`：4 张最终参考图（重绘/对照用）；
- `.probe/ref-tfc`、`tfc-crop`、`lab-assets`、`lab-old`、`lab-new`、`bak-src-20260927`、`bak-lab-20260927`；
- `de_moddev/src-ref`、`de_moddev/jar-extract`（许可证/来源审计）；
- `moddev/` 旧树（回滚/对照）；
- `simplebackups/`、`saves/`、`screenshots/`（游戏数据，不删）；
- `mod_rebuild/artifacts`（当前 JAR）；
- 所有源码、当前资源、contracts、verify/audit 脚本。

> 后续批次（dead textures/旧生成器/wrapper/`moddev/inventory` 等）暂不执行，等待重绘/分支稳定后再处理。
