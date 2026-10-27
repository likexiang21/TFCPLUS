# TerraFirmaCraft 4.2.10 配方 JSON 字段级考证 —— 组 A5

> 版本基准：TerraFirmaCraft-NeoForge-1.21.1-4.2.10 / Minecraft 1.21.1 / NeoForge 21.1.248
> 证据来源（全部为本地文件，无网络依赖）：
> - 反编译源码根：`moddev/src-ref/TFC-decompiled`（下文相对路径均以此为根）
> - 真实 jar 解包内容：`moddev/jar-extract`（下文「jar 内路径」以 `jar-extract` 为根）
> - jar 条目清单（交叉核对用）：`moddev/inventory/TFC.resources.txt`
> - 反编译产物**没有参数名与注释**，但 `CODEC` 定义、`record` 组件、字段常量完整可读；TFC 自有类的字段一律从**该类自身的 `CODEC` 逐行读出**确认。
> - **Minecraft 本体类（`net.minecraft.world.item.crafting.*`、`net.neoforged.*`）不在本反编译树中**。凡涉及它们的结论均在正文显式标注依据来源，并在「附录 A5-C」集中列出未核实项。
> - **字节码交叉验证（本组额外引入）**：`.minecraft/libraries/net/minecraft/client/1.21.1-20240808.144430/client-1.21.1-20240808.144430-srg.jar`，用 `javap -p -c` 读取原版类成员与常量池字符串。该 jar 中的原版类使用官方命名（字段名明文），可直接读出 `CODEC` 的 `fieldOf("...")` / `optionalFieldOf("...", default)` 参数与默认值，从而**把原版 `crafting_shaped` / `crafting_shapeless` 的字段名、必需性、默认值从「按 JSON 归纳」升级为「字节码确认」**。下文凡标注「（字节码确认）」处即指此来源。

## 组 A5 覆盖范围

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

### 关于「crafting 目录 3001 个文件」的口径澄清

任务描述提到 TFC 的 `data/tfc/recipe/crafting/` 下有 3001 个文件。实测结果如下（两条独立证据一致）：

| 口径 | 数量 | 证据 |
| --- | --- | --- |
| jar 清单中 `data/tfc/recipe/crafting` 前缀条目总数 | **3001** | `moddev/inventory/TFC.resources.txt` 中以 `data/tfc/recipe/crafting` 开头的行数为 3001（其中 106 条是目录条目，如 `data/tfc/recipe/crafting/jar/`） |
| jar 清单中实际 `.json` 文件数 | **2895** | 同上清单中匹配 `*.json` 的行数为 2895 |
| `jar-extract/data/tfc/recipe/crafting` 下实际 `.json` 文件数 | **2895** | `Get-ChildItem -Recurse -Filter *.json` 实测 |
| 该目录下全部文件（不限扩展名） | **2895** | 无额外非 JSON 文件 |

结论：**3001 是「文件 + 目录条目」的合计**，真实配方 JSON 为 **2895** 个。下文所有分布统计均以 2895 为分母。

### crafting 目录内 `type` 分布（实测，按 `"type":"<id>"` 全量匹配，含嵌套字段）

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

## [R-24] tfc:blast_furnace —— 高炉熔炼

### R-24.1 类型标识与实现类

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

### R-24.2 完整字段表

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

### R-24.3 真实 JSON 样例（该目录下全部文件）

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

### R-24.4 游戏内触发条件与调用点

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

### R-24.5 限制与陷阱

- **`fluid` 的 `amount` 决定倍率，不决定「够不够」**：`matches(FluidStack)` 只用 `ingredient().test(...)`，即只要流体种类对、数量 > 0 就能匹配；不足一个 `amount` 整数倍时余数保留在输入槽（`assembleFluidOutput` 只 `shrink` 整数倍部分，`BlastFurnaceRecipe.java:88-89`）。当整数倍为 0 时 `outputFluid.setAmount(0)`，产出空流体，`fill` 无效果。
- **催化剂的种类由数据包硬编码在唯一一条配方里**，一条高炉配方只有一个 `catalyst`；若要支持多种催化剂，需在 `catalyst` 使用 tag 或数组形式。
- **高炉配方与「配方类型」一一对应**：`get(Level, FluidStack)`（`BlastFurnaceRecipe.java:65-67`）返回**第一条**匹配的配方（`RecipeHelpers.getHolder` 线性取首个，`RecipeHelpers.java:163-169`），因此多条高炉配方之间没有优先级字段，靠数据包加载顺序决定。
- 该配方不产生物品，`INoopInputRecipe` 的 `assemble(NoopInput, ...)` 抛异常（`INoopInputRecipe.java:28-31`），故 JEI/EMI 展示需要各自的兼容层（`compat/jei/category/BlastFurnaceRecipeCategory.java:44-46`、`compat/emi/recipe/EmiBlastFurnaceRecipe.java`）。

