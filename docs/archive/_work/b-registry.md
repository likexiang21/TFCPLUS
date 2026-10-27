# Firmalife 注册清单与类结构表（中间材料 B）

- 分析对象：`D:\111\最强服务器\.minecraft\versions\Essential TerraFirmaCraft (TFC)\moddev\src-ref\Firmalife`
- Java 源码根（下文所有相对路径均以此为基准）：`src/main/java/com/eerussianguy/firmalife/`
- 目标 MC / 加载器：Minecraft 1.21.1 + NeoForge；依赖 TFC `TerraFirmaCraft-NeoForge-1.21.1-4.2.10`
- 所有事实均来自上述源码与 TFC jar 的 `javap` 输出；无法确认者显式标注「未能核实」。
- 表格说明：注册名为该对象在注册表里的 `ResourceLocation` 路径，命名空间均为 `firmalife`（除 TFC 注册表自带者外）。

---

## 1. `common/recipes/` 配方类

### 1.1 来源文件与注册入口

| 文件（相对 Firmalife 仓库根） | 作用 |
| --- | --- |
| `src/main/java/com/eerussianguy/firmalife/common/recipes/FLRecipeTypes.java` | 注册 8 个自定义 `RecipeType` 与 2 个 `PotOutput.OutputType` |
| `src/main/java/com/eerussianguy/firmalife/common/recipes/FLRecipeSerializers.java` | 注册 10 个 `RecipeSerializer` |
| `src/main/java/com/eerussianguy/firmalife/common/recipes/*.java` | 各配方类本体 |
| `src/main/java/com/eerussianguy/firmalife/common/recipes/data/*.java` | 4 个 `ItemStackModifier` 及其注册表 |

### 1.2 `FLRecipeTypes` 注册清单

来源：`common/recipes/FLRecipeTypes.java`。该类的每个条目都是 `TFCRecipeTypes.Id<R>` 包装 `DeferredHolder<RecipeType<?>, RecipeType<?>>`，通过私有 `register(String)` 用匿名 `RecipeType` 实现注册，`toString()` 返回裸名（不带命名空间）。

| 常量 | 注册名 | 泛型配方类型 |
| --- | --- | --- |
| `FLRecipeTypes.DRYING` | `firmalife:drying` | `DryingRecipe` |
| `FLRecipeTypes.SMOKING` | `firmalife:smoking` | `SmokingRecipe` |
| `FLRecipeTypes.MIXING_BOWL` | `firmalife:mixing_bowl` | `MixingBowlRecipe` |
| `FLRecipeTypes.OVEN` | `firmalife:oven` | `OvenRecipe` |
| `FLRecipeTypes.VAT` | `firmalife:vat` | `VatRecipe` |
| `FLRecipeTypes.STOMPING` | `firmalife:stomping` | `StompingRecipe` |
| `FLRecipeTypes.PRESS` | `firmalife:press` | `PressRecipe` |
| `FLRecipeTypes.CENTRIFUGE` | `firmalife:centrifuge` | `CentrifugeRecipe` |
| `FLRecipeTypes.STINKY_SOUP` | `firmalife:stinky_soup`（注册到 `PotOutput.KEY` 的 `OutputType`，不是 RecipeType） | `PotOutput.OutputType` |
| `FLRecipeTypes.BOWL` | `firmalife:bowl`（同上，注册到 `PotOutput.KEY`） | `PotOutput.OutputType` |

注册片段关键行：

```java
public static final DeferredRegister<RecipeType<?>> RECIPE_TYPE = DeferredRegister.create(Registries.RECIPE_TYPE, MOD_ID);
public static final DeferredRegister<PotOutput.OutputType> POT_OUTPUT_TYPE = DeferredRegister.create(PotOutput.KEY, MOD_ID);
public static final Id<DryingRecipe> DRYING = register("drying");
public static final DeferredHolder<PotOutput.OutputType, PotOutput.OutputType> STINKY_SOUP =
    POT_OUTPUT_TYPE.register("stinky_soup", () -> StinkySoupRecipe.OUTPUT_TYPE);
```

### 1.3 `FLRecipeSerializers` 注册清单

来源：`common/recipes/FLRecipeSerializers.java`。除 `PRESS` 用自定义的 `P_CODEC` / `P_STREAM_CODEC` 外，其余均使用同名类的 `CODEC` / `STREAM_CODEC`，封装进 TFC 的 `RecipeSerializerImpl<>(codec, stream)`。

| 常量 | 注册名 | 使用的 Codec 字段 |
| --- | --- | --- |
| `FLRecipeSerializers.DRYING` | `firmalife:drying` | `DryingRecipe.CODEC` / `STREAM_CODEC` |
| `FLRecipeSerializers.SMOKING` | `firmalife:smoking` | `SmokingRecipe.CODEC` / `STREAM_CODEC` |
| `FLRecipeSerializers.STOMPING` | `firmalife:stomping` | `StompingRecipe.CODEC` / `STREAM_CODEC` |
| `FLRecipeSerializers.MIXING_BOWL` | `firmalife:mixing_bowl` | `MixingBowlRecipe.CODEC` / `STREAM_CODEC` |
| `FLRecipeSerializers.OVEN` | `firmalife:oven` | `OvenRecipe.CODEC` / `STREAM_CODEC` |
| `FLRecipeSerializers.STINKY_SOUP` | `firmalife:stinky_soup` | `StinkySoupRecipe.CODEC` / `STREAM_CODEC` |
| `FLRecipeSerializers.BOWL_POT` | `firmalife:bowl_pot` | `BowlPotRecipe.CODEC` / `STREAM_CODEC` |
| `FLRecipeSerializers.VAT` | `firmalife:vat` | `VatRecipe.CODEC` / `STREAM_CODEC` |
| `FLRecipeSerializers.PRESS` | `firmalife:press` | `PressRecipe.P_CODEC` / `P_STREAM_CODEC` |
| `FLRecipeSerializers.CENTRIFUGE` | `firmalife:centrifuge` | `CentrifugeRecipe.CODEC` / `STREAM_CODEC` |

注意：`KegRecipe` **没有**自己的 recipe type / serializer，它复用 TFC 的 `tfc:barrel_instant`、`tfc:barrel_instant_fluid`、`tfc:barrel_sealed`。

### 1.4 配方总表

| 类名（全限定） | 注册名（type / serializer） | 基类 / 实现的接口 | 输入类型 | 说明 |
| --- | --- | --- | --- | --- |
| `common.recipes.DryingRecipe` | `firmalife:drying` / `firmalife:drying` | `extends ItemRecipe`（即 `INoopInputRecipe` + `IRecipePredicate<ItemStack>`） | `ItemStack` | 晒干/烘干；单物品输入 |
| `common.recipes.SmokingRecipe` | `firmalife:smoking` / `firmalife:smoking` | `extends ItemRecipe` | `ItemStack` | 烟熏（羊毛绳/菠萝绳挂在火坑上方） |
| `common.recipes.StompingRecipe` | `firmalife:stomping` / `firmalife:stomping` | `extends ItemRecipe` + 额外纹理与音效字段 | `ItemStack` | 踩踏木桶；带 `input_texture` / `output_texture` / `sound` |
| `common.recipes.PressRecipe` | `firmalife:press` / `firmalife:press` | `extends StompingRecipe` | `ItemStack` | 木桶压榨机；独立 `PRESS_CACHE` |
| `common.recipes.CentrifugeRecipe` | `firmalife:centrifuge` / `firmalife:centrifuge` | `extends ItemRecipe` | `ItemStack` | 离心机（需旋转动力） |
| `common.recipes.OvenRecipe` | `firmalife:oven` / `firmalife:oven` | `implements INoopInputRecipe, IRecipePredicate<ItemStack>` | `ItemStack` | 烤炉配方；含温度与时长 |
| `common.recipes.MixingBowlRecipe` | `firmalife:mixing_bowl` / `firmalife:mixing_bowl` | `implements ISimpleRecipe<MixingBowlBlockEntity.MixingBowlInventory>` | `MixingBowlInventory`（5 物品槽 + 1 流体罐） | 搅拌碗 |
| `common.recipes.VatRecipe` | `firmalife:vat` / `firmalife:vat` | `implements ISimpleRecipe<VatBlockEntity.VatInventory>` | `VatInventory`（1 物品槽 + 10000mB 罐） | 大桶（Vat） |
| `common.recipes.StinkySoupRecipe` | 无独立 type/serializer（沿用 `tfc:pot`），但注册 `PotOutput` 类型 `firmalife:stinky_soup` | `extends PotRecipe`（`ISimpleRecipe<IPotInventory>`） | `IPotInventory` | 臭汤；方形硬编码营养算法 |
| `common.recipes.BowlPotRecipe` | 无独立 type/serializer（沿用 `tfc:pot`），注册 `PotOutput` 类型 `firmalife:bowl` | `extends PotRecipe` | `IPotInventory` | 碗装成品（如披萨、派） |
| `common.recipes.KegRecipe` | 无（工具类） | 纯静态工具类，无 `Recipe` 实现 | `BarrelInventory` | 木桶（Keg）复用 TFC 木桶配方的匹配/装配逻辑 |
| `common.recipes.WrappedHeatingRecipe` | 无（`record` 工具类型） | `record WrappedHeatingRecipe(Function<ItemStack,ItemStack> output, float temperature, int duration, boolean oven)` | `ItemStack` | 统一 TFC `HeatingRecipe` 与 `OvenRecipe`，供烤炉上部使用 |

### 1.5 各类 CODEC / COD 定义片段与 JSON 字段

来源：各配方类文件。字段名即 JSON key。

**DryingRecipe / SmokingRecipe / CentrifugeRecipe**（三者结构相同，字段 `ingredient`、`result`）：

```java
public static final MapCodec<DryingRecipe> CODEC = RecordCodecBuilder.mapCodec(i -> i.group(
    Ingredient.CODEC.fieldOf("ingredient").forGetter(c -> c.ingredient),
    ItemStackProvider.CODEC.fieldOf("result").forGetter(c -> c.result)
).apply(i, DryingRecipe::new));
public static final IndirectHashCollection<Item, DryingRecipe> CACHE =
    IndirectHashCollection.createForRecipe(DryingRecipe::getValidItems, FLRecipeTypes.DRYING);
public static DryingRecipe getRecipe(ItemStack input)  // RecipeHelpers.getRecipe(CACHE, input, input.getItem())
```

**StompingRecipe**（额外 `input_texture`、`output_texture`、`sound`）：

```java
public static final MapCodec<StompingRecipe> CODEC = RecordCodecBuilder.mapCodec(instance -> instance.group(
    Ingredient.CODEC.fieldOf("ingredient").forGetter(c -> c.ingredient),
    ItemStackProvider.CODEC.fieldOf("result").forGetter(c -> c.result),
    ResourceLocation.CODEC.fieldOf("input_texture").forGetter(c -> c.inputTexture),
    ResourceLocation.CODEC.fieldOf("output_texture").forGetter(c -> c.outputTexture),
    BuiltInRegistries.SOUND_EVENT.byNameCodec().fieldOf("sound").forGetter(c -> c.sound)
).apply(instance, StompingRecipe::new));
public ResourceLocation getInputTexture(); public ResourceLocation getOutputTexture(); public SoundEvent getSound();
```

**PressRecipe**：字段与 `StompingRecipe` 完全一致，但用 `P_CODEC` / `P_STREAM_CODEC` 注册，并带独立缓存 `PRESS_CACHE`：

```java
public static final IndirectHashCollection<Item, PressRecipe> PRESS_CACHE =
    IndirectHashCollection.createForRecipe(PressRecipe::getValidItems, FLRecipeTypes.PRESS);
public static PressRecipe getPressRecipe(ItemStack input)
```

**OvenRecipe**（字段 `ingredient`、`result`、`temperature`、`duration`）：

```java
public static final MapCodec<OvenRecipe> CODEC = RecordCodecBuilder.mapCodec(i -> i.group(
    Ingredient.CODEC.fieldOf("ingredient").forGetter(c -> c.ingredient),
    ItemStackProvider.CODEC.fieldOf("result").forGetter(c -> c.outputItem),
    Codec.FLOAT.fieldOf("temperature").forGetter(c -> c.temperature),
    Codecs.POSITIVE_INT.fieldOf("duration").forGetter(c -> c.duration)
).apply(i, OvenRecipe::new));
public ItemStack assembleItem(ItemStack input)   // 输出保留输入的热量(HeatCapability)
public boolean isValidTemperature(float temperatureIn)  // temperatureIn >= temperature
```

**MixingBowlRecipe**（字段 `item_ingredients`、`fluid_ingredients`（可选）、`result_item`（可选，默认空）、`result_fluid`（可选，默认空））：

```java
Ingredient.CODEC.listOf().fieldOf("item_ingredients").forGetter(c -> c.itemIngredients),
SizedFluidIngredient.FLAT_CODEC.optionalFieldOf("fluid_ingredients").forGetter(c -> c.fluidIngredient),
ItemStack.CODEC.optionalFieldOf("result_item", ItemStack.EMPTY).forGetter(c -> c.resultItem),
FluidStack.CODEC.optionalFieldOf("result_fluid", FluidStack.EMPTY).forGetter(c -> c.resultFluid)
// 构造器末尾调用 FoodCapability.setNonDecaying(resultItem)
public boolean matches(MixingBowlBlockEntity.MixingBowlInventory inventory, Level level)
public ItemStack assemble(MixingBowlBlockEntity.MixingBowlInventory inventory, HolderLookup.Provider provider)
public Optional<SizedFluidIngredient> getFluidIngredient(); public FluidStack getResultFluid(); public FluidStack getDisplayFluid()
```

**VatRecipe**（字段 `input_item`、`input_fluid`、`output_item`（可选）、`output_fluid`（可选）、`length`、`temperature`、`jar_output`（可选）、`output_texture`（可选））：

```java
SizedIngredient.FLAT_CODEC.fieldOf("input_item").forGetter(c -> c.inputItem),
SizedFluidIngredient.FLAT_CODEC.fieldOf("input_fluid").forGetter(c -> c.inputFluid),
ItemStackProvider.CODEC.optionalFieldOf("output_item").forGetter(c -> c.outputItem),
FluidStack.OPTIONAL_CODEC.optionalFieldOf("output_fluid").forGetter(c -> c.outputFluid),
Codecs.POSITIVE_INT.fieldOf("length").forGetter(c -> c.length),
Codec.FLOAT.fieldOf("temperature").forGetter(c -> c.temperature),
ItemStack.OPTIONAL_CODEC.optionalFieldOf("jar_output").forGetter(c -> c.jarOutput),
ResourceLocation.CODEC.optionalFieldOf("output_texture").forGetter(c -> c.outputTexture)
public void assembleOutputs(VatBlockEntity vat, VatBlockEntity.VatInventory inventory)  // 返回 void；multiplier 逻辑
public boolean matches(VatBlockEntity.VatInventory container, Level level)
public ItemStack assemble(VatBlockEntity.VatInventory vatInventory, HolderLookup.Provider provider)  // 恒定返回 null
```

**StinkySoupRecipe**：`PotRecipe.CODEC.xmap(StinkySoupRecipe::new, Function.identity())`，即 JSON 结构与 TFC 锅配方完全一致（无新增字段）。内部 `record StinkOutput(ItemStack stack) implements PotOutput`。核心：

```java
public PotOutput getOutput(IPotInventory inventory)  // ingredientCount 每多 1 份，营养乘 (1 - 0.05f*i)；servings = (int)(ingredientCount/2f)+1
public static final PotOutput.OutputType OUTPUT_TYPE = (provider, nbt) -> new StinkOutput(ItemStack.parseOptional(provider, nbt.getCompound("item")));
```

**BowlPotRecipe**：`PotRecipe.CODEC` 嵌套 + 两个额外字段 `item_output`、`food`：

```java
public static final MapCodec<BowlPotRecipe> CODEC = RecordCodecBuilder.mapCodec(i -> i.group(
    PotRecipe.CODEC.forGetter(c -> c),                       // 直接继承 TFC 锅配方字段
    ItemStack.CODEC.fieldOf("item_output").forGetter(c -> c.itemOutput),
    FoodData.CODEC.fieldOf("food").forGetter(c -> c.food)
).apply(i, BowlPotRecipe::new));
public PotOutput getOutput(IPotInventory inv)  // new BowlOutput(item)，并 setFoodForDynamicItemOnCreate
public ItemStack getResultItem(HolderLookup.Provider access)
```

**KegRecipe**（工具类，无 CODEC）：提供 `getInstant/getInstantFluid/getSealed(BarrelInventory, Level)`、三个 `matches(...)` 重载、`assembleInstantFluid`、`assemble`、`onSealed`、`onUnsealed`，全部围绕 TFC `BarrelInventory` 与 `SealedBarrelRecipe`。

**WrappedHeatingRecipe**（`record`）：

