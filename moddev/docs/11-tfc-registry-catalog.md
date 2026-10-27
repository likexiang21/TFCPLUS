# TFC 注册名目录、枚举维度与资源清单速查

> 本文是「我到底该用哪个 id / 哪个枚举」的检索表。
> 数据来源：jar 4.2.10 资源清单 + CFR 反编译源码中的枚举定义。

---

## 0. 已生成的清单文件（可直接 grep）

| 文件 | 内容 | 规模 |
|---|---|---|
| `moddev/inventory/TFC-block-ids.txt` | 全部方块 id（从 `assets/tfc/blockstates/*.json` 反推） | 4504 条 |
| `moddev/inventory/TFC-item-ids.txt` | 全部物品 id（从 `assets/tfc/models/item/*.json` 反推） | 5597 条 |
| `moddev/inventory/TFC.classes.txt` | 全部类全名（`net.dries007.tfc.*` 等） | 2051 条 |
| `moddev/inventory/TFC.resources.txt` | jar 内全部资源路径 | 43184 条 |
| `moddev/inventory/api-dump/TFC-public-api.txt` | 284 个核心类的 `javap -public` 签名 | 371K 字符 |

**用法示例**（查「有没有某种岩石的砖块」）：

```powershell
Select-String -Path "moddev\inventory\TFC-block-ids.txt" -Pattern "rock/bricks"
```

---

## 1. 五大枚举维度（写循环注册时的核心）

TFC 的世界内容建立在 5 个枚举 + 若干横切维度上。**做「给每种 X 加一个方块」类需求时，直接遍历这些枚举。**

### 1.1 `net.dries007.tfc.util.Metal`（27 种金属）

```
BISMUTH, BISMUTH_BRONZE, BLACK_BRONZE, BRONZE, BRASS, COPPER, GOLD, NICKEL, ROSE_GOLD,
SILVER, TIN, ZINC, STERLING_SILVER, WROUGHT_IRON, CAST_IRON, PIG_IRON, STEEL,
BLACK_STEEL, BLUE_STEEL, RED_STEEL, WEAK_STEEL, WEAK_BLUE_STEEL, WEAK_RED_STEEL,
HIGH_CARBON_STEEL, HIGH_CARBON_BLACK_STEEL, HIGH_CARBON_BLUE_STEEL, HIGH_CARBON_RED_STEEL,
UNKNOWN
```

构造参数（源码 `Metal.java:106-133`）：`(int color, MapColor, Rarity, float weatheringResistance, PartType[, Tier, ArmorMaterial])`。

`Metal.PartType` 决定这种金属「有哪些形态」（`DEFAULT`、`DEFAULT_WEATHERING`、`INGOT`、`ALL`、`ALL_WEATHERED`、`WEATHERED`），
用 `PartType.has(metal)` 判断。**这是给金属加新形态时的关键开关。**

**`Metal.ItemType`（46 种物品形态，源码 `Metal.java:273-319`）**：
`INGOT, DOUBLE_INGOT, SHEET, DOUBLE_SHEET, ROD, TUYERE, FISH_HOOK, FISHING_ROD, UNFINISHED_LAMP,`
`PICKAXE, PICKAXE_HEAD, PROPICK, PROPICK_HEAD, AXE, AXE_HEAD, SHOVEL, SHOVEL_HEAD, HOE, HOE_HEAD,`
`CHISEL, CHISEL_HEAD, HAMMER, HAMMER_HEAD, SAW, SAW_BLADE, JAVELIN, JAVELIN_HEAD, SWORD, SWORD_BLADE,`
`MACE, MACE_HEAD, KNIFE, KNIFE_BLADE, SCYTHE, SCYTHE_BLADE, SHEARS, UNFINISHED_HELMET, HELMET,`
`UNFINISHED_CHESTPLATE, CHESTPLATE, UNFINISHED_GREAVES, GREAVES, UNFINISHED_BOOTS, BOOTS,`
`HORSE_ARMOR, SHIELD`

