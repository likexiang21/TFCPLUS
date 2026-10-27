# Firmalife ↔ TFC 集成点与对外可复用公开 API（中间材料）

> 本文是源码调查的中间材料，用于后续对外部附属模组开发者撰写文档。所有结论均附来源。
> 文中未标注「未能核实」的条目，均基于本机可读文件或 jar 的 javap 输出。

## 0. 调查范围、版本与工具

### 0.1 被调查对象

| 项 | 值 | 来源 |
|---|---|---|
| Firmalife 源码树 | `moddev/src-ref/Firmalife`（NeoForge 1.21.1） | 目录实际存在 |
| Firmalife 版本 | git tag `v3.0.14`，HEAD `505bbb7`（工作区干净） | 由子调查确认 |
| Firmalife 编译产物 | `mods/Firmalife-NeoForge-1.21.1-3.0.14.jar`（4,488,045 字节） | 目录列表 |
| TFC 编译产物 | `mods/TerraFirmaCraft-NeoForge-1.21.1-4.2.10.jar`（65,348,119 字节） | 目录列表 |
| TFC 源码 | **未克隆**。`moddev/src-ref/TerraFirmaCraft/` 只有 `.git`、无工作树，且 `git` 报 `HEAD` 损坏 | 检查 `moddev/src-ref` 目录 |
| JDK / javap | `C:\Program Files\Java\jdk-25.0.3\bin\javap.exe` | 实际执行 |

因此：**凡涉及 TFC 内部实现的判断（方法体行为、default 返回值语义），本文一律标注「未能核实」**；TFC 侧只引用 javap 得到的**签名**，并标注 jar 中的类名。

### 0.2 javap 命令形式

```powershell
$jar = "D:\111\最强服务器\.minecraft\versions\Essential TerraFirmaCraft (TFC)\mods\TerraFirmaCraft-NeoForge-1.21.1-4.2.10.jar"
& "C:\Program Files\Java\jdk-25.0.3\bin\javap.exe" -p -cp $jar net.dries007.tfc.util.registry.RegistryMetal
# 含 $ 的内部类名必须用单引号，否则 PowerShell 会当变量展开：
& "C:\Program Files\Java\jdk-25.0.3\bin\javap.exe" -p -cp $jar 'net.dries007.tfc.common.recipes.outputs.PotOutput$OutputType'
```

### 0.3 两个源集

Firmalife 有 **两个 Java 源集**，后续所有路径都以此为准：

| 源集 | 路径 | 作用 | 证据 |
|---|---|---|---|
| 主源集 | `src/main/java/com/eerussianguy/firmalife/` | 运行时代码 | `build.gradle.kts` 第 83–91 行 |
| 数据生成源集 | `src/data/java/com/eerussianguy/firmalife/` | datagen 生成器 | `build.gradle.kts` 第 90 行 `create("data")` |

```gradle
sourceSets {
    main {
        resources {
            srcDir(modDataOutput)
            srcDir(generateModMetadata)
        }
    }
    create("data")
}
```
（`build.gradle.kts` 第 83–91 行；`modDataOutput = "src/generated/resources"` 见第 25 行）

**重要事实**（后文第 2.3 节要用）：`src/main/resources/data/firmalife/` 下**只有** `advancement/` 与 `worldgen/`，**没有 `recipe/` 目录**；配方 JSON 全部由 datagen 输出到 `src/generated/resources/data/firmalife/recipe/`（约 1069 个 JSON）。证据：目录列表 + Firmalife jar 内 `data/firmalife/recipe/` 共 1159 个条目（含目录项）。

---

## 1. Firmalife 对 TFC 的集成点

### 1.1 复用 TFC 的枚举与注册体系

#### 1.1.1 `Wood` / `Rock` / `Ore`：不自定义枚举，直接遍历 TFC 枚举

Firmalife **没有自己的 Wood 枚举，也没有 `FLWood` 类**：全仓库 `**/*Wood*.java` 只命中 `WoodenBeehiveBlockEntity.java` 与 `WoodenBeehiveBlock.java`（与 `Wood` 枚举无关）。

`src/main/java/com/eerussianguy/firmalife/common/blocks/FLBlocks.java` 第 220–227 行（`Helpers.mapOf(Wood.class, ...)` 批量生成 7 类木制机器）：

```java
    public static final Map<Wood, Id<Block>> FOOD_SHELVES = Helpers.mapOf(Wood.class, wood -> register("wood/food_shelf/" + wood.getSerializedName(), () -> new FoodShelfBlock(shelfProperties().mapColor(wood.woodColor()))));
    public static final Map<Wood, Id<Block>> HANGERS = Helpers.mapOf(Wood.class, wood -> register("wood/hanger/" + wood.getSerializedName(), () -> new HangerBlock(hangerProperties().mapColor(wood.woodColor()))));
    public static final Map<Wood, Id<Block>> JARBNETS = Helpers.mapOf(Wood.class, wood -> register("wood/jarbnet/" + wood.getSerializedName(), () -> new JarbnetBlock(jarbnetProperties().mapColor(wood.woodColor()))));
    public static final Map<Wood, Id<Block>> KEG_SUBS = Helpers.mapOf(Wood.class, wood -> registerNoItem("wood/keg_sub/" + wood.getSerializedName(), () -> new KegSubBlock(ExtendedProperties.of().noLootTable().mapColor(wood.woodColor()).sound(SoundType.WOOD).noOcclusion().strength(10f).pushReaction(PushReaction.BLOCK).flammableLikeLogs().blockEntity(FLBlockEntities.KEG_SUB))));
    public static final Map<Wood, Id<Block>> KEGS = Helpers.mapOf(Wood.class, wood -> register("wood/keg/" + wood.getSerializedName(), () -> new KegCoreBlock(ExtendedProperties.of().mapColor(wood.woodColor()).sound(SoundType.WOOD).noOcclusion().strength(10f).pushReaction(PushReaction.BLOCK).flammableLikeLogs().blockEntity(FLBlockEntities.KEG).serverTicks(KegBlockEntity::serverTick), KEG_SUBS.get(wood))));
    public static final Map<Wood, Id<Block>> WINE_SHELVES = Helpers.mapOf(Wood.class, wood -> register("wood/wine_shelf/" + wood.getSerializedName(), () -> new WineShelfBlock(ExtendedProperties.of().mapColor(wood.woodColor()).sound(SoundType.WOOD).noOcclusion().strength(4f).pushReaction(PushReaction.BLOCK).flammableLikeLogs().blockEntity(FLBlockEntities.WINE_SHELF))));
    public static final Map<Wood, Id<Block>> STOMPING_BARRELS = Helpers.mapOf(Wood.class, wood -> register("wood/stomping_barrel/" + wood.getSerializedName(), () -> new StompingBarrelBlock(ExtendedProperties.of().mapColor(wood.woodColor()).sound(SoundType.WOOD).noOcclusion().strength(4f).pushReaction(PushReaction.BLOCK).flammableLikeLogs().blockEntity(FLBlockEntities.STOMPING_BARREL))));
    public static final Map<Wood, Id<Block>> BARREL_PRESSES = Helpers.mapOf(Wood.class, wood -> register("wood/barrel_press/" + wood.getSerializedName(), () -> new BarrelPressBlock(ExtendedProperties.of().mapColor(wood.woodColor()).sound(SoundType.WOOD).noOcclusion().strength(4f).pushReaction(PushReaction.BLOCK).flammableLikeLogs().blockEntity(FLBlockEntities.BARREL_PRESS).ticks(BarrelPressBlockEntity::tick))));
```

使用到的 TFC `Wood` 访问器：`getSerializedName()`（注册名）与 `woodColor()`（地图颜色）。

`Rock × Ore.Grade` 笛卡尔积注册铬铁矿（`FLBlocks.java` 第 248–253 行）：

```java
    public static final Id<Block> SMALL_CHROMITE = register("ore/small_chromite", () -> GroundcoverBlock.looseOre(Properties.of().strength(0.05F, 0.0F).sound(SoundType.NETHER_ORE).noCollission()));
    public static final Map<Rock, Map<Ore.Grade, Id<Block>>> CHROMITE_ORES = Helpers.mapOf(Rock.class, rock ->
        Helpers.mapOf(Ore.Grade.class, grade ->
            register(("ore/" + grade.name() + "_chromite" + "/" + rock.name()), () -> new Block(Properties.of().sound(SoundType.STONE).strength(3, 10).requiresCorrectToolForDrops()))
        )
    );
```

`Rock.BlockType` 的复用（`src/data/java/com/eerussianguy/firmalife/recipes/CollapseRecipes.java`，铬铁矿塌方→对应圆石）：

```java
        FLBlocks.CHROMITE_ORES.forEach((rock, entry) ->
            collapse(
                BlockIngredient.of(entry.values().stream().map(RegistryHolder::get)),
                TFCBlocks.ROCK_BLOCKS.get(rock).get(Rock.BlockType.COBBLE).get().defaultBlockState()
            )
        );
```

#### 1.1.2 `Metal` 与 `Metal.BlockType` / `Metal.ItemType`

`src/main/java/com/eerussianguy/firmalife/common/blocks/FLBlocks.java` 第 261–265 行：

```java
    public static final Map<FLMetal, Map<Metal.BlockType, Id<Block>>> METALS = Helpers.mapOf(FLMetal.class, metal ->
        Helpers.mapOf(Metal.BlockType.class, type -> type.has(Metal.BISMUTH), type ->
            register(type.createName(metal), type.create(metal), type.createBlockItem(new Item.Properties()))
        )
    );
```

即：金属方块用 TFC 的 `Metal.BlockType`（`createName` / `create` / `createBlockItem` / `has(Metal)`），而金属本体是 Firmalife 自己的 `FLMetal`（见 1.3.1）。物品侧取 TFC 金属物品（`src/data/java/com/eerussianguy/firmalife/Accessors.java`）：

```java
    default ItemLike itemOf(Metal metal, Metal.ItemType type)
    {
        return TFCItems.METAL_ITEMS.get(metal).get(type);
    }
```

**javap（来源 jar，类 `net.dries007.tfc.util.Metal` / `Metal$BlockType`）**：`Metal` 是 27 个常量、`implements StringRepresentable, RegistryMetal`；`Metal$BlockType` 21 个常量（BLOCK、EXPOSED_BLOCK、WEATHERED_BLOCK、OXIDIZED_BLOCK、*_SLAB、*_STAIRS、GRATE 系列、ANVIL、BARS、CHAIN、LAMP、TRAPDOOR）；`Metal$ItemType` 46 个常量。**注意：`Metal` 没有 `Tier` 内部类**，工具等级在 `net.dries007.tfc.common.TFCTiers` + `net.dries007.tfc.common.LevelTier`。

#### 1.1.3 `TFCItems`

Firmalife 用通配包导入 + 直接引用 TFC 的 `ItemId` 作为自己的 holder 类型（`src/main/java/com/eerussianguy/firmalife/common/items/FLItems.java` 第 33 行）：

```java
import net.dries007.tfc.common.items.TFCItems.ItemId;
```

引用点共 99 行、分布 20 个文件，去重后 35 个字段：`ALFALFA`、`BLUBBER`、`BRASS_MECHANISMS`、`BURLAP_CLOTH`、`CANOLA`、`COMPOST`、`CROP_SEEDS`、`EMPTY_JAR`、`EMPTY_JAR_WITH_LID`、`FIRE_INGOT_MOLD`、`FOOD`、`FRUIT_PRESERVES`、`GLUE`、`HEMATITIC_GLASS_BATCH`、`JUTE`、`JUTE_FIBER`、`LUMBER`、`METAL_ITEMS`、`MOLDS`、`MORTAR`、`OLIVE_PASTE`、`OLIVINE_GLASS_BATCH`、`PAPYRUS`、`POT`、`POWDERS`、`ROTTEN_COMPOST`、`SILICA_GLASS_BATCH`、`SPINDLE`、`STICK_BUNDLE`、`STRAW`、`VOLCANIC_GLASS_BATCH`、`WOODEN_BUCKET`、`WOOL`、`WOOL_YARN`、`WROUGHT_IRON_GRILL`。

典型片段（`FLItems.java` 第 97–100 行，同时展示 `Lore` 组件复用）：

```java
    public static final ItemId HONEY_JAR = register("jar/honey", () -> new Item(new Item.Properties().component(Lore.TYPE, Lore.SEALED).craftRemainder(TFCItems.EMPTY_JAR.asItem())));
    public static final ItemId COMPOST_JAR = register("jar/compost", () -> new Item(new Item.Properties().component(Lore.TYPE, Lore.UNSEALED).craftRemainder(TFCItems.EMPTY_JAR.asItem())));
```

**javap（来源 jar，类 `net.dries007.tfc.common.items.TFCItems`）**：`public final class`，230 个 `public static final` 字段 = 196 个 `TFCItems$ItemId` 常量 + 33 个 `Map<..., ItemId>` + 1 个 `DeferredRegister<Item> ITEMS`；0 个 public static 方法。`TFCItems$ItemId` 是 record，`implements RegistryHolder<Item, Item>` 与 `ItemLike`。

#### 1.1.4 `TFCCreativeTabs`

Firmalife **不建自己的 CreativeModeTab Id 体系**，而是复用 TFC 的 `TFCCreativeTabs.Id` 作为返回值类型，并把内容注入 TFC 现有标签页（`src/main/java/com/eerussianguy/firmalife/common/FLCreativeTabs.java`）：

```java
    public static final TFCCreativeTabs.Id FIRMALIFE = register("firmalife", () -> new ItemStack(FLBlocks.CURED_OVEN_TOP.get(OvenType.BRICK).get()),  FLCreativeTabs::fillFirmalifeTab);
```

```java
    private static TFCCreativeTabs.Id register(String name, Supplier<ItemStack> icon, CreativeModeTab.DisplayItemsGenerator displayItems)
    {
        final var holder = CREATIVE_TAB.register(name, () -> CreativeModeTab.builder()
            .icon(icon)
            .title(Component.translatable("firmalife.creative_tab." + name))
            .displayItems(displayItems)
            .build());
        return new TFCCreativeTabs.Id(holder, displayItems);
    }
```

向 TFC 标签页注入（第 199–267 行，节选）：

```java
        if (out.getTab() == TFCCreativeTabs.TFC_FOODS_DRINKS.tab().get())
        {
            FLItems.FOODS.values().forEach(reg -> accept(out, reg));
            ...
        }
        else if (out.getTab() == TFCCreativeTabs.TFC_METALS_INGREDIENTS.tab().get())
        {
            for (FLMetal metal : FLMetal.values())
            {
                for (FLMetal.ItemType type : FLMetal.ItemType.values())
                {
                    accept(out, FLItems.METAL_ITEMS, metal, type);
                }
                for (Metal.BlockType type : Metal.BlockType.values())
                {
                    accept(out, FLBlocks.METALS, metal, type);
                }
            }
        }
```

**javap（来源 jar，类 `net.dries007.tfc.common.TFCCreativeTabs`）**：10 个 `Id` 常量（`TFC_BUILDING_BLOCKS`、`TFC_COLORED_BLOCKS`、`TFC_NATURAL_BLOCKS`、`TFC_FLORA_CROPS`、`TFC_FUNCTIONAL_BLOCKS`、`TFC_TOOLS_UTILITIES`、`TFC_COMBAT`、`TFC_FOODS_DRINKS`、`TFC_METALS_INGREDIENTS`、`TFC_SPAWN_EGGS`），另有 `public static Stream<CreativeModeTab.DisplayItemsGenerator> generators()`、`public static void setAllTabContentAsNonDecaying(BuildCreativeModeTabContentsEvent)`、`public static void addToVanillaTabs(BuildCreativeModeTabContentsEvent)`。`TFCCreativeTabs$Id` 是 `public record(DeferredHolder<CreativeModeTab, CreativeModeTab> tab, DisplayItemsGenerator generator)`。

#### 1.1.5 `TFCTiers`（注意：类名不是 `Tiers`）

`src/main/java/com/eerussianguy/firmalife/common/util/FLMetal.java` 第 20、59–62 行：

```java
import net.dries007.tfc.common.TFCTiers;
...
    @Override
    public LevelTier toolTier()
    {
        return TFCTiers.STEEL;
    }
```

**javap（来源 jar）**：`net.dries007.tfc.common.TFCTiers` 有 14 个 `public static final LevelTier` 常量（IGNEOUS_INTRUSIVE、IGNEOUS_EXTRUSIVE、SEDIMENTARY、METAMORPHIC、OBSIDIAN、COPPER、BRONZE、BISMUTH_BRONZE、BLACK_BRONZE、WROUGHT_IRON、STEEL、BLACK_STEEL、BLUE_STEEL、RED_STEEL）；`net.dries007.tfc.common.LevelTier extends net.minecraft.world.item.Tier` 只加 `public abstract int level();`。

#### 1.1.6 `TFCBlockEntities`

Firmalife 只复用它的内部 `Id` 类型（`src/main/java/com/eerussianguy/firmalife/common/blockentities/FLBlockEntities.java` 第 14 行）：

```java
import net.dries007.tfc.common.blockentities.TFCBlockEntities.Id;
```

并继承 TFC 的方块实体基类（第 13、42 行）：

```java
import net.dries007.tfc.common.blockentities.BerryBushBlockEntity;
...
    public static final Id<BerryBushBlockEntity> BERRY_BUSH = register("berry_bush", FLBerryBushBlockEntity::new, Stream.of(FLBlocks.FRUIT_TREE_LEAVES.values().stream(), FLBlocks.STATIONARY_BUSHES.values().stream()).flatMap(e -> e));
```

**javap（来源 jar，类 `net.dries007.tfc.common.blockentities.TFCBlockEntities`）**：66 个 `public static final` 字段、0 个 public static 方法；`TFCBlockEntities$Id<T>` 是 record，`implements RegistryHolder<BlockEntityType<?>, BlockEntityType<T>>`。

#### 1.1.7 `TFCRecipeTypes` / `TFCRecipeSerializers`

Firmalife 自制配方类型（见第 2.3 节），但对 TFC 有 4 类依赖：

① 借用内部 `Id` 类型（`FLRecipeTypes.java` 第 10 行、`FLRecipeSerializers.java` 第 12 行）：

```java
import net.dries007.tfc.common.recipes.TFCRecipeTypes.Id;
import net.dries007.tfc.common.recipes.TFCRecipeSerializers.Id;
```

② 把自有锅产物注册进 TFC 的 `PotOutput` 注册表（`FLRecipeTypes.java` 第 18、29–30 行）：

```java
    public static final DeferredRegister<PotOutput.OutputType> POT_OUTPUT_TYPE = DeferredRegister.create(PotOutput.KEY, MOD_ID);
    ...
    public static final DeferredHolder<PotOutput.OutputType, PotOutput.OutputType> STINKY_SOUP = POT_OUTPUT_TYPE.register("stinky_soup", () -> StinkySoupRecipe.OUTPUT_TYPE);
    public static final DeferredHolder<PotOutput.OutputType, PotOutput.OutputType> BOWL = POT_OUTPUT_TYPE.register("bowl", () -> BowlPotRecipe.OUTPUT_TYPE);
```

③ 用 TFC 的 `RecipeSerializerImpl` 包装 codec（`FLRecipeSerializers.java` 第 11、31–34 行）：

```java
import net.dries007.tfc.common.recipes.RecipeSerializerImpl;
...
    private static <R extends Recipe<?>> Id<R> register(String name, MapCodec<R> codec, StreamCodec<RegistryFriendlyByteBuf, R> stream)
    {
        return register(name, new RecipeSerializerImpl<>(codec, stream));
    }
```

④ 运行时查询 TFC 配方类型（`src/main/java/com/eerussianguy/firmalife/common/recipes/KegRecipe.java` 第 32、39、46 行；`src/main/java/com/eerussianguy/firmalife/common/blockentities/StovetopPotBlockEntity.java` 第 85 行；`src/main/java/com/eerussianguy/firmalife/compat/jei/FLJEIPlugin.java` 第 92 行）：

```java
        return level.getRecipeManager().getAllRecipesFor(TFCRecipeTypes.BARREL_INSTANT.get()).stream()
            .filter(r -> matches(r.value(), inventory)).findFirst().orElse(null);
```
```java
            .getRecipeFor(TFCRecipeTypes.POT.get(), inventory, level)
```
```java
        r.addRecipes(BOWL_POT, recipes(TFCRecipeTypes.POT, recipe -> recipe.getSerializer() == FLRecipeSerializers.BOWL_POT.get()));
```

**javap（来源 jar）**：`TFCRecipeTypes` 20 个 `Id<...>` 类型常量 + `RECIPE_TYPES`；`TFCRecipeSerializers` 26 个 `Id<...>` + `RECIPE_SERIALIZERS`。两者的 `register(...)` 都是 `private static`。

#### 1.1.8 `net.dries007.tfc.util.data.DataManagers`

`src/main/java/com/eerussianguy/firmalife/common/util/FLDataManagers.java`（全文 18 行）：

```java
public class FLDataManagers
{
    public static void init()
    {
        register(GreenhouseType.MANAGER);
        register(Plantable.MANAGER);
    }

    private static void register(DataManager<?> manager)
    {
        DataManagers.MANAGERS.register(manager.getName(), () -> manager);
    }
}
```

调用点：`src/main/java/com/eerussianguy/firmalife/FirmaLife.java` 第 81 行 `FLDataManagers.init();`

#### 1.1.9 一个结构性事实：Firmalife 全面复用 TFC 的 `Id` 内部类

`import net.dries007.tfc.<...>.Id;` 命中 13 个文件：

| Firmalife 文件 | import 原文 |
|---|---|
| `common/blocks/FLBlocks.java` | `net.dries007.tfc.common.blocks.TFCBlocks.Id` |
| `common/items/FLItems.java` | `net.dries007.tfc.common.items.TFCItems.ItemId` |
| `common/blockentities/FLBlockEntities.java` | `net.dries007.tfc.common.blockentities.TFCBlockEntities.Id` |
| `common/container/FLMenuTypes.java` | `net.dries007.tfc.common.container.TFCContainerTypes.Id` |
| `common/recipes/FLRecipeTypes.java` | `net.dries007.tfc.common.recipes.TFCRecipeTypes.Id` |
| `common/recipes/FLRecipeSerializers.java` | `net.dries007.tfc.common.recipes.TFCRecipeSerializers.Id` |
| `common/capabilities/FLComponents.java` | `net.dries007.tfc.common.component.TFCComponents.Id` |
| `common/entities/FLEntities.java` | `net.dries007.tfc.common.entities.TFCEntities.Id` |
| `common/misc/FLEffects.java` | `net.dries007.tfc.common.effect.TFCEffects.Id` |
| `common/misc/FLSounds.java` | `net.dries007.tfc.client.TFCSounds.Id` |
| `common/misc/FLParticles.java` | `net.dries007.tfc.client.particle.TFCParticles.Id` |
| `common/worldgen/FLFeatures.java` | `net.dries007.tfc.world.feature.TFCFeatures.Id` |
| `common/util/FLAdvancements.java` | `net.dries007.tfc.util.advancements.TFCAdvancements.Id` |
| `common/misc/FLLoot.java` | `net.dries007.tfc.util.loot.TFCLoot.Id` |

### 1.2 `RegistrationHelpers`：Firmalife **没有**自己的一份

**核实过程**：全仓库 `glob **/RegistrationHelpers*` → 无结果；全仓库 grep `RegistrationHelpers` → 9 行命中，全部是 import 或对该 TFC 类方法的调用。

使用 TFC 类的 import 原文（4 个文件）：

```java
// src/main/java/com/eerussianguy/firmalife/common/blocks/FLFluids.java:25
// src/main/java/com/eerussianguy/firmalife/common/blocks/FLBlocks.java:115
// src/main/java/com/eerussianguy/firmalife/common/blockentities/FLBlockEntities.java:15
// src/main/java/com/eerussianguy/firmalife/common/container/FLMenuTypes.java:19
import net.dries007.tfc.util.registry.RegistrationHelpers;
```

**5 处调用点**：

