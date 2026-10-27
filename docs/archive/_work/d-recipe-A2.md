# TerraFirmaCraft 4.2.10 配方 JSON 字段级考证 —— 组 A2

> 版本基准：TerraFirmaCraft-NeoForge-1.21.1-4.2.10 / Minecraft 1.21.1 / NeoForge 21.1.248
> 证据来源（全部为本地文件，无网络依赖）：
> - 反编译源码根：`moddev/src-ref/TFC-decompiled`（下文相对路径均以此为根）
> - 真实 jar 解包内容：`moddev/jar-extract`（下文"jar 内路径"以 `jar-extract` 为根）
> - 反编译产物**无参数名、无注释**（CFR 0.152 输出），但 `CODEC` 定义、record 组件、字段常量完整可读，足以逐行还原字段名与默认值。
> - 文件头的 `Could not load the following classes` 仅为 classpath 缺失提示，不影响本次考证。

---

## 组 A2 覆盖范围

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

## A2-0 通用前置：本组共享的序列化与辅助类型

### A2-0.1 配方序列化器如何被选择

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

### A2-0.2 `BlockIngredient`（R-06 / R-07 / R-08 的 `ingredient` 字段类型）

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

### A2-0.3 `result` 字段的方块状态写法（`Codecs.BLOCK_STATE`）

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

### A2-0.4 `ItemStackProvider`（R-08 的 `item_output`、R-09/R-10 的 `output_item`、`on_seal`/`on_unseal`）

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

### A2-0.5 `ItemStackModifier` 与注册表全清单

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

### A2-0.6 `TFCIngredients`：barrel 的 `input_item` 里可用的 TFC 自定义 ingredient

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

### A2-0.7 barrel 使用的两个 NeoForge 定容 ingredient

| 字段类型 | 静态 Codec | JSON 结构 | 真实样例 |
| --- | --- | --- | --- |
| `SizedIngredient` | `SizedIngredient.FLAT_CODEC` | `Ingredient` 的内容 + 可选 `count`（默认 1），即 `{"item":"..."}` / `{"tag":"..."}` / `{"type":"tfc:and","children":[...]}`，可加 `"count":N` | `{"count":1,"item":"tfc:hardened_clay"}`、`{"type":"tfc:not_rotten","count":1}` |
| `SizedFluidIngredient` | `SizedFluidIngredient.FLAT_CODEC` | `{"amount":N,"fluid":"..."}` 或 `{"amount":N,"tag":"..."}`；`amount` 必填 | `{"amount":125,"fluid":"tfc:vinegar"}`、`{"amount":250,"tag":"tfc:alcohols"}` |

**FLAT_CODEC 的含义**（本组依据）：与 `SizedIngredient.CODEC` 的"带 `ingredient`/`count` 两键包裹"形式不同，`FLAT_CODEC` 把 ingredient 内容**平铺**在同一个对象里，所以真实数据中看到的是 `{"item":..., "count":...}` 而不是 `{"ingredient":{...},"count":...}`。本次在 barrel 的 330 个文件中检索 `"input_fluid"` 内含 `"type"` 的文件数为 0（即没有使用自定义流体 ingredient 类型的实例），也未发现 `{"ingredient":...}` 包裹式写法，与 FLAT_CODEC 一致。

`count` 的可选性由真实数据证实：`clean_bowl.json`、`beer.json`、`brined.json` 等文件的 `input_item` **不写 `count`**，而 `clay_ball.json`、`mud/*.json` 等写 `"count":1`，两种都能正常工作（后者是显式写默认值）。

### A2-0.8 相关方块 tag（R-06 / R-07 的 fallback 与触发门禁）

全部定义在 `net/dries007/tfc/common/TFCTags.java:383-386`：

| 常量 | tag id | 真实 tag 文件内容（`jar-extract/data/tfc/tags/block/`） |
| --- | --- | --- |
| `CAN_TRIGGER_COLLAPSE` | `tfc:can_trigger_collapse` | `["#c:ores","#c:stones"]` |
| `CAN_START_COLLAPSE` | `tfc:can_start_collapse` | `["#c:ores","#c:stones/raw"]` |
| `CAN_COLLAPSE` | `tfc:can_collapse` | `["#c:ores","#c:stones","#c:stones/smooth","#c:stones/spike"]` |
| `CAN_LANDSLIDE` | `tfc:can_landslide` | 长名单，共 **189 项**（cobble/mossy_cobble/gravel/sand/deposit/mud/coarse_dirt/duff/clay_duff/kaolin 等，均为具体方块 id 而非 tag 引用） |

另有 `SUPPORTS_LANDSLIDE = tfc:supports_landslide`（值为 `["#tfc:farmlands","#tfc:paths"]`）与 `NOT_SOLID_SUPPORTING = tfc:not_solid_supporting`（值为 `["#c:stones/smooth"]`），它们在 `LandslideRecipe.isSupportedOnSide` 与 `CollapseRecipe.canStartCollapse` 中被读取。

---

## [R-06] tfc:collapse —— 塌方

