## [W-1] data/tfc/worldgen 结构总览

### [W-1.1] 实测子目录清单（权威口径）

统计方式：在 `jar-extract\data\tfc\worldgen` 下执行 `Get-ChildItem -File -Recurse` 后按路径首段分组。**该目录只有 6 个一级子目录，共 1498 个 JSON。**

| 子目录 | 递归文件数 | 二级子目录 | 性质 |
|---|---|---|---|
| `configured_feature` | 690 | `plant`(379)、`tree`(101)、`vein`(52) | 原版格式 + TFC 自定义 `type` |
| `placed_feature` | 674 | `plant`(379)、`tree`(56)、`vein`(52) | 原版格式 + TFC placement modifier |
| `biome` | 125 | 无 | 纯原版 biome 格式 |
| `density_function` | 5 | 无 | 原版格式 + 2 个 TFC `type` |
| `configured_carver` | 3 | 无 | `type` 为 TFC，config 用原版 |
| `world_preset` | 1 | 无 | 原版格式 + TFC 私有 `tfc_settings` |

与任务给定数字的差异（**以实测为准**）：`configured_feature` 690（非 695）、`placed_feature` 674（非 679）、`biome` 125（非 126）、`density_function` 5（非 6）、`configured_carver` 3（非 4，仅 `canyon`/`cave`/`deep_cave`）、`world_preset` 1（非 2，仅 `overworld.json`）。

**`noise_settings` / `template_pool` / `structure` / `processor_list` / `structure_set` 全部不存在。** 依据：`Get-ChildItem <base> -Directory` 只返回上表 6 项；`world_preset/overworld.json`（2757 字节，全文已读）中 `settings` 直接引用原版 `minecraft:overworld`，TFC 不提供自己的噪声设置。

### [W-1.2] 并列但同属世界生成的相关目录（不在本目录内）

| 路径 | 文件数 | 用途 |
|---|---|---|
| `data/tfc/tfc/worldgen/rock_settings/` | 21 | datapack registry `tfc:worldgen/rock_settings`，见 [W-9] |
| `data/tfc/tfc/deposit/` | 84 | 地表矿点方块定义，见 [W-9.4] |
| `data/tfc/tfc/climate_range/crop` / `plant` | 28 / 20 | 作物与植物气候区间（`tfc:climate_range`），与世界生成无关 |
| `data/tfc/tags/worldgen/biome/` | 26 | `is_ocean`、`is_karst`、`has_atolls` 等 |
| `data/tfc/tags/worldgen/configured_feature/` | 3 | `forest_trees`、`dead_forest_trees`、`mangrove_forest_trees` |
| `data/tfc/tags/worldgen/placed_feature/` | 33 | 9 个 `in_biome/*` + 23 个 `feature/*` + 根级 |

`in_biome/` 的 9 个标签是 biome 组装 `features` 的关键：`all_lakes`、`erosion`、`strongholds`、`surface_structures`、`top_layer_modification`、`underground_decoration`、`underground_lakes`、`underground_structures`、`veins`。

## [W-2] 各子目录是什么、关键格式要点

### [W-2.1] `biome/`（125）——纯原版格式

TFC **没有**任何自定义 biome JSON 字段；地形行为由 Java 的 `BiomeExtension` 决定（见 [W-6.3]），JSON 只承担原版职责。要点：`carvers.air` 统一为 `["tfc:cave","tfc:deep_cave","tfc:canyon"]`；`features` 数组**全部用 tag 引用**（`#tfc:in_biome/...`），这是 125 个 biome 共享特征池的核心手段；`spawners.creature` 直接写 `tfc:bison`、`tfc:crocodile` 等 TFC 实体。真实文件 `data/tfc/worldgen/biome/plains.json`（`spawners` 内约 45 条 creature 条目已省略）：

```json
{"has_precipitation":true,"temperature":0.5,"downfall":0.5,
 "effects":{"fog_color":12638463,"sky_color":8709887,"water_color":4159204,"water_fog_color":329011},
 "carvers":{"air":["tfc:cave","tfc:deep_cave","tfc:canyon"],"liquid":[]},
 "features":["#tfc:in_biome/erosion","#tfc:in_biome/all_lakes","#tfc:in_biome/soil_discs/plains",
             "#tfc:in_biome/underground_structures","#tfc:in_biome/surface_structures",
             "#tfc:in_biome/strongholds","#tfc:in_biome/veins",
             "#tfc:in_biome/underground_decoration","#tfc:in_biome/large_features/plains",
             "#tfc:in_biome/surface_decoration/plains","#tfc:in_biome/top_layer_modification"],
 "spawners":{"monster":[{"type":"minecraft:spider","weight":100,"minCount":4,"maxCount":4}, ...],
             "creature":[{"type":"tfc:crocodile","weight":10,"minCount":1,"maxCount":1}, ...]},
 "creature_spawn_probability":0.1,"spawn_costs":{}}
```

### [W-2.2] `configured_feature/`（690）与 `placed_feature/`（674）

均为原版格式（`{"type":…,"config":{…}}` / `{"feature":…,"placement":[…]}`）。`configured_feature` 顶层 `type` 为 `minecraft:*` 的 296 个（`minecraft:random_patch` 177、`minecraft:simple_block` 126 等），为 `tfc:*` 的 394 个（全部由 `TFCFeatures` 注册，见 [W-3]）。

**对全部 674 个 placed_feature 解析 `placement` 数组后的 modifier 使用次数**：

| modifier | 次数 | modifier | 次数 |
|---|---|---|---|
| `minecraft:heightmap` | 430 | `tfc:volcano` | 7 |
| `block_predicate_filter` | 398 | `minecraft:random_offset` | 6 |
| `minecraft:in_square` | 284 | `tfc:flat_enough` | 6 |
| **`tfc:climate`** | 249 | `tfc:shallow_water` | 5 |
| `minecraft:rarity_filter` | 237 | `tfc:atoll` | 4 |
| **`tfc:stratovolcano`** | 39 | `minecraft:environment_scan` | 2 |
| `minecraft:count` | 31 | `tfc:near_fluid` | 2 |
| `minecraft:height_range` | 24 | `tfc:on_top` | 2 |
| **`tfc:intertidal`** | 19 | `tfc:ocean_ridge` | 1 |
| **`tfc:no_solid_neighbors`** | 13 | **`tfc:underground`** | **0** |
| `minecraft:noise_based_count` | 10 | **`tfc:tuff_cone`** | **0** |
| `tfc:tuya` / `tfc:carving_mask` | 7 / 7 | | |

`predicate` 内层（block predicate，属**另一套注册表**）统计：`would_survive` 165、`tfc:air_or_empty_fluid` 139、`tfc:replaceable` 60、`tfc:would_survive_with_fluid` 28、`matching_blocks` 5、`minecraft:matching_block_tag` 2、`tfc:dry_replaceable` 1。TFC 的 JSON 常省略 `minecraft:` 前缀（`"type":"block_predicate_filter"`、`"type":"would_survive"`），由 `ResourceLocation` 默认命名空间补全。

### [W-2.3] `configured_carver/`（3）

`type` 为 TFC 自定义，config 沿用原版结构。`data/tfc/worldgen/configured_carver/cave.json`（**全文，完整样例 1**）：

```json
{"type":"tfc:cave","config":{"probability":0.02,
 "y":{"type":"uniform","min_inclusive":{"absolute":-56},"max_inclusive":{"absolute":126}},
 "yScale":{"type":"uniform","min_inclusive":0.1,"max_exclusive":0.9},
 "lava_level":{"above_bottom":8},"aquifers_enabled":true,
 "horizontal_radius_multiplier":{"type":"uniform","min_inclusive":1.5,"max_exclusive":2.5},
 "vertical_radius_multiplier":{"type":"uniform","min_inclusive":1.5,"max_exclusive":2.5},
 "floor_level":{"type":"uniform","min_inclusive":-1,"max_exclusive":0.3},
 "replaceable":"#minecraft:overworld_carver_replaceables"}}
```

### [W-2.4] `density_function/`（5）与 `world_preset/`（1）

`density_function` 为原版 dispatch 格式，其中 `noise_caves.json` 内嵌 TFC 自定义类型：

| `type` | 源码类 | 字段 |
|---|---|---|
| `tfc:spaghetti2d` | `world/density/Spaghetti2D.java` | `rarity`、`thickness`、`elevation`（DensityFunction）+ `noise`（NoiseHolder） |
| `tfc:spaghetti3d` | `world/density/Spaghetti3D.java` | `rarity`、`thickness`（DensityFunction）+ `noise1`、`noise2`（NoiseHolder） |

`world_preset/overworld.json` 是原版格式，但 overworld 的 `generator` 换成 TFC 实现并插入私有块 `tfc_settings`：

```json
{"dimensions":{
  "minecraft:overworld":{"type":"minecraft:overworld","generator":{
    "type":"tfc:overworld","biome_source":{"type":"tfc:overworld"},
    "settings":"minecraft:overworld","tfc_settings":{ ...见 [W-5.3]... }}},
  "minecraft:the_nether":{"type":"minecraft:the_nether","generator":{"type":"minecraft:noise",
    "biome_source":{"type":"minecraft:multi_noise","preset":"minecraft:nether"},"settings":"minecraft:nether"}},
  "minecraft:the_end":{"type":"minecraft:the_end","generator":{"type":"minecraft:noise",
    "biome_source":{"type":"minecraft:the_end"},"settings":"minecraft:end"}}}}
```

依据 `world/TFCChunkGenerator.java:193`：