**`Metal.BlockType`（25 种方块形态，源码 `Metal.java:368-389`）**：
`BLOCK, EXPOSED_BLOCK, WEATHERED_BLOCK, OXIDIZED_BLOCK, BLOCK_SLAB(+变体 4), BLOCK_STAIRS(+变体 4),`
`GRATE, EXPOSED_GRATE, WEATHERED_GRATE, OXIDIZED_GRATE, ANVIL, BARS, CHAIN, LAMP, TRAPDOOR`

取用方式：`TFCItems.METAL_ITEMS.get(metal).get(Metal.ItemType.INGOT)`、
`TFCBlocks.METALS.get(metal).get(Metal.BlockType.ANVIL)`。

### 1.2 `net.dries007.tfc.common.blocks.wood.Wood`（20 种木材）

```
ACACIA, ASH, ASPEN, BIRCH, BLACKWOOD, CHESTNUT, DOUGLAS_FIR, HICKORY, KAPOK, MANGROVE,
MAPLE, OAK, PALM, PINE, ROSEWOOD, SEQUOIA, SPRUCE, SYCAMORE, WHITE_CEDAR, WILLOW
```

构造参数：`(boolean isConifer, float autumnIndex/fallHue, MapColor woodColor, MapColor barkColor, int ticksToGrow, int autumnIndex)`
（精确语义见源码 `Wood.java:114-133`）。

**`Wood.BlockType`（40+ 种形态）** —— 这是「给每种木材加一套方块」时最完整的参照：

```
LOG, STRIPPED_LOG, WOOD, STRIPPED_WOOD, LEAVES, PLANKS, SAPLING, POTTED_SAPLING, BOOKSHELF,
DOOR, TRAPDOOR, FENCE, LOG_FENCE, FENCE_GATE, BUTTON, PRESSURE_PLATE, SLAB, STAIRS,
TOOL_RACK, TWIG, FALLEN_LEAVES, VERTICAL_SUPPORT, HORIZONTAL_SUPPORT, WORKBENCH,
TRAPPED_CHEST, CHEST, LOOM, SLUICE, SIGN, WALL_SIGN, BARREL, LECTERN, SCRIBING_TABLE,
SEWING_TABLE, SHELF, AXLE, BLADED_AXLE, ENCASED_AXLE, CLUTCH, GEAR_BOX, WINDMILL,
WATER_WHEEL, CRATE
```

取用：`TFCBlocks.WOODS.get(wood).get(Wood.BlockType.PLANKS)`；
每个 `BlockType` 自己知道工厂函数与方块物品工厂（`BlockType` 是带函数的枚举，可直接被附属模组借鉴）。

### 1.3 `net.dries007.tfc.common.blocks.rock.Rock`（21 种岩石）

```
GRANITE, DIORITE, GABBRO, SHALE, CLAYSTONE, LIMESTONE, CONGLOMERATE, DOLOMITE, CHERT, CHALK,
TUFF, RHYOLITE, BASALT, ANDESITE, DACITE, QUARTZITE, SLATE, PHYLLITE, SCHIST, GNEISS, MARBLE
```

每个岩石带一个 `RockDisplayCategory`（`FELSIC_IGNEOUS_INTRUSIVE`、`SEDIMENTARY`、`MAFIC_IGNEOUS_EXTRUSIVE`、
`METAMORPHIC` 等，分类影响纹理与工具需求）。`Rock.BlockType` 含 `RAW, COBBLE, BRICKS, SMOOTH, SLAB/STAIRS/WALL 变体,
GRAVEL, SAND, ANVIL, …`（完整列表见源码 `Rock.java:142` 起的枚举）。

取用：`TFCBlocks.ROCK_BLOCKS.get(Rock.GRANITE).get(Rock.BlockType.BRICKS)`、
`TFCBlocks.ROCK_ANVILS.get(Rock.GABBRO)`。

另有 `Ore`（矿石种类）与 `Ore.Grade`（`POOR/NORMAL/RICH`）：`TFCItems.ORES`、`TFCItems.GRADED_ORES`。

### 1.4 其它横切维度

