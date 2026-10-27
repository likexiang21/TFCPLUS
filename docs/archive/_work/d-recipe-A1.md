# TerraFirmaCraft 4.2.10 配方 JSON 字段级考证 —— 组 A1

> 版本基准：TerraFirmaCraft-NeoForge-1.21.1-4.2.10 / Minecraft 1.21.1 / NeoForge 21.1.x
> 证据来源（全部为本地文件，无网络依赖）：
> - 反编译源码根：`moddev/src-ref/TFC-decompiled`（下文相对路径均以此为根）
> - 真实 jar 解包内容：`moddev/jar-extract`（下文"jar 内路径"以 `jar-extract` 为根）
> - 字节码交叉验证：`.minecraft/libraries/net/minecraft/client/1.21.1-20240808.144430/client-1.21.1-20240808.144430-srg.jar`（用 `javap` 读取，用于确认 Minecraft 侧 `CustomRecipe`/`CraftingRecipe` 的行为）
> - 反编译产物无参数名、无注释，但 `CODEC` 定义、record 组件、字段常量均完整可读。

## 组 A1 覆盖范围

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

## [R-01] tfc:alloy —— 合金配方

### R-01.1 类型标识与实现类

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

### R-01.2 完整字段表

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

### R-01.3 真实 JSON 样例

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

### R-01.4 游戏内触发条件

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

### R-01.5 特殊辅助类

| 辅助类 | 是否用于本类型 | 说明 |
| --- | --- | --- |
| `net.dries007.tfc.util.AlloyRange` | ✅ 核心 | `contents` 的元素类型，见 R-01.2 |
| `net.dries007.tfc.util.FluidAlloy` | ✅ 核心 | 输入/匹配载体；自身有 NBT codec：`{"amount":int,"content":{<fluid id>: double}}`（`FluidAlloy.java:71`） |
| `ItemStackProvider` / `ItemStackModifier` | ❌ | `tfc:alloy` 产物是**流体**不是物品，因此不用 Provider 体系。相关说明见附录 A1-1 |
| `TFCIngredients` | ❌ | 配方不含 `Ingredient` 字段 |
| `PotOutput` | ❌ | 属于 pot 系配方（其它组） |

`tfc:metal/unknown`（`Metal.UNKNOWN`）是「无匹配合金」的兜底流体，见 `FluidAlloy.java:164`。

---

## [R-02] tfc:anvil —— 砧板锻造配方

### R-02.1 类型标识与实现类

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

### R-02.2 完整字段表

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

### R-02.3 真实 JSON 样例

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

### R-02.4 游戏内触发条件

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

### R-02.5 特殊辅助类

| 辅助类 | 用法 |
| --- | --- |
| `net.dries007.tfc.common.recipes.outputs.ItemStackProvider` | `result` 字段类型。真实 anvil 数据只用裸 ItemStack 简写；理论上可写 `{"stack":{...},"modifiers":[...]}`，例如 `{"modifiers":[{"type":"tfc:copy_forging_bonus"}]}` 可把锻造加成写进产物（见附录 A1-1） |
| `net.dries007.tfc.common.component.forge.ForgeRule` | `rules` 元素类型；30 个枚举值 + `isConsistent` 校验 |
| `net.dries007.tfc.common.component.forge.ForgingBonus` / `ForgingBonusComponent` | `apply_bonus=true` 时由 `AnvilBlockEntity.java:279-286` 写入产物 |
| `net.dries007.tfc.config.TFCConfig.SERVER.anvilAcceptableWorkRange` | 目标值容差（`AnvilRecipe.java:152`） |
| `TFCIngredients` | `ingredient` 可用 TFC 自定义 ingredient，例如 `{"type":"tfc:heat","min":1000}`（见附录 A1-3） |

---

## [R-03] tfc:welding —— 砧板焊接配方

### R-03.1 类型标识与实现类

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

### R-03.2 完整字段表

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

### R-03.3 真实 JSON 样例

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

### R-03.4 游戏内触发条件

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

### R-03.5 特殊辅助类

| 辅助类 | 用法 |
| --- | --- |
| `net.dries007.tfc.common.recipes.outputs.ItemStackProvider` | `result` 字段类型（见附录 A1-1） |
| `net.dries007.tfc.common.component.forge.ForgingBonus` / `ForgingBonusComponent` | `bonus` 字段的运行时依赖（`ForgingBonusComponent.copy`） |
| `net.dries007.tfc.common.component.heat.HeatCapability` / `IHeat` | 焊接的**前置条件**（不是 JSON 字段）：两侧物品温度必须满足 `canWeld()`，且产物会继承较高温度（`AnvilBlockEntity.java:368-373, 378-386`） |
| `net.dries007.tfc.common.fluids` / 助焊剂 | 槽 3 必须非空（`AnvilBlockEntity.java:374-377`），也不是 JSON 字段 |

---

## [R-04] tfc:casting —— 模具浇铸配方

### R-04.1 类型标识与实现类

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

### R-04.2 完整字段表

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

### R-04.3 真实 JSON 样例

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

### R-04.4 游戏内触发条件

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

### R-04.5 特殊辅助类

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

## [R-05] tfc:casting_crafting —— 工作台浇铸（special crafting 配方）

### R-05.1 类型标识与实现类（本组最重要的一个"不一致"点）

