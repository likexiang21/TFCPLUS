# 第 4 部分　`data/tfc/tfc/<kind>/` 数据类型全解（B 部分）

本部分覆盖 TFC 4.2.10 中 `data/tfc/tfc/<kind>/` 下的全部数据类型。所有字段均从反编译源码的 `Codec` / `RecordCodecBuilder` 逐行读取确认，JSON 样例均取自本地 jar 真实文件。

## [D-0] 数据加载机制总览（必读）

### D-0.1 两种加载途径

TFC 的 `data/tfc/tfc/<kind>/` 下有**两套完全不同的加载机制**，附属模组写法差别很大：

| 机制 | 归属类 | 目录特征 | 覆盖方式 |
| --- | --- | --- | --- |
| `DataManager<T>`（SimpleJsonResourceReloadListener） | `net.dries007.tfc.util.data.DataManager` | `data/<ns>/tfc/<kind>/...` | 服务器资源重载；同名 ID 覆盖取决于加载顺序 |
| 数据包注册表（datapack registry） | `event.dataPackRegistry(...)` | `data/<ns>/tfc/<kind>/...` | 数据包注册表，同名 ID 由数据包覆盖 |

**来源**：`net/dries007/tfc/util/data/DataManager.java` L56-L80；`net/dries007/tfc/TerraFirmaCraft.java` L238（`event.dataPackRegistry(RockSettings.KEY, RockSettings.CODEC)`）。

### D-0.2 `DataManager` 的路径规则（关键结论）

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

### D-0.3 数据是否同步到客户端

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

### D-0.4 通用代码片段模板

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

## [D-1] `item_heat` —— 物品热容与锻造温度

### D-1.1 基本信息

| 项目 | 值 |
| --- | --- |
| 数据类 | `net.dries007.tfc.common.component.heat.HeatDefinition`（record） |
| 管理器 | `net.dries007.tfc.common.component.heat.HeatCapability.MANAGER` |
| 注册路径 | `tfc:item_heat` → 目录 `data/*/tfc/item_heat/**` |
| 同步 | 是（有 `STREAM_CODEC`） |
| 真实文件数 | 343 个（含 33 个子目录） |

**来源**：`net/dries007/tfc/common/component/heat/HeatCapability.java` L43；`net/dries007/tfc/common/component/heat/HeatDefinition.java` L28-L32。

### D-1.2 字段表

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

### D-1.3 真实 JSON 样例

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

### D-1.4 运行时如何被读取

| API | 语义 | 来源 |
| --- | --- | --- |
| `HeatCapability.getDefinition(ItemStack)` | 查定义，返回 `@Nullable HeatDefinition` | `HeatCapability.java` L95-L97 |
| `HeatCapability.get(ItemStack)` | 返回可写 `IHeat`（来自 capability 或 `TFCComponents.HEAT` 组件） | 同上 L48-L55 |
| `HeatCapability.view(ItemStack)` | 只读视图 | 同上 L58-L61 |
| `HeatCapability.has(ItemStack)` | 是否带 HEAT 组件 | 同上 L67-L69 |
| `HeatCapability.getTemperature(ItemStack)` | 当前温度 | 同上 L71-L74 |
| `HeatCapability.addTemp(IHeat, float)` | 加热 | 同上 L154-L168 |

**重要**：物品**只有存在 `item_heat` 定义时才能被加热**。`HeatCapability.get(stack)` 会先查 `ItemCapabilities.HEAT`（仅注册给模具 molds 与容器 vessels，见 `ItemCapabilities.java`）或 `TFCComponents.HEAT` 组件；组件由定义动态附加。附属模组新增的可加热物品**必须补 `item_heat`**，否则锻造炉/木炭堆不会给它加温。

### D-1.5 附属模组写法示例

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

## [D-2] `food` —— 食物营养与腐坏

### D-2.1 基本信息

| 项目 | 值 |
| --- | --- |
| 数据类 | `net.dries007.tfc.common.component.food.FoodDefinition`（record） |
| 管理器 | `net.dries007.tfc.common.component.food.FoodCapability.MANAGER` |
| 注册路径 | `tfc:food` → 目录 `data/*/tfc/food/**` |
| 同步 | 是 |
| 真实文件数 | 195 个（含 `jar` 子目录） |

