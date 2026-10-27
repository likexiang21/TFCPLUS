# H 册　TFC 4.2.10 植物类内容的自然生成机制与数据格式（附属模组开发字典）

> 本册目标：把「TerraFirmaCraft（TFC）里的植物是怎么被生成到世界里的」这件事讲全 —— feature 类清单、每个配置 Codec 的逐字段表、
> 真实 JSON 样例、placed_feature 完整参数表、群系挂载机制、野生作物/树/果树的特殊路径，最后给出「让附属模组的新植物自然生成」的最小落地文件集合。
>
> **每条结论都带来源。** 路径约定：
> - `TFC-decompiled/...` = `moddev/src-ref/TFC-decompiled/net/dries007/tfc/...`（行号即该反编译文件的行号，文件头的 “Could not load the following classes” 只是 classpath 提示，已忽略）
> - `jar-extract/...` = `moddev/jar-extract/...`（TFC jar 的真实 JSON 资源）
> - `neoforge-src/...` = `moddev/demo-mymod/build/moddev/artifacts/neoforge-21.1.233-sources.jar` 内的路径（本次为核实「features 数组长度可否超过 11」而打开）
> - `inventory/...` = `moddev/inventory/TFC.resources.txt`（jar 资源路径清单）
>
> 本册编号 `H-x`，与既有 `docs/12-tfc-data-driven.md` 的 `W-1 ~ W-11`（世界生成）章节**互不冲突**，末尾 [H-12] 给出与 W 章的核对结论。

---

## H-0　环境事实与核查方法

| 项 | 值 | 来源 |
|---|---|---|
| TFC 版本 | 4.2.10（jar 清单位于 `inventory/`） | `inventory/TFC.resources.txt` |
| NeoForge 版本 | 21.1.233 | `moddev/demo-mymod/build/moddev/artifacts/neoforge-21.1.233-*.jar` 文件名 |
| TFC feature 注册表 | `DeferredRegister.create(Registries.FEATURE, "tfc")` | `TFC-decompiled/world/feature/TFCFeatures.java:117` |
| TFC placement 注册表 | `DeferredRegister.create(Registries.PLACEMENT_MODIFIER_TYPE, "tfc")` | `TFC-decompiled/world/placement/TFCPlacements.java:38` |
| TFC block predicate 注册表 | `DeferredRegister.create(Registries.BLOCK_PREDICATE_TYPE, "tfc")` | `TFC-decompiled/world/blockpredicate/TFCBlockPredicates.java:29` |
| configured_feature 文件数 | 690 | `jar-extract/data/tfc/worldgen/configured_feature/` 实测 |
| placed_feature 文件数 | 674 | `jar-extract/data/tfc/worldgen/placed_feature/` 实测 |
| biome 文件数 | 125 | `jar-extract/data/tfc/worldgen/biome/` 实测 |

核查方法：所有字段表均从源码的 `RecordCodecBuilder.create(...)` / `MapCodec` 定义逐字段抄录，**未使用任何网络资料**；
所有 JSON 样例均为 `jar-extract/` 内真实文件原文（未格式化改写的会注明「单行原文」）。

---

## H-1　总览：植物进入世界的三条通路

TFC 的植物（野草、野花、野果灌木、野生作物、藤蔓、水生植物、树、果树）全部通过 **原版世界生成管线**（`ConfiguredFeature` + `PlacedFeature` + biome 的 `features` 数组）进入世界，
没有任何「运行时随机撒点」的旁路。三条通路：

1. **直接 placed_feature**：biome 的 `surface_decoration/<biome>` tag → `tfc:feature/land_plants` 等 tag → 单株/成片植物的 placed_feature
   （例：`tfc:plant/bluegrass`，来源 `jar-extract/data/tfc/tags/worldgen/placed_feature/in_biome/surface_decoration/plains.json` = `{"replace":false,"values":["#tfc:feature/land_plants"]}`）。
2. **聚合 feature**：一个 feature 内部再调用其它 ConfiguredFeature。
   - 森林：`tfc:forest`（`ForestFeature`）按气候挑树种 entry 并调用树 feature；
   - 组合：`tfc:noisy_multiple` / `tfc:multiple`（`SimpleRandomFeatureConfiguration`），例 `jar-extract/data/tfc/worldgen/configured_feature/surface_grasses.json`。
3. **树结构模板**：`tfc:random_tree` / `tfc:overlay_tree` / `tfc:stacked_tree` 从 `data/tfc/structure/<wood>/N.nbt` 粘贴结构（见 [H-8]）。

`TFC-decompiled/world/feature/TFCFeatures.java:133-164` 是植物与树木 feature 的注册总表。

---

## H-2　植物相关 feature 全清单

### H-2.1　`world/feature/plant` 包（20 个 feature 类 + 3 个 config 类）

来源：`TFC-decompiled/world/feature/TFCFeatures.java:133-148`（注册名与配置 codec 出处），类清单来自 `TFC-decompiled/world/feature/plant/` 目录实测。

| 类名 | 注册名 | 配置类型 | 生成什么方块 | 关键行为（源码行） |
|---|---|---|---|---|
| `TFCWeepingVinesFeature` | `tfc:weeping_vines` | `ColumnPlantConfig` | 从上方（树叶/原木/基岩）向下垂的藤；`body`=藤身，`head`=藤头 | 在水平 `radius` 内 `tries` 次随机取样，向下放一列；上方必须是 `#minecraft:leaves` / `#minecraft:logs` / `#minecraft:base_stone_overworld`；`age` 取值 17~25（硬编码）`TFCWeepingVinesFeature.java:44-82` |
| `TFCTwistingVinesFeature` | `tfc:twisting_vines` | `ColumnPlantConfig` | 从地面向上长的藤/大型蕨 | 起点必须坐在 `tfc:grass_plantable_on` 上，向上放一列；`age` 17~25（硬编码）`TFCTwistingVinesFeature.java:38-81` |
| `CreepingPlantFeature` | `tfc:creeping_plant` | `CreepingPlantConfig` | 贴地蔓延的地被（常春藤、苔藓等） | 以 origin 为心的 `radius×radius×height` 盒；`integrity` 概率过滤；仅放在潮位 `tide_height` **之上**；方块状态由 `CreepingPlantBlock.updateStateFromSides` 决定 `CreepingPlantFeature.java:34-62` |
| `CreepingOceanPlantFeature` | `tfc:creeping_ocean_plant` | `CreepingPlantConfig` | 海水中的蔓延地被（珊瑚藻类） | 仅放在潮位 **之下**（`y <= tide_height + noise`）；自动按流体灌水，`open` 属性 = 是否海水 `CreepingOceanPlantFeature.java:41-75` |
| `EpiphytePlantFeature` | `tfc:epiphyte_plant` | `BlockConfig<EpiphytePlantBlock>` | 附生植物（西班牙苔藓等） | origin 向上随机 0~11 格，然后 4 个水平面依次尝试 `canSurvive`，第一个成功即放置 `EpiphytePlantFeature.java:35-61` |
| `SubmergedTallPlantFeature` | `tfc:submerged_tall_plant` | `BlockConfig<TallWaterPlantBlock>` | 完全淹没的两格高水生植物 | 要求 `pos` 与 `pos.above()` 的流体**同种**且都可替换，然后 `placeTwoHalves(...,2,random)` `SubmergedTallPlantFeature.java:26-47` |
| `EmergentPlantFeature` | `tfc:emergent_plant` | `BlockConfig<TallWaterPlantBlock>` | 挺水植物（香蒲等） | 要求 `pos.above()` 是空气（`Fluids.EMPTY`）且两格可替换 `EmergentPlantFeature.java:28-48` |
| `TFCKelpFeature` | `tfc:kelp` | `ColumnPlantConfig` | 海带柱 | `tries` 次：用 `Heightmap.OCEAN_FLOOR` 找海底 → 检查水下 → 向上放 `min_height..max_height` 高，`age` 22~25；头方块为 `GrowingPlantHeadBlock` `TFCKelpFeature.java:45-92` |
| `GiantKelpFeature` | `tfc:kelp_tree` | `BlockConfig<KelpTreeFlowerBlock>` | 巨型海带树 | 直接委托 `KelpTreeFlowerBlock.generatePlant(level, pos, random, 8, fluid, seaLevel - random(6))` `GiantKelpFeature.java:25-43` |
| `TallPlantFeature` | `tfc:tall_plant` | `BlockConfig<TFCTallGrassBlock>` | 两格高野草（`TFCTallGrassBlock`） | `block.placeTwoHalves(level, origin, 2, random)`（两格，带随机双向态）`TallPlantFeature.java:19-33` |
| `TallWildCropFeature` | `tfc:tall_wild_crop` | `BlockConfig<WildDoubleCropBlock>` | 两格高野生作物（实测 JSON：green_bean、tomato、sugarcane、jute、papyrus 等） | `block.placeTwoHalves(level, origin, 2)` `TallWildCropFeature.java:19-33` |
| `SpreadingCropFeature` | `tfc:spreading_crop` | `BlockConfig<WildSpreadingCropBlock>` | 野生匍匐作物（南瓜、西瓜、甘蔗类果实附着） | 水平随机方向 `direction`；`origin.relative(dir)` 下方必须是 `#tfc:spreading_fruit_grows_on` 且可替换 → 放果实方块 + 给果实挂 `FoodTraits.WILD` 腐坏数据 + 在 origin 放主体并把该方向属性置 true `SpreadingCropFeature.java:42-73` |
| `SpreadingBushFeature` | `tfc:spreading_bush` | `BlockConfig<SpreadingBushBlock>` | 野果灌木（蓝莓/黑莓/树莓…灌木本体 + 藤条） | 5 次尝试：偏移 ±2 格 → `canSurvive` → 高 1~3 格逐格放 `STAGE` 递减的本体，并随机往水平方向放 `SpreadingCaneBlock` `SpreadingBushFeature.java:38-76` |
| `RotatableWaterPlantFeature` | `tfc:rotatable_water_plant` | `BlockConfig<RotatableWaterPlantBlock>` | 可朝向的水生植物（睡莲类） | origin 向上随机 0~11；`Direction.allShuffled` 依次试 `canSurvive`；按流体灌水并设 `open`=是否海水 `RotatableWaterPlantFeature.java:39-69` |
| `BlockWithFluidFeature` | `tfc:block_with_fluid` | `SimpleBlockConfiguration`（**原版**） | 需按所在流体灌水的单格方块（星星草等） | 取 `toPlace().getState(random,pos)` → `FluidHelpers.fillWithFluid` → `canSurvive` → `setBlock(...,2)` `BlockWithFluidFeature.java:26-42` |
| `BranchingCactusFeature` | `tfc:branching_cactus` | `BlockConfig<GrowingBranchingCactusBlock>` | 分枝仙人掌（`saguaro` 等） | `block.growRecursively(level, origin, block.defaultBlockState(), 8)` `BranchingCactusFeature.java:19-33` |
| `TFCBambooFeature` | `tfc:bamboo` | `TFCBambooConfig` | 竹子 + 周围草方块转 `rooted` 泥土 | 参照原版 `BambooFeature`，杆高 `random(12)+5`；`probability` 决定是否把半径 `random(4)+1` 内的 `IGrassBlock`/`DirtBlock` 变成 `getRooted()` `TFCBambooFeature.java:43-116` |
| `FruitTreeFeature` | `tfc:fruit_trees` | `BlockStateConfiguration`（**原版**，使用 `Codecs.BLOCK_STATE_CONFIG`） | 果树枝干方块（`tfc:plant/<fruit>_growing_branch`） | 下方必须是 `#tfc:bush_plantable_on`；上方 10 格必须全部可替换；放枝干 → 设 `natural=true`、`saplings=random(2..4)` → 给 `TICK_COUNTING_PLANT` 加计数 `0x6DDD00` → `scheduleTick` `FruitTreeFeature.java:39-71` |
| `BananaFeature` | `tfc:bananas` | `BlockStateConfiguration` | 香蕉植株（`tfc:plant/banana_plant`） | 下方 `#tfc:bush_plantable_on`；stage 0→2，每 stage 高 `random(2..3)` 格，逐格放 `Stage`+`Lifecycle.HEALTHY` `BananaFeature.java:40-67` |
| `TFCVinesFeature` | `tfc:vines` | `BlockStateConfiguration` | 原版式藤（`VineBlock`，四面可挂） | 4 个水平方向第一个 `VineBlock.isAcceptableNeighbour` 成功的方向 → 设对应面属性 → 向下延伸 `random(14)` 格 `TFCVinesFeature.java:35-67` |

> **注意区分**：`tfc:vines`（`TFCVinesFeature`，原版 `VineBlock` 语义）与 `tfc:weeping_vines`/`tfc:twisting_vines`（TFC 的 `ColumnPlantConfig` 语义）是两套东西。
> `TFC-decompiled/world/feature/TFCFeatures.java:133-134` 中 `HANGING_VINES` 字段注册名是 **`tfc:weeping_vines`**，`TWISTING_VINES` 注册名是 **`tfc:twisting_vines`**；而 `VINES` 字段在 `TFCFeatures.java:153` 注册为 `tfc:vines`。

### H-2.2　`world/feature/tree` 包（树）

来源：`TFC-decompiled/world/feature/TFCFeatures.java:159-164`。

