# 旧文档库归档索引

> 本目录是 `moddev/docs` 的完整归档副本（226 个文件，字节级复制），用于保留历史上下文。
> **它不是当前开发规范**；当前规范看 `../README.md`、`../273-...` 和 `../274-...`。
> 归档文档之间的相对链接、旧类名、旧路径可能仍指向 `moddev` 时代内容，未逐篇重写。

## 分类统计

| 分类 | 文件数 |
|---|---:|
| 架构 / API / 脚手架 | 6 |
| Firmalife / Patchouli | 3 |
| 作物 / 植物 | 11 |
| 贴图 / 渲染 | 21 |
| 轮次 / 交接 | 37 |
| 农业实现 | 74 |
| 近期 / 验证 | 45 |
| 未分类 | 29 |
| **合计** | **226** |

## 架构 / API / 脚手架

| 文件 | 标题 |
|---|---|
| [10-tfc-overview.md](archive/10-tfc-overview.md) | TFC 4.2.10 架构总览与注册体系 |
| [11-tfc-registry-catalog.md](archive/11-tfc-registry-catalog.md) | TFC 注册名目录、枚举维度与资源清单速查 |
| [12-tfc-data-driven.md](archive/12-tfc-data-driven.md) | TFC 4.2.10 数据驱动内容格式完整参考手册 |
| [13-tfc-api.md](archive/13-tfc-api.md) | TFC 4.2.10 公开 API、组件体系与事件 |
| [20-addon-scaffold.md](archive/20-addon-scaffold.md) | TFC 附属模组工程脚手架（MC 1.21.1 / NeoForge 21.1.x / TFC 4.2.10） |
| [00-README.md](archive/00-README.md) | TFC 附属模组开发技术文档库（索引） |

## Firmalife / Patchouli

| 文件 | 标题 |
|---|---|
| [30-firmalife-api.md](archive/30-firmalife-api.md) | Firmalife v3.0.14 技术文档（面向 MC 1.21.1 / NeoForge 21.1.x 附属模组开发） |
| [40-patchouli-api.md](archive/40-patchouli-api.md) | Patchouli `release-1.21.1-93` 技术文档（面向 MC 1.21.1 / NeoForge 21.1.x 附属模组开发） |
| [50-tfc-patchouli-integration.md](archive/50-tfc-patchouli-integration.md) | TFC 的 Patchouli 集成与「配方展示页」复刻指南 |

## 作物 / 植物

| 文件 | 标题 |
|---|---|
| [60-plants-crops-addon-guide.md](archive/60-plants-crops-addon-guide.md) | 在 TFC 中添加新作物 / 果树 / 灌木 / 棕榈式树 —— 可行性分析与实施方案 |
| [70-crop-implementation-plan.md](archive/70-crop-implementation-plan.md) | 作物系统实施计划（TFC 附属模组） |
| [71-flora-implementation-log.md](archive/71-flora-implementation-log.md) | TFC Farming Plus（TFC农业+）—— 实施记录（批次 1 ~ 批次 2.9） |
| [72-tfc-crop-reference.md](archive/72-tfc-crop-reference.md) | ﻿# TFC 4.2.10 作物参考数据（批次 3 设计依据） |
| [73-handoff.md](archive/73-handoff.md) | ﻿# 交接摘要（上下文压缩） |
| [74-handoff-and-inventory.md](archive/74-handoff-and-inventory.md) | 74 交接与资产清单（项目完整归档） |
| [75-session-handoff.md](archive/75-session-handoff.md) | 75 新对话交接（本轮会话的完整记忆快照） |
| [76-session-handoff-prior-rounds.md](archive/76-session-handoff-prior-rounds.md) | 76 交接补遗：更早一轮（flash-vision 期间） |
| [77-session-handoff.md](archive/77-session-handoff.md) | 77 本轮交接：枝干结果属性化 + 莲座/叶球重做 + 贴图重绘 |
| [78-texture-redraw-log.md](archive/78-texture-redraw-log.md) | 78 贴图重绘专项记录（2026-09-23 下午场） |
| [79-session-handoff.md](archive/79-session-handoff.md) | ﻿# 79 会话交接：贴图重绘专项（含失败复盘） |

## 贴图 / 渲染