**来源**：`net/dries007/tfc/common/component/food/FoodCapability.java`（`MANAGER` 字段行）；`FoodDefinition.java` L29-L33。

### D-2.2 字段表

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

### D-2.3 真实 JSON 样例

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

### D-2.4 运行时如何被读取

| API | 语义 | 来源 |
| --- | --- | --- |
| `FoodCapability.getDefinition(ItemStack)`（经由 `CACHE`） | 查食物定义 | `FoodCapability.java` |
| `FoodCapability.markRecipeOutputsAsNonDecaying(RegistryAccess, RecipeManager)` | 把配方输出标记为不腐坏 | `FoodCapability.java` |
| `FoodTraits.REGISTRY` / `FoodTrait` | 附加腐坏修正（腌制、盐渍、熏烤等） | `net/dries007/tfc/common/component/food/FoodTraits.java` |

内置 food trait 注册名（`FoodTraits.java`）：`salted`、`brined`、`pickled`、`preserved`、`vinegar`、`charcoal_grilled`、`wood_grilled`、`burnt_to_a_crisp`、`wild`、`canned`。它们注册在独立注册表 `ResourceKey<Registry<FoodTrait>> KEY = Helpers.identifier("food_trait")`，**由 `TFCComponents` 的 trait 列表引用**，不是通过 `tfc/food` 目录的数据文件声明的。附属模组若要给出自定义 trait，应注册自己的 `FoodTrait`（Java 侧）并在配方/物品上附加。

**重要**：食物定义只对 `ingredient` 命中的物品生效。新增食品必须在 `data/<modid>/tfc/food/` 中补充定义，否则该物品没有 hunger/water/nutrient 数据，玩家吃它不会产生 TFC 食物效果。

### D-2.5 附属模组写法示例

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

## [D-3] `item_size` —— 物品体积与重量

### D-3.1 基本信息

| 项目 | 值 |
| --- | --- |
| 数据类 | `net.dries007.tfc.common.component.size.ItemSizeDefinition`（record） |
| 管理器 | `net.dries007.tfc.common.component.size.ItemSizeManager.MANAGER` |
| 注册路径 | `tfc:item_size` → 目录 `data/*/tfc/item_size/**` |
| 同步 | 是 |
| 真实文件数 | 67 个（无子目录） |

**来源**：`net/dries007/tfc/common/component/size/ItemSizeManager.java` L39；`ItemSizeDefinition.java` L28-L31。

### D-3.2 字段表

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

### D-3.3 真实 JSON 样例

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

### D-3.4 运行时如何被读取

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

### D-3.5 附属模组写法示例

```json
// 文件：data/mymod/tfc/item_size/titanium_ingots.json → ID mymod:titanium_ingots
{ "ingredient": { "tag": "c:ingots/titanium" }, "size": "large", "weight": "medium" }
```

---

## [D-4] `fuel` —— 燃料

### D-4.1 基本信息

| 项目 | 值 |
| --- | --- |
| 数据类 | `net.dries007.tfc.util.data.Fuel`（record），实现 `IRecipePredicate<ItemStack>` |
| 管理器 | `Fuel.MANAGER` |
| 注册路径 | `tfc:fuel` → 目录 `data/*/tfc/fuel/**` |
| 同步 | 是 |
| 真实文件数 | 50 个（含 `groundcover`、`ore` 子目录） |

**来源**：`net/dries007/tfc/util/data/Fuel.java` L36-L46。

### D-4.2 字段表

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

### D-4.3 真实 JSON 样例

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

### D-4.4 运行时如何被读取

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

### D-4.5 附属模组写法示例

```json
// 文件：data/mymod/tfc/fuel/titanium_dust.json → ID mymod:titanium_dust
{ "ingredient": { "item": "mymod:titanium_dust" }, "duration": 2400, "temperature": 1800.0, "purity": 1.0 }
```

---

## [D-5] `fluid_heat` —— 流体热学属性

### D-5.1 基本信息

| 项目 | 值 |
| --- | --- |
| 数据类 | `net.dries007.tfc.util.data.FluidHeat`（record） |
| 管理器 | `FluidHeat.MANAGER` |
| 注册路径 | `tfc:fluid_heat` → 目录 `data/*/tfc/fluid_heat/**` |
| 同步 | 是 |
| 真实文件数 | 28 个 |

**来源**：`net/dries007/tfc/util/data/FluidHeat.java` L40-L44。

