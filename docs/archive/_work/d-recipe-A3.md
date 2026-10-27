## 组 A3 覆盖范围

本文组负责 TerraFirmaCraft 4.2.10（MC 1.21.1 / NeoForge 21.1.248）中 6 种配方 JSON 类型的源码级字段考证。

| 编号 | type id | 实现类全名 | 序列化器注册 | 数据目录（jar 内） | 真实文件数 |
| --- | --- | --- | --- | --- | --- |
| R-12 | `tfc:heating` | `net.dries007.tfc.common.recipes.HeatingRecipe` | `TFCRecipeSerializers` 第 61 行 `register("heating", HeatingRecipe.CODEC, HeatingRecipe.STREAM_CODEC)` | `data/tfc/recipe/heating/**` | 883 |
| R-13 | `tfc:quern` | `net.dries007.tfc.common.recipes.QuernRecipe` | 第 62 行 `register("quern", QuernRecipe.CODEC, QuernRecipe.STREAM_CODEC)` | `data/tfc/recipe/quern/**` | 89 |
| R-14 | `tfc:scraping` | `net.dries007.tfc.common.recipes.ScrapingRecipe` | 第 63 行 `register("scraping", ScrapingRecipe.CODEC, ScrapingRecipe.STREAM_CODEC)` | `data/tfc/recipe/scraping/**` | 7 |
| R-15 | `tfc:knapping` | `net.dries007.tfc.common.recipes.KnappingRecipe` | 第 67 行 `register("knapping", KnappingRecipe.CODEC, KnappingRecipe.STREAM_CODEC)` | `data/tfc/recipe/knapping/**` | 101 |
| R-16 | `tfc:glassworking` | `net.dries007.tfc.common.recipes.GlassworkingRecipe` | 第 78 行 `register("glassworking", GlassworkingRecipe.CODEC, GlassworkingRecipe.STREAM_CODEC)` | `data/tfc/recipe/glassworking/**` | 60 |
| R-17 | `tfc:sewing` | `net.dries007.tfc.common.recipes.SewingRecipe` | 第 79 行 `register("sewing", SewingRecipe.CODEC, SewingRecipe.STREAM_CODEC)` | `data/tfc/recipe/sewing/**` | 25 |

### 本组共同事实（源码依据）

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

## A3 共享依赖：ItemStackProvider / ItemStackModifier / Ingredient / ItemStack

本组 6 种类型中，R-12 用到 `ItemStackProvider` + `FluidStack` + `ItemStack`，R-13、R-14 用到 `ItemStackProvider`，
R-15、R-16、R-17 用的却是**裸 `ItemStack`**。差异必须在各节字段表中写明。

### A3.1 ItemStackProvider 的两种 JSON 形态

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

### A3.2 ItemStackModifier 注册表全清单

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

### A3.3 TFC 自定义 Ingredient 类型

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

### A3.4 ItemStack 的 JSON 写法（1.21 组件化格式）

1.21 中物品栈为 `{"id": "...", "count": N, "components": {...}}`，`count` 缺省为 1。实例见
`data/tfc/recipe/knapping/call_goat_horn_goat_horn.json`：

```json
{"type":"tfc:knapping","knapping_type":"tfc:goat_horn","pattern":["#####","#   #","# ###","## ##","#####"],"result":{"components":{"minecraft:instrument":"minecraft:call_goat_horn"},"count":1,"id":"minecraft:goat_horn"}}
```

`FluidStack` 的 JSON 写法为 `{"amount": N, "id": "tfc:metal/copper"}`。

---

## [R-12] tfc:heating —— 加热 / 熔炼

### R-12.1 基本信息

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

### R-12.2 CODEC 逐字段考证

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

### R-12.3 字段表

字段全部来自 `HeatingRecipe` 自身（该类**不继承** `ItemRecipe`，因此没有父类字段需要合并）。