| # | 文件 | 行 | 调用 |
|---|---|---|---|
| 1 | `src/main/java/com/eerussianguy/firmalife/common/blocks/FLFluids.java` | 107 | `registerFluid(...)` |
| 2 | `src/main/java/com/eerussianguy/firmalife/common/blocks/FLBlocks.java` | 359 | `registerBlock(...)` |
| 3 | `src/main/java/com/eerussianguy/firmalife/common/blockentities/FLBlockEntities.java` | 73 | `register(...)`（单方块） |
| 4 | `src/main/java/com/eerussianguy/firmalife/common/blockentities/FLBlockEntities.java` | 78 | `register(...)`（Stream） |
| 5 | `src/main/java/com/eerussianguy/firmalife/common/container/FLMenuTypes.java` | 34 | `registerBlockEntityContainer(...)` |

调用原文（`FLBlocks.java` 第 357–360 行）：

```java
    private static <T extends Block> Id<T> register(String name, Supplier<T> blockSupplier, @Nullable Function<T, ? extends BlockItem> blockItemFactory)
    {
        return new Id<>(RegistrationHelpers.registerBlock(BLOCK, FLItems.ITEM, name, blockSupplier, blockItemFactory));
    }
```

（`FLMenuTypes.java` 第 32–35 行）：

```java
    private static <T extends InventoryBlockEntity<?>, C extends BlockEntityContainer<T>> Id<C> registerBlock(String name, Supplier<BlockEntityType<T>> type, BlockEntityContainer.Factory<T, C> factory)
    {
        return new Id<>(RegistrationHelpers.registerBlockEntityContainer(MENU, name, type, factory));
    }
```

#### 1.2.1 完整签名（javap -p，来源 jar：`net.dries007.tfc.util.registry.RegistrationHelpers`）

```java
public final class net.dries007.tfc.util.registry.RegistrationHelpers {
  public net.dries007.tfc.util.registry.RegistrationHelpers();
  public static <T extends net.minecraft.world.level.block.Block> net.neoforged.neoforge.registries.DeferredHolder<net.minecraft.world.level.block.Block, T> registerBlock(net.neoforged.neoforge.registries.DeferredRegister<net.minecraft.world.level.block.Block>, net.neoforged.neoforge.registries.DeferredRegister<net.minecraft.world.item.Item>, java.lang.String, java.util.function.Supplier<T>, java.util.function.Function<T, ? extends net.minecraft.world.item.BlockItem>);
  public static <F extends net.minecraft.world.level.material.FlowingFluid> net.dries007.tfc.common.fluids.FluidHolder<F> registerFluid(net.neoforged.neoforge.registries.DeferredRegister<net.neoforged.neoforge.fluids.FluidType>, net.neoforged.neoforge.registries.DeferredRegister<net.minecraft.world.level.material.Fluid>, java.lang.String, java.lang.String, java.lang.String, java.util.function.Consumer<net.neoforged.neoforge.fluids.BaseFlowingFluid$Properties>, java.util.function.Supplier<net.neoforged.neoforge.fluids.FluidType>, java.util.function.Function<net.neoforged.neoforge.fluids.BaseFlowingFluid$Properties, F>, java.util.function.Function<net.neoforged.neoforge.fluids.BaseFlowingFluid$Properties, F>);
  public static <T extends net.minecraft.world.level.block.entity.BlockEntity> net.neoforged.neoforge.registries.DeferredHolder<net.minecraft.world.level.block.entity.BlockEntityType<?>, net.minecraft.world.level.block.entity.BlockEntityType<T>> register(net.neoforged.neoforge.registries.DeferredRegister<net.minecraft.world.level.block.entity.BlockEntityType<?>>, java.lang.String, net.minecraft.world.level.block.entity.BlockEntityType$BlockEntitySupplier<T>, java.util.function.Supplier<? extends net.minecraft.world.level.block.Block>);
  public static <T extends net.minecraft.world.level.block.entity.BlockEntity> net.neoforged.neoforge.registries.DeferredHolder<net.minecraft.world.level.block.entity.BlockEntityType<?>, net.minecraft.world.level.block.entity.BlockEntityType<T>> register(net.neoforged.neoforge.registries.DeferredRegister<net.minecraft.world.level.block.entity.BlockEntityType<?>>, java.lang.String, net.minecraft.world.level.block.entity.BlockEntityType$BlockEntitySupplier<T>, java.util.stream.Stream<? extends java.util.function.Supplier<? extends net.minecraft.world.level.block.Block>>);
  public static <T extends net.dries007.tfc.common.blockentities.InventoryBlockEntity<?>, C extends net.dries007.tfc.common.container.BlockEntityContainer<T>> net.neoforged.neoforge.registries.DeferredHolder<net.minecraft.world.inventory.MenuType<?>, net.minecraft.world.inventory.MenuType<C>> registerBlockEntityContainer(net.neoforged.neoforge.registries.DeferredRegister<net.minecraft.world.inventory.MenuType<?>>, java.lang.String, java.util.function.Supplier<net.minecraft.world.level.block.entity.BlockEntityType<T>>, net.dries007.tfc.common.container.BlockEntityContainer$Factory<T, C>);
  public static <C extends net.dries007.tfc.common.container.ItemStackContainer> net.neoforged.neoforge.registries.DeferredHolder<net.minecraft.world.inventory.MenuType<?>, net.minecraft.world.inventory.MenuType<C>> registerItemStackContainer(net.neoforged.neoforge.registries.DeferredRegister<net.minecraft.world.inventory.MenuType<?>>, java.lang.String, net.dries007.tfc.common.container.ItemStackContainer$Factory<C>);
  public static <C extends net.minecraft.world.inventory.AbstractContainerMenu> net.neoforged.neoforge.registries.DeferredHolder<net.minecraft.world.inventory.MenuType<?>, net.minecraft.world.inventory.MenuType<C>> registerContainer(net.neoforged.neoforge.registries.DeferredRegister<net.minecraft.world.inventory.MenuType<?>>, java.lang.String, net.neoforged.neoforge.network.IContainerFactory<C>);
}
```

（另有 10 个 `private static lambda$...` 合成方法，属编译器产物，不构成 API。）

**用法要点（对第三方最有用）**：`registerBlock(blockDR, itemDR, name, supplier, blockItemFactory)` 中 `blockItemFactory` 可传 `null` 表示「只注册方块、不注册 BlockItem」——Firmalife 的 `registerNoItem` 正是这么做的（`FLBlocks.java` 第 342–345 行）。

### 1.3 注册接口的完整定义与 Firmalife 的实现

#### 1.3.1 接口定义（javap -p，全部来自 jar `net.dries007.tfc.util.registry.*`）

```java
Compiled from "RegistryHolder.java"
public interface net.dries007.tfc.util.registry.RegistryHolder<R, T extends R> extends net.dries007.tfc.util.registry.IdHolder<T>, net.dries007.tfc.util.registry.HolderHolder<R> {
  public abstract net.neoforged.neoforge.registries.DeferredHolder<R, T> holder();
  public default T get();
}
Compiled from "IdHolder.java"
public interface net.dries007.tfc.util.registry.IdHolder<T> extends java.util.function.Supplier<T> {
  public abstract net.neoforged.neoforge.registries.DeferredHolder<? super T, T> holder();
  public default net.minecraft.resources.ResourceLocation getId();
}
Compiled from "HolderHolder.java"
public interface net.dries007.tfc.util.registry.HolderHolder<R> {
  public abstract net.neoforged.neoforge.registries.DeferredHolder<R, ? extends R> holder();
  public default net.minecraft.resources.ResourceKey<R> key();
}
Compiled from "RegistryMetal.java"
public interface net.dries007.tfc.util.registry.RegistryMetal extends net.minecraft.util.StringRepresentable {
  public abstract net.dries007.tfc.common.LevelTier toolTier();
  public abstract net.minecraft.core.Holder<net.minecraft.world.item.ArmorMaterial> armorMaterial();
  public abstract int armorDurability(net.minecraft.world.item.ArmorItem$Type);
  public abstract net.minecraft.world.level.block.Block getBlock(net.dries007.tfc.util.Metal$BlockType);
  public abstract net.minecraft.world.level.material.MapColor mapColor();
  public abstract net.minecraft.world.item.Rarity rarity();
  public default boolean weatheredParts();
  public abstract float weatheringResistance();
  public default boolean isPiglinCurrency();
}
Compiled from "RegistryWood.java"
public interface net.dries007.tfc.util.registry.RegistryWood extends net.minecraft.util.StringRepresentable {
  public abstract net.minecraft.world.level.material.MapColor woodColor();
  public abstract net.minecraft.world.level.material.MapColor barkColor();
  public abstract net.minecraft.world.level.block.grower.TreeGrower tree();
  public abstract java.util.function.Supplier<java.lang.Integer> ticksToGrow();
  public abstract int autumnIndex();
  public abstract java.util.function.Supplier<net.minecraft.world.level.block.Block> getBlock(net.dries007.tfc.common.blocks.wood.Wood$BlockType);
  public abstract net.minecraft.world.level.block.state.properties.BlockSetType getBlockSet();
  public abstract net.minecraft.world.level.block.state.properties.WoodType getVanillaWoodType();
  public abstract boolean isConifer();
  public abstract float getFlowerOffset();
}
Compiled from "RegistryPlant.java"
public interface net.dries007.tfc.util.registry.RegistryPlant {
  public abstract boolean isWetSeasonBlooming();
  public abstract int getStartTime();
  public abstract int getEndTime();
  public abstract float getBloomOffset();
  public abstract float getBloomingEnd();
  public abstract float getSeedingEnd();
  public abstract float getDyingEnd();
  public abstract float getDormantEnd();
  public abstract float getSproutingEnd();
  public abstract float getSpeedFactor();
  public abstract net.minecraft.world.level.block.state.properties.IntegerProperty getAgeProperty();
}
Compiled from "RegistryRock.java"
public interface net.dries007.tfc.util.registry.RegistryRock extends net.minecraft.util.StringRepresentable {
  public abstract net.dries007.tfc.common.blocks.rock.RockDisplayCategory displayCategory();
  public default net.dries007.tfc.common.blocks.rock.RockCategory category();
  public default net.minecraft.world.level.material.MapColor color();
  public abstract java.util.function.Supplier<? extends net.minecraft.world.level.block.Block> getBlock(net.dries007.tfc.common.blocks.rock.Rock$BlockType);
  public abstract java.util.function.Supplier<? extends net.minecraft.world.level.block.Block> getAnvil();
  public abstract java.util.function.Supplier<? extends net.minecraft.world.level.block.SlabBlock> getSlab(net.dries007.tfc.common.blocks.rock.Rock$BlockType);
  public abstract java.util.function.Supplier<? extends net.minecraft.world.level.block.StairBlock> getStair(net.dries007.tfc.common.blocks.rock.Rock$BlockType);
  public abstract java.util.function.Supplier<? extends net.minecraft.world.level.block.WallBlock> getWall(net.dries007.tfc.common.blocks.rock.Rock$BlockType);
}
```

**`RegistryOre` 不存在**：jar 中 `net/dries007/tfc/util/registry/` 只有 `RegistryPlant`、`RegistryRock`、`RegistryMetal`、`RegistryHolder`、`IdHolder`、`RegistryWood`、`HolderHolder`、`RegistrySoilVariant`、`RegistrationHelpers` 与 `package-info`（用 `jar tf | Where-Object { $_ -match "^net/dries007/tfc/util/registry/" }` 核实）。Firmalife 任务清单中提到的 `RegistryOre` **未能核实其存在**，检查位置即上述 jar 目录列举。

顺带一个清单外的接口（javap，同包）：`RegistrySoilVariant { Supplier<? extends Block> getBlock(SoilBlockType); Supplier<? extends Item> mudBrick(); }`。

#### 1.3.2 实现类清单（grep 结果）

| 接口 | 实现类 | 文件 |
|---|---|---|
| `RegistryMetal` | `FLMetal` | `src/main/java/com/eerussianguy/firmalife/common/util/FLMetal.java` |
| `RegistryPlant` | `FLPlant` | `src/main/java/com/eerussianguy/firmalife/common/util/FLPlant.java` |
| `RegistryHolder` | `FLLoot.GLMId`、`FLItemStackModifiers.Id`（均为 record） | `common/misc/FLLoot.java`、`common/recipes/data/FLItemStackModifiers.java` |
| `RegistryWood` | **无实现类** | grep 0 命中 |
| `RegistryRock` | **无实现类** | grep 0 命中 |
| `IdHolder` / `HolderHolder` | **无实现类**（仅作为泛型上界/参数类型出现） | `providers/BuiltinItemTags.java`、`recipes/KnappingRecipes.java` 等 |

#### 1.3.3 `FLMetal implements RegistryMetal` 的每个抽象方法实现（原文）

`src/main/java/com/eerussianguy/firmalife/common/util/FLMetal.java`（共 121 行）：

```java
public enum FLMetal implements RegistryMetal
{
    CHROMIUM(0xFFF5FEFF, MapColor.COLOR_LIGHT_GRAY),
    STAINLESS_STEEL(0xFFD9FCFF, MapColor.COLOR_LIGHT_GRAY);
```

```java
    @Override
    public String getSerializedName()
    {
        return serializedName;
    }

    @Override
    public LevelTier toolTier()
    {
        return TFCTiers.STEEL;
    }

    @Override
    public Holder<ArmorMaterial> armorMaterial()
    {
        return Metal.RED_STEEL.armorMaterial();
    }

    @Override
    public int armorDurability(ArmorItem.Type type)
    {
        return Metal.RED_STEEL.armorDurability(type);
    }

    @Override
    public Block getBlock(Metal.BlockType blockType)
    {
        return FLBlocks.METALS.get(this).get(Metal.BlockType.BLOCK).get();
    }

    @Override
    public MapColor mapColor()
    {
        return mapColor;
    }

    @Override
    public Rarity rarity()
    {
        return Rarity.EPIC;
    }

    @Override
    public float weatheringResistance()
    {
        return 0;
    }
```

`getSerializedName()` 来自 `StringRepresentable`；`toolTier/armorMaterial/armorDurability/getBlock/mapColor/rarity/weatheringResistance` 是 `RegistryMetal` 的 7 个抽象方法（`weatheredParts()` 与 `isPiglinCurrency()` 有默认实现，Firmalife 未覆写）。

#### 1.3.4 `FLPlant implements RegistryPlant` 的每个抽象方法实现（原文）

`src/main/java/com/eerussianguy/firmalife/common/util/FLPlant.java`：

```java
public enum FLPlant implements RegistryPlant
{
    HERB(0.9F, new int[] {0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0});
```

```java
    @Override
    public boolean isWetSeasonBlooming()
    {
        return false;
    }

    @Override
    public int getStartTime()
    {
        return 0;
    }

    @Override
    public int getEndTime()
    {
        return 0;
    }

    @Override
    public float getBloomOffset()
    {
        return 0;
    }

    @Override
    public float getBloomingEnd()
    {
        return 0;
    }

    @Override
    public float getSeedingEnd()
    {
        return 0;
    }

    @Override
    public float getDyingEnd()
    {
        return 0;
    }

    @Override
    public float getDormantEnd()
    {
        return 0;
    }

    @Override
    public float getSproutingEnd()
    {
        return 0;
    }

    @Override
    public @Nullable IntegerProperty getAgeProperty()
    {
        return property;
    }
```

`getSpeedFactor()` 未加 `@Override` 但签名与接口一致（同文件 `public float getSpeedFactor() { return speedFactor; }`）。构造中使用 TFC 的 `TFCBlockStateProperties.getAgeProperty(maxStage)`：

```java
        this.property = maxStage > 0 ? TFCBlockStateProperties.getAgeProperty(maxStage) : null;
```

消费点（`FLBlocks.java` 第 209 行）：

```java
    public static final Map<Herb, Id<Block>> HERBS = Helpers.mapOf(Herb.class, herb -> register("plant/" + herb.name(), () -> PlantBlock.create(FLPlant.HERB, FLPlant.HERB.nonSolidFire())));
```

#### 1.3.5 两个 `RegistryHolder` 实现（record，无显式方法体）

`src/main/java/com/eerussianguy/firmalife/common/misc/FLLoot.java`：

```java
    public record GLMId<T extends IGlobalLootModifier>(DeferredHolder<MapCodec<? extends IGlobalLootModifier>, MapCodec<T>> holder)
        implements RegistryHolder<MapCodec<? extends IGlobalLootModifier>, MapCodec<T>> {}
```

`src/main/java/com/eerussianguy/firmalife/common/recipes/data/FLItemStackModifiers.java`：

```java
    record Id<T extends ItemStackModifier>(DeferredHolder<ItemStackModifierType<?>, ItemStackModifierType<T>> holder)
        implements RegistryHolder<ItemStackModifierType<?>, ItemStackModifierType<T>> {}
```

（后者是**包私有 record**，见第 2.4 节。）

### 1.4 事件集成（`src/main/java/com/eerussianguy/firmalife/common/FLForgeEvents.java`）

注册入口：

```java
public class FLForgeEvents
{
    public static void init()
    {
        final IEventBus bus = NeoForge.EVENT_BUS;

        bus.addListener(FLForgeEvents::onFireStart);
        bus.addListener(FLForgeEvents::onFireStop);
        bus.addListener(FLForgeEvents::onAnimalProduce);
        bus.addListener(FLForgeEvents::onLevelLoad);
    }
```

被 `FirmaLife` 构造器调用：`src/main/java/com/eerussianguy/firmalife/FirmaLife.java` 第 88 行 `FLForgeEvents.init();`

三个 TFC 自定义事件（`net.dries007.tfc.util.events.*`）的处理方法原文：

```java
    public static void onFireStart(StartFireEvent event)
    {
        Level level = event.getLevel();
        BlockPos pos = event.getPos();
        BlockState state = event.getState();
        Block block = state.getBlock();

        if (block instanceof OvenBottomBlock)
        {
            level.getBlockEntity(pos, FLBlockEntities.OVEN_BOTTOM.get()).ifPresent(oven -> oven.light(state));
            event.setCanceled(true);
        }
        else if (block instanceof CarvedPumpkinBlock)
        {
            FLBlocks.CARVED_PUMPKINS.forEach((carve, reg) -> {
                if (block == reg.get())
                {
                    level.setBlockAndUpdate(pos, Helpers.copyProperty(FLBlocks.JACK_O_LANTERNS.get(carve).get().defaultBlockState(), state, HorizontalDirectionalBlock.FACING));
                    FLHelpers.resetCounter(level, pos);
                    event.setCanceled(true);
                }
            });
        }
        else if (block instanceof JarbnetBlock)
        {
            FLHelpers.readInventory(level, pos, FLBlockEntities.JARBNET, (jarbnet, inv) -> {
                for (ItemStack stack : Helpers.iterate(inv))
                {
                    if (stack.getItem() instanceof CandleBlockItem)
                    {
                        level.setBlockAndUpdate(pos, state.setValue(JarbnetBlock.LIT, true));
                        jarbnet.resetCounter();
                        event.setCanceled(true);
                        break;
                    }
                }
            });
        }
    }
```

```java
    public static void onFireStop(DouseFireEvent event)
    {
        final BlockState state = event.getState();
        final Level level = event.getLevel();
        final BlockPos pos = event.getPos();

        if (state.getBlock() instanceof OvenBottomBlock && level.getBlockEntity(pos) instanceof OvenBottomBlockEntity bottom)
        {
            bottom.extinguish(state);
            Helpers.playSound(level, pos, SoundEvents.FIRE_EXTINGUISH);
            event.setCanceled(true);
        }
        else if (state.getBlock() instanceof OvenTopBlock && level.getBlockEntity(pos) instanceof OvenTopBlockEntity top)
        {
            top.extinguish();
            Helpers.playSound(level, pos, SoundEvents.FIRE_EXTINGUISH);
            event.setCanceled(true);
        }
        else if (state.getBlock() instanceof StovetopPotBlock && level.getBlockEntity(pos) instanceof StovetopPotBlockEntity pot)
        {
            pot.coolInstantly();
            Helpers.playSound(level, pos, SoundEvents.FIRE_EXTINGUISH);
            event.setCanceled(true);
        }
    }
```

```java
    public static void onAnimalProduce(AnimalProductEvent event)
    {
        final EntityType<?> type = event.getEntity().getType();
        if (type == TFCEntities.YAK.get())
        {
            event.setProduct(new FluidStack(FLFluids.EXTRA_FLUIDS.get(ExtraFluid.YAK_MILK).getSource(), 1000));
        }
        else if (type == TFCEntities.GOAT.get())
        {
            event.setProduct(new FluidStack(FLFluids.EXTRA_FLUIDS.get(ExtraFluid.GOAT_MILK).getSource(), 1000));
        }
    }
```

三个事件的 javap 签名（来源 jar）：

```java
public final class net.dries007.tfc.util.events.AnimalProductEvent extends net.neoforged.bus.api.Event implements net.neoforged.bus.api.ICancellableEvent {
  public static boolean produce(Level, BlockPos, TFCAnimalProperties, ItemStack, ItemStack, int);
  public static boolean produce(Level, BlockPos, Player, TFCAnimalProperties, ItemStack, ItemStack, int);
  public Level getLevel();
  public BlockPos getPos();
  public TFCAnimalProperties getAnimalProperties();
  public Entity getEntity();
  public Player getPlayer();
  public ItemStack getTool();
  public ItemStack getProduct();
  public FluidStack getFluidProduct();
  public void setProduct(ItemStack);
  public void setProduct(FluidStack);
  public int getUses();
  public void setUses(int);
}
```

```java
public class net.dries007.tfc.util.events.DouseFireEvent extends net.neoforged.bus.api.Event implements net.neoforged.bus.api.ICancellableEvent {
  public static boolean douse(Level, BlockPos, Player);
  public static void douse(Level, AABB, Player);
  public Level getLevel();
  public BlockPos getPos();
  public AABB getBounds();
  public BlockState getState();
  public Player getPlayer();
}
```

```java
public final class net.dries007.tfc.util.events.StartFireEvent extends net.neoforged.bus.api.Event implements net.neoforged.bus.api.ICancellableEvent {
  public static boolean startFireWithSound(Level, BlockPos, BlockState, Direction, Player, ItemStack);
  public static boolean startFire(Level, BlockPos, BlockState, Direction, Player, ItemStack);
  public static boolean startFire(Level, BlockPos, BlockState, Direction, Player, ItemStack, StartFireEvent$FireStrength, double);
  public Level getLevel();
  public BlockPos getPos();
  public BlockState getState();
  public Direction getTargetedFace();
  public Player getPlayer();
  public ItemStack getItemStack();
  public boolean isStrong();
}
public final class net.dries007.tfc.util.events.StartFireEvent$FireStrength extends Enum { STRONG, WEAK }
```

（`DouseFireEvent` 与 `StartFireEvent` 的构造器是 `private`：只能监听，不能自行构造派发；主动触发请调用其 `public static` 方法。）

### 1.5 组件系统

#### 1.5.1 `FLComponents`（`src/main/java/com/eerussianguy/firmalife/common/capabilities/FLComponents.java`）

自定义 `DataComponentType` 的注册（复用 TFC 的 `TFCComponents.Id` 包装器）：

```java
    public static final DeferredRegister<DataComponentType<?>> COMPONENT = DeferredRegister.create(Registries.DATA_COMPONENT_TYPE, FirmaLife.MOD_ID);

    public static final Id<BeeComponent> BEE = register("bee", BeeComponent.CODEC, BeeComponent.STREAM_CODEC);
    public static final Id<WineComponent> WINE = register("wine", WineComponent.CODEC, WineComponent.STREAM_CODEC);
...
    private static <T> Id<T> register(String name, Codec<T> codec, StreamCodec<? super RegistryFriendlyByteBuf, T> streamCodec)
    {
        return new Id<>(COMPONENT.register(name, () -> new DataComponentType.Builder<T>()
            .persistent(codec)
            .networkSynchronized(streamCodec)
            .build()));
    }
```

能力注册（`RegisterCapabilitiesEvent`，注意用 `bus.addListener`）：

```java
    public static void register(RegisterCapabilitiesEvent event)
    {
        event.registerItem(ItemCapabilities.FLUID, FLComponents::forWine,
            FLItems.HEMATITIC_WINE_BOTTLE,
            FLItems.OLIVINE_WINE_BOTTLE,
            FLItems.VOLCANIC_WINE_BOTTLE
        );

        event.registerItem(ItemCapabilities.FLUID, ItemCapabilities::forBucket, FLItems.HOLLOW_SHELL, FLItems.WINE_GLASS);
        ...
        event.registerBlockEntity(BlockCapabilities.FLUID, FLBlockEntities.KEG.get(), KegBlockEntity::getSidedFluidInventory);
```