| 类名 | 注册名 | 配置类型 | 行为（源码行） |
|---|---|---|---|
| `ForestFeature` | `tfc:forest` | `ForestConfig` | 区块级森林生成：按 `ChunkData` 的气候/森林类型挑选 `Entry`，生成普通树 / 枯树 / 老树 / 高山矮曲林（krummholz）/ 灌木 / 地表覆盖 / 落叶堆 / 倒木 / 土壤圆盘 `ForestFeature.java:71-99` |
| `ForestFeature.Entry` | `tfc:forest_entry` | `ForestConfig.Entry` | **不是真 feature**：`place()` 直接抛 `IllegalArgumentException("This is not a real feature and should never be placed!")`，只作为携带配置的容器被 `tfc:forest` 读取 `ForestFeature.java:304-313` |
| `OverlayTreeFeature` | `tfc:overlay_tree` | `OverlayTreeConfig` | 先放 `base` 结构，再以 `overlay_integrity` 概率逐方块放 `overlay` 结构（`BlockRotProcessor`）`OverlayTreeFeature.java:44-77` |
| `RandomTreeFeature` | `tfc:random_tree` | `RandomTreeConfig` | 在 `structures` 里随机选一个 nbt 结构粘贴；可选先放 trunk 与根系 `RandomTreeFeature.java:43-77` |
| `StackedTreeFeature` | `tfc:stacked_tree` | `StackedTreeConfig` | 先放树干，然后按 `layers` 依次向上堆叠多个结构（每层随机数量）`StackedTreeFeature.java:42-78` |
| `KrummholzFeature` | `tfc:krummholz` | `KrummholzConfig` | 高山矮曲林：竖直一列 `KrummholzBlock`，最顶 `tip=true`，最底 `bottom=true` `KrummholzFeature.java:37-84` |
| `TreeHelpers` | （工具类） | — | 落地合法性判断、模板粘贴、树干、根系 `TreeHelpers.java:74-301` |

---

## H-3　配置 Codec 逐字段表（可直接当字典）

> 记号：**必填** = codec 用 `fieldOf`；**可选(默认值)** = `optionalFieldOf`。类型写 Java 类型 / JSON 形式。

### H-3.1　`BlockConfig<T extends Block>`（`TFC-decompiled/world/feature/BlockConfig.java:23-34`）

| 字段 | 类型 | 必填/默认 | 语义 |
|---|---|---|---|
| `block` | `T`（JSON: 方块 id 字符串） | 必填 | 目标方块；**codec 内含 `comapFlatMap` 的类型转换器**：若方块不是泛型 `T` 的实例，直接报错 `Must be a <类名>: <block id>`（`BlockConfig.java:25-33`） |

```json
{ "type": "tfc:emergent_plant", "config": { "block": "tfc:plant/cattail" } }
```
来源：`jar-extract/data/tfc/worldgen/configured_feature/plant/cattail.json`（单行原文）。

> **对附属模组极其重要**：`tfc:tall_plant` / `tfc:creeping_plant` / `tfc:weeping_vines` 等复用 TFC feature 的写法，
> 要求你的方块**继承对应的 TFC 方块类**，否则加载期就报错（见 [H-9] 坑 4）。

### H-3.2　`ColumnPlantConfig`（`TFC-decompiled/world/feature/plant/ColumnPlantConfig.java:22-25`）

| 字段 | 类型 | 必填/默认 | 语义 |
|---|---|---|---|
| `body` | `BlockState`（`Codecs.BLOCK_STATE`） | 必填 | 柱身方块 |
| `head` | `BlockState` | 必填 | 柱头（顶端）方块 |
| `tries` | int，范围 **1~128** | 必填 | 尝试次数 |
| `radius` | int，范围 **1~16** | 必填 | 每次尝试的水平随机半径 |
| `min_height` | int，范围 **1~100** | 必填 | 柱最小高度 |
| `max_height` | int，范围 **1~100** | 必填 | 柱最大高度 |

**⚠️ 源码缺陷（实测）**：`head` 字段的 `forGetter` 写成 `c -> c.bodyState`（`ColumnPlantConfig.java:24`），
即**编码（写出 JSON）时 `head` 会被写成 `body` 的值**。解码（读 JSON）不受影响，所以手写 JSON 时 `head` 是独立生效的。
用 datagen 生成这类 JSON 的附属模组会踩坑；手写 JSON 无影响。

#### `Codecs.BLOCK_STATE` 的 JSON 形式（`TFC-decompiled/world/Codecs.java:64`）
`Codec.either(BLOCK.xmap(默认态), BlockState.CODEC)` —— 也就是说：
- 只写方块 id 字符串 → 使用该方块的默认状态：`"block": "tfc:plant/hanging_vines_plant"`
- 写对象 → 完整状态：`{"Name":"tfc:plant/hanging_vines","Properties":{"age":"1"}}`

### H-3.3　`CreepingPlantConfig`（`TFC-decompiled/world/feature/plant/CreepingPlantConfig.java:22-25`）

| 字段 | 类型 | 必填/默认 | 语义 |
|---|---|---|---|
| `block` | `Block`（`Codecs.BLOCK`） | 必填 | 蔓延方块（`CreepingPlantBlock` / `CreepingWaterPlantBlock`） |
| `radius` | int（`Codec.INT`） | 必填 | 水平半径 |
| `height` | int（`Codec.INT`） | 必填 | 竖直高度 |
| `tide_height` | int（`Codec.INT`） | 必填 | 潮位阈值（相对海平面的偏移），配合 `BiomeNoise.shoreTideLevelNoise` 使用 |
| `integrity` | float，可选 | **可选，默认 `1.0`** | 放置概率（0~1） |

```json
{"type":"tfc:creeping_plant","config":{"block":"tfc:plant/ivy","height":7,"radius":4,"integrity":0.95,"tide_height":2}}
```
来源：`jar-extract/data/tfc/worldgen/configured_feature/plant/ivy_cover.json`（单行原文）。

### H-3.4　`TFCBambooConfig`（`TFC-decompiled/world/feature/plant/TFCBambooConfig.java:22-25`）

| 字段 | 类型 | 必填/默认 | 语义 |
|---|---|---|---|
| `probability` | float，范围 0~1 | 必填 | 把半径内草方块/泥土转成 `rooted` 的概率 |
| `state` | `BlockState` | 必填 | 竹杆方块（`BambooStalkBlock` 语义，会被强制设 `age=1`、`leaves=NONE`、`stage=0`） |

### H-3.5　`ForestConfig`（`TFC-decompiled/world/feature/tree/ForestConfig.java:33-35`）

| 字段 | 类型 | 必填/默认 | 语义 |
|---|---|---|---|
| `entries` | `HolderSet<ConfiguredFeature<?,?>>`（JSON: id / 列表 / `#tag`），`ExtraCodecs.nonEmptyHolderSet` | 必填 | 候选树种 entry 列表 |

```json
{"type":"tfc:forest","config":{"entries":"#tfc:forest_trees"}}
```
来源：`jar-extract/data/tfc/worldgen/configured_feature/forest.json`（单行原文）；tag 定义见 `jar-extract/data/tfc/tags/worldgen/configured_feature/forest_trees.json`。

### H-3.6　`ForestConfig.Entry`（`TFC-decompiled/world/feature/tree/ForestConfig.java:37-42`）

| 字段 | 类型 | 必填/默认 | 语义 |
|---|---|---|---|
| `climate` | `ClimatePlacement` | 必填 | 该树种的气候窗口（比较用温度、地下水、降雨方差、海拔） |
| `bush_log` | `BlockState` | 可选 | 灌木中心方块 |
| `bush_leaves` | `BlockState` | 可选 | 灌木叶片方块 |
| `fallen_log` | `BlockState` | 可选 | 倒木方块 |
| `fallen_leaves` | `BlockState` | 可选 | 落叶堆方块（`FallenLeavesBlock.LAYERS`） |
| `groundcover` | `IWeighted<BlockState>` 列表（`weightedCodec(BLOCK_STATE,"block")`） | 可选 | 地表覆盖物（树枝、松果等），权重字段 `weight`（默认 1.0，`Codecs.java:76-86`） |
| `normal_tree` | `Holder<ConfiguredFeature>` | 必填 | 普通树 |
| `dead_tree` | `Holder<ConfiguredFeature>` | 必填 | 枯树 |
| `old_growth_tree` | `Holder<ConfiguredFeature>` | 可选 | 老树；缺省时回退到 `normal_tree`（`ForestConfig.java:86-88`） |
| `krummholz` | `Holder<ConfiguredFeature>` | 可选 | 高山矮曲林 |
| `soil_disc` | `Holder<ConfiguredFeature>` | 可选 | 该树种对应的土壤圆盘（如 `tfc:duff_disc`） |
| `old_growth_chance` | int | 可选，默认 **6** | 主林区生成老树的 1/N 概率 |
| `spoiler_old_growth_chance` | int | 可选，默认 **200** | 非主林区生成老树的 1/N 概率 |
| `fallen_tree_chance` | int | 可选，默认 **14** | 倒木 1/N 概率 |
| `dead_chance` | int | 可选，默认 **75** | 枯树 1/N 概率 |
| `floating` | boolean | 可选，默认 **false** | 是否生成"浮空树"（y<59 直接失败，起点取水面高度 + random(2)，`ForestFeature.java:111-116`） |

真实样例（`jar-extract/data/tfc/worldgen/configured_feature/tree/acacia_entry.json`，单行原文）：

```json
{"type":"tfc:forest_entry","config":{"climate":{"min_temperature":10.4,"max_temperature":40,"min_groundwater":90,"max_groundwater":500,"min_rain_variance":0.4,"max_rain_variance":0.85,"rain_variance_absolute":true},"groundcover":[{"block":"tfc:wood/twig/acacia"},{"block":"tfc:wood/fallen_leaves/acacia"}],"normal_tree":"tfc:tree/acacia","dead_tree":"tfc:tree/acacia_dead","soil_disc":"tfc:duff_disc","fallen_tree_chance":0,"bush_log":{"Name":"tfc:wood/wood/acacia","Properties":{"branch_direction":"down","axis":"y"}},"bush_leaves":"tfc:wood/leaves/acacia","old_growth_tree":"tfc:tree/acacia_large"}}
```

### H-3.7　`RandomTreeConfig`（`TFC-decompiled/world/feature/tree/RandomTreeConfig.java:26-29`）

| 字段 | 类型 | 必填/默认 | 语义 |
|---|---|---|---|
| `structures` | `ResourceLocation` 列表 | 必填 | 候选 nbt 结构 id 列表（`data/tfc/structure/...`） |
| `trunk` | `TrunkConfig` | 可选 | 树干（先于结构放置并抬高 origin） |
| `placement` | `TreePlacementConfig` | 必填 | 落地校验参数 |
| `root_system` | `RootConfig` | 可选 | 根系 |

```json
{"type":"tfc:random_tree","config":{"structures":["tfc:acacia/1","...","tfc:acacia/35"],"radius":1,"placement":{"width":1,"height":3}}}
```
来源：`jar-extract/data/tfc/worldgen/configured_feature/tree/acacia.json`（单行原文，`structures` 中间项已省略）。

> **⚠️ 实测不一致**：真实 JSON 里出现的 `"radius":1` **在 `RandomTreeConfig` 的 codec 中不存在**（`RandomTreeConfig.java:28` 只有
> `structures` / `trunk` / `placement` / `root_system`）。Mojang 的 `RecordCodecBuilder` 会**静默忽略未知字段**，所以该字段无效。
> 这与 `docs/12-tfc-data-driven.md` [W-11.2] 对 `vein` 中 `spread` 字段的判断同类。附属模组**不要**照抄 `radius`。

### H-3.8　`OverlayTreeConfig`（`TFC-decompiled/world/feature/tree/OverlayTreeConfig.java:25-28`）

| 字段 | 类型 | 必填/默认 | 语义 |
|---|---|---|---|
| `base` | `ResourceLocation` | 必填 | 基础结构 id |
| `overlay` | `ResourceLocation` | 必填 | 叠加结构 id |
| `trunk` | `TrunkConfig` | 可选 | 树干 |
| `overlay_integrity` | float，0~1 | 可选，默认 **0.5** | 叠加结构每方块的保留概率（`BlockRotProcessor`） |
| `placement` | `TreePlacementConfig` | 必填 | 落地校验 |
| `root_system` | `RootConfig` | 可选 | 根系 |

### H-3.9　`StackedTreeConfig`（`TFC-decompiled/world/feature/tree/StackedTreeConfig.java:31-49`）

| 字段 | 类型 | 必填/默认 | 语义 |
|---|---|---|---|
| `layers` | `Layer` 列表 | 必填 | 自下而上的堆叠层 |
| `trunk` | `TrunkConfig` | 必填 | 树干 |
| `placement` | `TreePlacementConfig` | 必填 | 落地校验 |
| `root_system` | `RootConfig` | 可选 | 根系 |

`Layer`（`StackedTreeConfig.java:35-41`）：

| 字段 | 类型 | 必填/默认 | 语义 |
|---|---|---|---|
| `templates` | `ResourceLocation` 列表 | 必填 | 该层候选结构 |
| `min_count` | int | 必填 | 最少堆叠个数 |
| `max_count` | int | 必填 | 最多堆叠个数；**校验 `max_count >= min_count`**，否则报错 |

### H-3.10　`KrummholzConfig`（`TFC-decompiled/world/feature/tree/KrummholzConfig.java:24-27`）

| 字段 | 类型 | 必填/默认 | 语义 |
|---|---|---|---|
| `block` | `Block`（`Codecs.BLOCK`） | 必填 | 矮曲林方块（`KrummholzBlock`） |
| `height` | `IntProvider` | 必填 | 高度分布（`{"type":"uniform","min_inclusive":1,"max_inclusive":4}`） |
| `spawns_on_stone` | boolean | 可选，默认 **false** | 是否允许生长在 `#c:stones` 上 |
| `spawns_on_gravel` | boolean | 可选，默认 **false** | 是否允许生长在 `#c:gravels` 上 |