| 文件 | 标题 |
|---|---|
| [80-ingame-verify-and-rosette-geometry.md](archive/80-ingame-verify-and-rosette-geometry.md) | 80 实机验证打通 + 莲座几何根因（2026-09-23 晚，继承 docs/79 的第一批工作） |
| [81-texture-redraw-handwritten.md](archive/81-texture-redraw-handwritten.md) | 81 贴图重绘（逐像素手写）—— 莲座 3 物种 + 「整张 UV」路线 |
| [82-leafball-geometry-and-texture.md](archive/82-leafball-geometry-and-texture.md) | 82 叶球类作物：几何改造 + 贴图重绘（lettuce / broccoli 两个代表） |
| [83-reference-image-and-render-orientation-fix.md](archive/83-reference-image-and-render-orientation-fix.md) | 83 — 参考图失真与渲染器朝向错误（本轮纠正） |
| [84-rosette-wide-plate-and-cardoon-redraw.md](archive/84-rosette-wide-plate-and-cardoon-redraw.md) | 84 — 莲座宽板几何落盘 + cardoon 贴图重绘（2026-09-24 05:55~09:00 轮次） |
| [85-crop-texture-redraw-progress.md](archive/85-crop-texture-redraw-progress.md) | 85 — 作物贴图重绘进度（2026-09-24 05:55~09:00 轮次）· 叶子类 8 物种 |
| [86-texture-drawing-playbook.md](archive/86-texture-drawing-playbook.md) | 86 · TFC 作物贴图工作手册（本会话全部经验 · 结论版） |
| [86-texture-redraw-mid-session-summary.md](archive/86-texture-redraw-mid-session-summary.md) | 86 — 作物贴图重绘 会话中途总结（截至 2026-09-24 06:40） |
| [87-texture-acceptance-criteria.md](archive/87-texture-acceptance-criteria.md) | 87 · 作物贴图验收规格（v2，替换指标口径） |
| [88-texture-species-specs.md](archive/88-texture-species-specs.md) | 88 · 物种骨架规格（并行绘制作业单） |
| [89-texture-survey-ledger.md](archive/89-texture-survey-ledger.md) | 89 · 贴图全量视觉验收台账 |
| [90-texture-pipeline-lessons.md](archive/90-texture-pipeline-lessons.md) | 90 · 作物贴图流水线 · 本会话沉淀（可复用） |
| [91-session-handoff-texture-rounds-19-40.md](archive/91-session-handoff-texture-rounds-19-40.md) | 91 · 交接文档：作物贴图重画（第 19 ~ 40 轮） |
| [92-round41-fenugreek-and-silhouette-audit.md](archive/92-round41-fenugreek-and-silhouette-audit.md) | 92 · 第 41 轮：葫芦巴（fenugreek）age0~4 重画 + 剪影重复审计（新发现） |
| [93-code-backlog-handoff.md](archive/93-code-backlog-handoff.md) | 93 · 代码级未完成清单（交接给另一个会话） |
| [94-renderer-bugs-and-texture-naming-mismatch.md](archive/94-renderer-bugs-and-texture-naming-mismatch.md) | 第 42 轮：渲染器三处 bug、伪造的 crop.json、385 张贴图的命名错位 |
| [95-tfc-visual-standard-alignment.md](archive/95-tfc-visual-standard-alignment.md) | 第 43 轮：把审美标准对齐 TFC（用户明令）—— TFC 的真实画法读数 |
| [96-tfc-crop-drawing-atlas-study.md](archive/96-tfc-crop-drawing-atlas-study.md) | 第 44 轮：通读 TFC 全部作物贴图（29 物种 × 8 龄）—— 画法全谱 |
| [97-tfc-crop-style-spec.md](archive/97-tfc-crop-style-spec.md) | TFC 作物贴图 · 风格规范（画任何作物之前照这个来） |
| [98-chili-species-completion.md](archive/98-chili-species-completion.md) | 第 45 轮：按风格规范完善一个物种 —— chili（辣椒） |
| [99-session-handoff-rounds-41-46.md](archive/99-session-handoff-rounds-41-46.md) | 第 41~46 轮交接（渲染器修复 · 审美对齐 TFC · chili 物种完善） |

## 轮次 / 交接

