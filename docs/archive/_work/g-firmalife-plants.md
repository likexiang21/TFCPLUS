# Firmalife 3.0.14 植物系统在 TFC 之上的实现方式（可照抄技术文档）

> 目标读者：准备为 TFC（4.2.10 / NeoForge 1.21.1）编写附属模组、需要新增「作物 / 果树 / 灌木 / 藤蔓 / 大型热带植物」的开发者。
> 本文只描述**已在源码中核实过**的事实，每条结论都附 `文件:行号` 来源。凡无法核实的，明确标注「未能核实」。
>
> 来源缩写约定：
> - `F/<路径>` = `moddev/src-ref/Firmalife/src/main/java/com/eerussianguy/firmalife/<路径>`
> - `R/<路径>` = `moddev/src-ref/Firmalife/src/main/resources/<路径>`
> - `T/<路径>` = `moddev/src-ref/TFC-decompiled/net/dries007/tfc/<路径>`
> - `JAR/<路径>` = 本机发行包 `mods/Firmalife-NeoForge-1.21.1-3.0.14.jar` 内的条目（用 PowerShell `System.IO.Compression.ZipFile` 实测读取）

---

## 0. 一页速览（结论先行）

| 问题 | 结论 | 关键证据 |
| --- | --- | --- |
| Firmalife 有没有扩展 TFC 的 `Crop` 枚举？ | **没有**。它一个 TFC 式作物都没加 | `F/` 全库仅两处引用 `net.dries007.tfc.common.blocks.crop`：`WildCropBlock`（`F/common/blocks/FLBlocks.java:106`）与 `CropHelpers`（`F/common/blocks/greenhouse/LargePlanterBlock.java:39`） |
| Firmalife 有没有扩展 `FruitBlocks.Tree` / `StationaryBush` / `SpreadingBush` 枚举？ | **没有**。三个都是 `enum`，不可扩展 | `T/common/blocks/plant/fruit/FruitBlocks.java:147`、`:205`、`:230` |
| 它怎么加新植物？ | **自建枚举 + 自建 Map（用 TFC 的 `Helpers.mapOf`）+ 继承 TFC 的具体方块类 + 自建 BlockEntityType** | `F/common/blocks/plant/FLFruitBlocks.java:30`、`F/common/blocks/FLBlocks.java:212`、`F/common/blockentities/FLBlockEntities.java:26` |
| 是否复用了 TFC 的 `CropBlockEntity`？ | **完全没有**（Firmalife 无任何 `CropBlockEntity` 引用）。葡萄的生长状态保存在自建的 `GrapePlantBlockEntity` | `F/common/blockentities/GrapePlantBlockEntity.java:32` |
| 是否复用了 `SeasonalPlantBlock`？ | **是，但是间接的**：通过继承 `FruitTreeLeavesBlock` / 直接 new `StationaryBerryBushBlock`，没有直接继承 `SeasonalPlantBlock` | `F/common/blocks/plant/FLFruitTreeLeavesBlock.java:18`、`F/common/blocks/plant/FLFruitBlocks.java:88` |
| 是否复用了 `ClimateRange`？ | **是，完全复用**，用 `ClimateRange.MANAGER.getReference(...)`，数据包路径 `data/<ns>/tfc/climate_range/...` | `F/common/util/FLClimateRanges.java:15-22`、`T/util/data/DataManager.java:76` |
| 是否复用了 `PlantableInfo`？ | 只把它当**只读接口**读取 TFC 侧数据用于去重显示；Firmalife 自己**没有实现**它，而是自建 `Plantable` 数据管理器 + `ItemTooltipEvent` | `F/common/util/Plantable.java:128-174`、`F/client/FLClientForgeEvents.java:64-73` |
| 是否复用了 `Lifecycle` 与 `TFCBlockStateProperties.LIFECYCLE`？ | **是，直接复用**（葡萄、果树、灌木都用了） | `F/common/blocks/plant/GrapeStringWithPlantBlock.java:38` |
| 食物/营养怎么定义？ | `data/firmalife/tfc/food/*.json`（TFC 的 `FoodCapability.MANAGER`），字段是 TFC 的 `FoodData` | `T/util/data/DataManagers.java:60`、`T/common/component/food/FoodData.java:33,48` |
| 加了哪些植物内容？ | 8 种草药、2 种果树（fig/cocoa）、2 种灌木（pineapple/nightshade）、1 套葡萄系统（红/白，野生+栽培+温室）、把 TFC 香蕉接入温室 | 见 §1 |

---

## 1. Firmalife 新增的植物类内容（完整清单）

### 1.1 总表

| 类别 | 内容 | 方块类 | 物品类 | 注册位置 | 归属的 TFC 机制 |
| --- | --- | --- | --- | --- | --- |
| 草药（8） | basil, bay_laurel, cardamom, cilantro, cumin, oregano, pimento, vanilla | TFC `PlantBlock`（`PlantBlock.create(FLPlant.HERB, ...)` 返回的匿名子类） | 普通 `BlockItem` | `F/common/blocks/Herb.java:5-12`（枚举）、`F/common/blocks/FLBlocks.java:209-210`（方块） | TFC `net.dries007.tfc.util.registry.RegistryPlant`（Firmalife 自建实现 `FLPlant`） |
| 果树（2） | cocoa, fig | `FLFruitTreeSaplingBlock`（继承 TFC `FruitTreeSaplingBlock`）、`FruitTreeBranchBlock`（直接 new TFC 的）、`FLGrowingFruitTreeBranchBlock`（继承）、`FLFruitTreeLeavesBlock`（继承） | 树苗 `BlockItem`、果子 `Item` | `F/common/blocks/plant/FLFruitBlocks.java:30-70`、`F/common/blocks/FLBlocks.java:212-216` | TFC 果树链（`SeasonalPlantBlock` → `FruitTreeLeavesBlock`）+ TFC `BerryBushBlockEntity` / `TickingPlantBlockEntity` |
| 固定灌木（2） | pineapple, nightshade | TFC `StationaryBerryBushBlock`（**直接 new**，无子类） | 灌木 `BlockItem`、果子 `Item` | `F/common/blocks/plant/FLFruitBlocks.java:72-90`、`F/common/blocks/FLBlocks.java:218` | TFC `SeasonalPlantBlock` + `BerryBushBlockEntity` |
| 葡萄（红/白，野生） | wild_red_grapes, wild_white_grapes | TFC `WildCropBlock`（**直接 new**，带方块物品） | 普通 `BlockItem` | `F/common/blocks/FLBlocks.java:206-207` | TFC 野生植物（`WildCropBlock`） |
| 葡萄（红/白，栽培） | 棚架柱 / 绳 / 带植物绳 / 地面植株 / 绒叶 | `GrapeTrellisPostBlock`、`GrapeTrellisPostWithPlantBlock`、`GrapeStringBlock`、`GrapeStringWithPlantBlock`、`GrapeGroundPlantOnStringBlock`、`GrapeFluffBlock`（全部 Firmalife 自建） | `GrapeSeedItem`（`firmalife:seeds/red_grape` 等） | `F/common/blocks/FLBlocks.java:229-238`、`F/common/items/FLItems.java:86-87` | 自建系统；只复用 TFC 的 `Lifecycle`、`DeviceBlock`、`GroundcoverBlock`、`ISlowEntities`、`HoeOverlayBlock`、`ClimateRange` |
| 香蕉（TFC 内容，Firmalife 只接入） | `tfc:plant/banana_sapling` | 仍是 TFC 的 `BananaSaplingBlock` / `BananaPlantBlock` | 仍是 TFC 的物品 | 无新方块；只有 `JAR/data/firmalife/firmalife/plantable/banana.json` | TFC 大型热带植物机制（不在 `FruitBlocks` 枚举里，独立注册，`T/common/blocks/TFCBlocks.java:319`） |
| **TFC 式作物（`Crop`）** | **无** | — | — | — | — |

### 1.2 草药

- 枚举定义（8 项，带用途注释）：`F/common/blocks/Herb.java:3-13`
- 方块创建：
  ```java
  // F/common/blocks/FLBlocks.java:209-210
  public static final Map<Herb, Id<Block>> HERBS = Helpers.mapOf(Herb.class, herb -> register("plant/" + herb.name(), () -> PlantBlock.create(FLPlant.HERB, FLPlant.HERB.nonSolidFire())));
  public static final Map<Herb, Id<Block>> POTTED_HERBS = Helpers.mapOf(Herb.class, herb -> registerNoItem("plant/potted/" + herb.name(), () -> new FlowerPotBlock(() -> (FlowerPotBlock) Blocks.FLOWER_POT, HERBS.get(herb), Properties.of().instabreak().noOcclusion())));
  ```
- 关键点：**8 种草药共用同一个 `RegistryPlant`（`FLPlant.HERB`）和同一个方块状态定义**，名字差异只体现在注册名与模型/贴图上。`FLPlant` 是 Firmalife 自己写的枚举（只有 `HERB` 一项），实现了 TFC 的公开接口 `RegistryPlant`：`F/common/util/FLPlant.java:16-131`。
- `FLPlant` 里所有开花/季节相关方法都返回 0（即「不做季节开花」），并有 `//TODO this needs plant properties defined` 注释：`F/common/util/FLPlant.java:15`、`:67-125`。
- 物品：`register(name, blockSupplier)` 默认生成 `new BlockItem(block, new Item.Properties())`：`F/common/blocks/FLBlocks.java:347-350`。
- 世界生成：每种草药有 3 个 JSON（单株 / 成簇 / 放置规则），例如
  ```json
  // JAR/data/firmalife/worldgen/configured_feature/plant/basil.json
  {"type":"minecraft:simple_block","config":{"to_place":{"type":"minecraft:simple_state_provider","state":{"Name":"firmalife:plant/basil"}}}}
  // JAR/data/firmalife/worldgen/configured_feature/plant/basil_patch.json
  {"type":"minecraft:random_patch","config":{"tries":8,"xz_spread":10,"y_spread":1,"feature":"firmalife:plant/basil"}}
  // JAR/data/firmalife/worldgen/placed_feature/plant/basil.json
  {"feature":"firmalife:plant/basil","placement":[{"type":"minecraft:heightmap","heightmap":"WORLD_SURFACE_WG"},{"type":"block_predicate_filter","predicate":{"type":"tfc:replaceable"}},{"type":"block_predicate_filter","predicate":{"type":"would_survive","state":{"Name":"firmalife:plant/basil"}}}]}
  ```
  注意这里用了 TFC 自定义的两个谓词/谓词类型：`tfc:replaceable` 与 `would_survive`（后者是 vanilla `block_predicate_filter` 的谓词类型）。

### 1.3 果树（fig / cocoa）

```java
// F/common/blocks/plant/FLFruitBlocks.java:30-70（节选）
public enum Tree
{
    COCOA(FLItems.FOODS.get(FLFood.COCOA_BEANS), new Color(252, 171, 255).getRGB(), new Lifecycle[] {HEALTHY, HEALTHY, HEALTHY, FLOWERING, FLOWERING, FRUITING, DORMANT, DORMANT, DORMANT, DORMANT, DORMANT, HEALTHY}),
    FIG(FLItems.FRUITS.get(FLFruit.FIG), new Color(251, 135, 255).getRGB(), new Lifecycle[] {HEALTHY, HEALTHY, FLOWERING, FLOWERING, FRUITING, DORMANT, DORMANT, DORMANT, DORMANT, DORMANT, HEALTHY, HEALTHY});
    ...
    public Block createSapling()        { return new FLFruitTreeSaplingBlock(ExtendedProperties.of()...blockEntity(FLBlockEntities.TICKING_PLANT)..., FLBlocks.FRUIT_TREE_GROWING_BRANCHES.get(this), 8 * ICalendar.CALENDAR_TICKS_IN_DAY, FLClimateRanges.FRUIT_TREES.get(this), stages); }
    public Block createPottedSapling()  { return new FlowerPotBlock(...); }
    public Block createLeaves()         { return new FLFruitTreeLeavesBlock(ExtendedProperties.of().mapColor(FruitTreeLeavesBlock::getMapColor)...blockEntity(FLBlockEntities.BERRY_BUSH)..., product, stages, FLClimateRanges.FRUIT_TREES.get(this), color); }
    public Block createBranch()         { return new FruitTreeBranchBlock(ExtendedProperties.of()..., FLClimateRanges.FRUIT_TREES.get(this)); }   // 直接用 TFC 类
    public Block createGrowingBranch()  { return new FLGrowingFruitTreeBranchBlock(...blockEntity(FLBlockEntities.TICKING_PLANT)..., FLBlocks.FRUIT_TREE_BRANCHES.get(this), FLBlocks.FRUIT_TREE_LEAVES.get(this), FLClimateRanges.FRUIT_TREES.get(this)); }
}
```

注册（5 张 Map，键就是 Firmalife 自己的 `FLFruitBlocks.Tree`）：

```java
// F/common/blocks/FLBlocks.java:212-216
public static final Map<FLFruitBlocks.Tree, Id<Block>> FRUIT_TREE_LEAVES          = Helpers.mapOf(FLFruitBlocks.Tree.class, tree -> register("plant/" + tree.name() + "_leaves", tree::createLeaves));
public static final Map<FLFruitBlocks.Tree, Id<Block>> FRUIT_TREE_BRANCHES        = Helpers.mapOf(FLFruitBlocks.Tree.class, tree -> registerNoItem("plant/" + tree.name() + "_branch", tree::createBranch));
public static final Map<FLFruitBlocks.Tree, Id<Block>> FRUIT_TREE_GROWING_BRANCHES= Helpers.mapOf(FLFruitBlocks.Tree.class, tree -> registerNoItem("plant/" + tree.name() + "_growing_branch", tree::createGrowingBranch));
public static final Map<FLFruitBlocks.Tree, Id<Block>> FRUIT_TREE_SAPLINGS        = Helpers.mapOf(FLFruitBlocks.Tree.class, tree -> register("plant/" + tree.name() + "_sapling", tree::createSapling));
public static final Map<FLFruitBlocks.Tree, Id<Block>> FRUIT_TREE_POTTED_SAPLINGS = Helpers.mapOf(FLFruitBlocks.Tree.class, tree -> registerNoItem("plant/potted/" + tree.name() + "_sapling", tree::createPottedSapling));
```