```java
public static final MapCodec<TFCChunkGenerator> CODEC = RecordCodecBuilder.mapCodec(instance -> instance.group(
    BiomeSource.CODEC.comapFlatMap(TFCChunkGenerator::guardBiomeSource, BiomeSourceExtension::self)
        .fieldOf("biome_source").forGetter(c -> c.customBiomeSource),
    NoiseGeneratorSettings.CODEC.fieldOf("settings").forGetter(c -> c.noiseSettings),
    Settings.CODEC.fieldOf("tfc_settings").forGetter(c -> c.settings))
    .apply(instance, TFCChunkGenerator::new));
```

注册处 `world/TFCWorldGen.java:27-30`：`CHUNK_GENERATOR.register("overworld", () -> TFCChunkGenerator.CODEC)`、`BIOME_SOURCE.register("overworld", () -> RegionBiomeSource.CODEC)`。`RegionBiomeSource.CODEC` 无字段（只 `RegistryOps.retrieveGetter(Registries.BIOME)`），故 `{"type":"tfc:overworld"}` 即完整写法。

## [W-3] TFC 自定义 configured_feature 全清单

注册器 `net/dries007/tfc/world/feature/TFCFeatures.java`（`DeferredRegister.create(Registries.FEATURE, "tfc")`，第 117-175 行，共 **58** 条 `register(...)`）。下表 `type` 均带 `tfc:` 前缀，源码类均在 `world/feature/` 下：

```
cave_spike→cave/CaveSpikesFeature   large_cave_spike→cave/LargeCaveSpikesFeature
thin_spike→cave/ThinSpikeFeature    cave_column→cave/CaveColumnFeature
cave_vegetation→cave/CaveVegetationFeature   ice_cave→cave/IceCaveFeature
rivulet→RivuletFeature   fissure→FissureFeature   hot_spring→HotSpringFeature
sea_stacks→SeaStacksFeature   erosion→ErosionFeature   ice_and_snow→IceAndSnowFeature
spring→SpringFeature   flood_fill_lake→FloodFillLakeFeature   soil_disc→SoilDiscFeature
soil_forest_area→SoilForestAreaFeature   powder_snow→PowderSnowFeature
if_then→IfThenFeature   multiple→MultipleFeature   noisy_multiple→NoisyMultipleFeature
dynamic_random_patch→DynamicDensityRandomPatchFeature   loose_rock→LooseRockFeature
boulder→BouldersFeature   baby_boulder→BabyBoulderFeature   tide_pool→TidePoolFeature
cluster_vein→vein/ClusterVeinFeature   disc_vein→vein/DiscVeinFeature
kaolin_disc_vein→vein/KaolinDiscVeinFeature   pipe_vein→vein/PipeVeinFeature
vines→plant/TFCVinesFeature   kelp→plant/TFCKelpFeature   kelp_tree→plant/GiantKelpFeature
emergent_plant→plant/EmergentPlantFeature   tall_plant→plant/TallPlantFeature
tall_wild_crop→plant/TallWildCropFeature   spreading_crop→plant/SpreadingCropFeature
spreading_bush→plant/SpreadingBushFeature   block_with_fluid→plant/BlockWithFluidFeature
branching_cactus→plant/BranchingCactusFeature   creeping_plant→plant/CreepingPlantFeature
creeping_ocean_plant→plant/CreepingOceanPlantFeature   epiphyte_plant→plant/EpiphytePlantFeature
rotatable_water_plant→plant/RotatableWaterPlantFeature
submerged_tall_plant→plant/SubmergedTallPlantFeature
weeping_vines→plant/TFCWeepingVinesFeature   twisting_vines→plant/TFCTwistingVinesFeature
fruit_trees→plant/FruitTreeFeature   bananas→plant/BananaFeature   bamboo→plant/TFCBambooFeature
coral_claw→coral/TFCCoralClawFeature   coral_mushroom→coral/TFCCoralMushroomFeature
coral_tree→coral/TFCCoralTreeFeature
forest→tree/ForestFeature   forest_entry→tree/ForestFeature.Entry
overlay_tree→tree/OverlayTreeFeature   random_tree→tree/RandomTreeFeature
stacked_tree→tree/StackedTreeFeature   krummholz→tree/KrummholzFeature
```

各 `type` 使用的 config 类（源码逐行核对）：

```
NoneFeatureConfiguration（无字段）: cave_spike, large_cave_spike, cave_column, loose_rock,
    sea_stacks, coral_claw, coral_mushroom, coral_tree, ice_cave, tide_pool, erosion, ice_and_snow
BlockStateConfiguration: vines, powder_snow      SimpleBlockConfiguration: block_with_fluid
SimpleRandomFeatureConfiguration: multiple, noisy_multiple   RandomPatchConfiguration: dynamic_random_patch
SpringConfiguration(原版): spring                BlockStateMapConfig: rivulet
BoulderConfig: boulder, baby_boulder             ColumnPlantConfig: weeping_vines, twisting_vines, kelp
CreepingPlantConfig: creeping_plant, creeping_ocean_plant   TFCBambooConfig: bamboo
ClusterVeinConfig: cluster_vein                  DiscVeinConfig: disc_vein, kaolin_disc_vein
PipeVeinConfig: pipe_vein                        FissureConfig: fissure
HotSpringConfig: hot_spring                      ThinSpikeConfig: thin_spike
FloodFillLakeConfig: flood_fill_lake             SoilDiscConfig: soil_disc
SoilForestAreaConfig: soil_forest_area           IfThenConfig: if_then
CaveVegetationConfig: cave_vegetation            ForestConfig: forest   ForestConfig.Entry: forest_entry
OverlayTreeConfig/RandomTreeConfig/StackedTreeConfig/KrummholzConfig:
    overlay_tree / random_tree / stacked_tree / krummholz
其余 tfc:*_plant、coral_* 等: 各 Feature 类自带 CODEC（plant/*.java 内的静态字段）
```

jar 内实际使用分布（configured_feature 顶层 type）：`minecraft:random_patch` 177、`minecraft:simple_block` 126、`tfc:random_tree` 52、`tfc:forest_entry` 40、`tfc:cluster_vein` 33、`tfc:tall_plant` 21、`tfc:dynamic_random_patch` 20、`tfc:block_with_fluid` 18、`tfc:disc_vein` 13、`tfc:flood_fill_lake`/`tfc:creeping_plant`/`tfc:soil_disc`/`minecraft:simple_random_selector` 各 12、`tfc:emergent_plant` 9、`tfc:fruit_trees` 8、`tfc:spring`/`tfc:hot_spring` 各 7、`tfc:fissure`/`tfc:tall_wild_crop` 各 6，其余各 1~5。

### [W-3.1] 五个关键 configured_feature 详解

**(1) `tfc:cluster_vein`**（`vein/ClusterVeinFeature.java` + `ClusterVeinConfig.java`）：几何 `Metaballs3D.simple(random, size)`，包围盒三轴 `±size`；概率 `vein.metaballs.inside(x,y,z) ? density : 0.0f`；`chunkRadius() = 1 + (size>>4)`，`verticalRadius() = size`。字段 = `VeinConfig` 全部字段（[W-4.2]）**+ `size`（正整数，团块半径，必填）**。

**(2) `tfc:disc_vein`**（`vein/DiscVeinFeature.java` + `DiscVeinConfig.java`）：几何 `Metaballs2D.simple(random, size)`，包围盒水平 `±size`、垂直 `±height`；`getChanceToGenerate` = `density * clampedMap(|y-height|, 0.7f*height, height, 1.0f, 0.4f) * clampedMap(sample, 2.0f, 1.0f, 1.0f, 0.6f)`。字段 = `VeinConfig` 全部字段 **+ `size`（正整数）+ `height`（正整数，层的半厚）**。

**(3) `tfc:pipe_vein`**（`vein/PipeVeinFeature.java` + `PipeVeinConfig.java`）：随机角度的倾斜圆柱，`skew` 控制水平偏移、`slant` 控制底部收窄，命中圆柱内部即 `density`。字段 = `VeinConfig` 全部字段 **+ `height`（int，管长 = `verticalRadius()`）、`radius`（int，顶部半径，`chunkRadius()=1+(radius>>4)`）、`min_skew`/`max_skew`（int，水平倾斜区间，内部用 `Helpers.uniform(random, minSkew, 1+maxSkew)`）、`min_slant`/`max_slant`（int，底部收窄区间）、`sign`（float 0~1，圆柱向上/向下翻转概率）**。
> 反编译瑕疵：`PipeVeinConfig.CODEC` 中 `Codec.INT.fieldOf("height").forGetter(c -> c.radius)`，forGetter 被 CFR 误解析；由 `record PipeVeinConfig(VeinConfig config, int height, int radius, ...)` 可知应为 `c.height`。JSON 字段名 `height` 无误。

**(4) `tfc:soil_disc`**（`SoilDiscFeature.java` + `SoilDiscConfig.java`）：`states`（list，`[{"replace":<block>,"with":<block_state>}]`）、`min_radius`/`max_radius`（正整数，圆盘半径区间）、`height`（int 0~256，覆盖厚度）、`integrity`（float，默认 `1.0`，完整度）。完整样例：`data/tfc/worldgen/configured_feature/cassiterite_deposit.json`（21 条 `states` 对应 21 种岩石，见 [W-10.3]）。