```java
public record WrappedHeatingRecipe(Function<ItemStack, ItemStack> output, float temperature, int duration, boolean oven)
public static WrappedHeatingRecipe getRecipe(ItemStack stack)  // 先 OvenRecipe.getRecipe，再 HeatingRecipe.getRecipe
public static WrappedHeatingRecipe of(HeatingRecipe recipe)    // duration = 20*50 = 1000，oven=false
public static WrappedHeatingRecipe of(OvenRecipe recipe)       // duration = recipe.getDuration()，oven=true
public boolean isValidTemperature(float temperature); public ItemStack assemble(ItemStack input)
```

### 1.6 `common/recipes/data/` —— ItemStackModifier

来源：`common/recipes/data/FLItemStackModifiers.java` 及同包各文件。注册表 `FLItemStackModifiers.TYPES` 创建于 `ItemStackModifiers.KEY`。

| 类名 | 注册名 | 类型 | 说明（`apply` 行为） |
| --- | --- | --- | --- |
| `data.AddPiePanModifier` | `firmalife:add_pie_pan` | `enum implements ItemStackModifier`（单例 `INSTANCE`） | 给输出写入 `TFCComponents.BOWL` = 派盘（`FLItems.PIE_PAN`） |
| `data.CopyBowlModifier` | `firmalife:copy_bowl` | 同上 | 复制输入的碗组件；空则回退为原版 `Items.BOWL` |
| `data.CopyDynamicFoodModifier` | `firmalife:copy_dynamic_food` | 同上 | 复制输入食物的动态数据与创建日期，并复制碗组件 |
| `data.EmptyPanModifier` | `firmalife:empty_pan` | 同上，且 `dependsOnInput()` 返回 true | 返回碗内容物（派盘），默认 `FLItems.PIE_PAN` |
| `data.FLItemStackModifiers` | —（注册表本体） | `class` | 内部 `record Id<T extends ItemStackModifier>(DeferredHolder<...>)`，等价于 TFC 的 `ItemStackModifiers.Id` |

注册片段：

```java
public static final DeferredRegister<ItemStackModifierType<?>> TYPES = DeferredRegister.create(ItemStackModifiers.KEY, FirmaLife.MOD_ID);
public static final Id<AddPiePanModifier> ADD_PIE_PAN = register("add_pie_pan", AddPiePanModifier.INSTANCE);
// register() 内部：new ItemStackModifierType<>(MapCodec.unit(singleInstance), StreamCodec.unit(singleInstance))
```

---

## 2. `common/blockentities/` 方块实体

### 2.1 来源文件

`src/main/java/com/eerussianguy/firmalife/common/blockentities/`，注册入口 `FLBlockEntities.java`。

### 2.2 注册清单（`FLBlockEntities`）

注册名命名空间 `firmalife`。`Id<T>` 是 TFC 的 `TFCBlockEntities.Id<T>`（包装 `DeferredHolder<BlockEntityType<?>, BlockEntityType<T>>`）。

| 常量 | 注册名 | BE 类 | 关联方块（源码中的字段） |
| --- | --- | --- | --- |
| `TICK_COUNTER` | `tick_counter` | `FLTickCounterBlockEntity` | 7 种奶酪轮 + `JACK_O_LANTERNS.values()` |
| `TICKING_PLANT` | `ticking_plant` | `FLTickingPlantBlockEntity` | `FRUIT_TREE_SAPLINGS`、`FRUIT_TREE_GROWING_BRANCHES` |
| `OVEN_BOTTOM` | `oven_bottom` | `OvenBottomBlockEntity` | `CLAY_OVEN_BOTTOM`、`CURED_OVEN_BOTTOM`、`INSULATED_OVEN_BOTTOM` |
| `OVEN_TOP` | `oven_top` | `OvenTopBlockEntity` | `CLAY_OVEN_TOP`、`INSULATED_OVEN_TOP`、`CURED_OVEN_TOP` |
| `OVEN_HOPPER` | `oven_hopper` | `OvenHopperBlockEntity` | `CLAY_OVEN_HOPPER`、`CURED_OVEN_HOPPER` |
| `DRYING_MAT` | `drying_mat` | `DryingMatBlockEntity` | `FLBlocks.DRYING_MAT` |
| `SOLAR_DRIER` | `solar_drier` | `DryingMatBlockEntity` | `FLBlocks.SOLAR_DRIER` |
| `BEEHIVE` | `beehive` | `WoodenBeehiveBlockEntity` | `FLBlocks.BEEHIVE` |
| `CENTRIFUGE` | `centrifuge` | `CentrifugeBlockEntity` | `FLBlocks.CENTRIFUGE` |
| `SKEP` | `skep` | `SkepBlockEntity` | `FLBlocks.SKEP` |
| `COMPOST_TUMBLER` | `compost_tumbler` | `CompostTumblerBlockEntity` | `FLBlocks.COMPOST_TUMBLER` |
| `STRING` | `string` | `StringBlockEntity` | `WOOL_STRING`、`PINEAPPLE_YARN` |
| `MIXING_BOWL` | `mixing_bowl` | `MixingBowlBlockEntity` | `FLBlocks.MIXING_BOWL` |
| `BERRY_BUSH` | `berry_bush` | `FLBerryBushBlockEntity` | `FRUIT_TREE_LEAVES`、`STATIONARY_BUSHES` |
| `FOOD_SHELF` | `food_shelf` | `FoodShelfBlockEntity` | `FOOD_SHELVES.values()` |
| `HANGER` | `hanger` | `HangerBlockEntity` | `HANGERS.values()` |
| `JARBNET` | `jarbnet` | `JarbnetBlockEntity` | `JARBNETS.values()` |
| `KEG` | `keg` | `KegBlockEntity` | `KEGS.values()` |
| `KEG_SUB` | `keg_sub` | `KegSubBlockEntity` | `KEG_SUBS.values()` |
| `WINE_SHELF` | `wine_shelf` | `WineShelfBlockEntity` | `WINE_SHELVES.values()` |
| `STOMPING_BARREL` | `stomping_barrel` | `StompingBarrelBlockEntity` | `STOMPING_BARRELS.values()` |
| `BARREL_PRESS` | `barrel_press` | `BarrelPressBlockEntity` | `BARREL_PRESSES.values()` |
| `VAT` | `vat` | `VatBlockEntity` | `FLBlocks.VAT` |
| `ASHTRAY` | `ashtray` | `AshTrayBlockEntity` | `FLBlocks.ASHTRAY` |
| `STOVETOP_GRILL` | `stovetop_grill` | `StovetopGrillBlockEntity` | `FLBlocks.STOVETOP_GRILL` |
| `STOVETOP_POT` | `stovetop_pot` | `StovetopPotBlockEntity` | `FLBlocks.STOVETOP_POT` |
| `JARRING_STATION` | `jarring_station` | `JarringStationBlockEntity` | `FLBlocks.JARRING_STATION` |
| `PLATE` | `plate` | `PlateBlockEntity` | `FLBlocks.PLATE` |
| `GRAPE_PLANT` | `grape_plant` | `GrapePlantBlockEntity` | `GRAPE_STRING_PLANT_RED`、`GRAPE_STRING_PLANT_WHITE` |
| `LARGE_PLANTER` | `large_planter` | `LargePlanterBlockEntity` | `FLBlocks.LARGE_PLANTER` |
| `BONSAI_PLANTER` | `bonsai_planter` | `BonsaiPlanterBlockEntity` | `FLBlocks.BONSAI_PLANTER` |
| `HANGING_PLANTER` | `hanging_planter` | `HangingPlanterBlockEntity` | `FLBlocks.HANGING_PLANTER` |
| `QUAD_PLANTER` | `quad_planter` | `QuadPlanterBlockEntity` | `FLBlocks.QUAD_PLANTER` |
| `HYDROPONIC_PLANTER` | `hydroponic_planter` | `HydroponicPlanterBlockEntity` | `FLBlocks.HYDROPONIC_PLANTER` |
| `TRELLIS_PLANTER` | `trellis_planter` | `TrellisPlanterBlockEntity` | `FLBlocks.TRELLIS_PLANTER` |
| `CLIMATE_STATION` | `climate_station` | `ClimateStationBlockEntity` | `FLBlocks.CLIMATE_STATION` |
| `SPRINKLER` | `sprinkler` | `SprinklerBlockEntity` | `SPRINKLER`、`FLOOR_SPRINKLER` |
| `PUMPING_STATION` | `pumping_station` | `PumpingStationBlockEntity` | `FLBlocks.PUMPING_STATION` |
| `PICKER` | `picker` | `PickerBlockEntity` | `FLBlocks.PICKER` |
| `SWEEPER` | `sweeper` | `SweeperBlockEntity` | `FLBlocks.SWEEPER` |

### 2.3 方块实体明细

