# 276 全量内容审查报告：mod_rebuild / 分支 mod-rebuild-20261027

> 审查日期：2026-10-28（Asia/Shanghai）
> 审查对象：`mod_rebuild` 工作树（对应 GitHub `likexiang21/TFCPLUS` 分支 `mod-rebuild-20261027`，根目录已扁平化为 `mod_rebuild` 内容）
> 审查方式：只读内容审查 + 静态检查 + A/B 构建复现 + 资源引用图分析 + 旧 JAR 对比；另有 D1/D2/D3 三份专项证据报告。
> 重要边界：**本报告不把静态检查、构建成功或资源存在性等同于实机/视觉验收。** 本环境没有 `.tooling/game`，没有启动游戏，没有视觉验收。除新增本报告/audit 索引及修复 4 处工具断链外，未改 Java、资源、构建配置或既有文档正文。
> **后续修复**：2026-10-28 已按 277 完成许可证、6 整瓜、B loot/贴图/AFC、构建路径等修复；新产物与验证见 [279 修复记录](279-protocol-code-fixes-20261028.md)。本报告中的旧哈希/旧问题保留为审查快照。

---

## 0. 结论摘要

### 0.1 一句话结论

**Java 包/文件结构重构和 A/B 构建基线已经成立；当前内容还不能作为可交付版本。**
主要问题不是“代码不能编译”，而是：A 的大量美术处于生成器占位态（949 个模型会回退到 TFC 贴图）、整瓜模型丢贴图覆盖、B 大面积方块没有掉落表、B 有缺失贴图/物品/依赖，以及文档/交付/构建路径仍把旧工作区当成运行环境。

### 0.2 五条 P0

1. **A 949 个模型的贴图引用回退成 TFC 占位**
   - 旧已发布 JAR 中这些模型引用 `tfcfarmingplus:` 自有贴图；
   - 当前源码树全部改成 `tfc:` 借用；
   - 949 张自有贴图仍在树中，但没有模型引用；
   - `artifacts/` 当前 JAR 与源码树一致 ⇒ 现在构建/换包会把约 80% 作物美术换回 TFC 原版。
2. **A 6 个整瓜模型在资源分层时丢失 `textures` 覆盖**
   - `models/block/melon/{cantaloupe,winter_melon,bottle_gourd,rotten_*}.json` 仅有 `{"parent":"minecraft:block/melon"}`；
   - 旧 JAR 带 side/end 自有贴图覆盖；
   - 12 张 `textures/block/melon/*_fruit_{side,top}.png` 全死，游戏内显示 vanilla 西瓜。
3. **B 389/492 个方块没有 loot table**
   - 只有 34 木×3 种 timber 料 + `silkworm_rack` 等 103 个有掉落表；
   - 案板、刀架、晾架、6 类厨房柜、石臼、顶层功能方块等破坏后不掉落；
   - Java 中未见 `getDrops` 覆写。
4. **分支根目录不是自包含可构建树**
   - A/B 的 `build.gradle.kts` 都按 `rootProject.projectDir.resolve("../../mods")` 找依赖；
   - 分支根目录下这一路径指向仓库**外部**；仓库也没有 `mods/`、`gradlew`、`.tooling/`；
   - B 还依赖 `../tfcfarmingplus/build/libs`，而文档声明构建后删除 `build/`；
   - 结论：按分支根目录直接 `gradle build` 不可复现，必须在仓库外准备旧工作区布局。
5. **交付/状态证据链断裂，文档声称与实测不符**
   - 271/272 的 A/B 哈希是旧 JAR；当前 artifacts 哈希已不同；
   - 实例 `mods/` 里仍是 2026-10-05 的旧 JAR；
   - 274 仍写“资源逐字节与旧树一致、唯一差异是 B mixins”，实测 A 有 10 改 + 20 路径迁移、B 有 163 改 + 18 迁移；
   - 当前没有 `DELIVERY.md`/`STATUS.md`/`PLAN.md`，也没有新哈希、部署位置和回滚点。

### 0.3 判定

| 维度 | 结论 |
|---|---|
| Java 结构/命名 | 良好；0 个 `My*`，包/文件一致，A/B 构建成功 |
| 资源协议（加载/引用） | 基本完整；blockstate 变体 0 结构问题，tags 0 缺失，worldgen 闭环；但 B loot、B 缺失贴图是真实缺口 |
| 内容完成度 | **未完成**：A 主体美术是生成器占位/未接入态；B 主体方块美术是 TFC/vanilla 借用；两模组均未实机验收 |
| 文档可信度 | 中低：当前入口有自相矛盾/过时数字/失效绝对路径；真正计划在 archive 217/260，未提升 |
| 可交付性 | **不可交付**：先修 P0，再谈运行/视觉 |