**`FluidContainerHandler` 的直接复用**：

```java
    public static @Nullable FluidContainerHandler forWine(ItemStack stack, @Nullable Void context)
    {
        return stack.getItem() instanceof FilledWineBottleItem item ? new FluidContainerHandler(stack, item.getContainerInfo()) : null;
    }
```

javap（来源 jar，`net.dries007.tfc.common.component.fluid.FluidContainerHandler`）：

```java
public class net.dries007.tfc.common.component.fluid.FluidContainerHandler extends net.dries007.tfc.common.component.ComponentView<FluidComponent> implements net.neoforged.neoforge.fluids.capability.IFluidHandlerItem, net.dries007.tfc.common.component.fluid.FluidContainer {
  public FluidContainerHandler(ItemStack, FluidContainerInfo);
  public FluidContainerInfo containerInfo();
  public ItemStack getContainer();
  public FluidStack getFluidInTank(int);
  public int fill(FluidStack, IFluidHandler$FluidAction);
  public FluidStack drain(int, IFluidHandler$FluidAction);
}
```

#### 1.5.2 `FLFoodTraits`（`src/main/java/com/eerussianguy/firmalife/common/items/FLFoodTraits.java`）

**关键：把 Firmalife 的 18 个食物特性注册进 TFC 的 `FoodTrait` 注册表。**

```java
    // Need to use our own DR to have the correct namespace on traits
    public static final DeferredRegister<FoodTrait> TRAITS = DeferredRegister.create(FoodTraits.KEY, MOD_ID);

    public static final DeferredHolder<FoodTrait, FoodTrait> DRIED = register(Default.DRIED);
    ...
    private static DeferredHolder<FoodTrait, FoodTrait> register(FLFoodTraits.Default trait)
    {
        return TRAITS.register(trait.name.toLowerCase(Locale.ROOT), () -> new FoodTrait(FLConfig.SERVER.foodTraits.get(trait), MOD_ID + ".tooltip.food_trait." + trait.name.toLowerCase(Locale.ROOT)));
    }
```

对应的 javap（来源 jar）：

```java
public final class net.dries007.tfc.common.component.food.FoodTrait {
  public static final Codec<Holder<FoodTrait>> CODEC;
  public static final StreamCodec<RegistryFriendlyByteBuf, Holder<FoodTrait>> STREAM_CODEC;
  public FoodTrait(Supplier<Double>, String);
  public float getDecayModifier();
  public void addTooltipInfo(Consumer<Component>);
}
public class net.dries007.tfc.common.component.food.FoodTraits {
  public static final ResourceKey<Registry<FoodTrait>> KEY;
  public static final Registry<FoodTrait> REGISTRY;
  public static final DeferredRegister<FoodTrait> TRAITS;
  // 10 个内置 trait：SALTED, BRINED, PICKLED, PRESERVED, PRESERVED_IN_VINEGAR, CHARCOAL_GRILLED,
  //   WOOD_GRILLED, BURNT_TO_A_CRISP, WILD, CANNED
}
```

`FoodCapability` 的使用（`src/main/java/com/eerussianguy/firmalife/common/FLHelpers.java` 第 301–314 行，同时展示 `HeatCapability`）：

```java
    public static boolean stackableExceptHeatAndFood(ItemStack stack1, ItemStack stack2)
    {
        // This is a nice way of checking if two stacks are stackable, ignoring the creation date: copy both stacks, give them the same creation date, then check compatibility
        // This will also not stack items which have different traits, which is intended
        final ItemStack stack1Copy = stack1.copy(), stack2Copy = stack2.copy();
        final long date = Calendars.get().getTicks();

        FoodCapability.setCreationDate(stack1Copy, date);
        FoodCapability.setCreationDate(stack2Copy, date);
        HeatCapability.setTemperature(stack1Copy, 0);
        HeatCapability.setTemperature(stack2Copy, 0);

        return ItemStack.isSameItemSameComponents(stack1Copy, stack2Copy) && stack1Copy.getMaxStackSize() >= stack2Copy.getCount() + stack1Copy.getCount();
    }
```

`FoodCapability` javap（来源 jar）关键成员：`MANAGER`（`DataManager<FoodDefinition>`）、`CACHE`（`IndirectHashCollection<Item, FoodDefinition>`），以及 `get / has / getDefinition / applyTrait / removeTrait / hasTrait / isRotten / addTooltipInfo / setCreationDate / setCreatedNow / setTransientNonDecaying / setInvisibleNonDecaying / setNonDecaying / setRotten / updateFoodFromPrevious / updateFoodFromAllPrevious / markRecipeOutputsAsNonDecaying / mergeItemStacks / areStacksStackableExceptCreationDate / getRoundedCreationDate / roundCreationDate / getLifeTime`。

`FoodTraits.REGISTRY` 反查 holder（`FLHelpers.java` 第 133–144 行）：

```java
                FoodTraits.REGISTRY.getHolder(FLHelpers.res(excessNbt.getCompound(i).getString("trait"))).ifPresent(list::add);
```

`Lore`（javap 来源 jar，`net.dries007.tfc.common.Lore` —— **注意包名是 `common`，不是 `component`**）：

```java
public final class net.dries007.tfc.common.Lore {
  public static final DataComponentType<ItemLore> TYPE;
  public static final ItemLore SILICA, HEMATITIC, OLIVINE, VOLCANIC, UNSEALED, SEALED;
  public static final Map<RockDisplayCategory, ItemLore> ROCK_DISPLAY_CATEGORIES;
  public static final Map<RockCategory, ItemLore> ROCK_CATEGORIES;
  public static void append(ItemStack, MutableComponent);
}
```

`TFCComponents`（javap 来源 jar）：`public static final DeferredRegister<DataComponentType<?>> COMPONENTS` + 16 个 `Id` 组件（FORGING、FORGING_BONUS、GLASS、HEAT、FOOD、BOWL、INGREDIENTS、DEPOSIT、BAIT、PLANT、EGG、FLUID、VESSEL、CONTENTS、BARREL、CRUCIBLE）+ `onModifyDefaultComponents(ModifyDefaultComponentsEvent)`。Firmalife 直接使用其中若干（`CopyDynamicFoodModifier` 读写 `TFCComponents.BOWL`；`FilledWineBottleItem` 用 `TFCComponents.FLUID`）。

### 1.6 配方接口体系

#### 1.6.1 接口与基类（javap -p，来源 jar）

```java
public interface net.dries007.tfc.common.recipes.ISimpleRecipe<C extends net.minecraft.world.item.crafting.RecipeInput> extends net.minecraft.world.item.crafting.Recipe<C> {
  public default boolean canCraftInDimensions(int, int);
  public default boolean isSpecial();
  public default net.minecraft.world.item.ItemStack getResultItem(net.minecraft.core.HolderLookup$Provider);
}
public interface net.dries007.tfc.common.recipes.IRecipePredicate<C> {
  public abstract boolean matches(C);
}
public interface net.dries007.tfc.common.recipes.INoopInputRecipe extends net.dries007.tfc.common.recipes.ISimpleRecipe<net.dries007.tfc.common.recipes.input.NoopInput> {
  public default boolean matches(net.dries007.tfc.common.recipes.input.NoopInput, net.minecraft.world.level.Level);
  public default net.minecraft.world.item.ItemStack assemble(net.dries007.tfc.common.recipes.input.NoopInput, net.minecraft.core.HolderLookup$Provider);
  public default net.minecraft.core.NonNullList<net.minecraft.world.item.ItemStack> getRemainingItems(net.dries007.tfc.common.recipes.input.NoopInput);
  public default net.minecraft.core.NonNullList getRemainingItems(net.minecraft.world.item.crafting.RecipeInput);
  public default net.minecraft.world.item.ItemStack assemble(net.minecraft.world.item.crafting.RecipeInput, net.minecraft.core.HolderLookup$Provider);
  public default boolean matches(net.minecraft.world.item.crafting.RecipeInput, net.minecraft.world.level.Level);
}
public abstract class net.dries007.tfc.common.recipes.ItemRecipe implements net.dries007.tfc.common.recipes.INoopInputRecipe, net.dries007.tfc.common.recipes.IRecipePredicate<net.minecraft.world.item.ItemStack> {
  protected final net.minecraft.world.item.crafting.Ingredient ingredient;
  protected final net.dries007.tfc.common.recipes.outputs.ItemStackProvider result;
  protected net.dries007.tfc.common.recipes.ItemRecipe(net.minecraft.world.item.crafting.Ingredient, net.dries007.tfc.common.recipes.outputs.ItemStackProvider);
  public boolean matches(net.minecraft.world.item.ItemStack);
  public net.minecraft.world.item.ItemStack assemble(net.minecraft.world.item.ItemStack);
  public net.minecraft.world.item.ItemStack getResultItem(net.minecraft.core.HolderLookup$Provider);
  public java.util.Collection<net.minecraft.world.item.Item> getValidItems();
  public final net.minecraft.world.item.crafting.Ingredient getIngredient();
  public final net.dries007.tfc.common.recipes.outputs.ItemStackProvider getResult();
  public boolean isSpecial();
}
public abstract class net.dries007.tfc.common.recipes.BlockRecipe implements net.dries007.tfc.common.recipes.INoopInputRecipe, net.dries007.tfc.common.recipes.IRecipePredicate<net.minecraft.world.level.block.state.BlockState> {
  protected final net.dries007.tfc.common.recipes.ingredients.BlockIngredient ingredient;
  protected final java.util.Optional<net.minecraft.world.level.block.state.BlockState> output;
  public static <R extends BlockRecipe> RecipeSerializer<R> serializer(BiFunction<BlockIngredient, Optional<BlockState>, R>);
  public static <R extends BlockRecipe> MapCodec<R> codec(BiFunction<BlockIngredient, Optional<BlockState>, R>);
  public static <R extends BlockRecipe> StreamCodec<RegistryFriendlyByteBuf, R> streamCodec(BiFunction<BlockIngredient, Optional<BlockState>, R>);
  protected net.dries007.tfc.common.recipes.BlockRecipe(BlockIngredient, Optional<BlockState>);
  public boolean matches(net.minecraft.world.level.block.state.BlockState);
  public net.minecraft.world.item.ItemStack getResultItem(HolderLookup$Provider);
  public net.minecraft.world.level.block.state.BlockState assembleBlock(BlockState);
  public net.dries007.tfc.common.recipes.ingredients.BlockIngredient getBlockIngredient();
}
public final class net.dries007.tfc.common.recipes.RecipeSerializerImpl<R extends Recipe<?>> extends java.lang.Record implements net.minecraft.world.item.crafting.RecipeSerializer<R> {
  public net.dries007.tfc.common.recipes.RecipeSerializerImpl(R);
  public net.dries007.tfc.common.recipes.RecipeSerializerImpl(com.mojang.serialization.MapCodec<R>, net.minecraft.network.codec.StreamCodec<net.minecraft.network.RegistryFriendlyByteBuf, R>);
  public com.mojang.serialization.MapCodec<R> codec();
  public net.minecraft.network.codec.StreamCodec<net.minecraft.network.RegistryFriendlyByteBuf, R> streamCodec();
}
public interface net.dries007.tfc.common.recipes.input.NonEmptyInput extends net.minecraft.world.item.crafting.RecipeInput {
  public default net.minecraft.world.item.ItemStack getItem(int);
  public default int size();
  public default boolean isEmpty();
}
```

**关键更正**：

- `net.dries007.tfc.common.recipes.inventory.ItemStackInventory` **在 jar 中不存在**（全 jar 子串搜索 `ItemStackInventory` 命中 0）。`net/dries007/tfc/common/recipes/` 下只有 `ingredients/`、`input/`、`outputs/` 三个子包；`input/` 下有 `NonEmptyInput`、`NoopInput`、`BarrelInventory`。检查位置：`jar tf` + 子串匹配。
- `NonEmptyInput` 的**包名是 `...recipes.input`**，不是 `...recipes.inventory`。
- `Lore` 的包名是 `net.dries007.tfc.common.Lore`。

#### 1.6.2 `RecipeHelpers`（javap，来源 jar）

```java
public final class net.dries007.tfc.common.recipes.RecipeHelpers {
  public static Player getCraftingPlayer();
  public static void clearCraftingInput();
  public static void setCraftingInput(CraftingInput);
  public static void setCraftingInput(IItemHandler, int, int);
  public static Iterable<ItemStack> getCraftingInput();
  public static NonNullList<ItemStack> getRemainderItemsWithProvider(CraftingInput, ItemStackProvider, ItemStack);
  public static ItemStack getResultUnsafe(CraftingRecipe);
  public static Collection<Item> itemKeys(Ingredient);
  public static Stream<Item> stream(Ingredient);
  public static Collection<Fluid> fluidKeys(FluidIngredient);
  public static Stream<Fluid> stream(SizedFluidIngredient);
  public static Stream<Fluid> stream(FluidIngredient);
  public static <R extends Recipe<?>> R unbox(RecipeHolder<R>);
  public static <R extends IRecipePredicate<C>, C, K> R getRecipe(IndirectHashCollection<K, R>, C, K);
  public static <R extends IRecipePredicate<C>, C> R getRecipe(Collection<R>, C);
  public static <R, C> R getRecipe(Collection<R>, C, BiPredicate<R, C>);
  public static <R extends Recipe<?> & IRecipePredicate<C>, C> RecipeHolder<R> getHolder(Level, Supplier<RecipeType<R>>, C);
  public static <R extends Recipe<?> & IRecipePredicate<C>, C> RecipeHolder<R> getHolder(RecipeManager, Supplier<RecipeType<R>>, C);
  public static <R extends Recipe<?>> Collection<RecipeHolder<R>> getRecipes(Level, Supplier<RecipeType<R>>);
  public static <R extends Recipe<?>> Collection<RecipeHolder<R>> getRecipes(RecipeManager, Supplier<RecipeType<R>>);
  public static int dissolveRowColumn(int, int, int);
  public static int translateMatch(ShapedRecipe, int, CraftingInput);
  public static int translateMatch(NonNullList<Ingredient>, CraftingInput, int, int, int);
}
```

Firmalife 的用法（`src/main/java/com/eerussianguy/firmalife/common/recipes/DryingRecipe.java` 第 40–44 行）：

```java
    @Nullable
    public static DryingRecipe getRecipe(ItemStack input)
    {
        return RecipeHelpers.getRecipe(CACHE, input, input.getItem());
    }
```

#### 1.6.3 `PotOutput` 与 `PotOutput.OutputType`（javap，来源 jar）

```java
public interface net.dries007.tfc.common.recipes.outputs.PotOutput {
  public static final ResourceKey<Registry<PotOutput$OutputType>> KEY;
  public static final ResourceKey<PotOutput$OutputType> DEFAULT;
  public static final DefaultedRegistry<PotOutput$OutputType> REGISTRY;
  public static final DeferredRegister<PotOutput$OutputType> TYPES;
  public static final PotOutput EMPTY_INSTANCE;
  public static final DeferredHolder<PotOutput$OutputType, PotOutput$OutputType> EMPTY, SOUP, JAM;
  public static PotOutput read(HolderLookup$Provider, CompoundTag);
  public static CompoundTag write(HolderLookup$Provider, PotOutput);
  public default boolean isEmpty();
  public default int getFluidColor();
  public default ResourceLocation getRenderTexture();
  public default float getFluidYLevel();
  public default void onFinish(IPotInventory);
  public default ItemInteractionResult onInteract(IPotInventory, Player, ItemStack);
  public default PotOutput$OutputType getType();
  public default void write(HolderLookup$Provider, CompoundTag);
  public default BlockEntityTooltip getTooltip();
}
public interface net.dries007.tfc.common.recipes.outputs.PotOutput$OutputType {
  public abstract net.dries007.tfc.common.recipes.outputs.PotOutput read(net.minecraft.core.HolderLookup$Provider, net.minecraft.nbt.CompoundTag);
}
```

**`PotOutput.KEY` 的正确含义**：它是「注册表本身」的 `ResourceKey<Registry<OutputType>>`（不是某个元素的 key），配合 `REGISTRY`（`DefaultedRegistry<OutputType>`）与 `DEFAULT` 使用。**第三方注册方式**：`DeferredRegister.create(PotOutput.KEY, "yourmod")`，正如 Firmalife 所做（1.1.7 ②）。注意 `PotOutput.register(...)` 是 `private static`，不能调用。

Firmalife 的实现形态（`OutputType` 是函数式接口，实现放在 recipe 类里作为嵌套 record）：

```java
    public static final PotOutput.OutputType OUTPUT_TYPE = (provider, nbt) -> {
        ItemStack stack = ItemStack.parseOptional(provider, nbt.getCompound("item"));
        return new StinkOutput(stack);
    };
```

#### 1.6.4 `ItemStackModifier` 与 `ItemStackModifiers`

```java
public interface net.dries007.tfc.common.recipes.outputs.ItemStackModifier {
  public static final Codec<ItemStackModifier> CODEC;
  public static final StreamCodec<RegistryFriendlyByteBuf, ItemStackModifier> STREAM_CODEC;
  public abstract ItemStack apply(ItemStack, ItemStack, ItemStackModifier$Context);
  public default boolean dependsOnInput();
  public abstract ItemStackModifierType<?> type();
}
public final class net.dries007.tfc.common.recipes.outputs.ItemStackModifier$Context extends Enum { DEFAULT, NO_RANDOM_CHANCE }
public class net.dries007.tfc.common.recipes.outputs.ItemStackModifiers {
  public static final ResourceKey<Registry<ItemStackModifierType<?>>> KEY;
  public static final Registry<ItemStackModifierType<?>> REGISTRY;
  public static final DeferredRegister<ItemStackModifierType<?>> TYPES;
  // 22 个 Id 常量：COPY_INPUT, COPY_FOOD, COPY_OLDEST_FOOD, COPY_HEAT, COPY_FORGING_BONUS, RESET_FOOD,
  //   EMPTY_BOWL, FLOWER_CUTTING, ADD_BAIT_TO_ROD, ADD_GLASS, ADD_POWDER, CRAFTING_REMAINDER,
  //   DAMAGE_CRAFTING_REMAINDER, ADD_TRAIT, REMOVE_TRAIT, ROUND_CREATION_DATE, ADD_HEAT, DYE_LEATHER,
  //   REMOVE_DYE, MEAL, EXTRA_PRODUCT, CHANCE
}
```

（`ItemStackModifiers.register(...)` 两个重载均为 `private static`。）

Firmalife 的注册方式（`src/main/java/com/eerussianguy/firmalife/common/recipes/data/FLItemStackModifiers.java` 全文关键行）：

```java
    public static final DeferredRegister<ItemStackModifierType<?>> TYPES = DeferredRegister.create(ItemStackModifiers.KEY, FirmaLife.MOD_ID);

    public static final Id<AddPiePanModifier> ADD_PIE_PAN = register("add_pie_pan", AddPiePanModifier.INSTANCE);
    public static final Id<CopyDynamicFoodModifier> COPY_DYNAMIC_FOOD =register("copy_dynamic_food", CopyDynamicFoodModifier.INSTANCE);
    public static final Id<CopyBowlModifier> COPY_BOWL = register("copy_bowl", CopyBowlModifier.INSTANCE);
    public static final Id<EmptyPanModifier> EMPTY_PAN = register("empty_pan", EmptyPanModifier.INSTANCE);

    // Copied from TFC
    private static <T extends ItemStackModifier> FLItemStackModifiers.Id<T> register(String name, T singleInstance)
    {
        return new FLItemStackModifiers.Id<>(TYPES.register(name, () -> new ItemStackModifierType<>(MapCodec.unit(singleInstance), StreamCodec.unit(singleInstance))));
    }
```

四个 modifier 均为 `public enum X implements ItemStackModifier { INSTANCE; ... }` 单例；只有 `EmptyPanModifier` 覆写 `dependsOnInput()` 返回 `true`。

### 1.7 `DataManager` / `DataManagers` 扩展机制

javap（来源 jar）：

```java
public class net.dries007.tfc.util.data.DataManager<T> extends net.minecraft.server.packs.resources.SimpleJsonResourceReloadListener {
  public net.dries007.tfc.util.data.DataManager(net.minecraft.resources.ResourceLocation, com.mojang.serialization.Codec<T>);
  public net.dries007.tfc.util.data.DataManager(net.minecraft.resources.ResourceLocation, com.mojang.serialization.Codec<T>, net.minecraft.network.codec.StreamCodec<net.minecraft.network.RegistryFriendlyByteBuf, T>);
  public T get(ResourceLocation);
  public ResourceLocation getId(T);
  public T getOrThrow(ResourceLocation);
  public ResourceLocation getIdOrThrow(T);
  public net.dries007.tfc.util.data.DataManager$Reference<T> getReference(ResourceLocation);
  public net.dries007.tfc.util.data.DataManager$Reference<T> getCheckedReference(ResourceLocation);
  public Map<ResourceLocation, T> getElements();
  public Collection<T> getValues();
  public boolean isSynced();
  public final Codec<DataManager$Reference<T>> byIdReferenceCodec();
  public final StreamCodec<io.netty.buffer.ByteBuf, DataManager$Reference<T>> byIdStreamCodec();
  public final Codec<T> codec();
  public final StreamCodec<RegistryFriendlyByteBuf, T> streamCodec();
  public void bindValues(Map<ResourceLocation, T>);
  public final String getName();
}
public class net.dries007.tfc.util.data.DataManager$Reference<T> implements java.util.function.Supplier<T> {
  public ResourceLocation id();
  public T get();
  public void set(T);
}
public final class net.dries007.tfc.util.data.DataManagers {
  public static final ResourceKey<Registry<DataManager<?>>> KEY;
  public static final Registry<DataManager<?>> REGISTRY;
  public static final DeferredRegister<DataManager<?>> MANAGERS;
}
```

**回答任务中的三个具体问题**：

1. **`DataManager` 的构造签名**：`DataManager(ResourceLocation, Codec<T>)` 与 `DataManager(ResourceLocation, Codec<T>, StreamCodec<RegistryFriendlyByteBuf, T>)`。第一个参数是 **`ResourceLocation`（数据目录名）**，不是 `ResourceKey`。它是 `class` 而非 interface，`extends SimpleJsonResourceReloadListener`。
2. **`DataManagers.MANAGERS` 是 `DeferredRegister`**：是，且为 `DeferredRegister<DataManager<?>>`，注册目标是 TFC 自建的 `Registry<DataManager<?>>`（`KEY`/`REGISTRY`）。Firmalife 的注册代码见 1.1.8；**`DataManagers.register(...)` 是 `private static`，第三方需自行向 `MANAGERS` 注册**（Firmalife 就是这么做的）。
3. **`ClimateRange.MANAGER.getReference(...)` 用法**：Firmalife 通过 `DataManager.Reference` 做「延迟绑定引用」，例如 `src/main/java/com/eerussianguy/firmalife/common/util/FLClimateRanges.java`：

```java
    public static final Map<FLFruitBlocks.Tree, DataManager.Reference<ClimateRange>> FRUIT_TREES = Helpers.mapOf(FLFruitBlocks.Tree.class, tree -> register("plant/" + tree.name() + "_tree"));
    public static final Map<FLFruitBlocks.StationaryBush, DataManager.Reference<ClimateRange>> STATIONARY_BUSHES = Helpers.mapOf(FLFruitBlocks.StationaryBush.class, bush -> register("plant/" + bush.name() + "_bush"));
```

（`register` 私有方法体内调用对应 manager 的 `getReference(...)` —— 该文件具体实现行未逐行读取，标注**部分未核实**；但 `DataManager.Reference` 作为字段类型的使用方式是原文。）

`ClimateRange` javap（来源 jar，`net.dries007.tfc.util.climate.ClimateRange`）：record，字段 `minHydration/maxHydration/hydrationWiggleRange/minTemperature/maxTemperature/temperatureWiggleRange`；`public static final Codec CODEC`、`StreamCodec STREAM_CODEC`、`DataManager<ClimateRange> MANAGER`、`ClimateRange NOOP`；方法 `getMinHydration(boolean)`、`getMaxHydration(boolean)`、`getMinTemperature(boolean)`、`getMaxTemperature(boolean)`、`checkHydration(int, boolean)`、`checkTemperature(float, boolean)`、`checkBoth(int, float, boolean)`；嵌套 `Result { LOW, VALID, HIGH }` 与 `Builder`。

