# TFC 4.2.10 数据驱动内容格式完整参考手册

> 面向对象：**不带上下文、需要直接照抄字段**的 AI 代理，用于编写 TerraFirmaCraft 附属模组 / 数据包。
> 版本基准：`TerraFirmaCraft-NeoForge-1.21.1-4.2.10`（Minecraft 1.21.1 / NeoForge 21.1.248）。
> 本手册所有字段均从反编译源码的 `Codec` / `RecordCodecBuilder` / record 组件逐行读取确认，所有 JSON 样例均取自本地 jar 的真实文件。**未核实的内容一律标注「未能核实」并说明检查过哪些文件。**
> 网络不可用，本手册全部结论来自本地文件，未使用任何在线资料。

---

## 0. 环境事实与使用说明

### 0.1 本手册的证据来源（本地路径）

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

### 0.2 目录约定速查（附属模组最常踩的坑）

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

### 0.3 TFC 自定义注册表一览（决定 JSON 的 `type` 字符串）

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

## 1. 配方类型总览（28 种，编号 R-01 ~ R-28）

### 1.1 注册来源

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

### 1.2 全部类型索引与实测数量

数量统计依据 `...\moddev\inventory\TFC.resources.txt`（统计 `data/tfc/recipe/<type>/` 下的资源条目）：

| 编号 | type id | 数量 | 本手册章节 |
| --- | --- | --- | --- |
| R-01 | `tfc:alloy` | 9 | 合金 |
| R-02 | `tfc:anvil` | 281 | 砧板锻造 |
| R-03 | `tfc:welding` | 87 | 砧板焊接 |
| R-04 | `tfc:casting` | 111 | 模具浇铸 |
| R-05 | `tfc:casting_crafting` | 1 | 工作台浇铸 |
| R-06 | `tfc:collapse` | 525 | 岩石塌陷 |
| R-07 | `tfc:landslide` | 21 | 滑坡 |
| R-08 | `tfc:chisel` | 513 | 凿刻 |
| R-09 | `tfc:barrel_sealed` | 308 | 密封桶 |
| R-10 | `tfc:barrel_instant` | 20 | 即时桶 |
| R-11 | `tfc:barrel_instant_fluid` | 2 | 即时桶（流体） |
| R-12 | `tfc:heating` | 883 | 加热 |
| R-13 | `tfc:quern` | 89 | 手磨 |
| R-14 | `tfc:scraping` | 7 | 刮制 |
| R-15 | `tfc:knapping` | 101 | 打制 |
| R-16 | `tfc:glassworking` | 60 | 玻璃加工 |
| R-17 | `tfc:sewing` | 25 | 缝纫 |
| R-18 | `tfc:pot` | 145 | 陶罐（普通） |
| R-19 | `tfc:pot_soup` | 3 | 陶罐（汤） |
| R-20 | `tfc:pot_jam` | 66 | 陶罐（果酱） |
| R-21 | `tfc:loom` | 5 | 织机 |
| R-22 | `tfc:food_combining` | 1 | 食物合并 |
| R-23 | `tfc:bloomery` | 1 | 土高炉 |
| R-24 | `tfc:blast_furnace` | 1 | 高炉 |
| R-25 | `minecraft:crafting_shaped` | 1669 | 原版有序合成 |
| R-26 | `minecraft:crafting_shapeless` | 569 | 原版无序合成 |
| R-27 | `tfc:advanced_shaped_crafting` | 372 | TFC 扩展有序合成 |
| R-28 | `tfc:advanced_shapeless_crafting` | 283 | TFC 扩展无序合成 |
| R-29 | （通用章节） | — | `ItemStackProvider` / `ItemStackModifier` / `TFCIngredients` |

> 说明：`heating` 在资源清单中为 951 条，去重目录条目后实际 `.json` 约为 883 个；不同统计口径（是否计入子目录）会略有差异。所有数量仅供估算规模，不作为格式依据。

### 1.3 TFC 自定义数据类型的索引

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

---

## 2. 配方通用骨架模板（可直接复制）

以下模板覆盖 90% 的附属模组需求，字段含义详见对应章节。

### 2.1 加热配方（`tfc:heating`）

```json
{
  "type": "tfc:heating",
  "ingredient": { "item": "mymod:raw_titanium" },
  "result_item": { "stack": { "id": "mymod:titanium_ingot" } },
  "temperature": 1668.0
}
```

> `tfc:heating` **没有** `chance` 字段（CODEC 只有 `ingredient`/`result_item`/`result_fluid`/`temperature`/`use_durability`）；概率产出用 `result_item.modifiers` 里的 `{"type":"tfc:chance","chance":0.2}`。详见 R-12。

### 2.2 砧板锻造（`tfc:anvil`）

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

### 2.3 密封桶（`tfc:barrel_sealed`）

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

### 2.4 陶罐（`tfc:pot`）

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

### 2.5 打制（`tfc:knapping`）

```json
{
  "type": "tfc:knapping",
  "knapping_type": "tfc:rock",
  "pattern": [ "XXXXX", "X   X", "X   X", "X   X", "XXXXX" ],
  "result": { "count": 1, "id": "mymod:bone_plate" }
}
```

> `pattern` 与 `default_on` 是**顶层字段**（`KnappingPattern.CODEC` 经 `forGetter` 平铺）。图案**不要求** 5×5：允许 1~5 行/列，但**非 5×5 时必须提供 `default_on`**，否则报错 `default_on is required if the pattern is not 5x5`。`result` 是**裸 `ItemStack`**，不是 `ItemStackProvider`。可选 `outside_slot_required`（默认 `true`，即必须消耗外圈格）。详见 R-15。

### 2.6 扩展工作台合成（`tfc:advanced_shaped_crafting`）

```json
{
  "type": "tfc:advanced_shaped_crafting",
  "pattern": [ "XX", "XX" ],
  "key": { "X": { "tag": "c:ingots/titanium" } },
  "result": { "stack": { "id": "mymod:titanium_block" } }
}
```

> `result` 为 `ItemStackProvider`（支持裸 `ItemStack` 简写，也支持带 `modifiers` 的完整形式）。详见 R-27。

### 2.7 TFC 数据文件模板（`data/mymod/tfc/item_heat/...`）

```json
{
  "ingredient": { "tag": "c:ingots/titanium" },
  "heat_capacity": 2.5,
  "forging_temperature": 1200.0,
  "welding_temperature": 1500.0
}
```

### 2.8 通用 ingredient 写法速查

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

### 2.9 常用物品组件（`ItemStack` 的 JSON 写法）

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