```json
{"type":"tfc:krummholz","config":{"block":"tfc:plant/aspen_krummholz","height":{"type":"uniform","min_inclusive":1,"max_inclusive":4}}}
```
来源：`jar-extract/data/tfc/worldgen/configured_feature/tree/aspen_krummholz.json`（单行原文）。

### H-3.11　`TreePlacementConfig`（`TFC-decompiled/world/feature/tree/TreePlacementConfig.java:20-55`）

| 字段 | 类型 | 必填/默认 | 语义 |
|---|---|---|---|
| `width` | int | 必填 | 落地校验的正方形边长（`(1-width)/2 .. width/2`） |
| `height` | int | 必填 | 树干高度校验格数（`y = 1 .. height-1` 必须为空） |
| `ground_type` | 枚举，`optionalFieldOf` | 可选，默认 **`normal`** | `normal` / `sand` / `shallow_water` / `submerged` / `shallow_allow_saltwater` / `submerged_allow_saltwater` / `floating`（`TreePlacementConfig.java:35-55`） |

派生语义（`TreePlacementConfig.java:23-33`）：
- `mayPlaceInWater()`：`shallow_water`、`submerged`、`submerged_allow_saltwater`；
- `mayPlaceUnderwater()`：`submerged`、`submerged_allow_saltwater`；
- `requiresFreshwater()`：除 `submerged_allow_saltwater`、`shallow_allow_saltwater` 外都为 true。

### H-3.12　`TrunkConfig`（`TFC-decompiled/world/feature/tree/TrunkConfig.java:24-38`）

| 字段 | 类型 | 必填/默认 | 语义 |
|---|---|---|---|
| `state` | `BlockState` | 必填 | 树干方块（会被设置 `branch_direction` 属性） |
| `min_height` | int | 必填 | 最小高度 |
| `max_height` | int | 必填 | 最大高度；校验 `min_height <= max_height` |
| `wide` | boolean | 必填 | true = 2×2 宽树干（同时用四个 `TRUNK_*` 分支方向） |

### H-3.13　`RootConfig`（`TFC-decompiled/world/feature/tree/RootConfig.java:26-28`）

| 字段 | 类型 | 必填/默认 | 语义 |
|---|---|---|---|
| `blocks` | `Map<Block, IWeighted<BlockState>>` | 必填 | 「替换哪种方块 → 换成什么（带权重）」。JSON 形式为列表：`[{"replace":[方块id,...],"with":[{"block":状态,"weight":1.0},...]}]`（`Codecs.java:65,88-104`） |
| `width` | 正整数 | 可选，默认 **4** | 水平扩散半径（`Helpers.triangle`） |
| `height` | 正整数 | 可选，默认 **3** | 向下深度 |
| `tries` | 正整数 | 可选，默认 **5** | 尝试次数 |
| `special_placer` | `SpecialRootPlacer` | 可选 | 特殊根系（如红树） |
| `required` | boolean | 可选，默认 **false** | true 时根系放置失败则整棵树放弃 |

### H-3.14　复用的原版配置

| 原版 config | TFC 中用于 | 字段（原版语义） |
|---|---|---|
| `BlockStateConfiguration` | `tfc:fruit_trees`、`tfc:bananas`、`tfc:vines`（经 `Codecs.BLOCK_STATE_CONFIG`，`Codecs.java:66`） | `state`（`BlockState`），JSON 可写字符串或 `{Name,Properties}` |
| `SimpleBlockConfiguration` | `tfc:block_with_fluid`、以及大量 `minecraft:simple_block` 野草/野花 | `to_place`（`BlockStateProvider`，常见 `{"type":"tfc:random_property","state":{...},"property":"age"}`） |
| `RandomPatchConfiguration` | `tfc:dynamic_random_patch`（`TFCFeatures.java:175`）、以及所有 `*_patch` 用的 `minecraft:random_patch` | `tries`、`xz_spread`、`y_spread`、`feature` |
| `SimpleRandomFeatureConfiguration` | `tfc:multiple` / `tfc:noisy_multiple`（`TFCFeatures.java:173-174`） | `features`（可写 `#tag`） |

### H-3.15　TFC 自定义 state provider：`tfc:random_property`（植物数据里最常用）

注册：`TFCStateProviders.RANDOM_PROPERTY = register("random_property", RandomPropertyProvider.CODEC)`
（`TFC-decompiled/world/stateprovider/TFCStateProviders.java:27`，注册表为 `Registries.BLOCK_STATE_PROVIDER_TYPE`，命名空间 `tfc`，同文件 `:26`）。

字段表（`TFC-decompiled/world/stateprovider/RandomPropertyProvider.java:37`）：

| 字段 | 类型 | 必填/默认 | 语义 |
|---|---|---|---|
| `state` | `BlockState`（`Codecs.BLOCK_STATE`） | 必填 | 基础状态 |
| `property` | string | 必填 | 要在该方块的所有取值之间随机的属性名；**若该属性不存在，则原样返回 `state`**（`RandomPropertyProvider.java:46-49`） |

行为：`getState(random, pos)` 返回 `state` 把 `property` 设为「该属性可能值列表中随机一个」的结果（`:52-59`）。
典型用法：野草/野花把 `age` 随机化 —— `jar-extract/data/tfc/worldgen/configured_feature/plant/bluegrass.json`：
`"to_place":{"type":"tfc:random_property","state":{"Name":"tfc:plant/bluegrass","Properties":{"age":"1","stage":"1"}},"property":"age"}`。

同目录另有 `SpecialRootPlacer`（`RootConfig.special_placer` 的实现，`TFC-decompiled/world/stateprovider/SpecialRootPlacer.java`），本册未展开其 codec。

---

## H-4　真实 JSON 样例集（configured_feature / placed_feature）

所有 JSON 均为 `jar-extract/` 内**原文**（文件本身即单行）。

### H-4.1　贴地野草（单格）—— `tfc:plant/bluegrass`

`jar-extract/data/tfc/worldgen/configured_feature/plant/bluegrass.json`：
```json
{"type":"minecraft:simple_block","config":{"to_place":{"type":"tfc:random_property","state":{"Name":"tfc:plant/bluegrass","Properties":{"age":"1","stage":"1"}},"property":"age"}}}
```
逐字段：`type` = 原版 `simple_block` feature；`config.to_place` = state provider，`random_property` 表示在 `state` 基础上随机化 `age` 属性。

`jar-extract/data/tfc/worldgen/placed_feature/plant/bluegrass.json`：
```json
{"feature":"tfc:plant/bluegrass","placement":[{"type":"minecraft:heightmap","heightmap":"WORLD_SURFACE_WG"},{"type":"block_predicate_filter","predicate":{"type":"tfc:air_or_empty_fluid"}},{"type":"block_predicate_filter","predicate":{"type":"would_survive","state":{"Name":"tfc:plant/bluegrass","Properties":{"age":"1","stage":"1"}}}}]}
```
逐字段：`heightmap(WORLD_SURFACE_WG)` → 取地表 y；`block_predicate_filter(tfc:air_or_empty_fluid)` → 该格必须是空气或空流体；
`block_predicate_filter(minecraft:would_survive, state=…)` → 该状态必须能在此处 `canSurvive`。

配套的"成片"版本 `jar-extract/data/tfc/worldgen/placed_feature/plant/bluegrass_patch.json`：
```json
{"feature":"tfc:plant/bluegrass_patch","placement":[{"type":"minecraft:in_square"},{"type":"minecraft:heightmap","heightmap":"WORLD_SURFACE_WG"},{"type":"tfc:climate","min_temperature":-0.4,"max_temperature":14.0,"min_groundwater":110,"max_groundwater":280}]}
```
对应 configured（`jar-extract/data/tfc/worldgen/configured_feature/plant/bluegrass_patch.json`）是 `minecraft:random_patch`，`tries/xz_spread/y_spread` + `feature: "tfc:plant/bluegrass"`（`tfc:plant/bluegrass_patch` 引用单株版本）。

### H-4.2　挺水植物（两格）—— `tfc:plant/cattail`

`jar-extract/data/tfc/worldgen/configured_feature/plant/cattail.json`：
```json
{"type":"tfc:emergent_plant","config":{"block":"tfc:plant/cattail"}}
```
`jar-extract/data/tfc/worldgen/placed_feature/plant/cattail.json`：
```json
{"feature":"tfc:plant/cattail","placement":[{"type":"minecraft:heightmap","heightmap":"OCEAN_FLOOR_WG"},{"type":"block_predicate_filter","predicate":{"type":"tfc:air_or_empty_fluid"}},{"type":"block_predicate_filter","predicate":{"type":"tfc:would_survive_with_fluid","state":{"Name":"tfc:plant/cattail","Properties":{"age":"1","stage":"1","fluid":"empty","part":"lower"}}}}]}
```
注意这里用的是 **`tfc:would_survive_with_fluid`**（自带灌水逻辑）而不是原版 `would_survive`，因为方块带 `fluid` 属性。

### H-4.3　整格灌水的单格植物 —— `tfc:plant/star_grass`

`jar-extract/data/tfc/worldgen/configured_feature/plant/star_grass.json`：
```json
{"type":"tfc:block_with_fluid","config":{"to_place":{"type":"tfc:random_property","state":{"Name":"tfc:plant/star_grass","Properties":{"age":"1","stage":"1"}},"property":"age"}}}
```
`jar-extract/data/tfc/worldgen/placed_feature/plant/star_grass_patch.json`：
```json
{"feature":"tfc:plant/star_grass_patch","placement":[{"type":"minecraft:in_square"},{"type":"minecraft:heightmap","heightmap":"WORLD_SURFACE_WG"},{"type":"tfc:climate","min_temperature":5,"max_temperature":40,"min_groundwater":50,"max_groundwater":260}]}
```

### H-4.4　下垂藤 —— `tfc:plant/hanging_vines`

`jar-extract/data/tfc/worldgen/configured_feature/plant/hanging_vines.json`：
```json
{"type":"tfc:weeping_vines","config":{"body":"tfc:plant/hanging_vines_plant","head":"tfc:plant/hanging_vines","tries":90,"radius":10,"min_height":14,"max_height":21}}
```
逐字段：`body`/`head` = `ColumnPlantConfig.bodyState/headState`（可写字符串=默认态）；`tries=90` 次尝试；水平 `radius=10`；高度 14~21。

### H-4.5　向上生长的藤/树蕨 —— `tfc:plant/tree_fern`

`jar-extract/data/tfc/worldgen/configured_feature/plant/tree_fern.json`：
```json
{"type":"tfc:twisting_vines","config":{"body":"tfc:plant/tree_fern_plant","head":"tfc:plant/tree_fern","tries":8,"radius":7,"min_height":2,"max_height":6}}
```

### H-4.6　蔓延地被 —— `tfc:plant/ivy`

见 [H-3.3] 的 JSON（`configured_feature/plant/ivy_cover.json`）。placed 版本 `jar-extract/data/tfc/worldgen/placed_feature/plant/ivy_cover.json` 使用 `tfc:climate` + `heightmap`。

### H-4.7　野果灌木 —— `tfc:plant/blackberry_bush` / `blueberry_bush`

configured（`jar-extract/data/tfc/worldgen/configured_feature/plant/blackberry_bush.json`）：
```json
{"type":"tfc:spreading_bush","config":{"block":"tfc:plant/blackberry_bush"}}
```
placed（`jar-extract/data/tfc/worldgen/placed_feature/plant/blueberry_bush.json`）：
```json
{"feature":"tfc:plant/blueberry_bush","placement":[{"type":"tfc:climate","min_temperature":-8.8,"max_temperature":8.6,"min_groundwater":150,"max_groundwater":400,"min_forest":0,"max_forest":2},{"type":"minecraft:heightmap","heightmap":"WORLD_SURFACE_WG"},{"type":"minecraft:in_square"},{"type":"minecraft:rarity_filter","chance":22}]}
```
> **实测纠正**：灌木**没有** `*_bush_patch` 文件（`configured_feature/plant/blueberry_bush_patch.json` 不存在）。
> 灌木本身由 `SpreadingBushFeature` 一次生成 1~3 格高的小丛，`count/rarity_filter` 直接在 placed 层控制密度。

### H-4.8　野生作物（单格 / 两格 / 匍匐三种形态）

| 形态 | configured type | 真实文件 | TFC 方块 |
|---|---|---|---|
| 单格 | `minecraft:simple_block` | `configured_feature/plant/wild_crop/barley.json`：`{"type":"minecraft:simple_block","config":{"to_place":{"type":"minecraft:simple_state_provider","state":{"Name":"tfc:wild_crop/barley"}}}}` | `WildCropBlock` |
| 两格 | `tfc:tall_wild_crop` | `configured_feature/plant/wild_crop/green_bean.json`：`{"type":"tfc:tall_wild_crop","config":{"block":"tfc:wild_crop/green_bean"}}` | `WildDoubleCropBlock` |
| 匍匐（果实） | `tfc:spreading_crop` | `configured_feature/plant/wild_crop/pumpkin.json`：`{"type":"tfc:spreading_crop","config":{"block":"tfc:wild_crop/pumpkin"}}` | `WildSpreadingCropBlock` |
| 两格（甘蔗/番茄/黄麻/纸莎草等按 `Crop` 构造器判定） | `tfc:tall_wild_crop` | `configured_feature/plant/wild_crop/sugarcane.json` | `WildDoubleCropBlock` |

成片版本 = `minecraft:random_patch` 包一层：
```json
{"type":"minecraft:random_patch","config":{"tries":6,"xz_spread":5,"y_spread":1,"feature":"tfc:plant/wild_crop/barley"}}
```
（`jar-extract/data/tfc/worldgen/configured_feature/plant/wild_crop/barley_patch.json`，单行原文）

