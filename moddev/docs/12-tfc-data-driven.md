
---

# TFC 4.2.10 数据驱动内容格式完整参考手册


> 面向对象：**不带上下文、需要直接照抄字段**的 AI 代理，用于编写 TerraFirmaCraft 附属模组 / 数据包。
> 版本基准：`TerraFirmaCraft-NeoForge-1.21.1-4.2.10`（Minecraft 1.21.1 / NeoForge 21.1.248）。
> 本手册所有字段均从反编译源码的 `Codec` / `RecordCodecBuilder` / record 组件逐行读取确认，所有 JSON 样例均取自本地 jar 的真实文件。**未核实的内容一律标注「未能核实」并说明检查过哪些文件。**
> 网络不可用，本手册全部结论来自本地文件，未使用任何在线资料。

---

### 0. 环境事实与使用说明

##### 0.1 本手册的证据来源（本地路径）

| 项目 | 路径 | 说明 |
| --- | --- | --- |
| 反编译源码根 | `D:\111\最强服务器\.minecraft\versions\Essential TerraFirmaCraft (TFC)\moddev\src-ref\TFC-decompiled` | CFR 0.152 反编译产物，`net\dries007\tfc\...`，共 1672 个 `.java`。**无参数名无注释，但 Codec/字段/常量完整。** |
| 真实 jar | `...\mods\TerraFirmaCraft-NeoForge-1.21.1-4.2.10.jar` | 用于读取真实 JSON 与资源 |
| jar 解包目录 | `...\moddev\jar-extract\` | 本手册写作时解包出的真实内容，可直接当普通文件读 |
| jar 清单 | `...\moddev\inventory\TFC.resources.txt` | 全部资源路径清单（43184 行） |
| API 签名转储 | `...\moddev\inventory\api-dump\TFC-public-api.txt` | 284 个类的 `javap -public` 输出 |
| jar 读取辅助脚本 | `...\moddev\tools\readjar.ps1` | PowerShell 函数 `Read-JarEntry` / `Get-JarEntryList` / `Grep-JarEntry` |

**关于反编译产物头部的 `Could not load the following classes:`**：这是 CFR 在 classpath 缺依赖时的提示，不代表源码不可用，可忽略。

**读源码时要认的两种写法**：

```java
// 1) 独立 Codec（顶层 CODEC 字段）
public static final Codec<X> CODEC = RecordCodecBuilder.create(i -> i.group(...).apply(i, X::new));

// 2) MapCodec（用于 serializer / 嵌套内联，如 FoodData.MAP_CODEC）
public static final MapCodec<X> CODEC = RecordCodecBuilder.mapCodec(i -> ...);
```

**判断字段必需性的唯一可靠方法**：看字段是 `xxx.fieldOf("name")`（**必填**）还是 `xxx.optionalFieldOf("name", 默认值)`（**可选，有默认值**）。

##### 0.2 目录约定速查（附属模组最常踩的坑）

| 内容 | 正确路径 | 常见错误 |
| --- | --- | --- |
| 配方 | `data/<modid>/recipe/<recipe_path>.json` | — |
| TFC 数据管理器数据 | `data/<modid>/tfc/<kind>/<path>.json`（**第一个 `tfc` 段是常量字面量**） | 写成 `data/<modid>/<kind>/...` |
| 数据包注册表（如岩石设置） | `data/<modid>/tfc/worldgen/rock_settings/<name>.json` | — |
| tag | `data/<modid>/tags/<registry>/<path>.json` | 忘记 registry 层 |
| 战利品表（1.21.1） | `data/<modid>/loot_table/<path>.json` | 写成 `loot_tables`（旧版复数） |
| 进度 | `data/<modid>/advancement/<path>.json` | 写成 `advancements`（旧版复数） |
| worldgen 生物群系 | `data/<modid>/worldgen/biome/<path>.json` | — |
| worldgen 特征 | `data/<modid>/worldgen/configured_feature/<path>.json` 与 `.../placed_feature/<path>.json` | 两者缺一不可 |

**TFC 数据管理器数据的 ID 推导规则**：删除 `data/` 前缀与 `tfc/<kind>/` 中段后，剩下的相对路径就是 ID（**子目录会进入 ID**）：

```
data/tfc/tfc/item_heat/copper/sheet.json         → tfc:copper/sheet
data/tfc/tfc/climate_range/crop/barley.json      → tfc:crop/barley
data/tfc/tfc/deposit/native_copper/granite.json  → tfc:native_copper/granite
data/mymod/tfc/item_heat/my_alloy/ingot.json     → mymod:my_alloy/ingot
```

**不要试图覆盖 `tfc:` 命名空间下已存在的 ID**：`DataManager.apply` 使用 `ImmutableMap.Builder`，重复 key 会抛异常并被记为解析错误（来源：`net/dries007/tfc/util/data/DataManager.java` L154-L170）。要改行为，请**新增自己的 ID** 或使用数据包注册表。

##### 0.3 TFC 自定义注册表一览（决定 JSON 的 `type` 字符串）

| 注册表 | 源码类 | JSON 用法 |
| --- | --- | --- |
| 配方类型 / 序列化器 | `net.dries007.tfc.common.recipes.TFCRecipeSerializers`、`TFCRecipeTypes` | `"type": "tfc:xxx"` |
| 数据管理器 | `net.dries007.tfc.util.data.DataManagers` | `data/<ns>/tfc/<kind>/...` |
| 自定义 ingredient | `net.dries007.tfc.common.recipes.ingredients.TFCIngredients` | `{"type": "tfc:xxx", ...}` |
| 自定义战利品条件/函数 | `net.dries007.tfc.common.loot.TFCLoot` | `{"type": "tfc:xxx", ...}` / `{"function": "tfc:xxx", ...}` |
| 自定义进度触发器 | `net.dries007.tfc.common.advancements.TFCAdvancements` | `"trigger": "tfc:xxx"` |
| 世界生成 placement | `net.dries007.tfc.world.placement.TFCPlacements` | `{"type": "tfc:xxx", ...}` |
| 世界生成 feature | `net.dries007.tfc.world.feature.TFCFeatures` | `{"type": "tfc:xxx", ...}` |

---

### 1. 配方类型总览（28 种，编号 R-01 ~ R-28）

##### 1.1 注册来源

TFC 的配方序列化器集中在 `net/dries007/tfc/common/recipes/TFCRecipeSerializers.java` 的静态初始化块中，共 27 条 TFC 自有注册 + 原版扩展的 `advanced_*`。注册签名如下（源码实测）：

| 序列化器 id | 实现类 | 注册写法 |
| --- | --- | --- |
| `tfc:collapse` | `CollapseRecipe` | `BlockRecipe.serializer(CollapseRecipe::new)` |
| `tfc:landslide` | `LandslideRecipe` | `BlockRecipe.serializer(LandslideRecipe::new)` |
| `tfc:chisel` | `ChiselRecipe` | `ChiselRecipe.CODEC` / `STREAM_CODEC` |
| `tfc:heating` | `HeatingRecipe` | `HeatingRecipe.CODEC` / `STREAM_CODEC` |
| `tfc:quern` | `QuernRecipe` | `QuernRecipe.CODEC` / `STREAM_CODEC` |
| `tfc:scraping` | `ScrapingRecipe` | `ScrapingRecipe.CODEC` / `STREAM_CODEC` |
| `tfc:pot` | `SimplePotRecipe` | `SimplePotRecipe.CODEC` / `STREAM_CODEC` |
| `tfc:pot_soup` | `SoupPotRecipe` | `SoupPotRecipe.CODEC` / `STREAM_CODEC` |
| `tfc:pot_jam` | `JamPotRecipe` | `JamPotRecipe.CODEC` / `STREAM_CODEC` |
| `tfc:knapping` | `KnappingRecipe` | `KnappingRecipe.CODEC` / `STREAM_CODEC` |
| `tfc:alloy` | `AlloyRecipe` | `AlloyRecipe.CODEC` / `STREAM_CODEC` |
| `tfc:casting` | `CastingRecipe` | `CastingRecipe.CODEC` / `STREAM_CODEC` |
| `tfc:bloomery` | `BloomeryRecipe` | `BloomeryRecipe.CODEC` / `STREAM_CODEC` |
| `tfc:barrel_sealed` | `SealedBarrelRecipe` | `SealedBarrelRecipe.CODEC` / `STREAM_CODEC` |
| `tfc:barrel_instant` | `InstantBarrelRecipe` | `InstantBarrelRecipe.CODEC` / `STREAM_CODEC` |
| `tfc:barrel_instant_fluid` | `InstantFluidBarrelRecipe` | `InstantFluidBarrelRecipe.CODEC` / `STREAM_CODEC` |
| `tfc:loom` | `LoomRecipe` | `LoomRecipe.CODEC` / `STREAM_CODEC` |
| `tfc:anvil` | `AnvilRecipe` | `AnvilRecipe.CODEC` / `STREAM_CODEC` |
| `tfc:welding` | `WeldingRecipe` | `WeldingRecipe.CODEC` / `STREAM_CODEC` |
| `tfc:blast_furnace` | `BlastFurnaceRecipe` | `BlastFurnaceRecipe.CODEC` / `STREAM_CODEC` |
| `tfc:glassworking` | `GlassworkingRecipe` | `GlassworkingRecipe.CODEC` / `STREAM_CODEC` |
| `tfc:sewing` | `SewingRecipe` | `SewingRecipe.CODEC` / `STREAM_CODEC` |
| `tfc:food_combining` | `FoodCombiningCraftingRecipe` | `new RecipeSerializerImpl<>(FoodCombiningCraftingRecipe.INSTANCE)` |
| `tfc:casting_crafting` | `CastingCraftingRecipe` | `new RecipeSerializerImpl<>(CastingCraftingRecipe.INSTANCE)` |
| `tfc:advanced_shaped_crafting` | `AdvancedShapedRecipe` | `AdvancedShapedRecipe.CODEC` / `STREAM_CODEC` |
| `tfc:advanced_shapeless_crafting` | `AdvancedShapelessRecipe` | `AdvancedShapelessRecipe.CODEC` / `STREAM_CODEC` |

来源：`net/dries007/tfc/common/recipes/TFCRecipeSerializers.java` 全文。

`TFCRecipeTypes`（`net/dries007/tfc/common/recipes/TFCRecipeTypes.java`）另注册了 recipe type 名，其取值与上表 serializer 名基本一致，但**没有** `pot_soup`、`pot_jam`、`food_combining`、`casting_crafting`、`advanced_*` 的独立条目（详见各配方小节）。

##### 1.2 全部类型索引与实测数量

数量统计依据实测解包目录 `...\moddev\jar-extract\data\tfc\recipe\`（按 JSON 文件计数；子代理已用 JSON 解析器逐文件核对）。**「目录条目」与「json 文件」两种口径会差几十条**，例如 crafting 目录在资源清单中为 3001 条 = 2895 个 JSON + 106 个目录条目。

| 编号 | type id | 数量 | 所在目录 | 本手册章节 |
| --- | --- | --- | --- | --- |
| R-01 | `tfc:alloy` | 9 | `recipe/alloy/` | 合金 |
| R-02 | `tfc:anvil` | 281 | `recipe/anvil/`（含 `metal/` 子目录） | 砧板锻造 |
| R-03 | `tfc:welding` | 87 | `recipe/welding/` | 砧板焊接 |
| R-04 | `tfc:casting` | 111 | `recipe/casting/` | 模具浇铸 |
| R-05 | `tfc:casting_crafting` | 1 | `recipe/crafting/casting.json` | 工作台浇铸 |
| R-06 | `tfc:collapse` | 525 | `recipe/collapse/` | 岩石塌陷 |
| R-07 | `tfc:landslide` | 21 | `recipe/landslide/` | 滑坡 |
| R-08 | `tfc:chisel` | 513 | `recipe/chisel/` | 凿刻 |
| R-09 | `tfc:barrel_sealed` | 308 | `recipe/barrel/` | 密封桶 |
| R-10 | `tfc:barrel_instant` | 20 | `recipe/barrel/` | 即时桶 |
| R-11 | `tfc:barrel_instant_fluid` | 2 | `recipe/barrel/` | 即时桶（流体） |
| R-12 | `tfc:heating` | 883 | `recipe/heating/` | 加热 |
| R-13 | `tfc:quern` | 89 | `recipe/quern/` | 手磨 |
| R-14 | `tfc:scraping` | 7 | `recipe/scraping/` | 刮制 |
| R-15 | `tfc:knapping` | 101 | `recipe/knapping/` | 打制 |
| R-16 | `tfc:glassworking` | 60 | `recipe/glassworking/` | 玻璃加工 |

| R-17 | `tfc:sewing` | 25 | `recipe/sewing/` | 缝纫 |
| R-18 | `tfc:pot` | 145 | `recipe/pot/` | 陶罐（普通） |
| R-19 | `tfc:pot_soup` | 3 | `recipe/pot/`（**与 pot 混放**） | 陶罐（汤） |
| R-20 | `tfc:pot_jam` | 66 | `recipe/pot/`（**与 pot 混放**） | 陶罐（果酱） |
| R-21 | `tfc:loom` | 5 | `recipe/loom/` | 织机 |
| R-22 | `tfc:food_combining` | 1 | `recipe/crafting/food_combining.json` | 食物合并 |
| R-23 | `tfc:bloomery` | 1 | `recipe/bloomery/` | 土高炉 |
| R-24 | `tfc:blast_furnace` | 1 | `recipe/blast_furnace/` | 高炉 |
| R-25 | `minecraft:crafting_shaped` | 1669 | `recipe/crafting/`（混放） | 原版有序合成 |
| R-26 | `minecraft:crafting_shapeless` | 569 | `recipe/crafting/`（混放） | 原版无序合成 |
| R-27 | `tfc:advanced_shaped_crafting` | 372 | `recipe/crafting/`（混放） | TFC 扩展有序合成 |
| R-28 | `tfc:advanced_shapeless_crafting` | 283 | `recipe/crafting/`（混放） | TFC 扩展无序合成 |
| R-29 | （通用章节） | — | — | `ItemStackProvider` / `ItemStackModifier` / `TFCIngredients` |

> **重要目录事实（实测）**：
> 1. `recipe/pot_soup/`、`recipe/pot_jam/`、`recipe/advanced_shaped_crafting/`、`recipe/advanced_shapeless_crafting/` 这 4 个目录**在 jar 中不存在**。`pot_soup`(3) 与 `pot_jam`(66) 与 `tfc:pot` **混放在 `recipe/pot/`**（该目录顶层 199 个 = 130 pot + 66 pot_jam + 3 pot_soup，另有 `pot/food/` 15 个）；`advanced_*`(372+283) 与前两者一起混放在 `recipe/crafting/`。**区分方式只能是 JSON 内的 `type` 字段，不能靠目录或文件名**（`jam_*` 文件名具有误导性）。
> 2. `recipe/crafting/` 下的 `type` 分布实测为：`crafting_shaped` 1669 + `crafting_shapeless` 569 + `advanced_shaped_crafting` 372 + `advanced_shapeless_crafting` 283 + `casting_crafting` 1 + `food_combining` 1 = **2895**（每个文件恰一个顶层配方）。
> 3. `heating` 在资源清单中为 951 条，其中含目录条目，实际 `.json` 为 883 个。所有数量仅供估算规模，**不作为格式依据**。


##### 1.3 TFC 自定义数据类型的索引

| 编号 | kind | 数据类 | 管理路径 | 文件数 | 本手册章节 |
| --- | --- | --- | --- | --- | --- |
| D-1 | `item_heat` | `HeatDefinition` | `tfc:item_heat` | 343 | 物品热属性 |
| D-2 | `food` | `FoodDefinition` | `tfc:food` | 195 | 食物营养 |
| D-3 | `item_size` | `ItemSizeDefinition` | `tfc:item_size` | 67 | 体积重量 |
| D-4 | `fuel` | `Fuel` | `tfc:fuel` | 50 | 燃料 |
| D-5 | `fluid_heat` | `FluidHeat` | `tfc:fluid_heat` | 28 | 流体热学 |
| D-6 | `deposit` | `Deposit` | `tfc:deposit` | 84 | 矿砂沉积 |
| D-7 | `knapping_type` | `KnappingType` | `tfc:knapping_type` | 5 | 打制类型 |
| D-8 | `support` | `Support` | `tfc:support` | 1 | 方块支撑 |
| D-9 | `fertilizer` | `Fertilizer` | `tfc:fertilizer` | 10 | 肥料 |
| D-10 | `lamp_fuel` | `LampFuel` | `tfc:lamp_fuel` | 4 | 灯具燃料 |
| D-11 | `drinkable` | `Drinkable` | `tfc:drinkable` | 5 | 可饮流体 |
| D-12 | `item_damage_resistance` | `ItemDamageResistance` | `tfc:item_damage_resistance` | 11 | 物品物理抗性 |
| D-13 | `entity_damage_resistance` | `EntityDamageResistance` | `tfc:entity_damage_resistance` | 2 | 实体物理抗性 |
| D-14 | `climate_range` | `ClimateRange` | `tfc:climate_range` | 49 | 气候需求 |
| D-15 | `fauna` | `Fauna` | `tfc:fauna` | 77 | 动物生成 |
| D-16 | `worldgen/rock_settings` | `RockSettings` | 数据包注册表 | 21 | 岩石方块映射 |

##### 1.4 已核实「不存在」的 id（避免照抄错名）

以下是调查过程中**经全库/全源码搜索确认不存在**的 id。写附属模组时不要使用它们（三项均由子代理独立复核，命中数为 0）：

| 猜测/易错 id | 实际情况 | 依据 |
| --- | --- | --- |
| `tfc:damaged`（ingredient） | **不存在** | 全库搜索 0 次；正确做法是 `tfc:heat`（按温度范围）或自行组合 |
| `tfc:fluid`（ingredient） | **不存在** | 全库 0 次；正确名是 `tfc:fluid_content` |
| `tfc:item_stack_provider`（ingredient `type`） | **不存在** | 全库 0 次；`ItemStackProvider` 不是 ingredient，而是 `result` 字段的类型 |
| `tfc:metals/*`（tag 层级） | **不存在** | `tags/item/` 下只有 6 个一级子目录（`compost_browns`、`compost_greens`、`double_sheets`、`foods`、`stones`、`tools`），其余 172 个 tag 是扁平单文件 |
| `tfc:ores/*`（tag 层级） | **不存在** | 矿石相关只有 4 个扁平 tag：`tfc:metal_ores`、`tfc:ore_pieces`、`tfc:small_ore_pieces`、`tfc:ore_deposits`。`<ore>/<grade>` 形态只出现在**物品 id** 上（如 `tfc:ore/poor_native_copper`） |
| `tfc:can_be_chiseled` | **不存在** | 实际是 `tfc:mineable/chisel` |
| `tfc:forge_invisible_whitelist` | **不存在** | 实际是 `tfc:charcoal_forge_invisible` |
| `tfc:has_damage` / `tfc:not_damaged` / `tfc:any_damage` | **均不存在** | 源码全树 grep 无命中 |
| `ItemStackProviders`（复数类） | **不存在** | 实际体系为 `ItemStackProvider`（单数）+ `ItemStackModifiers`（注册表），且位于 `net/dries007/tfc/common/recipes/outputs/`，**不在** `net/dries007/tfc/util/` |
| `net/dries007/tfc/TFC.java`、`net/dries007/tfc/util/TagHelpers.java`、`net/dries007/tfc/common/loot/`、`net/dries007/tfc/common/advancements/`、`net/dries007/tfc/world/rocklayer/`、`net/dries007/tfc/world/vein/`、`net/dries007/tfc/world/TFCRegions` | **这些类/包在 4.2.10 中都不存在** | 真实位置：tag 常量在 `net/dries007/tfc/common/TFCTags.java`；loot 在 `net/dries007/tfc/util/loot/TFCLoot.java`；advancement 在 `net/dries007/tfc/util/advancements/TFCAdvancements.java`；岩层在 `net/dries007/tfc/world/settings/`；矿脉在 `net/dries007/tfc/world/feature/vein/` |

**统计口径差异说明**（避免与其他资料冲突）：本手册的 tags 数量以实测解包目录为准 —— `item` 203、`block` 143、`entity_type` 35、`fluid` 22、`damage_type` 3、`worldgen` 440，合计 **846** 个 JSON。若用 `TFC.resources.txt` 直接统计会因计入目录条目而偏高（例如得到 872）。`data/tfc/tfc/worldgen/` 实测为 **21** 个（全部是 `rock_settings/*.json`），而非 23。`data/tfc/worldgen/` 实测为 **1498** 个：`configured_feature` 690、`placed_feature` 674、`biome` 125、`density_function` 5、`configured_carver` 3、`world_preset` 1。

---

### 2. 配方通用骨架模板（可直接复制）

以下模板覆盖 90% 的附属模组需求，字段含义详见对应章节。

##### 2.1 加热配方（`tfc:heating`）

```json
{
  "type": "tfc:heating",
  "ingredient": { "item": "mymod:raw_titanium" },
  "result_item": { "stack": { "id": "mymod:titanium_ingot" } },
  "temperature": 1668.0
}
```

> `tfc:heating` **没有** `chance` 字段（CODEC 只有 `ingredient`/`result_item`/`result_fluid`/`temperature`/`use_durability`）；概率产出用 `result_item.modifiers` 里的 `{"type":"tfc:chance","chance":0.2}`。详见 R-12。

##### 2.2 砧板锻造（`tfc:anvil`）

```json
{
  "type": "tfc:anvil",
  "ingredient": { "item": "mymod:titanium_ingot" },
  "result": { "count": 1, "id": "mymod:titanium_sheet" },
  "rules": [ "bend_last", "draw_second_last", "upset_third_last" ],
  "tier": 5,
  "apply_bonus": true
}
```

> `rules` 长度必须是 1~3，且必须通过 `ForgeRule.isConsistent` 校验（否则数据包加载即报错）。`result` 可直接写裸 `ItemStack`（`{"id":...,"count":...}`），也可写 `{"stack":{...},"modifiers":[...]}`（此时 `modifiers` 必填）。详见 R-02。

##### 2.3 密封桶（`tfc:barrel_sealed`）

```json
{
  "type": "tfc:barrel_sealed",
  "input_item": { "count": 1, "item": "mymod:titanium_dust" },
  "input_fluid": { "amount": 100, "fluid": "tfc:metal/titanium" },
  "output_item": { "count": 1, "id": "mymod:titanium_ingot" },
  "duration": 1200
}
```

> **命名陷阱**：`input_fluid` 用 `fluid` 键（`SizedFluidIngredient.FLAT_CODEC`），而 `output_fluid` 用 `id` 键（`FluidStack.CODEC`）。`duration` 必需，`<= 0` 表示永久。可选 `on_seal`/`on_unseal`（`ItemStackProvider`）。详见 R-09。

##### 2.4 陶罐（`tfc:pot`）

```json
{
  "type": "tfc:pot",
  "ingredients": [ { "item": "mymod:titanium_dust" } ],
  "fluid_ingredient": { "amount": 100, "fluid": "minecraft:water" },
  "duration": 1200,
  "temperature": 300.0,
  "item_output": [ { "count": 1, "id": "mymod:titanium_ingot" } ]
}
```

> `temperature` 是**严格大于**的低阈值；`item_output` 是 `ItemStackProvider` 的**数组**（可为 `{"modifiers":[...]}` 形式，此时 `stack` 可选）；`fluid_output` 是 `FluidStack`（`{"amount":N,"id":"..."}`）。可选 `uses_all_fluid`（默认 `true`）。详见 R-18。

##### 2.5 打制（`tfc:knapping`）

```json
{
  "type": "tfc:knapping",
  "knapping_type": "tfc:rock",
  "pattern": [ "XXXXX", "X   X", "X   X", "X   X", "XXXXX" ],
  "result": { "count": 1, "id": "mymod:bone_plate" }
}
```

> `pattern` 与 `default_on` 是**顶层字段**（`KnappingPattern.CODEC` 经 `forGetter` 平铺）。图案**不要求** 5×5：允许 1~5 行/列，但**非 5×5 时必须提供 `default_on`**，否则报错 `default_on is required if the pattern is not 5x5`。`result` 是**裸 `ItemStack`**，不是 `ItemStackProvider`。可选 `outside_slot_required`（默认 `true`，即必须消耗外圈格）。详见 R-15。

##### 2.6 扩展工作台合成（`tfc:advanced_shaped_crafting`）

```json
{
  "type": "tfc:advanced_shaped_crafting",
  "pattern": [ "XX", "XX" ],
  "key": { "X": { "tag": "c:ingots/titanium" } },
  "result": { "stack": { "id": "mymod:titanium_block" } }
}
```

> `result` 为 `ItemStackProvider`（支持裸 `ItemStack` 简写，也支持带 `modifiers` 的完整形式）。详见 R-27。

##### 2.7 TFC 数据文件模板（`data/mymod/tfc/item_heat/...`）

```json
{
  "ingredient": { "tag": "c:ingots/titanium" },
  "heat_capacity": 2.5,
  "forging_temperature": 1200.0,
  "welding_temperature": 1500.0
}
```

##### 2.8 通用 ingredient 写法速查

```json
// 单个物品
{ "item": "minecraft:iron_ingot" }
// 物品 tag（加 # 前缀的字符串形式）
"#c:ingots/iron"
// 显式 tag 对象
{ "tag": "c:ingots/iron" }
// 多个候选项（任一匹配即可）
[ { "item": "tfc:food/potato" }, { "item": "tfc:food/cooked_potato" } ]
// NeoForge 差集
{ "type": "neoforge:difference", "base": { "tag": "c:ingots" }, "subtracted": { "tag": "c:bricks" } }
// 方块 ingredient（BlockIngredient）：单个方块 / tag / 数组
"tfc:rock/raw/granite"
"#tfc:rock/raw"
[ "tfc:wood/horizontal_support/oak", "tfc:wood/horizontal_support/pine" ]
// 流体 ingredient（NeoForge FluidIngredient）
{ "fluid": "minecraft:water" }
{ "tag": "tfc:alcohols" }
[ { "fluid": "minecraft:water" }, { "fluid": "tfc:river_water" } ]
```

来源：`net/dries007/tfc/common/recipes/ingredients/BlockIngredient.java` 的 `CODEC`（`Codec.either(Codecs.BLOCK.listOf(), TagKey.hashedCodec(Registries.BLOCK))`）；真实用例见 `data/tfc/tfc/support/horizontal_support_beam.json`、`data/tfc/tfc/drinkable/water.json`、`data/tfc/tfc/item_size/ingots.json`。

##### 2.9 常用物品组件（`ItemStack` 的 JSON 写法）

TFC 大量使用原版 `ItemStack.CODEC`，其键名是 `id` + `count`（**不是** `item`）：

```json
{ "id": "mymod:titanium_ingot", "count": 2 }
```

而 NeoForge 的 `SizedIngredient`（FLAT 形式）用 `item`/`tag` + `count`：

```json
{ "item": "mymod:titanium_ingot", "count": 2 }
{ "tag": "c:ingots/titanium", "count": 4 }
```

来源：`net/dries007/tfc/util/data/KnappingType.java` L45（`SizedIngredient.FLAT_CODEC` 与 `ItemStack.CODEC` 并用，真实文件 `data/tfc/tfc/knapping_type/rock.json` 中 `input` 用 `tag`+`count`、`icon` 用 `id`+`count`）。

---

<!-- SECTION_RECIPES -->

---

<!-- SECTION_DATA_TYPES -->

---

<!-- SECTION_MISC -->

---

## 第 1 部分　冶金与锻造配方（R-01 ~ R-05）


> 版本基准：TerraFirmaCraft-NeoForge-1.21.1-4.2.10 / Minecraft 1.21.1 / NeoForge 21.1.x
> 证据来源（全部为本地文件，无网络依赖）：
> - 反编译源码根：`moddev/src-ref/TFC-decompiled`（下文相对路径均以此为根）
> - 真实 jar 解包内容：`moddev/jar-extract`（下文"jar 内路径"以 `jar-extract` 为根）
> - 字节码交叉验证：`.minecraft/libraries/net/minecraft/client/1.21.1-20240808.144430/client-1.21.1-20240808.144430-srg.jar`（用 `javap` 读取，用于确认 Minecraft 侧 `CustomRecipe`/`CraftingRecipe` 的行为）
> - 反编译产物无参数名、无注释，但 `CODEC` 定义、record 组件、字段常量均完整可读。

### 组 A1 覆盖范围

本组负责以下 5 种配方类型，均为 TFC 冶金/锻造/浇铸链条的核心配方：

| 编号 | type id | 实现类 | 本组对应小节 |
| --- | --- | --- | --- |
| R-01 | `tfc:alloy` | `net.dries007.tfc.common.recipes.AlloyRecipe` | 合金配方（坩埚/容器内多金属熔液按比例判定产物） |
| R-02 | `tfc:anvil` | `net.dries007.tfc.common.recipes.AnvilRecipe` | 砧板锻造配方（锻造步骤规则 + 目标工作值） |
| R-03 | `tfc:welding` | `net.dries007.tfc.common.recipes.WeldingRecipe` | 砧板焊接配方（两个输入 + 助焊剂） |
| R-04 | `tfc:casting` | `net.dries007.tfc.common.recipes.CastingRecipe` | 模具浇铸配方（模具 + 定量流体） |
| R-05 | `tfc:casting_crafting` | `net.dries007.tfc.common.recipes.CastingCraftingRecipe` | 工作台浇铸（special crafting 配方，**无独立 recipe type**） |

不属于本组、但会被本组引用的通用辅助类型（`ItemStackProvider`、`ItemStackModifier`、`ForgeRule`、`AlloyRange`、`TFCIngredients`）在文末「附录 A1-1 / A1-2」集中说明。

编号说明：本组严格使用 `R-01` ~ `R-05`，不占其它组的编号空间。

---

### [R-01] tfc:alloy —— 合金配方

##### R-01.1 类型标识与实现类

| 项目 | 值 | 证据 |
| --- | --- | --- |
| JSON `type` | `tfc:alloy` | `net/dries007/tfc/common/recipes/TFCRecipeSerializers.java:68` |
| recipe type id | `tfc:alloy` | `net/dries007/tfc/common/recipes/TFCRecipeTypes.java:52`（`ALLOY = register("alloy")`） |
| serializer id | `tfc:alloy` | `TFCRecipeSerializers.java:68`（`register("alloy", AlloyRecipe.CODEC, AlloyRecipe.STREAM_CODEC)`） |
| 实现类全名 | `net.dries007.tfc.common.recipes.AlloyRecipe` | `AlloyRecipe.java:47` |
| 类型形态 | `record AlloyRecipe(List<AlloyRange> contents, Fluid result)` | `AlloyRecipe.java:47-49` |
| 实现的接口 | `INoopInputRecipe`、`IRecipePredicate<FluidAlloy>` | `AlloyRecipe.java:47-48` |
| `getType()` 返回值 | `TFCRecipeTypes.ALLOY.get()` | `AlloyRecipe.java:67-69` |
| `getSerializer()` 返回值 | `TFCRecipeSerializers.ALLOY.get()` | `AlloyRecipe.java:63-65` |

**类型名与序列化名一致**，不存在不一致问题。

结论：本配方**不通过** `Recipe.getType()` 之外的方式被分类；它仍然是标准 `Recipe<NoopInput>`（`NoopInput` 为占位输入，见 `net/dries007/tfc/common/recipes/input/NoopInput.java`），但实际匹配逻辑走 `IRecipePredicate<FluidAlloy>` 的重载 `matches(FluidAlloy)`。

##### R-01.2 完整字段表

字段全部来自 `AlloyRecipe` 自身的 `CODEC`（`AlloyRecipe.java:50`）与其嵌套类型 `AlloyRange` 的 `CODEC`（`net/dries007/tfc/util/AlloyRange.java:32`）。

`AlloyRecipe.CODEC`（`AlloyRecipe.java:50`）逐项拆解：

```java
public static final MapCodec<AlloyRecipe> CODEC = RecordCodecBuilder.mapCodec(i -> i.group(
    AlloyRange.CODEC.listOf().fieldOf("contents").forGetter(c -> c.contents),
    BuiltInRegistries.FLUID.byNameCodec().fieldOf("result").forGetter(c -> c.result)
).apply(i, AlloyRecipe::new));
```

`AlloyRange.CODEC`（`AlloyRange.java:32`）：

```java
public static final Codec<AlloyRange> CODEC = RecordCodecBuilder.create(i -> i.group(
    BuiltInRegistries.FLUID.byNameCodec().fieldOf("fluid").forGetter(c -> c.fluid),
    Codec.DOUBLE.fieldOf("min").forGetter(c -> c.min),
    Codec.DOUBLE.fieldOf("max").forGetter(c -> c.max)
).apply(i, AlloyRange::new));
```

**顶层字段**

| 字段名 | 类型 | 必需/可选 | 默认值 | 语义 |
| --- | --- | --- | --- | --- |
| `type` | `String` | 必需 | 无 | 固定为 `tfc:alloy`，由 serializer 分发（`TFCRecipeSerializers.java:68`） |
| `contents` | `List<AlloyRange>` | **必需** | 无（`fieldOf` 必填，缺失即解析失败） | 该合金的组分要求列表；每一项是一个「流体 + 占比区间」 |
| `result` | `Fluid`（`BuiltInRegistries.FLUID.byNameCodec()`） | **必需** | 无 | 满足 `contents` 全部区间时产出的熔融金属流体 id |

**`contents` 数组内每个元素的字段**（来自 `AlloyRange.CODEC`，`AlloyRange.java:31-33`）

| 字段名 | 类型 | 必需/可选 | 默认值 | 语义 |
| --- | --- | --- | --- | --- |
| `fluid` | `Fluid` | **必需** | 无 | 参与该合金的某一金属流体，例如 `tfc:metal/copper` |
| `min` | `double`（`Codec.DOUBLE`） | **必需** | 无 | 该流体占总量的最小质量占比（0~1 的分数，不是百分数） |
| `max` | `double`（`Codec.DOUBLE`） | **必需** | 无 | 该流体占总量的最大质量占比 |

**校验与容差（必须注意）**

1. `AlloyRange.isIn(double value)`（`AlloyRange.java:35-37`）使用**双向浮点容差**：
   ```java
   return this.min - 4.656612875245797E-10 <= value && value <= this.max + 4.656612875245797E-10;
   ```
   该常数即 `Float.MIN_VALUE` 量级（约 4.657e-10），所以边界值是「包含」的，且存在极小的松弛。
2. `min`/`max` 与「占比」的除法在 `FluidAlloy.matchesExactly(AlloyRecipe)` 中完成（`net/dries007/tfc/util/FluidAlloy.java:227-240`）：
   ```java
   double actualTotalAmount = this.getExactAmount();      // 所有流体量之和
   ...
   if (!content.containsKey(fluid) || !range.isIn(content.getDouble(fluid) / actualTotalAmount)) return false;
   ...
   return inputsNotMatched.isEmpty();                     // 不允许存在未被任何 range 覆盖的流体
   ```
   即：**（a）每种列出的流体都必须存在且占比落在区间内；（b）不允许有未列出的多余流体。**
3. `FluidAlloy.matches(AlloyRecipe)`（`FluidAlloy.java:202-210`）有一条特殊放宽：如果当前熔液中**已经含有 `result` 同名流体**，会先把它移除再比较：
   ```java
   if (this.content.containsKey(recipe.result())) {
       FluidAlloy other = this.copy();
       other.content.removeDouble(recipe.result());
       other.clearCaches();
       return other.matchesExactly(recipe);
   }
   return this.matchesExactly(recipe);
   ```
   这条用于「已生成的合金液体继续被再次检验」的场景（例如多次浇铸后剩余熔液）。
4. `min` 与 `max` 的数值先后顺序不影响解析（record 按字段名取值），但语义上应满足 `min <= max`；源码中**没有任何 `validate` 检查 `min <= max`**，也未检查占比之和为 1。写数据时若 `min > max`，该条目将永远不匹配（静默失效）。
5. `contents` 允许为空列表（`listOf()` 无长度约束）。空列表时 `matchesExactly` 只要求 `inputsNotMatched.isEmpty()`，但 `matches` 的调用前置条件是熔液 `content.size() > 1`（见 R-01.4），实际不会命中。

**JSON codec 与网络 codec 的差异**

| 项目 | JSON（`CODEC`） | 网络（`STREAM_CODEC`） | 差异说明 |
| --- | --- | --- | --- |
| 字段名 | `contents` / `result` | 无字段名，按位置序列化 | 网络侧无键名 |
| 列表长度 | `AlloyRange.CODEC.listOf()`，**无上限** | `AlloyRange.STREAM_CODEC.apply(ByteBufCodecs.list())`，同样无上限 | 一致 |
| `Fluid` | `byNameCodec()`（字符串 id） | `ByteBufCodecs.registry(Registries.FLUID)` | 表示法不同，语义一致 |
| 额外校验 | 无 | 无 | 一致 |

`STREAM_CODEC` 定义见 `AlloyRecipe.java:51`。

##### R-01.3 真实 JSON 样例

该目录下共有 **9 个**真实样例，全部读取过（`jar-extract/data/tfc/recipe/alloy/`）。因为 `tfc:alloy` 没有可选字段，这里给出全部 9 个中的 3 个代表性样例（覆盖 2 组分 / 3 组分 / 4 组分三种规模），其余仅列文件名。

样例 1：`data/tfc/recipe/alloy/bronze.json`（2 组分，最简）

```json
{"type":"tfc:alloy","contents":[{"fluid":"tfc:metal/copper","max":0.92,"min":0.88},{"fluid":"tfc:metal/tin","max":0.12,"min":0.08}],"result":"tfc:metal/bronze"}
```

样例 2：`data/tfc/recipe/alloy/bismuth_bronze.json`（3 组分）

```json
{"type":"tfc:alloy","contents":[{"fluid":"tfc:metal/zinc","max":0.3,"min":0.2},{"fluid":"tfc:metal/copper","max":0.65,"min":0.5},{"fluid":"tfc:metal/bismuth","max":0.2,"min":0.1}],"result":"tfc:metal/bismuth_bronze"}
```

样例 3：`data/tfc/recipe/alloy/weak_blue_steel.json`（4 组分，占比之和 0.95，含容差内空间）

```json
{"type":"tfc:alloy","contents":[{"fluid":"tfc:metal/black_steel","max":0.55,"min":0.5},{"fluid":"tfc:metal/steel","max":0.25,"min":0.2},{"fluid":"tfc:metal/bismuth_bronze","max":0.15,"min":0.1},{"fluid":"tfc:metal/sterling_silver","max":0.15,"min":0.1}],"result":"tfc:metal/weak_blue_steel"}
```

该目录全部 9 个文件（仅文件名，内容均已读取核对）：

| 文件（相对 `jar-extract/`） | `result` |
| --- | --- |
| `data/tfc/recipe/alloy/bismuth_bronze.json` | `tfc:metal/bismuth_bronze` |
| `data/tfc/recipe/alloy/black_bronze.json` | `tfc:metal/black_bronze` |
| `data/tfc/recipe/alloy/brass.json` | `tfc:metal/brass` |
| `data/tfc/recipe/alloy/bronze.json` | `tfc:metal/bronze` |
| `data/tfc/recipe/alloy/rose_gold.json` | `tfc:metal/rose_gold` |
| `data/tfc/recipe/alloy/sterling_silver.json` | `tfc:metal/sterling_silver` |
| `data/tfc/recipe/alloy/weak_blue_steel.json` | `tfc:metal/weak_blue_steel` |
| `data/tfc/recipe/alloy/weak_red_steel.json` | `tfc:metal/weak_red_steel` |
| `data/tfc/recipe/alloy/weak_steel.json` | `tfc:metal/weak_steel` |

注意：所有样例的 JSON 键都被**字母序**写成一行（`contents` 在 `result` 前，元素内 `max` 在 `min` 前），这是数据生成器的输出顺序，与解析无关。

##### R-01.4 游戏内触发条件

`AlloyRecipe` 的**唯一**静态查询入口是：

```java
// AlloyRecipe.java:53-56
public static AlloyRecipe get(RecipeManager recipes, FluidAlloy alloy) {
    return RecipeHelpers.unbox(RecipeHelpers.getHolder(recipes, TFCRecipeTypes.ALLOY, alloy));
}
```

- `RecipeHelpers.getHolder(RecipeManager, Supplier<RecipeType<R>>, C)`（`RecipeHelpers.java:157-169`）会遍历**该 recipe type 下的全部配方**，逐个调用 `IRecipePredicate.matches(input)`，返回**第一个匹配**的 `RecipeHolder`。
- 因此 `tfc:alloy` 的匹配是**顺序敏感的**：多个配方同时匹配时，只有 data pack 加载顺序中靠前的那个生效（原版 `RecipeManager` 按 id 排序）。

调用链（在源码里 grep `AlloyRecipe` 得到的全部非 JEI/EMI/Patchouli 调用点）：

| 相对源码路径 | 行 | 关键代码 | 说明 |
| --- | --- | --- | --- |
| `net/dries007/tfc/util/FluidAlloy.java` | 154-169 | `private FluidStack getResult(RecipeManager recipes)` → 第 160 行 `AlloyRecipe recipe = AlloyRecipe.get(recipes, this);` | **唯一的配方查询点**。`switch (this.content.size())`：0 → `Fluids.EMPTY`；1 → 直接返回该单一流体（**不查配方**）；≥2 → 查 `tfc:alloy`，查不到则返回 `TFCFluids.METALS.get(Metal.UNKNOWN)`（即 `tfc:metal/unknown`） |
| `net/dries007/tfc/common/blockentities/CrucibleBlockEntity.java` | 195-198 | `getAlloyResult()` → `alloy.getResult(this.level)` | 坩埚（`tfc:crucible`）界面/物流取产物 |
| `net/dries007/tfc/common/blockentities/CrucibleBlockEntity.java` | 256 | `FluidHeat.getOrUnknown(...getResult(this.level))` | 坩埚温度计算 |
| `net/dries007/tfc/common/blockentities/CrucibleBlockEntity.java` | 337、360 | `this.alloy.getResult(this.crucible.level)` | 坩埚内部合金成分同步/输出 |
| `net/dries007/tfc/common/component/mold/Vessel.java` | 82、106 | `this.vessel.fluidContent().getResult()` | 容器（vessel）内合金液体 |
| `net/dries007/tfc/common/component/mold/Vessel.java` | 212 | `FluidHeat.getOrUnknown(fluid.getResult())` | 容器热容计算 |
| `net/dries007/tfc/common/blockentities/MoldTableBlockEntity.java` | 138、142 | `FluidAlloy alloy = crucible.getAlloy(); ... alloy.getResult().getFluidType()` | 模具台从坩埚引流的流体判定 |
| `net/dries007/tfc/client/screen/CrucibleScreen.java` | 109 | `alloy = ((CrucibleBlockEntity)this.blockEntity).getAlloy()` | 客户端渲染（间接） |

**输入容器**：不是 `RecipeInput` 的实现，而是数据对象 `net.dries007.tfc.util.FluidAlloy`（`FluidAlloy.java:68`）。它自身实现了 `AlloyRecipe` 的匹配语义（`matches(AlloyRecipe)`，行 202-210），通过 `IRecipePredicate<FluidAlloy>` 反向调用。

**触发时机**：没有「做一次操作」的显式时机。`AlloyRecipe.get` 在**每次读取合金产物/成分时**（含 GUI 打开、坩埚被抽取流体、模具台引流判定）被惰性调用，结果缓存在 `FluidAlloy.cachedResult`（`FluidAlloy.java:155-168`），成分变化时由 `clearCaches()`（行 218-221）失效。

**JEI/EMI 侧**（仅用于配方展示，不参与逻辑）：`net/dries007/tfc/compat/jei/category/AlloyRecipeCategory.java`、`net/dries007/tfc/compat/emi/recipe/EmiAlloyingRecipe.java`、`net/dries007/tfc/compat/emi/EmiIntegration.java:222`-ish 的 `basicRecipeMapping(registry, TFCRecipeTypes.ALLOY, ...)`。

##### R-01.5 特殊辅助类

| 辅助类 | 是否用于本类型 | 说明 |
| --- | --- | --- |
| `net.dries007.tfc.util.AlloyRange` | ✅ 核心 | `contents` 的元素类型，见 R-01.2 |
| `net.dries007.tfc.util.FluidAlloy` | ✅ 核心 | 输入/匹配载体；自身有 NBT codec：`{"amount":int,"content":{<fluid id>: double}}`（`FluidAlloy.java:71`） |
| `ItemStackProvider` / `ItemStackModifier` | ❌ | `tfc:alloy` 产物是**流体**不是物品，因此不用 Provider 体系。相关说明见附录 A1-1 |
| `TFCIngredients` | ❌ | 配方不含 `Ingredient` 字段 |
| `PotOutput` | ❌ | 属于 pot 系配方（其它组） |

`tfc:metal/unknown`（`Metal.UNKNOWN`）是「无匹配合金」的兜底流体，见 `FluidAlloy.java:164`。

---

### [R-02] tfc:anvil —— 砧板锻造配方

##### R-02.1 类型标识与实现类

| 项目 | 值 | 证据 |
| --- | --- | --- |
| JSON `type` | `tfc:anvil` | `TFCRecipeSerializers.java:75` |
| recipe type id | `tfc:anvil` | `TFCRecipeTypes.java:59` |
| serializer id | `tfc:anvil` | `TFCRecipeSerializers.java:75` |
| 实现类全名 | `net.dries007.tfc.common.recipes.AnvilRecipe` | `AnvilRecipe.java:64` |
| 类型形态 | `class AnvilRecipe implements ISimpleRecipe<Inventory>`（**普通 class，非 record**） | `AnvilRecipe.java:64-65` |
| 内部输入接口 | `AnvilRecipe.Inventory extends RecipeInput`（`getItem()`/`getTier()`/`getSeed()`） | `AnvilRecipe.java:156-163` |
| `getType()` | `TFCRecipeTypes.ANVIL.get()` | `AnvilRecipe.java:139-141` |
| `getSerializer()` | `TFCRecipeSerializers.ANVIL.get()` | `AnvilRecipe.java:135-137` |

类内部还有两个静态缓存：

```java
// AnvilRecipe.java:66
private static final BiMap<ResourceLocation, AnvilRecipe> CACHE = IndirectHashCollection.createForRecipeId(TFCRecipeTypes.ANVIL);
```

该 `BiMap` 由 `IndirectHashCollection.reloadAllCaches(RecipeManager)` 在每次配方重载时填充（`net/dries007/tfc/util/collections/IndirectHashCollection.java:48-52, 121-133`），用于**按配方 id 反查配方**（客户端从物品 NBT 里的 recipe id 恢复锻造计划）。

**类型名与序列化名一致。**

##### R-02.2 完整字段表

`AnvilRecipe.CODEC`（`AnvilRecipe.java:67`，原文逐项拆解）：

```java
public static final MapCodec<AnvilRecipe> CODEC = RecordCodecBuilder.mapCodec(i -> i.group(
    Ingredient.CODEC.fieldOf("ingredient").forGetter(c -> c.input),
    Codec.INT.optionalFieldOf("tier", 0).forGetter(c -> c.minTier),
    ForgeRule.CODEC.listOf().fieldOf("rules")
            .validate(rules -> ForgeRule.isConsistent(rules)
                    ? DataResult.success(rules)
                    : DataResult.error(() -> "The rules " + rules + " cannot be satisfied by any combination of steps!"))
            .forGetter(c -> c.rules),
    Codec.BOOL.optionalFieldOf("apply_bonus", false).forGetter(c -> c.applyForgingBonus),
    ItemStackProvider.CODEC.fieldOf("result").forGetter(c -> c.output)
).apply(i, AnvilRecipe::new));
```

字段声明（`AnvilRecipe.java:69-73`）：

```java
private final Ingredient input;
private final int minTier;
private final List<ForgeRule> rules;
private final boolean applyForgingBonus;
private final ItemStackProvider output;
```

| 字段名 | 类型 | 必需/可选 | 默认值 | 语义 |
| --- | --- | --- | --- | --- |
| `type` | `String` | 必需 | 无 | 固定 `tfc:anvil` |
| `ingredient` | `Ingredient`（`Ingredient.CODEC`） | **必需** | 无 | 放在砧板主槽（槽 0）的输入物品。支持 `{"item":...}` / `{"tag":...}` / 数组 / NeoForge 自定义 ingredient（见附录 A1-3） |
| `tier` | `int`（`Codec.INT`） | 可选 | **`0`** | 最低砧板等级：`anvilTier >= tier` 才允许加工（`isCorrectTier`，行 118-120）。真实数据中显式取值 1~6，另有 28 个文件未写出（用默认 `0`） |
| `rules` | `List<ForgeRule>`（枚举，snake_case 字符串） | **必需** | 无 | 锻造步骤规则，**顺序即语义顺序**（列表第 1 项对应 `last`/`second_last`/`third_last` 中的位置由规则自身的 `Order` 决定）。受 `validate` 约束：必须 `ForgeRule.isConsistent(rules)` |
| `apply_bonus` | `boolean`（`Codec.BOOL`） | 可选 | **`false`** | 完成后是否按「工作精准度」计算并写入 `ForgingBonus`（`AnvilBlockEntity.java:279-286`） |
| `result` | `ItemStackProvider` | **必需** | 无 | 产物。**支持裸 ItemStack 简写**，也支持带 `modifiers` 的完整形式（见附录 A1-1） |

**`rules` 的取值与校验（关键）**

`ForgeRule` 是枚举，`CODEC = StringRepresentable.fromValues(ForgeRule::values)`（`net/dries007/tfc/common/component/forge/ForgeRule.java:240`），序列化名为 `name().toLowerCase(Locale.ROOT)`（行 63、185-187）。合法值共 30 个（行 30-59）：

| 步骤族 | 可用后缀 | 具体取值（JSON 字符串） |
| --- | --- | --- |
| HIT（轻击） | ANY / NOT_LAST / LAST / SECOND_LAST / THIRD_LAST | `hit_any` `hit_not_last` `hit_last` `hit_second_last` `hit_third_last` |
| DRAW（拉长） | 同上 5 种 | `draw_any` `draw_not_last` `draw_last` `draw_second_last` `draw_third_last` |
| PUNCH（冲压） | 同上 5 种 | `punch_any` `punch_not_last` `punch_last` `punch_second_last` `punch_third_last` |
| BEND（弯曲） | 同上 5 种 | `bend_any` `bend_not_last` `bend_last` `bend_second_last` `bend_third_last` |
| UPSET（镦粗） | 同上 5 种 | `upset_any` `upset_not_last` `upset_last` `upset_second_last` `upset_third_last` |
| SHRINK（收缩） | 同上 5 种 | `shrink_any` `shrink_not_last` `shrink_last` `shrink_second_last` `shrink_third_last` |

`ForgeRule.isConsistent(List<ForgeRule>)`（`ForgeRule.java:80-123`）的判定要点：

1. `rules.isEmpty() || rules.size() > 3` → 直接 **false**（即 `rules` 长度必须是 **1~3**）。
2. 同一规则重复出现会被 `continue` 跳过（不报错）。
3. 每个「位置」（`LAST`/`SECOND_LAST`/`THIRD_LAST`）最多一条规则；`NOT_LAST` 可最多两条（`notLast1`/`notLast2`）。
4. `conflict3(...)`（行 125-127）额外阻止三类互相矛盾的组合：当三个位置都已被占满时，要求存在两条规则**步骤类型相同**，否则视为不可满足。

失败时的错误信息为：`"The rules " + rules + " cannot be satisfied by any combination of steps!"`（行 67 内的 lambda）。**这是一条 `Codec.validate`，即数据包加载阶段就会报错并拒绝该配方。**

`ForgeRule.matches(...)`（行 201-231）定义了运行时判定：`hit_*` 规则把 `HIT_LIGHT`/`HIT_MEDIUM`/`HIT_HARD` 都视作命中（行 226-231），其它步骤族要求严格相等。

**目标工作值与判定公式**

```java
// AnvilRecipe.java:147-149
public int computeTarget(Inventory inventory) {
    return 40 + new XoroshiroRandomSource(inventory.getSeed()).forkPositional()
                  .fromHashOf(BuiltInRegistries.ITEM.getKey(this.output.stack().getItem())).nextInt(74);
}
```

- `inventory.getSeed()` 是**世界种子**（`AnvilBlockEntity.AnvilInventory#getSeed`，`AnvilBlockEntity.java:473-485` 返回 `ServerLevel.getSeed()`，客户端返回 `0L`）。
- 目标值 = `40 + [0,73]` → **40~113**。
- 完成判定 `checkComplete`（行 105-108）= `forging.matches(rules)` **且** `work ∈ [target - leeway, target + leeway]`；`leeway = TFCConfig.SERVER.anvilAcceptableWorkRange.get()`（行 151-154）。
- `work` 超出 `0..150` 会**摧毁物品**（`AnvilBlockEntity.java:267-271`）。

**JSON codec 与网络 codec 差异**

| 项目 | JSON（`CODEC`，行 67） | 网络（`STREAM_CODEC`，行 68） | 差异说明 |
| --- | --- | --- | --- |
| `ingredient` | `Ingredient.CODEC`（可含 count 之外的全部形式） | `Ingredient.CONTENTS_STREAM_CODEC` | 网络侧按内容流式传输 |
| `tier` | `Codec.INT` | `ByteBufCodecs.VAR_INT` | 表示法不同，语义一致 |
| `rules` | `listOf()`，**JSON 侧无长度上限**（由 `validate` 限制 ≤3） | `ForgeRule.STREAM_CODEC.apply(ByteBufCodecs.list(3))`，**网络侧硬上限 3** | 有差异：网络 codec 显式限长 3，JSON 侧靠 `validate` |
| `apply_bonus` | `Codec.BOOL` | `ByteBufCodecs.BOOL` | 一致 |
| `result` | `ItemStackProvider.CODEC` | `ItemStackProvider.STREAM_CODEC` | 一致（`STREAM_CODEC` 用 `ItemStack.OPTIONAL_STREAM_CODEC`，见 A1-1） |

##### R-02.3 真实 JSON 样例

`data/tfc/recipe/anvil/` 下共 **281 个** JSON（含 `metal/` 子目录，其中 `metal/` 下 271 个）。给出 3 个样例，覆盖「默认 tier / 显式 tier / 显式 tier + apply_bonus」三种写法：

样例 1：`data/tfc/recipe/anvil/blowpipe.json`（**不使用任何可选字段**，`tier` 与 `apply_bonus` 均走默认）

```json
{"type":"tfc:anvil","ingredient":{"tag":"c:rods/brass"},"result":{"count":1,"id":"tfc:blowpipe"},"rules":["draw_last","draw_second_last","hit_third_last"]}
```

样例 2：`data/tfc/recipe/anvil/minecart_steel.json`（**使用可选字段 `tier`**，并展示 `rules` 中重复的 `hit_not_last`）

```json
{"type":"tfc:anvil","ingredient":{"tag":"c:sheets/steel"},"result":{"count":1,"id":"minecraft:minecart"},"rules":["hit_not_last","hit_not_last","bend_last"],"tier":3}
```

样例 3：`data/tfc/recipe/anvil/metal/axe_head/bismuth_bronze.json`（**`apply_bonus` + `tier` 同时出现**，`result` 为裸 ItemStack 简写形式）

```json
{"type":"tfc:anvil","apply_bonus":true,"ingredient":{"tag":"c:ingots/bismuth_bronze"},"result":{"count":1,"id":"tfc:metal/axe_head/bismuth_bronze"},"rules":["punch_last","hit_second_last","upset_third_last"],"tier":2}
```

补充 1 个「非金属/高等级」样例：`data/tfc/recipe/anvil/refined_iron_bloom.json`

```json
{"type":"tfc:anvil","ingredient":{"item":"tfc:raw_iron_bloom"},"result":{"count":1,"id":"tfc:refined_iron_bloom"},"rules":["hit_last","hit_second_last","hit_third_last"],"tier":2}
```

真实数据统计（本次全量扫描 `data/tfc/recipe/anvil/**.json`）：

| 观察项 | 结果 |
| --- | --- |
| `tier` 取值分布（281 个全部解析后统计） | `2` → 83；`6` → 56；`3` → 31；`1` → 28；`4` → 28；`5` → 27；**未写出 → 28**（这 28 个使用默认值 `0`，即"任何砧板都可加工"） |
| `type` 字段 | 281 个文件全部为 `tfc:anvil`（无混入其它类型） |
| `apply_bonus` 取值分布 | `true` → **171**；其余 **110 个未写出**（默认 `false`）。写 `true` 的集中在 `metal/**/*_head/*.json`、`metal/unfinished_*/*.json`、`metal/shield/*.json`、`metal/fish_hook/*.json`、`metal/scythe_blade/*.json` 等工具/护甲部件 |
| **未写出 `tier` 的 28 个文件** | `blowpipe.json`、`brass_mechanisms.json`、`jar_lid.json`；`metal/ingot/{black_steel,blue_steel,high_carbon_steel,red_steel,steel}.json`；`metal/rod/*`（bismuth/brass/cast_iron/gold/nickel/rose_gold/silver/sterling_silver/tin/zinc，共 10 个）；`metal/sheet/*`（同一组 10 个软金属）。这些配方的 `tier` 为默认 `0` |
| `modifiers` | **anvil 目录下没有任何配方使用 `result.modifiers`**（全部是裸 ItemStack 简写）；`modifiers` 的真实用例集中在 `barrel/`、`crafting/`、`heating/` 目录 |

##### R-02.4 游戏内触发条件

`AnvilRecipe` 有 5 个静态入口：

| 方法 | 位置 | 语义 |
| --- | --- | --- |
| `hasAny(Level, ItemStack, int tier)` | `AnvilRecipe.java:75-77` | 是否存在可加工该物品的配方（用于 UI 判断"这个物品能不能打"） |
| `getAll(Level, ItemStack, int tier)` | `AnvilRecipe.java:79-81` | 返回全部候选配方（`input.test(stack) && tier >= minTier`） |
| `byId(ResourceLocation)` | `AnvilRecipe.java:83-86` | 从 `CACHE`（BiMap）按 id 反查 |
| `getId(AnvilRecipe)` | `AnvilRecipe.java:88-91` | 反向查 id（JEI 拖拽用） |
| `matches(Inventory, Level)` | `AnvilRecipe.java:101-103` | 实例方法：`input.test(inventory.getItem()) && isCorrectTier(inventory.getTier())` |

调用点（grep `AnvilRecipe` 全量结果，按目录归类）：

| 相对源码路径 | 行 | 关键代码 | 说明 |
| --- | --- | --- | --- |
| `net/dries007/tfc/common/blockentities/AnvilBlockEntity.java` | 198-212 | `setAndUpdateSlots(int slot)` → 204 `List<RecipeHolder<AnvilRecipe>> all = AnvilRecipe.getAll(this.level, stack, this.getTier());`；206/208 `forge.setRecipe(...)` | **配方"选定"时机**：放入物品时，若只有 1 个候选则自动选中；否则若 `lastRecipe`（方块实体 NBT `lastRecipe`，行 182-195）匹配则恢复 |
| `net/dries007/tfc/common/blockentities/AnvilBlockEntity.java` | 220-228 | `chooseRecipe(ResourceLocation recipeId)` → 222 `AnvilRecipe.byId(recipeId)` → 225 `setRecipe(new RecipeHolder<>(recipeId, recipe), inventory)` | 玩家在"砧板计划"界面选中配方（网络包驱动） |
| `net/dries007/tfc/common/blockentities/AnvilBlockEntity.java` | 254-290 | `work(ServerPlayer, ForgeStep)`：256 `recipe.matches((AnvilRecipe.Inventory)this.inventory, this.level)`；273 `recipe.checkComplete(...)`；274 `recipe.assemble(...)`；279-282 `recipe.shouldApplyForgingBonus()` + `ForgingBonus.byRatio(ratio)` | **主要加工路径**（玩家手动锤击）。`ratio = totalWorked / ForgeRule.calculateOptimalStepsToTarget(recipe.computeTarget(inventory), recipe.getRules())` |
| `net/dries007/tfc/common/blockentities/AnvilBlockEntity.java` | 293-340 | `workRemotely(ForgeStep, int movement, boolean forceCompletion)`：305 `recipe.matches(...)`；313 `recipe.computeTarget(...)`；329 `recipe.checkComplete(...)`；330 `recipe.assemble(...)` | 自动化路径（例如 `TripHammerBlockEntity.java:77` 调用 `anvil.workRemotely(ForgeStep.HIT_LIGHT, 12, true)`） |
| `net/dries007/tfc/common/blockentities/AnvilBlockEntity.java` | 441-493 | `static class AnvilInventory extends InventoryItemHandler implements AnvilRecipe.Inventory, WeldingRecipe.Inventory, NonEmptyInput` | **输入容器实现**。4 个槽：0=主物品（`getItem()`/`getMain()`）、1=副物品（`getSecondary()`）、2=锤子、3=助焊剂。`getTier()` 委托方块（行 422-432，读 `Tiered` 方块接口）；`getSeed()` 返回世界种子（行 473-485） |
| `net/dries007/tfc/common/container/AnvilContainer.java` | 64 | `AnvilRecipe.hasAny(level, stack, ((AnvilBlockEntity)this.blockEntity).getTier())` | 打开砧板界面时判断是否可加工，用于同步到客户端（`AnvilPlanButton` 的启用状态） |
| `net/dries007/tfc/common/container/AnvilPlanContainer.java` | 45 | `((AnvilBlockEntity)this.blockEntity).chooseRecipe(recipeId)` | 计划界面的选择回调 |
| `net/dries007/tfc/network/SelectAnvilPlanPacket.java` | 40 | `((AnvilBlockEntity)anvilContainer.getBlockEntity()).chooseRecipe(this.recipeId)` | 客户端 → 服务端的选择包 |
| `net/dries007/tfc/common/component/forge/ForgingComponent.java` | 44、50、59-70 | 字段 `private AnvilRecipe recipe;`；`getRecipe()` 内 61 `this.recipe = AnvilRecipe.byId(this.recipeId);` | **物品组件侧缓存**：锻造进度（`Forging` 组件）只存 `recipeId`，读取时通过 `CACHE` 反查 |
| `net/dries007/tfc/common/component/forge/Forging.java` | 28-37 | `setRecipe(RecipeHolder<AnvilRecipe>, AnvilRecipe.Inventory)` / `setRecipe(..., int target)` / `getRecipe()` | `target` 由 `recipe.computeTarget(inventory)` 计算后一并写入组件 |
| `net/dries007/tfc/common/blocks/devices/AnvilBlock.java` | 104 | `InteractionResult weld = anvil.weld(player);` | 右键触发（焊接路径，见 R-03） |
| 客户端 | `net/dries007/tfc/client/screen/AnvilPlanScreen.java:61` | `AnvilRecipe.getAll(this.playerInventory.player.level(), inputStack, ((AnvilBlockEntity)this.blockEntity).getTier())` | 「计划」界面列出全部可用配方 |
| 客户端 | `net/dries007/tfc/client/screen/AnvilPlanSelectButton.java:43,53` | 构造 `RecipeHolder<AnvilRecipe>`，`recipe.value().getResultItem(...)` | 配方按钮渲染 |
| 客户端 | `net/dries007/tfc/client/screen/button/AnvilPlanButton.java:48,55,62` | `AnvilRecipe.hasAny(this.anvil.getLevel(), inv.getStackInSlot(0), this.anvil.getTier())` | 界面按钮可用性 |
| 客户端 | `net/dries007/tfc/client/screen/AnvilScreen.java:69,111` | `AnvilRecipe recipe = forging.getRecipe();` | 绘制目标值与当前进度 |
| 兼容层 | `net/dries007/tfc/compat/patchouli/component/AnvilComponent.java:19-31` | `extends InputOutputComponent<AnvilRecipe>` | Patchouli 手册渲染 |
| 兼容层 | `net/dries007/tfc/compat/jei/transfer/AnvilRecipeTransferInfo.java:40-45`、`AnvilRecipeTransferHandler.java:45-50` | `recipe.isCorrectTier(...)`；`AnvilRecipe.getId(recipe)` | JEI 一键摆放（用 `getId` 把配方 id 通过自定义包发给服务端） |
| 兼容层 | `net/dries007/tfc/compat/jei/category/AnvilRecipeCategory.java:51-62`、`net/dries007/tfc/compat/emi/recipe/EmiAnvilRecipe.java:36-56` | 渲染规则图标 | 仅展示 |

**输入容器综述**：`AnvilBlockEntity.AnvilInventory`（`AnvilBlockEntity.java:441`），实现 `AnvilRecipe.Inventory`（= `RecipeInput` + `getItem()` + `getTier()` + `getSeed()`）。

**触发操作综述**：把可锻造物品（通常是加热后的金属锭/双锭/薄板）放入砧板主槽 → 系统在 `setAndUpdateSlots` 里选定一个 `AnvilRecipe`（或玩家在计划界面手动选）→ 玩家用锤子按 `rules` 规定的顺序与位置敲击 → `work(...)` 每次校验 `matches` 并在 `checkComplete` 成立时 `assemble` 出产物。

##### R-02.5 特殊辅助类

| 辅助类 | 用法 |
| --- | --- |
| `net.dries007.tfc.common.recipes.outputs.ItemStackProvider` | `result` 字段类型。真实 anvil 数据只用裸 ItemStack 简写；理论上可写 `{"stack":{...},"modifiers":[...]}`，例如 `{"modifiers":[{"type":"tfc:copy_forging_bonus"}]}` 可把锻造加成写进产物（见附录 A1-1） |
| `net.dries007.tfc.common.component.forge.ForgeRule` | `rules` 元素类型；30 个枚举值 + `isConsistent` 校验 |
| `net.dries007.tfc.common.component.forge.ForgingBonus` / `ForgingBonusComponent` | `apply_bonus=true` 时由 `AnvilBlockEntity.java:279-286` 写入产物 |
| `net.dries007.tfc.config.TFCConfig.SERVER.anvilAcceptableWorkRange` | 目标值容差（`AnvilRecipe.java:152`） |
| `TFCIngredients` | `ingredient` 可用 TFC 自定义 ingredient，例如 `{"type":"tfc:heat","min":1000}`（见附录 A1-3） |

---

### [R-03] tfc:welding —— 砧板焊接配方

##### R-03.1 类型标识与实现类

| 项目 | 值 | 证据 |
| --- | --- | --- |
| JSON `type` | `tfc:welding` | `TFCRecipeSerializers.java:76` |
| recipe type id | `tfc:welding` | `TFCRecipeTypes.java:60` |
| serializer id | `tfc:welding` | `TFCRecipeSerializers.java:76`（`register("welding", WeldingRecipe.CODEC, WeldingRecipe.STREAM_CODEC)`） |
| 实现类全名 | `net.dries007.tfc.common.recipes.WeldingRecipe` | `WeldingRecipe.java:52` |
| 类型形态 | `class WeldingRecipe implements INoopInputRecipe, IRecipePredicate<Inventory>`（**普通 class**） | `WeldingRecipe.java:52-54` |
| 内部输入接口 | `WeldingRecipe.Inventory extends RecipeInput`（`getMain()`/`getSecondary()`/`getTier()`） | `WeldingRecipe.java:138-145` |
| `getType()` | `TFCRecipeTypes.WELDING.get()` | `WeldingRecipe.java:107-109` |
| `getSerializer()` | `TFCRecipeSerializers.WELDING.get()` | `WeldingRecipe.java:103-105` |

**类型名与序列化名一致。** 注意与 R-02 的一个重要区别：`WeldingRecipe` **没有** `byId`/`getAll` 之类的静态缓存帮助方法，它只有唯一的查询方式 `RecipeHelpers.getHolder(level, TFCRecipeTypes.WELDING, inventory)`（在 `AnvilBlockEntity` 内直接调用，见 R-03.4）。

##### R-03.2 完整字段表

`WeldingRecipe.CODEC`（`WeldingRecipe.java:55`，原文逐项拆解）：

```java
public static final MapCodec<WeldingRecipe> CODEC = RecordCodecBuilder.mapCodec(i -> i.group(
    Ingredient.CODEC.fieldOf("first_input").forGetter(c -> c.firstInput),
    Ingredient.CODEC.fieldOf("second_input").forGetter(c -> c.secondInput),
    Codec.INT.optionalFieldOf("tier", 0).forGetter(c -> c.tier),
    ItemStackProvider.CODEC.fieldOf("result").forGetter(c -> c.output),
    Behavior.CODEC.optionalFieldOf("bonus", Behavior.IGNORE).forGetter(c -> c.bonus)
).apply(i, WeldingRecipe::new));
```

字段声明（`WeldingRecipe.java:57-61`）：

```java
private final Ingredient firstInput;
private final Ingredient secondInput;
private final int tier;
private final ItemStackProvider output;
private final Behavior bonus;
```

| 字段名 | 类型 | 必需/可选 | 默认值 | 语义 |
| --- | --- | --- | --- | --- |
| `type` | `String` | 必需 | 无 | 固定 `tfc:welding` |
| `first_input` | `Ingredient` | **必需** | 无 | 焊接左侧输入（砧板槽 0，`AnvilInventory#getMain`） |
| `second_input` | `Ingredient` | **必需** | 无 | 焊接右侧输入（砧板槽 1，`AnvilInventory#getSecondary`） |
| `tier` | `int` | 可选 | **`0`** | 最低砧板等级，判定 `anvilTier >= tier`（`isCorrectTier`，行 71-73）。真实数据出现 **`-1`**（见 R-03.3） |
| `result` | `ItemStackProvider` | **必需** | 无 | 焊接产物（支持裸 ItemStack 简写与 `modifiers` 完整形式） |
| `bonus` | `String` 枚举：`copy_best` / `copy_worst` / `ignore` | 可选 | **`ignore`** | 是否把两个输入之一的 `ForgingBonus`（锻造加成：`tfc:forging_bonus` 组件）继承到产物上 |

**`bonus` 的取值与语义（关键）**

枚举定义在 `WeldingRecipe.Behavior`（`WeldingRecipe.java:119-136`）：

```java
public static enum Behavior implements StringRepresentable {
    COPY_BEST, COPY_WORST, IGNORE;
    public static final Codec<Behavior> CODEC = StringRepresentable.fromEnum(Behavior::values);
    public static final StreamCodec<ByteBuf, Behavior> STREAM_CODEC = StreamCodecs.forEnum(Behavior::values);
    public String getSerializedName() { return this.name().toLowerCase(Locale.ROOT); }
}
```

- JSON 合法值：`"copy_best"`、`"copy_worst"`、`"ignore"`。
- 运行时逻辑在 `assemble(Inventory)`（`WeldingRecipe.java:86-96`）：

```java
ItemStack stack = this.output.getSingleStack(input.getMain());
if (this.bonus != Behavior.IGNORE) {
    ForgingBonus left  = ForgingBonusComponent.get(input.getMain());
    ForgingBonus right = ForgingBonusComponent.get(input.getSecondary());
    boolean leftIsHigher = left.ordinal() > right.ordinal();
    boolean copyHigher = this.bonus == Behavior.COPY_BEST;
    ForgingBonusComponent.copy(leftIsHigher == copyHigher ? input.getMain() : input.getSecondary(), stack);
}
return stack;
```

  即：`COPY_BEST` 取二者中 `ordinal()` 较大（更好）的加成；`COPY_WORST` 取较小（更差）的；`IGNORE` 不复制。复制方向由 `ForgingBonusComponent.copy(源, 产物)` 完成。

**匹配语义（顺序无关）**

```java
// WeldingRecipe.java:79-84
public boolean matches(Inventory input) {
    ItemStack left  = input.getMain();
    ItemStack right = input.getSecondary();
    return this.firstInput.test(left)  && this.secondInput.test(right)
        || this.firstInput.test(right) && this.secondInput.test(left);
}
```

结论：`first_input` 与 `second_input` **可以交换位置**，两个槽位对称。若两者 `Ingredient` 相同（绝大多数样例如此），则该条件恒等成立的那一侧即可。

**产物体积语义**

`assemble` 使用 `output.getSingleStack(input.getMain())`（行 87）：先 `copyWithCount(1)` 再走 `ItemStackProvider.getStack`。而 `ItemStackProvider.getStack` 中产物数量 = `stack.count × input.count`（`outputs/ItemStackProvider.java:92-101`），因为输入被规范化为 1 个，所以焊接产物**恒为 `result` 里写的数量**，不会因堆叠输入而倍增。

**JSON codec 与网络 codec 差异**

| 项目 | JSON（`CODEC`，行 55） | 网络（`STREAM_CODEC`，行 56） | 差异说明 |
| --- | --- | --- | --- |
| `first_input` / `second_input` | `Ingredient.CODEC`（对象形式） | `Ingredient.CONTENTS_STREAM_CODEC`（流式） | 表示法不同 |
| `tier` | `Codec.INT` | `ByteBufCodecs.VAR_INT` | 表示法不同 |
| `result` | `ItemStackProvider.CODEC` | `ItemStackProvider.STREAM_CODEC` | 一致 |
| `bonus` | `Behavior.CODEC`（`StringRepresentable.fromEnum`） | `Behavior.STREAM_CODEC`（`StreamCodecs.forEnum`） | 表示法不同，语义一致 |
| 额外校验 | **无任何 `validate` / `flatXmap`** | 无 | 与 `tfc:anvil` 不同，焊接没有类似 `isConsistent` 的规则校验 |

不存在「JSON 与网络 codec 校验强度不一致」的问题：两者都无额外校验。

##### R-03.3 真实 JSON 样例

`data/tfc/recipe/welding/` 下共 **87 个** JSON。给出 3 个样例：

样例 1：`data/tfc/recipe/welding/jacks.json`（**最简形式**，`tier`/`bonus` 均走默认，两个输入相同）

```json
{"type":"tfc:welding","first_input":{"tag":"c:rods/brass"},"result":{"count":1,"id":"tfc:jacks"},"second_input":{"tag":"c:rods/brass"}}
```

样例 2：`data/tfc/recipe/welding/metal/boots/copper.json`（**使用可选字段 `bonus`**）

```json
{"type":"tfc:welding","bonus":"copy_best","first_input":{"item":"tfc:metal/unfinished_boots/copper"},"result":{"count":1,"id":"tfc:metal/boots/copper"},"second_input":{"tag":"c:sheets/copper"}}
```

样例 3：`data/tfc/recipe/welding/metal/ingot/high_carbon_black_steel.json`（**使用可选字段 `tier`，且取值为 `-1`**）

```json
{"type":"tfc:welding","first_input":{"tag":"c:ingots/weak_steel"},"result":{"count":1,"id":"tfc:metal/ingot/high_carbon_black_steel"},"second_input":{"tag":"c:ingots/pig_iron"},"tier":-1}
```

真实数据统计（本次全量扫描 `data/tfc/recipe/welding/**.json`）：

| 观察项 | 结果 |
| --- | --- |
| `tier` 取值分布（87 个全部解析后统计） | `-1` → 23；`1` → 21；`5` → 14；`2` → 7；`3` → 7；`4` → 7；**未写出 → 8**（使用默认值 `0`） |
| `bonus` 取值分布 | `"copy_best"` → 36；`"copy_worst"` → 9；**未写出 → 42**（使用默认值 `ignore`） |
| `modifiers` | welding 目录下**没有任何配方使用 `result.modifiers`** |

**关于 `tier: -1` 的解读（经逐个文件核对）**：`isCorrectTier(anvilTier)`（行 71-73）判定 `anvilTier >= this.tier`。砧板等级来自方块（`AnvilBlockEntity#getTier`，行 422-432），最低为 0（非 `Tiered` 方块）或 `Tiered.getTier()`。因此 `tier = -1` 表示**任何砧板都满足**（无条件允许）。这 23 个文件为：

- `metal/double_ingot/{bismuth,brass,cast_iron,gold,nickel,rose_gold,silver,sterling_silver,tin,zinc}.json`（10 个）
- `metal/double_sheet/{bismuth,brass,cast_iron,gold,nickel,rose_gold,silver,sterling_silver,tin,zinc}.json`（10 个）
- `metal/ingot/{high_carbon_black_steel,high_carbon_blue_steel,high_carbon_red_steel}.json`（3 个）

即：**低熔点软金属的双锭/双薄板**以及**高碳合金锭的渗碳焊接**被设计为"任意砧板可焊"。

##### R-03.4 游戏内触发条件

`WeldingRecipe` **没有**自带 `get*` 静态方法，查询在调用点内联完成：

| 相对源码路径 | 行 | 关键代码 | 说明 |
| --- | --- | --- | --- |
| `net/dries007/tfc/common/blockentities/AnvilBlockEntity.java` | 355-391 | `weld(Player player)`，第 362 行：`WeldingRecipe recipe = RecipeHelpers.unbox(RecipeHelpers.getHolder(this.level, TFCRecipeTypes.WELDING, this.inventory));` | **主要触发路径**。之后依次校验：364 `!recipe.isCorrectTier(this.getTier())` → 提示 `tfc.tooltip.anvil_is_too_low_tier_to_weld`；368-373 两侧 `IHeat.canWeld()`；374-377 槽 3 必须有助焊剂；378 `recipe.assemble(inventory)`；380-382 写入槽 0、清空槽 1、助焊剂 -1 |
| `net/dries007/tfc/common/blockentities/AnvilBlockEntity.java` | 397-420 | `getWeldStatus()`，第 404 行同样的 `getHolder(...)` | UI 状态判定，返回 `WeldStatus` 枚举（行 495-504：`PROBLEM_TIER`/`PROBLEM_HEAT`/`PROBLEM_FLUX`/`PROBLEM_HAMMER`/`PROBLEM_INGOTS`/`PROBLEM_UNKNOWN`/`WELDABLE`） |
| `net/dries007/tfc/common/blocks/devices/AnvilBlock.java` | 104 | `InteractionResult weld = anvil.weld(player);` | **方块交互入口**：对砧板右键触发焊接 |
| `net/dries007/tfc/common/container/AnvilContainer.java` | 73 | `anvil.weld(this.player)` | 容器界面内的焊接按钮（要求槽 2 或手上持锤） |
| `net/dries007/tfc/common/blockentities/AnvilBlockEntity.java` | 441-493 | `AnvilInventory implements AnvilRecipe.Inventory, WeldingRecipe.Inventory, NonEmptyInput` | **输入容器**：同一 `AnvilInventory` 同时实现两个配方的输入接口，因此 `RecipeHelpers.getHolder(level, TFCRecipeTypes.WELDING, this.inventory)` 直接传它。槽位映射：`getMain()`=槽 0，`getSecondary()`=槽 1，`getTier()`=方块等级 |
| 兼容层 | `net/dries007/tfc/compat/jei/transfer/WeldingRecipeTransferInfo.java:40-45` | `recipe.isCorrectTier(((AnvilBlockEntity)container.getBlockEntity()).getTier())` | JEI 拖拽校验 |
| 兼容层 | `net/dries007/tfc/compat/patchouli/component/WeldingComponent.java:28-35` | `renderIngredient(...getFirstInput()/getSecondInput())`、`getResultItem(null)` | Patchouli 手册 |
| 兼容层 | `net/dries007/tfc/compat/jei/category/WeldingRecipeCategory.java:49-57`、`net/dries007/tfc/compat/emi/recipe/EmiWeldingRecipe.java:37-59` | 渲染 | 仅展示 |

**输入容器**：`AnvilBlockEntity.AnvilInventory`（`AnvilBlockEntity.java:441`）。
**触发操作**：把两个可焊接物品放入砧板槽 0/1（典型场景：双锭、胸甲部件 + 薄板），槽 3 放助焊剂，对砧板右键（或用界面按钮）。`RecipeHelpers.getHolder` 遍历 `tfc:welding` 全部配方取**首个匹配**（`RecipeHelpers.java:162-169`），因此**配方顺序会影响多匹配时的结果**。

##### R-03.5 特殊辅助类

| 辅助类 | 用法 |
| --- | --- |
| `net.dries007.tfc.common.recipes.outputs.ItemStackProvider` | `result` 字段类型（见附录 A1-1） |
| `net.dries007.tfc.common.component.forge.ForgingBonus` / `ForgingBonusComponent` | `bonus` 字段的运行时依赖（`ForgingBonusComponent.copy`） |
| `net.dries007.tfc.common.component.heat.HeatCapability` / `IHeat` | 焊接的**前置条件**（不是 JSON 字段）：两侧物品温度必须满足 `canWeld()`，且产物会继承较高温度（`AnvilBlockEntity.java:368-373, 378-386`） |
| `net.dries007.tfc.common.fluids` / 助焊剂 | 槽 3 必须非空（`AnvilBlockEntity.java:374-377`），也不是 JSON 字段 |

---

### [R-04] tfc:casting —— 模具浇铸配方

##### R-04.1 类型标识与实现类

| 项目 | 值 | 证据 |
| --- | --- | --- |
| JSON `type` | `tfc:casting` | `TFCRecipeSerializers.java:69` |
| recipe type id | `tfc:casting` | `TFCRecipeTypes.java:53` |
| serializer id | `tfc:casting` | `TFCRecipeSerializers.java:69` |
| 实现类全名 | `net.dries007.tfc.common.recipes.CastingRecipe` | `CastingRecipe.java:51` |
| 类型形态 | `class CastingRecipe implements INoopInputRecipe, IRecipePredicate<IMold>`（**普通 class**） | `CastingRecipe.java:51-53` |
| 输入接口 | `net.dries007.tfc.common.component.mold.IMold`（**不是 `RecipeInput`**） | `CastingRecipe.java:53`；`IMold.java:21-23` |
| `getType()` | `TFCRecipeTypes.CASTING.get()` | `CastingRecipe.java:113-115` |
| `getSerializer()` | `TFCRecipeSerializers.CASTING.get()` | `CastingRecipe.java:109-111` |

类内还有按输入物品建立的间接索引缓存：

```java
// CastingRecipe.java:56
public static final IndirectHashCollection<Item, CastingRecipe> CACHE =
        IndirectHashCollection.createForRecipe(r -> RecipeHelpers.itemKeys(r.ingredient), TFCRecipeTypes.CASTING);
```

`RecipeHelpers.itemKeys(Ingredient)`（`RecipeHelpers.java:108-110`）会把 `ingredient.getItems()` 展开成 `Item` 集合，因此**每个模具物品**都能索引到所有接受它的配方。缓存由 `IndirectHashCollection.reloadAllCaches` 在配方重载时刷新（`IndirectHashCollection.java:42-46, 108-119`）。

**类型名与序列化名一致。**

##### R-04.2 完整字段表

`CastingRecipe.CODEC`（`CastingRecipe.java:54`，原文逐项拆解）：

```java
public static final MapCodec<CastingRecipe> CODEC = RecordCodecBuilder.mapCodec(i -> i.group(
    Ingredient.CODEC.fieldOf("mold").forGetter(c -> c.ingredient),
    SizedFluidIngredient.FLAT_CODEC.fieldOf("fluid").forGetter(c -> c.fluidIngredient),
    ItemStackProvider.CODEC.fieldOf("result").forGetter(c -> c.result),
    Codec.FLOAT.optionalFieldOf("break_chance", 1.0f).forGetter(c -> c.breakChance)
).apply(i, CastingRecipe::new));
```

字段声明（`CastingRecipe.java:57-60`）：

```java
private final Ingredient ingredient;
private final SizedFluidIngredient fluidIngredient;
private final ItemStackProvider result;
private final float breakChance;
```

| 字段名 | 类型 | 必需/可选 | 默认值 | 语义 |
| --- | --- | --- | --- | --- |
| `type` | `String` | 必需 | 无 | 固定 `tfc:casting` |
| `mold` | `Ingredient`（Java 字段名是 `ingredient`） | **必需** | 无 | 模具物品。真实数据全部为 `{"item":"tfc:ceramic/xxx_mold"}`（也可用 tag / 数组 / 自定义 ingredient） |
| `fluid` | `SizedFluidIngredient`（**`FLAT_CODEC`**） | **必需** | 无 | **带数量的**流体要求。JSON 形式：`{"amount":100,"fluid":"tfc:metal/copper"}` |
| `result` | `ItemStackProvider` | **必需** | 无 | 浇铸产物（真实数据全部为裸 ItemStack 简写） |
| `break_chance` | `float`（`Codec.FLOAT`） | 可选 | **`1.0f`** | 浇铸/取出时模具破碎概率。`1.0` 表示**必定破碎**（未写该字段的真实数据即如此） |

**`fluid` 为什么是 `FLAT_CODEC`（重要坑点）**

- NeoForge 的 `SizedFluidIngredient` 默认 `CODEC` 是 **dispatch 形式**（带 `"type"` 字段，例如 `{"type":"neoforge:tag","tag":...,"amount":100}`）。
- 本配方用的是 `SizedFluidIngredient.FLAT_CODEC`（`CastingRecipe.java:54`），它是 `MapCodec`，直接把 `amount` 与 `fluid` 作为**同级字段**写进配方对象：

```json
"fluid":{"amount":100,"fluid":"tfc:metal/copper"}
```

- 因此**不能**在 `tfc:casting` 里写 `{"type":"neoforge:tag",...}` 那种形式（会被 `FLAT_CODEC` 解析失败）。真实数据的写法完全统一：`amount` + `fluid` 两个键。
- `TFCIngredients.FLUID_CONTENT`（`net/dries007/tfc/common/recipes/ingredients/FluidContentIngredient.java:46`）也使用同一个 `SizedFluidIngredient.FLAT_CODEC.fieldOf("fluid")`，用法可类比。

**`break_chance` 的运行时语义（三处使用，写法不同但等价）**

1. `MoldItem.use`（`net/dries007/tfc/common/items/MoldItem.java:129`）：
   ```java
   if (player.getRandom().nextFloat() < recipe.getBreakChance()) { stack.shrink(1); /* 播放 tfc 陶瓷碎裂音 */ }
   ```
2. `MoldItem.overrideOtherStackedOnMe`（`MoldItem.java:167`）：同一判定。
3. `CastingCraftingRecipe.getRemainingItems`（`CastingCraftingRecipe.java:68`）：
   ```java
   ... || !(player.getRandom().nextFloat() > recipe.getBreakChance())) continue;
   // 等价于 nextFloat() <= breakChance 时破碎
   ```
   这里若破碎，会把模具物品作为"剩余物"放回合成格（行 69-70：`mold.drainIgnoringTemperature(...)` + `items.set(i, item.copy())`）。

真实数据中 `break_chance` 只出现两种取值：`0.1`（28 次，普通陶瓷模具）与 `0.01`（28 次，`fire_ingot_mold`）。**默认值 `1.0` 只在"未写出"时生效**，实际对应 `bell_mold`（钟模，一次性）——见 R-04.3。

**产物的温度继承**

```java
// CastingRecipe.java:79-86
public ItemStack assemble(IMold mold) {
    ItemStack stack = this.result.getSingleStack(mold.getContainer().copy());
    IHeat heat = HeatCapability.get(stack);
    if (heat != null) { heat.setTemperatureIfWarmer(mold.getTemperature()); }
    return stack;
}
```

即`result` 若是带热量的物品（如金属锭），温度会取"模具温度"与"产物当前温度"中较高者。注意 `mold.getContainer()` 来自 `IFluidHandlerItem#getContainer()`（`IMold extends IFluidHandlerItem`，`IMold.java:21-23`）。

**JSON codec 与网络 codec 差异**

| 项目 | JSON（`CODEC`，行 54） | 网络（`STREAM_CODEC`，行 55） | 差异说明 |
| --- | --- | --- | --- |
| `mold` | `Ingredient.CODEC` | `Ingredient.CONTENTS_STREAM_CODEC` | 表示法不同 |
| `fluid` | **`SizedFluidIngredient.FLAT_CODEC`（扁平 amount+fluid）** | **`SizedFluidIngredient.STREAM_CODEC`** | **有差异**：JSON 是扁平结构，网络是标准 stream（含 dispatch 信息），因此"JSON 与网络 codec 不是同一个编解码形态" |
| `result` | `ItemStackProvider.CODEC` | `ItemStackProvider.STREAM_CODEC` | 一致 |
| `break_chance` | `Codec.FLOAT` | `ByteBufCodecs.FLOAT` | 一致 |
| 额外校验 | 无 `validate` | 无 | 一致 |

##### R-04.3 真实 JSON 样例

`data/tfc/recipe/casting/` 下共 **111 个** JSON。给出 3 个样例，覆盖「显式 `break_chance` / 省略 `break_chance` / 非金属产物」：

样例 1：`data/tfc/recipe/casting/copper_ingot.json`（**显式 `break_chance: 0.1`**）

```json
{"type":"tfc:casting","break_chance":0.1,"fluid":{"amount":100,"fluid":"tfc:metal/copper"},"mold":{"item":"tfc:ceramic/ingot_mold"},"result":{"count":1,"id":"tfc:metal/ingot/copper"}}
```

样例 2：`data/tfc/recipe/casting/copper_axe_head.json`（**省略 `break_chance` → 取默认 `1.0`，即必定碎模**；用 `axe_head_mold`；`result` 指向工具头）

```json
{"type":"tfc:casting","fluid":{"amount":100,"fluid":"tfc:metal/copper"},"mold":{"item":"tfc:ceramic/axe_head_mold"},"result":{"count":1,"id":"tfc:metal/axe_head/copper"}}
```

样例 3：`data/tfc/recipe/casting/gold_bell.json`（**产物是原版物品 `minecraft:bell`**；`bell_mold` + 省略 `break_chance`）

```json
{"type":"tfc:casting","fluid":{"amount":100,"fluid":"tfc:metal/gold"},"mold":{"item":"tfc:ceramic/bell_mold"},"result":{"count":1,"id":"minecraft:bell"}}
```

补充：`data/tfc/recipe/casting/high_carbon_steel_fire_ingot.json`（`break_chance: 0.01` + `fire_ingot_mold`）

```json
{"type":"tfc:casting","break_chance":0.01,"fluid":{"amount":100,"fluid":"tfc:metal/high_carbon_steel"},"mold":{"item":"tfc:ceramic/fire_ingot_mold"},"result":{"count":1,"id":"tfc:metal/ingot/high_carbon_steel"}}
```

真实数据统计（本次全量扫描并用 JSON 解析器逐个统计 `data/tfc/recipe/casting/*.json`，共 111 个）：

| 观察项 | 结果 |
| --- | --- |
| `break_chance` 取值分布 | `0.1` → 28；`0.01` → 28；**未写出 → 55**（默认 `1.0`，即必定碎模） |
| `mold` 种类与数量 | `tfc:ceramic/fire_ingot_mold` → 28；`tfc:ceramic/ingot_mold` → 28；`tfc:ceramic/bell_mold` → 3；**13 种**工具头/刀刃模具各 4（`saw_blade`/`shovel_head`/`axe_head`/`chisel_head`/`sword_blade`/`mace_head`/`pickaxe_head`/`hoe_head`/`knife_blade`/`propick_head`/`scythe_blade`/`hammer_head`/`javelin_head`）。合计 28+28+3+52 = 111，与文件总数一致 |
| `fluid.amount` | `100` → 103 个；**`200` → 8 个**（仅 `mold` 为 `tfc:ceramic/mace_head_mold` 与 `tfc:ceramic/sword_blade_mold` 的 4 种金属：copper / bismuth_bronze / black_bronze / bronze） |
| `modifiers` | casting 目录下**没有任何配方使用 `result.modifiers`** |

`break_chance` 与模具的对应关系（由 111 个文件逐个解析后的交叉表验证，无例外）：

| 模具 | `break_chance` | 文件数 | 说明 |
| --- | --- | --- | --- |
| `tfc:ceramic/ingot_mold` | `0.1` | 28 | 普通锭模，10% 破碎 |
| `tfc:ceramic/fire_ingot_mold` | `0.01` | 28 | 耐火锭模，1% 破碎 |
| `tfc:ceramic/*_head_mold`、`*_blade_mold`（13 种） | 未写出 → `1.0` | 52 | 工具头/刀刃模具**必定破碎** |
| `tfc:ceramic/bell_mold` | 未写出 → `1.0` | 3 | 钟模**必定破碎** |

##### R-04.4 游戏内触发条件

`CastingRecipe` 的唯一静态入口：

```java
// CastingRecipe.java:62-65
public static CastingRecipe get(IMold mold) {
    return RecipeHelpers.getRecipe(CACHE, mold, mold.getContainer().getItem());
}
```

- `RecipeHelpers.getRecipe(IndirectHashCollection, C input, K key)`（`RecipeHelpers.java:134-136`）先用 `CACHE.getAll(key)` 取出候选集合（key = 模具物品），再用 `IRecipePredicate.matches(IMold)` 逐个匹配（行 139-141）。
- 实例匹配 `matches(IMold mold)`（`CastingRecipe.java:74-77`）：`ingredient.test(mold.getContainer()) && fluidIngredient.test(mold.getFluidInTank(0))`。即同时要求**模具物品匹配**且**内部流体（含数量）匹配**。

调用点（grep `CastingRecipe` 全量结果）：

| 相对源码路径 | 行 | 关键代码 | 说明 |
| --- | --- | --- | --- |
| `net/dries007/tfc/common/items/MoldItem.java` | 115-148 | `use(Level, Player, InteractionHand)`：117 `IMold mold = IMold.get(stack);`；120 `CastingRecipe recipe = CastingRecipe.get(mold);`；126 `recipe.assemble(mold)`；127 `mold.drainIgnoringTemperature(MAX_VALUE, EXECUTE)`；129 `player.getRandom().nextFloat() < recipe.getBreakChance()` | **手持模具 + Shift 右键**取件；碎裂时 `stack.shrink(1)` |
| `net/dries007/tfc/common/items/MoldItem.java` | 150-175 | `overrideOtherStackedOnMe(...)`：153 `CastingRecipe.get(mold)`；155 `recipe.assemble(mold)`；167 破碎判定 | **鼠标拖到模具上（SECONDARY）** 的取件路径（非创造模式、槽位可修改、且模具不处于熔融态） |
| `net/dries007/tfc/common/blockentities/MoldTableBlockEntity.java` | 98-134 | `serverTick(...)`：第 128 行 `(recipe = CastingRecipe.get(moldItem)) != null`；129 `recipe.assemble(moldItem)`；130 写入槽 1；131 排空模具 | **模具台方块（`tfc:mold_table`）**：温度足够后自动成型并输出到输出槽；前置条件 `!moldItem.isMolten()` |
| `net/dries007/tfc/common/blockentities/MoldTableBlockEntity.java` | 136-149 | `getFluidHandlerIfAppropriate(CrucibleBlockEntity, Optional<Fluid>)`：第 142 行 `alloy.getResult().getFluidType()` | 模具台从坩埚引流的流体类型判定（**这里会间接触发 R-01 的 `tfc:alloy` 查询**） |
| `net/dries007/tfc/client/render/blockentity/MoldBlockEntityRenderer.java` | 114-125 | `getMetalItemFromFluidStack(FluidStack)`：116-118 构造一个 `tfc:ceramic/fire_ingot_mold` 的假模具物品，令 `FluidComponent` 装 9999 mB 该流体，然后 `CastingRecipe.get(IMold.get(ingotMold))`；122 `castingRecipe.getResultItem()` | **客户端渲染**：反查"某流体对应的金属锭物品"，用于模具台渲染金属外观。这是一个"人造输入"的客户端侧调用 |
| `net/dries007/tfc/util/SelfTests.java` | 325、330 | `((CastingRecipe)holder.value()).getIngredient().getItems()` / `.getFluidIngredient().getFluids()` | 自检（开发期校验配方可解析） |
| `net/dries007/tfc/common/recipes/CastingCraftingRecipe.java` | 45、51、68 | 见 R-05 | 工作台浇铸（special recipe）复用 `CastingRecipe.get` |
| 兼容层 | `net/dries007/tfc/compat/jei/category/CastingRecipeCategory.java:63-80` | `recipe.getFluidIngredient()` / `recipe.getResultItem()` | JEI 展示 |
| 兼容层 | `net/dries007/tfc/compat/emi/recipe/EmiCastingRecipe.java:25-43`；`net/dries007/tfc/compat/emi/EmiIntegration.java:225` | `basicRecipeMapping(registry, TFCRecipeTypes.CASTING, EmiCastingRecipe::new)` | EMI 展示 |

**输入容器**：`net.dries007.tfc.common.component.mold.IMold`（`IMold.java:21-36`），由物品能力 `ItemCapabilities.MOLD` 提供（`IMold.get(ItemStack)`，行 24-27）。它同时是 `IFluidHandlerItem` 与 `IHeat`，因此 `CastingRecipe.matches` 能同时读「模具物品」与「内部流体数量」。
**触发操作**：
1. 手持装好熔融金属的模具，Shift + 右键（或把其他物品拖到模具上）→ 立即成型；
2. 把模具放到模具台（`tfc:mold_table`）上并等待温度下降 → 服务器 tick 自动成型；
3. 在工作台里（见 R-05）→ 作为合成结果取出。

##### R-04.5 特殊辅助类

| 辅助类 | 用法 |
| --- | --- |
| `net.dries007.tfc.common.component.mold.IMold` | 输入接口（`isMolten()` / `drainIgnoringTemperature` / `getContainer()` / `getFluidInTank(0)` / 继承 `IHeat.getTemperature()`） |
| `net.dries007.tfc.common.component.heat.HeatCapability` / `IHeat` | 产物温度继承（`CastingRecipe.java:81-84`） |
| `net.neoforged.neoforge.fluids.crafting.SizedFluidIngredient` | `fluid` 字段类型，用 `FLAT_CODEC`（JSON 扁平写法） |
| `net.dries007.tfc.common.recipes.outputs.ItemStackProvider` | `result` 字段类型（见附录 A1-1） |
| `net.dries007.tfc.common.component.fluid.FluidComponent` | 模具的流体存储组件（`MoldItem` 构造行 96；渲染代码行 117 直接 `set(TFCComponents.FLUID, ...)`） |
| `net.dries007.tfc.common.recipes.TFCRecipeTypes.CASTING` | `CACHE` 构建与 `getType()` 使用 |
| `TFCIngredients` | `mold` 可用自定义 ingredient（附录 A1-3） |

---

### [R-05] tfc:casting_crafting —— 工作台浇铸（special crafting 配方）

##### R-05.1 类型标识与实现类（本组最重要的一个"不一致"点）

| 项目 | 值 | 证据 |
| --- | --- | --- |
| JSON `type` | `tfc:casting_crafting` | `TFCRecipeSerializers.java:81` |
| **serializer id** | **`tfc:casting_crafting`** | `TFCRecipeSerializers.java:81`：`register("casting_crafting", new RecipeSerializerImpl<CastingCraftingRecipe>(CastingCraftingRecipe.INSTANCE))` |
| **recipe type id** | **无独立注册**；实际为原版 **`minecraft:crafting`**（`RecipeType.CRAFTING`） | 见下方"结论与证据链" |
| 实现类全名 | `net.dries007.tfc.common.recipes.CastingCraftingRecipe` | `CastingCraftingRecipe.java:35` |
| 类型形态 | `class CastingCraftingRecipe extends CustomRecipe`，无字段，构造器 `private`，通过静态单例 `INSTANCE` 使用 | `CastingCraftingRecipe.java:35-41` |
| `getSerializer()` | `TFCRecipeSerializers.CASTING_CRAFTING.get()` | `CastingCraftingRecipe.java:75-77` |
| 实际数据文件 | `data/tfc/recipe/crafting/casting.json`，内容：`{"type":"tfc:casting_crafting"}` | jar 内真实文件，已读取 |

###### 结论与证据链：它的 recipe type 是 `minecraft:crafting`

1. **TFC 没有为它注册 recipe type。** 逐行检查 `net/dries007/tfc/common/recipes/TFCRecipeTypes.java:44-63`，全部注册项为：
   `collapse, landslide, chisel, heating, quern, pot, scraping, knapping, alloy, casting, loom, barrel_sealed, barrel_instant, barrel_instant_fluid, bloomery, anvil, welding, blast_furnace, glassworking, sewing`。**其中没有 `casting_crafting`，也没有 `food_combining`。**
2. **TFC 也没有重写 `getType()`。** `CastingCraftingRecipe.java` 全文（95 行）只有 `matches` / `assemble` / `canCraftInDimensions` / `getRemainingItems` / `getSerializer` / `getMold`，**没有 `getType()`**；API 签名转储同样确认（`moddev/inventory/api-dump/TFC-public-api.txt`，`CastingCraftingRecipe` 段列出了 `matches`/`assemble`/`canCraftInDimensions`/`getRemainingItems`/`getSerializer` 及若干桥接方法，**不含 `getType`**）。
3. **父类 `CustomRecipe` 也没有 `getType()`。** 用 `javap -p` 读取 1.21.1 客户端字节码（`client-1.21.1-20240808.144430-srg.jar`）：
   ```
   public abstract class net.minecraft.world.item.crafting.CustomRecipe implements net.minecraft.world.item.crafting.CraftingRecipe {
     private final net.minecraft.world.item.crafting.CraftingBookCategory category;
     public net.minecraft.world.item.crafting.CustomRecipe(net.minecraft.world.item.crafting.CraftingBookCategory);
     public boolean isSpecial();
     public net.minecraft.world.item.ItemStack getResultItem(net.minecraft.core.HolderLookup$Provider);
     public net.minecraft.world.item.crafting.CraftingBookCategory category();
   }
   ```
   `getType` 不在其中。
4. **`getType()` 来自接口 `CraftingRecipe` 的 default 方法**，其字节码（`javap -c`）为：
   ```
   public default net.minecraft.world.item.crafting.RecipeType<?> getType();
     Code:
        0: getstatic  #17  // Field net/minecraft/world/item/crafting/RecipeType.CRAFTING
        3: areturn
   ```
   而 `RecipeType.CRAFTING` 的字段声明为 `public static final RecipeType<CraftingRecipe> CRAFTING;`。

**因此：`tfc:casting_crafting` 的 recipe type = `minecraft:crafting`（`RecipeType.CRAFTING`），serializer = `tfc:casting_crafting`。二者名称不一致，且这类配方不属于 `TFCRecipeTypes` 中任何一个自定义 type。**

**由此产生的实际后果（写数据时必踩的坑）**：

- 该配方在 `RecipeManager.byType(RecipeType.CRAFTING)` 的索引里，而不是任何 `tfc:*` 索引里。因此 `RecipeHelpers.getRecipes(level, TFCRecipeTypes.CASTING)` **不会**返回它，`CastingRecipe.CACHE` 也不包含它。
- 它的配方 **id 是 `tfc:casting`**（因为文件路径是 `data/tfc/recipe/crafting/casting.json` → id 为 `tfc:casting`）。**这与 `tfc:casting` recipe type 同名但含义不同**（id 属于 `Registries.RECIPE`，type 属于 `Registries.RECIPE_TYPE`，是两套注册表）。排查问题时不要混淆：`type` 字段是 `tfc:casting_crafting`，而 id 恰好叫 `tfc:casting`。
- 同一份数据里另有一个同构文件 `data/tfc/recipe/crafting/food_combining.json`，内容 `{"type":"tfc:food_combining"}`，其 serializer 同为 `RecipeSerializerImpl` 单例形式（`TFCRecipeSerializers.java:80`，`FoodCombiningCraftingRecipe.INSTANCE`），recipe type 同样继承为 `minecraft:crafting`。两个文件是同一设计模式的产物（special crafting recipe）。

##### R-05.2 完整字段表

本配方**没有任何可配置字段**。

```java
// net/dries007/tfc/common/recipes/RecipeSerializerImpl.java:19-24
public record RecipeSerializerImpl<R extends Recipe<?>>(MapCodec<R> codec, StreamCodec<RegistryFriendlyByteBuf, R> streamCodec)
        implements RecipeSerializer<R> {
    public RecipeSerializerImpl(R singleInstance) {
        this(MapCodec.unit(singleInstance), StreamCodec.unit(singleInstance));
    }
}
```

`TFCRecipeSerializers.java:81` 使用**单参构造**，即 `MapCodec.unit(INSTANCE)` + `StreamCodec.unit(INSTANCE)`：

| 字段名 | 类型 | 必需/可选 | 默认值 | 语义 |
| --- | --- | --- | --- | --- |
| `type` | `String` | 必需 | 无 | 固定 `tfc:casting_crafting`，由 serializer 分发 |
| （其它字段） | — | — | — | **没有任何其它字段**。`MapCodec.unit` 会忽略 JSON 中除 `type` 之外的所有键（不报错、不读取）；该行为已由 DFU 字节码验证，见下方补充说明 |

补充说明：

- **`MapCodec.unit` 忽略一切多余字段（已用字节码验证，非推断）**：`MapCodec.unit(A)` → `MapCodec.of(Encoder.empty(), Decoder.unit(() -> A))`；`Decoder.unit(Supplier)` 返回匿名类 `com.mojang.serialization.Decoder$5`，其 `decode(DynamicOps, MapLike)` 字节码为 `Supplier.get()` + `DataResult.success(...)` 后直接 `areturn`（**完全不读取传入的 `MapLike`**），且其 `keys(...)` 返回 `Stream.empty()`。证据命令：`javap -p -c -classpath libraries/com/mojang/datafixerupper/9.0.19/datafixerupper-9.0.19.jar 'com.mojang.serialization.Decoder$5'`。因此在 `{"type":"tfc:casting_crafting"}` 里额外写任何键都会被静默忽略（不会报"未知字段"错误）。
- 因为 `MapCodec.unit(singleInstance)` 返回的永远是同一个 `INSTANCE` 对象，该配方**没有实例状态**：`matches` 内部的判定完全由"输入 `CraftingInput` 里的模具物品 + 对应的 `CastingRecipe`"动态决定。
- `CastingCraftingRecipe` 的构造器是 `private`（`CastingCraftingRecipe.java:39-41`），并显式调用 `super(CraftingBookCategory.MISC)`，因此其 `category()` 返回 **`misc`**（这一项影响配方书分类/显示，不影响匹配）。
- **不存在** JSON codec 与网络 codec 的语义差异（两者都是 `unit`）。

##### R-05.3 真实 JSON 样例

该类型在 jar 内只有 **1 个**真实文件，全部内容如下。

文件相对路径（相对 `jar-extract/`）：`data/tfc/recipe/crafting/casting.json`

```json
{"type":"tfc:casting_crafting"}
```

对应的"孪生"文件（同模式，供对照）：`data/tfc/recipe/crafting/food_combining.json`

```json
{"type":"tfc:food_combining"}
```

说明：这个配方出现在 `jar-extract/data/tfc/recipe/crafting/` 目录下（该目录顶层共 158 个文件，绝大多数是 `minecraft:crafting_shaped` / `minecraft:crafting_shapeless` / `tfc:advanced_shaped_crafting` / `tfc:advanced_shapeless_crafting`），这正是它属于 `minecraft:crafting` 这一事实的旁证——但也**只是旁证**，真正的判定依据是 R-05.1 的字节码证据链（目录位置本身不影响 recipe type）。

##### R-05.4 游戏内触发条件

`CastingCraftingRecipe` 是 **special recipe**：它没有静态 `getRecipe` 之类查询入口，TFC 侧也没有任何显式调用点。它的执行完全由**原版合成台逻辑**驱动。

TFC 源码内的全部引用点（grep `CastingCraftingRecipe` 的完整结果）：

| 相对源码路径 | 行 | 关键代码 | 说明 |
| --- | --- | --- | --- |
| `net/dries007/tfc/common/recipes/CastingCraftingRecipe.java` | 37 | `public static final CastingCraftingRecipe INSTANCE = new CastingCraftingRecipe();` | 单例 |
| `net/dries007/tfc/common/recipes/TFCRecipeSerializers.java` | 81 | `register("casting_crafting", new RecipeSerializerImpl<CastingCraftingRecipe>(CastingCraftingRecipe.INSTANCE))` | **唯一的注册点**（无 recipe type 注册） |
| `net/dries007/tfc/common/recipes/CastingCraftingRecipe.java` | 43-46 | `matches(CraftingInput, Level)` → `getMold(input)`；`mold != null && !mold.isMolten() && CastingRecipe.get(mold) != null` | 由原版工作台在查找配方时调用 |
| `net/dries007/tfc/common/recipes/CastingCraftingRecipe.java` | 48-55 | `assemble(CraftingInput, HolderLookup.Provider)` → `CastingRecipe.get(mold).assemble(mold)` | 取出结果时调用 |
| `net/dries007/tfc/common/recipes/CastingCraftingRecipe.java` | 61-73 | `getRemainingItems(CraftingInput)`：68 行按 `recipe.getBreakChance()` 判定是否把模具作为剩余物放回 | 取出结果后调用 |
| `net/dries007/tfc/common/recipes/CastingCraftingRecipe.java` | 79-93 | `private IMold getMold(CraftingInput input)` | **输入扫描规则**：遍历合成格，**只允许恰好 1 个非空物品**；若该物品不是模具（`IMold.get(stack) == null`）或出现第 2 个非空物品则返回 `null`（不匹配） |

`getMold` 的精确语义（`CastingCraftingRecipe.java:79-93`）：

```java
private IMold getMold(CraftingInput input) {
    IMold mold = null;
    for (int i = 0; i < input.size(); ++i) {
        ItemStack stack = input.getItem(i);
        if (stack.isEmpty()) continue;
        if (mold == null) {
            mold = IMold.get(stack);
            if (mold != null) continue;
            return null;          // 第一个非空物品不是模具 → 失败
        }
        return null;              // 出现第二个非空物品 → 失败
    }
    return mold;                  // 可能是 null（全空）
}
```

- **输入容器**：`net.minecraft.world.item.crafting.CraftingInput`（原版工作台 3×3 输入；`canCraftInDimensions` 恒 `true`，行 57-59）。
- **触发操作**：把**一个装好熔融金属的模具**单独放在工作台合成格里（其余格留空），且模具处于**非熔融态**（`!mold.isMolten()`，即金属已冷却固化），随后从结果槽取出。此时原版 `CraftingMenu`/`RecipeManager` 会在 `RecipeType.CRAFTING` 的配方集合中匹配到本配方（`matches` 返回 true），并调用 `assemble` 产出与 `tfc:casting` 相同的物品。
- **破碎判定发生在 `getRemainingItems`**：若 `player.getRandom().nextFloat() <= breakChance`（`CastingCraftingRecipe.java:68`，同时要求能取到合成玩家 `RecipeHelpers.getCraftingPlayer()`，见 `RecipeHelpers.java:65-68`），则 `mold.drainIgnoringTemperature(MAX_VALUE, EXECUTE)` 并把模具原物品复制回该格（相当于"模具碎了一个、但留下一个空模具"），否则该格留空。
- 客户端/兼容层：本类型**没有**任何 JEI/EMI/Patchouli 专用展示代码（grep 结果为空），因为它不通过 `TFCRecipeTypes` 暴露。它是 special recipe：`CustomRecipe.isSpecial()` 的字节码为 `iconst_1; ireturn`（用 `javap -c` 读取 1.21.1 客户端 jar 确认，即恒返回 `true`），因此它不会作为普通合成配方出现在 JEI 的配方列表中（JEI 会跳过 special 配方）。

##### R-05.5 特殊辅助类

| 辅助类 | 用法 |
| --- | --- |
| `net.dries007.tfc.common.recipes.CastingRecipe` | **本配方完全依赖它**：`matches`/`assemble`/`getRemainingItems` 三处都先 `CastingRecipe.get(mold)` 再委托（见 R-04） |
| `net.dries007.tfc.common.component.mold.IMold` | 判定"物品是否为模具"的唯一手段（`IMold.get(stack)`，`IMold.java:24-27`） |
| `net.dries007.tfc.common.recipes.RecipeHelpers.getCraftingPlayer()` | 取当前合成玩家（`RecipeHelpers.java:65-68`，内部为 `CommonHooks.getCraftingPlayer()`），用于随机数 |
| `net.minecraft.world.item.crafting.CustomRecipe` / `CraftingInput` | 父类与原版输入容器 |
| `ItemStackProvider` / `ItemStackModifier` | **间接**使用：`CastingRecipe.result` 的 modifiers 会在 `assemble` 中生效 |
| `RecipeSerializerImpl` | 该配方 serializer 的实现方式（`MapCodec.unit` 单例），`RecipeSerializerImpl.java:19-24` |

---

### 附录 A1-1：`ItemStackProvider` 与 `ItemStackModifier`（R-02 / R-03 / R-04 的 `result` 字段体系）

本组 5 个配方中，`tfc:anvil`、`tfc:welding`、`tfc:casting` 三者都有 `result` 字段，类型均为 `net.dries007.tfc.common.recipes.outputs.ItemStackProvider`；`tfc:casting_crafting` 间接经由 `CastingRecipe` 使用同一体系。

##### A1-1.1 `ItemStackProvider` 的 JSON 两种形态

```java
// net/dries007/tfc/common/recipes/outputs/ItemStackProvider.java:34-36
public record ItemStackProvider(ItemStack stack, List<ItemStackModifier> modifiers) {
    public static final Codec<ItemStackProvider> CODEC = Codec.either(
        RecordCodecBuilder.create(i -> i.group(
            ItemStack.CODEC.optionalFieldOf("stack", ItemStack.EMPTY).forGetter(c -> c.stack),
            ItemStackModifier.CODEC.listOf().fieldOf("modifiers").forGetter(c -> c.modifiers)
        ).apply(i, ItemStackProvider::new)),
        ItemStack.CODEC
    ).xmap(e -> e.map(Function.identity(), ItemStackProvider::of),
           provider -> provider.modifiers.isEmpty() ? Either.right(provider.stack) : Either.left(provider));
```

| 形态 | JSON 写法 | 说明 |
| --- | --- | --- |
| 形态 1（裸 ItemStack 简写） | `{"id":"tfc:blowpipe","count":1}` | 由 `Codec.either` 的**第二个**分支 `ItemStack.CODEC` 解析 |
| 形态 2（完整对象） | `{"stack":{...},"modifiers":[{...}]}` | 由**第一个**分支解析；其中 `stack` **可选**（缺省 `ItemStack.EMPTY`，见 `optionalFieldOf("stack", ItemStack.EMPTY)`），`modifiers` **必填** |

关键行为：

1. **解码顺序**：`Codec.either` 先尝试形态 2。由于形态 2 要求存在 `modifiers` 字段，裸 ItemStack 会先失败并回落到形态 1；反之若写了 `modifiers`，则形态 1 不可能解析成功。
2. **`{"stack":{...}}` 单独出现是非法写法**：形态 2 因缺 `modifiers` 失败，形态 1 因缺 `id` 失败 → 整个 `result` 解析报错。
3. **编码（序列化）规则**：`provider.modifiers.isEmpty()` 时写回裸 ItemStack，否则写完整对象。因此"形态 2 + 空 `modifiers`"不是稳定形态（保存后会被规范化）。
4. **产物数量语义**：`getStack(ItemStack input, Context)`（行 92-101）中 `output.setCount(output.getCount() * input.getCount())`（当 `input` 非空时）。因此同一个 `result` 在不同配方里的实际产量取决于调用方传入的输入数量：
   - `AnvilRecipe.assemble`：`output.getStack(input.getItem())`（`AnvilRecipe.java:127`）→ **按输入堆叠数放大**；
   - `WeldingRecipe.assemble`：`output.getSingleStack(input.getMain())`（`WeldingRecipe.java:87`）→ 输入被 `copyWithCount(1)`，**不放大**；
   - `CastingRecipe.assemble`：`result.getSingleStack(mold.getContainer().copy())`（`CastingRecipe.java:80`）→ **不放大**；
   - `getEmptyStack()`（行 80-82，JEI/配方书预览用）传 `NO_RANDOM_CHANCE` 上下文。
5. **`ItemStackProvider.of(...)`**（行 48-70）会对 `stack` 调用 `FoodCapability.setTransientNonDecaying(stack)`（行 69），即配方产出的食物带"不可腐烂"的瞬态标记。

`STREAM_CODEC`（行 36）使用 `ItemStack.OPTIONAL_STREAM_CODEC`（允许空物品）+ `ItemStackModifier.STREAM_CODEC` 列表，与 JSON 侧语义一致。

##### A1-1.2 `ItemStackModifier` 的 JSON 形状

```java
// net/dries007/tfc/common/recipes/outputs/ItemStackModifier.java:22-23
public static final Codec<ItemStackModifier> CODEC =
        ItemStackModifiers.REGISTRY.byNameCodec().dispatch(ItemStackModifier::type, ItemStackModifierType::codec);
public static final StreamCodec<RegistryFriendlyByteBuf, ItemStackModifier> STREAM_CODEC =
        ByteBufCodecs.registry(ItemStackModifiers.KEY).dispatch(ItemStackModifier::type, ItemStackModifierType::streamCodec);
```

- 必须带 `"type"` 字段，取值为 modifier 注册 id（**dispatch codec**）。
- 注册表：`ItemStackModifiers.KEY = tfc:item_stack_modifiers`，`REGISTRY` 同步到客户端（`ItemStackModifiers.java:54-56`）。
- 上下文字段（不是 JSON 字段）：`ItemStackModifier.Context` 有 **两个** 值 `DEFAULT` 与 `NO_RANDOM_CHANCE`（`ItemStackModifier.java:33-37`）。带随机性的 modifier 在 `NO_RANDOM_CHANCE` 下不实际随机（例如 `ChanceModifier.apply`，`ChanceModifier.java:33-46`：非 DEFAULT 时只追加 Lore 提示 `tfc.tooltip.chance` 并原样返回）。

##### A1-1.3 可用 modifier 全清单（22 个，来源 `ItemStackModifiers.java:57-78`）

| 注册 id（JSON `type` 值） | 实现类 | JSON 额外字段 | 语义摘要 |
| --- | --- | --- | --- |
| `tfc:copy_input` | `CopyInputModifier` | 无 | 以输入物品（含组件）作为产物基础 |
| `tfc:copy_food` | `CopyFoodModifier` | 无 | 复制输入的食物组件 |
| `tfc:copy_oldest_food` | `CopyOldestFoodModifier` | 无 | 复制"最旧"的食物数据（堆叠中） |
| `tfc:copy_heat` | `CopyHeatModifier` | 无 | 复制输入温度 |
| `tfc:copy_forging_bonus` | `CopyForgingBonusModifier` | 无 | 复制输入的锻造加成（`ForgingBonus`） |
| `tfc:reset_food` | `ResetFoodModifier` | 无 | 重置食物数据 |
| `tfc:empty_bowl` | `EmptyBowlModifier` | 无 | 倒空碗 |
| `tfc:flower_cutting` | `FlowerCuttingModifier` | 无 | 花卉扦插产物处理 |
| `tfc:add_bait_to_rod` | `AddBaitToRodModifier` | 无 | 把鱼饵装到鱼竿上 |
| `tfc:add_glass` | `AddGlassModifier` | 无 | 给吹管加玻璃 |
| `tfc:add_powder` | `AddPowderModifier` | 无 | 给吹管加粉末 |
| `tfc:crafting_remainder` | `CraftingRemainderModifier` | 无 | 使用输入的合成剩余物 |
| `tfc:damage_crafting_remainder` | `DamageCraftingRemainderModifier` | 无 | 剩余物改为"受损一次"（工具耐久） |
| `tfc:add_trait` | `AddTraitModifier` | `trait`（`FoodTrait`，如 `tfc:salted`） | 添加食物特性 |
| `tfc:remove_trait` | `RemoveTraitModifier` | `trait`（`FoodTrait`） | 移除食物特性 |
| `tfc:round_creation_date` | `RoundCreationDateModifier` | 无 | 创建日期取整 |
| `tfc:add_heat` | `AddHeatModifier` | `temperature`（float，可为负） | 增加/减少温度 |
| `tfc:dye_leather` | `DyeLeatherModifier` | `color`（`DyeColor`，如 `black`） | 给皮革染色 |
| `tfc:remove_dye` | `RemoveDyeModifier` | 无 | 去除染色 |
| `tfc:meal` | `MealModifier` | `food`（`FoodData`）、`portions`（数组） | 组装"餐食"（三明治/沙拉等） |
| `tfc:extra_products` | `ExtraProductModifier` | `stack`（`ItemStack`） | 额外产物（按玩家随机/掉落） |
| `tfc:chance` | `ChanceModifier` | `chance`（float，0~1） | 按概率保留产物数量 |

字段出处：`AddTraitModifier.java:26`（`trait`）、`RemoveTraitModifier.java:26`（`trait`）、`AddHeatModifier.java:30`（`temperature`）、`DyeLeatherModifier.java:29`（`color`）、`ExtraProductModifier.java:30`（`stack`）、`ChanceModifier.java:29`（`chance`）、`MealModifier.java:52`（`food` + `portions`，其中每个 portion 的可选字段为 `ingredient` / `nutrient_modifier` / `water_modifier` / `saturation_modifier`，默认 `1.0f`）。

**命名坑**：注册 id 是 `tfc:extra_products`（**复数**），Java 常量名却是 `EXTRA_PRODUCT`（`ItemStackModifiers.java:77`）。写 JSON 时必须用复数。

##### A1-1.4 本组 5 类配方中 modifier 的真实使用情况

**结论：`anvil` / `welding` / `casting` 三个目录下没有任何配方使用 `result.modifiers`**（全量扫描 `jar-extract/data/tfc/recipe/{anvil,welding,casting}/**.json`，匹配 `"modifiers"` 命中数 0）。真实用例集中在 `crafting/`、`heating/`、`barrel/` 目录。

`data/tfc/recipe/**` 内 modifier 的粗略使用频次（本次扫描）：

| modifier | 出现次数 |
| --- | --- |
| `tfc:damage_crafting_remainder` | 474 |
| `tfc:copy_input` | 359 |
| `tfc:add_trait` | 334 |
| `tfc:meal` | 186 |
| `tfc:copy_forging_bonus` | 126 |
| `tfc:copy_food` | 66 |
| `tfc:copy_oldest_food` | 48 |
| `tfc:dye_leather` | 16 |
| `tfc:extra_products` | 9 |
| `tfc:add_heat` | 4 |
| `tfc:add_glass` / `tfc:add_bait_to_rod` | 各 2 |
| `tfc:chance` / `tfc:round_creation_date` / `tfc:remove_trait` / `tfc:empty_bowl` / `tfc:add_powder` / `tfc:flower_cutting` / `tfc:remove_dye` | 各 1 |
| `tfc:copy_heat` / `tfc:reset_food` / `tfc:crafting_remainder` | **0（注册表内存在但数据未使用）** |

可用直接引用的真实片段：

```json
// data/tfc/recipe/heating/powder/kaolinite.json（结果片段，带参 modifier）
"result_item":{"modifiers":[{"type":"tfc:chance","chance":0.2}],"stack":{"count":1,"id":"tfc:powder/kaolinite"}}
```

```json
// data/tfc/recipe/crafting/metal/axe/bismuth_bronze.json（copy_forging_bonus 的典型场景）
{"type":"tfc:advanced_shaped_crafting","key":{"S":{"tag":"c:rods/wooden"},"X":{"item":"tfc:metal/axe_head/bismuth_bronze"}},"pattern":["X","S"],"result":{"modifiers":[{"type":"tfc:copy_forging_bonus"}],"stack":{"count":1,"id":"tfc:metal/axe/bismuth_bronze"}}}
```

```json
// data/tfc/recipe/crafting/salting.json（3 个无参 modifier）
"result":{"modifiers":[{"type":"tfc:copy_input"},{"type":"tfc:add_trait","trait":"tfc:salted"},{"type":"tfc:round_creation_date"}]}
```

```json
// data/tfc/recipe/crafting/food/barley_bread_jam_sandwich_jss_jam.json（meal 的复杂写法，含 portions）
"result":{"modifiers":[{"type":"tfc:meal","food":{"decay_modifier":4.5,"hunger":4,"saturation":1.0,"water":0.5},"portions":[{"ingredient":{"item":"tfc:food/barley_bread"},"nutrient_modifier":0.675,"saturation_modifier":0.5,"water_modifier":0.5},{"nutrient_modifier":0.8,"saturation_modifier":0.8,"water_modifier":0.8}]}],"stack":{"count":1,"id":"tfc:food/barley_bread_jam_sandwich"}}
```

---

### 附录 A1-2：本组引用的其它辅助类型

| 类型 | 归属 | 本组使用情况 | 说明 |
| --- | --- | --- | --- |
| `net.dries007.tfc.common.component.forge.ForgeRule` | `common/component/forge/` | R-02 的 `rules` 字段 | 30 个枚举值 + `isConsistent` 校验 + `matches` 运行时判定（详见 R-02.2） |
| `net.dries007.tfc.util.AlloyRange` | `util/` | R-01 的 `contents` 元素 | record `(Fluid fluid, double min, double max)` + `isIn` 浮点容差（详见 R-01.2） |
| `net.dries007.tfc.util.FluidAlloy` | `util/` | R-01 的输入 | 匹配语义实现者，同时是 `tfc:alloy` 的唯一调用者（详见 R-01.4） |
| `net.dries007.tfc.common.recipes.outputs.ItemStackProvider` | `common/recipes/outputs/` | R-02/R-03/R-04 的 `result` | 见附录 A1-1 |
| `net.dries007.tfc.common.recipes.outputs.ItemStackModifier(s)` | `common/recipes/outputs/` | 同上（作为 `result.modifiers` 元素） | 22 个注册项，见附录 A1-1.3 |
| `net.dries007.tfc.common.recipes.outputs.PotOutput` | `common/recipes/outputs/` | ❌ **本组不使用** | 属于 pot 系配方（`PotOutput.java:46-51` 注册 `empty` / `soup` / `jam` 三个 `OutputType`），由 `SoupPotRecipe` / `JamPotRecipe` 使用 |
| `net.dries007.tfc.common.recipes.outputs.ItemStackModifierType` | `common/recipes/outputs/` | 间接 | `record ItemStackModifierType<T>(MapCodec<T> codec, StreamCodec<...> streamCodec)`（`ItemStackModifierType.java:16`），dispatch 的右侧类型 |
| `TFCIngredients` | `common/recipes/ingredients/` | R-02/R-03/R-04 的 `ingredient`/`mold`/`*_input` 字段（可选写法） | 见附录 A1-3 |
| **`ItemStackProviders`（复数）** | — | ❌ | **全树 grep（`*.java`）无任何匹配，判定 4.2.10 中不存在该类**；请使用 `ItemStackProvider` + `ItemStackModifiers`。详见 A1-4 |

---

### 附录 A1-3：`Ingredient` 的 JSON 形式与 `TFCIngredients`

本组中 `tfc:anvil.ingredient`、`tfc:welding.first_input` / `second_input`、`tfc:casting.mold` 都是 `Ingredient`（`Ingredient.CODEC`）。

##### A1-3.1 原生 / NeoForge 形式

| 写法 | 示例 | 说明 |
| --- | --- | --- |
| 单物品 | `{"item":"tfc:ceramic/ingot_mold"}` | 真实数据大量使用 |
| 物品标签 | `{"tag":"c:ingots/copper"}` | 真实数据大量使用 |
| 数组（或） | `[{"tag":"c:rods/wooden"},{"item":"minecraft:bone"}]` | 见 `data/tfc/recipe/crafting/obsidian_axe.json` 的 `key.S` |
| NeoForge 内置 type | `{"type":"neoforge:compound","children":[...]}` | 见 `data/tfc/recipe/barrel/clean_bowl.json` |
| 空 | `[]` 或 `{"ingredient":...}` 的 `Ingredient.EMPTY` 形式 | 本组 5 类配方的这些字段**都是必填**，不可为空 |

##### A1-3.2 TFC 自定义 ingredient（`net/dries007/tfc/common/recipes/ingredients/TFCIngredients.java:42-48`）

| 注册 id | 实现类 | JSON 字段 | 出处行 | 示例 |
| --- | --- | --- | --- | --- |
| `tfc:rotten` | `RottenIngredient` | 无（`MapCodec.unit`） | `RottenIngredient.java:43` | `{"type":"tfc:rotten"}` |
| `tfc:not_rotten` | `NotRottenIngredient` | 无（`MapCodec.unit`） | `NotRottenIngredient.java:43` | `{"type":"tfc:not_rotten"}` |
| `tfc:has_trait` | `HasTraitIngredient` | `trait` | `HasTraitIngredient.java:27` | `{"type":"tfc:has_trait","trait":"tfc:brined"}` |
| `tfc:lacks_trait` | `LacksTraitIngredient` | `trait` | `LacksTraitIngredient.java:27` | `{"type":"tfc:lacks_trait","trait":"tfc:salted"}` |
| `tfc:heat` | `HeatIngredient` | `min`（可选，默认 `-∞`）、`max`（可选，默认 `+∞`） | `HeatIngredient.java:44` | `{"type":"tfc:heat","min":1000}`；**两者都省略会报错 "Must have one of min or max"** |
| `tfc:fluid_content` | `FluidContentIngredient` | `fluid`（`SizedFluidIngredient.FLAT_CODEC`：`amount` + `fluid`） | `FluidContentIngredient.java:46` | `{"type":"tfc:fluid_content","fluid":{"amount":100,"fluid":"minecraft:water"}}` |
| `tfc:and` | `AndIngredient` | `children`（`Ingredient` 列表） | `AndIngredient.java:32` | `{"type":"tfc:and","children":[{"item":"minecraft:egg"},{"type":"tfc:not_rotten"}]}` |

`TFCIngredients.TYPES` 注册到 NeoForge 的 `NeoForgeRegistries.INGREDIENT_TYPES`（`TFCIngredients.java:41`），对**所有**使用 `Ingredient.CODEC` 的配方字段都生效。

##### A1-3.3 一个常见误认

`tfc:air_or_empty_fluid` **不是** ingredient、也不是 modifier，而是 **`BlockPredicate`**（`net/dries007/tfc/world/blockpredicate/TFCBlockPredicates.java:30`，`AirOrEmptyFluidPredicate`）。它出现在 worldgen/pump 等场景的 JSON 中。若在全 `data/` 目录做关键词统计会把它与 modifier 混在一起，需按注册表区分（本次统计已限定在 `data/tfc/recipe/**`）。

---

### 附录 A1-4：未核实 / 存疑事项（Honest Gaps）

| 编号 | 事项 | 检查过的文件 | 结论 |
| --- | --- | --- | --- |
| G1 | `ItemStackProviders`（复数）类是否存在 | 全树 grep `*.java` 搜 `ItemStackProviders`（无匹配）；`net/dries007/tfc/util/` 目录列表；`common/recipes/outputs/` 目录列表 | **4.2.10 中不存在**。实际体系为 `ItemStackProvider`（单数，`outputs/`）+ `ItemStackModifiers`（注册表）。任务说明中提到的"`net/dries007/tfc/util/` 下的 ItemStackProvider modifier 注册表"实际位于 `net/dries007/tfc/common/recipes/outputs/`，`util/` 下没有该体系 |
| G2 | `IMold.getContainer()` 的定义位置与返回语义 | `IMold.java`（全文 37 行）、`CastingRecipe.java:64/76/80`、`MoldItem.java`、`MoldBlockEntityRenderer.java:116-118` | `IMold` 自身只声明 `isMolten()` / `drain` / `drainIgnoringTemperature`，`getContainer()` 未在 TFC 侧声明 → 来自 NeoForge 的 `IFluidHandlerItem`（**反编译产物不含 NeoForge 源码，故其接口声明未能直接读取**）。按调用形式可确定其返回"模具物品本身"（`MoldItem` 与该接口的 FluidHandler 用法一致）。标记为**部分未核实** |
| G3 | `RecipeHelpers.getCraftingPlayer()` 的返回值来源 | `RecipeHelpers.java:65-68`（`CommonHooks.getCraftingPlayer()`）；全树使用点仅 `CastingCraftingRecipe.java:68` | 内部为 NeoForge `CommonHooks`，**NeoForge 源码未读取**；语义按方法名与唯一使用点（`getRemainingItems` 中取随机数）推断 |
| G4 | 反编译产物无参数名与注释 | `AnvilRecipe.java`、`WeldingRecipe.java`、`CastingRecipe.java`、`AlloyRecipe.java`、`CastingCraftingRecipe.java` 全文 | `CODEC` 的 `group` 顺序与构造器赋值可完全对应（`AnvilRecipe.java:67` vs `93-99`；`WeldingRecipe.java:55` vs `63-69`；`CastingRecipe.java:54` vs `67-72`），**字段顺序/名称无歧义**；但原始注释（例如字段的语义说明）无法获取 |
| G5 | `tfc:casting_crafting` 的 recipe type | `TFCRecipeTypes.java`（全文 78 行，无该注册项）、`CastingCraftingRecipe.java`（全文 95 行，无 `getType()`）、API 转储 `TFC-public-api.txt`（无 `getType`）、`javap` 读取 1.21.1 字节码（`CustomRecipe` 无 `getType`；`CraftingRecipe.getType()` default 返回 `RecipeType.CRAFTING`） | 结论为 **`minecraft:crafting`**，证据为**字节码级**（TFC 源码内无显式声明）。这是本组唯一依赖 Minecraft 字节码而非 TFC 源码的结论 |
| G6 | `tfc:alloy` 的多个配方同时匹配时的优先级 | `RecipeHelpers.java:143-150/162-169`、`AlloyRecipe.java:54-56` | 代码语义确定为"取遍历中的**第一个**匹配"，而遍历顺序由 `RecipeManager.byType` 的返回顺序（原版按 id 排序）决定。**未做运行期验证**，故"同 id 排序为确定性顺序"这一细节属于推断 |
| G7 | `SizedFluidIngredient.FLAT_CODEC` 与 `SizedFluidIngredient.CODEC` 的完整字段差异 | `CastingRecipe.java:54-55`；真实数据 `data/tfc/recipe/casting/*.json`（111 个，全部为 `{"amount":...,"fluid":...}` 扁平写法）；`FluidContentIngredient.java:46` | `FLAT_CODEC` 的实际 JSON 形状已由 111 个真实文件完全确认；但 **NeoForge 侧 `SizedFluidIngredient` 的类源码未读取**（不在 TFC 反编译产物内），故"默认 `CODEC` 是 dispatch 形式"这一点属于按 NeoForge 通用约定与 `FLAT_CODEC` 命名推断，标记为**部分未核实** |
| G8 | `MoldBlockEntity` 是否存在 | glob/grep `common/blockentities/` 下 `*Mold*`，仅命中 `MoldTableBlockEntity.java` | 4.2.10 中**不存在** `MoldBlockEntity`；世界中的模具只以"物品"形态（`IMold` 能力）存在于模具台/玩家手中 |

---

### 附录 A1-5：字段级自查（每个字段的 CODEC 出处）

| 配方 | 字段 | CODEC 出处（文件:行） | 已核对 |
| --- | --- | --- | --- |
| `tfc:alloy` | `contents` | `AlloyRecipe.java:50`（`AlloyRange.CODEC.listOf().fieldOf("contents")`） | ✅ |
| `tfc:alloy` | `result` | `AlloyRecipe.java:50`（`BuiltInRegistries.FLUID.byNameCodec().fieldOf("result")`） | ✅ |
| `tfc:alloy` | `contents[].fluid` | `AlloyRange.java:32` | ✅ |
| `tfc:alloy` | `contents[].min` | `AlloyRange.java:32`（`Codec.DOUBLE.fieldOf("min")`） | ✅ |
| `tfc:alloy` | `contents[].max` | `AlloyRange.java:32`（`Codec.DOUBLE.fieldOf("max")`） | ✅ |
| `tfc:anvil` | `ingredient` | `AnvilRecipe.java:67`（`fieldOf` 必填） | ✅ |
| `tfc:anvil` | `tier` | `AnvilRecipe.java:67`（`optionalFieldOf("tier", 0)`） | ✅ |
| `tfc:anvil` | `rules` | `AnvilRecipe.java:67`（`ForgeRule.CODEC.listOf().fieldOf("rules").validate(...)`） | ✅ |
| `tfc:anvil` | `apply_bonus` | `AnvilRecipe.java:67`（`optionalFieldOf("apply_bonus", false)`） | ✅ |
| `tfc:anvil` | `result` | `AnvilRecipe.java:67`（`ItemStackProvider.CODEC.fieldOf("result")`） | ✅ |
| `tfc:welding` | `first_input` | `WeldingRecipe.java:55`（`fieldOf` 必填） | ✅ |
| `tfc:welding` | `second_input` | `WeldingRecipe.java:55`（`fieldOf` 必填） | ✅ |
| `tfc:welding` | `tier` | `WeldingRecipe.java:55`（`optionalFieldOf("tier", 0)`） | ✅ |
| `tfc:welding` | `result` | `WeldingRecipe.java:55`（`fieldOf` 必填） | ✅ |
| `tfc:welding` | `bonus` | `WeldingRecipe.java:55`（`optionalFieldOf("bonus", Behavior.IGNORE)`）+ `Behavior.CODEC` 行 133 | ✅ |
| `tfc:casting` | `mold` | `CastingRecipe.java:54`（Java 字段名 `ingredient`） | ✅ |
| `tfc:casting` | `fluid` | `CastingRecipe.java:54`（`SizedFluidIngredient.FLAT_CODEC.fieldOf("fluid")`） | ✅ |
| `tfc:casting` | `result` | `CastingRecipe.java:54`（`fieldOf` 必填） | ✅ |
| `tfc:casting` | `break_chance` | `CastingRecipe.java:54`（`optionalFieldOf("break_chance", 1.0f)`） | ✅ |
| `tfc:casting_crafting` | （除 `type` 外无字段） | `TFCRecipeSerializers.java:81` + `RecipeSerializerImpl.java:21-23`（`MapCodec.unit`） | ✅ |
| 三者共用 | `result.stack` | `ItemStackProvider.java:35`（`optionalFieldOf("stack", ItemStack.EMPTY)`） | ✅ |
| 三者共用 | `result.modifiers` | `ItemStackProvider.java:35`（`fieldOf("modifiers")` 必填）+ `ItemStackModifier.java:22` dispatch | ✅ |

**"无额外校验"的确认**：

- `tfc:alloy`：无 `validate`、无 `xmap`（`AlloyRecipe.java:50`）→ 数据可写出永远不匹配的配方（不报错），风险见 R-01.2 第 4 条。
- `tfc:anvil`：**有** `validate`（`ForgeRule.isConsistent`），失败信息见 R-02.2。
- `tfc:welding`：无 `validate`、无 `xmap`。
- `tfc:casting`：无 `validate`（`break_chance` 未做 `0~1` 范围限制，写超出范围会得到"恒碎/恒不碎"的异常行为）。
- `tfc:casting_crafting`：无字段，故无校验；输入合法性完全由 `getMold`（单物品、必须是模具）在运行时约束。

---

（组 A1 文档结束）

---

---


---

## 第 2 部分　方块交互与木桶配方（R-06 ~ R-11）


> 版本基准：TerraFirmaCraft-NeoForge-1.21.1-4.2.10 / Minecraft 1.21.1 / NeoForge 21.1.248
> 证据来源（全部为本地文件，无网络依赖）：
> - 反编译源码根：`moddev/src-ref/TFC-decompiled`（下文相对路径均以此为根）
> - 真实 jar 解包内容：`moddev/jar-extract`（下文"jar 内路径"以 `jar-extract` 为根）
> - 反编译产物**无参数名、无注释**（CFR 0.152 输出），但 `CODEC` 定义、record 组件、字段常量完整可读，足以逐行还原字段名与默认值。
> - 文件头的 `Could not load the following classes` 仅为 classpath 缺失提示，不影响本次考证。

---

### 组 A2 覆盖范围

本组负责以下 6 种配方类型，涵盖"地形破坏类"（塌方、滑坡）、"方块改造类"（凿刻）与"木桶流体加工类"（封口/即时/即时流体）三条独立链路。

| 编号 | type id | 实现类 | 类型形态 | 本组中文名 |
| --- | --- | --- | --- | --- |
| R-06 | `tfc:collapse` | `net.dries007.tfc.common.recipes.CollapseRecipe` | `class`，继承 `BlockRecipe` | 塌方 |
| R-07 | `tfc:landslide` | `net.dries007.tfc.common.recipes.LandslideRecipe` | `class`，继承 `BlockRecipe` | 滑坡 |
| R-08 | `tfc:chisel` | `net.dries007.tfc.common.recipes.ChiselRecipe` | `class`，实现 `INoopInputRecipe` | 凿刻 |
| R-09 | `tfc:barrel_sealed` | `net.dries007.tfc.common.recipes.SealedBarrelRecipe` | `class`，继承 `BarrelRecipe` | 木桶·封口配方 |
| R-10 | `tfc:barrel_instant` | `net.dries007.tfc.common.recipes.InstantBarrelRecipe` | `class`，继承 `BarrelRecipe` | 木桶·即时配方 |
| R-11 | `tfc:barrel_instant_fluid` | `net.dries007.tfc.common.recipes.InstantFluidBarrelRecipe` | `class`，继承 `BarrelRecipe` | 木桶·即时流体混合配方 |

本组涉及的、需要在阅读字段表前先理解的通用辅助类型：

| 辅助类型 | 全名 | 本组作用 |
| --- | --- | --- |
| `BlockIngredient` | `net.dries007.tfc.common.recipes.ingredients.BlockIngredient` | R-06/R-07/R-08 的 `ingredient` 字段类型（方块集合或方块 tag） |
| `ItemStackProvider` | `net.dries007.tfc.common.recipes.outputs.ItemStackProvider` | R-08/R-09/R-10 的物品输出包装（物品 + 修饰器列表） |
| `ItemStackModifier` / `ItemStackModifiers` | `net.dries007.tfc.common.recipes.outputs.*` | `ItemStackProvider` 的 `modifiers` 数组元素类型与其注册表 |
| `TFCIngredients` | `net.dries007.tfc.common.recipes.ingredients.TFCIngredients` | barrel 配方 `input_item` 里可用的 TFC 自定义 ingredient 类型清单 |
| `SizedIngredient`（NeoForge） | `net.neoforged.neoforge.common.crafting.SizedIngredient` | R-09/R-10 的 `input_item` 字段类型 |
| `SizedFluidIngredient`（NeoForge） | `net.neoforged.neoforge.fluids.crafting.SizedFluidIngredient` | R-09/R-10/R-11 的流体输入字段类型 |
| `BarrelInventory` | `net.dries007.tfc.common.recipes.input.BarrelInventory` | R-09/R-10/R-11 的实际输入容器接口 |

编号说明：本组严格使用 `R-06` ~ `R-11`，不占其它组的编号空间。

统计事实（来自 `jar-extract/data/tfc/recipe/`，实际清点所得）：

| type id | 真实 JSON 存放目录 | 文件数 |
| --- | --- | --- |
| `tfc:collapse` | `data/tfc/recipe/collapse/` | 525（`ore/` 504 + `rock/` 21） |
| `tfc:landslide` | `data/tfc/recipe/landslide/` | 21（顶层 5 + `clay/` 8 + `dirt/` 8） |
| `tfc:chisel` | `data/tfc/recipe/chisel/` | 513（`rock/` 336、`alabaster/` 65、`wood/` 40、`cut_sandstone/` 21、`smooth_sandstone/` 21、`mud_bricks/` 16、`raw_sandstone/` 14） |
| `tfc:barrel_sealed` | `data/tfc/recipe/barrel/`（与另两种共目录） | 308 |
| `tfc:barrel_instant` | `data/tfc/recipe/barrel/` | 20 |
| `tfc:barrel_instant_fluid` | `data/tfc/recipe/barrel/` | 2 |

**重要目录事实**：三种 barrel 配方**不按子目录分 type**，而是全部平铺在 `data/tfc/recipe/barrel/`（共 330 个 JSON）及其若干子目录中，靠每个文件顶层的 `"type"` 字段区分。`collapse` 与 `landslide` 则各有独立目录。

---

### A2-0 通用前置：本组共享的序列化与辅助类型

##### A2-0.1 配方序列化器如何被选择

三种不同形态的 serializer 注册方式（全部见 `net/dries007/tfc/common/recipes/TFCRecipeSerializers.java`）：

```java
// 58-59 行：collapse / landslide 走 BlockRecipe 的静态工厂
public static final Id<CollapseRecipe> COLLAPSE = TFCRecipeSerializers.register("collapse", BlockRecipe.serializer(CollapseRecipe::new));
public static final Id<LandslideRecipe> LANDSLIDE = TFCRecipeSerializers.register("landslide", BlockRecipe.serializer(LandslideRecipe::new));
// 60 行：chisel 使用类自身的 CODEC / STREAM_CODEC
public static final Id<ChiselRecipe> CHISEL = TFCRecipeSerializers.register("chisel", ChiselRecipe.CODEC, ChiselRecipe.STREAM_CODEC);
// 71-73 行：三种 barrel
public static final Id<SealedBarrelRecipe> SEALED_BARREL = TFCRecipeSerializers.register("barrel_sealed", SealedBarrelRecipe.CODEC, SealedBarrelRecipe.STREAM_CODEC);
public static final Id<InstantBarrelRecipe> INSTANT_BARREL = TFCRecipeSerializers.register("barrel_instant", InstantBarrelRecipe.CODEC, InstantBarrelRecipe.STREAM_CODEC);
public static final Id<InstantFluidBarrelRecipe> INSTANT_FLUID_BARREL = TFCRecipeSerializers.register("barrel_instant_fluid", InstantFluidBarrelRecipe.CODEC, InstantFluidBarrelRecipe.STREAM_CODEC);
```

这些 `register(...)` 重载最终都包装成 `RecipeSerializerImpl`（`net/dries007/tfc/common/recipes/RecipeSerializerImpl.java:19-23`）：

```java
public record RecipeSerializerImpl<R extends Recipe<?>>(MapCodec<R> codec, StreamCodec<RegistryFriendlyByteBuf, R> streamCodec) implements RecipeSerializer<R> {
    public RecipeSerializerImpl(R singleInstance) {
        this(MapCodec.unit(singleInstance), StreamCodec.unit(singleInstance));
    }
}
```

即：**JSON 顶层 `"type"` 决定调用哪个 `MapCodec`，而 `MapCodec` 就是下文各字段表的唯一权威来源。**

三种 type 的 type id 与 serializer id 的对应（`net/dries007/tfc/common/recipes/TFCRecipeTypes.java`）：

| type id（JSON `type`） | recipe type（`TFCRecipeTypes`） | 是否一致 |
| --- | --- | --- |
| `tfc:collapse` | `COLLAPSE = register("collapse")`（44 行） | 一致 |
| `tfc:landslide` | `LANDSLIDE = register("landslide")`（45 行） | 一致 |
| `tfc:chisel` | `CHISEL = register("chisel")`（46 行） | 一致 |
| `tfc:barrel_sealed` | `BARREL_SEALED = register("barrel_sealed")`（55 行） | 一致 |
| `tfc:barrel_instant` | `BARREL_INSTANT = register("barrel_instant")`（56 行） | 一致 |
| `tfc:barrel_instant_fluid` | `BARREL_INSTANT_FLUID = register("barrel_instant_fluid")`（57 行） | 一致 |

**核实结论**：用户提示中怀疑的 `tfc:barrel_sealed` 命名问题——经核实 `TFCRecipeSerializers` 的 serializer 名（`TFCRecipeSerializers.java:71`）与 `TFCRecipeTypes` 的 type 名（`TFCRecipeTypes.java:55`）**完全相同**，均为字符串 `barrel_sealed`，不存在 serializer 名与 type 名不一致的情况。本组 6 种 type 全部 serializer 名 == type 名。

##### A2-0.2 `BlockIngredient`（R-06 / R-07 / R-08 的 `ingredient` 字段类型）

定义于 `net/dries007/tfc/common/recipes/ingredients/BlockIngredient.java`：

```java
// 43 行
public record BlockIngredient(Either<ImmutableSet<Block>, TagKey<Block>> either) implements Predicate<Block> {
    // 45 行
    public static final Codec<BlockIngredient> CODEC = Codec.either(
        Codecs.BLOCK.listOf().xmap(ImmutableSet::copyOf, List::copyOf),
        TagKey.hashedCodec(Registries.BLOCK)
    ).xmap(BlockIngredient::new, BlockIngredient::either);
```

要点（逐条来自源码）：

1. 该字段是 **`Codec.either`**：既可以写成**方块 id 数组**（`Either.left`），也可以写成**单个方块 tag 字符串**（`Either.right`）。这是 JSON 层面的两种合法写法。
2. `test(BlockState state)`（62-64 行）先取 `state.getBlock()` 再 `test(Block)`，即 **`BlockIngredient` 只比较方块种类，不比较方块状态属性**。`tfc:collapse` / `tfc:landslide` 的 `ingredient` 因此无法表达"只有朝北的原木才塌方"这类条件。
3. `blocks()`（75-77 行）返回该 ingredient 展开后的方块列表，是 `IndirectHashCollection` 建立索引的依据（R-06/R-07 的 `CACHE`）。
4. `of(TagKey<Block>)`（48 行）用于 fallback 配方（见 R-06.4、R-07.4）。

真实文件里两种写法的出现情况（实际 grep 统计）：`collapse`（525 个）与 `landslide`（21 个）中**全部使用数组写法**，使用"单字符串 tag"写法的文件数为 **0**；`chisel`（513 个）同样全部使用数组写法。

数组写法的真实例子（`jar-extract/data/tfc/recipe/landslide/clay/alfisol.json`）：

```json
{"type":"tfc:landslide","ingredient":["tfc:clay/alfisol","tfc:clay_grass/alfisol","tfc:clay_duff/alfisol"],"result":"tfc:clay/alfisol"}
```

tag 写法（**本次未在 TFC 自带数据中发现实例**，但按 CODEC 合法）应写作：

```json
{"type":"tfc:landslide","ingredient":"tfc:some_block_tag","result":"minecraft:dirt"}
```

> 未能核实项：tag 写法没有官方数据样例可对照，其合法性仅由 `BlockIngredient.CODEC` 的 `Codec.either` 第二分支推出。

##### A2-0.3 `result` 字段的方块状态写法（`Codecs.BLOCK_STATE`）

R-06、R-07、R-08 的 `result` 都使用 `net.dries007.tfc.world.Codecs.BLOCK_STATE`（`net/dries007/tfc/world/Codecs.java:64`）：

```java
public static final Codec<BlockState> BLOCK_STATE = Codec.either(
    BLOCK.xmap(Block::defaultBlockState, BlockStateBase::getBlock),
    BlockState.CODEC
).xmap(e -> e.map(e1 -> e1, e1 -> e1),
       e -> e == e.getBlock().defaultBlockState() ? Either.left(e) : Either.right(e));
```

三种合法写法：

| 写法 | JSON 例 | 说明 |
| --- | --- | --- |
| 纯字符串 | `"result":"minecraft:dirt"` | 走 `Either.left`，等于该方块默认状态；TFC 全部自带 collapse/landslide/chisel 样例都用这种 |
| 完整状态对象 | `"result":{"Name":"minecraft:oak_log","Properties":{"axis":"x"}}` | 走 `Either.right`（`BlockState.CODEC`）；本次在 `collapse` 的 525 个文件中**搜索 `"result": {"Name"` 命中数为 0**，即官方数据未使用该写法 |
| 省略 | 不写 `result` 字段 | 仅 R-06/R-07 允许（`optionalFieldOf`），R-08 不允许（`fieldOf`） |

> 未能核实项：带 `Properties` 的 `result` 写法在 TFC 自带数据中无实例；其合法性来自 `Codecs.BLOCK_STATE` 与 `BlockState.CODEC`，本次仅做源码级确认，未做运行时验证。

##### A2-0.4 `ItemStackProvider`（R-08 的 `item_output`、R-09/R-10 的 `output_item`、`on_seal`/`on_unseal`）

定义于 `net/dries007/tfc/common/recipes/outputs/ItemStackProvider.java`：

```java
// 34 行
public record ItemStackProvider(ItemStack stack, List<ItemStackModifier> modifiers) {
    // 35 行
    public static final Codec<ItemStackProvider> CODEC = Codec.either(
        RecordCodecBuilder.create(i -> i.group(
            ItemStack.CODEC.optionalFieldOf("stack", ItemStack.EMPTY).forGetter(c -> c.stack),
            ItemStackModifier.CODEC.listOf().fieldOf("modifiers").forGetter(c -> c.modifiers)
        ).apply(i, ItemStackProvider::new)),
        ItemStack.CODEC
    ).xmap(e -> e.map(Function.identity(), ItemStackProvider::of),
           provider -> provider.modifiers.isEmpty() ? Either.right(provider.stack) : Either.left(provider));
```

**两种 JSON 写法（重要）**：

| 写法 | 触发条件 | JSON 结构 | 必需字段 |
| --- | --- | --- | --- |
| 简写（`Either.right`） | `modifiers` 为空 | 直接就是一个 `ItemStack` 对象 | `id`；`count` 可选 |
| 完整（`Either.left`） | 有 `modifiers` | `{"stack": <ItemStack, 可选>, "modifiers": [...]}` | **`modifiers` 为 `fieldOf`（必填）**，`stack` 为 `optionalFieldOf`（默认 `ItemStack.EMPTY`） |

这两点必须同时记住：**只要写了 `modifiers`，`stack` 就不再必填**（可以只写 modifiers，把输入物品本身当底子，例如 `{"modifiers":[{"type":"tfc:copy_input"}]}`）；**反之不写 `modifiers`，就不能写 `stack` 键**，必须把 `ItemStack` 直接作为该字段的值。

真实样例对照：

- 简写：`jar-extract/data/tfc/recipe/barrel/clay_ball.json` 的 `"output_item":{"count":4,"id":"minecraft:clay_ball"}`
- 完整（仅 modifiers）：`jar-extract/data/tfc/recipe/barrel/black_dyeable.json` 的 `"output_item":{"modifiers":[{"type":"tfc:copy_input"},{"type":"tfc:dye_leather","color":"black"}]}`

`ItemStackProvider` 的运行期语义（`ItemStackProvider.java:92-101`）：先把 `stack` 复制并按输入数量放大（`output.setCount(output.getCount() * input.getCount())`），再**按顺序**依次套用每个 `modifier`。

##### A2-0.5 `ItemStackModifier` 与注册表全清单

`ItemStackModifier` 是 dispatch 式 Codec（`net/dries007/tfc/common/recipes/outputs/ItemStackModifier.java:22`）：

```java
public static final Codec<ItemStackModifier> CODEC = ItemStackModifiers.REGISTRY.byNameCodec()
        .dispatch(ItemStackModifier::type, ItemStackModifierType::codec);
```

因此每个 modifier 的 JSON 都是 `{"type":"<registry id>", ...该 modifier 自己的字段}`。

注册表 id 全清单（`net/dries007/tfc/common/recipes/outputs/ItemStackModifiers.java:57-78`），以及各自是否带字段：

| registry id | 实现类 | 额外 JSON 字段 | 证据 |
| --- | --- | --- | --- |
| `tfc:copy_input` | `CopyInputModifier` | 无（`Codec.unit` 单例） | `ItemStackModifiers.java:57`，`register(name, singleInstance)` |
| `tfc:copy_food` | `CopyFoodModifier` | 无 | 同上 58 |
| `tfc:copy_oldest_food` | `CopyOldestFoodModifier` | 无 | 同上 59 |
| `tfc:copy_heat` | `CopyHeatModifier` | 无 | 同上 60 |
| `tfc:copy_forging_bonus` | `CopyForgingBonusModifier` | 无 | 同上 61 |
| `tfc:reset_food` | `ResetFoodModifier` | 无 | 同上 62 |
| `tfc:empty_bowl` | `EmptyBowlModifier` | 无 | 同上 63 |
| `tfc:flower_cutting` | `FlowerCuttingModifier` | 无 | 同上 64 |
| `tfc:add_bait_to_rod` | `AddBaitToRodModifier` | 无 | 同上 65 |
| `tfc:add_glass` | `AddGlassModifier` | 无 | 同上 66 |
| `tfc:add_powder` | `AddPowderModifier` | 无 | 同上 67 |
| `tfc:crafting_remainder` | `CraftingRemainderModifier` | 无 | 同上 68 |
| `tfc:damage_crafting_remainder` | `DamageCraftingRemainderModifier` | 无 | 同上 69 |
| `tfc:add_trait` | `AddTraitModifier` | `trait`（`FoodTrait` id） | `AddTraitModifier.java` CODEC：`FoodTrait.CODEC.fieldOf("trait")` |
| `tfc:remove_trait` | `RemoveTraitModifier` | `trait`（`FoodTrait` id） | `RemoveTraitModifier.java` CODEC：同上 |
| `tfc:round_creation_date` | `RoundCreationDateModifier` | 无 | `ItemStackModifiers.java:72` |
| `tfc:add_heat` | `AddHeatModifier` | `temperature`（float） | `AddHeatModifier.java` CODEC：`Codec.FLOAT.fieldOf("temperature")` |
| `tfc:dye_leather` | `DyeLeatherModifier` | `color`（`DyeColor`） | `DyeLeatherModifier.java` CODEC：`DyeColor.CODEC.fieldOf("color")` |
| `tfc:remove_dye` | `RemoveDyeModifier` | 无 | `ItemStackModifiers.java:75` |
| `tfc:meal` | `MealModifier` | `food`（`FoodData`，必填）、`portions`（列表，必填；每项可含 `ingredient`、`nutrient_modifier` 默认 1.0、`water_modifier` 默认 1.0、`saturation_modifier` 默认 1.0） | `MealModifier.java` CODEC |
| `tfc:extra_products` | `ExtraProductModifier` | `stack`（`ItemStack`，必填） | `ExtraProductModifier.java` CODEC：`ItemStack.CODEC.fieldOf("stack")` |
| `tfc:chance` | `ChanceModifier` | `chance`（float） | `ChanceModifier.java:29`：`ChanceModifier.CHANCE = Codec.FLOAT.fieldOf("chance")` |

真实用法举例（全部取自真实文件）：

```json
{"modifiers":[{"type":"tfc:copy_input"},{"type":"tfc:add_trait","trait":"tfc:brined"}]}
```

```json
{"modifiers":[{"type":"tfc:copy_input"},{"type":"tfc:add_heat","temperature":-5.0}]}
```

```json
{"modifiers":[{"type":"tfc:empty_bowl"}]}
```

##### A2-0.6 `TFCIngredients`：barrel 的 `input_item` 里可用的 TFC 自定义 ingredient

注册表见 `net/dries007/tfc/common/recipes/ingredients/TFCIngredients.java:42-48`，全部注册在 NeoForge 的 `IngredientType` 注册表下，命名空间 `tfc`：

| JSON `type` | 实现类 | 自己的 JSON 字段 | 证据（CODEC） |
| --- | --- | --- | --- |
| `tfc:rotten` | `RottenIngredient` | 无（`MapCodec.unit`） | `RottenIngredient.java` |
| `tfc:not_rotten` | `NotRottenIngredient` | 无（`MapCodec.unit`） | `NotRottenIngredient.java` |
| `tfc:has_trait` | `HasTraitIngredient` | `trait`（必填） | `FoodTrait.CODEC.fieldOf("trait")` |
| `tfc:lacks_trait` | `LacksTraitIngredient` | `trait`（必填） | `FoodTrait.CODEC.fieldOf("trait")` |
| `tfc:heat` | `HeatIngredient` | `min`（默认 `-Infinity`）、`max`（默认 `+Infinity`）；**两者都为默认值时 data result 报错** | `HeatIngredient.java` CODEC + `flatXmap(... DataResult.error("Must have one of min or max"))` |
| `tfc:fluid_content` | `FluidContentIngredient` | `fluid`（`SizedFluidIngredient.FLAT_CODEC`，必填） | `FluidContentIngredient.java` CODEC |
| `tfc:and` | `AndIngredient` | `children`（`Ingredient` 列表，必填） | `AndIngredient.java`：`Ingredient.CODEC.listOf()...fieldOf("children")` |

`tfc:and` 的 `children` 允许**嵌套数组**（即 children 里可以再放一组并列的 ingredient），这是真实数据里确实用到的写法（`jar-extract/data/tfc/recipe/barrel/preserved_in_vinegar.json` 中 `children` 的第一项就是一个数组）。其结构由 `Ingredient.CODEC` 的 `CompoundIngredient` 支持，本次未在 `AndIngredient.java` 里看到额外限制。

`TFCIngredients` 还提供 `EMPTY_ITEM`（`TFCIngredients.java:40`：`new SizedIngredient(Ingredient.EMPTY, 1)`），被 `BarrelRecipe.getInputItem()` 在 `input_item` 缺省时返回（`BarrelRecipe.java:176-178`）。

NeoForge 侧内置的 ingredient 类型也是合法的（真实数据中出现 `neoforge:compound`），例如：

```json
{"type":"neoforge:compound","children":[{"tag":"c:foods/soup"},{"tag":"c:foods/salad"}],"count":1}
```

（取自 `jar-extract/data/tfc/recipe/barrel/clean_bowl.json`）

##### A2-0.7 barrel 使用的两个 NeoForge 定容 ingredient

| 字段类型 | 静态 Codec | JSON 结构 | 真实样例 |
| --- | --- | --- | --- |
| `SizedIngredient` | `SizedIngredient.FLAT_CODEC` | `Ingredient` 的内容 + 可选 `count`（默认 1），即 `{"item":"..."}` / `{"tag":"..."}` / `{"type":"tfc:and","children":[...]}`，可加 `"count":N` | `{"count":1,"item":"tfc:hardened_clay"}`、`{"type":"tfc:not_rotten","count":1}` |
| `SizedFluidIngredient` | `SizedFluidIngredient.FLAT_CODEC` | `{"amount":N,"fluid":"..."}` 或 `{"amount":N,"tag":"..."}`；`amount` 必填 | `{"amount":125,"fluid":"tfc:vinegar"}`、`{"amount":250,"tag":"tfc:alcohols"}` |

**FLAT_CODEC 的含义**（本组依据）：与 `SizedIngredient.CODEC` 的"带 `ingredient`/`count` 两键包裹"形式不同，`FLAT_CODEC` 把 ingredient 内容**平铺**在同一个对象里，所以真实数据中看到的是 `{"item":..., "count":...}` 而不是 `{"ingredient":{...},"count":...}`。本次在 barrel 的 330 个文件中检索 `"input_fluid"` 内含 `"type"` 的文件数为 0（即没有使用自定义流体 ingredient 类型的实例），也未发现 `{"ingredient":...}` 包裹式写法，与 FLAT_CODEC 一致。

`count` 的可选性由真实数据证实：`clean_bowl.json`、`beer.json`、`brined.json` 等文件的 `input_item` **不写 `count`**，而 `clay_ball.json`、`mud/*.json` 等写 `"count":1`，两种都能正常工作（后者是显式写默认值）。

##### A2-0.8 相关方块 tag（R-06 / R-07 的 fallback 与触发门禁）

全部定义在 `net/dries007/tfc/common/TFCTags.java:383-386`：

| 常量 | tag id | 真实 tag 文件内容（`jar-extract/data/tfc/tags/block/`） |
| --- | --- | --- |
| `CAN_TRIGGER_COLLAPSE` | `tfc:can_trigger_collapse` | `["#c:ores","#c:stones"]` |
| `CAN_START_COLLAPSE` | `tfc:can_start_collapse` | `["#c:ores","#c:stones/raw"]` |
| `CAN_COLLAPSE` | `tfc:can_collapse` | `["#c:ores","#c:stones","#c:stones/smooth","#c:stones/spike"]` |
| `CAN_LANDSLIDE` | `tfc:can_landslide` | 长名单，共 **189 项**（cobble/mossy_cobble/gravel/sand/deposit/mud/coarse_dirt/duff/clay_duff/kaolin 等，均为具体方块 id 而非 tag 引用） |

另有 `SUPPORTS_LANDSLIDE = tfc:supports_landslide`（值为 `["#tfc:farmlands","#tfc:paths"]`）与 `NOT_SOLID_SUPPORTING = tfc:not_solid_supporting`（值为 `["#c:stones/smooth"]`），它们在 `LandslideRecipe.isSupportedOnSide` 与 `CollapseRecipe.canStartCollapse` 中被读取。

---

### [R-06] tfc:collapse —— 塌方

##### R-06.1 类型标识与实现类

| 项目 | 值 | 证据 |
| --- | --- | --- |
| JSON `type` | `tfc:collapse` | `net/dries007/tfc/common/recipes/TFCRecipeSerializers.java:58` |
| recipe type id | `tfc:collapse` | `net/dries007/tfc/common/recipes/TFCRecipeTypes.java:44` |
| serializer id | `tfc:collapse` | `TFCRecipeSerializers.java:58`，由 `BlockRecipe.serializer(CollapseRecipe::new)` 构造 |
| 实现类全名 | `net.dries007.tfc.common.recipes.CollapseRecipe` | `net/dries007/tfc/common/recipes/CollapseRecipe.java:64` |
| 继承关系 | `CollapseRecipe extends BlockRecipe` | `CollapseRecipe.java:64-65` |
| 父类 | `net.dries007.tfc.common.recipes.BlockRecipe` | `net/dries007/tfc/common/recipes/BlockRecipe.java:41-43` |
| 实现的接口 | `INoopInputRecipe`、`IRecipePredicate<BlockState>`（均由父类 `BlockRecipe` 实现） | `BlockRecipe.java:41-43` |
| `getType()` | `TFCRecipeTypes.COLLAPSE.get()` | `CollapseRecipe.java:183-185` |
| `getSerializer()` | `TFCRecipeSerializers.COLLAPSE.get()` | `CollapseRecipe.java:179-181` |
| 匹配输入类型 | `BlockState`（`IRecipePredicate<BlockState>`） | `BlockRecipe.java:64-67` |

**类型名与序列化名一致**（均为 `collapse`）。

需要特别注意的构造链（这是"字段来自父类"的根源）：

```java
// TFCRecipeSerializers.java:58
register("collapse", BlockRecipe.serializer(CollapseRecipe::new))

// BlockRecipe.java:47-49
public static <R extends BlockRecipe> RecipeSerializer<R> serializer(BiFunction<BlockIngredient, Optional<BlockState>, R> factory) {
    return new RecipeSerializerImpl<R>(BlockRecipe.codec(factory), BlockRecipe.streamCodec(factory));
}
```

`BiFunction<BlockIngredient, Optional<BlockState>, R>` 的方法引用 `CollapseRecipe::new` 解析到的是**包私有**构造 `CollapseRecipe(BlockIngredient, Optional<BlockState>)`（`CollapseRecipe.java:171-173`），而不是公开构造 `CollapseRecipe(BlockIngredient, BlockState)`（167-169 行，该构造把 `BlockState` 包成 `Optional.of`）。二者最终都调用 `super(ingredient, output)`。

##### R-06.2 完整字段表

`collapse` **没有自己的 CODEC**，字段表完全来自父类 `BlockRecipe` 的静态 `codec(...)` 工厂（`BlockRecipe.java:51-53`），逐行如下：

```java
public static <R extends BlockRecipe> MapCodec<R> codec(BiFunction<BlockIngredient, Optional<BlockState>, R> factory) {
    return RecordCodecBuilder.mapCodec(i -> i.group(
        BlockIngredient.CODEC.fieldOf("ingredient").forGetter(c -> c.ingredient),
        Codecs.BLOCK_STATE.optionalFieldOf("result").forGetter(c -> c.output)
    ).apply(i, factory));
}
```

| 字段名 | 类型 | 必需/可选 | 默认值 | 语义 | 来源 |
| --- | --- | --- | --- | --- | --- |
| `ingredient` | `BlockIngredient`：`Block` id 数组，或方块 tag 字符串（`Codec.either`） | **必需**（`fieldOf`） | 无（缺失即解析失败） | 判定"哪些方块会发生塌方"。匹配时只比较 `BlockState.getBlock()`，**不考虑方块状态属性**（`BlockRecipe.java:65-67` → `BlockIngredient.test`） | `BlockRecipe.java:52` |
| `result` | `BlockState`（`Codecs.BLOCK_STATE`：方块 id 字符串，或带 `Properties` 的完整状态对象） | **可选**（`optionalFieldOf`） | `Optional.empty()`（即"无替换"，塌方后仍生成原方块） | 塌方时替换成的新方块状态。父类 `assembleBlock(BlockState input)` 返回 `output.orElse(input)`（`BlockRecipe.java:74-76`） | `BlockRecipe.java:52` |

**没有其它字段。** 特别地：

- `collapse` 没有 `duration`、没有 `sound`、没有掉落表字段——掉落完全走方块自身战利品表（`collapseBlock` 只做 `level.setBlockAndUpdate` + 生成 `TFCFallingBlockEntity`，见 `CollapseRecipe.java:159-161`）。
- `result` 缺失是**完全合法**的：此时 `assembleBlock` 返回原状态，效果是"方块原地碎裂成同种下落方块"。这一路径在 fallback 配方中被使用（见 R-06.4）。
- 真实数据验证：`jar-extract/data/tfc/recipe/collapse/` 下 525 个文件中，**没有 `result` 的文件数 = 0**。也就是说官方数据虽然允许省略，但全部显式写了 `result`。

##### R-06.3 真实 JSON 样例

**样例 1（最常见结构：矿石降级）** —— 相对路径 `data/tfc/recipe/collapse/ore/normal_bismuthinite/andesite.json`，内容为文件原文：

```json
{"type":"tfc:collapse","ingredient":["tfc:ore/rich_bismuthinite/andesite"],"result":"tfc:ore/normal_bismuthinite/andesite"}
```

语义：安山岩中的**富铋华矿**塌方后变成**普通铋华矿**（富矿在塌方中"降级"）。

`collapse/ore/` 的实际结构（已逐项核查）：一级子目录 **24 个** = `normal_*` 12 个（`bismuthinite`、`cassiterite`、`garnierite`、`hematite`、`limonite`、`magnetite`、`malachite`、`native_copper`、`native_gold`、`native_silver`、`sphalerite`、`tetrahedrite`）+ `poor_*` 同名 12 个，每个子目录含 21 种岩石文件，故 24 × 21 = **504**，与统计一致。两个方向构成两条链条：

| 目录 | 输入 `ingredient` | 输出 `result` | 文件数 |
| --- | --- | --- | --- |
| `collapse/ore/normal_<ore>/<rock>.json` | `tfc:ore/rich_<ore>/<rock>` | `tfc:ore/normal_<ore>/<rock>` | 12 × 21 = 252 |
| `collapse/ore/poor_<ore>/<rock>.json` | `tfc:ore/normal_<ore>/<rock>` | `tfc:ore/poor_<ore>/<rock>` | 12 × 21 = 252 |

已核查：`normal_bismuthinite/` 下 21 个文件的 `ingredient` **全部**以 `tfc:ore/rich_bismuthinite/` 开头（无一例外）。

**样例 2（同一链条的另一种矿石；同时给出"普通→贫"方向的文件以便对照）** —— 相对路径 `data/tfc/recipe/collapse/ore/normal_native_copper/granite.json`：

```json
{"type":"tfc:collapse","ingredient":["tfc:ore/rich_native_copper/granite"],"result":"tfc:ore/normal_native_copper/granite"}
```

与之配对的下一级（相对路径 `data/tfc/recipe/collapse/ore/poor_native_copper/granite.json`）：

```json
{"type":"tfc:collapse","ingredient":["tfc:ore/normal_native_copper/granite"],"result":"tfc:ore/poor_native_copper/granite"}
```

**这三条放在一起就能看出设计意图**：普通铜矿塌方变贫铜矿、富铜矿塌方变普通铜矿——同一种矿石在反复塌方中逐级降级；而 `collapse/ore/poor_*/` 的输入正好是 `normal_*` 的输出，两个目录首尾相接。

**样例 3（结构明显不同：单个 `result` 对应 33 个 `ingredient` 元素）** —— 相对路径 `data/tfc/recipe/collapse/rock/cobble/andesite.json`（注意此类文件位于 `collapse/rock/cobble/`，**不是** `collapse/rock/` 直接子文件）；内容为文件原文（单行，已按原样给出）：

```json
{"type":"tfc:collapse","ingredient":["tfc:rock/raw/andesite","tfc:rock/hardened/andesite","tfc:rock/smooth/andesite","tfc:rock/cracked_bricks/andesite","tfc:ore/poor_native_copper/andesite","tfc:ore/poor_native_gold/andesite","tfc:ore/poor_hematite/andesite","tfc:ore/poor_native_silver/andesite","tfc:ore/poor_cassiterite/andesite","tfc:ore/poor_bismuthinite/andesite","tfc:ore/poor_garnierite/andesite","tfc:ore/poor_malachite/andesite","tfc:ore/poor_magnetite/andesite","tfc:ore/poor_limonite/andesite","tfc:ore/poor_sphalerite/andesite","tfc:ore/poor_tetrahedrite/andesite","tfc:ore/gypsum/andesite","tfc:ore/cinnabar/andesite","tfc:ore/cryolite/andesite","tfc:ore/borax/andesite","tfc:ore/graphite/andesite","tfc:ore/saltpeter/andesite","tfc:ore/sulfur/andesite","tfc:ore/sylvite/andesite","tfc:ore/amethyst/andesite","tfc:ore/diamond/andesite","tfc:ore/emerald/andesite","tfc:ore/lapis_lazuli/andesite","tfc:ore/opal/andesite","tfc:ore/pyrite/andesite","tfc:ore/ruby/andesite","tfc:ore/sapphire/andesite","tfc:ore/topaz/andesite"],"result":"tfc:rock/cobble/andesite"}
```

语义：安山岩的**所有"可塌形态"**塌方后**统一收敛为** `tfc:rock/cobble/andesite`（安山岩圆石）。33 个元素的构成（逐个清点）：4 种岩石形态（`rock/raw`、`rock/hardened`、`rock/smooth`、`rock/cracked_bricks`）+ 12 种贫金属矿（native_copper、native_gold、hematite、native_silver、cassiterite、bismuthinite、garnierite、malachite、magnetite、limonite、sphalerite、tetrahedrite）+ 8 种工业/盐类矿（gypsum、cinnabar、cryolite、borax、graphite、saltpeter、sulfur、sylvite）+ 9 种宝石矿（amethyst、diamond、emerald、lapis_lazuli、opal、pyrite、ruby、sapphire、topaz）= 4 + 12 + 8 + 9 = 33。这是本类型中"多对一收敛"写法的典型代表。

`collapse/rock/cobble/` 目录共 **21 个文件**，对应 21 种岩石，每个文件结构与上面完全一致（33 元素 → `tfc:rock/cobble/<rock>`）。其余 20 个文件名为：`basalt.json`、`chalk.json`、`chert.json`、`claystone.json`、`conglomerate.json`、`dacite.json`、`diorite.json`、`dolomite.json`、`gabbro.json`、`gneiss.json`、`granite.json`、`limestone.json`、`marble.json`、`phyllite.json`、`quartzite.json`、`rhyolite.json`、`schist.json`、`shale.json`、`slate.json`、`tuff.json`。

> 与 `chisel` 的对照：`collapse` 的字段里**没有 `mode`、没有 `item_output`**，其 `ingredient` 是"方块 id 数组"而 `result` 是"单个方块状态"；而 `chisel`（R-08）必须有 `mode`，且可选 `item_output`。二者的 JSON 结构不会混淆。

##### R-06.4 fallback 配方（无 JSON 也能塌方）

这是 `collapse` 最容易被忽略、但对数据包作者最重要的一点（`CollapseRecipe.java:66-77`）：

```java
public static final IndirectHashCollection<Block, CollapseRecipe> CACHE =
        IndirectHashCollection.createForRecipe(recipe -> recipe.getBlockIngredient().blocks(), TFCRecipeTypes.COLLAPSE);
private static final CollapseRecipe FALLBACK = new CollapseRecipe();   // 67 行

@Nullable
public static CollapseRecipe getRecipe(BlockState input) {
    @Nullable CollapseRecipe recipe = RecipeHelpers.getRecipe(CACHE, input, input.getBlock());
    return recipe == null && FALLBACK.matches(input) ? FALLBACK : recipe;
}
```

其中 `FALLBACK` 的构造（`CollapseRecipe.java:175-177`）：

```java
CollapseRecipe() {
    super(BlockIngredient.of(TFCTags.Blocks.CAN_COLLAPSE), Optional.empty());
}
```

结论（源码级确证）：

1. 先按方块种类在 JSON 配方索引里查；**查不到**时，若该方块属于 `#tfc:can_collapse` 标签（值为 `["#c:ores","#c:stones","#c:stones/smooth","#c:stones/spike"]`），则使用 `FALLBACK`。
2. `FALLBACK` 的 `result` 为空 → 塌方后保留原方块状态（即"整块掉下来"）。
3. 因此：**collapsed 的 JSON 配方只用于"改变方块"的场景；"不改变方块但会塌"的场景由 tag 兜底，无需 JSON。**

##### R-06.5 游戏内触发条件

全部调用点由 grep 源码确认，逐条列出（路径均相对 `moddev/src-ref/TFC-decompiled`）：

| # | 触发场景 | 调用点（文件:行） | 关键代码与 input 容器 |
| --- | --- | --- | --- |
| 1 | 玩家/实体**破坏方块** | `net/dries007/tfc/ForgeEventHandler.java:469-477` | `onBlockBroken(BlockEvent.BreakEvent)`：`if (Helpers.isBlock(state, TFCTags.Blocks.CAN_TRIGGER_COLLAPSE) && levelAccess instanceof Level) { CollapseRecipe.tryTriggerCollapse(level, pos); return; }` |
| 2 | **凿子右键**方块 | `net/dries007/tfc/common/items/ChiselItem.java:71` | `if (TFCConfig.SERVER.enableChiselsStartCollapses.get() && Helpers.isBlock(state, TFCTags.Blocks.CAN_TRIGGER_COLLAPSE) && CollapseRecipe.tryTriggerCollapse(level, pos)) return InteractionResult.CONSUME;` |
| 3 | **爆炸**波及 | `net/dries007/tfc/ForgeEventHandler.java:523-528` → `net/dries007/tfc/util/tracker/WorldTracker.java:111-123` | `onExplosionDetonate` 调 `addCollapsePositions(centerPos, event.getExplosion().getToBlow())`；该方法按 `TFCConfig.SERVER.collapseExplosionPropagateChance` 采样并 `addCollapseData(...)` |
| 4 | 塌方**传播**（世界 tick） | `net/dries007/tfc/util/tracker/WorldTracker.java:137-153` | `tick()` 中 `random.nextInt(10) == 0` 时遍历 `collapsesInProgress`，条件包含 `CollapseRecipe.canCollapse(stateAt)`，然后 `CollapseRecipe.collapseBlock(level, posAt, stateAt)` |
| 5 | 塌方**蔓延**（同一函数内） | `CollapseRecipe.java:123-146` | `startCollapse(Level, BlockPos)` 在 `±radius / -4..+4` 范围内找空腔后逐格 `collapseBlock(level, posAt, stateAt, true)`，并把结果登记进 `WorldTracker.get(level).addCollapseData(new Collapse(...))` |
| 6 | **石笋**失去支撑 | `net/dries007/tfc/common/blocks/rock/RockSpikeBlock.java:178` | `if (CollapseRecipe.collapseBlock((Level)level, pos, state)) { ... } else { level.destroyBlock(pos, true); }` |
| 7 | 玩家端**视觉提示** | `net/dries007/tfc/common/blocks/rock/RawRockBlock.java:39-46` | `animateTick`：`random.nextInt(64) == 0 && CollapseRecipe.canStartCollapse(level, pos) && !Support.isSupported(level, pos)` 时生成 `FALLING_DUST` 粒子（纯客户端表现，不触发塌方） |

`tryTriggerCollapse` 的判定细节（`CollapseRecipe.java:79-114`）：

```java
if (!level.isClientSide() && level.isAreaLoaded(pos, 32)) {
    boolean realCollapse = (double) random.nextFloat() < TFCConfig.SERVER.collapseTriggerChance.get();
    boolean fakeCollapse = !realCollapse && (double) random.nextFloat() < TFCConfig.SERVER.collapseFakeTriggerChance.get();
    ...
    for (BlockPos checking : Support.findUnsupportedPositions(level, pos.offset(-radX,-radY,-radZ), pos.offset(radX,radY,radZ))) {
        if (checking.equals(pos) || !CollapseRecipe.canStartCollapse(level, checking)) continue;
        ...
        if (CollapseRecipe.startCollapse(level, checking)) level.playSound(null, pos, TFCSounds.ROCK_SLIDE_LONG.get(), ...);
```

- 触发有**概率门禁**：真实塌方 `collapseTriggerChance`，假塌方（只响声音/粒子）`collapseFakeTriggerChance`。
- 只有 `canStartCollapse(...)` 为真的位置才能"起塌"（`CollapseRecipe.java:116-121`）：状态属于 `#tfc:can_start_collapse`，且下方满足"可穿过 / 非完整碰撞形状 / 属于 `#tfc:not_solid_supporting`"三者之一。
- 假塌方会向 `NeoForge.EVENT_BUS` 抛出 `CollapseEvent`（`CollapseRecipe.java:104`）并播放 `levelEvent 2001`（方块破坏粒子）。

**input 容器**：`collapse` 不使用物品/GUI 输入容器。它实现 `INoopInputRecipe`（`net/dries007/tfc/common/recipes/INoopInputRecipe.java`），其 `matches(NoopInput, Level)` / `assemble(NoopInput, ...)` 直接抛 `UnsupportedOperationException`（`INoopInputRecipe.java:23-36`），真正的判定入口是 `IRecipePredicate<BlockState>.matches(BlockState)`（`BlockRecipe.java:64-67`）。查询方式是绕开 RecipeManager 的 `IndirectHashCollection` 索引（`CollapseRecipe.java:66`）：

```java
RecipeHelpers.getRecipe(CACHE, input, input.getBlock())   // RecipeHelpers.java:134-136
```

##### R-06.6 塌方后的产物与实体

`collapseBlock`（`CollapseRecipe.java:152-165`）是唯一把配方结果落到世界里的地方：

```java
CollapseRecipe recipe = CollapseRecipe.getRecipe(state);
if (recipe != null) {
    BlockPos posBelow = pos.below();
    if (destroyBlockBelow && !TFCFallingBlockEntity.canFallThrough(level, posBelow, Direction.DOWN, Blocks.BEDROCK.defaultBlockState())) {
        level.destroyBlock(posBelow, true);
    }
    BlockState collapseState = recipe.assembleBlock(state);
    level.setBlockAndUpdate(pos, collapseState);
    level.addFreshEntity(new TFCFallingBlockEntity(level, pos.getX()+0.5, pos.getY(), pos.getZ()+0.5, collapseState, 2.0f, 20));
    return true;
}
return false;
```

- `assembleBlock(state)` 返回 `result`（若给出）或原状态 → **这就是 `result` 字段影响世界的唯一入口**。
- 生成的下落实体参数为 `gravity=2.0f, lifetime=20`（塌方下落更快、存活更短）。
- `destroyBlockBelow=true` 时（仅蔓延路径使用）会先破坏下方方块。

##### R-06.7 与 `landslide` 的字段对照（快速索引）

| 维度 | `tfc:collapse` | `tfc:landslide` |
| --- | --- | --- |
| 父类 | `BlockRecipe` | `BlockRecipe` |
| 字段 | `ingredient`（必填）、`result`（可选） | `ingredient`（必填）、`result`（可选） |
| 是否二者字段完全相同 | **完全相同**（同一个 `BlockRecipe.codec`） | 同左 |
| 区别所在 | 语义、触发链路、fallback tag（`can_collapse`） | 语义、触发链路、fallback tag（`can_landslide`） |

也就是说：**`collapse` 与 `landslide` 在 JSON 层面无法靠字段区分，只能靠 `type` 区分。** 二者的 `result` 都用于"替换方块"，但触发它们的方块 tag 与配置项完全不同（见 R-07.5）。

---

### [R-07] tfc:landslide —— 滑坡

##### R-07.1 类型标识与实现类

| 项目 | 值 | 证据 |
| --- | --- | --- |
| JSON `type` | `tfc:landslide` | `net/dries007/tfc/common/recipes/TFCRecipeSerializers.java:59` |
| recipe type id | `tfc:landslide` | `net/dries007/tfc/common/recipes/TFCRecipeTypes.java:45` |
| serializer id | `tfc:landslide` | `TFCRecipeSerializers.java:59`，由 `BlockRecipe.serializer(LandslideRecipe::new)` 构造 |
| 实现类全名 | `net.dries007.tfc.common.recipes.LandslideRecipe` | `net/dries007/tfc/common/recipes/LandslideRecipe.java:49` |
| 继承关系 | `LandslideRecipe extends BlockRecipe` | `LandslideRecipe.java:49-50` |
| 实现的接口 | `INoopInputRecipe`、`IRecipePredicate<BlockState>`（继承自父类） | `BlockRecipe.java:41-43` |
| `getType()` | `TFCRecipeTypes.LANDSLIDE.get()` | `LandslideRecipe.java:139-141` |
| `getSerializer()` | `TFCRecipeSerializers.LANDSLIDE.get()` | `LandslideRecipe.java:135-137` |
| 匹配输入类型 | `BlockState` | `BlockRecipe.java:64-67` |

**类型名与序列化名一致。**

##### R-07.2 完整字段表

与 `collapse` 相同，字段 100% 来自父类 `BlockRecipe` 的 `codec(...)`（`BlockRecipe.java:51-53`）——**`LandslideRecipe` 自身没有声明任何 `CODEC` 常量，也没有任何 record 组件**（`LandslideRecipe.java` 全文 143 行，只有静态方法与 `matches` 逻辑）。

| 字段名 | 类型 | 必需/可选 | 默认值 | 语义 | 来源 |
| --- | --- | --- | --- | --- | --- |
| `ingredient` | `BlockIngredient`（方块 id 数组，或方块 tag 字符串） | **必需**（`fieldOf`） | 无 | 哪些方块会滑坡。只比较方块种类（`BlockIngredient.test(BlockState)` → `test(Block)`） | `BlockRecipe.java:52` |
| `result` | `BlockState`（`Codecs.BLOCK_STATE`） | **可选**（`optionalFieldOf`） | `Optional.empty()` | 滑坡后替换成的方块；`assembleBlock` 返回 `output.orElse(input)` | `BlockRecipe.java:52`、`74-76` |

**没有其它字段。** 特别地：

- 没有 `duration` / `sound` / `target` / `direction` 之类的字段——滑坡的方向由 `LandslideRecipe.getLandslidePos(...)` 在运行时按周围支撑情况**计算**得出（见 R-07.5），而不是由 JSON 指定。
- `result` 省略时表示"方块滑动但不变形"。真实数据中 21 个文件全部写了 `result`（实际检索：21/21）。

##### R-07.3 真实 JSON 样例

`landslide` 全库 21 个文件，完整清单如下（相对 `jar-extract/data/tfc/recipe/`）：

```
landslide/cobblestone.json          landslide/clay/alfisol.json      landslide/dirt/alfisol.json
landslide/dirt.json                 landslide/clay/andisol.json      landslide/dirt/andisol.json
landslide/gravel.json               landslide/clay/aridisol.json     landslide/dirt/aridisol.json
landslide/red_kaolin_clay.json      landslide/clay/entisol.json      landslide/dirt/entisol.json
landslide/sand.json                 landslide/clay/fluvisol.json     landslide/dirt/fluvisol.json
                                    landslide/clay/mollisol.json      landslide/dirt/mollisol.json
                                    landslide/clay/oxisol.json        landslide/dirt/oxisol.json
                                    landslide/clay/podzol.json        landslide/dirt/podzol.json
```

**样例 1（单一方块，最简形态）** —— 相对路径 `data/tfc/recipe/landslide/dirt.json`：

```json
{"type":"tfc:landslide","ingredient":["minecraft:dirt"],"result":"minecraft:dirt"}
```

**样例 2（同类型不同方块）** —— 相对路径 `data/tfc/recipe/landslide/cobblestone.json`：

```json
{"type":"tfc:landslide","ingredient":["minecraft:cobblestone"],"result":"minecraft:cobblestone"}
```

**样例 3（结构不同的 1：多元素 `ingredient` + 单一 `result`，即"多个输入 → 一个输出"的收敛式写法）** —— 相对路径 `data/tfc/recipe/landslide/clay/alfisol.json`：

```json
{"type":"tfc:landslide","ingredient":["tfc:clay/alfisol","tfc:clay_grass/alfisol","tfc:clay_duff/alfisol"],"result":"tfc:clay/alfisol"}
```

语义：三种带草/腐殖层的粘土（`clay/`、`clay_grass/`、`clay_duff/`）发生滑坡时，**全部**退化为裸露的 `tfc:clay/alfisol`（草皮与腐殖层在滑坡中剥离）。这是 `landslide` 相对于 `collapse` 的典型结构差异：一个 `result` 对应多个 `ingredient` 元素。

**样例 4（结构不同的 2：`ingredient` 与 `result` 非同种方块——"草皮剥离"式）** —— 相对路径 `data/tfc/recipe/landslide/red_kaolin_clay.json`：

```json
{"type":"tfc:landslide","ingredient":["tfc:kaolin_clay_grass"],"result":"tfc:red_kaolin_clay"}
```

语义：**带草的红高岭土**（`tfc:kaolin_clay_grass`）滑坡后变成**裸露的红高岭土**（`tfc:red_kaolin_clay`）——注意这两个 id 的命名并不对称（前者叫 `kaolin_clay_grass`，后者叫 `red_kaolin_clay`），这正是必须用 JSON 显式声明、无法靠命名规则推导的原因。

**样例 5（结构不同的 3：6 元素 `ingredient`，覆盖土壤的所有表层形态）** —— 相对路径 `data/tfc/recipe/landslide/dirt/alfisol.json`：

```json
{"type":"tfc:landslide","ingredient":["tfc:dirt/alfisol","tfc:grass/alfisol","tfc:duff/alfisol","tfc:grass_path/alfisol","tfc:farmland/alfisol","tfc:rooted_dirt/alfisol"],"result":"tfc:dirt/alfisol"}
```

语义：淋溶土的**土、草方块、腐殖层、草径、耕地、生根土**六种形态滑坡后统一变为普通淋溶土（`tfc:dirt/alfisol`）。`landslide/dirt/` 与 `landslide/clay/` 两个目录各 8 个文件（共 16 个）都是这一结构，区别仅在土壤系列名。

> 对比小结：`landslide` 的三种真实结构分别是「单元素 → 同名」（dirt/gravel/sand/cobblestone）、「单元素 → 异名」（red_kaolin_clay）、「多元素 → 收敛为一种」（clay/*、dirt/*）。三者字段集合完全相同，仅数组长度与 id 不同。

##### R-07.4 fallback 配方

与 `collapse` 同构（`LandslideRecipe.java:51-62`）：

```java
public static final IndirectHashCollection<Block, LandslideRecipe> CACHE =
        IndirectHashCollection.createForRecipe(recipe -> recipe.getBlockIngredient().blocks(), TFCRecipeTypes.LANDSLIDE);
private static final LandslideRecipe FALLBACK = new LandslideRecipe();   // 52 行

@Nullable
public static LandslideRecipe getRecipe(BlockState input) {
    @Nullable LandslideRecipe recipe = RecipeHelpers.getRecipe(CACHE, input, input.getBlock());
    return recipe == null && FALLBACK.matches(input) ? FALLBACK : recipe;
}

LandslideRecipe() {   // 131-133 行
    super(BlockIngredient.of(TFCTags.Blocks.CAN_LANDSLIDE), Optional.empty());
}
```

- `#tfc:can_landslide` 是一个 **189 项的长名单**（圆石/苔石圆石/砂砾/沙子/矿藏/泥/粗土/腐殖土/粘土腐殖层/高岭土等，逐项为具体方块 id，不含 tag 引用），远超 21 个 JSON 配方覆盖的范围。
- **因此：绝大多数会滑坡的方块并没有专属 JSON 配方**，它们靠 `FALLBACK` + `can_landslide` tag 工作，效果是"滑走但方块不变"。
- 21 个 JSON 配方的存在意义正是**改写默认行为**（例如让带草的粘土滑坡后掉草皮）。

##### R-07.5 游戏内触发条件与滑动方向计算

调用点（grep 全源码确认）：

| # | 触发场景 | 调用点（文件:行） | 关键代码 |
| --- | --- | --- | --- |
| 1 | **方块被放置** | `net/dries007/tfc/ForgeEventHandler.java:485-498` | `onBlockPlace`：`if (LandslideRecipe.canLandslide(state)) WorldTracker.get((Level)world).addLandslidePos(pos);` |
| 2 | **邻 block 更新** | `net/dries007/tfc/ForgeEventHandler.java:507-521` | `onNeighborUpdate`：对 `event.getNotifiedSides()` 的每个方向取邻位状态，`if (LandslideRecipe.canLandslide(state)) WorldTracker.get((Level)level).addLandslidePos(pos);` |
| 3 | **延迟 tick 执行** | `net/dries007/tfc/util/tracker/WorldTracker.java:154-162` | `tick()` 中：`this.landslideTicks.flush();` 后逐个 `TickEntry`，`if (entry.tick()) { LandslideRecipe.tryLandslide(this.level, entry.getPos(), currentState); ... }` |
| 4 | 入队实现（延迟 2 tick） | `net/dries007/tfc/util/tracker/WorldTracker.java:90-92` | `public void addLandslidePos(BlockPos pos) { this.landslideTicks.add(new TickEntry(pos, 2)); }` → **放置/更新后 2 tick 才真正判定** |
| 5 | **下落方块落地后** | `net/dries007/tfc/common/entities/misc/TFCFallingBlockEntity.java:216-218` | `afterPlacementAsBlock(...)`：`if (LandslideRecipe.canLandslide(fallingBlockState)) WorldTracker.get(this.level()).addLandslidePos(posAt);` |
| 6 | 拦截**原版下落方块** | `net/dries007/tfc/mixin/FallingBlockMixin.java:30-35` | `@Inject(method="tick", at=@At("HEAD"), cancellable=true)`：`if (LandslideRecipe.getRecipe(state) != null) ci.cancel();` → 有 TFC 滑坡配方的方块**不再走原版 FallingBlock 逻辑** |
| 7 | **世界生成**阶段 | `net/dries007/tfc/world/feature/ErosionFeature.java:76` | `LandslideRecipe recipe = stateAt.isAir() ? null : LandslideRecipe.getRecipe(stateAt);` 用于在地形生成时判断"该方块会不会滑走"，进而决定是否用硬化岩填充（同文件 78-99 行） |

`tryLandslide` 的完整流程（`LandslideRecipe.java:64-87`）：

```java
public static boolean tryLandslide(Level level, BlockPos pos, BlockState state) {
    BlockPos fallPos;
    if (!level.isClientSide() && TFCConfig.SERVER.enableBlockLandslides.get()
        && (fallPos = LandslideRecipe.getLandslidePos(level, pos, state)) != null) {
        LandslideRecipe recipe = LandslideRecipe.getRecipe(state);
        if (recipe != null) {
            BlockState fallingState = recipe.assembleBlock(state);
            if (!fallPos.equals(pos)) {
                level.removeBlock(pos, false);
                if (!FluidHelpers.isAirOrEmptyFluid(level.getBlockState(fallPos))) level.destroyBlock(fallPos, true);
            }
            if (TFCConfig.SERVER.farmlandMakesTheBestRaceTracks.get()) level.setBlockAndUpdate(fallPos, fallingState);
            else level.setBlock(fallPos, fallingState, 18);
            level.playSound(null, pos, TFCSounds.DIRT_SLIDE_SHORT.get(), SoundSource.BLOCKS, 0.4f, 1.0f);
            level.addFreshEntity(new TFCFallingBlockEntity(level, fallPos.getX()+0.5, fallPos.getY(), fallPos.getZ()+0.5, fallingState, 0.8f, 10));
        }
        return true;
    }
    return false;
}
```

- 受 `TFCConfig.SERVER.enableBlockLandslides` 总开关控制。
- 生成下落实体参数 `gravity=0.8f, lifetime=10`（**比塌方慢得多、存活短**，与 collapse 的 2.0f/20 明显不同）。
- `farmlandMakesTheBestRaceTracks` 决定是否用 `setBlockAndUpdate`（会触发邻块更新）还是 flag 18（不触发邻块更新）——这是防止滑坡连锁递归的保护开关。

**滑向哪里（`getLandslidePos`，`LandslideRecipe.java:89-115`）**：

```java
if (Support.isSupported(level, pos)) return null;                       // 有支撑 → 不滑
if (TFCFallingBlockEntity.canFallThrough(level, pos.below(), Direction.DOWN, fallingState)) return pos;  // 正下方可穿 → 原地掉落
if (!LandslideRecipe.isSupportedOnSide(level, pos, Direction.UP)) {     // 上方无支撑
    int supportedDirections = 0;
    for (Direction side : Direction.Plane.HORIZONTAL) {
        if (LandslideRecipe.isSupportedOnSide(level, pos, side)) { if (++supportedDirections >= 2) return null; continue; }
        ...  // 收集可侧滑方向
    }
    if (!possibleDirections.isEmpty()) return possibleDirections.get(level.getRandom().nextInt(possibleDirections.size()));
}
return null;
```

要点：

1. **支撑判定优先**：`Support.isSupported`（`net/dries007/tfc/util/data/Support.java`，数据在 `jar-extract/data/tfc/tfc/support/` 下）为真则完全不滑。
2. 正下方可穿 → 原地化为下落方块。
3. 否则进入**侧向滑坡**：只有"未被侧面支撑、且侧位与侧位下方都可穿"的方向才是候选；随机挑一个方向作为落点。
4. `isSupportedOnSide`（117-121 行）：邻块"在朝向本方块的那一面是坚固面"（`isFaceSturdy`）**或**邻块属于 `#tfc:supports_landslide`（`["#tfc:farmlands","#tfc:paths"]`）。

**input 容器**：与 `collapse` 一样，`landslide` 不使用物品/GUI 输入容器，走 `INoopInputRecipe` + `IndirectHashCollection` 索引，判定入口为 `IRecipePredicate<BlockState>.matches(BlockState)`。

##### R-07.6 `collapse` 与 `landslide` 的关键差异汇总（数据包作者视角）

| 对比项 | `tfc:collapse`（R-06） | `tfc:landslide`（R-07） |
| --- | --- | --- |
| JSON 字段 | `ingredient`（必填）、`result`（可选） | 同左（**完全一致**） |
| 字段来源 | `BlockRecipe.codec`（`BlockRecipe.java:51-53`） | 同左 |
| 触发 tag | `#tfc:can_trigger_collapse`（触发）、`#tfc:can_start_collapse`（起塌）、`#tfc:can_collapse`（fallback） | `#tfc:can_landslide`（触发 + fallback），另有 `#tfc:supports_landslide` |
| 触发方式 | 破坏方块 / 凿子右键 / 爆炸 / 蔓延 | 放置 / 邻块更新（延迟 2 tick）/ 下落落地 / 地形生成 |
| 下落实体参数 | `gravity 2.0f`、`lifetime 20` | `gravity 0.8f`、`lifetime 10` |
| 是否原地（多数情况） | 是（原地起塌，随机半径蔓延） | 否（向侧方寻找落点，原地被 `removeBlock`） |
| 官方数据量 | 525 | 21 |
| 是否拦截原版方块行为 | 否 | 是（`FallingBlockMixin`，针对原版 `FallingBlock.tick`） |
| 配置开关 | `collapseTriggerChance`、`collapseFakeTriggerChance`、`collapseMinRadius`、`collapseRadiusVariance`、`collapsePropagateChance`、`collapseExplosionPropagateChance` | `enableBlockLandslides`、`farmlandMakesTheBestRaceTracks` |

---

### [R-08] tfc:chisel —— 凿刻

##### R-08.1 类型标识与实现类

| 项目 | 值 | 证据 |
| --- | --- | --- |
| JSON `type` | `tfc:chisel` | `net/dries007/tfc/common/recipes/TFCRecipeSerializers.java:60` |
| recipe type id | `tfc:chisel` | `net/dries007/tfc/common/recipes/TFCRecipeTypes.java:46` |
| serializer id | `tfc:chisel` | `TFCRecipeSerializers.java:60`（`register("chisel", ChiselRecipe.CODEC, ChiselRecipe.STREAM_CODEC)`） |
| 实现类全名 | `net.dries007.tfc.common.recipes.ChiselRecipe` | `net/dries007/tfc/common/recipes/ChiselRecipe.java:61-62` |
| 继承关系 | **无父类**，直接 `implements INoopInputRecipe` | `ChiselRecipe.java:61-62` |
| `getType()` | `TFCRecipeTypes.CHISEL.get()` | `ChiselRecipe.java:123-125` |
| `getSerializer()` | `TFCRecipeSerializers.CHISEL.get()` | `ChiselRecipe.java:119-121` |
| 数据形态 | 普通 class（**不是 record**），4 个 final 字段 | `ChiselRecipe.java:66-69` |
| 匹配入口 | 自定义 `matches(BlockState state, ChiselMode mode)`（**非** `IRecipePredicate`） | `ChiselRecipe.java:127-129` |

**类型名与序列化名一致。**

与 R-06/R-07 的根本区别：`ChiselRecipe` **不继承 `BlockRecipe`**，它有自己的 `CODEC`，并且带一个**必需的 `mode` 字段**（凿刻模式注册表）。因此三类配方的 JSON 在结构上一眼可辨。

##### R-08.2 完整字段表

`ChiselRecipe.CODEC` 逐行如下（`ChiselRecipe.java:64`，源码为单行，此处按 `RecordCodecBuilder` 的分组顺序换行展示）：

```java
public static final MapCodec<ChiselRecipe> CODEC = RecordCodecBuilder.mapCodec(i -> i.group(
    BlockIngredient.CODEC.fieldOf("ingredient").forGetter(c -> c.ingredient),
    Codecs.BLOCK_STATE.fieldOf("result").forGetter(c -> c.output),
    ChiselMode.REGISTRY.byNameCodec().fieldOf("mode").forGetter(c -> c.mode),
    ItemStackProvider.CODEC.optionalFieldOf("item_output", ItemStackProvider.empty()).forGetter(c -> c.itemOutput)
).apply(i, ChiselRecipe::new));
```

| 字段名 | 类型 | 必需/可选 | 默认值 | 语义 | 来源 |
| --- | --- | --- | --- | --- | --- |
| `ingredient` | `BlockIngredient`（方块 id 数组，或方块 tag 字符串） | **必需**（`fieldOf`） | 无 | 被凿的方块。只比较方块种类 | `ChiselRecipe.java:64` |
| `result` | `BlockState`（`Codecs.BLOCK_STATE`） | **必需**（`fieldOf`，**注意与 R-06/R-07 不同：这里不可省略**） | 无 | 凿刻后放置到世界里的方块状态 | 同上 |
| `mode` | `ChiselMode`（注册表 `tfc:chisel_mode` 的元素 id） | **必需**（`fieldOf`） | 无（虽然注册表有默认元素 `tfc:smooth`，但 `byNameCodec().fieldOf(...)` 要求必须写出） | 该配方在哪种凿刻模式下生效；三种内置模式 id：`tfc:smooth`、`tfc:slab`、`tfc:stair` | 同上 |
| `item_output` | `ItemStackProvider` | **可选**（`optionalFieldOf`） | `ItemStackProvider.empty()`（即 `ItemStack.EMPTY` + 空 modifier 列表，等价"不给任何物品"） | 凿刻成功时**额外给予玩家的物品**（不改变世界中方块，仅作为掉落/返还） | 同上 |

**关键点（源码级确认）**：

1. `mode` 是 `ChiselRecipe` 与 `collapse`/`landslide` 的分水岭；匹配时要求**模式相同且方块匹配**（`ChiselRecipe.java:127-129`）：
   ```java
   public boolean matches(BlockState state, ChiselMode mode) {
       return this.mode == mode && this.ingredient.test(state);
   }
   ```
   注意这里是 `this.mode == mode` 的**引用相等**，因此比较的是注册表单例对象。
2. `item_output` 的消费点在 `ChiselItem`（`net/dries007/tfc/common/items/ChiselItem.java:74-77`）：
   ```java
   ChiselRecipe recipeUsed = ChiselRecipe.getRecipe(state, IPlayerInfo.get(player).chiselMode());
   if (recipeUsed != null && !(extraDrop = recipeUsed.getItemOutput(held)).isEmpty()) {
       ItemHandlerHelper.giveItemToPlayer(player, extraDrop);
   }
   ```
   而 `getItemOutput` 会**以手持凿子作为 modifier 的输入**（`ChiselRecipe.java:139-141`）：
   ```java
   public ItemStack getItemOutput(ItemStack chisel) { return this.itemOutput.getSingleStack(chisel); }
   ```
   即 `item_output` 里的 modifier 可以读取"凿子本身"作为输入物品（例如 `tfc:damage_crafting_remainder` 这类依赖输入的 modifier）。
3. `item_output` 的**真实数据规律**（实际统计 513 个文件）：**228 个文件带 `item_output`，285 个不带**。228 恰好等于 `mode = tfc:slab` 的文件数——即**所有 slab（半砖）配方都带 `item_output`，所有 smooth / stair 配方都不带**。这与机制吻合：把一整块方块凿成半砖时，世界里只留半砖，另一半以物品形式返还给玩家。
4. `item_output` 在真实数据中**全部使用 `ItemStackProvider` 的简写形式**（`{"count":N,"id":"..."}`）；检索 `"item_output"` 内含 `"modifiers"` 的文件数为 **0**（即官方数据未在 chisel 里用过 modifier）。
5. `ChiselRecipe` **没有** `validate`、没有 `Codec.xmap` 附加校验；`STREAM_CODEC`（`ChiselRecipe.java:65`）与 `CODEC` 字段一一对应，不含额外字段。

##### R-08.3 `mode` 字段的取值来源：`ChiselMode` 注册表

定义于 `net/dries007/tfc/common/player/ChiselMode.java`：

```java
// 59-61 行
public static final ResourceKey<Registry<ChiselMode>> KEY = ResourceKey.createRegistryKey(Helpers.identifier("chisel_mode"));
public static final DefaultedRegistry<ChiselMode> REGISTRY = new RegistryBuilder(KEY).sync(true).defaultKey(Helpers.identifier("smooth")).create();
public static final DeferredRegister<ChiselMode> MODES = DeferredRegister.create(KEY, "tfc");
// 62 / 79 / 101 行
public static final DeferredHolder<ChiselMode, ChiselMode> SMOOTH = register("smooth", new ChiselMode(0) { ... });
public static final DeferredHolder<ChiselMode, ChiselMode> SLAB   = register("slab",   new ChiselMode(100) { ... });
public static final DeferredHolder<ChiselMode, ChiselMode> STAIR  = register("stair",  new ChiselMode(200) { ... });
```

| 注册表 id | priority | `modifyStateForPlacement` 行为（源码事实） |
| --- | --- | --- |
| `tfc:smooth` | 0 | 直接返回 `chiseled`（不做任何状态修改，`ChiselMode.java:64-67`） |
| `tfc:slab` | 100 | 按命中面与命中点高度（`hit.getLocation().y - hit.getBlockPos().getY() > 0.5`）设置 `SlabBlock.TYPE` 为 `TOP`/`BOTTOM`，并用原方块流体填充（85-88 行）；**返回 null 时凿刻失败** |
| `tfc:stair` | 200 | 若结果是 `StairBlock`，用 `getStateForPlacement(new BlockPlaceContext(player, MAIN_HAND, new ItemStack(stair), hit))` 计算朝向（105-111 行） |

- 注册表默认元素为 `tfc:smooth`（60 行 `defaultKey`），模式顺序由 `setupOrdering()`（128-133 行）按 priority 排序后串成环（`next()`），供玩家按键循环切换。
- 当前模式由玩家数据持有：`net/dries007/tfc/common/player/IPlayerInfo.java:42-44` 声明 `ChiselMode chiselMode();` 与 `void cycleChiselMode();`，调用点见 `ChiselRecipe.java:74` 与 `ChiselItem.java:74`。
- **数据包侧含义**：`chisel_mode` 是**同步注册表**（`sync(true)`），第三方可为它注册新模式；但 JSON 里 `mode` 只能写已注册的 id，写错会在加载时报"未知注册表元素"。

##### R-08.4 真实 JSON 样例

`chisel` 全库 513 个，按目录分布：`rock/` 336（其中 `smooth/` 63 = 21 岩石 × 3 种模式产物、`chiseled/` 21、其余 6 个子目录 `bricks`/`cobble`/`cracked_bricks`/`mossy_bricks`/`mossy_cobble`/`raw` 各 42 = 21 × 2）、`alabaster/` 65、`wood/` 40、`cut_sandstone/` 21、`smooth_sandstone/` 21、`mud_bricks/` 16、`raw_sandstone/` 14（336+65+40+21+21+16+14 = 513 ✓）。按 `mode` 分布：`tfc:slab` 228、`tfc:stair` 228、`tfc:smooth` 57。

**样例 1（最简：仅 4 个必需字段之外无任何可选字段，`mode = smooth`）** —— 相对路径 `data/tfc/recipe/chisel/alabaster/polished.json`（文件原文）：

```json
{"type":"tfc:chisel","ingredient":["tfc:alabaster/raw"],"mode":"tfc:smooth","result":"tfc:alabaster/polished"}
```

语义：把**生石膏（`tfc:alabaster/raw`）**用平滑模式凿成**抛光石膏（`tfc:alabaster/polished`）**。注意此文件**不写 `item_output`**（使用默认 `ItemStackProvider.empty()`）。

**样例 2（多元素 `ingredient`："原石与硬化石都能凿成平滑"）** —— 相对路径 `data/tfc/recipe/chisel/rock/smooth/andesite.json`：

```json
{"type":"tfc:chisel","ingredient":["tfc:rock/raw/andesite","tfc:rock/hardened/andesite"],"mode":"tfc:smooth","result":"tfc:rock/smooth/andesite"}
```

**样例 3（带 `item_output` 的 slab 模式）** —— 相对路径 `data/tfc/recipe/chisel/alabaster/bricks/black_slab.json`：

```json
{"type":"tfc:chisel","ingredient":["tfc:alabaster/bricks/black"],"item_output":{"count":1,"id":"tfc:alabaster/bricks/black_slab"},"mode":"tfc:slab","result":"tfc:alabaster/bricks/black_slab"}
```

语义：把 1 块黑色石膏砖凿成半砖时，世界里的方块变为 `tfc:alabaster/bricks/black_slab`，**同时额外把 1 个同 id 的 `black_slab` 物品直接塞进玩家背包**（`ChiselItem.java:74-77` 的 `ItemHandlerHelper.giveItemToPlayer`）。

**样例 4（同一套结构但 `mode = stair` 且**不带** `item_output`，为与样例 3 形成对照）** —— 相对路径 `data/tfc/recipe/chisel/alabaster/bricks/blue_stairs.json`：

```json
{"type":"tfc:chisel","ingredient":["tfc:alabaster/bricks/blue"],"mode":"tfc:stair","result":"tfc:alabaster/bricks/blue_stairs"}
```

**样例 5（结构不同的第 3 种：`ingredient` 与 `result` 分属不同"命名家族"）** —— 相对路径 `data/tfc/recipe/chisel/cut_sandstone/red.json`：

```json
{"type":"tfc:chisel","ingredient":["tfc:smooth_sandstone/red"],"mode":"tfc:smooth","result":"tfc:cut_sandstone/red"}
```

语义：用平滑模式把红**平滑砂岩**凿成红**切割砂岩**——id 前缀从 `smooth_sandstone` 变成 `cut_sandstone`，证明 `result` 与 `ingredient` 的命名无需任何关系，完全由 JSON 决定。

**样例 6（木制品：与岩石完全同构，证明该配方类型与材质无关）** —— 相对路径 `data/tfc/recipe/chisel/wood/planks/acacia_slab.json`：

```json
{"type":"tfc:chisel","ingredient":["tfc:wood/planks/acacia"],"item_output":{"count":1,"id":"tfc:wood/planks/acacia_slab"},"mode":"tfc:slab","result":"tfc:wood/planks/acacia_slab"}
```

##### R-08.5 游戏内触发条件

| # | 触发场景 | 调用点（文件:行） | 关键代码 |
| --- | --- | --- | --- |
| 1 | 玩家**手持凿子右键**方块（主逻辑） | `net/dries007/tfc/common/items/ChiselItem.java:59-90` | `useOn(UseOnContext)`：先 `ChiselRecipe.computeResult(player, state, new BlockHitResult(...), true)`（65 行），成功则播放音效、发放 `item_output`、`level.setBlockAndUpdate(pos, resultState)`（79 行）、触发进度 `TFCAdvancements.CHISELED`（82 行）、`Helpers.damageItem(held, player, MAIN_HAND)`（84 行）、给物品加 10 tick 冷却（85 行） |
| 2 | **工具前置条件**（在配方匹配之前） | `net/dries007/tfc/common/recipes/ChiselRecipe.java:71-92` | `computeResult` 首行判定：`Helpers.isItem(held, TFCTags.Items.TOOLS_CHISEL) && Helpers.isItem(player.getOffhandItem(), TFCTags.Items.TOOLS_HAMMER)`；**主手必须是凿子（`#c:tools/chisel`），副手必须是锤子（`#c:tools/hammer`）**，否则直接 `Either.right(InteractionResult.PASS)` |
| 3 | 模式来源 | `ChiselRecipe.java:74` | `ChiselMode mode = IPlayerInfo.get(player).chiselMode();`（玩家按键循环切换，见 R-08.3） |
| 4 | 失败反馈 | `ChiselRecipe.java:76-88` | 无匹配配方 → 提示 `tfc.chisel.no_recipe` 并返回 `PASS`；`mode.modifyStateForPlacement` 返回 null → 提示 `tfc.chisel.cannot_place` 并返回 `FAIL` |
| 5 | 凿刻**同时可能引发塌方** | `net/dries007/tfc/common/items/ChiselItem.java:71` | 服务端分支中：`if (TFCConfig.SERVER.enableChiselsStartCollapses.get() && Helpers.isBlock(state, TFCTags.Blocks.CAN_TRIGGER_COLLAPSE) && CollapseRecipe.tryTriggerCollapse(level, pos)) return InteractionResult.CONSUME;`（**凿子凿含矿岩层会引发塌方**，见 R-06.5 第 2 条） |
| 6 | 客户端**预览高亮** | `net/dries007/tfc/client/ClientForgeEventHandler.java:487-490` | 瞄准方块时 `ChiselRecipe.computeResult(player, stateAt, hit, false).ifLeft(chiseled -> { IHighlightHandler.drawBox(poseStack, chiseled.getShape(level, pos), ...); event.setCanceled(true); })` → 凿刻后会变成的形状以半透明红框预览（`informWhy=false`，不弹提示） |
| 7 | JEI/EMI 展示 | `net/dries007/tfc/compat/jei/JEIIntegration.java:167`、`204` | `CHISEL = JEIIntegration.type("chisel", ChiselRecipe.class)`；`new ChiselRecipeCategory(CHISEL, gui)`；EMI 侧见 `net/dries007/tfc/compat/emi/EmiIntegration.java` |

**input 容器**：`chisel` 同样不使用物品/GUI 输入容器——它实现 `INoopInputRecipe`（`ChiselRecipe.java:61-62`），`matches(NoopInput, Level)` / `assemble(NoopInput, ...)` / `getRemainingItems(NoopInput)` 全部抛 `UnsupportedOperationException`（`INoopInputRecipe.java:23-36`）。实际查表路径绕开 `RecipeManager`，使用按方块索引的哈希集合（`ChiselRecipe.java:63`、`98-105`）：

```java
public static final IndirectHashCollection<Block, ChiselRecipe> CACHE =
        IndirectHashCollection.createForRecipe(r -> r.ingredient.blocks(), TFCRecipeTypes.CHISEL);

@Nullable
public static ChiselRecipe getRecipe(BlockState state, ChiselMode mode) {
    for (ChiselRecipe recipe : CACHE.getAll(state.getBlock())) {
        if (!recipe.matches(state, mode)) continue;
        return recipe;
    }
    return null;
}
```

注意 `getRecipe` **没有 fallback**（与 collapse/landslide 不同）：方块没有专属 chisel 配方时就是"不能凿"。

##### R-08.6 特殊辅助类在 chisel 中的可见形式

| 辅助类型 | 在 chisel JSON 中的形态 | 真实例子 |
| --- | --- | --- |
| `BlockIngredient` | `ingredient` 数组 | `["tfc:rock/raw/andesite","tfc:rock/hardened/andesite"]` |
| `Codecs.BLOCK_STATE` | `result` 字符串或对象 | `"result":"tfc:rock/smooth/andesite"` |
| `ChiselMode` 注册表 | `mode` 字符串 | `"mode":"tfc:smooth"` / `"mode":"tfc:slab"` / `"mode":"tfc:stair"` |
| `ItemStackProvider` | `item_output`（简写形式，无 modifier 实例） | `{"count":1,"id":"tfc:alabaster/bricks/black_slab"}` |

`ItemStackModifier` 在 chisel 中虽然**技术上可用**（`item_output` 就是用 `ItemStackProvider.CODEC` 解析的，因此支持 `{"modifiers":[...]}` 写法），但 TFC 自带 513 个文件**一个都没用**。第三方数据包若要用，写法与 R-09/R-10 完全相同（见 A2-0.4 / A2-0.5）。

### [R-09] tfc:barrel_sealed —— 木桶·封口配方

##### R-09.1 类型标识与实现类

| 项目 | 值 | 证据 |
| --- | --- | --- |
| JSON `type` | `tfc:barrel_sealed` | `net/dries007/tfc/common/recipes/TFCRecipeSerializers.java:71` |
| recipe type id | `tfc:barrel_sealed` | `net/dries007/tfc/common/recipes/TFCRecipeTypes.java:55` |
| serializer id | `tfc:barrel_sealed` | `TFCRecipeSerializers.java:71`（`register("barrel_sealed", SealedBarrelRecipe.CODEC, SealedBarrelRecipe.STREAM_CODEC)`） |
| 实现类全名 | `net.dries007.tfc.common.recipes.SealedBarrelRecipe` | `net/dries007/tfc/common/recipes/SealedBarrelRecipe.java:46-47` |
| 继承关系 | `SealedBarrelRecipe extends BarrelRecipe` | `SealedBarrelRecipe.java:46-47` |
| 父类 | `net.dries007.tfc.common.recipes.BarrelRecipe` | `net/dries007/tfc/common/recipes/BarrelRecipe.java:84-86` |
| 实现的接口（来自父类） | `INoopInputRecipe`、`IRecipePredicate<BarrelInventory>` | `BarrelRecipe.java:84-86` |
| `getType()` | `TFCRecipeTypes.BARREL_SEALED.get()` | `SealedBarrelRecipe.java:104-107` |
| `getSerializer()` | `TFCRecipeSerializers.SEALED_BARREL.get()` | `SealedBarrelRecipe.java:109-112` |
| 匹配输入类型 | `BarrelInventory`（`net/dries007/tfc/common/recipes/input/BarrelInventory.java`） | `BarrelRecipe.java:112-115` |
| 自己新增的字段 | `duration`、`onSeal`、`onUnseal`（3 个） | `SealedBarrelRecipe.java:50-52` |

**类型名与序列化名一致**（均为 `barrel_sealed`）。

##### R-09.2 完整字段表

字段来自**两处**：父类 `BarrelRecipe` 的 5 个字段 + 本类新增的 3 个字段。

**（1）父类 `BarrelRecipe.CODEC`（`BarrelRecipe.java:87`，单行源码，按分组顺序换行展示）**：

```java
public static final MapCodec<BarrelRecipe> CODEC = RecordCodecBuilder.mapCodec(i -> i.group(
    SizedIngredient.FLAT_CODEC.optionalFieldOf("input_item").forGetter(c -> c.inputItem),
    SizedFluidIngredient.FLAT_CODEC.fieldOf("input_fluid").forGetter(c -> c.inputFluid),
    ItemStackProvider.CODEC.optionalFieldOf("output_item", ItemStackProvider.empty()).forGetter(c -> c.outputItem),
    FluidStack.CODEC.optionalFieldOf("output_fluid", FluidStack.EMPTY).forGetter(c -> c.outputFluid),
    SoundEvent.CODEC.optionalFieldOf("sound", Holder.direct(SoundEvents.BREWING_STAND_BREW)).forGetter(c -> c.sound)
).apply(i, BarrelRecipe::new));
```

**（2）`SealedBarrelRecipe.CODEC`（`SealedBarrelRecipe.java:48`，单行源码，按分组顺序换行展示）**：

```java
public static final MapCodec<SealedBarrelRecipe> CODEC = RecordCodecBuilder.mapCodec(i -> i.group(
    BarrelRecipe.CODEC.forGetter(c -> c),                        // 父类 5 字段，扁平展开
    Codec.INT.fieldOf("duration").forGetter(c -> c.duration),
    ItemStackProvider.CODEC.optionalFieldOf("on_seal").forGetter(c -> c.onSeal),
    ItemStackProvider.CODEC.optionalFieldOf("on_unseal").forGetter(c -> c.onUnseal)
).apply(i, SealedBarrelRecipe::new));
```

**关键结构事实**：父类字段是通过 `BarrelRecipe.CODEC.forGetter(c -> c)` **直接平铺**进来的，而不是包在某个子对象里——所以 `barrel_sealed` 的 JSON **顶层**同时出现 `input_item` / `input_fluid` / `output_item` / `output_fluid` / `sound` / `duration` / `on_seal` / `on_unseal` 共 8 个键，没有嵌套层。这一点被 `jar-extract/data/tfc/recipe/barrel/beer.json` 等全部 308 个文件实测证实。

**完整字段表（8 个字段）**：

| 字段名 | 类型 | 必需/可选 | 默认值 | 语义 | 来源 |
| --- | --- | --- | --- | --- | --- |
| `input_item` | `SizedIngredient`（`FLAT_CODEC`：`{"item"/"tag"/"type":..., "count":可选}`） | **可选**（`optionalFieldOf`，无默认值 → `Optional.empty()`） | 空（表示"无需物品"） | 桶内物品槽（槽位 2）必须匹配的物品。为空时 `BarrelRecipe.matches` 跳过物品判定（`BarrelRecipe.java:113-115`） | `BarrelRecipe.java:87` |
| `input_fluid` | `SizedFluidIngredient`（`FLAT_CODEC`：`{"amount":N,"fluid"/"tag":...}`） | **必需**（`fieldOf`） | 无 | 桶内流体必须匹配的流体与数量。**这是三种 barrel 配方中唯一永远必需的输入** | 同上 |
| `output_item` | `ItemStackProvider` | **可选**（`optionalFieldOf` 带默认值） | `ItemStackProvider.empty()`（等价"不产出物品"） | 完成时产出的物品（经 modifier 处理后按比例倍增至桶内） | 同上 |
| `output_fluid` | `FluidStack`（`{"amount":N,"id":"..."}`） | **可选**（`optionalFieldOf` 带默认值） | `FluidStack.EMPTY` | 完成时产出的流体 | 同上 |
| `sound` | `Holder<SoundEvent>`（注册表 `minecraft:sound_event` 的 id） | **可选**（`optionalFieldOf` 带默认值） | `Holder.direct(SoundEvents.BREWING_STAND_BREW)`，即 `minecraft:block.brewing_stand.brew` | 完成时播放的音效（`BarrelRecipe.getCompleteSound()`，`BarrelRecipe.java:192-194`） | 同上 |
| `duration` | `int` | **必需**（`Codec.INT.fieldOf`） | 无 | 封口后需要的时长；`isInfinite()` 为 `duration <= 0`（`SealedBarrelRecipe.java:74-76`），即 `0` 或负数表示**永久配方**（永不完成） | `SealedBarrelRecipe.java:48` |
| `on_seal` | `ItemStackProvider` | **可选**（`optionalFieldOf`，无默认值 → `Optional.empty()`） | 空 | **封口瞬间**对槽位 2 物品做一次替换（`onSealed(...)`，`SealedBarrelRecipe.java:90-95`）：取出槽 2 物品 → 经 provider 处理 → 放回槽 2 | `SealedBarrelRecipe.java:48` |
| `on_unseal` | `ItemStackProvider` | **可选**（同上） | 空 | **开封瞬间**对槽位 2 物品做一次替换（`onUnsealed(...)`，`SealedBarrelRecipe.java:97-102`），逻辑与 `on_seal` 相同但输入端不同 | `SealedBarrelRecipe.java:48` |

**没有其它字段。** 特别确认（回答任务书中"是否存在 `on_seal`/`on_unseal` 之类回调"的疑问）：**存在**，且**只在 `barrel_sealed` 上存在**——`InstantBarrelRecipe`（R-10）与 `InstantFluidBarrelRecipe`（R-11）的 CODEC 中都没有这两个键。

**额外校验**：`SealedBarrelRecipe` 未使用 `validate`、`Codec.either`、`flatXmap`；唯一的附加逻辑是 `matches` 覆写：

```java
// SealedBarrelRecipe.java:61-68
@Override
public boolean matches(BarrelInventory container) {
    return super.matches(container) && this.moreFluidThanItems(container);
}
private boolean moreFluidThanItems(BarrelInventory input) {
    return !this.isInfinite() || this.inputItem.isEmpty()
        || input.getFluidInTank(0).getAmount() / this.inputFluid.amount()
           >= input.getStackInSlot(2).getCount() / ((SizedIngredient) this.inputItem.get()).count();
}
```

含义：**有限时长（`duration > 0`）的封口配方不额外要求比例**；**无限配方（`duration <= 0`）要求流体量不少于物品量**（按 `input_fluid.amount` 与 `input_item.count` 归一化后的比值比较）。这正是 `preserved_in_vinegar.json`（`duration = -1`）能无限期"反复腌制"的前提。

##### R-09.3 真实 JSON 样例

**样例 1（最典型的封口酿制：`duration` + `input_item`(可选字段但写了，且**不写 `count`**) + `output_fluid`）** —— 相对路径 `data/tfc/recipe/barrel/beer.json`（文件原文）：

```json
{"type":"tfc:barrel_sealed","duration":72000,"input_fluid":{"amount":500,"fluid":"minecraft:water"},"input_item":{"type":"tfc:and","children":[{"item":"tfc:food/barley_flour"},{"type":"tfc:not_rotten"}],"count":1},"output_fluid":{"amount":500,"id":"tfc:beer"}}
```

语义：桶内 500 mB 水 + 1 份**未腐烂的大麦粉**，封口 72000 时长后得到 500 mB 啤酒（本例不写 `output_item`，故不产出物品）。

**样例 2（输入用 tag，并带 `output_item` 且使用 modifier——覆盖 `ItemStackProvider` 的"完整写法"）** —— 相对路径 `data/tfc/recipe/barrel/black_dyeable.json`：

```json
{"type":"tfc:barrel_sealed","duration":1200,"input_fluid":{"amount":25,"fluid":"tfc:black_dye"},"input_item":{"count":1,"tag":"minecraft:dyeable"},"output_item":{"modifiers":[{"type":"tfc:copy_input"},{"type":"tfc:dye_leather","color":"black"}]}}
```

语义：25 mB 黑色染料 + 任意 `#minecraft:dyeable` 物品，封口 1200 后通过 `tfc:copy_input`（保留输入物品本体）+ `tfc:dye_leather`（染色）产出染黑的物品。注意**此文件不写 `output_fluid`**（默认 `FluidStack.EMPTY`，即不产流体）。

**样例 3（**全库唯一**同时使用 `on_seal` 与 `on_unseal` 的文件，且为无限配方）** —— 相对路径 `data/tfc/recipe/barrel/preserved_in_vinegar.json`（文件原文，单行）：

```json
{"type":"tfc:barrel_sealed","duration":-1,"input_fluid":{"amount":125,"fluid":"tfc:vinegar"},"input_item":{"type":"tfc:and","children":[[{"tag":"c:foods/fruit"},{"tag":"c:foods/vegetable"},{"tag":"c:foods/meat"},{"tag":"c:foods/fish"}],{"type":"tfc:not_rotten"},{"type":"tfc:has_trait","trait":"tfc:pickled"}],"count":1},"on_seal":{"modifiers":[{"type":"tfc:copy_input"},{"type":"tfc:add_trait","trait":"tfc:vinegar"}]},"on_unseal":{"modifiers":[{"type":"tfc:copy_input"},{"type":"tfc:remove_trait","trait":"tfc:vinegar"}]}}
```

这一条把多个机制一次性展示清楚：

- `"duration":-1` → `isInfinite()` 为真 → 配方**永不完成**，物品可以长期泡在醋里；
- `input_item.children` 的第一项是**嵌套数组**（四种食物 tag 并列），第二、三项是单个 ingredient 对象，演示 `tfc:and` 的 children 允许数组与对象混排；
- `"type":"tfc:has_trait","trait":"tfc:pickled"` 说明这是**二次加工配方**（已被醋泡过的食物才匹配）；
- `on_seal` 给物品加 `tfc:vinegar` trait，`on_unseal` 在取出时移除该 trait——**这正是"封口/开封回调"的实际用途：物品在桶内的状态切换**。

**样例 4（`input_fluid` 使用 tag，且为长时长酿醋）** —— 相对路径 `data/tfc/recipe/barrel/vinegar.json`：

```json
{"type":"tfc:barrel_sealed","duration":7200,"input_fluid":{"amount":250,"tag":"tfc:alcohols"},"input_item":{"type":"tfc:and","children":[{"tag":"c:foods/fruit"},{"type":"tfc:not_rotten"}],"count":1},"output_fluid":{"amount":250,"id":"tfc:vinegar"}}
```

语义：任意 `#tfc:alcohols` 中的酒 250 mB + 未腐烂水果 → 250 mB 醋。**这是全库中 `input_fluid` 使用 tag 的实例**（检索结果：`input_fluid` 内含 `"tag"` 的文件仅此 1 个）。

**样例 5（带 `lacks_trait` 条件 + `output_item` modifier，腌制）** —— 相对路径 `data/tfc/recipe/barrel/brined.json`：

```json
{"type":"tfc:barrel_sealed","duration":3600,"input_fluid":{"amount":125,"fluid":"tfc:brine"},"input_item":{"type":"tfc:and","children":[[{"tag":"c:foods/fruit"},{"tag":"c:foods/vegetable"},{"tag":"c:foods/meat"},{"tag":"c:foods/fish"}],{"type":"tfc:not_rotten"},{"type":"tfc:lacks_trait","trait":"tfc:brined"}],"count":1},"output_item":{"modifiers":[{"type":"tfc:copy_input"},{"type":"tfc:add_trait","trait":"tfc:brined"}]}}
```

**样例 6（`output_item` 用简写、`output_fluid` 缺省的染色类配方）** —— 相对路径 `data/tfc/recipe/barrel/black_banner.json`：

```json
{"type":"tfc:barrel_sealed","duration":1200,"input_fluid":{"amount":25,"fluid":"tfc:black_dye"},"input_item":{"count":1,"item":"minecraft:white_banner"},"output_item":{"count":1,"id":"minecraft:black_banner"}}
```

##### R-09.4 `sound` 字段的真实用法

在 `jar-extract/data/tfc/recipe/barrel/` 全部 330 个文件中，含 `"sound"` 键的共 **4 个**：`canola_oil_cooling.json`、`olive_oil_cooling.json`、`salt_water_cooling.json`、`water_cooling.json`。经逐个核对，**这 4 个文件的 `type` 全部是 `tfc:barrel_instant`（R-10），没有任何一个是 `tfc:barrel_sealed`**——也就是说：**308 个封口配方使用了 `sound` 字段的默认值，官方数据中没有 `barrel_sealed` 的 `sound` 自定义实例**。

字段本身在两类配方中都存在（父类 `BarrelRecipe.CODEC` 定义的），第三方数据包若需要可以为 `barrel_sealed` 指定 `sound`，写法与 R-10.3 的 `water_cooling.json` 完全一致，例如：

```json
{"sound":"minecraft:block.fire.extinguish"}
```

`BarrelBlockEntity` 对 `sound` 有特殊处理（`net/dries007/tfc/common/blockentities/BarrelBlockEntity.java:192-204`）：若 `getCompleteSound() == SoundEvents.FIRE_EXTINGUISH`，则额外发送 `TFCParticles.BUBBLE` 与 `TFCParticles.STEAM` 粒子——也就是说 `sound` 字段除了音效外还兼作**粒子效果的开关**（该判定位于即时配方分支内）。

`BarrelBlockEntity` 对 `sound` 有特殊处理（`net/dries007/tfc/common/blockentities/BarrelBlockEntity.java:192-204`）：若 `getCompleteSound() == SoundEvents.FIRE_EXTINGUISH`，则额外发送 `TFCParticles.BUBBLE` 与 `TFCParticles.STEAM` 粒子——也就是说 `sound` 字段除了音效外还兼作**粒子效果的开关**。

##### R-09.5 游戏内触发条件

`barrel_sealed` 的完整生命周期在 `net/dries007/tfc/common/blockentities/BarrelBlockEntity.java` 中：

| # | 阶段 | 调用点（文件:行） | 关键代码 |
| --- | --- | --- | --- |
| 1 | **每 tick 查配方** | `BarrelBlockEntity.java:151-153` | `serverTick(...)` 首行 `barrel.getRecipe();` |
| 2 | 配方查询实现 | `BarrelBlockEntity.java:487-494` | `getRecipe()`：`this.recipe.load(((BarrelInventory) this.inventory).excess.isEmpty() ? BarrelRecipe.get(this.level, TFCRecipeTypes.BARREL_SEALED, this.inventory) : null);` → 走 `RecipeHelpers.getHolder(level, type, input)`（`BarrelRecipe.java:95-98`），**按 RecipeManager 的 `byType` 全量遍历 + `matches(BarrelInventory)` 判定** |
| 3 | **封口完成判定** | `BarrelBlockEntity.java:162-182` | `if (recipe != null && sealed) { int durationSealed = (int)(Calendars.SERVER.getTicks() - barrel.recipeTick); if (!recipe.isInfinite() && durationSealed > recipe.getDuration()) { if (recipe.matches(inventory)) { recipe.assembleOutputs(inventory); Helpers.playSound(level, pos, recipe.getCompleteSound()); } barrel.updateRecipe(); ... if (nextRecipe != null) { nextRecipe.onSealed(inventory); if (recipe == nextRecipe) barrel.resetTickTimer(level); } } }` |
| 4 | **封口瞬间** | `BarrelBlockEntity.java:418-435` | `onSeal()`：先把槽 0/1（流体容器）弹到世界里（422-423 行），再 `this.updateRecipe()`，然后 `if (recipe != null) { recipe.onSealed(inventory); this.recipeTick = this.sealedTick; }`，播放 `TFCSounds.CLOSE_BARREL` |
| 5 | **开封瞬间** | `BarrelBlockEntity.java:437-448` | `onUnseal()`：`this.sealedTick = 0L; this.recipeTick = -1L;` → `recipe.onUnsealed(inventory)` → `updateRecipe()`，播放 `TFCSounds.OPEN_BARREL` |
| 6 | **日历跳跃补偿** | `BarrelBlockEntity.java:273-304` | `onCalendarUpdate(long ticks)`：用 `try (CalendarTransaction tr = Calendars.SERVER.transaction()) { tr.add(-ticks); ... }` 回放每一段时长，逐次 `recipe.matches` / `assembleOutputs` / `knownRecipe.onSealed(inventory)`——**睡眠/时间跳跃不会让封口配方"跳过"，而是逐周期补算** |
| 7 | 剩余时间显示 | `BarrelBlockEntity.java:511-515` | `getRemainingTicks()` 返回 `recipe.getDuration() - (Calendars.get(level).getTicks() - this.recipeTick)` |
| 8 | **物品形态的桶**（快捷封口） | `net/dries007/tfc/common/component/block/Barrel.java:49-67` | `fill(...)` 中对假容器 `BarrelBlockEntity.BarrelInventory fakeInventory` 设置槽 2 物品并填流体，然后 `RecipeHelpers.getHolder(manager, TFCRecipeTypes.BARREL_SEALED, fakeInventory)` 判断是否存在封口配方，据此决定 `BarrelComponent` 的 `recipeTick`（**把桶当物品携带时也能记住配方状态**） |
| 9 | 配方提示（Patchouli 手册） | `net/dries007/tfc/compat/patchouli/component/SealedBarrelComponent.java:28-45` | `extends BarrelComponent<SealedBarrelRecipe>`；`if (!recipe.isInfinite()) { ... Calendars.CLIENT.getTimeDelta(recipe.getDuration()) ... }`；`getRecipeType()` 返回 `TFCRecipeTypes.BARREL_SEALED` |
| 10 | 配方名翻译键 | `BarrelBlockEntity.java:496-501` | `Component.translatable("tfc.recipe.barrel." + holder.id().getNamespace() + "." + holder.id().getPath().replace('/', '.'))` → **数据包自定义配方可通过该键提供本地化**（`tfc.recipe.barrel.<命名空间>.<路径，斜杠换点>`） |

**input 容器（`BarrelInventory`）**：接口定义在 `net/dries007/tfc/common/recipes/input/BarrelInventory.java`：

```java
public interface BarrelInventory extends IItemHandlerModifiable, IFluidHandler, NonEmptyInput {
    void whileMutable(Runnable var1);
    void insertItemWithOverflow(ItemStack var1);
}
```

槽位语义（来自 `BarrelBlockEntity.java:259-265` 的 `isItemValid` 与 455-469 的 `updateFluidIOSlots`）：

| 槽位 | 用途 |
| --- | --- |
| 0 | **输入流体容器**（物品必须具备 `Capabilities.FluidHandler.ITEM`）；每 5 tick（`level.getGameTime() % 5 == 0`）自动把容器内的流体倒入桶 |
| 1 | 空容器/输出容器（流体倒空后移到这里） |
| 2 | **配方输入物品**（即三种 barrel 配方的 `input_item` 所匹配的槽）；也是 `on_seal`/`on_unseal` 替换的槽 |

**匹配用的输入**：`matches(BarrelInventory)` 只读取 `getStackInSlot(2)` 与 `getFluidInTank(0)`（`BarrelRecipe.java:113-115`）。

##### R-09.6 `barrel_sealed` 与 `barrel_instant` 的字段差异（任务书重点）

| 对比维度 | `tfc:barrel_sealed`（R-09） | `tfc:barrel_instant`（R-10） | 证据 |
| --- | --- | --- | --- |
| 自己的 CODEC | `RecordCodecBuilder.mapCodec(...)`，**在父类 CODEC 之上追加 3 个字段** | `BarrelRecipe.CODEC.xmap(InstantBarrelRecipe::new, Function.identity())`，**字段与父类 100% 相同** | `SealedBarrelRecipe.java:48` vs `InstantBarrelRecipe.java:28` |
| `input_item` | 可选 | 可选（同一个父类字段） | `BarrelRecipe.java:87` |
| `input_fluid` | 必需 | 必需 | 同上 |
| `output_item` | 可选（默认空） | 可选（默认空） | 同上 |
| `output_fluid` | 可选（默认 `FluidStack.EMPTY`） | 可选（默认 `FluidStack.EMPTY`） | 同上 |
| `sound` | 可选（默认 `brewing_stand_brew`） | 可选（同默认） | 同上 |
| `duration` | **必需**（`Codec.INT.fieldOf`） | **不存在该字段**（写了会因未知字段被忽略或报错，取决于 `MapCodec` 严格性） | `SealedBarrelRecipe.java:48` / `InstantBarrelRecipe.java:28` |
| `on_seal` | **可选存在** | **不存在** | 同上 |
| `on_unseal` | **可选存在** | **不存在** | 同上 |
| 字段总数 | 8 | 5 | — |
| 完成时机 | 封口后经过 `duration`（日历 tick）才产出；`duration <= 0` 表示永不完成 | **无需时间**，只要槽位/流体状态变化（`needsInstantRecipeUpdate`）**立即**产出 | `BarrelBlockEntity.java:162-208` |
| 是否要求"封口" | 必须处于 `BarrelBlock.SEALED = true` 状态 | 不需要封口（未封口的桶也会立即反应） | `BarrelBlockEntity.java:165` vs `183` |
| 匹配附加条件 | `moreFluidThanItems`（无限配方才生效） | `moreItemsThanFluid`（见 R-10.2） | `SealedBarrelRecipe.java:61-68` / `InstantBarrelRecipe.java:35-42` |
| 配方查找 API | `BarrelRecipe.get(level, TFCRecipeTypes.BARREL_SEALED, inventory)` | `BarrelRecipe.get(level, TFCRecipeTypes.BARREL_INSTANT, inventory)`，**找不到时再查 `BARREL_INSTANT_FLUID`** | `BarrelBlockEntity.java:186-189`、`491` |
| JEI 过滤 | 无 | `recipe -> !(recipe.getInputItem().ingredient().getCustomIngredient() instanceof HeatIngredient)` —— **`input_item` 用 `tfc:heat` 的即时配方不在 JEI 里展示** | `net/dries007/tfc/compat/jei/JEIIntegration.java:221` |

**流体与物品输入的声明方式（任务书重点）**：

- 物品输入：`input_item`，类型是 NeoForge 的 `SizedIngredient`，用 **`FLAT_CODEC`** 解析，故 JSON 写成
  `{"item":"..."}`、`{"tag":"..."}`、或自定义 ingredient `{"type":"tfc:and","children":[...]}`，数量键为 `count`（可省略，默认 1）。
- 流体输入：`input_fluid`，类型是 NeoForge 的 `SizedFluidIngredient`，同样用 **`FLAT_CODEC`**，JSON 写成
  `{"amount":N,"fluid":"..."}` 或 `{"amount":N,"tag":"..."}`，**数量键为 `amount`（必需）**。
- 流体输出：`output_fluid`，类型是 **`FluidStack`**（不是 SizedFluidIngredient），JSON 写法用 **`id`** 而不是 `fluid`：
  `{"amount":N,"id":"tfc:beer"}`。
  → **同一份 JSON 里 `input_fluid` 用 `fluid` 键、`output_fluid` 用 `id` 键，这是最容易写错的地方**，上述所有样例文件均可对照。

### [R-10] tfc:barrel_instant —— 木桶·即时配方

##### R-10.1 类型标识与实现类

| 项目 | 值 | 证据 |
| --- | --- | --- |
| JSON `type` | `tfc:barrel_instant` | `net/dries007/tfc/common/recipes/TFCRecipeSerializers.java:72` |
| recipe type id | `tfc:barrel_instant` | `net/dries007/tfc/common/recipes/TFCRecipeTypes.java:56` |
| serializer id | `tfc:barrel_instant` | `TFCRecipeSerializers.java:72`（`register("barrel_instant", InstantBarrelRecipe.CODEC, InstantBarrelRecipe.STREAM_CODEC)`） |
| 实现类全名 | `net.dries007.tfc.common.recipes.InstantBarrelRecipe` | `net/dries007/tfc/common/recipes/InstantBarrelRecipe.java:26-27` |
| 继承关系 | `InstantBarrelRecipe extends BarrelRecipe` | `InstantBarrelRecipe.java:26-27` |
| `getType()` | `TFCRecipeTypes.BARREL_INSTANT.get()` | `InstantBarrelRecipe.java:49-52` |
| `getSerializer()` | `TFCRecipeSerializers.INSTANT_BARREL.get()` | `InstantBarrelRecipe.java:44-47` |
| 匹配输入类型 | `BarrelInventory` | `BarrelRecipe.java:112-115` |
| 自己新增的字段 | **0 个** | `InstantBarrelRecipe.java:28-29` |

**类型名与序列化名一致。**

##### R-10.2 完整字段表

`InstantBarrelRecipe.CODEC` 全部内容（`InstantBarrelRecipe.java:28-29`）：

```java
public static final MapCodec<InstantBarrelRecipe> CODEC = BarrelRecipe.CODEC.xmap(InstantBarrelRecipe::new, Function.identity());
public static final StreamCodec<RegistryFriendlyByteBuf, InstantBarrelRecipe> STREAM_CODEC = BarrelRecipe.STREAM_CODEC.map(InstantBarrelRecipe::new, Function.identity());
```

**这是一个纯粹的 `Codec.xmap` 包装**：`InstantBarrelRecipe` 的字段集合与 `BarrelRecipe` **完全相同**，仅把 `BarrelRecipe` 实例映射为 `InstantBarrelRecipe` 实例（`InstantBarrelRecipe.java:31-33` 的构造就是 `super(parent)` 逐字段复制，见 `BarrelRecipe.java:100-102`）。

因此字段表就是父类 `BarrelRecipe.CODEC`（`BarrelRecipe.java:87`）的全部 5 个字段：

| 字段名 | 类型 | 必需/可选 | 默认值 | 语义 | 来源 |
| --- | --- | --- | --- | --- | --- |
| `input_item` | `SizedIngredient`（`FLAT_CODEC`） | **可选**（`optionalFieldOf`，无默认值 → `Optional.empty()`） | 空 | 槽位 2 物品必须匹配的物品；为空则跳过物品判定 | `BarrelRecipe.java:87` |
| `input_fluid` | `SizedFluidIngredient`（`FLAT_CODEC`，`amount` + `fluid`/`tag`） | **必需**（`fieldOf`） | 无 | 桶内流体必须匹配的流体与数量 | 同上 |
| `output_item` | `ItemStackProvider` | **可选**（默认 `ItemStackProvider.empty()`） | 空 | 即时产出的物品 | 同上 |
| `output_fluid` | `FluidStack`（`{"amount":N,"id":"..."}`） | **可选**（默认 `FluidStack.EMPTY`） | 空 | 即时产出的流体 | 同上 |
| `sound` | `Holder<SoundEvent>` | **可选**（默认 `Holder.direct(SoundEvents.BREWING_STAND_BREW)`） | `minecraft:block.brewing_stand.brew` | 完成音效（兼作粒子开关，见 R-09.4） | 同上 |

**不存在**：`duration`、`on_seal`、`on_unseal`（这三个只有 R-09 有）、`primary_fluid`、`added_fluid`（这两个只有 R-11 有）。

**附加校验**：无 `validate`、无 `flatXmap`。唯一的附加逻辑是 `matches` 覆写（`InstantBarrelRecipe.java:35-42`）：

```java
@Override
public boolean matches(BarrelInventory container) {
    return super.matches(container) && this.moreItemsThanFluid(container);
}
private boolean moreItemsThanFluid(BarrelInventory input) {
    return this.inputItem.isEmpty() || this.outputFluid.isEmpty()
        || input.getFluidInTank(0).getAmount() / this.inputFluid.amount()
           <= input.getStackInSlot(2).getCount() / ((SizedIngredient) this.inputItem.get()).count();
}
```

含义（**与 R-09 的 `moreFluidThanItems` 恰好相反的力量平衡**）：

- 若 `input_item` 为空，或 `output_fluid` 为空 → 无条件通过；
- 否则要求"**桶内流体量比物品量少或相等**"。即：**当配方会产出流体时，不允许流体过剩**——防止"用水换水"式的无限循环（例如 `salt_water.json` 用 125 水 + 盐 → 125 盐水；若桶里已经堆了远超物品数量的水，就不该再按此配方一次性全转换）。

与之配对，实际执行时的倍率计算在父类 `BarrelRecipe.assembleOutputs`（`BarrelRecipe.java:117-157`）：

```java
int multiplier = this.inputItem.isEmpty()
    ? fluid.getAmount() / this.inputFluid.amount()
    : Math.min(fluid.getAmount() / this.inputFluid.amount(), stack.getCount() / this.inputItem.get().count());
```

即**一次 tick 内按"流体够几份、物品够几份"的较小者整批处理**（不是每次只处理 1 份）。

##### R-10.3 真实 JSON 样例

`tfc:barrel_instant` 全库 **20 个**文件，完整清单（相对 `jar-extract/data/tfc/recipe/barrel/`）：

```
canola_oil_cooling.json   clay_ball.json        clean_bowl.json      clean_jar.json
clean_jute_net.json       limewater.json        olive_oil_cooling.json
process_canola.json       process_olives.json   salt_water.json      salt_water_cooling.json
water_cooling.json
mud/alfisol.json  mud/andisol.json  mud/aridisol.json  mud/entisol.json
mud/fluvisol.json mud/mollisol.json mud/oxisol.json    mud/podzol.json
```

**样例 1（最简：物品 + 流体 → 物品，无 `output_fluid`）** —— 相对路径 `data/tfc/recipe/barrel/clay_ball.json`：

```json
{"type":"tfc:barrel_instant","input_fluid":{"amount":100,"fluid":"minecraft:water"},"input_item":{"count":1,"item":"tfc:hardened_clay"},"output_item":{"count":4,"id":"minecraft:clay_ball"}}
```

语义：100 mB 水 + 1 个硬化粘土 → 4 个粘土球（**倍率字段在输出侧用 `count` 表达**）。

**样例 2（多输入 ingredient：`neoforge:compound`）** —— 相对路径 `data/tfc/recipe/barrel/limewater.json`：

```json
{"type":"tfc:barrel_instant","input_fluid":{"amount":500,"fluid":"minecraft:water"},"input_item":{"type":"neoforge:compound","children":[{"item":"tfc:powder/lime"},{"item":"tfc:powder/flux"}],"count":1},"output_fluid":{"amount":500,"id":"tfc:limewater"}}
```

语义：500 mB 水 + **石灰粉或助熔剂粉**（`neoforge:compound` 表示"任一即可"）→ 500 mB 石灰水。这是"输入物品 → 输出流体"的典型。

**样例 3（`output_item` 与 `output_fluid` 同时存在：双向转换）** —— 相对路径 `data/tfc/recipe/barrel/process_canola.json`：

```json
{"type":"tfc:barrel_instant","input_fluid":{"amount":250,"fluid":"tfc:canola_oil_water"},"input_item":{"count":1,"item":"tfc:jute_net"},"output_fluid":{"amount":50,"id":"tfc:canola_oil"},"output_item":{"count":1,"id":"tfc:dirty_jute_net"}}
```

语义：250 mB 菜籽油水 + 1 个黄麻网 → 50 mB 菜籽油 + 1 个脏黄麻网。**同时产出物品与流体。**

**样例 4（`sound` 字段 + 使用 TFC 自定义 ingredient `tfc:heat` 的物品输入）** —— 相对路径 `data/tfc/recipe/barrel/water_cooling.json`：

```json
{"type":"tfc:barrel_instant","input_fluid":{"amount":1,"fluid":"minecraft:water"},"input_item":{"type":"tfc:heat","count":1,"min":1.0},"output_item":{"modifiers":[{"type":"tfc:copy_input"},{"type":"tfc:add_heat","temperature":-5.0}]},"sound":"minecraft:block.fire.extinguish"}
```

语义：任意**温度 ≥ 1.0 的热物品**（`tfc:heat` 的 `min` 默认 `-Infinity`、`max` 默认 `+Infinity`，本例只给 `min`）放入 1 mB 水，物品保留本体（`copy_input`）并降温 5.0（`add_heat` 传负值），音效为灭火声（同时触发泡泡/蒸汽粒子，见 R-09.4）。**注意：`input_item` 每份只消耗 1 mB 水**，与 `moreItemsThanFluid` 条件配合实现"冷却池"效果。

**样例 5（物品输入用 tag 且输出仅物品 modifier）** —— 相对路径 `data/tfc/recipe/barrel/clean_bowl.json`：

```json
{"type":"tfc:barrel_instant","input_fluid":{"amount":100,"fluid":"minecraft:water"},"input_item":{"type":"neoforge:compound","children":[{"tag":"c:foods/soup"},{"tag":"c:foods/salad"}],"count":1},"output_item":{"modifiers":[{"type":"tfc:empty_bowl"}]}}
```

语义：100 mB 水 + 任何汤/沙拉（`#c:foods/soup` 或 `#c:foods/salad`）→ 空的碗（`tfc:empty_bowl` modifier）。注意这里**不写 `stack`**，只写 `modifiers`（`ItemStackProvider` 完整写法的合法形态，见 A2-0.4）。

**样例 6（泥土→泥巴：`output_item` 简写 + 单元素 `input_item`，`mud/` 8 个文件同构）** —— 相对路径 `data/tfc/recipe/barrel/mud/alfisol.json`：

```json
{"type":"tfc:barrel_instant","input_fluid":{"amount":250,"fluid":"minecraft:water"},"input_item":{"count":1,"item":"tfc:dirt/alfisol"},"output_item":{"count":1,"id":"tfc:mud/alfisol"}}
```

##### R-10.4 游戏内触发条件

| # | 阶段 | 调用点（文件:行） | 关键代码 |
| --- | --- | --- | --- |
| 1 | **状态变化打标**（物品槽） | `net/dries007/tfc/common/blockentities/BarrelBlockEntity.java:244-249` | `setAndUpdateSlots(int slot)`：`this.needsInstantRecipeUpdate = true; this.updateRecipe(); this.setChanged();` |
| 2 | **状态变化打标**（流体） | `BarrelBlockEntity.java:251-256` | `fluidTankChanged()`：同样置 `needsInstantRecipeUpdate = true` 并 `updateRecipe()` |
| 3 | **每秒/每次变更执行** | `BarrelBlockEntity.java:183-208` | `if (barrel.needsInstantRecipeUpdate) { barrel.needsInstantRecipeUpdate = false; if (inventory.excess.isEmpty()) { RecipeHolder instantRecipe = BarrelRecipe.get(level, TFCRecipeTypes.BARREL_INSTANT, inventory); if (instantRecipe == null) instantRecipe = BarrelRecipe.get(level, TFCRecipeTypes.BARREL_INSTANT_FLUID, inventory); if (instantRecipe != null) { ((BarrelRecipe) instantRecipe.value()).assembleOutputs(inventory); ... } } }` |
| 4 | 音效与粒子 | `BarrelBlockEntity.java:192-204` | `if (barrel.soundCooldownTicks == 0) { Helpers.playSound(level, pos, recipe.getCompleteSound()); barrel.soundCooldownTicks = 5; if (recipe.getCompleteSound() == SoundEvents.FIRE_EXTINGUISH && level instanceof ServerLevel) { ... 发送 BUBBLE / STEAM 粒子 ... } }` |
| 5 | 自动收集掉落物进桶 | `BarrelBlockEntity.java:212-214` | `if (level.getGameTime() % 20L == 0L && !sealed && facing == Direction.UP) Helpers.gatherAndConsumeItems(level, new AABB(0.25,0.0625,0.25,0.75,0.9375,0.75).move(pos), inventory, 2, 2);` → 桶口朝上时**每秒把上方掉落的物品吸进槽 2**（这就是"往桶里扔东西"的入口） |
| 6 | 装雨 | `BarrelBlockEntity.java:216-219` | `if (!sealed && facing == Direction.UP && level.getGameTime() % 4L == 0L && level.isRainingAt(pos.above())) { inventory.fill(new FluidStack(Fluids.WATER, 1), EXECUTE); }` → 露天朝上的桶会**积雨水**，可能触发水相关即时配方 |
| 7 | 倒入流体（自动） | `BarrelBlockEntity.java:455-469` | `updateFluidIOSlots()`：每 5 tick 检查槽 0 的流体容器，`FluidHelpers.transferBetweenBlockEntityAndItem(...)` 把容器流体转入桶，容器移到槽 1 |
| 8 | **模具台**（Mold Table）复用即时配方 | `net/dries007/tfc/common/blockentities/MoldTableBlockEntity.java:403-413` | `level.getRecipeManager().getAllRecipesFor(TFCRecipeTypes.BARREL_INSTANT.get()).stream().filter(h -> h.value().getInputItem().test(stack) && h.value().getInputFluid().test(fluid)).findFirst().map(...)` → 用即时配方的**输入侧**计算模具台能产出什么（这是 `barrel_instant` 的唯一非桶调用点） |
| 9 | JEI 展示过滤 | `net/dries007/tfc/compat/jei/JEIIntegration.java:221` | `registry.addRecipes(INSTANT_BARREL, JEIIntegration.recipes(TFCRecipeTypes.BARREL_INSTANT, recipe -> !(recipe.getInputItem().ingredient().getCustomIngredient() instanceof HeatIngredient)));` |
| 10 | EMI 展示 | `net/dries007/tfc/compat/emi/EmiIntegration.java:233` | `EmiIntegration.basicRecipeMapping(registry, TFCRecipeTypes.BARREL_INSTANT, EmiInstantBarrelRecipe::new);` |

**与 R-09 的关键差异**：即时配方**不需要封口**（`BarrelBlockEntity.java:183` 的分支不检查 `sealed`），只要槽位或流体发生变化（`needsInstantRecipeUpdate`）就在下一次 `serverTick` 立即执行；封口配方必须 `BarrelBlock.SEALED = true`（`BarrelBlockEntity.java:165`）且经过时长。

##### R-10.5 特殊辅助类在 `barrel_instant` 中的可见形式

| 辅助类型 | 真实出现位置（已逐个读取核对） | 例子 |
| --- | --- | --- |
| `TFCIngredients.HEAT`（`tfc:heat`） | `water_cooling.json`、`canola_oil_cooling.json`、`olive_oil_cooling.json`、`salt_water_cooling.json` 的 `input_item`（共 4 个文件） | `{"type":"tfc:heat","count":1,"min":1.0}` |
| `neoforge:compound` | `limewater.json`（石灰粉/助熔剂）、`clean_bowl.json`（汤/沙拉）、`clean_jar.json`（两种罐头 tag）——共 **3 个**文件 | `{"type":"neoforge:compound","children":[{"item":"tfc:powder/lime"},{"item":"tfc:powder/flux"}],"count":1}` |
| `ItemStackProvider` + modifier（完整写法） | `water_cooling.json`、`canola_oil_cooling.json`、`olive_oil_cooling.json`、`salt_water_cooling.json`、`clean_bowl.json`——共 **5 个**文件 | `{"modifiers":[{"type":"tfc:copy_input"},{"type":"tfc:add_heat","temperature":-40.0}]}`（`canola_oil_cooling.json` 的实际内容） |
| 普通 `item`/`tag` 输入 + `ItemStackProvider` 简写输出 | `clay_ball.json`、`mud/*.json`（8 个）、`clean_jute_net.json`、`salt_water.json`、`process_olives.json` 等 | `{"input_item":{"count":1,"item":"tfc:dirty_jute_net"},"output_item":{"count":1,"id":"tfc:jute_net"}}` |

冷却类配方的完整真实内容（可作为"温度修正 + 音效"的最小范例）—— 相对路径 `data/tfc/recipe/barrel/salt_water_cooling.json`：

```json
{"type":"tfc:barrel_instant","input_fluid":{"amount":1,"fluid":"tfc:salt_water"},"input_item":{"type":"tfc:heat","count":1,"min":1.0},"output_item":{"modifiers":[{"type":"tfc:copy_input"},{"type":"tfc:add_heat","temperature":-5.0}]},"sound":"minecraft:block.fire.extinguish"}
```

而 `data/tfc/recipe/barrel/canola_oil_cooling.json` 与 `olive_oil_cooling.json` 与之结构完全一致，仅流体分别为 `tfc:canola_oil` / `tfc:olive_oil`，且 `temperature` 为 `-40.0`（油比水降温更快）——**这说明"降温速率"是数据驱动的，由 JSON 的 `temperature` 决定，而非硬编码**。

`tfc:heat` 的存在还带来一个**集成侧注意点**：带 `HeatIngredient` 的即时配方在 JEI 中不展示（见 R-10.4 表第 9 行），因为其"输入物品"无法用一个具体物品栈表示。

---

### [R-11] tfc:barrel_instant_fluid —— 木桶·即时流体混合配方

##### R-11.1 类型标识与实现类

| 项目 | 值 | 证据 |
| --- | --- | --- |
| JSON `type` | `tfc:barrel_instant_fluid` | `net/dries007/tfc/common/recipes/TFCRecipeSerializers.java:73` |
| recipe type id | `tfc:barrel_instant_fluid` | `net/dries007/tfc/common/recipes/TFCRecipeTypes.java:57` |
| serializer id | `tfc:barrel_instant_fluid` | `TFCRecipeSerializers.java:73` |
| 实现类全名 | `net.dries007.tfc.common.recipes.InstantFluidBarrelRecipe` | `net/dries007/tfc/common/recipes/InstantFluidBarrelRecipe.java:60-61` |
| 继承关系 | `InstantFluidBarrelRecipe extends BarrelRecipe` | `InstantFluidBarrelRecipe.java:60-61` |
| `getType()` | `TFCRecipeTypes.BARREL_INSTANT_FLUID.get()` | `InstantFluidBarrelRecipe.java:121-124` |
| `getSerializer()` | `TFCRecipeSerializers.INSTANT_FLUID_BARREL.get()` | `InstantFluidBarrelRecipe.java:116-119` |
| 匹配输入类型 | `BarrelInventory`（覆写为只看槽 0 与槽 2 的**物品内流体**） | `InstantFluidBarrelRecipe.java:75-83` |
| 自己新增的字段 | `addedFluid`（1 个）+ 重新定义了父类的 `inputFluid`（JSON 名改为 `primary_fluid`） | `InstantFluidBarrelRecipe.java:62-68` |

**类型名与序列化名一致。**

##### R-11.2 完整字段表

`InstantFluidBarrelRecipe.CODEC`（`InstantFluidBarrelRecipe.java:62`，单行源码，按分组顺序换行）：

```java
public static final MapCodec<InstantFluidBarrelRecipe> CODEC = RecordCodecBuilder.mapCodec(i -> i.group(
    SizedFluidIngredient.FLAT_CODEC.fieldOf("primary_fluid").forGetter(c -> c.inputFluid),
    SizedFluidIngredient.FLAT_CODEC.fieldOf("added_fluid").forGetter(c -> c.addedFluid),
    FluidStack.CODEC.optionalFieldOf("output_fluid", FluidStack.EMPTY).forGetter(c -> c.outputFluid),
    SoundEvent.CODEC.optionalFieldOf("sound", Holder.direct(SoundEvents.BREWING_STAND_BREW)).forGetter(c -> c.sound)
).apply(i, InstantFluidBarrelRecipe::new));
```

**关键：它没有复用父类 `BarrelRecipe.CODEC.forGetter(...)`，而是自己重写了 4 个字段。** 因此：

- 父类的 `input_fluid` 在这里**被改名**为 `primary_fluid`（用 `c -> c.inputFluid` 读取的仍是父类同一个字段）；
- 父类的 `input_item` 与 `output_item` **完全不出现在 JSON 里**——构造函数里被写死为"空"（`InstantFluidBarrelRecipe.java:66-69`）：
  ```java
  public InstantFluidBarrelRecipe(SizedFluidIngredient primaryFluid, SizedFluidIngredient addedFluid, FluidStack outputFluid, Holder<SoundEvent> sound) {
      super(Optional.empty(), primaryFluid, ItemStackProvider.empty(), outputFluid, sound);
      this.addedFluid = addedFluid;
  }
  ```
  即 `inputItem = Optional.empty()`、`outputItem = ItemStackProvider.empty()`。

| 字段名 | 类型 | 必需/可选 | 默认值 | 语义 | 来源 |
| --- | --- | --- | --- | --- | --- |
| `primary_fluid` | `SizedFluidIngredient`（`FLAT_CODEC`：`{"amount":N,"fluid"/"tag":...}`） | **必需**（`fieldOf`） | 无 | **桶内**的"主流体"数量与种类（对应父类 `inputFluid`，`getInputFluid()` 返回它） | `InstantFluidBarrelRecipe.java:62` |
| `added_fluid` | `SizedFluidIngredient`（`FLAT_CODEC`） | **必需**（`fieldOf`） | 无 | **物品中携带**的"添加流体"数量与种类（来自槽 0 或槽 2 的物品的 `IFluidHandlerItem` 能力） | 同上 |
| `output_fluid` | `FluidStack`（`{"amount":N,"id":"..."}`） | **可选**（`optionalFieldOf` 带默认值） | `FluidStack.EMPTY` | 混合产出的流体 | 同上 |
| `sound` | `Holder<SoundEvent>` | **可选**（`optionalFieldOf` 带默认值） | `Holder.direct(SoundEvents.BREWING_STAND_BREW)` | 完成音效 | 同上 |

**不存在的字段**：`input_item`、`output_item`（构造时写死为空，JSON 里写了也不会有字段接）、`duration`、`on_seal`、`on_unseal`。

**匹配逻辑（`InstantFluidBarrelRecipe.java:75-83`）——注意它完全不复用父类的 `matches`**：

```java
@Override
public boolean matches(BarrelInventory container) {
    return this.matches(container.getStackInSlot(2), container.getFluidInTank(0))
        || this.matches(container.getStackInSlot(0), container.getFluidInTank(0));
}

public boolean matches(ItemStack inputStack, FluidStack fluidStack) {
    FluidStack extractableFluid = FluidHelpers.getContainedFluid(inputStack);
    return this.inputFluid.test(fluidStack) && this.addedFluid.test(extractableFluid);
}
```

- 桶内流体（`getFluidInTank(0)`）必须匹配 `primary_fluid`；
- **物品中"装着的流体"**（`FluidHelpers.getContainedFluid(inputStack)`，即检查物品的流体容器能力）必须匹配 `added_fluid`；
- 检查两个槽位：**槽 2（配方物品位）优先，槽 0（流体容器输入位）其次** —— 这就是"把一桶醋拿在手里倒进盐水桶"能生效的原因。

**执行逻辑（`InstantFluidBarrelRecipe.java:85-114`）**：

```java
inventory.whileMutable(() -> {
    FluidStack primaryFluid = inventory.drain(Integer.MAX_VALUE, IFluidHandler.FluidAction.EXECUTE);
    boolean inputIsItemSlot = this.matches(inventory.getStackInSlot(2), primaryFluid);
    ItemStack originalStack = Helpers.removeStack(inventory, inputIsItemSlot ? 2 : 0);
    IFluidHandlerItem fluidHandler = originalStack.copyWithCount(1).getCapability(Capabilities.FluidHandler.ITEM);
    if (fluidHandler == null) return;
    FluidStack addedFluid = fluidHandler.drain(Integer.MAX_VALUE, SIMULATE);
    int multiplier = Math.min(primaryFluid.getAmount() / this.inputFluid.amount(), addedFluid.getAmount() / this.addedFluid.amount());
    int targetAddedFluid = multiplier * this.addedFluid.amount();
    ...
    FluidStack outputFluid = this.outputFluid.copy();
    outputFluid.setAmount(Math.min(TFCConfig.SERVER.barrelCapacity.get(), outputFluid.getAmount() * multiplier));
    inventory.fill(outputFluid, EXECUTE);
    FluidHelpers.updateContainerItem(originalStack, fluidHandler, (newOriginalStack, newContainerStack) -> { ... });
});
```

要点：**倍率取"主流体够几份"与"物品中流体够几份"的较小者**；输出量 = `output_fluid.amount × multiplier`，且不超过 `TFCConfig.SERVER.barrelCapacity`；处理完后通过 `FluidHelpers.updateContainerItem` 把原容器（例如空瓶/空桶）分离出来，容器回槽 1 或槽 2，剩余物进 `excess`。

##### R-11.3 真实 JSON 样例

**全库只有 2 个文件**，两者都完整给出（`jar-extract/data/tfc/recipe/barrel/` 下，文件原文）：

**样例 1** —— 相对路径 `data/tfc/recipe/barrel/brine.json`：

```json
{"type":"tfc:barrel_instant_fluid","added_fluid":{"amount":1,"fluid":"tfc:vinegar"},"output_fluid":{"amount":10,"id":"tfc:brine"},"primary_fluid":{"amount":9,"fluid":"tfc:salt_water"}}
```

语义：桶内 9 mB 盐水（`primary_fluid`）+ 物品中携带 1 mB 醋（`added_fluid`）→ 10 mB 卤水（`output_fluid`）。**注意输出量 10 = 输入 9 + 1，即"完全合并"**。

**样例 2** —— 相对路径 `data/tfc/recipe/barrel/milk_vinegar.json`：

```json
{"type":"tfc:barrel_instant_fluid","added_fluid":{"amount":1,"fluid":"tfc:vinegar"},"output_fluid":{"amount":10,"id":"tfc:milk_vinegar"},"primary_fluid":{"amount":9,"fluid":"minecraft:milk"}}
```

语义：桶内 9 mB 牛奶 + 物品中 1 mB 醋 → 10 mB 酸牛奶。两个文件结构完全相同，只有流体 id 不同（`tfc:salt_water`→`tfc:brine`、`minecraft:milk`→`tfc:milk_vinegar`），**说明该配方类型是"定量混合"的通用机制**。

值得注意的是这两个文件的**键书写顺序**与 CODEC 声明顺序不同（JSON 里 `added_fluid` 写在 `primary_fluid` 之前），但 JSON 对象键序无意义，解析不受影响。

##### R-11.4 游戏内触发条件

| # | 阶段 | 调用点（文件:行） | 关键代码 |
| --- | --- | --- | --- |
| 1 | 状态变化打标 | `BarrelBlockEntity.java:244-256` | 与 R-10 相同（`setAndUpdateSlots` / `fluidTankChanged` 置 `needsInstantRecipeUpdate`） |
| 2 | **查询顺序（关键）** | `BarrelBlockEntity.java:186-189` | `RecipeHolder instantRecipe = BarrelRecipe.get(level, TFCRecipeTypes.BARREL_INSTANT, inventory); if (instantRecipe == null) instantRecipe = BarrelRecipe.get(level, TFCRecipeTypes.BARREL_INSTANT_FLUID, inventory);` → **先查普通即时配方，查不到才查流体混合配方**；两者互斥，不会同时生效 |
| 3 | 执行 | `BarrelBlockEntity.java:190-205` | `if (instantRecipe != null) { ((BarrelRecipe) instantRecipe.value()).assembleOutputs(inventory); ... 音效与粒子 ... }` |
| 4 | 物品流体来源 | `BarrelBlockEntity.java:455-469` | `updateFluidIOSlots()` 每 5 tick 把槽 0 容器的流体**倒入桶**（注意：倒入桶后物品就变空了，因此 `added_fluid` 的匹配通常发生在"刚放进去、尚未倒空"的瞬间，或该物品的流体不能被桶接收时）。**本次未对该时序细节做运行时验证** |
| 5 | EMI 展示 | `net/dries007/tfc/compat/emi/EmiIntegration.java:234` | `basicRecipeMapping(registry, TFCRecipeTypes.BARREL_INSTANT_FLUID, EmiInstantFluidBarrelRecipe::new)` |
| 6 | JEI 展示 | `net/dries007/tfc/compat/jei/JEIIntegration.java:222` | `registry.addRecipes(INSTANT_FLUID_BARREL, JEIIntegration.recipes(TFCRecipeTypes.BARREL_INSTANT_FLUID));`；`InstantFluidBarrelRecipeCategory` 位于 `net/dries007/tfc/compat/jei/category/InstantFluidBarrelRecipeCategory.java:29-41` |

**input 容器**：`BarrelInventory`（槽 0 = 可能的流体容器/含流体物品，槽 1 = 空容器，槽 2 = 配方物品位），但 R-11 **不读 `input_item`**，它对槽 0 与槽 2 的**物品所携带的流体**做判定。

##### R-11.5 三种 barrel 配方的字段对照总表

| 字段 | R-09 `barrel_sealed` | R-10 `barrel_instant` | R-11 `barrel_instant_fluid` |
| --- | --- | --- | --- |
| `input_item` | 可选 | 可选 | **不存在**（构造写死 `Optional.empty()`） |
| `input_fluid` | 必需 | 必需 | **不存在该键名**（改名 `primary_fluid`） |
| `primary_fluid` | 不存在 | 不存在 | **必需** |
| `added_fluid` | 不存在 | 不存在 | **必需** |
| `output_item` | 可选（默认空） | 可选（默认空） | **不存在**（构造写死 `ItemStackProvider.empty()`） |
| `output_fluid` | 可选（默认 `FluidStack.EMPTY`） | 可选（同） | 可选（同） |
| `sound` | 可选（默认 `brewing_stand_brew`） | 可选（同） | 可选（同） |
| `duration` | **必需**（int） | 不存在 | 不存在 |
| `on_seal` / `on_unseal` | **可选存在** | 不存在 | 不存在 |
| CODEC 构造方式 | `RecordCodecBuilder`，父类字段 `forGetter` 平铺 + 追加 3 字段 | `BarrelRecipe.CODEC.xmap(...)`，字段 100% 等于父类 | `RecordCodecBuilder`，**自写 4 字段**，部分覆盖父类字段名 |
| 字段总数 | 8 | 5 | 4 |
| 官方数据文件数 | 308 | 20 | **2** |
| 是否要求封口 | 是（`BarrelBlock.SEALED`） | 否 | 否 |
| 是否要求时长 | 是（`duration` 日历 tick） | 否（立即） | 否（立即） |
| 查询优先级 | 独立（`getRecipe()` 单独查 `BARREL_SEALED`） | 第一优先 | 第二优先（仅当 `BARREL_INSTANT` 无匹配时） |

**给数据包作者的三句话总结**：

1. 想做"放进去、封上、等一段时间"→ `tfc:barrel_sealed`，必须写 `duration`，可选 `on_seal`/`on_unseal`。
2. 想做"放进去立刻反应"（物品↔流体）→ `tfc:barrel_instant`，字段只有 5 个，**不要写 `duration`**。
3. 想做"两种流体混合"→ `tfc:barrel_instant_fluid`，用 `primary_fluid` + `added_fluid`，**没有物品输入/输出字段**。

---

### 附录 A2-1：本组证据文件索引

| 用途 | 相对路径（`moddev/src-ref/TFC-decompiled` 为根） |
| --- | --- |
| 配方类型注册 | `net/dries007/tfc/common/recipes/TFCRecipeTypes.java:44-46,55-57` |
| 配方序列化器注册 | `net/dries007/tfc/common/recipes/TFCRecipeSerializers.java:58-60,71-73` |
| 序列化器实现 | `net/dries007/tfc/common/recipes/RecipeSerializerImpl.java:19-23` |
| `BlockRecipe`（R-06/R-07 字段来源） | `net/dries007/tfc/common/recipes/BlockRecipe.java:41-81`（CODEC 在 51-53 行） |
| `CollapseRecipe` | `net/dries007/tfc/common/recipes/CollapseRecipe.java`（全文 187 行） |
| `LandslideRecipe` | `net/dries007/tfc/common/recipes/LandslideRecipe.java`（全文 143 行） |
| `ChiselRecipe` | `net/dries007/tfc/common/recipes/ChiselRecipe.java`（全文 143 行） |
| `BarrelRecipe`（R-09/R-10/R-11 的父类） | `net/dries007/tfc/common/recipes/BarrelRecipe.java`（CODEC 在 87 行，Builder 在 196-285 行） |
| `SealedBarrelRecipe` | `net/dries007/tfc/common/recipes/SealedBarrelRecipe.java`（全文 114 行） |
| `InstantBarrelRecipe` | `net/dries007/tfc/common/recipes/InstantBarrelRecipe.java`（全文 54 行） |
| `InstantFluidBarrelRecipe` | `net/dries007/tfc/common/recipes/InstantFluidBarrelRecipe.java`（全文 126 行） |
| `BlockIngredient` | `net/dries007/tfc/common/recipes/ingredients/BlockIngredient.java:43-78` |
| `TFCIngredients` | `net/dries007/tfc/common/recipes/ingredients/TFCIngredients.java:39-57` |
| `ItemStackProvider` | `net/dries007/tfc/common/recipes/outputs/ItemStackProvider.java:34-110` |
| `ItemStackModifier` / `ItemStackModifiers` | `net/dries007/tfc/common/recipes/outputs/ItemStackModifier.java:21-38`；`ItemStackModifiers.java:53-91` |
| 各个带字段的 modifier CODEC | `net/dries007/tfc/common/recipes/outputs/{AddTraitModifier,RemoveTraitModifier,AddHeatModifier,DyeLeatherModifier,ChanceModifier,ExtraProductModifier,MealModifier}.java` |
| `ChiselMode` 注册表 | `net/dries007/tfc/common/player/ChiselMode.java:58-133` |
| 玩家侧模式接口 | `net/dries007/tfc/common/player/IPlayerInfo.java:42-44` |
| `BarrelInventory` | `net/dries007/tfc/common/recipes/input/BarrelInventory.java:16-23` |
| `INoopInputRecipe` | `net/dries007/tfc/common/recipes/INoopInputRecipe.java:21-37` |
| `IRecipePredicate` | `net/dries007/tfc/common/recipes/IRecipePredicate.java:6-8` |
| `RecipeHelpers` | `net/dries007/tfc/common/recipes/RecipeHelpers.java:128-177` |
| barrel 方块实体（触发全链路） | `net/dries007/tfc/common/blockentities/BarrelBlockEntity.java`（151-220、273-304、418-448、455-494、511-515） |
| 桶的物品组件 | `net/dries007/tfc/common/component/block/Barrel.java:49-78` |
| 塌方/滑坡事件入口 | `net/dries007/tfc/ForgeEventHandler.java:469-477、485-498、507-521、523-528` |
| 塌方/滑坡世界追踪 | `net/dries007/tfc/util/tracker/WorldTracker.java:90-92、111-123、137-173` |
| 下落方块实体 | `net/dries007/tfc/common/entities/misc/TFCFallingBlockEntity.java:209-227` |
| 原版下落方块拦截 | `net/dries007/tfc/mixin/FallingBlockMixin.java:28-36` |
| 地形生成期滑坡判定 | `net/dries007/tfc/world/feature/ErosionFeature.java:65-99` |
| 凿子物品交互 | `net/dries007/tfc/common/items/ChiselItem.java:53-91` |
| 客户端凿刻预览 | `net/dries007/tfc/client/ClientForgeEventHandler.java:478-490` |
| 石笋塌方 | `net/dries007/tfc/common/blocks/rock/RockSpikeBlock.java:165-185` |
| 客户端塌方粒子提示 | `net/dries007/tfc/common/blocks/rock/RawRockBlock.java:39-46` |
| 模具台复用即时配方 | `net/dries007/tfc/common/blockentities/MoldTableBlockEntity.java:396-420` |
| 相关 tag 定义 | `net/dries007/tfc/common/TFCTags.java:231,236,383-386` |
| 方块状态 Codec | `net/dries007/tfc/world/Codecs.java:61-66`（`BLOCK_STATE` 在 64 行） |
| JEI/EMI/Patchouli 集成 | `net/dries007/tfc/compat/jei/JEIIntegration.java:161-163,204,220-222`；`net/dries007/tfc/compat/emi/EmiIntegration.java:232-234`；`net/dries007/tfc/compat/patchouli/component/SealedBarrelComponent.java:28-45` |

### 附录 A2-2：真实数据文件索引（`moddev/jar-extract` 为根）

| 类型 | 文件 | 展示内容 |
| --- | --- | --- |
| collapse | `data/tfc/recipe/collapse/ore/normal_bismuthinite/andesite.json` | 最简矿石降级 |
| collapse | `data/tfc/recipe/collapse/ore/normal_native_copper/granite.json` | 第二种矿石降级 |
| collapse | `data/tfc/recipe/collapse/rock/cobble/andesite.json` | 33 元素 → 1 结果（收敛式） |
| landslide | `data/tfc/recipe/landslide/dirt.json` | 单元素同名 |
| landslide | `data/tfc/recipe/landslide/cobblestone.json` | 单元素同名 |
| landslide | `data/tfc/recipe/landslide/clay/alfisol.json` | 3 元素收敛 |
| landslide | `data/tfc/recipe/landslide/red_kaolin_clay.json` | 单元素异名（草皮剥离） |
| landslide | `data/tfc/recipe/landslide/dirt/alfisol.json` | 6 元素收敛（含耕地/生根土） |
| chisel | `data/tfc/recipe/chisel/alabaster/polished.json` | 最简（无 item_output） |
| chisel | `data/tfc/recipe/chisel/rock/smooth/andesite.json` | 多元素 ingredient |
| chisel | `data/tfc/recipe/chisel/alabaster/bricks/black_slab.json` | 带 item_output 的 slab |
| chisel | `data/tfc/recipe/chisel/alabaster/bricks/blue_stairs.json` | 不带 item_output 的 stair |
| chisel | `data/tfc/recipe/chisel/cut_sandstone/red.json` | ingredient 与 result 异名 |
| chisel | `data/tfc/recipe/chisel/wood/planks/acacia_slab.json` | 木质同构 |
| barrel_sealed | `data/tfc/recipe/barrel/beer.json` | duration + 物品输入（无 count） |
| barrel_sealed | `data/tfc/recipe/barrel/black_dyeable.json` | tag 输入 + output_item modifiers |
| barrel_sealed | `data/tfc/recipe/barrel/preserved_in_vinegar.json` | **唯一含 on_seal/on_unseal**、`duration=-1` |
| barrel_sealed | `data/tfc/recipe/barrel/vinegar.json` | `input_fluid` 用 tag（唯一实例） |
| barrel_sealed | `data/tfc/recipe/barrel/brined.json` | lacks_trait + modifier |
| barrel_sealed | `data/tfc/recipe/barrel/black_banner.json` | output_item 简写 |
| barrel_instant | `data/tfc/recipe/barrel/clay_ball.json` | 最简物品→物品 |
| barrel_instant | `data/tfc/recipe/barrel/limewater.json` | `neoforge:compound` + output_fluid |
| barrel_instant | `data/tfc/recipe/barrel/process_canola.json` | 同时产出物品与流体 |
| barrel_instant | `data/tfc/recipe/barrel/water_cooling.json` | `tfc:heat` + sound |
| barrel_instant | `data/tfc/recipe/barrel/clean_bowl.json` | tag 输入 + modifiers-only provider |
| barrel_instant | `data/tfc/recipe/barrel/mud/alfisol.json` | 泥土→泥巴 |
| barrel_instant_fluid | `data/tfc/recipe/barrel/brine.json` | 盐水 + 醋 → 卤水（**2 个之一**） |
| barrel_instant_fluid | `data/tfc/recipe/barrel/milk_vinegar.json` | 牛奶 + 醋 → 酸牛奶（**2 个之一**） |

### 附录 A2-3：本次"未能核实"或存在不确定性的点

| # | 事项 | 已检查的内容 | 结论 |
| --- | --- | --- | --- |
| 1 | `BlockIngredient` 的 **tag 字符串写法**在 `collapse`/`landslide`/`chisel` 中无官方实例 | `jar-extract/data/tfc/recipe/` 下 collapse(525) + landslide(21) + chisel(513) 全部文件检索 `"ingredient"` 为字符串（非数组）的命中数为 **0** | 写法合法性由 `BlockIngredient.CODEC = Codec.either(...)`（`BlockIngredient.java:45`）推出，**未做运行时验证** |
| 2 | `result` 带 `Properties` 的完整方块状态写法无官方实例 | 检索 `collapse/` 全部文件 `"result": {"Name"` 命中数为 **0** | 合法性由 `Codecs.BLOCK_STATE`（`Codecs.java:64`）与 `BlockState.CODEC` 推出，**未做运行时验证** |
| 3 | `chisel` 的 `item_output` 使用 `{"modifiers":[...]}` 写法无官方实例 | 检索 chisel(513) 中 `"item_output"` 内含 `modifiers` 的命中数为 **0** | 技术上可行（`ItemStackProvider.CODEC`），但官方数据一律用简写，**未验证运行时表现** |
| 4 | `barrel_instant` 的 `input_fluid` 使用自定义流体 ingredient（带 `"type"`）无官方实例 | 检索 barrel(330) 中 `"input_fluid"` 内含 `"type"` 的命中数为 **0** | 只是无实例，不代表不合法 |
| 5 | `duration` 的日历 tick 与真实游戏时长的换算 | 已确认判定式为 `Calendars.SERVER.getTicks() - barrel.recipeTick > recipe.getDuration()`（`BarrelBlockEntity.java:166-167`） | **换算比例受 TFC 日历/配置影响，本次未核实"72000 等于几天"这一具体数值关系**，只确认单位是日历 tick |
| 6 | `barrel_sealed` 在**未封口**状态下是否会残留 `recipe` 引用 | 已读 `serverTick`（162-182 行，`sealed` 为真才推进时长）与 `getRecipe()`（488-494 行，不检查 sealed） | `getRecipe()` 不检查封口状态，但时长推进检查；**未核实"未封口时 `on_seal` 是否会被调用"的边界情形**（从 `onSeal()` 是被 `BarrelBlockEntity.onSeal()` 显式调用的入口看，应只在封口时调用） |
| 7 | `InstantFluidBarrelRecipe` 中 `added_fluid` 的匹配时序 | 已读 `matches`（75-83 行）与 `updateFluidIOSlots`（455-469 行） | `updateFluidIOSlots` 每 5 tick 会把槽 0 容器流体倒入桶，理论上与"物品中流体"的判定存在竞争；**本次未做运行时验证**，仅在源码层标注该风险 |
| 8 | `BarrelRecipe.Builder` 的用途 | 已读 `BarrelRecipe.java:196-285`（`input`/`output`/`instant`/`instantOnAdd`/`sealed` 等） | 这是**程序化构造配方**（多为内置/兼容代码使用）的工具类，**不是 JSON 格式的一部分**；本次未追查全部调用者 |


---

## 第 3 部分　加工配方（R-12 ~ R-17）


本文组负责 TerraFirmaCraft 4.2.10（MC 1.21.1 / NeoForge 21.1.248）中 6 种配方 JSON 类型的源码级字段考证。

| 编号 | type id | 实现类全名 | 序列化器注册 | 数据目录（jar 内） | 真实文件数 |
| --- | --- | --- | --- | --- | --- |
| R-12 | `tfc:heating` | `net.dries007.tfc.common.recipes.HeatingRecipe` | `TFCRecipeSerializers` 第 61 行 `register("heating", HeatingRecipe.CODEC, HeatingRecipe.STREAM_CODEC)` | `data/tfc/recipe/heating/**` | 883 |
| R-13 | `tfc:quern` | `net.dries007.tfc.common.recipes.QuernRecipe` | 第 62 行 `register("quern", QuernRecipe.CODEC, QuernRecipe.STREAM_CODEC)` | `data/tfc/recipe/quern/**` | 89 |
| R-14 | `tfc:scraping` | `net.dries007.tfc.common.recipes.ScrapingRecipe` | 第 63 行 `register("scraping", ScrapingRecipe.CODEC, ScrapingRecipe.STREAM_CODEC)` | `data/tfc/recipe/scraping/**` | 7 |
| R-15 | `tfc:knapping` | `net.dries007.tfc.common.recipes.KnappingRecipe` | 第 67 行 `register("knapping", KnappingRecipe.CODEC, KnappingRecipe.STREAM_CODEC)` | `data/tfc/recipe/knapping/**` | 101 |
| R-16 | `tfc:glassworking` | `net.dries007.tfc.common.recipes.GlassworkingRecipe` | 第 78 行 `register("glassworking", GlassworkingRecipe.CODEC, GlassworkingRecipe.STREAM_CODEC)` | `data/tfc/recipe/glassworking/**` | 60 |
| R-17 | `tfc:sewing` | `net.dries007.tfc.common.recipes.SewingRecipe` | 第 79 行 `register("sewing", SewingRecipe.CODEC, SewingRecipe.STREAM_CODEC)` | `data/tfc/recipe/sewing/**` | 25 |

##### 本组共同事实（源码依据）

1. **配方类型注册表**：`moddev\src-ref\TFC-decompiled\net\dries007\tfc\common\recipes\TFCRecipeTypes.java` 第 43 行，
   `public static final DeferredRegister<RecipeType<?>> RECIPE_TYPES = DeferredRegister.create(Registries.RECIPE_TYPE, "tfc");`
   第 47、48、50、51、62、63 行分别注册 `heating`、`quern`、`scraping`、`knapping`、`glassworking`、`sewing`。
   `register(String name)` 内部 `RECIPE_TYPES.register(name, () -> new RecipeType<R>(){ ... })`（第 65-72 行），
   `toString()` 直接返回裸名 → 注册 id 为 `tfc:<name>`。

2. **序列化器注册表**：同目录 `TFCRecipeSerializers.java` 第 57 行 `DeferredRegister.create(Registries.RECIPE_SERIALIZER, "tfc")`；
   第 85-87 行 `register(String name, MapCodec<R> codec, StreamCodec<...> stream)` 统一包装为 `new RecipeSerializerImpl<R>(codec, stream)`。
   因此每种配方的 JSON 解码入口就是该类的 `CODEC`（`MapCodec`），JSON 顶层必须有 `"type": "tfc:<name>"` 作为 `RecipeSerializer` 分派键。

3. **1.21 数据包目录名是单数 `recipe`**（非旧版 `recipes`）。已由 `moddev\jar-extract\data\tfc\recipe\` 的实际存在证实。
   数据类（`DataManager` 管理的非配方文件）则位于 `data/tfc/tfc/<kind>/`，例如 `data/tfc/tfc/knapping_type/`、`data/tfc/tfc/item_heat/`。

4. **反编译产物没有参数名**：所有 `CODEC` 均为 `RecordCodecBuilder` 形式，字段名以字符串字面量硬编码在 `fieldOf(...)` / `optionalFieldOf(...)` 中，
   因此字段名可信；但反编译后的形参名（如 `c`、`i`、`j`）无意义，本文不引用。

5. **`MapCodec` 平铺规则**：当一个字段用另一个 `MapCodec` 的 `forGetter` 直接接入（例如 `KnappingPattern.CODEC.forGetter(c -> c.pattern)`），
   该 `MapCodec` 内部的字段名会**平铺到当前 JSON 顶层**，而不是嵌成一个子对象。这类情况在 R-15 中必须特别注意。

---

### A3 共享依赖：ItemStackProvider / ItemStackModifier / Ingredient / ItemStack

本组 6 种类型中，R-12 用到 `ItemStackProvider` + `FluidStack` + `ItemStack`，R-13、R-14 用到 `ItemStackProvider`，
R-15、R-16、R-17 用的却是**裸 `ItemStack`**。差异必须在各节字段表中写明。

##### A3.1 ItemStackProvider 的两种 JSON 形态

源码：`moddev\src-ref\TFC-decompiled\net\dries007\tfc\common\recipes\outputs\ItemStackProvider.java` 第 34-35 行。

```java
public record ItemStackProvider(ItemStack stack, List<ItemStackModifier> modifiers) {
    public static final Codec<ItemStackProvider> CODEC = Codec.either(
        RecordCodecBuilder.create(i -> i.group(
            ItemStack.CODEC.optionalFieldOf("stack", ItemStack.EMPTY).forGetter(c -> c.stack),
            ItemStackModifier.CODEC.listOf().fieldOf("modifiers").forGetter(c -> c.modifiers)
        ).apply(i, ItemStackProvider::new)),
        ItemStack.CODEC
    ).xmap(e -> e.map(Function.identity(), ItemStackProvider::of),
           provider -> provider.modifiers.isEmpty() ? Either.right(provider.stack) : Either.left(provider));
```

`Codec.either(left, right)` 先用 `left` 解码，失败再试 `right`。于是产生两种等价写法：

**形态 A —— 直接写 ItemStack（无 modifier）**

```json
"result": {"count": 1, "id": "tfc:large_raw_hide"}
```

**形态 B —— 对象形态（`modifiers` 必填）**

```json
"result": {"modifiers": [{"type": "tfc:copy_food"}], "stack": {"count": 1, "id": "tfc:food/cooked_beef"}}
```

要点：
- 形态 B 中 `stack` 是 `optionalFieldOf("stack", ItemStack.EMPTY)`，**可以省略**（此时基础产物为空，完全靠 modifier 产出）；
- 形态 B 中 `modifiers` 是 `fieldOf("modifiers")`，**必需**，即使写空数组 `[]` 也必须出现该键；
- 纯 `ItemStack` JSON（形态 A）会先被 `left` 尝试并因其缺少 `modifiers` 而失败，随后落到 `right` 成功，不是"两种 codec 竞争"。

`ItemStackProvider` 的运行时语义（同文件第 72-109 行）：
- `getSingleStack(input)` = `getStack(input.copyWithCount(1))` → 数量按 1 计算；
- `getStack(input, context)` 第 93-96 行：`output = stack.copy()`，若 `input` 非空则 `output.setCount(output.getCount() * input.getCount())`，
  即 **产物数量随输入堆叠数倍增**；随后逐个 `modifier.apply(output, input, context)`；
- `getEmptyStack()` 与 `getStackDisplayOnly(...)` 使用 `Context.NO_RANDOM_CHANCE`，用于配方书/JEI 显示（让 `tfc:chance` 不掷随机数、只追加提示 Lore）；
- `dependsOnInput()` 只要有一个 modifier `dependsOnInput()` 为真就返回真，`ItemRecipe.isSpecial()` 直接返回它（`ItemRecipe.java` 第 61-64 行）。

##### A3.2 ItemStackModifier 注册表全清单

源码：`moddev\src-ref\TFC-decompiled\net\dries007\tfc\common\recipes\outputs\ItemStackModifiers.java` 第 54-78 行。
分派方式（`ItemStackModifier.java` 第 22 行）：
`ItemStackModifiers.REGISTRY.byNameCodec().dispatch(ItemStackModifier::type, ItemStackModifierType::codec)`
→ JSON 中每个 modifier 都是**带 `type` 键的对象**，`type` 值为下列注册名（`tfc:` 命名空间，实际 JSON 中写作 `"tfc:copy_food"`）。

| 注册名 | 实现类 | 是否带额外字段 | 字段与类型 |
| --- | --- | --- | --- |
| `tfc:copy_input` | `CopyInputModifier` | 否（unit codec） | — |
| `tfc:copy_food` | `CopyFoodModifier` | 否 | — |
| `tfc:copy_oldest_food` | `CopyOldestFoodModifier` | 否 | — |
| `tfc:copy_heat` | `CopyHeatModifier` | 否 | — |
| `tfc:copy_forging_bonus` | `CopyForgingBonusModifier` | 否 | — |
| `tfc:reset_food` | `ResetFoodModifier` | 否 | — |
| `tfc:empty_bowl` | `EmptyBowlModifier` | 否 | — |
| `tfc:flower_cutting` | `FlowerCuttingModifier` | 否 | — |
| `tfc:add_bait_to_rod` | `AddBaitToRodModifier` | 否 | — |
| `tfc:add_glass` | `AddGlassModifier` | 否 | — |
| `tfc:add_powder` | `AddPowderModifier` | 否 | — |
| `tfc:crafting_remainder` | `CraftingRemainderModifier` | 否 | — |
| `tfc:damage_crafting_remainder` | `DamageCraftingRemainderModifier` | 否 | — |
| `tfc:round_creation_date` | `RoundCreationDateModifier` | 否 | — |
| `tfc:remove_dye` | `RemoveDyeModifier` | 否 | — |
| `tfc:add_trait` | `AddTraitModifier` | 是 | `trait` : `FoodTrait`（`AddTraitModifier.java:26`） |
| `tfc:remove_trait` | `RemoveTraitModifier` | 是 | `trait` : `FoodTrait`（`RemoveTraitModifier.java:26`） |
| `tfc:add_heat` | `AddHeatModifier` | 是 | `temperature` : float（`AddHeatModifier.java:30`） |
| `tfc:dye_leather` | `DyeLeatherModifier` | 是 | `color` : `DyeColor`（`DyeLeatherModifier.java:29`） |
| `tfc:meal` | `MealModifier` | 是 | `food` : `FoodData`（必需）、`portions` : list（必需，元素含 `ingredient` 可选 / `nutrient_modifier` 默认 1.0 / `water_modifier` 默认 1.0 / `saturation_modifier` 默认 1.0）（`MealModifier.java:52`） |
| `tfc:extra_products` | `ExtraProductModifier` | 是 | `stack` : `ItemStack`（`ExtraProductModifier.java:30`），产物额外塞给 `RecipeHelpers.getCraftingPlayer()` 的玩家 |
| `tfc:chance` | `ChanceModifier` | 是 | `chance` : float（`ChanceModifier.java:29`） |

共 **22** 项（15 项无字段 + 7 项带字段）。注册方法见 `ItemStackModifiers.java` 第 80-86 行：
无字段的走 `MapCodec.unit(singleInstance)`；带字段的走传入的 `MapCodec`。

`tfc:chance` 的语义（`ChanceModifier.java` 第 33-47 行）：
- `Context.NO_RANDOM_CHANCE`（配方书/JEI/`getEmptyStack`）→ 不掷随机，只 `Lore.append("tfc.tooltip.chance", chance*100)`；
- `Context.DEFAULT`（实际产出）→ 对 `stack.getCount()` 逐件 `Math.random() < chance`，计数为 0 时返回 `ItemStack.EMPTY`（产物消失）。

> 注意：`tfc:heating` 的"概率产出"**不是配方字段**，而是通过 `result_item.modifiers` 中的 `tfc:chance` 实现。
> 全 883 个 heating JSON 中，`"chance"` 仅出现 1 次，即 `data/tfc/recipe/heating/powder/kaolinite.json`。

##### A3.3 TFC 自定义 Ingredient 类型

源码：`moddev\src-ref\TFC-decompiled\net\dries007\tfc\common\recipes\ingredients\TFCIngredients.java` 第 41-48 行，
注册进 NeoForge 的 `NeoForgeRegistries.INGREDIENT_TYPES`，命名空间 `tfc`：

| type 值 | 实现类 | 用途 |
| --- | --- | --- |
| `tfc:rotten` | `RottenIngredient` | 匹配已腐烂的食品 |
| `tfc:not_rotten` | `NotRottenIngredient` | 匹配未腐烂的食品 |
| `tfc:has_trait` | `HasTraitIngredient` | 匹配带某食品词条的物品 |
| `tfc:lacks_trait` | `LacksTraitIngredient` | 匹配不带某食品词条的物品 |
| `tfc:heat` | `HeatIngredient` | 按温度区间匹配 |
| `tfc:fluid_content` | `FluidContentIngredient` | 按容器内流体匹配 |
| `tfc:and` | `AndIngredient` | 逻辑与，字段 `children` : Ingredient 列表 |

最常见的写法（全 883 个 heating JSON 中 56 个使用 `tfc:and`）：

```json
"ingredient": {"type": "tfc:and", "children": [{"item": "tfc:food/beef"}, {"type": "tfc:not_rotten"}]}
```

普通 `Ingredient` 的写法（原版 / NeoForge）：
- 单物品：`{"item": "tfc:metal/propick/copper"}`
- 物品标签：`{"tag": "c:storage_blocks/zinc"}`
- 多物品数组：`[{"item": "tfc:plant/blue_orchid"}, {"item": "tfc:plant/grape_hyacinth"}]`

`AndIngredient` 的具体字段名可从 JSON 反证为 `children`；其 `CODEC` 定义在
`moddev\src-ref\TFC-decompiled\net\dries007\tfc\common\recipes\ingredients\AndIngredient.java`（本组未逐行展开，见 A3「未能核实」）。

##### A3.4 ItemStack 的 JSON 写法（1.21 组件化格式）

1.21 中物品栈为 `{"id": "...", "count": N, "components": {...}}`，`count` 缺省为 1。实例见
`data/tfc/recipe/knapping/call_goat_horn_goat_horn.json`：

```json
{"type":"tfc:knapping","knapping_type":"tfc:goat_horn","pattern":["#####","#   #","# ###","## ##","#####"],"result":{"components":{"minecraft:instrument":"minecraft:call_goat_horn"},"count":1,"id":"minecraft:goat_horn"}}
```

`FluidStack` 的 JSON 写法为 `{"amount": N, "id": "tfc:metal/copper"}`。

---

### [R-12] tfc:heating —— 加热 / 熔炼

##### R-12.1 基本信息

| 项 | 值 |
| --- | --- |
| type id | `tfc:heating` |
| 实现类 | `net.dries007.tfc.common.recipes.HeatingRecipe` |
| 源码路径 | `moddev\src-ref\TFC-decompiled\net\dries007\tfc\common\recipes\HeatingRecipe.java` |
| 实现接口 | `INoopInputRecipe`、`IRecipePredicate<ItemStack>` |
| 配方类型 | `TFCRecipeTypes.HEATING`（`TFCRecipeTypes.java:47`） |
| 序列化器 | `TFCRecipeSerializers.HEATING`（`TFCRecipeSerializers.java:61`） |
| JSON 目录 | `data/tfc/recipe/heating/`（含 `ceramic/`、`food/`、`hanging_sign/`、`metal/`、`ore/`、`pan/`、`powder/` 7 个子目录） |
| 真实文件数 | 883 |
| 索引缓存 | `IndirectHashCollection<Item, HeatingRecipe> CACHE`，键为 `RecipeHelpers.itemKeys(ingredient)`（第 55 行），即**按 Ingredient 展开的物品建索引** |

##### R-12.2 CODEC 逐字段考证

`HeatingRecipe.java` 第 56 行（原文照录，去除强转噪音后）：

```java
public static final MapCodec<HeatingRecipe> CODEC = RecordCodecBuilder.mapCodec(i -> i.group(
    Ingredient.CODEC.fieldOf("ingredient").forGetter(c -> c.ingredient),
    ItemStackProvider.CODEC.optionalFieldOf("result_item", ItemStackProvider.empty()).forGetter(c -> c.outputItem),
    FluidStack.CODEC.optionalFieldOf("result_fluid", FluidStack.EMPTY).forGetter(c -> c.outputFluid),
    Codec.FLOAT.fieldOf("temperature").forGetter(c -> Float.valueOf(c.temperature)),
    Codec.BOOL.optionalFieldOf("use_durability", false).forGetter(c -> c.useDurability)
).apply(i, HeatingRecipe::new));
```

构造器（第 69-75 行）：`HeatingRecipe(Ingredient ingredient, ItemStackProvider outputItem, FluidStack outputFluid, float temperature, boolean useDurability)` —— 与 CODEC 的 5 个组件一一对应，**没有第 6 个组件**。

`STREAM_CODEC`（第 57 行）同序使用 `Ingredient.CONTENTS_STREAM_CODEC` / `ItemStackProvider.STREAM_CODEC` /
`FluidStack.OPTIONAL_STREAM_CODEC` / `ByteBufCodecs.FLOAT` / `ByteBufCodecs.BOOL`，可作为字段顺序的独立交叉验证。

##### R-12.3 字段表

字段全部来自 `HeatingRecipe` 自身（该类**不继承** `ItemRecipe`，因此没有父类字段需要合并）。

| 字段名 | 类型 | 必需/可选 | 默认值 | 语义 |
| --- | --- | --- | --- | --- |
| `ingredient` | `Ingredient` | **必需** | 无 | 被加热的物品。支持 `{"item":...}`、`{"tag":...}`、物品数组、以及 TFC 自定义 Ingredient（`tfc:and` 等）。`matches(ItemStack)` 即 `ingredient.test(input)`（第 78-80 行） |
| `result_item` | `ItemStackProvider` | 可选 | `ItemStackProvider.empty()`（空 provider，产物为空物品） | 加热后得到的**固体产物**。可为纯 `ItemStack`，或 `{"stack":..., "modifiers":[...]}`。产出走 `assembleItem(input)`（第 82-89 行），并在输入带热组件时**继承输入温度**（`HeatCapability.setTemperature(outputStack, inputHeat.getTemperature())`） |
| `result_fluid` | `FluidStack` | 可选 | `FluidStack.EMPTY`（空流体） | 加热后熔出的**流体产物**，写法 `{"amount":100,"id":"tfc:metal/copper"}`。产出走 `assembleFluid(inputStack)`（第 91-97 行） |
| `temperature` | `float` | **必需** | 无 | 触发温度阈值。判定见 `isValidTemperature(float)`（第 113-115 行）：`temperatureIn >= this.temperature`。热源温度不低于此值时才产出 |
| `use_durability` | `boolean` | 可选 | `false` | 仅对 `result_fluid` 生效：为 `true` 时按输入物品剩余耐久比例削减流体产量，见第 93-95 行 `outputFluid.setAmount(Mth.floor(outputFluid.getAmount() * (1 - damage/maxDamage)))` |

##### R-12.4 校验、默认值与"不存在"的字段

- **`chance` 字段不存在。** `HeatingRecipe` 的 CODEC 中没有任何名为 `chance` 的字段，构造器也没有该参数。
  概率产出只能通过 `result_item.modifiers` 里的 `tfc:chance` modifier 表达（见 A3.2 与本文 R-12.6 样例 4）。
  实测：883 个文件里字符串 `"chance"` 仅出现 1 次，且位于 `modifiers` 数组内部。
- **没有 `validate(...)` / `Codec.either(...)`**：`HeatingRecipe.CODEC` 是纯 `RecordCodecBuilder.mapCodec` + 3 个 `optionalFieldOf` + 2 个 `fieldOf`，无自定义校验函数。
  这意味着"只给 `ingredient` + `temperature`、不给任何产物"是**合法的**（见 R-12.6 样例 5、6），语义为"烧毁"。
- **两个可选产物可以同时缺失，但不能同时存在吗？** CODEC 层面二者可同时给出（无 either / 无校验），但**实际数据中不存在同时给出的文件**：
  883 个文件中，143 个只有 `result_item`，738 个只有 `result_fluid`，0 个两者都有，2 个两者都无。
- `use_durability` 仅在 `result_fluid` 非空且输入物品可损毁时才有意义（第 93 行条件：
  `useDurability && !outputFluid.isEmpty() && inputStack.getMaxDamage() > 0 && inputStack.isDamageableItem()`）。实测 198 个文件写了 `"use_durability": true`。

##### R-12.5 全部字段使用统计（883 文件实测）

| 组合 | 文件数 |
| --- | --- |
| 仅 `result_item` | 143 |
| 仅 `result_fluid` | 738 |
| 两者都有 | 0 |
| 两者都无（"烧毁"配方） | 2 |
| 含 `"use_durability": true` | 198 |
| `ingredient` 为 `tfc:and` 复合类型 | 56 |
| `ingredient` 顶层为物品数组 | 见 `hanging_sign/` 下 11 个文件等 |

##### R-12.6 真实 JSON 样例

**样例 1 —— 金属工具回炉（`result_fluid` + `use_durability`）**
文件：`data/tfc/recipe/heating/metal/propick/copper.json`

```json
{"type":"tfc:heating","ingredient":{"item":"tfc:metal/propick/copper"},"result_fluid":{"amount":100,"id":"tfc:metal/copper"},"temperature":1080.0,"use_durability":true}
```

**样例 2 —— 矿石熔炼（`ingredient` 为单物品，无 `use_durability`）**
文件：`data/tfc/recipe/heating/ore/rich_hematite.json`

```json
{"type":"tfc:heating","ingredient":{"item":"tfc:ore/rich_hematite"},"result_fluid":{"amount":35,"id":"tfc:metal/cast_iron"},"temperature":1535.0}
```

**样例 3 —— 标签 Ingredient（`{"tag": ...}` 写法）**
文件：`data/tfc/recipe/heating/metal/block/zinc.json`

```json
{"type":"tfc:heating","ingredient":{"tag":"c:storage_blocks/zinc"},"result_fluid":{"amount":100,"id":"tfc:metal/zinc"},"temperature":420.0}
```

**样例 4 —— 固体产物 + `tfc:chance` 概率 modifier（本类唯一带 chance 的文件）**
文件：`data/tfc/recipe/heating/powder/kaolinite.json`

```json
{"type":"tfc:heating","ingredient":{"item":"tfc:kaolin_clay"},"result_item":{"modifiers":[{"type":"tfc:chance","chance":0.2}],"stack":{"count":1,"id":"tfc:powder/kaolinite"}},"temperature":500.0}
```

**样例 5 —— 食物烹饪（`tfc:and` Ingredient + `tfc:copy_food`）**
文件：`data/tfc/recipe/heating/food/cooked_beef.json`

```json
{"type":"tfc:heating","ingredient":{"type":"tfc:and","children":[{"item":"tfc:food/beef"},{"type":"tfc:not_rotten"}]},"result_item":{"modifiers":[{"type":"tfc:copy_food"}],"stack":{"count":1,"id":"tfc:food/cooked_beef"}},"temperature":200.0}
```

**样例 6 —— "烧毁"配方（只有 `ingredient` + `temperature`，两个产物字段都省）**
文件：`data/tfc/recipe/heating/burn_bread.json`

```json
{"type":"tfc:heating","ingredient":{"tag":"c:foods/bread"},"temperature":700.0}
```

**样例 7 —— 同系列第二个"烧毁"配方**
文件：`data/tfc/recipe/heating/burn_meat.json`

```json
{"type":"tfc:heating","ingredient":{"tag":"c:foods/cooked_meat"},"temperature":900.0}
```

**样例 8 —— 大型物品数组 Ingredient（20 个悬挂告示牌）**
文件：`data/tfc/recipe/heating/hanging_sign/bronze.json`（节选首尾，完整文件为单行）

```json
{"type":"tfc:heating","ingredient":[{"item":"tfc:wood/hanging_sign/bronze/acacia"},{"item":"tfc:wood/hanging_sign/bronze/ash"},{"item":"tfc:wood/hanging_sign/bronze/aspen"},{"item":"tfc:wood/hanging_sign/bronze/birch"},{"item":"tfc:wood/hanging_sign/bronze/blackwood"},{"item":"tfc:wood/hanging_sign/bronze/chestnut"},{"item":"tfc:wood/hanging_sign/bronze/douglas_fir"},{"item":"tfc:wood/hanging_sign/bronze/hickory"},{"item":"tfc:wood/hanging_sign/bronze/kapok"},{"item":"tfc:wood/hanging_sign/bronze/mangrove"},{"item":"tfc:wood/hanging_sign/bronze/maple"},{"item":"tfc:wood/hanging_sign/bronze/oak"},{"item":"tfc:wood/hanging_sign/bronze/palm"},{"item":"tfc:wood/hanging_sign/bronze/pine"},{"item":"tfc:wood/hanging_sign/bronze/rosewood"},{"item":"tfc:wood/hanging_sign/bronze/sequoia"},{"item":"tfc:wood/hanging_sign/bronze/spruce"},{"item":"tfc:wood/hanging_sign/bronze/sycamore"},{"item":"tfc:wood/hanging_sign/bronze/white_cedar"},{"item":"tfc:wood/hanging_sign/bronze/willow"}],"result_fluid":{"amount":4,"id":"tfc:metal/bronze"},"temperature":950.0}
```

##### R-12.7 `temperature` 与 `data/tfc/tfc/item_heat/` 的配合

这是 heating 配方最容易踩坑的地方，必须讲清"哪些物品无法加热"。

**(1) 热数据的定义位置与字段**

`data/tfc/tfc/item_heat/*.json` 由 `HeatDefinition` 解析：

- 数据类：`moddev\src-ref\TFC-decompiled\net\dries007\tfc\common\component\heat\HeatDefinition.java`
  第 28 行 `public record HeatDefinition(Ingredient ingredient, float heatCapacity, float forgingTemperature, float weldingTemperature)`
  第 30 行 CODEC：

```java
public static final Codec<HeatDefinition> CODEC = RecordCodecBuilder.create(i -> i.group(
    Ingredient.CODEC.fieldOf("ingredient").forGetter(c -> c.ingredient),
    Codec.FLOAT.fieldOf("heat_capacity").forGetter(c -> Float.valueOf(c.heatCapacity)),
    Codec.FLOAT.optionalFieldOf("forging_temperature", 0.0f).forGetter(c -> Float.valueOf(c.forgingTemperature)),
    Codec.FLOAT.optionalFieldOf("welding_temperature", 0.0f).forGetter(c -> Float.valueOf(c.weldingTemperature))
).apply(i, HeatDefinition::new));
```

| 字段 | 类型 | 必需/可选 | 默认值 | 语义 |
| --- | --- | --- | --- | --- |
| `ingredient` | `Ingredient` | 必需 | — | 应用该热属性的物品 |
| `heat_capacity` | `float` | **必需** | — | 热容；越大升温越慢、降温越慢。用于 `HeatCapability.adjustTemp` 与 `addTemp` 的除数 |
| `forging_temperature` | `float` | 可选 | `0.0f` | 可锻造温度；`IHeatView.canWork()` = `temperature >= forgingTemperature` |
| `welding_temperature` | `float` | 可选 | `0.0f` | 可焊接温度；`IHeatView.canWeld()` = `temperature >= weldingTemperature` |

- 数据管理器与索引：`net\dries007\tfc\common\component\heat\HeatCapability.java`
  第 43 行 `public static final DataManager<HeatDefinition> MANAGER = new DataManager<>(Helpers.identifier("item_heat"), HeatDefinition.CODEC, HeatDefinition.STREAM_CODEC);`
  → 数据包路径即 `data/<ns>/tfc/item_heat/<id>.json`。
  第 44 行 `CACHE = IndirectHashCollection.create(r -> RecipeHelpers.itemKeys(r.ingredient()), MANAGER::getValues)`。
  第 94-97 行 `getDefinition(ItemStack)` = `RecipeHelpers.getRecipe(CACHE, stack, stack.getItem())`，**按物品查**，命中不到返回 `null`。

**(2) item_heat 决定"能不能被加热"**

`HeatCapability.get(stack)`（第 47-55 行）先查 `ItemCapabilities.HEAT` 能力，再查 `TFCComponents.HEAT` 组件；
两者都没有就返回 `null`。**只有带热能力的物品堆叠才能升温**，否则即使物品匹配了 heating 配方也永远不会达到 `temperature`。

这一约束在每个调用点都被显式判空，例如：
- `FirepitBlockEntity.java:79` `if (this.temperature > 0.0f && (cap = HeatCapability.get(inputStack)) != null)`
- `FireboxBlockEntity.java:193-194` `IHeat heat = HeatCapability.get(item); if (heat == null) continue;`
- `PitKilnBlockEntity.java:269-270` `@Nullable IHeat heat = HeatCapability.get(stack); if (heat == null) continue;`
- `CrucibleBlockEntity.java:135` `if (!inputStack.isEmpty() && (inputHeat = HeatCapability.get(inputStack)) != null)`
- `GrillBlockEntity.java:81-82`、`Vessel.java:203-204`、`BlastFurnaceBlockEntity.java:153-154`、`CharcoalForgeBlockEntity.java:310-311` 同理。

**物品何时获得热能力？** 由 `HeatDefinition` 决定 —— 具体地，物品的热组件/能力注册与 `item_heat` 数据挂钩；
`IHeatView.addTooltipInfo`（`IHeatView.java:38-55`）与 `GlassWorking.addTooltipInfo`（`GlassWorking.java:32-36`）在物品带热数据时才会展示温度提示。

**(3) 自检：TFC 自己会校验"heating 配方的输入是否有 item_heat"**

`moddev\src-ref\TFC-decompiled\net\dries007\tfc\util\SelfTests.java` 第 340-341 行：

```java
private static boolean validateHeatingRecipeIngredientsAreHeatable(RecipeManager manager) {
    List<ItemStack> errors = manager.getAllRecipesFor(TFCRecipeTypes.HEATING.get()).stream()
        .flatMap(recipe -> Arrays.stream(((HeatingRecipe) recipe.value()).getIngredient().getItems()))
        .filter(stack -> HeatCapability.getDefinition(stack) == null).toList();
```

即：**任何被某个 `tfc:heating` 配方引用的物品，若无对应 `item_heat` 定义，就会被自检列为错误。**
该自检在第 172 行与其他自检一起被执行。因此对模组作者而言，"加了一条 heating 配方却没写 item_heat" 会直接触发 TFC 的数据自检报错。

**(4) 哪些物品会因 item_heat 缺失而无法加热（实务结论）**

- 任何**没有** `data/tfc/tfc/item_heat/*.json` 条目、且未被其他模组/数据包赋予热组件的物品：`HeatCapability.get()` 返回 `null` → 温度恒为 0 → `isValidTemperature` 永假 → 该 heating 配方永不生效（且会触发上面的自检错误）。
- `item_heat` 的覆盖方式是按 `ingredient` 匹配，可写单个 `{"item":...}` 或物品数组（见样例），也可用标签。
- 实测 `data/tfc/tfc/item_heat/` 共 **343** 个 JSON，分布在 35 个子目录
  （`bismuth`、`bismuth_bronze`、`black_bronze`、`black_steel`、`blue_steel`、`brass`、`bronze`、`cast_iron`、`ceramic`、`copper`、`food`、`foods`、`gold`、`high_carbon_black_steel`、`high_carbon_blue_steel`、`high_carbon_red_steel`、`high_carbon_steel`、`nickel`、`pig_iron`、`powder`、`red_steel`、`rods`、`rose_gold`、`silver`、`steel`、`sterling_silver`、`tin`、`unknown`、`weak_blue_steel`、`weak_red_steel`、`weak_steel`、`wrought_iron`、`zinc` 及根目录）。
- 真实样例，文件 `data/tfc/tfc/item_heat/anemometer.json`：

```json
{"forging_temperature":558.0,"heat_capacity":5.714286,"ingredient":{"item":"tfc:anemometer"},"welding_temperature":744.0}
```

- 真实样例，文件 `data/tfc/tfc/item_heat/bismuthinite.json`（`ingredient` 为物品数组，一条覆盖 4 种矿石）：

```json
{"forging_temperature":162.0,"heat_capacity":2.857143,"ingredient":[{"item":"tfc:ore/small_bismuthinite"},{"item":"tfc:ore/poor_bismuthinite"},{"item":"tfc:ore/normal_bismuthinite"},{"item":"tfc:ore/rich_bismuthinite"}],"welding_temperature":216.0}
```

**(5) `temperature` 与 `heat_capacity` 的分工**

- heating 配方的 `temperature`：**产出阈值**，热源/物品温度 `>=` 它才产出；
- item_heat 的 `heat_capacity`：**升温速率的分母**。`HeatCapability.addTemp(instance, target, modifier)` 第 158-167 行
  `newTemperature = initial + modifier / instance.getHeatCapacity()`，并按 `targetTemperature` 截顶；
- item_heat 的 `forging_temperature` / `welding_temperature`：**锻造与焊接阈值**，与 heating 配方 `temperature` 相互独立（但在数据上通常接近/略低）。

##### R-12.8 游戏内触发条件（全部调用点，逐一列出）

`HeatingRecipe.getRecipe(ItemStack)` 定义在 `HeatingRecipe.java` 第 64-67 行：

```java
@Nullable
public static HeatingRecipe getRecipe(ItemStack stack) {
    return RecipeHelpers.getRecipe(CACHE, stack, stack.getItem());
}
```

它**不接 Level 参数**（与 R-13/R-16 不同），靠 `CACHE` 静态索引按物品查。以下为全仓库 grep 出的**全部**调用/引用点。

**A. 方块实体主逻辑（真正做加热的地方）**

| # | 相对源码路径 | 行号 | 调用上下文与作用 |
| --- | --- | --- | --- |
| 1 | `net\dries007\tfc\common\blockentities\FirepitBlockEntity.java` | 98 | `updateCachedRecipe()`：`this.cachedRecipe = HeatingRecipe.getRecipe(this.inventory.getStackInSlot(4))` |
| 2 | 同上 | 82-86 | `handleCooking()`：`if (cachedRecipe != null && cachedRecipe.isValidTemperature(itemTemp))` → `assembleItem` + `assembleFluid`。**篝火/火坑**（输入槽 4，输出槽 5/6） |
| 3 | `net\dries007\tfc\common\blockentities\GrillBlockEntity.java` | 104 | `updateCachedRecipe()`：对槽 4..8 各取一次 `getRecipe` |
| 4 | 同上 | 84-88 | `handleCooking()`：产出后追加 `FoodTraits.WOOD_GRILLED` 词条。**烤架/火盆** |
| 5 | `net\dries007\tfc\common\blockentities\CharcoalForgeBlockEntity.java` | 343 | `updateCachedRecipes()`：对输入槽 5..9 各取一次 `getRecipe` |
| 6 | 同上 | 309-319 | `handleInputMelting(stack, startIndex)`：产出后追加 `FoodTraits.CHARCOAL_GRILLED`。**木炭炉（锻造炉主体）** |
| 7 | `net\dries007\tfc\common\blockentities\CrucibleBlockEntity.java` | 288 | `setAndUpdateSlots(int slot)`：`if (slot != 9) cachedRecipes[slot] = HeatingRecipe.getRecipe(...)` |
| 8 | 同上 | 299 | `updateCaches()`：对槽 0..8 全部刷新 |
| 9 | 同上 | 137-145 | 主 tick：`cachedRecipes[slot]` + `isValidTemperature` → `assembleItem` / `assembleFluid`，并对固体产物加 `FoodTraits.BURNT_TO_A_CRISP`，流体灌入内部储罐。**坩埚** |
| 10 | `net\dries007\tfc\common\blockentities\PitKilnBlockEntity.java` | 287 | `updateCache()`：对槽 0..3 各取一次 `getRecipe` |
| 11 | 同上 | 272-275 | `cookContents()`：以 `pitKilnTemperature` 为目标温度，`isValidTemperature` 通过后 `assembleItem`。**炭窑/土窑（pit kiln）** |
| 12 | `net\dries007\tfc\common\blockentities\FireboxBlockEntity.java` | 196 | 火焰炉烤炉逻辑：`level.getGameTime() % 20L == 0` 时 `getRecipe(item)`，再 `recipe.matches(item)` + `isValidTemperature`，产出回写物品栏。**炭炉（firebox，多方块锻造炉的核心）** |
| 13 | `net\dries007\tfc\common\blockentities\BloomeryBlockEntity.java` | 277 | 点火时遍历炉内掉落物：`getRecipe(item)` → `assembleFluid` → 匹配 `BloomeryRecipe` |
| 14 | 同上 | 344-347 | 出铁时对产物 `getRecipe(outputStack)`，若命中则 `setTemperature(outputStack, recipe.getTemperature() - 1.0f)` |
| 15 | 同上 | 364-366 | `updateCachedRecipe()`：遍历输入取 `getRecipe`，用 `assembleFluid` 匹配 `BloomeryRecipe`。**炼铁炉** |
| 16 | `net\dries007\tfc\common\blockentities\BlastFurnaceBlockEntity.java` | 377 | `updateCachedRecipes()`：对输入物品逐个 `getRecipe` 存入 `inputCachedRecipes` |
| 17 | 同上 | 148-158 | 主 tick：迭代 `inputCachedRecipes`，`isValidTemperature` 通过后 `assembleFluid` 汇入输入流体。**高炉** |

**B. 配方类之间的级联（其他配方会先解析 heating 拿熔液）**

| # | 相对源码路径 | 行号 | 调用上下文 |
| --- | --- | --- | --- |
| 18 | `net\dries007\tfc\common\recipes\BlastFurnaceRecipe.java` | 53 | `get(Level, ItemStack)`：先用 `HeatingRecipe.getRecipe(stack)` 熔出 `moltenFluid`，再用它匹配 `BlastFurnaceRecipe.inputFluid` |
| 19 | 同上 | 75 | `matchesInput(ItemStack)`：同上，判断该物品能否作为高炉输入 |
| 20 | `net\dries007\tfc\common\recipes\BloomeryRecipe.java` | 89 | `consumeInput(ItemStack)`：`getRecipe` → `assembleFluid` → `matchesInput(FluidStack)` |

**C. 物品组件 / 容器能力（Vessel 等）**

| # | 相对源码路径 | 行号 | 调用上下文 |
| --- | --- | --- | --- |
| 21 | `net\dries007\tfc\common\component\mold\Vessel.java` | 221 | `getCachedRecipe(slot)`：`cache.load(HeatingRecipe.getRecipe(this.vessel.itemContent().get(slot)))` |
| 22 | 同上 | 172-184 | `updateInventoryOnMelt()`：`isValidTemperature` 通过后 `assembleStacked(stack, slotCapacity, false)`（**注意 `stackSizeCap` 参数**）+ `assembleFluid`，流体量按 `stack.getCount()` 倍乘。**大缸（Vessel）物品** |
| 23 | `net\dries007\tfc\common\component\glass\GlassWorking.java` | 32-36 | 玻璃工具提示：若 `temp / 0.8f > recipe.getTemperature()` 则追加 `tfc.tooltip.danger` |
| 24 | `net\dries007\tfc\common\component\heat\IHeatView.java` | 49-52 | 温度 tooltip：若 `temperature > 0.9 * recipe.getTemperature()` 且 `assembleItem(stack).isEmpty()` → 追加 `tfc.tooltip.danger`（**正是"烧毁"配方的提示来源**） |

**D. 客户端展示层（不产出，仅渲染）**

| # | 相对源码路径 | 行号 | 用途 |
| --- | --- | --- | --- |
| 25 | `net\dries007\tfc\client\BarSystem.java` | 64 | 热条形显示 |
| 26 | `net\dries007\tfc\client\ClientForgeEventHandler.java` | 329-337 | 物品 tooltip 追加 "熔化后成为 X（温度 T）"，用 `recipe.assembleFluid(stack)` 与 `recipe.getTemperature()` |
| 27 | `net\dries007\tfc\client\render\blockentity\MoldBlockEntityRenderer.java` | 79 | 铸模方块实体渲染，按 `getRecipe(mold.getOutputStack())` 决定外观 |

**E. 配方查看器（JEI / EMI / Patchouli）**

| # | 相对源码路径 | 行号 | 用途 |
| --- | --- | --- | --- |
| 28 | `net\dries007\tfc\compat\jei\JEIIntegration.java` | 152 | `HEATING = JEIIntegration.type("heating", HeatingRecipe.class)` |
| 29 | `net\dries007\tfc\compat\jei\category\HeatingRecipeCategory.java` | 55-80 | JEI 分类渲染（含流体槽位高度 116/90 分叉） |
| 30 | `net\dries007\tfc\compat\emi\recipe\EmiHeatingRecipe.java` | 53-103 | EMI 配方布局（火焰动画） |
| 31 | `net\dries007\tfc\compat\emi\handlers\EmiFirepitHandler.java` | 35-36 | EMI 篝火处理：仅当 `hasSolidOutput()` |
| 32 | `net\dries007\tfc\compat\emi\handlers\EmiGrillHandler.java` | 41-42 | EMI 烤架处理：仅当 `hasSolidOutput()` |
| 33 | `net\dries007\tfc\compat\emi\handlers\EmiForgeHandler.java` | 41 | EMI 锻造炉处理：任意 heating 配方 |
| 34 | `net\dries007\tfc\compat\patchouli\component\HeatingComponent.java` | 33-65 | Patchouli 手册的 heating 组件 |

**F. 自检**

| # | 相对源码路径 | 行号 | 用途 |
| --- | --- | --- | --- |
| 35 | `net\dries007\tfc\util\SelfTests.java` | 341 | `validateHeatingRecipeIngredientsAreHeatable`：校验所有 heating `ingredient` 均有 `HeatDefinition` |
| 36 | 同上 | 172 | 与其他自检一起执行 |

##### R-12.9 注意事项

1. `HeatingRecipe` **不继承 `ItemRecipe`**，也不实现 `ISimpleRecipe` 的默认 `matches(RecipeInput, Level)`；
   `INoopInputRecipe.matches(NoopInput, Level)` 被 `@Contract("_, _ -> fail")` 标注为抛 `UnsupportedOperationException`（`INoopInputRecipe.java:23-26`）。
   实际匹配入口是 `IRecipePredicate.matches(ItemStack)`（`HeatingRecipe.java:78-80`）。
2. `assembleStacked(ItemStack, int stackSizeCap, boolean isDisplay)`（第 99-107 行）会显式把产物数量夹到
   `min(output.count, min(output.getMaxStackSize(), stackSizeCap))`，这是 `Vessel` 用它而非 `assembleItem` 的原因。
3. `getResultItem(HolderLookup.Provider)`（第 121-124 行）返回 `outputItem.getEmptyStack()`，即**显示用的空输入产物**，
   对"烧毁"配方会返回 `ItemStack.EMPTY`。

---

### [R-13] tfc:quern —— 手推磨 / 磨盘

##### R-13.1 基本信息

| 项 | 值 |
| --- | --- |
| type id | `tfc:quern` |
| 实现类 | `net.dries007.tfc.common.recipes.QuernRecipe`（`extends ItemRecipe`） |
| 源码路径 | `moddev\src-ref\TFC-decompiled\net\dries007\tfc\common\recipes\QuernRecipe.java` |
| 父类 | `net.dries007.tfc.common.recipes.ItemRecipe`（`implements INoopInputRecipe, IRecipePredicate<ItemStack>`） |
| 配方类型 | `TFCRecipeTypes.QUERN`（`TFCRecipeTypes.java:48`） |
| 序列化器 | `TFCRecipeSerializers.QUERN`（`TFCRecipeSerializers.java:62`） |
| JSON 目录 | `data/tfc/recipe/quern/`（含 `food/`、`ore/`、`powder/` 3 个子目录） |
| 真实文件数 | 89 |
| 索引缓存 | `IndirectHashCollection<Item, QuernRecipe> CACHE`，键为 `ItemRecipe::getValidItems`（第 41 行） |

##### R-13.2 CODEC 逐字段考证

`QuernRecipe.java` 第 42 行：

```java
public static final MapCodec<QuernRecipe> CODEC = RecordCodecBuilder.mapCodec(i -> i.group(
    Ingredient.CODEC.fieldOf("ingredient").forGetter(c -> c.ingredient),
    ItemStackProvider.CODEC.fieldOf("result").forGetter(c -> c.result)
).apply(i, QuernRecipe::new));
```

`STREAM_CODEC`（第 43 行）同序：`Ingredient.CONTENTS_STREAM_CODEC` + `ItemStackProvider.STREAM_CODEC`。

构造器（第 50-52 行）：`QuernRecipe(Ingredient ingredient, ItemStackProvider result)` → `super(ingredient, result)`。
两个字段实际落在**父类** `ItemRecipe` 里（`ItemRecipe.java` 第 27-28 行）：

```java
protected final Ingredient ingredient;
protected final ItemStackProvider result;
```

因此：**字段声明属于 `ItemRecipe`，字段名（`ingredient` / `result`）由 `QuernRecipe.CODEC` 决定**。

##### R-13.3 字段表

| 字段名 | 类型 | 必需/可选 | 默认值 | 语义 | 声明位置 |
| --- | --- | --- | --- | --- | --- |
| `ingredient` | `Ingredient` | **必需** | 无 | 磨的输入物品。`matches(ItemStack)` = `ingredient.test(input)`（`ItemRecipe.java:36-38`） | 父类 `ItemRecipe.ingredient` |
| `result` | `ItemStackProvider` | **必需** | 无 | 磨出的产物。`assemble(ItemStack)` = `result.getSingleStack(input)`（`ItemRecipe.java:40-42`），产物数量按输入 1 个计算 | 父类 `ItemRecipe.result` |

**没有可选字段，没有校验函数，没有 `Codec.either`。** 实测 89 个文件字段集合**全部**为 `type,ingredient,result`，无任何例外。

父子类提供的额外语义（不属于 JSON 字段，但影响行为）：
- `ItemRecipe.getResultItem(registries)`（第 44-47 行）返回 `result.getEmptyStack()`；
- `ItemRecipe.isSpecial()`（第 61-64 行）返回 `result.dependsOnInput()`，即含 `copy_food` / `copy_heat` 等 modifier 时会被标记为 special（隐藏于配方书的普通条目）；
- `ItemRecipe.getValidItems()`（第 49-51 行）= `RecipeHelpers.itemKeys(ingredient)`，供 `CACHE` 建索引。

##### R-13.4 真实 JSON 样例

**样例 1 —— 最简形态（单物品 → 固定产物，无 modifier）**
文件：`data/tfc/recipe/quern/powder/flux_from_borax.json`

```json
{"type":"tfc:quern","ingredient":{"item":"tfc:ore/borax"},"result":{"count":6,"id":"tfc:powder/flux"}}
```

**样例 2 —— 物品数组 Ingredient（一次覆盖 3 种植物）**
文件：`data/tfc/recipe/quern/blue_dye.json`

```json
{"type":"tfc:quern","ingredient":[{"item":"tfc:plant/blue_orchid"},{"item":"tfc:plant/grape_hyacinth"},{"item":"tfc:plant/cornflower"}],"result":{"count":2,"id":"minecraft:blue_dye"}}
```

**样例 3 —— `tfc:and` Ingredient + `tfc:copy_food` modifier（面团保鲜信息传递）**
文件：`data/tfc/recipe/quern/food/wheat_flour.json`

```json
{"type":"tfc:quern","ingredient":{"type":"tfc:and","children":[{"item":"tfc:food/wheat_grain"},{"type":"tfc:not_rotten"}]},"result":{"modifiers":[{"type":"tfc:copy_food"}],"stack":{"count":1,"id":"tfc:food/wheat_flour"}}}
```

##### R-13.5 游戏内触发条件

`QuernRecipe.getRecipe(ItemStack)`（第 45-48 行）：

```java
@Nullable
public static QuernRecipe getRecipe(ItemStack input) {
    return RecipeHelpers.getRecipe(CACHE, input, input.getItem());
}
```

调用点（grep 全仓库，非展示层）：

| # | 相对源码路径 | 行号 | 上下文与作用 |
| --- | --- | --- | --- |
| 1 | `net\dries007\tfc\common\blockentities\QuernBlockEntity.java` | 204-215 | `startGrinding()`：读取槽 1 的输入，条件 `!inputStack.isEmpty() && this.hasHandstone() && (recipe = QuernRecipe.getRecipe(inputStack)) != null && recipe.matches(inputStack)`，通过则 `recipeTimer = 90.0f` 并播放 `TFCSounds.QUERN_DRAG` |
| 2 | 同上 | 259-272 | `finishGrinding()`：再次 `getRecipe` + `matches`，然后 `recipe.assemble(inputStack)`，产物合并进槽 2 / 掉落，输入 `shrink(1)`，`recipeTimer = 0` |
| 3 | 同上 | 100-119 | `serverTick`：`wasGrinding && recipeTimer <= 0` 时调用 `finishGrinding()` 并磨损手磨石；若接在旋转网络（风车/水车）上则自动 `startGrinding()` |
| 4 | `net\dries007\tfc\common\blocks\devices\QuernBlock.java` | 139-159 | `useItemOn(...)`：命中判定分支 `case 0/1 → attemptGrind(...)`、`case 1（潜行或手持 QUERN_HANDSTONES）→ insertOrExtract(..., 0)` 换手磨石、`case 2 → insertOrExtract(..., 1)` 放/取输入、`case 3 → insertOrExtract(..., 2)` 取产物 |
| 5 | 同上 | 161-163 | `attemptGrind(...)`：`!quern.isConnectedToNetwork() && quern.startGrinding()` —— **联网时禁止手动摇磨** |

**input 容器**：`QuernBlockEntity.inventory` 为 `ItemStackHandler`，槽位约定
**0 = 手磨石（handstone）**、**1 = 待磨输入**、**2 = 产物输出**（由上述 `insertOrExtract(..., slot)` 的实参 0/1/2 与 `hasHandstone()` 读槽 0、`startGrinding` 读槽 1、`finishGrinding` 读写槽 1/2 共同确定）。

展示层：`net\dries007\tfc\compat\jei\category\QuernRecipeCategory.java`（`SimpleItemRecipeCategory<QuernRecipe>`）、
`net\dries007\tfc\compat\emi\recipe\EmiQuernRecipe.java`、`net\dries007\tfc\compat\patchouli\component\QuernComponent.java`。

---

### [R-14] tfc:scraping —— 刮制（皮革 / 纸）

##### R-14.1 基本信息

| 项 | 值 |
| --- | --- |
| type id | `tfc:scraping` |
| 实现类 | `net.dries007.tfc.common.recipes.ScrapingRecipe`（`extends ItemRecipe`） |
| 源码路径 | `moddev\src-ref\TFC-decompiled\net\dries007\tfc\common\recipes\ScrapingRecipe.java` |
| 父类 | `net.dries007.tfc.common.recipes.ItemRecipe` |
| 配方类型 | `TFCRecipeTypes.SCRAPING`（`TFCRecipeTypes.java:50`） |
| 序列化器 | `TFCRecipeSerializers.SCRAPING`（`TFCRecipeSerializers.java:63`） |
| JSON 目录 | `data/tfc/recipe/scraping/`（无子目录） |
| 真实文件数 | **7**（全部列出见 R-14.4） |
| 索引缓存 | `IndirectHashCollection<Item, ScrapingRecipe> CACHE`，键为 `ItemRecipe::getValidItems`（第 43 行） |

##### R-14.2 CODEC 逐字段考证

`ScrapingRecipe.java` 第 44 行：

```java
public static final MapCodec<ScrapingRecipe> CODEC = RecordCodecBuilder.mapCodec(i -> i.group(
    Ingredient.CODEC.fieldOf("ingredient").forGetter(c -> c.ingredient),
    ItemStackProvider.CODEC.fieldOf("result").forGetter(c -> c.result),
    ResourceLocation.CODEC.fieldOf("input_texture").forGetter(c -> c.inputTexture),
    ResourceLocation.CODEC.fieldOf("output_texture").forGetter(c -> c.outputTexture),
    ItemStackProvider.CODEC.optionalFieldOf("result_item", ItemStackProvider.empty()).forGetter(c -> c.extraDrop)
).apply(i, ScrapingRecipe::new));
```

`STREAM_CODEC`（第 45 行）同序：`Ingredient.CONTENTS_STREAM_CODEC`、`ItemStackProvider.STREAM_CODEC`、
`ResourceLocation.STREAM_CODEC`、`ResourceLocation.STREAM_CODEC`、`ItemStackProvider.STREAM_CODEC`。

构造器（第 55-60 行）：`ScrapingRecipe(Ingredient, ItemStackProvider result, ResourceLocation inputTexture, ResourceLocation outputTexture, ItemStackProvider extraDrop)`。

**关键命名不一致（必须指出）**：第 5 个 JSON 字段名是 **`result_item`**，但它绑定的 Java 字段不是"主产物"，
而是 `extraDrop`（额外掉落）。命名沿用了 `HeatingRecipe` 里 `result_item` 的写法，语义却完全不同。
字段访问器为 `getExtraDrop()`（第 70-72 行）。前 2 个字段来自父类，后 3 个声明在本类（第 46-48 行）。

##### R-14.3 字段表

| 字段名 | 类型 | 必需/可选 | 默认值 | 语义 | 声明位置 |
| --- | --- | --- | --- | --- | --- |
| `ingredient` | `Ingredient` | **必需** | 无 | 待刮物品。`matches(ItemStack)` 继承自 `ItemRecipe.java:36-38` | 父类 `ItemRecipe.ingredient` |
| `result` | `ItemStackProvider` | **必需** | 无 | 刮完后的**主产物**（替换槽内物品）。`assemble(input)` = `result.getSingleStack(input)`（`ItemRecipe.java:40-42`） | 父类 `ItemRecipe.result` |
| `input_texture` | `ResourceLocation` | **必需** | 无 | 刮制界面上"未刮"状态显示的贴图。`getInputTexture()`（第 62-64 行） | 本类 `inputTexture`（第 46 行） |
| `output_texture` | `ResourceLocation` | **必需** | 无 | 刮制界面上"已刮"状态显示的贴图。`getOutputTexture()`（第 66-68 行） | 本类 `outputTexture`（第 47 行） |
| `result_item` | `ItemStackProvider` | 可选 | `ItemStackProvider.empty()`（无额外掉落） | **额外掉落**（不是主产物！）。`getExtraDrop()`（第 70-72 行）。在刮制完成时由 `ScrapingBlockEntity` 单独 `Helpers.spawnItem` 抛出 | 本类 `extraDrop`（第 48 行），**字段名与 Java 字段名不一致** |

**没有 `validate(...)`，没有 `Codec.either(...)`。**

##### R-14.4 真实 JSON 样例（7 个文件中有代表性的 4 个）

字段组合实测：**4 个文件**为 `type,ingredient,input_texture,output_texture,result`（无 `result_item`）；
**3 个文件**额外带 `result_item`。

**样例 1 —— 带额外掉落（`result_item`），大张羊皮 → 生皮 + 羊毛**
文件：`data/tfc/recipe/scraping/large_raw_hide.json`

```json
{"type":"tfc:scraping","ingredient":{"item":"tfc:large_sheepskin_hide"},"input_texture":"tfc:item/hide/large/sheepskin","output_texture":"tfc:item/hide/large/raw","result":{"count":1,"id":"tfc:large_raw_hide"},"result_item":{"count":1,"id":"tfc:wool"}}
```

**样例 2 —— 带额外掉落，小张羊皮**
文件：`data/tfc/recipe/scraping/small_raw_hide.json`

```json
{"type":"tfc:scraping","ingredient":{"item":"tfc:small_sheepskin_hide"},"input_texture":"tfc:item/hide/small/sheepskin","output_texture":"tfc:item/hide/small/raw","result":{"count":1,"id":"tfc:small_raw_hide"},"result_item":{"count":1,"id":"tfc:wool"}}
```

**样例 3 —— 无额外掉落的皮革流程**
文件：`data/tfc/recipe/scraping/medium_scraped_hide.json`

```json
{"type":"tfc:scraping","ingredient":{"item":"tfc:medium_soaked_hide"},"input_texture":"tfc:item/hide/medium/soaked","output_texture":"tfc:item/hide/medium/scraped","result":{"count":1,"id":"tfc:medium_scraped_hide"}}
```

**样例 4 —— 非皮革用途：纸（贴图指向方块贴图而非物品贴图）**
文件：`data/tfc/recipe/scraping/paper.json`

```json
{"type":"tfc:scraping","ingredient":{"item":"tfc:unrefined_paper"},"input_texture":"tfc:block/unrefined_paper","output_texture":"tfc:block/paper","result":{"count":1,"id":"minecraft:paper"}}
```

> **重要观察**：三个皮革文件（`*_raw_hide.json`）的 `result` 都是"未加工的 `*_raw_hide`"，
> 而 `*_scraped_hide.json` 的 `result` 是 `*_scraped_hide`。即同一 `tfc:scraping` 类型被用于**两段**流程：
> （a）`*_sheepskin_hide` → `*_raw_hide`（附带羊毛掉落）；（b）`*_soaked_hide` → `*_scraped_hide`。

完整 7 个文件清单（相对 `data/tfc/recipe/scraping/`）：
`large_raw_hide.json`、`large_scraped_hide.json`、`medium_raw_hide.json`、`medium_scraped_hide.json`、`paper.json`、`small_raw_hide.json`、`small_scraped_hide.json`。

##### R-14.5 游戏内触发条件（重点：不是"刮刀物品"，是**刀类工具**）

刮制分两步：先把物品**放到刮制方块上**，再用刀反复点击。

**第 1 步 —— 用待刮物品右键"刮制表面"方块，生成 `tfc:scraping` 方块**

`net\dries007\tfc\util\InteractionManager.java` 第 253-273 行：

```java
InteractionManager.registerBlock(KeyedIngredient.ofMatchingAnyRecipeInput(TFCRecipeTypes.SCRAPING, ScrapingRecipe.CACHE, ItemRecipe::getIngredient), (ItemStack stack, UseOnContext context) -> {
    Level level = context.getLevel();
    ScrapingRecipe recipe = ScrapingRecipe.getRecipe(stack);      // ← 第 255 行
    if (recipe != null) {
        BlockPos pos = context.getClickedPos();
        BlockPos abovePos = pos.above();
        Player player = context.getPlayer();
        if (player != null && context.getClickedFace() == Direction.UP
            && Helpers.isBlock(level.getBlockState(pos), TFCTags.Blocks.SCRAPING_SURFACE)
            && level.getBlockState(abovePos).isAir()) {
            BlockState state = TFCBlocks.SCRAPING.get().defaultBlockState();
            level.setBlockAndUpdate(abovePos, state);
            ...
                ItemStack insertStack = stack.split(1);
                ... entity.getInventory() ... insertItem(0, insertStack, false) ...
                entity.updateDisplayCache();                       // ← 第 266 行
```

条件：点击面为 `Direction.UP`、被点击方块属于 `TFCTags.Blocks.SCRAPING_SURFACE`、上方为空。

**第 2 步 —— 手持刀反复右键刮制方块**

`net\dries007\tfc\common\blocks\devices\ScrapingBlock.java` 第 99-117 行：

```java
BlockEntity blockEntity = level.getBlockEntity(pos);
if (blockEntity instanceof ScrapingBlockEntity) {
    ScrapingBlockEntity scraping = (ScrapingBlockEntity) blockEntity;
    Vec3 point = ScrapingBlock.calculatePoint(...);
    if (state.getValue(WAXED)) {
        ...  // 打蜡状态下用染料上色，不再刮制
    } else if (Helpers.isItem(stack.getItem(), TFCTags.Items.TOOLS_KNIFE)) {   // ← 第 112 行：刀类工具
        scraping.onClicked((float) point.x, (float) point.z);                  // ← 第 113 行
        Helpers.damageItem(stack, player, hand);                               // 消耗刀耐久
        ScrapingBlock.doParticles(level, pos, scraping, point);
        return ItemInteractionResult.sidedSuccess(level.isClientSide);
    }
}
```

**触发工具是 `TFCTags.Items.TOOLS_KNIFE`（刀），不是名为"刮刀"的独立物品。**

**第 3 步 —— 刮满 16 格后结算**

`net\dries007\tfc\common\blockentities\ScrapingBlockEntity.java`：

| 行号 | 代码 | 作用 |
| --- | --- | --- |
| 57-60 | `onClicked(float hitX, float hitZ)`：`positions \|= 1 << (xPos + zPos*4)` | 按 4×4=16 个格位记录已刮位置 |
| 49-51 | `isComplete()`：`positions == -1` | 16 格全刮完 |
| 65-71 | `if (isComplete() && (recipe = ScrapingRecipe.getRecipe(currentItem = inventory.getStackInSlot(0))) != null) { ItemStack extraDrop = recipe.getExtraDrop().getSingleStack(currentItem); if (!extraDrop.isEmpty()) Helpers.spawnItem(...); inventory.setStackInSlot(0, recipe.assemble(currentItem)); }` | **`getExtraDrop()` 抛落地、`assemble()` 替换槽内主产物** |
| 100-102 | `isItemValid(int slot, ItemStack stack)`：`return ScrapingRecipe.getRecipe(stack) != null;` | 槽位白名单 = 有 scraping 配方的物品 |
| 142-149 | `updateDisplayCache()`：`recipe.getInputTexture()` / `recipe.getOutputTexture()` | 贴图切换；注意仅在 `!isComplete()` 时刷新 |
| 104-130 | `loadAdditional` / `saveAdditional` 存 `positions`、`inputTexture`、`outputTexture`、`color1`、`color2` | 持久化 |

**input 容器**：`ScrapingBlockEntity` 继承 `InventoryBlockEntity<ItemStackHandler>`，`defaultInventory(1)` → **仅 1 个槽（槽 0）**，
既作输入又作输出（`setStackInSlot(0, recipe.assemble(currentItem))`）。

展示层：`net\dries007\tfc\compat\jei\category\ScrapingRecipeCategory.java`（第 38-39 行用 `getExtraDrop()` 收拢产物显示）、
`net\dries007\tfc\compat\emi\EmiIntegration.java`（第 263-264 行同样读 `getExtraDrop().getEmptyStack()`）、
`net\dries007\tfc\compat\patchouli\component\ScrapingComponent.java`。

---

### [R-15] tfc:knapping —— 打制（石器 / 陶器 / 皮革 / 山羊角）

##### R-15.1 基本信息

| 项 | 值 |
| --- | --- |
| type id | `tfc:knapping` |
| 实现类 | `net.dries007.tfc.common.recipes.KnappingRecipe` |
| 源码路径 | `moddev\src-ref\TFC-decompiled\net\dries007\tfc\common\recipes\KnappingRecipe.java` |
| 实现接口 | `INoopInputRecipe`、`IRecipePredicate<KnappingContainer>` |
| 配方类型 | `TFCRecipeTypes.KNAPPING`（`TFCRecipeTypes.java:51`） |
| 序列化器 | `TFCRecipeSerializers.KNAPPING`（`TFCRecipeSerializers.java:67`） |
| JSON 目录 | `data/tfc/recipe/knapping/`（含根目录、`ceramic/`、`stone/<head>/` 子目录） |
| 真实文件数 | 101 |
| **无 `CACHE`** | 与 R-12/R-13/R-14 不同：`KnappingRecipe` **没有** `IndirectHashCollection` 索引，靠 `RecipeHelpers.getHolder(level, type, input)` 线性遍历全部配方（见 R-15.6） |

##### R-15.2 CODEC 逐字段考证

`KnappingRecipe.java` 第 50 行：

```java
public static final MapCodec<KnappingRecipe> CODEC = RecordCodecBuilder.mapCodec(i -> i.group(
    KnappingType.MANAGER.byIdReferenceCodec().fieldOf("knapping_type").forGetter(c -> c.knappingType),
    KnappingPattern.CODEC.forGetter(c -> c.pattern),                                  // ← 注意：没有 fieldOf 包装！
    Ingredient.CODEC.optionalFieldOf("ingredient").forGetter(c -> c.ingredient),
    ItemStack.CODEC.fieldOf("result").forGetter(c -> c.result)
).apply(i, KnappingRecipe::new));
```

构造器（第 62-67 行）：
`KnappingRecipe(DataManager.Reference<KnappingType> knappingType, KnappingPattern pattern, Optional<Ingredient> ingredient, ItemStack result)`。

**两个必须讲清的结构性要点：**

**(1) `knapping_type` 是"数据管理器引用"，不是普通字符串**

`KnappingType.MANAGER.byIdReferenceCodec()` 解出的是 `DataManager.Reference<KnappingType>`（第 52 行 Java 字段类型），
运行时通过 `this.knappingType.get()` 拿到已加载的 `KnappingType` 对象（第 71 行 `input.getKnappingType() == this.knappingType.get()`）。
JSON 侧写法就是 `"knapping_type": "tfc:rock"` 这样的**资源位置字符串**。
若引用的 id 不存在 → 引用无法解析 → 配方加载失败。

`KnappingType` 数据类源码：`moddev\src-ref\TFC-decompiled\net\dries007\tfc\util\data\KnappingType.java`
第 43 行定义、第 45 行 CODEC、第 47 行 `MANAGER`：

```java
public record KnappingType(SizedIngredient inputItem, int amountToConsume, Holder<SoundEvent> clickSound,
                           boolean consumeAfterComplete, boolean hasOffTexture, boolean spawnsParticles, ItemStack icon) {
    public static final Codec<KnappingType> CODEC = RecordCodecBuilder.create(i -> i.group(
        SizedIngredient.FLAT_CODEC.fieldOf("input").forGetter(c -> c.inputItem),
        Codec.INT.optionalFieldOf("amount_to_consume").forGetter(c -> c.amountToConsume == c.inputItem.count() ? Optional.empty() : Optional.of(c.amountToConsume)),
        SoundEvent.CODEC.fieldOf("click_sound").forGetter(c -> c.clickSound),
        Codec.BOOL.fieldOf("consume_after_complete").forGetter(c -> c.consumeAfterComplete),
        Codec.BOOL.fieldOf("has_off_texture").forGetter(c -> c.hasOffTexture),
        Codec.BOOL.fieldOf("spawns_particles").forGetter(c -> c.spawnsParticles),
        ItemStack.CODEC.fieldOf("icon").forGetter(c -> c.icon)
    ).apply(i, KnappingType::new));
    public static final DataManager<KnappingType> MANAGER = new DataManager<>(Helpers.identifier("knapping_type"), CODEC, STREAM_CODEC);
```

→ 数据包路径 `data/tfc/tfc/knapping_type/`。

**(2) `pattern` 与 `default_on` 平铺到 JSON 顶层**

`KnappingPattern.CODEC.forGetter(c -> c.pattern)` 直接把一个 `MapCodec<KnappingPattern>` 接入 group，
因此 `KnappingPattern` 内部的字段名**成为 `tfc:knapping` 配方 JSON 的顶层字段**，而不是嵌套在 `"pattern": {...}` 里。
这就是为什么顶层同时出现 `pattern`（字符串数组）与 `default_on`（布尔）。

`KnappingPattern` 源码：`moddev\src-ref\TFC-decompiled\net\dries007\tfc\util\data\KnappingPattern.java`
第 33 行：

```java
public static final MapCodec<KnappingPattern> CODEC = RecordCodecBuilder.mapCodec(i -> i.group(
    Codec.STRING.listOf(1, 5).fieldOf("pattern").forGetter(c -> c.pattern),
    Codec.BOOL.optionalFieldOf("default_on").forGetter(c -> c.defaultOn)
).apply(i, Prototype::new)).flatXmap(KnappingPattern::readPattern, KnappingPattern::writePattern);
```

##### R-15.3 字段表（注意 `pattern` / `default_on` 来自 `KnappingPattern`）

| 字段名 | 类型 | 必需/可选 | 默认值 | 语义 | 来源 |
| --- | --- | --- | --- | --- | --- |
| `knapping_type` | `DataManager.Reference<KnappingType>`（JSON 为资源位置字符串） | **必需** | 无 | 打制类别。必须是 `data/tfc/tfc/knapping_type/` 下已存在的 id。运行时不匹配则配方不命中 | `KnappingRecipe` 第 52 行字段 / CODEC 第 50 行 |
| `pattern` | `List<String>`，长度 **1..5**（`Codec.STRING.listOf(1, 5)`） | **必需** | 无 | 打制图案：逐行字符串。行内**非空格字符 = 需要敲掉的格**，空格 = 保留。字符本身不限（数据中统一用 `#`）；判定只比较"是否空格"（`KnappingPattern.java:63` `pattern.set(r*width+c, row.charAt(c) != ' ')`） | `KnappingPattern.CODEC`，平铺进本类 JSON |
| `default_on` | `boolean`（`Optional<Boolean>`） | **条件必需** | 无（`Optional` 空） | 图案**不是 5×5** 时**必须**显式给出，否则报错 `default_on is required if the pattern is not 5x5`（`KnappingPattern.java:53-55`）。语义：图案外圈格子的期望状态（`false` = 图案外的格子必须保持未敲掉） | `KnappingPattern.CODEC`，平铺进本类 JSON |
| `ingredient` | `Optional<Ingredient>` | 可选 | `Optional.empty()`（不限制） | 额外的物品限制。缺省时只要 `knapping_type` 与图案匹配即可（`matchesItem` 第 74-76 行：`ingredient.isEmpty() \|\| ingredient.get().test(stack)`） | `KnappingRecipe` 第 54 行字段 |
| `result` | **`ItemStack`（裸物品栈，不是 `ItemStackProvider`！）** | **必需** | 无 | 打制成品。`assemble()` = `result.copy()`（第 78-80 行）——**无 modifier 机制** | `KnappingRecipe` 第 55 行字段 |

##### R-15.4 `pattern` 的严格约束（逐条对应源码）

`KnappingPattern.readPattern(Prototype)`（`KnappingPattern.java` 第 44-67 行）：

1. **行数 1..5**：`int height = proto.pattern.size(); if (height == 0 || height > 5) return DataResult.error("Invalid pattern: must have [1, 5] rows")`（第 45-48 行）。
2. **每行宽度 1..5，且以第一行宽度为准**：`int width = proto.pattern.getFirst().length(); if (width == 0 || width > 5) return DataResult.error("Invalid pattern: must have [1, 5] columns")`（第 49-52 行）。
3. **各行列宽必须一致**：`if (r > 0 && width != row.length()) return DataResult.error("Invalid pattern: each row must be the same width")`（第 59-61 行）。
4. **非 5×5 必须给 `default_on`**：`if ((height != 5 || width != 5) && proto.defaultOn.isEmpty()) return DataResult.error("default_on is required if the pattern is not 5x5")`（第 53-55 行）。
5. **`Codec.STRING.listOf(1, 5)` 已限制数组元素个数在 1..5**；单行的字符长度由 `data` 位域上限约束 —— `set(int index, boolean)` 第 117 行 `assert (index >= 0 && index < 32)`，即总格数 ≤ 32（5×5=25 满足）。

**所以：不是"必须恰好 5 行每行 5 字符"**。实测数据明确存在非 5×5 图案：
- 3 行 × 5 列：`knapping/leather_helmet.json`（`["#####","#   #","#   #"]`, `default_on:false`）
- 5 行 × 4 列：`knapping/ceramic/unfired_fire_ingot_mold.json`（`["####","#  #","#  #","#  #","####"]`, `default_on:true`）
- 2 行 × 5 列：`knapping/ceramic/unfired_channel_2.json`（`["#   #"," ### "]`, `default_on:true`）
- 2 行 × 2 列：`knapping/obsidian_knife_head.json`（`["# ","##","##","##","##"]` 是 5 行 × 2 列）

**行内空格与行外空格的语义差异：**
- **行内空格（字符串内部）** = 该格**不敲**（保留）→ `row.charAt(c) == ' '` → `set(..., false)`（第 63 行）。
- **行外空格（数组不足 5 行 / 或行不足 5 字符）** = 由 `default_on` 决定：`matches` 时越界格用 `other.defaultOn` 比对
  （`KnappingPattern.java:156-159`：`if (x < startX || y < startY || x-startX >= other.width || y-startY >= other.height) { if (this.get(patternIdx) == other.defaultOn) continue; return false; }`）。
  即 `default_on:false` 表示"图案范围外的格子必须**没有**被敲过"（保持原始状态）。

**写回行为**（`writePattern` 第 69-79 行）：序列化回 JSON 时，5×5 图案**省略** `default_on`（`Optional.empty()`），
非 5×5 则**写出** `default_on`。读取时 5×5 图案若显式写了 `default_on` 也会被接受（校验只在非 5×5 时强制）。

**匹配含镜像与偏移**（`matches` 第 142-166 行）：`KnappingPattern.matches(other)` 会在自身图案内滑动 `dx/dy` 并同时尝试**镜像**
（第 145 行 `!this.matches(other, dx, dy, false) && !this.matches(other, dx, dy, true)`），即玩家敲出的图案允许平移与左右镜像匹配。

##### R-15.5 `knapping_type` 真实清单（`data/tfc/tfc/knapping_type/`，共 5 个文件）

> 任务书提到"如 `tfc:rock`、`tfc:leather`、`tfc:clay`、`tfc:fire_clay`、`tfc:goat_horn` 等"，实际 jar 内**恰好 5 个**文件，无第 6 个。
> 目录 `D:\111\最强服务器\.minecraft\versions\Essential TerraFirmaCraft (TFC)\moddev\jar-extract\data\tfc\tfc\knapping_type\`
> 仅含 `clay.json`、`fire_clay.json`、`goat_horn.json`、`leather.json`、`rock.json`。

| id | 文件 | 内容（原文） |
| --- | --- | --- |
| `tfc:clay` | `clay.json` | `{"click_sound":"tfc:item.knapping.clay","consume_after_complete":true,"has_off_texture":true,"icon":{"count":1,"id":"minecraft:clay_ball"},"input":{"count":5,"tag":"tfc:clay_knapping"},"spawns_particles":false}` |
| `tfc:fire_clay` | `fire_clay.json` | `{"click_sound":"tfc:item.knapping.clay","consume_after_complete":true,"has_off_texture":true,"icon":{"count":1,"id":"tfc:fire_clay"},"input":{"count":5,"tag":"tfc:fire_clay_knapping"},"spawns_particles":false}` |
| `tfc:goat_horn` | `goat_horn.json` | `{"click_sound":"tfc:item.knapping.stone","consume_after_complete":false,"has_off_texture":true,"icon":{"count":1,"id":"tfc:goat_horn"},"input":{"count":1,"tag":"tfc:goat_horn_knapping"},"spawns_particles":false}` |
| `tfc:leather` | `leather.json` | `{"click_sound":"tfc:item.knapping.leather","consume_after_complete":false,"has_off_texture":false,"icon":{"count":1,"id":"minecraft:leather"},"input":{"count":1,"tag":"tfc:leather_knapping"},"spawns_particles":false}` |
| `tfc:rock` | `rock.json` | `{"amount_to_consume":1,"click_sound":"tfc:item.knapping.stone","consume_after_complete":false,"has_off_texture":false,"icon":{"count":1,"id":"tfc:rock/loose/granite"},"input":{"count":2,"tag":"tfc:rock_knapping"},"spawns_particles":true}` |

`KnappingType` 字段与语义（依据 `KnappingType.java:45` CODEC）：

| 字段 | 类型 | 必需/可选 | 默认值 | 语义 |
| --- | --- | --- | --- | --- |
| `input` | `SizedIngredient`（`FLAT_CODEC`，即 `{"count":N,"tag"/"item":...}`） | **必需** | 无 | 该类别允许的输入物品与"一次配方所需数量" |
| `amount_to_consume` | `int` | 可选 | `input.count()`（第 49-51 行构造器） | 实际消耗数量。仅当与 `input.count()` 不同时才会写出（CODEC 用 `Optional.empty()` 表达"同 input.count()"） |
| `click_sound` | `SoundEvent` | **必需** | 无 | 每次敲击音效 |
| `consume_after_complete` | `boolean` | **必需** | 无 | `true` = 打制过程中（首次敲击时）就消耗；`false` = 打制完成取出产物时才消耗 |
| `has_off_texture` | `boolean` | **必需** | 无 | 是否使用"关闭"状态的贴图 |
| `spawns_particles` | `boolean` | **必需** | 无 | 是否产生粒子 |
| `icon` | `ItemStack` | **必需** | 无 | JEI/EMI 类别图标 |

`rock` 是本目录中唯一带 `amount_to_consume` 的类别（`input.count()=2` 但只消耗 `1`）。

##### R-15.6 真实 JSON 样例

字段组合实测（101 个文件）：`knapping_type,pattern,result` 36 个；`+ingredient` 35 个；`+default_on,ingredient` 20 个；`+default_on` 10 个。

**样例 1 —— 标准 5×5 石器（带 `ingredient` 标签，无 `default_on`）**
文件：`data/tfc/recipe/knapping/stone/axe_head/igneous_extrusive.json`

```json
{"type":"tfc:knapping","ingredient":{"tag":"tfc:stones/loose/igneous_extrusive"},"knapping_type":"tfc:rock","pattern":[" #   ","#### ","#####","#### "," #   "],"result":{"count":1,"id":"tfc:stone/axe_head/igneous_extrusive"}}
```

**样例 2 —— 无 `ingredient`（仅靠 `knapping_type` 限制输入）**
文件：`data/tfc/recipe/knapping/saddle.json`

```json
{"type":"tfc:knapping","knapping_type":"tfc:leather","pattern":["  #  ","#####","#####","#####","  #  "],"result":{"count":1,"id":"minecraft:saddle"}}
```

**样例 3 —— `tfc:clay` 陶器，图案含内部空格（5×5，故无 `default_on`）**
文件：`data/tfc/recipe/knapping/ceramic/unfired_bowl.json`

```json
{"type":"tfc:knapping","knapping_type":"tfc:clay","pattern":["#   #"," ### ","     ","#   #"," ### "],"result":{"count":4,"id":"tfc:ceramic/unfired_bowl"}}
```

**样例 4 —— 非 5×5 图案，必须带 `default_on`（3 行 × 5 列）**
文件：`data/tfc/recipe/knapping/leather_helmet.json`

```json
{"type":"tfc:knapping","default_on":false,"knapping_type":"tfc:leather","pattern":["#####","#   #","#   #"],"result":{"count":1,"id":"minecraft:leather_helmet"}}
```

**样例 5 —— 非 5×5 图案，`default_on:true`（5 行 × 4 列）**
文件：`data/tfc/recipe/knapping/ceramic/unfired_fire_ingot_mold.json`

```json
{"type":"tfc:knapping","default_on":true,"knapping_type":"tfc:fire_clay","pattern":["####","#  #","#  #","#  #","####"],"result":{"count":2,"id":"tfc:ceramic/unfired_fire_ingot_mold"}}
```

**样例 6 —— 非 5×5，`default_on:false` + 物品 `ingredient`（黑曜石刀头，2 列）**
文件：`data/tfc/recipe/knapping/obsidian_knife_head.json`

```json
{"type":"tfc:knapping","default_on":false,"ingredient":{"item":"tfc:groundcover/obsidian_shard"},"knapping_type":"tfc:rock","pattern":["# ","##","##","##","##"],"result":{"count":1,"id":"tfc:obsidian_knife_head"}}
```

**样例 7 —— `result` 用带 `components` 的 ItemStack（山羊角，`tfc:goat_horn` 类别）**
文件：`data/tfc/recipe/knapping/call_goat_horn_goat_horn.json`

```json
{"type":"tfc:knapping","knapping_type":"tfc:goat_horn","pattern":["#####","#   #","# ###","## ##","#####"],"result":{"components":{"minecraft:instrument":"minecraft:call_goat_horn"},"count":1,"id":"minecraft:goat_horn"}}
```

##### R-15.7 游戏内触发条件

`KnappingRecipe.get(Level, KnappingContainer)`（第 57-60 行）：

```java
@Nullable
public static KnappingRecipe get(Level level, KnappingContainer input) {
    return RecipeHelpers.unbox(RecipeHelpers.getHolder(level, TFCRecipeTypes.KNAPPING, input));
}
```

匹配逻辑（第 69-72 行）：

```java
@Override
public boolean matches(KnappingContainer input) {
    return input.getKnappingType() == this.knappingType.get()
        && input.getPattern().matches(this.getPattern())
        && this.matchesItem(input.getOriginalStack());
}
```

三个条件：**类别一致（引用同一对象）** + **图案匹配（含平移/镜像）** + **原始物品通过 `ingredient`**。

**触发链：**

| # | 相对源码路径 | 行号 | 作用 |
| --- | --- | --- | --- |
| 1 | `net\dries007\tfc\util\InteractionManager.java` | 278 | 构造 `KeyedIngredient knapping`：`KeyedIngredient.of(stack -> KnappingType.get(stack) != null, () -> KnappingType.MANAGER.getValues().stream().flatMap(type -> RecipeHelpers.stream(type.inputItem().ingredient())).toList())` |
| 2 | 同上 | 279-291 | `InteractionManager.register(knapping, Target.AIR, ...)`：**对着空气使用**（`context.getClickedPos().equals(BlockPos.ZERO)`）时，`KnappingType type = KnappingType.get(player.getMainHandItem())`，非空且为服务端玩家则用 `ItemStackContainerProvider` 打开 `KnappingContainer.create(stack1, type, hand, slot, playerInventory, windowId)` 对应的界面，标题 `tfc.screen.knapping`，并写入 `KnappingType.MANAGER.getIdOrThrow(type)` |
| 3 | `net\dries007\tfc\common\container\KnappingContainer.java` | 74-89 | `onButtonPress(int buttonID, CompoundTag)`：`this.pattern.set(buttonID, false)`（**按下 = 该格被敲掉**，与图案中非空格对应）；首次修改时若不创造模式且 `!consumeAfterComplete()` 则 `stack.shrink(amountToConsume())`；随后服务端 `KnappingRecipe.get(level2, this)`，命中则 `slot.set(recipe.assemble())`，否则 `ItemStack.EMPTY` |
| 4 | 同上 | 96-104 | `removed(Player)`：把产物放回玩家背包并 `consumeIngredientStackAfterComplete()` |
| 5 | 同上 | 157-168 | `resetPattern()` / `consumeIngredientStackAfterComplete()`：`consumeAfterComplete()==true`（clay/fire_clay）时在取出产物时才 `shrink` |
| 6 | 同上 | 91-94 | `stillValid`：`!getTargetStack().isEmpty() \|\| hasBeenModified && !knappingType.consumeAfterComplete()` |
| 7 | 同上 | 59-67 | 构造时 `this.pattern = new KnappingPattern()` → **默认 5×5 全 `data=1`**（`KnappingPattern.java:81-87`：`this(width, height, (1 << width*height) - 1, defaultOn)`），即初始"全部未敲" |
| 8 | 同上 | 152-155 | `addContainerSlots()`：`new CallbackSlot(this, new ItemStackHandler(1), 0, 128, 46)` → **输出槽 `SLOT_OUTPUT = 0`** |

**input 容器**：`KnappingContainer extends ItemStackContainer`，持有玩家手持的那一叠物品作为"输入"（`originalStack` 为打开界面时的快照），
界面内只有一个输出槽（槽 0）。

**客户端界面**：`net\dries007\tfc\client\screen\KnappingScreen.java`（`KnappingScreen.getLowTexture(KnappingType, ItemStack)` 被 Patchouli 组件第 78 行调用）。

展示层：`net\dries007\tfc\compat\jei\category\KnappingRecipeCategory.java`（第 60-70 行读 `getPattern().getHeight()/getWidth()/defaultIsOn()` 与 `get(xd, yd)`；
第 92 行 `SizedIngredient inputItem = recipe.getIngredient() != null ? new SizedIngredient(recipe.getIngredient(), recipe.knappingType().get().inputItem().count()) : recipe.knappingType().get().inputItem()`）、
`net\dries007\tfc\compat\emi\recipe\EmiKnappingRecipe.java`、`net\dries007\tfc\compat\patchouli\component\KnappingComponent.java`、
`net\dries007\tfc\compat\patchouli\component\RockKnappingComponent.java`。

##### R-15.8 与 KnappingType 的耦合（简述，另有专章）

- `KnappingRecipe.knappingType` 是 `DataManager.Reference<KnappingType>`，**运行时对象同一性比较**（`==`，第 71 行）；
- `KnappingType` 双向参与：
  - **正向**：决定界面输入物品与数量、音效、粒子、`consume_after_complete`、贴图；
  - **反向**：`InteractionManager` 第 278 行用所有 `KnappingType` 的 `inputItem().ingredient()` 生成"哪些物品能打开打制界面"的索引；
  - `KnappingType.get(ItemStack)`（第 53-56 行）= `RecipeHelpers.getRecipe(MANAGER.getValues(), stack)`，按 `inputItem` 匹配。
- 因此**新增 knapping 配方时必须先有对应的 `knapping_type` 数据文件**（或复用现有 5 个之一），否则 `knapping_type` 引用无法解析。

---

### [R-16] tfc:glassworking —— 玻璃加工

##### R-16.1 基本信息

| 项 | 值 |
| --- | --- |
| type id | `tfc:glassworking` |
| 实现类 | `net.dries007.tfc.common.recipes.GlassworkingRecipe` |
| 源码路径 | `moddev\src-ref\TFC-decompiled\net\dries007\tfc\common\recipes\GlassworkingRecipe.java` |
| 形式 | **`record`**：`public record GlassworkingRecipe(List<GlassOperation> operations, Ingredient batchItem, ItemStack resultItem) implements INoopInputRecipe, IRecipePredicate<ItemStack>`（第 46-47 行） |
| 配方类型 | `TFCRecipeTypes.GLASSWORKING`（`TFCRecipeTypes.java:62`） |
| 序列化器 | `TFCRecipeSerializers.GLASSWORKING`（`TFCRecipeSerializers.java:78`） |
| JSON 目录 | `data/tfc/recipe/glassworking/`（无子目录） |
| 真实文件数 | 60 |
| **无 `CACHE`** | 靠 `RecipeHelpers.getHolder(level, type, stack)` 线性遍历 |

##### R-16.2 CODEC 逐字段考证

`GlassworkingRecipe.java` 第 49 行：

```java
public static final MapCodec<GlassworkingRecipe> CODEC = RecordCodecBuilder.mapCodec(i -> i.group(
    GlassOperation.REGISTRY.byNameCodec().listOf().fieldOf("operations").forGetter(c -> c.operations),
    Ingredient.CODEC.fieldOf("batch").forGetter(c -> c.batchItem),
    ItemStack.CODEC.fieldOf("result").forGetter(c -> c.resultItem)
).apply(i, GlassworkingRecipe::new));
```

`STREAM_CODEC`（第 50 行）：`ByteBufCodecs.registry(GlassOperation.KEY).apply(ByteBufCodecs.list())` + `Ingredient.CONTENTS_STREAM_CODEC` + `ItemStack.STREAM_CODEC`。

##### R-16.3 字段表

| 字段名 | 类型 | 必需/可选 | 默认值 | 语义 |
| --- | --- | --- | --- | --- |
| `operations` | `List<GlassOperation>`（注册表名列表，可空数组） | **必需** | 无 | **操作序列**：玻璃从吹管到成品的每一步加工，顺序敏感（比较用 `List.equals`，见第 60 行）。元素为 `glass_operation` 注册表内的 id 字符串 |
| `batch` | `Ingredient` | **必需** | 无 | 玻璃原料（玻璃批次）的匹配条件。可写 `{"item":...}` 或 `{"tag":...}` |
| `result` | **`ItemStack`（裸物品栈，不是 `ItemStackProvider`）** | **必需** | 无 | 成品。`getResultItem(registries)` = `resultItem.copy()`（第 63-66 行） |

**没有 `validate(...)`，没有 `Codec.either(...)`，没有可选字段。** 实测 60 个文件字段集合**全部**为 `type,batch,operations,result`。

**长度限制的差异（重要）：**
- `GlassworkingRecipe.CODEC` 用 `listOf()` —— **无长度上限**；
- 而玻璃组件 `GlassOperations`（`net\dries007\tfc\common\component\glass\GlassOperations.java` 第 32 行）用 `listOf(0, 24)`，
  且 `LIMIT = 24`（第 30 行），`with(GlassOperation)` 第 39-41 行 `steps.size() >= 24 ? this : ...` 会**拒绝第 25 步**。
  → 配方里写超过 24 步虽能加载，但玩家永远凑不出该序列，属于"合法但不可达"。

##### R-16.4 玻璃操作的表示方式与字母表

**表示方式**：`operations` 是**注册表 id 字符串数组**，按玩家施加操作的**时间顺序**排列。
匹配逻辑（`GlassworkingRecipe.java` 第 57-61 行）：

```java
@Override
public boolean matches(ItemStack input) {
    GlassOperations data = GlassWorking.get(input);
    return this.operations.equals(data.steps()) && this.batchItem.test(data.batch());
}
```

- `GlassWorking.get(stack)`（`net\dries007\tfc\common\component\glass\GlassWorking.java` 第 40-42 行）
  = `stack.getOrDefault(TFCComponents.GLASS, GlassOperations.DEFAULT)` → 从物品组件 `tfc:glass` 读；
- `GlassWorking.apply(stack, operation)`（第 48-52 行）→ `GlassWorking.get(stack).with(operation)`，用 `Helpers.immutableAdd` 追加；
- `createNewBatch(stack, glass)`（第 54-58 行）→ `with(ItemStack batch)` 设置批次物品。
- **序列必须完全相等**（`List.equals`，逐个 `GlassOperation` 对象引用比较，因为注册表保证了单例）→ 少一步、多一步、顺序不同都不匹配。

**可用操作字母表（`data/tfc/glass_operation` 注册表全清单）**

源码：`moddev\src-ref\TFC-decompiled\net\dries007\tfc\common\component\glass\GlassOperation.java`
第 52-54 行：

```java
public static final ResourceKey<Registry<GlassOperation>> KEY = ResourceKey.createRegistryKey(Helpers.identifier("glass_operation"));
public static final Registry<GlassOperation> REGISTRY = new RegistryBuilder(KEY).sync(true).create();
public static final DeferredRegister<GlassOperation> OPERATIONS = DeferredRegister.create(KEY, "tfc");
```

| id | 定义行 | 所需工具/物品（`getItems()`） | 是否粉末（`powder`） | 最低温度（`minTemperature`） |
| --- | --- | --- | --- | --- |
| `tfc:blow` | 64 | `tfc:blowpipe_with_glass`、`tfc:ceramic_blowpipe_with_glass`（副手空手时俯视也判为 blow，见下文 `GlassOperation.get`） | 否 | `Heat.FAINT_RED.getMin()` |
| `tfc:roll` | 65 | `tfc:wool_cloth` | 否 | `Heat.FAINT_RED.getMin()` |
| `tfc:stretch` | 66 | 同上两个带玻璃的吹管 | 否 | `Heat.FAINT_RED.getMin()` |
| `tfc:pinch` | 67 | `tfc:jacks` | 否 | `Heat.FAINT_RED.getMin()` |
| `tfc:flatten` | 68 | `tfc:paddle` | 否 | `Heat.FAINT_RED.getMin()` |
| `tfc:saw` | 69 | `tfc:gem_saw` | 否 | **0.0f**（无温度要求） |
| `tfc:amethyst` | 70 | 紫水晶矿粉 | **是** | `Heat.FAINT_RED.getMin()` |
| `tfc:soda_ash` | 71 | 苏打灰 | **是** | 同上 |
| `tfc:sulfur` | 72 | 硫矿粉 | **是** | 同上 |
| `tfc:iron` | 73 | 赤铁矿/褐铁矿/磁铁矿粉（3 种） | **是** | 同上 |
| `tfc:ruby` | 74 | 红宝石矿粉 | **是** | 同上 |
| `tfc:lapis_lazuli` | 75 | 青金石矿粉 | **是** | 同上 |
| `tfc:pyrite` | 76 | 黄铁矿粉 | **是** | 同上 |
| `tfc:sapphire` | 77 | 蓝宝石矿粉 | **是** | 同上 |
| `tfc:gold` | 78 | 天然金矿粉 | **是** | 同上 |
| `tfc:graphite` | 79 | 石墨矿粉 | **是** | 同上 |
| `tfc:copper` | 80 | 天然铜/孔雀石/黝铜矿粉（3 种） | **是** | 同上 |
| `tfc:nickel` | 81 | 硅镁镍矿粉 | **是** | 同上 |
| `tfc:tin` | 82 | 锡石粉 | **是** | 同上 |
| `tfc:silver` | 83 | 天然银矿粉 | **是** | 同上 |
| `tfc:table_pour` | 84 | 两个带玻璃的吹管 | 否 | 同上 |
| `tfc:basin_pour` | 85 | 两个带玻璃的吹管 | 否 | 同上 |

共 **22** 个操作 id。`saw` 是唯一 `minTemperature = 0.0f` 的操作，因此 `hasRequiredTemperature` 恒真（`GlassOperation.java:137-139`：`HeatCapability.getTemperature(stack) > this.minTemperature`）。

**操作决策**（`GlassOperation.get(ItemStack, Player)` 第 93-104 行）：
- 副手为空 → 看玩家俯仰角：`player.getLookAngle().y < -0.95 ? STRETCH : BLOW`；
- 副手是 `IGlassworkingTool` → 返回 `tool.getOperation()`（`jacks`/`paddle`/`gem_saw`/`wool_cloth` 等）；
- 否则 `null`（不是有效操作，`GlassBlowpipeItem.use` 返回 `pass`）。
- 粉末通过 `getByPowder(ItemStack)`（第 106-108 行）查 `POWDERS` 映射（第 55-63 行，由所有 `powder=true` 的操作展开其 `items`）。

##### R-16.5 真实 JSON 样例

实测 60 个文件的 `operations` 长度分布：1 步、2 步、3 步、5 步均有；**最后一步必然是 `tfc:table_pour` 或 `tfc:basin_pour`**（全部 60 个文件无一例外）。

**样例 1 —— 单步：直接浇入玻璃盆**
文件：`data/tfc/recipe/glassworking/glass.json`

```json
{"type":"tfc:glassworking","batch":{"item":"tfc:silica_glass_batch"},"operations":["tfc:basin_pour"],"result":{"count":1,"id":"minecraft:glass"}}
```

**样例 2 —— 四步：吹 → 拉伸 → 滚圆 → 锯（放大镜）**
文件：`data/tfc/recipe/glassworking/lens.json`

```json
{"type":"tfc:glassworking","batch":{"item":"tfc:silica_glass_batch"},"operations":["tfc:blow","tfc:stretch","tfc:roll","tfc:saw"],"result":{"count":1,"id":"tfc:lens"}}
```

**样例 3 —— `batch` 用标签 + 四步（空罐，二级玻璃批次）**
文件：`data/tfc/recipe/glassworking/empty_jar.json`

```json
{"type":"tfc:glassworking","batch":{"tag":"tfc:glass_batches_tier_2"},"operations":["tfc:blow","tfc:pinch","tfc:roll","tfc:saw"],"result":{"count":1,"id":"tfc:empty_jar"}}
```

**样例 4 —— 三步：粉末染色 + 浇注台（青色浇注玻璃）**
文件：`data/tfc/recipe/glassworking/cyan_poured_glass_2.json`

```json
{"type":"tfc:glassworking","batch":{"tag":"tfc:glass_batches_tier_3"},"operations":["tfc:sapphire","tfc:copper","tfc:table_pour"],"result":{"count":1,"id":"tfc:cyan_poured_glass"}}
```

**样例 5 —— 两步：粉末染色 + 浇入玻璃盆（黑色染色玻璃）**
文件：`data/tfc/recipe/glassworking/black_stained_glass.json`

```json
{"type":"tfc:glassworking","batch":{"tag":"tfc:glass_batches"},"operations":["tfc:graphite","tfc:basin_pour"],"result":{"count":1,"id":"minecraft:black_stained_glass"}}
```

本目录中出现的完整操作序列种类（实测去重，共 53 种不同序列），其中长度最长为 5 步：
`["tfc:blow","tfc:pinch","tfc:flatten","tfc:blow","tfc:saw"]`。

##### R-16.6 游戏内触发条件

`GlassworkingRecipe.get(Level, ItemStack)`（第 52-55 行）：

```java
@Nullable
public static GlassworkingRecipe get(Level level, ItemStack stack) {
    return RecipeHelpers.unbox(RecipeHelpers.getHolder(level, TFCRecipeTypes.GLASSWORKING, stack));
}
```

**触发主体是物品 `GlassBlowpipeItem`（吹管）**，源码 `moddev\src-ref\TFC-decompiled\net\dries007\tfc\common\items\GlassBlowpipeItem.java`：

| # | 行号 | 方法 | 行为 |
| --- | --- | --- | --- |
| 1 | 85-118 | `useOn(UseOnContext)` | **浇入玻璃盆**：若 `GlassBasinBlock.isValid(level, center)`，则 `copy = item.copy()` → `GlassWorking.apply(copy, GlassOperation.BASIN_POUR.value())` → `GlassworkingRecipe.get(level, copy)`；命中且温度达标（`BASIN_POUR.hasRequiredTemperature(copy)`）则消耗吹管、在该处放置 `TFCBlocks.GLASS_BASIN`、`glass.setGlassItem(recipe.getResultItem(level.registryAccess()))`。温度不足时提示 `tfc.tooltip.glass.not_hot_enough` |
| 2 | 119-142 | 同上 | **浇到浇注台**：`face == Direction.UP && Helpers.isBlock(state, TFCTags.Blocks.GLASS_POURING_TABLE) && level.getBlockState(pos.above()).isAir()`，`GlassWorking.apply(copy, TABLE_POUR.value())` → `get(level, copy)`，成功则放置 `TFCBlocks.HOT_POURED_GLASS` 并写入 `HotPouredGlassBlockEntity` |
| 3 | 152-166 | `use(Level, Player, InteractionHand)` | **开始"使用"吹管**：`op = GlassOperation.get(getOtherHandItem(player, hand), player)`；`op != null` 且温度足够则 `player.startUsingItem(hand)`，否则 `fail` |
| 4 | 168-174 | `onUseTick(...)` | 每 30 tick 播放一次操作音效 |
| 5 | 176-199 | `finishUsingItem(...)` | **完成一次操作**：`GlassWorking.apply(stack, op)` → `GlassworkingRecipe.get(level, stack)`；命中则消耗/损坏吹管并把 `recipe.getResultItem(level.registryAccess()).copy()` 给玩家，播放 `ITEM_BREAK` 或 `ENCHANTMENT_TABLE_USE`，并给 4 种吹管加 20 tick 冷却 |
| 6 | 146-150 | `consumeBlowpipe(...)` | 按 `breakChance` 决定吹管碎裂或变回 `BlowpipeItem.transform(item.getItem())` |

**blocks / blockentities 侧（接收端）**：

| # | 相对源码路径 | 行号 | 作用 |
| --- | --- | --- | --- |
| 7 | `net\dries007\tfc\common\blocks\GlassBasinBlock.java` | 40、45、61-68 | `GlassBasinBlock.isValid(level, pos)` 校验、按层高动态碰撞形状、方块实体 tick |
| 8 | `net\dries007\tfc\common\blockentities\GlassBasinBlockEntity.java` | 61、66、76-80 | 玻璃盆方块实体（`setGlassItem`、`getAnimationTicks`） |
| 9 | `net\dries007\tfc\common\blocks\TFCBlocks.java` | 334 | `GLASS_BASIN` 注册（`.blockEntity(TFCBlockEntities.GLASS_BASIN).dynamicShape().ticks(GlassBasinBlockEntity::ticks)`） |
| 10 | `net\dries007\tfc\common\blockentities\TFCBlockEntities.java` | 111 | `GLASS_BASIN` 方块实体注册 |
| 11 | `net\dries007\tfc\client\render\blockentity\GlassBasinBlockEntityRenderer.java` | 20-24 | 客户端渲染 |
| 12 | `net\dries007\tfc\client\GlassblowingOverlays.java` | 73 | 手持吹管时对玻璃盆/浇注台的叠加提示 |

**`batch`（玻璃批次）从哪来**：`GlassWorking.createNewBatch(stack, glass)` / `createWithBatch(stack, glass)`
（`GlassWorking.java` 第 54-63 行）写入 `TFCComponents.GLASS` 的 `batch` 字段。吹管在装料时（见 `GlassBlowpipeItem` 之外的装料路径）
用 `HeatingRecipe` 把 `*_glass_batch` 物品熔成玻璃并把批次物品记入组件 —— 这也是 `tfc:heating` 与 `tfc:glassworking` 的衔接点：
`GlassWorking.addTooltipInfo`（第 32-36 行）会用 `HeatingRecipe.getRecipe(stack)` 提示过热危险。

展示层：`net\dries007\tfc\compat\jei\category\GlassworkingRecipeCategory.java`（第 62-83 行）、
`net\dries007\tfc\compat\emi\recipe\EmiGlassworkingRecipe.java`、`net\dries007\tfc\compat\patchouli\component\GlassworkingComponent.java`（第 43 行遍历 `recipe.operations()`）。

---

### [R-17] tfc:sewing —— 缝纫

##### R-17.1 基本信息

| 项 | 值 |
| --- | --- |
| type id | `tfc:sewing` |
| 实现类 | `net.dries007.tfc.common.recipes.SewingRecipe` |
| 源码路径 | `moddev\src-ref\TFC-decompiled\net\dries007\tfc\common\recipes\SewingRecipe.java` |
| 实现接口 | **`ISimpleRecipe<SewingTableContainer.Input>`**（不是 `ItemRecipe`、不是 `INoopInputRecipe`） |
| 配方类型 | `TFCRecipeTypes.SEWING`（`TFCRecipeTypes.java:63`） |
| 序列化器 | `TFCRecipeSerializers.SEWING`（`TFCRecipeSerializers.java:79`） |
| JSON 目录 | `data/tfc/recipe/sewing/`（无子目录） |
| 真实文件数 | 25 |
| 常量 | `MAX_STITCHES = 45`（第 49 行）、`INVALID_SQUARES = Pattern.compile("[^ BW]+")`（第 50 行） |

##### R-17.2 CODEC 逐字段考证

`SewingRecipe.java` 第 51-68 行（`stitches` 部分完整照录）：

```java
public static final MapCodec<SewingRecipe> CODEC = RecordCodecBuilder.mapCodec(i -> i.group(
    SewingRecipe.flatCodec(9, 5).comapFlatMap(SewingRecipe::stitchesToBitset, bitset -> {
        StringBuilder builder = new StringBuilder();
        for (int j = 0; j < 45; ++j) {
            builder.append(SewingRecipe.bitFind(bitset, j) ? '#' : ' ');
        }
        return builder.toString();
    }).fieldOf("stitches").forGetter(c -> c.stitches),

    SewingRecipe.flatCodec(8, 4).validate(squares -> {
        Matcher match = INVALID_SQUARES.matcher(squares);
        if (match.find()) {
            List chars = match.results().map(MatchResult::group).mapMulti((s, c) -> { ... }).distinct().toList();
            return DataResult.error(() -> "Invalid char(s) for cloth squares: " + chars);
        }
        return DataResult.success(squares);
    }).fieldOf("squares").forGetter(c -> c.squares),

    ItemStack.CODEC.fieldOf("result").forGetter(c -> c.result)
).apply(i, SewingRecipe::new));
```

`flatCodec` 辅助方法（第 74-76 行）：

```java
private static Codec<String> flatCodec(int width, int height) {
    return Codec.string(width, width).listOf(height, height)
        .xmap(list -> String.join("", list), text -> Splitter.fixedLength(width).splitToList(text));
}
```

即：**JSON 层是"定长字符串数组"，内部层是"拼接后的单字符串"**：
- `flatCodec(9, 5)` → JSON 是 **5 个长度恰为 9 的字符串**，内部拼成 45 字符；
- `flatCodec(8, 4)` → JSON 是 **4 个长度恰为 8 的字符串**，内部拼成 32 字符。

`stitchesToBitset`（第 82-91 行）：

```java
private static DataResult<Long> stitchesToBitset(String text) {
    if (text.length() != 45) return DataResult.error(() -> "Must be exactly 45 stitches");
    long bitset = 0L;
    for (int j = 0; j < 45; ++j) {
        bitset |= text.charAt(j) != ' ' ? 1L << j : 0L;
    }
    return DataResult.success(bitset);
}
```

→ **任何非空格字符都表示"有针脚"**（数据中统一用 `#`），空格表示"无针脚"。

`STREAM_CODEC`（第 69 行）用 `ByteBufCodecs.VAR_LONG`（bitset）+ `ByteBufCodecs.STRING_UTF8`（squares 拼接串）+ `ItemStack.STREAM_CODEC`。

##### R-17.3 字段表

| 字段名 | 类型 | 必需/可选 | 默认值 | 语义 |
| --- | --- | --- | --- | --- |
| `stitches` | `List<String>`：**恰好 5 个元素，每个恰好 9 字符** | **必需** | 无 | 针脚图。45 个字符按行优先（先第 0 行 9 个，再第 1 行…）展开为 45 位 bitset。**非空格 = 有针脚**（习惯写 `#`）。`Codec.string(9,9).listOf(5,5)` 强制元素数与长度；拼接后再校验总长 45（`stitchesToBitset`） |
| `squares` | `List<String>`：**恰好 4 个元素，每个恰好 8 字符** | **必需** | 无 | 布料材质图（32 格）。字符**仅允许** `' '`、`'B'`、`'W'`（正则 `[^ BW]+` 命中即报错 `Invalid char(s) for cloth squares: [...]`）。映射见 `getSquare(int)`（第 107-114 行）：`' ' → -1`（空）、`'B' → 0`（burlap 深色布，`SewingTableContainer.BURLAP_ID = 0`）、`'W' → 1`（wool 浅色布，`WOOL_ID = 1`） |
| `result` | **`ItemStack`（裸物品栈，不是 `ItemStackProvider`）** | **必需** | 无 | 成品。`assemble(input, registries)` = `result.copy()`（第 120-122 行）、`getResultItem(registries)` = `result.copy()`（第 124-127 行） |

**没有 `optionalFieldOf`、没有 `Codec.either`。** 有两处校验：
1. `flatCodec` 自带的 `listOf(height, height)` + `Codec.string(width, width)` —— **数组长度与每行字符数在解码期强制**；
2. `squares` 上的 `.validate(...)` —— 字符集校验，报错文本为 `"Invalid char(s) for cloth squares: "`；
3. `stitches` 上的 `.comapFlatMap(SewingRecipe::stitchesToBitset, ...)` —— 45 字符长度校验，报错文本为 `"Must be exactly 45 stitches"`。

实测 25 个文件字段集合**全部**为 `type,result,squares,stitches`，无例外。

##### R-17.4 真实 JSON 样例

**样例 1 —— 地球仪旗帜图案**
文件：`data/tfc/recipe/sewing/globe_banner_pattern.json`

```json
{"type":"tfc:sewing","result":{"count":1,"id":"minecraft:globe_banner_pattern"},"squares":["BBWWWWBB","BBWBBWBB","BBWBBWBB","BBWWWWBB"],"stitches":["  ## ##  ","  ## ##  ","         ","  ## ##  ","  ## ##  "]}
```

**样例 2 —— 苦力怕旗帜图案（针脚分布不同）**
文件：`data/tfc/recipe/sewing/creeper_banner_pattern.json`

```json
{"type":"tfc:sewing","result":{"count":1,"id":"minecraft:creeper_banner_pattern"},"squares":["BBWBBWBB","BBBBBBBB","BBWWWWBB","BBWBBWBB"],"stitches":["  ## ##  ","  #   #  ","  # # #  ","  # # #  ","  ## ##  "]}
```

**样例 3 —— 盔甲纹饰模板（海岸，`stitches` 第 3 行全空）**
文件：`data/tfc/recipe/sewing/coast_armor_trim_smithing_template.json`

```json
{"type":"tfc:sewing","result":{"count":1,"id":"minecraft:coast_armor_trim_smithing_template"},"squares":["BBBBBWWB","BBBBWWBB","BBBBWWBB","BBBBBWWB"],"stitches":["     # # ","    #    ","         ","    #    ","     # # "]}
```

**25 个文件的产物覆盖**：13 个盔甲纹饰模板（`*_armor_trim_smithing_template`）、10 个旗帜图案（`*_banner_pattern`）、
以及 `bolt`/`flow`/`guster`/`raiser`/`shaper`/`silence`/`tide`/`vex`/`ward`/`wayfinder`/`wild` 等。
完整清单见 `data/tfc/recipe/sewing/`：`bolt_armor_trim_smithing_template.json`、`coast_armor_trim_smithing_template.json`、
`creeper_banner_pattern.json`、`dune_armor_trim_smithing_template.json`、`eye_armor_trim_smithing_template.json`、
`flower_banner_pattern.json`、`flow_armor_trim_smithing_template.json`、`globe_banner_pattern.json`、
`guster_banner_pattern.json`、`host_armor_trim_smithing_template.json`、`mojang_banner_pattern.json`、
`piglin_banner_pattern.json`、`raiser_armor_trim_smithing_template.json`、`rib_armor_trim_smithing_template.json`、
`sentry_armor_trim_smithing_template.json`、`shaper_armor_trim_smithing_template.json`、
`silence_armor_trim_smithing_template.json`、`skull_banner_pattern.json`、`snout_armor_trim_smithing_template.json`、
`spire_armor_trim_smithing_template.json`、`tide_armor_trim_smithing_template.json`、
`vex_armor_trim_smithing_template.json`、`ward_armor_trim_smithing_template.json`、
`wayfinder_armor_trim_smithing_template.json`、`wild_armor_trim_smithing_template.json`。

##### R-17.5 游戏内触发条件

**触发方块：缝纫台（`SewingTableBlock`）**，不是"针线物品"直接使用。

匹配入口（`SewingRecipe.java` 第 116-118 行）：

```java
public boolean matches(SewingTableContainer.Input inventory, Level level) {
    return inventory.squaresMatch(this) && inventory.stitchesMatch(this);
}
```

`SewingTableContainer.Input` 是 `record Input(SewingTableContainer container) implements NonEmptyInput`（第 360 行），
`stitchesMatch` / `squaresMatch` 定义在其内部类（第 362、373 行）。

| # | 相对源码路径 | 行号 | 作用 |
| --- | --- | --- | --- |
| 1 | `net\dries007\tfc\common\blocks\wood\SewingTableBlock.java` | 60-67 | 方块定义；`SHAPE` 由两个 box 拼合 |
| 2 | 同上 | 99 | `new SimpleMenuProvider((windowId, inv, player) -> SewingTableContainer.create(inv, windowId, ContainerLevelAccess.create(level, pos)), CONTAINER_TITLE)`，标题 `tfc.screen.sewing_table` |
| 3 | `net\dries007\tfc\common\blocks\wood\Wood.java` | 262 | `SEWING_TABLE(wood -> new SewingTableBlock(...))`，每种木材一个缝纫台方块 |
| 4 | `net\dries007\tfc\common\container\TFCContainerTypes.java` | 68 | `SEWING_TABLE` 菜单类型注册 |
| 5 | `net\dries007\tfc\common\container\SewingTableContainer.java` | 73-90 | 槽位常量：`NUM_SLOTS=5`、`SLOT_YARN=0`、`SLOT_TOOL=1`、`SLOT_INPUT_1=2`、`SLOT_INPUT_2=3`、`SLOT_RESULT=4`；按钮 id：`EMPTY_ID=-1`、`BURLAP_ID=0`、`WOOL_ID=1`、`REMOVE_ID=2`、`NEEDLE_ID=3`、`PLACE_STITCH_ID=4`、`RECIPE_ID=5`；容量常量 `SQUARES_PER_CLOTH=8`、`STITCHES_PER_YARN=16`、`MAX_SQUARES=32`、`MAX_STITCHES=45` |
| 6 | 同上 | 108-122 | 材料判定：`isWool` = `TFCTags.Items.SEWING_LIGHT_CLOTH`、`isBurlap` = `TFCTags.Items.SEWING_DARK_CLOTH`、`isString` = `Tags.Items.STRINGS`、`isNeedle` = `TFCTags.Items.SEWING_NEEDLES` |
| 7 | 同上 | 93-95、129-137 | 同步数据：`SimpleContainerData(32)` 存布料格（`placedMaterialData`）、`SimpleContainerData(45)` 存针脚（`stitchData`），与 JSON 的 32/45 完全对应 |
| 8 | 同上 | 161 | `ItemStack result = recipe.value().getResultItem(level.registryAccess())` —— 从配方取展示/产出 |
| 9 | 同上 | 362、373 | `stitchesMatch(SewingRecipe)` / `squaresMatch(SewingRecipe)` —— 与配方逐格比对 |
| 10 | 同上 | 324-333 | 产出时按 `usedWool` / `usedBurlap` / `usedString` / needle 条件扣材料 |
| 11 | 同上 | 216 | `stillValid`：`level.getBlockState(pos).getBlock() instanceof SewingTableBlock && player.position().distanceToSqr(pos.getCenter()) < 64.0` |
| 12 | `net\dries007\tfc\client\screen\SewingTableScreen.java` | 70-116 | 客户端界面；`TEXTURE = tfc:textures/gui/sewing.png`；4 个操作按钮对应 `tfc.tooltip.sewing.dark_cloth` / `light_cloth` / `remove_stitch` / `stitch`，另有 `select_recipe` 按钮（id 5） |
| 13 | 同上 | 121-123、288、328 | `this.recipes.add(holder.value())` 收集全部 `SewingRecipe`；`setRecipe(SewingRecipe)` 供 EMI 一键填充 |
| 14 | `net\dries007\tfc\client\ClientEventHandler.java` | 602 | `event.register(TFCContainerTypes.SEWING_TABLE.get(), SewingTableScreen::new)` |
| 15 | `net\dries007\tfc\common\TFCTags.java` | 202、292-294 | 物品标签 `SEWING_TABLES`、`SEWING_DARK_CLOTH`、`SEWING_LIGHT_CLOTH`、`SEWING_NEEDLES` |

**I/O 容器语义**：缝纫台是"UI 驱动的合成台"，**没有传统输入槽**——
槽 0 放线/绳（yarn，`Tags.Items.STRINGS`，每个提供 16 针）、槽 1 放针（`TFCTags.Items.SEWING_NEEDLES`）、
槽 2/3 放两种布料（浅色 `SEWING_LIGHT_CLOTH` / 深色 `SEWING_DARK_CLOTH`，每块 8 格）、槽 4 是产物。
配方的 `squares`/`stitches` 由玩家在界面上"画"出来（32 格布料 + 45 格针脚），
`matches` 拿这个界面状态与配方比对。

展示层：`net\dries007\tfc\compat\jei\category\SewingRecipeCategory.java`（第 59-60 行 `recipe.getResultItem(registryAccess())`）、
`net\dries007\tfc\compat\emi\recipe\EmiSewingRecipe.java`（第 67、103、117 行 `SewingPatternWidget`）、
`net\dries007\tfc\compat\emi\handlers\EmiSewingHandler.java`（第 47-50 行 `sewingScreen.setRecipe(sewingRecipe.getRecipe())`）。

##### R-17.6 注意事项

1. `SewingRecipe` 实现 `ISimpleRecipe<SewingTableContainer.Input>`，因此继承
   `canCraftInDimensions → true`、`isSpecial → true`、`getResultItem(registries) → ItemStack.EMPTY` 三个默认实现
   （`ISimpleRecipe.java` 第 19-29 行），但 `SewingRecipe` **自己覆写**了 `getResultItem`（第 124-127 行）返回 `result.copy()`。
2. 由于 `isSpecial() == true`，缝纫配方**不会出现在原版配方书**中，只在缝纫台界面与 JEI/EMI 中可见。
3. `stitches` 的 45 位 bitset 使用 `long` 存储；`getStitch(int index)`（第 103-105 行）用 `(bitset >> index & 1) == 1` 读取。
4. `getSquare(int index)`（第 107-114 行）对越界或非法字符会抛 `IllegalStateException("Sewing Recipe has invalid square at index " + index)`，
   但正常情况下已被 CODEC 的 `validate` 拦下。

---

### 附录：本组"未能核实"与已核查范围

| 项 | 状态 | 说明与已检查文件 |
| --- | --- | --- |
| `AndIngredient` 的 JSON 字段定义 | **部分核实** | 从全部 56 个使用它的 heating JSON 反证字段名为 `children`（值为 `Ingredient` 列表），但**未逐行读取** `net\dries007\tfc\common\recipes\ingredients\AndIngredient.java` 的 `CODEC` 定义。其余 6 种自定义 Ingredient（`rotten`、`not_rotten`、`has_trait`、`lacks_trait`、`heat`、`fluid_content`）的字段亦未逐个打开其类文件，仅由 `TFCIngredients.java:42-48` 确认注册名与实现类 |
| `Ingredient.CODEC` / `FluidStack.CODEC` / `ItemStack.CODEC` 的字段细节 | **属外部类** | 这些是 Minecraft / NeoForge 的 codec，不在 TFC 反编译产物内，本组按其 JSON 实际写法（`{"item":...}`、`{"tag":...}`、`{"amount":N,"id":...}`、`{"id":...,"count":N,"components":{...}}`）描述 |
| `HeatingRecipe` 是否存在"按 Level 查询"的变体 | **已核实不存在** | 全文件仅第 64-67 行一个 `getRecipe(ItemStack)`；`RecipeHelpers.getRecipe(CACHE, ...)` 系列均不带 `Level` |
| `heating` 的 `chance` 字段 | **已核实不存在** | `HeatingRecipe.java:56` CODEC 无该字段；构造器第 69-75 行无该参数；883 个 JSON 中 `"chance"` 仅出现在 `result_item.modifiers` 内部 1 次 |
| `knapping` 是否要求 5×5 | **已核实不要求** | `KnappingPattern.java:44-67` 允许 1..5 行/列；实测 30 个文件带 `default_on`，图案为 3×5、5×4、2×5、5×2 等 |
| `knapping_type` 的完整清单 | **已核实为 5 个** | 目录 `moddev\jar-extract\data\tfc\tfc\knapping_type\` 仅含 `clay.json`、`fire_clay.json`、`goat_horn.json`、`leather.json`、`rock.json`。任务书提及"等"暗示可能有第 6 个，**实际不存在** |
| `glassworking` 的"字母表"完整清单 | **已核实为 22 个注册项** | 逐行读取 `GlassOperation.java:64-85`；另需注意 `data/tfc/glass_operation` 若有语言/数据文件也可能存在，但注册表在代码中建全 |
| `sewing` 的 `stitches` 语义（`#` vs 其他字符） | **已核实** | `stitchesToBitset` 第 88 行 `text.charAt(j) != ' '` → 任何非空格等价于针脚；25 个真实文件统一使用 `#` |
| `scraping` 的"刮刀物品" | **已更正** | 任务书提示"由刮刀物品触发"；源码 `ScrapingBlock.java:112` 实际判定 `TFCTags.Items.TOOLS_KNIFE`（**刀**类工具），触发方块为 `tfc:scraping`。未见名为"刮刀"的独立物品参与该逻辑 |
| `HeatingRecipe` 的调用点是否穷尽 | **已穷尽（grep 全仓库）** | 对 `net\` 全树 grep `HeatingRecipe` 得 111 处匹配，去除 import / 类型声明 / 展示层后，本文 R-12.8 列出 36 个调用或引用点（其中 17 个为方块实体主逻辑） |
| `ItemStackModifier` 各实现的完整字段 | **主体已核实** | 逐行读取 `ItemStackModifiers.java:54-78`（22 项清单）与 `ItemStackProvider.java:35`；带字段的 7 项中，`add_trait`/`remove_trait`/`add_heat`/`dye_leather`/`meal`/`extra_products`/`chance` 的字段名经 grep `fieldOf` 于 `outputs\` 目录确认。**未逐个打开** 15 个 unit codec modifier 的类文件确认其无字段（依据是注册处传入 `INSTANCE` → `MapCodec.unit(...)`，见 `ItemStackModifiers.java:80-82`） |
| `heating` 中 `result_item` + `result_fluid` 同时给出的行为 | **代码层已核实，数据层无实例** | CODEC 无互斥校验，理论上可同时给出；实际 883 个文件中 0 例 |
| 各类型 JSON 的文件计数 | **已实测** | heating 883、quern 89、scraping 7、knapping 101、glassworking 60、sewing 25（统计目录 `moddev\jar-extract\data\tfc\recipe\<type>\`，递归含子目录） |

##### 本组核查所用文件清单

**反编译源码（`moddev\src-ref\TFC-decompiled\`）**
- `net\dries007\tfc\common\recipes\HeatingRecipe.java`（全文 138 行）
- `net\dries007\tfc\common\recipes\QuernRecipe.java`（全文 62 行）
- `net\dries007\tfc\common\recipes\ScrapingRecipe.java`（全文 82 行）
- `net\dries007\tfc\common\recipes\KnappingRecipe.java`（全文 108 行）
- `net\dries007\tfc\common\recipes\GlassworkingRecipe.java`（全文 76 行）
- `net\dries007\tfc\common\recipes\SewingRecipe.java`（全文 137 行）
- `net\dries007\tfc\common\recipes\ItemRecipe.java`、`ISimpleRecipe.java`、`IRecipePredicate.java`、`INoopInputRecipe.java`、`RecipeHelpers.java`
- `net\dries007\tfc\common\recipes\TFCRecipeTypes.java`、`TFCRecipeSerializers.java`
- `net\dries007\tfc\common\recipes\outputs\ItemStackProvider.java`、`ItemStackModifier.java`、`ItemStackModifiers.java`、`ChanceModifier.java`、`ExtraProductModifier.java`
- `net\dries007\tfc\common\recipes\ingredients\TFCIngredients.java`
- `net\dries007\tfc\util\data\KnappingPattern.java`、`KnappingType.java`
- `net\dries007\tfc\common\component\glass\GlassOperation.java`、`GlassOperations.java`、`GlassWorking.java`
- `net\dries007\tfc\common\component\heat\HeatDefinition.java`、`HeatCapability.java`、`IHeatView.java`
- `net\dries007\tfc\common\blockentities\`：`FirepitBlockEntity.java`、`GrillBlockEntity.java`、`CharcoalForgeBlockEntity.java`、`CrucibleBlockEntity.java`、`PitKilnBlockEntity.java`、`FireboxBlockEntity.java`、`BloomeryBlockEntity.java`、`BlastFurnaceBlockEntity.java`、`QuernBlockEntity.java`、`ScrapingBlockEntity.java`
- `net\dries007\tfc\common\blocks\devices\QuernBlock.java`、`ScrapingBlock.java`
- `net\dries007\tfc\common\blocks\GlassBasinBlock.java`、`net\dries007\tfc\common\blocks\wood\SewingTableBlock.java`
- `net\dries007\tfc\common\items\GlassBlowpipeItem.java`
- `net\dries007\tfc\common\container\KnappingContainer.java`、`SewingTableContainer.java`
- `net\dries007\tfc\common\component\mold\Vessel.java`
- `net\dries007\tfc\common\recipes\BlastFurnaceRecipe.java`、`BloomeryRecipe.java`
- `net\dries007\tfc\util\InteractionManager.java`、`net\dries007\tfc\util\SelfTests.java`（仅调用点行）
- `net\dries007\tfc\client\ClientForgeEventHandler.java`（仅调用点行）

**jar 内真实数据（`moddev\jar-extract\`）**
- 目录清单与计数：`data\tfc\recipe\{heating,quern,scraping,knapping,glassworking,sewing}\`
- 全文读取的 JSON 样例：`recipe\scraping\{large_raw_hide,small_raw_hide,medium_scraped_hide,paper}.json`；
  `recipe\heating\{metal\propick\copper,metal\knife\blue_steel,metal\block\zinc,ore\rich_hematite,powder\kaolinite,food\cooked_beef,burn_bread,burn_meat}.json`；
  `recipe\quern\{blue_dye,powder\flux_from_borax,food\wheat_flour}.json`；
  `recipe\knapping\{stone\axe_head\igneous_extrusive,saddle,ceramic\unfired_bowl,call_goat_horn_goat_horn,leather_helmet,obsidian_knife_head}.json`（后两个经 grep 全文）；
  `recipe\glassworking\{glass,lens,empty_jar,cyan_poured_glass_2,black_stained_glass}.json`；
  `recipe\sewing\{globe_banner_pattern,creeper_banner_pattern,coast_armor_trim_smithing_template}.json`
- 全文读取的数据文件：`tfc\knapping_type\{clay,fire_clay,goat_horn,leather,rock}.json`；
  `tfc\item_heat\{anemometer,bismuthinite,bell,blast_furnace,blowpipe,brass_bell}.json`

---

## 第 4 部分　锅煮、织机与冶炼炉配方（R-18 ~ R-23）


> 版本基准：TerraFirmaCraft-NeoForge-1.21.1-4.2.10 / Minecraft 1.21.1 / NeoForge 21.1.248
> 证据来源（全部为本地文件，无网络依赖）：
> - 反编译源码根：`moddev/src-ref/TFC-decompiled`（下文相对源码路径均以此为根）
> - 真实 jar 解包内容：`moddev/jar-extract`（下文"jar 内路径"以 `jar-extract` 为根）
> - 字节码交叉验证（NeoForge 与 Minecraft 侧类不在反编译树内时使用）：
>   - `.minecraft/libraries/net/minecraft/client/1.21.1-20240808.144430/client-1.21.1-20240808.144430-srg.jar`（`javap`）
>   - `.minecraft/libraries/net/neoforged/neoforge/21.1.248/neoforge-21.1.248-client.jar` + `neoforge-21.1.248-universal.jar`（`javap`）
> - 反编译产物无参数名、无注释，但 `CODEC` 定义、record 组件、字段常量完整可读，本组所有字段表均从 `CODEC` 逐行读出。

---

### 组 A4 覆盖范围

本组负责以下 6 种配方类型，覆盖 TFC 的锅（烹饪/熬煮/制酱/罐装）、织布机、合成台食物合并、冶炼炉（块炼铁）四条产线：

| 编号 | JSON `type` | 实现类 | 本组对应小节 |
| --- | --- | --- | --- |
| R-18 | `tfc:pot` | `net.dries007.tfc.common.recipes.SimplePotRecipe` | 锅煮配方（通用：物品→物品 / 流体→流体 / 两者兼有） |
| R-19 | `tfc:pot_soup` | `net.dries007.tfc.common.recipes.SoupPotRecipe` | 锅煮汤配方（无产物字段，产物由代码按食材营养动态构造） |
| R-20 | `tfc:pot_jam` | `net.dries007.tfc.common.recipes.JamPotRecipe` | 锅煮果酱/罐装配方（无封盖 + 有封盖双产物 + 贴图） |
| R-21 | `tfc:loom` | `net.dries007.tfc.common.recipes.LoomRecipe` | 织布机配方（定量物品 → 物品 + 推进步数 + 过程贴图） |
| R-22 | `tfc:food_combining` | `net.dries007.tfc.common.recipes.FoodCombiningCraftingRecipe` | 食物合并（合成台特殊配方，**无独立 recipe type**，无 JSON 字段） |
| R-23 | `tfc:bloomery` | `net.dries007.tfc.common.recipes.BloomeryRecipe` | 冶炼炉块炼配方（定量流体 + 催化物 → 物品 + 耗时） |

不属于本组、但被本组大量引用的通用辅助类型（`PotOutput`、`ItemStackProvider`、`ItemStackModifier`/`ItemStackModifiers`、`TFCIngredients`、`SizedIngredient`、`SizedFluidIngredient`）在文末「附录 A4-1 ~ A4-4」集中说明。

编号说明：本组严格使用 `R-18` ~ `R-23`，不占其它组的编号空间。

##### A4.0 六种类型的「type id / recipe type / serializer」速查

这是本组最容易出错的地方，先给结论表，后续各小节给出逐行源码证据。

| JSON `type`（= serializer 注册名） | 承载它的 `RecipeType`（`getType()` 返回值） | 二者是否同名 | 关键证据 |
| --- | --- | --- | --- |
| `tfc:pot` | `tfc:pot` | 是 | `TFCRecipeTypes.java:49`、`TFCRecipeSerializers.java:64`、`PotRecipe.java:83-85` |
| `tfc:pot_soup` | **`tfc:pot`**（无独立 recipe type） | **否** | `TFCRecipeSerializers.java:65`；`SoupPotRecipe` 未覆盖 `getType()`，继承 `PotRecipe.java:83-85` |
| `tfc:pot_jam` | **`tfc:pot`**（无独立 recipe type） | **否** | `TFCRecipeSerializers.java:66`；`JamPotRecipe` 未覆盖 `getType()`，继承 `PotRecipe.java:83-85` |
| `tfc:loom` | `tfc:loom` | 是 | `TFCRecipeTypes.java:54`、`TFCRecipeSerializers.java:74`、`LoomRecipe.java:105-107` |
| `tfc:food_combining` | **`minecraft:crafting`**（原版 `RecipeType.CRAFTING`） | **否** | `TFCRecipeSerializers.java:80`；`FoodCombiningCraftingRecipe extends CustomRecipe` 且**未**覆盖 `getType()`（`FoodCombiningCraftingRecipe.java` 全文 89 行无 `getType`），故继承 `CraftingRecipe.getType()`，字节码为 `getstatic RecipeType.CRAFTING` |
| `tfc:bloomery` | `tfc:bloomery` | 是 | `TFCRecipeTypes.java:58`、`TFCRecipeSerializers.java:70`、`BloomeryRecipe.java:109-111` |

补充：`TFCRecipeTypes` 中**没有** `pot_soup` / `pot_jam` / `food_combining` 的注册项。`TFCRecipeTypes.java` 全文注册的 20 个名字为：
`collapse`、`landslide`、`chisel`、`heating`、`quern`、`pot`、`scraping`、`knapping`、`alloy`、`casting`、`loom`、`barrel_sealed`、`barrel_instant`、`barrel_instant_fluid`、`bloomery`、`anvil`、`welding`、`blast_furnace`、`glassworking`、`sewing`（`TFCRecipeTypes.java:44-63`）。
`food_combining` 连 serializer 之外的类型注册都不存在，因为它挂在原版 `minecraft:crafting` 下。

TFC 官方模组自带的 JEI 集成代码直接印证了「三种 pot 共用 `tfc:pot` 类型、靠 serializer 区分」：

```java
// moddev/src-ref/TFC-decompiled/net/dries007/tfc/compat/jei/JEIIntegration.java:214-216
registry.addRecipes(SOUP_POT,   JEIIntegration.recipes(TFCRecipeTypes.POT, recipe -> recipe.getSerializer() == TFCRecipeSerializers.POT_SOUP.get()));
registry.addRecipes(SIMPLE_POT, JEIIntegration.recipes(TFCRecipeTypes.POT, recipe -> recipe.getSerializer() == TFCRecipeSerializers.POT_SIMPLE.get()));
registry.addRecipes(JAM_POT,    JEIIntegration.recipes(TFCRecipeTypes.POT, recipe -> recipe.getSerializer() == TFCRecipeSerializers.POT_JAM.get()));
```

EMI 集成同理（`net/dries007/tfc/compat/emi/EmiIntegration.java:235-247`：先 `recipes(registry.getRecipeManager(), TFCRecipeTypes.POT)`，再按 `serializer == POT_JAM/POT_SOUP/POT_SIMPLE` 分流）。

##### A4.1 文件分布速查（真实 jar）

| JSON `type` | jar 内目录 | 文件数 |
| --- | --- | --- |
| `tfc:pot` | `data/tfc/recipe/pot/`（顶层 130 个）+ `data/tfc/recipe/pot/food/`（15 个） | **145** |
| `tfc:pot_soup` | `data/tfc/recipe/pot/`（与 `tfc:pot` 混放在同一目录） | **3** |
| `tfc:pot_jam` | `data/tfc/recipe/pot/`（与 `tfc:pot` 混放在同一目录） | **66** |
| `tfc:loom` | `data/tfc/recipe/loom/` | **5** |
| `tfc:food_combining` | `data/tfc/recipe/crafting/` | **1** |
| `tfc:bloomery` | `data/tfc/recipe/bloomery/` | **1** |

统计命令与结果（PowerShell，逐文件解析 `type` 字段）：

```
data/tfc/recipe/pot 顶层文件: 199（= 130 pot + 66 pot_jam + 3 pot_soup）
data/tfc/recipe/pot 子目录 food: 15（全部为 tfc:pot）
data/tfc/recipe/pot 递归合计: 214
```

**重要**：`pot_soup` 与 `pot_jam` 的 JSON **不在** `data/tfc/recipe/pot_soup/`、`data/tfc/recipe/pot_jam/` 目录下（这两个目录在 jar 中不存在）。1.21 的配方加载器会遍历 `data/<ns>/recipe/**` 下的所有子目录，目录名与 type 无关，因此三种 pot 配方共处 `recipe/pot/` 目录完全合法。

---

### [R-18] tfc:pot —— 锅煮配方（通用产物）

##### R-18.1 类型标识与实现类

| 项目 | 值 | 证据 |
| --- | --- | --- |
| JSON `type` | `tfc:pot` | `net/dries007/tfc/common/recipes/TFCRecipeSerializers.java:64` |
| recipe type id | `tfc:pot` | `net/dries007/tfc/common/recipes/TFCRecipeTypes.java:49`（`POT = TFCRecipeTypes.register("pot")`） |
| serializer id | `tfc:pot` | `TFCRecipeSerializers.java:64`（`register("pot", SimplePotRecipe.CODEC, SimplePotRecipe.STREAM_CODEC)`） |
| 实现类全名 | `net.dries007.tfc.common.recipes.SimplePotRecipe` | `net/dries007/tfc/common/recipes/SimplePotRecipe.java:42` |
| 父类 | `net.dries007.tfc.common.recipes.PotRecipe` | `SimplePotRecipe.java:43`（`extends PotRecipe`） |
| 接口链 | `SimplePotRecipe` → `PotRecipe implements ISimpleRecipe<IPotInventory>` → `Recipe<IPotInventory>` | `PotRecipe.java:46-47`、`ISimpleRecipe.java:17-18` |
| `getType()` 返回值 | `TFCRecipeTypes.POT.get()`（定义在父类，子类未覆盖） | `PotRecipe.java:83-85` |
| `getSerializer()` 返回值 | `TFCRecipeSerializers.POT_SIMPLE.get()`（其注册名为 `pot`） | `SimplePotRecipe.java:91-94` |
| 输入容器类型 | `IPotInventory`（锅方块实体的物品 + 流体双接口） | `PotRecipe.java:47`、`net/dries007/tfc/common/blockentities/IPotInventory.java:10-19` |

注意：`TFCRecipeSerializers` 中这个 `Id` 的**字段名**是 `POT_SIMPLE`（而**注册名**是 `"pot"`），二者不同名极易混淆：

```java
// TFCRecipeSerializers.java:64-66
public static final Id<SimplePotRecipe> POT_SIMPLE = TFCRecipeSerializers.register("pot",       SimplePotRecipe.CODEC, SimplePotRecipe.STREAM_CODEC);
public static final Id<SoupPotRecipe>   POT_SOUP   = TFCRecipeSerializers.register("pot_soup",  SoupPotRecipe.CODEC,   SoupPotRecipe.STREAM_CODEC);
public static final Id<JamPotRecipe>    POT_JAM    = TFCRecipeSerializers.register("pot_jam",   JamPotRecipe.CODEC,    JamPotRecipe.STREAM_CODEC);
```

##### R-18.2 完整字段表

`SimplePotRecipe` 的字段由**两层**组成：父类 `PotRecipe` 的 4 个字段（继承）+ 自身 3 个字段。

###### R-18.2.1 父类 `PotRecipe` 字段（4 个，全部必需）

父类 `CODEC` 源码（`PotRecipe.java:48`，单行完整定义）：

```java
public static final MapCodec<PotRecipe> CODEC =
    RecordCodecBuilder.mapCodec(i -> i.group(
        Ingredient.CODEC.listOf(0, 5).fieldOf("ingredients").forGetter(c -> c.itemIngredients),
        SizedFluidIngredient.FLAT_CODEC.fieldOf("fluid_ingredient").forGetter(c -> c.fluidIngredient),
        Codec.INT.fieldOf("duration").forGetter(c -> c.duration),
        Codec.FLOAT.fieldOf("temperature").forGetter(c -> Float.valueOf(c.temperature))
    ).apply(i, PotRecipe::new));
```

| 字段名 | 类型 | 必需/可选 | 默认值 | 语义 | 证据 |
| --- | --- | --- | --- | --- | --- |
| `ingredients` | `Ingredient` 列表（长度 0~5） | **必需**（`fieldOf`） | 无（但允许 `[]`，因为 `listOf(0, 5)` 下界为 0） | 锅内的物品输入，最多 5 个。匹配顺序无关（见 R-18.2.3 的完美匹配算法） | `PotRecipe.java:48`（`Ingredient.CODEC.listOf(0, 5).fieldOf("ingredients")`）；字段声明 `PotRecipe.java:50` |
| `fluid_ingredient` | `SizedFluidIngredient`（NeoForge，扁平形式） | **必需** | 无 | 锅内流体输入（种类 + 需求量）。JSON 写作 `{"fluid":"<流体 id>","amount":N}` 或 `{"tag":"<流体 tag>","amount":N}`，详见 A4.3 | `PotRecipe.java:48`（`SizedFluidIngredient.FLAT_CODEC.fieldOf("fluid_ingredient")`）；字段声明 `PotRecipe.java:51` |
| `duration` | `int`（tick） | **必需** | 无 | 煮沸所需 tick 数（20 tick = 1 秒）。达到该值后才结算产物；另有一次性的 100 tick 预热（`PotBlockEntity.PRE_BOIL_TIME`，`PotBlockEntity.java:85`） | `PotRecipe.java:48`（`Codec.INT.fieldOf("duration")`）；字段声明 `PotRecipe.java:52` |
| `temperature` | `float` | **必需** | 无 | **最低所需温度**（不是产物温度）。判定为严格大于：`isHotEnough(tempIn) => tempIn > this.temperature` | `PotRecipe.java:48`（`Codec.FLOAT.fieldOf("temperature")`）；字段声明 `PotRecipe.java:53`；判定逻辑 `PotRecipe.java:99-101` |

`ingredients` 的上界来自 `listOf(0, 5)`，即**最多 5 个**；`SimplePotRecipe` 中输出列表也用同一个上界（`listOf(0, 5)`）。

###### R-18.2.2 `SimplePotRecipe` 自身字段（3 个，2 可选 1 必有默认）

自身 `CODEC` 源码（`SimplePotRecipe.java:44-50`）：

```java
public static final MapCodec<SimplePotRecipe> CODEC =
    RecordCodecBuilder.mapCodec(i -> i.group(
        PotRecipe.CODEC.forGetter(c -> c),                                                              // 继承的 4 字段
        FluidStack.CODEC.optionalFieldOf("fluid_output", FluidStack.EMPTY).forGetter(c -> c.outputFluid),
        ItemStackProvider.CODEC.listOf(0, 5).optionalFieldOf("item_output", List.of()).forGetter(c -> c.outputItems),
        Codec.BOOL.optionalFieldOf("uses_all_fluid", true).forGetter(c -> c.usesAllFluid)
    ).apply(i, SimplePotRecipe::new))
    .validate(recipe -> { /* 见 R-18.2.4 */ });
```

| 字段名 | 类型 | 必需/可选 | 默认值 | 语义 | 证据 |
| --- | --- | --- | --- | --- | --- |
| `fluid_output` | `FluidStack`（`{"id":"<流体 id>","amount":N}`） | **可选** | `FluidStack.EMPTY`（无流体产出） | 结算时向锅内填充的流体产物 | `SimplePotRecipe.java:44`（`FluidStack.CODEC.optionalFieldOf("fluid_output", FluidStack.EMPTY)`）；字段声明 `SimplePotRecipe.java:52` |
| `item_output` | `ItemStackProvider` 列表（长度 0~5） | **可选** | `List.of()`（空列表，无物品产出） | 结算时写入输入槽（槽 4~8）的物品产物，逐槽对应。元素既可以是纯 `ItemStack`（`{"id":"...","count":N}`），也可以是带 `modifiers` 的 provider 对象 | `SimplePotRecipe.java:44`（`ItemStackProvider.CODEC.listOf(0, 5).optionalFieldOf("item_output", List.of())`）；字段声明 `SimplePotRecipe.java:53` |
| `uses_all_fluid` | `boolean` | **可选** | **`true`** | 控制结算时的流体产物量：`true` → 直接输出 `fluid_output` 的整份量；`false` → 走 `favorNewFluidStack(...)`，若锅内剩余输入流体量 **严格大于** `fluid_ingredient.amount()` 且 `fluid_output` 为空，则把"输入流体减去消耗量"的余量作为产物，否则输出 `fluid_output` | `SimplePotRecipe.java:44`（`Codec.BOOL.optionalFieldOf("uses_all_fluid", true)`）；字段声明 `SimplePotRecipe.java:54`；行为 `SimplePotRecipe.java:83-89` 与 `:80` |

`uses_all_fluid` 的实际语义在 `getOutput` 与 `favorNewFluidStack` 中（`SimplePotRecipe.java:72-89`）：

```java
// SimplePotRecipe.java:80
return new SimpleOutput(
    this.usesAllFluid ? this.outputFluid.copy()
                      : this.favorNewFluidStack(inventory.getFluidHandler().getFluidInTank(0), this.outputFluid),
    outputs);

// SimplePotRecipe.java:83-89
public FluidStack favorNewFluidStack(FluidStack input, FluidStack output) {
    if ((input = input.copy()).getAmount() > this.fluidIngredient.amount() && output.isEmpty()) {
        input.setAmount(input.getAmount() - this.fluidIngredient.amount());
        return input;
    }
    return output.copy();
}
```

###### R-18.2.3 匹配语义（不是字段，但决定 JSON 怎么写）

`PotRecipe.matches(IPotInventory, Level)`（`PotRecipe.java:66-77`）：

```java
public boolean matches(IPotInventory inventory, Level worldIn) {
    if (!this.fluidIngredient.test(inventory.getFluidInTank(0))) return false;      // ① 流体必须先匹配（含数量）
    ArrayList<ItemStack> stacks = new ArrayList<>();
    for (int i = inventory.inputStart(); i <= inventory.inputEnd(); ++i) {           // ② 收集槽 4..8 的非空物品
        ItemStack stack = inventory.getStackInSlot(i);
        if (stack.isEmpty()) continue;
        stacks.add(stack);
    }
    return stacks.isEmpty() && this.itemIngredients.isEmpty()
        || Helpers.perfectMatchExists(stacks, this.itemIngredients);                 // ③ 完美匹配
}
```

- **槽位范围**：`inputStart() = 4`、`inputEnd() = 8`（`PotBlockEntity.java:270-277`），即 5 个输入槽。
- **物品数量必须完全相等**：`Helpers.perfectMatchExists` 第一步就要求 `inputs.size() == tests.size()`（`net/dries007/tfc/util/Helpers.java:1124-1127`），随后用二分图完美匹配判定（`Helpers.java:1129-1140`）。因此「3 个 `tfc:powder/wood_ash`」这类配方必须在 `ingredients` 中重复写 3 次。
- **`ingredients: []` 合法**：当 `ingredients` 为空且锅内无物品时匹配成功（`PotRecipe.java:76` 的左半边）。TFC 自带数据中**没有**这样的样例（`"ingredients":[]` 在 145 个 pot 配方中出现 0 次），但 codec 允许。
- **流体数量也参与匹配**：`SizedFluidIngredient.test(FluidStack)` 由 NeoForge 实现，会校验数量（`fluidIngredient.amount()`）。

###### R-18.2.4 额外校验（`validate`）

`SimplePotRecipe.CODEC` 挂了**唯一一处** `.validate(...)`（`SimplePotRecipe.java:44-50`）。原文（去掉强转噪声）：

```java
.validate(recipe -> {
    boolean anyProvidersDependOnInput = recipe.outputItems.stream().anyMatch(ItemStackProvider::dependsOnInput);
    if (anyProvidersDependOnInput && recipe.outputItems.size() != recipe.itemIngredients.size()) {
        return DataResult.error(() -> "At least one output is an ItemStackProvider that depends on the input. "
            + "This is only allowed if there are (1) equal number of inputs and outputs, and (2) All inputs and outputs are the same");
    }
    return DataResult.success(recipe);
});
```

要点：
- 只要 `item_output` 中存在**任一** `ItemStackProvider.dependsOnInput() == true` 的元素（例如带 `tfc:copy_input` 修饰符），就要求 `item_output.size() == ingredients.size()`。
- 报错文本里写的是 "All inputs and outputs are the same"，但代码**实际只校验了元素个数**（`size()` 比较），并未逐项比对物品是否相同。这是 TFC 侧的宽松之处，写数据时不要依赖它代为纠错。
- 若 `item_output` 全部是不依赖输入的 provider（例如纯 `{"id":"tfc:food/boiled_egg","count":1}`），则**不校验**个数是否与 `ingredients` 相等。例：`data/tfc/recipe/pot/food/cooked_rice_5.json` 是 5 输入 → 5 输出（相等）；而 `data/tfc/recipe/pot/food/boiled_egg_1.json` 是 1 输入 → 1 输出。理论上 1 输入 → 5 输出也在允许范围内（只要输出不依赖输入）。

###### R-18.2.5 `STREAM_CODEC`（网络同步用，与 JSON 无关，但可交叉验证字段顺序）

```java
// SimplePotRecipe.java:51
public static final StreamCodec<RegistryFriendlyByteBuf, SimplePotRecipe> STREAM_CODEC = StreamCodec.composite(
    PotRecipe.STREAM_CODEC, c -> c,
    FluidStack.OPTIONAL_STREAM_CODEC, c -> c.outputFluid,
    ItemStackProvider.STREAM_CODEC.apply(ByteBufCodecs.list(5)), c -> c.outputItems,
    ByteBufCodecs.BOOL, c -> c.usesAllFluid,
    SimplePotRecipe::new);
```

`FluidStack.OPTIONAL_STREAM_CODEC` 对应 JSON 的 `optionalFieldOf`，`ByteBufCodecs.list(5)` 对应 `listOf(0, 5)`。

##### R-18.3 真实 JSON 样例

以下内容均为从 `moddev/jar-extract` 逐字读取（文件均为单行），未做任何改写。

###### 样例 1：流体输入 → 流体输出（最简结构）

相对路径：`jar-extract/data/tfc/recipe/pot/black_dye.json`

```json
{"type":"tfc:pot","duration":2400,"fluid_ingredient":{"amount":1000,"fluid":"minecraft:water"},"fluid_output":{"amount":1000,"id":"tfc:black_dye"},"ingredients":[{"item":"minecraft:black_dye"}],"temperature":600.0}
```

结构特征：1 个物品输入、1 个流体输入、只有 `fluid_output`、**没有** `item_output` 与 `uses_all_fluid`（走默认值 `true`）。

###### 样例 2：物品输入 → 物品输出（纯物品，带 `item_output`）

相对路径：`jar-extract/data/tfc/recipe/pot/food/boiled_egg_1.json`

```json
{"type":"tfc:pot","duration":1200,"fluid_ingredient":{"amount":100,"fluid":"minecraft:water"},"ingredients":[{"type":"tfc:and","children":[{"item":"minecraft:egg"},{"type":"tfc:not_rotten"}]}],"item_output":[{"count":1,"id":"tfc:food/boiled_egg"}],"temperature":300.0}
```

结构特征：`ingredients` 用了自定义 ingredient `tfc:and`（原版物品 + `tfc:not_rotten` 组合）；`item_output` 的元素是**纯 ItemStack 形式**（`{"count":1,"id":"..."}`，走 `ItemStackProvider.CODEC` 的 `Either.right` 分支）；无 `fluid_output`。

这与样例 1 是两种结构上不同的配方（一个输出流体、一个输出物品）。

###### 样例 3（附加）：多物品输入 → 多物品输出（数量对齐）

相对路径：`jar-extract/data/tfc/recipe/pot/food/cooked_rice_5.json`

```json
{"type":"tfc:pot","duration":1200,"fluid_ingredient":{"amount":100,"fluid":"minecraft:water"},"ingredients":[{"type":"tfc:and","children":[{"item":"tfc:food/rice_grain"},{"type":"tfc:not_rotten"}]},{"type":"tfc:and","children":[{"item":"tfc:food/rice_grain"},{"type":"tfc:not_rotten"}]},{"type":"tfc:and","children":[{"item":"tfc:food/rice_grain"},{"type":"tfc:not_rotten"}]},{"type":"tfc:and","children":[{"item":"tfc:food/rice_grain"},{"type":"tfc:not_rotten"}]},{"type":"tfc:and","children":[{"item":"tfc:food/rice_grain"},{"type":"tfc:not_rotten"}]}],"item_output":[{"count":1,"id":"tfc:food/cooked_rice"},{"count":1,"id":"tfc:food/cooked_rice"},{"count":1,"id":"tfc:food/cooked_rice"},{"count":1,"id":"tfc:food/cooked_rice"},{"count":1,"id":"tfc:food/cooked_rice"}],"temperature":300.0}
```

###### 样例 4（附加）：`item_output` 使用 `modifiers`（依赖输入的 provider）

相对路径：`jar-extract/data/tfc/recipe/pot/jam_banana_canning_1.json`

```json
{"type":"tfc:pot","duration":300,"fluid_ingredient":{"amount":100,"fluid":"minecraft:water"},"ingredients":[{"type":"tfc:and","children":[{"item":"tfc:jar/banana"},{"type":"tfc:lacks_trait","trait":"tfc:canned"},{"type":"tfc:not_rotten"}]}],"item_output":[{"modifiers":[{"type":"tfc:copy_input"},{"type":"tfc:add_trait","trait":"tfc:canned"}]}],"temperature":300.0,"uses_all_fluid":false}
```

结构特征：`item_output` 元素走 `ItemStackProvider.CODEC` 的 `Either.left`（record 形式），只给了 `modifiers`（`stack` 字段省略 → 默认 `ItemStack.EMPTY`）；`uses_all_fluid:false`。这正是 R-18.2.4 校验规则针对的形态（1 输入 ↔ 1 输出）。

###### 样例 5（附加）：5 输入 + 5 个依赖输入的 provider + 显式 `uses_all_fluid:false`

相对路径：`jar-extract/data/tfc/recipe/pot/jam_banana_canning_5.json`

```json
{"type":"tfc:pot","duration":300,"fluid_ingredient":{"amount":500,"fluid":"minecraft:water"},"ingredients":[{"type":"tfc:and","children":[{"item":"tfc:jar/banana"},{"type":"tfc:lacks_trait","trait":"tfc:canned"},{"type":"tfc:not_rotten"}]},{"type":"tfc:and","children":[{"item":"tfc:jar/banana"},{"type":"tfc:lacks_trait","trait":"tfc:canned"},{"type":"tfc:not_rotten"}]},{"type":"tfc:and","children":[{"item":"tfc:jar/banana"},{"type":"tfc:lacks_trait","trait":"tfc:canned"},{"type":"tfc:not_rotten"}]},{"type":"tfc:and","children":[{"item":"tfc:jar/banana"},{"type":"tfc:lacks_trait","trait":"tfc:canned"},{"type":"tfc:not_rotten"}]},{"type":"tfc:and","children":[{"item":"tfc:jar/banana"},{"type":"tfc:lacks_trait","trait":"tfc:canned"},{"type":"tfc:not_rotten"}]}],"item_output":[{"modifiers":[{"type":"tfc:copy_input"},{"type":"tfc:add_trait","trait":"tfc:canned"}]},{"modifiers":[{"type":"tfc:copy_input"},{"type":"tfc:add_trait","trait":"tfc:canned"}]},{"modifiers":[{"type":"tfc:copy_input"},{"type":"tfc:add_trait","trait":"tfc:canned"}]},{"modifiers":[{"type":"tfc:copy_input"},{"type":"tfc:add_trait","trait":"tfc:canned"}]},{"modifiers":[{"type":"tfc:copy_input"},{"type":"tfc:add_trait","trait":"tfc:canned"}]}],"temperature":300.0,"uses_all_fluid":false}
```

###### 样例 6（附加）：5 输入 → 1 份流体输出（`lye`）

相对路径：`jar-extract/data/tfc/recipe/pot/lye.json`

```json
{"type":"tfc:pot","duration":2400,"fluid_ingredient":{"amount":1000,"fluid":"minecraft:water"},"fluid_output":{"amount":1000,"id":"tfc:lye"},"ingredients":[{"item":"tfc:powder/wood_ash"},{"item":"tfc:powder/wood_ash"},{"item":"tfc:powder/wood_ash"},{"item":"tfc:powder/wood_ash"},{"item":"tfc:powder/wood_ash"}],"temperature":600.0}
```

###### 样例 7（附加）：`tfc:canola_oil_water`（与 `lye` 同构，可对比 `temperature`）

相对路径：`jar-extract/data/tfc/recipe/pot/canola_oil_water.json`

```json
{"type":"tfc:pot","duration":2400,"fluid_ingredient":{"amount":1000,"fluid":"minecraft:water"},"fluid_output":{"amount":1000,"id":"tfc:canola_oil_water"},"ingredients":[{"item":"tfc:canola_paste"},{"item":"tfc:canola_paste"},{"item":"tfc:canola_paste"},{"item":"tfc:canola_paste"},{"item":"tfc:canola_paste"}],"temperature":300.0}
```

##### R-18.4 游戏内触发条件（驱动链）

**唯一驱动方：`PotBlockEntity`（锅方块实体）。**

| 环节 | 源码位置 | 关键代码 |
| --- | --- | --- |
| 缓存配方 | `net/dries007/tfc/common/blockentities/PotBlockEntity.java:212-215` | `this.cachedRecipe = this.level.getRecipeManager().getRecipeFor(TFCRecipeTypes.POT.get(), (RecipeInput)(IPotInventory)this.inventory, this.level).map(RecipeHolder::value).orElse(null);` |
| 是否在煮 | `PotBlockEntity.java:217-219` | `return this.cachedRecipe != null && this.output == null && this.cachedRecipe.isHotEnough(this.temperature);` |
| 预热判定 | `PotBlockEntity.java:85`、`:221-223` | `public static final int PRE_BOIL_TIME = 100;`、`hasRecipeStarted() => isBoiling() && preBoilingTicks >= 100` |
| 每 tick 推进 | `PotBlockEntity.java:140-177`（`handleCooking`） | 先累计 `preBoilingTicks` 到 100，再累加 `boilingTicks` 到 `cachedRecipe.getDuration()` |
| 结算 | `PotBlockEntity.java:154-171` | `RecipeHelpers.setCraftingInput(...)` → `recipe.getOutput((IPotInventory)this.inventory)` → `RecipeHelpers.clearCraftingInput()` → 输入槽替换为 `getCraftingRemainingItem()` → `output.onFinish(...)` → `if (!output.isEmpty()) this.output = output;` → 重置计数并 `updateCachedRecipe()` |
| 取走产物 | `PotBlockEntity.java:233-248` | `interactWithOutput(player, stack)` → `this.output.onInteract(...)`；产物空后 `this.output = null` |
| 菜单 | `PotBlockEntity.java:250-254` | `createMenu(...)` → `PotContainer.create(this, playerInv, windowID)`（`net/dries007/tfc/common/container/PotContainer.java:25-66`） |
| 界面 | `net/dries007/tfc/client/screen/PotScreen.java:43-47`、`net/dries007/tfc/client/ClientEventHandler.java:585` | `ClientEventHandler` 注册 `TFCContainerTypes.POT` → `PotScreen::new` |

**必须强调的一点**：`PotBlockEntity` 用的是 `getRecipeFor(TFCRecipeTypes.POT.get(), ...)`，即**只查 `tfc:pot` 这一个 recipe type**。由于 `SoupPotRecipe`/`JamPotRecipe` 的 `getType()` 也返回 `TFCRecipeTypes.POT`，它们与 `SimplePotRecipe` 处在**同一个类型桶**里，`getRecipeFor` 会按 `RecipeManager` 的遍历顺序返回**第一个 `matches` 成功的配方**。这意味着：

- 若一个锅状态同时匹配多条 pot 类配方，实际生效的是加载顺序中的第一条（TFC 自带数据通过让流体量/物品组合互斥来避免冲突）。
- `tfc:pot_soup`（`data/tfc/recipe/pot/soup_3.json` 等）与 `tfc:pot_jam` 配方也是通过这条路径被匹配到的，**没有任何按 serializer 分流的逻辑**（JEI/EMI 里的 serializer 判据仅用于展示分类）。

火源与温度：`PotBlockEntity extends AbstractFirepitBlockEntity`（`PotBlockEntity.java:81-82`），温度来自火坑燃烧的燃料（`burnTemperature`，`PotBlockEntity.java:183`），因此 `temperature: 600.0` 的配方需要能烧到 600 以上的燃料。此外 `PotBlockEntity.java:180-202` 的 `onCalendarUpdate` 处理「时间跳跃」（睡眠/离线）时的批量推进。

##### R-18.5 输入容器：`IPotInventory` 与槽位映射

接口定义（`net/dries007/tfc/common/blockentities/IPotInventory.java:10-19`）：

```java
public interface IPotInventory extends NonEmptyInput, DelegateItemHandler, DelegateFluidHandler {
    void clearFluid();
    int inputStart();
    int inputEnd();
}
```

实现（`PotBlockEntity.PotInventory`，`PotBlockEntity.java:256-320`）：

| 成员 | 值 | 证据 |
| --- | --- | --- |
| 物品槽总数 | 9（`new InventoryItemHandler(entity, 9)`） | `PotBlockEntity.java:265` |
| `inputStart()` | `4` | `PotBlockEntity.java:269-272` |
| `inputEnd()` | `8` | `PotBlockEntity.java:274-277` |
| 槽 0~3 | 燃料（`FIREPIT_FUEL`），`PotContainer.moveStack` 优先放入 | `PotContainer.java:41-46`、`PotContainer.java:58-60` |
| 槽 4~8 | 配方输入/输出（每个槽上限 1 个物品） | `PotBlockEntity.java:130-133`（`getSlotStackLimit => 1`）、`PotContainer.java:61-65` |
| 流体箱 | `new FluidTank(1000, this::canInsertFluid)`，容量 **1000 mB** | `PotBlockEntity.java:266` |
| 流体插入限制 | `pot.output == null && Helpers.isFluid(fluid, TFCTags.Fluids.USABLE_IN_POT)` | `PotBlockEntity.java:317-319` |
| `NonEmptyInput` 语义 | `isEmpty()` 恒返回 `false`、`size()` 返回 `0`、`getItem(i)` 返回空 —— 这是为了让 `RecipeInput` 契约不阻塞匹配 | `net/dries007/tfc/common/recipes/input/NonEmptyInput.java:13-26` |

**与 JSON 数值的对应关系**：
- `fluid_ingredient.amount` 不能超过箱容量 1000（实际 TFC 数据中最大值为 1000）。
- 输入物品最多 5 个 → `ingredients` 最多 5 项（与 `listOf(0, 5)` 一致）。
- 输出写回槽 4~8：`inventory.setStackInSlot(inventory.inputStart() + i, this.itemOutputs.get(i))`（`SimplePotRecipe.java:99-102`）；随后 `clearFluid()` 并 `fill(fluidOutput)`（`SimplePotRecipe.java:103-104`）。

代码侧还有一处一致性自检：`net/dries007/tfc/util/SelfTests.java:303-306` 会检查所有 pot 配方（含 soup/jam，因为都在 `TFCRecipeTypes.POT` 下）的输入流体是否都在 `tfc:usable_in_pot` tag 中：

```java
private static boolean validatePotFluidUsability(RecipeManager manager) {
    Set<Fluid> errors = manager.getAllRecipesFor(TFCRecipeTypes.POT.get()).stream()
        .flatMap(recipe -> RecipeHelpers.stream(((PotRecipe)recipe.value()).getFluidIngredient()))
        .filter(fluid -> !Helpers.isFluid(fluid, TFCTags.Fluids.USABLE_IN_POT))
        .collect(Collectors.toSet());
    return SelfTests.logErrors("{} fluids are listed in pot recipes that are not tagged as tfc:usable_in_pot", errors, LOGGER);
}
```

即：**自定义 pot 配方必须把 `fluid_ingredient` 指向 `tfc:usable_in_pot` tag 内的流体**，否则日志报错。

##### R-18.6 TFC 自带 145 个 `tfc:pot` 配方的取值统计

以下统计来自逐文件解析 `jar-extract/data/tfc/recipe/pot/**`（130 顶层 + 15 `food/`）。

`duration` 分布：

| duration | 数量 | 备注 |
| --- | --- | --- |
| 300 | 110 | 全部是 `*_canning_*.json`（罐装） |
| 1200 | 15 | 全部是 `food/` 下的煮蛋/煮扁豆/煮饭 |
| 2400 | 20 | 染料、碱液、油脂、板油等流体产出型 |

`temperature` 分布：

| temperature | 数量 | 备注 |
| --- | --- | --- |
| 300.0 | 127 | 食物类、罐装、`canola_oil_water` |
| 600.0 | 18 | 染料（16 色）、`lye`、`tallow` 等需要高温 |

`fluid_ingredient.fluid` 分布：**全部 145 个都是 `minecraft:water`**（0 个使用 tag 形式，0 个使用其他流体）。

`fluid_ingredient.amount` 分布：

| amount | 数量 |
| --- | --- |
| 100 | 37 |
| 200 | 22 |
| 300 | 22 |
| 400 | 22 |
| 500 | 22 |
| 1000 | 20 |

`fluid_output` 分布：**125 个没有 `fluid_output`**；20 个有，且全部是 `amount: 1000`，流体为 16 种染料 + `tfc:lye` + `tfc:canola_oil_water` + `tfc:olive_oil_water` + `tfc:tallow`。

`uses_all_fluid` 分布：**110 个显式写 `false`**（全部 canning），35 个未声明（⇒ 默认 `true`）。

`item_output`：**125 个有 `item_output`**（含 15 个 `food/`、110 个 canning）；20 个流体产出型没有。

##### R-18.7 文件清单（145 个）

顶层 `data/tfc/recipe/pot/`（130 个 `tfc:pot`）：

- **110 个罐装**：`jam_<fruit>_canning_1..5.json`，`<fruit>` ∈ {`banana`, `blackberry`, `blueberry`, `bunchberry`, `cherry`, `cloudberry`, `cranberry`, `elderberry`, `gooseberry`, `green_apple`, `lemon`, `melon_slice`, `olive`, `orange`, `peach`, `peanut`, `plum`, `raspberry`, `red_apple`, `snowberry`, `strawberry`, `wintergreen_berry`}（22 种 × 5 = 110）。
- **20 个流体产出型**：`black_dye.json`、`blue_dye.json`、`brown_dye.json`、`cyan_dye.json`、`gray_dye.json`、`green_dye.json`、`light_blue_dye.json`、`light_gray_dye.json`、`lime_dye.json`、`magenta_dye.json`、`orange_dye.json`、`pink_dye.json`、`purple_dye.json`、`red_dye.json`、`white_dye.json`、`yellow_dye.json`、`lye.json`、`tallow.json`、`canola_oil_water.json`、`olive_oil_water.json`。

子目录 `data/tfc/recipe/pot/food/`（15 个 `tfc:pot`）：`boiled_egg_1..5.json`、`cooked_lentil_1..5.json`、`cooked_rice_1..5.json`。

##### R-18.8 R-18 小结与易错点

1. `type` 与 recipe type 同名（都是 `tfc:pot`），但它**不是**「物品→物品」的简单烹饪配方，而是「物品 + 流体」的通用锅煮配方。
2. `fluid_ingredient` **必填**，且必须是 `tfc:usable_in_pot` 内的流体（SelfTests 会报错）。
3. `duration` 是 tick；`temperature` 是**最低阈值**且为**严格大于**判定。
4. `item_output` 的数量不必须等于 `ingredients`，**除非**输出里有依赖输入的 provider（R-18.2.4）。
5. `uses_all_fluid` 默认 `true`；设为 `false` 时配合「输入流体量 > 消耗量」可产出"剩余输入流体"（TFC 数据里 canning 用 `false` 来消耗定量的水同时保留原有内容）。
6. 不存在 `pot_output` 字段（见附录 A4-1）。

---

### [R-19] tfc:pot_soup —— 锅煮汤配方

##### R-19.1 类型标识与实现类

| 项目 | 值 | 证据 |
| --- | --- | --- |
| JSON `type` | `tfc:pot_soup` | `net/dries007/tfc/common/recipes/TFCRecipeSerializers.java:65` |
| recipe type id | **`tfc:pot`**（`TFCRecipeTypes` 中**没有** `pot_soup` 注册项） | `TFCRecipeTypes.java:44-63` 全表无 `pot_soup`；`SoupPotRecipe` 未覆盖 `getType()`，继承 `PotRecipe.java:83-85` 的 `return TFCRecipeTypes.POT.get();` |
| serializer id | `tfc:pot_soup` | `TFCRecipeSerializers.java:65` |
| 实现类全名 | `net.dries007.tfc.common.recipes.SoupPotRecipe` | `net/dries007/tfc/common/recipes/SoupPotRecipe.java:51` |
| 父类 | `PotRecipe` | `SoupPotRecipe.java:52`（`extends PotRecipe`） |
| `getSerializer()` 返回值 | `TFCRecipeSerializers.POT_SOUP.get()` | `SoupPotRecipe.java:121-124` |
| 输入容器 | `IPotInventory`（与 R-18 相同） | `PotRecipe.java:47` |
| 产物产出方式 | **完全由代码计算**，JSON 中**没有任何产物字段** | `SoupPotRecipe.java:70-119` |

**逐行核实「recipe type 名与 serializer 名对应关系」的过程（任务要求）**：

1. `TFCRecipeTypes.java` 全文 78 行，`register(...)` 调用点共 20 处（第 44~63 行），**不存在** `"pot_soup"`、`"pot_jam"`、`"food_combining"` 字符串。
2. `SoupPotRecipe.java` 全文 168 行，**只有** `getSerializer()`（第 121-124 行），**没有** `getType()`。
3. 因此 `SoupPotRecipe.getType()` 解析到父类 `PotRecipe.java:83-85` 的 `return (RecipeType)TFCRecipeTypes.POT.get();`。
4. 结论：`tfc:pot_soup` 的 **serializer 名 = `pot_soup`**，**recipe type 名 = `pot`**，二者不一致。

##### R-19.2 完整字段表

` SoupPotRecipe.CODEC` 是父类 codec 的直接 `xmap`（`SoupPotRecipe.java:53`）：

```java
public static final MapCodec<SoupPotRecipe> CODEC = PotRecipe.CODEC.xmap(SoupPotRecipe::new, Function.identity());
```

因此**字段与父类 `PotRecipe` 完全相同，一个不多一个不少**：

| 字段名 | 类型 | 必需/可选 | 默认值 | 语义 | 证据 |
| --- | --- | --- | --- | --- | --- |
| `ingredients` | `Ingredient` 列表（0~5） | **必需** | 无（允许 `[]`） | 汤的食材。实际语义上必须都是**食物**（见 R-19.3），TFC 数据用 `tfc:and` 组合 `tfc:usable_in_soup` tag 与 `tfc:not_rotten` | `PotRecipe.java:48`；`SoupPotRecipe.java:53`（继承） |
| `fluid_ingredient` | `SizedFluidIngredient`（扁平形式） | **必需** | 无 | 锅内流体输入（汤一律用水） | `PotRecipe.java:48`；`SoupPotRecipe.java:53` |
| `duration` | `int`（tick） | **必需** | 无 | 煮沸时长；TFC 数据固定 1200 | `PotRecipe.java:48`；`SoupPotRecipe.java:53` |
| `temperature` | `float` | **必需** | 无 | 最低温度阈值（严格大于）；TFC 数据固定 300.0 | `PotRecipe.java:48`、`PotRecipe.java:99-101` |

**没有** `fluid_output`、`item_output`、`uses_all_fluid` —— 这些是 `SimplePotRecipe` 专有字段，写在 `pot_soup` 配方里会被 codec 忽略（不会报错，因为 `RecordCodecBuilder` 默认不校验未知字段；但不会有任何效果）。

`SoupPotRecipe` 自身的**非 JSON 字段**常量（供参考，来自代码而非 JSON）：

| 名称 | 值 | 证据 |
| --- | --- | --- |
| `SOUP_HUNGER_VALUE` | `4` | `SoupPotRecipe.java:59` |
| `SOUP_DECAY_MODIFIER` | `3.5f` | `SoupPotRecipe.java:60` |
| `ingredientsToServings(int)` | `(int)(ingredientCount / 2.0f) + 1` | `SoupPotRecipe.java:62-64` |
| `OUTPUT_TYPE`（`PotOutput.OutputType`） | 从 NBT 读回 `SoupOutput` | `SoupPotRecipe.java:55-58` |

##### R-19.3 产物如何确定（没有 JSON 字段，全在代码里）

`SoupPotRecipe.getOutput(IPotInventory)`（`SoupPotRecipe.java:70-119`）逐行语义：

1. `inventory.clearFluid();` —— 先把锅里的水清空。
2. 遍历输入槽 4~8，对每个有 `FoodCapability.get(stack)`（即带 `IFood` 组件）的物品：
   - 若 `food.isRotten()` → `ingredientCount = 0` 并 `break`（**只要有一份腐烂食材，整锅汤报废**）。
   - 否则累加 `water`、`saturation`、各 `Nutrient` 营养值，并 `++ingredientCount`。
3. 若 `ingredientCount > 0`：
   - `outputCount = ingredientsToServings(ingredientCount) = ingredientCount/2 + 1`；
   - `multiplier = 1.2f / outputCount`；
   - `water = 20 + extraWater * multiplier`、`saturation = 2 + extraSaturation * multiplier`；
   - 取营养值最高的 `Nutrient` 决定汤的种类：`TFCItems.SOUPS.get(maxNutrient)`；
   - 给产物写入 `TFCComponents.INGREDIENTS`（`ItemListComponent.of(itemIngredients)`）与食物数据 `new FoodData(4, water, saturation, 0, nutrition, 3.5f)`。
4. 返回 `new SoupOutput(soupStack)`。

补充：`tfc:not_rotten` 是 TFC 自定义 `IngredientType`（`net/dries007/tfc/common/recipes/ingredients/NotRottenIngredient.java:22-46`），匹配时 `!FoodCapability.isRotten(stack)`；而 `getOutput` 里又独立做了腐烂检查（因此即使食材在入锅后腐烂也会作废整锅）。

##### R-19.4 真实 JSON 样例（全部 3 个，逐字读取）

###### 样例 1：`jar-extract/data/tfc/recipe/pot/soup_3.json`

```json
{"type":"tfc:pot_soup","duration":1200,"fluid_ingredient":{"amount":100,"fluid":"minecraft:water"},"ingredients":[{"type":"tfc:and","children":[{"tag":"tfc:usable_in_soup"},{"type":"tfc:not_rotten"}]},{"type":"tfc:and","children":[{"tag":"tfc:usable_in_soup"},{"type":"tfc:not_rotten"}]},{"type":"tfc:and","children":[{"tag":"tfc:usable_in_soup"},{"type":"tfc:not_rotten"}]}],"temperature":300.0}
```

###### 样例 2：`jar-extract/data/tfc/recipe/pot/soup_4.json`

```json
{"type":"tfc:pot_soup","duration":1200,"fluid_ingredient":{"amount":100,"fluid":"minecraft:water"},"ingredients":[{"type":"tfc:and","children":[{"tag":"tfc:usable_in_soup"},{"type":"tfc:not_rotten"}]},{"type":"tfc:and","children":[{"tag":"tfc:usable_in_soup"},{"type":"tfc:not_rotten"}]},{"type":"tfc:and","children":[{"tag":"tfc:usable_in_soup"},{"type":"tfc:not_rotten"}]},{"type":"tfc:and","children":[{"tag":"tfc:usable_in_soup"},{"type":"tfc:not_rotten"}]}],"temperature":300.0}
```

###### 样例 3：`jar-extract/data/tfc/recipe/pot/soup_5.json`

```json
{"type":"tfc:pot_soup","duration":1200,"fluid_ingredient":{"amount":100,"fluid":"minecraft:water"},"ingredients":[{"type":"tfc:and","children":[{"tag":"tfc:usable_in_soup"},{"type":"tfc:not_rotten"}]},{"type":"tfc:and","children":[{"tag":"tfc:usable_in_soup"},{"type":"tfc:not_rotten"}]},{"type":"tfc:and","children":[{"tag":"tfc:usable_in_soup"},{"type":"tfc:not_rotten"}]},{"type":"tfc:and","children":[{"tag":"tfc:usable_in_soup"},{"type":"tfc:not_rotten"}]},{"type":"tfc:and","children":[{"tag":"tfc:usable_in_soup"},{"type":"tfc:not_rotten"}]}],"temperature":300.0}
```

三个文件的差异**仅在于 `ingredients` 的元素个数**（3 / 4 / 5），其余字段完全相同（`duration: 1200`、`fluid_ingredient: {amount:100, fluid:"minecraft:water"}`、`temperature: 300.0`）。

| 文件 | `ingredients` 个数 | 依据代码算出的份数（`count/2+1`） |
| --- | --- | --- |
| `soup_3.json` | 3 | 2 |
| `soup_4.json` | 4 | 3 |
| `soup_5.json` | 5 | 3 |

> 说明：份数公式 `ingredientsToServings(n) = (int)(n/2.0f) + 1`（`SoupPotRecipe.java:62-64`）代入得 `n=3 → 2`、`n=4 → 3`、`n=5 → 3`（`5/2.0 = 2.5`，取整为 2，再加 1）。

##### R-19.5 游戏内触发条件

与 R-18 **完全相同**：`PotBlockEntity.updateCachedRecipe()` 用 `TFCRecipeTypes.POT` 检索（`PotBlockEntity.java:212-215`），`handleCooking()` 结算（`PotBlockEntity.java:154-171`），因为 `SoupPotRecipe.getType()` 返回的就是 `TFCRecipeTypes.POT`。

`soup_3/4/5.json` 三者在同一类型桶中并存，靠 `ingredients` 长度与完美匹配算法区分（不同数量的食材落入不同配方）。JEI 侧把 `serializer == POT_SOUP` 的配方单独展示（`JEIIntegration.java:214`），但这只是展示分类。

产物交互：`SoupOutput.onInteract` 允许用 `TFCTags.Items.SOUP_BOWLS` 内的碗取汤（`SoupPotRecipe.java:133-142`）：

```java
public ItemInteractionResult onInteract(IPotInventory entity, Player player, ItemStack clickedWith) {
    if (Helpers.isItem(clickedWith.getItem(), TFCTags.Items.SOUP_BOWLS) && !this.stack.isEmpty()) {
        this.stack.set(TFCComponents.BOWL, Bowl.of(clickedWith));
        clickedWith.shrink(1);
        ItemHandlerHelper.giveItemToPlayer(player, this.stack.split(1));
        return ItemInteractionResult.sidedSuccess(player.level().isClientSide);
    }
    return ItemInteractionResult.PASS_TO_DEFAULT_BLOCK_INTERACTION;
}
```

##### R-19.6 R-19 小结

- `tfc:pot_soup` **没有独立 recipe type**，挂在 `tfc:pot` 上。
- JSON 字段 = `PotRecipe` 的 4 个字段，**无产物字段**。
- 汤的种类、份数、营养全部由 `SoupPotRecipe.getOutput` 在运行时按锅内食材计算。
- 3 个内置配方靠 `ingredients` 长度（3/4/5）区分。

---

### [R-20] tfc:pot_jam —— 锅煮果酱 / 罐装配方

##### R-20.1 类型标识与实现类

| 项目 | 值 | 证据 |
| --- | --- | --- |
| JSON `type` | `tfc:pot_jam` | `net/dries007/tfc/common/recipes/TFCRecipeSerializers.java:66` |
| recipe type id | **`tfc:pot`**（无 `pot_jam` 注册项） | `TFCRecipeTypes.java:44-63` 无 `pot_jam`；`JamPotRecipe` 未覆盖 `getType()`，继承 `PotRecipe.java:83-85` |
| serializer id | `tfc:pot_jam` | `TFCRecipeSerializers.java:66` |
| 实现类全名 | `net.dries007.tfc.common.recipes.JamPotRecipe` | `net/dries007/tfc/common/recipes/JamPotRecipe.java:49` |
| 父类 | `PotRecipe` | `JamPotRecipe.java:50` |
| `getSerializer()` 返回值 | `TFCRecipeSerializers.POT_JAM.get()` | `JamPotRecipe.java:85-88` |
| 输入容器 | `IPotInventory` | `PotRecipe.java:47` |

核实过程同 R-19.1：`JamPotRecipe.java` 全文 145 行，只有 `getSerializer()`（第 85-88 行），**无** `getType()`，故 recipe type 为 `tfc:pot`。

##### R-20.2 完整字段表

自身 `CODEC` 源码（`JamPotRecipe.java:51`）：

```java
public static final MapCodec<JamPotRecipe> CODEC = RecordCodecBuilder.mapCodec(i -> i.group(
    PotRecipe.CODEC.forGetter(c -> c),                                              // 继承的 4 字段
    ItemStack.CODEC.fieldOf("unsealed_result").forGetter(c -> c.jarredStack),
    ItemStack.CODEC.fieldOf("sealed_result").forGetter(c -> c.jarredStackWithLid),
    ResourceLocation.CODEC.fieldOf("texture").forGetter(c -> c.texture)
).apply(i, JamPotRecipe::new));
```

| 字段名 | 类型 | 必需/可选 | 默认值 | 语义 | 来源类 | 证据 |
| --- | --- | --- | --- | --- | --- | --- |
| `ingredients` | `Ingredient` 列表（0~5） | **必需** | 无（允许 `[]`） | 物品输入；果酱配方用 `n` 份水果 + 1 份甜味剂（`tfc:foods/sweeteners` tag）的**完美匹配** | `PotRecipe` | `PotRecipe.java:48`；`JamPotRecipe.java:51` |
| `fluid_ingredient` | `SizedFluidIngredient`（扁平形式） | **必需** | 无 | 流体输入；TFC 数据固定 `{amount:100, fluid:"minecraft:water"}` | `PotRecipe` | `PotRecipe.java:48` |
| `duration` | `int`（tick） | **必需** | 无 | 煮沸时长；TFC 数据固定 `500` | `PotRecipe` | `PotRecipe.java:48` |
| `temperature` | `float` | **必需** | 无 | 最低温度阈值（严格大于）；TFC 数据固定 `300.0` | `PotRecipe` | `PotRecipe.java:48`、`:99-101` |
| `unsealed_result` | `ItemStack`（`{"id":"...","count":N}`） | **必需**（`fieldOf`） | 无 | **未封盖**果酱罐产物（`tfc:jar/<fruit>_unsealed`） | `JamPotRecipe` | `JamPotRecipe.java:51`；字段声明 `:59` |
| `sealed_result` | `ItemStack` | **必需** | 无 | **已封盖**果酱罐产物（`tfc:jar/<fruit>`） | `JamPotRecipe` | `JamPotRecipe.java:51`；字段声明 `:60` |
| `texture` | `ResourceLocation` | **必需** | 无 | 锅内液体渲染贴图（如 `tfc:block/jar/banana`），用于 `getRenderTexture()` | `JamPotRecipe` | `JamPotRecipe.java:51`；字段声明 `:61` |

**没有** `fluid_output` / `item_output` / `uses_all_fluid`（它们是 `SimplePotRecipe` 专有）。`JamPotRecipe` **没有任何可选字段**，也没有 `.validate(...)`。

四个父类字段 + 三个自身字段，**全部为必需**（`JamPotRecipe` 的 CODEC 里没有任何 `optionalFieldOf`）。

`getResultItem` 返回 `jarredStackWithLid`（`JamPotRecipe.java:70-73`），即封盖产物 —— 这是 JEI/Patchouli 展示用的"代表产物"。

##### R-20.3 产物语义

`JamPotRecipe.getOutput`（`JamPotRecipe.java:79-83`）：

```java
public PotOutput getOutput(IPotInventory inventory) {
    inventory.clearFluid();
    return new JamOutput(this.jarredStack.copy(), this.jarredStackWithLid.copy(), this.texture);
}
```

`JamOutput`（`JamPotRecipe.java:90-143`）的关键行为：

| 方法 | 行为 | 证据 |
| --- | --- | --- |
| `isEmpty()` | `unsealedStack.isEmpty() \|\| sealedStack.isEmpty()` —— 两者任一为空即视为"无产物" | `:92-95` |
| `onInteract(...)` | 用 `tfc:empty_jar`（`TFCItems.EMPTY_JAR`）点击 → 取走 1 个 `unsealedStack`；用 `TFCTags.Items.EMPTY_JARS_WITH_LID` 点击 → 取走 1 个 `sealedStack`；两种取走后都会扣减另一种的 1 个 | `:97-112` |
| `getRenderTexture()` | 返回 JSON 的 `texture` | `:114-117` |
| `getFluidYLevel()` | 按 `unsealedStack.getCount()` 在 0~4 映射到 0.4375~0.625 | `:119-122` |
| `write(provider, nbt)` | 写入 NBT 键 `unsealed_result`、`sealed_result`、`texture`（**这是方块实体 NBT，不是配方 JSON**） | `:124-129` |
| `getType()` | `JamPotRecipe.OUTPUT_TYPE`（注册为 `tfc:pot_output` 注册表中的 `jam`） | `:131-134` |

##### R-20.4 真实 JSON 样例

TFC 自带的 66 个 `tfc:pot_jam` 全部是"果酱合成"，`duration` 全为 `500`、`temperature` 全为 `300.0`、`fluid_ingredient` 全为 `{amount:100, fluid:"minecraft:water"}`。

###### 样例 1：2 份水果 + 1 份甜味剂 → 2 罐

相对路径：`jar-extract/data/tfc/recipe/pot/jam_banana_2.json`

```json
{"type":"tfc:pot_jam","duration":500,"fluid_ingredient":{"amount":100,"fluid":"minecraft:water"},"ingredients":[{"type":"tfc:and","children":[{"item":"tfc:food/banana"},{"type":"tfc:not_rotten"}]},{"type":"tfc:and","children":[{"item":"tfc:food/banana"},{"type":"tfc:not_rotten"}]},{"tag":"tfc:foods/sweeteners"}],"sealed_result":{"count":2,"id":"tfc:jar/banana"},"temperature":300.0,"texture":"tfc:block/jar/banana","unsealed_result":{"count":2,"id":"tfc:jar/banana_unsealed"}}
```

结构特征：3 个 `ingredients` 中前 2 个是水果（`tfc:and` 组合具体物品 + `tfc:not_rotten`），第 3 个直接是 tag `tfc:foods/sweeteners`（原版 `Ingredient` 的 tag 形式，无需 `type`）；`sealed_result`/`unsealed_result` 的 `count` 均为 2，与水果份数一致。

###### 样例 2：4 份水果 + 1 份甜味剂 → 4 罐

相对路径：`jar-extract/data/tfc/recipe/pot/jam_strawberry_4.json`

```json
{"type":"tfc:pot_jam","duration":500,"fluid_ingredient":{"amount":100,"fluid":"minecraft:water"},"ingredients":[{"type":"tfc:and","children":[{"item":"tfc:food/strawberry"},{"type":"tfc:not_rotten"}]},{"type":"tfc:and","children":[{"item":"tfc:food/strawberry"},{"type":"tfc:not_rotten"}]},{"type":"tfc:and","children":[{"item":"tfc:food/strawberry"},{"type":"tfc:not_rotten"}]},{"type":"tfc:and","children":[{"item":"tfc:food/strawberry"},{"type":"tfc:not_rotten"}]},{"tag":"tfc:foods/sweeteners"}],"sealed_result":{"count":4,"id":"tfc:jar/strawberry"},"temperature":300.0,"texture":"tfc:block/jar/strawberry","unsealed_result":{"count":4,"id":"tfc:jar/strawberry_unsealed"}}
```

###### 样例 3：3 份水果 + 1 份甜味剂 → 3 罐（`wintergreen_berry`）

相对路径：`jar-extract/data/tfc/recipe/pot/jam_wintergreen_berry_3.json`

```json
{"type":"tfc:pot_jam","duration":500,"fluid_ingredient":{"amount":100,"fluid":"minecraft:water"},"ingredients":[{"type":"tfc:and","children":[{"item":"tfc:food/wintergreen_berry"},{"type":"tfc:not_rotten"}]},{"type":"tfc:and","children":[{"item":"tfc:food/wintergreen_berry"},{"type":"tfc:not_rotten"}]},{"type":"tfc:and","children":[{"item":"tfc:food/wintergreen_berry"},{"type":"tfc:not_rotten"}]},{"tag":"tfc:foods/sweeteners"}],"sealed_result":{"count":3,"id":"tfc:jar/wintergreen_berry"},"temperature":300.0,"texture":"tfc:block/jar/wintergreen_berry","unsealed_result":{"count":3,"id":"tfc:jar/wintergreen_berry_unsealed"}}
```

###### 样例 4（对照）：同目录下的**非** jam 配方 —— `tfc:pot` 罐装

相对路径：`jar-extract/data/tfc/recipe/pot/jam_banana_canning_2.json`

```json
{"type":"tfc:pot","duration":300,"fluid_ingredient":{"amount":200,"fluid":"minecraft:water"},"ingredients":[{"type":"tfc:and","children":[{"item":"tfc:jar/banana"},{"type":"tfc:lacks_trait","trait":"tfc:canned"},{"type":"tfc:not_rotten"}]},{"type":"tfc:and","children":[{"item":"tfc:jar/banana"},{"type":"tfc:lacks_trait","trait":"tfc:canned"},{"type":"tfc:not_rotten"}]}],"item_output":[{"modifiers":[{"type":"tfc:copy_input"},{"type":"tfc:add_trait","trait":"tfc:canned"}]},{"modifiers":[{"type":"tfc:copy_input"},{"type":"tfc:add_trait","trait":"tfc:canned"}]}],"temperature":300.0,"uses_all_fluid":false}
```

> **易混淆点**：文件名以 `jam_` 开头的 `*_canning_*.json` **不是** `tfc:pot_jam`，而是 `tfc:pot`（`SimplePotRecipe`）。判断依据只能是 JSON 内的 `type` 字段，不能看文件名。

##### R-20.5 66 个 `tfc:pot_jam` 文件清单

全部位于 `data/tfc/recipe/pot/`：

```
jam_banana_2.json, jam_banana_3.json, jam_banana_4.json,
jam_blackberry_2.json, jam_blackberry_3.json, jam_blackberry_4.json,
jam_blueberry_2.json, jam_blueberry_3.json, jam_blueberry_4.json,
jam_bunchberry_2.json, jam_bunchberry_3.json, jam_bunchberry_4.json,
jam_cherry_2.json, jam_cherry_3.json, jam_cherry_4.json,
jam_cloudberry_2.json, jam_cloudberry_3.json, jam_cloudberry_4.json,
jam_cranberry_2.json, jam_cranberry_3.json, jam_cranberry_4.json,
jam_elderberry_2.json, jam_elderberry_3.json, jam_elderberry_4.json,
jam_gooseberry_2.json, jam_gooseberry_3.json, jam_gooseberry_4.json,
jam_green_apple_2.json, jam_green_apple_3.json, jam_green_apple_4.json,
jam_lemon_2.json, jam_lemon_3.json, jam_lemon_4.json,
jam_melon_slice_2.json, jam_melon_slice_3.json, jam_melon_slice_4.json,
jam_olive_2.json, jam_olive_3.json, jam_olive_4.json,
jam_orange_2.json, jam_orange_3.json, jam_orange_4.json,
jam_peach_2.json, jam_peach_3.json, jam_peach_4.json,
jam_peanut_2.json, jam_peanut_3.json, jam_peanut_4.json,
jam_plum_2.json, jam_plum_3.json, jam_plum_4.json,
jam_raspberry_2.json, jam_raspberry_3.json, jam_raspberry_4.json,
jam_red_apple_2.json, jam_red_apple_3.json, jam_red_apple_4.json,
jam_snowberry_2.json, jam_snowberry_3.json, jam_snowberry_4.json,
jam_strawberry_2.json, jam_strawberry_3.json, jam_strawberry_4.json,
jam_wintergreen_berry_2.json, jam_wintergreen_berry_3.json, jam_wintergreen_berry_4.json
```

共 **22 种水果 × 3 档份数（2/3/4）= 66** 个文件。命名规律：

- `jam_<fruit>_N.json` 中 `N` = 水果份数 = 产物罐数（`sealed_result.count` = `unsealed_result.count` = `N`）。
- 对应的罐装配方为 `jam_<fruit>_canning_N.json`（`tfc:pot`，`N` 从 1 到 5，共 5 档）。

##### R-20.6 游戏内触发条件

与 R-18/R-19 一致：`PotBlockEntity` 通过 `TFCRecipeTypes.POT` 检索并结算（`PotBlockEntity.java:212-215`、`:154-171`）。

取产物必须借助空罐（`JamOutput.onInteract`，`JamPotRecipe.java:97-112`）：
- `tfc:empty_jar` → 取 `unsealed_result` 产物；
- tag `tfc:empty_jars_with_lid` 内的物品 → 取 `sealed_result` 产物。

JEI 展示分类：`registry.addRecipes(JAM_POT, JEIIntegration.recipes(TFCRecipeTypes.POT, recipe -> recipe.getSerializer() == TFCRecipeSerializers.POT_JAM.get()))`（`JEIIntegration.java:216`）；点击区域绑定 `registry.addRecipeClickArea(PotScreen.class, 77, 6, 9, 14, new RecipeType[]{SIMPLE_POT, SOUP_POT, JAM_POT})`（`JEIIntegration.java:286`）。

##### R-20.7 R-20 小结

- `tfc:pot_jam` 无独立 recipe type，挂在 `tfc:pot`。
- 7 个字段全部必需：4 个继承自 `PotRecipe` + `unsealed_result`、`sealed_result`、`texture`。
- 无 `.validate(...)`。
- 与 `tfc:pot` 的 canning 配方**同目录、同前缀**，只能用 `type` 字段区分。

---

### [R-21] tfc:loom —— 织布机配方

##### R-21.1 类型标识与实现类

| 项目 | 值 | 证据 |
| --- | --- | --- |
| JSON `type` | `tfc:loom` | `net/dries007/tfc/common/recipes/TFCRecipeSerializers.java:74` |
| recipe type id | `tfc:loom` | `net/dries007/tfc/common/recipes/TFCRecipeTypes.java:54` |
| serializer id | `tfc:loom` | `TFCRecipeSerializers.java:74` |
| 实现类全名 | `net.dries007.tfc.common.recipes.LoomRecipe` | `net/dries007/tfc/common/recipes/LoomRecipe.java:48` |
| 实现的接口 | `INoopInputRecipe`、`IRecipePredicate<ItemStack>` | `LoomRecipe.java:49-50` |
| 接口链 | `INoopInputRecipe extends ISimpleRecipe<NoopInput>` → `Recipe<NoopInput>` | `net/dries007/tfc/common/recipes/INoopInputRecipe.java:21-22`、`ISimpleRecipe.java:17-18` |
| `getType()` 返回值 | `TFCRecipeTypes.LOOM.get()` | `LoomRecipe.java:105-107` |
| `getSerializer()` 返回值 | `TFCRecipeSerializers.LOOM.get()` | `LoomRecipe.java:101-103` |
| 是否 special | `isSpecial() => result.dependsOnInput()` | `LoomRecipe.java:109-112` |
| 索引缓存 | `CACHE = IndirectHashCollection.createForRecipe(r -> RecipeHelpers.itemKeys(r.ingredient.ingredient()), TFCRecipeTypes.LOOM)` | `LoomRecipe.java:51` |

**type 名与 serializer 名一致**，不存在不一致问题。

##### R-21.2 完整字段表

自身 `CODEC` 源码（`LoomRecipe.java:52`）：

```java
public static final MapCodec<LoomRecipe> CODEC = RecordCodecBuilder.mapCodec(i -> i.group(
    SizedIngredient.FLAT_CODEC.fieldOf("ingredient").forGetter(c -> c.ingredient),
    ItemStackProvider.CODEC.fieldOf("result").forGetter(c -> c.result),
    Codec.INT.fieldOf("steps").forGetter(c -> c.steps),
    ResourceLocation.CODEC.fieldOf("texture").forGetter(c -> c.inProgressTexture)
).apply(i, LoomRecipe::new));
```

| 字段名 | 类型 | 必需/可选 | 默认值 | 语义 | 证据 |
| --- | --- | --- | --- | --- | --- |
| `ingredient` | `SizedIngredient`（NeoForge 扁平形式：`{"item":"...","count":N}` 或 `{"tag":"...","count":N}`） | **必需** | 无 | 织布机消耗的原料与数量。`count` 决定 `getInputCount()`，进而决定槽 0 的堆叠上限 | `LoomRecipe.java:52`；字段声明 `:54`；`getInputCount() => ingredient.count()`（`:84-86`） |
| `result` | `ItemStackProvider`（**必填**，无默认） | **必需** | 无 | 产物。可写纯 `ItemStack`（`{"id":"...","count":N}`）或带 `modifiers` 的 provider | `LoomRecipe.java:52`；字段声明 `:55`；`getResultItem => result.getEmptyStack()`（`:96-99`） |
| `steps` | `int` | **必需** | 无 | 需要推进的次数。每次有效推进（手动右键 / 动力织机旋转）进度 +1，达到 `steps` 时产出 | `LoomRecipe.java:52`；字段声明 `:56`；`getStepCount()`（`:92-94`）；判定 `LoomBlockEntity.java:81` |
| `texture` | `ResourceLocation` | **必需** | 无 | 织布过程中显示的纹理（渲染用），不参与逻辑判定 | `LoomRecipe.java:52`；字段声明 `:57`；`getInProgressTexture()`（`:88-90`） |

说明：

1. `LoomRecipe` **没有** `optionalFieldOf`，也**没有** `.validate(...)`：4 个字段全部必需。
2. 字段与父类无关（`INoopInputRecipe` 不定义任何 JSON 字段，`INoopInputRecipe.java:21-37` 只提供三个 `@Contract("-> fail")` 的默认实现，防止误用；`ISimpleRecipe` 同样只有默认实现，`ISimpleRecipe.java:19-29`）。
3. `ItemStackProvider.CODEC`（`net/dries007/tfc/common/recipes/outputs/ItemStackProvider.java:35`）用 `Codec.either(recordCodec, ItemStack.CODEC)`，故 `result` 支持两种写法（见 A4-2）。
4. `result` 若含依赖输入的 modifier（如 `tfc:copy_input`），则 `isSpecial()` 返回 `true`，配方不会被原版配方书/JEI 当作普通配方处理（`LoomRecipe.java:109-112`）。

##### R-21.3 真实 JSON 样例（全部 5 个，逐字读取）

###### 样例 1：`jar-extract/data/tfc/recipe/loom/wool_cloth.json`

```json
{"type":"tfc:loom","ingredient":{"count":16,"item":"tfc:wool_yarn"},"result":{"count":1,"id":"tfc:wool_cloth"},"steps":16,"texture":"minecraft:block/white_wool"}
```

###### 样例 2：`jar-extract/data/tfc/recipe/loom/white_wool.json`

```json
{"type":"tfc:loom","ingredient":{"count":4,"item":"tfc:wool_cloth"},"result":{"count":8,"id":"minecraft:white_wool"},"steps":4,"texture":"minecraft:block/white_wool"}
```

###### 样例 3：`jar-extract/data/tfc/recipe/loom/silk_cloth.json`

```json
{"type":"tfc:loom","ingredient":{"count":24,"item":"minecraft:string"},"result":{"count":1,"id":"tfc:silk_cloth"},"steps":24,"texture":"minecraft:block/white_wool"}
```

###### 样例 4：`jar-extract/data/tfc/recipe/loom/burlap_cloth.json`

```json
{"type":"tfc:loom","ingredient":{"count":12,"item":"tfc:jute_fiber"},"result":{"count":1,"id":"tfc:burlap_cloth"},"steps":12,"texture":"tfc:block/burlap"}
```

###### 样例 5：`jar-extract/data/tfc/recipe/loom/unrefined_paper.json`

```json
{"type":"tfc:loom","ingredient":{"count":4,"item":"tfc:soaked_papyrus_strip"},"result":{"count":1,"id":"tfc:unrefined_paper"},"steps":8,"texture":"tfc:block/unrefined_paper"}
```

五个文件的汇总：

| 文件 | `ingredient` | `result` | `steps` | `texture` | `steps` 与 `count` 是否相等 |
| --- | --- | --- | --- | --- | --- |
| `wool_cloth.json` | `tfc:wool_yarn` ×16 | `tfc:wool_cloth` ×1 | 16 | `minecraft:block/white_wool` | 相等 |
| `white_wool.json` | `tfc:wool_cloth` ×4 | `minecraft:white_wool` ×8 | 4 | `minecraft:block/white_wool` | 相等 |
| `silk_cloth.json` | `minecraft:string` ×24 | `tfc:silk_cloth` ×1 | 24 | `minecraft:block/white_wool` | 相等 |
| `burlap_cloth.json` | `tfc:jute_fiber` ×12 | `tfc:burlap_cloth` ×1 | 12 | `tfc:block/burlap` | 相等 |
| `unrefined_paper.json` | `tfc:soaked_papyrus_strip` ×4 | `tfc:unrefined_paper` ×1 | 8 | `tfc:block/unrefined_paper` | **不相等**（4 vs 8） |

`unrefined_paper.json` 证明 `steps` 与 `ingredient.count` **没有强制关系**（代码中也不存在相关校验），只是 TFC 自带数据通常取相等值。

##### R-21.4 游戏内触发条件（驱动链）

织布机有**两个**驱动器，都继承自 `LoomBlockEntity`。

###### 驱动器 1：手动织布机 `LoomBlockEntity`

| 环节 | 源码位置 | 关键代码 |
| --- | --- | --- |
| 槽位常量 | `net/dries007/tfc/common/blockentities/LoomBlockEntity.java:52-53` | `SLOT_RECIPE = 0`、`SLOT_OUTPUT = 1` |
| 配方缓存 | `LoomBlockEntity.java:239-250`（`updateCachedRecipe`） | `this.recipe = LoomRecipe.getRecipe(((ItemStackHandler)this.inventory).getStackInSlot(0));` |
| 配方查询 | `LoomRecipe.java:59-62` | `return RecipeHelpers.getRecipe(CACHE, stack, stack.getItem());`（走 `IndirectHashCollection<Item, LoomRecipe>` 按物品索引） |
| 手动推进 | `LoomBlockEntity.java:134-144` | 条件：`canPushManually()` 且 `recipe != null` 且手持空 且 `recipe.getInputCount() == 槽0数量` 且 `progress < recipe.getStepCount()`；判定后设置 `needsProgressUpdate = true` |
| 节流 | `LoomBlockEntity.java:76` | `if (loom.needsProgressUpdate && level.getGameTime() - loom.lastPushed >= 20L)` —— 每次推进至少间隔 20 tick |
| 进度推进 | `LoomBlockEntity.java:79` | `++loom.progress;`（仅服务端） |
| 产出 | `LoomBlockEntity.java:81-84` | `if (loom.progress == recipe.getStepCount()) { setStackInSlot(0, EMPTY); setStackInSlot(1, recipe.assemble(inventory.getStackInSlot(0))); }` |
| 产物组装 | `LoomRecipe.java:76-78` | `public ItemStack assemble(ItemStack input) { return this.result.getSingleStack(input); }` |
| 放入原料 | `LoomBlockEntity.java:121-133`（`onRightClick`） | 空手/手持合法原料右键槽 0；已有 1 个时继续右键可堆到 `getInputCount()` 上限 |
| 取出产物 | `LoomBlockEntity.java:114-120` | 槽 1 非空时右键取走 |
| 槽 0 上限 | `LoomBlockEntity.java:226-232` | `getSlotStackLimit(0) => recipe != null ? recipe.getInputCount() : 1`；槽 1 上限 64 |
| 合法性判定 | `LoomBlockEntity.java:195-205` | `isItemValid(0, stack) => LoomRecipe.getRecipe(stack) != null` |
| 渲染 | `net/dries007/tfc/client/render/blockentity/LoomBlockEntityRenderer.java:63`、`:88-92` | `LoomRecipe recipe = loom.getRecipe();`，用 `recipe.getInProgressTexture()` 绘制过程纹理 |

###### 驱动器 2：动力织布机 `PowerLoomBlockEntity`

| 环节 | 源码位置 | 关键代码 |
| --- | --- | --- |
| 类声明 | `net/dries007/tfc/common/blockentities/rotation/PowerLoomBlockEntity.java:38-40` | `class PowerLoomBlockEntity extends LoomBlockEntity implements RotationSinkBlockEntity` |
| 旋转推进 | `PowerLoomBlockEntity.java:45-60` | `progressTicker += abs(rotation.speed()); if (progressTicker > 1.5707964f) { ... needsProgressUpdate = true; }`，条件同样是 `recipe.getInputCount() == 槽0数量 && progress < recipe.getStepCount()` |
| 禁止手动 | `PowerLoomBlockEntity.java:89-92` | `protected boolean canPushManually() { return false; }` |
| 渲染 | `net/dries007/tfc/client/render/blockentity/PowerLoomBlockEntityRenderer.java:46` 起 | `render(PowerLoomBlockEntity loom, ...)` |

**唯一性约束（运行时自检）**：`net/dries007/tfc/util/SelfTests.java:318-321`

```java
private static boolean validateUniqueLoomRecipes(RecipeManager manager) {
    List<Item> errors = manager.getAllRecipesFor(TFCRecipeTypes.LOOM.get()).stream()
        .flatMap(recipe -> Arrays.stream(((LoomRecipe)recipe.value()).getItemStackIngredient().ingredient().getItems()))
        .map(ItemStack::getItem)
        .collect(Collectors.groupingBy(Function.identity(), Collectors.counting()))
        .entrySet().stream().filter(m -> m.getValue() > 1L).map(Map.Entry::getKey).toList();
    return SelfTests.logErrors("{} items appeared in multiple loom recipes. Currently, every loom recipe must have a unique item input in order to work", errors, LOGGER);
}
```

即：**每个物品最多只能出现在一个 loom 配方的 `ingredient` 中**。原因见 `LoomRecipe.java:51`：`CACHE` 是 `IndirectHashCollection<Item, LoomRecipe>`，一个物品键映射到多个配方时 `RecipeHelpers.getRecipe` 只取第一条（`RecipeHelpers.java:134-136` 与 `:143-150` 的线性 first-match）。

##### R-21.5 R-21 小结

- `tfc:loom` 的 type 与 serializer 同名。
- 4 个字段**全部必需**：`ingredient`、`result`、`steps`、`texture`。
- `ingredient` 是 **Sized**（带数量），这是 loom 与多数 TFC 配方的区别点。
- 无 `.validate`；但运行时 `SelfTests` 强制「物品输入唯一」。
- 由 `LoomBlockEntity`（手动右键）与 `PowerLoomBlockEntity`（旋转动力）共同驱动。

---

### [R-22] tfc:food_combining —— 食物合并（合成台特殊配方）

##### R-22.1 类型标识与实现类

| 项目 | 值 | 证据 |
| --- | --- | --- |
| JSON `type` | `tfc:food_combining` | `net/dries007/tfc/common/recipes/TFCRecipeSerializers.java:80` |
| recipe type id | **`minecraft:crafting`**（原版 `RecipeType.CRAFTING`）；`TFCRecipeTypes` 中**没有**对应项 | `TFCRecipeTypes.java:44-63` 无该项；见下方证据链 |
| serializer id | `tfc:food_combining` | `TFCRecipeSerializers.java:80` |
| 实现类全名 | `net.dries007.tfc.common.recipes.FoodCombiningCraftingRecipe` | `net/dries007/tfc/common/recipes/FoodCombiningCraftingRecipe.java:28` |
| 父类 | `net.minecraft.world.item.crafting.CustomRecipe` | `FoodCombiningCraftingRecipe.java:29`（`extends CustomRecipe`） |
| 单例 | `public static final FoodCombiningCraftingRecipe INSTANCE = new FoodCombiningCraftingRecipe();`，构造器 `private`，参数 `CraftingBookCategory.MISC` | `FoodCombiningCraftingRecipe.java:30-34` |
| 注册方式 | `new RecipeSerializerImpl<FoodCombiningCraftingRecipe>(FoodCombiningCraftingRecipe.INSTANCE)` → `MapCodec.unit(INSTANCE)` + `StreamCodec.unit(INSTANCE)` | `TFCRecipeSerializers.java:80`、`net/dries007/tfc/common/recipes/RecipeSerializerImpl.java:19-23` |
| `getSerializer()` 返回值 | `TFCRecipeSerializers.FOOD_COMBINING_CRAFTING.get()` | `FoodCombiningCraftingRecipe.java:85-87` |

##### R-22.2 它到底有没有 recipe type？—— 证据链

任务要求「明确指出 `food_combining` 在 `TFCRecipeTypes` 中没有单独注册项，并核实它由哪个 `RecipeType` 承载」。核实过程如下（逐条列出检查过的文件与方法）：

1. **`TFCRecipeTypes.java`（全文 78 行）**：20 个 `register(...)` 调用（第 44~63 行），字符串分别为 `collapse`…`sewing`，**不含** `food_combining`。→ 没有独立注册。
2. **`FoodCombiningCraftingRecipe.java`（全文 89 行）**：方法只有 `FoodCombiningCraftingRecipe()`（私有构造）、`matches(CraftingInput, Level)`（`:36-54`）、`assemble(CraftingInput, HolderLookup.Provider)`（`:56-75`）、`getRemainingItems(CraftingInput)`（`:77-79`）、`canCraftInDimensions(int, int)`（`:81-83`）、`getSerializer()`（`:85-87`）。**没有 `getType()`**。
3. 因此 `getType()` 来自父类链 `CustomRecipe` → `CraftingRecipe.getType()`。TFC 反编译树内**不含** `net/minecraft`（已验证：`Test-Path src-ref\TFC-decompiled\net\minecraft` 为 `False`，`net` 下仅有 `dries007`），故改用字节码核实（`javap`，命令见文末 A4-4）：
   - `javap -p net.minecraft.world.item.crafting.CustomRecipe` → 成员仅 `Category` 字段、构造器、`isSpecial()`、`getResultItem(...)`、`category()`；**无 `getType()`**。
   - `javap -p net.minecraft.world.item.crafting.CraftingRecipe` → 含 `public default RecipeType<?> getType();`
   - `javap -c net.minecraft.world.item.crafting.CraftingRecipe` 中 `getType()` 的字节码：
     ```
     public default net.minecraft.world.item.crafting.RecipeType<?> getType();
       Code:
          0: getstatic  #17  // Field net/minecraft/world/item/crafting/RecipeType.CRAFTING:Lnet/minecraft/world/item/crafting/RecipeType;
          3: areturn
     ```
   - `javap -p net.minecraft.world.item.crafting.RecipeType` → `public static final RecipeType<CraftingRecipe> CRAFTING;`

**结论**：`tfc:food_combining` 的 **recipe type = `minecraft:crafting`**（`RecipeType.CRAFTING`），**serializer = `tfc:food_combining`**，二者不一致；它不属于任何 `tfc:*` recipe type。因此：

- `RecipeHelpers.getRecipes(level, TFCRecipeTypes.XXX)` 永远**不会**返回它；
- 它出现在 `RecipeManager` 的 `minecraft:crafting` 桶中，由原版合成台逻辑匹配。

同族对照：`tfc:casting_crafting`（`CastingCraftingRecipe`，`net/dries007/tfc/common/recipes/CastingCraftingRecipe.java:35-41`）是完全相同的模式（同为 `extends CustomRecipe` 的单例 + `RecipeSerializerImpl(singleInstance)` 注册），其 JSON 也在合成目录下：`jar-extract/data/tfc/recipe/crafting/casting.json` 内容为 `{"type":"tfc:casting_crafting"}`。

##### R-22.3 完整字段表 —— 没有字段

`FoodCombiningCraftingRecipe` **不定义任何 `CODEC`**，序列化器由 `RecipeSerializerImpl` 的单参构造器提供（`RecipeSerializerImpl.java:21-23`）：

```java
public RecipeSerializerImpl(R singleInstance) {
    this(MapCodec.unit(singleInstance), StreamCodec.unit(singleInstance));
}
```

`MapCodec.unit(...)` 在解码时忽略 JSON 的全部内容并直接返回该实例。因此：

| 字段名 | 类型 | 必需/可选 | 默认值 | 语义 | 证据 |
| --- | --- | --- | --- | --- | --- |
| （无） | — | — | — | 本配方**没有任何可配置字段**；JSON 中除 `type` 外的任何键都不会被读取，也不影响行为 | `FoodCombiningCraftingRecipe.java` 全文无 `CODEC`；`RecipeSerializerImpl.java:19-23` |
| `type` | 字符串（由 `RecipeManager`/`RecipeSerializer` 分派机制消费，不属于配方 codec 的字段） | **必需** | 无 | 固定为 `tfc:food_combining` | `TFCRecipeSerializers.java:80` |

严格说，`type` 是 1.21 配方 JSON 的序列化器分派键，由 `RecipeManager` 读取后选择 serializer，再交给 serializer 的 codec 解码剩余内容；`MapCodec.unit` 不消费任何键。

##### R-22.4 是否真的能从 JSON 加载？—— 是

- **能**。理由是 jar 中存在让这条配方被加载的真实文件：

  `jar-extract/data/tfc/recipe/crafting/food_combining.json`（逐字读取，全文 1 行）：

  ```json
  {"type":"tfc:food_combining"}
  ```

  该文件位于 `data/tfc/recipe/crafting/`，`type` 指向 `tfc:food_combining`，会由 `RecipeManager` 用对应的 `RecipeSerializer`（`MapCodec.unit(INSTANCE)`）解码，得到 `TFCRecipeSerializers.FOOD_COMBINING_CRAFTING` 的实例，即 `FoodCombiningCraftingRecipe.INSTANCE`。<br>
  同目录同写法的 `casting.json`（`{"type":"tfc:casting_crafting"}`）是同一机制的另一实例，可交叉印证。

- **但它不是"配置型"配方**：整个 JSON 没有可调字段，行为完全由 `matches` / `assemble` 的 Java 代码决定。因此这类配方**通常由代码（单例 + JSON 占位）而非常规 JSON 定义**；TFC 甚至用「代码里持有单例 + 一个极简 JSON 触发加载」的方式把它塞进配方管理器。

- 同类指示：`TFCRecipeSerializers.java:80-81` 对 `FOOD_COMBINING_CRAFTING` 与 `CASTING_CRAFTING` 都使用 `new RecipeSerializerImpl<>(X.INSTANCE)`，而其它配方都使用 `register(name, CODEC, STREAM_CODEC)` 的正常路径。

##### R-22.5 匹配与产出逻辑（无 JSON 字段，全部在代码中）

`matches(CraftingInput input, Level level)`（`FoodCombiningCraftingRecipe.java:36-54`）：

```java
public boolean matches(CraftingInput input, Level level) {
    int notEmptyCount = 0;
    ItemStack foodStack = ItemStack.EMPTY;
    for (int i = 0; i < input.size(); ++i) {
        ItemStack stack = input.getItem(i);
        if (stack.isEmpty()) continue;
        ++notEmptyCount;
        if (!FoodCapability.has(stack)) return false;                         // ① 所有非空格子必须是食物
        if (foodStack.isEmpty()) { foodStack = stack; continue; }
        if (FoodCapability.areStacksStackableExceptCreationDate(stack, foodStack)) continue;  // ② 除创建日期外必须可堆叠
        return false;
    }
    return notEmptyCount > 1;                                                 // ③ 至少 2 个非空
}
```

触发条件：**合成格中放至少 2 个"除创建日期外完全相同"的食物**（即同种食物、同 NBT 内容，仅 `creationDate` 不同）。

`assemble(CraftingInput input, HolderLookup.Provider registries)`（`:56-75`）：
- 统计非空食物格数作为产物数量 `outputAmount`；
- 取所有输入中**最小**的 `creationDate`（`minCreationDate`）；
- 以第一个非空食物栈为模板 `copy()`，`setCount(outputAmount)`，并 `FoodCapability.setCreationDate(resultStack, date)`。

`getRemainingItems` 返回全空 `NonNullList`（`:77-79`），`canCraftInDimensions` 恒 `true`（`:81-83`）。

##### R-22.6 游戏内触发条件（由哪个方块/界面驱动）

| 环节 | 证据 |
| --- | --- |
| 触发方块/界面 | **原版工作台界面**：`net/dries007/tfc/common/container/TFCWorkbenchContainer.java:20`（`extends CraftingMenu`）。TFC 的 TFC 工作台复用原版 `CraftingMenu` 逻辑，后者以 `RecipeType.CRAFTING` 检索配方并调用 `matches(CraftingInput, Level)` |
| 输入容器 | `net.minecraft.world.item.crafting.CraftingInput`（1.21.1 原版合成输入容器），由 `CraftingMenu`/`CraftingInput.of(...)` 构造 |
| 配方检索路径 | `RecipeManager.byType(RecipeType.CRAFTING)`（原版）→ 包含本配方（因其 `getType()` 为 `RecipeType.CRAFTING`） |
| TFC 侧是否有专用驱动代码 | **没有**。`grep -r "FoodCombining"` 在整个 `net/dries007/tfc` 下只有 3 处命中：`TFCRecipeSerializers.java:29`（import）、`TFCRecipeSerializers.java:80`（注册）、`FoodCombiningCraftingRecipe.java` 自身（第 28、30、32、86 行）。**不存在**任何 `FoodCombiningCraftingRecipe.INSTANCE.matches(...)` 之类的显式调用 |

补充：`CustomRecipe.isSpecial()` 在 1.21.1 返回 `true`（`javap -p CustomRecipe` 输出中可见 `public boolean isSpecial();`），因此该配方不会出现在配方书（RecipeBook）的普通合成列表里，也不会被 JEI 当作普通合成配方展示。

##### R-22.7 R-22 小结

- `type` = `tfc:food_combining`（serializer 名），**recipe type = `minecraft:crafting`**（继承自 `CraftingRecipe.getType()`）。
- **零 JSON 字段**，写法固定为 `{"type":"tfc:food_combining"}`。
- 能从 JSON 加载（jar 中有真实文件），但配方行为完全由 Java 代码决定。
- 由原版合成台（`TFCWorkbenchContainer extends CraftingMenu` + `RecipeType.CRAFTING`）驱动，TFC 侧无显式调用点。

---

### [R-23] tfc:bloomery —— 冶炼炉（块炼）配方

##### R-23.1 类型标识与实现类

| 项目 | 值 | 证据 |
| --- | --- | --- |
| JSON `type` | `tfc:bloomery` | `net/dries007/tfc/common/recipes/TFCRecipeSerializers.java:70` |
| recipe type id | `tfc:bloomery` | `net/dries007/tfc/common/recipes/TFCRecipeTypes.java:58` |
| serializer id | `tfc:bloomery` | `TFCRecipeSerializers.java:70` |
| 实现类全名 | `net.dries007.tfc.common.recipes.BloomeryRecipe` | `net/dries007/tfc/common/recipes/BloomeryRecipe.java:46` |
| 实现的接口 | `INoopInputRecipe`（→ `ISimpleRecipe<NoopInput>` → `Recipe<NoopInput>`） | `BloomeryRecipe.java:47`；`INoopInputRecipe.java:21-22` |
| `getType()` 返回值 | `TFCRecipeTypes.BLOOMERY.get()` | `BloomeryRecipe.java:109-111` |
| `getSerializer()` 返回值 | `TFCRecipeSerializers.BLOOMERY.get()` | `BloomeryRecipe.java:105-107` |

**type 名与 serializer 名一致**。

##### R-23.2 完整字段表

自身 `CODEC` 源码（`BloomeryRecipe.java:48`）：

```java
public static final MapCodec<BloomeryRecipe> CODEC = RecordCodecBuilder.mapCodec(i -> i.group(
    SizedFluidIngredient.FLAT_CODEC.fieldOf("fluid").forGetter(c -> c.inputFluid),
    SizedIngredient.FLAT_CODEC.fieldOf("catalyst").forGetter(c -> c.catalyst),
    ItemStackProvider.CODEC.fieldOf("result").forGetter(c -> c.result),
    Codec.INT.fieldOf("duration").forGetter(c -> c.duration)
).apply(i, BloomeryRecipe::new));
```

| 字段名 | 类型 | 必需/可选 | 默认值 | 语义 | 证据 |
| --- | --- | --- | --- | --- | --- |
| `fluid` | `SizedFluidIngredient`（扁平形式：`{"fluid":"<流体 id>","amount":N}`，亦支持 `{"tag":"...","amount":N}`） | **必需** | 无 | 冶炼炉消耗的熔融金属流体（由炉内物品经 `HeatingRecipe` 熔出后判定，见 R-23.4）。注意字段名是 **`fluid`** 而不是 `fluid_ingredient`（与 pot 系列不同） | `BloomeryRecipe.java:48`；字段声明 `:50`；`getInputFluid()`（`:70-72`） |
| `catalyst` | `SizedIngredient`（扁平形式：`{"item":"...","count":N}` 或 `{"tag":"...","count":N}`） | **必需** | 无 | 催化剂数量与种类。产物份数受 `catalyst.count()` 限制 | `BloomeryRecipe.java:48`；字段声明 `:51`；`getCatalyst()`（`:66-68`）、`matchesCatalyst`（`:82-84`） |
| `result` | `ItemStackProvider`（必填，无默认） | **必需** | 无 | 产物（块炼铁锭等）。可写纯 `ItemStack` 或带 `modifiers` 的 provider | `BloomeryRecipe.java:48`；字段声明 `:52`；`assembleOutput() => result.getEmptyStack()`（`:96-98`）、`getResultItem(...)`（`:100-103`） |
| `duration` | `int`（tick） | **必需** | 无 | 冶炼耗时 | `BloomeryRecipe.java:48`；字段声明 `:53`；`getDuration()`（`:62-64`） |

说明：

1. **4 个字段全部必需**，无 `optionalFieldOf`，也无 `.validate(...)`。
2. **没有 `temperature` 字段**：冶炼温度不来自配方，而是通过 `HeatingRecipe` 决定 —— `consumeInput(ItemStack)` 先 `HeatingRecipe.getRecipe(stack)` 得到熔融流体，再用 `matchesInput(FluidStack)` 比较（`BloomeryRecipe.java:86-94`）：

   ```java
   @Nullable
   public FluidStack consumeInput(ItemStack stack) {
       HeatingRecipe heat = HeatingRecipe.getRecipe(stack);
       if (heat != null && this.matchesInput(heat.assembleFluid(stack))) {
           return heat.assembleFluid(stack);
       }
       return null;
   }
   ```

   相应地，产物温度在 `BloomeryBlockEntity.completeRecipe` 中由 `HeatingRecipe` 设定：`HeatCapability.setTemperature(outputStack, recipe.getTemperature() - 1.0f)`（`net/dries007/tfc/common/blockentities/BloomeryBlockEntity.java:344-347`）。
3. `fluid` 使用 `SizedFluidIngredient.FLAT_CODEC`（与 pot 的 `fluid_ingredient` 同一 codec），`catalyst` 使用 `SizedIngredient.FLAT_CODEC`（与 loom 的 `ingredient` 同一 codec）。两者的 `amount`/`count` 都由 `ExtraCodecs.POSITIVE_INT` 约束（见 A4-3）。
4. `matchesInput(ItemStack)` 是 `consumeInput(stack) != null` 的封装（`:74-76`），注意它**不是**简单的 `catalyst.test`。

##### R-23.3 真实 JSON 样例（唯一 1 个，逐字读取）

相对路径：`jar-extract/data/tfc/recipe/bloomery/raw_iron_bloom.json`

```json
{"type":"tfc:bloomery","catalyst":{"count":2,"item":"minecraft:charcoal"},"duration":14400,"fluid":{"amount":100,"fluid":"tfc:metal/cast_iron"},"result":{"count":1,"id":"tfc:raw_iron_bloom"}}
```

字段解读：

| JSON 键 | 值 | 对应字段 / 代码 |
| --- | --- | --- |
| `type` | `tfc:bloomery` | serializer 名 |
| `catalyst` | `{"count":2,"item":"minecraft:charcoal"}` | `SizedIngredient.FLAT_CODEC` → `catalyst`；2 个木炭 |
| `duration` | `14400`（= 12 分钟 = 720 秒） | `duration` |
| `fluid` | `{"amount":100,"fluid":"tfc:metal/cast_iron"}` | `SizedFluidIngredient.FLAT_CODEC` → `inputFluid`；100 mB 生铁熔液 |
| `result` | `{"count":1,"id":"tfc:raw_iron_bloom"}` | `ItemStackProvider.CODEC` 走纯 `ItemStack` 分支 → `result` |

这是**整个 jar 中唯一的 bloomery 配方**（`data/tfc/recipe/bloomery/` 下仅此 1 个文件）。

##### R-23.4 游戏内触发条件（驱动链）

**唯一驱动方：`BloomeryBlockEntity`**（`net/dries007/tfc/common/blockentities/BloomeryBlockEntity.java`）。

| 环节 | 源码位置 | 关键代码 |
| --- | --- | --- |
| 缓存字段 | `BloomeryBlockEntity.java:78` | `protected BloomeryRecipe cachedRecipe;` |
| 读取缓存 | `BloomeryBlockEntity.java:145-149`（`getCachedRecipe`） | 返回 `cachedRecipe` |
| 缓存重建 | `BloomeryBlockEntity.java:359-373`（`updateCachedRecipe`） | `Collection recipes = RecipeHelpers.getRecipes(this.level, TFCRecipeTypes.BLOOMERY);` → 对每个已投入物品取 `HeatingRecipe.getRecipe(stack)` → `heat.assembleFluid(stack)` → `matchesInput(fluid)` → 命中即 `cachedRecipe = recipe.value()` |
| 投入物品时判定 | `BloomeryBlockEntity.java:256-309`（`addItemsFromWorld`） | 第 275 行同样用 `RecipeHelpers.getRecipes(this.level, TFCRecipeTypes.BLOOMERY)`；第 281 行 `matchesInput(fluid)`；第 293 行 `cachedRecipe.matchesInput(stack)` 区分输入物品与催化剂；第 297 行 `matchesCatalyst(stack)` |
| 结算 | `BloomeryBlockEntity.java:328-357`（`completeRecipe`） | 对每个输入物品调用 `consumeInput(stack)` 累计 `fluidAmount`，其余计为 `catalystAmount`；`producedAmount = min(fluidAmount / getInputFluid().amount(), catalystAmount / getCatalyst().count())`；随后 `assembleOutput()`、设温度、在内部方块位置放置 `tfc:bloom` 方块并 `bloom.setBloom(outputStack, producedAmount)` |
| 触发方块 | `net/dries007/tfc/common/blocks/devices/BloomeryBlock.java`（形成判定见 `BloomeryBlockEntity.java:318-326` 的 `calculateCapacity`，容量 = 烟囱层数 × `TFCConfig.SERVER.bloomeryCapacity`） | `BloomeryBlock.isFormed(level, pos, facing)`、`BloomeryBlock.getChimneyLevels(level, pos)` |

与 pot/loom 的**关键区别**：

- bloomery **没有 `RecipeManager.getRecipeFor` 调用**，而是自己遍历 `TFCRecipeTypes.BLOOMERY` 的全部配方并用 `matchesInput(FluidStack)` 逐条比较（`BloomeryBlockEntity.java:275`、`:281`、`:362`、`:368`）。原因：其输入是"炉内一堆物品熔出的流体"，不是标准 `RecipeInput`。
- 因此 `BloomeryRecipe` 虽然实现了 `INoopInputRecipe`，但 `matches(NoopInput, Level)` 与 `assemble(NoopInput, ...)` 都会抛 `UnsupportedOperationException`（`INoopInputRecipe.java:23-31`）。

**唯一性约束（运行时自检）**：`net/dries007/tfc/util/SelfTests.java:313-316`

```java
private static boolean validateUniqueBloomeryRecipes(RecipeManager manager) {
    List<Fluid> errors = manager.getAllRecipesFor(TFCRecipeTypes.BLOOMERY.get()).stream()
        .flatMap(recipe -> RecipeHelpers.stream(((BloomeryRecipe)recipe.value()).getInputFluid()))
        .collect(Collectors.groupingBy(Function.identity(), Collectors.counting()))
        .entrySet().stream().filter(m -> m.getValue() > 1L).map(Map.Entry::getKey).toList();
    return SelfTests.logErrors("{} fluids appeared in multiple bloomery recipes. Currently, every bloomery recipe must have a unique fluid input in order to work", errors, LOGGER);
}
```

即：**每个输入流体在全部 bloomery 配方中只能出现一次**（否则 `updateCachedRecipe` 的 first-match 逻辑会导致不确定行为）。

JEI 展示：`net/dries007/tfc/compat/jei/JEIIntegration.java:164`（`BLOOMERY = type("bloomery", BloomeryRecipe.class)`）、`:204`（注册 `BloomeryRecipeCategory`）；分类实现 `net/dries007/tfc/compat/jei/category/BloomeryRecipeCategory.java:46-49` 依次展示 `recipe.getCatalyst()`、`recipe.getInputFluid()`、`recipe.getResultItem(...)`。

##### R-23.5 R-23 小结

- `tfc:bloomery` 的 type 与 serializer 同名。
- 4 个字段全部必需：`fluid`（注意不叫 `fluid_ingredient`）、`catalyst`、`result`、`duration`。
- **无温度字段**，温度经 `HeatingRecipe` 传递。
- 由 `BloomeryBlockEntity` 自行遍历 `TFCRecipeTypes.BLOOMERY` 驱动，非 `getRecipeFor`。
- jar 中仅 1 个配方；运行时自检要求输入流体唯一。

---

### 附录 A4-1：`PotOutput` 详解（位置、JSON 字段、注册表）

##### A4-1.1 关键结论先行

**`PotOutput` 不是配方 JSON 的一部分。** 配方 JSON 中**不存在** `pot_output`、`chance`、`fluid`、`amount` 等指向 `PotOutput` 的字段：

- `tfc:pot` 的产物字段是 `fluid_output`（`FluidStack`）与 `item_output`（`ItemStackProvider` 列表），定义在 `SimplePotRecipe.CODEC`（`SimplePotRecipe.java:44`）。
- `tfc:pot_soup` / `tfc:pot_jam` 的产物字段分别是**无字段**（代码计算）与 `unsealed_result`/`sealed_result`/`texture`。
- `PotOutput` 是**运行时对象**，只在锅方块实体的 **NBT** 中序列化/反序列化（`PotBlockEntity.java:110-128`）：

  ```java
  // PotBlockEntity.java:111-128
  public void loadAdditional(CompoundTag nbt, HolderLookup.Provider provider) {
      if (nbt.contains("output")) {
          this.output = PotOutput.read(provider, nbt.getCompound("output"));
      }
      ...
  }
  public void saveAdditional(CompoundTag nbt, HolderLookup.Provider provider) {
      if (this.output != null) {
          nbt.put("output", PotOutput.write(provider, this.output));
      }
      ...
  }
  ```

##### A4-1.2 `PotOutput` 的形态与位置

| 项目 | 值 | 证据 |
| --- | --- | --- |
| 位置 | `net/dries007/tfc/common/recipes/outputs/PotOutput.java` | 全文 106 行 |
| 形态 | **`interface PotOutput`**（不是 `ItemStackProvider` 的子类，也不是 record） | `PotOutput.java:40` |
| 注册表键 | `ResourceKey<Registry<OutputType>> KEY = ResourceKey.createRegistryKey(Helpers.identifier("pot_output"))` → 注册表 id `tfc:pot_output` | `PotOutput.java:41` |
| 默认项 | `DEFAULT = ResourceKey.create(KEY, Helpers.identifier("empty"))`，且 `new RegistryBuilder(KEY).sync(true).defaultKey(DEFAULT)` | `PotOutput.java:42-43` |
| 默认实例 | `EMPTY_INSTANCE`（匿名实现，全部走 default 方法） | `PotOutput.java:45` |
| 已注册类型 | `empty`（→ `EMPTY_INSTANCE`）、`soup`（→ `SoupPotRecipe.OUTPUT_TYPE`）、`jam`（→ `JamPotRecipe.OUTPUT_TYPE`） | `PotOutput.java:46-48` |
| 类型接口 | `@FunctionalInterface OutputType { PotOutput read(HolderLookup.Provider, CompoundTag); }` | `PotOutput.java:101-104` |

##### A4-1.3 `PotOutput` 的 default 方法（行为契约）

| 方法 | 默认返回值 | 语义 | 证据 |
| --- | --- | --- | --- |
| `isEmpty()` | `true` | 产物是否为空；`PotBlockEntity` 结算时用它决定是否保存 | `PotOutput.java:65-67`、`PotBlockEntity.java:163-165` |
| `getFluidColor()` | `-1` | 渲染用流体颜色；`SoupOutput` 返回 `-5881324`，`JamOutput` 未覆盖 | `PotOutput.java:69-71`、`SoupPotRecipe.java:144-147` |
| `getRenderTexture()` | `null` | 渲染贴图；`JamOutput` 返回 JSON 的 `texture` | `PotOutput.java:73-76`、`JamPotRecipe.java:114-117` |
| `getFluidYLevel()` | `0.625f` | 液面高度；`JamOutput` 按未封盖数量映射 0.4375~0.625 | `PotOutput.java:78-80`、`JamPotRecipe.java:119-122` |
| `onFinish(IPotInventory)` | 空实现 | 结算回调；`SimpleOutput` 用它把产物写回槽 4~8 并置换流体 | `PotOutput.java:82-83`、`SimplePotRecipe.java:98-105` |
| `onInteract(IPotInventory, Player, ItemStack)` | `PASS_TO_DEFAULT_BLOCK_INTERACTION` | 取产物交互 | `PotOutput.java:85-87`、`PotBlockEntity.java:233-243` |
| `getType()` | `EMPTY.get()` | 类型（用于 NBT 序列化） | `PotOutput.java:89-91` |
| `write(Provider, CompoundTag)` | 空实现 | NBT 写出 | `PotOutput.java:93-94` |
| `getTooltip()` | `null` | 方块实体 tooltip | `PotOutput.java:96-99` |

##### A4-1.4 三种实现的 NBT 字段（**NBT，不是配方 JSON**）

| 实现 | 定义位置 | `getType()` 注册名 | NBT 键 |
| --- | --- | --- | --- |
| `SimplePotRecipe.SimpleOutput`（record `(FluidStack fluidOutput, List<ItemStack> itemOutputs)`） | `SimplePotRecipe.java:96-106` | 未单独注册（`getType()` 用 default `EMPTY`） | 无 `write` 覆写（走 default 空实现）——它**不通过 NBT 持久化**，而是在 `handleCooking` 中合成后立刻 `onFinish` 并写入 `this.output`；只有非空时才保存 |
| `SoupPotRecipe.SoupOutput`（record `(ItemStack stack)`） | `SoupPotRecipe.java:126-166` | `soup`（`PotOutput.SOUP`，`PotOutput.java:47`） | `item`（`ItemStack.save(provider)`）—— 见 `SoupPotRecipe.java:149-152` |
| `JamPotRecipe.JamOutput`（record `(ItemStack unsealedStack, ItemStack sealedStack, ResourceLocation texture)`） | `JamPotRecipe.java:90-143` | `jam`（`PotOutput.JAM`，`PotOutput.java:48`） | `unsealed_result`、`sealed_result`、`texture`（字符串）—— 见 `JamPotRecipe.java:124-129` |

此外，`PotOutput.write` 会额外写入键 `type`（值为注册表键字符串，如 `tfc:jam`）（`PotOutput.java:58-63`）：

```java
public static CompoundTag write(HolderLookup.Provider provider, PotOutput output) {
    CompoundTag nbt = new CompoundTag();
    nbt.putString("type", REGISTRY.getKey(output.getType()).toString());
    output.write(provider, nbt);
    return nbt;
}
```

##### A4-1.5 对写数据者的实际影响

- 你在 mod 里写 `tfc:pot` / `tfc:pot_soup` / `tfc:pot_jam` 配方时，**不需要也不能**写任何 `PotOutput` 相关字段。
- 想自定义"锅产物行为"（例如自定义取产物交互），只能通过注册到 `tfc:pot_output` 注册表的 `OutputType` + 自定义 `PotRecipe` 子类实现，纯 JSON 无法做到。
- `chance` 这类字段若出现在 pot 产物中，只可能来自 `ItemStackProvider` 的 `modifiers`（`tfc:chance`，见 A4-2），与 `PotOutput` 无关。

---

### 附录 A4-2：`ItemStackProvider` 与 `ItemStackModifier`（JSON 写法与类型清单）

##### A4-2.1 `ItemStackProvider` 的 JSON 两种写法

`ItemStackProvider` 是 record（`net/dries007/tfc/common/recipes/outputs/ItemStackProvider.java:34`）：

```java
public record ItemStackProvider(ItemStack stack, List<ItemStackModifier> modifiers)
```

其 `CODEC`（`ItemStackProvider.java:35`）：

```java
public static final Codec<ItemStackProvider> CODEC = Codec.either(
    RecordCodecBuilder.create(i -> i.group(
        ItemStack.CODEC.optionalFieldOf("stack", ItemStack.EMPTY).forGetter(c -> c.stack),
        ItemStackModifier.CODEC.listOf().fieldOf("modifiers").forGetter(c -> c.modifiers)
    ).apply(i, ItemStackProvider::new)),
    ItemStack.CODEC
).xmap(e -> e.map(Function.identity(), ItemStackProvider::of),
       provider -> provider.modifiers.isEmpty() ? Either.right(provider.stack) : Either.left(provider));
```

| 写法 | JSON 形态 | 字段是否必需 | 说明 |
| --- | --- | --- | --- |
| 纯物品（`Either.right`） | `{"id":"tfc:raw_iron_bloom","count":1}` | `id` 与 `count` 按 `ItemStack.CODEC` 规则 | `modifiers` 为空时序列化回该形式 |
| record 形式（`Either.left`） | `{"stack":{...},"modifiers":[...]}` 或 `{"modifiers":[...]}` | **`modifiers` 必需**；`stack` 可选，默认 `ItemStack.EMPTY` | 若 `modifiers` 缺省，`Either.left` 解码失败并回退到 `Either.right` |

**重要**：`Codec.either` 先尝试左支。因此 `{"id":"...","count":N}` 因为缺少 `modifiers` 而在左支失败，落到右支按 `ItemStack` 解析。反之 `{"modifiers":[...]}` 由于 `stack` 有默认值，会在左支成功。

真实样例（`tfc:advanced_shapeless_crafting`，可印证 `stack` + `modifiers` 并存的写法）：

`jar-extract/data/tfc/recipe/crafting/blowpipe_with_glass.json`

```json
{"type":"tfc:advanced_shapeless_crafting","ingredients":[{"tag":"tfc:glass_batches"},{"item":"tfc:blowpipe"}],"primary_ingredient":{"tag":"tfc:glass_batches"},"result":{"modifiers":[{"type":"tfc:add_glass"}],"stack":{"count":1,"id":"tfc:blowpipe_with_glass"}}}
```

本组中真实的两种 pot 写法：
- 纯物品：`jar-extract/data/tfc/recipe/pot/food/boiled_egg_1.json` 的 `"item_output":[{"count":1,"id":"tfc:food/boiled_egg"}]`
- record 形式：`jar-extract/data/tfc/recipe/pot/jam_banana_canning_1.json` 的 `"item_output":[{"modifiers":[{"type":"tfc:copy_input"},{"type":"tfc:add_trait","trait":"tfc:canned"}]}]`

##### A4-2.2 `ItemStackModifier` 的分派机制

`ItemStackModifier` 是接口（`ItemStackModifier.java:21`）：

```java
public interface ItemStackModifier {
    Codec<ItemStackModifier> CODEC = ItemStackModifiers.REGISTRY.byNameCodec()
        .dispatch(ItemStackModifier::type, ItemStackModifierType::codec);
    ...
    default boolean dependsOnInput() { return false; }
    ItemStackModifierType<?> type();
    enum Context { DEFAULT, NO_RANDOM_CHANCE; }
}
```

- 分派键是 **`type`**（`byNameCodec()` 提供注册名 → `ItemStackModifierType` 的映射），所以 JSON 里每个 modifier 都必须写 `"type":"tfc:<注册名>"`。
- 注册表：`ItemStackModifiers.KEY = Helpers.identifier("item_stack_modifiers")`，即 `tfc:item_stack_modifiers`（`ItemStackModifiers.java:54-56`）。
- 每个 modifier 的 JSON 字段由其 `ItemStackModifierType.codec`（`ItemStackModifierType.java:16`）决定。
- `dependsOnInput()` 决定该 modifier 是否使产物"依赖输入"（进而触发 `SimplePotRecipe` 的 validate 与 `LoomRecipe.isSpecial()`）。

##### A4-2.3 `ItemStackModifiers` 已注册的 22 种类型（`ItemStackModifiers.java:57-78`）

| 注册名（JSON `type`） | 实现类 | 是否需要额外字段 | 额外字段（来自该类 `CODEC`） | 证据 |
| --- | --- | --- | --- | --- |
| `tfc:copy_input` | `CopyInputModifier` | 否 | —（`MapCodec.unit`） | `ItemStackModifiers.java:57`、`:80-82` |
| `tfc:copy_food` | `CopyFoodModifier` | 否 | — | `:58` |
| `tfc:copy_oldest_food` | `CopyOldestFoodModifier` | 否 | — | `:59` |
| `tfc:copy_heat` | `CopyHeatModifier` | 否 | — | `:60` |
| `tfc:copy_forging_bonus` | `CopyForgingBonusModifier` | 否 | — | `:61` |
| `tfc:reset_food` | `ResetFoodModifier` | 否 | — | `:62` |
| `tfc:empty_bowl` | `EmptyBowlModifier` | 否 | — | `:63` |
| `tfc:flower_cutting` | `FlowerCuttingModifier` | 否 | — | `:64` |
| `tfc:add_bait_to_rod` | `AddBaitToRodModifier` | 否 | — | `:65` |
| `tfc:add_glass` | `AddGlassModifier` | 否 | — | `:66` |
| `tfc:add_powder` | `AddPowderModifier` | 否 | — | `:67` |
| `tfc:crafting_remainder` | `CraftingRemainderModifier` | 否 | — | `:68` |
| `tfc:damage_crafting_remainder` | `DamageCraftingRemainderModifier` | 否 | — | `:69` |
| `tfc:add_trait` | `AddTraitModifier` | **是** | `trait`（`FoodTrait`） | `:70`；`AddTraitModifier.java:26` |
| `tfc:remove_trait` | `RemoveTraitModifier` | **是** | `trait`（`FoodTrait`） | `:71`；`RemoveTraitModifier.java:26` |
| `tfc:round_creation_date` | `RoundCreationDateModifier` | 否 | — | `:72` |
| `tfc:add_heat` | `AddHeatModifier` | **是** | `temperature`（`Codec.FLOAT`） | `:73`；`AddHeatModifier.java:30` |
| `tfc:dye_leather` | `DyeLeatherModifier` | **是** | `color`（`DyeColor`） | `:74`；`DyeLeatherModifier.java:29` |
| `tfc:remove_dye` | `RemoveDyeModifier` | 否 | — | `:75` |
| `tfc:meal` | `MealModifier` | **是** | `food`（`FoodData`）+ `portions`（列表，元素含可选 `ingredient`、`nutrient_modifier`、`water_modifier`、`saturation_modifier`） | `:76`；`MealModifier.java:52` |
| `tfc:extra_products` | `ExtraProductModifier` | **是** | `stack`（`ItemStack`） | `:77`；`ExtraProductModifier.java:30` |
| `tfc:chance` | `ChanceModifier` | **是** | `chance`（`Codec.FLOAT`） | `:78`；`ChanceModifier.java:29` |

完整清单共 **22** 个注册常量（第 57~78 行），其中 `tfc:meal` 与 `tfc:extra_products` 的字段较复杂，写数据时以对应类 `CODEC` 为准。

##### A4-2.4 本组配方中实际出现过的 modifier

对 `data/tfc/recipe/pot/**` 全部文件的 `"modifiers"` 内 `type` 值做统计（结果）：

| modifier | 出现次数 |
| --- | --- |
| `tfc:copy_input` | 330 |
| `tfc:add_trait` | 330 |

（其余 `type` 计数属于 `ingredients` 里的 ingredient 类型，不是 modifier。）330 正好等于全部罐装配方中 `item_output` 的 provider 总数（22 种水果 × (1+2+3+4+5) 档 = 330），即每个 provider 各带 1 个 `copy_input` 与 1 个 `add_trait`。即 TFC 自带数据只用到了 `copy_input` + `add_trait` 组合来做"罐装"。

##### A4-2.5 `ItemStackProvider` 的取值方法（与 JSON 无关，供理解语义）

| 方法 | 行为 | 证据 |
| --- | --- | --- |
| `getSingleStack(ItemStack input)` | `getStack(input.copyWithCount(1))` —— 以单个输入为单位产出 | `ItemStackProvider.java:72-74` |
| `getEmptyStack()` | `getStack(ItemStack.EMPTY, Context.NO_RANDOM_CHANCE)` —— 不依赖输入（`getResultItem` 用它） | `:80-82` |
| `getStack(input, context)` | 先 `stack.copy()`，若 `input` 非空则 `count *= input.getCount()`，再依次应用 modifiers | `:92-101` |
| `dependsOnInput()` | 任一 modifier 的 `dependsOnInput()` 为真则返回真 | `:103-109` |

---

### 附录 A4-3：Ingredient 家族与 Sized* 的 JSON 形式（本组公共）

##### A4-3.1 原版 `Ingredient.CODEC`（用于 `ingredients` 的元素、`catalyst`/`ingredient` 的内层）

本组出现的三种基本写法（均有真实样例佐证）：

| 写法 | 示例 | 出现位置 |
| --- | --- | --- |
| 单物品 | `{"item":"minecraft:egg"}` | `jar-extract/data/tfc/recipe/pot/food/boiled_egg_1.json` |
| tag | `{"tag":"tfc:foods/sweeteners"}` | `jar-extract/data/tfc/recipe/pot/jam_banana_2.json` |
| 数组（多选一） | `[{...},{...}]` | 原版 `Ingredient.CODEC` 支持（本组自带数据中未出现） |

##### A4-3.2 `TFCIngredients` 自定义 ingredient（`type` 分派）

`net/dries007/tfc/common/recipes/ingredients/TFCIngredients.java:41-48` 注册到 NeoForge 的 `IngredientType` 注册表，注册名为 `tfc:<name>`：

| JSON `type` | 实现类 | 额外字段 | 语义 | 证据 |
| --- | --- | --- | --- | --- |
| `tfc:rotten` | `RottenIngredient` | 无 | 匹配已腐烂食物 | `TFCIngredients.java:42` |
| `tfc:not_rotten` | `NotRottenIngredient` | 无（`MapCodec.unit`） | 匹配未腐烂食物（`!FoodCapability.isRotten`） | `:43`；`NotRottenIngredient.java:26-31`、`:42-45` |
| `tfc:has_trait` | `HasTraitIngredient` | `trait` | 匹配拥有某食物特性的物品 | `:44` |
| `tfc:lacks_trait` | `LacksTraitIngredient` | `trait` | 匹配不具备某食物特性的物品 | `:45`；`LacksTraitIngredient.java:27` |
| `tfc:heat` | `HeatIngredient` | （见该类 `CODEC`） | 按温度匹配 | `:46` |
| `tfc:fluid_content` | `FluidContentIngredient` | （见该类 `CODEC`） | 按容器内流体匹配 | `:47` |
| `tfc:and` | `AndIngredient` | `children`（`Ingredient.CODEC.listOf()`） | 所有子 condition 同时成立 | `:48`；`AndIngredient.java:32` |

`tfc:and` 的 JSON 结构（`AndIngredient.java:32`）：

```json
{"type":"tfc:and","children":[{"tag":"tfc:usable_in_soup"},{"type":"tfc:not_rotten"}]}
```

真实样例：`jar-extract/data/tfc/recipe/pot/soup_3.json` 的每个 `ingredients` 元素。
`tfc:lacks_trait` 的真实样例：`jar-extract/data/tfc/recipe/pot/jam_banana_canning_1.json` 中的 `{"type":"tfc:lacks_trait","trait":"tfc:canned"}`。

##### A4-3.3 `SizedIngredient`（NeoForge）—— loom 的 `ingredient`、bloomery 的 `catalyst`

字节码核实结果（`javap`，见 A4-4）：

- `SizedIngredient` 有 `FLAT_CODEC` 与 `NESTED_CODEC` 两个静态字段。
- `NESTED_CODEC` 使用字段名 **`ingredient`** + **`count`**。
- `FLAT_CODEC` 使用原版 `Ingredient`（扁平展开，无需 `ingredient` 包装）+ **`count`**。
- `count` 使用 `ExtraCodecs.POSITIVE_INT`（字符串常量 "Size must be positive"），即**必须为正整数（≥1）**。

因此 FLAT 写法为：

```json
{"item":"tfc:wool_yarn","count":16}
{"tag":"c:tools/knife","count":1}
```

真实样例（loom）：`jar-extract/data/tfc/recipe/loom/wool_cloth.json` → `{"count":16,"item":"tfc:wool_yarn"}`；
真实样例（bloomery）：`jar-extract/data/tfc/recipe/bloomery/raw_iron_bloom.json` → `{"count":2,"item":"minecraft:charcoal"}`。

##### A4-3.4 `SizedFluidIngredient`（NeoForge）—— pot 的 `fluid_ingredient`、bloomery 的 `fluid`

字节码核实结果：

- `SizedFluidIngredient` 有 `FLAT_CODEC` 与 `NESTED_CODEC`（**没有**名为 `CODEC` 的字段）。
- `NESTED_CODEC` = 字段名 **`ingredient`**（`FluidIngredient.CODEC_NON_EMPTY`）+ **`amount`**。
- `FLAT_CODEC` = `FluidIngredient.MAP_CODEC_NONEMPTY` 扁平展开 + **`amount`**。
- `amount` 使用 `ExtraCodecs.POSITIVE_INT` → **必须 ≥ 1**。
- `MAP_CODEC_NONEMPTY` 由 `FluidIngredient.makeMapCodec()` 产生，该方法是 `NeoForgeExtraCodecs.dispatchMapOrElse(typeCodec, getter, codecGetter, fallback = singleOrTagCodec())`：
  - 若 JSON 里有 `type` 键 → 按 `type` 分派到对应的 `FluidIngredientType`；
  - 若没有 `type` 键 → 回退 `singleOrTagCodec()`，即 `xor(SingleFluidIngredient.MAP_CODEC, TagFluidIngredient.MAP_CODEC)`；
  - `SingleFluidIngredient` 的字段名是 **`fluid`**（`ldc "fluid"`），`TagFluidIngredient` 的字段名是 **`tag`**（`ldc "tag"`），失败信息为 "Basic fluid ingredient should be either a fluid or a tag!"。

由此可得 `FLAT_CODEC` 的可用写法：

```json
{"fluid":"minecraft:water","amount":100}          // TFC 全部 pot 配方使用的形式
{"tag":"tfc:usable_in_pot","amount":100}          // 同一 flat codec 的 tag 分支（TFC 自带数据未使用）
{"type":"tag","tag":"tfc:usable_in_pot","amount":100}   // 显式 dispatch 形式
```

**实证提醒**：TFC 自带全部 214 个 pot 配方文件 + 1 个 bloomery 配方，**100% 使用 `{"fluid":"<具体流体 id>","amount":N}` 形式**；对 `data/tfc/recipe/**` 全树做正则搜索 `(fluid_ingredient|"fluid"|fluid_output)"\s*:\s*\{[^}]*"tag"` **命中 0 次**。因此"tag 形式可用"是**从 NeoForge codec 结构推得**的结论，TFC 官方数据中无样例。

---

### 附录 A4-4：证据文件索引与「未能核实」清单

##### A4-4.1 本组引用的 TFC 源码文件

| 文件（相对 `moddev/src-ref/TFC-decompiled`） | 用到的内容 |
| --- | --- |
| `net/dries007/tfc/common/recipes/PotRecipe.java` | `CODEC`（第 48 行）、字段（50-53）、`matches`（66-77）、`getType`（83-85）、`isHotEnough`（99-101）、`getOutput` 默认（107-109） |
| `net/dries007/tfc/common/recipes/SimplePotRecipe.java` | `CODEC` + `validate`（44-50）、`STREAM_CODEC`（51）、字段（52-54）、`getOutput`（72-81）、`favorNewFluidStack`（83-89）、`getSerializer`（91-94）、`SimpleOutput`（96-106） |
| `net/dries007/tfc/common/recipes/SoupPotRecipe.java` | `CODEC`（53）、`OUTPUT_TYPE`（55-58）、常量（59-60）、`ingredientsToServings`（62-64）、`getOutput`（70-119）、`getSerializer`（121-124）、`SoupOutput`（126-166） |
| `net/dries007/tfc/common/recipes/JamPotRecipe.java` | `CODEC`（51）、`OUTPUT_TYPE`（53-58）、字段（59-61）、`getResultItem`（70-73）、`getOutput`（79-83）、`getSerializer`（85-88）、`JamOutput`（90-143） |
| `net/dries007/tfc/common/recipes/LoomRecipe.java` | `CACHE`（51）、`CODEC`（52）、字段（54-57）、`getRecipe`（59-62）、`matches`/`assemble`（71-78）、`getSerializer`/`getType`（101-107）、`isSpecial`（109-112） |
| `net/dries007/tfc/common/recipes/FoodCombiningCraftingRecipe.java` | 全文 89 行（单例、`matches`、`assemble`、`getRemainingItems`、`canCraftInDimensions`、`getSerializer`；**无 `CODEC`、无 `getType`**） |
| `net/dries007/tfc/common/recipes/BloomeryRecipe.java` | `CODEC`（48）、字段（50-53）、getter（62-72）、`matchesInput`（74-84）、`consumeInput`（86-94）、`assembleOutput`（96-98）、`getResultItem`（100-103）、`getSerializer`/`getType`（105-111） |
| `net/dries007/tfc/common/recipes/TFCRecipeTypes.java` | 20 个 type 注册（44-63），确认**无** `pot_soup`/`pot_jam`/`food_combining` |
| `net/dries007/tfc/common/recipes/TFCRecipeSerializers.java` | serializer 注册名（64-66、70、74、80-81） |
| `net/dries007/tfc/common/recipes/RecipeSerializerImpl.java` | `MapCodec.unit` 单例序列化器（19-23） |
| `net/dries007/tfc/common/recipes/ISimpleRecipe.java` | `isSpecial`/`getResultItem`/`canCraftInDimensions` 默认实现（19-29） |
| `net/dries007/tfc/common/recipes/INoopInputRecipe.java` | `NoopInput` 契约与三个 `fail` 默认实现（21-37） |
| `net/dries007/tfc/common/recipes/IRecipePredicate.java` | 全文 9 行 |
| `net/dries007/tfc/common/recipes/RecipeHelpers.java` | `setCraftingInput`（70-84）、`getRecipe`（128-150）、`getRecipes`（171-177） |
| `net/dries007/tfc/common/recipes/input/NonEmptyInput.java` | `RecipeInput` 的宽松实现（13-26） |
| `net/dries007/tfc/common/recipes/ingredients/TFCIngredients.java` | 7 个自定义 ingredient 注册（41-48） |
| `net/dries007/tfc/common/recipes/ingredients/AndIngredient.java` | `children` 字段（32） |
| `net/dries007/tfc/common/recipes/ingredients/NotRottenIngredient.java` | `MapCodec.unit`（42-45）、`test`（29-31） |
| `net/dries007/tfc/common/recipes/ingredients/LacksTraitIngredient.java` | `trait` 字段（27） |
| `net/dries007/tfc/common/recipes/outputs/PotOutput.java` | 接口全文 106 行（注册表、3 种类型、default 方法） |
| `net/dries007/tfc/common/recipes/outputs/ItemStackProvider.java` | `CODEC`（35）、`getStack`（92-101）、`dependsOnInput`（103-109） |
| `net/dries007/tfc/common/recipes/outputs/ItemStackModifier.java` | `CODEC` 分派（22）、`Context`（33-37） |
| `net/dries007/tfc/common/recipes/outputs/ItemStackModifiers.java` | 22 个类型注册（57-78） |
| `net/dries007/tfc/common/recipes/outputs/ItemStackModifierType.java` | 全文 18 行 |
| `net/dries007/tfc/common/blockentities/PotBlockEntity.java` | 常量与预热（83-85）、`handleCooking`（140-177）、`updateCachedRecipe`（211-215）、`isBoiling`（217-219）、`interactWithOutput`（233-243）、`PotInventory`（256-320） |
| `net/dries007/tfc/common/blockentities/IPotInventory.java` | 全文 20 行 |
| `net/dries007/tfc/common/container/PotContainer.java` | 槽位布局与 shift 行为（36-66） |
| `net/dries007/tfc/client/screen/PotScreen.java` | 界面（43-47） |
| `net/dries007/tfc/common/blockentities/LoomBlockEntity.java` | 常量（52-53）、`tick`（63-88）、`onRightClick`（102-146）、`isItemValid`（195-205）、`getSlotStackLimit`（226-232）、`updateCachedRecipe`（239-250） |
| `net/dries007/tfc/common/blockentities/rotation/PowerLoomBlockEntity.java` | 全文 94 行 |
| `net/dries007/tfc/common/blockentities/BloomeryBlockEntity.java` | 缓存字段（78）、`getCachedRecipe`（145-149）、`addItemsFromWorld`（256-309）、`completeRecipe`（328-357）、`updateCachedRecipe`（359-373） |
| `net/dries007/tfc/common/container/TFCWorkbenchContainer.java` | `extends CraftingMenu`（20）（R-22 的驱动证据） |
| `net/dries007/tfc/util/SelfTests.java` | pot 流体校验（303-306）、bloomery 唯一性（313-316）、loom 唯一性（318-321） |
| `net/dries007/tfc/util/Helpers.java` | `perfectMatchExists`（1124-1140） |
| `net/dries007/tfc/compat/jei/JEIIntegration.java` | 三种 pot 配方同属 `TFCRecipeTypes.POT`（214-216）、点击区（286）、BLOOMERY/LOOM 类型（159、164） |
| `net/dries007/tfc/compat/emi/EmiIntegration.java` | 三种 pot 配方同属 `TFCRecipeTypes.POT`（235-247）、BLOOMERY/LOOM 映射（226、229） |
| `net/dries007/tfc/client/render/blockentity/LoomBlockEntityRenderer.java` | 用 `getRecipe()`/`getInProgressTexture()` 渲染（63、88-92） |
| `net/dries007/tfc/client/render/blockentity/PowerLoomBlockEntityRenderer.java` | 动力织机渲染（46 起） |

##### A4-4.2 本组引用的 jar 内真实文件

| 相对路径（相对 `moddev/jar-extract`） | 用途 |
| --- | --- |
| `data/tfc/recipe/pot/black_dye.json` | R-18 样例（流体输出） |
| `data/tfc/recipe/pot/lye.json` | R-18 样例（5 输入 → 流体） |
| `data/tfc/recipe/pot/canola_oil_water.json` | R-18 样例（低温对照） |
| `data/tfc/recipe/pot/food/boiled_egg_1.json` | R-18 样例（物品输出，纯 ItemStack） |
| `data/tfc/recipe/pot/food/cooked_rice_5.json` | R-18 样例（5↔5 对齐） |
| `data/tfc/recipe/pot/jam_banana_canning_1.json` | R-18 样例（`modifiers` + `uses_all_fluid:false`） |
| `data/tfc/recipe/pot/jam_banana_canning_2.json` | R-20 对照样例（文件名带 jam 但 type 是 pot） |
| `data/tfc/recipe/pot/jam_banana_canning_5.json` | R-18 样例（5 输入 5 输出） |
| `data/tfc/recipe/pot/soup_3.json`、`soup_4.json`、`soup_5.json` | R-19 全部 3 个样例 |
| `data/tfc/recipe/pot/jam_banana_2.json` | R-20 样例 |
| `data/tfc/recipe/pot/jam_strawberry_4.json` | R-20 样例 |
| `data/tfc/recipe/pot/jam_wintergreen_berry_3.json` | R-20 样例 |
| `data/tfc/recipe/loom/wool_cloth.json`、`white_wool.json`、`silk_cloth.json`、`burlap_cloth.json`、`unrefined_paper.json` | R-21 全部 5 个样例 |
| `data/tfc/recipe/bloomery/raw_iron_bloom.json` | R-23 唯一样例 |
| `data/tfc/recipe/crafting/food_combining.json` | R-22 唯一样例 |
| `data/tfc/recipe/crafting/casting.json` | R-22 同族对照（`tfc:casting_crafting`） |
| `data/tfc/recipe/crafting/blowpipe_with_glass.json` | A4-2.1 的 `stack` + `modifiers` 并存样例 |

##### A4-4.3 本组使用的字节码核实命令

```powershell
# Minecraft 侧：确认 CustomRecipe / CraftingRecipe.getType() 的行为
$jar = "D:\111\最强服务器\.minecraft\libraries\net\minecraft\client\1.21.1-20240808.144430\client-1.21.1-20240808.144430-srg.jar"
javap -p    -cp $jar net.minecraft.world.item.crafting.CustomRecipe
javap -p -c -cp $jar net.minecraft.world.item.crafting.CraftingRecipe     # getType() => getstatic RecipeType.CRAFTING
javap -p    -cp $jar net.minecraft.world.item.crafting.RecipeType         # CRAFTING / SMELTING / ...

# NeoForge 侧：确认 SizedFluidIngredient / SizedIngredient / FluidIngredient 的 JSON 字段
$d  = "D:\111\最强服务器\.minecraft\libraries\net\neoforged\neoforge\21.1.248"
$cp = "$d\neoforge-21.1.248-client.jar;$d\neoforge-21.1.248-universal.jar"
javap -p    -cp $cp net.neoforged.neoforge.fluids.crafting.SizedFluidIngredient   # FLAT_CODEC / NESTED_CODEC
javap -c -p -cp $cp net.neoforged.neoforge.fluids.crafting.SizedFluidIngredient   # 字段名 ingredient / amount
javap -c -p -cp $cp net.neoforged.neoforge.fluids.crafting.FluidIngredient        # singleOrTag / dispatch，字符串 "fluid"、"tag"
javap -c -p -cp $cp net.neoforged.neoforge.fluids.crafting.SingleFluidIngredient  # ldc "fluid"
javap -c -p -cp $cp net.neoforged.neoforge.fluids.crafting.TagFluidIngredient     # ldc "tag"
javap -p    -cp $cp net.neoforged.neoforge.common.crafting.SizedIngredient        # FLAT_CODEC / NESTED_CODEC
javap -c -p -cp $cp net.neoforged.neoforge.common.crafting.SizedIngredient        # 字段名 count / ingredient，“Size must be positive”
```

##### A4-4.4 「未能核实」清单（明确列出）

| 编号 | 未能核实的点 | 已检查过的内容 | 现状说明 |
| --- | --- | --- | --- |
| U-1 | `ExtraCodecs.POSITIVE_INT` 是否允许 `0` | 已读 `javap` 输出中的错误字符串 "Size must be positive" 与字段引用 `net/minecraft/util/ExtraCodecs.POSITIVE_INT` | 依据命名与错误文本判定为「必须 ≥ 1」，但**未反编译 `ExtraCodecs` 本体**逐行确认。若需要绝对精确，可对 `client-1.21.1-*-srg.jar` 的 `net.minecraft.util.ExtraCodecs` 做 `javap -c` 核实 |
| U-2 | `SizedFluidIngredient.FLAT_CODEC` 对 `tag` 形式的实际接受情况 | 已用 `javap -c` 确认 `FLAT_CODEC` 基于 `FluidIngredient.MAP_CODEC_NONEMPTY = makeMapCodec() = dispatchMapOrElse(..., fallback = singleOrTagCodec())`，且 `singleOrTagCodec` 的 `xor` 两支字段名为 `fluid` / `tag` | 结论「`{"tag":...,"amount":N}` 可用」来自 codec 结构与失败信息推断；**TFC 官方 215 个相关配方文件中 0 个使用 tag 形式**，无实机加载样例佐证 |
| U-3 | `RecipeManager` 对同一 `RecipeType` 下多个 `matches` 成功的配方如何选择 | 已确认 `PotBlockEntity` 用 `getRecipeManager().getRecipeFor(TFCRecipeTypes.POT.get(), ...)`（`PotBlockEntity.java:212-215`），且三种 pot serializer 共用 `tfc:pot` 类型 | 采用顺序由原版 `RecipeManager` 内部实现决定，**本仓库无 `net/minecraft` 源码**，未逐行核实其遍历顺序；文中已按「实现依赖顺序、TFC 数据靠互斥避免冲突」谨慎表述 |
| U-4 | `food_combining` 在 `RecipeManager.byType(CRAFTING)` 桶中的具体注册路径 | 已核实 `FoodCombiningCraftingRecipe` 无 `getType()`、父类 `CustomRecipe` 无 `getType()`、`CraftingRecipe.getType()` 字节码返回 `RecipeType.CRAFTING` | recipe type = `minecraft:crafting` 的结论**已由字节码确认**；但「原版 `RecipeManager` 用 `recipe.getType()` 作为分桶键」这一环节属原版实现，本仓库无源码，未逐行核实 |
| U-5 | `SoupPotRecipe.getOutput` 中 `FoodData(4, water, saturation, 0, nutrition, 3.5f)` 各参数的确切含义 | 已读 `SoupPotRecipe.java:116` 与常量 `SOUP_HUNGER_VALUE = 4`、`SOUP_DECAY_MODIFIER = 3.5f` | `FoodData` 的构造参数顺序需读 `net/dries007/tfc/common/component/food/FoodData.java` 才能逐项命名；本组未展开（不影响 pot_soup 的 JSON 字段结论） |
| U-6 | `tfc:heat`（`HeatIngredient`）与 `tfc:fluid_content`（`FluidContentIngredient`）的 JSON 字段 | 已确认二者在 `TFCIngredients.java:46-47` 注册，且各自 `CODEC` 存在 | 未逐行读取这两个类的 `CODEC`，故 A4-3.2 表中标注为「见该类 `CODEC`」而未给出字段名 |

除以上 6 条外，本组所有字段表条目均能在指明的源码行找到出处。

---

## 第 5 部分　合成类配方与通用输出（R-24 ~ R-29）


> 版本基准：TerraFirmaCraft-NeoForge-1.21.1-4.2.10 / Minecraft 1.21.1 / NeoForge 21.1.248
> 证据来源（全部为本地文件，无网络依赖）：
> - 反编译源码根：`moddev/src-ref/TFC-decompiled`（下文相对路径均以此为根）
> - 真实 jar 解包内容：`moddev/jar-extract`（下文「jar 内路径」以 `jar-extract` 为根）
> - jar 条目清单（交叉核对用）：`moddev/inventory/TFC.resources.txt`
> - 反编译产物**没有参数名与注释**，但 `CODEC` 定义、`record` 组件、字段常量完整可读；TFC 自有类的字段一律从**该类自身的 `CODEC` 逐行读出**确认。
> - **Minecraft 本体类（`net.minecraft.world.item.crafting.*`、`net.neoforged.*`）不在本反编译树中**。凡涉及它们的结论均在正文显式标注依据来源，并在「附录 A5-C」集中列出未核实项。
> - **字节码交叉验证（本组额外引入）**：`.minecraft/libraries/net/minecraft/client/1.21.1-20240808.144430/client-1.21.1-20240808.144430-srg.jar`，用 `javap -p -c` 读取原版类成员与常量池字符串。该 jar 中的原版类使用官方命名（字段名明文），可直接读出 `CODEC` 的 `fieldOf("...")` / `optionalFieldOf("...", default)` 参数与默认值，从而**把原版 `crafting_shaped` / `crafting_shapeless` 的字段名、必需性、默认值从「按 JSON 归纳」升级为「字节码确认」**。下文凡标注「（字节码确认）」处即指此来源。

### 组 A5 覆盖范围

本组负责以下 5 种配方类型，全部围绕「工作台合成」与「高炉熔炼」两条链路：

| 编号 | type id | 实现类 | 本组对应小节 |
| --- | --- | --- | --- |
| R-24 | `tfc:blast_furnace` | `net.dries007.tfc.common.recipes.BlastFurnaceRecipe` | 高炉熔炼（催化剂 + 熔融流体 → 输出流体） |
| R-25 | `minecraft:crafting_shaped` | `net.minecraft.world.item.crafting.ShapedRecipe`（**不在反编译树中**） | 原版有序合成在 TFC 数据包中的实际用法 |
| R-26 | `minecraft:crafting_shapeless` | `net.minecraft.world.item.crafting.ShapelessRecipe`（**不在反编译树中**） | 原版无序合成在 TFC 数据包中的实际用法 |
| R-27 | `tfc:advanced_shaped_crafting` | `net.dries007.tfc.common.recipes.AdvancedShapedRecipe` | TFC 扩展有序合成（`ItemStackProvider` 输出 + 输入槽位定位） |
| R-28 | `tfc:advanced_shapeless_crafting` | `net.dries007.tfc.common.recipes.AdvancedShapelessRecipe` | TFC 扩展无序合成（`ItemStackProvider` 输出 + 主原料判定） |
| R-29 | （全局公用章节） | `ItemStackProvider` / `ItemStackModifier` / `TFCIngredients` | 通用输出与原料，供主控文档全局复用 |

编号说明：本组严格使用 `R-24` ~ `R-29`，不占其它组的编号空间。

##### 关于「crafting 目录 3001 个文件」的口径澄清

任务描述提到 TFC 的 `data/tfc/recipe/crafting/` 下有 3001 个文件。实测结果如下（两条独立证据一致）：

| 口径 | 数量 | 证据 |
| --- | --- | --- |
| jar 清单中 `data/tfc/recipe/crafting` 前缀条目总数 | **3001** | `moddev/inventory/TFC.resources.txt` 中以 `data/tfc/recipe/crafting` 开头的行数为 3001（其中 106 条是目录条目，如 `data/tfc/recipe/crafting/jar/`） |
| jar 清单中实际 `.json` 文件数 | **2895** | 同上清单中匹配 `*.json` 的行数为 2895 |
| `jar-extract/data/tfc/recipe/crafting` 下实际 `.json` 文件数 | **2895** | `Get-ChildItem -Recurse -Filter *.json` 实测 |
| 该目录下全部文件（不限扩展名） | **2895** | 无额外非 JSON 文件 |

结论：**3001 是「文件 + 目录条目」的合计**，真实配方 JSON 为 **2895** 个。下文所有分布统计均以 2895 为分母。

##### crafting 目录内 `type` 分布（实测，按 `"type":"<id>"` 全量匹配，含嵌套字段）

| type | 出现次数 | 说明 |
| --- | --- | --- |
| `minecraft:crafting_shaped` | 1669 | 顶层配方类型（原版 serializer） |
| `tfc:not_rotten` | 757 | 嵌套 ingredient（出现在 `key` / `ingredients` 内） |
| `tfc:and` | 757 | 嵌套 ingredient |
| `minecraft:crafting_shapeless` | 569 | 顶层配方类型 |
| `tfc:damage_crafting_remainder` | 474 | 嵌套 modifier（`remainder.modifiers` 内） |
| `tfc:advanced_shaped_crafting` | 372 | 顶层配方类型（TFC serializer） |
| `tfc:advanced_shapeless_crafting` | 283 | 顶层配方类型（TFC serializer） |
| `tfc:fluid_content` | 234 | 嵌套 ingredient |
| `tfc:meal` | 186 | 嵌套 modifier |
| `tfc:copy_forging_bonus` | 126 | 嵌套 modifier |
| `tfc:copy_oldest_food` | 48 | 嵌套 modifier |
| `tfc:extra_products` | 9 | 嵌套 modifier |
| `tfc:copy_food` | 6 | 嵌套 modifier |
| `tfc:copy_input` | 4 | 嵌套 modifier |
| `tfc:add_bait_to_rod` | 2 | 嵌套 modifier |
| `tfc:lacks_trait` | 2 | 嵌套 ingredient |
| `tfc:add_glass` | 2 | 嵌套 modifier |
| `tfc:casting_crafting` | 1 | 顶层配方类型（特殊 crafting，无字段） |
| `tfc:flower_cutting` | 1 | 嵌套 modifier |
| `tfc:add_powder` | 1 | 嵌套 modifier |
| `tfc:food_combining` | 1 | 顶层配方类型（特殊 crafting，无字段） |
| `tfc:round_creation_date` | 1 | 嵌套 modifier |
| `tfc:add_trait` | 1 | 嵌套 modifier |

顶层配方类型合计：1669 + 569 + 372 + 283 + 1 + 1 = **2895**，与文件数完全吻合，说明 crafting 目录下**每个文件恰好一个顶层配方**，不存在一个文件多配方的写法。

---

### [R-24] tfc:blast_furnace —— 高炉熔炼

##### R-24.1 类型标识与实现类

| 项目 | 值 | 证据 |
| --- | --- | --- |
| JSON `type` | `tfc:blast_furnace` | `net/dries007/tfc/common/recipes/TFCRecipeSerializers.java:77` |
| serializer id | `tfc:blast_furnace` | `TFCRecipeSerializers.java:77`（`register("blast_furnace", BlastFurnaceRecipe.CODEC, BlastFurnaceRecipe.STREAM_CODEC)`） |
| recipe type id | `tfc:blast_furnace` | `net/dries007/tfc/common/recipes/TFCRecipeTypes.java:61`（`BLAST_FURNACE = register("blast_furnace")`） |
| 实现类全名 | `net.dries007.tfc.common.recipes.BlastFurnaceRecipe` | `net/dries007/tfc/common/recipes/BlastFurnaceRecipe.java:45` |
| 类型形态 | `record BlastFurnaceRecipe(SizedFluidIngredient inputFluid, Ingredient catalyst, FluidStack outputFluid)` | `BlastFurnaceRecipe.java:45` |
| 实现的接口 | `INoopInputRecipe`（→ `ISimpleRecipe<NoopInput>`）、`IRecipePredicate<FluidStack>` | `BlastFurnaceRecipe.java:45-46` |
| `getType()` 返回值 | `TFCRecipeTypes.BLAST_FURNACE.get()` | `BlastFurnaceRecipe.java:98-100` |
| `getSerializer()` 返回值 | `TFCRecipeSerializers.BLAST_FURNACE.get()` | `BlastFurnaceRecipe.java:94-96` |

**关键点**：该配方实现的 `Recipe` 输入类型是 `NoopInput`（占位符），因此**不能**通过 `Recipe#matches(RecipeInput, Level)` 正常匹配；`INoopInputRecipe` 把 `matches(NoopInput, Level)` / `assemble(NoopInput, ...)` / `getRemainingItems(NoopInput)` 全部实现为直接抛 `UnsupportedOperationException`（`net/dries007/tfc/common/recipes/INoopInputRecipe.java:23-36`）。真正的匹配入口是接口 `IRecipePredicate<FluidStack>` 的 `matches(FluidStack)`（`BlastFurnaceRecipe.java:69-72`）与静态查询方法 `get(Level, ItemStack)` / `get(Level, FluidStack)`（`BlastFurnaceRecipe.java:52-67`）。

##### R-24.2 完整字段表

字段全部来自 `BlastFurnaceRecipe` 自身的 `CODEC`（`BlastFurnaceRecipe.java:48`），**三个字段全部必需，没有可选字段、没有默认值**。

`CODEC` 原文（`BlastFurnaceRecipe.java:48`）：

```java
public static final MapCodec<BlastFurnaceRecipe> CODEC = RecordCodecBuilder.mapCodec(i -> i.group(
    SizedFluidIngredient.FLAT_CODEC.fieldOf("fluid").forGetter(c -> c.inputFluid),
    Ingredient.CODEC.fieldOf("catalyst").forGetter(c -> c.catalyst),
    FluidStack.CODEC.fieldOf("result").forGetter(c -> c.outputFluid)
).apply(i, BlastFurnaceRecipe::new));
```

| 字段名 | 类型 | 必需/可选 | 默认值 | 语义 | 源码行 |
| --- | --- | --- | --- | --- | --- |
| `fluid` | `SizedFluidIngredient`（NeoForge，`FLAT_CODEC`） | **必需** | 无 | 输入熔融流体与所需数量。判据为 `inputFluid.ingredient().test(moltenFluid)`，即只需流体种类匹配（`BlastFurnaceRecipe.java:57`、`69-72`）；数量 `amount` 用于计算产出倍率 | `BlastFurnaceRecipe.java:48` |
| `catalyst` | `Ingredient`（原版/NeoForge，`Ingredient.CODEC`） | **必需** | 无 | 催化剂物品判据，`matchesCatalyst(stack)` 直接调用 `catalyst.test(stack)`（`BlastFurnaceRecipe.java:82-84`）。TFC 数据包中固定为 `tfc:powder/flux` | `BlastFurnaceRecipe.java:48` |
| `result` | `FluidStack`（NeoForge，`FluidStack.CODEC`） | **必需** | 无 | 输出流体原型；实际产出量 = `outputFluid.getAmount() * (输入量 / fluid.amount())`（`BlastFurnaceRecipe.java:86-92`） | `BlastFurnaceRecipe.java:48` |

字段形态说明（**依据真实 JSON 归纳**，`SizedFluidIngredient.FLAT_CODEC` 与 `FluidStack.CODEC` 的定义位于 NeoForge，**不在本反编译树中**）：

- `fluid` 的 JSON 是 `{"fluid":"<fluid id>","amount":<int>}`（示例文件即为此形态）。`FLAT_CODEC` 会把「流体 id + 数量」摊平在同一层对象内，故 `amount` 与 `fluid` 同级。
- `result` 的 JSON 是 `{"id":"<fluid id>","amount":<int>}`。注意与 `fluid` 的键名差异：**输入用 `fluid`，输出用 `id`**。
- `Ingredient.CODEC` 支持的形式：`{"item":"..."}`、`{"tag":"..."}`、`["<ingredient>","<ingredient>"]`（数组 = 或关系）、以及 NeoForge 自定义 `{"type":"<ingredient type>",...}`。本配方数据包中催化剂用的是 `{"item":"tfc:powder/flux"}`。

##### R-24.3 真实 JSON 样例（该目录下全部文件）

`data/tfc/recipe/blast_furnace/` 目录下**只有一个文件**，全文如下（jar 内路径相对 `jar-extract` 根）：

**样例 1 —— `data/tfc/recipe/blast_furnace/pig_iron.json`**（唯一文件，全部内容）：

```json
{"type":"tfc:blast_furnace","catalyst":{"item":"tfc:powder/flux"},"fluid":{"amount":1,"fluid":"tfc:metal/cast_iron"},"result":{"amount":1,"id":"tfc:metal/pig_iron"}}
```

逐字段对应：

| JSON 片段 | 字段 | 语义 |
| --- | --- | --- |
| `"type":"tfc:blast_furnace"` | serializer id | 选中 `BlastFurnaceRecipe` |
| `"catalyst":{"item":"tfc:powder/flux"}` | `catalyst` | 催化剂必须是 `tfc:powder/flux`（萤石粉） |
| `"fluid":{"amount":1,"fluid":"tfc:metal/cast_iron"}` | `fluid` | 每 1 mB 生铁熔液参与一次转化 |
| `"result":{"amount":1,"id":"tfc:metal/pig_iron"}` | `result` | 产出 1 mB 生铁（pig iron）熔液 |

即：**生铁 → 铁（cast_iron → pig_iron）**，比例 1:1。由于 `assembleFluidOutput` 使用整数倍（`inputFluid.getAmount() / this.inputFluid.amount()`，`BlastFurnaceRecipe.java:87`），输入 1000 mB 时一次性产出 1000 mB 并消耗 1000 mB。

##### R-24.4 游戏内触发条件与调用点

高炉配方**完全由 `BlastFurnaceBlockEntity` 驱动**，核实如下（`net/dries007/tfc/common/blockentities/BlastFurnaceBlockEntity.java`）：

| 位置 | 代码要点 | 作用 |
| --- | --- | --- |
| `BlastFurnaceBlockEntity.java:167` | `BlastFurnaceRecipe recipe = BlastFurnaceRecipe.get(level, entity.inputFluid);` 紧随 `recipe.assembleFluidOutput(entity.inputFluid)`（`:169`）与 `entity.outputFluidTank.fill(...)`（`:170`） | **每个 tick**：先把输入物品熔化成流体并入输入槽（`:145-166`），再用输入流体查表产出输出流体 |
| `BlastFurnaceBlockEntity.java:421` | `BlastFurnaceRecipe recipe = BlastFurnaceRecipe.get(this.level, stack);` | 从高炉周围的 `ItemEntity` 中挑选**第一条能匹配的物品**，确定为该炉的缓存配方 |
| `BlastFurnaceBlockEntity.java:437` | `this.cachedRecipe.matchesInput(stack)` | 后续物品按「原料」归类 |
| `BlastFurnaceBlockEntity.java:442` | `this.cachedRecipe.matchesCatalyst(stack)` | 物品按「催化剂」归类（走 `catalyst.test`） |
| `BlastFurnaceBlockEntity.java:447` | `Helpers.isItem(stack, TFCTags.Items.BLAST_FURNACE_FUEL)` | 燃料判定**不走配方**，直接查物品标签 |
| `BlastFurnaceBlockEntity.java:471-473` | `updateCachedRecipe()`：`this.cachedRecipe = !this.inputStacks.isEmpty() ? BlastFurnaceRecipe.get(this.level, this.inputStacks.get(0)) : null;` | 输入队列变化时重算缓存配方；若为 `null` 则 `dumpItems()` 吐出物品（`:410-413`） |

熔炼链路细节：

1. 输入物品必须**先能通过 `HeatingRecipe` 变成流体**，否则永远不匹配。`BlastFurnaceRecipe.get(Level, ItemStack)`（`BlastFurnaceRecipe.java:52-62`）的实现顺序是：
   - `HeatingRecipe heatRecipe = HeatingRecipe.getRecipe(stack);`
   - `FluidStack moltenFluid = heatRecipe.assembleFluid(stack);`
   - 在 `RecipeHelpers.getRecipes(level, TFCRecipeTypes.BLAST_FURNACE)` 的全部配方中找第一条 `inputFluid.ingredient().test(moltenFluid)` 成立者。
2. 温度门槛由 `HeatingRecipe` 自己把关：`BlastFurnaceBlockEntity.java:156` 要求 `inputRecipe.isValidTemperature(inputHeat.getTemperature())` 才执行 `assembleFluid(inputStack)`。
3. 温度的推进由 `HeatCapability.addTemp(inputHeat, entity.temperature)`（`:155`）完成，`entity.temperature` 由 `HeatCapability.adjustDeviceTemp(...)`（`:143`）依据鼓风（`airTicks`）与燃烧温度更新。
4. 输出流体经 `Capabilities.FluidHandler.BLOCK` 向下方方块转移（`:176-179`），转移成功时还会把热量传给下方方块（`:178`）。

`RecipeHelpers.getRecipes` 的实现是 `((RecipeManagerAccessor) recipeManager).invoke$byType(type.get())`（`net/dries007/tfc/common/recipes/RecipeHelpers.java:175-177`），即按 recipe type 取全部配方后**线性扫描**——高炉配方只有 1 条，无性能顾虑。

##### R-24.5 限制与陷阱

- **`fluid` 的 `amount` 决定倍率，不决定「够不够」**：`matches(FluidStack)` 只用 `ingredient().test(...)`，即只要流体种类对、数量 > 0 就能匹配；不足一个 `amount` 整数倍时余数保留在输入槽（`assembleFluidOutput` 只 `shrink` 整数倍部分，`BlastFurnaceRecipe.java:88-89`）。当整数倍为 0 时 `outputFluid.setAmount(0)`，产出空流体，`fill` 无效果。
- **催化剂的种类由数据包硬编码在唯一一条配方里**，一条高炉配方只有一个 `catalyst`；若要支持多种催化剂，需在 `catalyst` 使用 tag 或数组形式。
- **高炉配方与「配方类型」一一对应**：`get(Level, FluidStack)`（`BlastFurnaceRecipe.java:65-67`）返回**第一条**匹配的配方（`RecipeHelpers.getHolder` 线性取首个，`RecipeHelpers.java:163-169`），因此多条高炉配方之间没有优先级字段，靠数据包加载顺序决定。
- 该配方不产生物品，`INoopInputRecipe` 的 `assemble(NoopInput, ...)` 抛异常（`INoopInputRecipe.java:28-31`），故 JEI/EMI 展示需要各自的兼容层（`compat/jei/category/BlastFurnaceRecipeCategory.java:44-46`、`compat/emi/recipe/EmiBlastFurnaceRecipe.java`）。

---

### [R-25] minecraft:crafting_shaped —— 原版有序合成（TFC 数据包实测）

##### R-25.1 类型标识与实现类

| 项目 | 值 | 证据 |
| --- | --- | --- |
| JSON `type` | `minecraft:crafting_shaped` | 真实 JSON 实测（TFC 数据包 1669 个文件使用该 type） |
| serializer id | `minecraft:crafting_shaped`（原版 `RecipeSerializer`） | 原版注册；**Minecraft 本体，不在本反编译树中** |
| recipe type id | `minecraft:crafting` | **字节码确认**：`CraftingRecipe#getType()` 的 default 实现返回 `RecipeType.CRAFTING`；`ShapedRecipe` 未覆写它。原版类不在本反编译树中 |
| 实现类全名 | `net.minecraft.world.item.crafting.ShapedRecipe` | 原版类；`AdvancedShapedRecipe` 的 `extends ShapedRecipe`（`net/dries007/tfc/common/recipes/AdvancedShapedRecipe.java:49-50`）可间接证明其存在与继承关系 |
| 辅助 pattern 类型 | `net.minecraft.world.item.crafting.ShapedRecipePattern` | `AdvancedShapedRecipe.java:51` 直接复用 `ShapedRecipePattern.MAP_CODEC` / `STREAM_CODEC`（`AdvancedShapedRecipe.java:51-52`） |

**TFC 未注册、也未替换该 serializer**：`TFCRecipeSerializers`（`TFCRecipeSerializers.java:56-83`）中的 26 个 `Id` 常量里没有任何 `crafting_shaped` / `crafting_shapeless` 条目；`TFCRecipeTypes`（`TFCRecipeTypes.java:43-63`）中的 20 个 recipe type 里也没有 `crafting`。因此 `minecraft:crafting_shaped` 100% 走原版实现。

**TFC 未用 mixin 接管原版合成**：`net/dries007/tfc/mixin/` 下共 32 个顶层 mixin + `accessor` / `client` 子包，逐一核对后**没有任何一个针对 `ShapedRecipe`、`ShapelessRecipe`、`CraftingMenu`、`RecipeBook*`、`CraftingInput`**。唯一与配方加载有关的 mixin 是 `RecipeManagerMixin.java:29-35`，它只在原版配方解析报错时调用 `SelfTests.reportExternalError()` 上报自检状态，不改变任何配方语义。

##### R-25.2 完整字段表

> **依据来源声明**：`ShapedRecipe` 与 `ShapedRecipePattern` 属 Minecraft 本体，**不在本反编译树中**。下表字段名/必需性/默认值由**四方面证据**共同确定：
> 1. TFC 数据包中 1669 个真实 `minecraft:crafting_shaped` JSON 的**实测键集合**；
> 2. `AdvancedShapedRecipe.java:51` 对 `ShapedRecipePattern.MAP_CODEC` 的复用（证明 `pattern` / `key` 由该 codec 提供）；
> 3. `AdvancedShapedRecipe.java:60` 对父类构造器 `super("", CraftingBookCategory.MISC, pattern, ItemStack.EMPTY, showNotification)` 的调用（证明父类持有 `group`、`category`、`pattern`、`result`、`showNotification` 五个状态）；
> 4. **字节码确认**：`javap -p -c net.minecraft.world.item.crafting.ShapedRecipe$Serializer`，其常量池直接给出 `fieldOf("group")` 之外的四个键名与必需性 —— 原文为
>    `ldc // String group` + `optionalFieldOf`（默认 `""`）、
>    `ldc // String category` + `Codec.fieldOf`（**必需**）、
>    `ldc // String result` + `Codec.fieldOf`（**必需**）、
>    `ldc // String show_notification` + `optionalFieldOf`（默认 `true`，与 TFC `AdvancedShapedRecipe.java:51` 的 `optionalFieldOf("show_notification", true)` 一致）；
>    而 `pattern` / `key` 来自 `net.minecraft.world.item.crafting.ShapedRecipePattern$Data` 的 `MAP_CODEC`，其字节码为
>    `ExtraCodecs.strictUnboundedMap(SYMBOL_CODEC, Ingredient.CODEC_NONEMPTY).fieldOf("key")` 与 `PATTERN_CODEC.fieldOf("pattern")`（两者均 **必需**）。
>
> 未能在本树中核实的部分见「附录 A5-C」。

| 字段名 | 类型 | 必需/可选 | 默认值 | 语义 | 实测出现次数（2895 文件中） |
| --- | --- | --- | --- | --- | --- |
| `pattern` | 字符串数组（每项一个字符或空格，行内每个字符对应 `key` 的一个键） | **必需**（字节码确认：`PATTERN_CODEC.fieldOf("pattern")`，`PATTERN_CODEC = Codec.STRING.listOf().comapFlatMap(...)`） | 无 | 有序排列的行字符串；空格表示「必须为空」。数组长度即配方高度，字符串长度即配方宽度。TFC 数据包中均为 1~3 行、宽度 ≤ 3 | 2041（= 1669 shaped + 372 advanced_shaped） |
| `key` | map（键为单字符，值为 `Ingredient`） | **必需**（字节码确认：`ExtraCodecs.strictUnboundedMap(SYMBOL_CODEC, Ingredient.CODEC_NONEMPTY).fieldOf("key")`；`strict` 表示未知键报错，`CODEC_NONEMPTY` 表示不允许空 ingredient） | 无 | 字符 → 原料的映射。值支持 `{"item":...}`、`{"tag":...}`、`[{...},{...}]`（数组 = 或）、NeoForge 自定义 `{"type":"..."}` | 2041 |
| `result` | `ItemStack` | **必需**（字节码确认：`Codec.fieldOf("result")`） | 无 | 产出物品。TFC 数据包中**全部为对象形式且必带 `count`**：`{"count":N,"id":"<item id>"}`（2520 个文件命中 `"result":{"count"`） | 2893（全部含 `result` 的配方文件） |
| `group` | 字符串 | 可选 | `""` | 配方分组名（仅影响配方书归类显示） | **0**（TFC 数据包从未使用） |
| `category` | `CraftingBookCategory` 枚举（`building` / `redstone` / `equipment` / `misc`） | **必需**（字节码确认：`Codec.fieldOf("category")`） | 无（必须显式给出；TFC 全部写作 `misc`） | 配方书分类页签。注意：**TFC 的 `tfc:advanced_*` 类型没有此字段**，其 `category` 固定为 `MISC`（`AdvancedShapedRecipe.java:60`、`AdvancedShapelessRecipe.java:65`） | 2238（全部原版 shaped + shapeless 文件；取值 `misc` 2238 次，其它取值 0 次） |
| `show_notification` | 布尔 | 可选 | `true` | 首次解锁该配方时是否弹出提示 | **0**（TFC 数据包从未使用） |

实测键集合的交叉校验（全部 2895 个 crafting 文件）：

| 表达式 | 命中文件数 | 含义 |
| --- | --- | --- |
| 含 `"pattern"` | 2041 | 有序配方（原版 + advanced）总数 |
| 含 `"key"` | 2041 | 与 `pattern` 完全一致，说明两者总是成对出现 |
| 含 `"ingredients"` | 852（实测；= 569 原版 + 283 advanced，与 `2895 - 2041` 恰好互补） | 无序配方（原版 + advanced）总数 |
| `"result":{"count"` | 2520 | 产出带数量的配方 |
| `"result":{"id"`（无 count） | 0 | 不存在「省略数量」的写法 |
| `"result":"<字符串>"` | 0 | 不存在字符串简写 |
| `"ingredients":[`  且首项为字符串 | 0 | 无序配方不存在字符串简写 |
| 含 `"group"` | 0 | 从未使用 |
| 含 `"category"` | 2238 | 恰好等于原版 shaped + shapeless 文件数（1669 + 569），说明**原版两类的 `category` 是必需字段**，TFC 每个原版合成配方都显式写了它 |
| 含 `show_notification` | 0 | 从未使用 |

**TFC 是否用 `ItemStackProvider` 形式的 `result`？——否。**
检索全库 JSON：字符串 `item_stack_provider` 出现 **0** 次（不存在 `{"type":"tfc:item_stack_provider", ...}` 这种写法）；`"modifiers"` 只在 **655** 个 advanced 配方文件中出现（`tfc:advanced_shaped_crafting` 372 + `tfc:advanced_shapeless_crafting` 283 = 655，完全吻合），原版 `minecraft:crafting_shaped` / `minecraft:crafting_shapeless` 文件中**从不出现 `modifiers`**。因此结论是：**原版两类的 `result` 只接受纯 `ItemStack`，需要使用 `ItemStackProvider`（modifiers / remainder）时必须改用 R-27 / R-28 的 TFC 类型。**

##### R-25.3 真实 JSON 样例（2 个，其中 1 个含 tag ingredient）

**样例 1 —— `data/tfc/recipe/crafting/ladder.json`**（含 tag ingredient `tfc:lumber`）：

```json
{"type":"minecraft:crafting_shaped","category":"misc","key":{"L":{"tag":"tfc:lumber"}},"pattern":["L L","L L","L L"],"result":{"count":16,"id":"minecraft:ladder"}}
```

读法：`key.L` 是标签 `tfc:lumber`（任意 TFC 木材）；`pattern` 三行两列，只有左右两列有 `L`，中间列为空格；产出 16 个 `minecraft:ladder`；`category` 为 `misc`。

**样例 2 —— `data/tfc/recipe/crafting/obsidian_axe.json`**（含 **数组形式的 key 值**，即「木棍 或 骨头」）：

```json
{"type":"minecraft:crafting_shaped","category":"misc","key":{"S":[{"tag":"c:rods/wooden"},{"item":"minecraft:bone"}],"X":{"item":"tfc:obsidian_axe_head"}},"pattern":["X","S"],"result":{"count":1,"id":"tfc:obsidian_axe"}}
```

读法：`key.S` 是**数组**，数组内任意一项匹配即可（NeoForge `/ 原版 Ingredient 的 or 语义`）；`pattern` 为 1 列 2 行，上为斧头、下为柄；产出 1 个黑曜石斧。

**补充样例 3 —— `data/tfc/recipe/crafting/cake.json`**（原版 shaped 但 `key` 里直接使用 **TFC 自定义 ingredient**，说明自定义 ingredient 在原版配方里同样可用）：

```json
{"type":"minecraft:crafting_shaped","category":"misc","key":{"E":{"type":"tfc:and","children":[{"item":"minecraft:egg"},{"type":"tfc:not_rotten"}]},"F":{"type":"tfc:and","children":[{"tag":"c:foods/flour"},{"type":"tfc:not_rotten"}]},"M":{"type":"tfc:fluid_content","fluid":{"amount":100,"fluid":"minecraft:water"}},"S":{"tag":"tfc:foods/sweeteners"}},"pattern":[" M ","SES","FFF"],"result":{"count":1,"id":"tfc:cake"}}
```

**补充样例 4 —— `data/tfc/recipe/crafting/activator_rail.json`**（纯 tag 原料 + 原版物品混合）：

```json
{"type":"minecraft:crafting_shaped","category":"misc","key":{"I":{"tag":"c:rods/steel"},"S":{"tag":"c:rods/wooden"},"T":{"item":"minecraft:redstone_torch"}},"pattern":["ISI","ITI","ISI"],"result":{"count":12,"id":"minecraft:activator_rail"}}
```

##### R-25.4 游戏内触发条件

| 环节 | 说明 | 证据 |
| --- | --- | --- |
| 配方来源 | 数据包加载时由原版 `RecipeManager` 按 serializer id `minecraft:crafting_shaped` 实例化为 `ShapedRecipe` | 原版行为（**不在反编译树中**）；TFC 侧未注册同名 serializer，见 R-25.1 |
| 归类 | 归入 `RecipeType.CRAFTING`（`minecraft:crafting`），与 shapeless、TFC 的 advanced 两类**同处一个类型桶** | **字节码确认**：`CraftingRecipe#getType()` 是 default 方法，字节码为 `getstatic RecipeType.CRAFTING`；`ShapedRecipe` 未覆写 `getType()`，`AdvancedShapedRecipe` 也未覆写，故三类同桶 |
| 触发菜单 | 任何 `CraftingMenu` 及其子类。TFC 的工作台容器 `net/dries007/tfc/common/container/TFCWorkbenchContainer` **直接 `extends CraftingMenu`**（`TFCWorkbenchContainer.java:19-20`），构造器 `super(id, playerInventory)` / `super(id, playerInventory, access)`（`:24`、`:29`）完全委托原版，只用 `stillValid` 追加了「必须是 `TFCTags.Blocks.WORKBENCHES` 且距离 ≤ 8 格」的判定（`:33-35`） | `net/dries007/tfc/common/container/TFCWorkbenchContainer.java` |
| 判定 | 原版 `CraftingMenu` 依次对 `RecipeType.CRAFTING` 下的配方调用 `matches(CraftingInput, Level)`；`ShapedRecipe#matches` 内部做宽度/高度平移与镜像匹配 | 原版行为；TFC 在 `AdvancedShapedRecipe` 中通过 `RecipeHelpers.translateMatch` **重写了同样的平移/镜像逻辑**，可用于反证原版语义（`RecipeHelpers.java:183-214`） |
| 其余入口 | `CraftingMenu` 之外的任何自定义合成逻辑若按 `RecipeType.CRAFTING` 取配方，也会拿到这些配方 | — |

补充：TFC 数据包中**有 1 个 `tfc:food_combining` 与 1 个 `tfc:casting_crafting`** 顶层配方（位于 crafting 目录），它们的 serializer 分别是 `RecipeSerializerImpl(FoodCombiningCraftingRecipe.INSTANCE)` 与 `RecipeSerializerImpl(CastingCraftingRecipe.INSTANCE)`（`TFCRecipeSerializers.java:80-81`），属于「单例（无字段）合成配方」，实现类 `FoodCombiningCraftingRecipe` / `CastingCraftingRecipe` 直接实现 `CraftingRecipe` 并参与 `RecipeType.CRAFTING`，但它们**不是本组的 R-25 类型**，仅在此说明该目录出现次数。

##### R-25.5 限制与陷阱

- **宽度/高度上限为 3×3，且空格是保留符号**。字节码证据（`javap -p -c 'net.minecraft.world.item.crafting.ShapedRecipePattern$Data'` 常量池）直接给出五条校验错误文本：
  - `Invalid pattern: too many columns, 3 is maximum`
  - `Invalid pattern: too many rows, 3 is maximum`
  - `Invalid pattern: each row must be the same width`
  - `Invalid pattern: empty pattern not allowed`
  - `Invalid key entry: ' ' is a reserved symbol.`
  
  另有 TFC 侧旁证：`AdvancedShapelessRecipe.CODEC` 用 `ShapedRecipePattern.getMaxHeight() * ShapedRecipePattern.getMaxWidth()` 作为无序配方原料数量上限（`AdvancedShapelessRecipe.java:56`），说明上限存在且为 3。数据包中也**没有**任何超出 3×3 的有序配方。
- **`pattern` 与 `key` 必须自洽**：`pattern` 中出现的每个非空格字符都必须能在 `key` 中找到，否则配方解析失败（原版校验，不在本树）。
- **原版配方不能带 `remainder` 与 `modifiers`**：见 R-25.2 的实测结论；需要「工具磨损返还」「额外产物」「食物合并」等行为必须改用 advanced 类型。
- **原版配方的 `result` 固定**：即使输入是带热量/新鲜度的 TFC 物品，产出也不会继承任何组件（除非物品自身有合成剩余物 `getCraftingRemainingItem`）。TFC 中「用锤子砸板」这类需要继承输入组件的配方全部改用 R-27/R-28。
- `group` 与 `show_notification` 在 TFC 数据包中**完全未使用**，但字段依然可用（原版 codec 支持），写法分别为 `"group":"some_group"` 与 `"show_notification":false`。

---

### [R-26] minecraft:crafting_shapeless —— 原版无序合成（TFC 数据包实测）

##### R-26.1 类型标识与实现类

| 项目 | 值 | 证据 |
| --- | --- | --- |
| JSON `type` | `minecraft:crafting_shapeless` | 字节码确认：`RecipeSerializer` 接口 `<clinit>` 的常量池包含 `ldc // String crafting_shapeless`（`javap -p -c net.minecraft.world.item.crafting.RecipeSerializer`）；TFC 数据包中 569 个文件使用该 type |
| serializer 常量 | `RecipeSerializer.SHAPELESS_RECIPE` | 字节码确认：`javap -p net.minecraft.world.item.crafting.RecipeSerializer` 列出 `public static final RecipeSerializer<ShapelessRecipe> SHAPELESS_RECIPE` |
| recipe type id | `minecraft:crafting` | **字节码确认**：`CraftingRecipe#getType()` 是 default 方法，其字节码为 `getstatic RecipeType.CRAFTING`；`ShapelessRecipe` 未覆写 `getType()` |
| 实现类全名 | `net.minecraft.world.item.crafting.ShapelessRecipe` | 原版类（**不在本反编译树中**）；`AdvancedShapelessRecipe` 的 `extends ShapelessRecipe`（`AdvancedShapelessRecipe.java:52-53`）可间接证明 |
| 状态字段 | `group` / `category` / `result` / `ingredients`（**共 4 个，无 `showNotification`**） | 字节码确认：`javap -p net.minecraft.world.item.crafting.ShapelessRecipe` 的实例字段列表 |

**TFC 未替换该 serializer，也未用 mixin 接管**：见 R-25.1 的两条结论（`TFCRecipeSerializers` 无该条目；`mixin` 包中无任何针对 `ShapelessRecipe` 的注入）。

##### R-26.2 完整字段表

> **依据来源**：字段名 / 必需性 / 默认值全部来自**字节码确认** —— `javap -p -c 'net.minecraft.world.item.crafting.ShapelessRecipe$Serializer'` 的常量池依次给出
> `ldc // String group` + `optionalFieldOf`（默认 `""`）、
> `ldc // String category` + `Codec.fieldOf`（必需）、
> `ldc // String result` + `Codec.fieldOf`（必需）、
> `invokeinterface Codec.listOf` + `ldc // String ingredients` + `Codec.fieldOf`（必需）；
> 并给出两条校验错误文本：`No ingredients for shapeless recipe`、`Too many ingredients for shapeless recipe`。
> 全部 569 个真实 JSON 文件的实测键集合与之一致（含 `ingredients` 569、含 `result` 569、含 `category` 569、含字符串简写 0）。

| 字段名 | 类型 | 必需/可选 | 默认值 | 语义 | 实测出现次数 |
| --- | --- | --- | --- | --- | --- |
| `ingredients` | `Ingredient` 数组 | **必需**（字节码确认：`Codec.listOf().fieldOf("ingredients")`） | 无 | 无序原料列表。**顺序无关**，但列表长度必须与配方实际消耗的原料个数一致（多一个或少一个都不匹配）。元素支持 `{"item":...}`、`{"tag":...}`、`[{...},{...}]`、NeoForge 自定义 `{"type":"..."}` | 852（= 569 原版 + 283 advanced，与 `2895 - 2041` 完全吻合） |
| `result` | `ItemStack` | **必需**（字节码确认：`Codec.fieldOf("result")`） | 无 | 产出物品，TFC 数据包中全部为 `{"count":N,"id":"<item id>"}` 对象形式 | 569 |
| `category` | `CraftingBookCategory` 枚举 | **必需**（字节码确认：`Codec.fieldOf("category")`） | 无 | 配方书分类。TFC 数据包中 569 个文件全部写作 `"misc"` | 569 |
| `group` | 字符串 | 可选（字节码确认：`optionalFieldOf`） | `""` | 配方分组名 | **0**（TFC 数据包从未使用） |

**`show_notification` 字段在无序合成中不存在**，这是本类型与原版有序合成的**唯一字段级差异**：

- 字节码层面：`ShapelessRecipe` 的实例字段只有 `group` / `category` / `result` / `ingredients`，**没有 `showNotification`**；而 `ShapedRecipe` 有 `showNotification`。对 client jar 的 `net/minecraft/world/item/crafting/` 包做全包字符串扫描，`show_notification` 这个键名**只出现在 `ShapedRecipe$Serializer.class` 一个类中**（扫描方式：逐个读取该包下每个 `.class` 的字节并按 UTF-8 解码后匹配）。
- 数据层面：TFC 数据包中 `show_notification` 出现 0 次，无任何反例，无法从数据反证；这是「字节码确认」而非「数据归纳」的结论。
- 语义层面：`Recipe#showNotification()` 是 default 方法，字节码为 `iconst_1; ireturn`，即**默认返回 `true`**，所以无序合成相当于「永远 `show_notification = true`」。

**TFC 是否用 `ItemStackProvider` 形式的 `result`？——否**（同 R-25.2）：全库 `item_stack_provider` 出现 0 次，`modifiers` 只出现在 655 个 advanced 配方文件中，569 个 `minecraft:crafting_shapeless` 文件**无一**含 `modifiers`。

##### R-26.3 真实 JSON 样例（2 个）

**样例 1 —— `data/tfc/recipe/crafting/stick_from_bunch.json`**（单原料）：

```json
{"type":"minecraft:crafting_shapeless","category":"misc","ingredients":[{"item":"tfc:stick_bunch"}],"result":{"count":9,"id":"minecraft:stick"}}
```

读法：1 个 `tfc:stick_bunch` → 9 个 `minecraft:stick`。注意 `ingredients` 是**数组**（有序合成用的是 `key` 映射），这里只有一项。

**样例 2 —— `data/tfc/recipe/crafting/gunpowder.json`**（4 原料，含重复元素）：

```json
{"type":"minecraft:crafting_shapeless","category":"misc","ingredients":[{"item":"tfc:powder/saltpeter"},{"item":"tfc:powder/saltpeter"},{"item":"tfc:powder/sulfur"},{"item":"tfc:powder/charcoal"}],"result":{"count":4,"id":"minecraft:gunpowder"}}
```

读法：**同一 ingredient 元素可以重复出现**，表示需要两个硝石粉。无序合成不关心摆放位置，只要求网格中的物品集合能被这 4 项一一配对。

**补充样例 3 —— `data/tfc/recipe/crafting/black_dye.json`**（数组形式的 ingredient，即「或」关系）：

```json
{"type":"minecraft:crafting_shapeless","category":"misc","ingredients":[[{"item":"tfc:powder/coke"},{"item":"tfc:powder/charcoal"}]],"result":{"count":1,"id":"minecraft:black_dye"}}
```

读法：`ingredients` 只有一项，而该项本身是一个**数组**（焦炭粉或木炭粉皆可）。

##### R-26.4 游戏内触发条件

| 环节 | 说明 | 证据 |
| --- | --- | --- |
| 实例化 | 原版 `RecipeManager` 按 serializer id `minecraft:crafting_shapeless` 构造 `ShapelessRecipe` | 字节码确认 serializer id；TFC 未注册同名 serializer |
| 归类 | `RecipeType.CRAFTING`（与 shaped、advanced 两类同桶） | `CraftingRecipe#getType()` default 字节码 |
| 触发菜单 | 任何 `CraftingMenu` 子类；TFC 的 `TFCWorkbenchContainer` 直接继承 `CraftingMenu`（`TFCWorkbenchContainer.java:19-20`） | `net/dries007/tfc/common/container/TFCWorkbenchContainer.java` |
| 匹配 | 原版 `ShapelessRecipe#matches(CraftingInput, Level)`：把非空输入物品与 `ingredients` 逐项配对 | 原版行为（**不在反编译树中**）；旁证：TFC 的 `AdvancedShapelessRecipe` 复刻了同一套「输入网格遍历」思路（`AdvancedShapelessRecipe.java:91-99`） |

##### R-26.5 限制与陷阱

- **原料个数上限为 9（3×3）**：字节码给出错误文本 `Too many ingredients for shapeless recipe`（上限值由 `ShapedRecipePattern` 的 3×3 推出）。TFC 的 advanced 版本把这一上限写成了显式常量表达式（`ShapedRecipePattern.getMaxHeight() * ShapedRecipePattern.getMaxWidth()`，`AdvancedShapelessRecipe.java:56`）。
- **零原料非法**：字节码给出 `No ingredients for shapeless recipe`。
- **不能用 `remainder` / `modifiers`**：需要「工具自动磨损」或「复制输入」时必须改用 R-28。
- **`category` 在本类型是必需字段**，漏写会导致配方解析失败（与直觉相反，这点在与其它模组/版本对照时最容易踩坑）。
- **不支持 `show_notification`**：写了该键会在 `ExtraCodecs`/`RecordCodecBuilder` 的严格解析下报错（未知字段），不要照搬有序合成的写法。

---

### [R-27] tfc:advanced_shaped_crafting —— TFC 扩展有序合成

##### R-27.1 类型标识与实现类

| 项目 | 值 | 证据 |
| --- | --- | --- |
| JSON `type` | `tfc:advanced_shaped_crafting` | `net/dries007/tfc/common/recipes/TFCRecipeSerializers.java:82` |
| serializer id | `tfc:advanced_shaped_crafting` | `TFCRecipeSerializers.java:82`（`register("advanced_shaped_crafting", AdvancedShapedRecipe.CODEC, AdvancedShapedRecipe.STREAM_CODEC)`） |
| recipe type id | **`minecraft:crafting`**（TFC **没有**为它注册独立 recipe type） | `TFCRecipeTypes.java:43-63` 的 20 个 type 中没有 crafting 相关项；`AdvancedShapedRecipe` 未覆写 `getType()`（全文 105 行内无该方法），继承链 `AdvancedShapedRecipe → ShapedRecipe → CraftingRecipe`，而 `CraftingRecipe#getType()` 的 default 实现返回 `RecipeType.CRAFTING`（**字节码确认**：`javap -p -c net.minecraft.world.item.crafting.CraftingRecipe` → `getstatic RecipeType.CRAFTING`） |
| 实现类全名 | `net.dries007.tfc.common.recipes.AdvancedShapedRecipe` | `net/dries007/tfc/common/recipes/AdvancedShapedRecipe.java:49` |
| 父类 | `net.minecraft.world.item.crafting.ShapedRecipe` | `AdvancedShapedRecipe.java:49-50` |
| 自有状态字段 | `result: ItemStackProvider`、`remainder: Optional<ItemStackProvider>`、`inputSlot: int`、`inputRow: int`、`inputColumn: int` | `AdvancedShapedRecipe.java:53-57` |
| 父类状态字段 | `pattern`、`result`、`group`、`category`、`showNotification`（字节码确认自 `ShapedRecipe` 实例字段） | 构造器 `super("", CraftingBookCategory.MISC, pattern, ItemStack.EMPTY, showNotification)`（`AdvancedShapedRecipe.java:60`） |
| `getSerializer()` | `TFCRecipeSerializers.ADVANCED_SHAPED_CRAFTING.get()` | `AdvancedShapedRecipe.java:96-98` |

##### R-27.2 完整字段表

`CODEC` 原文（`AdvancedShapedRecipe.java:51`，此处已按可读性换行，逻辑完全等价）：

```java
public static final MapCodec<AdvancedShapedRecipe> CODEC = RecordCodecBuilder.mapCodec(i -> i.group(
    ShapedRecipePattern.MAP_CODEC.forGetter(c -> c.pattern),                    // → pattern + key 两个顶层字段
    Codec.BOOL.optionalFieldOf("show_notification", true).forGetter(ShapedRecipe::showNotification),
    ItemStackProvider.CODEC.fieldOf("result").forGetter(c -> c.result),
    ItemStackProvider.CODEC.optionalFieldOf("remainder").forGetter(c -> c.remainder),
    Codec.INT.optionalFieldOf("input_row", 0).forGetter(c -> c.inputRow),
    Codec.INT.optionalFieldOf("input_column", 0).forGetter(c -> c.inputColumn)
).apply(i, AdvancedShapedRecipe::new));
```

| 字段名 | 类型 | 必需/可选 | 默认值 | 语义 | 源码行 |
| --- | --- | --- | --- | --- | --- |
| `pattern` | 字符串数组 | **必需** | 无 | 与 R-25 完全相同的行字符串数组；由 `ShapedRecipePattern.MAP_CODEC` 提供，3×3 上限与「空格为保留符号」的校验一并继承 | `AdvancedShapedRecipe.java:51` |
| `key` | map（字符 → `Ingredient`） | **必需** | 无 | 同上，来自 `ShapedRecipePattern.MAP_CODEC`。**支持全部 TFC 自定义 ingredient**（`tfc:and` / `tfc:not_rotten` / `tfc:fluid_content` 等），因为内层用的是 NeoForge 扩展过的 `Ingredient.CODEC_NONEMPTY` | `AdvancedShapedRecipe.java:51` |
| `show_notification` | 布尔 | 可选 | **`true`** | 与父类同义；TFC 数据包 655 个 advanced 文件**没有一个写它** | `AdvancedShapedRecipe.java:51` |
| `result` | **`ItemStackProvider`** | **必需** | 无 | 输出。**这是与父类最本质的差异**：不是 `ItemStack` 而是 `ItemStackProvider`，可携带 `modifiers`（数组）并可按输入动态计算 | `AdvancedShapedRecipe.java:51`、`53` |
| `remainder` | `ItemStackProvider` | 可选 | `Optional.empty()`（即缺省时走父类 `super.getRemainingItems(input)`，返回**全空**的剩余物列表） | 「工具耐久返还 / 合成剩余物」的提供者。**一旦填写，整个剩余物列表都由它接管**：对每个与 `inputSlot` 对应物品相同的槽位调用 `provider.getStack(stack.copyWithCount(1))`，其它槽位仍走物品自身的 `getCraftingRemainingItem()`（`RecipeHelpers.getRemainderItemsWithProvider`，`RecipeHelpers.java:86-102`） | `AdvancedShapedRecipe.java:51`、`54`、`81-90` |
| `input_row` | 整数 | 可选 | `0` | 「主输入」在 `pattern` 中的**行号**（0 起）。用于 `remainder` 与依赖输入的 modifier 定位到底哪个槽是「被消耗的工具/原料」 | `AdvancedShapedRecipe.java:51`、`56`、`64` |
| `input_column` | 整数 | 可选 | `0` | 「主输入」在 `pattern` 中的**列号**（0 起） | `AdvancedShapedRecipe.java:51`、`57`、`65` |

**字段总数对比**：`minecraft:crafting_shaped` 有 6 个（`pattern` / `key` / `result` / `category` / `group` / `show_notification`），`tfc:advanced_shaped_crafting` 有 7 个（多出 `remainder` / `input_row` / `input_column`，**少掉 `category` / `group`**，`result` 换型）。

**注意 `inputSlot` 不是 JSON 字段**：它是构造器根据 `input_row`/`input_column` 算出来的内部值：`this.inputSlot = RecipeHelpers.dissolveRowColumn(inputRow, inputColumn, pattern.width())`（`AdvancedShapedRecipe.java:63`），而 `dissolveRowColumn(row, column, width) = column + row * width`（`RecipeHelpers.java:179-181`）。因此 `input_row=1, input_column=0` 在宽度为 3 的 pattern 中对应索引 3。

**为什么 `input_row`/`input_column` 要存在**：合成网格里的物品会因为摆放平移与镜像而**不落在配方 pattern 的原始坐标上**。`RecipeHelpers.translateMatch`（`RecipeHelpers.java:183-198`）会在 3×3 网格中穷举 `startCol` / `startRow` 并按**正向与镜像**两种方式比对 pattern，命中后把配方索引换算成**网格中的真实槽位**：

```java
// RecipeHelpers.java:191-194
return width - 1 - targetIndex % width + startCol + (targetIndex / width + startRow) * input.width();  // 镜像命中
return targetIndex % width + startCol + (targetIndex / width + startRow) * input.width();              // 正向命中
```

`assemble` 因此能正确地取到「玩家实际摆的那把刀/锤子」（`AdvancedShapedRecipe.java:70-71`），而不是固定槽位。

##### R-27.3 与父类 `ShapedRecipe` 的行为差异

| 行为 | 父类 `ShapedRecipe` | `AdvancedShapedRecipe` | 源码 |
| --- | --- | --- | --- |
| 输出字段类型 | `ItemStack result`（构造时固定） | `ItemStackProvider result`（可含 modifiers、可按输入动态变化） | `AdvancedShapedRecipe.java:53` |
| 交给父类的 `result` | — | **恒为 `ItemStack.EMPTY`**（`super("", CraftingBookCategory.MISC, pattern, ItemStack.EMPTY, showNotification)`），父类的 `result` 字段被完全绕过 | `AdvancedShapedRecipe.java:60` |
| `assemble(CraftingInput, Provider)` | 返回固定的 `result.copy()` | `RecipeHelpers.setCraftingInput(input)` → 定位主输入槽 → `result.getSingleStack(inputStack)` → `clearCraftingInput()` | `AdvancedShapedRecipe.java:68-75` |
| `getResultItem(Provider)` | 返回固定 `result` | 返回 `result.getEmptyStack()`，即以 `ItemStack.EMPTY` 作为输入、`NO_RANDOM_CHANCE` 上下文求值（用于显示预览，随机类 modifier 不会真的掷骰） | `AdvancedShapedRecipe.java:77-79`；`ItemStackProvider.java:80-82` |
| `getRemainingItems(CraftingInput)` | 每个槽位调用物品自身的 `getCraftingRemainingItem()` | 有 `remainder` 时由该 provider 接管（见上表）；无 `remainder` 时**回退到父类**（`.orElseGet(() -> super.getRemainingItems(input))`） | `AdvancedShapedRecipe.java:81-90` |
| `isSpecial()` | `ShapedRecipe` **未覆写**，用 `Recipe#isSpecial()` 的 default = `false`（**字节码确认**：`iconst_0; ireturn`） | `return this.result.dependsOnInput();` 即只要任一 modifier 声明依赖输入就返回 `true` | `AdvancedShapedRecipe.java:92-94`；`ItemStackProvider.java:103-109` |
| `category()` | 由构造器参数决定 | **恒为 `CraftingBookCategory.MISC`**（无 JSON 字段可改） | `AdvancedShapedRecipe.java:60` |
| `getGroup()` | 由构造器参数决定 | **恒为 `""`**（无 JSON 字段可改） | `AdvancedShapedRecipe.java:60` |
| `canCraftInDimensions(int, int)` | `ShapedRecipe` 自身实现（字节码确认该方法存在于 `ShapedRecipe`） | **未覆写**，完全继承父类实现 | `AdvancedShapedRecipe.java` 全文无该方法 |
| `getSerializer()` | `RecipeSerializer.SHAPED_RECIPE` | `TFCRecipeSerializers.ADVANCED_SHAPED_CRAFTING.get()` | `AdvancedShapedRecipe.java:96-98` |
| `getType()` | 未覆写 → `RecipeType.CRAFTING` | **未覆写** → 同样是 `RecipeType.CRAFTING` | `AdvancedShapedRecipe.java` 全文无该方法 |

关于 `isSpecial()` 的意义：`Recipe#isSpecial()` 的 default 为 `false`，TFC 在结果依赖输入时返回 `true`。`isSpecial` 在原版的用途（是否参与配方书/提示的展示逻辑）属于 Minecraft 本体行为，**未在本树中核实**（见附录 A5-C）。但可以确定的是：TFC 的 `AdvancedShapedRecipe` **一旦带任何 `dependsOnInput()` 的 modifier，`isSpecial()` 就会变成 `true`**，这正是 `tfc:copy_input` / `tfc:copy_heat` / `tfc:meal` 等 modifier 的效果所在（各 modifier 的 `dependsOnInput()` 见 R-29.2 表）。

##### R-27.4 真实 JSON 样例（3 个，另附 show_notification 示意）

**样例 1 —— `data/tfc/recipe/crafting/metal/block/bismuth.json`**（含 `input_column` + `remainder`，最典型的「工具锻造」写法）：

```json
{"type":"tfc:advanced_shaped_crafting","input_column":2,"key":{"H":{"tag":"c:tools/hammer"},"S":{"tag":"c:sheets/bismuth"},"W":{"tag":"minecraft:planks"}},"pattern":[" SH","SWS"," S "],"remainder":{"modifiers":[{"type":"tfc:damage_crafting_remainder"}]},"result":{"count":8,"id":"tfc:metal/block/bismuth"}}
```

读法：
- `pattern` 为 3 行 3 列：`(0,0)` 空、`(0,1)`=`S`、`(0,2)`=`H`；`(1,0)`=`S`、`(1,1)`=`W`、`(1,2)`=`S`；`(2,0)` 空、`(2,1)`=`S`、`(2,2)` 空。
- `key.H = {"tag":"c:tools/hammer"}`（任意锤子）、`key.S = {"tag":"c:sheets/bismuth"}`（铋板）、`key.W = {"tag":"minecraft:planks"}`（任意木板）。
- **`input_column: 2` 且 `input_row` 缺省为 `0`** → 主输入是 pattern 第 0 行第 2 列的 `H`，即**锤子**（宽度 3，故 `inputSlot = 2 + 0*3 = 2`）。
- `remainder` 用 `tfc:damage_crafting_remainder`：锤子被消耗时按耐久磨损后留在原位（`DamageCraftingRemainderModifier`，`outputs/DamageCraftingRemainderModifier.java:28-40`）。
- `result` 只有 `{"count":8,"id":"tfc:metal/block/bismuth"}`，**没有 modifiers**——这走的是 `ItemStackProvider.CODEC` 中 `Codec.either(...)` 的**右侧分支**（纯 `ItemStack`），解析后被包装为「无 modifier 的 provider」。
- 本配方**没有** `input_row`、`show_notification`（都用默认值）。

**样例 2 —— `data/tfc/recipe/crafting/food/barley_bread_jam_sandwich_jss_jam.json`**（含 `remainder` + `tfc:meal` modifier，覆盖「输出依赖输入」）：

```json
{"type":"tfc:advanced_shaped_crafting","key":{"B":{"type":"tfc:and","children":[{"item":"tfc:food/barley_bread"},{"type":"tfc:not_rotten"}]},"J":{"type":"tfc:and","children":[{"tag":"tfc:foods/jam"},{"type":"tfc:not_rotten"}]},"K":{"tag":"c:tools/knife"},"S":{"type":"tfc:and","children":[{"tag":"tfc:usable_in_jam_sandwich"},{"type":"tfc:not_rotten"}]}},"pattern":["KB ","JSS"," B "],"remainder":{"modifiers":[{"type":"tfc:damage_crafting_remainder"}]},"result":{"modifiers":[{"type":"tfc:meal","food":{"decay_modifier":4.5,"hunger":4,"saturation":1.0,"water":0.5},"portions":[{"ingredient":{"item":"tfc:food/barley_bread"},"nutrient_modifier":0.675,"saturation_modifier":0.5,"water_modifier":0.5},{"nutrient_modifier":0.8,"saturation_modifier":0.8,"water_modifier":0.8}]}],"stack":{"count":1,"id":"tfc:food/barley_bread_jam_sandwich"}}}
```

读法：
- `key` 中 `B` / `J` / `S` 全部是 `tfc:and` 组合 ingredient（标签/物品 + `tfc:not_rotten`），只有 `K` 是纯标签（刀）。
- **`input_row` / `input_column` 均缺省（都是 0）** → 主输入 = pattern 第 0 行第 0 列 = `K`（刀）。
- `result` 是**带 `stack` + `modifiers` 的完整 `ItemStackProvider` 对象**：基底是 1 个 `tfc:food/barley_bread_jam_sandwich`，再应用 `tfc:meal` modifier，后者用 `food`（`FoodData`）与 `portions`（每种原料的养分/水分/饱和度系数）在合成时**根据实际放入的食物动态计算**营养值。
- 该 modifier **未声明 `dependsOnInput()`**（`MealModifier` 未覆写，见 `outputs/MealModifier.java`），因此 `isSpecial()` 返回 `false`；但它读取 `RecipeHelpers.getCraftingInput()`（`MealModifier.java:62`）来遍历实际输入，所以**行为上仍然依赖输入**——这是「是否 Special」与「是否读输入」两个不同维度的例证。

**补充样例 3 —— `data/tfc/recipe/crafting/metal/axe/bismuth_bronze.json`**（最短的 advanced_shaped：只有 `pattern`/`key`/`result`，其余字段全用默认值）：

```json
{"type":"tfc:advanced_shaped_crafting","key":{"S":{"tag":"c:rods/wooden"},"X":{"item":"tfc:metal/axe_head/bismuth_bronze"}},"pattern":["X","S"],"result":{"modifiers":[{"type":"tfc:copy_forging_bonus"}],"stack":{"count":1,"id":"tfc:metal/axe/bismuth_bronze"}}}
```

读法：宽 1 高 2；没有 `input_row`/`input_column`（都取 0，但本配方没有任何读输入的 modifier，所以无所谓）；没有 `remainder`；`result` 用 `copy_forging_bonus` 把斧头的锻造加成带给成品。

**关于 `show_notification` 的样例**：TFC 官方数据包中 **372 个 `tfc:advanced_shaped_crafting` 文件里没有任何一个写 `show_notification`**（实测 0 个），因此本节无法给出「来自 jar 的真实样例」。按 `AdvancedShapedRecipe.java:51` 的 `Codec.BOOL.optionalFieldOf("show_notification", true)`，其合法写法为：

```json
"show_notification": false
```

（放在 `advanced_shaped_crafting` 顶层；这一行是**依据 CODEC 构造的示意**，非 jar 内真实文件内容。同字段在原版 `minecraft:crafting_shaped` 中也可用，写法相同。）

##### R-27.5 触发条件与调用点

**结论：`tfc:advanced_shaped_crafting` 由原版合成台逻辑直接驱动，TFC 没有写任何 mixin 去接管它。**

完整的调用点排查（对 `net/dries007/tfc` 全树 grep `AdvancedShapedRecipe`，共 39 处匹配，全部列出）：

| 位置 | 类型 | 说明 |
| --- | --- | --- |
| `net/dries007/tfc/common/recipes/TFCRecipeSerializers.java:18, 82` | 注册 | import + `register("advanced_shaped_crafting", ...)` |
| `net/dries007/tfc/common/recipes/AdvancedShapedRecipe.java:49, 51, 59` | 定义 | 类、`CODEC`、构造器 |
| `net/dries007/tfc/util/DataGenerationHelpers.java:31, 271` | **数据生成（datagen）** | `Builder.shaped(...)` 在 `isAdvanced()` 为真时构造 `AdvancedShapedRecipe`，否则构造原版 `ShapedRecipe` |
| `net/dries007/tfc/compat/emi/EmiIntegration.java:64, 310-313` | 兼容层 | 遍历 `RecipeType.CRAFTING` 的配方，对 `instanceof AdvancedShapedRecipe` 者注册 `EmiAdvancedShapedRecipe` |
| `net/dries007/tfc/compat/emi/recipe/EmiAdvancedShapedRecipe.java:21, 27, 29, 33` | 兼容层 | EMI 展示：用 `recipe.getResultItem(...)` 取预览、用 `padIngredients` 把 pattern 补成 3×3 |
| `net/dries007/tfc/compat/jei/TFCCraftingExtensions.java:30` | 兼容层 | JEI 的 crafting 分类扩展（只扩展了 `AdvancedShapelessRecipe.class`，见 R-28.5） |

**没有**任何 `net/dries007/tfc/mixin/**` 引用它。因此原版 `CraftingMenu` 之所以能识别它，纯粹是因为：

1. 它实现了 `CraftingRecipe`（经 `ShapedRecipe`），`getType()` 返回 `RecipeType.CRAFTING`（`CraftingRecipe#getType()` default 方法的字节码为 `getstatic RecipeType.CRAFTING`）；
2. 它注册了 serializer，因此数据包加载时被实例化并放进 crafting 类型桶；
3. 它覆写了 `assemble` / `getResultItem` / `getRemainingItems` / `isSpecial`，这些正是 `CraftingMenu` 会调用的方法。

`TFCWorkbenchContainer extends CraftingMenu`（`TFCWorkbenchContainer.java:19-20`）是 TFC 工作台容器的落点，它没有任何合成逻辑改写，因此**TFC 工作台的合成行为 = 原版 `CraftingMenu` 行为 + TFC 配方集合**。

##### R-27.6 数据生成侧：TFC 自己在什么条件下产出 advanced 配方

这一点对理解「为什么 TFC 的 crafting 目录里 shaped 与 advanced 混放」很关键。`net/dries007/tfc/util/DataGenerationHelpers.java` 的 `Builder` 决定类型：

```java
// DataGenerationHelpers.java:278-280
private boolean isAdvanced() {
    return !this.remainder.isEmpty() || !this.outputs.isEmpty();
}

// DataGenerationHelpers.java:271（有序）
this.onFinish.accept(this.name, this.isAdvanced()
    ? new AdvancedShapedRecipe(pattern, true, ItemStackProvider.of(output, this.outputs), this.remainder(), this.inputRow, this.inputCol)
    : new ShapedRecipe("", CraftingBookCategory.MISC, pattern, output));

// DataGenerationHelpers.java:250（无序）
this.onFinish.accept(this.name, this.isAdvanced()
    ? new AdvancedShapelessRecipe(this.ingredients, ItemStackProvider.of(output, this.outputs), this.remainder(), Optional.ofNullable(this.primaryInput))
    : new ShapelessRecipe("", CraftingBookCategory.MISC, output, this.ingredients));
```

即：**官方数据包中，只要配方带 `remainder`（工具磨损返还）或带输出 modifier（如 `tfc:meal`、`tfc:copy_forging_bonus`），就会被生成成 `tfc:advanced_*`；反之则是原版 `minecraft:crafting_*`。** 这就是「2895 个文件里 2238 个是原版、655 个是 advanced」这一分布的成因。

同时 `Builder` 还带两条断言（`:248`、`:268`），说明了 advanced 的约束：

- 需要依赖输入时（`needsAdvInput`）必须显式调 `inputIsPrimary(Ingredient)`（无序）或 `source(int row, int col)`（有序），否则 datagen 失败；
- 「要么输出非空，要么必须提供输出 modifier」（`!this.outputs.isEmpty() || !output.isEmpty()`），这正是 `flower_cutting.json` 这类「`result` 只有 `modifiers`、`stack` 为默认 `ItemStack.EMPTY`」的配方得以存在的前提。

##### R-27.7 限制与陷阱

- **不能指定 `category` / `group`**：JSON 里写了会解析失败（CODEC 无这两项），且值恒为 `MISC` / `""`。若某个配方必须在配方书里归到别的页签，只能用原版 `minecraft:crafting_shaped`（但那样就没有 modifiers 了）。
- **`result` 必须写 `modifiers` 才能走左侧分支**：`ItemStackProvider.CODEC` 是 `Codec.either(带 modifiers 的 record, 纯 ItemStack)`，其中 `modifiers` 用 `fieldOf("modifiers")`（**必需**）。因此 **`{"stack":{...}}` 这样只写 `stack` 而不写 `modifiers` 的对象是非法 JSON**（左侧分支缺 `modifiers` 失败，右侧 `ItemStack.CODEC` 也解析不了 `stack` 键）。全库实测印证：不存在「含 `"result":{"stack"` 但整文件无 `modifiers`」的配方（检索结果为 0 个文件）。合法写法只有两种：
  - `"result": {"count":1,"id":"..."}`（纯物品）
  - `"result": {"stack":{...},"modifiers":[...]}` 或 `"result": {"modifiers":[...]}`（`stack` 可省略，默认 `ItemStack.EMPTY`）
- **`remainder` 的类型与 `result` 完全相同**，也必须写 `modifiers`：TFC 数据包中 655 个 advanced 配方里的 `remainder` 全部是 `{"modifiers":[...]}` 形式，**没有任何一个用字符串或纯物品对象**（实测：匹配 `"remainder":` 后跟非 `{` 的文件数为 0）。
- **`input_row` / `input_column` 只影响「哪个槽位被当作主输入」**，**不影响匹配**（匹配完全由 `pattern` + `key` 决定）。填错只会导致 modifier 取到错的物品（例如把 `damage_crafting_remainder` 作用到原料上而不是工具上），不会导致配方无法合成。
- **越界的 `input_row` / `input_column` 没有显式校验**：`dissolveRowColumn` 只做 `column + row * width`（`RecipeHelpers.java:179-181`），若索引超出 `pattern` 范围，`translateMatch` 会返回 `-1`，此时 `assemble` 用 `ItemStack.EMPTY` 作为输入（`AdvancedShapedRecipe.java:71`）。
- **`isSpecial()` 由 `result.dependsOnInput()` 决定，不看 `remainder`**：若只写了 `remainder`（如 `bismuth.json`），`isSpecial()` 仍为 `false`。

---

### [R-28] tfc:advanced_shapeless_crafting —— TFC 扩展无序合成

##### R-28.1 类型标识与实现类

| 项目 | 值 | 证据 |
| --- | --- | --- |
| JSON `type` | `tfc:advanced_shapeless_crafting` | `net/dries007/tfc/common/recipes/TFCRecipeSerializers.java:83` |
| serializer id | `tfc:advanced_shapeless_crafting` | `TFCRecipeSerializers.java:83`（`register("advanced_shapeless_crafting", AdvancedShapelessRecipe.CODEC, AdvancedShapelessRecipe.STREAM_CODEC)`） |
| recipe type id | **`minecraft:crafting`**（无独立 recipe type） | `TFCRecipeTypes.java:43-63` 无该项；`AdvancedShapelessRecipe` 未覆写 `getType()`，继承链 `AdvancedShapelessRecipe → ShapelessRecipe → CraftingRecipe`，`CraftingRecipe#getType()` default 返回 `RecipeType.CRAFTING`（**字节码确认**） |
| 实现类全名 | `net.dries007.tfc.common.recipes.AdvancedShapelessRecipe` | `net/dries007/tfc/common/recipes/AdvancedShapelessRecipe.java:52` |
| 父类 | `net.minecraft.world.item.crafting.ShapelessRecipe` | `AdvancedShapelessRecipe.java:52-53` |
| 自有状态字段 | `result: ItemStackProvider`、`remainder: Optional<ItemStackProvider>`、`primaryIngredient: Optional<Ingredient>` | `AdvancedShapelessRecipe.java:60-62` |
| 父类状态字段 | `group`、`category`、`result`、`ingredients`（**无 `showNotification`**，字节码确认） | 构造器 `super("", CraftingBookCategory.MISC, ItemStack.EMPTY, ingredients)`（`AdvancedShapelessRecipe.java:65`） |
| `getSerializer()` | `TFCRecipeSerializers.ADVANCED_SHAPELESS_CRAFTING.get()` | `AdvancedShapelessRecipe.java:105-107` |

##### R-28.2 完整字段表

`CODEC` 原文（`AdvancedShapelessRecipe.java:54-58`，按可读性换行，逻辑等价）：

```java
public static final MapCodec<AdvancedShapelessRecipe> CODEC = RecordCodecBuilder.mapCodec(i -> i.group(
    Ingredient.CODEC_NONEMPTY.listOf().fieldOf("ingredients").flatXmap(list -> {
        Ingredient[] values = list.toArray(Ingredient[]::new);
        int length = ShapedRecipePattern.getMaxHeight() * ShapedRecipePattern.getMaxWidth();   // = 9
        return values.length == 0
            ? DataResult.error(() -> "No ingredients for shapeless recipe")
            : (values.length > length
                ? DataResult.error(() -> "Too many ingredients for shapeless recipe. The maximum is: %s".formatted(length))
                : DataResult.success(NonNullList.of(Ingredient.EMPTY, values)));
    }, DataResult::success).forGetter(ShapelessRecipe::getIngredients),
    ItemStackProvider.CODEC.fieldOf("result").forGetter(c -> c.result),
    ItemStackProvider.CODEC.optionalFieldOf("remainder").forGetter(c -> c.remainder),
    Ingredient.CODEC.optionalFieldOf("primary_ingredient").forGetter(c -> c.primaryIngredient)
).apply(i, AdvancedShapelessRecipe::new));
```

| 字段名 | 类型 | 必需/可选 | 默认值 | 语义 | 源码行 |
| --- | --- | --- | --- | --- | --- |
| `ingredients` | `Ingredient` 数组（每项 `CODEC_NONEMPTY`） | **必需** | 无 | 无序原料列表；**长度必须 1~9**，否则解析报错（错误文本 `No ingredients for shapeless recipe` / `Too many ingredients for shapeless recipe. The maximum is: %s`，上限由 `ShapedRecipePattern.getMaxHeight() * getMaxWidth()` 动态求得）。支持全部 TFC 自定义 ingredient | `AdvancedShapelessRecipe.java:54-57` |
| `result` | **`ItemStackProvider`** | **必需** | 无 | 输出（可带 modifiers、可按输入动态计算），与 R-27 的 `result` 语义完全一致 | `AdvancedShapelessRecipe.java:58`、`60` |
| `remainder` | `ItemStackProvider` | 可选 | `Optional.empty()`（缺省时走 `super.getRemainingItems(input)`，即原版「物品自身合成剩余物」） | 剩余物提供者；只对**与 `primary_ingredient` 匹配**的槽位生效：`RecipeHelpers.getRemainderItemsWithProvider(input, remainder, this.getPrimaryInput(input))` 内部用 `ItemStack.isSameItem(primaryInput, stack)` 判定（`RecipeHelpers.java:91`），匹配的槽位放 provider 结果，其它槽位仍走 `getCraftingRemainingItem()` | `AdvancedShapelessRecipe.java:58`、`82-89` |
| `primary_ingredient` | `Ingredient` | 可选（**但见下方陷阱**） | `Optional.empty()` | **主原料**：`assemble` 需要的「输入物品」就从匹配它的槽位取。`getPrimaryInput` 遍历整个合成网格，返回**第一个**满足 `primaryInput.test(item)` 的物品；一个都找不到则返回 `ItemStack.EMPTY` | `AdvancedShapelessRecipe.java:58`、`61`、`91-99` |

**与 `AdvancedShapedRecipe` 的字段对照**：

| 概念 | `tfc:advanced_shaped_crafting` | `tfc:advanced_shapeless_crafting` |
| --- | --- | --- |
| 原料描述 | `pattern` + `key` | `ingredients`（一维数组） |
| 主输入定位方式 | `input_row` / `input_column`（**坐标**，需配合 `translateMatch` 处理平移与镜像） | `primary_ingredient`（**按 ingredient 匹配**，天然免疫摆放位置与顺序） |
| 输出 | `result: ItemStackProvider` | 同 |
| 剩余物 | `remainder: ItemStackProvider`（可选） | 同 |
| 其它 | `show_notification`（可选，默认 true） | **无此字段** |
| `category` / `group` | 无（固定 `MISC` / `""`） | 无（固定 `MISC` / `""`） |

实测使用率（283 个文件）：全部含 `ingredients`、`result`、`primary_ingredient`（缺省 0 个）；55 个**没有** `remainder`。

##### R-28.3 与父类 `ShapelessRecipe` 的行为差异

| 行为 | 父类 `ShapelessRecipe` | `AdvancedShapelessRecipe` | 源码 |
| --- | --- | --- | --- |
| 输出字段类型 | `ItemStack result` | `ItemStackProvider result` | `AdvancedShapelessRecipe.java:60` |
| 交给父类的 `result` | — | 恒为 `ItemStack.EMPTY`（`AdvancedShapelessRecipe.java:65`） | 同 |
| `assemble(CraftingInput, Provider)` | 返回固定 `result` | `setCraftingInput(input)` → `result.getSingleStack(getPrimaryInput(input).copy())` → `clearCraftingInput()` | `AdvancedShapelessRecipe.java:71-76` |
| `getResultItem(Provider)` | 返回固定 `result` | 返回 `result.getEmptyStack()`（无随机掷骰的展示值） | `AdvancedShapelessRecipe.java:78-80` |
| `getRemainingItems(CraftingInput)` | 每槽位 `getCraftingRemainingItem()` | 有 `remainder` 时由 provider 接管；无则 `orElseGet(() -> super.getRemainingItems(input))` | `AdvancedShapelessRecipe.java:82-89` |
| `isSpecial()` | `ShapelessRecipe` 未覆写 → `Recipe#isSpecial()` default = `false`（字节码确认 `iconst_0; ireturn`） | `return this.result.dependsOnInput();` | `AdvancedShapelessRecipe.java:101-103` |
| `matches(CraftingInput, Level)` | 原版实现 | **未覆写**，完全继承原版无序匹配 | 全文无 `matches` 方法 |
| `category()` / `getGroup()` | 由构造器参数决定 | 恒 `MISC` / `""` | `AdvancedShapelessRecipe.java:65` |
| `canCraftInDimensions(int, int)` | 原版实现（字节码确认 `ShapelessRecipe` 有该方法） | **未覆写**，继承父类 | 全文无该方法 |
| 额外方法 | — | `public ItemStackProvider getResult()`（`:109-111`）、`getRemainder()`、`getPrimaryIngredient()`（均 `@VisibleForTesting`） | `AdvancedShapelessRecipe.java:109-121` |

##### R-28.4 真实 JSON 样例（4 个）

**样例 1 —— `data/tfc/recipe/crafting/pumpkin_pie.json`**（4 个字段全用：`ingredients` + `primary_ingredient` + `remainder` + `result`）：

```json
{"type":"tfc:advanced_shapeless_crafting","ingredients":[{"tag":"c:tools/knife"},{"type":"tfc:and","children":[{"item":"tfc:food/pumpkin_chunks"},{"type":"tfc:not_rotten"}]},{"tag":"tfc:foods/sweeteners"},{"type":"tfc:and","children":[{"item":"minecraft:egg"},{"type":"tfc:not_rotten"}]},{"type":"tfc:and","children":[{"tag":"c:foods/dough"},{"type":"tfc:not_rotten"}]}],"primary_ingredient":{"tag":"c:tools/knife"},"remainder":{"modifiers":[{"type":"tfc:damage_crafting_remainder"}]},"result":{"count":1,"id":"minecraft:pumpkin_pie"}}
```

读法：原料 5 项（刀、南瓜块、甜味剂、蛋、面团）；`primary_ingredient` 是刀 → `remainder` 的磨损效果作用在**玩家实际放的那把刀**所在的槽位；`result` 走纯 `ItemStack` 分支（无 modifiers）。

**样例 2 —— `data/tfc/recipe/crafting/salting.json`**（`result` 只有 modifiers、无 `stack`；`primary_ingredient` 与 `ingredients[0]` 是两处独立书写的同一结构）：

```json
{"type":"tfc:advanced_shapeless_crafting","ingredients":[{"type":"tfc:and","children":[{"tag":"tfc:foods/can_be_salted"},{"type":"tfc:not_rotten"},{"type":"tfc:lacks_trait","trait":"tfc:salted"}]},{"item":"tfc:powder/salt"}],"primary_ingredient":{"type":"tfc:and","children":[{"tag":"tfc:foods/can_be_salted"},{"type":"tfc:not_rotten"},{"type":"tfc:lacks_trait","trait":"tfc:salted"}]},"result":{"modifiers":[{"type":"tfc:copy_input"},{"type":"tfc:add_trait","trait":"tfc:salted"},{"type":"tfc:round_creation_date"}]}}
```

读法：
- `result` 是**只有 `modifiers`、没有 `stack`** 的对象 → 基底物品取 `ItemStack.EMPTY`（`stack` 用 `optionalFieldOf("stack", ItemStack.EMPTY)`），随后三个 modifier 依次作用：`tfc:copy_input` 先把输出**整体替换为输入物品的副本**（`CopyInputModifier.apply` 直接返回 `input.copy()`），再 `tfc:add_trait` 打上 `tfc:salted` 标签，最后 `tfc:round_creation_date` 把创建时间取整。
- `isSpecial()`：`tfc:copy_input` 的 `dependsOnInput()` 返回 `true`（`outputs/CopyInputModifier.java:20-22`），因此本配方 `isSpecial() == true`。

**补充样例 3 —— `data/tfc/recipe/crafting/add_powder.json`**（两个 modifier 组合，无 `remainder`）：

```json
{"type":"tfc:advanced_shapeless_crafting","ingredients":[{"tag":"tfc:glass_blowpipes"},{"tag":"tfc:glass_powders"}],"primary_ingredient":{"tag":"tfc:glass_blowpipes"},"result":{"modifiers":[{"type":"tfc:copy_input"},{"type":"tfc:add_powder"}]}}
```

**补充样例 4 —— `data/tfc/recipe/crafting/add_large_bait.json`**（钓鱼竿上饵，`copy_input` + `add_bait_to_rod`）：

```json
{"type":"tfc:advanced_shapeless_crafting","ingredients":[{"tag":"tfc:holds_large_fishing_bait"},{"tag":"tfc:large_fishing_bait"}],"primary_ingredient":{"tag":"tfc:holds_large_fishing_bait"},"result":{"modifiers":[{"type":"tfc:copy_input"},{"type":"tfc:add_bait_to_rod"}]}}
```

##### R-28.5 触发条件与调用点

与 R-27 同构：**没有 mixin 接管**，完全靠 `CraftingRecipe` 契约被原版合成台接纳。对 `net/dries007/tfc` 全树 grep `AdvancedShapelessRecipe` 的全部命中点：

| 位置 | 类型 | 说明 |
| --- | --- | --- |
| `net/dries007/tfc/common/recipes/TFCRecipeSerializers.java:19, 83` | 注册 | import + `register("advanced_shapeless_crafting", ...)` |
| `net/dries007/tfc/common/recipes/AdvancedShapelessRecipe.java:52, 54, 58, 64` | 定义 | 类、`CODEC`、`STREAM_CODEC`、构造器 |
| `net/dries007/tfc/util/DataGenerationHelpers.java:32, 250` | datagen | `Builder.shapeless(...)` 在 `isAdvanced()` 为真时构造它，否则构造原版 `ShapelessRecipe` |
| `net/dries007/tfc/compat/emi/EmiIntegration.java:65, 304-307` | 兼容层 | 对 `instanceof AdvancedShapelessRecipe` 注册 `EmiAdvancedShapelessRecipe` |
| `net/dries007/tfc/compat/emi/recipe/EmiAdvancedShapelessRecipe.java:28, 38, 45` | 兼容层 | EMI 展示 |
| `net/dries007/tfc/compat/jei/TFCCraftingExtensions.java:30, 40-43` | 兼容层 | **JEI 只对 `AdvancedShapelessRecipe` 注册了 crafting 分类扩展**（`registry.getCraftingCategory().addExtension(AdvancedShapelessRecipe.class, ...)`），用于按 `primary_ingredient` 调整 JEI 展示排布 |

`TFCCraftingExtensions` 只扩展了无序版本、没有扩展有序版本，原因是无序配方的 JEI 展示需要知道「哪个原料是主原料」才能还原正确排布（`TFCCraftingExtensions.java:42-43` 中直接读取 `recipeHolder.value()`）。

##### R-28.6 限制与陷阱

- **`primary_ingredient` 缺省会导致合成时抛异常**。`assemble` 无条件调用 `getPrimaryInput(input)`，而 `getPrimaryInput` 的第一行是 `this.primaryIngredient.orElseThrow()`（`AdvancedShapelessRecipe.java:92`）。因此：
  - 若配方**没有** `primary_ingredient`，玩家一旦成功匹配并取出产物，就会抛 `NoSuchElementException`（`Optional.orElseThrow()` 无参形式）；
  - 同理，若写了 `remainder` 却没有 `primary_ingredient`，`getRemainingItems` 也会在 `getPrimaryInput` 处抛异常（`AdvancedShapelessRecipe.java:85`）。
  - **官方数据包规避了这一点**：283 个 `tfc:advanced_shapeless_crafting` 文件中，**283 个全部写了 `primary_ingredient`**（缺省数为 0，实测）。
  - 给模组作者的实践结论：**`primary_ingredient` 事实上是必填项**，不要依赖「可选」这一 codec 声明。
- **`ingredients` 长度必须在 1~9 之间**，上限由 `ShapedRecipePattern.getMaxHeight() * getMaxWidth()` 求出（= 9）；错误信息中的 `%s` 会填入该上限数字。
- **`primary_ingredient` 不必与 `ingredients` 中任何一项字面相同**，但若它不匹配网格中的任何物品，`getPrimaryInput` 返回 `ItemStack.EMPTY`，此时 `result` 中所有依赖输入的 modifier 都会拿到空输入（例如 `tfc:copy_input` 会返回空 → 输出为空，**合成结果消失但原料仍被消耗**）。这是最危险的配置错误。
- **`result` / `remainder` 的 JSON 形态约束与 R-27.7 完全相同**（必须写 `modifiers`；只写 `stack` 非法）。
- **`remainder` 只作用于主原料槽位**，其它槽位的剩余物仍由物品自身的 `getCraftingRemainingItem()` 决定（`RecipeHelpers.java:91-99`）。
- `getRemainingItems` 在 `remainder` 缺席时回退父类实现，而 `Recipe#getRemainingItems(T)` 的 default 实现（字节码确认）是「返回与输入同尺寸、全空 `ItemStack` 的列表」，所以「无 `remainder`」等价于「没有剩余物」。

---

### [R-29] 通用输出与原料（ItemStackProvider / ItemStackModifier / TFCIngredients）

> 本节是**全局公用章节**：`ItemStackProvider`、`ItemStackModifier`、`TFCIngredients` 被 TFC 的绝大多数配方类型复用（不止本组的 R-24 ~ R-28），其中 `outputs/*Modifier` 也出现在 `tfc:heating`、`tfc:barrel_*`、`tfc:anvil`、`tfc:casting`、`tfc:pot`、`tfc:quern` 等类型的 `result_item` / `output_item` 字段中。主控文档可直接引用本节内容。

##### R-29.1 ItemStackProvider —— 通用输出包装

**位置**：`net/dries007/tfc/common/recipes/outputs/ItemStackProvider.java:34`

```java
public record ItemStackProvider(ItemStack stack, List<ItemStackModifier> modifiers)
```

**CODEC 原文**（`ItemStackProvider.java:35`，逻辑等价的换行版）：

```java
public static final Codec<ItemStackProvider> CODEC = Codec.either(
    RecordCodecBuilder.create(i -> i.group(
        ItemStack.CODEC.optionalFieldOf("stack", ItemStack.EMPTY).forGetter(c -> c.stack),
        ItemStackModifier.CODEC.listOf().fieldOf("modifiers").forGetter(c -> c.modifiers)
    ).apply(i, ItemStackProvider::new)),
    ItemStack.CODEC
).xmap(e -> e.map(Function.identity(), ItemStackProvider::of),
       provider -> provider.modifiers.isEmpty() ? Either.right(provider.stack) : Either.left(provider));
```

###### R-29.1.1 JSON 形态（**只有两种合法写法**）

| 形态 | JSON 写法 | 触发分支 | 说明 |
| --- | --- | --- | --- |
| **形态 A：纯物品** | `{"count":1,"id":"tfc:xxx"}`（或任何合法 `ItemStack` JSON） | `Codec.either` 的**右侧** `ItemStack.CODEC` | 解析后经 `ItemStackProvider.of(stack)` 包装为「无 modifier」的 provider；序列化时若 `modifiers` 为空也会退化为这种形态 |
| **形态 B：带 modifiers** | `{"stack":{...},"modifiers":[{...},{...}]}`，其中 `stack` 可省略 | 左侧 `RecordCodecBuilder` | `stack` 省略 → 默认 `ItemStack.EMPTY`；`modifiers` **必须存在** |

**关键限制：`modifiers` 是必需字段（`fieldOf`，非 `optionalFieldOf`）。** 因此

```json
"result": {"stack": {"count":1,"id":"tfc:xxx"}}      // 非法！
```

是**不可解析**的：左侧分支因缺 `modifiers` 失败，右侧 `ItemStack.CODEC` 也不认识 `stack` 这个键。实测印证：全库不存在「含 `"result":{"stack"` 但整文件不含 `modifiers`」的配方（命中 0 个文件）。合法形式只有 `{"count":N,"id":"..."}`、`{"modifiers":[...]}`、`{"stack":{...},"modifiers":[...]}` 三种。

###### R-29.1.2 字段表

| 字段名 | 类型 | 必需/可选 | 默认值 | 语义 | 源码行 |
| --- | --- | --- | --- | --- | --- |
| `stack` | `ItemStack` | 可选 | `ItemStack.EMPTY` | 输出基底物品。若为 `EMPTY` 且 modifier 链中第一个是 `tfc:copy_input` 之类「替换型」modifier，则最终以输入物品为基底 | `ItemStackProvider.java:35` |
| `modifiers` | `ItemStackModifier` 数组 | **必需**（当使用形态 B 时） | 无 | 依次作用于基底物品的修饰器列表，顺序即执行顺序 | `ItemStackProvider.java:35` |

###### R-29.1.3 求值算法（这是理解所有 modifier 语义的前提）

`ItemStackProvider.getStack(ItemStack input, Context context)`（`ItemStackProvider.java:92-101`）：

```java
ItemStack output = this.stack.copy();
if (!input.isEmpty()) {
    output.setCount(output.getCount() * input.getCount());   // ① 数量相乘
}
for (ItemStackModifier modifier : this.modifiers) {
    output = modifier.apply(output, input, context);         // ② 顺序链式应用
}
return output;
```

要点：

1. **数量相乘**：输出数量 = `stack.count × input.count`。这就是「用 3 个原料合成 3 倍产物」的来源（例：`barley_dough_2.json` 放 2 个面粉，`result.stack.count = 2`，实际产出 2 个面团）。`input` 为空时不做乘法。
2. **链式**：后面的 modifier 看到的 `stack` 是前面 modifier 的返回值，因此顺序敏感。若某个 modifier 返回 `ItemStack.EMPTY`（如 `tfc:chance` 未通过判定、`tfc:empty_bowl` 输入没有碗组件、`tfc:flower_cutting` 输入没有植物组件），**后续 modifier 会继续在空物品上执行**。
3. **两种 Context**（`ItemStackModifier.Context`，`outputs/ItemStackModifier.java:33-36`）：
   - `DEFAULT`：真实合成/加工时使用（随机类 modifier 会真的掷骰、`tfc:extra_products` 会真的给玩家物品）。
   - `NO_RANDOM_CHANCE`：**展示用**。`getEmptyStack()`（`ItemStackProvider.java:80-82`）、`getStackDisplayOnly(...)`、`getSingleStackDisplayOnly(...)` 都用它。此时 `tfc:chance` 会改为附加一段 tooltip 文本而不掷骰（`outputs/ChanceModifier.java:31-36`），`tfc:extra_products` 不会给玩家物品（`outputs/ExtraProductModifier.java:36-40` 要求 `context == DEFAULT`）。
4. **`dependsOnInput()`**（`ItemStackProvider.java:103-109`）：只要**任一** modifier 覆写 `dependsOnInput()` 返回 `true`，整个 provider 就依赖输入。高级合成配方用它决定 `isSpecial()`（见 R-27.3、R-28.3）。
5. **`of(...)` 工厂会顺手禁用腐败**：`ItemStackProvider.of(stack, modifiers)` 内部是 `new ItemStackProvider(FoodCapability.setTransientNonDecaying(stack), modifiers)`（`ItemStackProvider.java:68-70`），即**基底物品被标记为「临时永不腐败」**。这就是为什么 TFC 配方产出的食物不会在「刚合成出来」的瞬间带上腐败计时——真正的腐败时间由 `tfc:reset_food` / `tfc:copy_food` / `tfc:round_creation_date` 等 modifier 或 `FoodCapability` 的常规逻辑决定。
6. **`getSingleStack(input)`**：先 `input.copyWithCount(1)` 再求值（`ItemStackProvider.java:72-74`）。`AdvancedShapedRecipe.assemble` / `AdvancedShapelessRecipe.assemble` 用的都是它，所以形状合成**不会**触发上面的「数量相乘」（输入已被压成 1 个），产物数量完全由 `stack.count` 决定。

###### R-29.1.4 真实样例

来源于 `data/tfc/recipe/crafting/flower_cutting.json`（形态 B，只有 modifiers）：

```json
"result":{"modifiers":[{"type":"tfc:flower_cutting"}]}
```

来源于 `data/tfc/recipe/crafting/blowpipe_with_glass.json`（形态 B，stack + modifiers）：

```json
"result":{"modifiers":[{"type":"tfc:add_glass"}],"stack":{"count":1,"id":"tfc:blowpipe_with_glass"}}
```

来源于 `data/tfc/recipe/crafting/metal/block/bismuth.json`（形态 A，纯物品）：

```json
"result":{"count":8,"id":"tfc:metal/block/bismuth"}
```

来源于 `data/tfc/recipe/heating/powder/kaolinite.json`（注意：**非合成配方也使用同一套 provider**，字段名为 `result_item`）：

```json
{"type":"tfc:heating","ingredient":{"item":"tfc:kaolin_clay"},"result_item":{"modifiers":[{"type":"tfc:chance","chance":0.2}],"stack":{"count":1,"id":"tfc:powder/kaolinite"}},"temperature":500.0}
```

##### R-29.2 ItemStackModifier —— 修饰器清单（22 种）

**接口与注册表**（`net/dries007/tfc/common/recipes/outputs/ItemStackModifier.java:21-38`、`ItemStackModifiers.java:53-91`）：

```java
// 接口
public interface ItemStackModifier {
    Codec<ItemStackModifier> CODEC = ItemStackModifiers.REGISTRY.byNameCodec()
        .dispatch(ItemStackModifier::type, ItemStackModifierType::codec);
    ItemStack apply(ItemStack stack, ItemStack input, Context context);
    default boolean dependsOnInput() { return false; }
    ItemStackModifierType<?> type();
    enum Context { DEFAULT, NO_RANDOM_CHANCE }
}

// 注册表 key
public static final ResourceKey<Registry<ItemStackModifierType<?>>> KEY =
    ResourceKey.createRegistryKey(Helpers.identifier("item_stack_modifiers"));   // → tfc:item_stack_modifiers
```

**JSON 写法**：dispatch 型 codec，即 `{"type":"<modifier id>", <其余字段平铺>}`。**单例（enum）modifier 用 `MapCodec.unit` 注册**（`ItemStackModifiers.java:80-82`），因此它们**只接受 `type` 一个键**，多写字段会解析失败。

###### R-29.2.1 全部 22 种 modifier 一览

「数据用量」列 = `jar-extract/data` 全库中该 `"type"` 作为 `type` 值出现的次数（精确匹配，非子串）。

| # | JSON `type` | 实现类（`net/dries007/tfc/common/recipes/outputs/`） | 自有 JSON 字段 | `dependsOnInput()` | 数据用量 |
| --- | --- | --- | --- | --- | --- |
| 1 | `tfc:copy_input` | `CopyInputModifier`（enum 单例） | 无 | **true** | 359 |
| 2 | `tfc:copy_food` | `CopyFoodModifier`（enum） | 无 | false | 66 |
| 3 | `tfc:copy_oldest_food` | `CopyOldestFoodModifier`（enum） | 无 | false | 48 |
| 4 | `tfc:copy_heat` | `CopyHeatModifier`（enum） | 无 | **true** | **0** |
| 5 | `tfc:copy_forging_bonus` | `CopyForgingBonusModifier`（enum） | 无 | false | 126 |
| 6 | `tfc:reset_food` | `ResetFoodModifier`（enum） | 无 | false | **0** |
| 7 | `tfc:empty_bowl` | `EmptyBowlModifier`（enum） | 无 | **true** | 1 |
| 8 | `tfc:flower_cutting` | `FlowerCuttingModifier`（enum） | 无 | **true** | 1 |
| 9 | `tfc:add_bait_to_rod` | `AddBaitToRodModifier`（enum） | 无 | false（但读合成输入） | 2 |
| 10 | `tfc:add_glass` | `AddGlassModifier`（enum） | 无 | **true** | 2 |
| 11 | `tfc:add_powder` | `AddPowderModifier`（enum） | 无 | **true** | 1 |
| 12 | `tfc:crafting_remainder` | `CraftingRemainderModifier`（enum） | 无 | false | **0** |
| 13 | `tfc:damage_crafting_remainder` | `DamageCraftingRemainderModifier`（enum） | 无 | false | 474 |
| 14 | `tfc:add_trait` | `AddTraitModifier`（record） | `trait` | false | 334 |
| 15 | `tfc:remove_trait` | `RemoveTraitModifier`（record） | `trait` | false | 1 |
| 16 | `tfc:round_creation_date` | `RoundCreationDateModifier`（enum） | 无 | false | 1 |
| 17 | `tfc:add_heat` | `AddHeatModifier`（record） | `temperature` | false | 4 |
| 18 | `tfc:dye_leather` | `DyeLeatherModifier`（record） | `color` | false | 16 |
| 19 | `tfc:remove_dye` | `RemoveDyeModifier`（enum） | 无 | **true** | 1 |
| 20 | `tfc:meal` | `MealModifier`（record） | `food`、`portions` | false（但读合成输入） | 186 |
| 21 | `tfc:extra_products` | `ExtraProductModifier`（record） | `stack` | false | 9 |
| 22 | `tfc:chance` | `ChanceModifier`（record） | `chance` | false | 1 |

> 注册顺序与 id 的对应关系见 `ItemStackModifiers.java:57-78`（每行一个 `register("...", ...)`）。注意第 22 项在注册时传入的 codec 是 `ChanceModifier.CHANCE`（不是 `CODEC`，`ItemStackModifiers.java:78`）。

###### R-29.2.2 逐项详解

以下每项给出：JSON 字段、语义、`dependsOnInput`、真实 JSON 用例（若数据中用量为 0，则明确标注「jar 数据中无实例，以下为按 CODEC 构造的示意，字段名来自源码行」）。

##### (1) `tfc:copy_input` —— 输出取输入副本

| 项目 | 值 |
| --- | --- |
| 字段 | 无（单例，`MapCodec.unit`，`ItemStackModifiers.java:57`、`:80-82`） |
| 语义 | `return input.copy();`（`CopyInputModifier.java:24-26`）——**整条 modifier 链的实际基底变成输入物品**，`stack` 字段的内容被丢弃 |
| `dependsOnInput()` | `true`（`CopyInputModifier.java:20-22`） |
| 典型用途 | 给食物加标签（腌制、上盐）、给钓竿上饵、给皮革染色，都需要保留原物品的组件 |
| 真实用例 | `data/tfc/recipe/crafting/salting.json` → `{"type":"tfc:copy_input"}`；`data/tfc/recipe/barrel/black_dyeable.json` → `"output_item":{"modifiers":[{"type":"tfc:copy_input"},{"type":"tfc:dye_leather","color":"black"}]}` |
| JSON 示例 | `{"type":"tfc:copy_input"}` |

##### (2) `tfc:copy_food` —— 复制输入的食物属性

| 项目 | 值 |
| --- | --- |
| 字段 | 无 |
| 语义 | `return FoodCapability.updateFoodFromPrevious(input, stack);`（`CopyFoodModifier.java:21-23`）——把输入的 `FoodData`（新鲜度/创建时间/营养）搬到输出上 |
| `dependsOnInput()` | `false`（未覆写） |
| 真实用例 | `data/tfc/recipe/crafting/food/barley_grain.json`：`"result":{"modifiers":[{"type":"tfc:copy_food"}],"stack":{"count":1,"id":"tfc:food/barley_grain"}}`（脱壳：把大麦的腐败状态带给大麦粒） |
| JSON 示例 | `{"type":"tfc:copy_food"}` |

##### (3) `tfc:copy_oldest_food` —— 复制「最旧」输入的食物属性

| 项目 | 值 |
| --- | --- |
| 字段 | 无 |
| 语义 | `FoodCapability.updateFoodFromAllPrevious(Lists.newArrayList(RecipeHelpers.getCraftingInput()), stack)`（`CopyOldestFoodModifier.java:23-25`）——遍历**整个合成输入**，取最旧（最先腐败）的那一份食物属性 |
| `dependsOnInput()` | `false`（未覆写，但实际读 `RecipeHelpers.getCraftingInput()`） |
| 真实用例 | `data/tfc/recipe/crafting/food/barley_dough_1.json`：`"result":{"modifiers":[{"type":"tfc:copy_oldest_food"}],"stack":{"count":1,"id":"tfc:food/barley_dough"}}` |
| JSON 示例 | `{"type":"tfc:copy_oldest_food"}` |

##### (4) `tfc:copy_heat` —— 复制输入温度

| 项目 | 值 |
| --- | --- |
| 字段 | 无 |
| 语义 | `IHeat heat = HeatCapability.get(input); if (heat != null) HeatCapability.setTemperature(stack, heat.getTemperature());`（`CopyHeatModifier.java:23-30`） |
| `dependsOnInput()` | `true`（`CopyHeatModifier.java:33-35`） |
| 数据用量 | **0**（jar 数据中无实例） |
| 示意 JSON | `{"type":"tfc:copy_heat"}`（字段名依据：无字段，`ItemStackModifiers.java:60`） |

##### (5) `tfc:copy_forging_bonus` —— 复制锻造加成

| 项目 | 值 |
| --- | --- |
| 字段 | 无 |
| 语义 | `return ForgingBonusComponent.copy(input, stack);`（`CopyForgingBonusModifier.java:21-23`）——把砧板锻造出的「锻造加成」组件带到成品上 |
| `dependsOnInput()` | `false` |
| 真实用例 | `data/tfc/recipe/crafting/metal/axe/bismuth_bronze.json`：`"result":{"modifiers":[{"type":"tfc:copy_forging_bonus"}],"stack":{"count":1,"id":"tfc:metal/axe/bismuth_bronze"}}`（斧头 + 木棍 → 完整斧，保留锻造加成） |
| JSON 示例 | `{"type":"tfc:copy_forging_bonus"}` |

##### (6) `tfc:reset_food` —— 重置食物创建时间

| 项目 | 值 |
| --- | --- |
| 字段 | 无 |
| 语义 | `return FoodCapability.setCreatedNow(stack);`（`ResetFoodModifier.java:21-23`）——把食物的创建时间设为「现在」，相当于**刷新新鲜度** |
| `dependsOnInput()` | `false` |
| 数据用量 | **0** |
| 示意 JSON | `{"type":"tfc:reset_food"}`（`ItemStackModifiers.java:62`） |

##### (7) `tfc:empty_bowl` —— 取出输入中的碗

| 项目 | 值 |
| --- | --- |
| 字段 | 无 |
| 语义 | `return input.getOrDefault(TFCComponents.BOWL, Bowl.DISPLAY).stack();`（`EmptyBowlModifier.java:23-25`）——从输入物品的 `tfc:bowl` 组件取出碗（洗净汤碗/沙拉碗） |
| `dependsOnInput()` | `true` |
| 真实用例 | `data/tfc/recipe/barrel/clean_bowl.json`：`"output_item":{"modifiers":[{"type":"tfc:empty_bowl"}]}` |
| JSON 示例 | `{"type":"tfc:empty_bowl"}` |

##### (8) `tfc:flower_cutting` —— 取出输入中的植物 ×2

| 项目 | 值 |
| --- | --- |
| 字段 | 无 |
| 语义 | 读输入的 `TFCComponents.PLANT` 组件，返回 `plant.copyWithCount(2)`；若没有植物组件则返回 `ItemStack.EMPTY`（`FlowerCuttingModifier.java:22-25`） |
| `dependsOnInput()` | `true` |
| 真实用例 | `data/tfc/recipe/crafting/flower_cutting.json`：`"result":{"modifiers":[{"type":"tfc:flower_cutting"}]}` |
| JSON 示例 | `{"type":"tfc:flower_cutting"}` |

##### (9) `tfc:add_bait_to_rod` —— 给钓竿挂饵

| 项目 | 值 |
| --- | --- |
| 字段 | 无 |
| 语义 | 遍历 `RecipeHelpers.getCraftingInput()`，找到第一个鱼饵（`BaitType.getType(input) != NONE`）并写入钓竿的鱼饵组件（`AddBaitToRodModifier.java:23-31`） |
| `dependsOnInput()` | `false`（未覆写；实际遍历合成输入） |
| 真实用例 | `data/tfc/recipe/crafting/add_large_bait.json`：`"result":{"modifiers":[{"type":"tfc:copy_input"},{"type":"tfc:add_bait_to_rod"}]}` |
| JSON 示例 | `{"type":"tfc:add_bait_to_rod"}` |

##### (10) `tfc:add_glass` —— 吹管挂玻璃批料

| 项目 | 值 |
| --- | --- |
| 字段 | 无 |
| 语义 | `GlassWorking.createNewBatch(stack, input);`（`AddGlassModifier.java:21-24`） |
| `dependsOnInput()` | `true` |
| 真实用例 | `data/tfc/recipe/crafting/blowpipe_with_glass.json`：`"result":{"modifiers":[{"type":"tfc:add_glass"}],"stack":{"count":1,"id":"tfc:blowpipe_with_glass"}}` |
| JSON 示例 | `{"type":"tfc:add_glass"}` |

##### (11) `tfc:add_powder` —— 给玻璃吹管加粉末操作

| 项目 | 值 |
| --- | --- |
| 字段 | 无 |
| 语义 | 遍历合成输入，用 `GlassOperation.getByPowder(input)` 找到粉末对应的玻璃操作并 `GlassWorking.apply(stack, op)`（`AddPowderModifier.java:23-33`） |
| `dependsOnInput()` | `true` |
| 真实用例 | `data/tfc/recipe/crafting/add_powder.json`：`"result":{"modifiers":[{"type":"tfc:copy_input"},{"type":"tfc:add_powder"}]}` |
| JSON 示例 | `{"type":"tfc:add_powder"}` |

##### (12) `tfc:crafting_remainder` —— 使用物品自身合成剩余物

| 项目 | 值 |
| --- | --- |
| 字段 | 无 |
| 语义 | `return input.hasCraftingRemainingItem() ? input.getCraftingRemainingItem() : ItemStack.EMPTY;`（`CraftingRemainderModifier.java:20-22`）——等价于原版「合成后返还物品」的行为，但可用于配方显式指定的 `remainder` 字段 |
| `dependsOnInput()` | `false` |
| 数据用量 | **0**（jar 数据中全部改用 `damage_crafting_remainder`） |
| 示意 JSON | `{"type":"tfc:crafting_remainder"}`（`ItemStackModifiers.java:68`） |

##### (13) `tfc:damage_crafting_remainder` —— 工具磨损后返还（TFC 最常用）

| 项目 | 值 |
| --- | --- |
| 字段 | 无 |
| 语义 | 若输入可损坏：优先用 `RecipeHelpers.getCraftingPlayer()` 拿到玩家后 `Helpers.damageItem(input, player.level())`，否则 `Helpers.damageItem(input)`；然后「若输入同时有 `MAX_DAMAGE` 与 `DAMAGE` 组件则返回 `input.copy()`，否则返回 `ItemStack.EMPTY`」（`DamageCraftingRemainderModifier.java:28-40`） |
| `dependsOnInput()` | `false` |
| 数据用量 | **474**（全库第一） |
| 真实用例 | `data/tfc/recipe/crafting/metal/block/bismuth.json`：`"remainder":{"modifiers":[{"type":"tfc:damage_crafting_remainder"}]}` |
| 注意事项 | 该 modifier **总是返回不空**——它返回的是「被磨损后的工具本身」，所以正确用法是放在 `remainder` 里，而不是 `result` 里 |
| JSON 示例 | `{"type":"tfc:damage_crafting_remainder"}` |

##### (14) `tfc:add_trait` —— 添加食物标签

| 项目 | 值 |
| --- | --- |
| 字段 | `trait`：`FoodTrait` 的 registry holder（`FoodTrait.CODEC = FoodTraits.REGISTRY.holderByNameCodec()`，`net/dries007/tfc/common/component/food/FoodTrait.java:31`），JSON 写 trait id 字符串 |
| CODEC | `FoodTrait.CODEC.fieldOf("trait").xmap(AddTraitModifier::new, AddTraitModifier::trait)`（`outputs/AddTraitModifier.java:26`） |
| 语义 | `return FoodCapability.applyTrait(stack, this.trait);`（`AddTraitModifier.java:33-35`） |
| `dependsOnInput()` | `false` |
| 真实用例 | `data/tfc/recipe/crafting/salting.json` → `{"type":"tfc:add_trait","trait":"tfc:salted"}`；`data/tfc/recipe/barrel/pickled.json` → `{"type":"tfc:add_trait","trait":"tfc:pickled"}` |
| JSON 示例 | `{"type":"tfc:add_trait","trait":"tfc:salted"}` |

> `trait` 的合法取值来自 `FoodTraits` 注册表（`tfc:<name>` 形式，数据中出现的有 `tfc:salted`、`tfc:pickled`、`tfc:brined`、`tfc:vinegar` 等）。**完整 trait id 清单未在本任务中逐项核实**（见附录 A5-C）。

##### (15) `tfc:remove_trait` —— 移除食物标签

| 项目 | 值 |
| --- | --- |
| 字段 | `trait`（同 `tfc:add_trait`） |
| CODEC | `FoodTrait.CODEC.fieldOf("trait").xmap(RemoveTraitModifier::new, RemoveTraitModifier::trait)`（`outputs/RemoveTraitModifier.java:26`） |
| 语义 | `return FoodCapability.removeTrait(stack, this.trait);`（`RemoveTraitModifier.java:33-35`） |
| 真实用例 | `data/tfc/recipe/barrel/preserved_in_vinegar.json` → `"on_unseal":{"modifiers":[{"type":"tfc:copy_input"},{"type":"tfc:remove_trait","trait":"tfc:vinegar"}]}` |
| JSON 示例 | `{"type":"tfc:remove_trait","trait":"tfc:vinegar"}` |

##### (16) `tfc:round_creation_date` —— 创建时间取整

| 项目 | 值 |
| --- | --- |
| 字段 | 无 |
| 语义 | `return FoodCapability.roundCreationDate(stack);`（`RoundCreationDateModifier.java:21-23`）——把食物创建时间按天取整，避免合成品带有「半路」的腐败进度 |
| `dependsOnInput()` | `false` |
| 真实用例 | `data/tfc/recipe/crafting/salting.json` → `{"type":"tfc:round_creation_date"}` |
| JSON 示例 | `{"type":"tfc:round_creation_date"}` |

##### (17) `tfc:add_heat` —— 加热/降温

| 项目 | 值 |
| --- | --- |
| 字段 | `temperature`：`Codec.FLOAT`（**必需**，可负） |
| CODEC | `Codec.FLOAT.fieldOf("temperature").xmap(AddHeatModifier::new, AddHeatModifier::temperature)`（`outputs/AddHeatModifier.java:30`） |
| 语义 | `heat.setTemperature(heat.getTemperature() + this.temperature)`；若物品没有 `IHeat` 组件则什么都不做（`AddHeatModifier.java:36-42`） |
| `dependsOnInput()` | `false` |
| 真实用例 | `data/tfc/recipe/barrel/olive_oil_cooling.json` → `"output_item":{"modifiers":[{"type":"tfc:copy_input"},{"type":"tfc:add_heat","temperature":-40.0}]}`（油冷降温 40 度） |
| JSON 示例 | `{"type":"tfc:add_heat","temperature":-40.0}` |

##### (18) `tfc:dye_leather` —— 染色

| 项目 | 值 |
| --- | --- |
| 字段 | `color`：`DyeColor`（**必需**），JSON 为原版染料色名（`white`/`orange`/.../`black`） |
| CODEC | `DyeColor.CODEC.fieldOf("color").xmap(DyeLeatherModifier::new, DyeLeatherModifier::color)`（`outputs/DyeLeatherModifier.java:29`） |
| 语义 | `return DyedItemColor.applyDyes(stack, List.of(DyeItem.byColor(this.color)));`（`DyeLeatherModifier.java:36-38`） |
| 真实用例 | `data/tfc/recipe/barrel/blue_dyeable.json` → `"output_item":{"modifiers":[{"type":"tfc:copy_input"},{"type":"tfc:dye_leather","color":"blue"}]}` |
| JSON 示例 | `{"type":"tfc:dye_leather","color":"black"}` |

##### (19) `tfc:remove_dye` —— 去除染色

| 项目 | 值 |
| --- | --- |
| 字段 | 无 |
| 语义 | `input.remove(DataComponents.DYED_COLOR); return input;`（`RemoveDyeModifier.java:27-30`）——**注意它返回的是 `input` 而不是 `stack`**，等价于「先 copy_input 再清染色」 |
| `dependsOnInput()` | `true`（`RemoveDyeModifier.java:22-24`） |
| 真实用例 | `data/tfc/recipe/barrel/bleach_dyeable.json` → `"output_item":{"modifiers":[{"type":"tfc:copy_input"},{"type":"tfc:remove_dye"}]}` |
| JSON 示例 | `{"type":"tfc:remove_dye"}` |

##### (20) `tfc:meal` —— 动态计算餐食营养（最复杂的 modifier）

| 项目 | 值 |
| --- | --- |
| 字段 1 | `food`：`FoodData`（**必需**）—— 餐食的基底营养数据 |
| 字段 2 | `portions`：`MealPortion` 数组（**必需**）—— 每种原料的加成系数 |
| CODEC | `RecordCodecBuilder.mapCodec(i -> i.group(FoodData.CODEC.fieldOf("food")..., <MealPortion codec>.listOf().fieldOf("portions")...))`（`outputs/MealModifier.java:52`） |
| `MealPortion` 字段 | `ingredient`（`Ingredient`，**可选**，缺省表示「匹配任意食物」）、`nutrient_modifier`（float，可选，默认 `1.0`）、`water_modifier`（float，可选，默认 `1.0`）、`saturation_modifier`（float，可选，默认 `1.0`）（`MealModifier.java:52`、`:118`） |
| `food`（`FoodData`）字段 | `hunger`（int，默认 0）、`water`（float，默认 0.0）、`saturation`（float，默认 0.0）、`intoxication`（int，默认 0）、`grain` / `fruit` / `vegetables` / `protein` / `dairy`（各为 float，默认 0.0，来自 `Nutrient` 的序列化名，`FoodData.java:35`、`:57-59`）、`decay_modifier`（float 或字符串 `"infinity"`，可选，默认 0.0，`FoodData.java:48`） |
| 语义 | 遍历合成输入中的**食物**（去重合并计数），按 `portions` 里第一条匹配的系数，把每种原料的营养 × 系数 × 数量累加到 `food` 上；同时把原料列表写入 `tfc:ingredients` 组件，并用 `FoodCapability.setFoodForDynamicItemOnCreate` 生成动态 `FoodData`（`MealModifier.java:56-108`） |
| `dependsOnInput()` | `false`（未覆写；实际读 `RecipeHelpers.getCraftingInput()`，`MealModifier.java:62`） |
| 真实用例 | `data/tfc/recipe/crafting/food/barley_bread_jam_sandwich_jss_jam.json` → `"result":{"modifiers":[{"type":"tfc:meal","food":{"decay_modifier":4.5,"hunger":4,"saturation":1.0,"water":0.5},"portions":[{"ingredient":{"item":"tfc:food/barley_bread"},"nutrient_modifier":0.675,"saturation_modifier":0.5,"water_modifier":0.5},{"nutrient_modifier":0.8,"saturation_modifier":0.8,"water_modifier":0.8}]}],...}` |
| 关键细节 | `portions` **按声明顺序取第一条匹配**（`MealModifier.java:83-90` 的 `for (MealPortion portion : this.portions)` + 首个 `test` 命中即 `break`），因此**无 `ingredient` 的兜底项必须放在最后** |
| JSON 示例（结构示意，字段全部来自 CODEC） | `{"type":"tfc:meal","food":{"hunger":4,"water":0.5,"saturation":1.0,"decay_modifier":4.5},"portions":[{"ingredient":{"tag":"tfc:foods/bread"},"nutrient_modifier":0.5},{"nutrient_modifier":0.8}]}` |

##### (21) `tfc:extra_products` —— 额外产物（直接给玩家）

| 项目 | 值 |
| --- | --- |
| 字段 | `stack`：`ItemStack`（**必需**） |
| CODEC | `ItemStack.CODEC.fieldOf("stack").xmap(ExtraProductModifier::of, ExtraProductModifier::stack)`（`outputs/ExtraProductModifier.java:30`） |
| 语义 | 在 `context == DEFAULT` 且能拿到合成玩家时，`ItemHandlerHelper.giveItemToPlayer(player, this.stack.copy())`（`ExtraProductModifier.java:36-42`）；**不改变 `stack` 本身**，所以常与 `damage_crafting_remainder` 一起放在 `remainder` 里 |
| 构造时会做 `FoodCapability.setTransientNonDecaying(stack)`（`ExtraProductModifier.java:32-34`） | 额外产物默认不腐败 |
| 真实用例 | `data/tfc/recipe/crafting/large_raw_hide.json` → `"remainder":{"modifiers":[{"type":"tfc:damage_crafting_remainder"},{"type":"tfc:extra_products","stack":{"count":3,"id":"tfc:wool"}}]}`（刮皮时额外给 3 份羊毛） |
| JSON 示例 | `{"type":"tfc:extra_products","stack":{"count":3,"id":"tfc:wool"}}` |

##### (22) `tfc:chance` —— 概率产出

| 项目 | 值 |
| --- | --- |
| 字段 | `chance`：`Codec.FLOAT`（**必需**，0~1） |
| CODEC | `Codec.FLOAT.fieldOf("chance").xmap(ChanceModifier::new, ChanceModifier::chance)`（注册为 `ChanceModifier.CHANCE`，`outputs/ChanceModifier.java:28`；`ItemStackModifiers.java:78`） |
| 语义 | `DEFAULT` 上下文：对 `stack.getCount()` 个产物**逐个独立掷骰**，保留通过者（`Math.random() < chance`），全不通过则返回 `ItemStack.EMPTY`；`NO_RANDOM_CHANCE` 上下文：只追加 `tfc.tooltip.chance` 文本，不掷骰（`ChanceModifier.java:31-46`） |
| `dependsOnInput()` | `false` |
| 真实用例 | `data/tfc/recipe/heating/powder/kaolinite.json` → `"result_item":{"modifiers":[{"type":"tfc:chance","chance":0.2}],"stack":{"count":1,"id":"tfc:powder/kaolinite"}}` |
| JSON 示例 | `{"type":"tfc:chance","chance":0.2}` |

###### R-29.2.3 modifier 与 Context 的交互汇总

| modifier | 行为受 `NO_RANDOM_CHANCE` 影响？ | 依赖 `RecipeHelpers.getCraftingPlayer()`？ | 依赖 `RecipeHelpers.getCraftingInput()`？ |
| --- | --- | --- | --- |
| `tfc:chance` | **是**（改为打印 tooltip） | 否 | 否 |
| `tfc:extra_products` | **是**（不给物品） | **是** | 否 |
| `tfc:damage_crafting_remainder` | 否 | **是**（有玩家时按玩家位置损伤） | 否 |
| `tfc:add_bait_to_rod` / `tfc:add_powder` / `tfc:copy_oldest_food` / `tfc:meal` | 否 | 否 | **是** |
| 其余 | 否 | 否 | 否 |

`RecipeHelpers.getCraftingInput()` 是一个 `ThreadLocal<Iterable<ItemStack>>`（`RecipeHelpers.java:63`），由 `AdvancedShapedRecipe.assemble` / `AdvancedShapelessRecipe.assemble` / `PotBlockEntity` 在调用前 `setCraftingInput(...)`、调用后 `clearCraftingInput()`（`RecipeHelpers.java:70-84`；`AdvancedShapedRecipe.java:69, 73`；`AdvancedShapelessRecipe.java:72, 74`）。这意味着**只有高级合成与锅具配方会自动提供输入上下文**；其它配方类型若使用这些 modifier，`getCraftingInput()` 会是空列表。

##### R-29.3 TFCIngredients —— 自定义原料类型清单（7 种）

**注册入口**（`net/dries007/tfc/common/recipes/ingredients/TFCIngredients.java:41-48`）：

```java
public static final DeferredRegister<IngredientType<?>> TYPES =
    DeferredRegister.create(NeoForgeRegistries.INGREDIENT_TYPES, "tfc");

public static final Id<RottenIngredient>        ROTTEN        = register("rotten",        RottenIngredient.CODEC,        RottenIngredient.STREAM_CODEC);
public static final Id<NotRottenIngredient>     NOT_ROTTEN    = register("not_rotten",    NotRottenIngredient.CODEC,     NotRottenIngredient.STREAM_CODEC);
public static final Id<HasTraitIngredient>      HAS_TRAIT     = register("has_trait",     HasTraitIngredient.CODEC,      HasTraitIngredient.STREAM_CODEC);
public static final Id<LacksTraitIngredient>    LACKS_TRAIT   = register("lacks_trait",   LacksTraitIngredient.CODEC,    LacksTraitIngredient.STREAM_CODEC);
public static final Id<HeatIngredient>          HEAT          = register("heat",          HeatIngredient.CODEC,          HeatIngredient.STREAM_CODEC);
public static final Id<FluidContentIngredient>  FLUID_CONTENT = register("fluid_content", FluidContentIngredient.CODEC,  FluidContentIngredient.STREAM_CODEC);
public static final Id<AndIngredient>           AND           = register("and",           AndIngredient.CODEC,           AndIngredient.STREAM_CODEC);
```

这些类型注册进的是 **NeoForge 的 `IngredientType` 注册表**（`IngredientType` 的 codec 会作为 `Ingredient.CODEC` 的一个分支），因此它们的 JSON 写法就是 `{"type":"<id>", ...}`，可以出现在**任何使用 `Ingredient` 的位置**（原版 `key` / `ingredients`、TFC 各类配方的 `ingredient` / `catalyst` 等）。

###### R-29.3.1 一览表

| # | JSON `type` | 实现类（`net/dries007/tfc/common/recipes/ingredients/`） | 自有字段 | `isSimple()` | 全库用量 |
| --- | --- | --- | --- | --- | --- |
| 1 | `tfc:rotten` | `RottenIngredient`（enum 单例） | 无 | false | **0** |
| 2 | `tfc:not_rotten` | `NotRottenIngredient`（enum 单例） | 无 | false | 1418 |
| 3 | `tfc:has_trait` | `HasTraitIngredient`（record） | `trait` | false | 2 |
| 4 | `tfc:lacks_trait` | `LacksTraitIngredient`（record） | `trait` | false | 334 |
| 5 | `tfc:heat` | `HeatIngredient`（record） | `min`、`max` | false | 4 |
| 6 | `tfc:fluid_content` | `FluidContentIngredient`（record） | `fluid`（`SizedFluidIngredient`） | false | 234 |
| 7 | `tfc:and` | `AndIngredient`（record） | `children` | false | 1418 |

**重要澄清（针对任务描述中提到的 `tfc:damaged`、`tfc:fluid`）**：

| 被提及的写法 | 实际情况 | 证据 |
| --- | --- | --- |
| `tfc:damaged` | **不存在**。TFC 4.2.10 没有名为 `damaged` 的 ingredient 类型；全库 JSON 中作为 `type` 值出现 **0** 次 | `TFCIngredients.java:42-48` 只有 7 个注册；全库精确统计为 0 |
| `tfc:fluid` | **不存在**（全库作为 `type` 值出现 **0** 次）。正确名称是 `tfc:fluid_content`（234 次）。容易混淆的原因：`FluidContentIngredient` 的**字段**叫 `fluid`，而 `BlastFurnaceRecipe` 的字段也叫 `fluid` | 全库精确统计；`TFCIngredients.java:47` |
| `{"type":"tfc:item_stack_provider", ...}` | **不存在**（全库 0 次）。`ItemStackProvider` 不是可 dispatch 的类型，它在 JSON 里是「纯 `ItemStack`」或「`{stack, modifiers}` 对象」两种形态（见 R-29.1.1） | 全库精确统计 |

###### R-29.3.2 逐项详解

##### (1) `tfc:rotten` —— 腐败食物

| 项目 | 值 |
| --- | --- |
| 字段 | 无（`MapCodec.unit(INSTANCE)`，`RottenIngredient.java:26`、`:42-45`） |
| 语义 | `FoodCapability.isRotten(stack)`（`RottenIngredient.java:29-31`） |
| 展示修饰 | `modifyStackForDisplay` → `FoodCapability.setRotten(stack)`（`RottenIngredient.java:33-36`），即在 JEI/EMI 里展示「腐败态」的样子 |
| 数据用量 | **0** |
| 示意 JSON | `{"type":"tfc:rotten"}` |

##### (2) `tfc:not_rotten` —— 未腐败食物（TFC 数据包里出现最多的 ingredient）

| 项目 | 值 |
| --- | --- |
| 字段 | 无（`MapCodec.unit(INSTANCE)`，`NotRottenIngredient.java:26`、`:42-45`） |
| 语义 | `!FoodCapability.isRotten(stack)`（`NotRottenIngredient.java:29-31`） |
| 展示修饰 | `FoodCapability.setInvisibleNonDecaying(stack)`（`NotRottenIngredient.java:33-36`） |
| 数据用量 | **1418** |
| 真实用例 | `data/tfc/recipe/crafting/cake.json` → `{"type":"tfc:and","children":[{"item":"minecraft:egg"},{"type":"tfc:not_rotten"}]}` |
| JSON 示例 | `{"type":"tfc:not_rotten"}` |

##### (3) `tfc:has_trait` —— 带某食物标签

| 项目 | 值 |
| --- | --- |
| 字段 | `trait`（**必需**）：`FoodTrait.CODEC.fieldOf("trait").xmap(HasTraitIngredient::new, HasTraitIngredient::trait)`（`HasTraitIngredient.java:27`），JSON 写 trait id |
| 语义 | `FoodCapability.hasTrait(stack, this.trait)`（`HasTraitIngredient.java:34-36`） |
| 展示修饰 | 给展示物品**临时打上**该 trait，便于玩家看清（`HasTraitIngredient.java:38-41`） |
| 数据用量 | 2 |
| 真实用例 | `data/tfc/recipe/barrel/pickled.json` → `{"type":"tfc:has_trait","trait":"tfc:brined"}`（腌制需要先「盐渍」过的食物） |
| JSON 示例 | `{"type":"tfc:has_trait","trait":"tfc:brined"}` |

##### (4) `tfc:lacks_trait` —— 缺某食物标签

| 项目 | 值 |
| --- | --- |
| 字段 | `trait`（**必需**）：`FoodTrait.CODEC.fieldOf("trait")`（`LacksTraitIngredient.java:27`） |
| 语义 | `!FoodCapability.hasTrait(stack, this.trait)`（`LacksTraitIngredient.java:34-36`） |
| `PreciseIngredient` 的展示修饰 | 未覆写（用默认「原样返回」，`PreciseIngredient.java:28-30`） |
| 数据用量 | 334 |
| 真实用例 | `data/tfc/recipe/crafting/salting.json` → `{"type":"tfc:lacks_trait","trait":"tfc:salted"}`（不能重复上盐） |
| JSON 示例 | `{"type":"tfc:lacks_trait","trait":"tfc:salted"}` |

##### (5) `tfc:heat` —— 按温度区间匹配

| 项目 | 值 |
| --- | --- |
| 字段 | `min`：`Codecs.POSITIVE_FLOAT`，可选，默认 `Float.NEGATIVE_INFINITY`；`max`：同类型，可选，默认 `Float.POSITIVE_INFINITY` |
| CODEC | `RecordCodecBuilder.mapCodec(i -> i.group(Codecs.POSITIVE_FLOAT.optionalFieldOf("min", Float.NEGATIVE_INFINITY)..., Codecs.POSITIVE_FLOAT.optionalFieldOf("max", Float.POSITIVE_INFINITY)...))` + `flatXmap` 校验（**`min` 与 `max` 不能同时缺省**，否则报错 `Must have one of min or max`）（`HeatIngredient.java:44`） |
| 语义 | `float t = HeatCapability.getTemperature(stack); return t >= this.min && t <= this.max;`（`HeatIngredient.java:51-54`） |
| 展示修饰 | 把展示物品温度设成 `min`（若 `min` 是 `-∞` 则用 `max`），并追加温度 tooltip（`HeatIngredient.java:56-61`） |
| 数据用量 | 4（均在 `barrel` 的 `input_item` 中） |
| 真实用例 | `data/tfc/recipe/barrel/olive_oil_cooling.json` → `"input_item":{"type":"tfc:heat","count":1,"min":1.0}`（要求物品温度 ≥ 1，即「热油淬火」；`count` 是外层的 `SizedIngredient` 字段，不属于本 ingredient） |
| JSON 示例 | `{"type":"tfc:heat","min":1.0}`、`{"type":"tfc:heat","max":0.0}`、`{"type":"tfc:heat","min":100.0,"max":1000.0}` |

##### (6) `tfc:fluid_content` —— 按物品所含流体匹配

| 项目 | 值 |
| --- | --- |
| 字段 | `fluid`（**必需**）：`SizedFluidIngredient.FLAT_CODEC.fieldOf("fluid").xmap(FluidContentIngredient::new, FluidContentIngredient::fluid)`（`FluidContentIngredient.java:46`）。`FLAT_CODEC` 会把「流体 + 数量」摊平，因此 JSON 写成 `{"fluid":{"fluid":"<id>","amount":N}}` |
| 语义 | `this.fluid.test(FluidHelpers.getContainedFluid(stack))`（`FluidContentIngredient.java:53-55`）——物品必须通过 NeoForge 的 `Capabilities.FluidHandler.ITEM` 能力持有指定流体且数量足够 |
| 展示物品 | `getItems()` 会遍历 `TFCTags.Items.FLUID_ITEM_INGREDIENT_EMPTY_CONTAINERS` 标签下的空容器，逐个填充流体后作为展示项（`FluidContentIngredient.java:57-70`） |
| 数据用量 | 234 |
| 真实用例 | `data/tfc/recipe/crafting/cake.json` → `"M":{"type":"tfc:fluid_content","fluid":{"amount":100,"fluid":"minecraft:water"}}`；`data/tfc/recipe/crafting/food/barley_dough_1.json` → `"primary_ingredient":{"type":"tfc:fluid_content","fluid":{"amount":100,"fluid":"minecraft:water"}}`（面团配方要求 100 mB 水） |
| JSON 示例 | `{"type":"tfc:fluid_content","fluid":{"amount":100,"fluid":"minecraft:water"}}` |

##### (7) `tfc:and` —— 多条件与

| 项目 | 值 |
| --- | --- |
| 字段 | `children`（**必需**）：`Ingredient.CODEC.listOf().xmap(AndIngredient::new, AndIngredient::children).fieldOf("children")`（`AndIngredient.java:32`） |
| 语义 | 所有子条件**全部**成立才匹配（`AndIngredient.java:39-45`），等价于逻辑与 |
| `getItems()` 特例 | 以 `children` 的**第一个**元素的物品集合为基准，再对其中的 `PreciseIngredient` 子项调用 `modifyStackForDisplay` 做展示修饰（`AndIngredient.java:47-57`）——所以 `children[0]` 应当是「具体物品/标签」而不是 `tfc:not_rotten` 这类精确条件 |
| `isSimple()` | `false`（`AndIngredient.java:59-61`） |
| 数据用量 | **1418**（与 `tfc:not_rotten` 数量完全相同，因为 TFC 的惯用写法就是 `and(具体物品, not_rotten)`） |
| 真实用例 | `data/tfc/recipe/crafting/cake.json` → `{"type":"tfc:and","children":[{"tag":"c:foods/flour"},{"type":"tfc:not_rotten"}]}` |
| 数组写法 | `children` 中允许直接嵌套**数组**（NeoForge `Ingredient.CODEC` 的「或」形式）。实例：`data/tfc/recipe/barrel/pickled.json` → `{"type":"tfc:and","children":[[{"tag":"c:foods/fruit"},{"tag":"c:foods/vegetable"},{"tag":"c:foods/meat"},{"tag":"c:foods/fish"}],{"type":"tfc:not_rotten"},{"type":"tfc:has_trait","trait":"tfc:brined"},{"type":"tfc:lacks_trait","trait":"tfc:pickled"}]}` |
| JSON 示例 | `{"type":"tfc:and","children":[{"item":"minecraft:egg"},{"type":"tfc:not_rotten"}]}` |

###### R-29.3.3 `PreciseIngredient` —— 展示友好的自定义 ingredient 基接口

`net/dries007/tfc/common/recipes/ingredients/PreciseIngredient.java:18-31`：

```java
public interface PreciseIngredient extends ICustomIngredient {
    default Stream<ItemStack> getItems() {   // 默认：把「注册表里所有物品」逐个经 modifyStackForDisplay 后作为候选
        return BuiltInRegistries.ITEM.stream().map(Item::getDefaultInstance)
            .filter(e -> !e.isEmpty()).map(this::modifyStackForDisplay);
    }
    default boolean isSimple() { return false; }
    default ItemStack modifyStackForDisplay(ItemStack stack) { return stack; }
}
```

实现 `PreciseIngredient` 的 6 个类型：`NotRottenIngredient`、`RottenIngredient`、`HasTraitIngredient`、`LacksTraitIngredient`、`HeatIngredient`、以及 `AndIngredient`（`AndIngredient` 直接实现 `ICustomIngredient`，**不是** `PreciseIngredient`，见 `AndIngredient.java:30`）。`FluidContentIngredient` 也只实现 `ICustomIngredient`（`FluidContentIngredient.java:44`）。

**`isSimple()` 全为 `false` 的后果**：这些 ingredient 无法参与原版的「ingredient 展平/查询优化」（`CraftingInput` 的 `Ingredient` 匹配会走逐项 `test`），因此在大规模配方集合下会有性能开销；TFC 在 234 + 1418 处使用它们属于有意的取舍。

##### R-29.4 其它可用的 ingredient 形式（全局）

除 TFC 自定义的 7 种，配方中还能使用以下形式（均通过 `Ingredient.CODEC` 解析）：

| 形式 | JSON 写法 | 来源 | 数据用量 |
| --- | --- | --- | --- |
| 单个物品 | `{"item":"minecraft:stick"}` | 原版 `Ingredient` | 大量 |
| 物品标签 | `{"tag":"c:rods/wooden"}` | 原版 | 大量 |
| 「或」数组 | `[{"tag":"c:rods/wooden"},{"item":"minecraft:bone"}]` | 原版 | 见 `data/tfc/recipe/crafting/obsidian_axe.json` |
| `neoforge:compound` | `{"type":"neoforge:compound","children":[{...},{...}]}` | NeoForge 内置（`CompoundIngredient`） | 3 |
| `neoforge:difference` | `{"type":"neoforge:difference","base":{...},"subtracted":{...}}` | NeoForge 内置（`DifferenceIngredient`） | 1 |

`neoforge:compound` 的 TFC 实例（注意它出现在 **`SizedIngredient`** 位置，因此带 `count` 字段）：

```json
{"type":"tfc:barrel_instant","input_fluid":{"amount":100,"fluid":"minecraft:water"},"input_item":{"type":"neoforge:compound","children":[{"tag":"c:foods/soup"},{"tag":"c:foods/salad"}],"count":1},"output_item":{"modifiers":[{"type":"tfc:empty_bowl"}]}}
```

（来源：`data/tfc/recipe/barrel/clean_bowl.json`）

`neoforge:difference` 的 TFC 实例（在物品尺寸配置中，不在 crafting）：

```json
{"ingredient":{"type":"neoforge:difference","base":{"tag":"c:ingots"},"subtracted":{"tag":"c:bricks"}},"size":"large","weight":"medium"}
```

（来源：`data/tfc/tfc/item_size/ingots.json`）

**`SizedIngredient`（带 `count` 的 ingredient）**：NeoForge 的 `SizedIngredient.CODEC` 在 `Ingredient` 之外追加一个 `count` 字段（默认 1）。凡 JSON 里出现 `"count":N` 与 ingredient 并列的位置（如 `data/tfc/recipe/barrel/*.json` 的 `input_item`），都属于 `SizedIngredient` 而非普通 `Ingredient`。**本组的 5 种配方类型中**：`tfc:blast_furnace` 的 `fluid` 是 `SizedFluidIngredient`（按 mB 计数），`catalyst` 与两类 advanced 的 ingredient 都是**普通 `Ingredient`**（没有 `count` 字段）。

##### R-29.5 相关辅助类速查

| 类 / 方法 | 位置 | 作用 |
| --- | --- | --- |
| `ItemStackModifierType<T>(MapCodec<T> codec, StreamCodec<...> streamCodec)` | `net/dries007/tfc/common/recipes/outputs/ItemStackModifierType.java:16` | dispatch codec 的两半；`ItemStackModifiers.TYPES` 注册的就是它 |
| `ItemStackModifiers.KEY` = `tfc:item_stack_modifiers` | `ItemStackModifiers.java:54` | 注册表 key；`REGISTRY = new RegistryBuilder(KEY).sync(true).create()`（`:55`），**同步到客户端** |
| `RecipeHelpers.setCraftingInput / getCraftingInput / clearCraftingInput` | `RecipeHelpers.java:63, 70-84` | `ThreadLocal` 合成输入上下文，供需要遍历全部输入的 modifier 使用 |
| `RecipeHelpers.getRemainderItemsWithProvider(input, provider, primaryInput)` | `RecipeHelpers.java:86-102` | 剩余物列表的统一构造器；匹配 `primaryInput` 的槽位用 provider，其它槽位用 `getCraftingRemainingItem()` |
| `RecipeHelpers.translateMatch(recipe, targetIndex, inventory)` | `RecipeHelpers.java:183-198` | 把 pattern 索引换算成网格真实槽位（含镜像） |
| `RecipeHelpers.dissolveRowColumn(row, column, width)` | `RecipeHelpers.java:179-181` | `input_row`/`input_column` → 扁平索引 |
| `RecipeHelpers.getRecipes(level/manager, type)` | `RecipeHelpers.java:171-177` | 通过 `RecipeManagerAccessor` 按 type 取配方集合 |
| `RecipeSerializerImpl<R>(MapCodec<R>, StreamCodec<...>)` | `net/dries007/tfc/common/recipes/RecipeSerializerImpl.java:19` | TFC 所有配方的 serializer 实现体（只持有两个 codec）；单例版构造器为 `RecipeSerializerImpl(R singleInstance)`（`:21-23`） |
| `FoodData(int hunger, float water, float saturation, int intoxication, float[] nutrients, float decayModifier)` | `net/dries007/tfc/common/component/food/FoodData.java:33` | `tfc:meal` 的 `food` 字段类型；`nutrients` 展开为 `grain`/`fruit`/`vegetables`/`protein`/`dairy` 五个可选 float（`FoodData.java:35, 57-59`） |
| `FoodTrait.CODEC` = `FoodTraits.REGISTRY.holderByNameCodec()` | `net/dries007/tfc/common/component/food/FoodTrait.java:31` | `trait` 字段的解析方式（写 trait id 字符串） |
| `BlockIngredient(Either<ImmutableSet<Block>, TagKey<Block>>)` | `net/dries007/tfc/common/recipes/ingredients/BlockIngredient.java:43` | **注意：它不是 ingredient**（不实现 `ICustomIngredient`），只用于世界生成/塌方等按方块判定的场景，JSON 写法为 `["minecraft:stone", "#minecraft:base_stone_overworld"]` 形式的数组或标签（`BlockIngredient.java:45-46`） |
| `KeyedIngredient` | `net/dries007/tfc/common/recipes/ingredients/KeyedIngredient.java:28-54` | 内部用接口（`Predicate<ItemStack> + keys()`），用于配方索引/缓存，**不是 JSON 可写的 ingredient 类型** |
| `ItemStackProvider.of(...)` 的副作用 | `ItemStackProvider.java:68-70` | 所有经 `of(...)` 构造的 provider 都会把基底物品标记为「临时不腐败」 |

---

### 附录 A5-A：本组数据统计汇总

| 统计项 | 数值 | 证据 |
| --- | --- | --- |
| `data/tfc/recipe/crafting` 下 jar 清单条目数 | 3001（含 106 个目录条目） | `moddev/inventory/TFC.resources.txt` |
| 同上目录下 `.json` 文件数 | 2895 | 清单过滤 + 解包目录实测一致 |
| crafting 顶层配方类型合计 | 2895（每个文件恰好一个配方） | type 分布求和 |
| `minecraft:crafting_shaped` | 1669 | 实测 |
| `minecraft:crafting_shapeless` | 569 | 实测 |
| `tfc:advanced_shaped_crafting` | 372 | 实测 |
| `tfc:advanced_shapeless_crafting` | 283 | 实测 |
| `tfc:casting_crafting` / `tfc:food_combining` | 各 1 | 实测 |
| `tfc:blast_furnace` | 1（`data/tfc/recipe/blast_furnace/pig_iron.json`） | 实测 |
| advanced 配方中含 `modifiers` 的文件数 | 655（= 372 + 283） | 实测，与原版两类 0 命中互补 |
| 含 `"group"` / `show_notification` 的文件数 | 0 / 0 | 实测 |
| `advanced_shaped` 中带 `input_row` 或 `input_column` 的数量 | 69 / 372 | 实测 |
| `advanced_shaped` 中带 `remainder` 的数量 | 246 / 372 | 实测 |
| `advanced_shapeless` 中带 `primary_ingredient` 的数量 | 283 / 283（**无缺省**） | 实测 |
| `advanced_shapeless` 中带 `remainder` 的数量 | 228 / 283（55 个缺省） | 实测 |
| modifier 用量前五 | `damage_crafting_remainder` 474、`copy_input` 359、`add_trait` 334、`meal` 186、`copy_forging_bonus` 126 | 全库实测 |
| 源码中注册但数据从未使用的 modifier | `copy_heat`、`reset_food`、`crafting_remainder` | 全库实测均为 0 |
| 源码中注册但数据从未使用的 ingredient | `tfc:rotten` | 全库实测为 0 |

### 附录 A5-B：证据索引（关键源码行）

| 内容 | 文件 : 行 |
| --- | --- |
| `BlastFurnaceRecipe` record 与 CODEC | `net/dries007/tfc/common/recipes/BlastFurnaceRecipe.java:45, 48, 49` |
| `BlastFurnaceRecipe` 查询与匹配 | 同文件 `:52-67`、`:69-84`、`:86-92` |
| 高炉驱动 | `net/dries007/tfc/common/blockentities/BlastFurnaceBlockEntity.java:167, 169-170, 421, 437, 442, 447, 471-473` |
| `AdvancedShapedRecipe` CODEC / 字段 / 覆写 | `net/dries007/tfc/common/recipes/AdvancedShapedRecipe.java:51, 53-57, 59-66, 68-79, 81-90, 92-94, 96-98` |
| `AdvancedShapelessRecipe` CODEC / 字段 / 覆写 | `net/dries007/tfc/common/recipes/AdvancedShapelessRecipe.java:54-58, 60-62, 64-69, 71-80, 82-89, 91-99, 101-107, 109-121` |
| serializer 注册 | `net/dries007/tfc/common/recipes/TFCRecipeSerializers.java:77, 80-83` |
| recipe type 注册 | `net/dries007/tfc/common/recipes/TFCRecipeTypes.java:61` |
| `RecipeHelpers` 输入上下文 / 剩余物 / 索引换算 | `net/dries007/tfc/common/recipes/RecipeHelpers.java:63, 70-84, 86-102, 171-177, 179-181, 183-214` |
| datagen 的 advanced 判定 | `net/dries007/tfc/util/DataGenerationHelpers.java:202-206, 221-226, 248-251, 266-272, 274-280` |
| `ItemStackProvider` CODEC / 求值 | `net/dries007/tfc/common/recipes/outputs/ItemStackProvider.java:34-36, 40-70, 72-101, 103-109` |
| `ItemStackModifier` 接口与 Context | `net/dries007/tfc/common/recipes/outputs/ItemStackModifier.java:21-38` |
| modifier 注册清单 | `net/dries007/tfc/common/recipes/outputs/ItemStackModifiers.java:54-56, 57-78, 80-86` |
| `TFCIngredients` 注册清单 | `net/dries007/tfc/common/recipes/ingredients/TFCIngredients.java:41-51` |
| 各 ingredient CODEC | `AndIngredient.java:30-33`、`NotRottenIngredient.java:22-27, 42-45`、`RottenIngredient.java:22-27, 42-45`、`HasTraitIngredient.java:25-28`、`LacksTraitIngredient.java:25-28`、`HeatIngredient.java:40-45`、`FluidContentIngredient.java:44-47`、`PreciseIngredient.java:18-31` |
| 各 modifier CODEC / apply / type | `AddBaitToRodModifier.java:17, 23-36`、`AddGlassModifier.java:15, 21-29`、`AddHeatModifier.java:28-42`、`AddPowderModifier.java:17, 24-36`、`AddTraitModifier.java:24-36`、`ChanceModifier.java:27-47`、`CopyFoodModifier.java:15, 21-26`、`CopyForgingBonusModifier.java:15, 21-26`、`CopyHeatModifier.java:18, 23-36`、`CopyInputModifier.java:14, 20-30`、`CopyOldestFoodModifier.java:18, 23-28`、`CraftingRemainderModifier.java:14, 20-25`、`DamageCraftingRemainderModifier.java:22, 28-42`、`DyeLeatherModifier.java:27-41`、`EmptyBowlModifier.java:17, 23-30`、`ExtraProductModifier.java:28-44`、`FlowerCuttingModifier.java:16, 22-30`、`MealModifier.java:50-53, 55-116, 118-122`、`RemoveDyeModifier.java:16, 22-33`、`RemoveTraitModifier.java:24-36`、`ResetFoodModifier.java:15, 21-26`、`RoundCreationDateModifier.java:15, 21-26` |
| `FoodData` CODEC 与字段 | `net/dries007/tfc/common/component/food/FoodData.java:33, 35, 48-51, 57-59` |
| `FoodTrait` CODEC | `net/dries007/tfc/common/component/food/FoodTrait.java:31-32` |
| 工作台容器 | `net/dries007/tfc/common/container/TFCWorkbenchContainer.java:19-35` |
| 仅有的配方相关 mixin | `net/dries007/tfc/mixin/RecipeManagerMixin.java:29-35` |
| JEI / EMI 兼容层 | `net/dries007/tfc/compat/jei/TFCCraftingExtensions.java:30, 40-43`；`net/dries007/tfc/compat/emi/EmiIntegration.java:303-313`；`net/dries007/tfc/compat/emi/recipe/EmiAdvancedShapedRecipe.java:27-46`；`EmiAdvancedShapelessRecipe.java:38-45` |
| 字节码证据（client jar） | `javap -p -c net.minecraft.world.item.crafting.ShapedRecipe$Serializer`（`group` / `category` / `result` / `show_notification`）、`ShapelessRecipe$Serializer`（`group` / `category` / `result` / `ingredients`）、`CraftingRecipe`（`getType()` default → `RecipeType.CRAFTING`）、`Recipe`（`isSpecial()` default → false）、`ShapedRecipePattern$Data`（`key` / `pattern` + 3×3 校验文本） |

### 附录 A5-C：未能核实项（明确列出检查过的文件）

| # | 未核实内容 | 已检查范围 | 说明与影响 |
| --- | --- | --- | --- |
| 1 | 原版 `ShapedRecipe` / `ShapelessRecipe` / `ShapedRecipePattern` 的**源码与注释** | 反编译树 `moddev/src-ref/TFC-decompiled`（仅含 TFC，无 `net/minecraft` 包）；改用 client jar 的 `javap -p -c` 字节码 | 字段名/必需性/默认值已由字节码确认；但**参数名、注释、`ExtraCodecs` 的具体严格性语义**无法从字节码完全还原 |
| 2 | 原版 `CraftingMenu` / `RecipeBook` 内部是否、以及如何使用 `isSpecial()` 与 `showNotification()` | client jar 中未逐一反编译该类；TFC 侧无相关 mixin | 只能确定「TFC 覆写了 `isSpecial()`」这一事实，其**游戏内可见后果**（配方书是否展示、提示是否弹出）未核实。`isSpecial` 的具体用途属本表未核实项 |
| 3 | `SizedFluidIngredient.FLAT_CODEC` 的完整取值集合（是否支持 `{"tag":...}`、`neoforge:compound` 等流体形式） | NeoForge 类不在反编译树中；TFC 数据包里只出现 `{"fluid":"<id>","amount":N}` 一种形式（`blast_furnace/pig_iron.json`） | 本组只断言「实测形态」，未断言「全部可用形态」 |
| 4 | `FluidStack.CODEC` 的完整字段（是否支持 `components` / NBT） | 同上；TFC 数据包只出现 `{"id":"<fluid>","amount":N}` | 未断言 |
| 5 | `ItemStack.CODEC` 的完整字段（`components` 等）与字符串简写是否合法 | 实测 TFC 数据包中 `result` 100% 为 `{"count":N,"id":"..."}`，无字符串形式；未在 client jar 中反编译 `ItemStack` 的 codec | 本组只断言「TFC 数据包的用法」，模组作者若使用 `components` 需自行验证 |
| 6 | `FoodTraits` 注册表中**全部 trait id 清单** | `FoodTrait.java:31-32`（codec）、`recipes/ingredients/` 与 `outputs/` 中的用法 | 数据中出现过的仅 `tfc:salted`、`tfc:pickled`、`tfc:brined`、`tfc:vinegar`（及 `barrel` 目录中其它若干）；完整清单在 `net/dries007/tfc/common/component/food/FoodTraits.java`，本任务未逐项枚举 |
| 7 | `tfc:advanced_shaped_crafting` 的 `input_row` / `input_column` 越界时的确切行为 | `RecipeHelpers.java:179-198`、`AdvancedShapedRecipe.java:63, 70-71` | 源码显示越界会导致 `translateMatch` 返回 `-1` → 输入为空；但**是否在日志中产生告警**未核实（未见校验代码，但未做运行时验证） |
| 8 | TFC 是否在**客户端**对 `RecipeType.CRAFTING` 配方做额外过滤/排序 | `net/dries007/tfc/client/` 与 `common/container/` 全树 | 未发现对 crafting 配方集合的过滤逻辑；但未逐文件通读客户端配方书相关代码 |
| 9 | `tfc:food_combining` 与 `tfc:casting_crafting` 的字段情况 | 已确认二者 serializer 为 `RecipeSerializerImpl(单例)`（`TFCRecipeSerializers.java:80-81`），对应 JSON 文件无任何字段 | 二者不是本组负责的类型，仅作 distribution 说明；**其匹配逻辑**（`FoodCombiningCraftingRecipe.java:36-56`、`CastingCraftingRecipe.java:43-48`）未深入考证 |
| 10 | `tfc:blast_furnace` 中 `result` 的 `amount` 与 `fluid.amount` 比例关系在**非 1:1** 情形下的实际表现 | `BlastFurnaceRecipe.java:86-92` 已读数，机制清楚；TFC 数据包只有 1 条 1:1 配方 | 未做运行时验证（无运行环境），只有源码级推断 |


---

## 第 6 部分　`data/tfc/tfc/<kind>/` 数据类型全解（D-1 ~ D-17）


本部分覆盖 TFC 4.2.10 中 `data/tfc/tfc/<kind>/` 下的全部数据类型。所有字段均从反编译源码的 `Codec` / `RecordCodecBuilder` 逐行读取确认，JSON 样例均取自本地 jar 真实文件。

### [D-0] 数据加载机制总览（必读）

##### D-0.1 两种加载途径

TFC 的 `data/tfc/tfc/<kind>/` 下有**两套完全不同的加载机制**，附属模组写法差别很大：

| 机制 | 归属类 | 目录特征 | 覆盖方式 |
| --- | --- | --- | --- |
| `DataManager<T>`（SimpleJsonResourceReloadListener） | `net.dries007.tfc.util.data.DataManager` | `data/<ns>/tfc/<kind>/...` | 服务器资源重载；同名 ID 覆盖取决于加载顺序 |
| 数据包注册表（datapack registry） | `event.dataPackRegistry(...)` | `data/<ns>/tfc/<kind>/...` | 数据包注册表，同名 ID 由数据包覆盖 |

**来源**：`net/dries007/tfc/util/data/DataManager.java` L56-L80；`net/dries007/tfc/TerraFirmaCraft.java` L238（`event.dataPackRegistry(RockSettings.KEY, RockSettings.CODEC)`）。

##### D-0.2 `DataManager` 的路径规则（关键结论）

`DataManager` 构造签名与资源路径来源（`DataManager.java` L71-L80）：

```java
public DataManager(ResourceLocation domain, Codec<T> codec, @Nullable StreamCodec<RegistryFriendlyByteBuf, T> streamCodec) {
    super(GSON, domain.getNamespace() + "/" + domain.getPath());
    ...
}
```

所有 `MANAGER` 都用 `Helpers.identifier("<kind>")` 构造，而 `Helpers.identifier` 等价于 `tfc:<name>`（`net/dries007/tfc/util/Helpers.java`）：

```java
public static ResourceLocation identifier(String name) { return Helpers.resourceLocation("tfc", name); }
```

因此 `SimpleJsonResourceReloadListener` 的目录参数为 `"tfc/" + kind`，即实际扫描目录是：

```
data/<任意命名空间>/tfc/<kind>/**.json
```

**推论（对附属模组最重要的一点）**：

1. 附属模组要在 `data/<你的modid>/tfc/<kind>/<任意路径>.json` 放文件，而**不是** `data/<你的modid>/<kind>/`。第一个 `tfc` 是固定字面量，与命名空间无关。
2. 资源位置（ID）由 `data/` 之后的路径去掉 `tfc/<kind>/` 前缀、并去掉 `.json` 得到，**命名空间取自 `data/` 后的第一段**。例：

```
data/tfc/tfc/item_heat/copper/sheet.json          → tfc:copper/sheet
data/tfc/tfc/climate_range/crop/barley.json       → tfc:crop/barley
data/tfc/tfc/deposit/native_copper/granite.json   → tfc:native_copper/granite
data/mymod/tfc/item_heat/my_alloy/ingot.json      → mymod:my_alloy/ingot
```

3. **不要求** `kind` 目录名带任何 tag；也没有“替换 tfc 数据必须打 tag”的约定。
4. 子目录是**递归**的，真实 jar 中 `item_heat` 下有 33 个子目录、`climate_range` 下有 `crop`/`plant`、`deposit` 下有 4 个矿物子目录（实测见下）。

`DataManager` 只做一件事：把所有 `data/*/tfc/<kind>/**.json` 全部解析进一个 `Map<ResourceLocation, T>`（`DataManager.java` L154-L170）：

```java
protected void apply(Map<ResourceLocation, JsonElement> elements, ResourceManager resourceManagerIn, ProfilerFiller profilerIn) {
    ImmutableMap.Builder builder = ImmutableMap.builder();
    RegistryOps ops = this.getRegistryLookup().createSerializationContext((DynamicOps)JsonOps.INSTANCE);
    for (Map.Entry<ResourceLocation, JsonElement> entry : elements.entrySet()) {
        ResourceLocation id = entry.getKey();
        try {
            builder.put(id, this.codec.parse(ops, entry.getValue()).getOrThrow(JsonParseException::new));
        } catch (JsonParseException | IllegalArgumentException e) { ... }
    }
    ...
}
```

注意 `ImmutableMap.Builder` 遇到重复 key 会抛异常，所以**两个模组写同一个 ID 是冲突而非静默覆盖**；要覆盖 TFC 数据应当使用**不同的命名空间 ID**（例如 `mymod:xxx` 而不是 `tfc:xxx`），或者在 datapack 层面用同名网络包覆盖。实践中推荐「新 ID + tag」而不是硬覆盖。

##### D-0.3 数据是否同步到客户端

`isSynced()` 返回 `streamCodec != null`（`DataManager.java` L124）。有 `STREAM_CODEC` 的 kind 会把整表同步给客户端（用于 tooltip、JEI、渲染）。实测各类是否同步：

| kind | 是否同步（有 STREAM_CODEC） |
| --- | --- |
| `item_heat` | 是 |
| `food` | 是 |
| `item_size` | 是 |
| `fuel` | 是 |
| `fluid_heat` | 是 |
| `fertilizer` | 是 |
| `lamp_fuel` | 是 |
| `drinkable` | 是 |
| `deposit` | 是 |
| `knapping_type` | 是 |
| `support` | 是 |
| `climate_range` | 是 |
| `item_damage_resistance` | 是 |
| `entity_damage_resistance` | **否**（`new DataManager<>(..., CODEC)` 只有两个参数） |
| `fauna` | **否** |
| `worldgen/rock_settings` | 数据包注册表（非 DataManager） |

来源：各类 `MANAGER` 字段声明行。

##### D-0.4 通用代码片段模板

所有 kind 的字段表都遵循「`fieldOf` = 必填，`optionalFieldOf(name, default)` = 可选且有默认值」。附属模组最常用的**前置声明写法**：

```json
// ingredient：单物品
{"item": "minecraft:iron_ingot"}
// ingredient：物品 tag
{"tag": "c:ingots/iron"}
// ingredient：物品数组（任意一个匹配）
[{"item": "tfc:food/potato"}, {"item": "tfc:food/cooked_potato"}]
// ingredient：NeoForge 组合类型
{"type": "neoforge:difference", "base": {"tag": "c:ingots"}, "subtracted": {"tag": "c:bricks"}}
// block ingredient：单方块
"tfc:rock/raw/granite"
// block ingredient：方块 tag
"#tfc:rock/raw"
// block ingredient：方块数组
["tfc:wood/horizontal_support/acacia", "tfc:wood/horizontal_support/ash"]
// fluid ingredient：单流体
{"fluid": "minecraft:water"}
// fluid ingredient：流体数组
[{"fluid": "minecraft:water"}, {"fluid": "tfc:river_water"}]
```

来源：`BlockIngredient.CODEC`（`net/dries007/tfc/common/recipes/ingredients/BlockIngredient.java`）、jar 内真实文件 `data/tfc/tfc/support/horizontal_support_beam.json`、`data/tfc/tfc/drinkable/water.json`、`data/tfc/tfc/item_size/ingots.json`。

---

### [D-1] `item_heat` —— 物品热容与锻造温度

##### D-1.1 基本信息

| 项目 | 值 |
| --- | --- |
| 数据类 | `net.dries007.tfc.common.component.heat.HeatDefinition`（record） |
| 管理器 | `net.dries007.tfc.common.component.heat.HeatCapability.MANAGER` |
| 注册路径 | `tfc:item_heat` → 目录 `data/*/tfc/item_heat/**` |
| 同步 | 是（有 `STREAM_CODEC`） |
| 真实文件数 | 343 个（含 33 个子目录） |

**来源**：`net/dries007/tfc/common/component/heat/HeatCapability.java` L43；`net/dries007/tfc/common/component/heat/HeatDefinition.java` L28-L32。

##### D-1.2 字段表

来源：`HeatDefinition.java` L30 的 `CODEC` 定义：

```java
public static final Codec<HeatDefinition> CODEC = RecordCodecBuilder.create(i -> i.group(
    Ingredient.CODEC.fieldOf("ingredient").forGetter(c -> c.ingredient),
    Codec.FLOAT.fieldOf("heat_capacity").forGetter(c -> c.heatCapacity),
    Codec.FLOAT.optionalFieldOf("forging_temperature", 0.0f).forGetter(c -> c.forgingTemperature),
    Codec.FLOAT.optionalFieldOf("welding_temperature", 0.0f).forGetter(c -> c.weldingTemperature)
).apply(i, HeatDefinition::new));
```

| 字段名 | 类型 | 必需 | 默认值 | 语义 |
| --- | --- | --- | --- | --- |
| `ingredient` | `Ingredient` | **必需** | — | 匹配哪些物品获得热属性。支持 `item` / `tag` / 数组 / NeoForge 组合类型 |
| `heat_capacity` | float | **必需** | — | 热容量。数值越大升温越慢、降温越慢。典型值：锭 2.0、陶坯 0.4~0.6、未烧制风箱管 0.6 |
| `forging_temperature` | float | 可选 | `0.0` | 可锻造（砧上加工）的最低温度 |
| `welding_temperature` | float | 可选 | `0.0` | 可焊接的最低温度 |

##### D-1.3 真实 JSON 样例

样例 1 —— 铜片（完整可选字段齐全）：`data/tfc/tfc/item_heat/copper/sheet.json`

```json
{"forging_temperature":648.0,"heat_capacity":5.714286,"ingredient":{"tag":"c:sheets/copper"},"welding_temperature":864.0}
```

样例 2 —— 熟铁锭：`data/tfc/tfc/item_heat/wrought_iron/ingot.json`（同结构，`ingredient` 为 `{"tag":"c:ingots/wrought_iron"}`）

样例 3 —— 只给最简字段（无可选字段），生土豆：`data/tfc/tfc/item_heat/food/potato.json`

```json
{"heat_capacity":1.0,"ingredient":{"item":"tfc:food/potato"}}
```

样例 4 —— 陶坯（`heat_capacity` 很小，可快速烧制）：`data/tfc/tfc/item_heat/ceramic/unfired_bowl.json`

```json
{"heat_capacity":0.4,"ingredient":{"item":"tfc:ceramic/unfired_bowl"}}
```

样例 5 —— 多物品共用一条定义（数组 ingredient）：`data/tfc/tfc/item_heat/food/fresh_seaweed.json`

```json
{"heat_capacity":1.0,"ingredient":[{"item":"tfc:food/fresh_seaweed"},{"item":"tfc:food/dried_seaweed"},{"item":"tfc:food/dried_kelp"},{"item":"tfc:plant/giant_kelp_flower"}]}
```

样例 6 —— 合金系列用统一 tag：`data/tfc/tfc/item_heat/unknown/ingot.json`

```json
{"forging_temperature":240.00002,"heat_capacity":2.0,"ingredient":{"tag":"c:ingots/unknown"},"welding_temperature":320.0}
```

**实测子目录清单**（`jar-extract/data/tfc/tfc/item_heat/`）：`bismuth`、`bismuth_bronze`、`black_bronze`、`black_steel`、`blue_steel`、`brass`、`bronze`、`cast_iron`、`ceramic`、`copper`、`food`、`foods`、`gold`、`high_carbon_black_steel`、`high_carbon_blue_steel`、`high_carbon_red_steel`、`high_carbon_steel`、`nickel`、`pig_iron`、`powder`、`red_steel`、`rods`、`rose_gold`、`silver`、`steel`、`sterling_silver`、`tin`、`unknown`、`weak_blue_steel`、`weak_red_steel`、`weak_steel`、`wrought_iron`、`zinc`（共 33 个）。

##### D-1.4 运行时如何被读取

| API | 语义 | 来源 |
| --- | --- | --- |
| `HeatCapability.getDefinition(ItemStack)` | 查定义，返回 `@Nullable HeatDefinition` | `HeatCapability.java` L95-L97 |
| `HeatCapability.get(ItemStack)` | 返回可写 `IHeat`（来自 capability 或 `TFCComponents.HEAT` 组件） | 同上 L48-L55 |
| `HeatCapability.view(ItemStack)` | 只读视图 | 同上 L58-L61 |
| `HeatCapability.has(ItemStack)` | 是否带 HEAT 组件 | 同上 L67-L69 |
| `HeatCapability.getTemperature(ItemStack)` | 当前温度 | 同上 L71-L74 |
| `HeatCapability.addTemp(IHeat, float)` | 加热 | 同上 L154-L168 |

**重要**：物品**只有存在 `item_heat` 定义时才能被加热**。`HeatCapability.get(stack)` 会先查 `ItemCapabilities.HEAT`（仅注册给模具 molds 与容器 vessels，见 `ItemCapabilities.java`）或 `TFCComponents.HEAT` 组件；组件由定义动态附加。附属模组新增的可加热物品**必须补 `item_heat`**，否则锻造炉/木炭堆不会给它加温。

##### D-1.5 附属模组写法示例

```json
// 文件：data/mymod/tfc/item_heat/titanium/ingot.json  → ID mymod:titanium/ingot
{
  "ingredient": { "tag": "c:ingots/titanium" },
  "heat_capacity": 2.5,
  "forging_temperature": 1200.0,
  "welding_temperature": 1500.0
}
```

若要复用 TFC 的锻造温度梯度，可直接引用 TFC 的 `c:*` tag（所有 TFC 金属都已加入 `c:ingots/<metal>`）。

---

### [D-2] `food` —— 食物营养与腐坏

##### D-2.1 基本信息

| 项目 | 值 |
| --- | --- |
| 数据类 | `net.dries007.tfc.common.component.food.FoodDefinition`（record） |
| 管理器 | `net.dries007.tfc.common.component.food.FoodCapability.MANAGER` |
| 注册路径 | `tfc:food` → 目录 `data/*/tfc/food/**` |
| 同步 | 是 |
| 真实文件数 | 195 个（含 `jar` 子目录） |

**来源**：`net/dries007/tfc/common/component/food/FoodCapability.java`（`MANAGER` 字段行）；`FoodDefinition.java` L29-L33。

##### D-2.2 字段表

来源：`FoodDefinition.java` L31：

```java
public static final Codec<FoodDefinition> CODEC = RecordCodecBuilder.create(i -> i.group(
    Ingredient.CODEC.fieldOf("ingredient").forGetter(c -> c.ingredient),
    FoodData.MAP_CODEC.forGetter(c -> c.food),
    Codec.BOOL.optionalFieldOf("edible", true).forGetter(c -> c.edible)
).apply(i, FoodDefinition::new));
```

注意 `FoodData.MAP_CODEC` 是 `mapCodec`，其字段被**直接内联到本 JSON 顶层**（不是嵌套对象）。

`FoodData` 的字段（`net/dries007/tfc/common/component/food/FoodData.java` L48）：

| 字段名 | 类型 | 必需 | 默认值 | 语义 |
| --- | --- | --- | --- | --- |
| `hunger` | int | 可选 | `0` | 恢复饥饿值 |
| `water` | float | 可选 | `0.0` | 恢复口渴值（负数表示反而耗水） |
| `saturation` | float | 可选 | `0.0` | 饱和度 |
| `intoxication` | int | 可选 | `0` | 醉酒值积累 |
| `grain` | float | 可选 | `0.0` | 谷物营养 |
| `fruit` | float | 可选 | `0.0` | 水果营养 |
| `vegetables` | float | 可选 | `0.0` | 蔬菜营养 |
| `protein` | float | 可选 | `0.0` | 蛋白质营养 |
| `dairy` | float | 可选 | `0.0` | 乳制品营养 |
| `decay_modifier` | float 或字符串 `"infinity"` | 可选 | `0.0` | 腐坏速度倍率。`"infinity"` 表示永不腐坏（`Codec.either(Codec.FLOAT, Codec.STRING)` + `comapFlatMap`，L48） |

外加 `FoodDefinition` 自身的两个字段：

| 字段名 | 类型 | 必需 | 默认值 | 语义 |
| --- | --- | --- | --- | --- |
| `ingredient` | `Ingredient` | **必需** | — | 匹配哪些物品是食物 |
| `edible` | bool | 可选 | `true` | 是否可食用。`false` 表示“有营养数据但玩家不能直接吃”（用于原料/饲料类物品） |

营养字段名由 `Nutrient` 枚举的 `getSerializedName()` 决定（`net/dries007/tfc/common/component/food/Nutrient.java`），顺序为 `GRAIN`、`FRUIT`、`VEGETABLES`、`PROTEIN`、`DAIRY`，`TOTAL = Nutrient.values().length = 5`。

##### D-2.3 真实 JSON 样例

样例 1 —— 烤牛肉（营养齐全）：`data/tfc/tfc/food/cooked_beef.json`

```json
{"decay_modifier":1.5,"hunger":4,"ingredient":{"item":"tfc:food/cooked_beef"},"protein":2.5,"saturation":2.0}
```

样例 2 —— 南瓜派（五种营养都用上）：`data/tfc/tfc/food/pumpkin_pie.json`

```json
{"dairy":0.3,"decay_modifier":2.5,"grain":1.0,"hunger":4,"ingredient":{"item":"minecraft:pumpkin_pie"},"protein":1.0,"saturation":2.0,"vegetables":2.0,"water":5.0}
```

样例 3 —— 煮鸡蛋（含 water 字段）：`data/tfc/tfc/food/boiled_egg.json`

```json
{"dairy":0.6,"decay_modifier":4.0,"hunger":4,"ingredient":{"item":"tfc:food/boiled_egg"},"protein":1.2,"saturation":2.0,"water":10.0}
```

##### D-2.4 运行时如何被读取

| API | 语义 | 来源 |
| --- | --- | --- |
| `FoodCapability.getDefinition(ItemStack)`（经由 `CACHE`） | 查食物定义 | `FoodCapability.java` |
| `FoodCapability.markRecipeOutputsAsNonDecaying(RegistryAccess, RecipeManager)` | 把配方输出标记为不腐坏 | `FoodCapability.java` |
| `FoodTraits.REGISTRY` / `FoodTrait` | 附加腐坏修正（腌制、盐渍、熏烤等） | `net/dries007/tfc/common/component/food/FoodTraits.java` |

内置 food trait 注册名（`FoodTraits.java`）：`salted`、`brined`、`pickled`、`preserved`、`vinegar`、`charcoal_grilled`、`wood_grilled`、`burnt_to_a_crisp`、`wild`、`canned`。它们注册在独立注册表 `ResourceKey<Registry<FoodTrait>> KEY = Helpers.identifier("food_trait")`，**由 `TFCComponents` 的 trait 列表引用**，不是通过 `tfc/food` 目录的数据文件声明的。附属模组若要给出自定义 trait，应注册自己的 `FoodTrait`（Java 侧）并在配方/物品上附加。

**重要**：食物定义只对 `ingredient` 命中的物品生效。新增食品必须在 `data/<modid>/tfc/food/` 中补充定义，否则该物品没有 hunger/water/nutrient 数据，玩家吃它不会产生 TFC 食物效果。

##### D-2.5 附属模组写法示例

```json
// 文件：data/mymod/tfc/food/candied_yam.json → ID mymod:candied_yam
{
  "ingredient": { "item": "mymod:candied_yam" },
  "hunger": 4,
  "water": 2.0,
  "saturation": 2.5,
  "vegetables": 1.5,
  "decay_modifier": 1.2
}
```

`decay_modifier` 写 `"infinity"` 可让该食物永不腐烂：

```json
{ "ingredient": { "item": "mymod:eternal_ration" }, "hunger": 4, "saturation": 2.0, "decay_modifier": "infinity" }
```

---

### [D-3] `item_size` —— 物品体积与重量

##### D-3.1 基本信息

| 项目 | 值 |
| --- | --- |
| 数据类 | `net.dries007.tfc.common.component.size.ItemSizeDefinition`（record） |
| 管理器 | `net.dries007.tfc.common.component.size.ItemSizeManager.MANAGER` |
| 注册路径 | `tfc:item_size` → 目录 `data/*/tfc/item_size/**` |
| 同步 | 是 |
| 真实文件数 | 67 个（无子目录） |

**来源**：`net/dries007/tfc/common/component/size/ItemSizeManager.java` L39；`ItemSizeDefinition.java` L28-L31。

##### D-3.2 字段表

来源：`ItemSizeDefinition.java` L30：

```java
public static final Codec<ItemSizeDefinition> CODEC = RecordCodecBuilder.create(i -> i.group(
    Ingredient.CODEC.fieldOf("ingredient").forGetter(c -> c.ingredient),
    Size.CODEC.fieldOf("size").forGetter(c -> c.size),
    Weight.CODEC.fieldOf("weight").forGetter(c -> c.weight)
).apply(i, ItemSizeDefinition::new));
```

| 字段名 | 类型 | 必需 | 默认值 | 语义 |
| --- | --- | --- | --- | --- |
| `ingredient` | `Ingredient` | **必需** | — | 匹配物品 |
| `size` | `Size` 枚举字符串 | **必需** | — | 体积 |
| `weight` | `Weight` 枚举字符串 | **必需** | — | 重量 |

`Size` 取值（`net/dries007/tfc/common/component/size/Size.java`）：`tiny`、`very_small`、`small`、`large`、`very_large`、`huge`（`StringRepresentable.fromEnum`，序列化为小写）。
`Weight` 取值（`Weight.java`）：`very_light`、`light`、`medium`、`heavy`、`very_heavy`。

##### D-3.3 真实 JSON 样例

样例 1 —— 矿石碎粒：`data/tfc/tfc/item_size/ores.json`

```json
{"ingredient":{"tag":"tfc:ore_pieces"},"size":"small","weight":"medium"}
```

样例 2 —— 原木：`data/tfc/tfc/item_size/logs.json`

```json
{"ingredient":{"tag":"minecraft:logs"},"size":"very_large","weight":"medium"}
```

样例 3 —— 食物（引用 NeoForge 统一 tag）：`data/tfc/tfc/item_size/foods.json`

```json
{"ingredient":{"tag":"c:foods"},"size":"small","weight":"light"}
```

样例 4 —— 工具（数组 ingredient）：`data/tfc/tfc/item_size/tools.json`

```json
{"ingredient":[{"tag":"minecraft:pickaxes"},{"tag":"minecraft:shovels"},{"tag":"minecraft:hoes"},{"tag":"c:tools/hammer"},{"tag":"c:tools/saw"},{"tag":"c:tools/scythe"},{"tag":"c:tools/propick"},{"tag":"c:tools/fishing_rod"},{"tag":"c:tools/shield"},{"tag":"c:tools/melee_weapon"},{"tag":"c:tools/ranged_weapon"},{"tag":"tfc:all_blowpipes"},{"tag":"c:tools/glassworking"},{"tag":"c:tools/mace"}],"size":"very_large","weight":"very_heavy"}
```

样例 5 —— 粉末：`data/tfc/tfc/item_size/powders.json`

```json
{"ingredient":{"tag":"tfc:bowl_powders"},"size":"tiny","weight":"very_light"}
```

样例 6 —— NeoForge 组合类型 ingredient：`data/tfc/tfc/item_size/ingots.json`

```json
{"ingredient":{"type":"neoforge:difference","base":{"tag":"c:ingots"},"subtracted":{"tag":"c:bricks"}},"size":"large","weight":"medium"}
```

**实测全部文件**（67 个）：`alabaster_brick`、`anemometer`、`anvils`、`basket`、`bloomery`、`boats`、`bowls`、`brass_mechanisms`、`buckets`、`burlap_cloth`、`cactus_wood`、`calendar_clock`、`chests`、`doors`、`double_ingots`、`double_sheets`、`dusts`、`dyes`、`empty_jars`、`filled_jars`、`fired_molds`、`firepit_attachments`、`foods`、`glass_bottles`、`glue`、`grill`、`hanging_signs`、`ingots`、`jute`、`lamps`、`large_vessels`、`logs`、`looms`、`minecarts`、`mold_tables`、`ores`、`plants`、`powders`、`power_loom`、`quern`、`rails`、`rods`、`salads`、`scribing_tables`、`sheets`、`signs`、`slabs`、`sluices`、`small_ores`、`small_tools`、`soups`、`stairs`、`stick_bunch`、`stick_bundle`、`straw`、`tools`、`tool_racks`、`trapdoors`、`tuyeres`、`unfired_crucible`、`unfired_molds`、`vane`、`vessels`、`water_wheels`、`windmill_blades`、`wool`、`wool_cloth`。

##### D-3.4 运行时如何被读取

| API | 语义 | 来源 |
| --- | --- | --- |
| `ItemSizeManager.get(ItemStack)` → `IItemSize` | 取体积/重量接口，永不返回 null | `ItemSizeManager.java` L51-L64 |
| `ItemSizeManager.getDefinition(ItemStack)` → `@Nullable/默认` | 取原始定义 | 同上 L66-L82 |
| `IItemSize.getSize(ItemStack)` / `getWeight(ItemStack)` | 取值 | `ItemSizeDefinition.java` L38-L45 |

**回退逻辑**（`ItemSizeManager.getDefinition`，L66-L82）：先查数据表；查不到时按物品类型回退：

| 条件 | 回退值 |
| --- | --- |
| 物品是 `IItemSize`（TFC 自己实现的物品/方块） | 直接返回物品自身的实现，**不查数据表** |
| `TieredItem` 或 `BucketItem` | `Size.LARGE` + `Weight.MEDIUM` |
| `ArmorItem` 或 `AnimalArmorItem` | `Size.LARGE` + `Weight.VERY_HEAVY` |
| `BlockItem` | `Size.SMALL` + `Weight.LIGHT` |
| 其他 | `Size.VERY_SMALL` + `Weight.VERY_LIGHT` |

**对附属模组的含义**：如果自定义物品实现了 `IItemSize`，`tfc/item_size` 数据**不会生效**（会被短路）。若要允许数据包配置，就**不要**实现 `IItemSize`。

##### D-3.5 附属模组写法示例

```json
// 文件：data/mymod/tfc/item_size/titanium_ingots.json → ID mymod:titanium_ingots
{ "ingredient": { "tag": "c:ingots/titanium" }, "size": "large", "weight": "medium" }
```

---

### [D-4] `fuel` —— 燃料

##### D-4.1 基本信息

| 项目 | 值 |
| --- | --- |
| 数据类 | `net.dries007.tfc.util.data.Fuel`（record），实现 `IRecipePredicate<ItemStack>` |
| 管理器 | `Fuel.MANAGER` |
| 注册路径 | `tfc:fuel` → 目录 `data/*/tfc/fuel/**` |
| 同步 | 是 |
| 真实文件数 | 50 个（含 `groundcover`、`ore` 子目录） |

**来源**：`net/dries007/tfc/util/data/Fuel.java` L36-L46。

##### D-4.2 字段表

来源：`Fuel.java` L38：

```java
public static final Codec<Fuel> CODEC = RecordCodecBuilder.create(i -> i.group(
    Ingredient.CODEC.fieldOf("ingredient").forGetter(c -> c.ingredient),
    Codec.INT.fieldOf("duration").forGetter(c -> c.duration),
    Codec.FLOAT.fieldOf("temperature").forGetter(c -> c.temperature),
    Codec.FLOAT.optionalFieldOf("purity", 1.0f).forGetter(c -> c.purity)
).apply(i, Fuel::new));
```

| 字段名 | 类型 | 必需 | 默认值 | 语义 |
| --- | --- | --- | --- | --- |
| `ingredient` | `Ingredient` | **必需** | — | 匹配燃料物品 |
| `duration` | int | **必需** | — | 燃烧时长（tick） |
| `temperature` | float | **必需** | — | 燃烧温度（℃）。必须 ≥ 熔炼目标温度才能熔化物品 |
| `purity` | float | 可选 | `1.0` | 燃料纯度，影响加热效率（`AbstractFirepitBlockEntity.java` L328-L333 读取） |

##### D-4.3 真实 JSON 样例

样例 1 —— 无 `purity`（使用默认 1.0）：`data/tfc/tfc/fuel/charcoal.json`

```json
{"duration":1800,"ingredient":{"item":"minecraft:charcoal"},"temperature":1350.0}
```

样例 2 —— 含 `purity`（tag ingredient）：`data/tfc/tfc/fuel/acacia_logs.json`

```json
{"duration":1000,"ingredient":{"tag":"tfc:acacia_logs"},"purity":0.95,"temperature":650.0}
```

样例 3 —— 木板：`data/tfc/tfc/fuel/acacia_planks.json`

```json
{"duration":400,"ingredient":{"item":"tfc:wood/planks/acacia"},"purity":0.95,"temperature":700.0}
```

##### D-4.4 运行时如何被读取

| API | 语义 | 来源 |
| --- | --- | --- |
| `Fuel.get(ItemStack)` → `@Nullable Fuel` | 查燃料定义（内部用 `IndirectHashCollection<Item, Fuel> CACHE`） | `Fuel.java` L43-L46 |

**全部调用点（实测）**：

| 调用点 | 相对源码路径:行 |
| --- | --- |
| 客户端 tooltip 显示燃料温度 | `net/dries007/tfc/client/ClientForgeEventHandler.java:311` |
| 火坑（pit kiln / firepit）判断是否可作燃料 | `net/dries007/tfc/common/blockentities/AbstractFirepitBlockEntity.java:302` |
| 火坑消耗燃料 | `net/dries007/tfc/common/blockentities/AbstractFirepitBlockEntity.java:328` |
| 高炉消耗燃料 | `net/dries007/tfc/common/blockentities/BlastFurnaceBlockEntity.java:389` |
| 木炭锻造炉消耗燃料 | `net/dries007/tfc/common/blockentities/CharcoalForgeBlockEntity.java:289` |
| 火箱（firebox）消耗燃料 | `net/dries007/tfc/common/blockentities/FireboxBlockEntity.java:298`、`345` |
| `HeatCapability.consumeFuelForTicks` 通用消耗 | `net/dries007/tfc/common/component/heat/HeatCapability.java:184` |

注意 `AbstractFirepitBlockEntity.java:302` 还要求物品在 `TFCTags.Items.FIREPIT_FUEL` tag 内，因此**火坑燃料需要同时满足 `tfc:fuel` 数据与 tag**；而 `CharcoalForgeBlockEntity` 只查数据。

##### D-4.5 附属模组写法示例

```json
// 文件：data/mymod/tfc/fuel/titanium_dust.json → ID mymod:titanium_dust
{ "ingredient": { "item": "mymod:titanium_dust" }, "duration": 2400, "temperature": 1800.0, "purity": 1.0 }
```

---

### [D-5] `fluid_heat` —— 流体热学属性

##### D-5.1 基本信息

| 项目 | 值 |
| --- | --- |
| 数据类 | `net.dries007.tfc.util.data.FluidHeat`（record） |
| 管理器 | `FluidHeat.MANAGER` |
| 注册路径 | `tfc:fluid_heat` → 目录 `data/*/tfc/fluid_heat/**` |
| 同步 | 是 |
| 真实文件数 | 28 个 |

**来源**：`net/dries007/tfc/util/data/FluidHeat.java` L40-L44。

##### D-5.2 字段表

来源：`FluidHeat.java` L41：

```java
public static final Codec<FluidHeat> CODEC = RecordCodecBuilder.create(i -> i.group(
    Codecs.FLUID.fieldOf("fluid").forGetter(c -> c.fluid),
    Codec.FLOAT.fieldOf("melt_temperature").forGetter(c -> c.meltTemperature),
    Codec.FLOAT.fieldOf("specific_heat_capacity").forGetter(c -> c.specificHeatCapacity)
).apply(i, FluidHeat::new));
```

| 字段名 | 类型 | 必需 | 默认值 | 语义 |
| --- | --- | --- | --- | --- |
| `fluid` | `Fluid`（注册名） | **必需** | — | 流体 ID，如 `tfc:metal/copper` |
| `melt_temperature` | float | **必需** | — | 熔点（℃）。低于此温度该流体会凝固成物品 |
| `specific_heat_capacity` | float | **必需** | — | 单位体积热容（每 mB） |

##### D-5.3 真实 JSON 样例

`data/tfc/tfc/fluid_heat/copper.json`

```json
{"fluid":"tfc:metal/copper","melt_temperature":1080.0,"specific_heat_capacity":0.008571429}
```

##### D-5.4 运行时如何被读取

| API | 语义 | 来源 |
| --- | --- | --- |
| `FluidHeat.get(Fluid)` → `@Nullable` | 按流体查（内部 `IdentityHashMap<Fluid, FluidHeat> BY_FLUID`） | `FluidHeat.java` L51-L54 |
| `FluidHeat.getOrUnknown(FluidStack)` | 查不到时返回 `unknown()` 定义，绝不返回 null | 同上 L56-L58 |
| `FluidHeat.unknown()` | 返回 `tfc:unknown` 定义（`MANAGER.getOrThrow(UNKNOWN_ID)`） | 同上 L60-L62 |
| `FluidHeat.heatCapacity(float mB)` | `specific_heat_capacity * mB` | 同上 L72-L74 |

**重要**：`UNKNOWN_ID = Helpers.identifier("unknown")`（L43），因此 `data/tfc/tfc/fluid_heat/unknown.json` **必须是存在且定义有效的**，否则 `Manager.getOrThrow` 在 `updateCache()`（L64-L70）里抛异常。实测 jar 中该文件存在（同目录还有 `unknown` 之外的 27 个金属流体）。

调用点实测：`net/dries007/tfc/common/blockentities/CrucibleBlockEntity.java:256/312/337/370`、`net/dries007/tfc/common/component/mold/Mold.java:43/82`、`Mold.java` 的 `Vessel`、`net/dries007/tfc/client/screen/MoldLikeAlloyScreen.java:42`。

##### D-5.5 附属模组写法示例

```json
// 文件：data/mymod/tfc/fluid_heat/titanium.json → ID mymod:titanium
{ "fluid": "mymod:metal/titanium", "melt_temperature": 1668.0, "specific_heat_capacity": 0.0092 }
```

---

### [D-6] `deposit` —— 淘洗沉积物（矿砂）

##### D-6.1 基本信息

| 项目 | 值 |
| --- | --- |
| 数据类 | `net.dries007.tfc.util.data.Deposit`（record），实现 `IRecipePredicate<ItemStack>` |
| 管理器 | `Deposit.MANAGER` |
| 注册路径 | `tfc:deposit` → 目录 `data/*/tfc/deposit/**` |
| 同步 | 是 |
| 真实文件数 | 84 个，分 4 个子目录：`cassiterite`(21)、`native_copper`(21)、`native_gold`(21)、`native_silver`(21) |

**来源**：`net/dries007/tfc/util/data/Deposit.java` L45-L50。

##### D-6.2 字段表

来源：`Deposit.java` L47：

```java
public static final Codec<Deposit> CODEC = RecordCodecBuilder.create(i -> i.group(
    Ingredient.CODEC.fieldOf("ingredient").forGetter(c -> c.ingredient),
    ResourceKey.codec(Registries.LOOT_TABLE).fieldOf("loot_table").forGetter(c -> c.lootTable),
    ResourceLocation.CODEC.listOf().optionalFieldOf("model_stages", List.of()).forGetter(c -> c.modelStages)
).apply(i, Deposit::new));
```

| 字段名 | 类型 | 必需 | 默认值 | 语义 |
| --- | --- | --- | --- | --- |
| `ingredient` | `Ingredient` | **必需** | — | 匹配淘洗盘中的沉积物物品，如 `{"item":"tfc:deposit/native_copper/granite"}` |
| `loot_table` | `ResourceKey<LootTable>` | **必需** | — | 淘洗时使用的战利品表 ID |
| `model_stages` | `List<ResourceLocation>` | 可选 | 空列表 | 淘洗盘 3 个阶段的模型纹理序列。真实数据里都是 3 个（full → half → result） |

##### D-6.3 真实 JSON 样例

`data/tfc/tfc/deposit/native_copper/granite.json`

```json
{"ingredient":{"item":"tfc:deposit/native_copper/granite"},"loot_table":"tfc:deposit/native_copper_granite","model_stages":["tfc:item/pan/native_copper/granite_full","tfc:item/pan/native_copper/granite_half","tfc:item/pan/native_copper/result"]}
```

##### D-6.4 运行时如何被读取

| API | 语义 | 来源 |
| --- | --- | --- |
| `Deposit.get(@Nullable ItemStack)` → `@Nullable` | 按物品查沉积物定义 | `Deposit.java` L52-L55 |

调用点实测：

| 调用点 | 路径:行 |
| --- | --- |
| 客户端 tooltip | `net/dries007/tfc/client/ClientForgeEventHandler.java:338` |
| 淘洗盘渲染阶段 | `net/dries007/tfc/client/render/blockentity/PanItemRenderer.java:53` |
| 洗矿槽（sluice） | `net/dries007/tfc/common/blockentities/SluiceBlockEntity.java:94`、`152` |
| 空淘洗盘 | `net/dries007/tfc/common/items/EmptyPanItem.java:45` |
| 淘洗盘 | `net/dries007/tfc/common/items/PanItem.java:101` |

##### D-6.5 附属模组写法示例

```json
// 文件：data/mymod/tfc/deposit/titanium/granite.json → ID mymod:titanium/granite
{
  "ingredient": { "item": "mymod:deposit/titanium/granite" },
  "loot_table": "mymod:deposit/titanium_granite",
  "model_stages": ["mymod:item/pan/titanium/granite_full", "mymod:item/pan/titanium/granite_half", "mymod:item/pan/titanium/result"]
}
```

注意：`loot_table` 指向的战利品表必须自己提供（放在 `data/mymod/loot_table/deposit/...`，路径与 4.2.10 的 `loot_table` 复数列命名一致）。

---

### [D-7] `knapping_type` —— 打制类型

##### D-7.1 基本信息

| 项目 | 值 |
| --- | --- |
| 数据类 | `net.dries007.tfc.util.data.KnappingType`（record），实现 `IRecipePredicate<ItemStack>` |
| 管理器 | `KnappingType.MANAGER` |
| 注册路径 | `tfc:knapping_type` → 目录 `data/*/tfc/knapping_type/**` |
| 同步 | 是 |
| 真实文件数 | 5 个（实测：`clay`、`fire_clay`、`goat_horn`、`leather`、`rock`） |

**来源**：`net/dries007/tfc/util/data/KnappingType.java` L43-L47。

> 说明：任务书给出的清单里统计为 6 个，实测解压目录 `jar-extract/data/tfc/tfc/knapping_type/` 只有上述 5 个 `.json`。第 6 个可能是 `tfc:clay` 之外的扩展或统计口径差异（未能核实）；已检查 `Get-ChildItem -Force` 与 `TFC.resources.txt`。

##### D-7.2 字段表

来源：`KnappingType.java` L45：

```java
public static final Codec<KnappingType> CODEC = RecordCodecBuilder.create(i -> i.group(
    SizedIngredient.FLAT_CODEC.fieldOf("input").forGetter(c -> c.inputItem),
    Codec.INT.optionalFieldOf("amount_to_consume").forGetter(c -> c.amountToConsume == c.inputItem.count() ? Optional.empty() : Optional.of(c.amountToConsume)),
    SoundEvent.CODEC.fieldOf("click_sound").forGetter(c -> c.clickSound),
    Codec.BOOL.fieldOf("consume_after_complete").forGetter(c -> c.consumeAfterComplete),
    Codec.BOOL.fieldOf("has_off_texture").forGetter(c -> c.hasOffTexture),
    Codec.BOOL.fieldOf("spawns_particles").forGetter(c -> c.spawnsParticles),
    ItemStack.CODEC.fieldOf("icon").forGetter(c -> c.icon)
).apply(i, KnappingType::new));
```

| 字段名 | 类型 | 必需 | 默认值 | 语义 |
| --- | --- | --- | --- | --- |
| `input` | `SizedIngredient`（FLAT_CODEC） | **必需** | — | 打制输入。FLAT 形式即 `{"count":N,"item":...}` 或 `{"count":N,"tag":...}` |
| `amount_to_consume` | int（可选） | 可选 | 取 `input.count()` | 每次打制消耗的输入数量。**序列化时若等于 `input.count()` 会省略该字段**（见 L45 的 `forGetter`，L49-L51 的构造器把 `Optional.empty` 还原为 `input.count()`） |
| `click_sound` | `SoundEvent` | **必需** | — | 打制点击音效，如 `"tfc:item.knapping.stone"` |
| `consume_after_complete` | bool | **必需** | — | 完成后是否消耗输入物 |
| `has_off_texture` | bool | **必需** | — | 是否有“禁用”纹理（在界面里显示挖空状态） |
| `spawns_particles` | bool | **必需** | — | 敲击时是否产生粒子 |
| `icon` | `ItemStack` | **必需** | — | 打制界面/JEI 显示的图标，形如 `{"count":1,"id":"tfc:rock/loose/granite"}` |

> 注意 `icon` 用的是 `ItemStack.CODEC`，其 JSON 键是 `id` + `count`（**不是** `item`）。

##### D-7.3 真实 JSON 样例

`data/tfc/tfc/knapping_type/rock.json`

```json
{"amount_to_consume":1,"click_sound":"tfc:item.knapping.stone","consume_after_complete":false,"has_off_texture":false,"icon":{"count":1,"id":"tfc:rock/loose/granite"},"input":{"count":2,"tag":"tfc:rock_knapping"},"spawns_particles":true}
```

##### D-7.4 运行时如何被读取

| API | 语义 | 来源 |
| --- | --- | --- |
| `KnappingType.get(ItemStack)` → `@Nullable` | 按输入物品查打制类型（走 `MANAGER.getValues()` 全表遍历 + `matches`） | `KnappingType.java` L53-L56 |

调用点实测：`net/dries007/tfc/common/recipes/KnappingRecipe.java:71`、`net/dries007/tfc/util/InteractionManager.java:278`、`282`。

##### D-7.5 附属模组新增打制类型

打制类型是**数据驱动**的，附属模组只需新增一个 JSON，再写相应的 `tfc:knapping` 配方（其 `knapping_type` 字段引用该 ID）。示例：

```json
// 文件：data/mymod/tfc/knapping_type/bone.json → ID mymod:bone
{
  "input": { "count": 2, "tag": "mymod:bone_knapping" },
  "click_sound": "minecraft:entity.skeleton.step",
  "consume_after_complete": false,
  "has_off_texture": false,
  "spawns_particles": true,
  "icon": { "count": 1, "id": "minecraft:bone" }
}
```

---

### [D-8] `support` —— 方块支撑（防塌陷）

##### D-8.1 基本信息

| 项目 | 值 |
| --- | --- |
| 数据类 | `net.dries007.tfc.util.data.Support`（record） |
| 管理器 | `Support.MANAGER` |
| 注册路径 | `tfc:support` → 目录 `data/*/tfc/support/**` |
| 同步 | 是 |
| 真实文件数 | 1 个（`horizontal_support_beam.json`） |

**来源**：`net/dries007/tfc/util/data/Support.java` L41-L45。

##### D-8.2 字段表

来源：`Support.java` L42：

```java
public static final Codec<Support> CODEC = RecordCodecBuilder.create(i -> i.group(
    BlockIngredient.CODEC.fieldOf("ingredient").forGetter(c -> c.ingredient),
    Codec.INT.fieldOf("support_up").forGetter(c -> c.supportUp),
    Codec.INT.fieldOf("support_down").forGetter(c -> c.supportDown),
    Codec.INT.fieldOf("support_horizontal").forGetter(c -> c.supportHorizontal)
).apply(i, Support::new));
```

| 字段名 | 类型 | 必需 | 默认值 | 语义 |
| --- | --- | --- | --- | --- |
| `ingredient` | `BlockIngredient` | **必需** | — | 支持方块。支持：方块 ID 字符串 / `"#tag"` / 方块数组 |
| `support_up` | int | **必需** | — | 向上支持距离 |
| `support_down` | int | **必需** | — | 向下支持距离 |
| `support_horizontal` | int | **必需** | — | 水平支持半径 |

##### D-8.3 真实 JSON 样例

`data/tfc/tfc/support/horizontal_support_beam.json`

```json
{"ingredient":["tfc:wood/horizontal_support/acacia","tfc:wood/horizontal_support/ash","tfc:wood/horizontal_support/aspen","tfc:wood/horizontal_support/birch","tfc:wood/horizontal_support/blackwood","tfc:wood/horizontal_support/chestnut","tfc:wood/horizontal_support/douglas_fir","tfc:wood/horizontal_support/hickory","tfc:wood/horizontal_support/kapok","tfc:wood/horizontal_support/mangrove","tfc:wood/horizontal_support/maple","tfc:wood/horizontal_support/oak","tfc:wood/horizontal_support/palm","tfc:wood/horizontal_support/pine","tfc:wood/horizontal_support/rosewood","tfc:wood/horizontal_support/sequoia","tfc:wood/horizontal_support/spruce","tfc:wood/horizontal_support/sycamore","tfc:wood/horizontal_support/white_cedar","tfc:wood/horizontal_support/willow"],"support_down":2,"support_horizontal":4,"support_up":2}
```

##### D-8.4 运行时如何被读取

| API | 语义 | 来源 |
| --- | --- | --- |
| `Support.get(BlockState)` → `@Nullable` | 按方块状态查支撑定义（`IndirectHashCollection<Block, Support> CACHE`） | `Support.java` L91-L98 |
| `Support.isSupported(BlockGetter, BlockPos)` | 该位置是否被支撑 | 同上 L77-L85 |
| `Support.findUnsupportedPositions(BlockGetter, BlockPos, BlockPos)` | 返回某区域中所有不受支撑的位置（塌陷判定） | 同上 L52-L75 |
| `Support.updateMaximumSupportRange()` | 重算全局最大支持范围 `RANGE` | 同上 L100-L110 |
| `Support.getSupportCheckRange()` | 取全局最大范围 | 同上 L48-L50 |

**关键约束**：塌陷搜索范围由**所有 support 定义的最大值**决定（`updateMaximumSupportRange`），所以写一个超大 `support_horizontal` 会显著增大塌陷检测开销。

##### D-8.5 附属模组写法示例

```json
// 文件：data/mymod/tfc/support/steel_frame.json → ID mymod:steel_frame
{ "ingredient": { "tag": "mymod:steel_frames" }, "support_up": 3, "support_down": 3, "support_horizontal": 6 }
```

---

### [D-9] `fertilizer` —— 肥料

##### D-9.1 基本信息

| 项目 | 值 |
| --- | --- |
| 数据类 | `net.dries007.tfc.util.data.Fertilizer`（record） |
| 管理器 | `Fertilizer.MANAGER` |
| 注册路径 | `tfc:fertilizer` → 目录 `data/*/tfc/fertilizer/**` |
| 同步 | 是 |
| 真实文件数 | 10 个（含 `food`、`groundcover`、`powder` 子目录） |

**来源**：`net/dries007/tfc/util/data/Fertilizer.java` L37-L41。

##### D-9.2 字段表

来源：`Fertilizer.java` L38：

```java
public static final Codec<Fertilizer> CODEC = RecordCodecBuilder.create(i -> i.group(
    Ingredient.CODEC.fieldOf("ingredient").forGetter(c -> c.ingredient),
    Codec.FLOAT.optionalFieldOf("nitrogen", 0.0f).forGetter(c -> c.nitrogen),
    Codec.FLOAT.optionalFieldOf("phosphorus", 0.0f).forGetter(c -> c.phosphorus),
    Codec.FLOAT.optionalFieldOf("potassium", 0.0f).forGetter(c -> c.potassium)
).apply(i, Fertilizer::new));
```

| 字段名 | 类型 | 必需 | 默认值 | 语义 |
| --- | --- | --- | --- | --- |
| `ingredient` | `Ingredient` | **必需** | — | 匹配肥料物品 |
| `nitrogen` | float | 可选 | `0.0` | 氮含量 |
| `phosphorus` | float | 可选 | `0.0` | 磷含量 |
| `potassium` | float | 可选 | `0.0` | 钾含量 |

##### D-9.3 真实 JSON 样例（实测 10 个全部）

`data/tfc/tfc/fertilizer/powder/bone_meal.json`

```json
{"ingredient":{"item":"minecraft:bone_meal"},"phosphorus":0.1}
```

`data/tfc/tfc/fertilizer/compost.json`

```json
{"ingredient":{"item":"tfc:compost"},"nitrogen":0.2,"potassium":0.2}
```

`data/tfc/tfc/fertilizer/powder/pure_nitrogen.json`

```json
{"ingredient":{"item":"tfc:pure_nitrogen"},"nitrogen":0.1}
```

`data/tfc/tfc/fertilizer/powder/pure_phosphorus.json`

```json
{"ingredient":{"item":"tfc:pure_phosphorus"},"phosphorus":0.1}
```

`data/tfc/tfc/fertilizer/powder/pure_potassium.json`

```json
{"ingredient":{"item":"tfc:pure_potassium"},"potassium":0.1}
```

`data/tfc/tfc/fertilizer/food/shellfish.json`

```json
{"ingredient":{"item":"tfc:food/shellfish"},"phosphorus":0.15}
```

`data/tfc/tfc/fertilizer/groundcover/guano.json`

```json
{"ingredient":{"item":"tfc:groundcover/guano"},"nitrogen":0.4,"phosphorus":0.5,"potassium":0.1}
```

`data/tfc/tfc/fertilizer/powder/saltpeter.json`

```json
{"ingredient":{"item":"tfc:powder/saltpeter"},"nitrogen":0.1,"potassium":0.4}
```

`data/tfc/tfc/fertilizer/powder/sylvite.json`

```json
{"ingredient":{"item":"tfc:powder/sylvite"},"potassium":0.5}
```

`data/tfc/tfc/fertilizer/powder/wood_ash.json`

```json
{"ingredient":{"item":"tfc:powder/wood_ash"},"phosphorus":0.1,"potassium":0.2}
```

##### D-9.4 运行时如何被读取

| API | 语义 | 来源 |
| --- | --- | --- |
| `Fertilizer.get(ItemStack)` → `@Nullable` | 按物品查肥料（`CACHE` 按 Item 索引后逐个 `ingredient.test`） | `Fertilizer.java` L43-L50 |
| `Fertilizer.getNutrient(FarmlandBlockEntity.NutrientType)` | 按养分类型取值（`NITROGEN`/`PHOSPHOROUS`/`POTASSIUM`） | 同上 L52-L59 |

调用点实测：`net/dries007/tfc/ForgeEventHandler.java:1157`、`net/dries007/tfc/client/ClientForgeEventHandler.java:314`、`net/dries007/tfc/common/blocks/crop/CropHelpers.java:175`。

##### D-9.5 附属模组写法示例

```json
// 文件：data/mymod/tfc/fertilizer/powder/fish_meal.json → ID mymod:fish_meal
{ "ingredient": { "item": "mymod:powder/fish_meal" }, "nitrogen": 0.3, "phosphorus": 0.2 }
```

---

### [D-10] `lamp_fuel` —— 灯具燃料

##### D-10.1 基本信息

| 项目 | 值 |
| --- | --- |
| 数据类 | `net.dries007.tfc.util.data.LampFuel`（record） |
| 管理器 | `LampFuel.MANAGER` |
| 注册路径 | `tfc:lamp_fuel` → 目录 `data/*/tfc/lamp_fuel/**` |
| 同步 | 是 |
| 真实文件数 | 4 个（`canola_oil`、`lava`、`olive_oil`、`tallow`） |

**来源**：`net/dries007/tfc/util/data/LampFuel.java` L38-L42。

##### D-10.2 字段表

来源：`LampFuel.java` L39：

```java
public static final Codec<LampFuel> CODEC = RecordCodecBuilder.create(i -> i.group(
    FluidIngredient.CODEC.fieldOf("fluid").forGetter(c -> c.fluid),
    BlockIngredient.CODEC.fieldOf("lamps").forGetter(c -> c.lamps),
    Codec.INT.fieldOf("burn_rate").forGetter(c -> c.burnRate)
).apply(i, LampFuel::new));
```

| 字段名 | 类型 | 必需 | 默认值 | 语义 |
| --- | --- | --- | --- | --- |
| `fluid` | `FluidIngredient`（NeoForge） | **必需** | — | 允许的流体。写法 `{"fluid":"tfc:olive_oil"}` 或 `{"tag":"tfc:alcohols"}` 或数组 |
| `lamps` | `BlockIngredient` | **必需** | — | 允许的灯具方块。写法 `"#tfc:lamps"`（tag）或方块数组 |
| `burn_rate` | int | **必需** | — | 燃料消耗速率。**`-1` 表示无限燃烧**（实测 `lava.json` 为 `-1`） |

##### D-10.3 真实 JSON 样例（实测 4 个全部）

`data/tfc/tfc/lamp_fuel/olive_oil.json`

```json
{"burn_rate":7200,"fluid":{"fluid":"tfc:olive_oil"},"lamps":"#tfc:lamps"}
```

`data/tfc/tfc/lamp_fuel/canola_oil.json`

```json
{"burn_rate":6000,"fluid":{"fluid":"tfc:canola_oil"},"lamps":"#tfc:lamps"}
```

`data/tfc/tfc/lamp_fuel/tallow.json`

```json
{"burn_rate":2400,"fluid":{"fluid":"tfc:tallow"},"lamps":"#tfc:lamps"}
```

`data/tfc/tfc/lamp_fuel/lava.json`（`lamps` 用方块数组 + `burn_rate: -1`）

```json
{"burn_rate":-1,"fluid":{"fluid":"minecraft:lava"},"lamps":["tfc:metal/lamp/blue_steel","tfc:metal/lamp/red_steel"]}
```

##### D-10.4 运行时如何被读取

| API | 语义 | 来源 |
| --- | --- | --- |
| `LampFuel.get(Fluid, BlockState)` → `@Nullable` | 按流体 + 灯具方块状态查 | `LampFuel.java` L44-L51 |

调用点实测：`net/dries007/tfc/common/blockentities/LampBlockEntity.java:54`（构造流体罐校验器）、`:66`（tick 中查燃料）、`net/dries007/tfc/common/items/LampBlockItem.java:56`（放置时校验）。

##### D-10.5 附属模组写法示例

```json
// 文件：data/mymod/tfc/lamp_fuel/kerosene.json → ID mymod:kerosene
{ "fluid": { "fluid": "mymod:kerosene" }, "lamps": "#tfc:lamps", "burn_rate": 10000 }
```

---

### [D-11] `drinkable` —— 可饮用流体

##### D-11.1 基本信息

| 项目 | 值 |
| --- | --- |
| 数据类 | `net.dries007.tfc.util.data.Drinkable`（record） |
| 管理器 | `Drinkable.MANAGER` |
| 注册路径 | `tfc:drinkable` → 目录 `data/*/tfc/drinkable/**` |
| 同步 | 是 |
| 真实文件数 | 5 个（`alcohol`、`milk`、`salt_water`、`vinegar`、`water`） |

**来源**：`net/dries007/tfc/util/data/Drinkable.java` L77-L81。

##### D-11.2 字段表

来源：`Drinkable.java` L78：

```java
public static final Codec<Drinkable> CODEC = RecordCodecBuilder.create(i -> i.group(
    FluidIngredient.CODEC.fieldOf("ingredient").forGetter(c -> c.ingredient),
    Codec.FLOAT.optionalFieldOf("consume_chance", 0.0f).forGetter(c -> c.consumeChance),
    Codec.BOOL.optionalFieldOf("may_drink_when_full", false).forGetter(c -> c.mayDrinkWhenFull),
    FoodData.MAP_CODEC.forGetter(c -> c.food),
    RecordCodecBuilder.create(j -> j.group(
        MobEffect.CODEC.fieldOf("effect").forGetter(c -> c.type),
        Codec.INT.fieldOf("duration").forGetter(c -> c.duration),
        Codec.INT.fieldOf("amplifier").forGetter(c -> c.amplifier),
        Codec.FLOAT.fieldOf("chance").forGetter(c -> c.chance)
    ).apply(j, Effect::new)).listOf().optionalFieldOf("effects", List.of()).forGetter(c -> c.effects)
).apply(i, Drinkable::new));
```

| 字段名 | 类型 | 必需 | 默认值 | 语义 |
| --- | --- | --- | --- | --- |
| `ingredient` | `FluidIngredient` | **必需** | — | 匹配流体。写法 `{"fluid":"..."}` / `{"tag":"..."}` / 数组 |
| `consume_chance` | float | 可选 | `0.0` | 每喝一口后源头被消耗（变空）的概率 |
| `may_drink_when_full` | bool | 可选 | `false` | 口渴已满时是否仍可饮用 |
| `hunger` | int | 可选 | `0` | 来自内联 `FoodData`：恢复饥饿 |
| `water` | float | 可选 | `0.0` | 来自内联 `FoodData`：恢复口渴（负数则扣水） |
| `saturation` | float | 可选 | `0.0` | 来自内联 `FoodData` |
| `intoxication` | int | 可选 | `0` | 来自内联 `FoodData`：醉酒值 |
| `grain`/`fruit`/`vegetables`/`protein`/`dairy` | float | 可选 | `0.0` | 来自内联 `FoodData` 的五种营养 |
| `decay_modifier` | float/`"infinity"` | 可选 | `0.0` | 来自内联 `FoodData` |
| `effects` | 对象数组 | 可选 | `[]` | 药水效果列表 |

`effects` 数组元素字段（`Drinkable.Effect`，L143）：

| 字段名 | 类型 | 必需 | 默认值 | 语义 |
| --- | --- | --- | --- | --- |
| `effect` | `Holder<MobEffect>` | **必需** | — | 效果 ID，如 `"tfc:thirst"` |
| `duration` | int | **必需** | — | 持续时间（tick） |
| `amplifier` | int | **必需** | — | 等级（0 起） |
| `chance` | float | **必需** | — | 触发概率（0~1） |

> 效果触发概率按 `1 - (1 - chance)^multiplier` 计算，其中 `multiplier = mB / 25`（L130-L141）。

##### D-11.3 真实 JSON 样例（实测 5 个全部）

`data/tfc/tfc/drinkable/water.json`（数组 fluid ingredient，只有 water）

```json
{"ingredient":[{"fluid":"minecraft:water"},{"fluid":"tfc:river_water"}],"water":10.0}
```

`data/tfc/tfc/drinkable/alcohol.json`（tag ingredient + 醉酒）

```json
{"ingredient":{"tag":"tfc:alcohols"},"intoxication":4000,"may_drink_when_full":true,"water":5.0}
```

`data/tfc/tfc/drinkable/milk.json`

```json
{"dairy":1.0,"ingredient":{"fluid":"minecraft:milk"},"water":10.0}
```

`data/tfc/tfc/drinkable/salt_water.json`（负 water + 效果）

```json
{"effects":[{"amplifier":1,"chance":0.25,"duration":600,"effect":"tfc:thirst"}],"ingredient":{"fluid":"tfc:salt_water"},"may_drink_when_full":true,"water":-1.0}
```

`data/tfc/tfc/drinkable/vinegar.json`

```json
{"effects":[{"amplifier":1,"chance":0.8,"duration":80,"effect":"tfc:thirst"}],"ingredient":{"fluid":"tfc:vinegar"},"water":5.0}
```

##### D-11.4 运行时如何被读取

| API | 语义 | 来源 |
| --- | --- | --- |
| `Drinkable.get(Fluid)` → `@Nullable` | 按流体查饮用定义 | `Drinkable.java` L85-L92 |
| `Drinkable.attemptDrink(Level, Player, boolean)` | 玩家对着流体源右键时的整体流程 | 同上 L94-L114 |
| `drinkable.onDrink(Player, int mB)` | 应用食物数据与效果 | 同上 L130-L141 |

固定常量：`HAND_DRINK_MB = 25`、`JUG_DRINK_MB = 100`（L82-L83）。

调用点实测：`net/dries007/tfc/common/items/GlassBottleItem.java:73/107`、`net/dries007/tfc/common/items/JugItem.java:64/98`、`net/dries007/tfc/util/SelfTests.java:299`。

##### D-11.5 附属模组写法示例

```json
// 文件：data/mymod/tfc/drinkable/titanium_tonic.json → ID mymod:titanium_tonic
{
  "ingredient": { "fluid": "mymod:titanium_tonic" },
  "water": 15.0,
  "may_drink_when_full": true,
  "consume_chance": 0.25,
  "effects": [ { "effect": "minecraft:resistance", "duration": 1200, "amplifier": 0, "chance": 1.0 } ]
}
```

---

### [D-12] `item_damage_resistance` —— 物品物理抗性

##### D-12.1 基本信息

| 项目 | 值 |
| --- | --- |
| 数据类 | `net.dries007.tfc.util.data.ItemDamageResistance`（record），实现 `IRecipePredicate<ItemStack>` |
| 管理器 | `ItemDamageResistance.MANAGER` |
| 注册路径 | `tfc:item_damage_resistance` → 目录 `data/*/tfc/item_damage_resistance/**` |
| 同步 | 是 |
| 真实文件数 | 11 个（各金属护甲 1 个） |

**来源**：`net/dries007/tfc/util/data/ItemDamageResistance.java` L35-L40。

##### D-12.2 字段表

来源：`ItemDamageResistance.java` L37：

```java
public static final Codec<ItemDamageResistance> CODEC = RecordCodecBuilder.create(i -> i.group(
    Ingredient.CODEC.fieldOf("ingredient").forGetter(c -> c.ingredient),
    PhysicalDamage.CODEC.forGetter(c -> c.damages)
).apply(i, ItemDamageResistance::new));
```

`PhysicalDamage` 是 `RecordCodecBuilder.mapCodec`（`net/dries007/tfc/util/PhysicalDamage.java` L28），字段**直接内联到顶层**：

| 字段名 | 类型 | 必需 | 默认值 | 语义 |
| --- | --- | --- | --- | --- |
| `ingredient` | `Ingredient` | **必需** | — | 匹配物品（通常是整组护甲） |
| `piercing` | float | 可选 | `0.0` | 穿刺伤害倍率修正 |
| `slashing` | float | 可选 | `0.0` | 劈砍伤害倍率修正 |
| `crushing` | float | 可选 | `0.0` | 砸击伤害倍率修正 |

> 语义为「倍率（multiplier）」，正数表示承受更多该类伤害；TFC 护甲数据用正数表示护甲对物理伤害的放大（因为护甲削弱的是 TFC 的其他机制，详见 `PhysicalDamageType`）。

##### D-12.3 真实 JSON 样例

`data/tfc/tfc/item_damage_resistance/copper_armor.json`

```json
{"crushing":10.0,"ingredient":[{"item":"tfc:metal/helmet/copper"},{"item":"tfc:metal/chestplate/copper"},{"item":"tfc:metal/greaves/copper"},{"item":"tfc:metal/boots/copper"}],"piercing":10.0,"slashing":6.25}
```

##### D-12.4 运行时如何被读取

| API | 语义 | 来源 |
| --- | --- | --- |
| `ItemDamageResistance.get(ItemStack)` → `@Nullable` | 按物品查抗性 | `ItemDamageResistance.java` L42-L45 |

调用点实测：`net/dries007/tfc/util/PhysicalDamageType.java:132`（唯一的消费点）。

##### D-12.5 附属模组写法示例

```json
// 文件：data/mymod/tfc/item_damage_resistance/titanium_armor.json → ID mymod:titanium_armor
{
  "ingredient": [
    { "item": "mymod:titanium_helmet" },
    { "item": "mymod:titanium_chestplate" },
    { "item": "mymod:titanium_greaves" },
    { "item": "mymod:titanium_boots" }
  ],
  "piercing": 8.0,
  "slashing": 5.0,
  "crushing": 8.0
}
```

---

### [D-13] `entity_damage_resistance` —— 实体物理抗性

##### D-13.1 基本信息

| 项目 | 值 |
| --- | --- |
| 数据类 | `net.dries007.tfc.util.data.EntityDamageResistance`（record） |
| 管理器 | `EntityDamageResistance.MANAGER` |
| 注册路径 | `tfc:entity_damage_resistance` → 目录 `data/*/tfc/entity_damage_resistance/**` |
| 同步 | **否**（构造时只传了 `CODEC`） |
| 真实文件数 | 2 个（`skeletons`、`zombies`） |

**来源**：`net/dries007/tfc/util/data/EntityDamageResistance.java` L32-L34。

##### D-13.2 字段表

来源：`EntityDamageResistance.java` L33：

```java
public static final Codec<EntityDamageResistance> CODEC = RecordCodecBuilder.create(i -> i.group(
    TagKey.codec(Registries.ENTITY_TYPE).fieldOf("entity").forGetter(c -> c.entity),
    PhysicalDamage.CODEC.forGetter(c -> c.damages)
).apply(i, EntityDamageResistance::new));
```

| 字段名 | 类型 | 必需 | 默认值 | 语义 |
| --- | --- | --- | --- | --- |
| `entity` | `TagKey<EntityType<?>>` | **必需** | — | **必须是实体类型 tag ID**（`TagKey.codec`）。写裸字符串，如 `"minecraft:zombies"` |
| `piercing` | float | 可选 | `0.0` | 穿刺倍率（内联 `PhysicalDamage`） |
| `slashing` | float | 可选 | `0.0` | 劈砍倍率 |
| `crushing` | float | 可选 | `0.0` | 砸击倍率 |

> **务必注意**：`entity` 字段是 **tag**，不是实体类型 ID。TFC 的 `tfc:tags/entity_type/` 下没有 `zombies`/`skeletons`（实测该目录 35 个文件里无此二者），但 TFC jar 的 `data/minecraft/tags/entity_type/` 下也没有。实测 `data/tfc/tfc/entity_damage_resistance/zombies.json` 写的 `"entity":"minecraft:zombies"`，因此该 tag 由 TFC 之外的来源提供或为非空引用失败（此点**未能核实**，已检查 `jar-extract/data/tfc/tags/entity_type/`、`jar-extract/data/minecraft/tags/entity_type/`、`EntityDamageResistance.java`、`PhysicalDamageType.java`）。附属模组自行定义时，应**自己提供对应的 entity_type tag**，例如：

```json
// data/mymod/tags/entity_type/titans.json
{ "values": ["mymod:titan"] }
```

##### D-13.3 真实 JSON 样例

`data/tfc/tfc/entity_damage_resistance/zombies.json`

```json
{"crushing":50.0,"entity":"minecraft:zombies","piercing":-25.0}
```

（注意 `slashing` 缺省 → 0.0）

##### D-13.4 运行时如何被读取

| API | 语义 | 来源 |
| --- | --- | --- |
| `EntityDamageResistance.get(Entity)` → `@Nullable` | 全表遍历 + `Helpers.isEntity(entity, resist.entity)` tag 判定 | `EntityDamageResistance.java` L36-L43 |

调用点实测：`net/dries007/tfc/util/PhysicalDamageType.java:67`。

##### D-13.5 附属模组写法示例

```json
// 文件：data/mymod/tfc/entity_damage_resistance/titans.json → ID mymod:titans
{ "entity": "mymod:titans", "piercing": -50.0, "crushing": 25.0 }
// 同时需 data/mymod/tags/entity_type/titans.json: { "values": ["mymod:titan"] }
```

---

### [D-14] `climate_range` —— 作物/植物气候需求

##### D-14.1 基本信息

| 项目 | 值 |
| --- | --- |
| 数据类 | `net.dries007.tfc.util.climate.ClimateRange`（record） |
| 管理器 | `ClimateRange.MANAGER` |
| 注册路径 | `tfc:climate_range` → 目录 `data/*/tfc/climate_range/**` |
| 同步 | 是 |
| 真实文件数 | 49 个，分 `crop`（29）与 `plant`（20）两个子目录 |

**来源**：`net/dries007/tfc/util/climate/ClimateRange.java` L27-L31。

##### D-14.2 字段表

来源：`ClimateRange.java` L28：

```java
public static final Codec<ClimateRange> CODEC = RecordCodecBuilder.create(i -> i.group(
    Codec.INT.optionalFieldOf("min_hydration", 0).forGetter(c -> c.minHydration),
    Codec.INT.optionalFieldOf("max_hydration", 100).forGetter(c -> c.maxHydration),
    Codec.INT.optionalFieldOf("hydration_wiggle_range", 0).forGetter(c -> c.hydrationWiggleRange),
    Codec.FLOAT.optionalFieldOf("min_temperature", Float.NEGATIVE_INFINITY).forGetter(c -> c.minTemperature),
    Codec.FLOAT.optionalFieldOf("max_temperature", Float.POSITIVE_INFINITY).forGetter(c -> c.maxTemperature),
    Codec.FLOAT.optionalFieldOf("temperature_wiggle_range", 0.0f).forGetter(c -> c.temperatureWiggleRange)
).apply(i, ClimateRange::new));
```

| 字段名 | 类型 | 必需 | 默认值 | 语义 |
| --- | --- | --- | --- | --- |
| `min_hydration` | int | 可选 | `0` | 最低湿度 |
| `max_hydration` | int | 可选 | `100` | 最高湿度 |
| `hydration_wiggle_range` | int | 可选 | `0` | 湿度容差（`allowWiggle` 时向外扩展） |
| `min_temperature` | float | 可选 | `-∞` | 最低温度 |
| `max_temperature` | float | 可选 | `+∞` | 最高温度 |
| `temperature_wiggle_range` | float | 可选 | `0.0` | 温度容差 |

**全部字段都是可选**，因此空对象 `{}` 也是合法定义（等价于 `NOOP` 之外的全范围）。`NOOP` 常量 = `new ClimateRange(0, 100, 0, -100f, 100f, 0f)`（L31）。

判定逻辑：`checkHydration` / `checkTemperature` 返回 `Result.LOW | VALID | HIGH`（L49-L76），`checkBoth` 要求两项均 `VALID`。

##### D-14.3 真实 JSON 样例

`data/tfc/tfc/climate_range/crop/barley.json`

```json
{"max_hydration":70,"max_temperature":23.0,"min_hydration":10,"min_temperature":-7.0}
```

实测 `plant` 子目录 20 个文件：`banana_tree`、`blackberry_bush`、`blueberry_bush`、`bunchberry_bush`、`cherry_tree`、`cloudberry_bush`、`cranberry_bush`、`elderberry_bush`、`gooseberry_bush`、`green_apple_tree`、`lemon_tree`、`olive_tree`、`orange_tree`、`peach_tree`、`plum_tree`、`raspberry_bush`、`red_apple_tree`、`snowberry_bush`、`strawberry_bush`、`wintergreen_berry_bush`。

##### D-14.4 运行时如何被读取

| API | 语义 | 来源 |
| --- | --- | --- |
| `ClimateRange.MANAGER.get(id)` / `getOrThrow(id)` | 取定义 | `ClimateRange.java` L30；`DataManager.java` L82-L94 |
| `range.checkBoth(hydration, temperature, allowWiggle)` | 综合判定 | `ClimateRange.java` L59-L61 |
| `range.getMinHydration(allowWiggle)` 等 | 取值 | 同上 L33-L47 |

调用点实测（部分）：`net/dries007/tfc/common/blocks/crop/CropBlock.java:169/208`、`DeadCropBlock.java:69`、`net/dries007/tfc/common/blocks/plant/fruit/BananaPlantBlock.java:114/188`、`FruitBlocks.java:100/132`、`FruitTreeBranchBlock.java:53`。

##### D-14.5 附属模组写法示例

```json
// 文件：data/mymod/tfc/climate_range/crop/titanium_herb.json → ID mymod:crop/titanium_herb
{ "min_hydration": 30, "max_hydration": 90, "hydration_wiggle_range": 5, "min_temperature": 5.0, "max_temperature": 35.0, "temperature_wiggle_range": 2.0 }
```

---

### [D-15] `fauna` —— 动物生成条件

##### D-15.1 基本信息

| 项目 | 值 |
| --- | --- |
| 数据类 | `net.dries007.tfc.common.entities.Fauna`（record） |
| 管理器 | `Fauna.MANAGER` |
| 注册路径 | `tfc:fauna` → 目录 `data/*/tfc/fauna/**` |
| 同步 | **否**（构造时只传了 `CODEC`） |
| 真实文件数 | 77 个（无子目录） |

**来源**：`net/dries007/tfc/common/entities/Fauna.java` L25-L27。

**关键机制**：`Fauna` 的 **ID 必须与实体类型的 `ResourceLocation` 一致**。`Faunas.register`（`net/dries007/tfc/common/entities/Faunas.java`）用 `Fauna.MANAGER.getReference(entity.getId())` 绑定，例如实体 `tfc:cod` → 数据文件 ID `tfc:cod`。

##### D-15.2 字段表

来源：`Fauna.java` L26：

```java
public static final Codec<Fauna> CODEC = RecordCodecBuilder.create(i -> i.group(
    Codec.INT.optionalFieldOf("chance", 1).forGetter(c -> c.chance),
    Codec.INT.optionalFieldOf("distance_below_sea_level", -1).forGetter(c -> c.distanceBelowSeaLevel),
    ClimatePlacement.CODEC.forGetter(c -> c.climate),
    Codec.BOOL.optionalFieldOf("solid_ground", false).forGetter(c -> c.solidGround),
    Codec.INT.optionalFieldOf("max_brightness", -1).forGetter(c -> c.maxBrightness),
    Month.CODEC.listOf().optionalFieldOf("months", Collections.emptyList()).forGetter(c -> c.months)
).apply(i, Fauna::new));
```

Fauna 自身字段：

| 字段名 | 类型 | 必需 | 默认值 | 语义 |
| --- | --- | --- | --- | --- |
| `chance` | int | 可选 | `1` | 生成概率分母，`rand.nextInt(chance) != 0` 即拒绝 |
| `distance_below_sea_level` | int | 可选 | `-1` | 距海平面下方格数；`-1` 表示不限制 |
| `solid_ground` | bool | 可选 | `false` | 是否要求下方是 `minecraft:valid_spawn` |
| `max_brightness` | int | 可选 | `-1` | 最大光照；`-1` 表示不限制 |
| `months` | `Month` 数组 | 可选 | `[]` | 允许生成的月份（空 = 全年）。取值为小写英文月份名 |

`ClimatePlacement` 的字段**内联**（`net/dries007/tfc/world/placement/ClimatePlacement.java`，字段名来自 `Fauna.Builder` 的赋值顺序与其 `CODEC`）：

`ClimatePlacement` 的字段**内联到 `fauna` JSON 顶层**（`net/dries007/tfc/world/placement/ClimatePlacement.java` L46 的 `CODEC`，**已逐行核实**）：

| 字段名 | 类型 | 必需 | 默认值 | 语义 |
| --- | --- | --- | --- | --- |
| `min_temperature` | float | 可选 | `-∞` | 最低温度 |
| `max_temperature` | float | 可选 | `+∞` | 最高温度 |
| `min_groundwater` | float | 可选 | `-∞` | 最低地下水/降雨量 |
| `max_groundwater` | float | 可选 | `+∞` | 最高地下水/降雨量 |
| `min_rain_variance` | float | 可选 | `-1.0` | 最低降雨方差 |
| `max_rain_variance` | float | 可选 | `1.0` | 最高降雨方差 |
| `rain_variance_absolute` | bool | 可选 | `false` | 方差是否取绝对值 |
| `min_forest` | int（非负） | 可选 | `0` | 最低森林密度（`Codecs.NON_NEGATIVE_INT`） |
| `max_forest` | int（非负） | 可选 | `4` | 最高森林密度 |
| `forest_types` | `ForestType` 数组 | 可选 | `[]` | 限定森林类型（空 = 不限） |
| `min_elevation` | int | 可选 | `-64` | 最低高度 |
| `max_elevation` | int | 可选 | `320` | 最高高度 |
| `fuzzy` | bool | 可选 | `false` | 模糊匹配（按到区间中心的归一化距离做概率采样） |
| `ignore_rivers` | bool | 可选 | `false` | 忽略河流，改用平均降雨而非平均地下水 |

判定逻辑见 `ClimatePlacement.isValid(...)`（L145-L161）与 `getPositions(...)`（L163-L170）：所有条件同时满足才通过；`fuzzy` 时再按 `rand.nextFloat() * rand.nextFloat() > max(三个归一化距离)` 过滤。

##### D-15.3 真实 JSON 样例

`data/tfc/tfc/fauna/cod.json`（最简：只用两个可选字段 + 气候）

```json
{"distance_below_sea_level":5,"max_temperature":18.0}
```

`data/tfc/tfc/fauna/northern_pike.json`（含月份 + 地下水范围 + `ignore_rivers`）

```json
{"ignore_rivers":true,"max_groundwater":400.0,"max_temperature":-5.0,"min_groundwater":150.0,"min_temperature":-14.0,"months":["may","june","july","august","september","october"]}
```

`data/tfc/tfc/fauna/muksun.json`

```json
{"ignore_rivers":true,"max_groundwater":500.0,"max_temperature":-10.0,"min_groundwater":250.0,"min_temperature":-20.0,"months":["may","june","july","august","september","october"]}
```

##### D-15.4 运行时如何被读取

| API | 语义 | 来源 |
| --- | --- | --- |
| `Faunas.register(entity, spawnPlacement, heightmapType)` → `Id<E>` | 把实体与 `DataManager.Reference<Fauna>` 绑定 | `Faunas.java` `register` 私有方法 |
| `Faunas.registerSpawnPlacements(RegisterSpawnPlacementsEvent)` | 注册生成位置谓词，谓词内调用 `type.fauna().get()` 并逐条检查 | `Faunas.java` `registerSpawnPlacement` 方法 |
| `DataManager.Reference<T>.get()` | 取值，未加载时抛 `IllegalStateException("Referencing value before loaded")` | `DataManager.java` L210-L213 |

生成谓词检查顺序（`Faunas.java` 内）：

1. `rand.nextInt(fauna.chance()) != 0` → 拒绝
2. 水生生物：`AquaticMob.canSpawnIn(流体)`
3. `distanceBelowSeaLevel != -1 && pos.getY() > seaLevel - distanceBelowSeaLevel` → 拒绝
4. `fauna.climate().isValid(data, pos, rand, isNorthernHemisphere)` → 拒绝
5. `solidGround` 且下方非 `BlockTags.VALID_SPAWN` → 拒绝
6. `months` 非空且不含当前月份 → 拒绝
7. `maxBrightness != -1 && 光照 > maxBrightness` → 拒绝

##### D-15.5 附属模组新增一个可生成动物

需要 4 步：注册实体（Java）→ 写 `data/<modid>/tfc/fauna/<entity_path>.json`（**ID 必须等于实体 ID**）→ 调用 `Faunas.registerAnimal`/`registerFish` 等同等方法（Java）→ 在 `RegisterSpawnPlacementsEvent` 中注册。示例数据文件：

```json
// 实体 mymod:titan 对应的文件：data/mymod/tfc/fauna/titan.json → ID mymod:titan
{ "chance": 20, "min_temperature": -20.0, "max_temperature": 10.0, "solid_ground": true, "max_brightness": 7 }
```

---

### [D-16] `worldgen`（`rock_settings`）—— 岩石方块映射（数据包注册表）

##### D-16.1 基本信息

| 项目 | 值 |
| --- | --- |
| 数据类 | `net.dries007.tfc.world.settings.RockSettings` |
| 加载机制 | **数据包注册表**（不是 `DataManager`） |
| 注册调用 | `net/dries007/tfc/TerraFirmaCraft.java` L238：`event.dataPackRegistry(RockSettings.KEY, RockSettings.CODEC)` |
| 注册路径 | `tfc:worldgen/rock_settings` → 目录 `data/*/tfc/worldgen/rock_settings/**` |
| 真实文件数 | 21 个（每个岩石类型 1 个） |

**来源**：`net/dries007/tfc/TerraFirmaCraft.java:238`、`net/dries007/tfc/world/settings/RockSettings.java`。

##### D-16.2 字段表（依真实 JSON 实测）

实测 `data/tfc/tfc/worldgen/rock_settings/granite.json` 的键集合为：`cobble`、`gravel`、`hardened`、`karst`、`loose`、`mafic`、`mossy_loose`、`raw`、`sand`、`sandstone`、`spike`。

| 字段名 | 类型 | 必需 | 默认值 | 语义 |
| --- | --- | --- | --- | --- |
| `raw` | block ID | **必需** | — | 原石方块 |
| `hardened` | block ID | **必需** | — | 硬化岩（火山口附近） |
| `gravel` | block ID | **必需** | — | 砾石方块 |
| `cobble` | block ID | **必需** | — | 圆石方块 |
| `sand` | block ID | **必需** | — | 沙方块 |
| `sandstone` | block ID | **必需** | — | 砂岩方块 |
| `spike` | block ID | 可选 | `Optional.empty()` | 岩锥方块 |
| `loose` | block ID | 可选 | `Optional.empty()` | 松散岩（打制用） |
| `mossy_loose` | block ID | 可选 | `Optional.empty()` | 苔藓松散岩 |
| `karst` | bool | 可选 | `Optional.empty()` | 是否参与喀斯特地形 |
| `mafic` | bool | 可选 | `Optional.empty()` | 是否为镁铁质 |

**字段要求的判定依据**：`RockSettings.CODEC`（`net/dries007/tfc/world/settings/RockSettings.java` L32）中，前 6 个用 `Codecs.BLOCK.fieldOf(...)`（**必填**），后 5 个用 `optionalFieldOf(...)`（**可选，缺省为 `Optional.empty()`**，注意不是 `false`/默认方块，而是「未指定」语义）。record 组件的 `Optional` 类型（L30）与此一致。

另有 `RockSettings.isRawOrHardened(BlockState)`（L34-L36）用于判断方块是否属于该岩石的原石/硬化岩。

##### D-16.3 真实 JSON 样例

`data/tfc/tfc/worldgen/rock_settings/granite.json`

```json
{"cobble":"tfc:rock/cobble/granite","gravel":"tfc:rock/gravel/granite","hardened":"tfc:rock/hardened/granite","karst":false,"loose":"tfc:rock/loose/granite","mafic":false,"mossy_loose":"tfc:rock/mossy_loose/granite","raw":"tfc:rock/raw/granite","sand":"tfc:sand/yellow","sandstone":"tfc:raw_sandstone/yellow","spike":"tfc:rock/spike/granite"}
```

实测 21 个文件：`andesite`、`basalt`、`chalk`、`chert`、`claystone`、`conglomerate`、`dacite`、`diorite`、`dolomite`、`gabbro`、`gneiss`、`granite`、`limestone`、`marble`、`phyllite`、`quartzite`、`rhyolite`、`schist`、`shale`、`slate`、`tuff`。

##### D-16.4 运行时如何被读取

| API/字段 | 语义 | 来源 |
| --- | --- | --- |
| `ChunkGeneratorExtension.rockLayerSettings()` | 取岩层设置 | `net/dries007/tfc/world/ChunkGeneratorExtension.java:41-42` |
| `TFCChunkGenerator` 的地表构建 | 用 `rockLayerSettings()` 生成地表 | `net/dries007/tfc/world/TFCChunkGenerator.java:550` |
| `ChunkDataGenerator.generateRock(...)` / `generateSurfaceRock(x,z)` | 逐格生成岩石 | `net/dries007/tfc/world/chunkdata/ChunkDataGenerator.java:34-38` |
| `RegionChunkDataGenerator` | 持有 `RockLayerSettings` 并驱动生成 | `net/dries007/tfc/world/chunkdata/RegionChunkDataGenerator.java:51/66-68` |

##### D-16.5 附属模组新增岩石

因为它是**数据包注册表**，写法与 `DataManager` 数据不同：

1. 在 `data/<modid>/tfc/worldgen/rock_settings/<name>.json` 放定义（ID 为 `<modid>:<name>`）。
2. 数据包注册表**不参与 tag 合并**，同名 ID 由数据包优先级决定完整覆盖（整条替换，不做字段合并）。
3. 使用该岩石需要在 worldgen（`rock_layer` / 区域定义）中引用；TFC 的岩层分布逻辑位于 `net/dries007/tfc/world/region/` 与 `net/dries007/tfc/world/rocklayer/`，通过 `RegionGenerator`/`RockLayerSettings` 驱动（来源：`net/dries007/tfc/world/chunkdata/RegionChunkDataGenerator.java` L51/L66-L68 持有并构造 `RockLayerSettings`）。岩层分布数据本身是否可通过 JSON 增加，**未能核实**（已检查 `net/dries007/tfc/world/` 下文件列表、`data/tfc/worldgen/` 子目录清单、`data/tfc/tfc/worldgen/` 内容）。

---

### [D-17] 新增/覆盖数据的通用做法（速查）

1. **目录**：永远写 `data/<你的modid>/tfc/<kind>/...`。第一个 `tfc` 段是常量，与命名空间无关。
2. **ID**：`<你的modid>:<去掉 kind 后的相对路径>`。子目录会进入 ID（`mymod:metal/ingot`）。
3. **不要试图覆盖 `tfc:` 命名空间下的 ID**：`DataManager` 用 `ImmutableMap.Builder`，重复 key 抛异常（`DataManager.java` L155-L160），两个数据包写同一 ID 会冲突/报错。
4. **优先"新增 + tag"**：例如通过 `item_heat` 的 tag ingredient 一次性覆盖你所有 `c:ingots/mymetal`，而不是逐个物品写定义。
5. **同步性**：只有带 `STREAM_CODEC` 的数据会同步到客户端。`entity_damage_resistance` 与 `fauna` 不同步，其效果只在服务端生效；若你需要客户端 tooltip，请用同步数据。
6. **数据包注册表**（目前只有 `tfc:worldgen/rock_settings`）不能通过 tag 合并，必须整条提供。
7. **校验**：加载失败的条目会在日志中打印 `"<kind> '<id>' failed to parse. ..."`（`DataManager.java` L162-L165），并且调用 `SelfTests.reportExternalError()`；开发期务必看服务器日志。

---

## 第 7 部分　世界生成数据结构（W-1 ~ W-11）

### [W-1] data/tfc/worldgen 结构总览


##### [W-1.1] 实测子目录清单（权威口径）

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

##### [W-1.2] 并列但同属世界生成的相关目录（不在本目录内）

| 路径 | 文件数 | 用途 |
|---|---|---|
| `data/tfc/tfc/worldgen/rock_settings/` | 21 | datapack registry `tfc:worldgen/rock_settings`，见 [W-9] |
| `data/tfc/tfc/deposit/` | 84 | 地表矿点方块定义，见 [W-9.4] |
| `data/tfc/tfc/climate_range/crop` / `plant` | 28 / 20 | 作物与植物气候区间（`tfc:climate_range`），与世界生成无关 |
| `data/tfc/tags/worldgen/biome/` | 26 | `is_ocean`、`is_karst`、`has_atolls` 等 |
| `data/tfc/tags/worldgen/configured_feature/` | 3 | `forest_trees`、`dead_forest_trees`、`mangrove_forest_trees` |
| `data/tfc/tags/worldgen/placed_feature/` | 33 | 9 个 `in_biome/*` + 23 个 `feature/*` + 根级 |

`in_biome/` 的 9 个标签是 biome 组装 `features` 的关键：`all_lakes`、`erosion`、`strongholds`、`surface_structures`、`top_layer_modification`、`underground_decoration`、`underground_lakes`、`underground_structures`、`veins`。

### [W-2] 各子目录是什么、关键格式要点

##### [W-2.1] `biome/`（125）——纯原版格式

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

##### [W-2.2] `configured_feature/`（690）与 `placed_feature/`（674）

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

##### [W-2.3] `configured_carver/`（3）

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

##### [W-2.4] `density_function/`（5）与 `world_preset/`（1）

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

### [W-3] TFC 自定义 configured_feature 全清单

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

##### [W-3.1] 五个关键 configured_feature 详解

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

### [W-4] 矿脉（vein）系统

> **包路径更正**：TFC 4.2.10 **不存在** `net/dries007/tfc/world/vein/` 与 `net/dries007/tfc/world/rocklayer/`。矿脉全部位于 `net/dries007/tfc/world/feature/vein/`（13 个文件）。依据：`Get-ChildItem <src>\net\dries007\tfc\world -Directory` 返回 biome / blockpredicate / carver / chunkdata / density / feature / layer / noise / placement / region / river / settings / shore / stateprovider / structure / surface / volcano，**无 `vein`、无 `rocklayer`**。

##### [W-4.1] 类清单

| 文件（`world/feature/vein/`） | 作用 |
|---|---|
| `IVein.java` / `IVeinConfig.java` | 接口：`pos()`；`config()`/`chunkRadius()`/`verticalRadius()`/`indicator()`/`minY()`/`maxY()`/`getStateToGenerate(stoneState, random)` |
| `VeinConfig.java` / `Indicator.java` | 共享基础配置 / 指示物配置 |
| `ClusterVeinFeature`+`ClusterVeinConfig`（`tfc:cluster_vein`）、`DiscVeinFeature`+`DiscVeinConfig`（`tfc:disc_vein`）、`KaolinDiscVeinFeature`（`tfc:kaolin_disc_vein`，复用 `DiscVeinConfig`）、`PipeVeinFeature`+`PipeVeinConfig`（`tfc:pipe_vein`） | 四种矿脉实现 |
| `VeinFeature.java` | 抽象基类：稀有度判定、邻近区块扫描、指示物生成 |

##### [W-4.2] `VeinConfig` 与 `Indicator` 字段表

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

##### [W-4.3] 生成流程（`VeinFeature.java`）

1. `place(context)` 以当前区块为中心扫描 `chunkRadius` 范围内所有区块（`getNearbyVeins`）。
2. 每个被扫描区块用 `XoroshiroRandomSource(level.getSeed() ^ chunkX*61728364132L, config.seed() ^ chunkZ*16298364123L)` 播种，`nextInt(rarity) == 0` 则生成一个 vein（第 86-87 行）。
3. 对每个 vein 计算包围盒（各子类 `getBoundingBox`），与当前区块 `±15`、`[min_y, max_y]` 取交集后逐格判定。
4. `random.nextFloat() < getChanceToGenerate(dx,dy,dz,vein,config)` 时用 `getStateToGenerate(stoneState, random)` 按母岩方块查 `blocks`，非 null 才 `setBlock`。

##### [W-4.4] 真实 JSON 样例

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

##### [W-4.5] jar 内 52 个矿脉（`configured_feature/vein/` 与 `placed_feature/vein/` 同名各 52 个）

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

### [W-5] 岩层（rock layer）系统

##### [W-5.1] `RockSettings` —— 单个岩石类型（datapack registry 元素）

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

##### [W-5.2] `RockLayerSettings` —— 岩层分层规则

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

##### [W-5.3] 完整真实样例（`world_preset/overworld.json` 的 `tfc_settings`）

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

##### [W-5.4] 岩层如何进入地形

- `world/layer/RegionRockLayer.java`：`apply(TypedAreaFactory<Region.Point> prev)` 返回 `new Area((x,z) -> prevArea.get((int)x,(int)z).rock, 1024)`，即把 `Region.Point.rock` 经 Layer 放大到方块分辨率。
- `world/chunkdata/RegionChunkDataGenerator.java:183-184`：`int point = rockLayerArea.get().get(skewX, skewZ); RockSettings rock = rockLayerSettings.sampleAtLayer(point, layer);`
- `RegionGenerator.getSurfaceRock(point)`（第 161-163 行）= `rockLayerSettings().sampleAtLayer(point.rock, 0)`；`Region.Point.rock` 由 region 任务 `CHOOSE_ROCKS`（`world/region/ChooseRocks.java`，56 行）填充。
- 消费岩层数据的 feature：`world/feature/ErosionFeature.java:61`、`world/feature/cave/CaveSpikesFeature.java:62`、`world/feature/SpringFeature.java:48`、`world/surface/SurfaceBuilderContext.java:83`。

### [W-6] 气候与区域系统

##### [W-6.1] 区域（Region）系统 —— **完全硬编码，无 JSON**

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

##### [W-6.2] 气候模型（ClimateModel）—— **硬编码，无 JSON**

源码 `net/dries007/tfc/util/climate/`：`ClimateModel.java`（接口：温度、平均降雨、`type()`）、`ClimateModelType.java`（`record ClimateModelType<T extends ClimateModel>(StreamCodec<ByteBuf, T> codec)`）、`ClimateModels.java`（registry `KEY = tfc:climate_model`，`RegistryBuilder(KEY).sync(true).create()`，两项：`tfc:overworld` → `OverworldClimateModel`、`tfc:biome_based` → `BiomeBasedClimateModel`）、`OverworldClimateModel.java`（由 `ServerLevel` + `ChunkGeneratorExtension` 构造；`STREAM_CODEC = composite(VAR_LONG climateSeed, FLOAT temperatureScale)`）、`BiomeBasedClimateModel.java`（枚举单例）、`Climate.java`（从 `WorldTracker` 取当前模型）。

**关键结论：`ClimateModelType` 只带 `StreamCodec`（网络同步），不带 `Codec`/`MapCodec`，因此不存在对应 JSON 文件**；该注册表为同步注册表，由代码注册而非 datapack。选择逻辑 `ForgeEventHandler.java:1226-1231`：`event.setModel(new OverworldClimateModel(level, ex))`；默认值 `WorldTracker.java:78`：`private ClimateModel climateModel = BiomeBasedClimateModel.INSTANCE;`

##### [W-6.3] biome 扩展（BiomeExtension）—— **硬编码，无 JSON**

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

### [W-7] TFC 自定义 placement modifier 全清单

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

### [W-8] 其他 TFC 世界生成扩展

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

### [W-9] `data/tfc/tfc/worldgen/` 与 `data/tfc/worldgen/` 的区别

##### [W-9.1] 结论对照

| 维度 | `data/tfc/worldgen/` | `data/tfc/tfc/worldgen/` |
|---|---|---|
| 数量 | 1498 个 JSON（6 个子目录） | **21 个 JSON（仅 `rock_settings/`）** |
| 加载方式 | 原版世界生成注册表（`BIOME`/`CONFIGURED_FEATURE`/`PLACED_FEATURE`/`DENSITY_FUNCTION`/`CONFIGURED_CARVER`/`WORLD_PRESET`） | **NeoForge datapack registry**（`DataPackRegistryEvent.NewRegistry`） |
| registry id | 各原版注册表 | `tfc:worldgen/rock_settings` |
| 定义类 / 注册处 | 原版 `RegistryDataLoader` | `world/settings/RockSettings.java` / `TerraFirmaCraft.java:237-238` |
| 路径规则 | `data/<ns>/worldgen/...` | `data/<ns>/tfc/worldgen/...` |

**“多一层 `tfc/`”的机制**：NeoForge datapack registry 的文件路径为 `data/<pack namespace>/<registry path>/*.json`。registry key 是 `tfc:worldgen/rock_settings`（命名空间 `tfc`、path `worldgen/rock_settings`），故文件必须在 `data/tfc/tfc/worldgen/rock_settings/`。

**关于“23 个文件”的更正**：任务描述称该目录下有 23 个文件，**实测为 21 个**，全部在 `rock_settings/` 下，与 TFC 的 21 种岩石一一对应，也与 `world_preset/overworld.json` 中 `rocks` 映射的 21 个键完全一致。依据：`Get-ChildItem '...\data\tfc\tfc\worldgen' -Recurse -File` 返回 21 项；`data/tfc/tfc/` 下另有 `climate_range`、`deposit`、`drinkable`、`fauna`、`fertilizer`、`fluid_heat`、`food`、`fuel`、`item_damage_resistance`、`item_heat`、`item_size`、`knapping_type`、`lamp_fuel`、`support`，均不属于 `worldgen`。

##### [W-9.2] 完整清单与真实内容

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

##### [W-9.3] 二者协作链

1. `data/tfc/tfc/worldgen/rock_settings/*.json` 定义 21 种岩石各自对应的方块；
2. `data/tfc/worldgen/world_preset/overworld.json` 的 `tfc_settings.rock_layer_settings.rocks` 用短名→registry 引用（`"granite":"tfc:granite"`）引入，再以 `bottom`/`layers`/`ocean_floor`/`land`/`volcanic`/`uplift` 定义分层；
3. 运行时 `RegionChunkDataGenerator` → `RockLayerSettings.sampleAtLayer()` → `RockSettings` → `SurfaceBuilderContext` 生成实际方块。技术依据：`RockLayerSettings.java:187` 的 `RegistryFileCodec.create(RockSettings.KEY, RockSettings.CODEC)`。

##### [W-9.4] 相关但独立的 `data/tfc/tfc/deposit/`（84）

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

### [W-10] 完整真实 JSON 样例索引

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

##### [W-10.1] 样例 5 全文 —— `data/tfc/worldgen/placed_feature/plant/arundo.json`

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

##### [W-10.2] 样例 6 全文 —— `data/tfc/worldgen/configured_feature/tree/acacia_entry.json`

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

##### [W-10.3] 样例 7 节选 —— `data/tfc/worldgen/configured_feature/cassiterite_deposit.json`

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

### [W-11] 未能核实与注意事项

##### [W-11.1] 已核实为「不存在 / 硬编码」的项

| 项目 | 结论 | 依据 |
|---|---|---|
| `net/dries007/tfc/world/TFCRegions` | **不存在** | `world/` 根目录 18 个 java 文件已逐一列出 |
| `net/dries007/tfc/world/rocklayer/` 包 | **不存在** | `world/` 下 18 个子目录列表中无此包 |
| `net/dries007/tfc/world/vein/` 包 | **不存在** | 同上；矿脉在 `world/feature/vein/` |
| 区域（region）系统的 JSON | **无，全部硬编码** | `world/region/` 25 个类；任务序列硬编码于 `RegionGenerator.Task`；气候数值硬编码于 `AnnotateClimate.apply` |
| 气候模型（ClimateModel）的 JSON | **无，全部硬编码** | `ClimateModelType` 只有 `StreamCodec` 无 `Codec`；`data/tfc/climate_model/` 不存在 |
| biome 扩展（BiomeExtension）的 JSON | **无，全部硬编码** | `TFCBiomes.java` 约 120 个 `register(...)`；`data/tfc/biome_extension/` 实测不存在 |
| `data/tfc/worldgen/` 下的 `noise_settings`、`template_pool`、`structure`、`processor_list`、`structure_set` | **均不存在** | 目录列举无此五项 |

##### [W-11.2] 存疑点（已检查相关文件，仍无法完全定论）

1. **`StratovolcanoPlacement.variant` 的合法字符串取值**：字段为 `Codec.STRING`，默认 `"all"`；源码引用 `world/volcano/VolcanoVariant`，但字符串比较分支未逐一确认全部取值。jar 内 39 处 `tfc:stratovolcano` 均未显式指定。已检查：`world/placement/StratovolcanoPlacement.java`（CODEC 与类字段已读）、全部 `placed_feature/**`（正则检索 39 处）。
2. **`kaolin_disc.json` 的 `indicator.spread` 字段**：源码 `Indicator.CODEC` 无此字段，会被 codec 忽略（`RecordCodecBuilder` 默认不报未知字段错）。是否为旧版遗留或存在额外解码路径，**未能核实**。已检查：`world/feature/vein/Indicator.java`（全文）、`data/tfc/worldgen/configured_feature/vein/kaolin_disc.json`（全文）。
3. **`tfc:underground` 的实际使用数**：对 `placement` 数组的正规解析结果为 **0 次**；对文件全文正则匹配得 1 次（来自 `placed_feature/underground_loose_rocks.json` 的 `feature` id 字符串 `tfc:underground_loose_rocks`）。准确表述：**jar 内无任何 placed_feature 的 placement 数组使用 `tfc:underground`**。
4. **`PipeVeinConfig` 的 `height` forGetter**：反编译输出为 `c -> c.radius`，与 record 组件顺序矛盾，判定为 CFR 反编译瑕疵；JSON 字段名 `height` 无误。已检查：`world/feature/vein/PipeVeinConfig.java`（第 21-33 行）。
5. **`TFCFeatures` 注册项总数**：源码第 118-175 行共 **58** 条 `register(...)` 调用，非 55。本文按 58 条逐一列出。
6. **`data/tfc/tfc/worldgen/` 文件数**：任务描述为 23，实测 **21**。未在其他位置发现属于该 registry 的第 22、23 个文件。
7. **`Codecs.POSITIVE_INT` 是否允许 0**：该常量为原版 `ExtraCodecs.POSITIVE_INT`，`shallow_water` 的 `min_depth` 默认值为 `0`；本文按“非负整数”表述，未进一步反查原版 `ExtraCodecs` 的常量定义。
8. **`tfc:tuff_cone` 在 jar 内 0 次使用**，`TuffRingPlacement` 缺少可参照的实际用例；其字段已由源码 CODEC 确认，但实际生效效果未能核实。

##### [W-11.3] 给附属模组的注意事项

1. 按气候放特征 → 用 `tfc:climate`（14 个字段，最全）。
2. **按岩层放特征没有现成 placement modifier**：要么用矿脉的 `blocks` 按母岩匹配，要么在自定义 Feature 内取 `ChunkGeneratorExtension.rockLayerSettings()`（Java 侧，参考 `world/feature/ErosionFeature.java:61`、`world/feature/SpringFeature.java:48`）。
3. 火山/环礁/凝灰岩环/冰原丘定位 → `tfc:volcano`（渣锥）/ `tfc:stratovolcano` / `tfc:tuff_cone` / `tfc:atoll` / `tfc:tuya`；字段仅 `center` + `min_easing` + `max_easing`（stratovolcano 另加 4 个）。注意 `tfc:tuff_cone` 无实例可参照。
4. 放置前判定“上方为空 / 可替换 / 可存活” → 用 `block_predicate_filter` + `tfc:air_or_empty_fluid` / `tfc:replaceable` / `tfc:dry_replaceable` / `tfc:would_survive_with_fluid`；**不要**把它们误写成 placement 的 `type`。
5. 新增岩石类型 → 需提供 `data/<ns>/tfc/worldgen/rock_settings/<name>.json` + 修改 `world_preset` 的 `tfc_settings.rock_layer_settings`。后者是 world_preset 内联数据，要改动必须整体覆盖 overworld 的 world preset；**TFC 源码中未发现任何此类扩展点**，属高风险改动。

---

## 第 8 部分　tag、自定义 ingredient、loot 与 advancement（T-1 ~ T-4）


调查对象：TerraFirmaCraft NeoForge 1.21.1-4.2.10（jar：`mods\TerraFirmaCraft-NeoForge-1.21.1-4.2.10.jar`）。

数据来源与引用约定：

- jar 内真实数据：`moddev\jar-extract\data\tfc\...`（路径均相对 `moddev\jar-extract\`）
- 反编译源码：`moddev\src-ref\TFC-decompiled\net\dries007\tfc\...`（无参数名、无注释）
- 本文件中「未能核实」= 已检查过列出的文件但无法从这些文件得出结论。

---

### [T-1] tags 体系

##### T-1.1 实测目录与文件数

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

##### T-1.2 注册表维度

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

##### T-1.3 item tag 的命名空间结构（重要：TFC **没有** `metals/*`、`ores/*` 这类大目录）

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

##### T-1.4 item tag 一级文件的功能分组

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

##### T-1.5 block tag 结构

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

##### T-1.6 fluid tag（22 个，全部扁平）

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

##### T-1.7 entity_type tag（35 个，全部扁平）

`data/tfc/tags/entity_type/` 的完整文件清单：
`animals`、`bears`、`big_cats`、`bird_prey`、`bubble_column_immune`、`canine_predators`、`cold_pests`、`dairy_animals`、`desert_pests`、`farm_animals`、`hunted_by_cats`、`hunted_by_dogs`、`hunted_by_land_predators`、`hunted_by_ocean_predators`、`ignores_snow`、`land_predators`、`large_prey`、`monsters`、`needs_large_fishing_bait`、`not_rammed_by_rammers`、`ocean_predators`、`oviparous_animals`、`pests`、`pets`、`ramming_animals`、`rideable_animals`、`shearable_animals`、`small_fish`、`spawns_on_cold_blocks`、`tropical_pests`、`turtle_friends`、`universal_pests`、`water_ambient`、`water_creatures`、`wild_prey_animals`。

对应 `TFCTags.Entities`（`TFCTags.java:62-108`）。其中：

- `tfc:animals` 是聚合 tag，实测内容为 `["#tfc:land_predators","#tfc:water_ambient","#tfc:water_creatures","#tfc:pests","#tfc:pets","#tfc:ramming_animals","#tfc:water_creatures","#tfc:farm_animals","#tfc:wild_prey_animals","tfc:rabbit"]`（注意其中 `#tfc:water_creatures` 重复出现两次，属 jar 内原样数据）。
- `AMPHIBIOUS_CREATURES` 常量（`TFCTags.java:90`）**与 `WATER_CREATURES` 指向同一个 id** `tfc:water_creatures`，不存在单独的 `tfc:amphibious_creatures` 文件。
- 物品侧的 `deals_*_damage` 是 **item tag**；实体侧同样存在 `tfc:deals_slashing_damage` / `deals_piercing_damage` / `deals_crushing_damage` 三个 **entity_type tag**（`TFCTags.java:66-68`），由 `PhysicalDamageType.java:103-111` 使用。

##### T-1.8 damage_type tag（3 个）

对应源码 `net\dries007\tfc\util\PhysicalDamageType.java:151-156`。

| tag id | jar 内真实内容 | 源码行 |
|---|---|---|
| `tfc:is_crushing` | `{"values":["minecraft:in_wall","minecraft:cramming","minecraft:fall","minecraft:fly_into_wall","minecraft:falling_block","minecraft:falling_anvil"]}`（6 条） | 154 |
| `tfc:is_piercing` | `{"values":["minecraft:cactus","minecraft:sweet_berry_bush","minecraft:stalagmite","minecraft:falling_stalactite","minecraft:sting","minecraft:arrow","minecraft:trident"]}`（7 条） | 153 |
| `tfc:is_slashing` | `{"values":[]}`（**空**） | 155 |

以上三条内容均为直接读取文件所得（`data/tfc/tags/damage_type/`）。

**语义**：把 vanilla 伤害类型归入 TFC 的物理伤害三分类。这三个 tag 由**数据包填充**（TFC 自己写入了 crushing/piercing 的条目），代码侧通过 `TagKey` 引用；`tfc:is_slashing` 在 jar 内为空，说明斩击类伤害在 1.21.1 原版伤害类型中没有需要归入的项，或该项由其它来源填充。

另需注意：`PhysicalDamageType.java:152` 还声明了第 4 个常量 `tfc:bypasses_damage_resistances`，但 jar 内**没有对应文件**（`data/tfc/tags/damage_type/` 下只有上述 3 个文件）。

##### T-1.9 worldgen tag（440 个，3 个层级）

全部为 `Registries.BIOME` / configured_feature / placed_feature 侧的标准 tag JSON，写法与其它注册表一致（含显式 `"replace":false`）。

- `tags/worldgen/biome/*`（26 个）：生物群系分类，如 `is_ocean`、`is_river`、`is_karst`、`is_glaciated`、`is_ice_sheet`、`is_shilin`、`has_atolls`、`has_tuyas` 等（`TFCTags.Biomes`，`TFCTags.java:36-59`）。
- `tags/worldgen/configured_feature/*`（3 个）：`dead_forest_trees`、`forest_trees`、`mangrove_forest_trees`。
- `tags/worldgen/placed_feature/*`（411 个）：按 `feature/`、`in_biome/`、`in_biome/large_features/`、`in_biome/soil_discs/`、`in_biome/surface_decoration/`、`in_biome/veins/` 组织，用于按生物群系分类注入地物。

##### T-1.10 关于任务描述中猜测 tag 的逐条核实

| 任务描述中的 tag | 实测结论 | 依据 |
|---|---|---|
| `tfc:metals/*`（每种金属一个 tag） | **不存在**。`data/tfc/tags/item/` 与 `block/` 下都没有 `metals/` 目录，源码 `TFCTags` 中也没有任何 `metals` 字符串（grep 全源码仅命中 `metal_ores`） | 目录枚举 + grep |
| `tfc:ores/<ore>/<grade>` 形式 | **不存在**。矿石使用扁平 tag：`tfc:metal_ores`、`tfc:ore_pieces`、`tfc:small_ore_pieces`、`tfc:ore_deposits`；而 `<ore>/<grade>` 形态出现在**物品 id** 上（`tfc:ore/poor_native_copper`、`tfc:ore/normal_*`、`tfc:ore/rich_*`、`tfc:ore/small_*`）与**矿脉方块 id** 上（`tfc:deposit/<ore>/<rock>`） | `item/metal_ores.json`、`item/ore_deposits.json` 内容 |
| 按 item size 分类的 tag | **不存在**。item size 由自定义注册表 `data/tfc/tfc/item_size/*.json`（67 个文件）定义，不是 tag。样例：`{"ingredient":{"tag":"c:foods"},"size":"small","weight":"light"}`（`tfc/item_size/foods.json`） | 目录枚举 + 文件内容 |
| 按 food 分类的 tag | **存在**，但范围有限，仅 `tfc:foods/*` 的 9 个文件（`can_be_salted`、`empty_jars`、`empty_jars_with_lid`、`filled_jars`、`jam`、`jars`、`preserves`、`sealed_preserves`、`sweeteners`）+ 22 个 `*_food`（动物饲料）。真正的食物属性数据在 `data/tfc/tfc/food/`（195 个文件） | `data/tfc/tags/item/foods/`、`data/tfc/tfc/food/` |
| `tfc:forge_invisible_whitelist` | **不存在**。相关的是 `tfc:charcoal_forge_invisible`（block tag，`TFCTags.java:412`）。grep `forge_invisible_whitelist` 全源码无命中 | grep |
| `tfc:can_be_chiseled` | **不存在**。与凿子相关的是 `tfc:mineable/chisel`（block tag，`TFCTags.java:440`，jar 内容为空数组）与 `tfc:tools/chisel`→`c:tools/chisel`。grep `can_be_chiseled` 全源码无命中 | grep |
| `minecraft:*` 中 TFC 常用者 | TFC 数据文件实际引用到的 vanilla tag 共 19 个：`minecraft:axes`、`coals`、`dirt`、`hoes`、`leaves`、`logs`、`logs_that_burn`、`mineable/hoe`、`pickaxes`、`sand`、`shovels`、`small_flowers`、`stone_bricks`、`swords`、`undead`、`water`、`wool`、`wool_carpets`（另 `#minecraft:hoes` 等出现在 `item/tools/sharp.json`） | 正则统计 `tags/` 下全部文件中的 `#minecraft:` 引用 |

##### T-1.11 附属模组必须提供的通用 tag（`c:` 命名空间）

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

##### T-1.12 真实 tag JSON 样例（含 jar 内路径）

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

##### T-1.13 tag 覆盖 / 新增 / 合并规则

**规则本体不在 TFC 源码中**：TFC 只声明 `TagKey` 常量并读取 tag，不实现 tag 文件的加载与合并。加载逻辑由原版 `net.minecraft.tags.TagLoader` + NeoForge 的数据包加载器完成（反编译源码中已确认只有 `TFCTags.java`、`PhysicalDamageType.java`、`CrankshaftBlock.java`、`BlockIngredient.java` 出现 `TagKey.create`，无任何 tag 加载/合并代码）。因此以下规则描述的是**原版数据包 tag 机制**，不是从 TFC 源码读出的：

1. **同 id 合并（默认）**：多个数据包（含模组 jar）提供同一个 `data/<ns>/tags/<registry>/<路径>.json` 时，若都没有 `replace:true`，则所有 `values` 取并集。TFC 的聚合 tag 正是依赖这一点（例如 `tfc:compost_greens` 引用三个子 tag）。
2. **`replace: true`**：该文件的值**取代**此前所有来源对该 tag 的贡献（而不是追加）。TFC 自己在 `worldgen/placed_feature/feature/*.json` 里大量显式写 `"replace":false`，属于"显式声明不替换"，效果与省略该字段相同。
3. **第三方不应在 `data/tfc/` 命名空间下新增文件**：以 `tfc` 为命名空间写文件会与 TFC 自身的数据文件冲突（同路径文件在数据包优先级下互相覆盖），且 TFC 更新时可能被替换。正确做法是在**自己的 `data/<modid>/tags/` 下新建文件并填入自己的内容**，或用一个 `data/tfc/tags/...` 占位文件配合 `replace:true`（仅在必须覆盖时）。
4. **引用第三方 tag 以扩展 TFC 行为**：TFC 的很多 tag 是"由数据驱动、TFC 不写入"的空 tag（见 T-1.14），附属模组只需在 **自己的** 命名空间放 `data/<modid>/tags/item/<tfc_tag_path>.json`？—— **不成立**：tag 的归属命名空间是文件路径中的 `tfc`，因此要往 `tfc:xxx` 这个 tag 里加条目，**必须**创建 `data/tfc/tags/<registry>/<path>.json`（内容不含 `replace`，从而与原文件合并）。这是原版机制下的必然结果，也是 TFC 数据包/附属模组的通行做法。
5. **`remove` 字段**：jar 内 4 个文件使用了 `"remove"`（`item/usable_in_soup.json`、`item/foods/jam.json`、`item/foods/preserves.json`、`item/foods/sealed_preserves.json`），语义应从合并结果中删除指定条目。**该字段的加载语义未能核实**：TFC 反编译源码中不含 tag 加载代码，无法从本仓库确认 1.21.1 + NeoForge 21.1.248 的 `TagFile` codec 是否支持 `remove`、以及它是在合并前还是合并后生效。此处仅记录 jar 内真实存在该字段及其所在文件。

##### T-1.14 源码声明但 jar 内**没有**对应数据文件的 tag

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

### [T-2] 自定义 recipe ingredient（TFCIngredients）

##### T-2.1 注册表与 type id 全清单

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

##### T-2.2 逐类字段表

###### （1）`tfc:rotten` —— `RottenIngredient`

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

###### （2）`tfc:not_rotten` —— `NotRottenIngredient`

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

###### （3）`tfc:has_trait` —— `HasTraitIngredient`

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

###### （4）`tfc:lacks_trait` —— `LacksTraitIngredient`

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

###### （5）`tfc:heat` —— `HeatIngredient`

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

###### （6）`tfc:fluid_content` —— `FluidContentIngredient`

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

###### （7）`tfc:and` —— `AndIngredient`

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

##### T-2.3 非注册的同类目录文件（干扰项澄清）

`net\dries007\tfc\common\recipes\ingredients\` 目录下另有 3 个类**不是**注册的 ingredient type：

| 类 | 形态 | 是否可注册 | 说明 |
|---|---|---|---|
| `net.dries007.tfc.common.recipes.ingredients.BlockIngredient` | `public record BlockIngredient(Either<ImmutableSet<Block>, TagKey<Block>> either) implements Predicate<Block>`（`BlockIngredient.java:43`） | **否** | CODEC（`:45`）= `Codec.either(Codecs.BLOCK.listOf().xmap(ImmutableSet::copyOf, List::copyOf), TagKey.hashedCodec(Registries.BLOCK))`，即接受 `"#<block tag>"` 字符串或 `["<block id>", ...]` 数组两种写法。真实使用点：advancement 的 `tfc:chiseled` / `tfc:lit` / `tfc:rock_anvil` / `tfc:firepit_created` 触发器的 `conditions.ingredient`（见 T-4.3、T-4.4 样例） |
| `net.dries007.tfc.common.recipes.ingredients.KeyedIngredient` | `public interface KeyedIngredient extends Predicate<ItemStack>`（`KeyedIngredient.java:28`） | **否** | 纯 Java 侧接口（提供 `keys()` 用于索引/反查），非 JSON 类型，未注册、也未出现在任何 JSON 中 |
| `net.dries007.tfc.common.recipes.ingredients.PreciseIngredient` | `public interface PreciseIngredient extends ICustomIngredient`（`PreciseIngredient.java:18-19`） | **否** | 提供默认实现：`getItems()`（遍历 `BuiltInRegistries.ITEM` 全量物品并 `filter` + `modifyStackForDisplay`，`:20-22`）、`isSimple() -> false`（`:24-26`）、`modifyStackForDisplay`（默认原样返回，`:28-30`）。被 T-2.2 中前 5 个 ingredient 类实现，只是共享基接口 |

`PreciseIngredient` 的存在解释了为什么这些 ingredient 的 `getItems()` 会扫描全物品表：它们没有固定物品列表，只能按条件全量筛选后改写显示。

##### T-2.4 用例统计与任务猜测清单核实

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

### [T-3] 自定义 loot condition / function

##### T-3.1 注册表位置

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

##### T-3.2 自定义 loot condition（6 个）

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

##### T-3.3 自定义 loot number provider（2 个）

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

##### T-3.4 自定义 loot function（3 个）

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

##### T-3.5 TFC 是否给原版 loot function 提供自定义参数？

**结论：TFC 没有改写原版 loot function 本身，而是通过注册新的 `NumberProvider` 类型，把自定义参数注入原版 `minecraft:set_count` 的 `count` 字段。**

证据：

1. `tfc:animal_yield` 与 `tfc:crop_yield_uniform` 注册在 `Registries.LOOT_NUMBER_PROVIDER_TYPE`（`TFCLoot.java:49`），并被原版 function `minecraft:set_count` 的 `count` 字段引用（`loot_table/entities/goat.json`、`loot_table/blocks/crop/alfalfa.json`，见 T-3.3 样例）。原版 `SetItemCountFunction` 的 `count` 字段类型就是 `NumberProvider`，因此自定义 provider 可以合法嵌入，无需修改原版代码。
2. 已确认 TFC **没有** 任何 loot 相关的 Mixin：mixin 目录仅有 `net\dries007\tfc\mixin`（此目录存在），按 `-Filter '*.java'` 且文件名含 `Mixin` 且内容含 `Loot` 检索，命中 0 个文件；直接 grep `LootItem|LootContext|LootTable|loot`（限定 `*Mixin*.java`）同样 0 命中。
3. 除 `NumberProviders` 之外，TFC 未注册任何其它原版 loot 子注册表类型（`TFCLoot.java` 全文 86 行只含 3 个 `DeferredRegister`）。

##### T-3.6 自定义 loot condition / function 汇总表（含用例统计）

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

### [T-4] 自定义 advancement trigger

##### T-4.1 注册类与注册表

任务描述猜测的 `net\dries007\tfc\common\advancements\` **不存在**。真实位置是：

- 包目录：`moddev\src-ref\TFC-decompiled\net\dries007\tfc\util\advancements\`（4 个文件：`TFCAdvancements.java`、`GenericTrigger.java`、`BlockActionTrigger.java`、`EntityActionTrigger.java`，另有 `package-info.java`）
- 注册类：`net\dries007\tfc\util\advancements\TFCAdvancements.java`

`TFCAdvancements.java:30`：

```java
public static final DeferredRegister<CriterionTrigger<?>> TRIGGERS =
    DeferredRegister.create(Registries.TRIGGER_TYPE, "tfc");
```

##### T-4.2 全部 18 个自定义 trigger

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

##### T-4.3 各 trigger 的 conditions 字段

###### `GenericTrigger`（11 个 trigger 共用）

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

###### `BlockActionTrigger`（4 个 trigger 共用）

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

###### `EntityActionTrigger`（3 个 trigger 共用）

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

##### T-4.4 真实 advancement JSON 样例与用例统计

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

##### T-4.5 附属模组可复用的要点

- 所有 18 个 trigger 都是 `SimpleCriterionTrigger` 的子类，因此 advancement 的 criteria 写法遵循 vanilla 结构（`{"trigger":"tfc:xxx","conditions":{...}}`），且都可被附属模组直接引用（注册表 id 稳定）。
- `registerBlock` 系列要求写 `conditions.ingredient`；`registerEntity` 系列要求写 `conditions.entity`；`registerGeneric` 系列只能写 `conditions.player`（写了别的字段会被 codec 拒绝）。
- `tfc:chiseled` / `tfc:lit` / `tfc:rock_anvil` / `tfc:firepit_created` 的 `ingredient` 支持 `#tag` 字符串（`BlockIngredient` 的 `Either.right(TagKey<Block>)` 分支），因此附属模组可以通过往 block tag 加条目来扩展这些 advancement 的可触发方块，无需改 advancement JSON。
- `tfc:fed_animal` / `tfc:hooked_entity` / `tfc:stab_entity` 的 `entity.type` 使用 vanilla `EntityPredicate`，同样支持 `#tag` 形式（样例 4）。

##### T-4.6 未能核实的点（本章）

- `GenericTrigger` 的 11 个 trigger 各自在**哪个代码位置**被调用（如 `tfc:basin_pour` 由哪个方块实体触发）未逐一核实。已确认的仅是注册与 JSON 结构。若要逐一核实需按 id 反查调用点，本次未做。


---

## 附录 Z　本手册的写作与核查方式（可追溯性）

### Z.1 中间片段文件

本手册由 9 个独立核查片段拼装而成，片段保留在 `moddev\docs\_work\` 下，便于逐节复核：

| 片段文件 | 内容 | 行数规模 |
| --- | --- | --- |
| `00-frontmatter.md` | 前言、目录约定、索引表、骨架模板 | ~330 行 |
| `d-recipe-A1.md` | R-01 ~ R-05（alloy/anvil/welding/casting/casting_crafting）+ ItemStackProvider 体系附录 | ~1175 行 |
| `d-recipe-A2.md` | R-06 ~ R-11（collapse/landslide/chisel/barrel 三兄弟） | ~1491 行 |
| `d-recipe-A3.md` | R-12 ~ R-17（heating/quern/scraping/knapping/glassworking/sewing） | ~1425 行 |
| `d-recipe-A4.md` | R-18 ~ R-23（pot 三兄弟/loom/food_combining/bloomery） | ~1472 行 |
| `d-recipe-A5.md` | R-24 ~ R-29（blast_furnace/crafting 两类/advanced 两类/通用输出） | ~1339 行 |
| `f-data-types.md` | D-0 ~ D-17（全部 16 种数据类型 + 加载机制） | ~820 行 |
| `e-worldgen.md` | W-1 ~ W-11（世界生成） | ~739 行 |
| `e-tags-misc.md` | T-1 ~ T-4（tag / ingredient / loot / advancement） | ~895 行 |

### Z.2 核查方法

1. **字段来源**：每个字段均从对应类的 `CODEC`（`RecordCodecBuilder.create` 或 `mapCodec`）逐行读取，`fieldOf` 判为必填、`optionalFieldOf(name, default)` 判为可选并记录默认值。复用父类字段时同时阅读父类与接口源码。
2. **JSON 样例真实性**：所有引用为「完整样例」的 JSON 均从 `moddev\jar-extract\` 的真实文件中读取，并已程序化逐字比对（A3 组 33/33 一致、A4 组 21/22 一致且唯一差异项已标注为「片段」、A5 组 18/18 一致）。
3. **触发条件**：通过在整个反编译树中 grep 类名定位全部调用点，记录「相对源码路径:行号」，未凭经验推断。
4. **未核实项**：各组均设专节登记（`附录 A1-4`、`A2-3`、`A4-4.4`、`A5-C`、`W-11`、`T-*` 末节），写明检查过的文件与替代证据。

### Z.3 版本一致性提示

本手册基于 **4.2.10**。若升级到其它 4.2.x 版本，请优先复核以下易变点：`TFCRecipeSerializers` 的注册清单、`TFCIngredients`/`TFCLoot`/`TFCAdvancements`/`TFCPlacements`/`TFCFeatures` 的注册项数（本手册实测分别为 7 / 11 / 18 / 15 / 58）、以及 `ItemStackModifiers` 的 modifier 清单（实测 22 项）。