**(5) `tfc:forest` / `tfc:forest_entry`**（`tree/ForestFeature.java` + `ForestConfig.java`）：`tfc:forest` 的 config 只有 `entries`（`HolderSet<ConfiguredFeature>`，`ExtraCodecs.nonEmptyHolderSet`），jar 内写成 tag：`configured_feature/forest.json` = `{"type":"tfc:forest","config":{"entries":"#tfc:forest_trees"}}`，tag 定义在 `data/tfc/tags/worldgen/configured_feature/`。`tfc:forest_entry` 共 41 个文件（`configured_feature/tree/*_entry.json`）。`ForestConfig.Entry` 字段（`ForestConfig.java:37-42`）：`climate`(`ClimatePlacement`，必填)、`bush_log`/`bush_leaves`/`fallen_log`/`fallen_leaves`(BlockState，可选)、`groundcover`(加权 BlockState 列表，可选)、`normal_tree`/`dead_tree`(ConfiguredFeature，必填)、`old_growth_tree`(可选，回退 `normal_tree`)、`krummholz`/`soil_disc`(可选)、`old_growth_chance`(6)、`spoiler_old_growth_chance`(200)、`fallen_tree_chance`(14)、`dead_chance`(75)、`floating`(false)。`Entry.isValid(temp, groundwater, rainVar, elevation)` 用 `climate` 上下界过滤；`distanceFromMean` 用于多树种竞争时选取最贴近气候均值的树种。完整样例见 [W-10.2]。

**其他 config 字段速查**

| `type` | 字段（含默认值） |
|---|---|
| `tfc:fissure` | `wall_state`(可选)、`fluid_state`(必填)、`count`(5)、`radius`(12)、`min_depth`(`above_bottom(16)`)、`min_pieces`(10)、`max_pieces`(24)、`max_piece_length`(6)、`decoration`(可选：`blocks`+`rarity`+`radius`+`count`) |
| `tfc:hot_spring` | `wall_state`(可选)、`fluid_state`(必填)、`radius`(14，1~16)、`decoration`(可选)、`allow_underwater`(false)、`replaces_on_fluid_contact`(可选加权映射) |
| `tfc:flood_fill_lake` / `tfc:if_then` | `state`+`replace_fluids`+`overfill`(false) / `if`+`then`(均 PlacedFeature) |
| `tfc:thin_spike` / `tfc:bamboo` | `state`+`radius`(1~16)+`tries`+`min_height`+`max_height`+`allow_underwater` / `probability`(0~1)+`state` |
| `tfc:boulder` / `tfc:baby_boulder` | `states`：`[{"rock":<block>,"blocks":[<blockstate>…]}]` |
| `tfc:krummholz` | `block`、`height`(IntProvider)、`spawns_on_stone`(false)、`spawns_on_gravel`(false) |
| `tfc:random_tree` / `tfc:stacked_tree` / `tfc:overlay_tree` | `structures`+`trunk`(可选)+`placement`+`root_system`(可选) / `layers`(`templates`+`min_count`+`max_count`)+`trunk`+`placement`+`root_system`(可选) / `base`+`overlay`+`trunk`(可选)+`overlay_integrity`(0.5)+`placement`+`root_system`(可选) |
| `tfc:soil_forest_area` | `states`、`min_forest`、`max_forest`、`priority`(0)、`height`(0~256)、`spread`(0.05)、`noise_scale`(1.0)、`inverted`(false) |
| `tfc:rivulet` / `tfc:creeping_plant` | `states`（`replace`/`with` 映射） / `block`+`radius`+`height`+`tide_height`+`integrity`(1.0) |
| `tfc:weeping_vines`/`twisting_vines`/`kelp` | `body`、`head`、`tries`(1~128)、`radius`(1~16)、`min_height`(1~100)、`max_height`(1~100) |
| `tfc:cave_vegetation` | `blocks`：加权映射 `[{"replace":[<block>…],"with":[{"block":…,"weight":N}]}]` |
| tree 系列的 `RootConfig` | `blocks`、`width`(4)、`height`(3)、`tries`(5)、`special_placer`(可选 `{"skew_chance":float}`)、`required`(false) |

## [W-4] 矿脉（vein）系统

> **包路径更正**：TFC 4.2.10 **不存在** `net/dries007/tfc/world/vein/` 与 `net/dries007/tfc/world/rocklayer/`。矿脉全部位于 `net/dries007/tfc/world/feature/vein/`（13 个文件）。依据：`Get-ChildItem <src>\net\dries007\tfc\world -Directory` 返回 biome / blockpredicate / carver / chunkdata / density / feature / layer / noise / placement / region / river / settings / shore / stateprovider / structure / surface / volcano，**无 `vein`、无 `rocklayer`**。

### [W-4.1] 类清单

| 文件（`world/feature/vein/`） | 作用 |
|---|---|
| `IVein.java` / `IVeinConfig.java` | 接口：`pos()`；`config()`/`chunkRadius()`/`verticalRadius()`/`indicator()`/`minY()`/`maxY()`/`getStateToGenerate(stoneState, random)` |
| `VeinConfig.java` / `Indicator.java` | 共享基础配置 / 指示物配置 |
| `ClusterVeinFeature`+`ClusterVeinConfig`（`tfc:cluster_vein`）、`DiscVeinFeature`+`DiscVeinConfig`（`tfc:disc_vein`）、`KaolinDiscVeinFeature`（`tfc:kaolin_disc_vein`，复用 `DiscVeinConfig`）、`PipeVeinFeature`+`PipeVeinConfig`（`tfc:pipe_vein`） | 四种矿脉实现 |
| `VeinFeature.java` | 抽象基类：稀有度判定、邻近区块扫描、指示物生成 |

### [W-4.2] `VeinConfig` 与 `Indicator` 字段表

| JSON 字段 | 类型 | 必填/默认 | 说明 |
|---|---|---|---|
| `blocks` | 映射列表 | 必填 | 由 `Codecs.BLOCK_TO_WEIGHTED_BLOCKSTATE` 解析：`[{"replace":[<block>…],"with":[{"block":<block_state>,"weight":<double，默认 1.0>}…]}]` |
| `indicator` | object | 可选 | 见下 |
| `rarity` | `Codecs.POSITIVE_INT` | 必填 | `random.nextInt(rarity) == 0` |
| `density` | `Codecs.UNIT_FLOAT`（0~1） | 必填 | 命中体积内的转化概率 |
| `min_y` / `max_y` | int | 必填 | 高度范围 |
| `project` | bool | 可选，默认 `false` | 投影到 `Heightmap.Types.OCEAN_FLOOR_WG` |
| `project_offset` | bool | 可选，默认 `false` | 投影时用 `Helpers.hash` 派生 ±15 水平偏移 |
| `random_name` | string 或 long | 必填 | 字符串经 `RandomSupport.seedFromHashOf(name)` 的 `seedLo() ^ seedHi()` 转 seed |
| `near_lava` | bool | 可选，默认 `false` | 检查 y=-55、水平 ±4 内是否有岩浆（`isNearLava`） |

> `VeinConfig.java:41` 构造了局部变量 `TagKey.hashedCodec(Registries.BIOME)` 但**未在 codec 中使用**（源码残留，无对应 JSON 字段）。**没有** `size`、`weight`、`ore` 这些顶层字段：`size` 属于 `ClusterVeinConfig`/`DiscVeinConfig`，`weight` 只存在于 `with` 数组元素内部。

`Indicator`（`Indicator.java`）字段：`depth`（正整数，指示物允许偏离矿脉最高点的最大高度差）、`rarity`（int，地表指示物概率除数；为 0 则跳过地表指示物，见 `VeinFeature.java:134`）、`underground_rarity`（正整数）、`underground_count`（int，每个水平位置尝试生成个数）、`blocks`（加权方块状态列表 `[{"block":…,"weight":N}]`）。指示物仅在 `EnvironmentHelpers.isWorldgenReplaceable(stateAt)` 且 `state.canSurvive(...)` 为真时写入（`VeinFeature.java:132-154`）。

### [W-4.3] 生成流程（`VeinFeature.java`）

1. `place(context)` 以当前区块为中心扫描 `chunkRadius` 范围内所有区块（`getNearbyVeins`）。
2. 每个被扫描区块用 `XoroshiroRandomSource(level.getSeed() ^ chunkX*61728364132L, config.seed() ^ chunkZ*16298364123L)` 播种，`nextInt(rarity) == 0` 则生成一个 vein（第 86-87 行）。
3. 对每个 vein 计算包围盒（各子类 `getBoundingBox`），与当前区块 `±15`、`[min_y, max_y]` 取交集后逐格判定。
4. `random.nextFloat() < getChanceToGenerate(dx,dy,dz,vein,config)` 时用 `getStateToGenerate(stoneState, random)` 按母岩方块查 `blocks`，非 null 才 `setBlock`。

### [W-4.4] 真实 JSON 样例

**A —— `tfc:cluster_vein`（normal 银矿，完整样例 2）** `data/tfc/worldgen/configured_feature/vein/normal_native_silver.json`：

```json
{"type":"tfc:cluster_vein","config":{
  "rarity":25,"density":0.6,"min_y":-80,"max_y":20,"size":25,
  "random_name":"normal_native_silver",
  "blocks":[
    {"replace":["tfc:rock/raw/granite"],
     "with":[{"weight":15,"block":"tfc:ore/poor_native_silver/granite"},
             {"weight":25,"block":"tfc:ore/normal_native_silver/granite"},
             {"weight":60,"block":"tfc:ore/rich_native_silver/granite"}]},
    {"replace":["tfc:rock/raw/diorite"],"with":[ ...同上三档 diorite 矿石... ]},
    {"replace":["tfc:rock/raw/gneiss"], "with":[ ...gneiss... ]},
    {"replace":["tfc:rock/raw/schist"], "with":[ ...schist... ]}],
  "indicator":{"rarity":0,"depth":35,"underground_rarity":1,"underground_count":9,
               "blocks":[{"block":"tfc:ore/small_native_silver"}]}}}
```

其 placed_feature（`.../placed_feature/vein/normal_native_silver.json`）：`{"feature":"tfc:vein/normal_native_silver","placement":[]}`

**B —— `tfc:pipe_vein`（闪长岩岩脉，节选）** `.../configured_feature/vein/diorite_dike.json`：