placed 版本（`jar-extract/data/tfc/worldgen/placed_feature/plant/wild_crop/barley_patch.json`）：
```json
{"feature":"tfc:plant/wild_crop/barley_patch","placement":[{"type":"minecraft:rarity_filter","chance":90},{"type":"minecraft:in_square"},{"type":"tfc:climate","min_temperature":-9.4,"max_temperature":17.6,"min_groundwater":70,"max_groundwater":310,"max_forest":2}]}
```

### H-4.9　果树 —— `tfc:plant/cherry` / `tfc:plant/banana`

`jar-extract/data/tfc/worldgen/configured_feature/plant/cherry.json`：
```json
{"type":"tfc:fruit_trees","config":{"state":"tfc:plant/cherry_growing_branch"}}
```
`jar-extract/data/tfc/worldgen/placed_feature/plant/cherry.json`：
```json
{"feature":"tfc:plant/cherry","placement":[{"type":"tfc:climate","min_temperature":-5.2,"max_temperature":14.0,"min_groundwater":100,"max_groundwater":350,"max_forest":3},{"type":"minecraft:heightmap","heightmap":"WORLD_SURFACE_WG"},{"type":"minecraft:in_square"},{"type":"minecraft:rarity_filter","chance":50}]}
```
香蕉走另一条 feature：`jar-extract/data/tfc/worldgen/configured_feature/plant/banana.json` = `{"type":"tfc:bananas","config":{"state":"tfc:plant/banana_plant"}}`。

### H-4.10　巨型海带树 —— `tfc:plant/giant_kelp`

`jar-extract/data/tfc/worldgen/configured_feature/plant/giant_kelp.json`：
```json
{"type":"tfc:kelp_tree","config":{"block":"tfc:plant/giant_kelp_flower"}}
```

### H-4.11　树 —— `tfc:tree/acacia` / `tfc:tree/palm`

`jar-extract/data/tfc/worldgen/configured_feature/tree/acacia.json`（节选，`structures` 共 35 项）：
```json
{"type":"tfc:random_tree","config":{"structures":["tfc:acacia/1","tfc:acacia/2","…","tfc:acacia/35"],"radius":1,"placement":{"width":1,"height":3}}}
```

**棕榈（PALM）的特殊点**（`jar-extract/data/tfc/worldgen/configured_feature/tree/palm.json`，原文）：
```json
{"type":"tfc:random_tree","config":{"structures":["tfc:palm/1","tfc:palm/2","tfc:palm/3","tfc:palm/4","tfc:palm/5","tfc:palm/6","tfc:palm/7"],"radius":1,"placement":{"width":1,"height":5,"ground_type":"sand"}}}
```
差异：`placement.ground_type` = **`sand`**（可长在沙上，`TreeHelpers.isValidPosition` 才允许 `#minecraft:sand`）；
且 `palm_entry`（`jar-extract/data/tfc/worldgen/configured_feature/tree/palm_entry.json`）里**有 `fallen_log`/`fallen_leaves`，但没有 `bush_log`/`bush_leaves`、也没有 `old_growth_tree`**；气候窗口 `min_temperature: 17.6`（热带）。

### H-4.12　森林聚合 feature

`jar-extract/data/tfc/worldgen/configured_feature/forest.json`：
```json
{"type":"tfc:forest","config":{"entries":"#tfc:forest_trees"}}
```
`jar-extract/data/tfc/worldgen/placed_feature/forest.json`：
```json
{"feature":"tfc:forest","placement":[]}
```
> `placement` 为空数组是合法的：`tfc:forest` 自己按**区块**生成（origin 取 `chunkBlockPos`），不依赖 placement modifier 提供坐标。

它被挂在 `large_features/<biome>` tag 上（例：`jar-extract/data/tfc/tags/worldgen/placed_feature/in_biome/large_features/plains.json`）：
```json
{"replace":false,"values":["tfc:forest","tfc:rare_bamboo","tfc:bamboo","tfc:rare_bamboo_golden","tfc:bamboo_golden","tfc:cave_vegetation","#tfc:feature/surface_flood_fill_lakes"]}
```

### H-4.13　植物的"总汇" tag

`jar-extract/data/tfc/tags/worldgen/placed_feature/feature/land_plants.json`（`replace:false`，前几项）：
```json
{"replace":false,"values":["tfc:plant/hanging_vines","tfc:plant/hanging_vines_cave","tfc:plant/spanish_moss","tfc:plant/saguaro_patch","tfc:plant/jungle_vines","tfc:plant/liana","tfc:plant/moss_cover","tfc:plant/reindeer_lichen_cover","tfc:plant/morning_glory_cover","tfc:plant/philodendron_cover","tfc:plant/tree_fern","tfc:plant/arundo","tfc:plant/flame_vine","tfc:plant/cycad","#tfc:feature/crops","#tfc:feature/forest_plants","tfc:plant/arundo_forest","tfc:surface_grasses","tfc:plant/allium_patch","…（其余 200+ 项）"]}
```
`jar-extract/data/tfc/tags/worldgen/placed_feature/feature/crops.json` 收录全部 29 个 `tfc:plant/wild_crop/*_patch`。
`jar-extract/data/tfc/tags/worldgen/placed_feature/feature/fruit_trees.json` 收录 9 个果树：`banana, cherry, green_apple, red_apple, lemon, olive, orange, peach, plum`。

**实测统计**：125 个 biome 中，`in_biome/surface_decoration/<biome>.json` 里有 **99 个**直接引用 `#tfc:feature/land_plants` —— 这就是"往大片 TFC 群系里加植物"的挂载点。

---

## H-5　placed_feature 完整参数表

`PlacedFeature` 的 JSON 顶层只有两个字段：`feature`（configured_feature id / 内联对象 / `#tag`）与 `placement`（modifier 数组，按顺序执行过滤）。

### H-5.1　原版 placement modifier（TFC 数据中最常用的 7 个）

| `type` | 字段 | 语义与 TFC 用法 |
|---|---|---|
| `minecraft:count` | `count`（int 或 `IntProvider`） | 每区块尝试次数；TFC 植物数据里**很少直接用**，多靠 `random_patch` 的 `tries` |
| `minecraft:rarity_filter` | `chance`（int） | 1/chance 概率保留。TFC 大量使用：野草 `chance:3`、灌木 `chance:22`、野生作物成片 `chance:90` |
| `minecraft:in_square` | 无 | 在区块内随机偏移（x/z 0~15）。TFC 几乎每个植物 placed 都带 |
| `minecraft:heightmap` | `heightmap`（枚举） | TFC 常用 `WORLD_SURFACE_WG`（陆生）与 `OCEAN_FLOOR_WG`（水生/海底） |
| `minecraft:block_predicate_filter` | `predicate` | 通用谓词过滤，配合 TFC 自定义谓词（见 [H-5.2]） |
| `minecraft:biome` | 无 | 只在指定 biome（在 biome 有 tag 时被隐式处理）；TFC 数据里未观察到显式使用 |
| `minecraft:random_offset` | `xz_spread` / `y_spread`（`IntProvider`） | 随机偏移；TFC 的 `*_patch` 结构把偏移放在 configured 的 `random_patch` 里而非此处 |

> `surface_relative_threshold_filter`：**本次在 TFC 的 `worldgen` 数据中未检索到使用**（`jar-extract/data/tfc/worldgen/placed_feature/` 全量文本检索未命中）。
> 该 modifier 属原版，TFC 改用自定义的 `tfc:climate` 海拔区间（`min_elevation`/`max_elevation`）与 `tfc:flat_enough` 实现同类效果。**如后续需要精确结论请再核**。

### H-5.2　TFC 自定义 block predicate（`TFC-decompiled/world/blockpredicate/TFCBlockPredicates.java:29-33`）

| 注册名 | 类 | JSON 形式 | 语义 | 源码 |
|---|---|---|---|---|
| `tfc:air_or_empty_fluid` | `AirOrEmptyFluidPredicate` | `{"type":"tfc:air_or_empty_fluid"}`（**无字段**） | `FluidHelpers.isAirOrEmptyFluid(state)`：空气或"空流体"（TFC 的流体日志方块） | `AirOrEmptyFluidPredicate.java:21-38` |
| `tfc:would_survive_with_fluid` | `WouldSurviveWithFluidPredicate` | `{"type":"tfc:would_survive_with_fluid","offset":[0,0,0],"state":{...}}` | 先把 `state` 用该处流体灌水，再 `canSurvive` | `WouldSurviveWithFluidPredicate.java:35-50` |
| `tfc:replaceable` | `ReplaceablePredicate` | `{"type":"tfc:replaceable"}` | `EnvironmentHelpers.isWorldgenReplaceable(level,pos)` | `ReplaceablePredicate.java:21-38` |
| `tfc:dry_replaceable` | `DryReplaceablePredicate` | `{"type":"tfc:dry_replaceable"}` | `isWorldgenReplaceable && 流体为空` | `DryReplaceablePredicate.java:23-40` |

`tfc:would_survive_with_fluid` 的字段表：

| 字段 | 类型 | 必填/默认 | 语义 |
|---|---|---|---|
| `offset` | `Vec3i`（`Vec3i.offsetCodec(16)`，即每个分量 ∈ [-16,16]） | 可选，默认 `[0,0,0]` | 相对偏移 |
| `state` | `BlockState` | 必填 | 待校验的状态 |

### H-5.3　TFC 自定义 placement modifier 全 15 项（`TFC-decompiled/world/placement/TFCPlacements.java:38-53`）

> 实测确认：`TFCPlacements` 恰好 **15** 个 `Id` 常量（`TFCPlacements.java:39-53`），与任务描述一致。

| # | 注册名 | 类 | JSON 字段（名称 / 类型 / 默认） | 语义 | 源码 |
|---|---|---|---|---|---|
| 1 | `tfc:flat_enough` | `FlatEnoughPlacement` | `flatness` float 0~1 默认 **0.5**；`radius` 正整数 默认 **2**；`max_depth` 正整数 默认 **4** | 在深度 0..max_depth-1 中找第一个「非空气非流体的方块占比 > flatness」的层，返回该 y | `FlatEnoughPlacement.java:39-77` |
| 2 | `tfc:underground` | `UndergroundPlacement` | 无字段（`MapCodec.unit`） | `pos.y < WORLD_SURFACE_WG 高度` 才通过 | `UndergroundPlacement.java:25-37` |
| 3 | `tfc:carving_mask` | `BoundedCarvingMaskPlacement` | `min_y` `VerticalAnchor` 默认 **bottom**；`max_y` `VerticalAnchor` 默认 **top**；`step` `GenerationStep.Carving` **必填** | 输出该区块雕刻掩码内的 y 区间内所有坐标 | `BoundedCarvingMaskPlacement.java:39-63` |
| 4 | `tfc:climate` | `ClimatePlacement` | 见 [H-5.4] | 用 `ChunkData` 的气候/森林类型筛选 | `ClimatePlacement.java:44-171` |
| 5 | `tfc:intertidal` | `IntertidalPlacement` | `min_elevation` int 默认 **-64**；`max_elevation` int 默认 **320** | `pos.y - 高潮位噪声` 落在区间内（潮间带） | `IntertidalPlacement.java:34-70` |
| 6 | `tfc:volcano` | `CinderConePlacement` | `center` bool 默认 false；`min_easing` float 默认 0.0；`max_easing` float 默认 1.0（共用 `CenterOrDistanceToPlacement.codec`） | 火山渣锥中心或缓动区间 | `CinderConePlacement.java:19-34`、`CenterOrDistanceToPlacement.java:50-52` |
| 7 | `tfc:tuff_cone` | `TuffRingPlacement` | 同上三个字段 | 凝灰岩环 | `TuffRingPlacement.java:19-34` |
| 8 | `tfc:tuya` | `TuyaPlacement` | 同上三个字段 | 冰下平顶火山 | `TuyaPlacement.java:19-34` |
| 9 | `tfc:stratovolcano` | `StratovolcanoPlacement` | `center` bool 默认 false；`use_offset_center` bool 默认 false；`variant` string 默认 `"all"`；`min_easing` float 默认 0.0；`max_easing` float 默认 1.0；`hash_min` float 默认 0.0；`hash_max` float 默认 1.0 | 层状火山锥体 | `StratovolcanoPlacement.java:51-53` |
| 10 | `tfc:atoll` | `AtollPlacement` | `center`/`min_easing`/`max_easing` | 环礁 | `AtollPlacement.java:19-34` |
| 11 | `tfc:near_fluid` | `NearFluidPlacement` | `radius` 非负 int 默认 **2**；`fluids` 流体列表 默认 **null（=任意流体）** | 在 `radius³` 盒内向下搜索，找到目标流体才通过 | `NearFluidPlacement.java:42-72` |
| 12 | `tfc:shallow_water` | `ShallowWaterPlacement` | `min_depth` 正整数 默认 **0**；`max_depth` 正整数 默认 **5** | 向下数水深（`#tfc:any_infinite_water`），深度落在区间并按 `random > i/max_depth` 概率保留 | `ShallowWaterPlacement.java:35-62` |
| 13 | `tfc:on_top` | `OnTopPlacement` | `predicate` `BlockPredicate` **必填** | 谓词对 `pos.below()` 成立才通过 | `OnTopPlacement.java:31-47` |
| 14 | `tfc:no_solid_neighbors` | `NoSolidNeighborsPlacement` | 无字段（`MapCodec.unit`） | 4 个水平邻居**没有**「不可替换且不在 `#tfc:can_be_snow_piled`」的方块时通过 | `NoSolidNeighborsPlacement.java:34-59` |
| 15 | `tfc:ocean_ridge` | `OceanRidgePlacement` | `min_distance` int 默认 `Integer.MIN_VALUE`；`max_distance` int 默认 `Integer.MAX_VALUE` | 洋中脊到扭曲边缘的距离区间 | `OceanRidgePlacement.java:32-55` |