**命名与 TFC 完全同构**（`plant/<name>_leaves` / `_branch` / `_growing_branch` / `_sapling` / `plant/potted/<name>_sapling`），可以直接对照 TFC 的
`T/common/blocks/TFCBlocks.java:314-318`（`FRUIT_TREE_LEAVES` 等）拼接。

### 1.4 灌木（pineapple / nightshade）

```java
// F/common/blocks/plant/FLFruitBlocks.java:72-90
public enum StationaryBush
{
    PINEAPPLE(FLItems.FRUITS.get(FLFruit.PINEAPPLE), DORMANT, DORMANT, HEALTHY, HEALTHY, HEALTHY, HEALTHY, FLOWERING, FLOWERING, FRUITING, DORMANT, DORMANT, DORMANT),
    NIGHTSHADE(FLItems.NIGHTSHADE_BERRY, DORMANT, HEALTHY, HEALTHY, HEALTHY, HEALTHY, HEALTHY, FLOWERING, FRUITING, DORMANT, DORMANT, DORMANT, DORMANT);

    public Block create()
    {
        return new StationaryBerryBushBlock(ExtendedProperties.of().strength(0.6f).noOcclusion().randomTicks().sound(SoundType.SWEET_BERRY_BUSH).blockEntity(FLBlockEntities.BERRY_BUSH).flammableLikeLeaves(), product, stages, FLClimateRanges.STATIONARY_BUSHES.get(this));
    }
}
```

注意 `StationaryBerryBushBlock` 是 TFC 的**具体类**，直接 `new` 即可，不需要子类（`T/common/blocks/plant/fruit/StationaryBerryBushBlock.java:61-68`）。
但它的 `getDeadState()` 硬编码返回 TFC 的死灌木（见 §7.5）。

### 1.5 葡萄（详见 §3）

### 1.6 明确没有的东西

- **没有新增 TFC 式作物**：全库搜索 `net.dries007.tfc.common.blocks.crop` 只有 2 处命中（`WildCropBlock`、`CropHelpers`），没有 `Crop`、`TFCBlocks.CROPS`、`TFCBlockEntities.CROP`、`SeedItem` 的使用。
- **没有 mixin 干预植物系统**：`F/mixin/` 只有 `BarrelRackMixin.java`、`BeeMixin.java`、`ServerConfigMixin.java`。
- **没有新增扩散灌木/藤蔓（`SpreadingBushBlock`/`SpreadingCaneBlock`/`VineBlock`）**：全库无引用。
- **没有新增大型热带植物**：香蕉用的是 TFC 现有的方块，Firmalife 只提供了一条温室种植数据（`JAR/data/firmalife/firmalife/plantable/banana.json`）。

---

## 2. 它是否复用了 TFC 的枚举？逐条证据

### 2.1 TFC 侧枚举不可扩展（事实）

- `Crop` 是枚举类：`T/common/blocks/crop/Crop.java:49-51`（`public final class Crop extends Enum<Crop> implements StringRepresentable`），29 个常量位于 `:52-80`，工厂映射在 `:110-142`。
- `FruitBlocks.Tree` / `StationaryBush` / `SpreadingBush` 都是枚举：`T/common/blocks/plant/fruit/FruitBlocks.java:147`、`:205`、`:230`。
- 这些枚举与注册表强绑定：`TFCBlocks.CROPS = Helpers.mapOf(Crop.class, crop -> registerNoItem("crop/" + crop.name(), crop::create))`（`T/common/blocks/TFCBlocks.java:288-290`）、`TFCBlocks.STATIONARY_BUSHES`（`:307`）等。

所以「往 TFC 的枚举里塞新植物」在 Java 层面不可能，唯一办法是**另建枚举 + 另建 Map**（Firmalife 的做法），或者**放弃枚举、逐个手写注册**（TFC 自己对香蕉就是这么做的，见 §6.4）。

### 2.2 Firmalife 自建了哪些枚举

| 自建枚举 | 位置 | 对应 TFC 的哪个枚举 | 是否实现 TFC 接口 |
| --- | --- | --- | --- |
| `FLPlant` | `F/common/util/FLPlant.java:16` | `Plant`（`T/common/blocks/plant/Plant.java`） | 是，实现 `net.dries007.tfc.util.registry.RegistryPlant`（`:16`） |
| `Herb` | `F/common/blocks/Herb.java:3` | 无对应（TFC 无「草药」概念） | 否 |
| `FLFruit` | `F/common/util/FLFruit.java:6` | 无对应 | 否 |
| `FLFruitBlocks.Tree` | `F/common/blocks/plant/FLFruitBlocks.java:30` | `FruitBlocks.Tree` | 否 |
| `FLFruitBlocks.StationaryBush` | `F/common/blocks/plant/FLFruitBlocks.java:72` | `FruitBlocks.StationaryBush` | 否 |

### 2.3 自建 Map 的方式与 TFC 完全一致

Firmalife 使用 TFC 的公开工具方法 `Helpers.mapOf(Class<E extends Enum<E>>, Function<E,V>)`（`T/util/Helpers.java:281`），例如：

```java
// F/common/util/FLClimateRanges.java:15-16
public static final Map<FLFruitBlocks.Tree, DataManager.Reference<ClimateRange>> FRUIT_TREES = Helpers.mapOf(FLFruitBlocks.Tree.class, tree -> register("plant/" + tree.name() + "_tree"));
public static final Map<FLFruitBlocks.StationaryBush, DataManager.Reference<ClimateRange>> STATIONARY_BUSHES = Helpers.mapOf(FLFruitBlocks.StationaryBush.class, bush -> register("plant/" + bush.name() + "_bush"));
```

这与 TFC 的 `ClimateRanges`（`T/util/climate/ClimateRanges.java:17-20`）是**同构写法**，唯一区别是枚举类型和命名空间（`FLHelpers.identifier` → `firmalife:`，`F/common/FLHelpers.java:82-85`；`Helpers.identifier` → `tfc:`，`T/util/Helpers.java:242`）。

### 2.4 是否复用 `CropBlockEntity` / `SeasonalPlantBlock` / `ClimateRange` / `PlantableInfo`

| TFC 类 | Firmalife 是否复用 | 证据 |
| --- | --- | --- |
| `CropBlockEntity` | **否** | 全库无引用；葡萄用自建 `GrapePlantBlockEntity extends TickableBlockEntity implements ICalendarTickable`（`F/common/blockentities/GrapePlantBlockEntity.java:32`） |
| `CropHelpers` | 仅在温室花盆里用于催熟逻辑 | `F/common/blocks/greenhouse/LargePlanterBlock.java:39`（import） |
| `SeasonalPlantBlock` | **间接复用**（通过继承其子类）；**没有**直接继承它 | `FLFruitTreeLeavesBlock extends FruitTreeLeavesBlock`（`F/common/blocks/plant/FLFruitTreeLeavesBlock.java:18`）；`StationaryBerryBushBlock` 直接 new（`F/common/blocks/plant/FLFruitBlocks.java:88`） |
| `FruitTreeLeavesBlock` | 复用（继承） | `F/common/blocks/plant/FLFruitTreeLeavesBlock.java:18-23` |
| `FruitTreeSaplingBlock` | 复用（继承，并重写 `setPlacedBy` / `createTree`） | `F/common/blocks/plant/FLFruitTreeSaplingBlock.java:24-60` |
| `GrowingFruitTreeBranchBlock` | 复用（继承，重写 `randomTick` 以使用自己的 BE type） | `F/common/blocks/plant/FLGrowingFruitTreeBranchBlock.java:16-36` |
| `FruitTreeBranchBlock` | 复用（直接实例化，无子类） | `F/common/blocks/plant/FLFruitBlocks.java:63` |
| `StationaryBerryBushBlock` | 复用（直接实例化） | `F/common/blocks/plant/FLFruitBlocks.java:88` |
| `WildCropBlock` | 复用（直接实例化，用于野生葡萄） | `F/common/blocks/FLBlocks.java:206-207` |
| `Lifecycle` + `TFCBlockStateProperties.LIFECYCLE` | 直接复用（葡萄/果树/灌木都已使用） | `F/common/blocks/plant/GrapeStringWithPlantBlock.java:38`、`IGrape.java:21-24`、`FLFruitBlocks.java:26` |
| `ClimateRange` + `ClimateRange.MANAGER` | 直接复用 | `F/common/util/FLClimateRanges.java:19-22` |
| `BerryBushBlockEntity` | 复用（继承，换 type） | `F/common/blockentities/FLBerryBushBlockEntity.java:9-25` |
| `TickingPlantBlockEntity` | 复用（继承，换 type + 复制静态 helper） | `F/common/blockentities/FLTickingPlantBlockEntity.java:11-37` |
| `PlantableInfo` | **仅作为只读接口使用**，未实现 | `F/common/util/Plantable.java:23,128,147`、`F/client/FLClientForgeEvents.java:71` |
| `RegistryPlant` | **实现**（`FLPlant`） | `F/common/util/FLPlant.java:16` |
| `PlantBlock.create(...)` | 直接调用 | `F/common/blocks/FLBlocks.java:209` |
| `Helpers.mapOf` / `RegistrationHelpers.registerBlock` | 直接调用 | `F/common/blocks/FLBlocks.java:209,359` |
| `Codecs` / `DataManager` / `DataManagers.MANAGERS` | 直接调用（自建数据管理器） | `F/common/util/Plantable.java:75`、`F/common/util/FLDataManagers.java:8-17` |

### 2.5 为什么必须自建 BlockEntityType

TFC 的 BE type 用「工厂 + 具体方块集合」构造：

```java
// T/util/registry/RegistrationHelpers.java:89-94
public static <T extends BlockEntity> DeferredHolder<BlockEntityType<?>, BlockEntityType<T>> register(DeferredRegister<BlockEntityType<?>> blockEntities, String name, BlockEntityType.BlockEntitySupplier<T> factory, Supplier<? extends Block> block) {
    return blockEntities.register(name, () -> BlockEntityType.Builder.of(factory, new Block[]{block.get()}).build(null));
}
public static <T extends BlockEntity> ... register(..., Stream<? extends Supplier<? extends Block>> blocks) { ... }
```

即 `BlockEntityType` 在构造时**绑定了具体方块实例**：

```java
// T/common/blockentities/TFCBlockEntities.java:117-118,144
TICK_COUNTING_PLANT = register("tick_counting_branch", TickingPlantBlockEntity::new, Stream.of(TFCBlocks.FRUIT_TREE_SAPLINGS.values().stream(), TFCBlocks.FRUIT_TREE_GROWING_BRANCHES.values().stream(), Stream.of(TFCBlocks.BANANA_SAPLING)).flatMap(e -> e));
BERRY_BUSH          = register("berry_bush", BerryBushBlockEntity::new, Stream.of(List.of(TFCBlocks.BANANA_PLANT, TFCBlocks.CRANBERRY_BUSH), TFCBlocks.SPREADING_BUSHES.values(), TFCBlocks.SPREADING_CANES.values(), TFCBlocks.STATIONARY_BUSHES.values(), TFCBlocks.FRUIT_TREE_LEAVES.values()).flatMap(Collection::stream));
CROP                = register("crop", CropBlockEntity::new, TFCBlocks.CROPS.values().stream());
```

**所以任何 TFC 之外的方块都拿不到 `TFCBlockEntities.CROP` / `BERRY_BUSH` / `TICK_COUNTING_PLANT`**（`BlockEntityType` 只有在其方块集合里才允许创建对应 BE）。Firmalife 因此建了自己的注册表：

```java
// F/common/blockentities/FLBlockEntities.java:19,26-29,42,57
public static final DeferredRegister<BlockEntityType<?>> BLOCK_ENTITY = DeferredRegister.create(Registries.BLOCK_ENTITY_TYPE, FirmaLife.MOD_ID);
public static final Id<FLTickingPlantBlockEntity> TICKING_PLANT = register("ticking_plant", FLTickingPlantBlockEntity::new, Stream.of(FLBlocks.FRUIT_TREE_SAPLINGS.values().stream(), FLBlocks.FRUIT_TREE_GROWING_BRANCHES.values().stream()).flatMap(e -> e));
public static final Id<BerryBushBlockEntity> BERRY_BUSH = register("berry_bush", FLBerryBushBlockEntity::new, Stream.of(FLBlocks.FRUIT_TREE_LEAVES.values().stream(), FLBlocks.STATIONARY_BUSHES.values().stream()).flatMap(e -> e));
public static final Id<GrapePlantBlockEntity> GRAPE_PLANT = register("grape_plant", GrapePlantBlockEntity::new, Stream.of(FLBlocks.GRAPE_STRING_PLANT_RED, FLBlocks.GRAPE_STRING_PLANT_WHITE));
```

注意 Firmalife 复用了 TFC 的 `TFCBlockEntities.Id` 包装类型（`F/common/blockentities/FLBlockEntities.java:14`）与 `RegistrationHelpers.register`（`:71-79`），因此写法与 TFC 一致。

### 2.6 顺带指出：TFC 的「物品 tooltip 实现类」是 private，无法复用

TFC 把 `PlantableInfo` 实现在两个**private static class** 上，外部无法继承或实例化：

```java
// T/common/blocks/plant/fruit/FruitBlocks.java:85-108
private static class BushBlockItem extends BlockItem implements PlantableInfo { ... }
// T/common/blocks/plant/fruit/FruitBlocks.java:110-145
private static class FruitTreeSaplingItem extends BlockItem implements PlantableInfo { ... }
```

这正是 Firmalife 放弃复用、改走「数据驱动 + 事件注入」的直接原因（§4.5、§7.4）。

---

## 3. 葡萄（grape）的完整实现

葡萄是 Firmalife 里最复杂、也最有参考价值的自定义植物（爬藤 + 结果 + 作物风味 + 酿造链）。它**完全没有**使用 TFC 的作物或季节植物继承体系，只借用了 `Lifecycle` 枚举与属性。