---

## 1. 审查对象、方法与证据

### 1.1 对象基线

- 分支：`mod-rebuild-20261027`（GitHub 根目录 = `mod_rebuild` 内容）；
- 审查工作树：`mod_rebuild/`；
- 分支跟踪文件数：9,586（项目文件 9,584 + `.gitignore` + `.gitattributes`）；
- Java：A 37 文件 / 5,003 行，B 86 文件 / 7,504 行；
- A 资源：5,922 文件；B 资源：3,031 文件；
- A/B 构建：`gradle build --offline` 均 BUILD SUCCESSFUL；
- 当前 artifacts：
  - A `TFCFarmingPlus-NeoForge-1.21.1-0.1.0.jar`：2,416,956 B，SHA-256 `386834A158241D9371D9744BB93CDBD9CDAF4E0C32765403F70D989DC7EAF8B8`；
  - B `TFCAgriculturePlus-NeoForge-1.21.1-0.1.0.jar`：1,407,338 B，SHA-256 `97B961DB4E83DD8779B522B1B9313585959E3025225B996D0DFD1A5C4778A916`。
- 实例 `mods/` 当前是同名旧 JAR：
  - A 2,209,146 B（2026-10-05 08:04）；
  - B 258,502 B（2026-10-05 10:57）。
  - **未部署新 artifacts。**

### 1.2 方法

1. 逐篇阅读 12 份当前文档与 244 份旧文档归档，核对 271/272/273/274/275/README/217/218/260 的数字与状态；
2. 对 `src/main/resources` 做资源引用图（blockstate → model → texture、item model、parent 链）与死资源扫描；
3. 用 TFC/Firmalife/afc/vanilla/旧 A JAR 作为外部参照，核验跨命名空间引用；
4. 运行 A/B 离线构建、A/B 关键 verify/audit、静态检查；
5. 对 `tools/`、`contracts/`、`data/`、wrapper、构建路径、部署路径做只读审计；
6. D1/D2/D3 专项报告分别从文档、资源、Java/工具角度交叉复核。

### 1.3 证据文件

- [D1 文档与计划审查](audit/D1-docs-and-plans.md)
- [D2 资源与数据协议审查](audit/D2-resources-and-protocols.md)
- [D3 Java/工具/合同审查](audit/D3-java-tools-contracts.md)
- 原始 CSV/脚本/日志：工作区 `mod_rebuild/docs/audit/` 下 `d2-*`、`D3-*`、`lead-*`（分支未全部携带，见文末）。

### 1.4 审查期间的工具修复（不是内容修复）

审查中发现 4 处“脚本分组后路径/旧变量名断链”，已修复并复测：

- `audit-soil-contracts.ps1`、`audit-bush-contracts.ps1` 读取生成器时仍走根 wrapper 而非 `scripts/generate/`；
- `audit-branch-fruit-contracts.ps1` 仍期望旧变量名 `now`，当前已是 `currentState`；
- B `verify-vegetable-beverage-processing.ps1` 仍读 A 的 `tools/crops-manifest.json` 与 A `AgricultureItems.java`，应为 `tools/contracts/` 与 A `FarmingItems.java`。

修复后：A `audit-soil` 174 findings → 0；`audit-bush` 2 → 0；`audit-branch` 1 → 0；B `verify-vegetable` 崩溃 → EXIT 0。这些**不计入内容缺陷**，但说明工具路径维护仍是风险。另新增了本报告与 `docs/audit/` 索引，并更新了 `docs/README`/根 `README` 的审计文档入口；未改既有文档正文。

---

## 2. 项目全貌

### 2.1 A `tfcfarmingplus`（农业、果树、灌木、资源）

| 项目 | 数量/状态 |
|---|---:|
| Java 文件 | 37 |
| Java 行数 | 5,003 |
| 包数 | 11 |
| 资源文件 | 5,922 |
| blockstates | 481 |
| models/block | 1,652 |
| models/item | 435 |
| textures/block | 1,487 |
| textures/item | 330 |
| 已公开内容 | 87 作物 / 49 果树 / 12 灌木 |
| 已有构建 JAR | 2,416,956 B |

功能层包括：TFC 作物扩展、果树（含树干/枝干果实）、浆果灌木、野生/枯死变体、气候与 worldgen、掉落、Patchouli 手册、TFC/Firmalife 兼容数据。