### D-5.2 字段表

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

### D-5.3 真实 JSON 样例

`data/tfc/tfc/fluid_heat/copper.json`

```json
{"fluid":"tfc:metal/copper","melt_temperature":1080.0,"specific_heat_capacity":0.008571429}
```

### D-5.4 运行时如何被读取

| API | 语义 | 来源 |
| --- | --- | --- |
| `FluidHeat.get(Fluid)` → `@Nullable` | 按流体查（内部 `IdentityHashMap<Fluid, FluidHeat> BY_FLUID`） | `FluidHeat.java` L51-L54 |
| `FluidHeat.getOrUnknown(FluidStack)` | 查不到时返回 `unknown()` 定义，绝不返回 null | 同上 L56-L58 |
| `FluidHeat.unknown()` | 返回 `tfc:unknown` 定义（`MANAGER.getOrThrow(UNKNOWN_ID)`） | 同上 L60-L62 |
| `FluidHeat.heatCapacity(float mB)` | `specific_heat_capacity * mB` | 同上 L72-L74 |

**重要**：`UNKNOWN_ID = Helpers.identifier("unknown")`（L43），因此 `data/tfc/tfc/fluid_heat/unknown.json` **必须是存在且定义有效的**，否则 `Manager.getOrThrow` 在 `updateCache()`（L64-L70）里抛异常。实测 jar 中该文件存在（同目录还有 `unknown` 之外的 27 个金属流体）。

调用点实测：`net/dries007/tfc/common/blockentities/CrucibleBlockEntity.java:256/312/337/370`、`net/dries007/tfc/common/component/mold/Mold.java:43/82`、`Mold.java` 的 `Vessel`、`net/dries007/tfc/client/screen/MoldLikeAlloyScreen.java:42`。

### D-5.5 附属模组写法示例

```json
// 文件：data/mymod/tfc/fluid_heat/titanium.json → ID mymod:titanium
{ "fluid": "mymod:metal/titanium", "melt_temperature": 1668.0, "specific_heat_capacity": 0.0092 }
```

---

## [D-6] `deposit` —— 淘洗沉积物（矿砂）

### D-6.1 基本信息

| 项目 | 值 |
| --- | --- |
| 数据类 | `net.dries007.tfc.util.data.Deposit`（record），实现 `IRecipePredicate<ItemStack>` |
| 管理器 | `Deposit.MANAGER` |
| 注册路径 | `tfc:deposit` → 目录 `data/*/tfc/deposit/**` |
| 同步 | 是 |
| 真实文件数 | 84 个，分 4 个子目录：`cassiterite`(21)、`native_copper`(21)、`native_gold`(21)、`native_silver`(21) |

**来源**：`net/dries007/tfc/util/data/Deposit.java` L45-L50。

### D-6.2 字段表

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

### D-6.3 真实 JSON 样例

`data/tfc/tfc/deposit/native_copper/granite.json`

```json
{"ingredient":{"item":"tfc:deposit/native_copper/granite"},"loot_table":"tfc:deposit/native_copper_granite","model_stages":["tfc:item/pan/native_copper/granite_full","tfc:item/pan/native_copper/granite_half","tfc:item/pan/native_copper/result"]}
```

### D-6.4 运行时如何被读取

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

### D-6.5 附属模组写法示例

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

## [D-7] `knapping_type` —— 打制类型

### D-7.1 基本信息

| 项目 | 值 |
| --- | --- |
| 数据类 | `net.dries007.tfc.util.data.KnappingType`（record），实现 `IRecipePredicate<ItemStack>` |
| 管理器 | `KnappingType.MANAGER` |
| 注册路径 | `tfc:knapping_type` → 目录 `data/*/tfc/knapping_type/**` |
| 同步 | 是 |
| 真实文件数 | 5 个（实测：`clay`、`fire_clay`、`goat_horn`、`leather`、`rock`） |

**来源**：`net/dries007/tfc/util/data/KnappingType.java` L43-L47。

> 说明：任务书给出的清单里统计为 6 个，实测解压目录 `jar-extract/data/tfc/tfc/knapping_type/` 只有上述 5 个 `.json`。第 6 个可能是 `tfc:clay` 之外的扩展或统计口径差异（未能核实）；已检查 `Get-ChildItem -Force` 与 `TFC.resources.txt`。

### D-7.2 字段表

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