### 3.1 方块类层次

```
net.minecraft Block / TFC 基类                       Firmalife 子类
─────────────────────────────────────────────────────────────────────
TFC ExtendedBlock                        ──►
   └─ GrapeTrellisPostBlock                    F/common/blocks/plant/GrapeTrellisPostBlock.java:34
        └─ GrapeTrellisPostWithPlantBlock     F/common/blocks/plant/GrapeTrellisPostWithPlantBlock.java:41   implements ISlowEntities

TFC DeviceBlock                          ──►
   └─ GrapeStringBlock                        F/common/blocks/plant/GrapeStringBlock.java:25
        ├─ GrapeStringWithPlantBlock          F/common/blocks/plant/GrapeStringWithPlantBlock.java:36      implements IGrape
        └─ GrapeGroundPlantOnStringBlock      F/common/blocks/plant/GrapeGroundPlantOnStringBlock.java:40  implements IGrape, HoeOverlayBlock
              ↑ 唯一挂载 BlockEntity 的方块（FLBlockEntities.GRAPE_PLANT）

TFC GroundcoverBlock                     ──►
   └─ GrapeFluffBlock                         F/common/blocks/plant/GrapeFluffBlock.java:26                implements ISlowEntities
```

- `IGrape` 是 Firmalife 自己的接口（`F/common/blocks/plant/IGrape.java:10-25`），提供三个默认方法：`advance`（生长推进）、`advanceLifecycle`（季节推进）、`updateLifecycle`（写 `TFCBlockStateProperties.LIFECYCLE`）。`updateLifecycle` 里用 TFC 的 `Lifecycle.advanceTowards` 做平滑过渡：

  ```java
  // F/common/blocks/plant/IGrape.java:19-25
  default void updateLifecycle(Level level, BlockPos pos, BlockState state, Lifecycle lifecycle) {
      if (state.hasProperty(TFCBlockStateProperties.LIFECYCLE) && state.getValue(TFCBlockStateProperties.LIFECYCLE).advanceTowards(lifecycle) != state.getValue(TFCBlockStateProperties.LIFECYCLE)) {
          level.setBlockAndUpdate(pos, state.setValue(TFCBlockStateProperties.LIFECYCLE, lifecycle));
      }
  }
  ```

- 方块状态属性：柱用 `AXIS`（水平轴）+ `STRING_PLUS` / `STRING_MINUS`（自定义属性，`F/common/blocks/plant/GrapeTrellisPostBlock.java:36-38`，属性常量在 `FLStateProperties`）；绳用 `AXIS`（`GrapeStringBlock.java:27`）；带植物绳/地面植株用 `+ LIFECYCLE`（`GrapeStringWithPlantBlock.java:38`）；地面植株另有 `STAGE`（0–2，复用 `TFCBlockStateProperties.STAGE_2`，`GrapeGroundPlantOnStringBlock.java:42`）。

### 3.2 生长逻辑（有自己的 BlockEntity 与 ticker）

**唯一挂 BE 的方块**是 `GrapeGroundPlantOnStringBlock`（地面上的那截植株）：

```java
// F/common/blocks/FLBlocks.java:237-238
public static final Id<Block> GRAPE_STRING_PLANT_RED   = registerNoItem("grape_string_plant_red",   () -> new GrapeGroundPlantOnStringBlock(ExtendedProperties.of().randomTicks().noOcclusion().strength(1.0f).sound(SoundType.CROP).flammableLikeLogs().blockEntity(FLBlockEntities.GRAPE_PLANT).serverTicks(GrapePlantBlockEntity::serverTick), GRAPE_STRING_RED));
public static final Id<Block> GRAPE_STRING_PLANT_WHITE = registerNoItem("grape_string_plant_white", () -> new GrapeGroundPlantOnStringBlock(...same..., GRAPE_STRING_WHITE));
```

驱动路径：

```
GrapeGroundPlantOnStringBlock.randomTick()        F/common/blocks/plant/GrapeGroundPlantOnStringBlock.java:63-70
        └─► GrapePlantBlockEntity.tryUpdate()     F/common/blockentities/GrapePlantBlockEntity.java:63-77
                └─► updateTick()（每个游戏日一次） F/common/blockentities/GrapePlantBlockEntity.java:79-107
GrapePlantBlockEntity.serverTick()（ticker）       F/common/blockentities/GrapePlantBlockEntity.java:34-38  → checkForCalendarUpdate() / checkForLastTickSync()
```

关键代码：

```java
// F/common/blockentities/GrapePlantBlockEntity.java:40-107（节选）
public static final int UPDATE_INTERVAL = ICalendar.CALENDAR_TICKS_IN_DAY;   // 每游戏日一次

public void tryUpdate() {
    final long now = Calendars.SERVER.getTicks();
    if (now > (lastGrowthTick + UPDATE_INTERVAL)) {
        while (lastGrowthTick < now) { updateTick(); lastGrowthTick += UPDATE_INTERVAL; }
        recordOwnData();     // 扫描 7x7x2 土壤/蜜蜂数据
        markForSync();
    }
}

public void updateTick() {
    Lifecycle lifecycle = Lifecycle.DORMANT;
    if (FLClimateRanges.GRAPES.get().checkTemperature(Climate.getInstantTemperature(level, worldPosition), false) == ClimateRange.Result.VALID) {
        growth += 0.125f + (level.random.nextFloat() * 0.05f);
        if (growth >= 1f) {
            advanceAt(worldPosition);
            advanceAt(worldPosition.above());
            growth = 0f;
            markForSync();
        }
        lifecycle = Lifecycle.HEALTHY;
        final Month month = Calendars.get(level).getHemispheralCalendarMonthOfYear(SolarCalculator.getInNorthernHemisphere(worldPosition, level));
        if (month == Month.JUNE)        lifecycle = Lifecycle.FLOWERING;
        else if (month == Month.JULY)   lifecycle = Lifecycle.FRUITING;
    }
    lifecycleAt(worldPosition, lifecycle);
    lifecycleAt(worldPosition.above(), lifecycle);
}
```

要点：

1. **节气不走 12 元数组**，而是硬编码「6 月开花、7 月结果、其余健康；气候不满足则休眠」（`:95-104`）。这与 TFC `SeasonalPlantBlock` 的 12 月 `Lifecycle[]` 机制不同（`T/common/blocks/plant/fruit/SeasonalPlantBlock.java:265-267`）。
2. `growth` 存在 BE 的 NBT 里（`"growth"`，`F/common/blockentities/GrapePlantBlockEntity.java:322,333`），**不在 BlockState 里**，这点与 TFC 作物一致（TFC 作物同样把 growth 放在 `CropBlockEntity`，`T/common/blockentities/CropBlockEntity.java:32`）。
3. 时间跳过处理：`tryUpdate` 用 while 循环按天补算（`:67-73`），`onCalendarUpdate(long ticks)` 直接调 `tryUpdate`（`:56-61`），保证睡眠/回溯后不丢生长。
4. 生长推进 `advance()` 的语义：
   - `GrapeGroundPlantOnStringBlock.advance`：`STAGE` 0→1→2（`state.cycle(STAGE)`），到 2 时把上方同轴的那截 **纯绳** 转成 `GrapeStringWithPlantBlock`（`F/common/blocks/plant/GrapeGroundPlantOnStringBlock.java:85-101`）。
   - `GrapeStringWithPlantBlock.advance`：把两端相邻的**棚架柱**转换成带植物版本，并在上方生成 `GrapeFluffBlock`（`:90-125`，`convertToPlant` 在 `:113-125`）。

### 3.3 一条藤 = 多个 BE：`brain` 机制

一条葡萄藤由多段绳/柱组成，每 2 格才有一个 BE。BE 通过「走到轴向尽头再退回一格」确定「大脑」（brain）位置，用于汇总整条藤的数据：

```java
// F/common/blockentities/GrapePlantBlockEntity.java:129-148
public BlockPos getBrainPos() {
    BlockState state = level.getBlockState(worldPosition);
    final Direction dir = getStringDirection(state);
    final BlockPos.MutableBlockPos cursor = new BlockPos.MutableBlockPos();
    cursor.set(worldPosition);
    while (state.getBlock() instanceof GrapeGroundPlantOnStringBlock) { cursor.move(dir, 2); state = level.getBlockState(cursor); }
    cursor.move(dir, -2);
    return cursor.immutable();
}
```

`scanAndReport()`（`:150-213`）先找到 brain，再由 brain 沿轴线累加所有段的 `soilData` 与 `hasBees`，据此产出 FoodTrait 列表。`recordOwnData()`（`:215-269`）每游戏日扫描自身周围 `7×7×2`（x,z ∈ [-3,3]，y ∈ [-1,0]）统计泥土/草/砂砾方块数、`y=-1` 与 `y=0` 的非空气方块数，以及是否有带蜂王的 Firmalife 蜂箱。

### 3.4 气候如何约束

- 数据 id：`firmalife:plant/grapes`（`F/common/util/FLClimateRanges.java:17`）。
- 运行时只用**温度**判定：

  ```java
  // F/common/blockentities/GrapePlantBlockEntity.java:84
  if (FLClimateRanges.GRAPES.get().checkTemperature(Climate.getInstantTemperature(level, worldPosition), false) == ClimateRange.Result.VALID) { ... }
  ```

  （TFC 的季节植物是 `checkBoth(hydration, temp, false)`，`T/common/blocks/plant/fruit/StationaryBerryBushBlock.java:82`；葡萄**不检查湿度**。）
- 玩家能看到的提示：锄头覆盖显示（`addHoeOverlayInfo`）+ 调试信息：

  ```java
  // F/common/blocks/plant/GrapeGroundPlantOnStringBlock.java:103-114
  tooltip.accept(FarmlandBlock.getInstantTemperatureTooltip(level, pos, FLClimateRanges.GRAPES.get(), false));
  if (level.getBlockEntity(pos) instanceof GrapePlantBlockEntity grape && TFCConfig.CLIENT.enableDebug.get()) { ... }
  ```
- JSON 实测内容见 §4。

### 3.5 产物如何定义与获得

两种情况（柱顶、绳上）都在 `Lifecycle.FRUITING` 时可右键采摘：

```java
// F/common/blocks/plant/GrapeTrellisPostWithPlantBlock.java:55-77（节选）
if (!ropeUse.consumesAction() && state.getValue(LIFECYCLE) == Lifecycle.FRUITING) {
    level.playSound(player, pos, SoundEvents.SWEET_BERRY_BUSH_PICK_BERRIES, ...);
    final ItemStack stack = grapeItem.get().getDefaultInstance();
    final GrapePlantBlockEntity grape = findPlant(level, pos, state);
    if (grape != null) {
        final List<DeferredHolder<FoodTrait, FoodTrait>> traits = grape.scanAndReport();
        for (DeferredHolder<FoodTrait, FoodTrait> trait : traits) { FoodCapability.applyTrait(stack, trait); }
    }
    FoodCapability.setCreationDate(stack, FoodCapability.getRoundedCreationDate());
    ItemHandlerHelper.giveItemToPlayer(player, stack);
    level.setBlockAndUpdate(pos, state.setValue(LIFECYCLE, Lifecycle.HEALTHY));
}
```

```java
// F/common/blocks/plant/GrapeStringWithPlantBlock.java:67-88（同样的逻辑，挂在绳上）
```

风味标签（FoodTrait）在 `F/common/items/FLFoodTraits.java` 中定义，葡萄用到 4 个：

| trait | 触发条件（`GrapePlantBlockEntity.scanAndReport()`，`F/common/blockentities/GrapePlantBlockEntity.java:191-212`） |
| --- | --- |
| `BEE_POLLINATED` | 7×7×2 范围内存在带蜂王的 Firmalife 蜂箱（`hasBees`） |
| `DIRT_GROWN` | 泥土计数 > 草计数且 > 砂砾计数 |
| `GRAVEL_GROWN` | 砂砾计数 > 泥土计数且 > 草计数 |
| `SLOPE_GROWN` | `countAtMinus1 < 33 && countAtZero > 20`（下方少、同层多 ⇒ 判定为斜坡） |

播种：

```java
// F/common/items/GrapeSeedItem.java:46-60
private boolean placePlant(UseOnContext context, Level level, BlockPos pos, BlockState stateAt, @Nullable Player player) {
    if (Helpers.isBlock(stateAt, FLBlocks.GRAPE_STRING.get())) {                       // 只能种在「纯绳」上
        final BlockState placeState = crop.get().defaultBlockState();
        if (Helpers.isBlock(level.getBlockState(pos.below()), TFCTags.Blocks.BUSH_PLANTABLE_ON)) {  // 下方必须可种植
            level.setBlockAndUpdate(pos, Helpers.copyProperty(placeState, stateAt, GrapeStringBlock.AXIS));
            ...
        }
    }
}
```

搭棚架：`GrapeTrellisPostBlock.useItemOn` 用 `tfc:jute_fiber` 在两根柱之间拉绳（`F/common/blocks/plant/GrapeTrellisPostBlock.java:47-66`），绳只有在**两端都是异轴柱**时才存活（`GrapeStringBlock.java:47-57`）。柱可以向下堆叠（`getStateForPlacement` 继承下方柱的 `AXIS`，`:68-84`）。

### 3.6 注册名一览（世界内可检索的字符串）

方块：

| 注册名 | 类 |
| --- | --- |
| `firmalife:grape_trellis_post` | `GrapeTrellisPostBlock` |
| `firmalife:grape_trellis_post_red` / `_white` | `GrapeTrellisPostWithPlantBlock` |
| `firmalife:grape_string` | `GrapeStringBlock` |
| `firmalife:grape_string_red` / `_white` | `GrapeStringWithPlantBlock` |
| `firmalife:grape_string_plant_red` / `_white` | `GrapeGroundPlantOnStringBlock`（带 BE） |
| `firmalife:grape_fluff_red` / `_white` | `GrapeFluffBlock` |
| `firmalife:plant/wild_red_grapes` / `plant/wild_white_grapes` | TFC `WildCropBlock` |

