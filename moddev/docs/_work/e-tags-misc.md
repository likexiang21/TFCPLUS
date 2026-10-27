# TFC 4.2.10 数据格式调查：tag 体系 / 自定义 ingredient / loot / advancement

调查对象：TerraFirmaCraft NeoForge 1.21.1-4.2.10（jar：`mods\TerraFirmaCraft-NeoForge-1.21.1-4.2.10.jar`）。

数据来源与引用约定：

- jar 内真实数据：`moddev\jar-extract\data\tfc\...`（路径均相对 `moddev\jar-extract\`）
- 反编译源码：`moddev\src-ref\TFC-decompiled\net\dries007\tfc\...`（无参数名、无注释）
- 本文件中「未能核实」= 已检查过列出的文件但无法从这些文件得出结论。

---

## [T-1] tags 体系

### T-1.1 实测目录与文件数

以 `Get-ChildItem -Recurse -File` 实测（统计口径：注册表目录下递归的 `.json` 文件数）：

| 注册表目录 | 递归文件数 | 其中一级文件 | 子目录 |
|---|---|---|---|
| `data/tfc/tags/item/` | 203 | 172 | 6 个 |
| `data/tfc/tags/block/` | 143 | 134 | 3 个 |
| `data/tfc/tags/entity_type/` | 35 | 35 | 0 |
| `data/tfc/tags/fluid/` | 22 | 22 | 0 |
| `data/tfc/tags/damage_type/` | 3 | 3 | 0 |
| `data/tfc/tags/worldgen/` | 440 | 0 | 3 个（`biome`、`configured_feature`、`placed_feature`） |
| **合计** | **846** | — | — |

> 与任务描述给出的数字（worldgen 450 / item 211 / block 147 / entity_type 36 / fluid 23 / damage_type 4）存在系统性差异：任务描述的每个值都恰好比实测多 4~10 个。实测结果以本表为准，且 `item`/`block` 的"一级文件 + 子目录内文件"合计已核对一致（172+31=203，134+9=143）。

`worldgen` 子目录细分（实测）：

| 路径 | 文件数 |
|---|---|
| `tags/worldgen/biome/` | 26 |
| `tags/worldgen/configured_feature/` | 3 |
| `tags/worldgen/placed_feature/feature/` | 23 |
| `tags/worldgen/placed_feature/in_biome/` | 9 |
| `tags/worldgen/placed_feature/in_biome/large_features/` | 125 |
| `tags/worldgen/placed_feature/in_biome/soil_discs/` | 125 |
| `tags/worldgen/placed_feature/in_biome/surface_decoration/` | 125 |
| `tags/worldgen/placed_feature/in_biome/veins/` | 4 |

### T-1.2 注册表维度

TFC 使用的 tag 注册表由源码 `net\dries007\tfc\common\TFCTags.java` 的嵌套类确定：

| 嵌套类 | 注册表 | `TagKey.create` 位置 |
|---|---|---|
| `TFCTags.Biomes` | `Registries.BIOME` | `TFCTags.java:58` |
| `TFCTags.Entities` | `Registries.ENTITY_TYPE` | `TFCTags.java:107` |
| `TFCTags.Items` | `Registries.ITEM`（含转发到 `c:` 命名空间的重载） | `TFCTags.java:339,343,347` |
| `TFCTags.Fluids` | `Registries.FLUID` | `TFCTags.java:378` |
| `TFCTags.Blocks` | `Registries.BLOCK`（含转发到 `c:` 命名空间的重载） | `TFCTags.java:502,506` |

另外 `net\dries007\tfc\util\PhysicalDamageType.java:152-155` 单独定义了 `damage_type` 注册表下的 4 个常量：

- `tfc:bypasses_damage_resistances`
- `tfc:is_piercing`
- `tfc:is_crushing`
- `tfc:is_slashing`

`net\dries007\tfc\common\blocks\rotation\CrankshaftBlock.java:81` 另有一个内联 tag 常量：

- `c:rods/steel`（`Registries.ITEM`）

全源码 `TagKey.create` 仅出现在上述 3 个类中（`grep "TagKey\.create"` 命中 14 处，其中 6 处在 `TFCTags` 的 `create`/`tag`/`commonTag` 工厂方法内）。

### T-1.3 item tag 的命名空间结构（重要：TFC **没有** `metals/*`、`ores/*` 这类大目录）

`data/tfc/tags/item/` 下**只有 6 个一级子目录**，其余 172 个 tag 全部是扁平的单文件：

| 子目录 | 文件 | 语义 | 源码常量 |
|---|---|---|---|
| `compost_greens/` | `low.json`、`medium.json`、`high.json` | 堆肥"绿料"按肥力分三档 | `TFCTags.java:169-172` |
| `compost_browns/` | `low.json`、`medium.json`、`high.json` | 堆肥"褐料"按肥力分三档 | `TFCTags.java:173-176` |
| `double_sheets/` | `any_bronze.json` | 全部青铜系双层板（引用 `#c:double_sheets/bronze`、`#c:double_sheets/bismuth_bronze`、`#c:double_sheets/black_bronze`） | `TFCTags.java:230` |
| `foods/` | `can_be_salted.json`、`empty_jars.json`、`empty_jars_with_lid.json`、`filled_jars.json`、`jam.json`、`jars.json`、`preserves.json`、`sealed_preserves.json`、`sweeteners.json` | 食物归类与罐装/保存品判定 | `TFCTags.java:129-146` |
| `stones/loose/` | `igneous_extrusive.json`、`igneous_intrusive.json`、`metamorphic.json`、`sedimentary.json` | 按岩石大类分的"松散石块"；id 由 `RockCategory` 动态拼成 `stones/loose/<category>` | `TFCTags.java:309`（`Helpers.mapOf(RockCategory.class, type -> Items.tag("stones/loose/" + type.getSerializedName()))`） |
| `tools/` | `bismuth_bronze`、`black_bronze`、`black_steel`、`blue_steel`、`bronze`、`copper`、`red_steel`、`sharp`、`steel`、`stone`、`wrought_iron`（共 11 个） | 按材质分的"整套金属工具"，以及 `sharp`（能割的） | `TFCTags.java:239-251` |

注意区分两套工具 tag：

- `tfc:tools/<metal>`（11 个文件，每文件列齐该金属的 16 件工具，如 `tfc:metal/pickaxe/bronze`）
- `c:tools/<tool>`（NeoForge 通用命名空间，如 `c:tools/hammer`、`c:tools/knife`；TFC 侧常量 `TOOLS_HAMMER` 等定义在 `TFCTags.java:231-238`，指向 `c:` 而非 `tfc:`）
- `tfc:tools/sharp.json` 内容为 `["#minecraft:hoes","#c:tools/knife","#c:tools/scythe"]` —— 它**间接**依赖 vanilla 与 `c:` tag，附属模组若只加物品而不打 vanilla/`c:` tag，不会进入此 tag。

### T-1.4 item tag 一级文件的功能分组

以下为 `data/tfc/tags/item/` 下 172 个一级文件的完整功能分组（文件名即 tag 路径，如 `alpaca_food.json` → `tfc:alpaca_food`）。

| 分组 | 条数 | tag 路径（均省略 `tfc:` 前缀） | 源码常量位置 |
|---|---|---|---|
| 动物饲料（用于手持喂食，与 `entity_type` 侧无关） | 22 | `alpaca_food`、`camel_food`、`cat_food`、`chicken_food`、`cow_food`、`dog_food`、`donkey_food`、`duck_food`、`frog_food`、`goat_food`、`horse_food`、`mule_food`、`musk_ox_food`、`ocelot_food`、`penguin_food`、`pig_food`、`quail_food`、`rabbit_food`、`seal_food`、`sheep_food`、`turtle_food`、`yak_food` | `TFCTags.java:147-168` |
| 原木分类（砍伐/木炭/单宁等，每种树一个 tag） | 24 | `acacia_logs`、`ash_logs`、`aspen_logs`、`birch_logs`、`blackwood_logs`、`chestnut_logs`、`douglas_fir_logs`、`hickory_logs`、`kapok_logs`、`mangrove_logs`、`maple_logs`、`oak_logs`、`palm_logs`、`pine_logs`、`rosewood_logs`、`sequoia_logs`、`spruce_logs`、`sycamore_logs`、`white_cedar_logs`、`willow_logs`、`tannin_logs`，以及用途型的 `firepit_logs`、`log_pile_logs`、`pit_kiln_logs` | `TANNIN_LOGS` `:275`、`FIREPIT_LOGS` `:279`、`LOG_PILE_LOGS` `:280`、`PIT_KILN_LOGS` `:283`；其余按树名动态生成，未在 `TFCTags` 逐个列常量 |
| 燃料与点火 | 9 | `firepit_fuel`（`:295`）、`forge_fuel`（`:296`）、`blast_furnace_fuel`（`:297`）、`blast_furnace_tuyeres`（`:298`）、`firepit_kindling`（`:277`）、`firepit_sticks`（`:278`）、`usable_in_powder_keg`（`:300`）、`can_be_lit_on_torch`（`:285`）、`inefficient_logging_axes`（`:284`） | 同左列括号内行号 |
| 打制（knapping）原料 | 5 | `rock_knapping`（`:286`）、`clay_knapping`（`:287`）、`fire_clay_knapping`（`:288`）、`leather_knapping`（`:289`）、`goat_horn_knapping`（`:290`） | 同左列括号内行号 |
| 玻璃与吹管 | 9 | `glass_batches`（`:257`）、`glass_batches_tier_2`（`:258`）、`glass_batches_tier_3`（`:259`）、`glass_batches_not_tier_1`（`:260`）、`glass_blowpipes`（`:261`）、`all_blowpipes`（`:262`）、`glass_bottles`（`:264`）、`glass_potash`（`:265`）、`glass_powders`（`:263`） | 同左列括号内行号 |
| 烹饪与食物加工 | 12 | `usable_in_soup`（`:143`）、`usable_in_salad`（`:142`）、`usable_in_sandwich`（`:144`）、`usable_in_jam_sandwich`（`:145`）、`soup_bowls`（`:140`）、`salad_bowls`（`:141`）、`bowl_powders`（`:307`）、`wild_crops`（`:183`）、`plants`（`:182`）、`compost_browns`、`compost_greens`、`compost_poisons`（`:177`） | 同左列括号内行号 |
| 机械与动力 | 9 | `axles`（`:222`）、`gear_boxes`（`:223`）、`clutches`（`:224`）、`water_wheels`（`:220`）、`windmill_blades`（`:221`）、`colored_windmill_blades`（`:194`）、`support_beams`（`:225`）、`lumber`（`:226`）、`sluices`（`:203`） | 同左列括号内行号 |
| 冶炼、铸造与容器 | 12 | `molds`（`:213`）、`unfired_molds`（`:214`）、`fired_molds`（`:215`）、`vessels`（`:207`）、`unfired_vessels`（`:208`）、`fired_vessels`（`:209`）、`large_vessels`（`:210`）、`unfired_large_vessels`（`:211`）、`fired_large_vessels`（`:212`）、`unfired_pottery`（`:314`）、`usable_in_mold_table`（`:301`）、`trip_hammers`（`:303`） | 同左列括号内行号 |
| 工具与手工艺 | 9 | `quern_handstones`（`:291`）、`scraping_waxes`（`:308`）、`sewing_needles`（`:294`）、`sewing_dark_cloth`（`:292`）、`sewing_light_cloth`（`:293`）、`high_quality_cloth`（`:270`）、`skeleton_weapons`（`:320`）、`usable_on_tool_rack`（`:299`）、`scribing_ink`（`:305`） | 同左列括号内行号 |
| 颜色变体 | 15 | `colored_wool`、`colored_carpets`、`colored_beds`、`colored_banners`、`colored_terracotta`、`colored_glazed_terracotta`、`colored_shulker_boxes`、`colored_concrete_powder`、`colored_candles`、`colored_windmill_blades`、`colored_raw_alabaster`、`colored_alabaster_bricks`、`colored_polished_alabaster`、`colored_vessels`、`colored_large_vessels` | `TFCTags.java:185-199` |
| 物理伤害 3 件套（物品侧） | 3 | `deals_slashing_damage`、`deals_piercing_damage`、`deals_crushing_damage` | `TFCTags.java:254-256`；判定逻辑在 `PhysicalDamageType.java:117-128`（依次 PIERCING → SLASHING → CRUSHING） |

**补充分组 A：矿物与金属（关键结论）** —— 只有这 4 个矿石/矿脉相关 tag，**不存在 `tfc:ores/*` 目录**：

| tag id | 语义 | 内容形态（实测） | 源码 |
|---|---|---|---|
| `tfc:metal_ores` | 全部金属矿石物品（poor/normal/rich 三档混排） | 36 个条目 | `TFCTags.java:252` |
| `tfc:ore_pieces` | 全部"矿石物品"（含非金属矿物，55 条） | 55 个条目 | `TFCTags.java:218` |
| `tfc:small_ore_pieces` | 地表小矿石（12 条） | 12 个条目 | `TFCTags.java:219` |
| `tfc:ore_deposits` | 可放置的矿脉露头方块物品（4 金属 × 21 岩石 = 84 条） | 84 个条目 | `TFCTags.java:274` |

**补充分组 B：其它高频/机制 tag**：
`anvils`（`:332`）、`barrels`（`:205`）、`workbenches`（`:333`）、`aqueducts`（`:334`）、`lamps`（`:216`）、`looms`（`:204`）、`scribing_tables`（`:201`）、`sewing_tables`（`:202`）、`tool_racks`（`:200`）、`minecart_holdable`（`:302`）、`minecarts`（`:217`，`c:` 命名空间）、`twigs`（`:206`）、`fluxstone`（`:276`）、`welding_flux`（`:304`）、`gem_powders`（`:271`）、`mud_brick_items`（`:253`）、`mud_bricks`（`:331`）、`metal_plated_blocks`（`:315`）、`mob_feet_armor`/`mob_leg_armor`/`mob_chest_armor`/`mob_head_armor`（`:316-319`）、`disabled_monster_held_items`（`:311`）、`fox_spawns_with`（`:312`）、`carried_by_horse`（`:313`）、`thatch_bed_hides`（`:306`）、`small_fishing_bait`/`large_fishing_bait`/`holds_small_fishing_bait`/`holds_large_fishing_bait`（`:178-181`）、`fluid_item_ingredient_empty_containers`（`:310`）、`scraped_hide`（`:241`）。

**补充分组 C：与 block tag 同名复用的 item tag（9 个）** —— 源码用 `Items.tag(TagKey<Block>)` 直接复制 block tag 的 `ResourceLocation`（`TFCTags.java:338-340`），因此这些 tag 在 `item/` 与 `block/` 下**同名成对存在**：
`tfc:dirt`、`tfc:grass`、`tfc:coarse_dirt`、`tfc:mud`、`tfc:mud_bricks`、`tfc:anvils`、`tfc:workbenches`、`tfc:aqueducts`、`tfc:fallen_leaves`、`tfc:clay_indicators`，以及 `tfc:stones/raw`、`tfc:stones/hardened`、`tfc:stones/smooth`、`tfc:stones/smooth_slabs`、`tfc:stones/pressure_plates`、`tfc:stones/loose`（`TFCTags.java:321-336`）。
附属模组要同时给方块和物品打标时必须写两份文件（分别放 `tags/block/` 与 `tags/item/`），TFC 本身也是这样做的。

### T-1.5 block tag 结构

一级子目录只有 3 个：

| 子目录 | 文件 | 语义 |
|---|---|---|
| `clays/` | `kaolin.json` | 高岭土类方块；常量 `KAOLIN_CLAYS`（`TFCTags.java:456`）；另有扁平文件 `clays.json`（`CLAYS`，`:455`） |
| `mineable/` | `chisel.json`、`glass_saw.json`、`hammer.json`、`hoe.json`、`knife.json`、`propick.json`、`scythe.json`（7 个） | TFC 工具的可挖掘方块集合；常量 `MINEABLE_WITH_*`（`TFCTags.java:439-445`）。**注意**：`mineable/chisel.json` 与 `mineable/propick.json` 在 jar 内是空数组 `{"values":[]}` |
| `spreading_bushes/` | `living.json` | 活着的蔓延灌木；常量 `LIVING_SPREADING_BUSHES`（`TFCTags.java:428`）；另有扁平 `spreading_bushes.json`（`:429`） |

其余 134 个 block tag 为扁平文件，按机制分组：

- **地形塌方/滑坡**：`can_collapse`、`can_start_collapse`、`can_trigger_collapse`、`can_landslide`、`supports_landslide`、`not_solid_supporting`、`toughness_1`、`toughness_2`、`toughness_3`、`breaks_when_isolated`（`TFCTags.java:383-392`）
- **保温/隔热（冶炼）**：`insulation`、`heat_insulation`、`heat_passable`、`charcoal_pit_insulation`、`charcoal_forge_insulation`、`charcoal_forge_invisible`、`bloomery_insulation`、`blast_furnace_insulation`、`smokes_in_rain`（`TFCTags.java:402,410-416,438`）
- **植物可种植面（10+ 个）**：`anemone_plantable_on`、`tree_grows_on`、`wild_crop_grows_on`、`spreading_fruit_grows_on`、`bush_plantable_on`、`dry_plant_plantable_on`、`epiphyte_plantable_on`、`grass_plantable_on`、`sea_bush_plantable_on`、`halophyte_plantable_on`、`creeping_stone_plantable_on`、`creeping_plant_not_plantable_on`（`TFCTags.java:464-475`）
- **农业/土壤**：`dirt`、`grass`、`coarse_dirt`、`farmlands`、`paths`、`mud`、`duff`、`mud_bricks`、`clays`、`increases_soil_hydration`、`decreases_soil_hydration`、`very_rich_farmland`、`rich_farmland`、`normal_farmland`、`poor_farmland`、`very_poor_farmland`、`converts_to_humus`（`TFCTags.java:447-463,435`）
- **实体行为**：`rabbit_raidable`、`fox_raidable`、`pet_sits_on`、`camel_faster_on`、`bear_crawls_on`、`monster_spawns_on`、`animal_ignored_plants`、`natural_regrowing_plants`、`consumes_tool_durability`（`TFCTags.java:476-484`）
- **世界生成/替换**：`extra_cave_carver_replaceable`、`single_block_replaceable`、`kaolin_clay_replaceable`、`powder_snow_replaceable`、`cancels_flood_fill_lake`、`tide_pool_blocks`、`sea_stack_rocks`、`cold_ocean_blocks`（`TFCTags.java:403,490-496`）
- **爆炸与保护**：`explosion_proof`（常量名 `POWDERKEG_CANNOT_BREAK`）、`powderkeg_breaking_blocks`（常量名 `POWDERKEG_CAN_BREAK`）（`TFCTags.java:431-432`）
- **可积雪/结冰**：`can_be_snow_piled`、`can_be_ice_piled`、`solid_top_face`（`TFCTags.java:433-436`）
- **岩浆/荧光/显示**：`lit_by_dropped_torch`、`thermometer_readable`、`clock_readable`、`lamps`（`TFCTags.java:437,497-498,404`）
- **岩石系列（`c:` 命名空间）**：`c:stones/raw`、`c:stones/hardened`、`c:stones/smooth`、`c:stones/smooth_slabs`、`c:stones/spike`、`c:stones/pressure_plate`、`c:stones/loose`（`TFCTags.java:395-401`，用 `commonTag`）
- **植物/珊瑚类**（**无 TFCTags 常量引用，未能核实源码引用点**）：`mosses`、`epiphytes`、`ferns`、`shrubs`、`cacti`、`tall_grasses`、`dead_plants`、`dry_plants`、`shore_plants`、`creeping_plant_not_plantable_on`（后者有常量）、`halophyte`、`thorny_bushes`、`spreading_bushes`、`fruit_tree_branches`、`fruit_tree_leaves`、`fruit_tree_saplings`、`kelp_trees`、`kelp_branches`、`salt_water_corals`、`salt_water_coral_plants`、`salt_water_wall_corals`、`fresh_emergent_plants`、`fresh_floating_plants`、`fresh_underwater_plants`、`salty_emergent_plants`、`salty_floating_plants`、`salty_underwater_plants`、`bamboo`、`bamboo_sapling`（`TFCTags.java:424-430,486-489` 只覆盖其中一部分）。这些 tag 中有一部分在 `TFCTags.java` 里有常量（见括号内行号），另一部分（`mosses`、`epiphytes`、`ferns`、`shrubs`、`cacti`、`tall_grasses` 等）在反编译源码中**没有任何 `TagKey` 常量或字符串引用**（已 grep `mosses|epiphytes|"ferns"|"shrubs"|"cacti"|tall_grasses`，仅命中 `TFCTags.java:446,497` 两个不相关的 tag）。

### T-1.6 fluid tag（22 个，全部扁平）

对应 `TFCTags.Fluids`（`TFCTags.java:351-380`）：

| tag id | 语义 | 源码行 |
|---|---|---|
| `tfc:any_fresh_water` | 所有淡水 | 354 |
| `tfc:any_infinite_water` | 所有可无限取水的液体 | 355 |
| `tfc:fresh_water` | 淡水（具体液体） | 356 |
| `tfc:salt_water` | 盐水 | 357 |
| `tfc:infinite_water` | 无限水源 | 358 |
| `tfc:mixable` | 可在桶/罐中混合 | 359 |
| `tfc:hydrating` | 可湿润土壤 | 360 |
| `tfc:alcohols` | 酒类 | 361 |
| `tfc:molten_metals` | 熔融金属（实测 28 条 `tfc:metal/*`） | 362 |
| `tfc:drinkables` | 可饮用 | 363 |
| `tfc:ingredients` | 酿制/加工原料液体 | 364 |
| `tfc:usable_in_pot` | 可用锅 | 365 |
| `tfc:usable_in_jug` | 可用壶 | 366 |
| `tfc:usable_in_wooden_bucket` | 木桶类 | 367 |
| `tfc:usable_in_red_steel_bucket` | 红钢桶 | 368 |
| `tfc:usable_in_blue_steel_bucket` | 蓝钢桶 | 369 |
| `tfc:usable_in_barrel` | 可用大桶（实测内容为 `["#tfc:ingredients"]`） | 370 |
| `tfc:usable_in_scribing_table` | 可用划线台 | 371 |
| `tfc:usable_in_sluice` | 可用洗矿槽 | 372 |
| `tfc:usable_in_ingot_mold` | 可用锭模 | 373 |
| `tfc:usable_in_tool_head_mold` | 可用工具头模 | 374 |
| `tfc:usable_in_bell_mold` | 可用钟模 | 375 |

### T-1.7 entity_type tag（35 个，全部扁平）

`data/tfc/tags/entity_type/` 的完整文件清单：
`animals`、`bears`、`big_cats`、`bird_prey`、`bubble_column_immune`、`canine_predators`、`cold_pests`、`dairy_animals`、`desert_pests`、`farm_animals`、`hunted_by_cats`、`hunted_by_dogs`、`hunted_by_land_predators`、`hunted_by_ocean_predators`、`ignores_snow`、`land_predators`、`large_prey`、`monsters`、`needs_large_fishing_bait`、`not_rammed_by_rammers`、`ocean_predators`、`oviparous_animals`、`pests`、`pets`、`ramming_animals`、`rideable_animals`、`shearable_animals`、`small_fish`、`spawns_on_cold_blocks`、`tropical_pests`、`turtle_friends`、`universal_pests`、`water_ambient`、`water_creatures`、`wild_prey_animals`。

对应 `TFCTags.Entities`（`TFCTags.java:62-108`）。其中：

- `tfc:animals` 是聚合 tag，实测内容为 `["#tfc:land_predators","#tfc:water_ambient","#tfc:water_creatures","#tfc:pests","#tfc:pets","#tfc:ramming_animals","#tfc:water_creatures","#tfc:farm_animals","#tfc:wild_prey_animals","tfc:rabbit"]`（注意其中 `#tfc:water_creatures` 重复出现两次，属 jar 内原样数据）。
- `AMPHIBIOUS_CREATURES` 常量（`TFCTags.java:90`）**与 `WATER_CREATURES` 指向同一个 id** `tfc:water_creatures`，不存在单独的 `tfc:amphibious_creatures` 文件。
- 物品侧的 `deals_*_damage` 是 **item tag**；实体侧同样存在 `tfc:deals_slashing_damage` / `deals_piercing_damage` / `deals_crushing_damage` 三个 **entity_type tag**（`TFCTags.java:66-68`），由 `PhysicalDamageType.java:103-111` 使用。

### T-1.8 damage_type tag（3 个）

对应源码 `net\dries007\tfc\util\PhysicalDamageType.java:151-156`。

| tag id | jar 内真实内容 | 源码行 |
|---|---|---|
| `tfc:is_crushing` | `{"values":["minecraft:in_wall","minecraft:cramming","minecraft:fall","minecraft:fly_into_wall","minecraft:falling_block","minecraft:falling_anvil"]}`（6 条） | 154 |
| `tfc:is_piercing` | `{"values":["minecraft:cactus","minecraft:sweet_berry_bush","minecraft:stalagmite","minecraft:falling_stalactite","minecraft:sting","minecraft:arrow","minecraft:trident"]}`（7 条） | 153 |
| `tfc:is_slashing` | `{"values":[]}`（**空**） | 155 |

以上三条内容均为直接读取文件所得（`data/tfc/tags/damage_type/`）。

**语义**：把 vanilla 伤害类型归入 TFC 的物理伤害三分类。这三个 tag 由**数据包填充**（TFC 自己写入了 crushing/piercing 的条目），代码侧通过 `TagKey` 引用；`tfc:is_slashing` 在 jar 内为空，说明斩击类伤害在 1.21.1 原版伤害类型中没有需要归入的项，或该项由其它来源填充。

另需注意：`PhysicalDamageType.java:152` 还声明了第 4 个常量 `tfc:bypasses_damage_resistances`，但 jar 内**没有对应文件**（`data/tfc/tags/damage_type/` 下只有上述 3 个文件）。

### T-1.9 worldgen tag（440 个，3 个层级）

全部为 `Registries.BIOME` / configured_feature / placed_feature 侧的标准 tag JSON，写法与其它注册表一致（含显式 `"replace":false`）。

- `tags/worldgen/biome/*`（26 个）：生物群系分类，如 `is_ocean`、`is_river`、`is_karst`、`is_glaciated`、`is_ice_sheet`、`is_shilin`、`has_atolls`、`has_tuyas` 等（`TFCTags.Biomes`，`TFCTags.java:36-59`）。
- `tags/worldgen/configured_feature/*`（3 个）：`dead_forest_trees`、`forest_trees`、`mangrove_forest_trees`。
- `tags/worldgen/placed_feature/*`（411 个）：按 `feature/`、`in_biome/`、`in_biome/large_features/`、`in_biome/soil_discs/`、`in_biome/surface_decoration/`、`in_biome/veins/` 组织，用于按生物群系分类注入地物。

### T-1.10 关于任务描述中猜测 tag 的逐条核实

| 任务描述中的 tag | 实测结论 | 依据 |
|---|---|---|
| `tfc:metals/*`（每种金属一个 tag） | **不存在**。`data/tfc/tags/item/` 与 `block/` 下都没有 `metals/` 目录，源码 `TFCTags` 中也没有任何 `metals` 字符串（grep `"metals|metals/` 全源码仅命中 `metal_ores`） | 目录枚举 + grep |
| `tfc:ores/<ore>/<grade>` 形式 | **不存在**。矿石使用扁平 tag：`tfc:metal_ores`、`tfc:ore_pieces`、`tfc:small_ore_pieces`、`tfc:ore_deposits`；而 `<ore>/<grade>` 形态出现在**物品 id** 上（`tfc:ore/poor_native_copper`、`tfc:ore/normal_*`、`tfc:ore/rich_*`、`tfc:ore/small_*`）与**矿脉方块 id** 上（`tfc:deposit/<ore>/<rock>`） | `item/metal_ores.json`、`item/ore_deposits.json` 内容 |
| 按 item size 分类的 tag | **不存在**。item size 由自定义注册表 `data/tfc/tfc/item_size/*.json`（67 个文件）定义，不是 tag。样例：`{"ingredient":{"tag":"c:foods"},"size":"small","weight":"light"}`（`tfc/item_size/foods.json`） | 目录枚举 + 文件内容 |
| 按 food 分类的 tag | **存在**，但范围有限，仅 `tfc:foods/*` 的 9 个文件（`can_be_salted`、`empty_jars`、`empty_jars_with_lid`、`filled_jars`、`jam`、`jars`、`preserves`、`sealed_preserves`、`sweeteners`）+ 22 个 `*_food`（动物饲料）。真正的食物属性数据在 `data/tfc/tfc/food/`（195 个文件） | `data/tfc/tags/item/foods/`、`data/tfc/tfc/food/` |
| `tfc:forge_invisible_whitelist` | **不存在**。相关的是 `tfc:charcoal_forge_invisible`（block tag，`TFCTags.java:412`）。grep `forge_invisible_whitelist` 全源码无命中 | grep |
| `tfc:can_be_chiseled` | **不存在**。与凿子相关的是 `tfc:mineable/chisel`（block tag，`TFCTags.java:440`，jar 内容为空数组）与 `tfc:tools/chisel`→`c:tools/chisel`。grep `can_be_chiseled` 全源码无命中 | grep |
| `minecraft:*` 中 TFC 常用者 | TFC 数据文件实际引用到的 vanilla tag 共 19 个：`minecraft:axes`、`coals`、`dirt`、`hoes`、`leaves`、`logs`、`logs_that_burn`、`mineable/hoe`、`pickaxes`、`sand`、`shovels`、`small_flowers`、`stone_bricks`、`swords`、`undead`、`water`、`wool`、`wool_carpets`（另 `#minecraft:hoes` 等出现在 `item/tools/sharp.json`） | 正则统计 `tags/` 下全部文件中的 `#minecraft:` 引用 |

### T-1.11 附属模组必须提供的通用 tag（`c:` 命名空间）

TFC 数据文件与源码引用到的 `c:` tag 去重清单（共 46 个），这些是第三方模组"接入 TFC"的最常见契约：

```
c:books                c:bowls                    c:chests                    c:chests/wooden
c:cobblestones         c:double_sheets/bismuth_bronze            c:double_sheets/black_bronze
c:double_sheets/bronze c:foods                    c:foods/bread               c:foods/cooked_fish
c:foods/cooked_meat    c:foods/dairy              c:foods/fruit               c:foods/grain
c:foods/meat           c:foods/raw_fish           c:foods/vegetable           c:glass_blocks
c:glass_panes          c:gravels                  c:ores                      c:rods/wooden
c:sands                c:sandstone/blocks         c:seeds                     c:stones
c:stones/hardened      c:stones/loose             c:stones/raw                c:stones/smooth
c:stones/spike         c:tools                    c:tools/blowpipe            c:tools/bow
c:tools/chisel         c:tools/crossbow           c:tools/fishing_rod         c:tools/hammer
c:tools/knife          c:tools/mace               c:tools/saw                 c:tools/scythe
c:tools/shear          c:tools/shield             c:tools/spear
```

其中 `c:stones/*`、`c:sands/*`、`c:double_sheets/*`、`c:rods/steel`、`c:tools/*`、`c:foods/*` 由 `TFCTags` 中的 `commonTag(...)` 工厂（`TFCTags.java:346-348`、`:505-507`）或内联常量（`CrankshaftBlock.java:81`）定义/引用；其余（`c:ores`、`c:cobblestones`、`c:glass_blocks` 等）只出现在 tag JSON 的 `values` 引用中。

### T-1.12 真实 tag JSON 样例（含 jar 内路径）

**样例 1~3：最简 `values` / 嵌套引用 `#tag`（含 `c:` 命名空间）/ 聚合 tag** —— 依次为 `data/tfc/tags/item/foods/sweeteners.json`、`data/tfc/tags/item/tools/sharp.json`、`data/tfc/tags/item/compost_greens.json`

```json
{"values":["minecraft:sugar"]}
{"values":["#minecraft:hoes","#c:tools/knife","#c:tools/scythe"]}
{"values":["#tfc:compost_greens/low","#tfc:compost_greens/medium","#tfc:compost_greens/high"]}
```

**样例 4：显式 `"replace":false`** —— `data/tfc/tags/worldgen/placed_feature/feature/ore_deposits.json`

```json
{"replace":false,"values":["tfc:native_copper_deposit","tfc:native_copper_deep_deposit","tfc:cassiterite_deposit","tfc:cassiterite_deep_deposit","tfc:native_silver_deposit","tfc:native_silver_deep_deposit","tfc:native_gold_deposit","tfc:native_gold_deep_deposit"]}
```

**样例 5：`remove` 字段** —— `data/tfc/tags/item/foods/preserves.json`（节选，原文为单行）

```json
{"remove":["tfc:jar/peanut_unsealed"],"values":["tfc:jar/blackberry_unsealed","tfc:jar/blueberry_unsealed","...（共 22 项）","tfc:jar/peanut_unsealed"]}
```

**样例 6：空 tag** —— `data/tfc/tags/damage_type/is_slashing.json`

```json
{"values":[]}
```

**关于 vanilla 的 `{"id":..., "required":...}` 对象形式**：TFC 的 846 个 tag 文件中均未使用该形式。核对方式：对 `data/tfc/tags/` 下全部文件做 `"required"` 全文匹配，命中 0 个文件（`required` 是对象形式的标志字段），因此 jar 内 TFC 的 tag 值全部为纯字符串形式（tag 引用写作 `"#ns:path"`）。

### T-1.13 tag 覆盖 / 新增 / 合并规则

**规则本体不在 TFC 源码中**：TFC 只声明 `TagKey` 常量并读取 tag，不实现 tag 文件的加载与合并。加载逻辑由原版 `net.minecraft.tags.TagLoader` + NeoForge 的数据包加载器完成（反编译源码中已确认只有 `TFCTags.java`、`PhysicalDamageType.java`、`CrankshaftBlock.java`、`BlockIngredient.java` 出现 `TagKey.create`，无任何 tag 加载/合并代码）。因此以下规则描述的是**原版数据包 tag 机制**，不是从 TFC 源码读出的：

1. **同 id 合并（默认）**：多个数据包（含模组 jar）提供同一个 `data/<ns>/tags/<registry>/<路径>.json` 时，若都没有 `replace:true`，则所有 `values` 取并集。TFC 的聚合 tag 正是依赖这一点（例如 `tfc:compost_greens` 引用三个子 tag）。
2. **`replace: true`**：该文件的值**取代**此前所有来源对该 tag 的贡献（而不是追加）。TFC 自己在 `worldgen/placed_feature/feature/*.json` 里大量显式写 `"replace":false`，属于"显式声明不替换"，效果与省略该字段相同。
3. **第三方不应在 `data/tfc/` 命名空间下新增文件**：以 `tfc` 为命名空间写文件会与 TFC 自身的数据文件冲突（同路径文件在数据包优先级下互相覆盖），且 TFC 更新时可能被替换。正确做法是在**自己的 `data/<modid>/tags/` 下新建文件并填入自己的内容**，或用一个 `data/tfc/tags/...` 占位文件配合 `replace:true`（仅在必须覆盖时）。
4. **引用第三方 tag 以扩展 TFC 行为**：TFC 的很多 tag 是"由数据驱动、TFC 不写入"的空 tag（见 T-1.14），附属模组只需在 **自己的** 命名空间放 `data/<modid>/tags/item/<tfc_tag_path>.json`？—— **不成立**：tag 的归属命名空间是文件路径中的 `tfc`，因此要往 `tfc:xxx` 这个 tag 里加条目，**必须**创建 `data/tfc/tags/<registry>/<path>.json`（内容不含 `replace`，从而与原文件合并）。这是原版机制下的必然结果，也是 TFC 数据包/附属模组的通行做法。
5. **`remove` 字段**：jar 内 4 个文件使用了 `"remove"`（`item/usable_in_soup.json`、`item/foods/jam.json`、`item/foods/preserves.json`、`item/foods/sealed_preserves.json`），语义应从合并结果中删除指定条目。**该字段的加载语义未能核实**：TFC 反编译源码中不含 tag 加载代码，无法从本仓库确认 1.21.1 + NeoForge 21.1.248 的 `TagFile` codec 是否支持 `remove`、以及它是在合并前还是合并后生效。此处仅记录 jar 内真实存在该字段及其所在文件。

### T-1.14 源码声明但 jar 内**没有**对应数据文件的 tag

已通过"源码常量清单 vs jar 文件清单"交叉比对确认：

| tag id | 源码位置 | jar 内状态 |
|---|---|---|
| `tfc:bypasses_damage_resistances` | `PhysicalDamageType.java:152` | 无 `tags/damage_type/bypasses_damage_resistances.json` |
| `tfc:horses` | `TFCTags.java:69` | 无 `tags/entity_type/horses.json` |
| `tfc:destroyed_by_leaves` | `TFCTags.java:70` | 无对应文件 |
| `tfc:leashable_wild_animals` | `TFCTags.java:71` | 无对应文件 |
| `tfc:no_icicle_generation` | `TFCTags.java:499` | 无 `tags/block/no_icicle_generation.json` |

含义：这些 tag 在 TFC 内部会以"空 tag"形式存在（`Helpers.isItem/isEntity` 对空 tag 恒返回 false），只有在数据包或附属模组写入条目后才会生效。附属模组可以安全地把自己的条目加到这些 tag 里（见 T-1.13 第 4 条关于路径的说明）。

反向情况（jar 内有文件、`TFCTags` 中无常量）：`block/mosses`、`block/epiphytes`、`block/ferns`、`block/shrubs`、`block/cacti`、`block/tall_grasses` 等。这些文件**未能核实**其源码读取点——已 grep 全源码相应字符串（`mosses|epiphytes|"ferns"|"shrubs"|"cacti"|tall_grasses`），只命中无关的 `TFCTags.java:446,497`。它们可能是仅供数据包/附属模组使用的公共 tag，或由反编译产物未覆盖的代码路径使用。

---

## [T-2] 自定义 recipe ingredient（TFCIngredients）

### T-2.1 注册表与 type id 全清单

注册类：`net\dries007\tfc\common\recipes\ingredients\TFCIngredients.java`

```java
public static final DeferredRegister<IngredientType<?>> TYPES =
    DeferredRegister.create(NeoForgeRegistries.INGREDIENT_TYPES, "tfc");
```

（`TFCIngredients.java:41`）——即注册目标是 **NeoForge 的 `IngredientType` 注册表**（不是 vanilla `RecipeType`），命名空间 `tfc`。

`TFCIngredients.java:42-48` 注册的全部 7 个类型：

| JSON `type` id | Java 类（全名） | 注册常量 | 源码行 |
|---|---|---|---|
| `tfc:rotten` | `net.dries007.tfc.common.recipes.ingredients.RottenIngredient` | `ROTTEN` | 42 |
| `tfc:not_rotten` | `net.dries007.tfc.common.recipes.ingredients.NotRottenIngredient` | `NOT_ROTTEN` | 43 |
| `tfc:has_trait` | `net.dries007.tfc.common.recipes.ingredients.HasTraitIngredient` | `HAS_TRAIT` | 44 |
| `tfc:lacks_trait` | `net.dries007.tfc.common.recipes.ingredients.LacksTraitIngredient` | `LACKS_TRAIT` | 45 |
| `tfc:heat` | `net.dries007.tfc.common.recipes.ingredients.HeatIngredient` | `HEAT` | 46 |
| `tfc:fluid_content` | `net.dries007.tfc.common.recipes.ingredients.FluidContentIngredient` | `FLUID_CONTENT` | 47 |
| `tfc:and` | `net.dries007.tfc.common.recipes.ingredients.AndIngredient` | `AND` | 48 |

**共 7 个自定义 ingredient type。** 这是 `TFCIngredients` 中所有 `register(...)` 调用的完整数量（同文件内无其它注册点）。

### T-2.2 逐类字段表

#### （1）`tfc:rotten` —— `RottenIngredient`

- 源码：`net\dries007\tfc\common\recipes\ingredients\RottenIngredient.java`
- 形态：`public enum RottenIngredient implements PreciseIngredient { INSTANCE; }`（单例枚举，`RottenIngredient.java:22-24`）
- CODEC：`MapCodec.unit(INSTANCE)`（`:43`）→ **无任何字段**
- 判定：`FoodCapability.isRotten(stack)`（`:30`）
- 显示改写：`FoodCapability.setRotten(stack)`（`:35`）

| 字段名 | 类型 | 必需性 | 默认值 | 语义 |
|---|---|---|---|---|
| （无） | — | — | — | `MapCodec.unit`，只需 `{"type":"tfc:rotten"}` |

真实用例：**jar 内无真实用例**。已对 `data/tfc/` 下全部 14162 个 JSON 文件做全文匹配，`"type":"tfc:rotten"` 命中 0 个文件。
（注意区分：loot function `tfc:rotten` 有 2 个真实用例，见 T-3；两者同名但属不同注册表。）

按 CODEC 推导的最小示例（**推导，非实测**）：

```json
{"type":"tfc:rotten"}
```

#### （2）`tfc:not_rotten` —— `NotRottenIngredient`

- 源码：`net\dries007\tfc\common\recipes\ingredients\NotRottenIngredient.java`
- 形态：单例枚举（`:22-24`）
- CODEC：`MapCodec.unit(INSTANCE)`（`:43`）→ **无字段**
- 判定：`!FoodCapability.isRotten(stack)`（`:30`）
- 显示改写：`FoodCapability.setInvisibleNonDecaying(stack)`（`:35`）

| 字段名 | 类型 | 必需性 | 默认值 | 语义 |
|---|---|---|---|---|
| （无） | — | — | — | 无字段 |

真实用例：560 个文件（`"type":"tfc:not_rotten"`）。示例 —— `data/tfc/recipe/quern/food/wheat_flour.json`：

```json
{"type":"tfc:quern","ingredient":{"type":"tfc:and","children":[{"item":"tfc:food/wheat_grain"},{"type":"tfc:not_rotten"}]},"result":{"modifiers":[{"type":"tfc:copy_food"}],"stack":{"count":1,"id":"tfc:food/wheat_flour"}}}
```

#### （3）`tfc:has_trait` —— `HasTraitIngredient`

- 源码：`net\dries007\tfc\common\recipes\ingredients\HasTraitIngredient.java`
- 形态：`public record HasTraitIngredient(Holder<FoodTrait> trait) implements PreciseIngredient`（`:25`）
- CODEC（`:27`）：`FoodTrait.CODEC.fieldOf("trait").xmap(HasTraitIngredient::new, HasTraitIngredient::trait)`

| 字段名 | 类型 | 必需性 | 默认值 | 语义 |
|---|---|---|---|---|
| `trait` | `Holder<FoodTrait>`（FoodTrait 注册表 id 或其 tag 形式） | **必需**（`fieldOf`） | 无 | 要求物品带有该食物 trait |

- 判定：`FoodCapability.hasTrait(stack, trait)`（`:35`）
- 显示改写：`FoodCapability.applyTrait(stack, trait)`（`:40`）

真实用例：2 个文件。示例 —— `data/tfc/recipe/barrel/pickled.json`（节选，原文单行）：

```json
{"input_item":{"type":"tfc:and","children":[[{"tag":"c:foods/fruit"},{"tag":"c:foods/vegetable"},{"tag":"c:foods/meat"},{"tag":"c:foods/fish"}],{"type":"tfc:not_rotten"},{"type":"tfc:has_trait","trait":"tfc:brined"},{"type":"tfc:lacks_trait","trait":"tfc:pickled"}],"count":1}}
```

#### （4）`tfc:lacks_trait` —— `LacksTraitIngredient`

- 源码：`net\dries007\tfc\common\recipes\ingredients\LacksTraitIngredient.java`
- 形态：`public record LacksTraitIngredient(Holder<FoodTrait> trait)`（`:25`）
- CODEC（`:27`）：`FoodTrait.CODEC.fieldOf("trait")`

| 字段名 | 类型 | 必需性 | 默认值 | 语义 |
|---|---|---|---|---|
| `trait` | `Holder<FoodTrait>` | **必需** | 无 | 要求物品**不带**该食物 trait |

- 判定：`!FoodCapability.hasTrait(stack, trait)`（`:35`）
- **无 `modifyStackForDisplay` 覆盖**（未实现 `PreciseIngredient` 的该方法），因此显示走默认（原样返回）。

真实用例：113 个文件。示例 —— `data/tfc/recipe/pot/jam_strawberry_canning_1.json`（节选）：

```json
{"ingredients":[{"type":"tfc:and","children":[{"item":"tfc:jar/strawberry"},{"type":"tfc:lacks_trait","trait":"tfc:canned"},{"type":"tfc:not_rotten"}]}]}
```

#### （5）`tfc:heat` —— `HeatIngredient`

- 源码：`net\dries007\tfc\common\recipes\ingredients\HeatIngredient.java`
- 形态：`public record HeatIngredient(float min, float max) implements PreciseIngredient`（`:40`）
- CODEC（`:44`）：

```java
RecordCodecBuilder.mapCodec(i -> i.group(
    Codecs.POSITIVE_FLOAT.optionalFieldOf("min", Float.NEGATIVE_INFINITY),
    Codecs.POSITIVE_FLOAT.optionalFieldOf("max", Float.POSITIVE_INFINITY)
).apply(i, HeatIngredient::new))
 .flatXmap(c -> (c.min == NEGATIVE_INFINITY && c.max == POSITIVE_INFINITY)
     ? DataResult.error(() -> "Must have one of min or max")
     : DataResult.success(c), DataResult::success);
```

| 字段名 | 类型 | 必需性 | 默认值 | 语义 |
|---|---|---|---|---|
| `min` | float（`Codecs.POSITIVE_FLOAT`） | 可选 | `-Infinity` | 允许的最低温度（含） |
| `max` | float（`Codecs.POSITIVE_FLOAT`） | 可选 | `+Infinity` | 允许的最高温度（含） |

**校验约束（来自 `flatXmap`，非猜测）**：`min` 与 `max` **不能同时**取默认值（即二者至少显式给出一个），否则解码报错 `"Must have one of min or max"`。

- 判定：`temperature = HeatCapability.getTemperature(stack); return temperature >= min && temperature <= max;`（`:51-54`）
- 显示改写：设静态温度并追加 tooltip（`:57-61`）

真实用例：4 个文件。示例 —— `data/tfc/recipe/barrel/water_cooling.json`：

```json
{"type":"tfc:barrel_instant","input_fluid":{"amount":1,"fluid":"minecraft:water"},"input_item":{"type":"tfc:heat","count":1,"min":1.0},"output_item":{"modifiers":[{"type":"tfc:copy_input"},{"type":"tfc:add_heat","temperature":-40.0}]},"sound":"minecraft:block.fire.extinguish"}
```

注意：真实用例中 `input_item` 内同时出现了 `count` 字段，而 `HeatIngredient` 的 CODEC 只有 `min`/`max`。原因是 TFC 的 `input_item` 字段解码为 `SizedIngredient`（`count` 属于 `SizedIngredient` 的外层包装，`type` + `min` 属于内层 ingredient）。也就是说 `{"type":"tfc:heat","count":1,"min":1.0}` 里 `count` 由 `SizedIngredient` 消费，`type`/`min` 由 `HeatIngredient` 消费。

#### （6）`tfc:fluid_content` —— `FluidContentIngredient`

- 源码：`net\dries007\tfc\common\recipes\ingredients\FluidContentIngredient.java`
- 形态：`public record FluidContentIngredient(SizedFluidIngredient fluid) implements ICustomIngredient`（`:44`）——注意实现的是 `ICustomIngredient`（非 `PreciseIngredient`）
- CODEC（`:46`）：`SizedFluidIngredient.FLAT_CODEC.fieldOf("fluid").xmap(...)`

| 字段名 | 类型 | 必需性 | 默认值 | 语义 |
|---|---|---|---|---|
| `fluid` | `SizedFluidIngredient`（`FLAT_CODEC`） | **必需** | 无 | 物品内含流体必须匹配（含流体种类与数量） |

`FLAT_CODEC` 展开后即 `{"fluid":"<流体 id>","amount":<整数>}`（也可为 `{"tag":"..."}` 形式，取决于 NeoForge 的 `SizedFluidIngredient` 实现；TFC 真实用例只出现 `fluid`+`amount` 形式，见下例）。

- 判定：`this.fluid.test(FluidHelpers.getContainedFluid(stack))`（`:53-54`）
- `getItems()`（`:57-70`）：遍历 `TFCTags.Items.FLUID_ITEM_INGREDIENT_EMPTY_CONTAINERS`（`tfc:fluid_item_ingredient_empty_containers`）中的容器物品，逐个填充该流体后返回装填结果——这也是该 tag 存在的原因
- `isSimple()` 返回 `false`（`:72-74`）

真实用例：186 个文件。示例 —— `data/tfc/recipe/crafting/clay_ball_small.json`：

```json
{"type":"minecraft:crafting_shapeless","category":"misc","ingredients":[{"item":"tfc:hardened_clay"},{"type":"tfc:fluid_content","fluid":{"amount":100,"fluid":"minecraft:water"}}],"result":{"count":4,"id":"minecraft:clay_ball"}}
```

#### （7）`tfc:and` —— `AndIngredient`

- 源码：`net\dries007\tfc\common\recipes\ingredients\AndIngredient.java`
- 形态：`public record AndIngredient(List<Ingredient> children) implements ICustomIngredient`（`:30`）
- CODEC（`:32`）：`Ingredient.CODEC.listOf().xmap(AndIngredient::new, AndIngredient::children).fieldOf("children")`

| 字段名 | 类型 | 必需性 | 默认值 | 语义 |
|---|---|---|---|---|
| `children` | `List<Ingredient>`（vanilla `Ingredient.CODEC` 列表，`listOf()` 无默认值） | **必需** | 无 | 所有子 ingredient 必须**同时**满足（AND） |

- 判定：遍历 `children`，任一 `test(stack)` 为 false 即返回 false（`:39-45`）
- `getItems()`（`:47-57`）：以**第一个** child 的物品列表为基准，再对每个 child 中实现 `PreciseIngredient` 的子项调用 `modifyStackForDisplay` 改写显示（用于 JEI/REI 展示"腐烂/温度/带 trait"的形态）
- `isSimple()` 返回 `false`（`:59-61`）

**重要结构约定**：`children` 的元素既可以是 vanilla ingredient（`{"item":"..."}` / `{"tag":"..."}`），也可以是自定义 ingredient（`{"type":"tfc:not_rotten"}`），也可以是**数组**（多选一）。实测真实用例 `data/tfc/recipe/barrel/brined.json` 中，`children` 的第一个元素就是一个数组：

```json
"children":[[{"tag":"c:foods/fruit"},{"tag":"c:foods/vegetable"},{"tag":"c:foods/meat"},{"tag":"c:foods/fish"}],{"type":"tfc:not_rotten"},{"type":"tfc:lacks_trait","trait":"tfc:brined"}]
```

该数组形式对应 vanilla `Ingredient.CODEC` 的"多选一"编码，即 `children` 内允许嵌套 OR 列表。

**与 `SizedIngredient` 的组合**：`input_item` 等字段使用 NeoForge `SizedIngredient`，因此 ingredient 可直接带 `count`。实测 —— `data/tfc/recipe/barrel/beer.json`：

```json
{"input_item":{"type":"tfc:and","children":[{"item":"tfc:food/barley_flour"},{"type":"tfc:not_rotten"}],"count":1}}
```

（`count` 与 `type` 同级，由外层 `SizedIngredient` 解释。）

### T-2.3 非注册的同类目录文件（干扰项澄清）

`net\dries007\tfc\common\recipes\ingredients\` 目录下另有 3 个类**不是**注册的 ingredient type：

| 类 | 形态 | 是否可注册 | 说明 |
|---|---|---|---|
| `net.dries007.tfc.common.recipes.ingredients.BlockIngredient` | `public record BlockIngredient(Either<ImmutableSet<Block>, TagKey<Block>> either) implements Predicate<Block>`（`BlockIngredient.java:43`） | **否** | CODEC（`:45`）= `Codec.either(Codecs.BLOCK.listOf().xmap(ImmutableSet::copyOf, List::copyOf), TagKey.hashedCodec(Registries.BLOCK))`，即接受 `"#<block tag>"` 字符串或 `["<block id>", ...]` 数组两种写法。真实使用点：advancement 的 `tfc:chiseled` / `tfc:lit` / `tfc:rock_anvil` / `tfc:firepit_created` 触发器的 `conditions.ingredient`（见 T-4.3、T-4.4 样例） |
| `net.dries007.tfc.common.recipes.ingredients.KeyedIngredient` | `public interface KeyedIngredient extends Predicate<ItemStack>`（`KeyedIngredient.java:28`） | **否** | 纯 Java 侧接口（提供 `keys()` 用于索引/反查），非 JSON 类型，未注册、也未出现在任何 JSON 中 |
| `net.dries007.tfc.common.recipes.ingredients.PreciseIngredient` | `public interface PreciseIngredient extends ICustomIngredient`（`PreciseIngredient.java:18-19`） | **否** | 提供默认实现：`getItems()`（遍历 `BuiltInRegistries.ITEM` 全量物品并 `filter` + `modifyStackForDisplay`，`:20-22`）、`isSimple() -> false`（`:24-26`）、`modifyStackForDisplay`（默认原样返回，`:28-30`）。被 T-2.2 中前 5 个 ingredient 类实现，只是共享基接口 |

`PreciseIngredient` 的存在解释了为什么这些 ingredient 的 `getItems()` 会扫描全物品表：它们没有固定物品列表，只能按条件全量筛选后改写显示。

### T-2.4 用例统计与任务猜测清单核实

对 `data/tfc/` 下 14162 个 JSON 文件做 `"type":"<id>"` 全文匹配的统计结果：

| type id | 命中文件数 | 首个真实用例路径 |
|---|---|---|
| `tfc:not_rotten` | 560 | `recipe/quern/food/wheat_flour.json` |
| `tfc:and` | 560 | 同上 |
| `tfc:fluid_content` | 186 | `recipe/crafting/clay_ball_small.json` |
| `tfc:lacks_trait` | 113 | `recipe/pot/jam_strawberry_canning_1.json` |
| `tfc:heat` | 4 | `recipe/barrel/water_cooling.json` |
| `tfc:has_trait` | 2 | `recipe/barrel/pickled.json` |
| `tfc:rotten` | **0（jar 内无真实用例）** | — |

（`tfc:and` 与 `tfc:not_rotten` 计数相同是因为几乎每个 `tfc:and` 都包裹了 `tfc:not_rotten`；两者计数一致属预期。）

**任务猜测清单的逐条核实**：

| 任务猜测的 type | 结论 |
|---|---|
| `tfc:damaged` | **不存在**。源码中无该类、无该 id（grep 全源码 `damaged` 无 ingredient 相关命中） |
| `tfc:not_rotten` | **存在**（T-2.2 第 2 项） |
| `tfc:has_trait` | **存在**（第 3 项） |
| `tfc:lacks_trait` | **存在**（第 4 项） |
| `tfc:heat` | **存在**（第 5 项） |
| `tfc:fluid` | **不存在**。实际存在的是 `tfc:fluid_content`（第 6 项，字段为 `fluid`） |
| `tfc:has_damage` | **不存在** |
| `tfc:not_damaged` | **不存在** |
| `tfc:any_damage` | **不存在** |
| （猜测清单未提，实际存在） | `tfc:rotten`、`tfc:and` |

「损坏（damage）」维度**没有**做成 recipe ingredient：TFC 的损坏用物品组件 + `minecraft:damage` 表达，`TFCIngredients` 中无相关 type（已通读该文件全部 58 行确认）。

---

## [T-3] 自定义 loot condition / function

### T-3.1 注册表位置

任务描述猜测的 `net\dries007\tfc\common\loot\` **不存在**。真实位置是：

- 包目录：`moddev\src-ref\TFC-decompiled\net\dries007\tfc\util\loot\`（14 个文件）
- 注册类：`net\dries007\tfc\util\loot\TFCLoot.java`

`TFCLoot.java:48-50` 注册三个注册表，命名空间均为 `tfc`：

```java
public static final DeferredRegister<LootItemConditionType> CONDITIONS =
    DeferredRegister.create(Registries.LOOT_CONDITION_TYPE, "tfc");
public static final DeferredRegister<LootNumberProviderType> NUMBER_PROVIDERS =
    DeferredRegister.create(Registries.LOOT_NUMBER_PROVIDER_TYPE, "tfc");
public static final DeferredRegister<LootItemFunctionType<?>> LOOT_FUNCTIONS =
    DeferredRegister.create(Registries.LOOT_FUNCTION_TYPE, "tfc");
```

自定义 loot 上下文参数（`TFCLoot.java:51-53`，**代码侧，不是 JSON 字段**）：

```java
public static final LootContextParam<Boolean> ISOLATED  = new LootContextParam<>(Helpers.identifier("isolated"));
public static final LootContextParam<Boolean> BURNT_OUT = new LootContextParam<>(Helpers.identifier("burnt_out"));
public static final LootContextParam<Boolean> SLUICE   = new LootContextParam<>(Helpers.identifier("sluice"));
```

即三个 param id：`tfc:isolated`、`tfc:burnt_out`、`tfc:sluice`。

### T-3.2 自定义 loot condition（6 个）

`TFCLoot.java:54-59` 注册，全部为 `MapCodec.unit(INSTANCE)`，即**JSON 中不含任何额外字段**。

| JSON `condition` id | 类全名 | 源码路径 | 字段 | 判定逻辑（源码依据） |
|---|---|---|---|---|
| `tfc:is_isolated` | `net.dries007.tfc.util.loot.IsIsolatedCondition` | `util/loot/IsIsolatedCondition.java` | 无 | `context.hasParam(TFCLoot.ISOLATED)`（`:28-30`） |
| `tfc:is_burnt_out` | `net.dries007.tfc.util.loot.IsBurntOutCondition` | `util/loot/IsBurntOutCondition.java` | 无 | `context.hasParam(TFCLoot.BURNT_OUT)`（`:28-30`） |
| `tfc:is_sluice` | `net.dries007.tfc.util.loot.IsSluiceCondition` | `util/loot/IsSluiceCondition.java` | 无 | `context.hasParam(TFCLoot.SLUICE)`（`:28-30`） |
| `tfc:is_male` | `net.dries007.tfc.util.loot.IsMaleCondition` | `util/loot/IsMaleCondition.java` | 无 | 需 `LootContextParams.THIS_ENTITY`，实体实现 `TFCAnimalProperties` 且 `isMale()`（`:31-35`） |
| `tfc:always_true` | `net.dries007.tfc.util.loot.AlwaysTrueCondition` | `util/loot/AlwaysTrueCondition.java` | 无 | `return true;`（`:28-30`） |
| `tfc:not_predated` | `net.dries007.tfc.util.loot.NotPredatedCondition` | `util/loot/NotPredatedCondition.java` | 无 | 无攻击者 → true；攻击者是玩家 → true；否则攻击者若属于 `TFCTags.Entities.LAND_PREDATORS` 或 `OCEAN_PREDATORS` → false（`:43-49`）。`getReferencedContextParams()` 声明依赖 `LootContextParams.ATTACKING_ENTITY`（`:39-41`） |

**字段表（6 个 condition 通用）**：

| 字段名 | 类型 | 必需性 | 默认值 | 语义 |
|---|---|---|---|---|
| （无自定义字段） | — | — | — | 写法即 `{"condition":"tfc:<id>"}`；可选地配合 vanilla 的 `"term"`（仅在 `minecraft:inverted` 等包装器中出现） |

真实 JSON 用例（均有实测）：

- `tfc:is_isolated` —— 42 个文件。`data/tfc/loot_table/blocks/rock/hardened/andesite.json`：

```json
{"type":"minecraft:block","pools":[{"name":"loot_pool","rolls":1,"entries":[{"type":"minecraft:alternatives","children":[{"type":"minecraft:item","name":"tfc:rock/raw/andesite","conditions":[{"condition":"tfc:is_isolated"}]},{"type":"minecraft:item","name":"tfc:rock/loose/andesite","functions":[{"function":"minecraft:set_count","count":{"min":1,"max":4,"type":"minecraft:uniform"}}]}]}],"conditions":[{"condition":"minecraft:survives_explosion"}]}]}
```

- `tfc:is_burnt_out` —— 1 个文件。`data/tfc/loot_table/blocks/torch.json`（同时演示与 `minecraft:inverted` 的组合用法）：

```json
{"type":"minecraft:block","pools":[{"name":"loot_pool","rolls":1,"entries":[{"type":"minecraft:alternatives","children":[{"type":"minecraft:item","name":"minecraft:stick","conditions":[{"condition":"tfc:is_burnt_out"},{"condition":"minecraft:random_chance","chance":0.25}]},{"type":"minecraft:item","name":"tfc:powder/wood_ash","conditions":[{"condition":"tfc:is_burnt_out"},{"condition":"minecraft:random_chance","chance":0.25}]},{"type":"minecraft:item","name":"tfc:torch","conditions":[{"condition":"minecraft:inverted","term":{"condition":"tfc:is_burnt_out"}}]}]}],"conditions":[{"condition":"minecraft:survives_explosion"}]}]}
```

- `tfc:is_sluice` —— 84 个文件。`data/tfc/loot_table/deposit/cassiterite_andesite.json`：

```json
{"type":"minecraft:empty","pools":[{"name":"loot_pool","rolls":1,"entries":[{"type":"minecraft:alternatives","children":[{"type":"minecraft:item","name":"tfc:ore/small_cassiterite","conditions":[{"condition":"minecraft:random_chance","chance":0.5}]},{"type":"minecraft:item","name":"tfc:ore/small_cassiterite","conditions":[{"condition":"minecraft:random_chance","chance":0.1},{"condition":"tfc:is_sluice"}]},{"type":"minecraft:item","name":"tfc:rock/loose/andesite","conditions":[{"condition":"minecraft:random_chance","chance":0.5}]},{"type":"minecraft:item","name":"tfc:groundcover/pumice","conditions":[{"condition":"minecraft:random_chance","chance":0.25}]},{"type":"minecraft:item","name":"tfc:ore/pyrite","conditions":[{"condition":"minecraft:random_chance","chance":0.0533}]}]}]}]}
```

- `tfc:is_male` —— 1 个文件。`data/tfc/loot_table/entities/goat.json`（见下方 `tfc:animal_yield` 样例，同一个文件内同时含 `tfc:is_male` 与 `tfc:not_predated`）
- `tfc:not_predated` —— 29 个文件。首个：`data/tfc/loot_table/entities/alpaca.json`
- `tfc:always_true` —— **jar 内无真实用例**（0 个文件）。它由代码使用：`AlwaysTrueCondition.alwaysTrue()`（`AlwaysTrueCondition.java:32-35`）返回的 builder 在 Java 侧构造 loot table 时使用。

### T-3.3 自定义 loot number provider（2 个）

`TFCLoot.java:60-61` 注册，均通过 `MinMaxProvider.codec(...)` 生成 CODEC。

| JSON `type` id | 类全名 | 源码路径 |
|---|---|---|
| `tfc:crop_yield_uniform` | `net.dries007.tfc.util.loot.CropYieldProvider` | `util/loot/CropYieldProvider.java` |
| `tfc:animal_yield` | `net.dries007.tfc.util.loot.AnimalYieldProvider` | `util/loot/AnimalYieldProvider.java` |

两者共同父类：`net.dries007.tfc.util.loot.MinMaxProvider`（`util/loot/MinMaxProvider.java`），CODEC 由父类静态工厂生成（`MinMaxProvider.java:27-29`）：

```java
RecordCodecBuilder.mapCodec(i -> i.group(
    NumberProviders.CODEC.fieldOf("min"),
    NumberProviders.CODEC.fieldOf("max")
).apply(i, factory));
```

**字段表（2 个 provider 通用）**：

| 字段名 | 类型 | 必需性 | 默认值 | 语义 |
|---|---|---|---|---|
| `min` | `NumberProvider`（vanilla `NumberProviders.CODEC`，可为常数或 `{"type":"minecraft:uniform",...}` 等） | **必需**（`fieldOf`） | 无 | 下限值 |
| `max` | `NumberProvider` | **必需**（`fieldOf`） | 无 | 上限值 |

- `CropYieldProvider.getFloat`（`CropYieldProvider.java:30-37`）：取 `LootContextParams.BLOCK_ENTITY`，若为 `CropBlockEntity`，按 `Mth.lerp(crop.getYield(), min, max)` 插值；否则返回 `min.getFloat(context)`。
- `AnimalYieldProvider.getFloat`（`AnimalYieldProvider.java:34-51`）：取 `LootContextParams.THIS_ENTITY` 与 `LootContextParams.LAST_DAMAGE_PLAYER`，按遗传体型 + 玩家攻击力（`Attributes.ATTACK_DAMAGE` 映射到 `1..8`）+ 熟悉度（`familiarity` 映射到 `1..8`）计算 adjustedSize，再 `Mth.clampedMap(1..46 → 0..1)` 后 `Mth.lerp` 插值；非 `TFCAnimalProperties` 时返回 `min`。

真实 JSON 用例：

- `tfc:animal_yield` —— 15 个文件。`data/tfc/loot_table/entities/goat.json`（原文单行，此处格式化以便阅读）：

```json
{"type":"minecraft:entity","pools":[{"bonus_rolls":0.0,"entries":[{"type":"minecraft:item","functions":[{"add":false,"count":{"type":"tfc:animal_yield","max":{"type":"minecraft:uniform","max":13.0,"min":7.0},"min":4.0},"function":"minecraft:set_count"}],"name":"tfc:food/chevon"}],"rolls":1.0},{"bonus_rolls":0.0,"conditions":[{"condition":"tfc:not_predated"}],"entries":[{"type":"minecraft:item","name":"tfc:medium_raw_hide"}],"rolls":1.0},{"bonus_rolls":0.0,"conditions":[{"condition":"tfc:not_predated"}],"entries":[{"type":"minecraft:item","functions":[{"add":false,"count":{"type":"minecraft:uniform","max":4.0,"min":1.0},"function":"minecraft:set_count"}],"name":"minecraft:bone"}],"rolls":1.0},{"bonus_rolls":0.0,"conditions":[{"condition":"tfc:is_male"}],"entries":[{"type":"minecraft:item","name":"tfc:goat_horn"}],"rolls":1.0}],"random_sequence":"tfc:entities/goat"}
```

注意 `count` 内 `min` 是常数 `4.0`，`max` 是嵌套的 vanilla uniform provider；同时该文件演示了 `tfc:not_predated` 与 `tfc:is_male` 放在 pool 级 `conditions` 的写法。

- `tfc:crop_yield_uniform` —— 27 个文件。`data/tfc/loot_table/blocks/crop/alfalfa.json`：

```json
{"type":"minecraft:block","pools":[{"name":"loot_pool","rolls":1,"entries":[{"type":"minecraft:item","name":"tfc:alfalfa","conditions":[{"condition":"minecraft:block_state_property","block":"tfc:crop/alfalfa","properties":{"age":"5"}}],"functions":[{"function":"minecraft:set_count","count":{"type":"tfc:crop_yield_uniform","min":0,"max":{"type":"minecraft:uniform","min":6,"max":10}}}]}],"conditions":[{"condition":"minecraft:survives_explosion"}]},{"name":"loot_pool","rolls":1,"entries":[{"type":"minecraft:item","name":"tfc:seeds/alfalfa"}],"conditions":[{"condition":"minecraft:survives_explosion"}]}]}
```

### T-3.4 自定义 loot function（3 个）

`TFCLoot.java:62-64` 注册。三者都继承 vanilla `LootItemConditionalFunction`，CODEC 均由 `commonFields(...)` 构造（`ROTTEN` 见 `RottenFunction.java:31`，`COPY_FLUID` 见 `CopyFluidFunction.java:44`，`APPLY_STACK_SIZE` 见 `ApplyStackSizeFunction.java:31`）。

| JSON `function` id | 类全名 | 源码路径 | 自定义字段 | 行为 |
|---|---|---|---|---|
| `tfc:copy_fluid` | `net.dries007.tfc.util.loot.CopyFluidFunction` | `util/loot/CopyFluidFunction.java` | 无 | 若上下文含 `LootContextParams.BLOCK_ENTITY`，把方块实体的流体转入掉落物（`copyToItem`，`:46-56`、`:76-81`） |
| `tfc:rotten` | `net.dries007.tfc.util.loot.RottenFunction` | `util/loot/RottenFunction.java` | 无 | `FoodCapability.setRotten(stack)`（`:41-43`） |
| `tfc:apply_stack_size` | `net.dries007.tfc.util.loot.ApplyStackSizeFunction` | `util/loot/ApplyStackSizeFunction.java` | 无 | `ItemSizeManager.get(stack).modifyWeight(stack)`，把物品尺寸换算成实际堆叠数量上限（`:41-44`） |

**字段表**：

| 字段名 | 类型 | 必需性 | 默认值 | 语义 |
|---|---|---|---|---|
| `conditions` | `List<LootItemCondition>` | 可选 | 空列表 | 由 vanilla `LootItemConditionalFunction.commonFields` 提供的通用字段（继承自父类，非 TFC 自定义）。已读的 3 个 TFC 用例中，function 对象内只含 `function` 字段，未出现 `conditions` |

（`conditions` 字段名来自 vanilla `LootItemConditionalFunction` 的 `commonFields`；TFC 反编译源码中该字段由继承获得，非 TFC 显式声明。）

真实 JSON 用例（依次为三个 function；`tfc:copy_fluid` 9 个文件 → `data/tfc/loot_table/blocks/metal/lamp/bismuth_bronze.json`；`tfc:rotten` 2 个文件 → `data/tfc/loot_table/blocks/rotten_melon.json`，另一文件为 `data/tfc/loot_table/blocks/rotten_pumpkin.json`；`tfc:apply_stack_size` 39 个文件 → `data/tfc/loot_table/blocks/crucible.json`，后者同时演示与 vanilla function `minecraft:copy_components` 串联）：

```json
{"type":"minecraft:block","pools":[{"name":"loot_pool","rolls":1,"entries":[{"type":"minecraft:item","name":"tfc:metal/lamp/bismuth_bronze","functions":[{"function":"tfc:copy_fluid"}]}],"conditions":[{"condition":"minecraft:survives_explosion"}]}]}
{"type":"minecraft:block","pools":[{"name":"loot_pool","rolls":1,"entries":[{"type":"minecraft:item","name":"tfc:melon","functions":[{"function":"tfc:rotten"}]}],"conditions":[{"condition":"minecraft:survives_explosion"}]}]}
{"type":"minecraft:block","pools":[{"name":"loot_pool","rolls":1,"entries":[{"type":"minecraft:item","name":"tfc:crucible","functions":[{"function":"minecraft:copy_components","source":"block_entity","include":["minecraft:custom_name","tfc:crucible"]},{"function":"tfc:apply_stack_size"}]}],"conditions":[{"condition":"minecraft:survives_explosion"}]}]}
```

### T-3.5 TFC 是否给原版 loot function 提供自定义参数？

**结论：TFC 没有改写原版 loot function 本身，而是通过注册新的 `NumberProvider` 类型，把自定义参数注入原版 `minecraft:set_count` 的 `count` 字段。**

证据：

1. `tfc:animal_yield` 与 `tfc:crop_yield_uniform` 注册在 `Registries.LOOT_NUMBER_PROVIDER_TYPE`（`TFCLoot.java:49`），并被原版 function `minecraft:set_count` 的 `count` 字段引用（`loot_table/entities/goat.json`、`loot_table/blocks/crop/alfalfa.json`，见 T-3.3 样例）。原版 `SetItemCountFunction` 的 `count` 字段类型就是 `NumberProvider`，因此自定义 provider 可以合法嵌入，无需修改原版代码。
2. 已确认 TFC **没有** 任何 loot 相关的 Mixin：mixin 目录仅有 `net\dries007\tfc\mixin`（此目录存在），按 `-Filter '*.java'` 且文件名含 `Mixin` 且内容含 `Loot` 检索，命中 0 个文件；直接 grep `LootItem|LootContext|LootTable|loot`（限定 `*Mixin*.java`）同样 0 命中。
3. 除 `NumberProviders` 之外，TFC 未注册任何其它原版 loot 子注册表类型（`TFCLoot.java` 全文 86 行只含 3 个 `DeferredRegister`）。

### T-3.6 自定义 loot condition / function 汇总表（含用例统计）

条件统计口径：遍历 `data/tfc/` 下全部 14162 个 JSON 文件做全文匹配。

| 类别 | JSON id | 类 | 真实用例数 | 首个用例路径 |
|---|---|---|---|---|
| condition | `tfc:is_isolated` | `IsIsolatedCondition` | 42 | `loot_table/blocks/rock/hardened/andesite.json` |
| condition | `tfc:is_burnt_out` | `IsBurntOutCondition` | 1 | `loot_table/blocks/torch.json` |
| condition | `tfc:is_sluice` | `IsSluiceCondition` | 84 | `loot_table/deposit/cassiterite_andesite.json` |
| condition | `tfc:is_male` | `IsMaleCondition` | 1 | `loot_table/entities/goat.json` |
| condition | `tfc:always_true` | `AlwaysTrueCondition` | **0（jar 内无真实用例，仅代码侧使用）** | — |
| condition | `tfc:not_predated` | `NotPredatedCondition` | 29 | `loot_table/entities/alpaca.json` |
| number provider | `tfc:crop_yield_uniform` | `CropYieldProvider` | 27 | `loot_table/blocks/crop/alfalfa.json` |
| number provider | `tfc:animal_yield` | `AnimalYieldProvider` | 15 | `loot_table/entities/alpaca.json` |
| function | `tfc:copy_fluid` | `CopyFluidFunction` | 9 | `loot_table/blocks/metal/lamp/bismuth_bronze.json` |
| function | `tfc:rotten` | `RottenFunction` | 2 | `loot_table/blocks/rotten_melon.json` |
| function | `tfc:apply_stack_size` | `ApplyStackSizeFunction` | 39 | `loot_table/blocks/crucible.json` |

**合计：6 condition + 2 number provider + 3 function = 11 个自定义 loot 类型。**

（对照：`data/tfc/loot_table/` 下共 4569 个 JSON 文件。）

---

## [T-4] 自定义 advancement trigger

### T-4.1 注册类与注册表

任务描述猜测的 `net\dries007\tfc\common\advancements\` **不存在**。真实位置是：

- 包目录：`moddev\src-ref\TFC-decompiled\net\dries007\tfc\util\advancements\`（4 个文件：`TFCAdvancements.java`、`GenericTrigger.java`、`BlockActionTrigger.java`、`EntityActionTrigger.java`，另有 `package-info.java`）
- 注册类：`net\dries007\tfc\util\advancements\TFCAdvancements.java`

`TFCAdvancements.java:30`：

```java
public static final DeferredRegister<CriterionTrigger<?>> TRIGGERS =
    DeferredRegister.create(Registries.TRIGGER_TYPE, "tfc");
```

### T-4.2 全部 18 个自定义 trigger

`TFCAdvancements.java:31-48` 注册，分三类工厂方法（`:50-60`）：

**（A）`registerGeneric` —— `GenericTrigger`（11 个，`TFCAdvancements.java:31-41`）**

| JSON `trigger` id | 类全名 | 源码路径 |
|---|---|---|
| `tfc:full_powderkeg` | `net.dries007.tfc.util.advancements.GenericTrigger` | `util/advancements/GenericTrigger.java` |
| `tfc:full_fertilizer` | 同上 | 同上 |
| `tfc:lava_lamp` | 同上 | 同上 |
| `tfc:rotten_compost_kill` | 同上 | 同上 |
| `tfc:present_day` | 同上 | 同上 |
| `tfc:eat_rotten_food` | 同上 | 同上 |
| `tfc:perfectly_forged` | 同上 | 同上 |
| `tfc:full_nutrition` | 同上 | 同上 |
| `tfc:max_windmill` | 同上 | 同上 |
| `tfc:basin_pour` | 同上 | 同上 |
| `tfc:table_pour` | 同上 | 同上 |

**（B）`registerBlock` —— `BlockActionTrigger`（4 个，`TFCAdvancements.java:42-45`）**

| JSON `trigger` id | 类全名 | 源码路径 |
|---|---|---|
| `tfc:chiseled` | `net.dries007.tfc.util.advancements.BlockActionTrigger` | `util/advancements/BlockActionTrigger.java` |
| `tfc:lit` | 同上 | 同上 |
| `tfc:rock_anvil` | 同上 | 同上 |
| `tfc:firepit_created` | 同上 | 同上 |

**（C）`registerEntity` —— `EntityActionTrigger`（3 个，`TFCAdvancements.java:46-48`）**

| JSON `trigger` id | 类全名 | 源码路径 |
|---|---|---|
| `tfc:hooked_entity` | `net.dries007.tfc.util.advancements.EntityActionTrigger` | `util/advancements/EntityActionTrigger.java` |
| `tfc:fed_animal` | 同上 | 同上 |
| `tfc:stab_entity` | 同上 | 同上 |

**合计 18 个自定义 advancement trigger。**

### T-4.3 各 trigger 的 conditions 字段

#### `GenericTrigger`（11 个 trigger 共用）

CODEC（`GenericTrigger.java:23`）：

```java
public static final Codec<TriggerInstance> CODEC =
    EntityPredicate.ADVANCEMENT_CODEC.optionalFieldOf("player")
        .xmap(TriggerInstance::new, TriggerInstance::player).codec();
```

| 字段名 | 类型 | 必需性 | 默认值 | 语义 |
|---|---|---|---|---|
| `player` | `ContextAwarePredicate`（vanilla `EntityPredicate.ADVANCEMENT_CODEC`） | 可选（`optionalFieldOf`） | 空 `Optional` | 玩家谓词；留空即任意玩家触发 |

触发方法 `trigger(ServerPlayer player)`（`:29-31`）不附带额外数据，谓词恒为 `true`（`:30`）——即**这 11 个 trigger 没有可用条件字段**，`conditions` 里最多只能写 `player`。

#### `BlockActionTrigger`（4 个 trigger 共用）

CODEC（`BlockActionTrigger.java:32`）：

```java
RecordCodecBuilder.create(i -> i.group(
    EntityPredicate.ADVANCEMENT_CODEC.optionalFieldOf("player"),
    BlockIngredient.CODEC.fieldOf("ingredient")
).apply(i, TriggerInstance::new));
```

| 字段名 | 类型 | 必需性 | 默认值 | 语义 |
|---|---|---|---|---|
| `player` | `ContextAwarePredicate` | 可选 | 空 `Optional` | 玩家谓词 |
| `ingredient` | `BlockIngredient`（见 T-2.3） | **必需**（`fieldOf`） | 无 | 方块匹配；可为 `"#<block tag>"` 字符串或 `["<block id>", ...]` 数组 |

触发判定：`this.trigger(player, instance -> instance.ingredient.test(state))`（`:38-40`），即传入触发的 `BlockState` 交给 `ingredient` 过滤。

#### `EntityActionTrigger`（3 个 trigger 共用）

CODEC（`EntityActionTrigger.java:31`）：

```java
RecordCodecBuilder.create(i -> i.group(
    EntityPredicate.ADVANCEMENT_CODEC.optionalFieldOf("player"),
    EntityPredicate.CODEC.fieldOf("entity")
).apply(i, TriggerInstance::new));
```

| 字段名 | 类型 | 必需性 | 默认值 | 语义 |
|---|---|---|---|---|
| `player` | `ContextAwarePredicate` | 可选 | 空 `Optional` | 玩家谓词 |
| `entity` | `EntityPredicate`（vanilla `EntityPredicate.CODEC`） | **必需**（`fieldOf`） | 无 | 实体谓词，按 vanilla 写法（`type`、`distance`、`nbt` 等） |

触发判定：`this.trigger(player, instance -> instance.entity.matches(serverPlayer, entity))`（`:37-39`）。

### T-4.4 真实 advancement JSON 样例与用例统计

**TFC 通过 JSON 提供了 advancement 数据**：`data/tfc/advancement/` 下共 115 个文件，分 `story/`（68 个）与 `world/`（47 个）两个子目录。18 个自定义 trigger **全部**有真实 JSON 用例。

**用例统计**（遍历 115 个 advancement 文件，匹配 `"trigger":"tfc:<id>"`）：

| `trigger` id | 用例数 | 用例路径 |
|---|---|---|
| `tfc:full_powderkeg` | 1 | `advancement/world/full_powderkeg.json` |
| `tfc:full_fertilizer` | 1 | `advancement/world/full_fertilizer.json` |
| `tfc:lava_lamp` | 1 | `advancement/world/lava_lamp.json` |
| `tfc:rotten_compost_kill` | 1 | `advancement/world/rotten_compost.json` |
| `tfc:present_day` | 1 | `advancement/story/the_future.json` |
| `tfc:eat_rotten_food` | 1 | `advancement/world/eat_rotten_food.json` |
| `tfc:perfectly_forged` | 1 | `advancement/story/perfectly_forged.json` |
| `tfc:full_nutrition` | 1 | `advancement/world/full_nutrition.json` |
| `tfc:max_windmill` | 1 | `advancement/story/windmill.json` |
| `tfc:basin_pour` | 1 | `advancement/story/basin_pour.json` |
| `tfc:table_pour` | 1 | `advancement/story/table_pour.json` |
| `tfc:chiseled` | 1 | `advancement/story/smooth_stone.json` |
| `tfc:lit` | 3 | `advancement/story/forge.json`（另 2 处） |
| `tfc:rock_anvil` | 1 | `advancement/story/stone_anvil.json` |
| `tfc:firepit_created` | 3 | `advancement/story/firepit.json`（另 2 处） |
| `tfc:hooked_entity` | 2 | `advancement/world/advanced_fishing.json`（另 1 处） |
| `tfc:fed_animal` | 1 | `advancement/world/familiarity.json` |
| `tfc:stab_entity` | 1 | `advancement/world/greatest_hunter.json` |

**样例 1：`GenericTrigger`，无 conditions** —— `data/tfc/advancement/world/full_powderkeg.json`（原文单行）

```json
{"parent":"tfc:world/powderkeg","criteria":{"special_condition":{"trigger":"tfc:full_powderkeg"}},"display":{"icon":{"id":"minecraft:gunpowder"},"title":{"translate":"tfc.advancements.world.full_powderkeg.title"},"description":{"translate":"tfc.advancements.world.full_powderkeg.description"},"frame":"task","show_toast":true,"announce_to_chat":true,"hidden":false,"background":"tfc:textures/block/mud/fluvisol.png"},"requirements":[["special_condition"]]}
```

**样例 2：`BlockActionTrigger`，`conditions.ingredient` 用 tag 字符串形式** —— `data/tfc/advancement/story/smooth_stone.json`

```json
{"parent":"tfc:story/chisel","criteria":{"special_condition":{"trigger":"tfc:chiseled","conditions":{"ingredient":"#c:stones/smooth"}}},"display":{"icon":{"id":"tfc:rock/smooth/chert"},"title":{"translate":"tfc.advancements.story.smooth_stone.title"},"description":{"translate":"tfc.advancements.story.smooth_stone.description"},"frame":"task","show_toast":true,"announce_to_chat":true,"hidden":false,"background":"tfc:textures/block/rock/mossy_cobble/diorite.png"},"requirements":[["special_condition"]]}
```

**样例 3：`BlockActionTrigger`，`conditions.ingredient` 用数组形式** —— `data/tfc/advancement/story/firepit.json`

```json
{"parent":"tfc:story/firestarter","criteria":{"special_condition":{"trigger":"tfc:firepit_created","conditions":{"ingredient":["tfc:firepit"]}}},"display":{"icon":{"id":"tfc:firepit"},"title":{"translate":"tfc.advancements.story.firepit.title"},"description":{"translate":"tfc.advancements.story.firepit.description"},"frame":"task","show_toast":true,"announce_to_chat":true,"hidden":false,"background":"tfc:textures/block/rock/mossy_cobble/diorite.png"},"requirements":[["special_condition"]]}
```

**样例 4：`EntityActionTrigger`，`conditions.entity.type` 用 tag** —— `data/tfc/advancement/world/familiarity.json`

```json
{"parent":"tfc:world/root","criteria":{"special_condition":{"trigger":"tfc:fed_animal","conditions":{"entity":{"type":"#tfc:animals"}}}},"display":{"icon":{"id":"tfc:food/wheat_grain","components":{"tfc:food":{"creation_date":-3}}},"title":{"translate":"tfc.advancements.world.familiarity.title"},"description":{"translate":"tfc.advancements.world.familiarity.description"},"frame":"task","show_toast":true,"announce_to_chat":true,"hidden":false,"background":"tfc:textures/block/mud/fluvisol.png"},"requirements":[["special_condition"]]}
```

**样例 5：`EntityActionTrigger`，`conditions.entity` 用距离谓词** —— `data/tfc/advancement/world/greatest_hunter.json`

```json
{"parent":"tfc:world/hunter","criteria":{"special_condition":{"trigger":"tfc:stab_entity","conditions":{"entity":{"type":"tfc:rabbit","distance":{"horizontal":{"min":50}}}}}},"display":{"icon":{"id":"tfc:metal/javelin/red_steel"},"title":{"translate":"tfc.advancements.world.greatest_hunter.title"},"description":{"translate":"tfc.advancements.world.greatest_hunter.description"},"frame":"task","show_toast":true,"announce_to_chat":true,"hidden":false,"background":"tfc:textures/block/mud/fluvisol.png"},"requirements":[["special_condition"]]}
```

（另有 `advancement/world/advanced_fishing.json`、`advancement/story/windmill.json` 等未贴全文：前者与样例 4 同为 `conditions.entity.type` 的 `#tag` 形式，后者与样例 1 同为无 conditions 形式。）

### T-4.5 附属模组可复用的要点

- 所有 18 个 trigger 都是 `SimpleCriterionTrigger` 的子类，因此 advancement 的 criteria 写法遵循 vanilla 结构（`{"trigger":"tfc:xxx","conditions":{...}}`），且都可被附属模组直接引用（注册表 id 稳定）。
- `registerBlock` 系列要求写 `conditions.ingredient`；`registerEntity` 系列要求写 `conditions.entity`；`registerGeneric` 系列只能写 `conditions.player`（写了别的字段会被 codec 拒绝）。
- `tfc:chiseled` / `tfc:lit` / `tfc:rock_anvil` / `tfc:firepit_created` 的 `ingredient` 支持 `#tag` 字符串（`BlockIngredient` 的 `Either.right(TagKey<Block>)` 分支），因此附属模组可以通过往 block tag 加条目来扩展这些 advancement 的可触发方块，无需改 advancement JSON。
- `tfc:fed_animal` / `tfc:hooked_entity` / `tfc:stab_entity` 的 `entity.type` 使用 vanilla `EntityPredicate`，同样支持 `#tag` 形式（样例 4）。

### T-4.6 未能核实的点（本章）

- `GenericTrigger` 的 11 个 trigger 各自在**哪个代码位置**被调用（如 `tfc:basin_pour` 由哪个方块实体触发）未逐一核实。已确认的仅是注册与 JSON 结构。若要逐一核实需按 id 反查调用点，本次未做。