Firmalife 自己的两个 DataManager 定义（`common/util/GreenhouseType.java`、`common/util/Plantable.java`）：

```java
    public static final DataManager<GreenhouseType> MANAGER = new DataManager<>(FLHelpers.identifier("greenhouse"), CODEC, STREAM_CODEC);
    public static final IndirectHashCollection<Block, GreenhouseType> CACHE = IndirectHashCollection.create(s -> s.ingredient.blocks(), MANAGER::getValues);
```
```java
    public static final DataManager<Plantable> MANAGER = new DataManager<>(FLHelpers.identifier("plantable"), CODEC, STREAM_CODEC);
    public static final IndirectHashCollection<Item, Plantable> CACHE = IndirectHashCollection.create(c -> RecipeHelpers.itemKeys(c.ingredient), MANAGER::getValues);
```

数据文件落在 `data/firmalife/firmalife/plantable/*.json`、`data/firmalife/firmalife/greenhouse/*.json`（jar 内实际路径；datagen 由 `DataManagerProvider` 按 `<domain>/<managerName>` 输出，见第 2.3 节）。

### 1.8 其它 TFC 工具类（每类一处真实用法 + javap）

#### `BlockIngredient`（`common/util/GreenhouseType.java`）

```java
public record GreenhouseType(BlockIngredient ingredient, int tier, Component translationKey)
{
    public static final Codec<GreenhouseType> CODEC = RecordCodecBuilder.create(instance -> instance.group(
        BlockIngredient.CODEC.fieldOf("ingredient").forGetter(c -> c.ingredient),
        Codecs.POSITIVE_INT.fieldOf("tier").forGetter(c -> c.tier),
        ComponentSerialization.CODEC.fieldOf("translation_key").forGetter(c -> c.translationKey)
    ).apply(instance, GreenhouseType::new);
```

javap（来源 jar）：`public final class BlockIngredient extends Record implements Predicate<Block>`，静态 `CODEC`/`STREAM_CODEC`，工厂 `of(TagKey<Block>)`、`of(Block...)`、`of(Stream<Block>)`，方法 `test(BlockState)`、`test(Block)`、`all()`、`blocks()`。

#### `IndirectHashCollection`（`common/recipes/DryingRecipe.java` 第 33 行）

```java
    public static final IndirectHashCollection<Item, DryingRecipe> CACHE = IndirectHashCollection.createForRecipe(DryingRecipe::getValidItems, FLRecipeTypes.DRYING);
```

javap（来源 jar）：`create(Function<R, Iterable<? extends K>>, Supplier<Collection<R>>)`、`createForRecipe(Function<R, Iterable<? extends K>>, Supplier<RecipeType<R>>)`、`createForRecipeId(Supplier<RecipeType<R>>)`（返回 `BiMap<ResourceLocation, R>`）、`create(T cache)`、`static reloadAllCaches(RecipeManager)`、`static clearAllCaches()`、`getAll(K)`、`reload(Collection<R>)`、`clear()`。

#### `net.dries007.tfc.world.Codecs`（`common/util/GreenhouseType.java`、`Plantable.java`）

```java
        Codecs.POSITIVE_INT.optionalFieldOf("tier", 0).forGetter(c -> c.tier),
        Codecs.POSITIVE_INT.optionalFieldOf("stages", 0).forGetter(c -> c.stages),
        Codecs.POSITIVE_FLOAT.optionalFieldOf("extra_seed_chance", 0.5f).forGetter(c -> c.extraSeedChance),
```

javap（来源 jar）：`public final class Codecs extends ExtraCodecs`；静态字段 `UNIT_FLOAT`、`BLOCK`、`FLUID`、`BLOCK_STATE`、`BLOCK_TO_WEIGHTED_BLOCKSTATE`、`BLOCK_STATE_CONFIG`；静态方法 `nonDefaultedRegistryCodec`、`recordPairCodec`、`weightedCodec`、`mapKeyListCodec`、`mapListCodec`、`orderPreservingUnboundedMapCodec`。

#### `Helpers.mapOf`（javap，来源 jar `net.dries007.tfc.util.Helpers`）

```java
  public static <E extends java.lang.Enum<E>, V> java.util.Map<E, V> mapOf(java.lang.Class<E>, java.util.function.Function<E, V>);
  public static <E extends java.lang.Enum<E>, V> java.util.Map<E, V> mapOf(java.lang.Class<E>, java.util.function.Predicate<E>, java.util.function.Function<E, V>);
```

Firmalife 用得非常广（40+ 处，见 1.1.1 与 `FLItems.FINISHES`）：

```java
    public static final Map<OvenType, ItemId> FINISHES = Helpers.mapOf(OvenType.class, type -> type != OvenType.BRICK, type -> register(type.getSerializedName() + "_finish", () -> new FinishItem(prop(), type)));
```

#### `ExtendedProperties` / `ExtendedBlock`

`src/main/java/com/eerussianguy/firmalife/common/blocks/FLBlocks.java` 第 292–315 行（作为集中式属性工厂）：

```java
    public static ExtendedProperties shelfProperties()
    {
        return ExtendedProperties.of().strength(0.3F).sound(SoundType.WOOD).noOcclusion().blockEntity(FLBlockEntities.FOOD_SHELF);
    }

    public static ExtendedProperties jarbnetProperties()
    {
        return ExtendedProperties.of().strength(0.3F).sound(SoundType.WOOD).noOcclusion().randomTicks().lightLevel(s -> s.getValue(JarbnetBlock.LIT) ? 11 : 0).blockEntity(FLBlockEntities.JARBNET);
    }
```

```java
    public static final Id<Block> TREATED_WOOD = register("treated_wood", () -> new ExtendedBlock(ExtendedProperties.of().mapColor(MapColor.COLOR_BROWN).sound(SoundType.WOOL).strength(2f).flammableLikePlanks()));
```

javap（来源 jar）：`ExtendedProperties` 是**非 final 的 public class**，构造器 private，必须经 `of(...)` 起链；扩展方法包含 `blockEntity(Supplier<BlockEntityType<?>>)`、`ticks/serverTicks/clientTicks(BlockEntityTicker<T>)`、`flammable(int,int)`、`flammableLikeLogs/Planks/Leaves/Wool()`、`pathType(PathType)`、`enchantPower(...)`、`cloneEmpty()`、`cloneItem(ItemLike)`、`dropsLike(...)`、`isValidSpawn(...)` 等，且转发返回 `this`。`ExtendedBlock` 是 `public class ExtendedBlock extends Block implements IForgeBlockExtension`，构造 `ExtendedBlock(ExtendedProperties)`，方法 `getExtendedProperties()`。

#### `GroundcoverBlock` / `WildCropBlock` / `PlantBlock` / `PouredGlassBlock` / `JackOLanternBlock`

```java
    public static final Id<Block> HOLLOW_SHELL = registerNoItem("hollow_shell", () -> new GroundcoverBlock(ExtendedProperties.of().strength(0.05F, 0.0F).sound(SoundType.NETHER_WART).noCollission(), GroundcoverBlock.SMALL));
```
```java
    public static final Id<Block> WILD_WHITE_GRAPES = register("plant/wild_white_grapes", () -> new WildCropBlock(ExtendedProperties.of(MapColor.PLANT).noCollission().randomTicks().strength(0.4F).sound(SoundType.CROP).flammable(60, 30).randomTicks()));
```
```java
    public static final Map<Herb, Id<Block>> HERBS = Helpers.mapOf(Herb.class, herb -> register("plant/" + herb.name(), () -> PlantBlock.create(FLPlant.HERB, FLPlant.HERB.nonSolidFire())));
```
```java
    public static final Id<Block> REINFORCED_POURED_GLASS = register("reinforced_poured_glass", () -> new PouredGlassBlock(ExtendedProperties.of().strength(0.3F).sound(SoundType.GLASS).pushReaction(PushReaction.DESTROY).noOcclusion().requiresCorrectToolForDrops(), FLItems.REINFORCED_GLASS));
```
```java
    public static final Map<Carving, Id<Block>> JACK_O_LANTERNS = Helpers.mapOf(Carving.class, carve ->
        register("lit_pumpkin/" + carve.getSerializedName(), () -> new JackOLanternBlock(ExtendedProperties.of(Properties.of().mapColor(MapColor.COLOR_ORANGE).strength(1.0F).sound(SoundType.WOOD).randomTicks().isValidSpawn(FLBlocks::always).lightLevel(alwaysLit())).blockEntity(FLBlockEntities.TICK_COUNTER), CARVED_PUMPKINS.get(carve)))
    );
```

javap（来源 jar）关键签名：

```java
public class net.dries007.tfc.common.blocks.GroundcoverBlock extends ExtendedBlock implements IFluidLoggable {
  public static GroundcoverBlock twig(ExtendedProperties);
  public static GroundcoverBlock looseOre(BlockBehaviour$Properties);
  public GroundcoverBlock(GroundcoverBlockType);
  public GroundcoverBlock(ExtendedProperties, VoxelShape);
}
public class net.dries007.tfc.common.blocks.crop.WildCropBlock extends TFCBushBlock implements ISpecialPile {
  public static final BooleanProperty MATURE;
  public static boolean isMature(Level, BlockPos);
  public WildCropBlock(ExtendedProperties);
}
public abstract class net.dries007.tfc.common.blocks.plant.PlantBlock extends TFCBushBlock implements ISlowEntities {
  public static PlantBlock create(RegistryPlant, ExtendedProperties);
  public static PlantBlock createShrub(RegistryPlant, ExtendedProperties);
  public static PlantBlock createShortShrub(RegistryPlant, ExtendedProperties);
  public static PlantBlock createDry(RegistryPlant, ExtendedProperties);
  public static PlantBlock createPerchedEpiphyte(RegistryPlant, ExtendedProperties);
  public static PlantBlock createCactusFlower(RegistryPlant, ExtendedProperties);
  public static PlantBlock createFlowerbed(RegistryPlant, ExtendedProperties);
  public abstract net.dries007.tfc.util.registry.RegistryPlant getPlant();
}
public class net.dries007.tfc.common.blocks.PouredGlassBlock extends ExtendedBlock {
  public PouredGlassBlock(ExtendedProperties, Supplier<? extends Item>);
  public static Item getStainedGlass(DyeColor);
}
public class net.dries007.tfc.common.blocks.devices.JackOLanternBlock extends CarvedPumpkinBlock implements EntityBlockExtension, IForgeBlockExtension {
  public JackOLanternBlock(ExtendedProperties, Supplier<? extends Block>);
  public void extinguish(Level, BlockPos, BlockState);
}
```

**注意**：`WildCropBlock` 的包名是 `net.dries007.tfc.common.blocks.crop`（不是 `...blocks.plant`）；`JackOLanternBlock` 在 `...blocks.devices`。

#### `Env`：**未使用，且 jar 中无此类**

Firmalife 中不存在 `net.dries007.tfc.util.Env`。实际使用的是 `net.dries007.tfc.util.EnvironmentHelpers`：

```java
// src/main/java/com/eerussianguy/firmalife/common/worldgen/FLFruitTreeFeature.java
import net.dries007.tfc.util.EnvironmentHelpers;
...
                if (!EnvironmentHelpers.isWorldgenReplaceable(level, mutablePos))
```

javap（来源 jar）：

```java
public final class net.dries007.tfc.util.EnvironmentHelpers {
  public static float adjustAvgTempForElev(int, float);
  public static float adjustAvgTempForElev(int, float, float);
  public static boolean isAdjacentToNotWater(LevelAccessor, BlockPos);
  public static boolean isWaterAt(LevelAccessor, BlockPos);
  public static boolean isWorldgenReplaceable(WorldGenLevel, BlockPos);
  public static boolean isWorldgenReplaceable(BlockState);
  public static boolean canPlaceBushOn(WorldGenLevel, BlockPos);
  public static boolean isOnSturdyFace(WorldGenLevel, BlockPos);
}
```

`jar tf` 中类名含 `Env` 的顶层类只有 `EnvironmentHelpers` 一个（检查位置：`jar tf | Where-Object { $_ -match "Env" }`）。

#### `Helpers` 的常用成员

Firmalife 用到的（各 1 处真实片段）：`isBlock`（`common/util/Mechanics.java` 第 210 行 `state -> Helpers.isBlock(state, FLTags.Blocks.CELLAR_INSULATION)`）、`isItem`、`copyProperty`、`iterate`、`playSound`、`playPlaceSound`、`getCapability`、`removeStack`、`computeHorizontalShapes`、`identifier`、`translateEnum`、`uniform`、`gatherAndConsumeItems`、`DIRECTIONS`、`fireSpreaderTick`（`common/blockentities/OvenLike.java` 第 28 行）。

**`Helpers.getRandom` / `Helpers.getRandomElement` 在 Firmalife 中不存在**（grep 0 命中）；Firmalife 用自有的 `FLHelpers.getRandomElement`、`level.getRandom()`、`Helpers.uniform`。

javap 中 `Helpers` 的 `public static` 方法共 130+ 个（`public final class net.dries007.tfc.util.Helpers`），与上述相关的重要几个：

```java
  public static ResourceLocation identifier(String);
  public static ResourceLocation resourceLocation(String);
  public static ResourceLocation resourceLocation(String, String);
  public static <T, C> T getCapability(BlockCapability<T, C>, BlockEntity);
  public static <T, C> T getCapability(BlockCapability<T, C>, Level, BlockPos);
  public static <T, C> T getCapability(BlockCapability<T, C>, BlockEntity, C);
  public static BlockState copyProperty(BlockState, BlockState, Property<T>);
  public static Iterable<ItemStack> iterate(IItemHandler);
  public static ItemStack removeStack(IItemHandler, int);
  public static VoxelShape[] computeHorizontalShapes(Function<Direction, VoxelShape>);
  public static boolean isBlock(BlockState, TagKey<Block>);
  public static boolean isItem(ItemStack, ItemLike);
  public static float uniform(RandomSource, float, float);
  public static void gatherAndConsumeItems(Level, AABB, IItemHandler, int, int);
  public static void fireSpreaderTick(ServerLevel, BlockPos, RandomSource, int);
```

### 1.9 `FLHelpers`（`src/main/java/com/eerussianguy/firmalife/common/FLHelpers.java`，共 501 行）

`public class FLHelpers`（**非 final、非 abstract**）。内含两个 public static 字段与 40 个 public 方法。

**public static 字段**：

| 字段 | 说明 |
|---|---|
| `public static final boolean ASSERTIONS_ENABLED` | 用 `assert enabled = true;` 探测 JVM 是否开启断言（第 77 行，实现见第 495 行 `detectAssertionsEnabled()`） |
| `public static final Codec<KoppenClimateClassification> KOPPEN_CODEC` | TFC 柯本气候分类枚举的 JSON Codec（复用 TFC 的 `StringRepresentable.fromEnum`） |
| `public static final StreamCodec<ByteBuf, KoppenClimateClassification> KOPPEN_STREAM_CODEC` | 同上枚举的网络 Codec（复用 TFC 的 `net.dries007.tfc.network.StreamCodecs.forEnum`） |

**public 方法完整签名与用途**（签名逐字来自源码）：

| # | 签名 | 用途 |
|---|---|---|
| 1 | `public static ResourceLocation identifier(String id)` | 用 `MOD_ID` 前缀构造 ResourceLocation |
| 2 | `public static FluidStack getFluidInTank(BlockEntity blockEntity)` | 经 TFC `Helpers.getCapability` 取方块第 0 号罐内流体，无能力返回 `FluidStack.EMPTY` |
| 3 | `public static void resetCounter(Level level, BlockPos pos)` | 若该处是 TFC `TickCounterBlockEntity` 则重置其计数器（**直接依赖 TFC 类**） |
| 4 | `public static BlockState copyProperties(BlockState copyTo, BlockState copyFrom, Property<?>... properties)` | 批量复制多个方块属性（TFC `Helpers.copyProperty` 的多属性封装） |
| 5 | `public static <T> Optional<T> getRandomElement(Registry<T> registry, TagKey<T> tag, RandomSource random)` | 从标签集合随机取一个注册表元素 |
| 6 | `public static void writeTraitList(List<Holder<FoodTrait>> list, CompoundTag nbt, String key)` | 食物特性列表 → NBT |
| 7 | `public static void readTraitList(List<Holder<FoodTrait>> list, CompoundTag nbt, String key)` | NBT → 食物特性列表（经 `FoodTraits.REGISTRY.getHolder`） |
| 8 | `public static void writeItemStackList(List<ItemStack> list, CompoundTag nbt, String key, HolderLookup.Provider access)` | ItemStack 列表 → NBT |
| 9 | `public static void readItemStackList(List<ItemStack> list, CompoundTag nbt, String key, HolderLookup.Provider access)` | NBT → ItemStack 列表 |
| 10 | `public static Component blockEntityName(String name)` | 生成 `firmalife.block_entity.<name>` 翻译键 |
| 11 | `public static <T extends BlockEntity> void readInventory(Level level, BlockPos pos, Supplier<BlockEntityType<T>> type, BiConsumer<T, IItemHandler> consumer)` | 查方块实体 + 取物品能力后回调 |
| 12 | `public static <T extends BlockEntity> InteractionResult consumeInventory(Level level, BlockPos pos, Supplier<BlockEntityType<T>> type, BiFunction<T, IItemHandler, InteractionResult> consumer)` | 同上但返回 `InteractionResult`（缺省 `PASS`） |
| 13 | `public static <T extends InventoryBlockEntity<?>> ItemInteractionResult consumeItemInventory(Level level, BlockPos pos, Supplier<BlockEntityType<T>> type, BiFunction<T, IItemHandler, ItemInteractionResult> consumer)` | 用 TFC `InventoryBlockEntity.getInventory()` 的版本 |
| 14 | `public static ItemInteractionResult swapOne(Level level, ItemStack item, int slot, IItemHandler inv, Player player)` | 手中物品与槽位物品一对一交换（含防复制处理） |
| 15 | `public static BlockPos getPoint(Level level, BlockPos origin, int radius, Holder<PoiType> type)` | 半径内查 POI（仅服务端，找不到返回 null） |
| 16 | `public static BlockPos getPoint(Level level, BlockPos origin, int radius, Holder<PoiType> type, BiPredicate<Level, BlockPos> predicate)` | 同上，带位置过滤谓词 |
| 17 | `public static ItemInteractionResult insertOne(Level level, ItemStack item, int slot, IItemHandler inv, Player player)` | 向指定槽插入 1 个物品 |
| 18 | `public static ItemInteractionResult takeOne(Level level, int slot, IItemHandler inv, Player player)` | 从指定槽取出 1 个物品给玩家 |
| 19 | `public static ItemInteractionResult insertOneAny(Level level, ItemStack item, int start, int end, IItemHandler inv, Player player)` | 区间内第一个空槽插入 1 个 |
| 20 | `public static ItemStack mergeInsertStack(IItemHandler inventory, int slot, ItemStack stack)` | 用 TFC `FoodCapability.mergeItemStacks` 合并后插回，返回剩余 |
| 21 | `public static void spawnParticlesOnBlockFaces(Level level, BlockPos pos, ParticleOptions particle, IntProvider count)` | 客户端在方块各面生成粒子 |
| 22 | `public static void spawnParticlesInBlock(Level level, BlockPos pos, int count, ParticleOptions particle)` | 客户端在方块内生成粒子 |
| 23 | `public static int getRedstoneSignalFromContainer(Level level, BlockPos pos)` | 由 TFC `InventoryBlockEntity` 算红石信号 |
| 24 | `public static int getRedstoneSignalFromContainer(IItemHandler inv)` | 按「数量/槽上限」平均装载率映射 0–15 |
| 25 | `public static boolean stackableExceptHeatAndFood(ItemStack stack1, ItemStack stack2)` | 忽略食物创建日期与温度判断是否可堆叠 |
| 26 | `public static <T extends Comparable<T>> boolean hasPropertyAndValue(BlockState state, Property<T> property, T value)` | 安全判断属性存在且取值相等 |
| 27 | `public static NonNullList<ItemStack> extractAllItems(IItemHandlerModifiable inventory)` | 抽空并复制全部槽位（源码注释注明「Copied from TFC 1.20.x」） |
| 28 | `public static void insertAllItems(IItemHandlerModifiable inventory, NonNullList<ItemStack> from)` | 写回列表内容（允许长度不同） |
| 29 | `public static ItemInteractionResult takeOneAny(Level level, int start, int end, IItemHandler inv, Player player)` | 区间内第一个非空槽取 1 个 |
| 30 | `public static ResourceLocation res(String string)` | `ResourceLocation.parse` 简写 |
| 31 | `public static ResourceLocation res(String namespace, String path)` | 分别指定命名空间与路径 |
| 32 | `public static Iterable<BlockPos> allPositionsCentered(BlockPos center, int radius, int height)` | 以中心点的立方范围全部坐标（`BlockPos.betweenClosed`，惰性） |
| 33 | `public static MutableComponent translateEnum(Enum<?> anEnum)` | 枚举 → 翻译组件 |
| 34 | `public static String getEnumTranslationKey(Enum<?> anEnum)` | 生成枚举翻译键（如 `firmalife.enum.Metal.unknown`） |
| 35 | `public static String getEnumTranslationKey(Enum<?> anEnum, String enumName)` | 同上，可自定义枚举名 |
| 36 | `public static void roundCreationDate(ItemStack stack)` | 食物创建日期取整，便于堆叠 |
| 37 | `public static <T> void fakeDataManager(DataManager<T> manager, Map<String, T> values)` | **datagen 专用**：把硬编码条目灌进 TFC `DataManager` 并 `bindValues` |
| 38 | `public static boolean aabbContainsPoint(AABB shape, Vec3 pos)` | 含上边界的 AABB 包含判定 |
| 39 | `public static VoxelShape[][] computeHorizontalShapeGroup(List<Function<Direction, VoxelShape>> shapes)` | 批量把「方向→形状」函数转为二维数组 |
| 40 | `public static <B, C, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10> StreamCodec<B, C> composite(StreamCodec<? super B, T1> codec1, Function<C, T1> getter1, ... , Function10<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, C> function)` | **10 参数版 `StreamCodec.composite`**（原版最多 6 项；`Plantable` 有 10 个字段） |

**private 方法**：`private static ItemInteractionResult completeInsertion(Level, ItemStack, IItemHandler, Player, int)`（第 353 行）、`private static boolean detectAssertionsEnabled()`（第 495 行）。

### 1.10 mixin 三个与 `firmalife.mixins.json`

`src/main/resources/firmalife.mixins.json` **真实内容**（全文 11 行）：

```json
{
  "required": true,
  "minVersion": "0.8",
  "package": "com.eerussianguy.firmalife.mixin",
  "compatibilityLevel": "JAVA_17",
  "injectors": {
    "defaultRequire": 1
  },
  "mixins": ["BarrelRackMixin", "BeeMixin", "ServerConfigMixin"],
  "refmap": "firmalife.refmap.json"
}
```

在 `src/main/templates/META-INF/neoforge.mods.toml` 中声明：

```toml
[[mixins]]
    config = "${modId}.mixins.json"
```

（jar 内确实包含 `firmalife.mixins.json`，核实方式：`jar tf | Where-Object { $_ -match "mixins" }`。）

#### 1.10.1 `BarrelRackMixin`（`src/main/java/com/eerussianguy/firmalife/mixin/BarrelRackMixin.java` 全文）

- **目标类**：`net.dries007.tfc.common.blocks.devices.BarrelRackBlock`
- **注入点**：`canBeReplaced`，`at = HEAD`，`cancellable = true`

```java
@Mixin(BarrelRackBlock.class)
public class BarrelRackMixin
{
    @Inject(method = "canBeReplaced", at = @At("HEAD"), cancellable = true)
    private void inject$canBeReplaced(BlockState state, BlockPlaceContext context, CallbackInfoReturnable<Boolean> cir)
    {
        if (context.getItemInHand().getItem() instanceof BlockItem bi && bi.getBlock() instanceof CheeseWheelBlock)
        {
            cir.setReturnValue(true);
        }
    }
}
```

**作用**：让 TFC 的木质置物架允许被 Firmalife 的奶酪轮方块替换（否则放不上去）。