| 文件 | 标题 |
|---|---|
| [100-inheritance-review-round-47.md](archive/100-inheritance-review-round-47.md) | 第 47 轮：接手复核（全部结论来自本轮实测，不引用文档说法） |
| [101-chili-round9-10-and-tool-bugs.md](archive/101-chili-round9-10-and-tool-bugs.md) | 第 47 轮（续）：chili 收尾五版迭代 + 两个工具级 bug |
| [102-tfc-fruit-tree-and-berry-study.md](archive/102-tfc-fruit-tree-and-berry-study.md) | 第 47 轮 P2：TFC 果树（9 物种）与浆果灌木（12 物种）贴图通读 |
| [103-round47-autonomous-progress.md](archive/103-round47-autonomous-progress.md) | 第 47 轮（续）：自主推进日志（07:00 起，目标 10:00） |
| [104-redraw-per-spec-and-three-lessons.md](archive/104-redraw-per-spec-and-three-lessons.md) | 第 48 轮：重新画（按规范执行）+ 三条教训 |
| [105-rosette-and-leafball-geometry-review.md](archive/105-rosette-and-leafball-geometry-review.md) | 105 · 莲座 / 结球几何与贴图的重新审查（2026-09-27 第 48 轮） |
| [106-cabbage-leafball-redraw.md](archive/106-cabbage-leafball-redraw.md) | 106 — 卷心菜（cabbage）leafball 贴图重画（组名 cabbage-1） |
| [106-round48-summary-and-handoff.md](archive/106-round48-summary-and-handoff.md) | 106 · 第 48 轮小结与交接（2026-09-27 晚） |
| [107-round48-self-review.md](archive/107-round48-self-review.md) | 107 · 第 48 轮**自查报告**（用户要求「自己看看你的工作是否合格」） |
| [108-cubehead-textures-round48.md](archive/108-cubehead-textures-round48.md) | 第 48 轮（子任务）：结球 head / 莲座果实 —— 方块表皮贴图重画 |
| [109-round48-tail-geometry-v5-and-texture-findings.md](archive/109-round48-tail-geometry-v5-and-texture-findings.md) | 第 48 轮尾：结球几何 v5 + 贴图实看发现（2026-09-27 深夜） |
| [110-center-ball-three-fixes.md](archive/110-center-ball-three-fixes.md) | 110 · 中心立方体三项修复（径向叶片 / UV 1:1 / 分面贴图） |
| [111-stick-textures-and-dead-asset-audit.md](archive/111-stick-textures-and-dead-asset-audit.md) | 111 · 插棍贴图 `_stick` 重画 + sisal/agave 区分 + 死贴图全量审计 |
| [112-session-handoff-code-layer.md](archive/112-session-handoff-code-layer.md) | 112 · 会话迁移交接（**代码层**） |
| [113-stick-pole-canonical-and-redraw-spec.md](archive/113-stick-pole-canonical-and-redraw-spec.md) | 113 · 插棍贴图：**杆必须与原版逐像素一致** + 按现实原型重画 |
| [114-session-handoff-texture-and-models.md](archive/114-session-handoff-texture-and-models.md) | 114 · 对话交接：**贴图资源生成 + 方块模型修改** |
| [115-generator-divergence-and-shadow-run-incident.md](archive/115-generator-divergence-and-shadow-run-incident.md) | 115 · 生成器分叉修复 + 影子跑事故（代码层第 2 轮） |
| [115-stick-pole-exact-fix-round49.md](archive/115-stick-pole-exact-fix-round49.md) | 115 · 第 49 轮：插棍 44 张贴图的「杆」逐像素归位（承接 docs/114 的唯一 P0） |
| [116-round49-autonomous-redraw-and-tool-lessons.md](archive/116-round49-autonomous-redraw-and-tool-lessons.md) | 116 · 第 49 轮（下半场）：插棍/老贴图自主重画 + 两条工具级教训 |
| [116-stability-and-completeness-audit.md](archive/116-stability-and-completeness-audit.md) | 116 · 稳定性与完备性审查（代码层第 3 轮） |
| [117-agriculture-redesign-plan.md](archive/117-agriculture-redesign-plan.md) | 117 · 农业重做方案（四模组架构） |
| [117-round49-acceptance-report.md](archive/117-round49-acceptance-report.md) | 117 · 第 49 轮验收报告（2026-09-28 06:00 交付） |
| [118-round49-final-handover.md](archive/118-round49-final-handover.md) | 118 · 第 49 轮最终交接（贴图资源绘制 · 2026-09-28） |
| [119-round49-model-sweep-and-defect-analysis.md](archive/119-round49-model-sweep-and-defect-analysis.md) | 119 · 第 49 轮「逐模型渲染补齐 + 全作物缺陷分析」（2026-09-28） |
| [120-render-defect-ledger-and-wild-crop-placeholders.md](archive/120-render-defect-ledger-and-wild-crop-placeholders.md) | 120 · 全渲染图缺陷台账 + 野生作物占位贴图清查（2026-09-28） |
| [121-session-handoff-texture-production.md](archive/121-session-handoff-texture-production.md) | 121 · 贴图资源制作 **全对话**交接（第 49 轮，2026-09-28） |
| [121-texture-rework-workorder.md](archive/121-texture-rework-workorder.md) | 贴图重画工单（第 52 轮原型对照的总产出） |
| [122-texture-fix-list-and-plans.md](archive/122-texture-fix-list-and-plans.md) | 贴图修复清单与修改方案（可跟踪施工表） |
| [123-tree-leaves-batch3.md](archive/123-tree-leaves-batch3.md) | 批次 9 第 3 批 · 果树叶片 8 树种 × 4 状态（kiwi / lime / loquat / lychee / macadamia / mangosteen / medlar / papaya） |
| [124-cereal-top-report.md](archive/124-cereal-top-report.md) | 第 55 轮追加：cereal-top —— 禾本 `_top` 竖向连续段修复（16 张） |
| [124-tree-leaves-batch4.md](archive/124-tree-leaves-batch4.md) | 批次 9 第 4 批 · 果树叶片 26 树种 × 4 状态（组名 tree-leaves-4） |
| [125-mature-organ-3-report.md](archive/125-mature-organ-3-report.md) | 批次 6 · 成熟期对比色器官（组名 `mature-organ-3`） |
| [125-wild-dead-5-group-report.md](archive/125-wild-dead-5-group-report.md) | 125 · wild-dead-5 组报告 —— 野生态 / 枯死态重画（M–Z 补集，8 物种 / 15 张） |
| [126-b-module-implementation.md](archive/126-b-module-implementation.md) | 126 · B 部分（`tfcagricultureplus`）实现子文档 |
| [127-extradelight-full-analysis.md](archive/127-extradelight-full-analysis.md) | 127 · extradelight 全面分析 |
| [128-in-world-jei-20261006.md](archive/128-in-world-jei-20261006.md) | 128 · 世界中加工的 JEI 分类（2026-10-06） |
| [129-boards-timber-validation-20261006.md](archive/129-boards-timber-validation-20261006.md) | 129 · 案板、木工与实机检查交接（2026-10-06） |

## 农业实现