### R-06.1 类型标识与实现类

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

### R-06.2 完整字段表

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

### R-06.3 真实 JSON 样例

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

### R-06.4 fallback 配方（无 JSON 也能塌方）

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

### R-06.5 游戏内触发条件

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

### R-06.6 塌方后的产物与实体

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

### R-06.7 与 `landslide` 的字段对照（快速索引）

| 维度 | `tfc:collapse` | `tfc:landslide` |
| --- | --- | --- |
| 父类 | `BlockRecipe` | `BlockRecipe` |
| 字段 | `ingredient`（必填）、`result`（可选） | `ingredient`（必填）、`result`（可选） |
| 是否二者字段完全相同 | **完全相同**（同一个 `BlockRecipe.codec`） | 同左 |
| 区别所在 | 语义、触发链路、fallback tag（`can_collapse`） | 语义、触发链路、fallback tag（`can_landslide`） |

也就是说：**`collapse` 与 `landslide` 在 JSON 层面无法靠字段区分，只能靠 `type` 区分。** 二者的 `result` 都用于"替换方块"，但触发它们的方块 tag 与配置项完全不同（见 R-07.5）。

---

## [R-07] tfc:landslide —— 滑坡

### R-07.1 类型标识与实现类

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

### R-07.2 完整字段表

与 `collapse` 相同，字段 100% 来自父类 `BlockRecipe` 的 `codec(...)`（`BlockRecipe.java:51-53`）——**`LandslideRecipe` 自身没有声明任何 `CODEC` 常量，也没有任何 record 组件**（`LandslideRecipe.java` 全文 143 行，只有静态方法与 `matches` 逻辑）。

| 字段名 | 类型 | 必需/可选 | 默认值 | 语义 | 来源 |
| --- | --- | --- | --- | --- | --- |
| `ingredient` | `BlockIngredient`（方块 id 数组，或方块 tag 字符串） | **必需**（`fieldOf`） | 无 | 哪些方块会滑坡。只比较方块种类（`BlockIngredient.test(BlockState)` → `test(Block)`） | `BlockRecipe.java:52` |
| `result` | `BlockState`（`Codecs.BLOCK_STATE`） | **可选**（`optionalFieldOf`） | `Optional.empty()` | 滑坡后替换成的方块；`assembleBlock` 返回 `output.orElse(input)` | `BlockRecipe.java:52`、`74-76` |

**没有其它字段。** 特别地：

- 没有 `duration` / `sound` / `target` / `direction` 之类的字段——滑坡的方向由 `LandslideRecipe.getLandslidePos(...)` 在运行时按周围支撑情况**计算**得出（见 R-07.5），而不是由 JSON 指定。
- `result` 省略时表示"方块滑动但不变形"。真实数据中 21 个文件全部写了 `result`（实际检索：21/21）。

### R-07.3 真实 JSON 样例

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

### R-07.4 fallback 配方

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

### R-07.5 游戏内触发条件与滑动方向计算

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

### R-07.6 `collapse` 与 `landslide` 的关键差异汇总（数据包作者视角）

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

## [R-08] tfc:chisel —— 凿刻

### R-08.1 类型标识与实现类

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

### R-08.2 完整字段表

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

### R-08.3 `mode` 字段的取值来源：`ChiselMode` 注册表

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

### R-08.4 真实 JSON 样例

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

### R-08.5 游戏内触发条件

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

### R-08.6 特殊辅助类在 chisel 中的可见形式

| 辅助类型 | 在 chisel JSON 中的形态 | 真实例子 |
| --- | --- | --- |
| `BlockIngredient` | `ingredient` 数组 | `["tfc:rock/raw/andesite","tfc:rock/hardened/andesite"]` |
| `Codecs.BLOCK_STATE` | `result` 字符串或对象 | `"result":"tfc:rock/smooth/andesite"` |
| `ChiselMode` 注册表 | `mode` 字符串 | `"mode":"tfc:smooth"` / `"mode":"tfc:slab"` / `"mode":"tfc:stair"` |
| `ItemStackProvider` | `item_output`（简写形式，无 modifier 实例） | `{"count":1,"id":"tfc:alabaster/bricks/black_slab"}` |

`ItemStackModifier` 在 chisel 中虽然**技术上可用**（`item_output` 就是用 `ItemStackProvider.CODEC` 解析的，因此支持 `{"modifiers":[...]}` 写法），但 TFC 自带 513 个文件**一个都没用**。第三方数据包若要用，写法与 R-09/R-10 完全相同（见 A2-0.4 / A2-0.5）。

## [R-09] tfc:barrel_sealed —— 木桶·封口配方

### R-09.1 类型标识与实现类

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

### R-09.2 完整字段表

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

### R-09.3 真实 JSON 样例

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

### R-09.4 `sound` 字段的真实用法

