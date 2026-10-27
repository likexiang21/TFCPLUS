# TerraFirmaCraft 4.2.10 配方 JSON 字段级考证 —— 组 A4

> 版本基准：TerraFirmaCraft-NeoForge-1.21.1-4.2.10 / Minecraft 1.21.1 / NeoForge 21.1.248
> 证据来源（全部为本地文件，无网络依赖）：
> - 反编译源码根：`moddev/src-ref/TFC-decompiled`（下文相对源码路径均以此为根）
> - 真实 jar 解包内容：`moddev/jar-extract`（下文"jar 内路径"以 `jar-extract` 为根）
> - 字节码交叉验证（NeoForge 与 Minecraft 侧类不在反编译树内时使用）：
>   - `.minecraft/libraries/net/minecraft/client/1.21.1-20240808.144430/client-1.21.1-20240808.144430-srg.jar`（`javap`）
>   - `.minecraft/libraries/net/neoforged/neoforge/21.1.248/neoforge-21.1.248-client.jar` + `neoforge-21.1.248-universal.jar`（`javap`）
> - 反编译产物无参数名、无注释，但 `CODEC` 定义、record 组件、字段常量完整可读，本组所有字段表均从 `CODEC` 逐行读出。

---

## 组 A4 覆盖范围

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

### A4.0 六种类型的「type id / recipe type / serializer」速查

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

### A4.1 文件分布速查（真实 jar）

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

## [R-18] tfc:pot —— 锅煮配方（通用产物）

### R-18.1 类型标识与实现类

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

### R-18.2 完整字段表

`SimplePotRecipe` 的字段由**两层**组成：父类 `PotRecipe` 的 4 个字段（继承）+ 自身 3 个字段。

#### R-18.2.1 父类 `PotRecipe` 字段（4 个，全部必需）

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

#### R-18.2.2 `SimplePotRecipe` 自身字段（3 个，2 可选 1 必有默认）

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

#### R-18.2.3 匹配语义（不是字段，但决定 JSON 怎么写）

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

#### R-18.2.4 额外校验（`validate`）

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

#### R-18.2.5 `STREAM_CODEC`（网络同步用，与 JSON 无关，但可交叉验证字段顺序）

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

### R-18.3 真实 JSON 样例

以下内容均为从 `moddev/jar-extract` 逐字读取（文件均为单行），未做任何改写。

#### 样例 1：流体输入 → 流体输出（最简结构）

相对路径：`jar-extract/data/tfc/recipe/pot/black_dye.json`

```json
{"type":"tfc:pot","duration":2400,"fluid_ingredient":{"amount":1000,"fluid":"minecraft:water"},"fluid_output":{"amount":1000,"id":"tfc:black_dye"},"ingredients":[{"item":"minecraft:black_dye"}],"temperature":600.0}
```

结构特征：1 个物品输入、1 个流体输入、只有 `fluid_output`、**没有** `item_output` 与 `uses_all_fluid`（走默认值 `true`）。

#### 样例 2：物品输入 → 物品输出（纯物品，带 `item_output`）

相对路径：`jar-extract/data/tfc/recipe/pot/food/boiled_egg_1.json`

```json
{"type":"tfc:pot","duration":1200,"fluid_ingredient":{"amount":100,"fluid":"minecraft:water"},"ingredients":[{"type":"tfc:and","children":[{"item":"minecraft:egg"},{"type":"tfc:not_rotten"}]}],"item_output":[{"count":1,"id":"tfc:food/boiled_egg"}],"temperature":300.0}
```

结构特征：`ingredients` 用了自定义 ingredient `tfc:and`（原版物品 + `tfc:not_rotten` 组合）；`item_output` 的元素是**纯 ItemStack 形式**（`{"count":1,"id":"..."}`，走 `ItemStackProvider.CODEC` 的 `Either.right` 分支）；无 `fluid_output`。

这与样例 1 是两种结构上不同的配方（一个输出流体、一个输出物品）。

#### 样例 3（附加）：多物品输入 → 多物品输出（数量对齐）

相对路径：`jar-extract/data/tfc/recipe/pot/food/cooked_rice_5.json`

```json
{"type":"tfc:pot","duration":1200,"fluid_ingredient":{"amount":100,"fluid":"minecraft:water"},"ingredients":[{"type":"tfc:and","children":[{"item":"tfc:food/rice_grain"},{"type":"tfc:not_rotten"}]},{"type":"tfc:and","children":[{"item":"tfc:food/rice_grain"},{"type":"tfc:not_rotten"}]},{"type":"tfc:and","children":[{"item":"tfc:food/rice_grain"},{"type":"tfc:not_rotten"}]},{"type":"tfc:and","children":[{"item":"tfc:food/rice_grain"},{"type":"tfc:not_rotten"}]},{"type":"tfc:and","children":[{"item":"tfc:food/rice_grain"},{"type":"tfc:not_rotten"}]}],"item_output":[{"count":1,"id":"tfc:food/cooked_rice"},{"count":1,"id":"tfc:food/cooked_rice"},{"count":1,"id":"tfc:food/cooked_rice"},{"count":1,"id":"tfc:food/cooked_rice"},{"count":1,"id":"tfc:food/cooked_rice"}],"temperature":300.0}
```