| 文件 | 标题 |
|---|---|
| [130-next-development-plan-20261006.md](archive/130-next-development-plan-20261006.md) | 130 · 下一阶段开发计划 |
| [131-source-audit-independent-design-20261007.md](archive/131-source-audit-independent-design-20261007.md) | 131 · 第一阶段：代码来源复核与独立实现 |
| [132-phase2-baseline-ledger-20261007.md](archive/132-phase2-baseline-ledger-20261007.md) | 132 · 阶段 2 基础台账与覆盖入口交接 |
| [133-phase3-mortar-foods-20261007.md](archive/133-phase3-mortar-foods-20261007.md) | 133 · 阶段 3 石臼食品研磨小批次交接 |
| [134-phase4-board-foods-20261007.md](archive/134-phase4-board-foods-20261007.md) | 134 · 阶段 4 案板预处理小批次交接 |
| [135-phase5-drying-rack-20261007.md](archive/135-phase5-drying-rack-20261007.md) | 135 · 阶段 5 干燥架试点交接 |
| [136-release-integration-handoff-20261007.md](archive/136-release-integration-handoff-20261007.md) | 136 · 阶段 6 整合、发布与交接检查 |
| [137-runtime-regression-20261007.md](archive/137-runtime-regression-20261007.md) | 第 7 步：受控实机回归记录（2026-10-07） |
| [138-phase8-fixes-20261007.md](archive/138-phase8-fixes-20261007.md) | 第 8 步：回归问题修复（2026-10-07） |
| [139-phase9-cocoa-vertical-slice-20261007.md](archive/139-phase9-cocoa-vertical-slice-20261007.md) | 第 9 步：可可首批加工闭环（2026-10-07） |
| [140-phase10-runtime-regression-20261008.md](archive/140-phase10-runtime-regression-20261008.md) | 第 10 步：第 9 步内容实机回归（2026-10-08） |
| [141-phase11-cocoa-processing-20261008.md](archive/141-phase11-cocoa-processing-20261008.md) | 第 11 步：可可加工链扩展（2026-10-08） |
| [142-next-development-plan-20261008.md](archive/142-next-development-plan-20261008.md) | 后续开发计划（第 12 步起，2026-10-08） |
| [143-interaction-regression-20261008.md](archive/143-interaction-regression-20261008.md) | 案板、石臼、干燥架鼠标交互回归记录（2026-10-08） |
| [144-minecraft-automation-diagnosis-20261008.md](archive/144-minecraft-automation-diagnosis-20261008.md) | Minecraft 客户端自动操作故障诊断（2026-10-08） |
| [145-minecraft-automation-repair-attempt-20261008.md](archive/145-minecraft-automation-repair-attempt-20261008.md) | Minecraft 自动操作修复尝试（2026-10-08） |
| [146-phase12-acceptance-deferred-20261008.md](archive/146-phase12-acceptance-deferred-20261008.md) | 第 12 步：用户验收暂缓记录（2026-10-08） |
| [147-phase13-cocoa-fermentation-20261008.md](archive/147-phase13-cocoa-fermentation-20261008.md) | 第 13 步：可可发酵流程（2026-10-08） |
| [148-phase14-strawberry-preflight-20261008.md](archive/148-phase14-strawberry-preflight-20261008.md) | 第 14 步：草莓接管预研记录（2026-10-08） |
| [149-phase15-spice-preflight-20261008.md](archive/149-phase15-spice-preflight-20261008.md) | 第 15 步：香料调味入口实现（2026-10-09） |
| [150-phase16-integration-and-manual-checklist-20261009.md](archive/150-phase16-integration-and-manual-checklist-20261009.md) | 第 16 步：跨批次整合与实机验证清单（2026-10-09） |
| [151-manual-validation-step8-onward-20261009.txt](archive/151-manual-validation-step8-onward-20261009.txt) | TFC农业重制——第八步起完整待实机验证项目清单 |
| [152-defect-remediation-master-plan-20261009.md](archive/152-defect-remediation-master-plan-20261009.md) | TFC 农业重制缺陷整改总方案 |
| [153-canonical-id-ledger-20261009.json](archive/153-canonical-id-ledger-20261009.json) | 153-canonical-id-ledger-20261009 |
| [153-phase0-baseline-audit-20261009.md](archive/153-phase0-baseline-audit-20261009.md) | 第 0 阶段：缺陷整改基线审计记录 |
| [154-global-defect-audit-and-development-plan-20261010.md](archive/154-global-defect-audit-and-development-plan-20261010.md) | TFC 农业重制：全局缺陷审计与后续开发总计划 |
| [155-phase1-tooling-baseline-20261010.json](archive/155-phase1-tooling-baseline-20261010.json) | 155-phase1-tooling-baseline-20261010 |
| [155-phase1-tooling-baseline-20261010.md](archive/155-phase1-tooling-baseline-20261010.md) | 阶段 1：工具门禁与版本基线 |
| [156-phase2-p0-canonical-cleanup-20261010.json](archive/156-phase2-p0-canonical-cleanup-20261010.json) | 156-phase2-p0-canonical-cleanup-20261010 |
| [156-phase2-p0-canonical-cleanup-20261010.md](archive/156-phase2-p0-canonical-cleanup-20261010.md) | 阶段 2 P0：草莓、可可和汤入口规范化（2026-10-10） |
| [157-phase2-p1-tfc-inventory-refactor-20261010.json](archive/157-phase2-p1-tfc-inventory-refactor-20261010.json) | 157-phase2-p1-tfc-inventory-refactor-20261010 |
| [157-phase2-p1-tfc-inventory-refactor-20261010.md](archive/157-phase2-p1-tfc-inventory-refactor-20261010.md) | 阶段 2 P1：TFC 容器接口第一批重构（2026-10-10） |
| [158-phase2-p2-worldgen-cocoa-seasoning-20261012.md](archive/158-phase2-p2-worldgen-cocoa-seasoning-20261012.md) | 阶段 2 P2：草莓世界生成、可可和调味入口修复 |
| [159-phase3-4-drying-timber-kiln-20261012.md](archive/159-phase3-4-drying-timber-kiln-20261012.md) | 阶段三、四：干燥架、木工与封窑修复交接 |
| [160-runtime-acceptance-drying-batch-plan-20261013.md](archive/160-runtime-acceptance-drying-batch-plan-20261013.md) | 实机验收记录与干燥架批量改动 |
| [161-phase-b-independent-woodworking-migration-plan-20261013.md](archive/161-phase-b-independent-woodworking-migration-plan-20261013.md) | B 阶段：独立木工系统迁移与工作台契约计划 |
| [162-phase-b1-independent-woodwork-core-20261013.md](archive/162-phase-b1-independent-woodwork-core-20261013.md) | B-1：独立木工核心迁移首批交接 |
| [163-phase-b1-pile-behavior-20261013.md](archive/163-phase-b1-pile-behavior-20261013.md) | B-1：木料堆状态与劈木行为第二批交接 |
| [164-phase-b1-pile-settling-20261013.md](archive/164-phase-b1-pile-settling-20261013.md) | B-1：木料堆容量整理与纵向续堆第三批交接 |
| [165-phase-b2-pile-crouch-insert-20261013.md](archive/165-phase-b2-pile-crouch-insert-20261013.md) | B-2：木料堆潜行连续放入交接 |
| [166-phase-b2-tool-interaction-20261013.md](archive/166-phase-b2-tool-interaction-20261013.md) | B-2：木工工具交互规则交接 |
| [167-phase-b3-b4-contract-gates-20261013.md](archive/167-phase-b3-b4-contract-gates-20261013.md) | B-3 / B-4：工作台与容器契约门禁交接 |
| [168-phase-b5-display-compatibility-20261013.md](archive/168-phase-b5-display-compatibility-20261013.md) | B-5：显示、兼容与构建收尾交接 |
| [169-phase-b6-pile-interaction-polish-20261013.md](archive/169-phase-b6-pile-interaction-polish-20261013.md) | B-6：木料堆交互收尾 |
| [170-phase-b7-pile-species-compatibility-20261013.md](archive/170-phase-b7-pile-species-compatibility-20261013.md) | B-7：木料堆树种一致性修复 |
| [171-phase-b8-woodwork-flow-gate-20261013.md](archive/171-phase-b8-woodwork-flow-gate-20261013.md) | B-8：木工流程审计门禁 |
| [172-phase-b-woodworking-completion-20261013.md](archive/172-phase-b-woodworking-completion-20261013.md) | B 阶段独立木工完成交接 |
| [173-next-development-plan-20261013.md](archive/173-next-development-plan-20261013.md) | 下一阶段开发规划 |
| [174-phase-c1-silkworm-foundation-20261014.md](archive/174-phase-c1-silkworm-foundation-20261014.md) | C1：B 养蚕基础链交接 |
| [175-phase-c1-silkworm-processing-20261014.md](archive/175-phase-c1-silkworm-processing-20261014.md) | C1 后续：养蚕产物与 TFC 织绸链交接 |
| [176-runtime-verification-record-20261014.md](archive/176-runtime-verification-record-20261014.md) | 当前版本实机验证记录 |
| [177-runtime-feedback-and-silkworm-redesign-20261015.md](archive/177-runtime-feedback-and-silkworm-redesign-20261015.md) | 实机反馈、木工阻断分析与养蚕重做方案 |
| [178-phase-c1-silkworm-and-woodwork-closeout-20261015.md](archive/178-phase-c1-silkworm-and-woodwork-closeout-20261015.md) | 阶段记录：木工流程收尾与养蚕基础流程施工 |
| [179-phase-c1-silkworm-second-batch-20261015.md](archive/179-phase-c1-silkworm-second-batch-20261015.md) | 阶段记录：养蚕第二批生命周期与容器访问补全 |
| [180-phase-c1-silkworm-third-batch-20261016.md](archive/180-phase-c1-silkworm-third-batch-20261016.md) | 阶段记录：养蚕第三批每日结算一致性修复 |
| [181-phase-c1-silkworm-guide-sync-20261016.md](archive/181-phase-c1-silkworm-guide-sync-20261016.md) | 阶段记录：养蚕手册与当前流程同步 |
| [182-phase-c1-silkworm-full-flow-closeout-20261016.md](archive/182-phase-c1-silkworm-full-flow-closeout-20261016.md) | 阶段记录：养蚕系统全流程开发收口 |
| [183-phase-c1-silkworm-runtime-ready-20261016.md](archive/183-phase-c1-silkworm-runtime-ready-20261016.md) | C1 养蚕全流程实机验证准备记录 |
| [184-runtime-feedback-silkworm-woodwork-repair-20261017.md](archive/184-runtime-feedback-silkworm-woodwork-repair-20261017.md) | 实机反馈后的养蚕与独立木工修复记录（2026-10-17） |
| [185-silkworm-ui-layout-20261017.md](archive/185-silkworm-ui-layout-20261017.md) | 养蚕箱 UI 布局调整记录（2026-10-17） |
| [186-next-development-plan-20261017.md](archive/186-next-development-plan-20261017.md) | 下一阶段开发计划（2026-10-17） |
| [187-phase2-b-regression-closeout-20261017.md](archive/187-phase2-b-regression-closeout-20261017.md) | 阶段二施工记录：B 设备与木工回归收口（2026-10-17） |
| [188-next-content-development-plan-20261018.md](archive/188-next-content-development-plan-20261018.md) | 下一阶段新内容开发计划（2026-10-18） |
| [189-kitchenware-first-development-plan-20261018.md](archive/189-kitchenware-first-development-plan-20261018.md) | 额外厨具系统优先开发计划（2026-10-18） |
| [190-kitchenware-k0-ledger-20261018.md](archive/190-kitchenware-k0-ledger-20261018.md) | K0 厨具台账与接口冻结记录（2026-10-18） |
| [191-kitchenware-k1-skeleton-20261018.md](archive/191-kitchenware-k1-skeleton-20261018.md) | K1 厨房骨架首批施工记录（2026-10-18） |
| [192-k1-runtime-test-checklist-20261018.md](archive/192-k1-runtime-test-checklist-20261018.md) | K1 厨具系统实机测试清单与自动化验证记录 |
| [193-k2-pan-vertical-slice-20261018.md](archive/193-k2-pan-vertical-slice-20261018.md) | K2 炒锅与调味垂直切片施工记录（2026-10-18） |
| [194-k3-dough-and-placeable-pie-20261018.md](archive/194-k3-dough-and-placeable-pie-20261018.md) | K3 面团成型与可放置整派垂直切片（2026-10-18） |
| [195-k3-melting-pot-20261019.md](archive/195-k3-melting-pot-20261019.md) | K3 熔化锅与 Firmalife 巧克力混合物垂直切片（2026-10-19） |
| [196-k3-whole-cake-placeable-food-20261019.md](archive/196-k3-whole-cake-placeable-food-20261019.md) | K3 整蛋糕与统一可放置食品切片（2026-10-19） |
| [197-k3-whole-cheese-placeable-food-20261019.md](archive/197-k3-whole-cheese-placeable-food-20261019.md) | K3 整奶酪与统一可放置食品切片（2026-10-19） |
| [198-k3-butter-block-placeable-food-20261019.md](archive/198-k3-butter-block-placeable-food-20261019.md) | K3 黄油块与统一可放置食品切片（2026-10-19） |
| [199-k3-jelly-block-placeable-food-20261019.md](archive/199-k3-jelly-block-placeable-food-20261019.md) | K3 果冻块与统一可放置食品切片（2026-10-19） |