（来源：`F/common/blocks/FLBlocks.java:206-207,229-238`）

物品：`firmalife:seeds/red_grape`、`firmalife:seeds/white_grape`（`F/common/items/FLItems.java:86-87`）、`firmalife:food/red_grapes`、`firmalife:food/white_grapes`（`F/common/items/FLItems.java:43`，由 `FLFruit` 枚举批量生成）。

资源文件（实测 `JAR/` 条目与本机 `src/main/resources` 双重确认）：

| 类型 | 路径 |
| --- | --- |
| blockstate | `assets/firmalife/blockstates/grape_trellis_post.json`、`grape_trellis_post_red.json`、`grape_trellis_post_white.json`、`grape_string.json`、`grape_string_red.json`、`grape_string_white.json`、`grape_string_plant_red.json`、`grape_string_plant_white.json`、`grape_fluff_red.json`、`grape_fluff_white.json`（均在 `src/main/resources/assets/firmalife/blockstates/` 下实测存在） |
| 模型 | `assets/firmalife/models/block/grape_0..2.json`、`grape_dead_0..2.json`、`grape_top_red.json`、`grape_top_white.json`、`grape_top_0..1.json`、`grape_top_*_norope.json`、`grape_fluff_{healthy,flowering,fruiting_{red,white},dormant}_{1,2,3}.json`、`grape_trellis.json`、`grape_trellis_string.json`、`grape_trellis_string_center.json`（`JAR/` 实测） |
| 物品模型 | `assets/firmalife/models/item/seeds/red_grape.json`、`white_grape.json`、`models/item/food/{red_grapes,white_grapes,smashed_*_grapes,*_grapes_jam}.json`（`src/main/resources` 实测存在（`seeds/`、`food/` 目录）） |
| 贴图 | `assets/firmalife/textures/block/crop/grape_{0,1,2,dead_0,dead_1,dead_2,leaves,leaves_dead,leaves_flowering,leaves_red,leaves_white}.png`、`textures/block/grape_trellis.png`、`textures/item/seeds/{red,white}_grape.png`（`JAR/` 实测） |
| 语言键 | `block.firmalife.grape_trellis_post`、`block.firmalife.grape_string`、`block.firmalife.grape_string_plant_red`、`block.firmalife.grape_fluff_red`、`block.firmalife.plant.wild_red_grapes`、`item.firmalife.seeds.red_grape`（`R/assets/firmalife/lang/en_us.json:133-146`） |
| 数据 | `data/firmalife/tfc/climate_range/plant/grapes.json`、`data/firmalife/firmalife/plantable/{red_grapes,white_grapes}.json`、`data/firmalife/tfc/food/grapes.json`、`data/firmalife/tags/block/grape_strings.json`、`data/firmalife/tags/block/grape_trellis_posts_plant.json`、`data/firmalife/loot_table/blocks/grape_*.json`、`data/firmalife/worldgen/configured_feature/wild_{red,white}_grapes{,_patch}.json`、`data/firmalife/worldgen/placed_feature/wild_{red,white}_grapes{,_patch}.json` |

blockstate 的变体写法（可照抄，注意葡萄的模型区分 `axis` 与 `lifecycle`/`stage`）：

```json
// JAR/assets/firmalife/blockstates/grape_string_plant_red.json（节选，实际为 24 个变体）
{"variants":{
  "axis=x,lifecycle=dormant,stage=0":{"model":"firmalife:block/grape_dead_0","y":90},
  "axis=x,lifecycle=healthy,stage=0":{"model":"firmalife:block/grape_0","y":90},
  "axis=z,lifecycle=fruiting,stage=2":{"model":"firmalife:block/grape_2"}
}}
```

果树叶子的 blockstate（`lifecycle` → 四张模型）也是同样的套路：

```json
// JAR/assets/firmalife/blockstates/plant/fig_leaves.json
{"variants":{"lifecycle=flowering":{"model":"firmalife:block/plant/fig_flowering_leaves"},"lifecycle=fruiting":{"model":"firmalife:block/plant/fig_fruiting_leaves"},"lifecycle=dormant":{"model":"firmalife:block/plant/fig_dry_leaves"},"lifecycle=healthy":{"model":"firmalife:block/plant/fig_leaves"}}}
```

```json
// JAR/assets/firmalife/blockstates/plant/pineapple_bush.json（节选）
{"variants":{"lifecycle=healthy,stage=0":{"model":"firmalife:block/plant/pineapple_bush_0"}, ...,"lifecycle=dormant,stage=2":{"model":"firmalife:block/plant/dry_pineapple_bush_2"}, ...}}
```

### 3.7 温室路线（Trellis Planter）与酿造链（概览）

葡萄在温室里走的是**完全不同的另一套**代码：`Plantable` 数据 + `TrellisPlanterBlock`（`F/common/blocks/greenhouse/TrellisPlanterBlock.java:11-31`，`PlanterType.TRELLIS`，`F/common/blocks/greenhouse/PlanterType.java:16`）。其数据：

```json
// JAR/data/firmalife/firmalife/plantable/red_grapes.json
{"crop":{"count":1,"id":"firmalife:food/red_grapes"},"ingredient":{"item":"firmalife:seeds/red_grape"},"nutrient":{"nitrogen":0.25,"phosphorous":0.25,"potassium":0.25},"planter":"trellis","seed":{"count":1,"id":"firmalife:seeds/red_grape"},"specials":[],"textures":["firmalife:block/crop/grape_leaves","firmalife:block/crop/grape_leaves_dead","firmalife:block/crop/grape_leaves_flowering","firmalife:block/crop/grape_leaves_red"],"tier":15}
```

酿造链（仅列与植物相关的衔接点，细节超出本文范围）：`firmalife:food/red_grapes` → `stomping`/`quern` 配方 → `firmalife:food/smashed_red_grapes` → `barrel_sealed` 发酵 → 葡萄酒（`WineComponent`，`F/common/capabilities/wine/`）。

---

## 4. 它用什么方式定义「气候范围」

### 4.1 结论：**完全复用 TFC 的 `ClimateRange.MANAGER`（数据包 JSON）**，没有自建系统

```java
// F/common/util/FLClimateRanges.java:13-23（全文关键部分）
public class FLClimateRanges
{
    public static final Map<FLFruitBlocks.Tree, DataManager.Reference<ClimateRange>> FRUIT_TREES = Helpers.mapOf(FLFruitBlocks.Tree.class, tree -> register("plant/" + tree.name() + "_tree"));
    public static final Map<FLFruitBlocks.StationaryBush, DataManager.Reference<ClimateRange>> STATIONARY_BUSHES = Helpers.mapOf(FLFruitBlocks.StationaryBush.class, bush -> register("plant/" + bush.name() + "_bush"));
    public static final DataManager.Reference<ClimateRange> GRAPES = register("plant/grapes");

    private static DataManager.Reference<ClimateRange> register(String name)
    {
        return ClimateRange.MANAGER.getReference(FLHelpers.identifier(name.toLowerCase(Locale.ROOT)));
    }
}
```

### 4.2 数据包路径是怎么推导出来的（关键机制）

```java
// T/util/climate/ClimateRange.java:30
public static final DataManager<ClimateRange> MANAGER = new DataManager<>(Helpers.identifier("climate_range"), CODEC, STREAM_CODEC);

// T/util/data/DataManager.java:75-80
public DataManager(ResourceLocation domain, Codec<T> codec, @Nullable StreamCodec<...> streamCodec) {
    super(GSON, domain.getNamespace() + "/" + domain.getPath());   // ← SimpleJsonResourceReloadListener 的目录
    this.registryName = domain.getPath();
    ...
}
```

`Helpers.identifier("climate_range")` 返回 `tfc:climate_range`（`T/util/Helpers.java:242`），所以监听目录固定为 **`tfc/climate_range`**。
⇒ 任何命名空间的模组，只要把 JSON 放在 **`data/<你的命名空间>/tfc/climate_range/...`**，并用**完整的 ResourceLocation（含命名空间）**引用即可。
Firmalife 用 `FLHelpers.identifier(name)` = `firmalife:<name>`（`F/common/FLHelpers.java:82-85`），所以文件名是 `<name>.json`，而引用 id 是 `firmalife:<name>`。

### 4.3 Firmalife 的 `climate_range` JSON 真实内容（5 个，全部实测）

```json
// data/firmalife/tfc/climate_range/plant/fig_tree.json
{"max_hydration":43,"max_temperature":35.0,"min_hydration":25,"min_temperature":20.0}
```
```json
// data/firmalife/tfc/climate_range/plant/cocoa_tree.json
{"max_hydration":80,"max_temperature":35.0,"min_hydration":44,"min_temperature":20.0}
```
```json
// data/firmalife/tfc/climate_range/plant/pineapple_bush.json
{"max_hydration":80,"max_temperature":24.0,"min_hydration":40,"min_temperature":7.0}
```
```json
// data/firmalife/tfc/climate_range/plant/nightshade_bush.json
{"max_temperature":32.0,"min_hydration":50,"min_temperature":20.0}
```
```json
// data/firmalife/tfc/climate_range/plant/grapes.json
{"max_temperature":50.0,"min_temperature":0.0}
```

字段全部是可选（缺省即无限/0），与 TFC 的 codec 定义一致：

```java
// T/util/climate/ClimateRange.java:27-31
public record ClimateRange(int minHydration, int maxHydration, int hydrationWiggleRange, float minTemperature, float maxTemperature, float temperatureWiggleRange) {
    public static final Codec<ClimateRange> CODEC = RecordCodecBuilder.create(i -> i.group(
        Codec.INT.optionalFieldOf("min_hydration", 0).forGetter(c -> c.minHydration),
        Codec.INT.optionalFieldOf("max_hydration", 100).forGetter(c -> c.maxHydration),
        Codec.INT.optionalFieldOf("hydration_wiggle_range", 0).forGetter(c -> c.hydrationWiggleRange),
        Codec.FLOAT.optionalFieldOf("min_temperature", Float.NEGATIVE_INFINITY).forGetter(c -> c.minTemperature),
        Codec.FLOAT.optionalFieldOf("max_temperature", Float.POSITIVE_INFINITY).forGetter(c -> c.maxTemperature),
        Codec.FLOAT.optionalFieldOf("temperature_wiggle_range", 0.0f).forGetter(c -> c.temperatureWiggleRange)).apply(i, ClimateRange::new));
    public static final DataManager<ClimateRange> MANAGER = new DataManager<>(Helpers.identifier("climate_range"), CODEC, STREAM_CODEC);
}
```

注意 `nightshade_bush.json` 没有 `max_hydration`（默认 100）、`grapes.json` 既没有 hydration 字段也没有 wiggle 字段（因此湿度限制为 0–100，即不限制）。

### 4.4 懒绑定语义（写附属时的重要前提）

`getReference(id)` 只创建一个「引用占位」，实际值在数据包重载时才填充：

```java
// T/util/data/DataManager.java:103-110
public Reference<T> getReference(ResourceLocation id) {
    synchronized (referencesLock) { return references.computeIfAbsent(id, key -> new Reference<>(key, byKey.get(key))); }
}
// T/util/data/DataManager.java:175-194（updateReferences，节选）
if (!unboundReferences.isEmpty()) { LOGGER.error("There were {} '{}' that were used but not defined: {}", ...); SelfTests.reportExternalError(); }
```

⇒ 允许在**静态初始化阶段**（枚举构造器里）就调用 `ClimateRange.MANAGER.getReference(...)`，这正是 Firmalife `FLClimateRanges` 与 TFC `ClimateRanges` 的做法。**但如果 JSON 缺失，会在日志里报错并触发 SelfTests**。

---

## 5. 它以什么方式定义「食物 / 产物」

### 5.1 结论：产物食物走 TFC 的 `tfc/food/*.json`（`FoodCapability.MANAGER`），运行时用 `FoodCapability` 组件接口

Firmalife 有大量 `data/firmalife/tfc/food/*.json`（`JAR/` 实测约 90 个），植物的有：

```json
// data/firmalife/tfc/food/fig.json
{"decay_modifier":1.0,"fruit":0.9,"hunger":4,"ingredient":{"item":"firmalife:food/fig"},"saturation":0.8,"water":5.0}
```
```json
// data/firmalife/tfc/food/pineapple.json
{"decay_modifier":1.0,"fruit":0.75,"hunger":4,"ingredient":{"item":"firmalife:food/pineapple"},"saturation":0.85,"water":1.0}
```
```json
// data/firmalife/tfc/food/nightshade_berry.json
{"decay_modifier":1.0,"fruit":3.0,"hunger":4,"ingredient":{"item":"firmalife:food/nightshade_berry"},"saturation":0.85,"water":1.0}
```
```json
// data/firmalife/tfc/food/grapes.json   ← 用 tag 一次覆盖红白两种葡萄
{"decay_modifier":0.5,"fruit":0.5,"hunger":4,"ingredient":{"tag":"firmalife:foods/grapes"},"saturation":2.5,"water":2.0}
```
```json
// data/firmalife/tfc/food/cocoa_beans.json
{"decay_modifier":0.25,"hunger":4,"ingredient":{"item":"firmalife:food/cocoa_beans"}}
```
（`data/firmalife/tfc/food/banana.json` **不存在** —— 香蕉用的是 TFC 自己的 food 定义。实测 `MISSING`。）

### 5.2 数据管理器与字段来源

```java
// T/util/data/DataManagers.java:60
DataManagers.register(FoodCapability.MANAGER);

// T/common/component/food/FoodDefinition.java:29-33
public record FoodDefinition(Ingredient ingredient, FoodData food, boolean edible) implements IRecipePredicate<ItemStack> {
    public static final Codec<FoodDefinition> CODEC = RecordCodecBuilder.create(i -> i.group(Ingredient.CODEC.fieldOf("ingredient").forGetter(c -> c.ingredient), FoodData.MAP_CODEC.forGetter(c -> c.food), Codec.BOOL.optionalFieldOf("edible", true).forGetter(c -> c.edible)).apply(i, FoodDefinition::new));
}

// T/common/component/food/FoodData.java:33,48
public record FoodData(int hunger, float water, float saturation, int intoxication, float[] nutrients, float decayModifier) { ... }
public static final MapCodec<FoodData> MAP_CODEC = RecordCodecBuilder.mapCodec(i -> i.group(
    Codec.INT.optionalFieldOf("hunger", 0)...,
    Codec.FLOAT.optionalFieldOf("water", 0f)...,
    Codec.FLOAT.optionalFieldOf("saturation", 0f)...,
    Codec.INT.optionalFieldOf("intoxication", 0)...,
    NUTRITION_CODEC.forGetter(...),                       // grain / fruit / vegetables / protein / dairy
    Codec.either(Codec.FLOAT, Codec.STRING)...optionalFieldOf("decay_modifier", 0f)...).apply(i, FoodData::new));
```