⚠️ 字段类型注解提醒（源码实测）：`shallow_water.min_depth/max_depth`、`flat_enough.radius/max_depth` 用 `Codecs.POSITIVE_INT`（≥1），
但**默认值写的是 0 / 2 / 4**。因此显式写 `"min_depth": 0` 会解码失败，而不写该字段则得到 0（`ShallowWaterPlacement.java:37`、`FlatEnoughPlacement.java:41`）。**推断**：生成器侧容错，手写 JSON 时请避开显式 0。

### H-5.4　`tfc:climate` 逐字段表（`TFC-decompiled/world/placement/ClimatePlacement.java:46`）

| 字段 | 类型 | 默认 | 语义 |
|---|---|---|---|
| `min_temperature` | float | `-∞` | 比较用**年均温**下界（已按海拔校正：`EnvironmentHelpers.adjustAvgTempForElev`） |
| `max_temperature` | float | `+∞` | 年均温上界 |
| `min_groundwater` | float | `-∞` | 地下水（或降雨，见 `ignore_rivers`）下界 |
| `max_groundwater` | float | `+∞` | 地下水上界 |
| `min_rain_variance` | float | `-1.0` | 降雨方差下界 |
| `max_rain_variance` | float | `1.0` | 降雨方差上界 |
| `rain_variance_absolute` | boolean | `false` | true = 取 `abs(降雨方差)`（南半球镜像统一）；false = 按半球取符号 |
| `min_forest` | 非负 int | `0` | 森林密度下界（`ForestType.getDensity()`） |
| `max_forest` | 非负 int | `4` | 森林密度上界 |
| `forest_types` | `ForestType` 列表 | `[]`（空=不限） | 限定森林类型 |
| `min_elevation` | int | `-64` | y 下界 |
| `max_elevation` | int | `320` | y 上界 |
| `fuzzy` | boolean | `false` | 边缘模糊：以 `random² > max(归一化偏移)` 的概率在区间边缘衰减（`ClimatePlacement.java:152-157`） |
| `ignore_rivers` | boolean | `false` | true 时用 `getAverageRainfall` 而不是 `getAverageGroundwater`（`ClimatePlacement.java:149`） |

### H-5.5　典型 placement 组合（实测，可直接照抄）

| 用途 | placement 数组 | 来源 |
|---|---|---|
| 陆生野草/野花（单株） | `heightmap(WORLD_SURFACE_WG)` → `block_predicate_filter(tfc:air_or_empty_fluid)` → `block_predicate_filter(would_survive)` | `placed_feature/plant/bluegrass.json` |
| 陆生野草（成片） | `in_square` → `heightmap(WORLD_SURFACE_WG)` → `tfc:climate` | `placed_feature/plant/bluegrass_patch.json` |
| 水生/挺水 | `heightmap(OCEAN_FLOOR_WG)` → `block_predicate_filter(would_survive_with_fluid)` | `placed_feature/plant/cattail.json` |
| 需要靠水 | `heightmap(WORLD_SURFACE_WG)` → `rarity_filter(3)` → `in_square` → `tfc:climate` → `tfc:near_fluid{radius:6, fluids:[...]}` → `block_predicate_filter(tfc:air_or_empty_fluid)` | `placed_feature/plant/arundo.json` |
| 野果灌木 | `tfc:climate`（**放在最前**） → `heightmap(WORLD_SURFACE_WG)` → `in_square` → `rarity_filter(22)` | `placed_feature/plant/blueberry_bush.json` |
| 果树 | `tfc:climate` → `heightmap(WORLD_SURFACE_WG)` → `in_square` → `rarity_filter(50)` | `placed_feature/plant/cherry.json` |
| 野生作物成片 | `rarity_filter(90)` → `in_square` → `tfc:climate` | `placed_feature/plant/wild_crop/barley_patch.json` |
| 森林（区块级） | `[]`（空） | `placed_feature/forest.json` |

### H-5.6　实测使用频次（全量检索 `jar-extract/data/tfc/worldgen/placed_feature/`）

**placement modifier 实际被使用的次数**（按 `"type":"..."` 统计；同一文件多次出现分别计入）：

| modifier | 次数 | 备注 |
|---|---|---|
| `minecraft:heightmap` | 430 | 最基础 |
| `minecraft:in_square` | 284 | |
| `tfc:climate` | 249 | TFC 的核心筛选器 |
| `minecraft:rarity_filter` | 237 | |
| `tfc:stratovolcano` | 39 | |
| `minecraft:count` | 31 | |
| `minecraft:height_range` | 24 | |
| `tfc:intertidal` | 19 | |
| `tfc:no_solid_neighbors` | 13 | |
| `minecraft:noise_based_count` | 10 | |
| `tfc:carving_mask` / `tfc:volcano` / `tfc:tuya` | 各 7 | |
| `minecraft:random_offset` | 6 | |
| `tfc:flat_enough` | 6 | |
| `tfc:shallow_water` | 5 | |
| `minecraft:clamped_normal` | 4 | |
| `tfc:atoll` | 4 | |
| `tfc:near_fluid` / `tfc:on_top` / `minecraft:environment_scan` | 各 2 | |
| `tfc:ocean_ridge` | 1 | |
| **`tfc:tuff_cone`** | **0** | 注册了但数据里未使用 |
| **`tfc:underground`** | **0** | 注册了但数据里未使用 |
| **`minecraft:surface_relative_threshold_filter`** | **0** | **确认 TFC 未使用**（见 [H-10] 2） |

**block predicate 实际被使用的次数**（包含 `block_predicate_filter` 内联与 `tfc:on_top` 的 `predicate`）：

| predicate | 次数 |
|---|---|
| `tfc:air_or_empty_fluid` | 139 |
| `tfc:replaceable` | 60 |
| `tfc:would_survive_with_fluid` | 28 |
| `tfc:dry_replaceable` | 1 |
| `minecraft:matching_blocks` / `minecraft:matching_block_tag` / `minecraft:solid` | 各 2 |

**TFC 自定义 configured_feature 类型在数据中的使用次数**（前 20）：

| type | 次数 | | type | 次数 |
|---|---|---|---|---|
| `tfc:random_property`（state provider） | 87 | | `tfc:emergent_plant` | 9 |
| `tfc:random_tree` | 52 | | `tfc:fruit_trees` | 8 |
| `tfc:forest_entry` | 40 | | `tfc:tall_wild_crop` | 6 |
| `tfc:cluster_vein` | 33 | | `tfc:krummholz` | 5 |
| `tfc:tall_plant` | **21** | | `tfc:twisting_vines` | 5 |
| `tfc:dynamic_random_patch` | 20 | | `tfc:epiphyte_plant` | 5 |
| `tfc:block_with_fluid` | 18 | | `tfc:weeping_vines` | 5 |
| `tfc:disc_vein` | 13 | | `tfc:spreading_bush` | 4 |
| `tfc:flood_fill_lake` | 12 | | `tfc:creeping_ocean_plant` | 4 |
| `tfc:soil_disc` | 12 | | `tfc:bamboo` | 4 |
| `tfc:creeping_plant` | 12 | | `tfc:rotatable_water_plant` | 3 |
| — | — | | `tfc:spreading_crop` / `tfc:kelp` / `tfc:vines` / `tfc:overlay_tree` / `tfc:stacked_tree` | 各 2 |

> **对附属模组的启示**：植物侧最"标准"的配方就是 `tfc:climate` + `minecraft:heightmap` + `minecraft:in_square` + `minecraft:rarity_filter` + 1~2 个 `tfc:*` predicate。

---

## H-6　这些 feature 如何被挂到生物群系

### H-6.1　biome JSON 的 `features` 数组 = 按索引对应 generation step

`jar-extract/data/tfc/worldgen/biome/plains.json` 的 `features` 字段（原文，已去掉 spawners 等内容）：
```json
"features":["#tfc:in_biome/erosion","#tfc:in_biome/all_lakes","#tfc:in_biome/soil_discs/plains","#tfc:in_biome/underground_structures","#tfc:in_biome/surface_structures","#tfc:in_biome/strongholds","#tfc:in_biome/veins","#tfc:in_biome/underground_decoration","#tfc:in_biome/large_features/plains","#tfc:in_biome/surface_decoration/plains","#tfc:in_biome/top_layer_modification"]
```

对应关系（**11 项版本**，与 `neoforge-src/net/minecraft/world/level/levelgen/GenerationStep.java:28-39` 的枚举顺序逐一吻合）：

| 索引 | TFC 的 tag | `GenerationStep.Decoration` | ordinal | 放什么 |
|---|---|---|---|---|
| 0 | `#tfc:in_biome/erosion` | `RAW_GENERATION` | 0 | 地形侵蚀 |
| 1 | `#tfc:in_biome/all_lakes` 或 `#tfc:in_biome/underground_lakes` | `LAKES` | 1 | 湖 |
| 2 | `#tfc:in_biome/soil_discs/<biome>` | `LOCAL_MODIFICATIONS` | 2 | 土壤圆盘 |
| 3 | `#tfc:in_biome/underground_structures` | `UNDERGROUND_STRUCTURES` | 3 | — |
| 4 | `#tfc:in_biome/surface_structures` | `SURFACE_STRUCTURES` | 4 | — |
| 5 | `#tfc:in_biome/strongholds` | `STRONGHOLDS` | 5 | — |
| 6 | `#tfc:in_biome/veins` | `UNDERGROUND_ORES` | 6 | 矿脉 |
| 7 | `#tfc:in_biome/underground_decoration` | `UNDERGROUND_DECORATION` | 7 | 洞穴植物（`tfc:cave_vegetation` 除外，见下） |
| 8 | `#tfc:in_biome/large_features/<biome>` | `FLUID_SPRINGS` | 8 | **森林 `tfc:forest`、竹子、洞穴植被、地表淹水湖** |
| 9 | `#tfc:in_biome/surface_decoration/<biome>` | `VEGETAL_DECORATION` | 9 | **所有地表植物（`#tfc:feature/land_plants`）** |
| 10 | `#tfc:in_biome/top_layer_modification` | `TOP_LAYER_MODIFICATION` | 10 | 顶层修饰（雪/冰等） |

**关键结论：TFC 的植物生成在 index 9（= 原版 `vegetal_decoration`），树在 index 8（= 原版 `fluid_springs`，TFC 借用该空槽位）。**

### H-6.2　实测：数组长度并非固定 11 —— 12 项与 13 项也存在

对 125 个 biome 实测统计（`jar-extract/data/tfc/worldgen/biome/*.json`，`features.Count`）：

| 长度 | 数量 | 说明 |
|---|---|---|
| 11 | 57 | 标准布局（plains、hills、deep_ocean、shore…） |
| 12 | 55 | 在 index 6 之后**多插一层 `#tfc:in_biome/veins/<变体>`**（`veins/kaolin`、`veins/river`、`veins/montane` 之一） |
| 13 | 13 | 多插**两层**（例：`collisional_mountains` = `veins/montane` + `veins/collisional_mountains`；`tower_karst_lake` = `veins/river` + `veins/montane`） |

例（`jar-extract/data/tfc/worldgen/biome/badlands.json`，12 项）：
```json
["#tfc:in_biome/erosion","#tfc:in_biome/underground_lakes","#tfc:in_biome/soil_discs/badlands","#tfc:in_biome/underground_structures","#tfc:in_biome/surface_structures","#tfc:in_biome/strongholds","#tfc:in_biome/veins","#tfc:in_biome/veins/kaolin","#tfc:in_biome/underground_decoration","#tfc:in_biome/large_features/badlands","#tfc:in_biome/surface_decoration/badlands","#tfc:in_biome/top_layer_modification"]
```

**为什么能超过 11 项？** —— 因为原版 `BiomeGenerationSettings` 的 `features` 是「列表的列表」，长度不受 `Decoration` 枚举数量限制：
- `neoforge-src/net/minecraft/world/level/biome/BiomeGenerationSettings.java:45-48`：`PlacedFeature.LIST_OF_LISTS_CODEC.fieldOf("features")`；
- `neoforge-src/net/minecraft/world/level/biome/FeatureSorter.java:44`：`i = Math.max(i, list1.size());`（**取所有 biome 的最大层数**）；
- 同文件 `:103`：`for (int l = 0; l < i; l++)`（**逐层遍历，层数由数据决定**）。

**这正是附属模组必须知道的副作用**：多插一层会让**其后所有层的索引整体右移**，
所以「靠 `BiomeModifier` 的 `step` 指定索引」在不同 biome 上落点不同（见 [H-6.4]）。

### H-6.3　TFC 自定义群系与 `TFCBiomes.EXTENSIONS`

- `TFCBiomes.KEY = ResourceKey.createRegistryKey("tfc:biome_extension")`，`REGISTRY` 为该注册表实例，`EXTENSIONS = DeferredRegister.create(KEY, "tfc")`（`TFC-decompiled/world/biome/TFCBiomes.java:59-61`）。
- 每个 `BiomeExtension` 同时绑定一个同名 `Biome`（`ResourceKey.create(Registries.BIOME, name)`），注册时二者同名（`TFCBiomes.java:207-211`）。
- `Biome` 与 `BiomeExtension` 的绑定靠 mixin：`BiomeMixin implements BiomeBridge`（`TFC-decompiled/mixin/BiomeMixin.java:45-58`），通过 biome id 去 `REGISTRY` 里查同名 extension（`TFCBiomes.java:203-205`）。
- **群系源**：`RegionBiomeSource` 的 codec 无字段（`RegionBiomeSource.java:46`），possibleBiomes 为 `TFCBiomes.REGISTRY.stream()`（`RegionBiomeSource.java:86`）。