但资源实际质量是：**大量模型只是生成器输出态**。旧 JAR 中有 949 个模型使用 A 自有贴图，当前源码树全部退回 `tfc:` 借用；949 张自有贴图仍在 `textures/block|crop|dead_crop|wild_crop|item` 下，但没有任何模型引用。另有 6 个整瓜模型丢失 `textures` 覆盖。

### 2.2 B `tfcagricultureplus`（木工、养蚕、厨具、加工）

| 项目 | 数量/状态 |
|---|---:|
| Java 文件 | 86 |
| Java 行数 | 7,504 |
| 包数 | 18 |
| 资源文件 | 3,031 |
| blockstates | 492（69 个基础方块名） |
| models/block | 506 |
| models/item | 636 |
| textures/item | 57 |
| textures/block | 0（全部借用 TFC/vanilla/Firmalife） |
| 配方 | 756（其中 in_world 409） |
| loot table | 103 |
| 已有构建 JAR | 1,407,338 B |

功能层包括：木工（原木/案板/刀架/石臼/木料/木堆）、养蚕链、厨房家具/容器、烹饪锅/烤炉/面团台/融化锅、食物加工配方与 JEI 兼容。

主要问题：**389/492 个方块没有 loot table**；16 处模型贴图引用缺失；`food/pan_seasoned_vegetables` 无 item 模型；B 未在 `neoforge.mods.toml` 声明 afc 依赖，却注册/引用 14 个 AFC 树种资源。

### 2.3 开发阶段与验证状态

- 功能开发在 271（AR4-AG 大黄显示链）后暂停；272 记录暂停上传；
- 之后执行了 273/274/275 工程重构、A/B 构建、资源分层；
- 当前没有恢复功能开发的记录；
- 最后一次游戏日志为 **2026-10-05 11:00**；
- 本次审查没有启动游戏；
- A `verify.ps1` 在修复工具断链后可到 **0 FAIL / 5 OK**，随后因缺 Minecraft client asset jar 中断；
- B 的 container/grain/fruit/in-world/boundaries/kitchenware/drying/silkworm 等脚本可运行通过；`verify-registry` 的 static 模式会因循环注册变体产生必然假阳性，需 `-FromLog`；B loot 缺口没有被现有工具覆盖。

---

## 3. 死内容、占位内容与“该不该删”

### 3.1 A 的 949 个模型贴图回退（P0，不能删，必须接入）

证据链：

- 旧已发布 `mods/TFCFarmingPlus-*.jar` 中，`models/block/crop/adzuki_age_0.json` 为
  `"textures":{"crop":"tfcfarmingplus:block/crop/adzuki_age_0"}`；
- 当前源码树同名模型为
  `"textures":{"crop":"tfc:block/crop/soybean_0"}`；
- 旧 item 模型 `item/food/adzuki.json` 引用 `tfcfarmingplus:item/food/adzuki`，当前农物 item 模型大量改回 TFC 物品贴图。

D2 对比结果：

| 目录 | 回退模型数 |
|---|---:|
| block/crop | 609 |
| block/dead_crop | 138 |
| block/wild_crop | 73 |
| item/seeds | 84 |
| item/food | 39 |
| item/fiber | 4 |
| 其他 | 2 |
| **合计** | **949** |

949 张对应自有贴图**全部存在**（缺失 0）。因此：

- 这不是“无引用垃圾”，而是**待接入的正式资产**；
- 不能按“未引用就删”处理；
- 应由旧 JAR/旧资源回写模型引用，或执行修正后的 `localize-textures.ps1` 并复验；
- 当前 `artifacts` 已携带回退后的模型，换包会直接视觉回退。

### 3.2 6 个整瓜模型丢失 `textures` 覆盖（P0）

当前：

```json
{"parent":"minecraft:block/melon"}
```

旧 JAR：

```json
{"parent":"minecraft:block/melon",
 "textures":{"side":"tfcfarmingplus:block/bottle_gourd_fruit_side",
             "end":"tfcfarmingplus:block/bottle_gourd_fruit_top",
             "particle":"tfcfarmingplus:block/bottle_gourd_fruit_side"}}
```

受影响：`bottle_gourd`、`cantaloupe`、`winter_melon`、`rotten_bottle_gourd`、`rotten_cantaloupe`、`rotten_winter_melon`。
12 张 `textures/block/melon/*_fruit_{side,top}.png` 因此全部死引用。游戏内整瓜/腐烂瓜会显示 vanilla 西瓜。

### 3.3 A 死贴图总量与分类（1,130 张）

D2 统计：A 共 1,817 张 PNG，死贴图 **1,130 张（约 241 KB）**：