⇒ `tfc/food/*.json` 的**顶层**字段是 `ingredient` / `edible`，**食物数据字段直接平铺在同一层**（`hunger` / `water` / `saturation` / `intoxication` / `grain` / `fruit` / `vegetables` / `protein` / `dairy` / `decay_modifier`）。这一点 Firmalife 的 JSON 与 TFC 一致。

### 5.3 运行时：产物如何获得 TFC 食物组件

1. 采摘时打时间戳：`FoodCapability.setCreationDate(stack, FoodCapability.getRoundedCreationDate())`（`F/common/blocks/plant/GrapeStringWithPlantBlock.java:82`、`GrapeTrellisPostWithPlantBlock.java:71`）。
2. 打风味标签：`FoodCapability.applyTrait(stack, trait)`（同上 `:79` / `:68`）。
3. 温室播种产出物品时直接 `setCreatedNow`：

   ```java
   // F/common/util/Plantable.java:94-107
   public ItemStack getSeed() { return seed.copy(); }
   public ItemStack getCrop() { return FoodCapability.setCreatedNow(crop.copy()); }
   ```
4. 物品本体也会带 vanilla `FoodProperties`（用于原版饥饿条显示与「是否可食用」判定）：

   ```java
   // F/common/util/FLFruit.java:33-38
   public FoodProperties getFoodProperties() {
       FoodProperties.Builder builder = new FoodProperties.Builder();
       if (fast) builder.fast();
       return builder.nutrition(4).saturationModifier(0.3f).build();
   }
   // F/common/items/FLItems.java:42-43
   public static final Map<FLFood, ItemId> FOODS  = Helpers.mapOf(FLFood.class, food -> register("food/" + food.name(), () -> new Item(new Item.Properties().food(food.getFoodProperties()))));
   public static final Map<FLFruit, ItemId> FRUITS = Helpers.mapOf(FLFruit.class, food -> register("food/" + food.name(), () -> new Item(new Item.Properties().food(food.getFoodProperties()))));
   ```

   **注意**：真正的 TFC 饥饿/营养/腐坏曲线来自 `tfc/food/*.json`，vanilla `FoodProperties` 只是「外壳」（TFC 的 `FoodCapability` 会在吃过之后接管）。
5. 特例（有毒）：`nightshade_berry` 额外挂了 vanilla 负面效果，但仍需 TFC food JSON：

   ```java
   // F/common/items/FLItems.java:108
   public static final ItemId NIGHTSHADE_BERRY = register("food/nightshade_berry", () -> new Item(new Item.Properties().food(new FoodProperties.Builder().nutrition(4).saturationModifier(0.3f).effect(() -> new MobEffectInstance(MobEffects.HARM, 1, 10), 0.5f).build())));
   ```

### 5.4 温室产出如何与营养挂钩（`Plantable` 的 `nutrient`）

Firmalife 的 `Plantable` 数据自带 `nutrient` 字段（不是 TFC 的 `Fertilizer`）：

```java
// F/common/util/Plantable.java:31-39
public record Plantable(Ingredient ingredient, PlanterType planter, int tier, int stages, float extraSeedChance, ItemStack seed, ItemStack crop, NutrientList nutrient, List<ResourceLocation> textures, List<ResourceLocation> specials) {
    public record NutrientList(float nitrogen, float phosphorous, float potassium) {}
}
```

如果同一个物品**同时**被 TFC 的 `SeedItem`（实现了 `PlantableInfo`）和 Firmalife 的 `Plantable` 覆盖，tooltip 会去重（只有不一致时才显示 FL 的）：

```java
// F/common/util/Plantable.java:142-172（节选）
if (pi != null) {
    final PlantableInfo.PlantNutrients tfc = pi.getNutrientsInfo();
    ...
    showN = !equals(tfcN, fl.nitrogen); ...
}
```

---

## 6. 可复制的模式（四类需求）

> 下面每一类都给出「Firmalife 实际怎么写」与「推荐你照抄的最小骨架」。

### 6.1 需求 A：在 TFC 里加一种「新作物」（`Crop` 式，种在耕地上）

**Firmalife 未实现这类内容**（它一个 TFC 作物都没加，§1.6）。所以必须参考 TFC 自身的作物类。核实后可用的路径如下：

**(1) 哪些类可用、哪些不可用（实测可见性与签名）**

| 类 | 可见性 | 能否继承/直接 new | 证据 |
| --- | --- | --- | --- |
| `Crop`（枚举） | `public final class Crop extends Enum<Crop>` | ❌ 不能扩展 | `T/common/blocks/crop/Crop.java:49-51` |
| `DefaultCropBlock.create(ExtendedProperties, int, Crop)` | `public static`，**签名强制 `Crop`** | ❌ 不能用于自定义作物 | `T/common/blocks/crop/DefaultCropBlock.java:36-45` |
| `DefaultCropBlock` 的 `protected` 构造器 | `protected DefaultCropBlock(ExtendedProperties, int maxAge, Supplier<? extends Block> dead, Supplier<? extends Item> seeds, float n, float p, float k, Supplier<ClimateRange>)` | ✅ **可被子类调用**（绕开 `Crop` 枚举） | `T/common/blocks/crop/DefaultCropBlock.java:47-49` |
| `CropBlock`（抽象基类） | `public abstract class`，`protected CropBlock(...)` | ✅ 可继承 | `T/common/blocks/crop/CropBlock.java:75-104` |
| `CropBlock.getAgeProperty()` / `postGrowthTick(...)` | `abstract` | 必须实现 | `T/common/blocks/crop/CropBlock.java:122,226` |
| `DeadCropBlock(ExtendedProperties, Supplier<ClimateRange>)` | `public` | ✅ 可直接 new | `T/common/blocks/crop/DeadCropBlock.java:57-65` |
| `ICropBlock` / `CropBlockEntity` | `CropBlockEntity` 有 **public** `(BlockEntityType<?>, BlockPos, BlockState)` 构造器 | ✅ 可自建 BE type 复用该类 | `T/common/blockentities/CropBlockEntity.java:51-57` |
| `CropHelpers.growthTick(...)` | `public final class` + `public static` | ✅ 可直接调用 | `T/common/blocks/crop/CropHelpers.java:49-63` |
| `TFCBlockEntities.CROP` | 绑定 `TFCBlocks.CROPS.values()` | ❌ 新方块不能用 | `T/common/blockentities/TFCBlockEntities.java:144` |

**(2) 可照抄骨架**

```java
// 1) 自己的 BE type（必须自建，理由见 §2.5）
//    写法照抄 Firmalife 的 FLBlockEntities（复用 TFC 的 Id 包装与 RegistrationHelpers）
public static final DeferredRegister<BlockEntityType<?>> BE = DeferredRegister.create(Registries.BLOCK_ENTITY_TYPE, MOD_ID);
public static final Id<CropBlockEntity> CROP = new Id<>(RegistrationHelpers.register(BE, "crop", CropBlockEntity::new, MY_CROP_BLOCK));
//    ↑ 复用 TFC 的 CropBlockEntity *类*（它的 (BlockEntityType<?>, BlockPos, BlockState) 构造器是 public，
//      T/common/blockentities/CropBlockEntity.java:55-57），但必须换成自己的 BlockEntityType

// 把 BE type 的 ticker 绑到方块上：
ExtendedProperties.of(MapColor.PLANT).noCollission().randomTicks().strength(0.4f).sound(SoundType.CROP)
    .blockEntity(MY_BE)                          // 必须先 blockEntity(...) 再 serverTicks(...)
    .serverTicks(CropBlockEntity::serverTick);   // 该静态方法 public (T/.../CropBlockEntity.java:41)
```

（对照 Firmalife 的实际写法：`F/common/blockentities/FLBlockEntities.java:71-79` 的 `register` 辅助方法 + `new Id<>(...)`；`F/common/blocks/FLBlocks.java:359`。）

```java
// 2) 方块：继承 DefaultCropBlock 并调用它的 protected 构造器
public class MyCropBlock extends DefaultCropBlock
{
    private static final IntegerProperty AGE = TFCBlockStateProperties.getAgeProperty(7);   // 8 阶段 ⇒ maxAge 7

    public MyCropBlock(ExtendedProperties props, Supplier<? extends Block> dead, Supplier<? extends Item> seeds, Supplier<ClimateRange> range)
    {
        super(props, 7, dead, seeds, 0.4f, 0.3f, 0.5f, range);   // ← 绕开 Crop 枚举
    }

    @Override public IntegerProperty getAgeProperty() { return AGE; }
    @Override protected void postGrowthTick(Level level, BlockPos pos, BlockState state, CropBlockEntity crop)
    {
        final int age = crop.getGrowth() == 1f ? getMaxAge() : (int) (crop.getGrowth() * (float) getMaxAge());
        level.setBlockAndUpdate(pos, state.setValue(AGE, age));
    }
    @Override protected void createBlockStateDefinition(StateDefinition.Builder<Block, BlockState> b) { b.add(AGE); }
}
```

（`postGrowthTick` 的实现直接照抄 TFC 的 `DefaultCropBlock.postGrowthTick`，`T/common/blocks/crop/DefaultCropBlock.java:57-61`。）

**(3) 仍必须做的事**

- 死株方块：自己 new `DeadCropBlock(props, myClimateRange)`（`DeadCropBlock` 有 `(ExtendedProperties, Supplier<ClimateRange>)` 公开构造器，`:61`），并在方块 `die()` 里切换（参考 `DefaultCropBlock.die`，`:52-55`）。
- 种子物品：TFC 的 `SeedItem` 构造器强制要 `Crop`（`T/common/items/SeedItem.java:30-35`），**不能复用**。要么自写 `ItemNameBlockItem implements PlantableInfo`（照抄 `SeedItem` 的 4 个方法与 `registerBlocks`，`:23-53`），要么用 Firmalife 式数据驱动 tooltip（§6.2 与 §7.4）。
- 缺省形状/催熟：`CropBlock.getShape` / `useItemOn` 已由基类提供（`T/common/blocks/crop/CropBlock.java:111-120,148-150`），只要继承就自动生效。

### 6.2 需求 B：加一种新果树

**Firmalife 完整实现过（fig / cocoa）**，直接照抄这套五件套：

```java
// 1) 枚举（自建，不能用 FruitBlocks.Tree）
public enum MyTree
{
    MY_FRUIT(MyItems.FRUIT, 0xFF00FF, new Lifecycle[] { /* 必须是 12 个元素 */ HEALTHY, ... });

    public Block createSapling()       { return new MyFruitTreeSaplingBlock(ExtendedProperties.of().noCollission().randomTicks().strength(0).sound(SoundType.GRASS).blockEntity(MY_BE_TICKING_PLANT).flammableLikeLeaves(), MY_BLOCKS.GROWING_BRANCHES.get(this), 8 * ICalendar.CALENDAR_TICKS_IN_DAY, MyClimateRanges.FRUIT_TREES.get(this), stages); }
    public Block createPottedSapling() { return new FlowerPotBlock(() -> (FlowerPotBlock) Blocks.FLOWER_POT, MY_BLOCKS.SAPLINGS.get(this), BlockBehaviour.Properties.of().instabreak().noOcclusion()); }
    public Block createLeaves()        { return new MyFruitTreeLeavesBlock(ExtendedProperties.of().mapColor(FruitTreeLeavesBlock::getMapColor).strength(0.5F).sound(SoundType.GRASS).randomTicks().noOcclusion().blockEntity(MY_BE_BERRY_BUSH).flammableLikeLeaves(), product, stages, MyClimateRanges.FRUIT_TREES.get(this), color); }
    public Block createBranch()        { return new FruitTreeBranchBlock(ExtendedProperties.of().mapColor(MapColor.WOOD).sound(SoundType.SCAFFOLDING).randomTicks().strength(1.0f).flammableLikeLogs(), MyClimateRanges.FRUIT_TREES.get(this)); }   // TFC 类可直接用
    public Block createGrowingBranch() { return new MyGrowingFruitTreeBranchBlock(ExtendedProperties.of()...blockEntity(MY_BE_TICKING_PLANT)..., MY_BLOCKS.BRANCHES.get(this), MY_BLOCKS.LEAVES.get(this), MyClimateRanges.FRUIT_TREES.get(this)); }
}
```

（逐字对应 `F/common/blocks/plant/FLFruitBlocks.java:46-69`。）

```java
// 2) 三个子类：全部是「换个 BE type + 复用父类逻辑」
public class MyFruitTreeSaplingBlock extends FruitTreeSaplingBlock {
    @Override public void setPlacedBy(...) { /* 用自己 BE 的静态 helper，见 §7.1 */ }
    @Override public void createTree(...)  { /* 同上，抄 FLFruitTreeSaplingBlock:45-60 */ }
}
public class MyFruitTreeLeavesBlock extends FruitTreeLeavesBlock { /* 可只改 animateTick/粒子 */ }
public class MyGrowingFruitTreeBranchBlock extends GrowingFruitTreeBranchBlock { /* 重写 randomTick 用自己 BE 的 reset，抄 FLGrowingFruitTreeBranchBlock:26-36 */ }
```

```java
// 3) BE：继承 TFC 的 BE 类并换 type
public class MyBerryBushBlockEntity extends BerryBushBlockEntity { public MyBerryBushBlockEntity(BlockPos p, BlockState s) { super(MY_BE_BERRY_BUSH.get(), p, s); } }
public class MyTickingPlantBlockEntity extends TickingPlantBlockEntity { public MyTickingPlantBlockEntity(BlockPos p, BlockState s) { super(MY_BE_TICKING_PLANT.get(), p, s); } /* + 复制静态 helper */ }
```