| 类名（`common.blockentities.X`） | 注册名 | 继承链 / 接口 | 是否 ticker | 关键 public 方法签名 |
| --- | --- | --- | --- | --- |
| `FLTickCounterBlockEntity` | `tick_counter` | `extends TickCounterBlockEntity` | 由方块驱动（`TickCounterBlockEntity` 自身计数） | `static void reset(Level, BlockPos)`；`BlockEntityType<?> getType()` |
| `FLTickingPlantBlockEntity` | `ticking_plant` | `extends TickingPlantBlockEntity` | 是（继承 TFC） | `static void reset(Level, BlockPos)`、`static void addTicks(Level, BlockPos, long)`、`static void setStemPos(Level, BlockPos, BlockPos)`、`getType()` |
| `FLBerryBushBlockEntity` | `berry_bush` | `extends BerryBushBlockEntity` | 继承 TFC | `getType()` |
| `ApplianceBlockEntity<C extends IItemHandlerModifiable & INBTSerializable<CompoundTag> & IHeatConsumer>` | 无（抽象） | `extends TickableInventoryBlockEntity<C> implements ICalendarTickable` | 是 | `ContainerData getSyncableData()`、`void tickTemperature()`、`void onTemperatureAdjusted()`、`void advanceForCalendar(long)`、`void ranOutDueToCalendar()`、`float getTemperature()`；嵌套 `static class ApplianceInventory implements IHeatConsumer, DelegateItemHandler, INBTSerializable<CompoundTag>, CrucibleLikeHeatBlock` |
| `BoilingBlockEntity<C extends IItemHandlerModifiable & INBTSerializable<CompoundTag> & IHeatConsumer & IFluidHandler>` | 无（抽象） | `extends ApplianceBlockEntity<C> implements ICalendarTickable, FluidTankCallback` | 是 | `void ranOutDueToCalendar()`、`void fluidTankChanged()`、`void setAndUpdateSlots(int)`、`abstract boolean isBoiling()`；嵌套 `static class BoilingInventory extends ApplianceInventory implements DelegateFluidHandler, FluidTankCallback`（`extractItem` 在沸腾时返回空） |
| `OvenBottomBlockEntity` | `oven_bottom` | `extends TickableInventoryBlockEntity<ItemStackHandler> implements ICalendarTickable, OvenLike` | 是（`OvenBottomBlockEntity::serverTick`） | `static void cure(Level, BlockState, BlockState, BlockPos)`、`static void serverTick(Level, BlockPos, BlockState, OvenBottomBlockEntity)`、`float getTemperature()`、`int getCureTicks()`、`void addCureTicks(int)`、`boolean light(BlockState)`、`void extinguish(BlockState)`、`void onAirIntake(int)`、`void onFuelConsumed()`；常量 `SLOT_FUEL_MIN=0`、`SLOT_FUEL_MAX=3` |
| `OvenTopBlockEntity` | `oven_top` | `extends ApplianceBlockEntity<ApplianceBlockEntity.ApplianceInventory> implements ICalendarTickable, OvenLike` | 是 | `static void cure(Level, BlockState, BlockState, BlockPos)`、`static void serverTick(...)`、`void tickTemperature()`、`void spreadHeat()`、`void extinguish()`、`void setInsulated(boolean)`、`int getTicksLeft(int slot)`、`int getCureTicks()`、`void addCureTicks(int)`、`void advanceForCalendar(long)`；常量 `SLOTS=4`、`SLOT_INPUT_START=0`、`SLOT_INPUT_END=3`、`TARGET_TEMPERATURE_STABILITY_TICKS=400`；嵌套 `static class OvenInventory extends ApplianceInventory` |
| `OvenHopperBlockEntity` | `oven_hopper` | `extends TickableInventoryBlockEntity<ItemStackHandler>` | 是 | `static void serverTick(...)`、`int getQueuedSlot()`；常量 `SLOTS=4` |
| `AshTrayBlockEntity` | `ashtray` | `extends InventoryBlockEntity<ItemStackHandler>` | 否 | `void updateBlockState()`；槽位限 1（`defaultInventory(1)`），单槽上限 16，仅接受 `TFCItems.POWDERS(WOOD_ASH)` |
| `DryingMatBlockEntity` | `drying_mat` / `solar_drier` | `extends SimpleItemRecipeBlockEntity<DryingRecipe>` | 是 | `static DryingMatBlockEntity dryingMat(BlockPos, BlockState)`、`static DryingMatBlockEntity solarDrier(...)`、`static void serverTick(...)`、`void ejectItem(Direction)`、`void updateCache()` |
| `SimpleItemRecipeBlockEntity<T extends ItemRecipe>` | 无（抽象，`drying_mat`/`string` 使用） | `extends InventoryBlockEntity<ItemStackHandler>` | 否（由外部 tick） | `abstract void updateCache()`、`T getCachedRecipe()`、`long getTicksLeft()`、`void start()`、`void finish()`、`void resetCounter()`、`ItemStack viewStack()`、`ItemStack readStack()`、`int getDuration()` |
| `StringBlockEntity` | `string` | `extends SimpleItemRecipeBlockEntity<SmokingRecipe>` | 是 | `static void serverTick(...)`、`void updateCache()` |
| `FoodShelfBlockEntity` | `food_shelf` | `extends InventoryBlockEntity<ItemStackHandler> implements ClimateReceiver` | 否 | `boolean isClimateValid()`、`Holder<FoodTrait> getFoodTrait()`、`Set<DeferredHolder<FoodTrait, FoodTrait>> getPossibleTraits()`、`ItemInteractionResult use(ItemStack, Player)`、`void updatePreservation(boolean)`、`void setValid(Level, BlockPos, boolean, int, ClimateType)`、`ModelData getModelData()` |
| `HangerBlockEntity` | `hanger` | `extends FoodShelfBlockEntity` | 否 | `Holder<FoodTrait> getFoodTrait()`、`boolean isItemValid(int, ItemStack)`、`Set<DeferredHolder<FoodTrait, FoodTrait>> getPossibleTraits()`（HUNG 系列） |
| `JarbnetBlockEntity` | `jarbnet` | `extends InventoryBlockEntity<ItemStackHandler>` | 否 | `long getTicksSinceUpdate()`、`void setLastUpdateTick(long)`、`long getLastUpdateTick()`、`void resetCounter()`、`ModelData getModelData()`；常量 `SLOTS=6` |
| `WineShelfBlockEntity` | `wine_shelf` | `extends InventoryBlockEntity<ItemStackHandler>` | 否 | `getModelData()`、`isItemValid(int, ItemStack)`（`FLTags.Items.WINE_BOTTLES`）；4 槽，单槽上限 1 |
| `PlateBlockEntity` | `plate` | `extends InventoryBlockEntity<ItemStackHandler>` | 否 | `void setRotation(Player)`、`float getRotation()`、`ItemStack viewStack()`；仅接受食物 |
| `KegBlockEntity` | `keg` | `extends TickableInventoryBlockEntity<KegBlockEntity.KegInventory> implements BarrelInventoryCallback, IRecipeTimer, ICalendarTickable` | 是 | `static void serverTick(Level, BlockPos, BlockState, KegBlockEntity)`、`void onSeal()`、`void onUnseal()`、`boolean canModify()`、`SealedBarrelRecipe getRecipe()`、`Component getRecipeTooltip()`、`long getSealedTick()`、`long getRecipeTick()`、`long getRemainingTicks()`、`int getRecipeDuration()`、`long getRemainingTime()`、`void tickPouring(Level, BlockPos, boolean, Direction)`、`IFluidHandler getSidedFluidInventory(Direction)`、`AbstractContainerMenu createMenu(int, Inventory, Player)`、`void ejectInventory()`、`void onCalendarUpdate(long)`；常量 `SLOTS=38`、`SLOT_FLUID_CONTAINER_IN=0`、`SLOT_FLUID_CONTAINER_OUT=1`、`SLOT_INPUT_START=2`、`SLOT_INPUT_END=37`、`CAPACITY=80000`；嵌套 `static class KegInventory implements DelegateItemHandler, DelegateFluidHandler, NonEmptyInput, FluidTankCallback, BarrelInventory, INBTSerializable<CompoundTag>` |
| `KegSubBlockEntity` | `keg_sub` | `extends TFCBlockEntity` | 否 | `IItemHandler getSidedInventory(Direction)`、`IFluidHandler getSidedFluidInventory(Direction)`、`BlockPos getZeroPos()`（全部代理到核心 `KegBlockEntity`） |
| `StompingBarrelBlockEntity` | `stomping_barrel` | `extends InventoryBlockEntity<ItemStackHandler>` | 否（由实体踩踏触发） | `void stomp(Entity)`、`ResourceLocation getTexture()`、`boolean isOutputMode()`、`int getStomps()`、`ItemStack readStack()`、`void causeTextureUpdate()`；常量 `MAX_GRAPES=16` |
| `BarrelPressBlockEntity` | `barrel_press` | `extends TickableInventoryBlockEntity<ItemStackHandler>` | 是 | `static void tick(...)`、`ItemInteractionResult push()`、`void squish()`、`WineType getWineType()`、`ItemStack tryFillWine(Level, BlockPos, ItemStack)`、`WineOutput getOutput()`、`boolean hasOutput()`、`float sinceWeLastTouched(float)`、`AbstractContainerMenu createMenu(int, Inventory, Player)`；常量 `SLOTS=9`、`SLOT_GRAPES=0`、`SLOT_WINE_IN=5`、`SLOT_WINE_OUT=6`、`SLOT_CORK=7`、`SLOT_LABEL=8`、`TIME=40L`；嵌套 `record WineOutput(WineType wine, KoppenClimateClassification koppen, int servings, List<Holder<FoodTrait>> traits)` |
| `MixingBowlBlockEntity` | `mixing_bowl` | `extends TickableInventoryBlockEntity<MixingBowlBlockEntity.MixingBowlInventory>` | 是（服务端 + 客户端 tick） | `static void serverTick(...)`、`static void clientTick(...)`、`IFluidHandler getSidedFluidInventory(Direction)`、`boolean isMixing()`、`int getRotationTimer()`、`boolean startMixing(Player)`、`MixingBowlRecipe getRecipe()`；常量 `SLOTS=5`；嵌套 `static class MixingBowlInventory implements NonEmptyInput, DelegateItemHandler, DelegateFluidHandler, INBTSerializable<CompoundTag>`（1 桶流体罐，受 `FLTags.Fluids.USABLE_IN_MIXING_BOWL` 限制） |
| `VatBlockEntity` | `vat` | `extends BoilingBlockEntity<VatBlockEntity.VatInventory>` | 是 | `static void serverTick(...)`、`boolean hasOutput()`、`ItemStack getOutput()`、`ItemStack takeOutput()`、`void setOutput(ItemStack, ResourceLocation)`、`ResourceLocation getJarTexture()`、`void updateCachedRecipe()`、`void handleCooking()`、`boolean isBoiling()`、`IFluidHandler getSidedFluidInventory(Direction)`、`void advanceForCalendar(long)`；常量 `CAPACITY=10_000`；嵌套 `static class VatInventory extends BoilingInventory implements NonEmptyInput`（含 `excess` 溢出列表与 `insertItemWithOverflow`） |
| `StovetopGrillBlockEntity` | `stovetop_grill` | `extends ApplianceBlockEntity<StovetopGrillBlockEntity.GrillInventory>` | 是 | `static void serverTick(...)`、`AbstractContainerMenu createMenu(int, Inventory, Player)`、`int getSlotStackLimit(int)`、`boolean isItemValid(int, ItemStack)`；常量 `SLOTS=5`；嵌套 `static class GrillInventory extends ApplianceInventory` |
| `StovetopPotBlockEntity` | `stovetop_pot` | `extends BoilingBlockEntity<StovetopPotBlockEntity.StovetopPotInventory>` | 是 | `static void serverTick(...)`、`IFluidHandler getSidedFluidInventory(Direction)`、`AbstractContainerMenu createMenu(int, Inventory, Player)`、`void updateCachedRecipe()`、`void advanceForCalendar(long)`、`boolean isBoiling()`、`boolean hasRecipeStarted()`、`boolean shouldRenderAsBoiling()`、`int getBoilingTicks()`、`ItemInteractionResult interactWithOutput(Player, ItemStack)`、`PotOutput getOutput()`、`void handleCooking()`、`void coolInstantly()`；常量 `SLOTS=5`、`DURATION=1000`；嵌套 `static class StovetopPotInventory extends BoilingInventory implements IPotInventory` |
| `JarringStationBlockEntity` | `jarring_station` | `extends TickableInventoryBlockEntity<ItemStackHandler>` | 是 | `static void tick(Level, BlockPos, BlockState, JarringStationBlockEntity)`、`ModelData getModelData()`；常量 `SLOTS=9`；每 60 tick 从朝向的 `VatBlockEntity` 取 `jarOutput` 灌入空罐 |
| `CentrifugeBlockEntity` | `centrifuge` | `extends TickableInventoryBlockEntity<ItemStackHandler> implements RotationSinkBlockEntity` | 是（服务端 + 客户端） | `static void serverTick(...)`、`static void clientTick(...)`、`boolean isWorking()`、`boolean startWorking()`、`float getRotationSpeed()`、`boolean isConnectedToNetwork()`、`float getRotationAngle(float)`、`Node getRotationNode()`；常量 `MANUAL_TICKS=180`、`MANUAL_SPEED=Mth.TWO_PI/MANUAL_TICKS`、`SLOTS=4` |
| `CompostTumblerBlockEntity` | `compost_tumbler` | `extends TickableInventoryBlockEntity<ItemStackHandler> implements RotationSinkBlockEntity` | 是 | `static void serverTick(...)`、`ItemInteractionResult use(ItemStack, Player, boolean)`、`void checkReady()`、`boolean canWork()`、`boolean isRotating()`、`int getTotal()`、`boolean isRotten()`、`boolean isReady()`、`void reset()`、`void calculateRotten()`、`long getReadyTicks()`、`Compost getCompost(ItemStack)`、`void resetCounter()`、`long getTicksSinceUpdate()`、`Node getRotationNode()`、`float getPercentage(AdditionType)`；常量 `MAX_COMPOST=32`、`MIN_COMPOST=16`、`SLOT_COMPOST=0`；嵌套 `record Compost(AdditionType type, int amount)` 与 `enum AdditionType { NONE, POISON, GREEN, BROWN, FISH, BONE, POTTERY, CHARCOAL }` |
| `SprinklerBlockEntity` | `sprinkler` | `extends TFCBlockEntity implements FluidTankCallback, ClimateReceiver` | 是 | `static void serverTick(...)`、`static Fluid searchForFluid(Level, BlockPos, Direction, boolean drain)`、`boolean isActive()`、`boolean isValid()`、`void setValid(Level, BlockPos, boolean, int, ClimateType)`；`MAX_COST=32`；私有 `record Path(BlockState state, BlockPos pos, int cost)` |
| `PumpingStationBlockEntity` | `pumping_station` | `extends TFCBlockEntity implements RotationSinkBlockEntity` | 否 | `boolean isPumping()`、`Node getRotationNode()` |
| `PickerBlockEntity` | `picker` | `extends TickableBlockEntity` | 是 | `static void tick(...)`、`float getExtensionLength()`、`long getLastPushed()`、`void push()`、`void pick()`（向下方 `QuadPlanterBlockEntity` 取成熟作物） |
| `SweeperBlockEntity` | `sweeper` | `extends TickableBlockEntity implements RotationSinkBlockEntity` | 是 | `static void serverTick(...)`、`Node getRotationNode()`；按旋转角度在 8 个方位上扫取相邻 `LargePlanterBlockEntity`（跳过 `QuadPlanterBlockEntity`） |
| `LargePlanterBlockEntity` | `large_planter` | `extends TickableInventoryBlockEntity<ItemStackHandler> implements ICalendarTickable, ClimateReceiver, IFarmland` | 是 | `static void serverTick(...)`、`void onCalendarUpdate(long)`、`void updateBlockState(BlockState)`、`long getLastGrowthTick()`、`void setLastGrowthTick(long)`、`long getLastCalendarUpdateTick()`、`void setLastCalendarUpdateTick(long)`、`void updateCache()`、`boolean checkValid()`、`boolean isClimateValid()`、`Component getInvalidReason()`、`int getTier()`、`int slots()`、`float getGrowth(int)`、`float getYield(int)`、`void setYield(int,float)`、`void setGrowth(int,float)`、`Plantable getPlantable(int)`、`float getNutrient(FarmlandBlockEntity.NutrientType)`、`void setNutrient(...)`、`void setNutrientWithoutSync(...)`、`float getNAbsorbed(int)`、`float getPAbsorbed(int)`、`float getKAbsorbed(int)`、`void addNutrients(int,float,float,float)`、`void resetAbsorbed(int)`、`void waterTick()`、`boolean addWater(float, Direction)`、`void drainWater(float)`、`void setValid(Level, BlockPos, boolean, int, ClimateType)`、`float getWater()`、`void afterGrowthTickStep(boolean)`、`float resetGrowthTo()`；`LARGE_PLANTER_SLOTS=1` |
| `QuadPlanterBlockEntity` | `quad_planter` | `extends LargePlanterBlockEntity` | 是 | `void loadUnique/saveUnique(CompoundTag)`、`void updateCache()`、`int slots()`（=4）、`float getGrowth(int)`、`void setGrowth(int,float)`、`float getYield(int)`、`void setYield(int,float)`、`Plantable getPlantable(int)` |
| `HydroponicPlanterBlockEntity` | `hydroponic_planter` | `extends QuadPlanterBlockEntity` | 是（`hydroponicServerTick`） | `static void hydroponicServerTick(Level, BlockPos, BlockState, HydroponicPlanterBlockEntity)`、`Component getInvalidReason()`、`float getWater()`、`boolean hasPipe()`、`boolean addWater(float, Direction)`（恒 false）、`void drainWater(float)`（空实现） |
| `BonsaiPlanterBlockEntity` | `bonsai_planter` | `extends LargePlanterBlockEntity` | 是 | `float resetGrowthTo()`（0.2f） |
| `HangingPlanterBlockEntity` | `hanging_planter` | `extends LargePlanterBlockEntity` | 是 | `Direction airFindOffset()`（DOWN）、`boolean addWater(float, Direction)`、`float resetGrowthTo()`（0.2f） |
| `TrellisPlanterBlockEntity` | `trellis_planter` | `extends LargePlanterBlockEntity` | 是 | `Direction airFindOffset()`（null）、`void afterGrowthTickStep(boolean)`（向上一格传递作物）、`float resetGrowthTo()`（0.2f） |
| `GrapePlantBlockEntity` | `grape_plant` | `extends TickableBlockEntity implements ICalendarTickable` | 是 | `static void serverTick(...)`、`void onCalendarUpdate(long)`、`void tryUpdate()`、`void updateTick()`、`BlockPos getBrainPos()`、`List<DeferredHolder<FoodTrait, FoodTrait>> scanAndReport()`、`boolean isBrain()`、`int[] debugViewOfSoilData()`、`boolean debugHasBees()`、`float getGrowth()`、`long getLastGrowthTick()`、`void setLastGrowthTick(long)`；`UPDATE_INTERVAL = ICalendar.CALENDAR_TICKS_IN_DAY` |
| `ClimateStationBlockEntity` | `climate_station` | `extends TFCBlockEntity` | 否 | `void updateValidity(boolean, int)`、`void setType(ClimateType)`、`void setStructureInfo(GreenhouseType, int)`、`int getSize()`、`GreenhouseType getStructureType()`、`void setPositions(Set<BlockPos>)`、`boolean setFavorite(ItemStack)`、`void setFavorite(GreenhouseType)`、`void setFavoriteIsCellar()`、`GreenhouseType getFavoriteType()`、`boolean favoriteIsCellar()` |
| `FLBeehiveBlockEntity` | 无自身注册名（被 `beehive` / `skep` 复用） | `extends TickableInventoryBlockEntity<ItemStackHandler> implements ICalendarTickable` | 是 | `static void serverTick(...)`、`BlockPos getLinkedHive()`、`void linkSwarmFrom(BlockPos)`、`void tryPeriodicUpdate()`、`void setBeeData(BeeComponent)`、`BeeComponent getBee()`、`void updateTick(float, boolean, AreaScan)`、`boolean isOccluded()`、`boolean canSwarm(boolean)`、`void trySwarm(boolean)`、`void checkInfections(float, boolean)`、`void takeHoney(int)`、`void addHoney(int)`、`boolean isWarmEnough()`、`boolean isWarmEnough(float)`、`float getMinTemperature()`、`AreaScan scanArea()`、`Set<Flower> countFlowers()`、`int getHoneyTickChanceInverted(BeeComponent, int)`、`int getHoney()`、`int getAvailableFrames()`、`void updateState()`、`boolean isSplitting()`、`boolean isSkep()`；常量 `MIN_FLOWERS=10`、`UPDATE_INTERVAL=ICalendar.CALENDAR_TICKS_IN_DAY`、`ENTITY_HANDLING_INTERVAL=1000`、`FRAME_SLOTS=4`；嵌套 `record Flower(BlockPos pos, BlockState state)`、`record AreaScan(Set<Flower> flowers, Set<BlockPos> tickable)` |
| `WoodenBeehiveBlockEntity` | `beehive` | `extends FLBeehiveBlockEntity` | 是（继承 `FLBeehiveBlockEntity::serverTick`） | 构造：`super(pos, state, FLBlockEntities.BEEHIVE.get(), 4)`，4 槽 + 侧向 `PartialItemHandler` |
| `SkepBlockEntity` | `skep` | `extends FLBeehiveBlockEntity` | 是 | 覆写 `addHoney(int)`、`getHoney()`、`takeHoney(int)`、`trySwarm(boolean)`、`updateTick(float,boolean,AreaScan)`、`canSwarm(boolean)`、`isSplitting()`（false）、`isSkep()`（true）、`isItemValid(int, ItemStack)`、`boolean hasBait(int flowers)`；构造 `super(pos, state, FLBlockEntities.SKEP.get(), 1)` |

### 2.4 侧向接口（非注册类）

| 类名（`common.blockentities.X`） | 类型 | 内容 |
| --- | --- | --- |
| `OvenLike` | `interface` | `static void regularBlockUpdate(Level, BlockPos, BlockState, OvenLike, boolean cured, int updateInterval)`；抽象 `float getTemperature()`、`int getCureTicks()`、`void addCureTicks(int)`；实现者：`OvenBottomBlockEntity`、`OvenTopBlockEntity` |
| `ClimateReceiver` | `interface` | `static ClimateReceiver get(Level, BlockPos)`；`default boolean addWater(float)`、`default boolean addWater(float, Direction)`（默认 false）、`void setValid(Level, BlockPos, boolean valid, int tier, ClimateType climate)`、`default void findClimateStation(Level, BlockPos)`；实现者：`FoodShelfBlockEntity`、`LargePlanterBlockEntity`（含全部子类）、`SprinklerBlockEntity`、`CheeseWheelBlock`（方块实现） |
| `ClimateType` | `enum` | `GREENHOUSE`、`CELLAR`；`VALUES`；`static ClimateType byId(int id)`（越界回退 `GREENHOUSE`） |
| `CrucibleLikeHeatBlock` | `interface extends IHeatConsumer` | `void setTargetTemperature(float)`、`float getTargetTemperature()`、`void resetStability()`、`default void setTemperature(float)`、`default void setTemperatureIfWarmer(float)`；实现者：`ApplianceBlockEntity.ApplianceInventory` |

---

## 3. `common/container/` 容器与 `client/screen/` 界面

来源：`common/container/FLMenuTypes.java` 及各 Container 文件；`client/screen/*.java`。

### 3.1 菜单类型注册（`FLMenuTypes`）

注册名命名空间 `firmalife`；`Id<C>` 为 TFC `TFCContainerTypes.Id<C>`。全部通过 `RegistrationHelpers.registerBlockEntityContainer(MENU, name, type, factory)` 注册，即**都是 `BlockEntityContainer<T>` 子类**。

| 常量 | 注册名 | 绑定 BE | Container 类 | 创建方式 |
| --- | --- | --- | --- | --- |
| `STOVETOP_GRILL` | `firmalife:stovetop_grill` | `FLBlockEntities.STOVETOP_GRILL` | `StovetopGrillContainer` | `StovetopGrillContainer::create` |
| `STOVETOP_POT` | `firmalife:stovetop_pot` | `FLBlockEntities.STOVETOP_POT` | `StovetopPotContainer` | `StovetopPotContainer::create` |
| `KEG` | `firmalife:keg` | `FLBlockEntities.KEG` | `KegContainer` | `KegContainer::create` |
| `BARREL_PRESS` | `firmalife:barrel_press` | `FLBlockEntities.BARREL_PRESS` | `BarrelPressContainer` | `BarrelPressContainer::create` |

### 3.2 Container 明细与对应 Screen