#### 1.10.2 `BeeMixin`（全文 40 行）

- **目标类**：`net.minecraft.world.entity.animal.Bee`（原版）
- **注入点**：`tick`，`at = TAIL`

```java
@Mixin(Bee.class)
public abstract class BeeMixin extends Animal implements NeutralMob, FlyingAnimal
{
    @Shadow
    abstract void setHasNectar(boolean pHasNectar);

    @Inject(method = "tick", at = @At("TAIL"))
    private void injectLosePollenSometimes(CallbackInfo ci)
    {
        if (((Bee) (Object) this) instanceof FLBee)
        {
            if (((Bee) (Object) this).tickCount % (600) == 0)
            {
                setHasNectar(false);
            }
        }
    }
}
```

**作用**：让 Firmalife 自己的蜜蜂实体 `FLBee` 每 600 tick 掉落花粉状态（`@Shadow` 访问原版私有方法 `setHasNectar`）。注意它 `extends Animal` 是为了满足 `Bee` 的类型约束（mixin 目标类的父类型）。

#### 1.10.3 `ServerConfigMixin`（全文 28 行）

- **目标类**：`net.dries007.tfc.config.ServerConfig`
- **注入点**：`<init>`，`at = TAIL`，`remap = false`

```java
@Mixin(ServerConfig.class)
public abstract class ServerConfigMixin
{
    @Shadow(remap = false)
    @Mutable
    @Final
    public Supplier<Boolean> enablePumpkinCarving;

    @Inject(method = "<init>", at = @At("TAIL"), remap = false)
    private void inject$init(ConfigBuilder builder, CallbackInfo ci)
    {
        enablePumpkinCarving = () -> false;
    }
}
```

**作用**：强制把 TFC 的 `enablePumpkinCarving` 配置项改成 `false` —— 因为 Firmalife 自己接管的南瓜雕刻系统（见 `FLForgeEvents.onFireStart` 与 `CARVED_PUMPKINS`/`JACK_O_LANTERNS`），必须关掉 TFC 的对应功能。

**注意**：`@Shadow @Mutable @Final` 三个注解组合用于改写 final 字段，且必须带 `remap = false`（TFC 的配置类在混淆表中不参与映射）。

### 1.11 Patchouli 集成与 `mods.toml` 的硬依赖

#### 1.11.1 硬依赖声明

`src/main/templates/META-INF/neoforge.mods.toml`：

```toml
[[dependencies.firmalife]]
    modId = "patchouli"
    type = "required"
    versionRange = "${patchouliVersionRange}"
    ordering = "NONE"
    side = "BOTH"
```

（`patchouliVersionRange` = `[1.21.1-92-NEOFORGE,)`，由 `build.gradle.kts` 第 35 行的替换变量生成。）

因此 Patchouli 是 **required 硬依赖**，代码可以无条件引用 `vazkii.patchouli.api.*`：`src/main/java/com/eerussianguy/firmalife/compat/patchouli/FLPatchouliIntegration.java` 直接 import 并使用 API。

#### 1.11.2 `FLPatchouliIntegration` 做什么

在 `FMLCommonSetupEvent` 之后调用（`FirmaLife.java` 第 100–108 行）：

```java
    public void setup(FMLCommonSetupEvent event)
    {
        // Vanilla registries are not thread safe
        event.enqueueWork(() -> {
            FLInteractionManager.init();
            FLBlocks.registerFlowerPotFlowers();
        });
        FLPatchouliIntegration.registerMultiBlocks();
    }
```

它用 Patchouli API 注册**多方块结构预览**（`api.makeMultiblock(new String[][], ...)`），把 Firmalife 温室与地窖的判据写成 Patchouli 的 `IStateMatcher`：

```java
    private static void registerMultiblock(String name, Function<PatchouliAPI.IPatchouliAPI, IMultiblock> factory)
    {
        final PatchouliAPI.IPatchouliAPI api = PatchouliAPI.get();
        api.registerMultiblock(FLHelpers.identifier(name), factory.apply(api));
    }
```

```java
            'X', api.predicateMatcher(FLBlocks.SEALED_BRICKS.get().defaultBlockState(), Mechanics.CELLAR),
```

（`Mechanics.CELLAR` 是 Firmalife 自己的判据谓词，见 `common/util/Mechanics.java` 第 210 行 —— 即「Patchouli 的结构预览」与「实际判定」共用同一个 `Helpers.isBlock(state, FLTags.Blocks.CELLAR_INSULATION)`。）

另有 `DryingComponent` / `SmokingComponent` 继承 TFC 的 Patchouli 页面组件（`net.dries007.tfc.compat.patchouli.component.SimpleItemRecipeComponent`）：

```java
public class DryingComponent extends SimpleItemRecipeComponent<DryingRecipe>
{
    @Override
    protected RecipeType<DryingRecipe> getRecipeType()
    {
        return FLRecipeTypes.DRYING.get();
    }
}
```

#### 1.11.3 书籍覆盖/合并机制

**事实**：Firmalife 不提供自己的 `book.json`，而是把内容直接放进 TFC 书的命名空间下：

- `src/main/resources/assets/tfc/patchouli_books/field_guide/en_us/categories/firmalife.json`（新分类，`"name": "Firmalife"`、`"icon": "firmalife:brick_oven_top"`、`"sortnum": 10`）
- `src/main/resources/assets/tfc/patchouli_books/field_guide/<lang>/entries/firmalife/*.json`（20+ 篇新条目，lang 覆盖 `en_us`、`ja_jp`、`ru_ru`、`zh_cn`、`zh_tw`）
- **同名覆盖文件**：`src/main/resources/assets/tfc/patchouli_books/field_guide/en_us/entries/mechanics/bread.json` 与 `.../mechanics/dairy.json`（TFC 自有条目的同名路径），内容指向 Firmalife 的新条目：

```json
{
  "name": "Bread",
  "category": "tfc:mechanics",
  "icon": "tfc:textures/item/food/wheat_bread.png",
  "pages": [
    {
      "type": "patchouli:text",
      "text": "$(l:firmalife/bread)See the Firmalife entry for the correct information.$()",
      "title": "Bread"
    }
  ],
  "read_by_default": true
}
```

- 另有 `templates/drying_recipe.json`、`templates/smoking_recipe.json`（自定义页面模板）。

**机制说明（标注可信度）**：Patchouli 的书籍内容按文件从资源包读取，`vazkii.patchouli.client.book.BookContentResourceListenerLoader extends SimpleJsonResourceReloadListener implements BookContentLoader`，并提供 `public void findFiles(Book, String, List<ResourceLocation>)` 与 `public BookContentLoader$LoadResult loadJson(Book, ResourceLocation)`（javap 来源：`Patchouli-1.21.1-93-NEOFORGE.jar`）。这**说明内容是按「文件」逐条加载、并且可跨资源包收集**，因此：
- **不同路径**的文件（`entries/firmalife/*`）会**并入** `tfc` 的 `field_guide` 书；
- **同一路径**的文件（如 `entries/mechanics/bread.json`）会**互相覆盖**，生效者由**资源包优先级**决定——Firmalife 在 `neoforge.mods.toml` 中声明对 TFC `ordering = "AFTER"`：

```toml
[[dependencies.firmalife]]
    modId = "tfc"
    type = "required"
    versionRange = "${tfcVersionRange}"
    ordering = "AFTER"
    side = "BOTH"
```

**未能核实**：Patchouli 内部对「同名文件覆盖 + 多包合并」的确切实现（只读到了方法签名，未反编译方法体）。检查位置：Patchouli jar 中 `BookContentLoader` / `BookContentsBuilder` / `ClientBookRegistry` 等类。因此上面第 2 条（同名覆盖由资源包优先级决定）是**基于资源包加载语义的推断**，不是从 Patchouli 源码读出的结论。

### 1.12 `compat/tooltip/` 与 `compat/jei/` 的接入方式

#### 1.12.1 共享的 tooltip 数据源：`FLTooltips`

`src/main/java/com/eerussianguy/firmalife/compat/tooltip/FLTooltips.java`（423 行，`public final class`）把「每个方块显示什么信息」集中定义为 TFC 的 `BlockEntityTooltip` / `EntityTooltip` 函数式接口常量，并暴露两个 `register` 方法给不同 mod 使用：

```java
public final class FLTooltips
{
    public static final class BlockEntities
    {
        public static void register(RegisterCallback<BlockEntityTooltip, Block> r)
        {
            register(r, "drying_mat", DRYING_MAT, DryingMatBlock.class);
            register(r, "solar_drier", DRYING_MAT, SolarDrierBlock.class);
            ...
        }

        private static void register(RegisterCallback<BlockEntityTooltip, Block> r, String name, BlockEntityTooltip tooltip, Class<? extends Block> aClass)
        {
            r.register(FLHelpers.identifier(name), tooltip, aClass);
        }

        public static final BlockEntityTooltip KEG = (level, state, pos, entity, tooltip) -> { ... };
        public static final BlockEntityTooltip VAT = (level, state, pos, entity, tooltip) -> { ... };
        public static final BlockEntityTooltip OVEN = (level, state, pos, entity, tooltip) -> { ... };
        ...
    }

    public static final class Entities
    {
        public static void register(RegisterCallback<EntityTooltip, Entity> r)
        {
        }
    }
```

（`RegisterCallback` 是 TFC 的接口 `net.dries007.tfc.util.tooltip.RegisterCallback`；`BlockEntityTooltips` 的静态工厂如 `DRYING_MAT`、`STRING`、`CHEESE`、`OVEN`、`SHELF_OR_HANGER`、`VAT`、`TUMBLER`、`CLIMATE_STATION`、`JARBNET`、`BARREL_PRESS`、`POT`、`KEG` 通过 `import static net.dries007.tfc.util.tooltip.BlockEntityTooltips.*;` 引入。）

#### 1.12.2 Jade

`src/main/java/com/eerussianguy/firmalife/compat/tooltip/JadeIntegration.java`（64 行）：

```java
@WailaPlugin
public class JadeIntegration implements IWailaPlugin
{
    @Override
    public void registerClient(IWailaClientRegistration registry)
    {
        FLTooltips.BlockEntities.register((name, tooltip, block) -> register(registry, name, tooltip, block));
        FLTooltips.Entities.register((name, tooltip, entity) -> register(registry, name, tooltip, entity));
    }
```

即：用 `@WailaPlugin` + `IWailaPlugin#registerClient`，把 `FLTooltips` 的每个常量包成匿名 `IBlockComponentProvider`（`getUid()` 返回该 name、`appendTooltip` 调 `tooltip.display(...)`）并 `registry.registerBlockComponent(provider, blockClass)`。

**未能核实**：Jade 如何发现 `@WailaPlugin` 类。检查位置：Firmalife jar 与 TFC jar 中均**没有** Jade 的 descriptor 文件（`jar tf` 搜 `jade`/`services` 只命中 class 本身），因此推测是 Jade 通过 mod 文件注解扫描发现——但未反编译验证。

依赖声明：`build.gradle.kts` 第 160 行把 Jade 作为 **implementation（运行期存在）**：

```gradle
    implementation(group = "curse.maven", name = "jade-324717", version = "6853386")
```

#### 1.12.3 The One Probe

`src/main/java/com/eerussianguy/firmalife/compat/tooltip/TheOneProbeIntegration.java`（76 行）：

```java
public class TheOneProbeIntegration implements Function<ITheOneProbe, Void>
{
    public static void init(IEventBus bus)
    {
        bus.addListener((InterModEnqueueEvent event) -> InterModComms.sendTo("theoneprobe", "getTheOneProbe", TheOneProbeIntegration::new));
    }
```

接入条件（`FirmaLife.java` 第 95–96 行）：

```java
        if (THE_ONE_PROBE)
            TheOneProbeIntegration.init(bus);
```

（`THE_ONE_PROBE = ModList.get().isLoaded("theoneprobe")`，见第 52 行。）

TOP 用 IMC（`InterModComms.sendTo`）注册，回调里把 `FLTooltips` 包成 `IProbeInfoProvider` / `IProbeInfoEntityProvider`。依赖是 **compileOnly**（`build.gradle.kts` 第 161 行），所以运行期可能不存在——这正是必须用 `THE_ONE_PROBE` 布尔守卫的原因（见第 3.5 节）。

#### 1.12.4 JEI

`src/main/java/com/eerussianguy/firmalife/compat/jei/FLJEIPlugin.java`（137 行）：

```java
@JeiPlugin
public class FLJEIPlugin implements IModPlugin
{
    private static <T extends Recipe<?>> RecipeType<RecipeHolder<T>> type(String name, Class<T> kind)
    {
        return RecipeType.createRecipeHolderType(ResourceLocation.fromNamespaceAndPath(FirmaLife.MOD_ID, name));
    }

    public static final RecipeType<RecipeHolder<DryingRecipe>> DRYING = type("drying", DryingRecipe.class);
    ...
    @Override
    public ResourceLocation getPluginUid()
    {
        return FLHelpers.identifier("jei");
    }
```

- 用 `mezz.jei.api.JeiPlugin` 注解 + `IModPlugin` 实现，`RecipeType.createRecipeHolderType(...)` 包 `RecipeHolder`；
- `registerCategories` 注册 10 个 `*Category`（DryingCategory、SmokingCategory、StompingCategory、PressCategory、CentrifugeCategory、MixingCategory、OvenCategory、VatCategory、StinkySoupCategory、BowlPotCategory）；
- `registerRecipes` 从客户端 `RecipeManager` 取配方（**直接复用 TFC 的 `ClientHelpers`**）：

```java
    // Copied from TFC
    private static <C extends RecipeInput, T extends Recipe<C>> List<RecipeHolder<T>> recipes(Supplier<net.minecraft.world.item.crafting.RecipeType<T>> type, Predicate<T> filter)
    {
        return ClientHelpers.getLevelOrThrow().getRecipeManager()
            .getAllRecipesFor(type.get())
            .stream()
            .filter(holder -> filter.test(holder.value()))
            .toList();
    }
```

- 还从 TFC 的配方类型里筛出自己的序列化器（`recipes(TFCRecipeTypes.POT, recipe -> recipe.getSerializer() == FLRecipeSerializers.BOWL_POT.get())`）；
- `registerRecipeCatalysts` 用 TFC 物品当催化剂（`TFCItems.WOOL_YARN`、`TFCItems.POT`）与 Firmalife 木种变体（`FLBlocks.STOMPING_BARRELS.get(Wood.MANGROVE)`）。

依赖：JEI 是 **compileOnly（API）+ runtimeOnly（完整）**，并在 `mods.toml` 里声明为 optional（见第 3.1 节）。

`@JeiPlugin` 的发现机制由 JEI 自身的注解扫描完成（与 Jade 同类问题，**未能核实**细节）。

### 1.13 数据包侧集成（datagen 与 TFC 命名空间数据）

#### 1.13.1 写进 `tfc` 命名空间的数据

Firmalife 的 datagen 直接向 TFC 命名空间输出数据（jar 内实际路径）：

- `data/tfc/tags/block/*.json`：`fruit_tree_leaves`、`fruit_tree_branches`、`fruit_tree_saplings`、`single_block_replaceable`、`thorny_bushes`、`can_collapse`、`can_start_collapse`、`fox_raidable`、`can_be_snow_piled`、`prospectable`、`mineable/glass_saw`
- `data/tfc/tags/worldgen/placed_feature/**`：`feature/berry_bushes`、`feature/fruit_trees`、`feature/land_plants`、`feature/shore_decorations`、`in_biome/veins`
- `data/firmalife/tfc/**`：把 Firmalife 内容喂进 TFC 的 DataManager（`tfc/fluid_heat/*`、`tfc/knapping_type/pumpkin`、`tfc/drinkable/chocolate`、`tfc/item_size/*`）

其中标签是**合并语义**（datapack tag 会与 TFC 原文件合并），这是 Firmalife 把「野果丛/果树/矿脉生成」挂到 TFC 世界生成上的方式。

对应 datagen 代码（`src/data/java/com/eerussianguy/firmalife/DataEntryPoint.java`）：

```java
        add(event, new DataManagerProvider<LampFuel>(LampFuel.MANAGER, output, lookup, TerraFirmaCraft.MOD_ID)
        {

            @Override
            protected void addData(HolderLookup.Provider provider)
            {
                add("soybean_oil", new LampFuel(FluidIngredient.of(FLFluids.EXTRA_FLUIDS.get(ExtraFluid.SOYBEAN_OIL).getSource()), BlockIngredient.of(TFCTags.Blocks.LAMPS), 7000));
            }
        });
```

（`DataManagerProvider` 的第 4 个参数 `domain` 决定输出命名空间——TFC 的 manager 用 `TerraFirmaCraft.MOD_ID`，Firmalife 自己的用 `MOD_ID`。）

#### 1.13.2 一个必须注意的数据分布事实

- `src/main/resources/data/firmalife/` 只有 `advancement/` 与 `worldgen/`；**没有 `recipe/`**。
- 配方 JSON 全在 `src/generated/resources/data/firmalife/recipe/`（datagen 输出，约 1069 个文件），对应 jar 内 `data/firmalife/recipe/`（1159 个条目，含目录项）的 22 个类型子目录：`alloy/anvil/barrel_instant/barrel_instant_fluid/barrel_sealed/casting/centrifuge/chisel/collapse/crafting/drying/glassworking/heating/knapping/loom/mixing_bowl/oven/pot/quern/smoking/stomping/vat/welding`。
- **Firmalife 自有类型中，`press` 没有内置配方 JSON**：`data/firmalife/recipe/` 下无 `press/` 目录，`src/data` 中也无 `pressRecipes()`（`BuiltinRecipes.buildRecipes` 调用了 21 个 `*Recipes()` 方法，其中不含 press）。第三方若写 press 配方，可以直接写 `data/<modid>/recipe/press/*.json`。

---

## 2. 对外可复用的公开 API 与扩展点

### 2.1 可作为扩展基类的 `public` 非 final 类型

#### 2.1.1 总览（类声明扫描结果）

扫描方式：对 `src/main/java` 与 `src/data/java` 全树匹配 `^(public )(abstract |final )*(class|interface|record|enum) ` 等模式，共 320 行声明。

| 类别 | 数量 | 说明 |
|---|---|---|
| `public class`（普通类） | 多数 | 可继承（除非构造器受限） |
| `public abstract class` | 7 | `ApplianceBlockEntity`、`BoilingBlockEntity`、`SimpleItemRecipeBlockEntity`、`AbstractOvenBlock`、`SimpleDynamicBlockModel`、`BeeMixin`、`ServerConfigMixin` |
| `public interface` | 7 | `IWeatherable`、`ICure`、`IGrape`、`GreenhouseConnectable`、`ClimateReceiver`、`OvenLike`、`CrucibleLikeHeatBlock` |
| `public final class` | 11 | 见 2.2.3（**不可继承**） |
| 包私有顶层类 | **0** | 全部顶层类型都有显式 `public` |

#### 2.1.2 接口（7 个，全部可在包外实现）

**① `ClimateReceiver`** — 包 `com.eerussianguy.firmalife.common.blockentities`，文件 `src/main/java/com/eerussianguy/firmalife/common/blockentities/ClimateReceiver.java`

```java
public interface ClimateReceiver
{
    @Nullable
    static ClimateReceiver get(Level level, BlockPos pos);

    default boolean addWater(float amount);

    default boolean addWater(float amount, @Nullable Direction direction);

    void setValid(Level level, BlockPos pos, boolean valid, int tier, ClimateType climate);

    default void findClimateStation(Level level, BlockPos origin);
}
```

- **唯一抽象方法**：`setValid(Level, BlockPos, boolean, int, ClimateType)`。
- **实现示例**：`CheeseWheelBlock`（`common/blocks/CheeseWheelBlock.java`）：

```java
    @Override
    public void setValid(Level level, BlockPos pos, boolean valid, int tier, ClimateType climate)
    {
        BlockState state = level.getBlockState(pos);
        if (state.getBlock() instanceof CheeseWheelBlock)
        {
            final boolean isAgingNow = state.getValue(AGING);
            final boolean shouldAge = valid && climate == ClimateType.CELLAR;
            if (isAgingNow != shouldAge)
            {
                level.setBlockAndUpdate(pos, state.setValue(AGING, shouldAge));
            }
        }
    }
```

其它实现：`FoodShelfBlockEntity`、`LargePlanterBlockEntity`（`addWater` / `setValid`）、`SprinklerBlockEntity`。

**② `OvenLike`** — 包 `com.eerussianguy.firmalife.common.blockentities`，文件 `common/blockentities/OvenLike.java`

```java
public interface OvenLike
{
    static void regularBlockUpdate(Level level, BlockPos pos, BlockState state, OvenLike oven, boolean cured, int updateInterval);

    float getTemperature();

    int getCureTicks();

    void addCureTicks(int ticks);
}
```

- 3 个抽象方法 + 1 个静态工具方法（内含烟囱检查、点火蔓延、固化计时逻辑，见第 1.4 节同文件的 `Helpers.fireSpreaderTick` 使用）。
- **实现示例**：`OvenBottomBlockEntity`（`common/blockentities/OvenBottomBlockEntity.java`）：

```java
    @Override
    public float getTemperature()
    {
        return temperature;
    }

    @Override
    public int getCureTicks()
    {
        return cureTicks;
    }

    @Override
    public void addCureTicks(int ticks)
    {
        cureTicks += ticks;
    }
```

另一实现 `OvenTopBlockEntity`（`getTemperature()` 继承自 `ApplianceBlockEntity`）。

**③ `IWeatherable`** — 包 `com.eerussianguy.firmalife.common.blocks`，文件 `common/blocks/IWeatherable.java`（源码自带 `// todo remove?` 注释）

```java
public interface IWeatherable
{
    default void onRandomTick(BlockState state, ServerLevel level, BlockPos pos, RandomSource random);

    default int weatherChance();

    default boolean hasNext();

    @Nullable
    Supplier<? extends Block> getNext();
}
```

- **唯一抽象方法**：`getNext()`。
- 实现：`BaseGreenhouseBlock`、`GreenhouseDoorBlock`、`GreenhousePanelRoofBlock`、`GreenhousePanelWallBlock`、`GreenhouseSlabBlock`、`GreenhouseStairBlock`、`GreenhouseTrapDoorBlock`（共 7 个）。
- 默认实现体（第 16–23 行）：

```java
    default void onRandomTick(BlockState state, ServerLevel level, BlockPos pos, RandomSource random)
    {
        Supplier<? extends Block> next = getNext();
        if (next != null && random.nextInt(weatherChance()) == 0)
        {
            level.setBlockAndUpdate(pos, Helpers.copyProperties(next.get().defaultBlockState(), state));
        }
    }
```

**④ `ICure`** — 包 `com.eerussianguy.firmalife.common.blocks.oven`，文件 `common/blocks/oven/ICure.java`（全文 20 行）

```java
public interface ICure
{
    void cure(Level level, BlockState state, BlockPos pos);

    @Nullable
    Block getCured();

    default boolean isCured()
    {
        return getCured() == null;
    }
}
```

- 实现：`AbstractOvenBlock`（只实现 `getCured()`，`cure` 留给子类）、`OvenBottomBlock`、`OvenTopBlock`（`OvenChimneyBlock`/`OvenHopperBlock` 的 implements 子句未逐行核实）。
- 实现示例（`OvenTopBlock`）：

```java
    @Override
    public void cure(Level level, BlockState state, BlockPos pos)
    {
        if (getCured() != null)
        {
            OvenTopBlockEntity.cure(level, state, getCured().defaultBlockState(), pos);
        }
    }
```

**⑤ `IGrape`** — 包 `com.eerussianguy.firmalife.common.blocks.plant`，文件 `common/blocks/plant/IGrape.java`（全文 26 行）

```java
public interface IGrape
{
    default void advance(Level level, BlockPos pos, BlockState state) {}

    default void advanceLifecycle(Level level, BlockPos pos, BlockState state, Lifecycle lifecycle);

    default void updateLifecycle(Level level, BlockPos pos, BlockState state, Lifecycle lifecycle);
}
```

- **全部方法都是 default** —— 实现类只挑需要的覆写。
- 实现：`GrapeStringWithPlantBlock`、`GrapeGroundPlantOnStringBlock`。
- 实现示例（`GrapeStringWithPlantBlock`）：

