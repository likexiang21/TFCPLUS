# 273 命名与文件结构整理需求

> 记录日期：2026-10-27
> 状态：**需求与执行计划**；本文只定义整理要求，尚未迁移源码、资源、工具或历史目录。
> 新树执行记录：[274 号重构记录](274-rebuild-log-20261027.md)。本目录中的 273 是重构前需求，实际 Java/包结构已按本要求执行；变量级清理与资源路径分层仍未完成。
> 关联：[233 号可读性计划](233-final-code-readability-and-structure-plan-20261024.md)、[271 号大黄交接](271-ar4ag-rhubarb-native16-display-20261027.md)、[272 号暂停记录](272-github-snapshot-and-development-pause-20261027.md)、[CURRENT_DELIVERY.json](../../CURRENT_DELIVERY.json)。
> 适用范围：A `tfcfarmingplus`、B `tfcagricultureplus`、资源、`tools`、`docs`、`inventory`、根级交接文件。
> 硬边界：**mod id、注册 ID、资源标识符、NBT/序列化字段、旧存档兼容不因整理而改变**。
> ⚠️ 资源目录修正：**blockstate 文件路径与注册 ID 绑定**，不能仅按目录重排；§3.4 中的 blockstates 分类是模型/贴图的目标分类，blockstates 迁移必须与注册 ID 迁移一起设计，当前新树未执行。

---

## 0. 目的与成功判据

整理的目标不是“看起来整齐”，而是让检查、交接和后续施工可预测：

1. 任意一项内容都能按 **`SLICE_ID → 文档 → 证据目录 → 合同 → JAR 哈希`** 串起来；
2. 任意一个方块 ID 都能按固定路径找到 `blockstate / model / texture`；
3. 新脚本、新文档、新证据目录不再出现 `My*`、`batch2`、`final`、`rev7`、`_v1` 之类历史名；
4. 源码目录、资源目录、工具目录、文档目录各自只有一个权威入口；
5. 整理前后行为、注册 ID、资源 ID 和旧存档兼容保持一致。

**本文完成后的最终判据**：

- 活动 Java 源码中 `My*` 文件/类为 **0**；
- `BlockBlock` 等重复词为 **0**；
- 非白名单短变量/缩写变量为 **0**；
- 活动工具中 `batch/rev/final/old/new/temp` 主名为 **0**；
- 文档编号重复为 **0**，且存在 `docs/INDEX.md`；
- 运行时资源名带 `_vN` 的为 **0**；
- `blockstates` / `models/block` / `textures/block` 分类镜像；
- `verify-naming.ps1`、`verify-links.ps1`、`verify-layout.ps1` 全部通过；
- A/B 构建与现有 verify 流程通过，且没有改动注册 ID/NBT。

---

## 1. 当前审计事实（本需求的输入）

### 1.1 Java 文件/类

| 项目 | 当前值 |
|---|---:|
| Java 文件 / 顶层类型 | **112 / 112**（文件与类型全部同名，包路径与目录一致） |
| 以 `My` 开头的类/文件 | **43**（A 32 / B 11，占 38%） |
| A/B 跨模块同名简单类 | **4 组**：`MyBlocks`、`MyItems`、`MyBlockEntities`、`MyCreativeTab` |
| `BlockBlock` 重复词 | **2 个文件 + 1 个嵌套类**：`KnifeBlockBlockEntity`、`KnifeBlockBlockEntityRenderer`、`KnifeBlockBlock` |
| 物品类缺 `Item` 后缀 | **1**：`SawdustSoupBowl` |
| 泛化顶层/嵌套类型 | `Tree`、`Kind`、`Input`×4、`SoundInstance`、`Action`、`Motion`、`Serializer`×7 |
| 高置信度问题变量/字段/方法 | **30+**（详见 §4.2/§4.3） |

A 的示例：[MyCrops.java](../tfcfarmingplus/src/main/java/io/github/likexiang21/tfcplus/farming/common/crop/FarmingCrops.java)（约 1,148 行）、[MySpeciesApi.java](../tfcfarmingplus/src/main/java/io/github/likexiang21/tfcplus/farming/common/api/SpeciesLookup.java)、[MySeasonalPlantFix.java](../tfcfarmingplus/src/main/java/io/github/likexiang21/tfcplus/farming/common/support/SeasonalPlantTimers.java)。

B 的示例：[MyBlocks.java](../tfcagricultureplus/src/main/java/io/github/likexiang21/tfcplus/agriculture/common/registry/AgricultureBlocks.java)（约 802 行，内嵌 4 个方块类）、[MyTags.java](../tfcagricultureplus/src/main/java/io/github/likexiang21/tfcplus/agriculture/common/registry/AgricultureTags.java)、[DebugValidation.java](../tfcagricultureplus/src/main/java/io/github/likexiang21/tfcplus/agriculture/common/debug/DebugValidation.java)。

### 1.2 变量/字段/方法

典型问题：