| Container 类 | 绑定的 BE | 继承 | 构造 / 创建签名 | 槽位布局 | 对应 Screen |
| --- | --- | --- | --- | --- | --- |
| `BarrelPressContainer` | `BarrelPressBlockEntity` | `extends BlockEntityContainer<BarrelPressBlockEntity>` | `static BarrelPressContainer create(BarrelPressBlockEntity press, Inventory playerInventory, int windowId)`；构造 `BarrelPressContainer(BarrelPressBlockEntity, Inventory, int)` | 9 个 `CallbackSlot`：葡萄 17,19 / 52,19 / 70,19 / 88,19 / 106,19；酒瓶入 132,19；出 132,55；软木塞 154,19；标签 154,37 | `client.screen.BarrelPressScreen`（底图 `firmalife:textures/gui/barrel_press.png`） |
| `KegContainer` | `KegBlockEntity` | `extends BlockEntityContainer<KegBlockEntity> implements ButtonHandlerContainer` | `static KegContainer create(KegBlockEntity barrel, Inventory playerInv, int windowId)`（`init(playerInv, 76)`）；私有构造 `KegContainer(int windowId, KegBlockEntity)` | 流体容器入 35,18 / 出 35,54；6×6 输入格（`SLOT_INPUT_START..SLOT_INPUT_END`）从 62,18 起每格 18px | `client.screen.KegScreen` + 按钮 `client.screen.KegSealButton`（底图 `firmalife:textures/gui/keg.png`） |
| `StovetopGrillContainer` | `StovetopGrillBlockEntity` | `extends BlockEntityContainer<StovetopGrillBlockEntity>` | `static StovetopGrillContainer create(StovetopGrillBlockEntity grill, Inventory playerInventory, int windowId)`（`init(playerInventory, 20)`）；构造 `(StovetopGrillBlockEntity, int)`，并 `addDataSlots(grill.getSyncableData())` | 5 槽：`62 + i*18, 20` | `client.screen.StovetopGrillScreen`（底图 `.../gui/stovetop_grill.png`，显示温度条） |
| `StovetopPotContainer` | `StovetopPotBlockEntity` | `extends BlockEntityContainer<StovetopPotBlockEntity>` | `static StovetopPotContainer create(StovetopPotBlockEntity pot, Inventory playerInventory, int windowId)`（`init(playerInventory, 20)`）；构造 `(StovetopPotBlockEntity, int)`，并 `addDataSlots(pot.getSyncableData())` | 5 槽：65,23 / 83,23 / 56,41 / 74,41 / 92,41 | `client.screen.StovetopPotScreen`（底图 `.../gui/stovetop_pot.png`，显示温度、流体与锅输出贴图） |

补充：`KegContainer.clicked(...)` 在木桶密封时直接屏蔽所有点击；`KegContainer.onButtonPress(int, CompoundTag)` 调用 `KegCoreBlock.toggleSeal(level, pos, state)`；`KegSealButton.onPress()` 发送 `ScreenButtonPacket(0)`。`KegScreen` 显示密封日期与配方名（`Calendars.CLIENT.getExactTimeAndDate(blockEntity.getSealedTick())`）。

---

## 4. `common/blocks/` 方块类清单

来源：`common/blocks/` 及其子包 `bee/`、`greenhouse/`、`oven/`、`plant/`，注册表 `FLBlocks.java`（`DeferredRegister<Block> BLOCK`）。
下表「注册名」为 `FLBlocks` 中使用的字段名（即注册路径）；命名空间 `firmalife`。

### 4.1 oven 子系统（`common/blocks/oven/`）

| 类名 | 注册字段 / 注册名 | 基类 / 接口 | 说明与关键 public 方法 |
| --- | --- | --- | --- |
| `oven.AbstractOvenBlock` | 无（抽象基类） | `extends FourWayDeviceBlock implements ICure` | `static BlockPos locateChimney(LevelAccessor, BlockPos, BlockState)`、`static void cureAllAround(Level, BlockPos, boolean myself)`、`boolean isInsulated(LevelAccessor, BlockPos, BlockState)`、`void animateTick(...)`、`Block getCured()` |
| `oven.OvenBottomBlock` | `CLAY_OVEN_BOTTOM`、`CURED_OVEN_BOTTOM`（按 `OvenType` 4 种）、`INSULATED_OVEN_BOTTOM`（4 种） | `extends AbstractOvenBlock implements IBellowsConsumer, ICure` | 燃烧室：`useItemOn(...)`（点火/加燃料）、`cure(Level, BlockState, BlockPos)`、`intakeAir(Level, BlockPos, BlockState, int)`、`updateShape(...)`、`randomTick(...)`、模拟输出信号 |
| `oven.InsulatedOvenBottomBlock` | 由 `INSULATED_OVEN_BOTTOM` 映射创建 | `extends OvenBottomBlock` | 仅覆写 `isInsulated(...)` → true |
| `oven.OvenTopBlock` | `CLAY_OVEN_TOP`、`CURED_OVEN_TOP`（4 种）、`INSULATED_OVEN_TOP`（4 种） | `extends AbstractOvenBlock` | `useItemOn(...)`、`cure(...)`、`getShape(...)`、`getLightBlock(...)`、`animateTick(...)`、模拟输出信号 |
| `oven.InsulatedOvenTopBlock` | 由 `INSULATED_OVEN_TOP` 映射创建 | `extends OvenTopBlock` | `isInsulated(...)` → true |
| `oven.OvenChimneyBlock` | `CLAY_OVEN_CHIMNEY`、`CURED_OVEN_CHIMNEY`（4 种） | `extends Block implements ICure` | `useItemOn(...)`、`cure(Level, BlockState, BlockPos)`、`Block getCured()` |
| `oven.OvenHopperBlock` | `CLAY_OVEN_HOPPER`、`CURED_OVEN_HOPPER`（4 种） | `extends FourWayDeviceBlock implements ICure` | `onPlace(...)`、`neighborChanged(...)`、`cure(...)`、`createBlockStateDefinition(...)`（`ENABLED` 属性） |
| `oven.AbstractOvenBlock` 的 `ICure` | `oven.ICure` | `interface` | `void cure(Level, BlockState, BlockPos)`、`Block getCured()`、`default boolean isCured()`（`getCured() == null`） |
| `oven.OvenType` | —（枚举） | `enum` | 取值 `BRICK`、`RUSTIC`、`TILE`、`STONE`；`String getSerializedName()`（小写） |
| `oven.AshtrayBlock` | `ASHTRAY` | `extends DeviceBlock` | `useWithoutItem(...)`（取灰）、`randomTick(...)`、`attack(...)`；`STAGE` 属性 0..5 |
| `oven.StovetopGrillBlock` | `STOVETOP_GRILL`（`registerNoItem`） | `extends BottomSupportedDeviceBlock implements IHighlightHandler` | `static int getSlotForSelection(BlockHitResult)`、`useItemOn(...)`、`entityInside(...)`（高温烫伤）、`drawHighlight(...)` |
| `oven.StovetopPotBlock` | `STOVETOP_POT`（`registerNoItem`） | `extends BottomSupportedDeviceBlock` | `useItemOn(...)`、`animateTick(...)` |
| `oven.VatBlock` | `VAT` | `extends SealableDeviceBlock` | `static void toggleSeal(Level, BlockPos, BlockState)`、`useItemOn(...)`、`neighborChanged(...)`、`animateTick(...)`、模拟输出信号 |

### 4.2 greenhouse 子系统（`common/blocks/greenhouse/`）

| 类名 | 注册字段 / 注册名 | 基类 / 接口 | 说明与关键 public 方法 |
| --- | --- | --- | --- |
| `greenhouse.Greenhouse` | 见 4.8（`GREENHOUSE_BLOCKS`） | `enum implements 无` | 见 4.9 详述 |
| `greenhouse.BaseGreenhouseBlock` | 无（被 `WALL` 使用） | `extends TransparentBlock implements IWeatherable, IForgeBlockExtension` | `boolean isRandomlyTicking(BlockState)`、`void onRandomTick(...)`、`Supplier<? extends Block> getNext()`、`ExtendedProperties getExtendedProperties()` |
| `greenhouse.GreenhouseWallBlock` | `WALL` 类型（`<GREENHOUSE>_greenhouse_WALL`） | `extends TransparentBlock implements IWeatherable, IForgeBlockExtension` | `getNext()`、`updateShape(...)`、`getStateForPlacement(...)`、`skipRendering(...)`、`boolean connects(BlockState adjacent)` |
| `greenhouse.GreenhousePanelWallBlock` | `PANEL_WALL` | `extends BaseGreenhouseBlock implements IWeatherable, IForgeBlockExtension, GreenhouseConnectable, IHighlightHandler` | 带左右连接状态的板墙：`getShape(...)`、`getStateForPlacement(...)`、`updateShape(...)`、`drawHighlight(...)`、`BlockState rotate/mirror(...)`、`static Set<Direction> getWallStates(BlockState)`、`withConnection(...)`、`getConnectionFaces(...)`、`canConnectTo(...)`；嵌套 `public static class WallSegmentLocator`（`Pair<Pair<BlockPos,BlockState>,Pair<BlockPos,BlockState>> scan(Level, BlockPos, Direction)`） |
| `greenhouse.GreenhousePanelRoofBlock` | `PANEL_ROOF` | `extends TransparentBlock implements IWeatherable, IForgeBlockExtension, GreenhouseConnectable` | `getShape(...)`、`updateShape(...)`、`tick(...)`、`getStateForPlacement(...)`、`onRemove(...)`、`withConnection(...)`、`getConnectionFaces(...)` |
| `greenhouse.GreenhouseStairBlock` | `ROOF` | `extends GlassStairBlock implements IWeatherable, IForgeBlockExtension` | `isRandomlyTicking(...)`、`onRandomTick(...)`、`skipRendering(...)`、`getNext()`、`getExtendedProperties()`；父方块由 `FLBlocks.GREENHOUSE_BLOCKS.get(green).get(WALL)` 提供 |
| `greenhouse.GreenhouseSlabBlock` | `ROOF_TOP` | `extends GlassSlabBlock implements IWeatherable` | `isRandomlyTicking(...)`、`onRandomTick(...)`、`skipRendering(...)`、`getNext()` |
| `greenhouse.GreenhouseTrapDoorBlock` | `TRAPDOOR` | `extends TrapDoorBlock implements IWeatherable, IForgeBlockExtension` | 玻璃半透明渲染方法与 `isRandomlyTicking(...)`、`getExtendedProperties()` |
| `greenhouse.GreenhouseDoorBlock` | `DOOR` | `extends DoorBlock implements IWeatherable, IForgeBlockExtension, GreenhouseConnectable` | `onRandomTick(...)`、`getNext()`、`withConnection(...)`、`getConnectionFaces(...)` |
| `greenhouse.GreenhousePortBlock` | `PORT` | `extends GreenhouseWallBlock` | 管道接口：`getStateForPlacement(...)`（带 `AXIS`）、`createBlockStateDefinition(...)` |
| `greenhouse.GlassSlabBlock` | 无（玻璃板基类） | `extends SlabBlock implements IForgeBlockExtension` | 透明渲染四件套 + `getExtendedProperties()` |
| `greenhouse.GlassStairBlock` | 无（玻璃楼梯基类） | `extends StairBlock` | 透明渲染四件套 |
| `greenhouse.ClimateStationBlock` | `CLIMATE_STATION` | `extends DeviceBlock` | **核心**：`static Either<Mechanics.GreenhouseInfo, Set<BlockPos>> check(Level, BlockPos, BlockState)`（绿色温室为左、地窖为右）、`useItemOn(...)`（设置偏好结构）、`randomTick(...)`、`tick(...)`、`setPlacedBy(...)`、`onRemove(...)` |
| `greenhouse.LargePlanterBlock` | `LARGE_PLANTER` | `extends DeviceBlock implements HoeOverlayBlock` | `randomTick(...)`（调用 `Mechanics.growthTick`）、`useItemOn(...)`、`getPlanterType()`（LARGE）、`setPlacedBy(...)`（注册到气候站）、`addHoeOverlayInfo(...)`、`protected int getUseSlot(BlockHitResult, BlockPos)`、`ItemInteractionResult insertSlot(Level, LargePlanterBlockEntity, ItemStack, Player, int)`、`static ItemInteractionResult takeSlot(Level, LargePlanterBlockEntity, int, Consumer<ItemStack>)`；`WATERED` 属性 |
| `greenhouse.QuadPlanterBlock` | `QUAD_PLANTER` | `extends LargePlanterBlock implements IHighlightHandler` | `PlanterType getPlanterType()`（= `PlanterType.QUAD`）、`protected int getUseSlot(BlockHitResult, BlockPos)`（按命中 X/Z 与 0.5 比较分 4 槽）、`boolean drawHighlight(Level, BlockPos, Player, BlockHitResult, PoseStack, MultiBufferSource, Vec3)`（用 `HITBOXES[]` 画红框）、`getShape(...)`（`box(0,0,0,16,6,16)`）；三个静态 `VoxelShape[] HITBOXES` 分别对应 `(0,0)-(8,8)`、`(8,8)-(16,16)`、`(8,0)-(16,8)`、`(0,8)-(8,16)` 四个象限 |
| `greenhouse.HydroponicPlanterBlock` | `HYDROPONIC_PLANTER` | `extends QuadPlanterBlock` | `getPlanterType()` = HYDROPONIC；`animateTick(...)`（水滴粒子） |
| `greenhouse.BonsaiPlanterBlock` | `BONSAI_PLANTER` | `extends LargePlanterBlock` | `getPlanterType()` = BONSAI、`getShape(...)` |
| `greenhouse.HangingPlanterBlock` | `HANGING_PLANTER` | `extends LargePlanterBlock` | `getPlanterType()` = HANGING、`getShape(...)`、`updateShape(...)`、`canSurvive(...)`（需上方支撑） |
| `greenhouse.TrellisPlanterBlock` | `TRELLIS_PLANTER` | `extends LargePlanterBlock` | `getPlanterType()` = TRELLIS、`getShape(...)` |
| `greenhouse.SprinklerBlock` | `SPRINKLER`（`registerNoItem`） | `extends AbstractSprinklerBlock` | 顶部喷头 |
| `greenhouse.FloorSprinklerBlock` | `FLOOR_SPRINKLER`（`registerNoItem`） | `extends AbstractSprinklerBlock` | 地面喷头，`getShape(...)` |
| `greenhouse.AbstractSprinklerBlock` | 无（抽象基类） | `extends DeviceBlock implements HoeOverlayBlock` | 构造 `(ExtendedProperties, Predicate<Direction> pipeConnection, Function<BlockPos, Iterable<BlockPos>> pathMaker, double dh, double dy, Vec3 particleOffset)`；`setPlacedBy(...)`、`animateTick(...)`（`FLParticles.SPRINKLER`）、`Predicate<Direction> getPipeConnection()`、`Function<BlockPos, Iterable<BlockPos>> getPathMaker()`、`addHoeOverlayInfo(...)`；`STASIS` 属性 |
| `greenhouse.SprinklerPipeBlock` | `COPPER_PIPE`、`OXIDIZED_COPPER_PIPE` | `extends ExtendedBlock implements DirectionPropertyBlock` | 六向连接管道，供 `SprinklerBlockEntity.searchForFluid` 遍历 |
| `greenhouse.PumpingStationBlock` | `PUMPING_STATION` | `extends FourWayDeviceBlock` | 抽水站；`static boolean hasConnection(Level, BlockPos)`（被 `SprinklerBlockEntity` 使用） |
| `greenhouse.PickerBlock` | `PICKER` | `extends DeviceBlock` | 自动采摘臂，配合 `PickerBlockEntity` |
| `greenhouse.SweeperBlock` | `SWEEPER` | `extends DeviceBlock` | 旋转扫掠收获 |
| `greenhouse.PlanterType` | —（枚举） | `enum implements StringRepresentable` | 见 4.9 |

### 4.3 bee 子系统（`common/blocks/bee/`）

| 类名 | 注册字段 / 注册名 | 基类 / 接口 | 说明与关键 public 方法 |
| --- | --- | --- | --- |
| `bee.BaseBeehiveBlock` | 无（抽象基类） | `extends FourWayDeviceBlock implements HoeOverlayBlock` | `static boolean shouldAnger(Level, BlockPos)`、`static boolean shouldAnger(Level, BlockPos, BlockEntity)`、`static boolean hasFirepit(Level, BlockPos)`、`static void attack(Player)`、`useItemOn(...)`、`randomTick(...)`、`playerDestroy(...)`、`animateTick(...)`、`addHoeOverlayInfo(...)`、模拟输出信号（蜂巢内蜜蜂/蜜量） |
| `bee.WoodenBeehiveBlock` | `BEEHIVE` | `extends BaseBeehiveBlock` | `useItemOn(...)`、`createBlockStateDefinition(...)`；属性含 `FLStateProperties.BEES`、`HONEY` |
| `bee.SkepBlock` | `SKEP` | `extends BaseBeehiveBlock implements IItemSize` | `useItemOn(...)`、`updateShape(...)`、`canSurvive(...)`、`Size getSize(ItemStack)`、`Weight getWeight(ItemStack)`、`getCloneItemStack(...)`（保留蜂王 NBT/组件）、`boolean isFilled(ItemStack)`、`getShape(...)`、`addHoeOverlayInfo(...)` |
| `bee.WildBeehiveBlock` | `WILD_BEEHIVE` | `extends HorizontalDirectionalBlock implements IForgeBlockExtension, HoeOverlayBlock` | `static void honeyDripParticle(Level, BlockPos, BlockState)`、`static boolean canHangOn(BlockState)`、`static boolean isWarmEnough(Level, BlockPos)`、`static void angerAllNearby(BlockState, LevelAccessor, BlockPos)`、`randomTick(...)`、`onProjectileHit(...)`、`animateTick(...)`、`getExtendedProperties()`、`codec()` |
| `bee.CentrifugeBlock` | `CENTRIFUGE` | `extends FourWayDeviceBlock` | `useItemOn(...)` 手动转动、`getLightBlock(...)`、`getShadeBrightness(...)`、模拟输出信号 |