**结论**：附属模组**可以**注册自己的 `BiomeExtension`（`TFCBiomes.EXTENSIONS` 是 public 的 `DeferredRegister`），
但它只会出现在 possibleBiomes 列表里；**具体地形位置由 `RegionGenerator` 的硬编码气候/区域规则决定**，
TFC 没有提供「注册新群系并参与区域划分」的数据驱动接口。因此**不推荐**通过新增 TFC 群系的方式加植物，**推荐往已有群系的 tag 里追加**（见 [H-9]）。

### H-6.4　附属模组往已有群系加植物的三种写法（按推荐度排序）

#### 方案 A（**强烈推荐**）：往 TFC 的 placed_feature tag 里追加

原理：**Minecraft 的 tag 是"合并"语义** —— 多个数据包/模组提供同一 tag id 时，`"replace": false` 的条目会被**合并**而不是覆盖。
TFC 自己所有 tag 文件都写了 `"replace":false`（例：`jar-extract/data/tfc/tags/worldgen/placed_feature/feature/land_plants.json`）。

做法：你的模组提供

```
data/tfc/tags/worldgen/placed_feature/feature/land_plants.json
```
```json
{ "replace": false, "values": ["mymod:plant/my_flower_patch"] }
```

即可让 `mymod:plant/my_flower_patch` 出现在所有引用 `#tfc:feature/land_plants` 的 **99 个群系**里（`jar-extract/data/tfc/tags/worldgen/placed_feature/in_biome/surface_decoration/*.json` 实测 99 个引用它）。

若要更精细，也可以只针对单个群系：

```
data/tfc/tags/worldgen/placed_feature/in_biome/surface_decoration/plains.json
```
```json
{ "replace": false, "values": ["mymod:plant/my_flower_patch"] }
```

优点：**不碰 biome JSON、不影响其它层索引、零冲突**、与 TFC 植物同层同顺序。
风险：你会往 `tfc:` 命名空间写文件（tag 是 id 合并，不会覆盖 TFC 的同名文件内容，但仍属"跨命名空间写入"，少数整合包校验工具会警告）。

#### 方案 B（可用，注意索引漂移）：NeoForge `BiomeModifier`

`neoforge:add_features` 是 NeoForge 21.1 的**标准且可用** API（不是已废弃的 Forge 旧接口）：
- 接口：`neoforge-src/net/neoforged/neoforge/common/world/BiomeModifier.java:19-35`（“JSON-serializable biome modifier”）
- 内置实现：`neoforge-src/net/neoforged/neoforge/common/world/BiomeModifiers.java:29-47`

```json
{
  "type": "neoforge:add_features",
  "biomes": "#minecraft:is_overworld",
  "features": ["mymod:plant/my_flower_patch"],
  "step": "vegetal_decoration"
}
```

它如何落位：`BiomeModifiers.AddFeaturesBiomeModifier.modify` → `BiomeGenerationSettingsBuilder.addFeature(step, holder)`
→ 继承自 `PlainBuilder.addFeature(ordinal, holder)`（`neoforge-src/net/neoforged/neoforge/common/world/BiomeGenerationSettingsBuilder.java:16-37` 与
`neoforge-src/net/minecraft/world/level/biome/BiomeGenerationSettings.java:117-125`）。
**即：`step` 直接映射到 biome `features` 数组的索引 `ordinal`（0~10）。**

于是在 TFC 世界里会出现索引漂移：

| `step` 写成 | 11 项 biome 落入 | 12 项 biome 落入 | 13 项 biome 落入 |
|---|---|---|---|
| `vegetal_decoration` (9) | `surface_decoration`（**植物层，理想**） | `large_features`（森林层，比理想早一层） | `underground_decoration` |
| `fluid_springs` (8) | `large_features`（森林层） | `underground_decoration` | `large_features` |
| `top_layer_modification` (10) | `top_layer_modification` | `surface_decoration`（植物层） | `large_features` |

**实践结论**：用方案 B 时，植物一般仍会生成（都处在地形之后的地表阶段），但**层序可能与 TFC 原生植物不一致**，
在 12/13 项 biome（badlands、canyons、active_shield_volcano、多数山地/高原）里可能被树木覆盖或覆盖树木。
若你要严格对齐 TFC 原生植物层，请用方案 A，或对 `step` 做「按群系分派」。

#### 方案 C（不推荐 / 危险）：覆盖 `data/tfc/worldgen/biome/*.json`

不要这样做：biome 文件是**同 id 整文件覆盖**语义，你会把 TFC 的 125 个 biome 之一整体替换掉，
丢失 `carvers`、`spawners`（约 45 个 TFC 动物条目）、`effects` 等；且与其它做同样事情的模组**互斥**（后加载者胜）。
本次未实测「模组 jar 与 TFC jar 同 id 文件谁胜出」，但**语义上必然是覆盖而非合并**，因此不建议。

---

## H-7　野生作物与栽培作物的关系

### H-7.1　`Crop` 枚举与 `createWild()`

`Crop` 枚举（`TFC-decompiled/common/blocks/crop/Crop.java:49-183`）共 **29** 个常量
（`Crop.java:177`：`CASSAVA, GREEN_BEAN, LENTIL, PEANUT, SOYBEAN, BARLEY, OAT, RYE, MAIZE, WHEAT, RICE, BEET, CABBAGE, CARROT, GARLIC, ONION, POTATO, SQUASH, TOMATO, RED_BELL_PEPPER, YELLOW_BELL_PEPPER, PUMPKIN, MELON, CANOLA, RADISH, ALFALFA, JUTE, PAPYRUS, SUGARCANE`）。

每个 `Crop` 有**三套**方块工厂（`Crop.java:85-88, 148-158`）：

| 方法 | 返回 | 注册位置 |
|---|---|---|
| `create()` | 栽培作物方块（`DefaultCropBlock`/`DoubleCropBlock`/`SpreadingCropBlock`/`FloodedCropBlock`/`PickableCropBlock`/`ClimbingCropBlock`…） | `TFCBlocks.CROPS` → `tfc:crop/<name>`（`TFCBlocks.java:288`） |
| `createDead()` | 枯死方块（`DeadCropBlock` 等） | `TFCBlocks.DEAD_CROPS` → `tfc:dead_crop/<name>`（`TFCBlocks.java:289`） |
| `createWild()` | **野生方块** | `TFCBlocks.WILD_CROPS` → `tfc:wild_crop/<name>`（`TFCBlocks.java:290`） |

野生方块的类型由 `Crop` 的构造器分支决定（`Crop.java:110-133`）：

| 构造器分支（`Crop.java`） | `createWild()` 返回 | 对应 feature |
|---|---|---|
| `Crop(n,p,k, singleBlockStages)` : 110 | `WildCropBlock` | `minecraft:simple_block` |
| `Crop(n,p,k, spreadingSingleBlockStages, fruit)` : 114 | `WildSpreadingCropBlock` | `tfc:spreading_crop` |
| `Crop(n,p,k, spreadingSingleBlockStages, fruit1, fruit2)` : 118 | `WildCropBlock`（可采果实的作物野生态仍是单格） | `minecraft:simple_block` |
| `Crop(n,p,k, floodedSingleBlockStages, flooded)` : 122 | `FloodedWildCropBlock`（水稻） | `minecraft:simple_block` + 流体灌水 |
| `Crop(n,p,k, doubleBlockBottomStages, doubleBlockTopStages, requiresStick)` : 131 / `(..., fruit1, fruit2)` : 127 | `WildDoubleCropBlock` | `tfc:tall_wild_crop` |

**注册名大小写**：`TFCBlocks.java:290` 用的是 `"wild_crop/" + crop.name()`（枚举名，大写），
但 `RegistrationHelpers.registerBlock` 内部 `name.toLowerCase(Locale.ROOT)`（`TFC-decompiled/util/registry/RegistrationHelpers.java:67-74`），
所以最终 id 是**小写**：`tfc:wild_crop/barley`、`tfc:crop/green_bean` 等。附属模组自己注册时同样要保证全小写。

### H-7.2　野生方块的交互与生长

- **`WildCropBlock`**（`TFC-decompiled/common/blocks/crop/WildCropBlock.java:50-108`）：
  - 状态属性只有 `MATURE`（`TFCBlockStateProperties.MATURE`，`WildCropBlock.java:53`）；
  - `canSurvive` 要求下方是 `#tfc:wild_crop_grows_on`（= `#minecraft:dirt`，见 `jar-extract/data/tfc/tags/block/wild_crop_grows_on.json`）；
  - `randomTick` 只在 `MATURE` 与当前月份不符时 `cycle(MATURE)`（`WildCropBlock.java:75-79`）；
  - **成熟由日历决定**：`isMature()` 用 `TFCConfig.SERVER.wildCropMaturityStartMonth/EndMonth` 之间的月份判定（`WildCropBlock.java:55-63`）；
  - 实现 `ISpecialPile`，被雪/冰掩埋时隐藏（`WildCropBlock.java:85-94`）。
- **`WildDoubleCropBlock`**（`WildDoubleCropBlock.java:63-160`）：额外 `PART`（top/bottom）；`randomTick` 会同步另一半的 `MATURE`（`:97-110`）；`placeTwoHalves(level,pos,flags)`（`:157-160`）正是 `TallWildCropFeature` 调用的方法。
- **`WildSpreadingCropBlock`**（`WildSpreadingCropBlock.java:35-74`）：实现 `HorizontalPipeBlock`，带 N/S/E/W 四个布尔属性表示相邻果实；`getFruit()`（`:72-74`）供 `SpreadingCropFeature` 取果实方块。

### H-7.3　破坏掉落：**普通战利品表，不是自定义 loot function**

- 掉落表目录：`jar-extract/data/tfc/loot_table/blocks/wild_crop/` 共 **29** 个文件（与 `Crop` 数量一致）。
- 实测未发现任何 TFC 自定义 loot function（例如所谓 `CropYieldProvider`）参与野生作物掉落。**结论：不存在这样的 loot function**（在 `jar-extract/data/tfc/loot_table/blocks/wild_crop/` 全量检索与 `TFC-decompiled` 中 loot function 注册表检索均未命中）。
- 真实样例（`jar-extract/data/tfc/loot_table/blocks/wild_crop/barley.json`，单行原文）：
```json
{"type":"minecraft:block","pools":[{"name":"loot_pool","rolls":1,"entries":[{"type":"minecraft:item","name":"tfc:food/barley","conditions":[{"condition":"minecraft:block_state_property","block":"tfc:wild_crop/barley","properties":{"mature":"true"}}],"functions":[{"function":"minecraft:set_count","count":{"min":1,"max":3,"type":"minecraft:uniform"}}]}],"conditions":[{"condition":"minecraft:survives_explosion"}]},{"name":"loot_pool","rolls":1,"entries":[{"type":"minecraft:item","name":"tfc:seeds/barley","functions":[{"function":"minecraft:set_count","count":{"type":"minecraft:uniform","min":2,"max":3}}]}],"conditions":[{"condition":"minecraft:survives_explosion"}]}]}
```
  要点：**两个 pool** —— ①「成熟才掉的食物」用 `block_state_property{mature:true}` 作条件；②「种子」无条件掉 2~3。
- 两格作物的掉落表额外要求 `part: bottom`（`jar-extract/data/tfc/loot_table/blocks/wild_crop/green_bean.json`）：
```json
{"type":"minecraft:block","pools":[{"name":"loot_pool","rolls":1,"entries":[{"type":"minecraft:item","name":"tfc:food/green_bean","conditions":[{"condition":"minecraft:block_state_property","block":"tfc:wild_crop/green_bean","properties":{"part":"bottom","mature":"true"}}],"functions":[{"function":"minecraft:set_count","count":{"min":1,"max":3,"type":"minecraft:uniform"}}]}],"conditions":[{"condition":"minecraft:survives_explosion"}]},{"name":"loot_pool","rolls":1,"entries":[{"type":"minecraft:item","name":"tfc:seeds/green_bean","conditions":[{"condition":"minecraft:block_state_property","block":"tfc:wild_crop/green_bean","properties":{"part":"bottom"}}]}],"conditions":[{"condition":"minecraft:survives_explosion"}]}]}
```
- 两格作物在创造模式破坏时会连带清除另一半（`WildDoubleCropBlock.onPlayerWillDestroy`，`:67-80`）。
- 匍匐作物的**果实**由 `SpreadingCropFeature` 放置时就挂了 `FoodTraits.WILD` 腐坏标签（`SpreadingCropFeature.java:62-68`），
  玩家取走果实后靠 `DecayingBlockEntity` 腐烂。

---

## H-8　树的生成

### H-8.1　木材枚举与 `TreeGrower`（**种苗长树**路径）

- `RegistryWood` 接口声明 `TreeGrower tree();`（`TFC-decompiled/util/registry/RegistryWood.java:29`）。
- `Wood` 枚举（`TFC-decompiled/common/blocks/wood/Wood.java`）持有一个 `TreeGrower` 字段（`:141`），构造为：
```java
this.tree = new TreeGrower(
    Helpers.identifier(this.serializedName).toString(),
    Optional.empty(),
    Optional.of(ResourceKey.create(Registries.CONFIGURED_FEATURE, Helpers.identifier("tree/" + this.serializedName))),
    Optional.empty());
```
  （`Wood.java:152`）→ **种苗长出的树 feature id = `tfc:tree/<wood>`**（例：`tfc:tree/acacia`，即 `RandomTreeConfig` 的那一个，**不是** `*_entry`）。