| 枚举 / 类型 | 用途 | 取用点 |
|---|---|---|
| `DyeColor` | 16 色染色方块/流体 | `TFCBlocks.DYED_*`、`TFCFluids.COLORED_FLUIDS` |
| `SimpleFluid` | TFC 的简单流体（盐水、醋、染料等） | `TFCFluids.SIMPLE_FLUIDS` |
| `Crop` / `FruitBlocks.Tree` / `FruitBlocks.StationaryBush` / `FruitBlocks.SpreadingBush` | 作物与果树 | `TFCBlocks.CROPS`、`TFCBlocks.FRUIT_TREE_*` |
| `Plant` / `Coral` | 野生植物与珊瑚 | `TFCBlocks.PLANTS` |
| `GroundcoverBlockType` | 地表小物件 | `TFCBlocks.GROUNDCOVER` |
| `Nutrient` | 营养维度 | `Nutrient.VALUES`、`Nutrient.getColor()` |
| `SoilBlockType` / `SoilBlockType.Variant` | 土壤 | `TFCBlocks.SOIL` |
| `FoodTrait` | 食物词条（注册表） | `TFCComponents.FOOD` / `FoodTraits.REGISTRY` |
| `ChiselMode` / `GlassOperation` | 凿子模式 / 玻璃工序（注册表） | `TFCBlocks`、`interaction` 相关 |

---

## 2. 注册名命名规律（照它编自己的 id 就能与 TFC 风格一致）

| 类别 | 规律 | 例子 |
|---|---|---|
| 岩石类 | `rock/<type>/<rock>` | `tfc:rock/raw/granite`、`tfc:rock/bricks/slate` |
| 矿石 | `ore/<grade>/<ore>` | `tfc:ore/rich_hematite`、`tfc:ore/poor_malachite` |
| 金属 | `metal/<type>`、`metal/<blocktype>/<metal>` | `tfc:metal/ingot/copper`、`tfc:metal/block/bronze_stairs` |
| 木材 | `wood/<type>/<wood>` | `tfc:wood/planks/oak`、`tfc:wood/barrel/pine` |
| 植物 | `plant/<name>`、`plant/potted/<name>` | `tfc:plant/banana_sapling` |
| 作物 | `crop/<name>`、`seeds/<name>` | `tfc:crop/wheat`、`tfc:seeds/wheat` |
| 果品 | `food/<name>`、`fruit/<name>` | `tfc:food/cooked_grouse` |
| 陶器 | `ceramic/<name>` | `tfc:ceramic/large_vessel`、`tfc:ceramic/ingot_mold` |
| 粉状物 | `powder/<name>` | `tfc:powder/flux`、`tfc:powder/salt` |
| 设备 | 直接短名 | `tfc:anvil`、`tfc:firepit`、`tfc:barrel`（木材前缀者在 `wood/` 下） |
| 染色变体 | `<base>/<color>` | `tfc:alabaster/bricks/black`、`tfc:wood/planks/oak`（染色者用 `color.getName()`） |

**附属模组命名建议**：`mymod:<type>/<name>`，并在资源里复用 TFC 的 `tfc:wood/*` 等父级 tag 以便被 TFC 的配方/工具正确识别
（例如让自定义木材方块进 `tfc:mineable_with_axe`、`minecraft:logs` 之类的 tag）。

---

## 3. 各类注册表 id 速查

### 3.1 配方类型（TFC 注册的 28 个 `type` 值）

由 `TFCRecipeTypes` + `TFCRecipeSerializers` 注册，完整字段见 `12-tfc-data-driven.md`：

```
tfc:collapse  tfc:landslide  tfc:chisel  tfc:heating  tfc:quern  tfc:pot  tfc:scraping
tfc:knapping  tfc:alloy  tfc:casting  tfc:loom  tfc:barrel_sealed  tfc:barrel_instant
tfc:barrel_instant_fluid  tfc:bloomery  tfc:anvil  tfc:welding  tfc:blast_furnace
tfc:glassworking  tfc:sewing
tfc:pot_soup  tfc:pot_jam  tfc:food_combining  tfc:casting_crafting
tfc:advanced_shaped_crafting  tfc:advanced_shapeless_crafting
```
（另有两种沿用原版：`minecraft:crafting_shaped`、`minecraft:crafting_shapeless`。）