### 4.4 plant 子系统（`common/blocks/plant/`）

| 类名 | 注册字段 / 注册名 | 基类 / 接口 | 说明与关键 public 方法 |
| --- | --- | --- | --- |
| `plant.FLFruitBlocks` | —（工厂类） | `final class` | 见 4.9 详述 |
| `plant.FLFruitTreeLeavesBlock` | `FRUIT_TREE_LEAVES`（按 `Tree`） | `extends FruitTreeLeavesBlock` | 构造 `(ExtendedProperties, Supplier<? extends Item> productItem, Lifecycle[] stages, Supplier<ClimateRange> climateRange, int color)`；`animateTick(...)`（飘落粒子） |
| `plant.FLFruitTreeSaplingBlock` | `FRUIT_TREE_SAPLINGS`（按 `Tree`） | `extends FruitTreeSaplingBlock` | `setPlacedBy(...)`、`createTree(Level, BlockPos, BlockState, RandomSource, long ticksToAdd, BlockPos stemPos)` |
| `plant.FLGrowingFruitTreeBranchBlock` | `FRUIT_TREE_GROWING_BRANCHES`（按 `Tree`） | `extends GrowingFruitTreeBranchBlock` | 构造 `(ExtendedProperties, Supplier<? extends Block> body, Supplier<? extends Block> leaves, Supplier<ClimateRange>)`；`randomTick(...)` |
| `plant.GrapeStringBlock` | `GRAPE_STRING`（`registerNoItem`） | `extends DeviceBlock` | 葡萄架绳：`updateShape(...)`、`canSurvive(...)`、`getShape(...)`、`getCloneItemStack(...)`；`AXIS` 属性 |
| `plant.GrapeStringWithPlantBlock` | `GRAPE_STRING_RED`、`GRAPE_STRING_WHITE`（`registerNoItem`） | `extends GrapeStringBlock implements IGrape` | 构造 `(ExtendedProperties, Supplier<? extends Block> postPlantBlock, Supplier<? extends Block> fluffBlock, Supplier<? extends Item> grape)`；`useWithoutItem(...)`（采收）、`advance(...)`、`advanceLifecycle(...)` |
| `plant.GrapeGroundPlantOnStringBlock` | `GRAPE_STRING_PLANT_RED`、`GRAPE_STRING_PLANT_WHITE`（`registerNoItem`） | `extends GrapeStringBlock implements IGrape, HoeOverlayBlock` | 带 BE（`FLBlockEntities.GRAPE_PLANT`）的地面葡萄藤：`useItemOn(...)`、`randomTick(...)`、`advance(...)`、`addHoeOverlayInfo(...)`、`getBlockSupportShape(...)` |
| `plant.GrapeTrellisPostBlock` | `GRAPE_TRELLIS_POST` | `extends ExtendedBlock` | 葡萄架立柱：`useItemOn(...)`、`getStateForPlacement(...)`、`canSurvive(...)`、`updateShape(...)`、`getShape(...)` |
| `plant.GrapeTrellisPostWithPlantBlock` | `GRAPE_TRELLIS_POST_RED`、`GRAPE_TRELLIS_POST_WHITE`（`registerNoItem`） | `extends GrapeTrellisPostBlock implements ISlowEntities` | `useItemOn(...)`（采收）、`getShape/getCollisionShape/getBlockSupportShape(...)`、`float slowEntityFactor(BlockState)`、`getCloneItemStack(...)` |
| `plant.GrapeFluffBlock` | `GRAPE_FLUFF_RED`、`GRAPE_FLUFF_WHITE`（`registerNoItem`） | `extends GroundcoverBlock implements ISlowEntities` | 叶絮层：`slowEntityFactor(...)`、`useItemOn(...)`、`updateShape(...)`、`canSurvive(...)` |
| `plant.IGrape` | —（接口） | `interface` | `default void advance(Level, BlockPos, BlockState)`、`default void advanceLifecycle(Level, BlockPos, BlockState, Lifecycle)`、`default void updateLifecycle(Level, BlockPos, BlockState, Lifecycle)`（改动 `TFCBlockStateProperties.LIFECYCLE`） |

### 4.5 keg / barrel-stave 子系统

| 类名 | 注册字段 / 注册名 | 基类 / 接口 | 说明与关键 public 方法 |
| --- | --- | --- | --- |
| `TwoByTwoCoreBlock` | 无（2×2 核心基类） | `extends FourWayDeviceBlock` | `static boolean coreBlockSurvives(LevelReader, BlockPos, BlockState)`、构造 `(ExtendedProperties, Supplier<? extends Block> sub)`、`getStateForPlacement(...)`、`setPlacedBy(...)`（放置附属方块）、`getShape(...)` |
| `TwoByTwoSubBlock` | 无（2×2 附属基类） | `extends FourWayDeviceBlock` | `static boolean stageAt(int dx, int dy, int dz, LevelReader, BlockPos origin, BlockPos.MutableBlockPos cursor, int stageWanted)`、`static BlockPos findZeroPos(BlockPos, BlockState)`、`useItemOn(...)`（转发到核心）、`canSurvive(...)`、`updateShape(...)`；`BARREL_PART` 属性 1..7 |
| `KegCoreBlock` | `KEGS`（按 `Wood`，`wood/keg/<wood>`） | `extends TwoByTwoCoreBlock` | `static void toggleSeal(Level, BlockPos, BlockState)`、构造 `(ExtendedProperties, Supplier<? extends Block> subBlock)`、`useItemOn(...)`、`updateShape(...)`、`neighborChanged(...)`、`handleNeighborChanged(BlockState, Level, BlockPos, Runnable onSeal, Runnable onUnseal)` |
| `KegSubBlock` | `KEG_SUBS`（按 `Wood`，`wood/keg_sub/<wood>`） | `extends TwoByTwoSubBlock` | 仅构造，全部行为委托核心 |
| `BarrelPressBlock` | `BARREL_PRESSES`（按 `Wood`，`wood/barrel_press/<wood>`） | `extends DeviceBlock` | `useItemOn(...)`（`press.push()`）、`getShape(...)` |
| `StompingBarrelBlock` | `STOMPING_BARRELS`（按 `Wood`，`wood/stomping_barrel/<wood>`） | `extends DeviceBlock` | 构造、`useItemOn(...)`、`fallOn(Level, BlockState, BlockPos, Entity, float)`（踩踏触发 `stomp`）、模拟输出信号 |
| `WineShelfBlock` | `WINE_SHELVES`（按 `Wood`，`wood/wine_shelf/<wood>`） | `extends FourWayDeviceBlock` | `useItemOn(...)`、`getShape(...)`、`getLightBlock(...)`、`getShadeBrightness(...)`、模拟输出信号 |

### 4.6 planters（种植盆）与气候相关

其余 planter 类见 4.2（`large_planter`、`quad_planter`、`hydroponic_planter`、`bonsai_planter`、`hanging_planter`、`trellis_planter`）。对应方块实体见 2.3。

### 4.7 cheese 与 misc

| 类名 | 注册字段 / 注册名 | 基类 / 接口 | 说明与关键 public 方法 |
| --- | --- | --- | --- |
| `CheeseWheelBlock` | `CHEDDAR_WHEEL`、`CHEVRE_WHEEL`、`RAJYA_METOK_WHEEL`、`GOUDA_WHEEL`、`FETA_WHEEL`、`SHOSHA_WHEEL`、`BLUE_WHEEL` | `extends BottomSupportedDeviceBlock implements ClimateReceiver` | `useItemOn(...)`（切片/取用）、`getStateForPlacement(...)`、`randomTick(...)`（熟成推进 `FoodAge`）、`setPlacedBy(...)`、`getShape(...)`、`setValid(Level, BlockPos, boolean, int, ClimateType)`、`onRemove(...)`、`onDestroyedByPlayer(...)`；使用 `FLBlockEntities.TICK_COUNTER` |
| `ConsumingBlock` | `PLATE`（通过 `ConsumingBlock.plate(...)`） | `extends BottomSupportedDeviceBlock` | `static ConsumingBlock plate(ExtendedProperties)`、构造 `(ExtendedProperties, VoxelShape)`、`useItemOn(...)`（吃盘子上的食物） |
| `DryingMatBlock` | `DRYING_MAT`、`SOLAR_DRIER`（后者为 `SolarDrierBlock`） | `extends BottomSupportedDeviceBlock` | `static ItemInteractionResult use(Level, BlockPos, Player, ItemStack)`、`updateShape(...)`、`useItemOn(...)`、模拟输出信号 |
| `SolarDrierBlock` | `SOLAR_DRIER` | `extends BottomSupportedDeviceBlock` | `updateShape(...)`、`useItemOn(...)`、模拟输出信号 |
| `FLLadderBlock` | `SEALED_BRICK_LADDER` | `extends LadderBlock` | `isLadder(BlockState, LevelReader, BlockPos, LivingEntity)` |
| `FoodShelfBlock` | `FOOD_SHELVES`（按 `Wood`，`wood/food_shelf/<wood>`） | `extends FourWayDeviceBlock` | `setPlacedBy(...)`、`getShape(...)`、`useItemOn(...)` |
| `HangerBlock` | `HANGERS`（按 `Wood`，`wood/hanger/<wood>`） | `extends DeviceBlock` | `static boolean canSurvive(LevelReader, BlockPos)`、`getShape(...)`、`useItemOn(...)`、`getStateForPlacement(...)`、`updateShape(...)` |
| `JarbnetBlock` | `JARBNETS`（按 `Wood`，`wood/jarbnet/<wood>`） | `extends FourWayDeviceBlock` | `static boolean isItemAllowed(ItemStack)`、`animateTick(...)`（蜡烛粒子）、`updateShape(...)`、`randomTick(...)`、`useItemOn(...)`、`getShape(...)`；`LIT` 属性与亮度 11 |
| `JarringStationBlock` | `JARRING_STATION` | `extends FourWayDeviceBlock` | `useItemOn(...)`、`getShape(...)` |
| `MixingBowlBlock` | `MIXING_BOWL` | `extends BottomSupportedDeviceBlock` | `useItemOn(...)`（放勺/搅拌）、模拟输出信号；`SPOON` 属性 |
| `StringBlock` | `WOOL_STRING`、`PINEAPPLE_YARN`（均 `registerNoItem`） | `extends DeviceBlock` | `static FirepitBlockEntity findFirepit(Level, BlockPos)`、`animateTick(...)`、`updateShape(...)`、`setPlacedBy(...)`、`getShape(...)`、`getCloneItemStack(...)`、`useItemOn(...)`、`rotate(...)`、`ItemStack getItem()` |
| `FourWayDeviceBlock` | 无（基类） | `extends DeviceBlock` | 构造 `(ExtendedProperties, InventoryRemoveBehavior)`；`createBlockStateDefinition(...)`（加 `HORIZONTAL_FACING`）、`getStateForPlacement(...)`、`rotate(...)`、`mirror(...)` |
| `IWeatherable` | —（接口） | `interface` | `default void onRandomTick(BlockState, ServerLevel, BlockPos, RandomSource)`（按 `weatherChance()` 升变）、`default int weatherChance()`（350）、`default boolean hasNext()`、`Supplier<? extends Block> getNext()` |

### 4.8 `FLBlocks` 中的主要注册组

来源：`common/blocks/FLBlocks.java`。

| 注册字段 | 形态 | 说明 |
| --- | --- | --- |
| `INSULATED_OVEN_BOTTOM` / `INSULATED_OVEN_TOP` / `CURED_OVEN_BOTTOM` / `CURED_OVEN_TOP` / `CURED_OVEN_CHIMNEY` / `CURED_OVEN_HOPPER` / `OVEN_COUNTERTOP` | `Map<OvenType, Id<Block>>` | 名称模式 `insulated_<type>_oven_bottom`、`<type>_oven_bottom`、`<type>_oven_top`、`<type>_oven_chimney`、`<type>_oven_hopper`、`<type>_countertop` |
| `CLAY_OVEN_BOTTOM` / `CLAY_OVEN_TOP` / `CLAY_OVEN_CHIMNEY` / `CLAY_OVEN_HOPPER` | `Id<Block>` | 未烧制的黏土炉，固化目标为 `OvenType.BRICK` |
| `RUSTIC_BRICKS`、`RUSTIC_BRICK_DECOR`、`TILES`、`TILE_BRICKS`、`TILE_BRICK_DECOR` | `Id<Block>` / `DecorationBlockHolder` | 装饰砖（`_slab` / `_stairs` / `_wall`） |
| `SEALED_BRICKS`、`POLISHED_SEALED_BRICKS`、`CHISELED_SEALED_BRICKS`、`SEALED_BRICK_DOOR`、`SEALED_BRICK_TRAPDOOR`、`SEALED_BRICK_WALL`、`SEALED_BRICK_LADDER` | `Id<Block>` | 地窖保温建材 |
| `GREENHOUSE_BLOCKS` | `Map<Greenhouse, Map<Greenhouse.BlockType, Id<Block>>>` | 名称模式 `<GREENHOUSE>_greenhouse_<BLOCKTYPE>` |
| `METALS` | `Map<FLMetal, Map<Metal.BlockType, Id<Block>>>` | 金属块（含 `BLOCK` 等 TFC 类型） |
| `METAL_FLUIDS`、`EXTRA_FLUIDS`、`WINE_FLUIDS` | `Map<..., Id<LiquidBlock>>` | 流体方块，路径 `fluid/metal/<metal>`、`fluid/<extra>`、`fluid/<wine>`（无物品形式） |
| `HERBS` / `POTTED_HERBS` | `Map<Herb, Id<Block>>` | `plant/<HERB>` 与 `plant/potted/<HERB>`（后者无物品） |
| `FRUIT_TREE_LEAVES` / `FRUIT_TREE_BRANCHES` / `FRUIT_TREE_GROWING_BRANCHES` / `FRUIT_TREE_SAPLINGS` / `FRUIT_TREE_POTTED_SAPLINGS` | `Map<FLFruitBlocks.Tree, Id<Block>>` | 路径 `plant/<TREE>_leaves`、`plant/<TREE>_branch`、`plant/<TREE>_growing_branch`、`plant/<TREE>_sapling`、`plant/potted/<TREE>_sapling` |
| `STATIONARY_BUSHES` | `Map<FLFruitBlocks.StationaryBush, Id<Block>>` | 路径 `plant/<BUSH>_bush` |
| `FOOD_SHELVES`、`HANGERS`、`JARBNETS`、`KEG_SUBS`、`KEGS`、`WINE_SHELVES`、`STOMPING_BARRELS`、`BARREL_PRESSES` | `Map<Wood, Id<Block>>` | 路径分别 `wood/food_shelf/<wood>`、`wood/hanger/<wood>`、`wood/jarbnet/<wood>`、`wood/keg_sub/<wood>`、`wood/keg/<wood>`、`wood/wine_shelf/<wood>`、`wood/stomping_barrel/<wood>`、`wood/barrel_press/<wood>` |
| `CARVED_PUMPKINS` / `JACK_O_LANTERNS` | `Map<Carving, Id<Block>>` | 路径 `carved_pumpkin/<carving>` 与 `lit_pumpkin/<carving>` |
| `SMALL_CHROMITE` / `CHROMITE_ORES` | `Id<Block>` / `Map<Rock, Map<Ore.Grade, Id<Block>>>` | 路径 `ore/small_chromite`、`ore/<GRADE>_chromite/<ROCK>` |
| `WILD_WHITE_GRAPES` / `WILD_RED_GRAPES` | `Id<Block>` | `plant/wild_white_grapes`、`plant/wild_red_grapes` |
| `PICKER`、`SWEEPER`、`PUMPING_STATION`、`IRRIGATION_TANK`、`COPPER_PIPE`、`OXIDIZED_COPPER_PIPE`、`TREATED_WOOD`、`REINFORCED_POURED_GLASS`、`HOLLOW_SHELL` | `Id<Block>` | 各类杂项；`HOLLOW_SHELL`、`SPRINKLER`、`FLOOR_SPRINKLER`、`WOOL_STRING`、`PINEAPPLE_YARN`、`STOVETOP_*`、`KEG_SUBS`、`*_BRANCH` 等使用 `registerNoItem` |
| 工具方法 | — | `static void registerFlowerPotFlowers()`、`static Properties brickProperties()`、`static ExtendedProperties shelfProperties()/hangerProperties()/jarbnetProperties()/wheelProperties()/jarProperties()`、`static int lightEmission(BlockState)`（`LIT` 时 15） |