#### 样例 4（附加）：`item_output` 使用 `modifiers`（依赖输入的 provider）

相对路径：`jar-extract/data/tfc/recipe/pot/jam_banana_canning_1.json`

```json
{"type":"tfc:pot","duration":300,"fluid_ingredient":{"amount":100,"fluid":"minecraft:water"},"ingredients":[{"type":"tfc:and","children":[{"item":"tfc:jar/banana"},{"type":"tfc:lacks_trait","trait":"tfc:canned"},{"type":"tfc:not_rotten"}]}],"item_output":[{"modifiers":[{"type":"tfc:copy_input"},{"type":"tfc:add_trait","trait":"tfc:canned"}]}],"temperature":300.0,"uses_all_fluid":false}
```

结构特征：`item_output` 元素走 `ItemStackProvider.CODEC` 的 `Either.left`（record 形式），只给了 `modifiers`（`stack` 字段省略 → 默认 `ItemStack.EMPTY`）；`uses_all_fluid:false`。这正是 R-18.2.4 校验规则针对的形态（1 输入 ↔ 1 输出）。

#### 样例 5（附加）：5 输入 + 5 个依赖输入的 provider + 显式 `uses_all_fluid:false`

相对路径：`jar-extract/data/tfc/recipe/pot/jam_banana_canning_5.json`

```json
{"type":"tfc:pot","duration":300,"fluid_ingredient":{"amount":500,"fluid":"minecraft:water"},"ingredients":[{"type":"tfc:and","children":[{"item":"tfc:jar/banana"},{"type":"tfc:lacks_trait","trait":"tfc:canned"},{"type":"tfc:not_rotten"}]},{"type":"tfc:and","children":[{"item":"tfc:jar/banana"},{"type":"tfc:lacks_trait","trait":"tfc:canned"},{"type":"tfc:not_rotten"}]},{"type":"tfc:and","children":[{"item":"tfc:jar/banana"},{"type":"tfc:lacks_trait","trait":"tfc:canned"},{"type":"tfc:not_rotten"}]},{"type":"tfc:and","children":[{"item":"tfc:jar/banana"},{"type":"tfc:lacks_trait","trait":"tfc:canned"},{"type":"tfc:not_rotten"}]},{"type":"tfc:and","children":[{"item":"tfc:jar/banana"},{"type":"tfc:lacks_trait","trait":"tfc:canned"},{"type":"tfc:not_rotten"}]}],"item_output":[{"modifiers":[{"type":"tfc:copy_input"},{"type":"tfc:add_trait","trait":"tfc:canned"}]},{"modifiers":[{"type":"tfc:copy_input"},{"type":"tfc:add_trait","trait":"tfc:canned"}]},{"modifiers":[{"type":"tfc:copy_input"},{"type":"tfc:add_trait","trait":"tfc:canned"}]},{"modifiers":[{"type":"tfc:copy_input"},{"type":"tfc:add_trait","trait":"tfc:canned"}]},{"modifiers":[{"type":"tfc:copy_input"},{"type":"tfc:add_trait","trait":"tfc:canned"}]}],"temperature":300.0,"uses_all_fluid":false}
```

#### 样例 6（附加）：5 输入 → 1 份流体输出（`lye`）

相对路径：`jar-extract/data/tfc/recipe/pot/lye.json`

```json
{"type":"tfc:pot","duration":2400,"fluid_ingredient":{"amount":1000,"fluid":"minecraft:water"},"fluid_output":{"amount":1000,"id":"tfc:lye"},"ingredients":[{"item":"tfc:powder/wood_ash"},{"item":"tfc:powder/wood_ash"},{"item":"tfc:powder/wood_ash"},{"item":"tfc:powder/wood_ash"},{"item":"tfc:powder/wood_ash"}],"temperature":600.0}
```

#### 样例 7（附加）：`tfc:canola_oil_water`（与 `lye` 同构，可对比 `temperature`）

相对路径：`jar-extract/data/tfc/recipe/pot/canola_oil_water.json`

```json
{"type":"tfc:pot","duration":2400,"fluid_ingredient":{"amount":1000,"fluid":"minecraft:water"},"fluid_output":{"amount":1000,"id":"tfc:canola_oil_water"},"ingredients":[{"item":"tfc:canola_paste"},{"item":"tfc:canola_paste"},{"item":"tfc:canola_paste"},{"item":"tfc:canola_paste"},{"item":"tfc:canola_paste"}],"temperature":300.0}
```