| 分类 | 数量 | 处置建议 |
|---|---:|---|
| 949 张“旧 JAR 曾用、当前树存在但模型改回 TFC” | 949 | **保留并接入**，不是垃圾 |
| 12 张 melon 果皮 | 12 | 恢复 6 个模型 `textures` 后即可用 |
| 5 张 plant 历史图 | 5 | 对照 `branch_fruit` 旧模型，确认后归档 |
| 其余 food/seeds/fiber 等历史遗留 | 约 164 | 逐项确认；无模型/无配方/无 Java 引用者归档或删除 |
| **合计** | **1,130** | |

补充特征：

- 6 张低色数图（`broccoli_age_0`、`cauliflower_age_0`、`kale_age_0`、`pearl_millet_age_2`、`sorghum_age_1`、`sorghum_age_2`）均为死贴图，颜色数 ≤2，属于明显占位；
- 6 张左右全透明/单色贴图；84 张颜色数 ≤3；
- 26 组重复贴图（最大一组 3 张）；
- 8 张与 TFC 逐像素相同（strawberry 整套借用 TFC 灌木图）。

### 3.4 A 死模型（3 个）

- `models/block/plant/branch_fruit.json`
- `models/block/plant/cocoa_branch_fruit_ripe.json`
- `models/block/plant/cocoa_branch_fruit_unripe.json`

这三个模型没有被任何 blockstate、item model 或 parent 链引用；Java 也没有直接引用。属于旧树干果实方案的遗留，应与旧方案文档一起归档，删除前确认无外部 addon 依赖。

### 3.5 B 的占位/缺失/协议缺口

B 没有自有 `textures/block`，方块模型几乎全部借用 TFC/vanilla/Firmalife 贴图：**493/506 个 block 模型只使用外部贴图**。这是设计上的“占位美术”，不是加载错误，但视觉完成度低。

具体主问题：

1. **389/492 个方块无 loot table**（详见 §4.3）；
2. **16 处模型贴图引用缺失**：
   - 12 个 `raw_*_bun/naan` 引用 `firmalife:item/food/*_dough`，Firmalife 实际为 `*_flatbread_dough`；
   - `item/flint_pestle` 引用不存在的 `tfcagricultureplus:item/flint_pestle`；
   - `item/food/chocolate_cake_slice`、`cream_cake_slice` 引用不存在的 `item/food/cake_slice`；
   - `whole_pie` 引用不存在的 `minecraft:block/pumpkin` 贴图（应为 `pumpkin_side/top`）。
3. `food/pan_seasoned_vegetables` 已注册且是配方产物，但没有 item 模型；`data/tfcagricultureplus/tfc/food/pan_seasoned_vegetables.json` 也指向该物品。
4. B 未声明 `afc` 依赖，却引用/注册 14 个 AFC 树种资源；缺 AFC 时资源/创造页可能不完整。
5. `log_pile`/`burning_log_pile` blockstate 指向空模型，靠 BE renderer 渲染；这是设计，但需文档注明。

### 3.6 Java 死代码/占位代码（不是全部都需要删）

正面：A/B 均无 `My*`，无泛化前缀，文件/类型/包一致，构建通过。

需要单独判断的：

| 项 | 结论 |
|---|---|
| `SpeciesLookup`（164 行，0 Java 消费者） | 文档/OVERRIDE 说它是 B 的稳定 API，但 B 对 A **0 个 Java import**，且 B 仍保留 `implementation(files(aJar))`。它是“声明中的 API、实施上的空契约”，不能仅凭 javadoc 当活代码；建议接线或删除 A-jar 依赖并修正文档。 |
| `DebugValidation` | 仅 debug 命令入口；其中“12 个案板配方”断言与实际 **15** 不符，一跑即失败；应修正或删除该断言。 |
| `DoughRecipeCategory` / `MeltingRecipeCategory` / DOUGH、MELTING RecipeType | 可能为死代码/JEI 兼容遗留，需确认是否被配方注册实际使用。 |
| `FarmingCrops` 348 个公开注册字段 | 多数只在本文件自引，可能是供 B/外部使用的公共 API；不能按“无外部引用”批量删。 |
| A/B 31 条 FQCN-only import、B 25 条通配 import、11 处 `be/s/r` 短变量 | 命名/风格债；不阻断构建，但违反 273 的收尾标准。 |
| 两个 `setup/commonSetup` 空方法 | 空挂载点；应删除或注明保留原因。 |
| 公共嵌套 record（273 §2.1.6） | 部分公共嵌套类型不符合“主要类型独立文件”的要求；需按 API 兼容策略评估，不宜批量拆。 |
| JEI 两个空 category | 若配方类型未被使用，应删除或补真实注册。 |