| 字段名 | 类型 | 必需/可选 | 默认值 | 语义 |
| --- | --- | --- | --- | --- |
| `ingredient` | `Ingredient` | **必需** | 无 | 被加热的物品。支持 `{"item":...}`、`{"tag":...}`、物品数组、以及 TFC 自定义 Ingredient（`tfc:and` 等）。`matches(ItemStack)` 即 `ingredient.test(input)`（第 78-80 行） |
| `result_item` | `ItemStackProvider` | 可选 | `ItemStackProvider.empty()`（空 provider，产物为空物品） | 加热后得到的**固体产物**。可为纯 `ItemStack`，或 `{"stack":..., "modifiers":[...]}`。产出走 `assembleItem(input)`（第 82-89 行），并在输入带热组件时**继承输入温度**（`HeatCapability.setTemperature(outputStack, inputHeat.getTemperature())`） |
| `result_fluid` | `FluidStack` | 可选 | `FluidStack.EMPTY`（空流体） | 加热后熔出的**流体产物**，写法 `{"amount":100,"id":"tfc:metal/copper"}`。产出走 `assembleFluid(inputStack)`（第 91-97 行） |
| `temperature` | `float` | **必需** | 无 | 触发温度阈值。判定见 `isValidTemperature(float)`（第 113-115 行）：`temperatureIn >= this.temperature`。热源温度不低于此值时才产出 |
| `use_durability` | `boolean` | 可选 | `false` | 仅对 `result_fluid` 生效：为 `true` 时按输入物品剩余耐久比例削减流体产量，见第 93-95 行 `outputFluid.setAmount(Mth.floor(outputFluid.getAmount() * (1 - damage/maxDamage)))` |

### R-12.4 校验、默认值与"不存在"的字段

- **`chance` 字段不存在。** `HeatingRecipe` 的 CODEC 中没有任何名为 `chance` 的字段，构造器也没有该参数。
  概率产出只能通过 `result_item.modifiers` 里的 `tfc:chance` modifier 表达（见 A3.2 与本文 R-12.6 样例 4）。
  实测：883 个文件里字符串 `"chance"` 仅出现 1 次，且位于 `modifiers` 数组内部。
- **没有 `validate(...)` / `Codec.either(...)`**：`HeatingRecipe.CODEC` 是纯 `RecordCodecBuilder.mapCodec` + 3 个 `optionalFieldOf` + 2 个 `fieldOf`，无自定义校验函数。
  这意味着"只给 `ingredient` + `temperature`、不给任何产物"是**合法的**（见 R-12.6 样例 5、6），语义为"烧毁"。
- **两个可选产物可以同时缺失，但不能同时存在吗？** CODEC 层面二者可同时给出（无 either / 无校验），但**实际数据中不存在同时给出的文件**：
  883 个文件中，143 个只有 `result_item`，738 个只有 `result_fluid`，0 个两者都有，2 个两者都无。
- `use_durability` 仅在 `result_fluid` 非空且输入物品可损毁时才有意义（第 93 行条件：
  `useDurability && !outputFluid.isEmpty() && inputStack.getMaxDamage() > 0 && inputStack.isDamageableItem()`）。实测 198 个文件写了 `"use_durability": true`。

### R-12.5 全部字段使用统计（883 文件实测）

| 组合 | 文件数 |
| --- | --- |
| 仅 `result_item` | 143 |
| 仅 `result_fluid` | 738 |
| 两者都有 | 0 |
| 两者都无（"烧毁"配方） | 2 |
| 含 `"use_durability": true` | 198 |
| `ingredient` 为 `tfc:and` 复合类型 | 56 |
| `ingredient` 顶层为物品数组 | 见 `hanging_sign/` 下 11 个文件等 |

### R-12.6 真实 JSON 样例

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

### R-12.7 `temperature` 与 `data/tfc/tfc/item_heat/` 的配合

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

### R-12.8 游戏内触发条件（全部调用点，逐一列出）

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

### R-12.9 注意事项

1. `HeatingRecipe` **不继承 `ItemRecipe`**，也不实现 `ISimpleRecipe` 的默认 `matches(RecipeInput, Level)`；
   `INoopInputRecipe.matches(NoopInput, Level)` 被 `@Contract("_, _ -> fail")` 标注为抛 `UnsupportedOperationException`（`INoopInputRecipe.java:23-26`）。
   实际匹配入口是 `IRecipePredicate.matches(ItemStack)`（`HeatingRecipe.java:78-80`）。
2. `assembleStacked(ItemStack, int stackSizeCap, boolean isDisplay)`（第 99-107 行）会显式把产物数量夹到
   `min(output.count, min(output.getMaxStackSize(), stackSizeCap))`，这是 `Vessel` 用它而非 `assembleItem` 的原因。
3. `getResultItem(HolderLookup.Provider)`（第 121-124 行）返回 `outputItem.getEmptyStack()`，即**显示用的空输入产物**，
   对"烧毁"配方会返回 `ItemStack.EMPTY`。

---

## [R-13] tfc:quern —— 手推磨 / 磨盘

### R-13.1 基本信息

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

### R-13.2 CODEC 逐字段考证

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

### R-13.3 字段表