---

## [R-25] minecraft:crafting_shaped —— 原版有序合成（TFC 数据包实测）

### R-25.1 类型标识与实现类

| 项目 | 值 | 证据 |
| --- | --- | --- |
| JSON `type` | `minecraft:crafting_shaped` | 真实 JSON 实测（TFC 数据包 1669 个文件使用该 type） |
| serializer id | `minecraft:crafting_shaped`（原版 `RecipeSerializer`） | 原版注册；**Minecraft 本体，不在本反编译树中** |
| recipe type id | `minecraft:crafting` | **字节码确认**：`CraftingRecipe#getType()` 的 default 实现返回 `RecipeType.CRAFTING`；`ShapedRecipe` 未覆写它。原版类不在本反编译树中 |
| 实现类全名 | `net.minecraft.world.item.crafting.ShapedRecipe` | 原版类；`AdvancedShapedRecipe` 的 `extends ShapedRecipe`（`net/dries007/tfc/common/recipes/AdvancedShapedRecipe.java:49-50`）可间接证明其存在与继承关系 |
| 辅助 pattern 类型 | `net.minecraft.world.item.crafting.ShapedRecipePattern` | `AdvancedShapedRecipe.java:51` 直接复用 `ShapedRecipePattern.MAP_CODEC` / `STREAM_CODEC`（`AdvancedShapedRecipe.java:51-52`） |

**TFC 未注册、也未替换该 serializer**：`TFCRecipeSerializers`（`TFCRecipeSerializers.java:56-83`）中的 26 个 `Id` 常量里没有任何 `crafting_shaped` / `crafting_shapeless` 条目；`TFCRecipeTypes`（`TFCRecipeTypes.java:43-63`）中的 20 个 recipe type 里也没有 `crafting`。因此 `minecraft:crafting_shaped` 100% 走原版实现。

**TFC 未用 mixin 接管原版合成**：`net/dries007/tfc/mixin/` 下共 32 个顶层 mixin + `accessor` / `client` 子包，逐一核对后**没有任何一个针对 `ShapedRecipe`、`ShapelessRecipe`、`CraftingMenu`、`RecipeBook*`、`CraftingInput`**。唯一与配方加载有关的 mixin 是 `RecipeManagerMixin.java:29-35`，它只在原版配方解析报错时调用 `SelfTests.reportExternalError()` 上报自检状态，不改变任何配方语义。

### R-25.2 完整字段表

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

### R-25.3 真实 JSON 样例（2 个，其中 1 个含 tag ingredient）

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

### R-25.4 游戏内触发条件

| 环节 | 说明 | 证据 |
| --- | --- | --- |
| 配方来源 | 数据包加载时由原版 `RecipeManager` 按 serializer id `minecraft:crafting_shaped` 实例化为 `ShapedRecipe` | 原版行为（**不在反编译树中**）；TFC 侧未注册同名 serializer，见 R-25.1 |
| 归类 | 归入 `RecipeType.CRAFTING`（`minecraft:crafting`），与 shapeless、TFC 的 advanced 两类**同处一个类型桶** | **字节码确认**：`CraftingRecipe#getType()` 是 default 方法，字节码为 `getstatic RecipeType.CRAFTING`；`ShapedRecipe` 未覆写 `getType()`，`AdvancedShapedRecipe` 也未覆写，故三类同桶 |
| 触发菜单 | 任何 `CraftingMenu` 及其子类。TFC 的工作台容器 `net/dries007/tfc/common/container/TFCWorkbenchContainer` **直接 `extends CraftingMenu`**（`TFCWorkbenchContainer.java:19-20`），构造器 `super(id, playerInventory)` / `super(id, playerInventory, access)`（`:24`、`:29`）完全委托原版，只用 `stillValid` 追加了「必须是 `TFCTags.Blocks.WORKBENCHES` 且距离 ≤ 8 格」的判定（`:33-35`） | `net/dries007/tfc/common/container/TFCWorkbenchContainer.java` |
| 判定 | 原版 `CraftingMenu` 依次对 `RecipeType.CRAFTING` 下的配方调用 `matches(CraftingInput, Level)`；`ShapedRecipe#matches` 内部做宽度/高度平移与镜像匹配 | 原版行为；TFC 在 `AdvancedShapedRecipe` 中通过 `RecipeHelpers.translateMatch` **重写了同样的平移/镜像逻辑**，可用于反证原版语义（`RecipeHelpers.java:183-214`） |
| 其余入口 | `CraftingMenu` 之外的任何自定义合成逻辑若按 `RecipeType.CRAFTING` 取配方，也会拿到这些配方 | — |