```java
// 4) 气候 + 5) 标签（放 TFC 命名空间！）
// data/<你的ns>/tfc/climate_range/plant/<name>_tree.json  →  用 <你的ns>:plant/<name>_tree 引用
// data/tfc/tags/block/fruit_tree_leaves.json    {"values":["<你的ns>:plant/<name>_leaves"]}
// data/tfc/tags/block/fruit_tree_branches.json  {"values":["<你的ns>:plant/<name>_branch","<你的ns>:plant/<name>_growing_branch"]}
// data/tfc/tags/block/fruit_tree_saplings.json  {"values":["<你的ns>:plant/<name>_sapling"]}
```

Firmalife 实测的这三个 TFC 标签文件内容：

```json
// JAR/data/tfc/tags/block/fruit_tree_leaves.json
{"values":["firmalife:plant/cocoa_leaves","firmalife:plant/fig_leaves"]}
// JAR/data/tfc/tags/block/fruit_tree_branches.json
{"values":["firmalife:plant/cocoa_branch","firmalife:plant/fig_branch","firmalife:plant/cocoa_growing_branch","firmalife:plant/fig_growing_branch"]}
// JAR/data/tfc/tags/block/fruit_tree_saplings.json
{"values":["firmalife:plant/cocoa_sapling","firmalife:plant/fig_sapling"]}
```

> 这三个标签**非常关键**：`FruitTreeLeavesBlock.isValid()` 判定叶片是否存活靠 `TFCTags.Blocks.FRUIT_TREE_BRANCH`（`T/common/blocks/plant/fruit/FruitTreeLeavesBlock.java:225-236`），`GrowingFruitTreeBranchBlock` 的蔓延也依赖它（`T/common/blocks/plant/fruit/GrowingFruitTreeBranchBlock.java:117-130`）。不写标签 → 叶子一放就掉。

```java
// 6) 世界生成（野生果树）：Firmalife 自建了一个 Feature
// F/common/worldgen/FLFruitTreeFeature.java:20-58（读取 BlockStateConfiguration，放一棵 GrowingFruitTreeBranchBlock，
//   立刻 increaseCounter(ICalendar.CALENDAR_TICKS_IN_DAY * 300) 让树"长大"，然后 scheduleTick）
// F/common/worldgen/FLFeatures.java:21 注册：Id<FLFruitTreeFeature> FRUIT_TREE = register("fruit_trees", FLFruitTreeFeature::new, Codecs.BLOCK_STATE_CONFIG);
```

### 6.3 需求 C：加一种新灌木 / 藤蔓

**固定灌木**：Firmalife 有实现（pineapple / nightshade），照抄 §1.4 即可（一行 `new StationaryBerryBushBlock(...)` + 一份 `climate_range` JSON + 一份 `BerryBushBlockEntity` 子类）。别忘了把产物做成 TFC food JSON。

**扩散灌木（`SpreadingBush`）/ 蔓越莓（水logged）/ 攀爬藤**：**Firmalife 未实现**，需参考 TFC 自身的类：

| TFC 类 | 用途 | 可见性 | 注册参考 |
| --- | --- | --- | --- |
| `SpreadingBushBlock` / `SpreadingCaneBlock` | 黑莓/树莓/蓝莓/接骨木（横向蔓延） | 见 `T/common/blocks/plant/fruit/SpreadingBushBlock.java`、`SpreadingCaneBlock.java` | `T/common/blocks/TFCBlocks.java:308-309`（命名为 `plant/<name>_bush` 与 `plant/<name>_bush_cane`） |
| `WaterloggedBerryBushBlock` | 蔓越莓（可被水淹） | `T/common/blocks/plant/fruit/WaterloggedBerryBushBlock.java` | `T/common/blocks/TFCBlocks.java:310`（`plant/cranberry_bush`，工厂 `FruitBlocks::createCranberry`，`T/.../FruitBlocks.java:61-67`） |
| `DeadBerryBushBlock` / `DeadCaneBlock` | 死株 | — | `T/common/blocks/TFCBlocks.java:311`、`:313` |
| `TFCBlocks.Id` 的注册顺序 | 先 bush 再 cane（cane 需要 bush 的 `Supplier`） | — | `T/common/blocks/TFCBlocks.java:307-310` |

另外注意扩散灌木与季节植物的「按轴传播」都靠标签 `TFCTags.Blocks.SPREADING_BUSHES`（`T/common/TFCTags.java:429`）与 `LIVING_SPREADING_BUSHES`（`:428`）。

**关于 Firmalife 的葡萄藤**：它不是 TFC 的「藤蔓」机制（没有 `VineBlock` / `TFCVineBlock`），而是一套「柱 + 绳 + 挂 BE 的地面植株」的自建结构（§3）。如果你要的是「攀爬生长、可攀爬」的藤蔓，请参考 TFC 的 `TFCVineBlock`（`T/common/blocks/plant/TFCVineBlock.java`）而不是葡萄。

### 6.4 需求 D：加一种像香蕉那样的大型热带植物

**Firmalife 未实现新的大型热带植物**。它只是把 TFC 的香蕉**接入温室**（`JAR/data/firmalife/firmalife/plantable/banana.json`，引用了 `tfc:plant/banana_sapling`）：

```json
// JAR/data/firmalife/firmalife/plantable/banana.json
{"crop":{"count":1,"id":"tfc:food/banana"},"extra_seed_chance":0.08,"ingredient":{"item":"tfc:plant/banana_sapling"},"nutrient":{"nitrogen":0.25,"phosphorous":0.3,"potassium":0.3},"planter":"hanging","seed":{"count":1,"id":"tfc:plant/banana_sapling"},"specials":["firmalife:block/crop/banana_fruit"],"stages":4,"textures":["firmalife:block/crop/banana_0","firmalife:block/crop/banana_1","firmalife:block/crop/banana_2","firmalife:block/crop/banana_3","firmalife:block/crop/banana_4"],"tier":15}
```

若要自己加「香蕉式大型热带植物」，请照 TFC 的写法（**不是枚举，逐个独立注册**）：

```java
// T/common/blocks/plant/fruit/FruitBlocks.java:57,59,69-83
private static final Lifecycle[] BANANA_STAGES = new Lifecycle[]{DORMANT, DORMANT, HEALTHY, HEALTHY, HEALTHY, HEALTHY, FLOWERING, FLOWERING, FRUITING, DORMANT, DORMANT, DORMANT};
public static Block createBananaSapling() { return new BananaSaplingBlock(ExtendedProperties.of(MapColor.PLANT).noCollission().randomTicks().strength(0.0f).sound(SoundType.GRASS).blockEntity(TFCBlockEntities.TICK_COUNTING_PLANT).flammableLikeLeaves(), BANANA_STAGES, TFCBlocks.BANANA_PLANT, TFCConfig.SERVER.bananaSaplingGrowthTicks); }
public static BlockItem createBananaSaplingItem(Block block) { return new FruitTreeSaplingItem(block, ClimateRanges.BANANA_PLANT, BANANA_STAGES); }   // ← 该类是 private，外部无法复用
public static Block createPottedBananaSapling() { return new FlowerPotBlock(...); }
public static Block createBananaPlant() { return new BananaPlantBlock(ExtendedProperties.of(MapColor.PLANT).strength(0.5f).sound(SoundType.GRASS).randomTicks().noOcclusion().forceSolidOn().blockEntity(TFCBlockEntities.BERRY_BUSH).flammableLikeLeaves().cloneItem(TFCBlocks.BANANA_SAPLING), TFCItems.FOOD.get(Food.BANANA), BANANA_STAGES); }
```

注册点：`T/common/blocks/TFCBlocks.java:319`（`BANANA_PLANT` = `registerNoItem("plant/banana_plant", FruitBlocks::createBananaPlant)`）、`:320`（`BANANA_SAPLING`）、`:312`（`DEAD_BANANA_PLANT`）。
气候数据 id 是 `tfc:plant/banana_tree`（`T/util/climate/ClimateRanges.java:15`，注意名字是 `_tree` 而不是 `_plant`）。
**你必须自建 BE type**：`BANANA_SAPLING` 用的是 `TFCBlockEntities.TICK_COUNTING_PLANT`，`BANANA_PLANT` 用的是 `TFCBlockEntities.BERRY_BUSH`（`T/common/blockentities/TFCBlockEntities.java:117-118`），两者都绑定死 TFC 方块集合。

---

## 7. 踩坑点（按踩坑概率排序）

### 7.1 TFC 的 BlockEntity 静态 helper 写死了 TFC 的 BE type —— 必须逐个复制

```java
// T/common/blockentities/TickingPlantBlockEntity.java:29-39
public static void reset(Level level, BlockPos pos)         { level.getBlockEntity(pos, TFCBlockEntities.TICK_COUNTING_PLANT.get()).ifPresent(TickCounterBlockEntity::resetCounter); }
public static void addTicks(Level level, BlockPos pos, long ticks) { ... TFCBlockEntities.TICK_COUNTING_PLANT.get() ... }
public static void setStemPos(Level level, BlockPos pos, BlockPos stemPos) { ... TFCBlockEntities.TICK_COUNTING_PLANT.get() ... }
```

这些静态方法**永远只会查到 TFC 的 BE**，所以：
- 派生类里**任何调用父类静态 helper 的地方都会静默失效**（拿不到 BE）。Firmalife 在自己的 BE 子类里重写了一套同名静态方法：

  ```java
  // F/common/blockentities/FLTickingPlantBlockEntity.java:13-26
  public static void reset(Level level, BlockPos pos)                       { level.getBlockEntity(pos, FLBlockEntities.TICKING_PLANT.get()).ifPresent(TickCounterBlockEntity::resetCounter); }
  public static void addTicks(Level level, BlockPos pos, long ticks)        { level.getBlockEntity(pos, FLBlockEntities.TICKING_PLANT.get()).ifPresent(entity -> entity.increaseCounter(ticks)); }
  public static void setStemPos(Level level, BlockPos pos, BlockPos stemPos){ level.getBlockEntity(pos, FLBlockEntities.TICKING_PLANT.get()).ifPresent(entity -> entity.setStemPos(stemPos)); }
  ```
- 并且必须**重写父类的实例方法**，否则父类实现内部会调到 TFC 的静态 helper。Firmalife 明确写了注释：

  ```java
  // F/common/blocks/plant/FLFruitTreeSaplingBlock.java:31-43
  @Override
  public void setPlacedBy(Level level, BlockPos pos, BlockState state, @Nullable LivingEntity placer, ItemStack stack)
  {
      // Same as the parent, but against our own block entity type, as the parent's static helpers only resolve TFC's
      final BlockPos downPos = pos.below();
      ...
      FLTickingPlantBlockEntity.setStemPos(level, pos, findBaseOfTree(level, downPos, downState));
      FLTickingPlantBlockEntity.reset(level, pos);
      super.setPlacedBy(level, pos, state, placer, stack);
  }
  ```
  同理 `createTree`（`:45-60`）与 `FLGrowingFruitTreeBranchBlock.randomTick`（`:26-36`）也都在调 `FLTickingPlantBlockEntity.reset` 而不是父类的。

> **结论**：写附属时，凡是继承 TFC 的 `FruitTreeSaplingBlock` / `GrowingFruitTreeBranchBlock`，必须把 `setPlacedBy` / `createTree` / `randomTick` / `tick` 里所有 `*BlockEntity.reset/addTicks/setStemPos` 替换成自己的版本。

### 7.2 自建 BE type 时别忘了 `getType()`

Firmalife 的 `FLTickingPlantBlockEntity` 显式覆盖了 `getType()`：

```java
// F/common/blockentities/FLTickingPlantBlockEntity.java:33-37
@Override public BlockEntityType<?> getType() { return FLBlockEntities.TICKING_PLANT.get(); }
```

（TFC 的 `TickingPlantBlockEntity` 与 `BerryBushBlockEntity` 本身**没有**覆盖 `getType()`，因此这一步在技术上可能是冗余的；但 `FLBerryBushBlockEntity` 也做了同样的事，`F/common/blockentities/FLBerryBushBlockEntity.java:21-25`。保守做法：照抄。）

另外注意：**`BerryBushBlockEntity` 只有 `protected` 构造器**，没有 public 的：

```java
// T/common/blockentities/BerryBushBlockEntity.java:36,40
protected BerryBushBlockEntity(BlockPos pos, BlockState state) { ... }
protected BerryBushBlockEntity(BlockEntityType<?> type, BlockPos pos, BlockState state) { ... }
```

⇒ 你**必须**为它写一个子类才能在 `super(...)` 里注入自己的 `BlockEntityType`（不能直接 `new BerryBushBlockEntity(myType, pos, state)`）。Firmalife 的 `FLBerryBushBlockEntity` 正是这么做的（`F/common/blockentities/FLBerryBushBlockEntity.java:9-19`）。`TickingPlantBlockEntity` 则是 public 构造器（`T/common/blockentities/TickingPlantBlockEntity.java:41-49`），可以直接子类化。

### 7.3 `ExtendedProperties` 的 ticker 绑定顺序与唯一性（有断言）

```java
// T/common/blocks/ExtendedProperties.java:113-137
public ExtendedProperties blockEntity(Supplier<? extends BlockEntityType<?>> blockEntityType) { this.blockEntityType = blockEntityType; this.blockEntityFactory = (pos, state) -> blockEntityType.get().create(pos, state); return this; }
public <T extends BlockEntity> ExtendedProperties serverTicks(BlockEntityTicker<T> serverTicker) { ... }
public <T extends BlockEntity> ExtendedProperties ticks(@Nullable BlockEntityTicker<T> serverTicker, @Nullable BlockEntityTicker<T> clientTicker) {
    assert (this.blockEntityType != null) : "Must call .blockEntity() before adding a ticker";
    assert (this.serverTicker == null && this.clientTicker == null) : "Calling ticks() twice, can only call one of ticks(), clientTicks(), or serverTicks()";
    ...
}
```