- `TreeGrower` 被塞进 `TFCSaplingBlock`（`Wood.java:235`；`TFCSaplingBlock.java:63`），
  生长计时由 `TFCConfig.SERVER.saplingGrowthTicks` / `saplingGrowthModifier` 控制（`TFCSaplingBlock.java:101`）。
- **注意分工**：世界生成的树走 **`*_entry`**（`ForestConfig.Entry`）+ `tfc:forest`；
  种苗长出的树走 **`tfc:tree/<wood>`**（无气候判断）。两者是不同的 configured_feature，但指向同一批 nbt 结构。

### H-8.2　`configured_feature/tree/` 目录结构（101 个文件，实测）

| 文件名模式 | 实测数量 | 内容 |
|---|---|---|
| `<wood>.json` | **20** | `tfc:random_tree`，普通树。实测 20 个：`acacia ash aspen birch blackwood chestnut douglas_fir hickory kapok mangrove maple oak palm pine rosewood sequoia spruce sycamore white_cedar willow` |
| `<wood>_entry.json` | **20** | `tfc:forest_entry`，森林生成用的气候条目 |
| `dead_<wood>_entry.json` | **20** | 枯林专用 entry（被 `tfc:dead_forest` 使用） |
| `<wood>_dead.json` | **20** | `tfc:random_tree`，枯树（entry 的 `dead_tree` 目标） |
| `<wood>_large.json` | **16** | `tfc:random_tree`，老树（entry 的 `old_growth_tree` 目标）；并非所有树种都有老树版本 |
| `<wood>_krummholz.json` | **5** | `tfc:krummholz`：实测恰好 5 个 —— `aspen`、`douglas_fir`、`pine`、`spruce`、`white_cedar` |
| 合计 | **101** | 20+20+20+20+16+5 = 101，与目录实测总数吻合 |

> 统计方式：`Get-ChildItem jar-extract/data/tfc/worldgen/configured_feature/tree -File` 后按后缀计数。`<wood>` 取值即 `Wood` 枚举的 `serializedName`。
> 森林收录关系：`jar-extract/data/tfc/tags/worldgen/configured_feature/forest_trees.json` 收录 **19** 个 `<wood>_entry`（**不含 `mangrove`**）；
> 红树单独走 `configured_feature/mangrove_forest.json` + tag `mangrove_forest_trees.json`。`dead_forest.json` 对应 `dead_forest_trees.json`。

**树 feature 类型的使用统计（全量文本检索 `jar-extract/data/tfc/worldgen/configured_feature/`）**：

| configured type | 使用文件数 | 文件 |
|---|---|---|
| `tfc:random_tree` | **52** | 全部 `<wood>` / `<wood>_dead` / `<wood>_large`（除下面 4 个特殊的） |
| `tfc:krummholz` | **5** | `tree/{aspen,douglas_fir,pine,spruce,white_cedar}_krummholz.json` |
| `tfc:forest_entry` | **40** | `<wood>_entry` 20 + `dead_<wood>_entry` 20 |
| `tfc:forest` | **3** | `forest.json`、`dead_forest.json`、`mangrove_forest.json` |
| `tfc:stacked_tree` | **2** | `tree/douglas_fir_large.json`、`tree/sequoia_large.json` |
| `tfc:overlay_tree` | **2** | `tree/white_cedar.json`、`tree/white_cedar_large.json` |

真实样例（`jar-extract/data/tfc/worldgen/configured_feature/tree/douglas_fir_large.json`，单行原文）：
```json
{"type":"tfc:stacked_tree","config":{"trunk":{"state":{"Name":"tfc:wood/log/douglas_fir","Properties":{"axis":"y","branch_direction":"none"}},"min_height":8,"max_height":12,"wide":true},"layers":[{"templates":["tfc:douglas_fir_large/layer1_1","tfc:douglas_fir_large/layer1_2","tfc:douglas_fir_large/layer1_3"],"min_count":2,"max_count":3},{"templates":["tfc:douglas_fir_large/layer2_1","tfc:douglas_fir_large/layer2_2","tfc:douglas_fir_large/layer2_3"],"min_count":1,"max_count":1},{"templates":["tfc:douglas_fir_large/layer3_1","tfc:douglas_fir_large/layer3_2","tfc:douglas_fir_large/layer3_3"],"min_count":1,"max_count":1}],"radius":2,"placement":{"width":2,"height":7}}}
```

真实样例（`jar-extract/data/tfc/worldgen/configured_feature/tree/white_cedar.json`，单行原文）：
```json
{"type":"tfc:overlay_tree","config":{"base":"tfc:white_cedar/base","overlay":"tfc:white_cedar/overlay","trunk":{"state":{"Name":"tfc:wood/log/white_cedar","Properties":{"axis":"y","branch_direction":"none"}},"min_height":2,"max_height":4,"wide":false},"radius":1,"placement":{"width":1,"height":5}}}
```
> 这两个样例同样带有 **`radius` 冗余字段**（`StackedTreeConfig`/`OverlayTreeConfig` 的 codec 中均无此字段，见 [H-3.9]/[H-3.8]），与 [H-3.7] 同类。

### H-8.3　树的生成流程（`RandomTreeFeature`）

`RandomTreeFeature.place()`（`TFC-decompiled/world/feature/tree/RandomTreeFeature.java:49-76`）：

1. 取 `StructurePlaceSettings`：包围盒为「当前区块 ±16」，随机 rotation/mirror，处理器为 `BlockIgnoreProcessor.STRUCTURE_AND_AIR`（`TreeHelpers.java:232-234`）；
2. 从 `structures` 列表随机取一个 nbt，`manager.getOrCreate(id)`；若模板 palette 为空 → 抛 `IllegalStateException("Empty structure: ...")`（`RandomTreeFeature.java:60-62`）；
3. `TreeHelpers.isValidLocation(...)`：`isValidGround + isValidTrunk`（`TreeHelpers.java:78-170`）；
4. 可选铺根系（`placeRoots`，失败且 `required` 则放弃）；
5. 可选先放树干并把 origin 抬高 trunk 高度（`TreeHelpers.placeTrunk`，`:184-207`；宽树干会写 4 个 `branch_direction`）；
6. 粘贴结构：`placeTemplate`（`TreeHelpers.java:172-182`）—— 只覆盖「可替换或树叶」的方块。

落地/树干校验要点（`TreeHelpers.java:99-170`）：
- 地面：`stateAt` 必须空气 / 树苗 / （允许水中时）水且空流体；下方必须 `#tfc:tree_grows_on`（=`#minecraft:dirt`），
  `ground_type=sand` 时额外允许 `#minecraft:sand`；水中时要求 `#tfc:sea_bush_plantable_on`；
- `floating` 类型：0~3 格内找到 `#tfc:bush_plantable_on` / `#tfc:sea_bush_plantable_on` / `#tfc:any_infinite_water`；
- 树干：从 y=1 到 height-1 的 `width×width` 柱体必须为空（水下模式允许空流体）。

### H-8.4　森林 feature 的树种选择算法（`ForestFeature`）

`getTrees()`（`ForestFeature.java:273-279`）：把 `entries` 全部解码成 `ForestConfig.Entry`，
按 `entry.isValid(温度, 地下水, 降雨方差, 海拔)` 过滤，再按 `entry.distanceFromMean(...)` **升序排序**（越接近气候均值越靠前）。

`getTree()`（`ForestFeature.java:281-302`）：
1. 空 → null；只有 1 个 → 直接返回；
2. 截断到 `ForestType.getMaxTreeTypes()`；
3. 按 `ForestType.getAlternateSize()` 从**头部**最贴近的若干个里剔除；
4. 从剩下的里以 0.6 概率逐步往后跳，最终随机取一个 —— 即「越靠前越可能被选中，但靠后的也有机会」。

`placeTree()`（`ForestFeature.java:101-125`）选择实际 feature 的优先级：
`krummholz`（当 `blockTemp <= entry.getClimatePlacement().getMinTemp() + 5`，概率 `clampedMap`）→
`old_growth`（主林区 `1/old_growth_chance`）→ `dead`（`1/dead_chance` 或森林类型本身就是 DEAD）→
`spoiler_old_growth`（`1/spoiler_old_growth_chance`）→ `normal_tree`。

`ForestType` 决定密度：例如 `PRIMARY_DIVERSE`（`ForestType.java:42`）`treeCount=value(7)`、`groundcover=value(40)`、`maxTreeTypes=2`；
`EDGE_MONOCULTURE`（`:52`）`treeCount=value(2)`、`maxTreeTypes=1`；`GRASSLAND`（`:31`）`treeCount=zero()`（不长树）。
每个区块还先过 `random.nextFloat() > forestType.getPerChunkChance()`（`ForestFeature.java:80`）这一关。

---

## H-9　给附属模组的落地清单

### H-9.1　目标：让「我的野生作物 / 野果灌木 / 野花」在 TFC 世界里自然生成

#### 最小文件集合（纯数据 + 少量 Java）

假设模组 id = `mymod`，新增一种植物方块 `mymod:plant/my_flower`，要在 TFC 主世界草原/丘陵等地表生成。

**(1) Java 侧（必须，因为方块得先存在）**

```
src/main/java/.../MyModBlocks.java     # DeferredRegister<Block>，注册 mymod:plant/my_flower
src/main/java/.../MyModItems.java      # BlockItem（可选但要能拿到手里）
```
注册要点：
- id 全小写；用 `DeferredRegister.create(Registries.BLOCK, "mymod")`；
- 方块类建议直接继承 TFC 的基类以复用「可被世界生成替换」语义（详见坑 4）：

```java
public class MyFlowerBlock extends TFCBushBlock {   // 或 extends WildCropBlock / SpreadingBushBlock
    public MyFlowerBlock(ExtendedProperties properties) { super(properties); }
    @Override protected boolean mayPlaceOn(BlockState state, BlockGetter level, BlockPos pos) {
        return Helpers.isBlock(state, TFCTags.Blocks.GRASS_PLANTABLE_ON);
    }
    @Override public boolean canSurvive(BlockState state, LevelReader level, BlockPos pos) {
        return Helpers.isBlock(level.getBlockState(pos.below()), TFCTags.Blocks.GRASS_PLANTABLE_ON);
    }
}
```

**(2) configured_feature（必须）**

```
src/main/resources/data/mymod/worldgen/configured_feature/plant/my_flower.json
```
```json
{
  "type": "minecraft:simple_block",
  "config": {
    "to_place": { "type": "minecraft:simple_state_provider", "state": { "Name": "mymod:plant/my_flower" } }
  }
}
```

**(3) placed_feature（必须）**

```
src/main/resources/data/mymod/worldgen/placed_feature/plant/my_flower_patch.json
```
```json
{
  "feature": "mymod:plant/my_flower",
  "placement": [
    { "type": "minecraft:rarity_filter", "chance": 8 },
    { "type": "minecraft:in_square" },
    { "type": "minecraft:heightmap", "heightmap": "WORLD_SURFACE_WG" },
    { "type": "tfc:climate", "min_temperature": -5, "max_temperature": 20, "min_groundwater": 100, "max_groundwater": 400 },
    { "type": "block_predicate_filter", "predicate": { "type": "tfc:air_or_empty_fluid" } },
    { "type": "block_predicate_filter", "predicate": { "type": "minecraft:would_survive", "state": { "Name": "mymod:plant/my_flower" } } }
  ]
}
```
（「成片」版本再包一层 `minecraft:random_patch` 的 configured_feature，并把 placed 指向它 —— 照抄 [H-4.8] 的 `*_patch` 结构。）

**(4) 挂载到群系（三选一，推荐 A）**

- **A（推荐）** 追加到 TFC 的植物总 tag：
  `src/main/resources/data/tfc/tags/worldgen/placed_feature/feature/land_plants.json`
  ```json
  { "replace": false, "values": ["mymod:plant/my_flower_patch"] }
  ```
- **A′（定向）** 只往某群系：
  `src/main/resources/data/tfc/tags/worldgen/placed_feature/in_biome/surface_decoration/plains.json`
  ```json
  { "replace": false, "values": ["mymod:plant/my_flower_patch"] }
  ```
- **B** NeoForge BiomeModifier：
  `src/main/resources/data/mymod/neoforge/biome_modifier/add_my_flower.json`
  ```json
  {
    "type": "neoforge:add_features",
    "biomes": ["tfc:plains", "tfc:hills", "tfc:lowlands"],
    "features": ["mymod:plant/my_flower_patch"],
    "step": "vegetal_decoration"
  }
  ```
  （承受 [H-6.4] 的索引漂移。`biomes` 也可写 `#minecraft:is_overworld` 或 TFC 自带的 26 个 biome tag ——
  实测清单见 `jar-extract/data/tfc/tags/worldgen/biome/`：`has_atolls`、`has_cinder_cones`、`has_predictable_winds`、`has_stratovolcanoes`、
  `has_tuff_cones`、`has_tuyas`、`is_burren`、`is_cenote`、`is_coastal_cliffs`、`is_continental_mountains`、`is_dolines`、`is_extreme_dolines`、
  `is_glaciated`、`is_ice_sheet`、`is_isolated_island`、`is_karst`、`is_nonvolcanic_mountains`、`is_ocean`、`is_oceanic_mountains`、`is_rift`、
  `is_river`、`is_salt_marsh`、`is_shield_volcano`、`is_shilin`、`is_tower_karst`、`is_volcanic_mountains`。
  **注意：没有「平原/丘陵」之类的通用地表 tag**，写具体 biome id 列表最稳。）

**(5) 若还想要生存逻辑/掉落（可选但实践中需要）**