### 4.9 重点枚举 / 接口详述

#### `Greenhouse.java`

```java
public enum Greenhouse {
    RUSTED_IRON(SoundType.METAL, false),
    IRON(SoundType.METAL, false, RUSTED_IRON),
    OXIDIZED_COPPER(SoundType.COPPER, false),
    WEATHERED_COPPER(SoundType.COPPER, false, OXIDIZED_COPPER),
    EXPOSED_COPPER(SoundType.COPPER, false, WEATHERED_COPPER),
    COPPER(SoundType.COPPER, false, EXPOSED_COPPER),
    WEATHERED_TREATED_WOOD(SoundType.WOOD, true),
    TREATED_WOOD(SoundType.WOOD, true, WEATHERED_TREATED_WOOD),
    STAINLESS_STEEL(SoundType.LANTERN, false);
}
```

- 字段：`@Nullable Greenhouse next`（风化后的下一级）、`SoundType sound`、`boolean flammable`、`BlockSetType blockSet`（可燃用 `OAK`，否则 `STONE`）。
- 风化方向：`IRON → RUSTED_IRON`、`COPPER → EXPOSED_COPPER → WEATHERED_COPPER → OXIDIZED_COPPER`、`TREATED_WOOD → WEATHERED_TREATED_WOOD`；`RUSTED_IRON`、`OXIDIZED_COPPER`、`WEATHERED_TREATED_WOOD`、`STAINLESS_STEEL` 的 `next == null`（不再风化）。

`Greenhouse.BlockType`（8 个取值，工厂式枚举）：

| 取值 | 工厂产生的方块 | 说明 |
| --- | --- | --- |
| `WALL` | `GreenhouseWallBlock` | 玻璃墙 |
| `PANEL_WALL` | `GreenhousePanelWallBlock` | 带左右连接的板墙 |
| `PANEL_ROOF` | `GreenhousePanelRoofBlock` | 板顶 |
| `ROOF` | `GreenhouseStairBlock`（父状态取自 `GREENHOUSE_BLOCKS.get(green).get(WALL)`） | 楼梯形屋顶 |
| `ROOF_TOP` | `GreenhouseSlabBlock` | 板形屋顶 |
| `TRAPDOOR` | `GreenhouseTrapDoorBlock`（固定 `BlockSetType.OAK`） | 活板门 |
| `DOOR` | `GreenhouseDoorBlock`（使用 `green.blockSet`） | 门 |
| `PORT` | `GreenhousePortBlock` | 管道端口 |

`BlockType` 的方法：

```java
public static ExtendedProperties properties(Greenhouse green)   // strength 4.0f, noOcclusion, randomTicks; flammable(60,30)
public Supplier<Block> create(Greenhouse type)
public Function<Block, BlockItem> createBlockItem(Item.Properties properties)
@Nullable public Supplier<? extends Block> getNext(Greenhouse green)  // 查 GREENHOUSE_BLOCKS 中下一级同 BlockType
```

#### `PlanterType.java`

```java
public enum PlanterType implements StringRepresentable { QUAD, LARGE, HANGING, TRELLIS, BONSAI, HYDROPONIC; }
```
- 序列化名 = `name().toLowerCase(Locale.ROOT)`；`Codec<PlanterType> CODEC = StringRepresentable.fromEnum(PlanterType::values)`；`StreamCodec<ByteBuf, PlanterType>` 用 TFC `StreamCodecs.forEnum`。
- 与方块的对应（全部已核实，见 `common/blocks/greenhouse/*.java`）：`LargePlanterBlock#getPlanterType()` 返回 `LARGE`（第 117-119 行）；`QuadPlanterBlock` 返回 `QUAD`（第 34-36 行）；`BonsaiPlanterBlock` 返回 `BONSAI`（第 21-23 行）；`HangingPlanterBlock` 返回 `HANGING`（第 25-27 行）；`TrellisPlanterBlock` 返回 `TRELLIS`（第 21-23 行）；`HydroponicPlanterBlock` 返回 `HYDROPONIC`（第 21-23 行）。`Plantable.planter` 字段（JSON `planter`）与方块返回值比对，不一致时提示 `firmalife.greenhouse.wrong_type`。

#### `OvenType.java`

```java
public enum OvenType { BRICK, RUSTIC, TILE, STONE; public String getSerializedName(); }
```
用于生成 4 套炉体方块名称前缀与 `FinishItem` 种类（`FINISHES` 跳过 `BRICK`）。

#### `Herb.java`

```java
public enum Herb { BASIL, BAY_LAUREL, CARDAMOM, CILANTRO, CUMIN, OREGANO, PIMENTO, VANILLA; }
```
源码注释给出的用途：BASIL→披萨、BAY_LAUREL→香饭、CARDAMOM→抓饭、CILANTRO→莎莎酱与香饭、OREGANO→千层面、PIMENTO→南瓜派、VANILLA→冰淇淋；`CUMIN` 无注释。

#### `FLFruitBlocks.java`

`enum Tree`（2 个取值）：

| 取值 | product | color | stages（12 个月 `Lifecycle[]`） |
| --- | --- | --- | --- |
| `COCOA` | `FLItems.FOODS.get(FLFood.COCOA_BEANS)` | `new Color(252, 171, 255).getRGB()` | HEALTHY, HEALTHY, HEALTHY, FLOWERING, FLOWERING, FRUITING, DORMANT, DORMANT, DORMANT, DORMANT, DORMANT, HEALTHY |
| `FIG` | `FLItems.FRUITS.get(FLFruit.FIG)` | `new Color(251, 135, 255).getRGB()` | HEALTHY, HEALTHY, FLOWERING, FLOWERING, FRUITING, DORMANT, DORMANT, DORMANT, DORMANT, DORMANT, HEALTHY, HEALTHY |

`Tree` 的 create* 方法（全部 `public Block`）：

```java
public Block createSapling()        // new FLFruitTreeSaplingBlock(..., FLBlocks.FRUIT_TREE_GROWING_BRANCHES.get(this), 8 * ICalendar.CALENDAR_TICKS_IN_DAY, FLClimateRanges.FRUIT_TREES.get(this), stages)
public Block createPottedSapling()  // FlowerPotBlock，内含 createSapling 的方块
public Block createLeaves()         // new FLFruitTreeLeavesBlock(..., blockEntity(FLBlockEntities.BERRY_BUSH), product, stages, climateRange, color)
public Block createBranch()         // new FruitTreeBranchBlock(..., climateRange)   —— 直接使用 TFC 类
public Block createGrowingBranch()  // new FLGrowingFruitTreeBranchBlock(..., FRUIT_TREE_BRANCHES.get(this), FRUIT_TREE_LEAVES.get(this), climateRange)
```

`enum StationaryBush`（2 个取值，`product` + 12 个月 `Lifecycle...`）：

| 取值 | product | stages |
| --- | --- | --- |
| `PINEAPPLE` | `FLItems.FRUITS.get(FLFruit.PINEAPPLE)` | DORMANT, DORMANT, HEALTHY, HEALTHY, HEALTHY, HEALTHY, FLOWERING, FLOWERING, FRUITING, DORMANT, DORMANT, DORMANT |
| `NIGHTSHADE` | `FLItems.NIGHTSHADE_BERRY` | DORMANT, HEALTHY, HEALTHY, HEALTHY, HEALTHY, HEALTHY, FLOWERING, FRUITING, DORMANT, DORMANT, DORMANT, DORMANT |

`StationaryBush.create()` 返回 `new StationaryBerryBushBlock(ExtendedProperties..., blockEntity(FLBlockEntities.BERRY_BUSH), product, stages, FLClimateRanges.STATIONARY_BUSHES.get(this))`。

#### `GreenhouseConnectable.java`

`interface GreenhouseConnectable`，内部三个枚举 + 两个抽象方法：

| 成员 | 取值 / 签名 | 说明 |
| --- | --- | --- |
| `enum DualSide implements StringRepresentable` | `NONE, LEFT, RIGHT, BOTH` | `DualSide combine(DualSide)`、`DualSide subtract(DualSide)`、`DualSide opposite()`（NONE↔BOTH、LEFT↔RIGHT）、`boolean contains(DualSide)`、`static DualSide resolve(boolean left, boolean right)` |
| `enum Side implements StringRepresentable` | `LEFT, RIGHT, NONE` | `Direction getDirection(Direction)`（LEFT→clockwise、RIGHT→counterClockwise、NONE→原方向）、`Side opposite()`、`DualSide dual()` |
| `enum Size implements StringRepresentable` | `NONE, THIN, THICK` | 仅 `getSerializedName()` |
| 方法 | `@Deprecated default boolean canConnectTo(BlockState, Direction facing, BlockState facingState, LevelAccessor, BlockPos currentPos, BlockPos facingPos)`（默认 false） | 注释标为可能不再需要 |
| 方法 | `BlockState withConnection(BlockState, Direction facing, BlockState facingState, LevelAccessor, BlockPos currentPos, BlockPos facingPos)` | 抽象 |
| 方法 | `@Deprecated Set<Direction> getConnectionFaces(BlockState, BlockPos, LevelAccessor)` | 抽象 |
| 方法 | `default BlockState updateConnections(BlockState, BlockPos, LevelAccessor, Direction... directions)` | 逐方向应用 `withConnection` |
| 方法 | `static boolean hasConnectionAt(BlockState, BlockPos, LevelAccessor, Direction)` | 委托给方块实现 |

---

## 5. `common/util/` 与 `common/capabilities/` 枚举与数据类

### 5.1 `common/util/`

| 类名 | 类型 | 取值 / 字段 | 实现的接口 | 关键方法 |
| --- | --- | --- | --- | --- |
| `util.FLMetal` | `enum` | 取值：`CHROMIUM(0xFFF5FEFF, MapColor.COLOR_LIGHT_GRAY)`、`STAINLESS_STEEL(0xFFD9FCFF, MapColor.COLOR_LIGHT_GRAY)`；字段 `serializedName`、`color`、`mapColor`、`sheet`（`firmalife:block/metal/full/<name>`） | `implements RegistryMetal`（TFC） | `ResourceLocation getSheet()`、`String getSerializedName()`、`int getColor()`、`LevelTier toolTier()`（`TFCTiers.STEEL`）、`Holder<ArmorMaterial> armorMaterial()`（红钢）、`int armorDurability(ArmorItem.Type)`、`Block getBlock(Metal.BlockType)`、`MapColor mapColor()`、`Rarity rarity()`（EPIC）、`float weatheringResistance()`（0）；嵌套 `enum ItemType { INGOT, DOUBLE_INGOT, SHEET, DOUBLE_SHEET, ROD; Item create(FLMetal) }` |
| `util.FLPlant` | `enum` | 仅 `HERB(0.9F, new int[]{0,0,0,0,1,1,1,1,0,0,0,0})`；字段 `speedFactor`、`@Nullable IntegerProperty property`、`@Nullable int[] stagesByMonth` | `implements RegistryPlant`（TFC） | `float getSpeedFactor()`、`int stageFor(Month)`、`BlockBehaviour.Properties solid()`、`BlockBehaviour.Properties nonSolid()`、`ExtendedProperties nonSolidFire()`、`IntegerProperty getAgeProperty()`；其余 `RegistryPlant` 回调（`getStartTime`、`getEndTime`、`getBloomOffset`…）均返回 0，`isWetSeasonBlooming()` 返回 false；类注释：「this needs plant properties defined」 |
| `util.FLFruit` | `enum` | 取值：`FIG`、`PINEAPPLE`、`RED_GRAPES`、`WHITE_GRAPES`；字段 `name`（小写）、`boolean fast` | 无 | `String getSerializedName()`、`FoodProperties getFoodProperties()`（nutrition 4、saturation 0.3，`fast` 时 `.fast()`）。注意：目前无任何取值以 `fast=true` 构造 |
| `util.ExtraFluid` | `enum` | 取值（含颜色）：`YEAST_STARTER(0xFFa79464)`、`COCONUT_MILK(0xFFfcfae2)`、`YAK_MILK(0xFFfcfaec)`、`GOAT_MILK(0xFFf6f6eb)`、`CURDLED_YAK_MILK(0xFFf9f4d6)`、`CURDLED_GOAT_MILK(0xFFeeeed9)`、`CREAM(0xFFFCF6C7)`、`PINA_COLADA(0xFFE4C06A)`、`CHOCOLATE(0xFF875633)`、`SUGAR_WATER(0xFF99EEFF)`、`MEAD(0xFFc79f28)`、`SOYBEAN_OIL(0xFFdbc99a)`、`WHEY(0xFFe8e4b0)` | `implements StringRepresentable` | `String getSerializedName()`（小写）、`int getColor()` |
| `util.Carving` | `enum` | 取值：`NONE`、`CIRCLE`、`CREEPER`、`AXE`、`HAMMER`、`PICKAXE`、`LEFT`、`RIGHT` | `implements StringRepresentable` | `String getSerializedName()`（小写） |
| `util.FoodAge` | `enum` | 取值：`FRESH(0, ChatFormatting.GRAY, FLFoodTraits.FRESH)`、`AGED(4, ChatFormatting.DARK_RED, FLFoodTraits.AGED)`、`VINTAGE(8, ChatFormatting.GOLD, FLFoodTraits.VINTAGE)`；字段 `id`、`name`、`format`、`trait`（`DeferredHolder<FoodTrait, FoodTrait>`） | `implements StringRepresentable` | `String getSerializedName()`、`int getId()`、`ChatFormatting getFormat()`、`DeferredHolder<FoodTrait, FoodTrait> getTrait()`；被 `FLStateProperties.AGE` 作为 `EnumProperty` 使用 |
| `util.Mechanics` | `final class`（工具类） | 常量：`CELLAR`（`Predicate<BlockState>`，匹配 `FLTags.Blocks.CELLAR_INSULATION`）、`UPDATE_INTERVAL = ICalendar.CALENDAR_TICKS_IN_DAY`、`NUTRIENT_CONSUMPTION`、`WATER_CONSUMPTION`、`GROWTH_FACTOR = 1f/(16*CALENDAR_TICKS_IN_DAY)`、`NUTRIENT_GROWTH_FACTOR = 0.5f`、`YIELD_MIN = 0.2f`、`YIELD_LIMIT = 1f`；嵌套 `record GreenhouseInfo(GreenhouseType type, Set<BlockPos> positions)` | 无 | `static Set<BlockPos> floodfill(...)`、`static Set<BlockPos> getCellar(Level, BlockPos, BlockState[, int lastSize])`、`static GreenhouseInfo getGreenhouse(Level, BlockPos, BlockState[, int lastSize])`、`static boolean growthTick(Level, BlockPos, BlockState, LargePlanterBlockEntity)`、`static boolean growthTickStep(Level, RandomSource, long fromTick, long toTick, LargePlanterBlockEntity)` |
| `util.GreenhouseType` | `record` | `record GreenhouseType(BlockIngredient ingredient, int tier, Component translationKey)`；静态：`CODEC`（字段 `ingredient` / `tier` / `translation_key`）、`STREAM_CODEC`、`DataManager<GreenhouseType> MANAGER`（路径 `firmalife:greenhouse`）、`IndirectHashCollection<Block, GreenhouseType> CACHE` | 无 | `@Nullable static GreenhouseType get(BlockState)`、`Component getTitle()` |
| `util.Plantable` | `record` | `record Plantable(Ingredient ingredient, PlanterType planter, int tier, int stages, float extraSeedChance, ItemStack seed, ItemStack crop, NutrientList nutrient, List<ResourceLocation> textures, List<ResourceLocation> specials)`；嵌套 `record NutrientList(float nitrogen, float phosphorous, float potassium)`；静态 `CODEC`（字段 `ingredient`、`planter`、`tier`（默认 0）、`stages`（默认 0）、`extra_seed_chance`（默认 0.5）、`seed`、`crop`、`nutrient`、`textures`、`specials`）、`STREAM_CODEC`、`DataManager<Plantable> MANAGER`（`firmalife:plantable`）、`IndirectHashCollection<Item, Plantable> CACHE` | 无 | `@Nullable static Plantable get(ItemStack)`、`ItemStack getSeed()`、`ItemStack getCrop()`（自动盖创建日期）、`NutrientList getNutrients()`、`ResourceLocation getSpecialTexture(int)`、`ResourceLocation getTexture(int)`、`ResourceLocation getTexture(float growth)`、`void addTooltipInfo(List<Component>, @Nullable PlantableInfo)` |
| `util.FLArmorMaterials` | `final class` | `DeferredRegister<ArmorMaterial> ARMOR_MATERIAL`；`TFCArmorMaterials.Id BEEKEEPER = register("beekeeper", SoundEvents.ARMOR_EQUIP_LEATHER, 160, 200, 215, 150, 1, 2, 3, 1, 15, 0f, 0f)` | 无 | 私有 `register(...)` 构造 `ArmorMaterial`（耐久 靴/腿/胸/头 = 160/200/215/150，护甲 1/2/3/1，附魔性 15） |
| `util.FLAdvancements` | `final class` | `Id BIG_CELLAR`、`BIG_STAINLESS_GREENHOUSE`、`STOVETOP_POT`、`STOVETOP_GRILL`（全部 `TFCAdvancements.Id` / `GenericTrigger`） | 无 | `static Id registerGeneric(String name)` |
| `util.FLClimateRanges` | `final class` | 见文件 `common/util/FLClimateRanges.java`（本清单未展开其内部值） | 无 | 提供 `FRUIT_TREES`、`STATIONARY_BUSHES`、`GRAPES` 等 `Supplier<ClimateRange>` 映射 |
| `util.FLDataManagers` | `final class` | 见 `common/util/FLDataManagers.java` | 无 | 数据管理器注册 |
| `util.FLSelfTests` | `final class` | 见 `common/util/FLSelfTests.java` | 无 | 自检逻辑 |