补充：TFC 数据包中**有 1 个 `tfc:food_combining` 与 1 个 `tfc:casting_crafting`** 顶层配方（位于 crafting 目录），它们的 serializer 分别是 `RecipeSerializerImpl(FoodCombiningCraftingRecipe.INSTANCE)` 与 `RecipeSerializerImpl(CastingCraftingRecipe.INSTANCE)`（`TFCRecipeSerializers.java:80-81`），属于「单例（无字段）合成配方」，实现类 `FoodCombiningCraftingRecipe` / `CastingCraftingRecipe` 直接实现 `CraftingRecipe` 并参与 `RecipeType.CRAFTING`，但它们**不是本组的 R-25 类型**，仅在此说明该目录出现次数。

### R-25.5 限制与陷阱

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

## [R-26] minecraft:crafting_shapeless —— 原版无序合成（TFC 数据包实测）

### R-26.1 类型标识与实现类

| 项目 | 值 | 证据 |
| --- | --- | --- |
| JSON `type` | `minecraft:crafting_shapeless` | 字节码确认：`RecipeSerializer` 接口 `<clinit>` 的常量池包含 `ldc // String crafting_shapeless`（`javap -p -c net.minecraft.world.item.crafting.RecipeSerializer`）；TFC 数据包中 569 个文件使用该 type |
| serializer 常量 | `RecipeSerializer.SHAPELESS_RECIPE` | 字节码确认：`javap -p net.minecraft.world.item.crafting.RecipeSerializer` 列出 `public static final RecipeSerializer<ShapelessRecipe> SHAPELESS_RECIPE` |
| recipe type id | `minecraft:crafting` | **字节码确认**：`CraftingRecipe#getType()` 是 default 方法，其字节码为 `getstatic RecipeType.CRAFTING`；`ShapelessRecipe` 未覆写 `getType()` |
| 实现类全名 | `net.minecraft.world.item.crafting.ShapelessRecipe` | 原版类（**不在本反编译树中**）；`AdvancedShapelessRecipe` 的 `extends ShapelessRecipe`（`AdvancedShapelessRecipe.java:52-53`）可间接证明 |
| 状态字段 | `group` / `category` / `result` / `ingredients`（**共 4 个，无 `showNotification`**） | 字节码确认：`javap -p net.minecraft.world.item.crafting.ShapelessRecipe` 的实例字段列表 |

**TFC 未替换该 serializer，也未用 mixin 接管**：见 R-25.1 的两条结论（`TFCRecipeSerializers` 无该条目；`mixin` 包中无任何针对 `ShapelessRecipe` 的注入）。

### R-26.2 完整字段表

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

### R-26.3 真实 JSON 样例（2 个）

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

### R-26.4 游戏内触发条件

| 环节 | 说明 | 证据 |
| --- | --- | --- |
| 实例化 | 原版 `RecipeManager` 按 serializer id `minecraft:crafting_shapeless` 构造 `ShapelessRecipe` | 字节码确认 serializer id；TFC 未注册同名 serializer |
| 归类 | `RecipeType.CRAFTING`（与 shaped、advanced 两类同桶） | `CraftingRecipe#getType()` default 字节码 |
| 触发菜单 | 任何 `CraftingMenu` 子类；TFC 的 `TFCWorkbenchContainer` 直接继承 `CraftingMenu`（`TFCWorkbenchContainer.java:19-20`） | `net/dries007/tfc/common/container/TFCWorkbenchContainer.java` |
| 匹配 | 原版 `ShapelessRecipe#matches(CraftingInput, Level)`：把非空输入物品与 `ingredients` 逐项配对 | 原版行为（**不在反编译树中**）；旁证：TFC 的 `AdvancedShapelessRecipe` 复刻了同一套「输入网格遍历」思路（`AdvancedShapelessRecipe.java:91-99`） |

### R-26.5 限制与陷阱