### 3.7 工具/文档死内容

- A tools：13 contracts + 18 data + 14 `_tags-baseline`；`_tags-baseline` 全树零引用，是死工具数据；
- A tools `data/texture-jobs-{bushes,final,rosefix,rosette,trunk,fruit-texture-jobs-rosette}.json` 等无脚本引用，属于历史任务输入；
- A tools `java/TextureAverage.java`、`TextureStats.java` 无脚本引用；
- 49 个 A wrapper + 17 个 B wrapper 是兼容层，不是实际实现；`scripts/` 下才是活动脚本；
- `_refactor/` 含写操作脚本（refactor/cleanup/move），不应随“发布分支”默认执行；应在 README/CONTRIBUTING 标注“仅重构期使用”；
- `docs/archive/` 244 份旧文档 + README 是**历史归档**，不是死内容；应冻结，不应混入当前入口；
- 当前文档中 271/272/190/219/220/233 属于历史；273/274/275 是工程三件套；
- 274 仍含过时/错误陈述（见 §5）。

---

## 4. 协议规范符合性

### 4.1 构建与资源加载（通过）

- A/B 均 `BUILD SUCCESSFUL`；
- `artifacts` 与新产物 class 逐字节一致；
- 全部 JSON 可解析；
- blockstates 结构 0 问题（莲座 12 变体、part/stick/facing 全覆盖；B 479 个 facing 全 4 向）；
- model/texture 本地引用 0 缺失（除 B 的 16 处缺失和 vanilla 误报）；
- A/B tags 引用 0 缺失；
- A worldgen 246 configured + 246 placed 闭环 0 死；
- loot table 的 block 路径无缺失（但 B 数量不足，见 4.3）；
- 无 AT 悬空引用；B mixin package/class 匹配；
- A/B mods.toml 模板与 Gradle expand 一致；
- `pack.mcmeta` 缺失：NeoForge mod 资源包不强制，构建产物同样无；记录为可接受。

### 4.2 A 数据协议

- 148 个 climate_range、145 个 food；字段与 TFC codec 一致；
- D2 的 `CLIMATE_MISSING=49` 是**误报**：TFC `ClimateRange` 的 hydration 字段有默认值（0/100），树气候只写温度合法；
- A 的 loot 481/481 与 blockstate 1:1；没有缺失；
- A 的 `_vN` 运行期贴图 **69 张**，违反 273 §2.3.3（目标 0），属命名/发布规范债；
- 6 个 `assets/tfc/models/block/crop/cabbage_age_*.json` 覆盖 TFC 模型，是有意的跨模组覆盖，需文档标注。

### 4.3 B 数据协议（存在真实缺口）

- **389/492 方块无 loot table**（P0/P1，见 §0.2）；
- **16 处缺失贴图**（P1）；
- **`food/pan_seasoned_vegetables` 无 item 模型**（P1）；
- **B 未声明 afc 依赖**（P1）；
- B 的 180 个 `data/tfc` 配方禁用文件路径全部有效；另有 2 个新增配方误放在 `data/tfc/` 命名空间（P2）；
- B 的 blockstate/loot 覆盖：`log_pile`/`burning_log_pile` 空模型靠 renderer，设计上成立但应注明；
- `verify-registry` static 模式对循环注册变体必然假失败，不能作为实际协议判据；应改为 `-FromLog` 或修正扫描器。

### 4.4 工具合同（416/416 绿，但存在盲区）

- contracts 416/416 哈希匹配、路径 0 缺失，且 `VisualAccepted/RuntimeVerified` 为 false，诚实标注了未验收；
- 但合同绑定的是**当前 TFC 占位态模型**，所以 R-1 回退不会被合同发现；
- 建议新增两个断言：
  1. crop/dead_crop/wild_crop 模型中的 `textures` 必须为 `tfcfarmingplus:` 自有命名空间（或显式白名单）；
  2. 受保护的“正式美术贴图”必须被至少一个模型引用，否则合同失败；
- `DebugValidation` 的 12 配方断言、`java-mapping.csv` 112 行 vs 123 文件、`Action.java` 坏行，说明工具自身的回归检测还不够。

### 4.5 分支自包含性（P0 风险）

按分支根目录直接使用会失败：