### D-7.3 真实 JSON 样例

`data/tfc/tfc/knapping_type/rock.json`

```json
{"amount_to_consume":1,"click_sound":"tfc:item.knapping.stone","consume_after_complete":false,"has_off_texture":false,"icon":{"count":1,"id":"tfc:rock/loose/granite"},"input":{"count":2,"tag":"tfc:rock_knapping"},"spawns_particles":true}
```

### D-7.4 运行时如何被读取

| API | 语义 | 来源 |
| --- | --- | --- |
| `KnappingType.get(ItemStack)` → `@Nullable` | 按输入物品查打制类型（走 `MANAGER.getValues()` 全表遍历 + `matches`） | `KnappingType.java` L53-L56 |

调用点实测：`net/dries007/tfc/common/recipes/KnappingRecipe.java:71`、`net/dries007/tfc/util/InteractionManager.java:278`、`282`。

### D-7.5 附属模组新增打制类型

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

## [D-8] `support` —— 方块支撑（防塌陷）

### D-8.1 基本信息

| 项目 | 值 |
| --- | --- |
| 数据类 | `net.dries007.tfc.util.data.Support`（record） |
| 管理器 | `Support.MANAGER` |
| 注册路径 | `tfc:support` → 目录 `data/*/tfc/support/**` |
| 同步 | 是 |
| 真实文件数 | 1 个（`horizontal_support_beam.json`） |

**来源**：`net/dries007/tfc/util/data/Support.java` L41-L45。

### D-8.2 字段表

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

### D-8.3 真实 JSON 样例

`data/tfc/tfc/support/horizontal_support_beam.json`

```json
{"ingredient":["tfc:wood/horizontal_support/acacia","tfc:wood/horizontal_support/ash","tfc:wood/horizontal_support/aspen","tfc:wood/horizontal_support/birch","tfc:wood/horizontal_support/blackwood","tfc:wood/horizontal_support/chestnut","tfc:wood/horizontal_support/douglas_fir","tfc:wood/horizontal_support/hickory","tfc:wood/horizontal_support/kapok","tfc:wood/horizontal_support/mangrove","tfc:wood/horizontal_support/maple","tfc:wood/horizontal_support/oak","tfc:wood/horizontal_support/palm","tfc:wood/horizontal_support/pine","tfc:wood/horizontal_support/rosewood","tfc:wood/horizontal_support/sequoia","tfc:wood/horizontal_support/spruce","tfc:wood/horizontal_support/sycamore","tfc:wood/horizontal_support/white_cedar","tfc:wood/horizontal_support/willow"],"support_down":2,"support_horizontal":4,"support_up":2}
```

### D-8.4 运行时如何被读取

| API | 语义 | 来源 |
| --- | --- | --- |
| `Support.get(BlockState)` → `@Nullable` | 按方块状态查支撑定义（`IndirectHashCollection<Block, Support> CACHE`） | `Support.java` L91-L98 |
| `Support.isSupported(BlockGetter, BlockPos)` | 该位置是否被支撑 | 同上 L77-L85 |
| `Support.findUnsupportedPositions(BlockGetter, BlockPos, BlockPos)` | 返回某区域中所有不受支撑的位置（塌陷判定） | 同上 L52-L75 |
| `Support.updateMaximumSupportRange()` | 重算全局最大支持范围 `RANGE` | 同上 L100-L110 |
| `Support.getSupportCheckRange()` | 取全局最大范围 | 同上 L48-L50 |

**关键约束**：塌陷搜索范围由**所有 support 定义的最大值**决定（`updateMaximumSupportRange`），所以写一个超大 `support_horizontal` 会显著增大塌陷检测开销。

### D-8.5 附属模组写法示例

```json
// 文件：data/mymod/tfc/support/steel_frame.json → ID mymod:steel_frame
{ "ingredient": { "tag": "mymod:steel_frames" }, "support_up": 3, "support_down": 3, "support_horizontal": 6 }
```

---

## [D-9] `fertilizer` —— 肥料

### D-9.1 基本信息

| 项目 | 值 |
| --- | --- |
| 数据类 | `net.dries007.tfc.util.data.Fertilizer`（record） |
| 管理器 | `Fertilizer.MANAGER` |
| 注册路径 | `tfc:fertilizer` → 目录 `data/*/tfc/fertilizer/**` |
| 同步 | 是 |
| 真实文件数 | 10 个（含 `food`、`groundcover`、`powder` 子目录） |