| 字段名 | 类型 | 必需/可选 | 默认值 | 语义 | 声明位置 |
| --- | --- | --- | --- | --- | --- |
| `ingredient` | `Ingredient` | **必需** | 无 | 磨的输入物品。`matches(ItemStack)` = `ingredient.test(input)`（`ItemRecipe.java:36-38`） | 父类 `ItemRecipe.ingredient` |
| `result` | `ItemStackProvider` | **必需** | 无 | 磨出的产物。`assemble(ItemStack)` = `result.getSingleStack(input)`（`ItemRecipe.java:40-42`），产物数量按输入 1 个计算 | 父类 `ItemRecipe.result` |

**没有可选字段，没有校验函数，没有 `Codec.either`。** 实测 89 个文件字段集合**全部**为 `type,ingredient,result`，无任何例外。

父子类提供的额外语义（不属于 JSON 字段，但影响行为）：
- `ItemRecipe.getResultItem(registries)`（第 44-47 行）返回 `result.getEmptyStack()`；
- `ItemRecipe.isSpecial()`（第 61-64 行）返回 `result.dependsOnInput()`，即含 `copy_food` / `copy_heat` 等 modifier 时会被标记为 special（隐藏于配方书的普通条目）；
- `ItemRecipe.getValidItems()`（第 49-51 行）= `RecipeHelpers.itemKeys(ingredient)`，供 `CACHE` 建索引。

### R-13.4 真实 JSON 样例

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

### R-13.5 游戏内触发条件

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

## [R-14] tfc:scraping —— 刮制（皮革 / 纸）

### R-14.1 基本信息

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

### R-14.2 CODEC 逐字段考证

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

### R-14.3 字段表

| 字段名 | 类型 | 必需/可选 | 默认值 | 语义 | 声明位置 |
| --- | --- | --- | --- | --- | --- |
| `ingredient` | `Ingredient` | **必需** | 无 | 待刮物品。`matches(ItemStack)` 继承自 `ItemRecipe.java:36-38` | 父类 `ItemRecipe.ingredient` |
| `result` | `ItemStackProvider` | **必需** | 无 | 刮完后的**主产物**（替换槽内物品）。`assemble(input)` = `result.getSingleStack(input)`（`ItemRecipe.java:40-42`） | 父类 `ItemRecipe.result` |
| `input_texture` | `ResourceLocation` | **必需** | 无 | 刮制界面上"未刮"状态显示的贴图。`getInputTexture()`（第 62-64 行） | 本类 `inputTexture`（第 46 行） |
| `output_texture` | `ResourceLocation` | **必需** | 无 | 刮制界面上"已刮"状态显示的贴图。`getOutputTexture()`（第 66-68 行） | 本类 `outputTexture`（第 47 行） |
| `result_item` | `ItemStackProvider` | 可选 | `ItemStackProvider.empty()`（无额外掉落） | **额外掉落**（不是主产物！）。`getExtraDrop()`（第 70-72 行）。在刮制完成时由 `ScrapingBlockEntity` 单独 `Helpers.spawnItem` 抛出 | 本类 `extraDrop`（第 48 行），**字段名与 Java 字段名不一致** |

**没有 `validate(...)`，没有 `Codec.either(...)`。**

### R-14.4 真实 JSON 样例（7 个文件中有代表性的 4 个）

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

### R-14.5 游戏内触发条件（重点：不是"刮刀物品"，是**刀类工具**）

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

## [R-15] tfc:knapping —— 打制（石器 / 陶器 / 皮革 / 山羊角）

### R-15.1 基本信息

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

### R-15.2 CODEC 逐字段考证

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

### R-15.3 字段表（注意 `pattern` / `default_on` 来自 `KnappingPattern`）

| 字段名 | 类型 | 必需/可选 | 默认值 | 语义 | 来源 |
| --- | --- | --- | --- | --- | --- |
| `knapping_type` | `DataManager.Reference<KnappingType>`（JSON 为资源位置字符串） | **必需** | 无 | 打制类别。必须是 `data/tfc/tfc/knapping_type/` 下已存在的 id。运行时不匹配则配方不命中 | `KnappingRecipe` 第 52 行字段 / CODEC 第 50 行 |
| `pattern` | `List<String>`，长度 **1..5**（`Codec.STRING.listOf(1, 5)`） | **必需** | 无 | 打制图案：逐行字符串。行内**非空格字符 = 需要敲掉的格**，空格 = 保留。字符本身不限（数据中统一用 `#`）；判定只比较"是否空格"（`KnappingPattern.java:63` `pattern.set(r*width+c, row.charAt(c) != ' ')`） | `KnappingPattern.CODEC`，平铺进本类 JSON |
| `default_on` | `boolean`（`Optional<Boolean>`） | **条件必需** | 无（`Optional` 空） | 图案**不是 5×5** 时**必须**显式给出，否则报错 `default_on is required if the pattern is not 5x5`（`KnappingPattern.java:53-55`）。语义：图案外圈格子的期望状态（`false` = 图案外的格子必须保持未敲掉） | `KnappingPattern.CODEC`，平铺进本类 JSON |
| `ingredient` | `Optional<Ingredient>` | 可选 | `Optional.empty()`（不限制） | 额外的物品限制。缺省时只要 `knapping_type` 与图案匹配即可（`matchesItem` 第 74-76 行：`ingredient.isEmpty() \|\| ingredient.get().test(stack)`） | `KnappingRecipe` 第 54 行字段 |
| `result` | **`ItemStack`（裸物品栈，不是 `ItemStackProvider`！）** | **必需** | 无 | 打制成品。`assemble()` = `result.copy()`（第 78-80 行）——**无 modifier 机制** | `KnappingRecipe` 第 55 行字段 |