### R-18.4 游戏内触发条件（驱动链）

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

### R-18.5 输入容器：`IPotInventory` 与槽位映射

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

### R-18.6 TFC 自带 145 个 `tfc:pot` 配方的取值统计

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

### R-18.7 文件清单（145 个）

顶层 `data/tfc/recipe/pot/`（130 个 `tfc:pot`）：

- **110 个罐装**：`jam_<fruit>_canning_1..5.json`，`<fruit>` ∈ {`banana`, `blackberry`, `blueberry`, `bunchberry`, `cherry`, `cloudberry`, `cranberry`, `elderberry`, `gooseberry`, `green_apple`, `lemon`, `melon_slice`, `olive`, `orange`, `peach`, `peanut`, `plum`, `raspberry`, `red_apple`, `snowberry`, `strawberry`, `wintergreen_berry`}（22 种 × 5 = 110）。
- **20 个流体产出型**：`black_dye.json`、`blue_dye.json`、`brown_dye.json`、`cyan_dye.json`、`gray_dye.json`、`green_dye.json`、`light_blue_dye.json`、`light_gray_dye.json`、`lime_dye.json`、`magenta_dye.json`、`orange_dye.json`、`pink_dye.json`、`purple_dye.json`、`red_dye.json`、`white_dye.json`、`yellow_dye.json`、`lye.json`、`tallow.json`、`canola_oil_water.json`、`olive_oil_water.json`。

子目录 `data/tfc/recipe/pot/food/`（15 个 `tfc:pot`）：`boiled_egg_1..5.json`、`cooked_lentil_1..5.json`、`cooked_rice_1..5.json`。

### R-18.8 R-18 小结与易错点

1. `type` 与 recipe type 同名（都是 `tfc:pot`），但它**不是**「物品→物品」的简单烹饪配方，而是「物品 + 流体」的通用锅煮配方。
2. `fluid_ingredient` **必填**，且必须是 `tfc:usable_in_pot` 内的流体（SelfTests 会报错）。
3. `duration` 是 tick；`temperature` 是**最低阈值**且为**严格大于**判定。
4. `item_output` 的数量不必须等于 `ingredients`，**除非**输出里有依赖输入的 provider（R-18.2.4）。
5. `uses_all_fluid` 默认 `true`；设为 `false` 时配合「输入流体量 > 消耗量」可产出"剩余输入流体"（TFC 数据里 canning 用 `false` 来消耗定量的水同时保留原有内容）。
6. 不存在 `pot_output` 字段（见附录 A4-1）。

---

## [R-19] tfc:pot_soup —— 锅煮汤配方

### R-19.1 类型标识与实现类

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

### R-19.2 完整字段表

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

### R-19.3 产物如何确定（没有 JSON 字段，全在代码里）

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

### R-19.4 真实 JSON 样例（全部 3 个，逐字读取）

#### 样例 1：`jar-extract/data/tfc/recipe/pot/soup_3.json`

```json
{"type":"tfc:pot_soup","duration":1200,"fluid_ingredient":{"amount":100,"fluid":"minecraft:water"},"ingredients":[{"type":"tfc:and","children":[{"tag":"tfc:usable_in_soup"},{"type":"tfc:not_rotten"}]},{"type":"tfc:and","children":[{"tag":"tfc:usable_in_soup"},{"type":"tfc:not_rotten"}]},{"type":"tfc:and","children":[{"tag":"tfc:usable_in_soup"},{"type":"tfc:not_rotten"}]}],"temperature":300.0}
```

#### 样例 2：`jar-extract/data/tfc/recipe/pot/soup_4.json`

```json
{"type":"tfc:pot_soup","duration":1200,"fluid_ingredient":{"amount":100,"fluid":"minecraft:water"},"ingredients":[{"type":"tfc:and","children":[{"tag":"tfc:usable_in_soup"},{"type":"tfc:not_rotten"}]},{"type":"tfc:and","children":[{"tag":"tfc:usable_in_soup"},{"type":"tfc:not_rotten"}]},{"type":"tfc:and","children":[{"tag":"tfc:usable_in_soup"},{"type":"tfc:not_rotten"}]},{"type":"tfc:and","children":[{"tag":"tfc:usable_in_soup"},{"type":"tfc:not_rotten"}]}],"temperature":300.0}
```

#### 样例 3：`jar-extract/data/tfc/recipe/pot/soup_5.json`

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

### R-19.5 游戏内触发条件

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

### R-19.6 R-19 小结