**来源**：`net/dries007/tfc/util/data/Fertilizer.java` L37-L41。

### D-9.2 字段表

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

### D-9.3 真实 JSON 样例（实测 10 个全部）

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

### D-9.4 运行时如何被读取

| API | 语义 | 来源 |
| --- | --- | --- |
| `Fertilizer.get(ItemStack)` → `@Nullable` | 按物品查肥料（`CACHE` 按 Item 索引后逐个 `ingredient.test`） | `Fertilizer.java` L43-L50 |
| `Fertilizer.getNutrient(FarmlandBlockEntity.NutrientType)` | 按养分类型取值（`NITROGEN`/`PHOSPHOROUS`/`POTASSIUM`） | 同上 L52-L59 |

调用点实测：`net/dries007/tfc/ForgeEventHandler.java:1157`、`net/dries007/tfc/client/ClientForgeEventHandler.java:314`、`net/dries007/tfc/common/blocks/crop/CropHelpers.java:175`。

### D-9.5 附属模组写法示例

```json
// 文件：data/mymod/tfc/fertilizer/powder/fish_meal.json → ID mymod:fish_meal
{ "ingredient": { "item": "mymod:powder/fish_meal" }, "nitrogen": 0.3, "phosphorus": 0.2 }
```

---

## [D-10] `lamp_fuel` —— 灯具燃料

### D-10.1 基本信息

| 项目 | 值 |
| --- | --- |
| 数据类 | `net.dries007.tfc.util.data.LampFuel`（record） |
| 管理器 | `LampFuel.MANAGER` |
| 注册路径 | `tfc:lamp_fuel` → 目录 `data/*/tfc/lamp_fuel/**` |
| 同步 | 是 |
| 真实文件数 | 4 个（`canola_oil`、`lava`、`olive_oil`、`tallow`） |

**来源**：`net/dries007/tfc/util/data/LampFuel.java` L38-L42。

### D-10.2 字段表

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

### D-10.3 真实 JSON 样例（实测 4 个全部）

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

### D-10.4 运行时如何被读取

| API | 语义 | 来源 |
| --- | --- | --- |
| `LampFuel.get(Fluid, BlockState)` → `@Nullable` | 按流体 + 灯具方块状态查 | `LampFuel.java` L44-L51 |

调用点实测：`net/dries007/tfc/common/blockentities/LampBlockEntity.java:54`（构造流体罐校验器）、`:66`（tick 中查燃料）、`net/dries007/tfc/common/items/LampBlockItem.java:56`（放置时校验）。

### D-10.5 附属模组写法示例

```json
// 文件：data/mymod/tfc/lamp_fuel/kerosene.json → ID mymod:kerosene
{ "fluid": { "fluid": "mymod:kerosene" }, "lamps": "#tfc:lamps", "burn_rate": 10000 }
```

---

## [D-11] `drinkable` —— 可饮用流体

### D-11.1 基本信息

| 项目 | 值 |
| --- | --- |
| 数据类 | `net.dries007.tfc.util.data.Drinkable`（record） |
| 管理器 | `Drinkable.MANAGER` |
| 注册路径 | `tfc:drinkable` → 目录 `data/*/tfc/drinkable/**` |
| 同步 | 是 |
| 真实文件数 | 5 个（`alcohol`、`milk`、`salt_water`、`vinegar`、`water`） |

**来源**：`net/dries007/tfc/util/data/Drinkable.java` L77-L81。

### D-11.2 字段表

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

### D-11.3 真实 JSON 样例（实测 5 个全部）

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

### D-11.4 运行时如何被读取

| API | 语义 | 来源 |
| --- | --- | --- |
| `Drinkable.get(Fluid)` → `@Nullable` | 按流体查饮用定义 | `Drinkable.java` L85-L92 |
| `Drinkable.attemptDrink(Level, Player, boolean)` | 玩家对着流体源右键时的整体流程 | 同上 L94-L114 |
| `drinkable.onDrink(Player, int mB)` | 应用食物数据与效果 | 同上 L130-L141 |

固定常量：`HAND_DRINK_MB = 25`、`JUG_DRINK_MB = 100`（L82-L83）。