## 近期 / 验证

| 文件 | 标题 |
|---|---|
| [200-k3-sugar-block-placeable-food-20261019.md](archive/200-k3-sugar-block-placeable-food-20261019.md) | K3 糖块与统一可放置食品切片（2026-10-19） |
| [201-k3-placeable-food-runtime-checklist-20261019.md](archive/201-k3-placeable-food-runtime-checklist-20261019.md) | K3 可放置食品统一实机验证清单（2026-10-19） |
| [202-path-length-audit-and-pcl-staging-20261019.md](archive/202-path-length-audit-and-pcl-staging-20261019.md) | 路径长度审计与 PCL 短路径迁移实例（2026-10-19） |
| [203-k3-placeable-food-level-null-crashfix-20261020.md](archive/203-k3-placeable-food-level-null-crashfix-20261020.md) | K3 可放置整黄油放置崩溃修复记录（2026-10-20） |
| [204-k3-dough-board-and-kitchen-rework-plan-20261020.md](archive/204-k3-dough-board-and-kitchen-rework-plan-20261020.md) | K3 面团、案板与厨具系统重构开发计划（2026-10-20） |
| [205-k3-dough-board-confirm-interaction-revision-20261021.md](archive/205-k3-dough-board-confirm-interaction-revision-20261021.md) | K3 面团案板确认交互修订记录（2026-10-21） |
| [206-k3-dough-board-confirmation-comprehensive-plan-20261021.md](archive/206-k3-dough-board-confirmation-comprehensive-plan-20261021.md) | K3 面团案板确认加工功能全面开发计划（2026-10-21） |
| [207-k3-dough-board-confirmation-implementation-20261021.md](archive/207-k3-dough-board-confirmation-implementation-20261021.md) | K3 面团案板确认加工施工记录（2026-10-21） |
| [208-pcl-instance-archive-20261021.md](archive/208-pcl-instance-archive-20261021.md) | PCL 启动器实例压缩包记录（2026-10-21） |
| [209-pcl-client-archive-20261022.md](archive/209-pcl-client-archive-20261022.md) | PCL 客户端压缩包修复记录（2026-10-22） |
| [210-pcl-neoforge-missing-20261022.md](archive/210-pcl-neoforge-missing-20261022.md) | PCL 导入后 NeoForge 缺失错误记录（2026-10-22） |
| [211-pcl-neoforge-artifact-path-20261022.md](archive/211-pcl-neoforge-artifact-path-20261022.md) | PCL NeoForge 通用包路径修复记录（2026-10-22） |
| [212-pcl-client-runtime-20261022.md](archive/212-pcl-client-runtime-20261022.md) | PCL NeoForge 客户端运行库修复记录（2026-10-22） |
| [213-pcl-v5-runtime-repair-20261022.md](archive/213-pcl-v5-runtime-repair-20261022.md) | PCL v5 启动包与现有实例修复（2026-10-22） |
| [214-pcl-runtime-rebuild-20261022.md](archive/214-pcl-runtime-rebuild-20261022.md) | PCL 客户端运行时重建与 14:47 崩溃报告复盘（2026-10-22） |
| [215-pcl-packaging-playbook-and-failure-lessons-20261022.md](archive/215-pcl-packaging-playbook-and-failure-lessons-20261022.md) | PCL 客户端打包前必读：成功流程与失误复盘（2026-10-22） |
| [216-oven-timer-and-butter-cake-fix-20261022.md](archive/216-oven-timer-and-butter-cake-fix-20261022.md) | K3 烤炉计时与黄油蛋糕修复记录（2026-10-22） |
| [217-agriculture-repair-next-phase-plan-20261023.md](archive/217-agriculture-repair-next-phase-plan-20261023.md) | 下一阶段开发计划：农业系统修复与闭环（2026-10-23） |
| [218-agriculture-audit-baseline-20261023.md](archive/218-agriculture-audit-baseline-20261023.md) | 农业阶段 AR0：源码与资源现状审计（2026-10-23） |
| [219-ar1a-strawberry-guide-20261023.md](archive/219-ar1a-strawberry-guide-20261023.md) | AR1-A：草莓灌木手册收口与草莓种植说明（2026-10-23） |
| [220-ar1b-cocoa-canonical-20261023.md](archive/220-ar1b-cocoa-canonical-20261023.md) | AR1-B：可可产物统一与旧树兼容收口（2026-10-23） |
| [221-ar1c-single-pickable-crop-audit-20261023.md](archive/221-ar1c-single-pickable-crop-audit-20261023.md) | AR1-C：单格与可重复采收作物审查及采收说明修订（2026-10-23） |
| [222-ar1d-tall-climbing-crop-repair-20261023.md](archive/222-ar1d-tall-climbing-crop-repair-20261023.md) | AR1-D：双格与攀爬作物审查、修复和交接（2026-10-23） |
| [223-ar1e-flooded-crop-generation-guide-repair-20261023.md](archive/223-ar1e-flooded-crop-generation-guide-repair-20261023.md) | AR1-E：水生作物审查、浅水生成与种植说明修复（2026-10-23） |
| [224-ar1f-spreading-fruit-decay-harvest-repair-20261023.md](archive/224-ar1f-spreading-fruit-decay-harvest-repair-20261023.md) | AR1-F：蔓延作物、整瓜腐烂与采收修复交接（2026-10-23） |
| [225-ar1g-rosette-state-harvest-guide-repair-20261023.md](archive/225-ar1g-rosette-state-harvest-guide-repair-20261023.md) | AR1-G：莲座作物结果、返种和手册修复交接 |
| [226-ar3a-temperate-tree-lifecycle-repair-20261023.md](archive/226-ar3a-temperate-tree-lifecycle-repair-20261023.md) | AR3-A：温带果树与共享生长接口修复交接 |
| [227-ar2a-fruit-tags-pie-processing-repair-20261023.md](archive/227-ar2a-fruit-tags-pie-processing-repair-20261023.md) | AR2-A：水果原料、整派配方与食品信息修复交接 |
| [228-ar3b-tropical-tree-generation-repair-20261023.md](archive/228-ar3b-tropical-tree-generation-repair-20261023.md) | AR3-B：热带果树、自然初始生长与水果分类修复交接 |
| [229-ar3c-nut-tree-food-integration-20261024.md](archive/229-ar3c-nut-tree-food-integration-20261024.md) | AR3-C：五种坚果树与原生食物用途接入交接 |
| [230-ar3d-trunk-fruit-lifecycle-legacy-cocoa-20261024.md](archive/230-ar3d-trunk-fruit-lifecycle-legacy-cocoa-20261024.md) | AR3-D：树干结果生命周期与旧可可兼容修复交接 |
| [231-ar3e-pepper-and-remaining-fruit-trees-20261024.md](archive/231-ar3e-pepper-and-remaining-fruit-trees-20261024.md) | AR3-E 黑胡椒及其余八种果树闭环交接（2026-10-24） |
| [232-农业完善阶段总结-20261024.txt](archive/232-农业完善阶段总结-20261024.txt) | ﻿农业完善阶段总结 |
| [233-final-code-readability-and-structure-plan-20261024.md](archive/233-final-code-readability-and-structure-plan-20261024.md) | 全部现有工作完成后的工程可读性整理计划 |
| [234-ar3f-bush-timers-worldgen-compatibility-20261024.md](archive/234-ar3f-bush-timers-worldgen-compatibility-20261024.md) | AR3-F 灌木计时与自然生成兼容交接（2026-10-24） |
| [235-ar2b-soil-nutrients-fertilizer-compost-20261024.md](archive/235-ar2b-soil-nutrients-fertilizer-compost-20261024.md) | AR2-B 土壤养分、原生肥料与堆肥入口交接（2026-10-24） |
| [236-ar2c-agricultural-material-processing-20261025.md](archive/236-ar2c-agricultural-material-processing-20261025.md) | AR2-C 非食品农业材料与既有加工接入交接（2026-10-25） |
| [237-ar2d-grain-bean-oilseed-processing-20261025.md](archive/237-ar2d-grain-bean-oilseed-processing-20261025.md) | AR2-D：现有谷物、豆类和油料的加工与食品信息 |
| [238-ar2e-vegetables-spices-beverage-harvests-20261025.md](archive/238-ar2e-vegetables-spices-beverage-harvests-20261025.md) | AR2-E：剩余蔬菜、调味及茶咖啡收获物用途 |
| [239-ar4a-seedling-texture-reference-review-20261025.md](archive/239-ar4a-seedling-texture-reference-review-20261025.md) | AR4-A：苗期模型与历史贴图引用复核 |
| [240-ar4b-leaf-vegetable-lifecycle-visuals-particles-20261025.md](archive/240-ar4b-leaf-vegetable-lifecycle-visuals-particles-20261025.md) | AR4-B：三种叶菜完整形态审查与粒子接线修复 |
| [241-ar4c-shared-rosette-fruit-support-20261025.md](archive/241-ar4c-shared-rosette-fruit-support-20261025.md) | AR4-C：五种共享莲座结果态的高度与承托修复 |
| [242-ar4d-broccoli-wild-dead-models-20261025.md](archive/242-ar4d-broccoli-wild-dead-models-20261025.md) | 242 · AR4-D 西兰花野生与枯死形态修复交接 |
| [243-ar4e-lettuce-wild-dead-models-20261025.md](archive/243-ar4e-lettuce-wild-dead-models-20261025.md) | 243 · AR4-E 生菜野生与枯死形态修复交接 |
| [244-ar4f-kale-wild-shared-dead-scope-20261025.md](archive/244-ar4f-kale-wild-shared-dead-scope-20261025.md) | 244 · AR4-F 羽衣甘蓝野生形态修复与共享枯死模型范围复核 |