```json
{"type":"tfc:pipe_vein","config":{"rarity":300,"min_y":-64,"max_y":180,"density":0.98,
 "random_name":"diorite","height":150,"radius":18,"min_skew":7,"max_skew":20,
 "min_slant":2,"max_slant":5,"project":false,"sign":0,
 "blocks":[{"replace":["tfc:rock/raw/granite", ...共 21 种 raw 岩石..., "tfc:rock/gravel/granite", ...共 21 种 gravel 岩石...],
            "with":[{"block":"tfc:rock/raw/diorite"}]},
           {"replace":["tfc:rock/hardened/granite", ...共 21 种 hardened 岩石...],
            "with":[{"block":"tfc:rock/hardened/diorite"}]}]}}
```

（`replace` 数组按 `granite/diorite/gabbro/shale/claystone/limestone/conglomerate/dolomite/chert/chalk/tuff/rhyolite/basalt/andesite/dacite/quartzite/slate/phyllite/schist/gneiss/marble` 顺序列出，**已省略重复部分**。）

**C —— `tfc:kaolin_disc_vein`（带地表指示物，完整样例 3）** `.../configured_feature/vein/kaolin_disc.json`：

```json
{"type":"tfc:kaolin_disc_vein","config":{
  "rarity":50,"min_y":-7,"max_y":1,"size":18,"height":6,"density":1.0,
  "project":true,"random_name":"kaolin",
  "indicator":{"depth":35,"spread":5,"rarity":10,"underground_rarity":1,"underground_count":0,
               "blocks":[{"block":"tfc:plant/blood_lily"}]},
  "blocks":[]}}
```

placed_feature（`.../placed_feature/vein/kaolin_disc.json`）：`{"feature":"tfc:vein/kaolin_disc","placement":[{"type":"tfc:climate","min_temperature":18,"min_groundwater":300}]}`
> 此文件的 `indicator` 含源码中**不存在**的 `spread` 字段，会被 codec 忽略，见 [W-11.2]。

**D —— `tfc:disc_vein`（砾石层）**：`.../vein/gravel.json` = `{"type":"tfc:disc_vein","config":{"rarity":30,"min_y":-64,"max_y":100,"size":44,"height":2,"density":0.98,"project":false,"random_name":"gravel","blocks":[{"replace":["tfc:rock/raw/granite"],"with":[{"block":"tfc:rock/gravel/granite"}]}, …共 21 组 raw→gravel 映射…]}}`

**E —— `tfc:disc_vein`（红宝石大理岩带，`project_offset` 用法）**：`.../vein/ruby_marble_belt.json` = `{"type":"tfc:disc_vein","config":{"rarity":16,"density":1,"min_y":-40,"max_y":-4,"project":true,"project_offset":true,"size":50,"height":5,"random_name":"ruby_marble_belt","blocks":[{"replace":["tfc:rock/raw/rhyolite"],"with":[{"block":"tfc:rock/raw/marble","weight":94},{"block":"tfc:ore/ruby/marble","weight":6}]}, …共 13 组母岩…]}}`

### [W-4.5] jar 内 52 个矿脉（`configured_feature/vein/` 与 `placed_feature/vein/` 同名各 52 个）

```
amethyst  bituminous_coal  borax  cryolite  deep_ruby  diamond  diorite_dike  emerald
fake_native_gold  gabbro_dike  gabbro_garnierite  granite_dike  graphite  gravel  gypsum
halite  kaolin_disc  lapis_lazuli  lignite  montane_bismuthinite  montane_cassiterite
montane_cinnabar  montane_hematite  montane_limonite  montane_magnetite  montane_malachite
montane_native_copper  montane_native_silver  montane_sphalerite  montane_tetrahedrite
normal_bismuthinite  normal_cinnabar  normal_garnierite  normal_malachite  normal_native_gold
normal_native_silver  normal_sphalerite  normal_tetrahedrite  opal  rich_native_gold
ruby_marble_belt  saltpeter  sulfur  surface_bismuthinite  surface_hematite  surface_limonite
surface_magnetite  surface_malachite  surface_native_copper  surface_sphalerite  sylvite  tuff_sulfur
```

## [W-5] 岩层（rock layer）系统

### [W-5.1] `RockSettings` —— 单个岩石类型（datapack registry 元素）

源码 `world/settings/RockSettings.java:30-32`：

```java
public record RockSettings(Block raw, Block hardened, Block gravel, Block cobble, Block sand,
    Block sandstone, Optional<Block> spike, Optional<Block> loose, Optional<Block> mossyLoose,
    Optional<Boolean> karst, Optional<Boolean> mafic)
public static final ResourceKey<Registry<RockSettings>> KEY =
    ResourceKey.createRegistryKey(Helpers.identifier("worldgen/rock_settings"));
```

registry id = **`tfc:worldgen/rock_settings`**，故文件落在 `data/tfc/tfc/worldgen/rock_settings/*.json`（21 个，见 [W-9]）。字段：`raw`/`hardened`/`gravel`/`cobble`/`sand`/`sandstone`（Block，均必填，六种基础方块）、`spike`（Block，可选，岩锥）、`loose`/`mossy_loose`（Block，可选）、`karst`（bool，可选，是否喀斯特母岩）、`mafic`（bool，可选，是否镁铁质岩）。

注册入口 `net/dries007/tfc/TerraFirmaCraft.java:237-238`：

```java
public void registerDatapackRegistries(DataPackRegistryEvent.NewRegistry event) {
    event.dataPackRegistry(RockSettings.KEY, RockSettings.CODEC);
}
```

**这是 `data/tfc/tfc/worldgen/` 存在的唯一原因**——NeoForge datapack registry 需要双命名空间路径。

### [W-5.2] `RockLayerSettings` —— 岩层分层规则

源码 `world/settings/RockLayerSettings.java`。它**不是**独立 JSON 文件，而是 `Settings`（即 `world_preset` 的 `tfc_settings`）的内联对象，路径 `tfc_settings.rock_layer_settings`。`Data` codec（第 186-188 行）字段：`rocks`（字符串→岩石 映射，值为 `RegistryFileCodec.create(RockSettings.KEY, RockSettings.CODEC)`，即引用 `tfc:granite` 这类 registry 条目）、`bottom`（字符串列表，最底层可选岩石短名）、`layers`（`LayerData` 列表）、`ocean_floor`/`land`/`volcanic`/`uplift`（四组顶层入口，每项为某个 layer 的 id 或 `bottom`）。

`LayerData`（第 193-194 行）：`id`（字符串，重复则报 `More than one layer named <id>`）+ `layers`（有序映射 `orderPreservingUnboundedMapCodec`，岩石短名 → 下一层 id）。
解析校验（`decode`，第 57-92 行）：`bottom` 与 `layers[].layers` 的 key 必须存在于 `rocks`（否则 `No rock with id: <name>`）；value 必须指向已定义的层 id（否则 `No layer with id: <id>`）；四组顶层入口同理。

采样逻辑（`sampleAtLayer(int pointRock, int layerN)`，第 147-160 行）：

```java
XoroshiroRandomSource source = new XoroshiroRandomSource(pointRock >> 2);
List<Layer> rootLayers = switch (pointRock & 3) {
    case 0 -> this.oceanFloor;  case 1 -> this.volcanic;
    case 2 -> this.land;        default -> this.uplift; };
Layer layer = rootLayers.get(source.nextInt(rootLayers.size()));
for (int i = 0; i < layerN; ++i) layer = layer.next.get(source.nextInt(layer.next.size()));
return layer.rock.value();
```

即 `pointRock & 3` 决定用哪一组顶层入口，`pointRock >> 2` 决定随机种子。

### [W-5.3] 完整真实样例（`world_preset/overworld.json` 的 `tfc_settings`）

路径 `data/tfc/worldgen/world_preset/overworld.json`（jar 内 2757 字节，此处摘出 `tfc_settings` 并格式化）：

```json
"tfc_settings":{
  "continentalness":0.5,"finite_continents":false,"flat_bedrock":false,"grass_density":0.5,
  "rainfall_scale":20000,"temperature_scale":20000,"spawn_distance":4000,
  "spawn_center_x":0,"spawn_center_z":0,
  "rock_layer_settings":{
    "bottom":["gneiss","schist","diorite","granite","gabbro"],
    "land":["sedimentary","sedimentary","sedimentary","igneous_extrusive"],
    "ocean_floor":["igneous_extrusive"],
    "volcanic":["igneous_extrusive","igneous_extrusive_x2","igneous_intrusive"],
    "uplift":["uplift","uplift","uplift","sedimentary"],
    "rocks":{"andesite":"tfc:andesite","basalt":"tfc:basalt","chalk":"tfc:chalk","chert":"tfc:chert",
             "claystone":"tfc:claystone","conglomerate":"tfc:conglomerate","dacite":"tfc:dacite",
             "diorite":"tfc:diorite","dolomite":"tfc:dolomite","gabbro":"tfc:gabbro","gneiss":"tfc:gneiss",
             "granite":"tfc:granite","limestone":"tfc:limestone","marble":"tfc:marble",
             "phyllite":"tfc:phyllite","quartzite":"tfc:quartzite","rhyolite":"tfc:rhyolite",
             "schist":"tfc:schist","shale":"tfc:shale","slate":"tfc:slate","tuff":"tfc:tuff"},
    "layers":[
      {"id":"felsic","layers":{"granite":"bottom"}},
      {"id":"intermediate","layers":{"diorite":"bottom"}},
      {"id":"mafic","layers":{"gabbro":"bottom"}},
      {"id":"igneous_extrusive","layers":{"andesite":"intermediate","basalt":"mafic","dacite":"intermediate","rhyolite":"felsic"}},
      {"id":"igneous_extrusive_x2","layers":{"andesite":"igneous_extrusive","basalt":"igneous_extrusive","dacite":"igneous_extrusive","rhyolite":"igneous_extrusive"}},
      {"id":"igneous_intrusive","layers":{"diorite":"intermediate","gabbro":"mafic","granite":"felsic"}},
      {"id":"high_grade","layers":{"gneiss":"bottom","schist":"bottom"}},
      {"id":"low_grade","layers":{"phyllite":"high_grade","slate":"high_grade"}},
      {"id":"marble","layers":{"marble":"bottom"}},
      {"id":"quartzite","layers":{"quartzite":"bottom"}},
      {"id":"sedimentary","layers":{"chalk":"marble","chert":"quartzite","claystone":"low_grade",
        "conglomerate":"low_grade","dolomite":"marble","limestone":"marble","shale":"low_grade"}},
      {"id":"uplift","layers":{"diorite":"low_grade","gabbro":"low_grade","gneiss":"high_grade",
        "granite":"low_grade","marble":"bottom","phyllite":"high_grade","quartzite":"bottom",
        "schist":"high_grade","slate":"high_grade"}}
    ]}}
```