调用点实测：`net/dries007/tfc/common/items/GlassBottleItem.java:73/107`、`net/dries007/tfc/common/items/JugItem.java:64/98`、`net/dries007/tfc/util/SelfTests.java:299`。

### D-11.5 附属模组写法示例

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

## [D-12] `item_damage_resistance` —— 物品物理抗性

### D-12.1 基本信息

| 项目 | 值 |
| --- | --- |
| 数据类 | `net.dries007.tfc.util.data.ItemDamageResistance`（record），实现 `IRecipePredicate<ItemStack>` |
| 管理器 | `ItemDamageResistance.MANAGER` |
| 注册路径 | `tfc:item_damage_resistance` → 目录 `data/*/tfc/item_damage_resistance/**` |
| 同步 | 是 |
| 真实文件数 | 11 个（各金属护甲 1 个） |

**来源**：`net/dries007/tfc/util/data/ItemDamageResistance.java` L35-L40。

### D-12.2 字段表

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

### D-12.3 真实 JSON 样例

`data/tfc/tfc/item_damage_resistance/copper_armor.json`

```json
{"crushing":10.0,"ingredient":[{"item":"tfc:metal/helmet/copper"},{"item":"tfc:metal/chestplate/copper"},{"item":"tfc:metal/greaves/copper"},{"item":"tfc:metal/boots/copper"}],"piercing":10.0,"slashing":6.25}
```

### D-12.4 运行时如何被读取

| API | 语义 | 来源 |
| --- | --- | --- |
| `ItemDamageResistance.get(ItemStack)` → `@Nullable` | 按物品查抗性 | `ItemDamageResistance.java` L42-L45 |

调用点实测：`net/dries007/tfc/util/PhysicalDamageType.java:132`（唯一的消费点）。

### D-12.5 附属模组写法示例

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

## [D-13] `entity_damage_resistance` —— 实体物理抗性

### D-13.1 基本信息

| 项目 | 值 |
| --- | --- |
| 数据类 | `net.dries007.tfc.util.data.EntityDamageResistance`（record） |
| 管理器 | `EntityDamageResistance.MANAGER` |
| 注册路径 | `tfc:entity_damage_resistance` → 目录 `data/*/tfc/entity_damage_resistance/**` |
| 同步 | **否**（构造时只传了 `CODEC`） |
| 真实文件数 | 2 个（`skeletons`、`zombies`） |

**来源**：`net/dries007/tfc/util/data/EntityDamageResistance.java` L32-L34。

### D-13.2 字段表

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

### D-13.3 真实 JSON 样例

`data/tfc/tfc/entity_damage_resistance/zombies.json`

```json
{"crushing":50.0,"entity":"minecraft:zombies","piercing":-25.0}
```

（注意 `slashing` 缺省 → 0.0）

### D-13.4 运行时如何被读取

| API | 语义 | 来源 |
| --- | --- | --- |
| `EntityDamageResistance.get(Entity)` → `@Nullable` | 全表遍历 + `Helpers.isEntity(entity, resist.entity)` tag 判定 | `EntityDamageResistance.java` L36-L43 |

调用点实测：`net/dries007/tfc/util/PhysicalDamageType.java:67`。

### D-13.5 附属模组写法示例

```json
// 文件：data/mymod/tfc/entity_damage_resistance/titans.json → ID mymod:titans
{ "entity": "mymod:titans", "piercing": -50.0, "crushing": 25.0 }
// 同时需 data/mymod/tags/entity_type/titans.json: { "values": ["mymod:titan"] }
```

---

## [D-14] `climate_range` —— 作物/植物气候需求

### D-14.1 基本信息

| 项目 | 值 |
| --- | --- |
| 数据类 | `net.dries007.tfc.util.climate.ClimateRange`（record） |
| 管理器 | `ClimateRange.MANAGER` |
| 注册路径 | `tfc:climate_range` → 目录 `data/*/tfc/climate_range/**` |
| 同步 | 是 |
| 真实文件数 | 49 个，分 `crop`（29）与 `plant`（20）两个子目录 |

**来源**：`net/dries007/tfc/util/climate/ClimateRange.java` L27-L31。

### D-14.2 字段表

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

### D-14.3 真实 JSON 样例

`data/tfc/tfc/climate_range/crop/barley.json`

```json
{"max_hydration":70,"max_temperature":23.0,"min_hydration":10,"min_temperature":-7.0}
```