- `tfc:pot_soup` **没有独立 recipe type**，挂在 `tfc:pot` 上。
- JSON 字段 = `PotRecipe` 的 4 个字段，**无产物字段**。
- 汤的种类、份数、营养全部由 `SoupPotRecipe.getOutput` 在运行时按锅内食材计算。
- 3 个内置配方靠 `ingredients` 长度（3/4/5）区分。

---

## [R-20] tfc:pot_jam —— 锅煮果酱 / 罐装配方

### R-20.1 类型标识与实现类

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

### R-20.2 完整字段表

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

### R-20.3 产物语义

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

### R-20.4 真实 JSON 样例

TFC 自带的 66 个 `tfc:pot_jam` 全部是"果酱合成"，`duration` 全为 `500`、`temperature` 全为 `300.0`、`fluid_ingredient` 全为 `{amount:100, fluid:"minecraft:water"}`。

#### 样例 1：2 份水果 + 1 份甜味剂 → 2 罐

相对路径：`jar-extract/data/tfc/recipe/pot/jam_banana_2.json`

```json
{"type":"tfc:pot_jam","duration":500,"fluid_ingredient":{"amount":100,"fluid":"minecraft:water"},"ingredients":[{"type":"tfc:and","children":[{"item":"tfc:food/banana"},{"type":"tfc:not_rotten"}]},{"type":"tfc:and","children":[{"item":"tfc:food/banana"},{"type":"tfc:not_rotten"}]},{"tag":"tfc:foods/sweeteners"}],"sealed_result":{"count":2,"id":"tfc:jar/banana"},"temperature":300.0,"texture":"tfc:block/jar/banana","unsealed_result":{"count":2,"id":"tfc:jar/banana_unsealed"}}
```

结构特征：3 个 `ingredients` 中前 2 个是水果（`tfc:and` 组合具体物品 + `tfc:not_rotten`），第 3 个直接是 tag `tfc:foods/sweeteners`（原版 `Ingredient` 的 tag 形式，无需 `type`）；`sealed_result`/`unsealed_result` 的 `count` 均为 2，与水果份数一致。

#### 样例 2：4 份水果 + 1 份甜味剂 → 4 罐

相对路径：`jar-extract/data/tfc/recipe/pot/jam_strawberry_4.json`

```json
{"type":"tfc:pot_jam","duration":500,"fluid_ingredient":{"amount":100,"fluid":"minecraft:water"},"ingredients":[{"type":"tfc:and","children":[{"item":"tfc:food/strawberry"},{"type":"tfc:not_rotten"}]},{"type":"tfc:and","children":[{"item":"tfc:food/strawberry"},{"type":"tfc:not_rotten"}]},{"type":"tfc:and","children":[{"item":"tfc:food/strawberry"},{"type":"tfc:not_rotten"}]},{"type":"tfc:and","children":[{"item":"tfc:food/strawberry"},{"type":"tfc:not_rotten"}]},{"tag":"tfc:foods/sweeteners"}],"sealed_result":{"count":4,"id":"tfc:jar/strawberry"},"temperature":300.0,"texture":"tfc:block/jar/strawberry","unsealed_result":{"count":4,"id":"tfc:jar/strawberry_unsealed"}}
```

#### 样例 3：3 份水果 + 1 份甜味剂 → 3 罐（`wintergreen_berry`）

相对路径：`jar-extract/data/tfc/recipe/pot/jam_wintergreen_berry_3.json`

```json
{"type":"tfc:pot_jam","duration":500,"fluid_ingredient":{"amount":100,"fluid":"minecraft:water"},"ingredients":[{"type":"tfc:and","children":[{"item":"tfc:food/wintergreen_berry"},{"type":"tfc:not_rotten"}]},{"type":"tfc:and","children":[{"item":"tfc:food/wintergreen_berry"},{"type":"tfc:not_rotten"}]},{"type":"tfc:and","children":[{"item":"tfc:food/wintergreen_berry"},{"type":"tfc:not_rotten"}]},{"tag":"tfc:foods/sweeteners"}],"sealed_result":{"count":3,"id":"tfc:jar/wintergreen_berry"},"temperature":300.0,"texture":"tfc:block/jar/wintergreen_berry","unsealed_result":{"count":3,"id":"tfc:jar/wintergreen_berry_unsealed"}}
```

#### 样例 4（对照）：同目录下的**非** jam 配方 —— `tfc:pot` 罐装

相对路径：`jar-extract/data/tfc/recipe/pot/jam_banana_canning_2.json`