| 项目 | 值 | 证据 |
| --- | --- | --- |
| JSON `type` | `tfc:casting_crafting` | `TFCRecipeSerializers.java:81` |
| **serializer id** | **`tfc:casting_crafting`** | `TFCRecipeSerializers.java:81`：`register("casting_crafting", new RecipeSerializerImpl<CastingCraftingRecipe>(CastingCraftingRecipe.INSTANCE))` |
| **recipe type id** | **无独立注册**；实际为原版 **`minecraft:crafting`**（`RecipeType.CRAFTING`） | 见下方"结论与证据链" |
| 实现类全名 | `net.dries007.tfc.common.recipes.CastingCraftingRecipe` | `CastingCraftingRecipe.java:35` |
| 类型形态 | `class CastingCraftingRecipe extends CustomRecipe`，无字段，构造器 `private`，通过静态单例 `INSTANCE` 使用 | `CastingCraftingRecipe.java:35-41` |
| `getSerializer()` | `TFCRecipeSerializers.CASTING_CRAFTING.get()` | `CastingCraftingRecipe.java:75-77` |
| 实际数据文件 | `data/tfc/recipe/crafting/casting.json`，内容：`{"type":"tfc:casting_crafting"}` | jar 内真实文件，已读取 |

#### 结论与证据链：它的 recipe type 是 `minecraft:crafting`

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

### R-05.2 完整字段表

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

### R-05.3 真实 JSON 样例

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

### R-05.4 游戏内触发条件

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

### R-05.5 特殊辅助类

| 辅助类 | 用法 |
| --- | --- |
| `net.dries007.tfc.common.recipes.CastingRecipe` | **本配方完全依赖它**：`matches`/`assemble`/`getRemainingItems` 三处都先 `CastingRecipe.get(mold)` 再委托（见 R-04） |
| `net.dries007.tfc.common.component.mold.IMold` | 判定"物品是否为模具"的唯一手段（`IMold.get(stack)`，`IMold.java:24-27`） |
| `net.dries007.tfc.common.recipes.RecipeHelpers.getCraftingPlayer()` | 取当前合成玩家（`RecipeHelpers.java:65-68`，内部为 `CommonHooks.getCraftingPlayer()`），用于随机数 |
| `net.minecraft.world.item.crafting.CustomRecipe` / `CraftingInput` | 父类与原版输入容器 |
| `ItemStackProvider` / `ItemStackModifier` | **间接**使用：`CastingRecipe.result` 的 modifiers 会在 `assemble` 中生效 |
| `RecipeSerializerImpl` | 该配方 serializer 的实现方式（`MapCodec.unit` 单例），`RecipeSerializerImpl.java:19-24` |

---

## 附录 A1-1：`ItemStackProvider` 与 `ItemStackModifier`（R-02 / R-03 / R-04 的 `result` 字段体系）

本组 5 个配方中，`tfc:anvil`、`tfc:welding`、`tfc:casting` 三者都有 `result` 字段，类型均为 `net.dries007.tfc.common.recipes.outputs.ItemStackProvider`；`tfc:casting_crafting` 间接经由 `CastingRecipe` 使用同一体系。

### A1-1.1 `ItemStackProvider` 的 JSON 两种形态

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

### A1-1.2 `ItemStackModifier` 的 JSON 形状

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

### A1-1.3 可用 modifier 全清单（22 个，来源 `ItemStackModifiers.java:57-78`）

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

### A1-1.4 本组 5 类配方中 modifier 的真实使用情况

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

## 附录 A1-2：本组引用的其它辅助类型

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

## 附录 A1-3：`Ingredient` 的 JSON 形式与 `TFCIngredients`

本组中 `tfc:anvil.ingredient`、`tfc:welding.first_input` / `second_input`、`tfc:casting.mold` 都是 `Ingredient`（`Ingredient.CODEC`）。

### A1-3.1 原生 / NeoForge 形式

| 写法 | 示例 | 说明 |
| --- | --- | --- |
| 单物品 | `{"item":"tfc:ceramic/ingot_mold"}` | 真实数据大量使用 |
| 物品标签 | `{"tag":"c:ingots/copper"}` | 真实数据大量使用 |
| 数组（或） | `[{"tag":"c:rods/wooden"},{"item":"minecraft:bone"}]` | 见 `data/tfc/recipe/crafting/obsidian_axe.json` 的 `key.S` |
| NeoForge 内置 type | `{"type":"neoforge:compound","children":[...]}` | 见 `data/tfc/recipe/barrel/clean_bowl.json` |
| 空 | `[]` 或 `{"ingredient":...}` 的 `Ingredient.EMPTY` 形式 | 本组 5 类配方的这些字段**都是必填**，不可为空 |

### A1-3.2 TFC 自定义 ingredient（`net/dries007/tfc/common/recipes/ingredients/TFCIngredients.java:42-48`）

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

### A1-3.3 一个常见误认

`tfc:air_or_empty_fluid` **不是** ingredient、也不是 modifier，而是 **`BlockPredicate`**（`net/dries007/tfc/world/blockpredicate/TFCBlockPredicates.java:30`，`AirOrEmptyFluidPredicate`）。它出现在 worldgen/pump 等场景的 JSON 中。若在全 `data/` 目录做关键词统计会把它与 modifier 混在一起，需按注册表区分（本次统计已限定在 `data/tfc/recipe/**`）。

---

## 附录 A1-4：未核实 / 存疑事项（Honest Gaps）

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

## 附录 A1-5：字段级自查（每个字段的 CODEC 出处）

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