实测 `plant` 子目录 20 个文件：`banana_tree`、`blackberry_bush`、`blueberry_bush`、`bunchberry_bush`、`cherry_tree`、`cloudberry_bush`、`cranberry_bush`、`elderberry_bush`、`gooseberry_bush`、`green_apple_tree`、`lemon_tree`、`olive_tree`、`orange_tree`、`peach_tree`、`plum_tree`、`raspberry_bush`、`red_apple_tree`、`snowberry_bush`、`strawberry_bush`、`wintergreen_berry_bush`。

### D-14.4 运行时如何被读取

| API | 语义 | 来源 |
| --- | --- | --- |
| `ClimateRange.MANAGER.get(id)` / `getOrThrow(id)` | 取定义 | `ClimateRange.java` L30；`DataManager.java` L82-L94 |
| `range.checkBoth(hydration, temperature, allowWiggle)` | 综合判定 | `ClimateRange.java` L59-L61 |
| `range.getMinHydration(allowWiggle)` 等 | 取值 | 同上 L33-L47 |

调用点实测（部分）：`net/dries007/tfc/common/blocks/crop/CropBlock.java:169/208`、`DeadCropBlock.java:69`、`net/dries007/tfc/common/blocks/plant/fruit/BananaPlantBlock.java:114/188`、`FruitBlocks.java:100/132`、`FruitTreeBranchBlock.java:53`。

### D-14.5 附属模组写法示例

```json
// 文件：data/mymod/tfc/climate_range/crop/titanium_herb.json → ID mymod:crop/titanium_herb
{ "min_hydration": 30, "max_hydration": 90, "hydration_wiggle_range": 5, "min_temperature": 5.0, "max_temperature": 35.0, "temperature_wiggle_range": 2.0 }
```

---

## [D-15] `fauna` —— 动物生成条件

### D-15.1 基本信息

| 项目 | 值 |
| --- | --- |
| 数据类 | `net.dries007.tfc.common.entities.Fauna`（record） |
| 管理器 | `Fauna.MANAGER` |
| 注册路径 | `tfc:fauna` → 目录 `data/*/tfc/fauna/**` |
| 同步 | **否**（构造时只传了 `CODEC`） |
| 真实文件数 | 77 个（无子目录） |

**来源**：`net/dries007/tfc/common/entities/Fauna.java` L25-L27。

**关键机制**：`Fauna` 的 **ID 必须与实体类型的 `ResourceLocation` 一致**。`Faunas.register`（`net/dries007/tfc/common/entities/Faunas.java`）用 `Fauna.MANAGER.getReference(entity.getId())` 绑定，例如实体 `tfc:cod` → 数据文件 ID `tfc:cod`。

### D-15.2 字段表

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

### D-15.3 真实 JSON 样例

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

### D-15.4 运行时如何被读取

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

### D-15.5 附属模组新增一个可生成动物

需要 4 步：注册实体（Java）→ 写 `data/<modid>/tfc/fauna/<entity_path>.json`（**ID 必须等于实体 ID**）→ 调用 `Faunas.registerAnimal`/`registerFish` 等同等方法（Java）→ 在 `RegisterSpawnPlacementsEvent` 中注册。示例数据文件：

```json
// 实体 mymod:titan 对应的文件：data/mymod/tfc/fauna/titan.json → ID mymod:titan
{ "chance": 20, "min_temperature": -20.0, "max_temperature": 10.0, "solid_ground": true, "max_brightness": 7 }
```

---

## [D-16] `worldgen`（`rock_settings`）—— 岩石方块映射（数据包注册表）

### D-16.1 基本信息

| 项目 | 值 |
| --- | --- |
| 数据类 | `net.dries007.tfc.world.settings.RockSettings` |
| 加载机制 | **数据包注册表**（不是 `DataManager`） |
| 注册调用 | `net/dries007/tfc/TerraFirmaCraft.java` L238：`event.dataPackRegistry(RockSettings.KEY, RockSettings.CODEC)` |
| 注册路径 | `tfc:worldgen/rock_settings` → 目录 `data/*/tfc/worldgen/rock_settings/**` |
| 真实文件数 | 21 个（每个岩石类型 1 个） |

**来源**：`net/dries007/tfc/TerraFirmaCraft.java:238`、`net/dries007/tfc/world/settings/RockSettings.java`。

### D-16.2 字段表（依真实 JSON 实测）

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