```java
    @Override
    public void advance(Level level, BlockPos pos, BlockState state)
    {
        final Direction dir = state.getValue(AXIS) == Direction.Axis.X ? Direction.EAST : Direction.SOUTH;
        convertToPlant(level, pos.relative(dir));
        convertToPlant(level, pos.relative(dir.getOpposite()));

        final BlockPos above = pos.above();
        if (level.getBlockState(above).isAir())
        {
            level.setBlockAndUpdate(above, fluffBlock.get().defaultBlockState());
        }
    }

    @Override
    public void advanceLifecycle(Level level, BlockPos pos, BlockState state, Lifecycle lifecycle)
    {
        updateLifecycle(level, pos, state, lifecycle);
        final Direction dir = state.getValue(AXIS) == Direction.Axis.X ? Direction.EAST : Direction.SOUTH;
        updateLifecycle(level, pos.relative(dir), level.getBlockState(pos.relative(dir)), lifecycle);
        updateLifecycle(level, pos.relative(dir.getOpposite()), level.getBlockState(pos.relative(dir.getOpposite())), lifecycle);
    }
```

**⑥ `GreenhouseConnectable`** — 包 `com.eerussianguy.firmalife.common.blocks.greenhouse`，文件 `common/blocks/greenhouse/GreenhouseConnectable.java`（187 行）

```java
    @Deprecated
    default boolean canConnectTo(BlockState state, Direction facing, BlockState facingState, LevelAccessor level, BlockPos currentPos, BlockPos facingPos);

    BlockState withConnection(BlockState state, Direction facing, BlockState facingState, LevelAccessor level, BlockPos currentPos, BlockPos facingPos);

    @Deprecated
    Set<Direction> getConnectionFaces(BlockState state, BlockPos pos, LevelAccessor level);

    default BlockState updateConnections(BlockState state, BlockPos pos, LevelAccessor level, Direction... directions);

    @Deprecated
    static boolean hasConnectionAt(BlockState state, BlockPos pos, LevelAccessor level, Direction direction);
```

- **两个抽象方法**：`withConnection(...)`、`getConnectionFaces(...)`。
- 嵌套枚举：`DualSide { NONE, LEFT, RIGHT, BOTH }`（含 `combine`/`subtract`/`opposite`/`contains`/`static resolve`）、`Side { LEFT, RIGHT, NONE }`（含 `getDirection`/`opposite`/`dual`）、`Size { NONE, THIN, THICK }`。
- 实现：`GreenhouseDoorBlock`、`GreenhousePanelRoofBlock`、`GreenhousePanelWallBlock`。
- 实现示例（`GreenhouseDoorBlock`）：

```java
    @Override
    public BlockState withConnection(BlockState state, Direction facing, BlockState facingState, LevelAccessor level, BlockPos currentPos, BlockPos facingPos)
    {
        return state;
    }

    @Override
    public Set<Direction> getConnectionFaces(BlockState state, BlockPos pos, LevelAccessor level)
    {
        Direction facing = state.getValue(FACING);
        return Set.of(facing.getClockWise(), facing.getCounterClockWise());
    }
```

**⑦ `CrucibleLikeHeatBlock`** — 包 `com.eerussianguy.firmalife.common.blockentities`，文件 `common/blockentities/CrucibleLikeHeatBlock.java`：

```java
public interface CrucibleLikeHeatBlock extends IHeatConsumer
```

（`IHeatConsumer` 是 TFC 的接口；本接口不新增方法，属标记/别名式接口。实现类：`ApplianceBlockEntity.ApplianceInventory`。）

#### 2.1.3 抽象类（可继承的基类）

**① `AbstractOvenBlock`** — 包 `com.eerussianguy.firmalife.common.blocks.oven`，文件 `common/blocks/oven/AbstractOvenBlock.java`

```java
public abstract class AbstractOvenBlock extends FourWayDeviceBlock implements ICure
{
    public static final BooleanProperty HAS_CHIMNEY = FLStateProperties.HAS_CHIMNEY;

    @Nullable
    public static BlockPos locateChimney(LevelAccessor level, BlockPos pos, BlockState state);
    public static void cureAllAround(Level level, BlockPos pos, boolean myself);
    public AbstractOvenBlock(ExtendedProperties properties, @Nullable Supplier<? extends Block> curedBlock);
    public boolean isInsulated(LevelAccessor level, BlockPos pos, BlockState state);
    @Override public void animateTick(BlockState state, Level level, BlockPos pos, RandomSource random);
    @Override public @Nullable Block getCured();
    @Override protected void createBlockStateDefinition(StateDefinition.Builder<Block, BlockState> builder);
}
```

- **无包私有抽象方法** → 可在包外继承；`cure(Level, BlockState, BlockPos)` 由子类实现。
- 内部子类：`OvenTopBlock`、`OvenBottomBlock`（再看 `InsulatedOvenTopBlock`、`InsulatedOvenBottomBlock`）。

**② `LargePlanterBlockEntity`** — 包 `com.eerussianguy.firmalife.common.blockentities`，文件 `common/blockentities/LargePlanterBlockEntity.java`（441 行）

```java
public class LargePlanterBlockEntity extends TickableInventoryBlockEntity<ItemStackHandler> implements ICalendarTickable, ClimateReceiver, IFarmland
```

关键 public 方法（完整列表见下，逐条由源码提取）：

```java
public LargePlanterBlockEntity(BlockPos pos, BlockState state)
public LargePlanterBlockEntity(BlockEntityType<?> type, BlockPos pos, BlockState state, InventoryFactory<ItemStackHandler> inventoryFactory, String modId)
public static void serverTick(Level level, BlockPos pos, BlockState state, LargePlanterBlockEntity planter)
public int getSlotStackLimit(int slot)
public boolean isItemValid(int slot, ItemStack stack)
public void onCalendarUpdate(long ticks)
public void updateBlockState(BlockState state)
public long getLastGrowthTick()
public void setLastGrowthTick(long lastGrowthTick)
public long getLastCalendarUpdateTick()
public void setLastCalendarUpdateTick(long ticks)
public void loadAdditional(CompoundTag nbt, HolderLookup.Provider access)
public void saveAdditional(CompoundTag nbt, HolderLookup.Provider access)
public void updateCache()
public boolean checkValid()
public boolean isClimateValid()
public @Nullable Component getInvalidReason()
public int getTier()
public int slots()
public float getGrowth(int slot)
public float getYield(int slot)
public void setYield(int slot, float yield)
public void setGrowth(int slot, float growth)
public @Nullable Plantable getPlantable(int slot)
public float getNutrient(FarmlandBlockEntity.NutrientType type)
public void setNutrient(FarmlandBlockEntity.NutrientType type, float amount)
public void setNutrientWithoutSync(FarmlandBlockEntity.NutrientType type, float amount)
public float getNAbsorbed(int slot)
public float getPAbsorbed(int slot)
public float getKAbsorbed(int slot)
public void addNutrients(int slot, float n, float p, float k)
public void resetAbsorbed(int slot)
public float getAdditionalWater()
public void waterTick()
public void setAdditionalWater(float amount)
public void setAdditionalWaterWithoutSync(float amount)
public long getLastWaterTick()
public void setLastWaterTick(long l)
public void setAndUpdateSlots(int slot)
public boolean addWater(float amount, @Nullable Direction direction)
public void drainWater(float amount)
public void setValid(Level level, BlockPos pos, boolean valid, int tier, ClimateType climate)
public float getWater()
public void afterGrowthTickStep(boolean wasGrowing)
public float resetGrowthTo()
```

- **protected 扩展点**（包外可用）：`protected void loadUnique(CompoundTag)`、`protected void saveUnique(CompoundTag)`、`protected Direction airFindOffset()`。
- **内部子类 5 个**：`TrellisPlanterBlockEntity`（覆盖 `airFindOffset` 返回 `null`、`afterGrowthTickStep`、`resetGrowthTo`→`0.2f`）、`HangingPlanterBlockEntity`（`airFindOffset`→`Direction.DOWN`、`addWater`、`resetGrowthTo`）、`BonsaiPlanterBlockEntity`（`resetGrowthTo`）、`QuadPlanterBlockEntity`（`loadUnique`/`saveUnique`/`updateCache`/`slots`/`getGrowth`/`setGrowth`/`getYield`/`setYield`/`getPlantable`）、`HydroponicPlanterBlockEntity extends QuadPlanterBlockEntity`（override 集合未逐行核实）。
- 最短的实现示例（`HangingPlanterBlockEntity` 全文）：

```java
public class HangingPlanterBlockEntity extends LargePlanterBlockEntity
{
    public HangingPlanterBlockEntity(BlockPos pos, BlockState state)
    {
        super(FLBlockEntities.HANGING_PLANTER.get(), pos, state, defaultInventory(LARGE_PLANTER_SLOTS), FirmaLife.MOD_ID);
    }

    @Override
    protected Direction airFindOffset()
    {
        return Direction.DOWN;
    }

    @Override
    public boolean addWater(float amount, @Nullable Direction direction)
    {
        return direction != Direction.DOWN && super.addWater(amount, direction);
    }

    @Override
    public float resetGrowthTo()
    {
        return 0.2f;
    }
}
```

**注意**：`LargePlanterBlockEntity` 的 public 构造器是 `(BlockEntityType<?>, BlockPos, BlockState, InventoryFactory<ItemStackHandler>, String modId)` —— 这是**为第三方预留**的构造签名（少见的「带 modId 参数」设计），但其依赖的 `defaultInventory`/`InventoryFactory` 来自 TFC 的 `InventoryBlockEntity`。

#### 2.1.4 普通类（可继承，构造器 public）

| 类 | 包 | 关键 public 方法 / 说明 |
|---|---|---|
| `TwoByTwoCoreBlock` | `com.eerussianguy.firmalife.common.blocks`（**顶层，不在子包**） | `public static boolean coreBlockSurvives(LevelReader, BlockPos, BlockState)`；`public TwoByTwoCoreBlock(ExtendedProperties, Supplier<? extends Block> sub)`；`getStateForPlacement`/`setPlacedBy`/`getShape`。子类示例：`KegCoreBlock` |
| `FourWayDeviceBlock` | `common.blocks` | `public static final DirectionProperty FACING`；`public FourWayDeviceBlock(ExtendedProperties, InventoryRemoveBehavior)`；`rotate`/`mirror`/`getStateForPlacement`。**11 个子类**（`CompostTumblerBlock`、`WineShelfBlock`、`TwoByTwoSubBlock`、`TwoByTwoCoreBlock`、`CentrifugeBlock`、`BaseBeehiveBlock` 系列、`JarringStationBlock`、`JarbnetBlock`、`FoodShelfBlock`、`AbstractOvenBlock`、`PumpingStationBlock`） |
| `ConsumingBlock` | `common.blocks` | **不是接口**！`public class ConsumingBlock extends BottomSupportedDeviceBlock`；`public static ConsumingBlock plate(ExtendedProperties)`；`public static final VoxelShape PLATE_SHAPE`；`protected ItemInteractionResult useItemOn(...)` |
| `BarrelPressBlockEntity` | `common.blockentities` | `public BarrelPressBlockEntity(BlockPos, BlockState)`；`push()`、`squish()`、`getWineType()`、`tryFillWine(...)`、`getOutput()`、`hasOutput()`、`sinceWeLastTouched(float)`；`public record WineOutput(...)` 嵌套 |
| `DryingMatBlockEntity` | `common.blockentities` | **继承受限**，见 2.2.2；但可作为「怎么用 `SimpleItemRecipeBlockEntity`」的参考实现 |
| `ApplianceBlockEntity<C>`（abstract） | `common.blockentities` | `abstract class ApplianceBlockEntity<C extends IItemHandlerModifiable & INBTSerializable<CompoundTag> & IHeatConsumer> extends TickableInventoryBlockEntity<C> implements ICalendarTickable`；嵌套 `public static class ApplianceInventory implements IHeatConsumer, DelegateItemHandler, INBTSerializable<CompoundTag>, CrucibleLikeHeatBlock` |
| `SimpleDynamicBlockModel<T>`（abstract，客户端） | `client.model` | `public abstract class SimpleDynamicBlockModel<T extends BlockEntity> extends DynamicBlockModel.Baked`；需配合 `DynamicBlockModel.Loader` 使用 |

#### 2.1.5 其余被点名类型的完整 public 签名

**① `SimpleItemRecipeBlockEntity<T extends ItemRecipe>`**（abstract，包 `com.eerussianguy.firmalife.common.blockentities`，文件 `common/blockentities/SimpleItemRecipeBlockEntity.java`）

```java
public abstract class SimpleItemRecipeBlockEntity<T extends ItemRecipe> extends InventoryBlockEntity<ItemStackHandler>
{
    protected long startTick;
    protected boolean needsRecipeUpdate = false;

    public SimpleItemRecipeBlockEntity(BlockEntityType<?> type, BlockPos pos, BlockState state, String modId, Supplier<Integer> duration)
    public void loadAdditional(CompoundTag nbt, HolderLookup.Provider access)
    public void saveAdditional(CompoundTag nbt, HolderLookup.Provider access)
    public void setAndUpdateSlots(int slot)
    public int getSlotStackLimit(int slot)
    abstract void updateCache();                 // ← 包私有抽象方法（继承屏障，见 2.2.1）
    public T getCachedRecipe()
    public long getTicksLeft()
    public void start()
    public void finish()
    public void resetCounter()
    public ItemStack viewStack()
    public ItemStack readStack()
    public int getDuration()
}
```

- 内部实现示例：`DryingMatBlockEntity`（override `setAndUpdateSlots`/`isItemValid`/`updateCache`）、`StringBlockEntity extends SimpleItemRecipeBlockEntity<SmokingRecipe>`（override `isItemValid`/`setAndUpdateSlots`/`getSlotStackLimit`/`updateCache`）。

**② `DryingMatBlockEntity`**（包 `common.blockentities`）

```java
public class DryingMatBlockEntity extends SimpleItemRecipeBlockEntity<DryingRecipe>
{
    public static DryingMatBlockEntity dryingMat(BlockPos pos, BlockState state)
    public static DryingMatBlockEntity solarDrier(BlockPos pos, BlockState state)
    public static void serverTick(Level level, BlockPos pos, BlockState state, DryingMatBlockEntity mat)
    public DryingMatBlockEntity(BlockEntityType<DryingMatBlockEntity> type, BlockPos pos, BlockState state, Supplier<Integer> dryTicks)
    public void setAndUpdateSlots(int slot)
    public void ejectItem(Direction d)
    public boolean isItemValid(int slot, ItemStack stack)
    public void updateCache()
}
```

- 两个 public 静态工厂 `dryingMat` / `solarDrier` 是烧干架与日晒架共用一个 BE 类的方式（`FLBlockEntities` 中分别注册为 `DRYING_MAT` 与 `SOLAR_DRIER`，用方法引用做工厂）。

**③ `FLTickingPlantBlockEntity`**（包 `common.blockentities`，叶子类，无子类）

```java
public class FLTickingPlantBlockEntity extends TickingPlantBlockEntity
{
    public static void reset(Level level, BlockPos pos)
    public static void addTicks(Level level, BlockPos pos, long ticks)
    public static void setStemPos(Level level, BlockPos pos, BlockPos stemPos)
    public FLTickingPlantBlockEntity(BlockPos pos, BlockState state)
    public BlockEntityType<?> getType()
}
```

- 用途：Firmalife 果树幼苗与生长枝条（`FLBlockEntities.TICKING_PLANT` 注册了 `FRUIT_TREE_SAPLINGS` 与 `FRUIT_TREE_GROWING_BRANCHES` 两组方块）。

**④ `FLTickCounterBlockEntity`**（包 `common.blockentities`，叶子类）

```java
public class FLTickCounterBlockEntity extends TickCounterBlockEntity
{
    public static void reset(Level level, BlockPos pos)
    public FLTickCounterBlockEntity(BlockPos pos, BlockState state)
    public BlockEntityType<?> getType()
}
```

- 用途：奶酪轮与南瓜灯（`FLBlockEntities.TICK_COUNTER`）。

**⑤ `BoilingBlockEntity<C>`**（abstract，包 `common.blockentities`）

```java
public abstract class BoilingBlockEntity<C extends IItemHandlerModifiable & INBTSerializable<CompoundTag> & IHeatConsumer & IFluidHandler>
    extends ApplianceBlockEntity<C> implements ICalendarTickable, FluidTankCallback
{
    protected int boilingTicks = 0;
    protected boolean needsRecipeUpdate = true;

    public BoilingBlockEntity(BlockEntityType<?> type, BlockPos pos, BlockState state, InventoryFactory<C> inventoryFactory, Component name)
    public void ranOutDueToCalendar()
    public void fluidTankChanged()
    public void setAndUpdateSlots(int slot)
    public void loadAdditional(CompoundTag nbt, HolderLookup.Provider access)
    public void saveAdditional(CompoundTag nbt, HolderLookup.Provider access)
    abstract boolean isBoiling();                // ← 包私有抽象方法（继承屏障，见 2.2.1）

    public static class BoilingInventory extends ApplianceInventory implements DelegateFluidHandler, FluidTankCallback
    {
        protected final InventoryFluidTank tank;
        public BoilingInventory(InventoryBlockEntity<?> entity, int slots, InventoryFluidTank tank)
        public IFluidHandler getFluidHandler()
        public ItemStack extractItem(int slot, int amount, boolean simulate)
        public CompoundTag serializeNBT(HolderLookup.Provider access)
        public void deserializeNBT(HolderLookup.Provider access, CompoundTag nbt)
    }
}
```

- 内部实现示例：`VatBlockEntity extends BoilingBlockEntity<VatBlockEntity.VatInventory>`、`StovetopPotBlockEntity extends BoilingBlockEntity<StovetopPotBlockEntity.StovetopPotInventory>`（两类的 override 集合未逐行核实）。
- 嵌套 `public static class BoilingInventory` 的**构造器是 public**，因此在包外可被实例化/继承（与包私有抽象方法不同）。

### 2.2 **不可**直接复用的类型

#### 2.2.1 包私有抽象方法造成的「继承屏障」（最重要）

| 类 | 包私有抽象方法 | 文件 |
|---|---|---|
| `SimpleItemRecipeBlockEntity<T extends ItemRecipe>` | `abstract void updateCache();` | `src/main/java/com/eerussianguy/firmalife/common/blockentities/SimpleItemRecipeBlockEntity.java:58` |
| `BoilingBlockEntity<C>` | `abstract boolean isBoiling();` | `src/main/java/com/eerussianguy/firmalife/common/blockentities/BoilingBlockEntity.java:68` |

Java 语言规定：**包外子类无法实现包私有抽象方法**，因此这两个看起来很像公开扩展点的抽象类，**实际上只能在 `com.eerussianguy.firmalife.common.blockentities` 包内继承**。第三方模组无法在自己的包里继承它们（会编译失败）。

这条也解释了为什么 `DryingMatBlockEntity`、`StringBlockEntity`、`VatBlockEntity`、`StovetopPotBlockEntity` 都写在 Firmalife 自己那个包里。

#### 2.2.2 包私有构造器

```java
// src/main/java/com/eerussianguy/firmalife/common/blockentities/KegBlockEntity.java（KegInventory 的两个构造）
    KegInventory(InventoryBlockEntity<?> inventory)
    KegInventory(BarrelInventoryCallback inventory)

// src/main/java/com/eerussianguy/firmalife/common/container/KegContainer.java:30（Firmalife 中唯一的私有构造器）
    private KegContainer(int windowId, KegBlockEntity blockEntity)
```

`KegContainer` 的公开入口是静态工厂：`public static KegContainer create(KegBlockEntity barrel, Inventory playerInv, int windowId)`。

#### 2.2.3 `public final class`（11 个，不可继承）

| 类 | 文件 |
|---|---|
| `FLClientHelpers` | `client/FLClientHelpers.java` |
| `FLClientSelfTests` | `client/FLClientSelfTests.java` |
| `RenderUtils` | `client/render/RenderUtils.java` |
| `FLTooltips` | `compat/tooltip/FLTooltips.java` |
| `FLFruitBlocks` | `common/blocks/plant/FLFruitBlocks.java` |
| `FLComponents` | `common/capabilities/FLComponents.java` |
| `FLCreativeTabs` | `common/FLCreativeTabs.java` |
| `FLArmorMaterials` | `common/util/FLArmorMaterials.java` |
| `FLAdvancements` | `common/util/FLAdvancements.java` |
| `Mechanics` | `common/util/Mechanics.java` |
| `FLPOIs` | `common/misc/FLPOIs.java` |

（这些类**可以被调用**——例如 `FLComponents.WINE`、`FLPOIs.CLIMATE_STATIONS`——但不能被子类化，也不能覆写其中的静态逻辑。）

#### 2.2.4 其它受限项

- **包私有嵌套类型**：`FLItemStackModifiers.Id`（`common/recipes/data/FLItemStackModifiers.java`，无 `public`）、`SprinklerBlockEntity.Path`（`private record Path(BlockState state, BlockPos pos, int cost)`，`common/blockentities/SprinklerBlockEntity.java:216`）。
- **mixin 类**：`BarrelRackMixin`、`BeeMixin`、`ServerConfigMixin` 是 `@Mixin` 载体，只能通过 mixin 配置生效，无法被继承或实例化。
- **自检代码**：`common/util/FLSelfTests.java`、`client/FLClientSelfTests.java`（后者是 final），属内部测试设施。
- **屏幕/渲染类**：`*Screen`、`*Renderer` 通常是 final 式的使用方式（`BarrelPressScreen` 是普通 public class，可继承，但继承意义有限）。

### 2.3 新写一个 Firmalife 风格配方类型的完整步骤与骨架

> 以 `DryingRecipe`（`src/main/java/com/eerussianguy/firmalife/common/recipes/DryingRecipe.java`）为模板。示例模组 id 用 `examplemod`，请自行替换。

#### 步骤 0：确定输入形态（选基类）

| 输入 | 基类 | Firmalife 实例 |
|---|---|---|
| 单个物品 → 物品 | TFC 的 `ItemRecipe`（已实现 `INoopInputRecipe` + `IRecipePredicate<ItemStack>`） | `DryingRecipe`、`SmokingRecipe`、`CentrifugeRecipe`、`StompingRecipe`（+ `PressRecipe`） |
| 方块状态 → 方块状态 | TFC 的 `BlockRecipe`（含 3 个静态工厂 `codec`/`streamCodec`/`serializer`） | Firmalife 未使用，TFC 的 `CollapseRecipe`/`LandslideRecipe` 是范例 |
| 自定义带状态的容器（物品+流体） | `ISimpleRecipe<你的容器类型>` | `VatRecipe implements ISimpleRecipe<VatBlockEntity.VatInventory>`、`MixingBowlRecipe implements ISimpleRecipe<MixingBowlBlockEntity.MixingBowlInventory>` |
| 无输入（纯条件配方） | `INoopInputRecipe` + `IRecipePredicate<ItemStack>` | `OvenRecipe` |

#### 步骤 1：写配方类（含 CODEC / STREAM_CODEC）

```java
package com.example.examplemod.common.recipes;

import com.mojang.serialization.MapCodec;
import com.mojang.serialization.codecs.RecordCodecBuilder;
import net.minecraft.network.RegistryFriendlyByteBuf;
import net.minecraft.network.codec.StreamCodec;
import net.minecraft.world.item.Item;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.crafting.Ingredient;
import net.minecraft.world.item.crafting.RecipeSerializer;
import net.minecraft.world.item.crafting.RecipeType;
import org.jetbrains.annotations.Nullable;

import net.dries007.tfc.common.recipes.ItemRecipe;
import net.dries007.tfc.common.recipes.RecipeHelpers;
import net.dries007.tfc.common.recipes.outputs.ItemStackProvider;
import net.dries007.tfc.util.collections.IndirectHashCollection;

/** 与 Firmalife 的 drying 同型：单个物品 → 单个产物。 */
public class ExampleRoastingRecipe extends ItemRecipe
{
    public static final MapCodec<ExampleRoastingRecipe> CODEC = RecordCodecBuilder.mapCodec(i -> i.group(
        Ingredient.CODEC.fieldOf("ingredient").forGetter(c -> c.ingredient),
        ItemStackProvider.CODEC.fieldOf("result").forGetter(c -> c.result)
    ).apply(i, ExampleRoastingRecipe::new));

    public static final StreamCodec<RegistryFriendlyByteBuf, ExampleRoastingRecipe> STREAM_CODEC = StreamCodec.composite(
        Ingredient.CONTENTS_STREAM_CODEC, c -> c.ingredient,
        ItemStackProvider.STREAM_CODEC, c -> c.result,
        ExampleRoastingRecipe::new
    );

    public static final IndirectHashCollection<Item, ExampleRoastingRecipe> CACHE =
        IndirectHashCollection.createForRecipe(ExampleRoastingRecipe::getValidItems, ExRecipeTypes.ROASTING);

    public ExampleRoastingRecipe(Ingredient ingredient, ItemStackProvider result)
    {
        super(ingredient, result);
    }

    @Nullable
    public static ExampleRoastingRecipe getRecipe(ItemStack input)
    {
        return RecipeHelpers.getRecipe(CACHE, input, input.getItem());
    }

    @Override
    public RecipeSerializer<?> getSerializer()
    {
        return ExRecipeSerializers.ROASTING.get();
    }

    @Override
    public RecipeType<?> getType()
    {
        return ExRecipeTypes.ROASTING.get();
    }
}
```