在 `jar-extract/data/tfc/recipe/barrel/` 全部 330 个文件中，含 `"sound"` 键的共 **4 个**：`canola_oil_cooling.json`、`olive_oil_cooling.json`、`salt_water_cooling.json`、`water_cooling.json`。经逐个核对，**这 4 个文件的 `type` 全部是 `tfc:barrel_instant`（R-10），没有任何一个是 `tfc:barrel_sealed`**——也就是说：**308 个封口配方使用了 `sound` 字段的默认值，官方数据中没有 `barrel_sealed` 的 `sound` 自定义实例**。

字段本身在两类配方中都存在（父类 `BarrelRecipe.CODEC` 定义的），第三方数据包若需要可以为 `barrel_sealed` 指定 `sound`，写法与 R-10.3 的 `water_cooling.json` 完全一致，例如：

```json
{"sound":"minecraft:block.fire.extinguish"}
```

`BarrelBlockEntity` 对 `sound` 有特殊处理（`net/dries007/tfc/common/blockentities/BarrelBlockEntity.java:192-204`）：若 `getCompleteSound() == SoundEvents.FIRE_EXTINGUISH`，则额外发送 `TFCParticles.BUBBLE` 与 `TFCParticles.STEAM` 粒子——也就是说 `sound` 字段除了音效外还兼作**粒子效果的开关**（该判定位于即时配方分支内）。

`BarrelBlockEntity` 对 `sound` 有特殊处理（`net/dries007/tfc/common/blockentities/BarrelBlockEntity.java:192-204`）：若 `getCompleteSound() == SoundEvents.FIRE_EXTINGUISH`，则额外发送 `TFCParticles.BUBBLE` 与 `TFCParticles.STEAM` 粒子——也就是说 `sound` 字段除了音效外还兼作**粒子效果的开关**。

### R-09.5 游戏内触发条件

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

### R-09.6 `barrel_sealed` 与 `barrel_instant` 的字段差异（任务书重点）

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

## [R-10] tfc:barrel_instant —— 木桶·即时配方

### R-10.1 类型标识与实现类

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

### R-10.2 完整字段表

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

### R-10.3 真实 JSON 样例

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

### R-10.4 游戏内触发条件

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

### R-10.5 特殊辅助类在 `barrel_instant` 中的可见形式

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

## [R-11] tfc:barrel_instant_fluid —— 木桶·即时流体混合配方

### R-11.1 类型标识与实现类

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

### R-11.2 完整字段表

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

### R-11.3 真实 JSON 样例

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

### R-11.4 游戏内触发条件

| # | 阶段 | 调用点（文件:行） | 关键代码 |
| --- | --- | --- | --- |
| 1 | 状态变化打标 | `BarrelBlockEntity.java:244-256` | 与 R-10 相同（`setAndUpdateSlots` / `fluidTankChanged` 置 `needsInstantRecipeUpdate`） |
| 2 | **查询顺序（关键）** | `BarrelBlockEntity.java:186-189` | `RecipeHolder instantRecipe = BarrelRecipe.get(level, TFCRecipeTypes.BARREL_INSTANT, inventory); if (instantRecipe == null) instantRecipe = BarrelRecipe.get(level, TFCRecipeTypes.BARREL_INSTANT_FLUID, inventory);` → **先查普通即时配方，查不到才查流体混合配方**；两者互斥，不会同时生效 |
| 3 | 执行 | `BarrelBlockEntity.java:190-205` | `if (instantRecipe != null) { ((BarrelRecipe) instantRecipe.value()).assembleOutputs(inventory); ... 音效与粒子 ... }` |
| 4 | 物品流体来源 | `BarrelBlockEntity.java:455-469` | `updateFluidIOSlots()` 每 5 tick 把槽 0 容器的流体**倒入桶**（注意：倒入桶后物品就变空了，因此 `added_fluid` 的匹配通常发生在"刚放进去、尚未倒空"的瞬间，或该物品的流体不能被桶接收时）。**本次未对该时序细节做运行时验证** |
| 5 | EMI 展示 | `net/dries007/tfc/compat/emi/EmiIntegration.java:234` | `basicRecipeMapping(registry, TFCRecipeTypes.BARREL_INSTANT_FLUID, EmiInstantFluidBarrelRecipe::new)` |
| 6 | JEI 展示 | `net/dries007/tfc/compat/jei/JEIIntegration.java:222` | `registry.addRecipes(INSTANT_FLUID_BARREL, JEIIntegration.recipes(TFCRecipeTypes.BARREL_INSTANT_FLUID));`；`InstantFluidBarrelRecipeCategory` 位于 `net/dries007/tfc/compat/jei/category/InstantFluidBarrelRecipeCategory.java:29-41` |

**input 容器**：`BarrelInventory`（槽 0 = 可能的流体容器/含流体物品，槽 1 = 空容器，槽 2 = 配方物品位），但 R-11 **不读 `input_item`**，它对槽 0 与槽 2 的**物品所携带的流体**做判定。

### R-11.5 三种 barrel 配方的字段对照总表

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

## 附录 A2-1：本组证据文件索引

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

## 附录 A2-2：真实数据文件索引（`moddev/jar-extract` 为根）

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

## 附录 A2-3：本次"未能核实"或存在不确定性的点

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