### D-16.3 真实 JSON 样例

`data/tfc/tfc/worldgen/rock_settings/granite.json`

```json
{"cobble":"tfc:rock/cobble/granite","gravel":"tfc:rock/gravel/granite","hardened":"tfc:rock/hardened/granite","karst":false,"loose":"tfc:rock/loose/granite","mafic":false,"mossy_loose":"tfc:rock/mossy_loose/granite","raw":"tfc:rock/raw/granite","sand":"tfc:sand/yellow","sandstone":"tfc:raw_sandstone/yellow","spike":"tfc:rock/spike/granite"}
```

实测 21 个文件：`andesite`、`basalt`、`chalk`、`chert`、`claystone`、`conglomerate`、`dacite`、`diorite`、`dolomite`、`gabbro`、`gneiss`、`granite`、`limestone`、`marble`、`phyllite`、`quartzite`、`rhyolite`、`schist`、`shale`、`slate`、`tuff`。

### D-16.4 运行时如何被读取

| API/字段 | 语义 | 来源 |
| --- | --- | --- |
| `ChunkGeneratorExtension.rockLayerSettings()` | 取岩层设置 | `net/dries007/tfc/world/ChunkGeneratorExtension.java:41-42` |
| `TFCChunkGenerator` 的地表构建 | 用 `rockLayerSettings()` 生成地表 | `net/dries007/tfc/world/TFCChunkGenerator.java:550` |
| `ChunkDataGenerator.generateRock(...)` / `generateSurfaceRock(x,z)` | 逐格生成岩石 | `net/dries007/tfc/world/chunkdata/ChunkDataGenerator.java:34-38` |
| `RegionChunkDataGenerator` | 持有 `RockLayerSettings` 并驱动生成 | `net/dries007/tfc/world/chunkdata/RegionChunkDataGenerator.java:51/66-68` |

### D-16.5 附属模组新增岩石

因为它是**数据包注册表**，写法与 `DataManager` 数据不同：

1. 在 `data/<modid>/tfc/worldgen/rock_settings/<name>.json` 放定义（ID 为 `<modid>:<name>`）。
2. 数据包注册表**不参与 tag 合并**，同名 ID 由数据包优先级决定完整覆盖（整条替换，不做字段合并）。
3. 使用该岩石需要在 worldgen（`rock_layer` / 区域定义）中引用；TFC 的岩层分布逻辑位于 `net/dries007/tfc/world/region/` 与 `net/dries007/tfc/world/rocklayer/`，通过 `RegionGenerator`/`RockLayerSettings` 驱动（来源：`net/dries007/tfc/world/chunkdata/RegionChunkDataGenerator.java` L51/L66-L68 持有并构造 `RockLayerSettings`）。岩层分布数据本身是否可通过 JSON 增加，**未能核实**（已检查 `net/dries007/tfc/world/` 下文件列表、`data/tfc/worldgen/` 子目录清单、`data/tfc/tfc/worldgen/` 内容）。

---

## [D-17] 新增/覆盖数据的通用做法（速查）

1. **目录**：永远写 `data/<你的modid>/tfc/<kind>/...`。第一个 `tfc` 段是常量，与命名空间无关。
2. **ID**：`<你的modid>:<去掉 kind 后的相对路径>`。子目录会进入 ID（`mymod:metal/ingot`）。
3. **不要试图覆盖 `tfc:` 命名空间下的 ID**：`DataManager` 用 `ImmutableMap.Builder`，重复 key 抛异常（`DataManager.java` L155-L160），两个数据包写同一 ID 会冲突/报错。
4. **优先"新增 + tag"**：例如通过 `item_heat` 的 tag ingredient 一次性覆盖你所有 `c:ingots/mymetal`，而不是逐个物品写定义。
5. **同步性**：只有带 `STREAM_CODEC` 的数据会同步到客户端。`entity_damage_resistance` 与 `fauna` 不同步，其效果只在服务端生效；若你需要客户端 tooltip，请用同步数据。
6. **数据包注册表**（目前只有 `tfc:worldgen/rock_settings`）不能通过 tag 合并，必须整条提供。
7. **校验**：加载失败的条目会在日志中打印 `"<kind> '<id>' failed to parse. ..."`（`DataManager.java` L162-L165），并且调用 `SelfTests.reportExternalError()`；开发期务必看服务器日志。