```
src/main/resources/data/mymod/loot_table/blocks/plant/my_flower.json   # 参照 H-7.3 的两 pool 结构
src/main/resources/assets/mymod/blockstates/plant/my_flower.json
src/main/resources/assets/mymod/models/block/plant/my_flower.json
src/main/resources/assets/mymod/items/plant/my_flower.json             # 1.21.1 的 item model 定义
src/main/resources/assets/mymod/lang/en_us.json
```

**(6) 野果灌木的额外要求**：父类必须是 `SpreadingBushBlock`（否则 `tfc:spreading_bush` 的 `BlockConfig` 转换器会拒绝），
并且果实方块要有 `DecayingBlockEntity`（`SpreadingCropFeature.java:62-68` 会往里塞带 `WILD` 腐坏标签的 `ItemStack`）。

### H-9.2　坑清单（全部有源码/数据依据）

1. **`tfc:` 命名空间不能写 `worldgen/biome/*.json`、`worldgen/configured_feature/*.json` 等"整文件"资源** ——
   同 id 是覆盖语义，会整体替换 TFC 的资源并丢失其中所有内容（[H-6.4] 方案 C）。
   **唯一安全写入 `tfc:` 命名空间的东西是 tag 文件**（`data/tfc/tags/**`），因为 tag 是合并语义。
2. **注册名冲突**：`RegistrationHelpers` 会把名字 `toLowerCase(Locale.ROOT)`（`RegistrationHelpers.java:68`），
   所以 `MY_FLOWER` 与 `my_flower` 会冲突。所有 id 一律小写。
3. **`BlockConfig` 的类型强约束**：各 feature 只接受对应的 TFC 方块子类（逐条见 [H-2.1] 表），例如
   `tfc:tall_plant` → `TFCTallGrassBlock`、`tfc:tall_wild_crop` → `WildDoubleCropBlock`、`tfc:spreading_crop` → `WildSpreadingCropBlock`、
   `tfc:submerged_tall_plant` / `tfc:emergent_plant` → `TallWaterPlantBlock`、`tfc:epiphyte_plant` → `EpiphytePlantBlock`、
   `tfc:spreading_bush` → `SpreadingBushBlock`、`tfc:branching_cactus` → `GrowingBranchingCactusBlock`、`tfc:kelp_tree` → `KelpTreeFlowerBlock`。
   你的方块的 `class` 不符就在**加载期**报 `Must be a <类名>: <block id>`（`BlockConfig.java:25-33`）。
   想复用 TFC feature 就必须继承 TFC 对应方块类。
4. **`ColumnPlantConfig.head` 的 encoder bug**（[H-3.2]）：用 datagen 生成 `tfc:weeping_vines`/`tfc:twisting_vines`/`tfc:kelp` 的 JSON 会写错 `head`，手写 JSON 无影响。
5. **JSON `radius` 字段在树配置里无效**（[H-3.7]）：`RandomTreeConfig` 无此字段，会被静默忽略。
6. **`features` 层数不固定**（[H-6.2]）：不要假设 TFC 群系是 11 层；用 `BiomeModifier` 时层序会漂移。
7. **`required`/`fallback` 语义**：`RootConfig.required=true` 时根系放不下会整树失败（`RandomTreeFeature.java:64`）。
8. **结构模板缺失**：`RandomTreeFeature` 在模板为空时直接抛异常（`RandomTreeFeature.java:60-62`），
   附属模组添加新树时必须同时提供 `data/<modid>/structure/<name>/N.nbt`。
9. **跨半球**：`tfc:climate` 的 `rain_variance_absolute` 与半球有关（`ClimatePlacement.java:146`），
   写气候窗口时注意南半球镜像行为（`SolarCalculator.getInNorthernHemisphere`）。
10. **树的落地 tag**：`#tfc:tree_grows_on` = `#minecraft:dirt`；`#tfc:bush_plantable_on` = `#minecraft:dirt + #tfc:farmlands + #tfc:clays`；
    `#tfc:wild_crop_grows_on` = `#minecraft:dirt`（`jar-extract/data/tfc/tags/block/*.json` 原文）。
    若你的植物要长在自定义方块上，需要往这些 tag 追加（同样是 tag 合并，安全）。

### H-9.3　可直接照抄的"三种新植物"模板索引

| 你要做的 | configured type | 参考 TFC 文件 | 你的方块父类 |
|---|---|---|---|
| 单格野花/野草 | `minecraft:simple_block` | `configured_feature/plant/bluegrass.json` | `TFCBushBlock` |
| 两格高草 / 两格花 | `tfc:tall_plant` | `configured_feature/plant/tall_fescue_grass.json`、`sunflower.json`、`rose.json`、`azalea.json`（实测共 **21** 个使用者） | `TFCTallGrassBlock`（**必须**） |
| 野果灌木 | `tfc:spreading_bush` | `configured_feature/plant/blackberry_bush.json` | `SpreadingBushBlock`（**必须**） |
| 野生作物（单格） | `minecraft:simple_block` | `configured_feature/plant/wild_crop/barley.json` | `WildCropBlock` |
| 野生作物（两格） | `tfc:tall_wild_crop` | `configured_feature/plant/wild_crop/green_bean.json` | `WildDoubleCropBlock`（**必须**） |
| 匍匐作物/果实 | `tfc:spreading_crop` | `configured_feature/plant/wild_crop/pumpkin.json` | `WildSpreadingCropBlock`（**必须**） |
| 果树 | `tfc:fruit_trees` | `configured_feature/plant/cherry.json` | `GrowingFruitTreeBranchBlock` |
| 向上藤/大型蕨 | `tfc:twisting_vines` | `configured_feature/plant/tree_fern.json` | 柱状植物（`body`/`head` 两段） |
| 下垂藤 | `tfc:weeping_vines` | `configured_feature/plant/hanging_vines.json` | 同上 |
| 贴地蔓延地被 | `tfc:creeping_plant` | `configured_feature/plant/ivy_cover.json` | `CreepingPlantBlock` |
| 海底蔓延 | `tfc:creeping_ocean_plant` | （`tfc:plant/*_patch` 海洋类） | `CreepingWaterPlantBlock` |
| 挺水/沉水两格 | `tfc:emergent_plant` / `tfc:submerged_tall_plant` | `configured_feature/plant/cattail.json` | `TallWaterPlantBlock` |
| 单格水生 | `tfc:block_with_fluid` | `configured_feature/plant/star_grass.json` | 带流体属性的方块 |
| 丛生（多次随机） | `minecraft:random_patch` | 所有 `*_patch` | — |
| 组合（多个子 feature） | `tfc:noisy_multiple` | `configured_feature/surface_grasses.json` | — |
| 新树 | `tfc:random_tree` | `configured_feature/tree/acacia.json` | nbt 结构 + `#tfc:tree_grows_on` |
| 新树（森林内） | `tfc:forest_entry` | `configured_feature/tree/acacia_entry.json` | 同上，且要被某个 `tfc:forest` 的 `entries` tag 收录 |

---

## H-10　未能核实 / 存疑事项（写明检查过的位置）

> 说明：本册写作分两轮。第一轮登记了 7 个待核实项，第二轮逐项回查后，其中 6 项已确证并补入 [H-3.15] / [H-5.6] / [H-8.2]，
> 下面保留原编号并用 ~~删除线~~ 标出「已补齐」，便于追溯；**目前仅剩第 3 条为真正未核实项**。

1. ~~**`tfc:random_property` 的字段定义**~~ —— **已在第二轮补齐（[H-3.15]）**：`RandomPropertyProvider.java:37`（`state` + `property`），注册于 `TFCStateProviders.java:27`。
2. ~~**`minecraft:surface_relative_threshold_filter` 在 TFC 数据中的使用**~~ —— **已在第二轮实证（[H-5.6]）**：
   对 `jar-extract/data/tfc/worldgen/placed_feature/` 全量检索 placement type 分布，结果中**没有** `surface_relative_threshold_filter`（也没有 `minecraft:biome`），
   即 TFC **未使用**它。TFC 用 `tfc:climate` 的 `min_elevation`/`max_elevation` 与 `tfc:flat_enough`、`tfc:intertidal` 承担同类职责。
3. **模组 jar 与 TFC jar 同 id 资源（`data/tfc/...` 非 tag 文件）的实际优先级** —— 本次只从语义推断为「整文件覆盖」，未做实际加载实测。
4. ~~**`StackedTreeConfig` / `OverlayTreeConfig` 的真实数据用例**~~ —— **已在第二轮补齐（[H-8.2]）**：`tfc:stacked_tree` 2 处（`douglas_fir_large`、`sequoia_large`）、`tfc:overlay_tree` 2 处（`white_cedar`、`white_cedar_large`），JSON 原文已收录。
5. ~~**`tfc:fruit_trees` 的果树完整列表**~~ —— **已在第二轮补齐**：`tfc:fruit_trees` 恰好 **8** 个使用者
   （`configured_feature/plant/` 下的 `cherry`、`green_apple`、`lemon`、`olive`、`orange`、`peach`、`plum`、`red_apple`），
   加上走 `tfc:bananas` 的 `banana`，共 **9** 种，与 tag `#tfc:feature/fruit_trees` 的 9 项完全吻合
   （`jar-extract/data/tfc/tags/worldgen/placed_feature/feature/fruit_trees.json`）。
   另有 `tfc:vines` 的实测使用者 2 个：`configured_feature/plant/jungle_vines.json`、`marsh_jungle_vines.json`。
6. ~~**`KrummholzConfig` 的 5 个使用者**~~ —— **已在第二轮补齐（[H-8.2]）**：恰好 5 个，`tree/{aspen,douglas_fir,pine,spruce,white_cedar}_krummholz.json`。
7. ~~**TFC 的 `data/tfc/structure/` 目录内容**~~ —— **已在第二轮核实**：目录存在，jar 清单中 `data/tfc/structure/**.nbt` 共 **539** 个
   （`inventory/TFC.resources.txt` 统计），每个树 id（如 `tfc:acacia/1`）对应一个 `.nbt` 模板。
   附属模组新增树时必须自带 `data/<modid>/structure/<name>/N.nbt`（见 [H-9.2] 坑 8）。

---

## H-11　速查卡（打印版）

```
植物进入世界的链路：
  biome JSON 的 features[i]
    └─ #tfc:in_biome/surface_decoration/<biome>   (i = 9，11 项布局)
         └─ #tfc:feature/land_plants              (99 个群系共用)
              └─ tfc:plant/xxx_patch   (placed_feature: rarity/in_square/heightmap/tfc:climate/block_predicate_filter)
                   └─ tfc:plant/xxx    (configured_feature: 单个 TFC plant feature)
                        └─ 实际方块 (tfc:plant/xxx 或 tfc:wild_crop/xxx)

树的链路：
  biome features[8] → #tfc:in_biome/large_features/<biome> → tfc:forest
      → ForestConfig.entries (#tfc:forest_trees → tfc:tree/<wood>_entry)
      → ForestFeature 按 tfc:climate 挑选 entry → tfc:tree/<wood> | _dead | _large | _krummholz
      → RandomTreeFeature 粘贴 data/tfc/structure/<wood>/N.nbt

野生作物链路：
  tfc:plant/wild_crop/<crop>_patch (rarity 90) → random_patch(tries 6)
      → tfc:plant/wild_crop/<crop>  (simple_block | tfc:tall_wild_crop | tfc:spreading_crop)
      → 方块 tfc:wild_crop/<crop>（破坏 → loot_table/blocks/wild_crop/<crop>.json）

附属模组最小集合（推荐方案 A）：
  1. Java：注册方块（继承 TFC 方块类）+ BlockItem
  2. data/<modid>/worldgen/configured_feature/plant/<name>.json
  3. data/<modid>/worldgen/placed_feature/plant/<name>_patch.json
  4. data/tfc/tags/worldgen/placed_feature/feature/land_plants.json  {"replace":false,"values":["<modid>:plant/<name>_patch"]}
  5. （可选）data/<modid>/loot_table/blocks/plant/<name>.json + 客户端 blockstate/model
```

---

## H-12　与 `docs/12-tfc-data-driven.md` [W-1~W-11] 的核对结论

| 项 | W 章口径 | 本册实测 | 结论 |
|---|---|---|---|
| biome `features` 数组「全部用 tag 引用」 | W-2.1 | 成立（125/125 全部为 `#tfc:in_biome/...`） | 一致 |
| `tfc:forest` 的 `entries` 用 tag | W-3.1(5) | 成立（`configured_feature/forest.json` = `#tfc:forest_trees`） | 一致 |
| `ForestConfig.Entry` 字段与默认值 | W-3.1(5) 列出的默认值 6/200/14/75/false | 与 `ForestConfig.java:41` 完全一致 | 一致 |
| 自定义 placement modifier 数量 | W-7「全清单」 | 15 项（`TFCPlacements.java:39-53`） | 一致（数量已在本册逐条展开字段表） |
| **biome features 数组只能有 11 项** | W 章未展开 | **实测存在 11 / 12 / 13 三种长度（57/55/13）** | **本册补充**：这是 W 章未覆盖的关键点，直接决定 `BiomeModifier` 的落层行为 |
| **`tfc:climate` 的完整字段数（14）** | W-7 只列了部分（含 `forest_types`） | 14 个字段，见 [H-5.4] | 本册补全 |
| **野生作物掉落是否用自定义 loot function** | W 章未涉及 | **不存在**该 loot function；纯原版两-pool 战利品表 | 本册新增结论 |
| `vein` 中 `radius`/`spread` 类冗余字段 | W-4.4 指出 `spread` 无效 | `tree/*.json` 中 `radius` 同样**无效**（`RandomTreeConfig` 无该字段） | 同类现象，本册新增 |

---

*本册由源码 + jar 真实资源双向核对写成；凡未亲自读到的内容，已在 [H-10] 逐项登记并写明检查过的位置。*