- **原料个数上限为 9（3×3）**：字节码给出错误文本 `Too many ingredients for shapeless recipe`（上限值由 `ShapedRecipePattern` 的 3×3 推出）。TFC 的 advanced 版本把这一上限写成了显式常量表达式（`ShapedRecipePattern.getMaxHeight() * ShapedRecipePattern.getMaxWidth()`，`AdvancedShapelessRecipe.java:56`）。
- **零原料非法**：字节码给出 `No ingredients for shapeless recipe`。
- **不能用 `remainder` / `modifiers`**：需要「工具自动磨损」或「复制输入」时必须改用 R-28。
- **`category` 在本类型是必需字段**，漏写会导致配方解析失败（与直觉相反，这点在与其它模组/版本对照时最容易踩坑）。
- **不支持 `show_notification`**：写了该键会在 `ExtraCodecs`/`RecordCodecBuilder` 的严格解析下报错（未知字段），不要照搬有序合成的写法。

---

## [R-27] tfc:advanced_shaped_crafting —— TFC 扩展有序合成

### R-27.1 类型标识与实现类

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

### R-27.2 完整字段表

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

### R-27.3 与父类 `ShapedRecipe` 的行为差异

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

### R-27.4 真实 JSON 样例（3 个，另附 show_notification 示意）

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

### R-27.5 触发条件与调用点

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

### R-27.6 数据生成侧：TFC 自己在什么条件下产出 advanced 配方

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

### R-27.7 限制与陷阱

- **不能指定 `category` / `group`**：JSON 里写了会解析失败（CODEC 无这两项），且值恒为 `MISC` / `""`。若某个配方必须在配方书里归到别的页签，只能用原版 `minecraft:crafting_shaped`（但那样就没有 modifiers 了）。
- **`result` 必须写 `modifiers` 才能走左侧分支**：`ItemStackProvider.CODEC` 是 `Codec.either(带 modifiers 的 record, 纯 ItemStack)`，其中 `modifiers` 用 `fieldOf("modifiers")`（**必需**）。因此 **`{"stack":{...}}` 这样只写 `stack` 而不写 `modifiers` 的对象是非法 JSON**（左侧分支缺 `modifiers` 失败，右侧 `ItemStack.CODEC` 也解析不了 `stack` 键）。全库实测印证：不存在「含 `"result":{"stack"` 但整文件无 `modifiers`」的配方（检索结果为 0 个文件）。合法写法只有两种：
  - `"result": {"count":1,"id":"..."}`（纯物品）
  - `"result": {"stack":{...},"modifiers":[...]}` 或 `"result": {"modifiers":[...]}`（`stack` 可省略，默认 `ItemStack.EMPTY`）
- **`remainder` 的类型与 `result` 完全相同**，也必须写 `modifiers`：TFC 数据包中 655 个 advanced 配方里的 `remainder` 全部是 `{"modifiers":[...]}` 形式，**没有任何一个用字符串或纯物品对象**（实测：匹配 `"remainder":` 后跟非 `{` 的文件数为 0）。
- **`input_row` / `input_column` 只影响「哪个槽位被当作主输入」**，**不影响匹配**（匹配完全由 `pattern` + `key` 决定）。填错只会导致 modifier 取到错的物品（例如把 `damage_crafting_remainder` 作用到原料上而不是工具上），不会导致配方无法合成。
- **越界的 `input_row` / `input_column` 没有显式校验**：`dissolveRowColumn` 只做 `column + row * width`（`RecipeHelpers.java:179-181`），若索引超出 `pattern` 范围，`translateMatch` 会返回 `-1`，此时 `assemble` 用 `ItemStack.EMPTY` 作为输入（`AdvancedShapedRecipe.java:71`）。
- **`isSpecial()` 由 `result.dependsOnInput()` 决定，不看 `remainder`**：若只写了 `remainder`（如 `bismuth.json`），`isSpecial()` 仍为 `false`。

---

## [R-28] tfc:advanced_shapeless_crafting —— TFC 扩展无序合成

### R-28.1 类型标识与实现类

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

### R-28.2 完整字段表

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

### R-28.3 与父类 `ShapelessRecipe` 的行为差异

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

### R-28.4 真实 JSON 样例（4 个）

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

### R-28.5 触发条件与调用点

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

### R-28.6 限制与陷阱

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

## [R-29] 通用输出与原料（ItemStackProvider / ItemStackModifier / TFCIngredients）

> 本节是**全局公用章节**：`ItemStackProvider`、`ItemStackModifier`、`TFCIngredients` 被 TFC 的绝大多数配方类型复用（不止本组的 R-24 ~ R-28），其中 `outputs/*Modifier` 也出现在 `tfc:heating`、`tfc:barrel_*`、`tfc:anvil`、`tfc:casting`、`tfc:pot`、`tfc:quern` 等类型的 `result_item` / `output_item` 字段中。主控文档可直接引用本节内容。

### R-29.1 ItemStackProvider —— 通用输出包装

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