- A/B `build.gradle.kts`：`rootProject.projectDir.resolve("../../mods")`，分支根 `tfcfarmingplus` 的 `../..` 是仓库外部；仓库无 `mods/`；
- **无 `gradlew`**，依赖全局 Gradle 8.13；
- **`latestJar()` 用文件名字典序取最大版本**：`...-4.2.9.jar` 会排在 `...-4.2.11.jar` 之后，可能静默选旧依赖；
- B 依赖 `../tfcfarmingplus/build/libs`，但文档声明构建后删除 `build/`，新检出没有该目录；
- `tools/launch-client.ps1` 等仍按 `../..` 查找 `.tooling/`；仓库无 `.tooling/`；
- 当前文档 61 条相对链接逃逸分支根（`../moddev`、`CURRENT_DELIVERY.json`、`inventory` 等）；本地工作区有这些路径，分支根没有。

这不是“代码 bug”，但决定分支是否可交付/可复现。

### 4.6 已跑验证与限制

已通过/已运行：

- A/B 离线构建成功；
- A `audit-crop`、`audit-tree`、`audit-branch`、`audit-bush`、`audit-soil`、`audit-rosette-*`（修复后 0 findings）；
- A `verify.ps1` 修复后 0 FAIL/5 OK，止于缺少 Minecraft client asset jar；
- B `verify-container`、`verify-grain`、`verify-fruit`、`verify-in-world`、`check-boundaries`、`verify-kitchenware`、`verify-drying`、`verify-silkworm-chain`、`verify-silkworm-lifecycle`、`verify-vegetable`（修复后）通过；
- B `verify-registry` static 模式假阳性，未作为通过；
- **无游戏启动、无视觉验收、无运行时 loot/模型加载验证。**

---

## 5. 文档/计划 vs 实现偏差

### 5.1 权威角色

| 文档 | 实际角色 | 问题 |
|---|---|---|
| `docs/README.md` | 当前入口 | 仍称“资源路径分层待做”；与 275 矛盾 |
| `273` | 命名/结构需求 | 头部说 Java/包已执行；尾部仍说“没迁移/没构建”；`_vN` 目标 0 未达；编号重复/门禁脚本缺失 |
| `274` | 重构记录 | §2 仍称“资源逐字节与旧树一致、唯一差异 B mixins”（假）；§3“尚未完成”混入已完成项；PS 数 245 vs 实际 161；归档 226 vs 244/245 |
| `275` | 资源分层 | 权威；未记录 949 回退和 6 整瓜覆盖丢失；`§5 未做` 未提 `_vN` |
| `271` | 大黄交接 | 历史；绝对路径失效；旧 JAR 哈希与当前 artifacts 不符 |
| `272` | 暂停记录 | 历史；暂停后没有恢复记录；旧备份路径失效 |
| `233` | 可读性计划 | 已被 273/274 部分取代；仍说“未执行” |
| `190/219/220` | 历史记录 | 过期/绝对路径/与 archive 重复 |
| `archive/` | 历史库 | 244 份旧文档 + README；`ARCHIVE-INDEX` 只索引 226 个顶层文件，18 个 `_research/_work` 嵌套文件未入索引 |

### 5.2 关键偏差

1. **真正的计划/状态入口缺失**：主线计划在 `archive/217`、状态在 `archive/260`，但 `docs/README` 称 archive 不是当前规范；新树没有 `PLAN.md`/`STATUS.md`/`INDEX.md`。
2. **274 资源声明假**：A 资源 5,922 中 5,892 同、10 改、20 路径迁移；B 3,031 中 2,850 同、163 改、18 迁移。声明的“唯一差异是 B mixins”明显不成立。
3. **273 自相矛盾**：:5 与 :726-731 状态互斥；:701-702 的“未发现 JDK21/无 Git”已过时。
4. **构建/部署记录缺失**：271/272 的哈希是旧 JAR；274/README 只写大小，没有当前 SHA-256、部署位置、回滚点；实例 `mods/` 仍是旧 JAR。
5. **状态时序**：272 暂停后，273/274/275 与两次构建发生，但没有“用户恢复开发”的记录；文档暂停状态需修正。
6. **归档完整性表述**：归档实际 244 份旧文档 + README；`ARCHIVE-INDEX` 只索引 226 个顶层文件；18 个 `_research/_work` 文件未进索引。
7. **文档重复**：190/219/220 等同时存在于当前入口与 archive；273 存在 8 组编号重复 + 153/155/156/157 四组 md/json 同号。
8. **绝对路径**：当前文档 20 处 `D:\TFC农业重置`、archive 44 份；271/272 的备份/证据无法复核。

---

## 6. 总体开发情况

### 6.1 做得好的地方

- A/B 的 Java 包结构、命名、模块边界已明显改善；
- 无旧 `My*`、无 `com.example`，文件/类型/包一致；
- A/B 都能在正确 JDK/Gradle/依赖环境下构建；
- blockstate 变体、tags、worldgen、A loot 的静态结构完整；
- B 的几类验证脚本能真实运行，未把“静态通过”写成实机通过；
- 文档归档与当前入口已经分层，90% 旧文档有字节级副本；
- D1/D2/D3 审查能独立复现关键结论。