`Settings`（`tfc_settings` 顶层）字段（`world/settings/Settings.java:21`）：`flat_bedrock`(bool)、`spawn_distance`/`spawn_center_x`/`spawn_center_z`(int)、`temperature_scale`(int)、`temperature_constant`(float，默认 `0.0`)、`rainfall_scale`(int)、`rainfall_constant`(float，默认 `0.0`)、`rock_layer_settings`、`continentalness`(float)、`grass_density`(float)、`finite_continents`(bool)——除两个 `*_constant` 外均必填。

### [W-5.4] 岩层如何进入地形

- `world/layer/RegionRockLayer.java`：`apply(TypedAreaFactory<Region.Point> prev)` 返回 `new Area((x,z) -> prevArea.get((int)x,(int)z).rock, 1024)`，即把 `Region.Point.rock` 经 Layer 放大到方块分辨率。
- `world/chunkdata/RegionChunkDataGenerator.java:183-184`：`int point = rockLayerArea.get().get(skewX, skewZ); RockSettings rock = rockLayerSettings.sampleAtLayer(point, layer);`
- `RegionGenerator.getSurfaceRock(point)`（第 161-163 行）= `rockLayerSettings().sampleAtLayer(point.rock, 0)`；`Region.Point.rock` 由 region 任务 `CHOOSE_ROCKS`（`world/region/ChooseRocks.java`，56 行）填充。
- 消费岩层数据的 feature：`world/feature/ErosionFeature.java:61`、`world/feature/cave/CaveSpikesFeature.java:62`、`world/feature/SpringFeature.java:48`、`world/surface/SurfaceBuilderContext.java:83`。

## [W-6] 气候与区域系统

### [W-6.1] 区域（Region）系统 —— **完全硬编码，无 JSON**

**明确结论：TFC 4.2.x 的区域系统没有任何 JSON 描述文件。** 源码 `net/dries007/tfc/world/region/`（25 个文件）：`Region`(274 行)、`RegionGenerator`(304)、`RegionPartition`(40)、`RiverEdge`(89)、`Units`(71)、`Init`(60)、`AddContinentsAndSetOceanDepths`(51)、`AddHotspots`(66)、`AddIslands`(38)、`AddMountainsAndBarrierIslands`(178)、`AddRiversAndLakes`(165)、`AnnotateBaseLandHeight`(76)、`AnnotateBiomeAltitude`(67)、`AnnotateBoundaryTypes`(23)、`AnnotateClimate`(66)、`AnnotateDistanceToCellEdge`(61)、`AnnotateDistanceToDeepOcean`(51)、`AnnotateDistanceToOcean`(54)、`AnnotateDistanceToWestCoast`(89)、`ChooseBiomes`(258)、`ChooseRocks`(56)、`FloodFillSmallOceans`(94)、`KarstSurfaceRocks`(26)。

任务序列**硬编码为枚举** `RegionGenerator.Task`（第 272-290 行，每项对应同名类的 `INSTANCE`）：

```
INIT → ANNOTATE_DISTANCE_TO_CELL_EDGE → ANNOTATE_BOUNDARY_TYPES → ADD_CONTINENTS
→ FLOOD_FILL_SMALL_OCEANS → ADD_HOTSPOTS → ANNOTATE_DISTANCE_TO_OCEAN
→ ANNOTATE_DISTANCE_TO_DEEP_OCEAN → ANNOTATE_BASE_LAND_HEIGHT → ANNOTATE_DISTANCE_TO_WEST_COAST
→ ADD_MOUNTAINS → ADD_ISLANDS → ANNOTATE_BIOME_ALTITUDE → ANNOTATE_CLIMATE → CHOOSE_ROCKS
→ ANNOTATE_KARST_SURFACE → ADD_RIVERS_AND_LAKES → CHOOSE_BIOMES
```

**“区域/气候数据”的真实载体是 `Region.Point`**（`Region.java:161-272`）：

| 字段 | 类型 | 说明 |
|---|---|---|
| `distanceToOcean` / `distanceToDeepOcean` / `distanceToEdge` / `distanceToWestCoast` / `distanceToLand` | byte | 各类距离 |
| `baseLandHeight` / `biomeAltitude` / `oceanDepth` | byte | 高度（`discreteBiomeAltitude() = biomeAltitude / 4`） |
| `rainfall` / `rainfallVariance` / `temperature` / `divergence` | float | 气候（`rainfallVariance` 范围 -1~1） |
| `biome` / `rock` | int | biome 索引（默认 `TFCLayers.OCEAN`）/ 岩层索引（`sampleAtLayer` 输入） |
| `isSurfaceRockKarst` / `hotSpotAge` | boolean / byte | 喀斯特表层岩标记 / 热点年龄 |
| `flags` | short（私有） | `LAND`=1、`ISLAND`=2、`RIVER`=4、`LAKE`=8、`MOUNTAIN`=16、`COASTAL_MOUNTAIN`=32、`VOLCANIC`=64、`BARRIER_ISLAND`=128 |

`Region` 本身是默认 `±101` 格的方形网格（第 41-46 行），中心来自 `Cellular2D.Cell`。**气候数值硬编码在 `AnnotateClimate.apply`**（第 28-55 行）：温度 = `baseNoise(false, temperatureScale, temperatureConstant).scaled(-20,30)` + `OpenSimplex2D.spread(0.15).scaled(-3,3)`；降雨 = `baseNoise(true, rainfallScale, rainfallConstant).scaled(0,500)` + `spread(0.15).scaled(-80,40)`；`rainfallVariance = clampedMap(distanceToWestCoast + noise, 0, 80, -1, 1)`；海洋邻近偏置 `temperature → lerp(bias, 5.0f, temperature)`、`rainfall → lerp(bias, min(rainfall+350, 500), rainfall)`。这些量**没有**任何 JSON 可配置。

> 题面提到的 `net/dries007/tfc/world/TFCRegions` **在该版本不存在**。`world/` 根目录 18 个 java 文件为：`BiomeNoiseSampler`、`ChunkBaseBlockSource`、`ChunkBiomeSampler`、`ChunkGeneratorExtension`、`ChunkHeightFiller`、`ChunkMapBridge`、`ChunkNoiseFiller`、`Codecs`、`FastConcurrentCache`、`MutableDensityFunctionContext`、`NoopClimateSampler`、`RandomStateExtension`、`Sampler`、`Seed`、`TFCAquifer`、`TFCChunkGenerator`、`TFCWorldGen`、`package-info`。

### [W-6.2] 气候模型（ClimateModel）—— **硬编码，无 JSON**

源码 `net/dries007/tfc/util/climate/`：`ClimateModel.java`（接口：温度、平均降雨、`type()`）、`ClimateModelType.java`（`record ClimateModelType<T extends ClimateModel>(StreamCodec<ByteBuf, T> codec)`）、`ClimateModels.java`（registry `KEY = tfc:climate_model`，`RegistryBuilder(KEY).sync(true).create()`，两项：`tfc:overworld` → `OverworldClimateModel`、`tfc:biome_based` → `BiomeBasedClimateModel`）、`OverworldClimateModel.java`（由 `ServerLevel` + `ChunkGeneratorExtension` 构造；`STREAM_CODEC = composite(VAR_LONG climateSeed, FLOAT temperatureScale)`）、`BiomeBasedClimateModel.java`（枚举单例）、`Climate.java`（从 `WorldTracker` 取当前模型）。

**关键结论：`ClimateModelType` 只带 `StreamCodec`（网络同步），不带 `Codec`/`MapCodec`，因此不存在对应 JSON 文件**；该注册表为同步注册表，由代码注册而非 datapack。选择逻辑 `ForgeEventHandler.java:1226-1231`：`event.setModel(new OverworldClimateModel(level, ex))`；默认值 `WorldTracker.java:78`：`private ClimateModel climateModel = BiomeBasedClimateModel.INSTANCE;`

### [W-6.3] biome 扩展（BiomeExtension）—— **硬编码，无 JSON**

源码 `world/biome/TFCBiomes.java`（215 行）。registry `KEY = tfc:biome_extension`（`RegistryBuilder(KEY).create()`，**不同步、无 Codec**）；`data/tfc/biome_extension/` 实测**不存在**。约 120 个常量硬编码，例：