### 3.2 `data/tfc/tfc/` 数据表名（TFC 的 `DataManager` 语义 id）

```
item_heat (377)  food (197)  deposit (89)  fauna (78)  item_size (68)  fuel (53)
climate_range (52)  fluid_heat (29)  worldgen (23)  fertilizer (14)
item_damage_resistance (12)  drinkable (6)  knapping_type (6)  lamp_fuel (5)
entity_damage_resistance (3)  support (2)
```

附属模组要往这些表里加内容：路径写 `data/<你的命名空间>/tfc/<表名>/xxx.json`。

### 3.3 菜单（`TFCContainerTypes` 的 25 个）

```
calendar  nutrition  climate  salad  workbench  scribing_table  sewing_table  firepit  grill
pot  charcoal_forge  firebox  crucible  barrel  powderkeg  nest_box  large_vessel  anvil
anvil_plan  blast_furnace  chest_9x2  chest_9x4  small_vessel_inventory  mold_like_alloy  knapping
```

### 3.4 方块实体（`TFCBlockEntities`，部分代表项）

`firepit / pot / grill / barrel / crucible / anvil / bloomery / blast_furnace / charcoal_forge /
quern / loom / sluice / chest / trapped_chest / barrel / shelf / placed_item / ingot_pile /
crop / farmland / tick_counter / nest_box / large_vessel / mold_table / channel / pump /
windmill / water_wheel / axle / clutch / gear_box / power_loom / crankshaft / lamp / vane / anemometer /
thermometer / calendar_clock / bell / sign / hanging_sign / lectern / bookshelf / decaying /
glass_basin / hot_poured_glass / scraping / pit_kiln / log_pile / burning_log_pile / powderkeg / composter /
bloom / bowl / crate / tool_rack / thatch_bed / sluice`

（完整注册名以 `net/dries007/tfc/common/blockentities/TFCBlockEntities.java` 为准。）

### 3.5 组件（`TFCComponents` 的 16 个）

`tfc:forging  tfc:forging_bonus  tfc:glass  tfc:heat  tfc:food  tfc:bowl  tfc:ingredients
tfc:deposit  tfc:bait  tfc:plant  tfc:egg  tfc:fluid  tfc:vessel  tfc:contents  tfc:barrel  tfc:crucible`

### 3.6 能力（ItemCapability）

`tfc:heat`（`IHeat`）、`tfc:mold`（`IMold`），以及 NeoForge 内置的
`neoforge:fluid_handler`（`Capabilities.FluidHandler.ITEM`）与 `neoforge:item_handler`（`Capabilities.ItemHandler.ITEM`）。

---

## 4. 常见「我要 X」对照

| 需求 | 用哪个 |
|---|---|
| 拿任意金属的锭物品 | `TFCItems.METAL_ITEMS.get(Metal.COPPER).get(Metal.ItemType.INGOT)` |
| 遍历所有金属做批量注册 | `for (Metal metal : Metal.values())`，先用 `metal.has(PartType...)` 过滤 |
| 拿任意木材的原木方块 | `TFCBlocks.WOODS.get(Wood.OAK).get(Wood.BlockType.LOG)` |
| 拿任意岩石的圆石 | `TFCBlocks.ROCK_BLOCKS.get(Rock.GRANITE).get(Rock.BlockType.COBBLE)` |
| 拿砧方块 | `TFCBlocks.ROCK_ANVILS.get(Rock.GABBRO)` 或金属砧 `TFCBlocks.METALS.get(metal).get(Metal.BlockType.ANVIL)` |
| 判断物品能否被某工具采掘 | `Helpers.isBlock(state, TFCTags.Blocks.MINEABLE_WITH_KNIFE)` 等 `TFCTags` |
| 拿 TFC 的 TNT/火药类 | `TFCBlocks.POWDERKEG` |
| 拿盐/助熔剂 | `TFCItems.POWDERS.get(Powder.SALT)` / `Powder.FLUX` |
| 金属流体 | `TFCFluids.METALS.get(metal).getSource()` / `getFlowing()` |
| 简单流体 | `TFCFluids.SIMPLE_FLUIDS.get(SimpleFluid.TANNIN)` |