⇒ 必须 `.blockEntity(X).serverTicks(...)` 的顺序；且**只能调一次** `ticks()/clientTicks()/serverTicks()`。这是**断言**（`assert`），在正式运行（未启用 `-ea`）时不会报错，会静默变成「没有 ticker」——非常容易踩。
Firmalife 全部按此顺序写，例如 `F/common/blocks/plant/FLFruitBlocks.java:48`、`F/common/blocks/FLBlocks.java:237-238`。

另外 `.randomTicks()` 与 `.serverTicks()` 是两件事：`randomTicks()` 让方块进入随机刻（大多数植物逻辑靠它驱动，如 `GrapeGroundPlantOnStringBlock.randomTick`），`serverTicks()` 才是给 BE 挂每刻 ticker。

### 7.4 物品的 `PlantableInfo`：TFC 的实现类是 private，只能自己写

- TFC 的 `BushBlockItem` / `FruitTreeSaplingItem` 是 `private static class`（`T/common/blocks/plant/fruit/FruitBlocks.java:85,110`），**外部无法继承或实例化**。
- 接口本身是公开的，实现它即可让 TFC 的 tooltip 渲染器自动工作：

  ```java
  // T/common/items/PlantableInfo.java:28-31,121-138
  public interface PlantableInfo {
      public static void addTooltipInfo(ItemStack stack, Consumer<Component> tooltip) { ... }   // 由 TFC 的 ItemTooltip 事件调用
      default PlantNutrients getNutrientsInfo() { return null; }
      default ClimateRange getClimateRangeInfo() { return null; }
      default List<Lifecycle> getLifecycleInfo() { return null; }
      default int getGrowthTimeInfo() { return -1; }
  }
  ```
  调用点：`T/client/ClientForgeEventHandler.java:328`（`PlantableInfo.addTooltipInfo(stack, tooltip::add)`）。
  最小实现示例（照抄 TFC 的 `SeedItem`，`T/common/items/SeedItem.java:23-47`）：

  ```java
  public class MySeedItem extends ItemNameBlockItem implements PlantableInfo {
      private final PlantableInfo.PlantNutrients nutrients; private final Supplier<ClimateRange> range;
      public MySeedItem(Block block, float n, float p, float k, Supplier<ClimateRange> range, Item.Properties props) { super(block, props); this.nutrients = new PlantableInfo.PlantNutrients(n, p, k); this.range = range; }
      @Override public PlantableInfo.PlantNutrients getNutrientsInfo() { return nutrients; }
      @Override public ClimateRange getClimateRangeInfo() { return range.get(); }
  }
  ```
- Firmalife 选择了另一条路（因为要支持「一个 `Plantable` 数据定义覆盖任意物品」）：自建 `Plantable` 数据管理器 + 客户端事件注入：

  ```java
  // F/common/util/Plantable.java:75-76
  public static final DataManager<Plantable> MANAGER = new DataManager<>(FLHelpers.identifier("plantable"), CODEC, STREAM_CODEC);
  public static final IndirectHashCollection<Item, Plantable> CACHE = IndirectHashCollection.create(c -> RecipeHelpers.itemKeys(c.ingredient), MANAGER::getValues);
  ```
  ```java
  // F/client/FLClientForgeEvents.java:64-73
  private static void onTooltipLater(ItemTooltipEvent event)   // 注册在 EventPriority.LOW（:31）
  {
      final ItemStack stack = event.getItemStack();
      final List<Component> text = event.getToolTip();
      final Plantable plantable = Plantable.get(stack);
      if (plantable != null) { plantable.addTooltipInfo(text, stack.getItem() instanceof PlantableInfo info ? info : null); }
  }
  ```
  **它的 `DataManager` 目录**由 `FLHelpers.identifier("plantable")` = `firmalife:plantable` 决定（`T/util/data/DataManager.java:76`）⇒ 数据包路径是 `data/<ns>/firmalife/plantable/*.json`（不是 `data/<ns>/firmalife/plantable` 之外的任何地方）。实测 jar 中正是 `data/firmalife/firmalife/plantable/*.json`。
  注册进 TFC 的注册表：

  ```java
  // F/common/util/FLDataManagers.java:8-17
  public static void init() { register(GreenhouseType.MANAGER); register(Plantable.MANAGER); }
  private static void register(DataManager<?> manager) { DataManagers.MANAGERS.register(manager.getName(), () -> manager); }
  ```
  注意 `DataManagers.MANAGERS` 是 TFC 用**命名空间 `tfc`** 创建的 `DeferredRegister`（`T/util/data/DataManagers.java:39`），所以 Firmalife 的 plantable 在这个注册表里的键是 `tfc:plantable`（`manager.getName()` 只给 path）。而 TFC 在自己的 mod 构造器里把它挂到 bus 上（`T/TerraFirmaCraft.java:178`）——Firmalife 只是往这个已存在的 DR 里追加条目，时机在 `FirmaLife` 构造器（`F/FirmaLife.java:81`）。

### 7.5 死株/枯死是被父类硬编码到 TFC 方块上的

| 场景 | 硬编码位置 | 后果 |
| --- | --- | --- |
| 固定灌木气候不满足 | `StationaryBerryBushBlock.getDeadState()` 返回 `TFCBlocks.DEAD_BERRY_BUSH`（`T/common/blocks/plant/fruit/StationaryBerryBushBlock.java:201-203`） | Firmalife 的 pineapple/nightshade 枯死后变成 **TFC 的死灌木**（因为它没有子类覆盖这个方法） |
| 树苗气候不满足 | `FruitTreeSaplingBlock.randomTick` 里 `level.setBlockAndUpdate(pos, TFCBlocks.PLANTS.get(Plant.DEAD_BUSH).get().defaultBlockState())`（`T/common/blocks/plant/fruit/FruitTreeSaplingBlock.java:162-165`） | Firmalife 的 fig/cocoa 树苗枯死后变成 **TFC 的 dead bush** |
| 作物枯死 | `DefaultCropBlock.die` 使用自己的 `dead` Supplier（可由构造器注入，`T/common/blocks/crop/DefaultCropBlock.java:47-55`） | 作物这一项是可配置的，没有硬编码 |

⇒ 如果要自己的枯死形态，必须**继承并重写** `getDeadState()` / 对应的 `randomTick` 分支。

### 7.6 `Lifecycle[]` 长度必须恰好 12，否则构造期就崩

```java
// T/common/blocks/plant/fruit/SeasonalPlantBlock.java:167-174
public SeasonalPlantBlock(ExtendedProperties properties, Supplier<ClimateRange> climateRange, Supplier<? extends Item> productItem, Lifecycle[] lifecycle) {
    super(properties.properties());
    Preconditions.checkArgument(lifecycle.length == 12, "Lifecycle length must be 12");
    ...
}
```

⇒ 用 `Lifecycle...` 可变参数写枚举时（如 Firmalife 的 `StationaryBush`，`F/common/blocks/plant/FLFruitBlocks.java:80`）极容易写错一个，务必数够 12 个。
`Lifecycle` 的语义：`DORMANT < HEALTHY < FLOWERING < FRUITING`，且 `advanceTowards` 每次只走一步（`T/common/blocks/plant/fruit/Lifecycle.java:12-33`）。

### 7.7 注册顺序

| 顺序约束 | 证据 |
| --- | --- |
| `FLItems.ITEM` → `FLBlocks.BLOCK` → `FLBlockEntities.BLOCK_ENTITY` | `F/FirmaLife.java:56-60`。方块注册需要 `FLItems.ITEM` 这个 DR（`FLBlocks.register` 内部用 `RegistrationHelpers.registerBlock(BLOCK, FLItems.ITEM, ...)`，`F/common/blocks/FLBlocks.java:359`）；BE 注册需要方块实例（`BlockEntityType.Builder.of(factory, blocks)`，`T/util/registry/RegistrationHelpers.java:89-94`） |
| 花盆联动必须在 setup 阶段 | `F/FirmaLife.java:100-106`（`event.enqueueWork(() -> { FLInteractionManager.init(); FLBlocks.registerFlowerPotFlowers(); })`）；`registerFlowerPotFlowers` 往 vanilla 的 `FlowerPotBlock` 静态表塞映射（`F/common/blocks/FLBlocks.java:280-285`） |
| 数据管理器注册在 mod 构造阶段 | `F/FirmaLife.java:81`（`FLDataManagers.init()`），且它往 TFC 的 DR 里追加（§7.4） |
| 自建枚举 → 自建 Map 的静态初始化顺序 | `FLClimateRanges` 在静态块里引用 `FLFruitBlocks.Tree.class`（`F/common/util/FLClimateRanges.java:15`），而 `FLFruitBlocks.Tree` 又引用 `FLClimateRanges`（`F/common/blocks/plant/FLFruitBlocks.java:48`）——**互相引用的类初始化环**。Firmalife 之所以没炸，是因为 `ClimateRange.MANAGER.getReference(...)` 是懒绑定（§4.4）。自己写时建议把「枚举」与「数据引用」拆成不同类，避免踩类初始化顺序的坑 |

### 7.8 资源文件命名约定（照抄即可）

| 内容 | TFC 约定 | Firmalife 实例 |
| --- | --- | --- |
| 果树叶子 | `plant/<name>_leaves` | `firmalife:plant/fig_leaves` |
| 果树树干 | `plant/<name>_branch`（无物品） | `firmalife:plant/cocoa_branch` |
| 果树生长中树干 | `plant/<name>_growing_branch`（无物品） | `firmalife:plant/fig_growing_branch` |
| 果树树苗 | `plant/<name>_sapling` | `firmalife:plant/fig_sapling` |
| 果树盆苗 | `plant/potted/<name>_sapling`（无物品） | `firmalife:plant/potted/fig_sapling` |
| 固定灌木 | `plant/<name>_bush` | `firmalife:plant/pineapple_bush` |
| 扩散灌木 / 藤 | `plant/<name>_bush` + `plant/<name>_bush_cane` | —（Firmalife 未实现） |
| 草药（TFC 花草风格） | `plant/<name>` + `plant/potted/<name>` | `firmalife:plant/basil`、`firmalife:plant/potted/basil` |
| 作物 / 死株 / 野生 | `crop/<name>` / `dead_crop/<name>` / `wild_crop/<name>`（均无物品） | —（Firmalife 未实现） |
| 模型 | `models/block/plant/<name>_{0,1,2}.json`、`<name>_{dry,flowering,fruiting}_leaves.json` | `models/block/plant/fig_fruiting_leaves.json` 等（实测存在） |
| 贴图 | `textures/block/plant/<name>/`、`textures/block/crop/<name>_*.png` | `textures/block/crop/grape_leaves_red.png` |
| blockstate 变体键 | `lifecycle=<dormant|healthy|flowering|fruiting>`、`stage=0..2`、`axis=x|z` | `JAR/assets/firmalife/blockstates/plant/fig_leaves.json` |

参考 TFC 自己的命名：`T/common/blocks/TFCBlocks.java:286-290`（`plant/`、`crop/`、`dead_crop/`、`wild_crop/`）、`:307-319`。

### 7.9 标签：必须写、且写在 TFC 命名空间下

| 标签 | 作用 | Firmalife 是否写了 | 证据 |
| --- | --- | --- | --- |
| `tfc:fruit_tree_leaves` | 叶子存活/蔓延判定 | ✅ `data/tfc/tags/block/fruit_tree_leaves.json` | 判定：`T/common/blocks/plant/fruit/FruitTreeLeavesBlock.java:225-236` |
| `tfc:fruit_tree_branches`（**注意标签 key 是单数 `FRUIT_TREE_BRANCH`，文件名是复数 `fruit_tree_branches.json`**） | 树干识别、树苗可否剪接 | ✅ `data/tfc/tags/block/fruit_tree_branches.json` | `T/common/TFCTags.java:421`；剪接判定 `T/common/blocks/plant/fruit/FruitTreeSaplingBlock.java:98-105` |
| `tfc:fruit_tree_saplings` | 用于某些交互/锄头提示 | ✅ `data/tfc/tags/block/fruit_tree_saplings.json` | — |
| `tfc:bush_plantable_on` | 所有季节植物/葡萄的「可种植地面」 | 未新增（用的是 TFC 已有内容） | `T/common/TFCTags.java:468`；`StationaryBerryBushBlock.canSurvive` → `SeasonalPlantBlock.mayPlaceOn`（`T/.../SeasonalPlantBlock.java:269-276`） |
| `tfc:thorny_bushes` | 菠萝丛会扎人（`entityInside` 伤害） | ✅ `data/tfc/tags/block/thorny_bushes.json` = `{"values":["firmalife:plant/pineapple_bush"]}` | 判定 `T/common/blocks/plant/fruit/SeasonalPlantBlock.java:206-210` |
| `tfc:spreading_bushes` / `spreading_bushes/living` | 扩散灌木 | 未新增 | `T/common/TFCTags.java:428-429` |
| `tfc:plants`（item） | 让植物物品被 TFC 识别（堆肥/其它） | ✅ `data/tfc/tags/item/plants.json` 收录 8 种草药方块物品 | `T/common/TFCTags.java:182` |
| `minecraft:leaves` | 原版叶子行为 | ✅ `data/minecraft/tags/block/leaves.json` 收录 cocoa/fig 叶 | — |
| Firmalife 私有标签 | `firmalife:herbs`、`firmalife:grape_strings`、`firmalife:grape_trellis_posts_plant`、`firmalife:buzzing_leaves`、`firmalife:bee_restoration_plants` | ✅ | `F/common/FLTags.java:35-53`；内容见 §1、§3 |

实测内容：