```json
{"type":"tfc:pot","duration":300,"fluid_ingredient":{"amount":200,"fluid":"minecraft:water"},"ingredients":[{"type":"tfc:and","children":[{"item":"tfc:jar/banana"},{"type":"tfc:lacks_trait","trait":"tfc:canned"},{"type":"tfc:not_rotten"}]},{"type":"tfc:and","children":[{"item":"tfc:jar/banana"},{"type":"tfc:lacks_trait","trait":"tfc:canned"},{"type":"tfc:not_rotten"}]}],"item_output":[{"modifiers":[{"type":"tfc:copy_input"},{"type":"tfc:add_trait","trait":"tfc:canned"}]},{"modifiers":[{"type":"tfc:copy_input"},{"type":"tfc:add_trait","trait":"tfc:canned"}]}],"temperature":300.0,"uses_all_fluid":false}
```

> **易混淆点**：文件名以 `jam_` 开头的 `*_canning_*.json` **不是** `tfc:pot_jam`，而是 `tfc:pot`（`SimplePotRecipe`）。判断依据只能是 JSON 内的 `type` 字段，不能看文件名。

### R-20.5 66 个 `tfc:pot_jam` 文件清单

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

### R-20.6 游戏内触发条件

与 R-18/R-19 一致：`PotBlockEntity` 通过 `TFCRecipeTypes.POT` 检索并结算（`PotBlockEntity.java:212-215`、`:154-171`）。

取产物必须借助空罐（`JamOutput.onInteract`，`JamPotRecipe.java:97-112`）：
- `tfc:empty_jar` → 取 `unsealed_result` 产物；
- tag `tfc:empty_jars_with_lid` 内的物品 → 取 `sealed_result` 产物。

JEI 展示分类：`registry.addRecipes(JAM_POT, JEIIntegration.recipes(TFCRecipeTypes.POT, recipe -> recipe.getSerializer() == TFCRecipeSerializers.POT_JAM.get()))`（`JEIIntegration.java:216`）；点击区域绑定 `registry.addRecipeClickArea(PotScreen.class, 77, 6, 9, 14, new RecipeType[]{SIMPLE_POT, SOUP_POT, JAM_POT})`（`JEIIntegration.java:286`）。

### R-20.7 R-20 小结

- `tfc:pot_jam` 无独立 recipe type，挂在 `tfc:pot`。
- 7 个字段全部必需：4 个继承自 `PotRecipe` + `unsealed_result`、`sealed_result`、`texture`。
- 无 `.validate(...)`。
- 与 `tfc:pot` 的 canning 配方**同目录、同前缀**，只能用 `type` 字段区分。

---

## [R-21] tfc:loom —— 织布机配方

### R-21.1 类型标识与实现类

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

### R-21.2 完整字段表

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

### R-21.3 真实 JSON 样例（全部 5 个，逐字读取）

#### 样例 1：`jar-extract/data/tfc/recipe/loom/wool_cloth.json`

```json
{"type":"tfc:loom","ingredient":{"count":16,"item":"tfc:wool_yarn"},"result":{"count":1,"id":"tfc:wool_cloth"},"steps":16,"texture":"minecraft:block/white_wool"}
```

#### 样例 2：`jar-extract/data/tfc/recipe/loom/white_wool.json`

```json
{"type":"tfc:loom","ingredient":{"count":4,"item":"tfc:wool_cloth"},"result":{"count":8,"id":"minecraft:white_wool"},"steps":4,"texture":"minecraft:block/white_wool"}
```

#### 样例 3：`jar-extract/data/tfc/recipe/loom/silk_cloth.json`

```json
{"type":"tfc:loom","ingredient":{"count":24,"item":"minecraft:string"},"result":{"count":1,"id":"tfc:silk_cloth"},"steps":24,"texture":"minecraft:block/white_wool"}
```

#### 样例 4：`jar-extract/data/tfc/recipe/loom/burlap_cloth.json`

```json
{"type":"tfc:loom","ingredient":{"count":12,"item":"tfc:jute_fiber"},"result":{"count":1,"id":"tfc:burlap_cloth"},"steps":12,"texture":"tfc:block/burlap"}
```

#### 样例 5：`jar-extract/data/tfc/recipe/loom/unrefined_paper.json`

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

### R-21.4 游戏内触发条件（驱动链）

织布机有**两个**驱动器，都继承自 `LoomBlockEntity`。

#### 驱动器 1：手动织布机 `LoomBlockEntity`

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

#### 驱动器 2：动力织布机 `PowerLoomBlockEntity`

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

### R-21.5 R-21 小结

- `tfc:loom` 的 type 与 serializer 同名。
- 4 个字段**全部必需**：`ingredient`、`result`、`steps`、`texture`。
- `ingredient` 是 **Sized**（带数量），这是 loom 与多数 TFC 配方的区别点。
- 无 `.validate`；但运行时 `SelfTests` 强制「物品输入唯一」。
- 由 `LoomBlockEntity`（手动右键）与 `PowerLoomBlockEntity`（旋转动力）共同驱动。

---

## [R-22] tfc:food_combining —— 食物合并（合成台特殊配方）