### R-15.4 `pattern` 的严格约束（逐条对应源码）

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

### R-15.5 `knapping_type` 真实清单（`data/tfc/tfc/knapping_type/`，共 5 个文件）

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

### R-15.6 真实 JSON 样例

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

### R-15.7 游戏内触发条件

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

### R-15.8 与 KnappingType 的耦合（简述，另有专章）

- `KnappingRecipe.knappingType` 是 `DataManager.Reference<KnappingType>`，**运行时对象同一性比较**（`==`，第 71 行）；
- `KnappingType` 双向参与：
  - **正向**：决定界面输入物品与数量、音效、粒子、`consume_after_complete`、贴图；
  - **反向**：`InteractionManager` 第 278 行用所有 `KnappingType` 的 `inputItem().ingredient()` 生成"哪些物品能打开打制界面"的索引；
  - `KnappingType.get(ItemStack)`（第 53-56 行）= `RecipeHelpers.getRecipe(MANAGER.getValues(), stack)`，按 `inputItem` 匹配。
- 因此**新增 knapping 配方时必须先有对应的 `knapping_type` 数据文件**（或复用现有 5 个之一），否则 `knapping_type` 引用无法解析。

---

## [R-16] tfc:glassworking —— 玻璃加工

### R-16.1 基本信息

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

### R-16.2 CODEC 逐字段考证

`GlassworkingRecipe.java` 第 49 行：

```java
public static final MapCodec<GlassworkingRecipe> CODEC = RecordCodecBuilder.mapCodec(i -> i.group(
    GlassOperation.REGISTRY.byNameCodec().listOf().fieldOf("operations").forGetter(c -> c.operations),
    Ingredient.CODEC.fieldOf("batch").forGetter(c -> c.batchItem),
    ItemStack.CODEC.fieldOf("result").forGetter(c -> c.resultItem)
).apply(i, GlassworkingRecipe::new));
```

`STREAM_CODEC`（第 50 行）：`ByteBufCodecs.registry(GlassOperation.KEY).apply(ByteBufCodecs.list())` + `Ingredient.CONTENTS_STREAM_CODEC` + `ItemStack.STREAM_CODEC`。

### R-16.3 字段表

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

### R-16.4 玻璃操作的表示方式与字母表

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

### R-16.5 真实 JSON 样例

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

### R-16.6 游戏内触发条件

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

## [R-17] tfc:sewing —— 缝纫

### R-17.1 基本信息

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

### R-17.2 CODEC 逐字段考证

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

### R-17.3 字段表

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

### R-17.4 真实 JSON 样例

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

### R-17.5 游戏内触发条件

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

### R-17.6 注意事项

1. `SewingRecipe` 实现 `ISimpleRecipe<SewingTableContainer.Input>`，因此继承
   `canCraftInDimensions → true`、`isSpecial → true`、`getResultItem(registries) → ItemStack.EMPTY` 三个默认实现
   （`ISimpleRecipe.java` 第 19-29 行），但 `SewingRecipe` **自己覆写**了 `getResultItem`（第 124-127 行）返回 `result.copy()`。
2. 由于 `isSpecial() == true`，缝纫配方**不会出现在原版配方书**中，只在缝纫台界面与 JEI/EMI 中可见。
3. `stitches` 的 45 位 bitset 使用 `long` 存储；`getStitch(int index)`（第 103-105 行）用 `(bitset >> index & 1) == 1` 读取。
4. `getSquare(int index)`（第 107-114 行）对越界或非法字符会抛 `IllegalStateException("Sewing Recipe has invalid square at index " + index)`，
   但正常情况下已被 CODEC 的 `validate` 拦下。

---

## 附录：本组"未能核实"与已核查范围

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

### 本组核查所用文件清单

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