### 6.2 真实短板

- **内容完成度低**：A 的正式美术未接入，B 的方块美术主要是 TFC/vanilla 占位；
- **可交付性不足**：分支不可直接构建、旧 JAR 未替换、无 STATUS/DELIVERY；
- **协议缺口**：B loot 389、B 缺失贴图/物品、AFC 依赖、`_vN` 命名；
- **工具链风险**：wrapper + 旧绝对路径 + 无 gradlew + 合同只验证占位态；
- **验证缺口**：无游戏/视觉/运行时验证，B loot 与模型缺失不可能靠静态检查发现；
- **文档漂移**：当前入口与实现/归档不一致，读者无法判断哪个是权威状态。

### 6.3 质量评估（供决策）

| 维度 | 等级 | 说明 |
|---|---|---|
| 结构/可维护性 | 中上 | Java 层明显改善；工具/文档仍有债 |
| 构建可复现性 | 中下 | 依赖仓库外、无 wrapper、B 依赖 build 产物 |
| A 内容完整性 | 低 | 949 模型回退；1,130 死贴图；美术未接入 |
| B 内容完整性 | 中下 | 功能/配方多，但 loot/贴图/依赖缺口 |
| 协议正确性 | 中 | 资源加载基本对；B loot、贴图是硬缺口 |
| 文档可信度 | 中下 | 大量历史/重复/过时数字/失效路径 |
| 可交付性 | **低** | 未实机、未部署、P0 未修 |

---

## 7. 建议优先级

### 7.1 P0（在做任何游戏/发布验证之前）

1. **恢复 949 个模型的自有贴图引用**
   - 从旧 JAR/旧资源回写模型；或修正并执行 `localize-textures` 后生成；
   - 验收：`d2-model-ref-regression` 中“旧自有 → 当前 TFC”数量降为 0；
   - 重新构建 A/B 并更新 artifacts。
2. **恢复 6 个整瓜模型 `textures` 覆盖**
   - 使用旧 JAR 版本，保留 side/end/particle；
   - 验收：12 张 melon 贴图不再是死资源。
3. **修复 B 389 个方块 loot table**
   - 优先覆盖有 BlockItem 的功能方块；技术方块可显式声明无掉落；
   - 验收：blockstate 与 loot table 的 block ID 1:1（排除有意的空模型）。
4. **修复 B 16 处缺失贴图 + `pan_seasoned_vegetables` item model + AFC 依赖**
   - 面团路径改为 `*_flatbread_dough`；补 flint/cake 贴图；whole_pie 用 `pumpkin_side/top`；
   - `mods.toml` 声明 afc（required 或 optional+条件跳过）。
5. **补 DELIVERY/STATUS + 部署新 JAR**
   - 记录当前 A/B SHA-256、部署位置、回滚点、旧 JAR 备份；
   - 把 `artifacts` 新 JAR 部署到实际实例并做最小启动/日志验证。
6. **修分支可复现性**
   - 增加 `gradlew`/toolchain 说明；把 `mods` 路径改为可配置/仓库根 `mods`；B 不再依赖已删除的 `build/libs`（或保留 A build 产物）；清理 `../../` 假设。
7. **修当前文档的错误陈述**
   - 274 §2/§3；273 头部/尾部；README 结构注释；271/272 明确标“历史”；补恢复记录。

### 7.2 P1

- 修 `latestJar()` 版本选择（按语义版本/版本号排序，不要用文件名字典序）；
- 工具合同加两条断言（crop 模型必须自有命名空间；受保护贴图必须被引用）；
- B `verify-registry` 改 `-FromLog` 或修静态扫描器；
- 删/改 JEI 死 category、DebugValidation 12 断言、空 setup 方法；
- `SpeciesLookup` 接线或删除 A-jar 依赖 + 修正 javadoc/OVERRIDE；
- 清理 `_vN` 命名（69 张）；
- 文档新建 `PLAN.md`/`STATUS.md`/`INDEX.md`，上提 archive/217/218/260，归档 190/219/220/233/271/272；
- 修正 `ARCHIVE-INDEX` 到 244 份 + 18 嵌套文件；
- 统一 `java-mapping.csv`（缺 11 外移类、Action 坏行）。

### 7.3 P2