```java
public static final BiomeExtension PLAINS = TFCBiomes.register("plains",
    BiomeBuilder.builder().heightmap(seed -> BiomeNoise.hills(seed, -2, 4))
        .surface(NormalSurfaceBuilder.INSTANCE).aquiferHeightOffset(-12.0)
        .spawnable().type(RiverBlendType.FLOODPLAIN));
public static final BiomeExtension OCEAN = TFCBiomes.register("ocean",
    BiomeBuilder.builder().heightmap(seed -> BiomeNoise.ocean(seed, -26, -12))
        .surface(ShoreAndOceanSurfaceBuilder.OCEAN).aquiferHeightOffset(-24.0)
        .salty().type(BiomeBlendType.OCEAN).noRivers());
```

`TFCBiomes.register(name, builder)`（第 207-213 行）以 `Registries.BIOME` 的**同名** `ResourceKey` 构建扩展，因此 **biome JSON 的 id 必须与 `TFCBiomes` 中的常量名严格一致**（`data/tfc/worldgen/biome/plains.json` ↔ `TFCBiomes.PLAINS`）。`TFCBiomes.findExtension`（第 201-205 行）用 biome 的 ResourceKey 到 `biome_extension` registry 中查同名条目。`world/layer/` 下另有 15 个 Layer（`ForestEdgeLayer`、`ForestInitLayer`、`ForestRandomizeLayer`、`ForestRandomizeSmallLayer`、`IceSheetEdgeLayer`、`MoreShoresLayer`、`RegionBiomeLayer`、`RegionEdgeBiomeLayer`、`RegionLayer`、`RegionRockLayer`、`ShoreAndRiverLayer`、`SmoothLayer`、`TFCLayers`、`UniformLayer`、`ZoomLayer`）把 region 网格数据放大至方块级；`TFCLayers.createOverworldRockLayer(regionGenerator, seed)` 在 `RegionChunkDataGenerator:69` 被实例化。

`world/chunkdata/ForestType.java` 定义 29 个枚举常量（`CODEC = StringRepresentable.fromEnum`，JSON 中写小写），供 `tfc:climate` 的 `forest_types` 使用：

```
GRASSLAND  CLEARING  SHRUBLAND  SPARSE  SAVANNA_MONOCULTURE  SAVANNA_DIVERSE
SAVANNA_ALTERNATE  SAVANNA_SHRUB_MONOCULTURE  SAVANNA_SHRUB_DIVERSE  SAVANNA_SHRUB_ALTERNATE
PRIMARY_MONOCULTURE  PRIMARY_DIVERSE  PRIMARY_ALTERNATE  SECONDARY_MONOCULTURE
SECONDARY_MONOCULTURE_TALL  SECONDARY_DIVERSE  SECONDARY_BAMBOO  SECONDARY_DIVERSE_TALL
SECONDARY_DENSE  SECONDARY_DENSE_TALL  SECONDARY_ALTERNATE  EDGE_MONOCULTURE  EDGE_DIVERSE
EDGE_ALTERNATE  EDGE_BAMBOO  DEAD_MONOCULTURE  DEAD_DIVERSE  DEAD_ALTERNATE  DEAD_BAMBOO
```

每个常量携带 `(ForestSubType subType, int density, IntProvider treeCount, IntProvider groundcoverCount, IntProvider leafPileCount, IntProvider bushCount, int maxTreeTypes, float perChunkChance, int alternateSize)`，`ForestSubType` = `NONE / PRIMARY / SECONDARY / EDGE / DEAD / SAVANNA`。代码侧由 `world/layer/Forest*Layer` 生成并存入 `ChunkData`。

## [W-7] TFC 自定义 placement modifier 全清单

注册器 `net/dries007/tfc/world/placement/TFCPlacements.java`（`Registries.PLACEMENT_MODIFIER_TYPE`，第 39-53 行），共 **15 项**：

| # | JSON `type` | 注册器常量 | 源码类 | 字段 | 字段（类型 = 默认值） |
|---|---|---|---|---|---|
| 1 | `tfc:flat_enough` | `FLAT_ENOUGH` | `FlatEnoughPlacement` | 有 | `flatness`(float 0~1 = 0.5)、`radius`(`Codecs.POSITIVE_INT` = 2)、`max_depth`(正整数 = 4) |
| 2 | `tfc:underground` | `UNDERGROUND` | `UndergroundPlacement` | 无 | `MapCodec.unit`；逻辑 `pos.getY() < 最高高度` |
| 3 | `tfc:carving_mask` | `CARVING_MASK` | `BoundedCarvingMaskPlacement` | 有 | `min_y`(`VerticalAnchor` = bottom)、`max_y`(= top)、`step`(`GenerationStep.Carving`，**必填**) |
| 4 | `tfc:climate` | `CLIMATE` | `ClimatePlacement` | 有 | 14 个，见下表 |
| 5 | `tfc:intertidal` | `INTERTIDAL` | `IntertidalPlacement` | 有 | `min_elevation`(int = -64)、`max_elevation`(int = 320)；相对 `BiomeNoise.shoreTideLevelNoise(seed)` 高潮位的高度差落入区间 |
| 6 | **`tfc:volcano`** | `VOLCANO` | **`CinderConePlacement`** | 有 | `center`(bool = false)、`min_easing`(`UNIT_FLOAT` = 0.0)、`max_easing`(`UNIT_FLOAT` = 1.0)；采样器 `CenteredFeatureNoise.cinder(seed)` |
| 7 | **`tfc:tuff_cone`** | `TUFF_RING` | **`TuffRingPlacement`** | 有 | 同上三字段；采样器 `CenteredFeatureNoise.tuffRing(seed)` |
| 8 | `tfc:tuya` | `TUYA` | `TuyaPlacement` | 有 | 同上三字段；采样器 `CenteredFeatureNoise.tuya(seed)` |
| 9 | `tfc:stratovolcano` | `STRATOVOLCANO` | `StratovolcanoPlacement` | 有 | `center`(false)、`use_offset_center`(false)、`variant`(string = `"all"`)、`min_easing`/`max_easing`(= 0.0/1.0)、`hash_min`/`hash_max`(= 0.0/1.0) |
| 10 | `tfc:atoll` | `ATOLL` | `AtollPlacement` | 有 | `center`/`min_easing`/`max_easing` 三字段；采样器 `CenteredFeatureNoise.atolls(seed)` |
| 11 | `tfc:near_fluid` | `NEAR_FLUID` | `NearFluidPlacement` | 有 | `radius`(`ExtraCodecs.NON_NEGATIVE_INT` = 2)、`fluids`(Fluid 列表 = null 即不限)；向下 `radius` 层、水平 `±radius` 内搜索 |
| 12 | `tfc:shallow_water` | `SHALLOW_WATER` | `ShallowWaterPlacement` | 有 | `min_depth`(`POSITIVE_INT`，允许 0 = 0)、`max_depth`(`POSITIVE_INT` = 5) |
| 13 | `tfc:on_top` | `ON_TOP` | `OnTopPlacement` | 有 | `predicate`(`BlockPredicate`，**必填**)；对 `pos.below()` 测试 |
| 14 | `tfc:no_solid_neighbors` | `NO_SOLID_NEIGHBORS` | `NoSolidNeighborsPlacement` | 无 | `MapCodec.unit`；水平四方向均非实心，且方块 `isWorldgenReplaceable` 或属 `TFCTags.Blocks.CAN_BE_SNOW_PILED` |
| 15 | `tfc:ocean_ridge` | `OCEAN_RIDGE` | `OceanRidgePlacement` | 有 | `min_distance`(int = `Integer.MIN_VALUE`)、`max_distance`(int = `Integer.MAX_VALUE`)；`BiomeNoise.getOceanRidgeWarpedEdgeDistanceAndScale(x,z,seed,false).x` 落入区间 |

> **易错点 1**：`tfc:volcano` 由 **`CinderConePlacement`**（火山渣锥）实现，**不是**通用“火山”判断；`tfc:tuff_cone` 由 `TuffRingPlacement`（凝灰岩环）实现；`tfc:stratovolcano` 才是层状火山。三者注册名与类名/常量名均不一致。
> **易错点 2**：#6/#7/#8/#10 四者继承抽象基类 `CenterOrDistanceToPlacement`（本身不注册），**字段完全相同**，仅 `createContext` 的采样器不同。

`tfc:climate`（`ClimatePlacement.java:46`）完整字段表：

| 字段 | 类型 | 默认 | 说明 |
|---|---|---|---|
| `min_temperature` / `max_temperature` | float | `-Inf` / `+Inf` | |
| `min_groundwater` / `max_groundwater` | float | `-Inf` / `+Inf` | 地下水（降雨量） |
| `min_rain_variance` / `max_rain_variance` | float | `-1.0` / `1.0` | |
| `rain_variance_absolute` | bool | `false` | 为 true 时取 `abs(rainVar)` |
| `min_forest` / `max_forest` | 非负 int | `0` / `4` | |
| `forest_types` | `ForestType` 列表 | `[]`（空=不限） | 取值见 [W-6.3] |
| `min_elevation` / `max_elevation` | int | `-64` / `320` | |
| `fuzzy` / `ignore_rivers` | bool | `false` | 边界模糊化 / 忽略河流影响 |

jar 内真实用法实例：