```json
// JAR/data/tfc/tags/block/thorny_bushes.json
{"values":["firmalife:plant/pineapple_bush"]}
// JAR/data/tfc/tags/item/plants.json
{"values":["firmalife:plant/basil","firmalife:plant/bay_laurel","firmalife:plant/cardamom","firmalife:plant/cilantro","firmalife:plant/cumin","firmalife:plant/oregano","firmalife:plant/pimento","firmalife:plant/vanilla"]}
// JAR/data/firmalife/tags/block/grape_strings.json
{"values":["firmalife:grape_string_red","firmalife:grape_string_white"]}
// JAR/data/firmalife/tags/block/grape_trellis_posts_plant.json
{"values":["firmalife:grape_trellis_post_red","firmalife:grape_trellis_post_white"]}
// JAR/data/firmalife/tags/block/buzzing_leaves.json
{"values":["firmalife:plant/fig_leaves"]}
// JAR/data/minecraft/tags/block/leaves.json
{"values":["firmalife:plant/cocoa_leaves","firmalife:plant/fig_leaves"]}
```

> ⚠️ **`thorny_bushes` 这个坑很典型**：菠萝丛的「扎人」不是方块代码里的，而是标签驱动的（`SeasonalPlantBlock.entityInside` 检查 `TFCTags.Blocks.THORNY_BUSHES`）。不加标签 → 荆棘丛林不扎人，且 `getBlockPathType` 不会返回 `DAMAGE_OTHER`。

### 7.10 其它小坑

- **`FLPlant` 的占位实现**：Firmalife 的 `RegistryPlant` 实现里 `getStartTime()/getEndTime()/...` 全返回 0，并留了 TODO。如果直接照抄，草药不会有季节开花（`F/common/util/FLPlant.java:15,67-125`）。
- **`PlantBlock.create` 的默认方块状态**：它会在构造时把 `plant.getAgeProperty()` 的默认值设为 0（`T/common/blocks/plant/PlantBlock.java:219-227`），所以 `RegistryPlant.getAgeProperty()` 返回 null 就必须自己处理（Firmalife 的 `FLPlant` 就是通过 `maxStage > 0 ? TFCBlockStateProperties.getAgeProperty(maxStage) : null` 处理，`F/common/util/FLPlant.java:38`）。
- **`BlockEntityType` 的 `Id` 包装**：Firmalife 复用 TFC 的 `TFCBlockEntities.Id` 与 `TFCBlocks.Id`（`F/common/blockentities/FLBlockEntities.java:14`、`F/common/blocks/FLBlocks.java:105`），因此可以无缝使用 `RegistrationHelpers`。
- **葡萄的 `Lifecycle` 只在** `GrapeStringWithPlantBlock` / `GrapeGroundPlantOnStringBlock` / `GrapeTrellisPostWithPlantBlock` 上有；纯绳/纯柱没有 → 用 `state.hasProperty(LIFECYCLE)` 守卫（`F/common/blocks/plant/IGrape.java:21`）。
- **`cloneItem` 的处理**：带植物的柱/绳在创造模式中键取块时要返回可放置的「干净」方块或基础材料（`GrapeStringBlock.getCloneItemStack` 返回 `TFCItems.JUTE_FIBER`，`GrapeTrellisPostWithPlantBlock.getCloneItemStack` 返回纯柱，`F/common/blocks/plant/GrapeStringBlock.java:71-75`、`GrapeTrellisPostWithPlantBlock.java:135-139`）——自定义植物方块如果有多形态，别忘了这个。
- **`BlockEntity` 数据的同步**：Firmalife 的葡萄 BE 在改数据后调 `markForSync()`（`F/common/blockentities/GrapePlantBlockEntity.java:74-76,92,300`），否则客户端渲染/工具提示不同步。

---

## 8. 未能核实的项（诚实清单）

1. **`data/tfc/tags/block/fruit_tree_*.json`、`data/tfc/tags/item/plants.json`、`data/minecraft/tags/block/leaves.json` 等文件在 `src-ref` 源码副本中不存在。**
   - 检查过的位置：`Firmalife/src/main/resources/data/` 全量列举 → 只有 `data/firmalife/advancement/**` 与 `data/tfc/tags/worldgen/placed_feature/**`。
   - 但它们在**发行 jar** 中确实存在（用 `System.IO.Compression.ZipFile` 对 `mods/Firmalife-NeoForge-1.21.1-3.0.14.jar` 逐条读取并打印了内容，见上文 JSON 引用），并且 `moddev/inventory/Firmalife.resources.txt` 也列出了这些条目。
   - **生成方式未能核实**：检查了 `Firmalife/resources/*.py`（`advancements.py`、`assets.py`、`constants.py`、`format_lang.py`、`generate_book.py`、`generate_resources.py`、`generate_textures.py`、`i18n.py`、`metal_stuff.py`、`patchouli.py`、`validate_assets.py`、`world_gen.py`），其中没有生成 block/item tag 的脚本片段（在 `resources/*.py` 中搜索 `tags` 只命中 `constants.py:41` 的矿物标签常量与 `patchouli.py` 的文档字符串）。
   - 结论：**只能确认文件存在与内容，无法确认它是手写还是由本副本未包含的某步流程生成**。
2. **`FLPlant.HERB` 的 `stagesByMonth` 数组（`{0,0,0,0,1,1,1,1,0,0,0,0}`）在何处被读取**：`FLPlant.stageFor(Month)` 存在（`F/common/util/FLPlant.java:46-50`），但在 Firmalife 源码中未找到调用点（`PlantBlock.create` 只用到 `getAgeProperty()`）。未能核实它是否被 TFC 侧或客户端模型读取。
3. **草药的世界生成如何挂进群系**：`JAR/data/firmalife/worldgen/placed_feature/plant/*.json` 存在，但对应的 `in_biome` 标签或 biome modifier 在 `src-ref` 副本中未找到对应文件（`data/tfc/tags/worldgen/placed_feature/feature/land_plants.json` 在 jar 中存在，其内容未能逐一核读）。
4. **`Plantable` 的 `specials` / `textures` 在客户端模型里的具体用法**：只确认了消费点在 `F/client/model/{BonsaiPlanterBlockModel,HangingPlanterBlockModel,LargePlanterBakedModel,QuadPlanterBlockModel,TrellisPlanterBlockModel}.java`，未逐个阅读其渲染逻辑。

---

## 9. 附：本文用到的关键文件索引

**Firmalife（`F/`）**

| 文件 | 关键行 | 内容 |
| --- | --- | --- |
| `common/blocks/FLBlocks.java` | 206-207、209-210、212-218、229-238、280-285、342-360 | 全部植物方块注册、花盆联动、注册辅助方法 |
| `common/blocks/plant/FLFruitBlocks.java` | 30-70、72-90 | 自建 `Tree` / `StationaryBush` 枚举 |
| `common/blocks/plant/FLFruitTreeSaplingBlock.java` | 31-43、45-60 | 换 BE type、重写 `setPlacedBy` / `createTree` |
| `common/blocks/plant/FLFruitTreeLeavesBlock.java` | 18-32 | 继承 TFC 叶子 + 蜂群粒子 |
| `common/blocks/plant/FLGrowingFruitTreeBranchBlock.java` | 26-36 | 气候失效时用自建 BE 重置计数器 |
| `common/blocks/plant/IGrape.java` | 10-25 | 葡萄方块通用接口 |
| `common/blocks/plant/GrapeTrellisPostBlock.java` | 34-120 | 棚架柱（拉绳、堆叠、轴向） |
| `common/blocks/plant/GrapeTrellisPostWithPlantBlock.java` | 41-140 | 带植物柱（采摘、找 BE） |
| `common/blocks/plant/GrapeStringBlock.java` | 25-76 | 绳（两端异轴柱才存活） |
| `common/blocks/plant/GrapeStringWithPlantBlock.java` | 36-150 | 带植物绳（采摘、蔓延到柱） |
| `common/blocks/plant/GrapeGroundPlantOnStringBlock.java` | 40-134 | 挂 BE 的地面植株（randomTick 驱动、STAGE） |
| `common/blocks/plant/GrapeFluffBlock.java` | 26-71 | 葡萄绒叶（贴着有植物的柱/绳） |
| `common/blockentities/FLBlockEntities.java` | 19、26-29、42、57、71-79 | 自建 BE type |
| `common/blockentities/GrapePlantBlockEntity.java` | 32-338 | 葡萄 BE 全部逻辑（生长/气候/季节/soilData/brain/NBT） |
| `common/blockentities/FLTickingPlantBlockEntity.java` | 11-37 | 复制 TFC 的静态 helper |
| `common/blockentities/FLBerryBushBlockEntity.java` | 9-25 | 换 type |
| `common/util/FLPlant.java` | 16-131 | 实现 TFC `RegistryPlant` 的自建枚举 |
| `common/util/FLFruit.java` | 6-38 | 果子物品枚举 + vanilla `FoodProperties` |
| `common/util/FLClimateRanges.java` | 13-23 | 气候引用（复用 `ClimateRange.MANAGER`） |
| `common/util/Plantable.java` | 31-199 | 自建温室种植数据管理器 + tooltip |
| `common/util/FLDataManagers.java` | 8-17 | 把自建 DataManager 挂进 TFC 注册表 |
| `common/items/FLItems.java` | 40-43、86-87、108 | 植物相关物品注册 |
| `common/items/GrapeSeedItem.java` | 20-61 | 葡萄播种物品 |
| `common/blocks/Herb.java` | 3-13 | 草药枚举 |
| `common/FLTags.java` | 35-53、81-83、106 | 植物相关标签 |
| `common/FLHelpers.java` | 82-85 | `firmalife:` 命名空间构造 |
| `common/worldgen/FLFruitTreeFeature.java` / `FLFeatures.java` | 20-58 / 21 | 野生果树 feature |
| `client/FLClientForgeEvents.java` | 64-73 | `Plantable` tooltip 注入 |
| `common/blocks/greenhouse/TrellisPlanterBlock.java`、`PlanterType.java` | 11-31 / 11-19 | 温室棚架花盆（葡萄的温室路线） |
| `FirmaLife.java` | 56-60、81、100-106 | 注册顺序 |

**TFC（`T/`）**

| 文件 | 关键行 | 内容 |
| --- | --- | --- |
| `common/blocks/crop/Crop.java` | 49-51、110-142、148-158、172-174 | 枚举不可扩展、工厂分派、`getClimateRange()` |
| `common/blocks/crop/CropBlock.java` | 75-104、122、200-204、226 | 抽象基类、protected 构造器、`growthTick` |
| `common/blocks/crop/DefaultCropBlock.java` | 36-49 | `create` 强制 Crop；protected 构造器可绕开 |
| `common/blocks/crop/DeadCropBlock.java` | 51-65 | 死株（有 Supplier<ClimateRange> 构造器） |
| `common/blocks/crop/CropHelpers.java` | 49-79、172、209 | 生长/肥料/土壤系数（public static） |
| `common/blockentities/CropBlockEntity.java` | 29-57、41-49 | 生长状态存储、public 构造器、`serverTick` |
| `common/blockentities/TFCBlockEntities.java` | 117-118、144 | BE type 绑定固定方块集合 |
| `common/blocks/TFCBlocks.java` | 286-290、307-319 | 植物/作物/果树/香蕉的注册参照 |
| `common/blocks/plant/fruit/FruitBlocks.java` | 57-83、85-145、147-203、205-228、230-257 | 香蕉工厂、**private** 的 PlantableInfo 实现、三个枚举 |
| `common/blocks/plant/fruit/SeasonalPlantBlock.java` | 105-174、181-196、206-210、239-241、269-276 | 季节植物基类 |
| `common/blocks/plant/fruit/FruitTreeLeavesBlock.java` | 93-116、118-124、146-172、225-236 | 叶子（含 `isValid` 用标签） |
| `common/blocks/plant/fruit/FruitTreeSaplingBlock.java` | 86-114、154-186、204-225、240-242 | 树苗（含枯死硬编码） |
| `common/blocks/plant/fruit/GrowingFruitTreeBranchBlock.java` | 65-96、191-212、255-271 | 生长树干 |
| `common/blocks/plant/fruit/FruitTreeBranchBlock.java` | 39-45 | 成熟树干（public 构造器） |
| `common/blocks/plant/fruit/StationaryBerryBushBlock.java` | 61-87、89-141、201-203 | 固定灌木（含死株硬编码） |
| `common/blocks/plant/fruit/Lifecycle.java` | 12-33 | 季节枚举与推进语义 |
| `common/blockentities/TickingPlantBlockEntity.java` | 24-49、29-39 | **静态 helper 写死 TFC 的 type** |
| `common/blockentities/BerryBushBlockEntity.java` | 24-40 | protected 构造器 |
| `common/items/PlantableInfo.java` | 28-31、121-138 | 可实现的公开接口 |
| `common/items/SeedItem.java` | 23-53 | 参考实现（构造器强制 Crop） |
| `util/registry/RegistryPlant.java` | 13-36 | 可实现的公开接口 |
| `util/registry/RegistrationHelpers.java` | 67、89-94 | 方块/BE 注册（BE 绑定方块集合） |
| `util/data/DataManager.java` | 56-80、103-110、175-194 | 数据管理器目录推导、懒引用 |
| `util/data/DataManagers.java` | 36-39、45-61 | `MANAGERS`（命名空间 tfc）与内置管理器列表 |
| `util/climate/ClimateRange.java` | 27-31、49-61 | `climate_range` 数据格式与判定 |
| `util/climate/ClimateRanges.java` | 15-24 | TFC 自己的气候引用写法（对照） |
| `common/component/food/FoodDefinition.java` / `FoodData.java` | 29-33 / 33,48 | `tfc/food/*.json` 的字段 |
| `common/blocks/ExtendedProperties.java` | 113-137 | ticker 绑定的断言约束 |
| `common/blocks/plant/PlantBlock.java` | 84-98、219-227 | `PlantBlock.create` 与默认方块状态 |
| `common/blockentities/TickingPlantBlockEntity.java` | 29-39 | （重复强调）静态 helper |
| `TerraFirmaCraft.java` | 178 | TFC 把 `DataManagers.MANAGERS` 挂到 bus |

**实测证据留档**（本次调查生成，可删除）：
- `moddev/docs/_work/_fljar/dump.txt`：climate_range / plantable / tag / food 的原始 JSON
- `moddev/docs/_work/_fljar/dump2.txt`：worldgen / blockstate 的原始 JSON