### R-22.1 类型标识与实现类

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

### R-22.2 它到底有没有 recipe type？—— 证据链

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

### R-22.3 完整字段表 —— 没有字段

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

### R-22.4 是否真的能从 JSON 加载？—— 是

- **能**。理由是 jar 中存在让这条配方被加载的真实文件：

  `jar-extract/data/tfc/recipe/crafting/food_combining.json`（逐字读取，全文 1 行）：

  ```json
  {"type":"tfc:food_combining"}
  ```

  该文件位于 `data/tfc/recipe/crafting/`，`type` 指向 `tfc:food_combining`，会由 `RecipeManager` 用对应的 `RecipeSerializer`（`MapCodec.unit(INSTANCE)`）解码，得到 `TFCRecipeSerializers.FOOD_COMBINING_CRAFTING` 的实例，即 `FoodCombiningCraftingRecipe.INSTANCE`。<br>
  同目录同写法的 `casting.json`（`{"type":"tfc:casting_crafting"}`）是同一机制的另一实例，可交叉印证。

- **但它不是"配置型"配方**：整个 JSON 没有可调字段，行为完全由 `matches` / `assemble` 的 Java 代码决定。因此这类配方**通常由代码（单例 + JSON 占位）而非常规 JSON 定义**；TFC 甚至用「代码里持有单例 + 一个极简 JSON 触发加载」的方式把它塞进配方管理器。

- 同类指示：`TFCRecipeSerializers.java:80-81` 对 `FOOD_COMBINING_CRAFTING` 与 `CASTING_CRAFTING` 都使用 `new RecipeSerializerImpl<>(X.INSTANCE)`，而其它配方都使用 `register(name, CODEC, STREAM_CODEC)` 的正常路径。

### R-22.5 匹配与产出逻辑（无 JSON 字段，全部在代码中）

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

### R-22.6 游戏内触发条件（由哪个方块/界面驱动）

| 环节 | 证据 |
| --- | --- |
| 触发方块/界面 | **原版工作台界面**：`net/dries007/tfc/common/container/TFCWorkbenchContainer.java:20`（`extends CraftingMenu`）。TFC 的 TFC 工作台复用原版 `CraftingMenu` 逻辑，后者以 `RecipeType.CRAFTING` 检索配方并调用 `matches(CraftingInput, Level)` |
| 输入容器 | `net.minecraft.world.item.crafting.CraftingInput`（1.21.1 原版合成输入容器），由 `CraftingMenu`/`CraftingInput.of(...)` 构造 |
| 配方检索路径 | `RecipeManager.byType(RecipeType.CRAFTING)`（原版）→ 包含本配方（因其 `getType()` 为 `RecipeType.CRAFTING`） |
| TFC 侧是否有专用驱动代码 | **没有**。`grep -r "FoodCombining"` 在整个 `net/dries007/tfc` 下只有 3 处命中：`TFCRecipeSerializers.java:29`（import）、`TFCRecipeSerializers.java:80`（注册）、`FoodCombiningCraftingRecipe.java` 自身（第 28、30、32、86 行）。**不存在**任何 `FoodCombiningCraftingRecipe.INSTANCE.matches(...)` 之类的显式调用 |

补充：`CustomRecipe.isSpecial()` 在 1.21.1 返回 `true`（`javap -p CustomRecipe` 输出中可见 `public boolean isSpecial();`），因此该配方不会出现在配方书（RecipeBook）的普通合成列表里，也不会被 JEI 当作普通合成配方展示。

### R-22.7 R-22 小结

- `type` = `tfc:food_combining`（serializer 名），**recipe type = `minecraft:crafting`**（继承自 `CraftingRecipe.getType()`）。
- **零 JSON 字段**，写法固定为 `{"type":"tfc:food_combining"}`。
- 能从 JSON 加载（jar 中有真实文件），但配方行为完全由 Java 代码决定。
- 由原版合成台（`TFCWorkbenchContainer extends CraftingMenu` + `RecipeType.CRAFTING`）驱动，TFC 侧无显式调用点。

---

## [R-23] tfc:bloomery —— 冶炼炉（块炼）配方

### R-23.1 类型标识与实现类

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

### R-23.2 完整字段表

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

### R-23.3 真实 JSON 样例（唯一 1 个，逐字读取）

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

### R-23.4 游戏内触发条件（驱动链）

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

### R-23.5 R-23 小结

- `tfc:bloomery` 的 type 与 serializer 同名。
- 4 个字段全部必需：`fluid`（注意不叫 `fluid_ingredient`）、`catalyst`、`result`、`duration`。
- **无温度字段**，温度经 `HeatingRecipe` 传递。
- 由 `BloomeryBlockEntity` 自行遍历 `TFCRecipeTypes.BLOOMERY` 驱动，非 `getRecipeFor`。
- jar 中仅 1 个配方；运行时自检要求输入流体唯一。