```json
// placed_feature/cobble_boulder.json
{"type":"tfc:flat_enough","flatness":0.4}
// placed_feature/plant/flame_vine.json（step 必填）
{"type":"tfc:carving_mask","step":"air","min_y":{"absolute":30},"max_y":{"absolute":100}}
{"type":"tfc:climate","min_temperature":14,"max_temperature":26.6,"min_groundwater":200,
 "max_groundwater":370,"min_rain_variance":0.3,"max_rain_variance":1.0,
 "rain_variance_absolute":true,"min_forest":1,"max_forest":4,"fuzzy":true}
// placed_feature/plant/arundo.json
{"type":"tfc:climate","min_temperature":2.5,"max_temperature":19.6,
 "min_groundwater":150,"max_groundwater":400}
{"type":"tfc:near_fluid","fluids":["tfc:salt_water","minecraft:water","tfc:spring_water"],"radius":6}
// placed_feature/plant/anemone_large_orange_patch.json、plant/barrel_cactus.json
{"type":"tfc:intertidal","min_elevation":-15,"max_elevation":0}
{"type":"tfc:intertidal","min_elevation":1,"max_elevation":512}
{"type":"tfc:no_solid_neighbors"}
// placed_feature/cinder_cone_obsidian_shard_patch.json、tuya_caldera.json、atoll_coral_claw.json
{"type":"tfc:volcano","min_easing":0.8}   {"type":"tfc:tuya","center":true}
{"type":"tfc:atoll","min_easing":0.3,"max_easing":0.42}
// placed_feature/plant/green_algae.json、extra_island_guano.json、ocean_ridge_rivulet.json
{"type":"tfc:shallow_water","max_depth":2}
{"type":"tfc:on_top","predicate":{"type":"minecraft:matching_block_tag","tag":"tfc:creeping_stone_plantable_on"}}
{"type":"tfc:ocean_ridge","min_distance":0,"max_distance":32}
```

**可直接套用的模板（附属模组）**：

```json
{"feature": "mymod:my_plant",
 "placement": [
   {"type": "minecraft:rarity_filter", "chance": 12},
   {"type": "minecraft:in_square"},
   {"type": "minecraft:heightmap", "heightmap": "WORLD_SURFACE_WG"},
   {"type": "tfc:climate", "min_temperature": 5, "max_temperature": 25,
    "min_groundwater": 100, "max_groundwater": 400, "min_forest": 0, "max_forest": 4},
   {"type": "block_predicate_filter", "predicate": {"type": "tfc:air_or_empty_fluid"}},
   {"type": "block_predicate_filter",
    "predicate": {"type": "would_survive", "state": {"Name": "mymod:my_plant"}}}]}
```

## [W-8] 其他 TFC 世界生成扩展

| 注册表 | `type` | 类 | 字段 |
|---|---|---|---|
| `Registries.BLOCK_PREDICATE_TYPE` | `tfc:air_or_empty_fluid` / `tfc:replaceable` / `tfc:dry_replaceable` | `AirOrEmptyFluidPredicate` / `ReplaceablePredicate` / `DryReplaceablePredicate` | 均无 |
| 同上 | `tfc:would_survive_with_fluid` | `WouldSurviveWithFluidPredicate` | `offset`(`Vec3i.offsetCodec(16)` = (0,0,0))、`state`(BlockState，必填) |
| `Registries.BLOCK_STATE_PROVIDER_TYPE` | `tfc:random_property` | `RandomPropertyProvider` | `state`(`Codecs.BLOCK_STATE`)、`property`(string)，均必填 |
| `Registries.CARVER` | `tfc:cave` / `tfc:canyon` | `TFCCaveCarver` / `TFCCanyonCarver` | 原版 `CaveCarverConfiguration` / `CanyonCarverConfiguration` |
| `Registries.STRUCTURE_PLACEMENT` | `tfc:climate` | `ClimateStructurePlacement` | 原版 `StructurePlacement` 字段 + `spacing`(0~4096)、`separation`(0~4096)、`spread_type`(`RandomSpreadType` = LINEAR)、`climate`(`ClimatePlacement`) |
| `Registries.CHUNK_GENERATOR` / `BIOME_SOURCE` | `tfc:overworld` | `TFCChunkGenerator` / `RegionBiomeSource` | 见 [W-2.4]；biome source 无字段 |
| `Registries.DENSITY_FUNCTION_TYPE` | `tfc:spaghetti2d` / `tfc:spaghetti3d` | `Spaghetti2D` / `Spaghetti3D` | 见 [W-2.4] |

源码位置依次为 `world/blockpredicate/TFCBlockPredicates.java`、`world/stateprovider/TFCStateProviders.java`、`world/carver/TFCCarvers.java`、`world/structure/TFCStructureHooks.java`、`world/TFCWorldGen.java`、`world/density/TFCDensityFunctions.java`。注意事项：

1. **`climate` 这个 id 同时存在于 `PLACEMENT_MODIFIER_TYPE` 与 `STRUCTURE_PLACEMENT` 两套注册表**，字段结构不同（后者含 `spacing`/`separation`）；引用时依上下文区分。
2. `world/stateprovider/SpecialRootPlacer.java` **不是注册项**，只是 `RootConfig.special_placer` 的内嵌对象：`{"special_placer":{"skew_chance":float}}`。
3. jar 内 `data/tfc/worldgen/` **无 `structure_set/`**，故 `tfc:climate` 的 structure placement 无实例；TFC 自身不使用。
4. block predicate 的 4 个 `type` 必须写在 `block_predicate_filter` 的 `predicate` 内，**不能**直接写进 `placement` 数组。

## [W-9] `data/tfc/tfc/worldgen/` 与 `data/tfc/worldgen/` 的区别

### [W-9.1] 结论对照

| 维度 | `data/tfc/worldgen/` | `data/tfc/tfc/worldgen/` |
|---|---|---|
| 数量 | 1498 个 JSON（6 个子目录） | **21 个 JSON（仅 `rock_settings/`）** |
| 加载方式 | 原版世界生成注册表（`BIOME`/`CONFIGURED_FEATURE`/`PLACED_FEATURE`/`DENSITY_FUNCTION`/`CONFIGURED_CARVER`/`WORLD_PRESET`） | **NeoForge datapack registry**（`DataPackRegistryEvent.NewRegistry`） |
| registry id | 各原版注册表 | `tfc:worldgen/rock_settings` |
| 定义类 / 注册处 | 原版 `RegistryDataLoader` | `world/settings/RockSettings.java` / `TerraFirmaCraft.java:237-238` |
| 路径规则 | `data/<ns>/worldgen/...` | `data/<ns>/tfc/worldgen/...` |

**“多一层 `tfc/`”的机制**：NeoForge datapack registry 的文件路径为 `data/<pack namespace>/<registry path>/*.json`。registry key 是 `tfc:worldgen/rock_settings`（命名空间 `tfc`、path `worldgen/rock_settings`），故文件必须在 `data/tfc/tfc/worldgen/rock_settings/`。

**关于“23 个文件”的更正**：任务描述称该目录下有 23 个文件，**实测为 21 个**，全部在 `rock_settings/` 下，与 TFC 的 21 种岩石一一对应，也与 `world_preset/overworld.json` 中 `rocks` 映射的 21 个键完全一致。依据：`Get-ChildItem '...\data\tfc\tfc\worldgen' -Recurse -File` 返回 21 项；`data/tfc/tfc/` 下另有 `climate_range`、`deposit`、`drinkable`、`fauna`、`fertilizer`、`fluid_heat`、`food`、`fuel`、`item_damage_resistance`、`item_heat`、`item_size`、`knapping_type`、`lamp_fuel`、`support`，均不属于 `worldgen`。

### [W-9.2] 完整清单与真实内容

```
data/tfc/tfc/worldgen/rock_settings/  （21 个，均为 <岩石名>.json）
andesite  basalt  chalk  chert  claystone  conglomerate  dacite  diorite  dolomite  gabbro
gneiss  granite  limestone  marble  phyllite  quartzite  rhyolite  schist  shale  slate  tuff
```

`granite.json` **全文（完整样例 4）**（jar 内为单行，此处格式化）：

```json
{"cobble":"tfc:rock/cobble/granite","gravel":"tfc:rock/gravel/granite",
 "hardened":"tfc:rock/hardened/granite","karst":false,
 "loose":"tfc:rock/loose/granite","mafic":false,
 "mossy_loose":"tfc:rock/mossy_loose/granite","raw":"tfc:rock/raw/granite",
 "sand":"tfc:sand/yellow","sandstone":"tfc:raw_sandstone/yellow",
 "spike":"tfc:rock/spike/granite"}
```

### [W-9.3] 二者协作链

1. `data/tfc/tfc/worldgen/rock_settings/*.json` 定义 21 种岩石各自对应的方块；
2. `data/tfc/worldgen/world_preset/overworld.json` 的 `tfc_settings.rock_layer_settings.rocks` 用短名→registry 引用（`"granite":"tfc:granite"`）引入，再以 `bottom`/`layers`/`ocean_floor`/`land`/`volcanic`/`uplift` 定义分层；
3. 运行时 `RegionChunkDataGenerator` → `RockLayerSettings.sampleAtLayer()` → `RockSettings` → `SurfaceBuilderContext` 生成实际方块。技术依据：`RockLayerSettings.java:187` 的 `RegistryFileCodec.create(RockSettings.KEY, RockSettings.CODEC)`。

### [W-9.4] 相关但独立的 `data/tfc/tfc/deposit/`（84）

`tfc:surface_*` 系列矿脉把 `tfc:deposit/<ore>/<rock>` 作为表层矿点方块写入。4 种矿 × 21 种岩 = 84 个文件。`native_copper/granite.json` 全文：

```json
{"ingredient":{"item":"tfc:deposit/native_copper/granite"},
 "loot_table":"tfc:deposit/native_copper_granite",
 "model_stages":["tfc:item/pan/native_copper/granite_full",
                 "tfc:item/pan/native_copper/granite_half",
                 "tfc:item/pan/native_copper/result"]}
```

矿脉中的引用方式（`configured_feature/vein/surface_native_copper.json` 片段）：

```json
{"replace":["tfc:rock/raw/rhyolite"],
 "with":[{"weight":70,"block":"tfc:ore/poor_native_copper/rhyolite"},
         {"weight":25,"block":"tfc:ore/normal_native_copper/rhyolite"},
         {"weight":5,"block":"tfc:ore/rich_native_copper/rhyolite"},
         {"weight":10,"block":"tfc:deposit/native_copper/rhyolite"}]}
```