#### R-29.1.1 JSON 形态（**只有两种合法写法**）

| 形态 | JSON 写法 | 触发分支 | 说明 |
| --- | --- | --- | --- |
| **形态 A：纯物品** | `{"count":1,"id":"tfc:xxx"}`（或任何合法 `ItemStack` JSON） | `Codec.either` 的**右侧** `ItemStack.CODEC` | 解析后经 `ItemStackProvider.of(stack)` 包装为「无 modifier」的 provider；序列化时若 `modifiers` 为空也会退化为这种形态 |
| **形态 B：带 modifiers** | `{"stack":{...},"modifiers":[{...},{...}]}`，其中 `stack` 可省略 | 左侧 `RecordCodecBuilder` | `stack` 省略 → 默认 `ItemStack.EMPTY`；`modifiers` **必须存在** |

**关键限制：`modifiers` 是必需字段（`fieldOf`，非 `optionalFieldOf`）。** 因此

```json
"result": {"stack": {"count":1,"id":"tfc:xxx"}}      // 非法！
```

是**不可解析**的：左侧分支因缺 `modifiers` 失败，右侧 `ItemStack.CODEC` 也不认识 `stack` 这个键。实测印证：全库不存在「含 `"result":{"stack"` 但整文件不含 `modifiers`」的配方（命中 0 个文件）。合法形式只有 `{"count":N,"id":"..."}`、`{"modifiers":[...]}`、`{"stack":{...},"modifiers":[...]}` 三种。

#### R-29.1.2 字段表

| 字段名 | 类型 | 必需/可选 | 默认值 | 语义 | 源码行 |
| --- | --- | --- | --- | --- | --- |
| `stack` | `ItemStack` | 可选 | `ItemStack.EMPTY` | 输出基底物品。若为 `EMPTY` 且 modifier 链中第一个是 `tfc:copy_input` 之类「替换型」modifier，则最终以输入物品为基底 | `ItemStackProvider.java:35` |
| `modifiers` | `ItemStackModifier` 数组 | **必需**（当使用形态 B 时） | 无 | 依次作用于基底物品的修饰器列表，顺序即执行顺序 | `ItemStackProvider.java:35` |

#### R-29.1.3 求值算法（这是理解所有 modifier 语义的前提）

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

#### R-29.1.4 真实样例

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

### R-29.2 ItemStackModifier —— 修饰器清单（22 种）

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

#### R-29.2.1 全部 22 种 modifier 一览

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

#### R-29.2.2 逐项详解

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

#### R-29.2.3 modifier 与 Context 的交互汇总

| modifier | 行为受 `NO_RANDOM_CHANCE` 影响？ | 依赖 `RecipeHelpers.getCraftingPlayer()`？ | 依赖 `RecipeHelpers.getCraftingInput()`？ |
| --- | --- | --- | --- |
| `tfc:chance` | **是**（改为打印 tooltip） | 否 | 否 |
| `tfc:extra_products` | **是**（不给物品） | **是** | 否 |
| `tfc:damage_crafting_remainder` | 否 | **是**（有玩家时按玩家位置损伤） | 否 |
| `tfc:add_bait_to_rod` / `tfc:add_powder` / `tfc:copy_oldest_food` / `tfc:meal` | 否 | 否 | **是** |
| 其余 | 否 | 否 | 否 |

`RecipeHelpers.getCraftingInput()` 是一个 `ThreadLocal<Iterable<ItemStack>>`（`RecipeHelpers.java:63`），由 `AdvancedShapedRecipe.assemble` / `AdvancedShapelessRecipe.assemble` / `PotBlockEntity` 在调用前 `setCraftingInput(...)`、调用后 `clearCraftingInput()`（`RecipeHelpers.java:70-84`；`AdvancedShapedRecipe.java:69, 73`；`AdvancedShapelessRecipe.java:72, 74`）。这意味着**只有高级合成与锅具配方会自动提供输入上下文**；其它配方类型若使用这些 modifier，`getCraftingInput()` 会是空列表。

### R-29.3 TFCIngredients —— 自定义原料类型清单（7 种）

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

#### R-29.3.1 一览表

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

#### R-29.3.2 逐项详解

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

#### R-29.3.3 `PreciseIngredient` —— 展示友好的自定义 ingredient 基接口

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

### R-29.4 其它可用的 ingredient 形式（全局）

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

### R-29.5 相关辅助类速查

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

## 附录 A5-A：本组数据统计汇总

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

## 附录 A5-B：证据索引（关键源码行）

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

## 附录 A5-C：未能核实项（明确列出检查过的文件）

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