## 未分类

| 文件 | 标题 |
|---|---|
| [245-ar4g-shared-dead-rosette-visuals-20261025.md](archive/245-ar4g-shared-dead-rosette-visuals-20261025.md) | 245 · AR4-G 共享莲座成熟与幼年枯死形态修复交接 |
| [246-ar4h-cauliflower-lifecycle-models-20261025.md](archive/246-ar4h-cauliflower-lifecycle-models-20261025.md) | 246 · AR4-H 花菜全生命周期模型与粒子接线核对 |
| [247-ar4i-napa-cabbage-lifecycle-models-20261025.md](archive/247-ar4i-napa-cabbage-lifecycle-models-20261025.md) | 247 · AR4-I 白菜全生命周期模型与粒子接线核对 |
| [248-ar4j-shared-leafball-support-20261025.md](archive/248-ar4j-shared-leafball-support-20261025.md) | 248 · AR4-J 共享叶球承托、透明轮廓与原生卷心菜范围复核 |
| [249-ar4k-current-visual-backlog-review-20261025.md](archive/249-ar4k-current-visual-backlog-review-20261025.md) | 249 · AR4-K 剩余农业视觉问题与当前接线复核 |
| [250-ar4l-chili-display-and-generator-protection-20261025.md](archive/250-ar4l-chili-display-and-generator-protection-20261025.md) | 250 · AR4-L 辣椒自有显示链与生成器防回退 |
| [251-ar4m-fenugreek-display-and-shared-checks-20261026.md](archive/251-ar4m-fenugreek-display-and-shared-checks-20261026.md) | 251 · AR4-M 葫芦巴显示链与共用检查 |
| [252-ar4n-spinach-display-and-asset-mismatch-20261026.md](archive/252-ar4n-spinach-display-and-asset-mismatch-20261026.md) | 252 · AR4-N 菠菜显示修复与素材错配 |
| [253-ar4o-item-icon-audit-and-leafy-first-batch-20261026.md](archive/253-ar4o-item-icon-audit-and-leafy-first-batch-20261026.md) | AR4-O 农业食品与种子图标核对、首批叶菜修复 |
| [254-ar4p-asparagus-eggplant-okra-harvest-icons-20261026.md](archive/254-ar4p-asparagus-eggplant-okra-harvest-icons-20261026.md) | AR4-P 芦笋、茄子、秋葵采收物图标修复 |
| [255-ar4q-leaf-stem-harvest-icons-20261026.md](archive/255-ar4q-leaf-stem-harvest-icons-20261026.md) | AR4-Q 六种叶菜/茎菜采收物图标修复 |
| [256-ar4r-bean-harvest-icons-and-size-guard-20261026.md](archive/256-ar4r-bean-harvest-icons-and-size-guard-20261026.md) | AR4-R 四豆类采收物图标与16×16检查 |
| [257-ar4s-climbing-gourd-harvest-icons-20261026.md](archive/257-ar4s-climbing-gourd-harvest-icons-20261026.md) | AR4-S 四攀爬瓜类采收物图标修复 |
| [258-ar4t-underground-harvest-icons-20261026.md](archive/258-ar4t-underground-harvest-icons-20261026.md) | AR4-T 芋头、山药、莲藕、慈菇图标修复 |
| [259-ar4u-remaining-food-icons-20261026.md](archive/259-ar4u-remaining-food-icons-20261026.md) | AR4-U 八项食品图标修复与交付记录 |
| [260-ar4v-visual-backlog-and-agriculture-status-20261026.md](archive/260-ar4v-visual-backlog-and-agriculture-status-20261026.md) | AR4-V 剩余视觉待办与农业阶段状态复核 |
| [261-ar4w-nut-food-icons-20261026.md](archive/261-ar4w-nut-food-icons-20261026.md) | AR4-W 五种坚果食品图标修复 |
| [262-ar4x-special-food-icons-and-guide-20261026.md](archive/262-ar4x-special-food-icons-and-guide-20261026.md) | AR4-X 大黄、向日葵、龙舌兰食品图标与说明修复 |
| [263-ar4y-leafy-food-icons-first-batch-20261026.md](archive/263-ar4y-leafy-food-icons-first-batch-20261026.md) | AR4-Y 芝麻菜、茼蒿、芥菜、紫苏食品图标 |
| [264-ar4z-leafy-food-icons-second-batch-20261026.md](archive/264-ar4z-leafy-food-icons-second-batch-20261026.md) | AR4-Z 生菜、菠菜、牛皮菜、马齿苋食品图标 |
| [265-ar4aa-sunflower-whole-display-20261027.md](archive/265-ar4aa-sunflower-whole-display-20261027.md) | AR4-AA 向日葵完整显示链审查与修复 |
| [266-ar4ab-spinach-planter-mature-20261027.md](archive/266-ar4ab-spinach-planter-mature-20261027.md) | AR4-AB 菠菜盆栽成熟显示修复 |
| [267-ar4ac-swiss-chard-harvest-guide-20261027.md](archive/267-ar4ac-swiss-chard-harvest-guide-20261027.md) | AR4-AC 牛皮菜采收说明与生命周期一致性核对 |
| [268-ar4ad-swiss-chard-native16-display-20261027.md](archive/268-ar4ad-swiss-chard-native16-display-20261027.md) | AR4-AD 牛皮菜完整显示与原生16格贴图 |
| [269-ar4ae-celery-native16-display-20261027.md](archive/269-ar4ae-celery-native16-display-20261027.md) | AR4-AE 芹菜完整显示与原生16格贴图 |
| [270-ar4af-celtuce-native16-display-20261027.md](archive/270-ar4af-celtuce-native16-display-20261027.md) | AR4-AF 莴笋完整显示与原生16格贴图 |
| [271-ar4ag-rhubarb-native16-display-20261027.md](archive/271-ar4ag-rhubarb-native16-display-20261027.md) | AR4-AG 大黄完整显示与原生16格贴图 |
| [272-github-snapshot-and-development-pause-20261027.md](archive/272-github-snapshot-and-development-pause-20261027.md) | 暂停开发与GitHub版本整理 |
| [273-naming-and-file-structure-requirements-20261027.md](archive/273-naming-and-file-structure-requirements-20261027.md) | 273 命名与文件结构整理需求 |