---

## 附录 A4-1：`PotOutput` 详解（位置、JSON 字段、注册表）

### A4-1.1 关键结论先行

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

### A4-1.2 `PotOutput` 的形态与位置

| 项目 | 值 | 证据 |
| --- | --- | --- |
| 位置 | `net/dries007/tfc/common/recipes/outputs/PotOutput.java` | 全文 106 行 |
| 形态 | **`interface PotOutput`**（不是 `ItemStackProvider` 的子类，也不是 record） | `PotOutput.java:40` |
| 注册表键 | `ResourceKey<Registry<OutputType>> KEY = ResourceKey.createRegistryKey(Helpers.identifier("pot_output"))` → 注册表 id `tfc:pot_output` | `PotOutput.java:41` |
| 默认项 | `DEFAULT = ResourceKey.create(KEY, Helpers.identifier("empty"))`，且 `new RegistryBuilder(KEY).sync(true).defaultKey(DEFAULT)` | `PotOutput.java:42-43` |
| 默认实例 | `EMPTY_INSTANCE`（匿名实现，全部走 default 方法） | `PotOutput.java:45` |
| 已注册类型 | `empty`（→ `EMPTY_INSTANCE`）、`soup`（→ `SoupPotRecipe.OUTPUT_TYPE`）、`jam`（→ `JamPotRecipe.OUTPUT_TYPE`） | `PotOutput.java:46-48` |
| 类型接口 | `@FunctionalInterface OutputType { PotOutput read(HolderLookup.Provider, CompoundTag); }` | `PotOutput.java:101-104` |

### A4-1.3 `PotOutput` 的 default 方法（行为契约）

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

### A4-1.4 三种实现的 NBT 字段（**NBT，不是配方 JSON**）

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

### A4-1.5 对写数据者的实际影响

- 你在 mod 里写 `tfc:pot` / `tfc:pot_soup` / `tfc:pot_jam` 配方时，**不需要也不能**写任何 `PotOutput` 相关字段。
- 想自定义"锅产物行为"（例如自定义取产物交互），只能通过注册到 `tfc:pot_output` 注册表的 `OutputType` + 自定义 `PotRecipe` 子类实现，纯 JSON 无法做到。
- `chance` 这类字段若出现在 pot 产物中，只可能来自 `ItemStackProvider` 的 `modifiers`（`tfc:chance`，见 A4-2），与 `PotOutput` 无关。

---

## 附录 A4-2：`ItemStackProvider` 与 `ItemStackModifier`（JSON 写法与类型清单）

### A4-2.1 `ItemStackProvider` 的 JSON 两种写法

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

### A4-2.2 `ItemStackModifier` 的分派机制

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

### A4-2.3 `ItemStackModifiers` 已注册的 22 种类型（`ItemStackModifiers.java:57-78`）

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

### A4-2.4 本组配方中实际出现过的 modifier

对 `data/tfc/recipe/pot/**` 全部文件的 `"modifiers"` 内 `type` 值做统计（结果）：

| modifier | 出现次数 |
| --- | --- |
| `tfc:copy_input` | 330 |
| `tfc:add_trait` | 330 |

（其余 `type` 计数属于 `ingredients` 里的 ingredient 类型，不是 modifier。）330 正好等于全部罐装配方中 `item_output` 的 provider 总数（22 种水果 × (1+2+3+4+5) 档 = 330），即每个 provider 各带 1 个 `copy_input` 与 1 个 `add_trait`。即 TFC 自带数据只用到了 `copy_input` + `add_trait` 组合来做"罐装"。

### A4-2.5 `ItemStackProvider` 的取值方法（与 JSON 无关，供理解语义）

| 方法 | 行为 | 证据 |
| --- | --- | --- |
| `getSingleStack(ItemStack input)` | `getStack(input.copyWithCount(1))` —— 以单个输入为单位产出 | `ItemStackProvider.java:72-74` |
| `getEmptyStack()` | `getStack(ItemStack.EMPTY, Context.NO_RANDOM_CHANCE)` —— 不依赖输入（`getResultItem` 用它） | `:80-82` |
| `getStack(input, context)` | 先 `stack.copy()`，若 `input` 非空则 `count *= input.getCount()`，再依次应用 modifiers | `:92-101` |
| `dependsOnInput()` | 任一 modifier 的 `dependsOnInput()` 为真则返回真 | `:103-109` |

---

## 附录 A4-3：Ingredient 家族与 Sized* 的 JSON 形式（本组公共）

### A4-3.1 原版 `Ingredient.CODEC`（用于 `ingredients` 的元素、`catalyst`/`ingredient` 的内层）