### 5.2 `common/capabilities/`

| 类名 | 类型 | 字段/取值 | 接口 | 关键方法 |
| --- | --- | --- | --- | --- |
| `capabilities.FLComponents` | `final class` | `DeferredRegister<DataComponentType<?>> COMPONENT`；`Id<BeeComponent> BEE` = `firmalife:bee`；`Id<WineComponent> WINE` = `firmalife:wine` | 无 | `static void register(RegisterCapabilitiesEvent)`（注册物品流体能力：3 种酒瓶 → `forWine`；`HOLLOW_SHELL`/`WINE_GLASS` → 桶式；并为 30 余种 BE 注册 `BlockCapabilities.ITEM`，为 KEG/KEG_SUB/MIXING_BOWL/STOVETOP_POT/VAT 注册 FLUID，为 OVEN_TOP/STOVETOP_GRILL/STOVETOP_POT/VAT 注册 HEAT）；`@Nullable static FluidContainerHandler forWine(ItemStack, Void)` |
| `capabilities.bee.BeeComponent` | `record` | `record BeeComponent(Map<BeeAbility,Integer> abilities, boolean hasQueen, GeneticDisease geneticDisease, ParasiticInfection parasiticInfection, BeeSpecies species, int age)`；`CODEC` 字段：`abilities`、`has_queen`、`genetic_disease`、`parasitic_infection`、`species`、`age`；常量 `DEFAULT`（无女王，WESTERN）、`DEFAULT_QUEEN` | 无 | `static BeeComponent getWildBee(Level, BlockPos)`、`static BeeComponent withDiseases(BeeComponent, @Nullable GeneticDisease, @Nullable ParasiticInfection)`、`BeeComponent getOlder()`、`withAge(int)`、`mutate(RandomSource)`（突变：`MUTANT` 能力决定变异幅度，上限 1..10，可能获得遗传病）、`withTrait(BeeAbility, int)`、`int getAbility(BeeAbility)`、`boolean hasGeneticDisease()`、`boolean hasParasiticInfection()`、`void addTooltipInfo(Consumer<Component>)` |
| `capabilities.bee.BeeSpecies` | `enum implements StringRepresentable` | 11 个取值，格式 `(Map<BeeAbility,Integer> defaults, float minTemp, float maxTemp, float minRain, float maxRain, int weight, boolean mountain)`：`WESTERN`（CALMNESS 4、PRODUCTION 3、HARDINESS 1；5/20/100/400/15/false）、`ASIAN`（FERTILITY 3、NATURE_RESTORATION 1；10/30/250/400/10/false）、`GIANT`（FERTILITY 1；15/30/300/450/10/false）、`DWARF`（FERTILITY 5、PRODUCTION 2；20/30/300/400/10/false）、`BLACK_DWARF`（MUTANT 1、NATURE_RESTORATION 2；12/22/150/350/5/false）、`KOSCHEVNIKOV`（HARDINESS 2、PRODUCTION 1、NATURE_RESTORATION 1；12/16/200/375/2/false）、`HIMALAYAN_GIANT`（HARDINESS 3、MUTANT 1、PRODUCTION 1；10/19/150/250/5/true）、`PHILIPPINE`（CALMNESS 1、CROP_AFFINITY 1；15/20/350/450/2/false）、`BORNEO_MOUNTAIN`（HARDINESS 3、INFECTION_RESISTANCE 1；13/22/150/400/10/true）、`INDONESIAN_GIANT`（NATURE_RESTORATION 1、FERTILITY 1、INFECTION_RESISTANCE 1；16/20/350/420/5/false）、`AFRICANIZED`（HARDINESS 2；10/25/100/320/15/false） | `StringRepresentable`；静态 `CODEC`、`STREAM_CODEC`、`CAN_BE_FOUND` | `String getSerializedName()`、`Map<BeeAbility,Integer> getDefaults()`、`static BeeSpecies choose(float temp, float rain, BlockPos pos, RandomSource random)`（按温/雨区间与 `mountain`（Y>96）过滤后加权随机，兜底 WESTERN） |
| `capabilities.bee.BeeAbility` | `enum implements StringRepresentable` | 8 个取值：`HARDINESS`、`PRODUCTION`、`MUTANT`、`FERTILITY`、`CROP_AFFINITY`、`NATURE_RESTORATION`、`CALMNESS`、`INFECTION_RESISTANCE`（每个带源码注释说明效果） | `StringRepresentable` | `static float getMinTemperature(int hardiness)`（`-2*hardiness + 7`）、`static int[] fresh()`、`static BeeAbility random(RandomSource)`；`VALUES`、`SIZE` |
| `capabilities.bee.GeneticDisease` | `enum implements StringRepresentable` | `NONE`、`MALFORMED_RECTUM`、`MALPHIGIAN_TUBULE_IRIDESCENCE`、`RECTAL_STONES`、`POOR_OSMOREGULATION`、`NOSEMOSIS`、`BROKEN_WINGS` | `StringRepresentable` | `CODEC`、`STREAM_CODEC`、`VALUES`、`static GeneticDisease valueOf(int i)`（越界回退 NONE）、`getSerializedName()` |
| `capabilities.bee.ParasiticInfection` | `enum implements StringRepresentable` | `NONE`、`CHALKBROOD`、`STONEBROOD`、`FOULBROOD`、`WAX_MOTHS`、`HIVE_BEETLES`、`VARROA` | `StringRepresentable` | 同上的 `CODEC`、`STREAM_CODEC`、`VALUES`、`valueOf(int)`、`getSerializedName()` |
| `capabilities.wine.WineComponent` | `record` | `record WineComponent(long creationDate, long openDate, Optional<String> labelText, WineType wineType, KoppenClimateClassification climate, List<Holder<FoodTrait>> traits)`；`CODEC` 字段：`creation_date`、`open_date`、`label_text`、`wine`、`climate`、`traits`；`DEFAULT = (-1, -1, empty, RED, KoppenClimateClassification.AF, [])` | 无 | `static WineComponent opened(WineComponent, long date)`、`boolean isSealed()`（`openDate == -1`）、`void addTooltipInfo(Consumer<Component>, ItemStack)` |
| `capabilities.wine.WineType` | `enum implements StringRepresentable` | 取值（带颜色，序列化名 = 小写 + `_wine`）：`RED(0xFFa10d00)`、`WHITE(0xFFfff3f2)`、`ROSE(0xFFf5cac6)`、`SPARKLING(0xFFffeed4)`、`DESSERT(0xFFf2ebdf)`；`VALUES`、`KOPPEN_VALUES = KoppenClimateClassification.values()` | `StringRepresentable` | `CODEC`、`STREAM_CODEC`、`int getColor()`、`String getSerializedName()` |

### 5.3 `common/items/` 中的 `FLFood` / `FLFoodTraits` / `Spice`

| 类名 | 类型 | 取值 / 字段 | 接口 | 关键方法 |
| --- | --- | --- | --- | --- |
| `items.FLFood` | `enum` | 107 个取值，按源码顺序：`FROTHY_COCONUT, TOFU, SOY_MIXTURE, YAK_CURD, GOAT_CURD, MILK_CURD, RICOTTA, MOZZARELLA, OAT_SLICE, WHEAT_SLICE, BARLEY_SLICE, MAIZE_SLICE, RICE_SLICE, RYE_SLICE, OAT_FLATBREAD, WHEAT_FLATBREAD, BARLEY_FLATBREAD, MAIZE_FLATBREAD, RICE_FLATBREAD, RYE_FLATBREAD, OAT_DOUGH, WHEAT_DOUGH, BARLEY_DOUGH, MAIZE_DOUGH, RICE_DOUGH, RYE_DOUGH, TOAST, TOAST_WITH_JAM, TOAST_WITH_BUTTER, BACON, COOKED_BACON, GARLIC_BREAD, CHEDDAR, CHEVRE, RAJYA_METOK, GOUDA, FETA, SHOSHA, BLUE_CHEESE, BUTTER, PIE_DOUGH, PUMPKIN_PIE_DOUGH, PIZZA_DOUGH, SHREDDED_CHEESE, PICKLED_EGG, COCOA_BEANS, ROASTED_COCOA_BEANS, COCOA_BUTTER, COCOA_POWDER, WHITE_CHOCOLATE_BLEND, DARK_CHOCOLATE_BLEND, MILK_CHOCOLATE_BLEND, WHITE_CHOCOLATE, DARK_CHOCOLATE, MILK_CHOCOLATE, CURED_MAIZE, NIXTAMAL, MASA_FLOUR, MASA, CORN_TORTILLA, TACO_SHELL, TOMATO_SAUCE, TOMATO_SAUCE_MIX, SALSA, VANILLA_ICE_CREAM, STRAWBERRY_ICE_CREAM, CHOCOLATE_ICE_CREAM, BANANA_SPLIT, COOKIE_DOUGH_ICE_CREAM, BURRITO, TACO, RICE_PILAF, CARNE_ASADA, COOKED_PIZZA, COOKED_PIE, COOKIE_DOUGH, CHOCOLATE_CHIP_COOKIE_DOUGH, SUGAR_COOKIE, CHOCOLATE_CHIP_COOKIE, MAKI_ROLL, FUTO_MAKI_ROLL, HARDTACK, HARDTACK_DOUGH, RAW_LASAGNA, COOKED_LASAGNA, RAW_EGG_NOODLES, COOKED_PASTA, PASTA_WITH_TOMATO_SAUCE, RAW_RICE_NOODLES, COOKED_RICE_NOODLES, TORTILLA_CHIPS, NACHOS, SMASHED_RED_GRAPES, SMASHED_WHITE_GRAPES, SOYBEAN_PASTE, DEHYDRATED_SOYBEANS, RAW_HONEY, SPICED_FLOUR, FLAVORFUL_COOKED_RICE`；字段 `boolean fast`（所有取值均走无参构造 `fast=false`） | 无 | `FoodProperties getFoodProperties()`（nutrition 4、saturation 0.3） |
| `items.FLFoodTraits` | `final class` + 嵌套 `enum Default` | `Default` 取值与 `mod`：`DRIED(0.5)`、`FRESH(1.1)`、`AGED(0.9)`、`VINTAGE(0.6)`、`OVEN_BAKED(0.9)`、`SMOKED(0.7)`、`RANCID_SMOKED(2.0)`、`SHELVED(0.4)`、`SHELVED_2(0.35)`、`SHELVED_3(0.25)`、`HUNG(0.35)`、`HUNG_2(0.3)`、`HUNG_3(0.25)`、`FERMENTED(0.25)`、`BEE_POLLINATED(0.8)`、`DIRT_GROWN(0.9)`、`GRAVEL_GROWN(0.8)`、`SLOPE_GROWN(0.8)`；`DeferredRegister<FoodTrait> TRAITS`（注册到 `FoodTraits.KEY`） | `Default` 无接口 | `Default.getName()`、`getCapitalizedName()`、`float getMod()`；注册出的 `DeferredHolder<FoodTrait, FoodTrait>` 常量与 `Default` 同名（DRIED…SLOPE_GROWN），值取自 `FLConfig.SERVER.foodTraits.get(trait)`，描述键 `firmalife.tooltip.food_trait.<name>` |
| `items.Spice` | `enum` | `BASIL_LEAVES`、`VANILLA`、`CHOPPED_CILANTRO`、`ALLSPICE`、`BAY_LEAVES`、`GROUND_CARDAMOM`、`GROUND_CUMIN` | 无 | 无方法（注册名 `firmalife:spice/<name>`） |

---

## 6. `common/items/` 物品类

来源：`common/items/*.java`，注册表 `FLItems.java`（`DeferredRegister<Item> ITEM`），`ItemId` 为 TFC `TFCItems.ItemId`。

| 类名 | 注册名（`FLItems` 字段 → 路径） | 基类 | 构造签名与要点 |
| --- | --- | --- | --- |
| `items.BeehiveFrameItem` | `INSULATING_BEEHIVE_FRAME`（`insulating_beehive_frame`，drop = `TFCItems.WOOL`）、`FILLED_BEEHIVE_FRAME`（drop = `BEESWAX`）、`HONEYED_BEEHIVE_FRAME`（drop = `FOODS(RAW_HONEY)`）、`SUGARED_BEEHIVE_FRAME`（drop = `Items.SUGAR`） | `extends Item` | `BeehiveFrameItem(Properties properties, Supplier<? extends Item> drop)`；`boolean overrideOtherStackedOnMe(ItemStack, ItemStack, Slot, ClickAction, Player, SlotAccess)`（副手用刀刮取掉落物并消耗耐久）；`void appendHoverText(ItemStack, TooltipContext, List<Component>, TooltipFlag)` |
| `items.FilledWineBottleItem` | `HEMATITIC_WINE_BOTTLE`、`VOLCANIC_WINE_BOTTLE`、`OLIVINE_WINE_BOTTLE` | `extends WineBottleItem` | `FilledWineBottleItem(Properties, ResourceLocation modelLocation)`；内部 `FluidContainerInfo`（容量 2000，仅 `FLTags.Fluids.WINE`）；`FluidContainerInfo getContainerInfo()`、`InteractionResultHolder<ItemStack> use(Level, Player, InteractionHand)`、`boolean overrideOtherStackedOnMe(...)`（刀开瓶，写入 `openDate`）、`Component getName(ItemStack)`、`void appendHoverText(...)`、`ItemStack getCraftingRemainingItem(ItemStack)`、`boolean hasCraftingRemainingItem(ItemStack)` |
| `items.WineBottleItem` | `EMPTY_HEMATITIC_WINE_BOTTLE`、`EMPTY_VOLCANIC_WINE_BOTTLE`、`EMPTY_OLIVINE_WINE_BOTTLE` | `extends Item` | `WineBottleItem(Properties, ResourceLocation modelLocation)`；`ResourceLocation getModelLocation()` |
| `items.WineGlassItem` | `WINE_GLASS` | `extends JugItem`（TFC） | `WineGlassItem(Properties, Supplier<Integer> capacity, TagKey<Fluid> whitelist)`；覆写 `afterFillFailed(...)` 返回 `pass`；容量来自 `FLConfig.SERVER.wineGlassCapacity` |
| `items.HollowShellItem` | `HOLLOW_SHELL` | `extends FluidContainerItem`（TFC） | `HollowShellItem(Properties, Supplier<Integer> capacity, TagKey<Fluid> whitelist, boolean canPlaceSourceBlocks, boolean canPlaceLiquidsInWorld)`；覆写 `afterFillFailed(...)`：潜行对上方流体可放置 `FLBlocks.HOLLOW_SHELL` 方块，否则播放 `FLSounds.HOLLOW_SHELL_BLOW` |
| `items.FinishItem` | `FINISHES`（按 `OvenType`，排除 BRICK），路径 `<type>_finish` | `extends Item` | `FinishItem(Properties, OvenType type)`；`InteractionResult useOn(UseOnContext)`：把砖炉/隔温炉/炉顶/料斗/台面替换为对应 `OvenType` 变体，或把原版砖替换为 `RUSTIC_BRICKS` / `TILE_BRICKS` |
| `items.GrapeSeedItem` | `RED_GRAPE_SEEDS`（`seeds/red_grape`）、`WHITE_GRAPE_SEEDS`（`seeds/white_grape`） | `extends Item` | `GrapeSeedItem(Properties, Supplier<? extends Block> crop)`；`InteractionResult useOn(UseOnContext)`：在 `GRAPE_STRING` 上（且下方为 `TFCTags.Blocks.BUSH_PLANTABLE_ON`）放置葡萄作物，复制 `AXIS` |
| `items.PeelItem` | `PEEL`、`OVEN_INSULATION`（两者都用 `PeelItem`） | `extends Item` | `PeelItem(Properties)`；`UseAnim getUseAnimation(ItemStack)` = SPEAR；嵌套 `enum Extension implements IClientItemExtensions`（单例 `INSTANCE`，提供 `PeelRenderer` 作为 `BlockEntityWithoutLevelRenderer`） |
| `items.SprinklerItem` | `SPRINKLER` | `extends BlockItem` | `SprinklerItem(Block block, Block floorBlock, Properties properties)`；`protected BlockState getPlacementState(BlockPlaceContext)` 根据相邻管道方向选择顶部/地面喷头；`void registerBlocks(Map<Block,Item>, Item)`、`removeFromBlockToItemMap(...)`、`boolean isPipe(Level, BlockPos)` |
| `items.WateringCanItem` | `WATERING_CAN`（耐久 20） | `extends Item` | `WateringCanItem(Properties)`；`void onUseTick(Level, LivingEntity, ItemStack, int countLeft)`（对 `3×3` 范围内 `ClimateReceiver` 加水 0.25）；`InteractionResult useOn(UseOnContext)`（水中补满）；`int getUseDuration(ItemStack, LivingEntity)` = 20；`UseAnim getUseAnimation(ItemStack)` = BOW |
| `items.FLFood` / `items.FLFoodTraits` / `items.Spice` | 见 5.3 | — | 见 5.3 |
| `items.FLItems` | 注册表本体 | `class` | 主要映射：`FOODS`（`Map<FLFood, ItemId>`，`food/<name>`）、`FRUITS`（`Map<FLFruit, ItemId>`）、`SPICES`（`Map<Spice, ItemId>`，`spice/<name>`）、`FINISHES`（`Map<OvenType, ItemId>`）、`FRUIT_PRESERVES` / `UNSEALED_FRUIT_PRESERVES` / `JAM`（按 `FLFruit`）、`METAL_ITEMS`（`Map<FLMetal, Map<FLMetal.ItemType, ItemId>>`，`metal/<type>/<metal>`）、`METAL_FLUID_BUCKETS` / `EXTRA_FLUID_BUCKETS` / `WINE_FLUID_BUCKETS`、`CHROMIUM_ORES`；另有 `TFC_FRUITS`（`EnumSet<Food>`，22 种 TFC 水果，用于联动配方）、`BEEKEEPER_*` 4 件护甲、`HONEY_JAR`/`COMPOST_JAR`/`ROTTEN_COMPOST_JAR`/`GUANO_JAR` |