## [W-10] 完整真实 JSON 样例索引

均取自 jar 内真实文件，路径相对 `jar-extract\data\tfc\`：

| # | jar 内路径 | 所在章节 | 完整度 |
|---|---|---|---|
| 1 | `worldgen/configured_carver/cave.json` | [W-2.3] | **全文** |
| 2 | `worldgen/configured_feature/vein/normal_native_silver.json` | [W-4.4] A | **全文**（`blocks` 中 3 条同类条目以文字省略） |
| 3 | `worldgen/configured_feature/vein/kaolin_disc.json` | [W-4.4] C | **全文** |
| 4 | `tfc/worldgen/rock_settings/granite.json` | [W-9.2] | **全文** |
| 5 | `worldgen/placed_feature/plant/arundo.json` | [W-10.1] | **全文** |
| 6 | `worldgen/configured_feature/tree/acacia_entry.json` | [W-10.2] | **全文** |
| 7 | `worldgen/configured_feature/cassiterite_deposit.json` | [W-10.3] | 节选（其余 17 条同构） |
| 8 | `worldgen/world_preset/overworld.json` 的 `tfc_settings` | [W-5.3] | 节选并格式化 |
| 9 | `worldgen/biome/plains.json` | [W-2.1] | 节选（`spawners` 约 45 条 creature） |
| 10 | `worldgen/configured_feature/vein/diorite_dike.json` | [W-4.4] B | 节选（21 种岩石列表） |

### [W-10.1] 样例 5 全文 —— `data/tfc/worldgen/placed_feature/plant/arundo.json`

```json
{"feature":"tfc:plant/arundo","placement":[
  {"type":"minecraft:heightmap","heightmap":"WORLD_SURFACE_WG"},
  {"type":"minecraft:rarity_filter","chance":3},
  {"type":"minecraft:in_square"},
  {"type":"tfc:climate","min_temperature":2.5,"max_temperature":19.6,
   "min_groundwater":150,"max_groundwater":400},
  {"type":"tfc:near_fluid","fluids":["tfc:salt_water","minecraft:water","tfc:spring_water"],"radius":6},
  {"type":"block_predicate_filter","predicate":{"type":"tfc:air_or_empty_fluid"}}]}
```

### [W-10.2] 样例 6 全文 —— `data/tfc/worldgen/configured_feature/tree/acacia_entry.json`

```json
{"type":"tfc:forest_entry","config":{
  "climate":{"min_temperature":10.4,"max_temperature":40,
             "min_groundwater":90,"max_groundwater":500,
             "min_rain_variance":0.4,"max_rain_variance":0.85,
             "rain_variance_absolute":true},
  "groundcover":[{"block":"tfc:wood/twig/acacia"},{"block":"tfc:wood/fallen_leaves/acacia"}],
  "normal_tree":"tfc:tree/acacia",
  "dead_tree":"tfc:tree/acacia_dead",
  "soil_disc":"tfc:duff_disc",
  "fallen_tree_chance":0,
  "bush_log":{"Name":"tfc:wood/wood/acacia","Properties":{"branch_direction":"down","axis":"y"}},
  "bush_leaves":"tfc:wood/leaves/acacia",
  "old_growth_tree":"tfc:tree/acacia_large"}}
```

### [W-10.3] 样例 7 节选 —— `data/tfc/worldgen/configured_feature/cassiterite_deposit.json`

```json
{"type":"tfc:soil_disc","config":{
  "min_radius":3,"max_radius":10,"height":3,"integrity":0.9,
  "states":[
    {"replace":"tfc:rock/raw/granite","with":"tfc:deposit/cassiterite/granite"},
    {"replace":"tfc:rock/raw/diorite","with":"tfc:deposit/cassiterite/diorite"},
    {"replace":"tfc:rock/raw/gabbro","with":"tfc:deposit/cassiterite/gabbro"},
    ...依次为 shale/claystone/limestone/conglomerate/dolomite/chert/chalk/tuff/rhyolite/basalt/
       andesite/dacite/quartzite/slate/phyllite/schist/gneiss，最后一条 marble...,
    {"replace":"tfc:rock/raw/marble","with":"tfc:deposit/cassiterite/marble"}]}}
```

（全文共 21 条 `states`，与 TFC 的 21 种岩石一一对应；**已省略中间 17 条同构条目**。）

## [W-11] 未能核实与注意事项

### [W-11.1] 已核实为「不存在 / 硬编码」的项

| 项目 | 结论 | 依据 |
|---|---|---|
| `net/dries007/tfc/world/TFCRegions` | **不存在** | `world/` 根目录 18 个 java 文件已逐一列出 |
| `net/dries007/tfc/world/rocklayer/` 包 | **不存在** | `world/` 下 18 个子目录列表中无此包 |
| `net/dries007/tfc/world/vein/` 包 | **不存在** | 同上；矿脉在 `world/feature/vein/` |
| 区域（region）系统的 JSON | **无，全部硬编码** | `world/region/` 25 个类；任务序列硬编码于 `RegionGenerator.Task`；气候数值硬编码于 `AnnotateClimate.apply` |
| 气候模型（ClimateModel）的 JSON | **无，全部硬编码** | `ClimateModelType` 只有 `StreamCodec` 无 `Codec`；`data/tfc/climate_model/` 不存在 |
| biome 扩展（BiomeExtension）的 JSON | **无，全部硬编码** | `TFCBiomes.java` 约 120 个 `register(...)`；`data/tfc/biome_extension/` 实测不存在 |
| `data/tfc/worldgen/` 下的 `noise_settings`、`template_pool`、`structure`、`processor_list`、`structure_set` | **均不存在** | 目录列举无此五项 |

### [W-11.2] 存疑点（已检查相关文件，仍无法完全定论）

1. **`StratovolcanoPlacement.variant` 的合法字符串取值**：字段为 `Codec.STRING`，默认 `"all"`；源码引用 `world/volcano/VolcanoVariant`，但字符串比较分支未逐一确认全部取值。jar 内 39 处 `tfc:stratovolcano` 均未显式指定。已检查：`world/placement/StratovolcanoPlacement.java`（CODEC 与类字段已读）、全部 `placed_feature/**`（正则检索 39 处）。
2. **`kaolin_disc.json` 的 `indicator.spread` 字段**：源码 `Indicator.CODEC` 无此字段，会被 codec 忽略（`RecordCodecBuilder` 默认不报未知字段错）。是否为旧版遗留或存在额外解码路径，**未能核实**。已检查：`world/feature/vein/Indicator.java`（全文）、`data/tfc/worldgen/configured_feature/vein/kaolin_disc.json`（全文）。
3. **`tfc:underground` 的实际使用数**：对 `placement` 数组的正规解析结果为 **0 次**；对文件全文正则匹配得 1 次（来自 `placed_feature/underground_loose_rocks.json` 的 `feature` id 字符串 `tfc:underground_loose_rocks`）。准确表述：**jar 内无任何 placed_feature 的 placement 数组使用 `tfc:underground`**。
4. **`PipeVeinConfig` 的 `height` forGetter**：反编译输出为 `c -> c.radius`，与 record 组件顺序矛盾，判定为 CFR 反编译瑕疵；JSON 字段名 `height` 无误。已检查：`world/feature/vein/PipeVeinConfig.java`（第 21-33 行）。
5. **`TFCFeatures` 注册项总数**：源码第 118-175 行共 **58** 条 `register(...)` 调用，非 55。本文按 58 条逐一列出。
6. **`data/tfc/tfc/worldgen/` 文件数**：任务描述为 23，实测 **21**。未在其他位置发现属于该 registry 的第 22、23 个文件。
7. **`Codecs.POSITIVE_INT` 是否允许 0**：该常量为原版 `ExtraCodecs.POSITIVE_INT`，`shallow_water` 的 `min_depth` 默认值为 `0`；本文按“非负整数”表述，未进一步反查原版 `ExtraCodecs` 的常量定义。
8. **`tfc:tuff_cone` 在 jar 内 0 次使用**，`TuffRingPlacement` 缺少可参照的实际用例；其字段已由源码 CODEC 确认，但实际生效效果未能核实。

### [W-11.3] 给附属模组的注意事项

1. 按气候放特征 → 用 `tfc:climate`（14 个字段，最全）。
2. **按岩层放特征没有现成 placement modifier**：要么用矿脉的 `blocks` 按母岩匹配，要么在自定义 Feature 内取 `ChunkGeneratorExtension.rockLayerSettings()`（Java 侧，参考 `world/feature/ErosionFeature.java:61`、`world/feature/SpringFeature.java:48`）。
3. 火山/环礁/凝灰岩环/冰原丘定位 → `tfc:volcano`（渣锥）/ `tfc:stratovolcano` / `tfc:tuff_cone` / `tfc:atoll` / `tfc:tuya`；字段仅 `center` + `min_easing` + `max_easing`（stratovolcano 另加 4 个）。注意 `tfc:tuff_cone` 无实例可参照。
4. 放置前判定“上方为空 / 可替换 / 可存活” → 用 `block_predicate_filter` + `tfc:air_or_empty_fluid` / `tfc:replaceable` / `tfc:dry_replaceable` / `tfc:would_survive_with_fluid`；**不要**把它们误写成 placement 的 `type`。
5. 新增岩石类型 → 需提供 `data/<ns>/tfc/worldgen/rock_settings/<name>.json` + 修改 `world_preset` 的 `tfc_settings.rock_layer_settings`。后者是 world_preset 内联数据，要改动必须整体覆盖 overworld 的 world preset；**TFC 源码中未发现任何此类扩展点**，属高风险改动。