要点（与 Firmalife 现有代码一致）：
- `extends ItemRecipe` 即可获得 `matches(ItemStack)` / `assemble(ItemStack)` / `getValidItems()` / `getIngredient()` / `getResult()`；
- CODEC 键名用 `ingredient` + `result`（沿用 Firmalife 惯例）；
- `STREAM_CODEC` 用 `Ingredient.CONTENTS_STREAM_CODEC` 与 `ItemStackProvider.STREAM_CODEC`；
- `CACHE` 用 `IndirectHashCollection.createForRecipe(::getValidItems, FLRecipeTypes.X)`，查询用 `RecipeHelpers.getRecipe(CACHE, stack, stack.getItem())`（**必须传两个参数**：栈用于状态谓词、物品用于哈希定位）。

#### 步骤 2：注册 `RecipeType`

```java
package com.example.examplemod.common.recipes;

import net.minecraft.core.registries.Registries;
import net.minecraft.world.item.crafting.Recipe;
import net.minecraft.world.item.crafting.RecipeType;
import net.neoforged.neoforge.registries.DeferredRegister;

import net.dries007.tfc.common.recipes.TFCRecipeTypes.Id;   // 复用 TFC 的 Id 包装器

public class ExRecipeTypes
{
    public static final DeferredRegister<RecipeType<?>> RECIPE_TYPE =
        DeferredRegister.create(Registries.RECIPE_TYPE, "examplemod");

    public static final Id<ExampleRoastingRecipe> ROASTING = register("roasting");

    private static <R extends Recipe<?>> Id<R> register(String name)
    {
        return new Id<>(RECIPE_TYPE.register(name, () -> new RecipeType<>()
        {
            @Override
            public String toString()
            {
                return name;
            }
        }));
    }
}
```

#### 步骤 3：注册 `RecipeSerializer`

```java
package com.example.examplemod.common.recipes;

import com.mojang.serialization.MapCodec;
import net.minecraft.core.registries.Registries;
import net.minecraft.network.RegistryFriendlyByteBuf;
import net.minecraft.network.codec.StreamCodec;
import net.minecraft.world.item.crafting.Recipe;
import net.minecraft.world.item.crafting.RecipeSerializer;
import net.neoforged.neoforge.registries.DeferredRegister;

import net.dries007.tfc.common.recipes.RecipeSerializerImpl;      // TFC 的通用实现
import net.dries007.tfc.common.recipes.TFCRecipeSerializers.Id;  // 复用 TFC 的 Id 包装器

public class ExRecipeSerializers
{
    public static final DeferredRegister<RecipeSerializer<?>> RECIPE_SERIALIZER =
        DeferredRegister.create(Registries.RECIPE_SERIALIZER, "examplemod");

    public static final Id<ExampleRoastingRecipe> ROASTING =
        register("roasting", ExampleRoastingRecipe.CODEC, ExampleRoastingRecipe.STREAM_CODEC);

    private static <R extends Recipe<?>> Id<R> register(String name, MapCodec<R> codec, StreamCodec<RegistryFriendlyByteBuf, R> stream)
    {
        return new Id<>(RECIPE_SERIALIZER.register(name, () -> new RecipeSerializerImpl<>(codec, stream)));
    }
}
```

并在主类构造器中挂到事件总线（顺序见第 3.4 节）：

```java
        ExRecipeTypes.RECIPE_TYPE.register(bus);
        ExRecipeSerializers.RECIPE_SERIALIZER.register(bus);
```

#### 步骤 4：在 BlockEntity 中查询配方

三种可用范式（都来自 Firmalife 实践）：

**(a) 静态 `IndirectHashCollection`（推荐，O(1) 查表）**——参考 `DryingMatBlockEntity`：

```java
    @Override
    public boolean isItemValid(int slot, ItemStack stack)
    {
        return ExampleRoastingRecipe.getRecipe(stack) != null;
    }

    @Override
    public void updateCache()   // 若你继承 SimpleItemRecipeBlockEntity，必须与它同包
    {
        cachedRecipe = ExampleRoastingRecipe.getRecipe(readStack());
        needsRecipeUpdate = false;
    }
```

**(b) `RecipeManager.getRecipeFor` + `RecipeHolder::value`**——参考 `VatBlockEntity`：

```java
        cachedRecipe = level.getRecipeManager()
            .getRecipeFor(ExRecipeTypes.ROASTING.get(), inventory, level)
            .map(RecipeHolder::value)
            .orElse(null);
```

**(c) `getAllRecipesFor` 线性扫描**——参考 `KegRecipe`（仅适合配方少或需要按序尝试的场景）：

```java
        return level.getRecipeManager().getAllRecipesFor(ExRecipeTypes.ROASTING.get()).stream()
            .filter(r -> r.value().matches(inventory))
            .findFirst()
            .orElse(null);
```

#### 步骤 5：写数据包 JSON 或加 datagen provider

**手写 JSON**（最简，路径 `src/main/resources/data/examplemod/recipe/roasting/<name>.json`）：

```json
{
  "type": "examplemod:roasting",
  "ingredient": {
    "type": "tfc:and",
    "children": [
      { "tag": "c:foods/raw_meat" },
      { "type": "tfc:not_rotten" }
    ]
  },
  "result": {
    "modifiers": [
      { "type": "tfc:copy_input" },
      { "type": "tfc:add_trait", "trait": "tfc:wood_grilled" }
    ]
  }
}
```

（上面这个形状直接对应 Firmalife 生成的 `drying/dry_fruits.json` 与 `smoking/smoke_meats.json`；`tfc:and` / `tfc:not_rotten` / `tfc:has_trait` / `tfc:lacks_trait` / `tfc:copy_input` / `tfc:add_trait` 都是 TFC 注册的 ingredient / modifier 类型。）

**加 datagen provider**（Firmalife 的做法：一个 `RecipeProvider` + 若干「配方集」接口）：

```gradle
// build.gradle.kts 中建立 data 源集（Firmalife 第 83–91 行的原样做法）
sourceSets {
    main { resources { srcDir(modDataOutput) } }
    create("data")
}
```

```java
// src/data/java/com/example/examplemod/recipes/RoastingRecipes.java
package com.example.examplemod.recipes;

import net.minecraft.world.item.crafting.Ingredient;
import net.minecraft.world.level.ItemLike;

import net.dries007.tfc.common.recipes.outputs.AddTraitModifier;
import net.dries007.tfc.common.recipes.outputs.CopyInputModifier;
import net.dries007.tfc.common.recipes.outputs.ItemStackProvider;

/** 与 Firmalife 的 DryingRecipes 同型：一个接口 = 一组同类配方。 */
public interface RoastingRecipes extends Recipes
{
    default void roastingRecipes()
    {
        roasting(nameOf(itemOf(MyItems.RAW_THING)), Ingredient.of(MyItems.RAW_THING),
            ItemStackProvider.of(CopyInputModifier.INSTANCE, AddTraitModifier.of(MyFoodTraits.TOASTED)));
    }

    private void roasting(String name, Ingredient input, ItemStackProvider output)
    {
        add(name, new ExampleRoastingRecipe(input, output));
    }
}
```

```java
// src/data/java/com/example/examplemod/DataEntryPoint.java —— 入口，仿 Firmalife 的 DataEntryPoint
@EventBusSubscriber(modid = "examplemod")
public class DataEntryPoint
{
    @SubscribeEvent
    public static void gatherData(GatherDataEvent event)
    {
        final PackOutput output = event.getGenerator().getPackOutput();
        event.getGenerator().addProvider(true,
            new BuiltinRecipes(output, event.getLookupProvider()));
    }
}

// src/data/java/com/example/examplemod/providers/BuiltinRecipes.java —— 仿 Firmalife 的 BuiltinRecipes
public class BuiltinRecipes extends RecipeProvider implements Recipes, RoastingRecipes
{
    private RecipeOutput output;
    private HolderLookup.Provider lookup;

    public BuiltinRecipes(PackOutput output, CompletableFuture<HolderLookup.Provider> registries)
    {
        super(output, registries);
    }

    @Override
    public void buildRecipes(RecipeOutput output)
    {
        this.output = output;
        roastingRecipes();
    }

    @Override
    public HolderLookup.Provider lookup()
    {
        return lookup;
    }

    @Override
    public void add(String prefix, String name, Recipe<?> recipe)
    {
        output.accept(Helpers.identifier((prefix + "/" + name).toLowerCase(Locale.ROOT)), recipe, null);
    }

    @Override
    public void remove(String... names) { /* 见 Firmalife 的 removedRecipes 实现 */ }
}
```

（Firmalife 的 `Recipes` 接口只依赖 `add(String prefix, String name, Recipe<?>)` 与 `remove(String...)`，见 `src/data/java/com/eerussianguy/firmalife/recipes/Recipes.java`；`add(String name, Recipe<?>)` 会用 `BuiltInRegistries.RECIPE_TYPE.getKey(recipe.getType()).getPath()` 自动推导前缀目录 —— **这正是 recipe type 注册名决定 JSON 目录名的机制**。）

#### 步骤 6：加 JEI 类目

```java
@JeiPlugin
public class ExJEIPlugin implements IModPlugin
{
    public static final RecipeType<RecipeHolder<ExampleRoastingRecipe>> ROASTING =
        RecipeType.createRecipeHolderType(ResourceLocation.fromNamespaceAndPath("examplemod", "roasting"));

    @Override
    public ResourceLocation getPluginUid()
    {
        return ResourceLocation.fromNamespaceAndPath("examplemod", "jei");
    }

    @Override
    public void registerCategories(IRecipeCategoryRegistration r)
    {
        r.addRecipeCategories(new RoastingCategory(ROASTING, r.getJeiHelpers().getGuiHelper()));
    }

    @Override
    public void registerRecipes(IRecipeRegistration r)
    {
        r.addRecipes(ROASTING, ClientHelpers.getLevelOrThrow().getRecipeManager()
            .getAllRecipesFor(ExRecipeTypes.ROASTING.get()));
    }

    @Override
    public void registerRecipeCatalysts(IRecipeCatalystRegistration r)
    {
        r.addRecipeCatalyst(new ItemStack(MyBlocks.ROASTER.get()), ROASTING);
    }
}
```

（`RecipeType.createRecipeHolderType`、`ClientHelpers.getLevelOrThrow()` 的用法逐字来自 `src/main/java/com/eerussianguy/firmalife/compat/jei/FLJEIPlugin.java`。）

#### 可选步骤 7：自定义产物后处理（`ItemStackModifier`）

若你的产物需要「继承输入的食物数据 / 温度 / 特性」，实现 TFC 的 `ItemStackModifier` 并自行注册（参考 `common/recipes/data/*`）。注意 TFC 的 `ItemStackModifiers.register(...)` 是 `private static`，必须自己建 `DeferredRegister`：

```java
public class ExItemStackModifiers
{
    public static final DeferredRegister<ItemStackModifierType<?>> TYPES =
        DeferredRegister.create(ItemStackModifiers.KEY, "examplemod");

    public static final Id<MyModifier> MY = register("my_modifier", MyModifier.INSTANCE);

    private static <T extends ItemStackModifier> Id<T> register(String name, T singleInstance)
    {
        return new Id<>(TYPES.register(name, () -> new ItemStackModifierType<>(
            MapCodec.unit(singleInstance), StreamCodec.unit(singleInstance))));
    }

    record Id<T extends ItemStackModifier>(DeferredHolder<ItemStackModifierType<?>, ItemStackModifierType<T>> holder)
        implements RegistryHolder<ItemStackModifierType<?>, ItemStackModifierType<T>> {}
}
```

```java
public enum MyModifier implements ItemStackModifier
{
    INSTANCE;

    @Override
    public ItemStack apply(ItemStack stack, ItemStack input, Context context)
    {
        FoodCapability.updateFoodFromPrevious(input, stack);   // TFC API：让产物继承原料的新鲜度
        return stack;
    }

    @Override
    public ItemStackModifierType<?> type()
    {
        return ExItemStackModifiers.MY.get();
    }
}
```

#### 排查清单

| 症状 | 检查点 |
|---|---|
| 配方 JSON 不加载 | JSON 的 `"type"` 必须等于 serializer 注册名（`examplemod:roasting`），不是 RecipeType 名 |
| `getRecipe(...)` 永远返回 null | `CACHE` 是否在**类型对象上**以 `static final` 初始化；`getValidItems()` 是否覆盖了所有可匹配物品；`RecipeHelpers.getRecipe` 是否传了两个参数 |
| 客户端与服务端行为不一致 | `STREAM_CODEC` 是否漏字段（服务端独有字段会被静默丢弃） |
| 产物食物立即腐烂 | 没走 `ItemStackProvider` 的 modifier 链，或没调用 `FoodCapability.setNonDecaying` / `updateFoodFromPrevious` |
| datagen 生成的路径不对 | `Recipes.add(String name, Recipe<?>)` 用 RecipeType 的注册路径作目录；想让目录名与类型名不同就重载 `add(prefix, name, recipe)` |

### 2.4 新写一个 Firmalife 风格 BlockEntity + Menu + Screen 的最小骨架

> 模板取自 `BarrelPressBlockEntity` + `BarrelPressContainer` + `BarrelPressScreen`（`src/main/java/com/eerussianguy/firmalife/common/blockentities/`、`common/container/`、`client/screen/`）。示例 modid 用 `examplemod`。

#### 2.4.1 注册 BlockEntityType

```java
public class ExBlockEntities
{
    public static final DeferredRegister<BlockEntityType<?>> BLOCK_ENTITY =
        DeferredRegister.create(Registries.BLOCK_ENTITY_TYPE, "examplemod");

    public static final Id<ExMachineBlockEntity> MACHINE = register("machine", ExMachineBlockEntity::new, ExBlocks.MACHINE);

    private static <T extends BlockEntity> Id<T> register(String name, BlockEntityType.BlockEntitySupplier<T> factory, Supplier<? extends Block> block)
    {
        return new Id<>(RegistrationHelpers.register(BLOCK_ENTITY, name, factory, block));
    }
}
```

（`Id` 来自 `net.dries007.tfc.common.blockentities.TFCBlockEntities.Id`，`RegistrationHelpers` 来自 TFC —— 与 Firmalife 完全一致。）

#### 2.4.2 BlockEntity（继承 TFC 的 `TickableInventoryBlockEntity<ItemStackHandler>`）

```java
public class ExMachineBlockEntity extends TickableInventoryBlockEntity<ItemStackHandler>
{
    public static final int SLOTS = 2;
    public static final int SLOT_INPUT = 0;
    public static final int SLOT_OUTPUT = 1;

    public static void tick(Level level, BlockPos pos, BlockState state, ExMachineBlockEntity machine)
    {
        machine.checkForLastTickSync();          // TFC 的定时同步（由基类提供）
        // ... 你的逻辑（配方判定、进度推进、完成时写入产物、markForSync()）
    }

    public ExMachineBlockEntity(BlockPos pos, BlockState state)
    {
        super(ExBlockEntities.MACHINE.get(), pos, state, defaultInventory(SLOTS), "examplemod");
    }

    @Override
    public int getSlotStackLimit(int slot)
    {
        return slot == SLOT_INPUT ? 16 : 64;
    }

    @Override
    public boolean isItemValid(int slot, ItemStack stack)
    {
        return slot == SLOT_INPUT && ExampleRoastingRecipe.getRecipe(stack) != null;
    }

    @Override
    public void saveAdditional(CompoundTag tag, HolderLookup.Provider access)
    {
        super.saveAdditional(tag, access);
        // tag.putLong("progress", progress);
    }

    @Override
    public void loadAdditional(CompoundTag tag, HolderLookup.Provider access)
    {
        super.loadAdditional(tag, access);
        // progress = tag.getLong("progress");
    }

    @Override
    public void setAndUpdateSlots(int slot)
    {
        super.setAndUpdateSlots(slot);
        // 槽位变化 → 重新判定配方
    }

    @Nullable
    @Override
    public AbstractContainerMenu createMenu(int windowId, Inventory inv, Player player)
    {
        return ExMachineContainer.create(this, inv, windowId);
    }
}
```

同时别忘了在方块里打开界面（Firmalife 的做法，逐字来自 `common/blocks/BarrelPressBlock.java`）：

```java
            else if (player instanceof ServerPlayer server)
            {
                server.openMenu(press, pos);
            }
```

#### 2.4.3 Container（继承 TFC 的 `BlockEntityContainer<BE>`）

```java
public class ExMachineContainer extends BlockEntityContainer<ExMachineBlockEntity>
{
    public static ExMachineContainer create(ExMachineBlockEntity machine, Inventory playerInventory, int windowId)
    {
        return new ExMachineContainer(machine, playerInventory, windowId).init(playerInventory);
    }

    public ExMachineContainer(ExMachineBlockEntity blockEntity, Inventory playerInv, int windowId)
    {
        super(ExMenuTypes.MACHINE.get(), windowId, blockEntity);
    }

    @Override
    protected void addContainerSlots()
    {
        final IItemHandler inventory = Helpers.getCapability(BlockCapabilities.ITEM, blockEntity);
        if (inventory != null)
        {
            addSlot(new CallbackSlot(blockEntity, inventory, ExMachineBlockEntity.SLOT_INPUT, 56, 35));
            addSlot(new CallbackSlot(blockEntity, inventory, ExMachineBlockEntity.SLOT_OUTPUT, 116, 35));
        }
    }

    @Override
    protected boolean moveStack(ItemStack stack, int slotIndex)
    {
        return switch (typeOf(slotIndex))
            {
                case MAIN_INVENTORY, HOTBAR -> !moveItemStackTo(stack, 0, ExMachineBlockEntity.SLOTS, false);
                case CONTAINER -> !moveItemStackTo(stack, containerSlots, slots.size(), false);
            };
    }
}
```

（`CallbackSlot`、`BlockEntityContainer.init(Inventory)`、`typeOf(int)`、`moveItemStackTo`、`containerSlots`/`slots` 均来自 TFC 的 `net.dries007.tfc.common.container.*`。）

若需要按钮（如 Firmalife 的 Keg 密封按钮），实现 TFC 的 `ButtonHandlerContainer#onButtonPress(int, CompoundTag)` 并配一个客户端 `Button`：

```java
public class ExMachineContainer extends BlockEntityContainer<ExMachineBlockEntity> implements ButtonHandlerContainer
{
    @Override
    public void onButtonPress(int buttonID, @Nullable CompoundTag extraNBT)
    {
        // 处理按钮
    }
}
```

#### 2.4.4 MenuType 注册

```java
public class ExMenuTypes
{
    public static final DeferredRegister<MenuType<?>> MENU = DeferredRegister.create(Registries.MENU, "examplemod");

    public static final Id<ExMachineContainer> MACHINE =
        new Id<>(RegistrationHelpers.registerBlockEntityContainer(MENU, "machine", ExBlockEntities.MACHINE, ExMachineContainer::create));
}
```

（**必须**用 TFC 的 `RegistrationHelpers.registerBlockEntityContainer`，因为它把 `BlockEntityContainer.Factory` 接到 `MenuType` 上；Firmalife 全树没有使用 NeoForge 原生的 `IMenuTypeExtension`。）

#### 2.4.5 Screen（继承 TFC 的 `BlockEntityScreen<BE, C>`）

```java
public class ExMachineScreen extends BlockEntityScreen<ExMachineBlockEntity, ExMachineContainer>
{
    private static final ResourceLocation TEXTURE =
        ResourceLocation.fromNamespaceAndPath("examplemod", "textures/gui/machine.png");

    public ExMachineScreen(ExMachineContainer container, Inventory playerInventory, Component name)
    {
        super(container, playerInventory, name, TEXTURE);
    }

    @Override
    protected void renderLabels(GuiGraphics graphics, int mouseX, int mouseY)
    {
        super.renderLabels(graphics, mouseX, mouseY);
        // 额外的文字/进度显示（BarrelPressScreen 只覆写这一个方法）
    }
}
```

若需要背景内容（进度条、流体面），覆写 `renderBg`（参考 `KegScreen` 用 `RenderHelpers.getAndBindFluidSprite` / `fillAreaWithSprite` 画流体）。

#### 2.4.6 Screen 注册（客户端）

```java
    public static void onRegisterScreens(RegisterMenuScreensEvent event)
    {
        event.register(ExMenuTypes.MACHINE.get(), ExMachineScreen::new);
    }
```

（注册时机与位置见第 3.4 节；`RegisterMenuScreensEvent` 是 NeoForge 的 mod 事件总线事件，Firmalife 在 `FLClientEvents.init(bus)` 里 `bus.addListener(FLClientEvents::onMenuRegister)`。）

#### 2.4.7 能力注册（可选，但几乎必需）

```java
    public static void registerCapabilities(RegisterCapabilitiesEvent event)
    {
        event.registerBlockEntity(BlockCapabilities.ITEM, ExBlockEntities.MACHINE.get(), InventoryBlockEntity::getSidedInventory);
    }
```

（**注意**：Firmalife 的写法是 `InventoryBlockEntity::getSidedInventory` 方法引用 —— 见 `common/capabilities/FLComponents.java` 第 95–98 行。第三方也必须用方块实体类型对象调用 `.get()`，不能传 `DeferredHolder`。）

---

## 3. 第三方附属模组开发要点

### 3.1 需要声明的依赖（`src/main/templates/META-INF/neoforge.mods.toml` 原文）

```toml
# Loader metadata
modLoader = "javafml"
loaderVersion = "[4,)"
license = "MIT"
issueTrackerURL = "https://github.com/eerussianguy/firmalife/issues"

# TFC
[[mods]]
    modId = "${modId}"
    version = "${modVersion}"
    displayName = "Firmalife"
    credits = "EERussianguy, Charnuz, Dodo, Indi, Peffern, Lumintorious"
    authors = "EERussianguy, Charnuz, Dodo, Indi, Peffern, Lumintorious"
    description = '''A cooking and farming addon for TFC.'''

# Dependencies
[[dependencies.firmalife]]
    modId = "tfc"
    type = "required"
    versionRange = "${tfcVersionRange}"
    ordering = "AFTER"
    side = "BOTH"
    [dependencies.firmalife.mc-publish]
        ignore=false
        modrinth="terrafirmacraft"
        curseforge="terrafirmacraft"

[[dependencies.firmalife]]
    modId = "patchouli"
    type = "required"
    versionRange = "${patchouliVersionRange}"
    ordering = "NONE"
    side = "BOTH"

[[dependencies.firmalife]]
    modId = "jei"
    type = "optional"
    versionRange = "${jeiVersionRange}"
    ordering = "NONE"
    side = "CLIENT"

[[dependencies.firmalife]]
    modId = "neoforge"
    type = "required"
    versionRange = "${neoForgeVersionRange}"
    ordering = "AFTER"
    side = "BOTH"

[[dependencies.firmalife]]
    modId = "minecraft"
    type = "required"
    versionRange = "${minecraftVersionRange}"
    ordering = "AFTER"
    side = "BOTH"

[[mixins]]
    config = "${modId}.mixins.json"
```

关键点：