- A 106 技术方块 lang、5 个孤儿 lang；
- B 2 个空 lang、4 个缺 lang；
- A 3 个死模型、6 个低色数图；
- 2,572 个 CRLF、325 组重复文件；
- tools `_tags-baseline`、无引用 texture-jobs、TextureAverage/TextureStats；
- 49/17 个 wrapper 的清理（在外部调用迁移后）；
- `_refactor` 写脚本移出活动工具路径；
- `.gitignore` 旧 `/moddev` 路径、`textures.zip` 死引用。

---

## 8. “该废弃什么”清单

> 原则：**先分类，后删除。** 949 张 A 贴图不是垃圾；B 没有死贴图；历史 archive 不是垃圾。

### 可以归档/删除（高置信度）

- A 12 张 melon 果皮：先恢复 6 模型后再决定；恢复前可视为死文件；
- A 3 个死模型：`branch_fruit`、`cocoa_branch_fruit_{ripe,unripe}`（先确认无外部 addon）；
- A 5 个 `dead_crop.*` 孤儿 lang key；
- A 6 张低色数占位（broccoli/kale/cauliflower 等）在模型仍用 TFC 时可归档；
- tools `_tags-baseline`（14 文件，全树零引用）；
- tools `data/texture-jobs-{bushes,final,rosefix,rosette,trunk,fruit-texture-jobs-rosette}.json` 等无引用输入；
- tools `java/TextureAverage.java`、`TextureStats.java`（无脚本引用）；
- `_refactor` 写操作脚本：保留在审计/重构目录，不随默认工具入口执行；
- 旧 wrapper：外部调用迁移后再删，不要先删。

### 必须保留

- 949 张“旧 JAR 曾用”的 A 贴图：待接入，不是垃圾；
- A 其他作物/树/灌木贴图：即使当前是占位，仍是正式资产候选；
- B 自有 57 张 item 贴图：全部被模型引用；
- `docs/archive` 244 份旧文档 + README：历史证据，冻结；
- `SpeciesLookup`：先做 API 决策，不要按“0 引用”直接删；
- `FarmingCrops` 348 个公开注册字段：可能是 A→B/外部 API，按契约处理。

---

## 9. 结论

**当前 `mod_rebuild` 是“结构重构 + 构建基线”成功的开发树，但不是可交付、可验收、可复现的完整版本。**

- 代码层：Java 结构/命名/构建通过，A/B 可编译；
- 内容层：A 的正式美术大面积回退为 TFC 占位，B 的功能方块美术是借用占位且缺 loot/贴图；
- 工程层：分支路径、依赖、部署、STATUS/DELIVERY 未闭环；
- 文档层：当前入口与归档/计划/状态互相矛盾，不能作为唯一权威；
- 验证层：没有游戏运行与视觉验收，静态检查无法替代。

建议顺序：**P0 美术/ loot/交付/可复现性 → 最小实机加载与视觉验收 → 文档 PLAN/STATUS/INDEX 重构 → 273 剩余工程项 → 新功能。**

---

## 10. 取证与复现

- D1 文档：`docs/audit/D1-docs-and-plans.md`
- D2 资源：`docs/audit/D2-resources-and-protocols.md`
- D3 Java/工具：`docs/audit/D3-java-tools-contracts.md`
- Lead 资源扫描：`docs/audit/lead-asset-scan.json`、`lead-dead-assets.json`（工作区）
- D2 证据：`docs/audit/d2-*.csv/txt`、`d2-index.json`（工作区）
- D3 证据：`docs/audit/D3-*.csv/log`（工作区）
- 构建日志：`%TEMP%\tfcfarmingplus-build.log`、`fcagricultureplus-build*.log`
- 关键复现命令：

```powershell
# A/B 构建（JDK21）
$env:JAVA_HOME="$env:USERPROFILE\.gradle\jdks\eclipse_adoptium-21-amd64-windows.2"
$env:Path="$env:JAVA_HOME\bin;$env:Path"
cd mod_rebuild\tfcfarmingplus; gradle build --console=plain --offline
cd ..\tfcagricultureplus; gradle build --console=plain --offline

# A 关键审计（修复后）
.\tools\audit-crop-contracts.ps1
.\tools\audit-tree-contracts.ps1
.\tools\audit-branch-fruit-contracts.ps1
.\tools\audit-bush-contracts.ps1
.\tools\audit-soil-contracts.ps1

# B 关键验证（部分）
.\tools\verify-container-contract.ps1
.\tools\verify-grain-food-processing.ps1
.\tools\verify-vegetable-beverage-processing.ps1
```

> 注：本报告只描述审查结果；P0 内容修复未在本轮执行。审查期间只修复了 4 处工具断链（见 §1.4），新增了本报告与 audit 索引，未修改 Java、资源、构建配置或既有文档正文。