---

## 7. `common/misc/`、`config/`、`compat/` 清单

### 7.1 `common/misc/`

| 类名 | 注册名 | 作用 |
| --- | --- | --- |
| `misc.FLParticles` | `DeferredRegister<ParticleType<?>> PARTICLE_TYPE`；`GROWTH`（`firmalife:growth`，`SimpleParticleType`）、`SPRINKLER`（`firmalife:sprinkler`，`ParticleType<FluidParticleOption>`） | 粒子类型注册 |
| `misc.FLSounds` | `SOUND`；`HOLLOW_SHELL_BLOW`（`firmalife:item.hollow_shell.blow`） | 音效注册（`SoundEvent.createVariableRangeEvent`） |
| `misc.FLPOIs` | `TYPES`（注册到 `BuiltInRegistries.POINT_OF_INTEREST_TYPE`）；`BEEHIVES`（`firmalife:beehives`，含 `BEEHIVE` 与 `SKEP` 全部状态）、`CLIMATE_STATIONS`（`firmalife:climate_stations`，含 `CLIMATE_STATION` 全部状态） | 兴趣点，用于蜂群寻巢与气候站搜索（`ClimateReceiver.findClimateStation`） |
| `misc.FLLoot` | `MODIFIER_SERIALIZER`（`NeoForgeRegistries.Keys.GLOBAL_LOOT_MODIFIER_SERIALIZERS`）、`CONDITION`（`Registries.LOOT_CONDITION_TYPE`）；`BLOCK_INGREDIENT`（`firmalife:block_ingredient`）、`ADD_ITEM`（`firmalife:add_item`） | 战利品条件与全局战利品修饰器注册；`static void registerAll(IEventBus bus)`；嵌套 `record GLMId<T extends IGlobalLootModifier>` |
| `misc.FLDamageTypes` | 伤害类型 ResourceKey：`firmalife:oven`（`OVEN`）、`firmalife:swarm`（`SWARM`） | `static void oven(Entity, float)`、`static void swarm(Entity, float)`、私有 `fetch(...)` |
| `misc.FLEffects` | `EFFECT`；`SWARM`（`firmalife:swarm`，`SwarmEffect`，`MobEffectCategory.HARMFUL`，颜色 `0xffff1a`） | 状态效果注册；`static <T extends MobEffect> Id<T> register(String, Supplier<T>)` |
| `misc.FLInteractionManager` | 无 | `static void init()`：注册 3 个 TFC `InteractionManager` 条目——羊毛线/菠萝线放置成 `StringBlock`（并在 `postPlacement` 调用 `setPlacedBy`）、`WROUGHT_IRON_GRILL` 放在炉底上方生成 `STOVETOP_GRILL`、`POT` 生成 `STOVETOP_POT`（后两者触发 `FLAdvancements`） |
| `misc.AddItemModifier` | `firmalife:add_item`（全局战利品修饰器） | `extends LootModifier`；`CODEC`（`codecStart` + `item` + `chance`（默认 1.0））；`doApply(...)`：有精准采集则跳过，否则按 `chance` 追加物品（构造时 `FoodCapability.setTransientNonDecaying`） |
| `misc.BlockIngredientLootCondition` | `firmalife:block_ingredient`（战利品条件） | `record BlockIngredientLootCondition(BlockIngredient ingredient) implements LootItemCondition`；`CODEC`（字段 `ingredient`）；`boolean test(LootContext)` 检查 `LootContextParams.BLOCK_STATE` |
| `misc.SwarmEffect` | `firmalife:swarm`（状态效果） | `extends MobEffect`；`static void particles(Level, BlockPos, RandomSource)`；`boolean shouldApplyEffectTickThisTick(int time, int amp)`（`25 >> amp` 周期）、`boolean applyEffectTick(LivingEntity, int)`（未淋雨/水中且 `FLConfig.SERVER.enableBeeAttack` 且非全套防蜂护甲时 `FLDamageTypes.swarm(entity, 0.5f)`）；`hasBeeArmor(LivingEntity)` 要求四件均为 `FLTags.Items.BEEKEEPER_ARMOR` |
| `misc.SprinklerParticle` | 无（客户端粒子类） | `extends FluidDripParticle.FluidFallAndLandParticle`；`SprinklerParticle(ClientLevel, double, double, double, Fluid)`；`static ParticleProvider<FluidParticleOption> provider(SpriteSet, FluidParticleFactory)` |

`common/misc/` 下另有 `package-info.java`（包注解），无其他类。

### 7.2 `config/`

| 类名 | 注册名 | 作用 |
| --- | --- | --- |
| `config.FLConfig` | 无 | `public static final FLServerConfig SERVER = register(FLServerConfig::new, ConfigBuilder.ServerValue::new, "server")`；私有泛型 `register(Function<ConfigBuilder,C>, ConfigBuilder.Factory, String prefix)` 用 `ModConfigSpec.Builder().configure(...)` 构建并 `updateSpec` |
| `config.FLServerConfig` | 配置文件段 `server` | `extends BaseConfig`（TFC）；字段（全部 `Supplier`）：`cheeseAgedDays`(28)、`cheeseVintageDays`(112)、`dryingTicks`(12000)、`solarDryingTicks`(1000)、`smokingTicks`(8000)、`smokingFirepitRange`(6)、`compostTumblerTicks`(96000)、`ovenCureTicks`(2000)、`ovenCureTemperature`(600)、`ovenAshChance`(0.5)、`ovenRequirePeel`(true)、`enableSeedBalls`(true)、`enableBeeAttack`(true)、`beeUseHoneyDays`(12)、`hollowShellCapacity`(100)、`wineGlassCapacity`(250，注意其 define 名误用 `hollowShellCapacity`)、`cellarLevel2Temperature`(0)、`cellarLevel3Temperature`(-12)、`greenhouseGrowthModifier`(1)、`greenhouseWaterDays`(14)、`greenhouseNutrientDays`(8)、`foodTraits`(`Map<FLFoodTraits.Default, Supplier<Double>>`)、`greenhouseRadius`(15)、`cellarRadius`(15)、`mechanicalPowerCheatMode`(false)、`usePipesForSprinklers`(true) |

### 7.3 `compat/`

| 类名 | 注册名 / 注解 | 作用 |
| --- | --- | --- |
| `compat.jei.FLJEIPlugin` | `@JeiPlugin`，`implements IModPlugin` | 定义 JEI 配方类型常量：`DRYING`、`SMOKING`、`STOMPING`、`PRESS`、`CENTRIFUGE`、`MIXING_BOWL`、`PUMPKIN_KNAPPING`（复用 TFC `KnappingRecipe`）、`OVEN`、`VAT`、`BOWL_POT`、`STINKY_SOUP`；`registerCategories(IRecipeCategoryRegistration)`、`registerRecipes(IRecipeRegistration)`、`registerRecipeCatalysts(IRecipeCatalystRegistration)` |
| `compat.jei.DryingCategory` | — | `extends SimpleItemRecipeCategory<DryingRecipe>` |
| `compat.jei.SmokingCategory` | — | `extends SimpleItemRecipeCategory<SmokingRecipe>` |
| `compat.jei.StompingCategory` | — | `extends SimpleItemRecipeCategory<StompingRecipe>` |
| `compat.jei.PressCategory` | — | `extends SimpleItemRecipeCategory<PressRecipe>` |
| `compat.jei.CentrifugeCategory` | — | `extends SimpleItemRecipeCategory<CentrifugeRecipe>` |
| `compat.jei.MixingCategory` | — | `extends BaseRecipeCategory<MixingBowlRecipe>`（5 个输入坐标 `INPUT_X = {15,5,25,5,25}`、`INPUT_Y = {5,25,25,45,45}`） |
| `compat.jei.OvenCategory` | — | `extends BaseRecipeCategory<OvenRecipe>` |
| `compat.jei.VatCategory` | — | `extends BaseRecipeCategory<VatRecipe>` |
| `compat.jei.BowlPotCategory` | — | `extends PotRecipeCategory<PotRecipe>` |
| `compat.jei.StinkySoupCategory` | — | `extends PotRecipeCategory<PotRecipe>` |
| `compat.patchouli.FLPatchouliIntegration` | 无 | `static void registerMultiBlocks()`：注册帕秋莉多方块结构；私有 `static void registerMultiblock(String name, Function<PatchouliAPI.IPatchouliAPI, IMultiblock> factory)` |
| `compat.patchouli.DryingComponent` | — | `extends SimpleItemRecipeComponent<DryingRecipe>` |
| `compat.patchouli.SmokingComponent` | — | `extends SimpleItemRecipeComponent<SmokingRecipe>` |
| `compat.tooltip.FLTooltips` | 无 | `final class`；`static final class BlockEntities`：`static void register(RegisterCallback<BlockEntityTooltip, Block>)` 以及 12 个具名 tooltip：`KEG`、`POT`、`VAT`、`TUMBLER`、`CLIMATE_STATION`、`DRYING_MAT`、`STRING`、`CHEESE`、`SHELF_OR_HANGER`、`OVEN`、`JARBNET`、`BARREL_PRESS`；`static final class Entities`：`static void register(RegisterCallback<EntityTooltip, Entity>)` |
| `compat.tooltip.JadeIntegration` | `implements IWailaPlugin` | `void registerClient(IWailaClientRegistration)`；两个私有 `register(...)` 重载（方块实体 tooltip / 实体 tooltip） |
| `compat.tooltip.TheOneProbeIntegration` | `implements Function<ITheOneProbe, Void>` | `apply(ITheOneProbe)`；两个私有 `register(...)` 重载 |

---

## 8. `common/entities/FLBee.java` 要点

来源：`common/entities/FLBee.java`、`common/entities/FLEntities.java`。

- 注册：`FLEntities.FLBEE` → 注册名 `firmalife:bee`，`EntityType.Builder.of(FLBee::new, MobCategory.CREATURE).sized(0.2F, 0.2F).clientTrackingRange(2)`。
- 继承：`extends Bee`（原版蜜蜂）。私有的 TFC 专属状态：`@Nullable BlockPos spawnPos`、`long daySpawned = -1`。
- 构造：`public FLBee(EntityType<? extends Bee> type, Level level)`。
- 交互：`public InteractionResult mobInteract(Player, InteractionHand)` 恒定返回 `PASS`（不能用花/瓶子交互）。
- AI 改动（`protected void registerGoals()`）：在父类目标之后，**移除优先级 1、5、8 的原有目标**，然后在优先级 8 加入自定义 `FLBeeWanderGoal`：

```java
EntityHelpers.removeGoalOfPriority(this.goalSelector, 1);
EntityHelpers.removeGoalOfPriority(this.goalSelector, 5);
EntityHelpers.removeGoalOfPriority(this.goalSelector, 8);
this.goalSelector.addGoal(8, new FLBeeWanderGoal());
```

- `FLBeeWanderGoal`（内部 `public class ... extends Goal`）：`setFlags(EnumSet.of(Goal.Flag.MOVE))`；`WANDER_THRESHOLD = 6`；`canUse()` = `navigation.isDone() && random.nextInt(10) == 0`；`canContinueToUse()` = `navigation.isInProgress()`；`start()` 用 `navigation.moveTo(createPath(...), 1.0D)`；`findPos()` 逻辑：距 `spawnPos` 超过 6 格时朝巢方向飞，否则沿视线方向；主用 `HoverRandomPos.getPos(this, 8, 7, ...)`，失败回退 `AirAndWaterRandomPos.getPos(this, 8, 4, -2, ...)`。
- 生命周期（`public void aiStep()`）：前 2 tick 初始化 `spawnPos`（默认当前位置）与 `daySpawned`（`Calendars.get(level()).getTotalCalendarDays()`）；夜晚或下雨立即 `discard()`；每 400 tick 检查，若已跨日（`getTotalCalendarDays() > daySpawned && daySpawned >= 0`）或 `isAngry()` 则 `discard()`。
- 存档：`addAdditionalSaveData`/`readAdditionalSaveData` 读写 `spawnPos`（`NbtUtils`）与 `daySpawned`；`public BlockPos getSpawnPos()`、`public void setSpawnPos(BlockPos)`。
- 生成来源：由 `FLBeehiveBlockEntity.controlEntitiesTick()` 在白天、温度足够、有蜂王且前方格可通行时于朝向前方生成，并设置朝向与 `setSpawnPos(posInFront)`。
- 属性（Attributes）：源码未覆写 `createAttributes()`，因此沿用原版 `Bee` 的属性；FLBee 未注册自定义属性，**未能核实**任何 Firmalife 特有的属性改动。

---

## 9. 交叉验证与不确定项

以下内容在本次分析中无法从 Firmalife 源码直接确认，或存在需要后续核对之处：

1. `QuadPlanterBlock` 的 `PlanterType.QUAD` 赋值位置：初次批量扫描时输出被截断导致误判，后续以 `grep` 定点复核确认存在该覆写（`QuadPlanterBlock.java:34-36` 返回 `PlanterType.QUAD`），已在 4.2 与 4.9 更正。
2. `util.FLClimateRanges`、`util.FLDataManagers`、`util.FLSelfTests`、`common/FLHelpers.java`、`common/FLTags.java`、`common/FLEvents.java`、`common/FLForgeEvents.java`、`client/**`、`worldgen/**`、`mixin/**` 的逐类明细未纳入本清单（任务范围限定为 recipes / blockentities / container / blocks / util+capabilities / items / misc+config+compat / FLBee）。其中涉及的方块实体注册在 `FLBlockEntities` 中已全部覆盖，无遗漏注册项。
3. `FLServerConfig.wineGlassCapacity` 的 `define("hollowShellCapacity", 250, ...)` 使用了重复的配置键名（源码如此），可能造成 `wine_glass` 容量实际读取到 `hollowShellCapacity` 键 —— 属源码事实，是否为缺陷需作者确认。
4. `OvenRecipe.assembleItem` 会无条件把输入热量写入输出；`VatRecipe.assemble` 恒返回 `null`（真实产出走 `assembleOutputs`）—— 均为源码事实，非推测。
5. TFC 侧类型（`ISimpleRecipe`、`INoopInputRecipe`、`IRecipePredicate`、`ItemRecipe`、`PotRecipe`、`PotOutput`）均已通过 `javap -cp <TFC jar>` 核实其签名，见 1.4 / 1.5 的接口描述。