- `remembered`、`TEA`、`TAG`、`checks`、`en`、`donor`、`out`、`be`、`s`、`h`、`m`、`n`、`p`、`t`、`old`、`fed`、`at`、`cl`、`ref`、`ok`；
- `Tree.en`、`Tree.donor` 这种缩写 record 组件；
- `KnifeBlockBlockEntity.kind`、`KitchenStorageBlock.id/kind`、`Action.key` 等过于泛化的字段；
- `MyDebugCommands.say`、`DebugValidation.run/check/item/board/use/place/drops` 等过于泛化的方法名；
- `SPECIES_BLOCKS` / `SPECIES_NAMES` 这种“可变缓存却用常量名”的字段。

### 1.3 工具、文档、证据、资源

| 项目 | 当前值/问题 |
|---|---|
| A `tools` | 116 个文件：66 `.ps1` + 31 `.json` + 4 `.java` + 1 `.deprecated`，全部平铺 |
| A 工具坏名 | `gen-batch2`、`gen-batch2x-wild`、`fix-batch1-food-models`、`fix-wild-single-placed`、`finalize`、`polish-book`、`TexAvg` |
| B `tools` | 18 `.ps1` + 1 `.py`，相对整齐 |
| 文档重复编号 | **8 组**：86、106、115、116、117、121、124、125 |
| 文档索引 | [旧文档索引](../../moddev/docs/00-README.md) 仍描述 `tfcflora`、132 作物、TFC 4.2.10；根级 [HANDOVER.md](../../HANDOVER.md)、[INBOX.md](../../INBOX.md)、[AGENTS.md](../../AGENTS.md#L574) 的进度数字过时 |
| `inventory` | 53 个目录；`api-dump` 无日期；3 个 `*-before` 与主题目录并列；2 个 `swiss-*` 缩写 |
| 运行时贴图 | **25 张**带 `_v1/_v2`（19 个 `_v1`、6 个 `_v2`） |
| 资源分类 | A：`models/block/plant` 对 `textures/block/fruit_tree` 不镜像；B：`blockstates/counter_cabinet` 对 `models/block/kitchen_storage/counter_cabinet` 不镜像 |
| 跨命名空间 | A 217 个、B 201 个，合计 418；与 [OVERRIDE-REGISTRY.md](../tfcagricultureplus/OVERRIDE-REGISTRY.md) 一致（这部分已有台账，整理时保留） |

---

## 2. 硬性命名规范

### 2.1 Java 包、类、文件

1. **包名全小写**，按职责分段，不使用 `My`、`Example`、`expansion` 这类占位词。
2. **一个文件一个顶层 public 类型**；文件名 = 类型名。
3. **禁止 `My` 前缀**（文件、类、接口、枚举、record 全部禁止）。
4. **禁止 `BlockBlock` / `ItemItem` / `EntityEntity`** 等重复词。
5. **禁止泛化顶层名**：`Tree`、`Kind`、`Input`、`Action`、`Motion`、`SoundInstance`。公共类型必须带领域限定，例如 `FruitTreeDefinition`、`StorageKind`、`CuttingBoardInput`、`InWorldAction`、`SoundSpec`。
6. **公共类型顶层化**；嵌套类型只允许用于私有实现细节。
7. **模块前缀规则**：
   - A 的注册类、共享类、易与 TFC 重名的类用 `Farming` 前缀；
   - B 的注册类、共享类用 `Agriculture` 前缀；
   - 普通内容类用“领域 + 角色”，不强制再加模块前缀，例如 `CookingPanBlock`、`DryingRackBlock`。
8. **角色后缀统一**：`Block`、`BlockEntity`、`Item`、`Menu`、`Screen`、`Renderer`、`Recipe`、`Serializer`、`Events`、`Interactions`、`Rules`、`Definition`。
9. **禁止历史名**：`Fix`、`Old`、`New`、`BatchN`、`RevN`、`Temp`、`Final` 不作为活动类名。
10. **包名必须与 mod 身份一致**：B 不得继续放在 `com.example.tfcfarmingplus.expansion` 下；最终根包 `<group>` 在施工前由用户确认（例如 `io.github.likexiang21.tfcplus.farming` / `.agriculture`，或项目自有域名）。

### 2.2 变量、字段、方法

1. 变量/字段 lowerCamelCase；常量 UPPER_SNAKE_CASE；可变缓存**不得**用常量命名。
2. 方法名用动词或 `is/has/can/get/set/on/register/create` 等前缀，禁止 `say`、`run`、`check`、`item`、`board`、`use`、`place`、`drops` 这种脱离上下文的名字。
3. **允许保留的短名/框架名**：
   ```text
   level  pos  state  stack  player  hit  ctx  bus  id  age
   x  y  z  i  j  k  dx  dy  dz（仅渲染/数学偏移）
   ```
4. 其余 1~2 字母、`out/ref/ok/be/at/cl/s/h/m/n/p/t/old/fed/en/donor/loc/main/board/food/kind/tag`（无限定）一律改名。
5. 字段带业务限定：`storageId`、`storageKind`、`pieceKind`、`toolTag`、`serializedName`；不用裸 `id/kind/tag/key` 作为字段名。
6. record 组件用完整词：`englishName`、`textureDonor`，不用 `en/donor`。
7. 禁止可变 `static` 字段使用 UPPER_SNAKE_CASE；`speciesBlocks` 这类缓存用 lowerCamel。
8. `@Override` 的方法名、框架回调签名、TFC/Minecraft 固定 API 名不因整理而改。

### 2.3 资源命名

1. 资源 ID/namespace 不变；只整理路径与文件名。
2. 文件名全小写 snake_case；目录全小写；不得有空格、中文、大写（`META-INF` 除外）。
3. **运行时资源不带版本后缀**；`_v1/_v2` 只允许出现在 `inventory` 草稿/归档中。
4. 分类目录三处镜像：
   ```text
   blockstates/<category>/<id>.json
   models/block/<category>/<id>.json
   textures/block/<category>/<id>.png
   ```
5. A 的分类统一为：`crop`、`wild_crop`、`dead_crop`、`fruit_tree`、`bush`、`branch_fruit`；不再用含义重叠的 `plant`。
6. B 的厨房家具统一为：`kitchen_storage/<furniture>/`，blockstate 与 model 目录名完全一致。
7. 贴图命名统一为：
   - `<species>_age_<n>[_<organ>].png`
   - `<species>_<organ>_<state>.png`
   - `<species>_<part>_<top|bottom>.png`
8. 新增资源必须同时提供模型/方块状态引用与来源记录；不能只落一张 PNG。

### 2.4 工具命名

1. 活动脚本：`动词-对象[-范围].ps1`。
   - `generate-*`、`audit-*`、`verify-*`、`export-*`、`import-*`、`repair-*`。
2. 禁止活动目录出现 `batch/rev/final/old/new/temp/tmp` 主名。
3. 历史脚本进入 `tools/archive/YYYYMMDD-<旧名>.ps1`。
4. 工具目录按类型分层：
   ```text
   tools/
   ├── scripts/{generate,audit,verify}/
   ├── contracts/
   ├── data/
   ├── java/
   ├── archive/
   └── README.md
   ```
5. `tools/README.md` 必须列出入口、输入、输出、检查级别、最后验证。
6. `.ps1` 保持 UTF-8 BOM；改完做 `[Parser]::ParseFile` 语法检查。

### 2.5 文档命名

1. 新文档：`<NNN>-<stage>-<topic>-<YYYYMMDD>.md`；编号唯一，不复用。
2. 本文为 **273**；后续从 274 起追加；已有重复编号用 `b` 后缀别名，不重排历史。
3. 禁止旧项目名 `tfcflora`、旧基线 `TFC 4.2.10`、旧数字（132/86/77 等）作为当前状态。
4. 每份交接/修复文档顶部固定状态块：
   ```text
   > 编号：
   > 阶段：
   > 状态：static-delivered / visual-pending / runtime-pending
   > 证据：
   > 构建：
   ```
5. 历史文档保留原貌；被替代的文档通过 `docs/INDEX.md` 标 `superseded`，不删除内容。

### 2.6 证据目录命名

1. 新切片：`inventory/slices/<YYYYMMDD>-<stage>-<topic>/`。
2. 固定子目录：
   ```text
   README.md  plan.md  inputs/  before/  drafts/  outputs/  checks/  final.json  delivery.json
   ```
3. `README.md` 必须回答：Slice、Doc、改动文件、静态/视觉/实机状态、证据、回滚。
4. 历史证据目录不强制搬迁；若含绝对路径/清单，保持原位并在 `inventory/INDEX.md` 标 `legacy`。
5. `-before` 快照不要与当前切片并列；新目录使用 `before/` 子目录，旧目录进 `inventory/archive/`。

---

## 3. 目标文件结构

### 3.1 根目录与 `moddev/`

```text
<workspace>/
├── README.md                  # 当前入口
├── AGENTS.md                  # 保留根目录，自动加载；只更新进度锚点
├── CURRENT_DELIVERY.json
├── SOURCE_MANIFEST.json
├── DEPENDENCY_LOCK.json
├── DEVELOPMENT_RULES.md
├── moddev/
│   ├── README.md              # 构建/验证/部署/打包入口
│   ├── docs/
│   ├── inventory/
│   ├── tools/
│   ├── tfcfarmingplus/
│   └── tfcagricultureplus/
├── deliverables/
└── mods/ ...                  # 运行环境，不属于源码整理范围
```

根级旧文件处理：

| 文件 | 处理 |
|---|---|
| `README.md` | 保留并更新入口 |
| `AGENTS.md` | 保留根路径；只更新 §四进度锚点，不搬移 |
| `WORKSPACE_README.md` | 合并到新 `docs/README.md` 后移入 `docs/archive/` |
| `HANDOVER.md` | 移入 `docs/archive/20261005-handover.md` 或更新为当前交接 |
| `INBOX.md` | 移入 `docs/archive/20260923-inbox.md` 或更新 |
| `CURRENT_DELIVERY.json` / `SOURCE_MANIFEST.json` / `DEPENDENCY_LOCK.json` | 保留根目录 |
| `.probe/`、`px/`、`de_moddev` 等旧目录 | 保留或移入 `reference/archive`；**不得按无引用删除** |

### 3.2 A 模块 Java 包

```text
com.<group>.tfcfarmingplus
├── TFCFarmingPlus.java
├── client/
│   └── TFCFarmingPlusClient.java
├── common/
│   ├── block/
│   │   ├── FarmingBerryBushBlock.java
│   │   ├── FarmingClimbingCropBlock.java
│   │   ├── FarmingCropBlock.java
│   │   ├── FarmingDoubleCropBlock.java
│   │   ├── FarmingFloodedCropBlock.java
│   │   ├── FarmingFruitingBranchBlock.java
│   │   ├── FarmingFruitTreeLeavesBlock.java
│   │   ├── FarmingFruitTreeSaplingBlock.java
│   │   ├── FarmingGrowingFruitTreeBranchBlock.java
│   │   ├── FarmingPickableCropBlock.java
│   │   ├── FarmingSpreadingBushBlock.java
│   │   ├── FarmingSpreadingCaneBlock.java
│   │   ├── FarmingSpreadingCropBlock.java
│   │   └── RosetteCropBlock.java
│   ├── blockentity/
│   │   ├── FarmingBerryBushBlockEntity.java
│   │   └── FarmingDecayingBlockEntity.java
│   ├── item/
│   │   ├── FarmingBushBlockItem.java
│   │   ├── FarmingFruitTreeSaplingItem.java
│   │   └── FarmingSeedItem.java
│   ├── registry/
│   │   ├── FarmingBlocks.java
│   │   ├── FarmingItems.java
│   │   ├── FarmingBlockEntities.java
│   │   ├── FarmingCreativeTab.java
│   │   └── FarmingClimateRanges.java
│   ├── crop/
│   │   ├── FarmingCrops.java
│   │   ├── CropDefinition.java
│   │   ├── LeafyCrops.java
│   │   ├── GrainCrops.java
│   │   ├── RootCrops.java
│   │   ├── FruitCrops.java
│   │   └── ...
│   ├── tree/
│   │   ├── FarmingFruitTrees.java
│   │   └── FarmingBranchFruits.java
│   ├── support/
│   │   └── SeasonalPlantTimers.java
│   ├── api/
│   │   └── SpeciesLookup.java        # 仅当保留 MySpeciesApi 时
│   └── debug/
│       ├── FarmingDebugCommands.java
│       └── FastGrow.java
```

### 3.3 B 模块 Java 包

```text
com.<group>.tfcagricultureplus
├── TFCAgriculturePlus.java
├── client/
│   ├── TFCAgriculturePlusClient.java
│   ├── renderer/
│   └── screen/
├── common/
│   ├── block/
│   │   ├── CookingPanBlock.java
│   │   ├── CuttingBoardBlock.java
│   │   ├── DryingRackBlock.java
│   │   ├── KnifeRackBlock.java
│   │   ├── KitchenStorageBlock.java
│   │   └── ...
│   ├── blockentity/
│   ├── item/
│   │   ├── AdultSilkwormItem.java
│   │   └── SawdustSoupBowlItem.java
│   ├── interaction/
│   │   ├── CuttingBoardInteractions.java
│   │   ├── CuttingBoardLeftClickHandler.java
│   │   ├── DoughFormingInteractions.java
│   │   └── ...
│   ├── kitchen/
│   ├── silkworm/
│   ├── timber/
│   ├── recipe/
│   │   ├── AgricultureRecipeTypes.java
│   │   ├── AgricultureRecipeSerializers.java
│   │   └── inworld/
│   ├── registry/
│   │   ├── AgricultureBlocks.java
│   │   ├── AgricultureItems.java
│   │   ├── AgricultureBlockEntities.java
│   │   ├── AgricultureCreativeTab.java
│   │   ├── AgricultureTags.java
│   │   ├── AgricultureMenuTypes.java
│   │   ├── AgricultureFoodTraits.java
│   │   └── WoodworkingSounds.java
│   └── debug/
│       └── DebugValidation.java
├── compat/jei/
└── mixin/
```

### 3.4 资源目录

A：

```text
assets/tfcfarmingplus/
├── blockstates/
│   ├── crop/
│   ├── wild_crop/
│   ├── dead_crop/
│   ├── fruit_tree/
│   ├── bush/
│   └── branch_fruit/
├── models/block/          # 与 blockstates 同名分类
├── models/item/
│   ├── food/
│   ├── seeds/
│   ├── fiber/
│   ├── plant/
│   └── wild_crop/
├── textures/block/        # 与 blockstates 同名分类
└── lang/
```

B：

```text
assets/tfcagricultureplus/
├── blockstates/
│   ├── cutting_board/
│   ├── log_cutting_board/
│   ├── knife_block/
│   ├── mortar/
│   ├── drying_rack/
│   ├── kitchen_storage/
│   │   ├── counter_cabinet/
│   │   ├── food_display/
│   │   ├── fruit_bowl/
│   │   ├── half_cabinet/
│   │   ├── sink_cabinet/
│   │   └── spice_rack/
│   ├── timber/
│   └── ...
├── models/block/          # 与 blockstates 完全镜像
├── textures/block/        # 与上面完全镜像
└── models/item/
```

给定方块 ID，应能机械推出：

```text
blockstates/<category>/<id>.json
models/block/<category>/<id>.json
textures/block/<category>/<id>.png
```

### 3.5 工具目录

```text
moddev/
├── tools/
│   ├── README.md
│   ├── launch/
│   ├── verify/
│   ├── refs/
│   └── inspect/
├── tfcfarmingplus/tools/
│   ├── README.md
│   ├── scripts/
│   │   ├── generate/
│   │   ├── audit/
│   │   └── verify/
│   ├── contracts/
│   ├── data/
│   ├── java/
│   └── archive/
└── tfcagricultureplus/tools/
    ├── README.md
    ├── scripts/
    ├── contracts/
    ├── data/
    └── archive/
```

### 3.6 文档目录

```text
moddev/docs/
├── README.md              # 当前入口/索引说明
├── INDEX.md               # 编号、标题、日期、阶段、状态、证据、替代关系
├── STATUS.md              # 当前版本/构建/检查/下一片
├── reference/             # 10-... 等长期参考
├── plans/                 # 117、217、233、273 等
├── handoffs/              # 271、272 等
├── rounds/                # 100-199 历史轮次（冻结）
├── ar/                    # 200-299 农业阶段
├── archive/               # 旧索引、_work、_research、被替代文档
└── _templates/
```

**迁移策略**：

- 第一阶段保持现有文件平铺，只加 `INDEX.md`、`STATUS.md`，避免 225 份文档一次性断链；
- 第二阶段处理 8 组重复编号（保留主号，另一份加 `b` 后缀并记录别名）；
- 第三阶段在链接检查器就绪后，再按类别移动到 `reference/plans/handoffs/rounds/archive`。

### 3.7 `inventory` 目录

```text
moddev/inventory/
├── README.md              # 证据索引说明
├── INDEX.md               # 日期、SLICE_ID、主题、文档、静态/视觉/实机、路径
├── reference/             # api-dump 等参考数据
├── slices/                # 新切片，按 §2.6 模板
└── archive/               # 旧 -before 快照
```

历史目录不强制搬迁；含绝对路径/清单的旧证据保持原位并在 `INDEX.md` 标 `legacy`。

---

## 4. 全量改名映射

### 4.1 43 个 `My*` 类/文件

规则：A 用 `Farming` 前缀，B 用 `Agriculture` 前缀；普通内容类优先“领域 + 角色”。

```text
A（32）
MyBlockEntities                    -> FarmingBlockEntities
MyBlocks                           -> FarmingBlocks
MyBranchFruits                     -> FarmingBranchFruits
MyBushes                           -> FarmingBushes
MyClimateRanges                    -> FarmingClimateRanges
MyCreativeTab                      -> FarmingCreativeTab
MyCrops                            -> FarmingCrops
MyDebugCommands                    -> FarmingDebugCommands
MyFruitTrees                       -> FarmingFruitTrees
MyItems                            -> FarmingItems
MySpeciesApi                       -> SpeciesLookup（保留时；否则归档）
MyWildCrops                        -> FarmingWildCrops
MyBerryBushBlockEntity             -> FarmingBerryBushBlockEntity
MyDecayingBlockEntity              -> FarmingDecayingBlockEntity
MyBerryBushBlock                   -> FarmingBerryBushBlock
MyClimbingCropBlock                -> FarmingClimbingCropBlock
MyCropBlock                        -> FarmingCropBlock
MyDecayingBlock                    -> FarmingDecayingBlock
MyDoubleCropBlock                  -> FarmingDoubleCropBlock
MyFloodedCropBlock                 -> FarmingFloodedCropBlock
MyFruitingBranchBlock              -> FarmingFruitingBranchBlock
MyFruitTreeLeavesBlock             -> FarmingFruitTreeLeavesBlock
MyFruitTreeSaplingBlock            -> FarmingFruitTreeSaplingBlock
MyGrowingFruitTreeBranchBlock      -> FarmingGrowingFruitTreeBranchBlock
MyPickableCropBlock                -> FarmingPickableCropBlock
MySeasonalPlantFix                 -> SeasonalPlantTimers
MySpreadingBushBlock               -> FarmingSpreadingBushBlock
MySpreadingCaneBlock               -> FarmingSpreadingCaneBlock
MySpreadingCropBlock               -> FarmingSpreadingCropBlock
MyBushBlockItem                    -> FarmingBushBlockItem
MyFruitTreeSaplingItem             -> FarmingFruitTreeSaplingItem
MySeedItem                         -> FarmingSeedItem

B（11）
MyBlockEntities                    -> AgricultureBlockEntities
MyBlocks                           -> AgricultureBlocks
MyCreativeTab                      -> AgricultureCreativeTab
MyFoodTraits                       -> AgricultureFoodTraits
MyItems                            -> AgricultureItems
MyJeiPlugin                        -> AgricultureJeiPlugin
MyMenuTypes                        -> AgricultureMenuTypes
MyRecipeSerializers                -> AgricultureRecipeSerializers
MyRecipeTypes                      -> AgricultureRecipeTypes
MyTags                             -> AgricultureTags
MyWoodworkingSounds                -> WoodworkingSounds
```

### 4.2 变量/字段

| 位置 | 现名 | 新名 |
|---|---|---|
| `MySpeciesApi` | `SPECIES_BLOCKS` / `SPECIES_NAMES` | `speciesBlocks` / `speciesNames` |
| `MyDebugCommands` | `remembered` | `lastPlacedPosition` |
| `MyDebugCommands` | `TAG` | `DEBUG_PREFIX` |
| `MyBushes` | `TEA` | `TEA_LIFECYCLE` |
| `MyFruitTrees.Tree` | `en` / `donor` | `englishName` / `textureDonor` |
| `FarmingFruitTrees` | `t` / `n` / `cl` / `h` / `out` | `treeDefinition` / `speciesName` / `climateReference` / `holder` / `blocks` |
| `FarmingBlockEntities` | `a` / `out` / `at` | `array` / `result` / `offset` |
| `FarmingDebugCommands` | `p` / `at` / `be` / `ref` / `ok` / `m` | `candidatePos` / `positionLabel` / `blockEntity` / `climateReference` / `canGrow` / `hydrationMethod` |
| `FarmingFruitingBranchBlock` | `now` | `currentState` |
| `FarmingFruitTreeLeavesBlock` | `dx` / `dz` | `offsetX` / `offsetZ`（渲染数学可酌情保留） |
| B `AgricultureItems` | `h` | `holder` |
| B `AgricultureBlocks` | `out` / `be` / `s` / `k` / `c` / `m` | `result` / `blockEntity` / `stack` / `knifeBlockEntity` / `cuttingBoardEntity` / `mortarBlockEntity` |
| `KnifeRackBlockEntity` | `s` | `stack` |
| `TimberPileBlock` | `y` | `yOffset` |
| `TimberPieceBlock` | `kind` | `pieceKind` |
| `KitchenStorageBlock` | `id` / `kind` | `storageId` / `storageKind` |
| `KitchenStorageBlock.Kind` | `Kind` | `StorageKind` |
| `InWorldAction` | `key` | `serializedName` |
| `InWorldComponents.Tool` | `key` / `tag` | `serializedName` / `toolTag` |
| `SilkwormData` | `tag` | `compoundTag` |
| `SilkwormRackBlockEntity` | `fed` / `old` | `feedSucceeded` / `previousItems` |
| `DryingRackBlockEntity` | `now` | `currentTick` |
| `DebugValidation` | `checks` | `passedChecks` |
| `MyTags` | `NONE` | 删除（无引用占位） |

### 4.3 方法名

| 位置 | 现名 | 新名 |
|---|---|---|
| `FarmingDebugCommands` | `say` | `sendMessage` |
| `DebugValidation` | `run` | `runChecks` |
| `DebugValidation` | `check` | `require` |
| `DebugValidation` | `item` | `createItemStack` |
| `DebugValidation` | `board` | `getCuttingBoard` |
| `DebugValidation` | `use` | `simulateUse` |
| `DebugValidation` | `place` | `simulatePlace` |
| `DebugValidation` | `drops` | `countDrops` |
| `SilkwormData` | `day` | `getCurrentDay` |
| `KitchenStorageBlock` | `id()` / `kind()` | `storageId()` / `storageKind()` |

保留不改：`register`、`init`、`create`、`tick`、`randomTick`、`useItemOn`、`die`，以及 `TimberPileBlockEntity.get(int slot)` 等重写方法。

### 4.4 其他文件/类名

| 现名 | 新名 |
|---|---|
| `KnifeBlockBlockEntity.java` | `KnifeRackBlockEntity.java` |
| `KnifeBlockBlockEntityRenderer.java` | `KnifeRackBlockEntityRenderer.java` |
| `SawdustSoupBowl.java` | `SawdustSoupBowlItem.java` |
| `TimberPileRenderer.java` | `TimberPileBlockEntityRenderer.java` |
| `record Tree` | `record FruitTreeDefinition` |
| `enum Kind` | `enum StorageKind` |
| `record Input` ×4 | `CuttingBoardInput` / `MeltingInput` / `PanInput` / `InWorldInput` |
| `record SoundInstance` | `record SoundSpec` |
| `Action` / `Motion` | `InWorldAction` / `InWorldMotion` |

### 4.5 文档重复编号

| 编号 | 保留主号 | 改名 |
|---|---|---|
| 86 | `86-texture-drawing-playbook.md` | `86b-texture-redraw-mid-session-summary.md` |
| 106 | `106-cabbage-leafball-redraw.md` | `106b-round48-summary-and-handoff.md` |
| 115 | `115-stick-pole-exact-fix-round49.md` | `115b-generator-divergence-and-shadow-run.md` |
| 116 | `116-round49-autonomous-redraw-and-tool-lessons.md` | `116b-stability-and-completeness-audit.md` |
| 117 | `117-agriculture-redesign-plan.md` | `117b-round49-acceptance-report-20260928.md` |
| 121 | `121-texture-rework-workorder.md` | `121b-session-handoff-texture-production.md` |
| 124 | `124-cereal-top-report.md` | `124b-tree-leaves-batch4.md` |
| 125 | `125-mature-organ-3-report.md` | `125b-wild-dead-5-group-report.md` |

补充：

- `00-README.md` 更新为当前索引，或移入 `docs/archive/`；
- `232-农业完善阶段总结-20261024.txt` → `232-agriculture-phase-summary-20261024.md`；
- 新文档从 274 起编号；不再复用。

### 4.6 工具/证据目录

| 现名 | 新名方向 |
|---|---|
| `gen-batch2.ps1` | 按职责，如 `generate-vegetable-crop-models.ps1` |
| `gen-batch2x-wild.ps1` | `generate-wild-crop-patches.ps1` |
| `fix-batch1-food-models.ps1` | `repair-food-item-models.ps1` |
| `fix-wild-single-placed.ps1` | `repair-wild-crop-placement.ps1` |
| `finalize.ps1` | 合并进具体收尾脚本，或 `finalize-resource-set.ps1` |
| `polish-book.ps1` | `polish-patchouli-book.ps1` |
| `TexAvg.java` | `TextureAverage.java` |
| `gen-trunk-fruits.ps1.deprecated-20260923` | `tools/archive/20260923-generate-trunk-fruit-models.ps1` |
| `inventory/api-dump` | `inventory/reference/api-dump` |
| `*-before` | 对应主题的 `before/` 或 `inventory/archive/` |
| `swiss-display-*` / `swiss-harvest-*` | `swiss-chard-display-*` / `swiss-chard-harvest-*` |

### 4.7 资源路径

- A：`blockstates/plant`、`models/block/plant` 与 `textures/block/fruit_tree` 统一为 `fruit_tree`/`bush`/`branch_fruit`；例如 `almond_leaves` 三个路径使用同一分类。
- B：`blockstates/counter_cabinet` 等 6 类厨房家具移入 `blockstates/kitchen_storage/<furniture>/`，与模型目录镜像。
- 25 张 `_vN` 运行时贴图去掉版本后缀；版本试作进 `inventory/<slice>/drafts/`。
- 资源 ID、namespace、模型/方块状态引用的最终 ID 不变。

---

## 5. 迁移批次

### Batch 0：冻结与基线

- 备份 A/B 源码、资源、tools、docs、inventory；
- 生成 `docs/233a-rename-map.csv`（kind/old/new/reason/references/status）；
- 生成当前文件清单、链接清单、资源引用清单；
- 写只读 `verify-naming.ps1`、`verify-links.ps1`、`verify-layout.ps1`，先输出当前违规数，不改文件。

### Batch 1：检查入口与过期元信息（低风险）

- 新建 `docs/README.md`、`docs/INDEX.md`、`docs/STATUS.md`、`inventory/INDEX.md`、`tools/README.md`、模板；
- 更新 `00-README`、`AGENTS` 进度锚点、`HANDOVER`、`INBOX` 的当前入口/数字；
- 处理 8 组文档重复编号的别名；
- **不移动代码/资源**；跑链接检查。

### Batch 2：变量/字段/方法改名（低风险）

- 按 §4.2/§4.3 改；不动文件名、不建包；
- 编译 A、B；跑 `verify.ps1`、`verify-registry.ps1`、`healthcheck.ps1`；
- 行为、ID、NBT 不得变化。

### Batch 3：类/文件改名（中高风险）

- 按 §4.1/§4.4 改 43 个 `My*` 及其他文件；
- 同步 import、日志/调试字符串、文档、脚本中的类名引用；
- 每批编译 A、B；跑 verify；记录 JAR 新哈希。

### Batch 4：包名迁移（高风险）

- 确定 `<group>` 根包；A → `com.<group>.tfcfarmingplus`，B → `com.<group>.tfcagricultureplus`；
- 同步 `build.gradle.kts` 的 `group`、mixin 配置、B 对 A 的 import、文档/脚本；
- 注册 ID、资源 ID、NBT 不变；构建 A → B，跑完整静态检查。

### Batch 5：Java 结构拆分（行为保持）

- B `common` 29 个文件按 `block/item/interaction/kitchen/silkworm/timber/registry/debug` 拆分；
- B `MyBlocks` 内嵌 4 个方块类外移；
- A `MyCrops`/`MyFruitTrees`/`MyBushes` 按注册/数据/形态拆分；
- 统一 A/B 注册初始化模式；
- 每批构建 + verify。

### Batch 6：资源路径迁移（最高风险）

- 先出完整旧→新路径映射；
- 更新 blockstate/model JSON、合同、保护哈希、脚本、文档；
- 保证 blockstates/models/textures 三处镜像；
- 跑 `verify.ps1`、资源引用检查、16×16 检查，并抽样 2D/3D 渲染；
- 不要只改一边目录。

### Batch 7：工具/文档/证据目录迁移

- 按 §3.5–§3.7 拆 tools、建 docs 分类、inventory slices/reference/archive；
- 更新 Markdown 链接、脚本路径、索引；
- 历史证据目录有绝对路径的保持原位并标 `legacy`；
- 跑链接检查、脚本解析、最终 verify。

---

## 6. 检查门禁

新增 `moddev/tools/verify/verify-naming.ps1`，并纳入 `healthcheck`：

| 规则 | 失败条件 |
|---|---|
| Java 文件/顶层类型 | 匹配 `^My` |
| 文件/类型一致性 | 文件名 ≠ 顶层 public 类型 |
| 重复词 | 类名匹配 `BlockBlock|ItemItem|EntityEntity` |
| 泛化名 | 顶层类为 `Tree|Kind|Input|Action|Motion|SoundInstance` |
| 变量 | 长度 ≤2 且不在 allowlist；或命中黑名单 |
| 常量 | 可变 `static` 字段使用 UPPER_SNAKE |
| 方法 | 命中 `say|run|check|item|board|use|place|drops`（`@Override` 除外） |
| 工具 | 活动目录出现 `batch|rev|final|old|new|temp|tmp` |
| 文档 | 编号重复 |
| 资源 | 运行时文件名匹配 `_v\d+` |
| 资源结构 | blockstates/models/textures 分类不一致 |
| inventory | 新目录无日期/无 README |

配套 `naming-allowlist.json` 保存框架名：

```text
register init create tick randomTick useItemOn
level pos state stack player hit ctx bus id age
x y z i j k dx dy dz
```

同时建议：

- `verify-links.ps1`：检查 Markdown 相对链接是否存在；
- `verify-layout.ps1`：检查三类资源目录镜像、文档编号唯一、tools 命名；
- 每次交付前运行三件套 + 现有 verify/healthcheck。

---

## 7. 边界与禁止项

1. **不改 mod id、注册 ID、资源标识符、NBT/序列化字段、旧存档字段**；只改类/包/文件名与路径。
2. **不按“grep 无引用”直接删类**。`@EventBusSubscriber`、mixin 配置、JEI 注册、数据包都可能让一个类实际生效；`MySpeciesApi`、`DoughRecipeCategory`、`MeltingRecipeCategory` 等先确认用途。
3. **不一次性搬 225 份文档/53 个证据目录**。先索引，后分批；有绝对路径的清单先保留原位。
4. **不先改资源路径再改引用**。blockstate/model/texture/合同必须同步迁移。
5. **不删除受保护快照**：`.probe`、旧手绘原图、历史证据、`-before` 备份；整理只归档，不清理。
6. **不移动 `AGENTS.md`**：它依赖根路径自动加载；只更新内容。
7. **不在当前快照直接执行 Java 重命名**：本快照默认 Java 17，未发现 JDK 21，`launch-client.ps1` 依赖的 `.tooling/jdk21` 与 `.tooling/game` 也不存在；Java 改名应在原开发机或补好 JDK21/Gradle 的环境执行。
8. **无 Git 可用**：所有批量移动/改名必须先备份，并保留旧→新映射；不能用 `git diff` 回滚。
9. **路径长度与编码**：整理后的路径尽量浅、纯 ASCII、无空格；`.ps1` 保持 UTF-8 BOM，JSON 解析校验。

---

## 8. 验收标准

- [ ] 活动 Java 源码无 `My*` 类/文件；
- [ ] 无 `BlockBlock`、无物品类缺 `Item` 后缀；
- [ ] 无泛化顶层类型；嵌套公共类型已限定；
- [ ] 非白名单短变量/缩写变量为 0；
- [ ] 可变缓存不再使用 UPPER_SNAKE；
- [ ] 8 组文档编号重复已处理，`docs/INDEX.md` 覆盖全部文档；
- [ ] 运行时资源无 `_vN`；
- [ ] A/B 的 blockstates/models/textures 分类镜像；
- [ ] 活动工具名无历史批次/阶段词；`tools/README.md` 可用；
- [ ] `inventory/INDEX.md` 可用，新切片带 README/checks；
- [ ] `verify-naming.ps1`、`verify-links.ps1`、`verify-layout.ps1` 通过；
- [ ] A/B 构建、`verify.ps1`、`verify-registry.ps1`、`verify-coverage-ledger.ps1`、`healthcheck.ps1` 通过；
- [ ] 注册 ID、资源 ID、NBT、食品/玩法数据无变化；
- [ ] 新 JAR 哈希、部署位置和回滚点已记录。

---

## 9. 本文档的状态

- 本文只记录**命名与文件结构整理需求**及执行计划；
- 本轮没有迁移源码、资源、工具、文档或证据目录；
- 没有构建、没有启动游戏、没有制作 PCL 包；
- 下一步若执行，建议从 **Batch 0 + Batch 1** 开始，并在原开发机或具备 JDK 21 构建环境的位置执行 Java 改名批次。