本组出现的三种基本写法（均有真实样例佐证）：

| 写法 | 示例 | 出现位置 |
| --- | --- | --- |
| 单物品 | `{"item":"minecraft:egg"}` | `jar-extract/data/tfc/recipe/pot/food/boiled_egg_1.json` |
| tag | `{"tag":"tfc:foods/sweeteners"}` | `jar-extract/data/tfc/recipe/pot/jam_banana_2.json` |
| 数组（多选一） | `[{...},{...}]` | 原版 `Ingredient.CODEC` 支持（本组自带数据中未出现） |

### A4-3.2 `TFCIngredients` 自定义 ingredient（`type` 分派）

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

### A4-3.3 `SizedIngredient`（NeoForge）—— loom 的 `ingredient`、bloomery 的 `catalyst`

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

### A4-3.4 `SizedFluidIngredient`（NeoForge）—— pot 的 `fluid_ingredient`、bloomery 的 `fluid`

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

## 附录 A4-4：证据文件索引与「未能核实」清单

### A4-4.1 本组引用的 TFC 源码文件

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

### A4-4.2 本组引用的 jar 内真实文件

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

### A4-4.3 本组使用的字节码核实命令

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

### A4-4.4 「未能核实」清单（明确列出）

| 编号 | 未能核实的点 | 已检查过的内容 | 现状说明 |
| --- | --- | --- | --- |
| U-1 | `ExtraCodecs.POSITIVE_INT` 是否允许 `0` | 已读 `javap` 输出中的错误字符串 "Size must be positive" 与字段引用 `net/minecraft/util/ExtraCodecs.POSITIVE_INT` | 依据命名与错误文本判定为「必须 ≥ 1」，但**未反编译 `ExtraCodecs` 本体**逐行确认。若需要绝对精确，可对 `client-1.21.1-*-srg.jar` 的 `net.minecraft.util.ExtraCodecs` 做 `javap -c` 核实 |
| U-2 | `SizedFluidIngredient.FLAT_CODEC` 对 `tag` 形式的实际接受情况 | 已用 `javap -c` 确认 `FLAT_CODEC` 基于 `FluidIngredient.MAP_CODEC_NONEMPTY = makeMapCodec() = dispatchMapOrElse(..., fallback = singleOrTagCodec())`，且 `singleOrTagCodec` 的 `xor` 两支字段名为 `fluid` / `tag` | 结论「`{"tag":...,"amount":N}` 可用」来自 codec 结构与失败信息推断；**TFC 官方 215 个相关配方文件中 0 个使用 tag 形式**，无实机加载样例佐证 |
| U-3 | `RecipeManager` 对同一 `RecipeType` 下多个 `matches` 成功的配方如何选择 | 已确认 `PotBlockEntity` 用 `getRecipeManager().getRecipeFor(TFCRecipeTypes.POT.get(), ...)`（`PotBlockEntity.java:212-215`），且三种 pot serializer 共用 `tfc:pot` 类型 | 采用顺序由原版 `RecipeManager` 内部实现决定，**本仓库无 `net/minecraft` 源码**，未逐行核实其遍历顺序；文中已按「实现依赖顺序、TFC 数据靠互斥避免冲突」谨慎表述 |
| U-4 | `food_combining` 在 `RecipeManager.byType(CRAFTING)` 桶中的具体注册路径 | 已核实 `FoodCombiningCraftingRecipe` 无 `getType()`、父类 `CustomRecipe` 无 `getType()`、`CraftingRecipe.getType()` 字节码返回 `RecipeType.CRAFTING` | recipe type = `minecraft:crafting` 的结论**已由字节码确认**；但「原版 `RecipeManager` 用 `recipe.getType()` 作为分桶键」这一环节属原版实现，本仓库无源码，未逐行核实 |
| U-5 | `SoupPotRecipe.getOutput` 中 `FoodData(4, water, saturation, 0, nutrition, 3.5f)` 各参数的确切含义 | 已读 `SoupPotRecipe.java:116` 与常量 `SOUP_HUNGER_VALUE = 4`、`SOUP_DECAY_MODIFIER = 3.5f` | `FoodData` 的构造参数顺序需读 `net/dries007/tfc/common/component/food/FoodData.java` 才能逐项命名；本组未展开（不影响 pot_soup 的 JSON 字段结论） |
| U-6 | `tfc:heat`（`HeatIngredient`）与 `tfc:fluid_content`（`FluidContentIngredient`）的 JSON 字段 | 已确认二者在 `TFCIngredients.java:46-47` 注册，且各自 `CODEC` 存在 | 未逐行读取这两个类的 `CODEC`，故 A4-3.2 表中标注为「见该类 `CODEC`」而未给出字段名 |

除以上 6 条外，本组所有字段表条目均能在指明的源码行找到出处。