- **TFC 必须 `required` + `ordering = "AFTER"`**（你依赖它的类与注册表，必须后加载）。
- **patchouli 是 `required`**（Firmalife 直接 `import vazkii.patchouli.api.*` 且用完整 jar 编译，见 `build.gradle.kts` 第 150–153 行的注释「We need to compile against the full JAR, not just the API, because we do some egregious hacks.」）。若你的 mod 不修改 Patchouli 内部行为，可以只标 `optional` 并做类隔离。
- **jei 是 `optional` + `side = "CLIENT"`**（因为 JEI 插件是纯客户端）。
- 版本范围由 Gradle 变量注入（`${...}`），不要写死。
- `[[mixins]] config = "${modId}.mixins.json"` 是 mixin 配置的声明位置（NeoForge 1.21 用 `neoforge.mods.toml` 而非 manifest 声明 mixin）。

### 3.2 构建脚本写法（`build.gradle.kts` 原文摘录）

```gradle
plugins {
    id("net.neoforged.moddev") version "2.0.107"
}

// Toolchain versions
val minecraftVersion: String = "1.21.1"
val neoForgeVersion: String = "21.1.234"
val parchmentVersion: String = "2024.11.17"
val parchmentMinecraftVersion: String = "1.21.1"

// Dependency versions
val emiVersion: String = "1.1.22+1.21.1"
val jeiVersion: String = "19.25.0.321"
val patchouliVersion: String = "1.21.1-92-NEOFORGE"
val tfcVersion: String = "4.2.8"

val modId: String = "firmalife"
val modVersion: String = System.getenv("VERSION") ?: "0.0.0-indev"
val modJavaVersion: String = "21"
val modIsInCI: Boolean = !modVersion.contains("-indev")
val modDataOutput: String = "src/generated/resources"
```

版本范围变量的注入（第 28–42 行）：

```gradle
val generateModMetadata = tasks.register<ProcessResources>("generateModMetadata") {
    val modReplacementProperties = mapOf(
        "modId" to modId,
        "modVersion" to modVersion,
        "minecraftVersionRange" to "[$minecraftVersion]",
        "neoForgeVersionRange" to "[$neoForgeVersion,)",
        "tfcVersionRange" to "[$tfcVersion,)",
        "patchouliVersionRange" to "[$patchouliVersion,)",
        "jeiVersionRange" to "[$jeiVersion,)"
    )
    inputs.properties(modReplacementProperties)
    expand(modReplacementProperties)
    from("src/main/templates")
    into(layout.buildDirectory.dir("generated/sources/modMetadata"))
}
```

parchment 映射（第 97–100 行）：

```gradle
    parchment {
        minecraftVersion.set(parchmentMinecraftVersion)
        mappingsVersion.set(parchmentVersion)
    }
```

TFC 的坐标（**curse.maven**，第 156–157 行）：

```gradle
    // TFC
    implementation(group = "curse.maven", name = "terrafirmacraft-302973", version = "8666972")
    "dataImplementation"(group = "curse.maven", name = "terrafirmacraft-302973", version = "8666972")
```

其它依赖（第 140–168 行）：

```gradle
dependencies {
    // EMI
    compileOnly("dev.emi:emi-neoforge:${emiVersion}:api")

    // JEI
    compileOnly("mezz.jei:jei-${minecraftVersion}-common-api:${jeiVersion}")
    compileOnly("mezz.jei:jei-${minecraftVersion}-neoforge-api:${jeiVersion}")
    runtimeOnly("mezz.jei:jei-${minecraftVersion}-neoforge:${jeiVersion}")

    // Patchouli
    // We need to compile against the full JAR, not just the API, because we do some egregious hacks.
    implementation("vazkii.patchouli:Patchouli:$patchouliVersion")
    "dataImplementation"("vazkii.patchouli:Patchouli:$patchouliVersion")

    // TFC
    implementation(group = "curse.maven", name = "terrafirmacraft-302973", version = "8666972")
    "dataImplementation"(group = "curse.maven", name = "terrafirmacraft-302973", version = "8666972")

    // Jade / The One Probe
    implementation(group = "curse.maven", name = "jade-324717", version = "6853386")
    compileOnly(group = "mcjty.theoneprobe", name = "theoneprobe", version = "1.21_neo-12.0.4-6")

    // ModernFix
    runtimeOnly(group = "curse.maven", name = "modernfix-790626", version = "6766126")

    // Data
    "dataImplementation"(sourceSets["main"].output)
}
```

私有仓库（`exclusiveContent`）声明（第 58–81 行）：

```gradle
repositories {
    mavenCentral()
    mavenLocal()
    exclusiveContent {
        forRepository { maven("https://maven.terraformersmc.com/") }
        filter { includeGroup("dev.emi") }
    }
    exclusiveContent {
        forRepository { maven("https://maven.blamejared.com/") }
        filter { includeGroup("mezz.jei") }
    }
    exclusiveContent {
        forRepository { maven("https://maven.k-4u.nl/") }
        filter { includeGroup("mcjty.theoneprobe") }
    }
    exclusiveContent {
        forRepository { maven("https://maven.blamejared.com") }
        filter { includeGroup("vazkii.patchouli") }
    }
    exclusiveContent {
        forRepository { maven("https://www.cursemaven.com") }
        filter { includeGroup("curse.maven") }
    }
}
```

运行配置（第 102–122 行）—— `data` run 的 `--existing` / `--existing-mod` 参数值得照抄：

```gradle
        register("data") {
            data()
            sourceSet = sourceSets["data"]
            programArguments.addAll("--all", "--mod", modId, "--output", file(modDataOutput).absolutePath, "--existing",  file("src/main/resources").absolutePath, "--existing-mod", "tfc")
        }
```

注意 `--existing-mod tfc`：让 datagen 能读取 TFC 的既有数据（例如把内容加进 TFC 的标签）。

### 3.3 `@Mod` 构造参数注入与 `IEventBus` 的来源

```java
@Mod(FirmaLife.MOD_ID)
public class FirmaLife
{
    public static final String MOD_ID = "firmalife";
    public static final Logger LOGGER = LogUtils.getLogger();

    public FirmaLife(ModContainer mod, IEventBus bus)
    {
        ...
    }
}
```

- `@Mod(FirmaLife.MOD_ID)`：字符串常量必须是编译期常量（因此 `MOD_ID` 是 `public static final String`）。
- **`ModContainer` 参数**：NeoForge 注入当前 mod 的容器，用于 `mod.registerConfig(ModConfig.Type.SERVER, FLConfig.SERVER.spec())`（第 78 行）。
- **`IEventBus` 参数**：NeoForge 注入 **mod 专用事件总线（mod event bus）**，用于 `DeferredRegister.register(bus)`、`bus.addListener(...)`。它**不等于** `NeoForge.EVENT_BUS`；后者是游戏事件总线，Firmalife 在 `FLForgeEvents.init()` 中单独获取：

```java
    public static void init()
    {
        final IEventBus bus = NeoForge.EVENT_BUS;

        bus.addListener(FLForgeEvents::onFireStart);
        ...
    }
```

构造参数顺序可自定义（Firmalife 用 `(ModContainer, IEventBus)`；NeoForge 也支持 `(IEventBus, ModContainer)` 等排列，按参数类型注入而非位置）。

### 3.4 注册时序注意点

以下时序**全部以 `FirmaLife.java` 的真实顺序为准**：

```java
    public FirmaLife(ModContainer mod, IEventBus bus)
    {
        FLItems.ITEM.register(bus);
        FLBlocks.BLOCK.register(bus);
        FLFluids.FLUID.register(bus);
        FLFluids.FLUID_TYPES.register(bus);
        FLBlockEntities.BLOCK_ENTITY.register(bus);
        FLRecipeTypes.RECIPE_TYPE.register(bus);
        FLRecipeTypes.POT_OUTPUT_TYPE.register(bus);
        FLRecipeSerializers.RECIPE_SERIALIZER.register(bus);
        FLItemStackModifiers.TYPES.register(bus);
        FLMenuTypes.MENU.register(bus);
        FLEffects.EFFECT.register(bus);
        FLEntities.ENTITY.register(bus);
        FLParticles.PARTICLE_TYPE.register(bus);
        FLFeatures.FEATURE.register(bus);
        FLSounds.SOUND.register(bus);
        FLCreativeTabs.CREATIVE_TAB.register(bus);
        FLAdvancements.TRIGGER_TYPE.register(bus);
        FLArmorMaterials.ARMOR_MATERIAL.register(bus);
        FLComponents.COMPONENT.register(bus);
        FLPOIs.TYPES.register(bus);
        FLLoot.registerAll(bus);

        mod.registerConfig(ModConfig.Type.SERVER, FLConfig.SERVER.spec());

        FLFoodTraits.TRAITS.register(bus);
        FLDataManagers.init();

        bus.addListener(this::setup);
        bus.addListener(FLComponents::register);
        bus.addListener(FLCreativeTabs::setAllTabContentAsNonDecaying);

        FLEvents.init(bus);
        FLForgeEvents.init();
        if (FMLEnvironment.dist == Dist.CLIENT)
        {
            FLClientEvents.init(bus);
            FLClientForgeEvents.init();
        }

        if (THE_ONE_PROBE)
            TheOneProbeIntegration.init(bus);

    }
```

要点：

1. **所有 `DeferredRegister.register(bus)` 都必须在构造器内完成**（`DeferredRegister` 只在 mod 构造阶段可注册到总线；之后再 `register` 会报错/静默失效）。
2. **`FLDataManagers.init()` 在 `FLFoodTraits.TRAITS.register(bus)` 之后调用**（第 80–81 行）。DataManager 的注册是把「自建 DataManager 实例」登记到 TFC 的 `DataManagers.MANAGERS`（同样是 `DeferredRegister`），因此必须在 `MANAGERS` 尚未被冻结时完成。**如果要加自己的 DataManager，请放在 `FLDataManagers.init()` 之前**（即紧跟 `TRAITS.register(bus)` 的同一段内）。
3. **能力注册用 `bus.addListener(...)`**，而不是 `DeferredRegister`：`bus.addListener(FLComponents::register)`（第 84 行），对应 `public static void register(RegisterCapabilitiesEvent event)`。
4. **`FMLCommonSetupEvent` 内的原版注册用 `enqueueWork`**（第 100–108 行），因为原版注册表不是线程安全的：

```java
    public void setup(FMLCommonSetupEvent event)
    {
        // Vanilla registries are not thread safe
        event.enqueueWork(() -> {
            FLInteractionManager.init();
            FLBlocks.registerFlowerPotFlowers();
        });
        FLPatchouliIntegration.registerMultiBlocks();
    }
```

5. **客户端专有注册放在 dist 分支**：`FLClientEvents.init(bus)` 内 `bus.addListener(FLClientEvents::onMenuRegister)` 处理 `RegisterMenuScreensEvent`，另外还有 `EntityRenderersEvent.RegisterRenderers`、`ModelEvent.RegisterAdditional`、`ModelEvent.RegisterGeometryLoaders`、`RegisterColorHandlersEvent.Item`、`RegisterParticleProvidersEvent`、`RegisterClientExtensionsEvent`（`src/main/java/com/eerussianguy/firmalife/client/FLClientEvents.java` 第 96–108 行）。
6. **`AddPackFindersEvent` / `EntityAttributeCreationEvent`**：本次调查在 Firmalife 中**未发现**对这两个事件的使用（grep 无命中）。若第三方需要，它们是 NeoForge 的注册类事件，应同样通过 `bus.addListener(...)` 挂在 **mod 事件总线**上。检查位置：全仓库 grep `AddPackFindersEvent`、`EntityAttributeCreationEvent`。
7. **`FLLoot.registerAll(bus)`** 展示了一种「把多个 `DeferredRegister` 集中注册」的写法（`common/misc/FLLoot.java`）：

```java
    public static void registerAll(IEventBus bus)
    {
        CONDITION.register(bus);
        MODIFIER_SERIALIZER.register(bus);
    }
```

### 3.5 类加载陷阱（哪些静态引用会在错误时机触发 TFC 类加载）

以下按风险从高到低排列。**标「机制说明」的条目是基于代码结构 + JVM 类加载语义的推断**，未在运行期复现；标「事实」的条目在源码中可直接读到。

#### ① 事实：`FirmaLife` 类在极早时机被初始化（因为它被 `import static` 引用）

`src/main/java/com/eerussianguy/firmalife/common/FLHelpers.java` 第 73 行：

```java
import static com.eerussianguy.firmalife.FirmaLife.*;
```

这使任何调用 `FLHelpers.identifier(...)` 的类都会触发 `FirmaLife` 的**类初始化**，进而求值：

```java
    public static final boolean JEI = ModList.get().isLoaded("jei");
    public static final boolean EMI = ModList.get().isLoaded("emi");
    public static final boolean JADE = ModList.get().isLoaded("jade");
    public static final boolean THE_ONE_PROBE = ModList.get().isLoaded("theoneprobe");
```

**风险**：`ModList.get()` 在 mod 加载早期是可用的，但这些常量会在**任何 mod 的任何代码第一次触摸 `FirmaLife` 时**被求值。若第三方在自己的 `@Mod` 构造器之前、或在不该探测 mod 的时机（例如 mixin 的静态初始化、数据生成进程、专用服务器早期）触发该类初始化，就会连带执行四次 `ModList` 查询。**建议**：第三方不要 `import static` 别人的主类；只静态引用自己 mod 的 `MOD_ID` 常量，并把自己的 `ModList.get().isLoaded(...)` 探测收敛到单点。

#### ② 事实 + 机制说明：`THE_ONE_PROBE` 布尔守卫保护的是「实现 mcjty 接口的类」

```java
        if (THE_ONE_PROBE)
            TheOneProbeIntegration.init(bus);
```

而 `TheOneProbeIntegration` 的声明是：

```java
public class TheOneProbeIntegration implements Function<ITheOneProbe, Void>
```

`mcjty.theoneprobe` 在 `build.gradle.kts` 中只是 **compileOnly**（第 161 行），运行期可能完全不存在。

**机制说明**：JVM 在**加载** `TheOneProbeIntegration` 时会解析其超接口 `Function`（`java.util.function`，安全）与方法签名中引用的 `ITheOneProbe`（`mcjty.theoneprobe.*`，**缺失时会抛 `NoClassDefFoundError`**）。因此：
- 该类的**首次主动使用**必须被 `THE_ONE_PROBE` 守卫（Firmalife 做到了，而且 `init(bus)` 内部用 `InterModComms.sendTo` 传递 `TheOneProbeIntegration::new` 方法引用，同样只在守卫内执行）；
- **不要**在其它公共类里静态引用 `TheOneProbeIntegration`（例如写成 `private static final Function<...> TOP = TheOneProbeIntegration::new;`，会在类初始化时直接崩）；
- `FirmaLife` 里只保留 `import` 语句是安全的：`import` 不触发类加载。

同样的模式适用于 **Jade**（`JadeIntegration implements IWailaPlugin`、引用 `snownee.jade.*`）。区别是 Jade 在 Gradle 里是 `implementation`，所以运行期一定存在——但若第三方把它改成 `compileOnly`，就必须额外加守卫。

#### ③ 机制说明：`FMLEnvironment.dist == Dist.CLIENT` 分支的意义

```java
        if (FMLEnvironment.dist == Dist.CLIENT)
        {
            FLClientEvents.init(bus);
            FLClientForgeEvents.init();
        }
```

`FLClientEvents` 与 `FLClientForgeEvents` 引用 `net.minecraft.client.*`（例如 `ItemBlockRenderTypes`、`ItemProperties`、`Minecraft`）与 `net.neoforged.neoforge.client.*`。在**专用服务器**上这些类不存在，一旦被加载就会 `NoClassDefFoundError`。

**机制说明**：
- 把客户端代码放在 dist 分支内、且用**方法引用/直接调用**（而非静态字段初始化），可以保证专用服务器不加载它们（JVM 惰性解析：不执行到的 `invokestatic` 不会解析目标类）；
- **但**一个常见错误是把客户端对象放进 `static final` 字段（`private static final Foo F = new ClientOnlyThing();`），那会在类初始化时立刻加载 —— 第三方若把客户端注册也写进公共注册类，必须避免这种写法；
- Firmalife 的划分方式是：`client` 包整体只在 dist==CLIENT 时初始化，`compat/tooltip/JadeIntegration` 则是**客户端专用**的 Jade 插件类（Jade 只会在客户端侧加载它，同样属于「由第三方 mod 的加载时机决定」的类）。

#### ④ 事实：`EnqueueWork` 与「原版注册表非线程安全」

见第 3.4 节第 4 点。若第三方在 `FMLCommonSetupEvent` 里直接调用 `FlowerPotBlock#addPlant`、`ItemProperties#register` 之类**没有加锁的原版注册表 API**，可能与其他 mod 竞争导致丢失条目。Firmalife 的选择是把它们放进 `event.enqueueWork(...)`。

#### ⑤ 事实：mixin 的 `refmap` 与 `required: true`

`src/main/resources/firmalife.mixins.json` 用了 `"required": true` + `"refmap": "firmalife.refmap.json"` + `"injectors": { "defaultRequire": 1 }`：
- `required: true` 意味着 mixin 应用失败会**直接崩溃**而不是告警；
- `defaultRequire: 1` 意味着**每个 `@Inject` 至少要命中一次**，否则崩溃。因此像 `BarrelRackMixin`（注入 TFC 的 `BarrelRackBlock#canBeReplaced`）这类注入点一旦在 TFC 更新中改名，会导致启动崩溃——第三方做同类注入时需明确接受这个代价，或把 `require` 降为 0 并自行检测。

#### ⑥ 事实：`ServerConfigMixin` 直接改写 TFC 的 final 配置字段

```java
    @Shadow(remap = false)
    @Mutable
    @Final
    public Supplier<Boolean> enablePumpkinCarving;
```

- `remap = false` 是**必须的**：TFC 的 `ServerConfig` 不在原版混淆映射内，若不写 `remap = false`，mixin 会按混淆名去找字段而失败；
- 该 mixin 在 TFC 的构造器 TAIL 处把配置项**强制改成常量 `false`**。第三方若也想改 TFC 配置，注意这是「无条件覆盖」，会与用户的配置文件设置冲突（Firmalife 显然是有意为之：它把南瓜雕刻功能搬到了自己这边）。

### 3.6 本文的「未能核实」清单（含检查位置）

| 项 | 检查位置 | 原因 |
|---|---|---|
| TFC 全部类的方法体/默认语义 | `moddev/src-ref/TerraFirmaCraft/` | 该目录只有 `.git`、无工作树，`git` 报 `HEAD` 损坏；只有 jar 可 javap |
| `RegistrationHelpers.registerBlockEntityContainer` / `BlockEntityContainer` / `BlockEntityContainer.Factory` / `BlockEntityScreen` 的实现 | 同上 | 同上 |
| `RegistryOre` 接口是否存在 | jar `net/dries007/tfc/util/registry/` 目录列举 | 该目录无此类；可能与其它 registry 接口混记 |
| `net.dries007.tfc.common.recipes.inventory.ItemStackInventory` | jar 全量类名子串搜索 | 命中 0；`recipes/` 下只有 `ingredients`、`input`、`outputs` |
| `net.dries007.tfc.util.Env` | jar 全量类名含 `Env` 搜索 | 只命中 `EnvironmentHelpers` |
| `Metal$Tier` | javap 尝试 + jar 内部类列举 | 不存在；工具等级在 `net.dries007.tfc.common.TFCTiers` / `LevelTier` |
| Patchouli 的「同名文件覆盖 + 多包合并」实现 | `Patchouli-1.21.1-93-NEOFORGE.jar`（只 javap 了 `BookContentResourceListenerLoader`、`ClientBookRegistry`） | 未反编译方法体；覆盖机制为基于资源包语义的推断 |
| Jade / JEI 的插件发现机制 | Firmalife jar 与 TFC jar 的 `jar tf`（无 descriptor 文件） | 未反编译 Jade/JEI 自身的扫描逻辑 |
| `AddPackFindersEvent` / `EntityAttributeCreationEvent` 在 Firmalife 中的使用 | 全仓库 grep | 无命中（据任务清单提及，但本项目未使用） |
| 部分子类的 override 集合 | `FoodShelfBlockEntity`、`SprinklerBlockEntity`、`OvenChimneyBlock`、`OvenHopperBlock`、`GrapeGroundPlantOnStringBlock`、`VatBlockEntity`、`StovetopPotBlockEntity`、`StovetopGrillBlockEntity`、`HydroponicPlanterBlockEntity`、`InsulatedOvenTopBlock`、`InsulatedOvenBottomBlock` | 只核实了声明与继承关系，未逐行读取全文 |
| `FLClimateRanges` 的 `register(...)` 私有实现体 | `src/main/java/com/eerussianguy/firmalife/common/util/FLClimateRanges.java` | 只核实了 `DataManager.Reference<ClimateRange>` 作为字段类型的使用方式 |

---

## 4. 一页速查（给第三方开发者的最短路径）

**要做的事 → 用 Firmalife/TFC 的哪个东西：**

| 需求 | 用 |
|---|---|
| 注册方块 + 方块物品 | `RegistrationHelpers.registerBlock(BLOCK_DR, ITEM_DR, name, supplier, blockItemFactory)`；`blockItemFactory` 传 `null` = 不注册物品 |
| 注册方块实体 | `RegistrationHelpers.register(BLOCK_ENTITY_DR, name, factory, block)` 或 `(..., Stream<Supplier<Block>>)` |
| 注册 MenuType | `RegistrationHelpers.registerBlockEntityContainer(MENU_DR, name, beTypeSupplier, factory)` |
| 注册流体 | `RegistrationHelpers.registerFluid(...)` |
| 批量按枚举生成内容 | `Helpers.mapOf(EnumClass.class, fn)` / `Helpers.mapOf(EnumClass.class, predicate, fn)` |
| 方块属性 | `ExtendedProperties.of()...</*>`；方块基类 `ExtendedBlock` |
| 配方基类 | 物品→物品：`ItemRecipe`；方块→方块：`BlockRecipe`；自定义容器：`ISimpleRecipe<C>`；无输入：`INoopInputRecipe` |
| 配方序列化器 | `RecipeSerializerImpl<>(mapCodec, streamCodec)` |
| 配方快速查询索引 | `IndirectHashCollection.createForRecipe(Type::getValidItems, RECIPE_TYPE)` + `RecipeHelpers.getRecipe(CACHE, input, key)` |
| 配方产物后处理 | `ItemStackProvider` + `ItemStackModifier`/`ItemStackModifiers` 内置 modifier（`CopyInputModifier`、`AddTraitModifier`、`CopyFoodModifier` 等） |
| datapack 数据表 | `new DataManager<>(identifier, CODEC, STREAM_CODEC)` + 自建 `DeferredRegister` 注册进 TFC 的 `DataManagers.MANAGERS` |
| 食物特性 | `DeferredRegister.create(FoodTraits.KEY, MOD_ID)` + `new FoodTrait(mod, translationKey)` |
| 物品数据组件 | 自建 `DeferredRegister<DataComponentType<?>>`（或复用 TFC 的 `TFCComponents.BOWL/FLUID` 等） |
| 方块实体基类 | TFC 的 `InventoryBlockEntity` / `TickableInventoryBlockEntity`；Firmalife 的 `ApplianceBlockEntity`（可继承） |
| 容器/界面 | TFC 的 `BlockEntityContainer` + `BlockEntityScreen`；Firmalife 的 `BarrelPressContainer`/`BarrelPressScreen` 作模板 |
| 提示信息（Jade/TOP） | 定义 TFC 的 `BlockEntityTooltip` 常量 + 分别实现 `IWailaPlugin` 与 `IProbeInfoProvider`（参考 `compat/tooltip/`） |
| JEI | `@JeiPlugin implements IModPlugin` + `RecipeType.createRecipeHolderType(...)` + `ClientHelpers.getLevelOrThrow()` |
| Patchouli 结构预览 | `PatchouliAPI.get().makeMultiblock(...)` + `predicateMatcher(..., 你的判据谓词)` |

**最容易踩的三个坑（本文实测结论）**：

1. `SimpleItemRecipeBlockEntity` / `BoilingBlockEntity` 因**包私有抽象方法**无法被包外继承（2.2.1）。
2. `press` 配方类型已注册但**没有任何内置配方 JSON**，也不在 datagen 中（1.13.2）。
3. Firmalife 的 `DataManager` 必须在 `FLDataManagers.init()` 之前注册；`DeferredRegister.register(bus)` 必须全部在 `@Mod` 构造器内完成（3.4）。
