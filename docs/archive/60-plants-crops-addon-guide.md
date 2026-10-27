# 在 TFC 中添加新作物 / 果树 / 灌木 / 棕榈式树 —— 可行性分析与实施方案

> 目标：搞清楚「TFC 4.2.10 里的植物类内容是怎么搭起来的」，以及**附属模组要加一种新的作物/果树/灌木/树，
> 到底能复用多少、必须自己写多少**。
>
> 全部结论来自 TFC 4.2.10 的反编译源码（`moddev/src-ref/TFC-decompiled`）与 jar 的 `javap` 签名，
> 关键可用性判断都经过了「构造器可见性」实测（`javap -p`）。

---

## 0. 结论速览（先看这张表）

| 想加什么 | TFC 侧的扩展点 | 能否直接复用 | 推荐方案 | 工作量 |
|---|---|---|---|---|
| **新作物**（小麦/番茄那类，种在农田上、按阶段生长、可收获） | `Crop` 枚举（**不可扩展**）；`CropBlock` 体系 | 方块基类**可继承**；`CropBlockEntity` 可复用；气候数据可纯 JSON | 写 `class MyCropBlock extends CropBlock`（或继承 `DefaultCropBlock` 等），自建枚举/映射，注册自己的方块+种子物品 | 中 |
| **新果树**（樱桃/苹果那类，树苗→枝条→树叶结果） | `FruitBlocks.Tree` 枚举（**不可扩展**）；4 个方块类 | **构造器全是 public，可直接 `new`** | 不用枚举，直接 `new FruitTreeSaplingBlock / GrowingFruitTreeBranchBlock / FruitTreeBranchBlock / FruitTreeLeavesBlock` | 小 |
| **新灌木**（浆果丛） | `FruitBlocks.StationaryBush` / `SpreadingBush` 枚举（**不可扩展**）；4 个方块类 | **构造器全是 public，可直接 `new`** | 直接 `new StationaryBerryBushBlock` / `SpreadingBushBlock` / `SpreadingCaneBlock` / `WaterloggedBerryBushBlock` | 小 |
| **棕榈式大型植物**（香蕉那种，一株多格、结果后可采） | `BananaPlantBlock` + `BananaSaplingBlock`（**非枚举，独立注册**） | **构造器 public，可直接 `new`** | 照抄香蕉的注册方式，一套 = 树苗 + 植物体（+ 盆栽） | 小 |
| **新树种**（棕榈、橡树那类完整木材树） | `RegistryWood` 接口（**public**）+ `Wood.BlockType` 的 `create/nameFor/createBlockItem`（**public**） | **可以整套复用** | 实现 `RegistryWood` + 用 `Wood.BlockType` 生成 40+ 种木制品方块 + 自己的 `TreeGrower` | 中（但代码极少） |
| **野生植物**（草、花、藤、珊瑚那类） | `Plant` 枚举（**不可扩展**） | 方块类可继承 | 仿 `PlantBlock` 系；自然生成见 §8 | 中 |
| **让新植物自然生成** | TFC 的 20 个植物 feature + 15 个 placement modifier | **feature 可直接复用**（但方块必须继承对应 TFC 类） | 写 `configured_feature` + `placed_feature` + 往 `#tfc:feature/land_plants` tag 追加 | 小 |

**一句话总结**：TFC 把「植物种类」都做成了**枚举**（不可扩展），但把「植物行为」都做成了**可继承/可直接实例化的 public 类**。
所以附属模组的正确姿势是：**自建种类集合，复用 TFC 的行为类**。除了作物需要写一个自己方块子类，其余三类几乎只是「参数拼装 + 注册」。

### 0.1 实测验证状态（重要）

本节的标志性结论**已在 `moddev/demo-mymod/` 里实际编译通过**（`gradle build` → `BUILD SUCCESSFUL in 20s`，
产物 `MyMod-NeoForge-1.21.1-0.0.0-indev.jar`，零警告）：

| 验证项 | 结果 | 对应源码 |
|---|---|---|
| 直接 `new StationaryBerryBushBlock(props, item, Lifecycle[12], Supplier<ClimateRange>)` | ✅ 通过 | `demo-mymod/.../common/blocks/MyBushes.java` |
| `DataManager.Reference<ClimateRange>` 当 `Supplier<ClimateRange>` 直接传参 | ✅ 通过 | 同上 |
| 继承 `CropBlock` 的子类（实现 `getAgeProperty` / `postGrowthTick` / `die`） | ✅ 通过 | `demo-mymod/.../common/blocks/MyCropBlock.java` |
| `new DeadCropBlock(props, Supplier<ClimateRange>)`（绕开 `Crop` 枚举） | ✅ 通过 | `demo-mymod/.../common/blocks/MyBlocks.java` |
| `RegistrationHelpers.registerBlock(BLOCKS, null, name, supplier, null)`（不生成方块物品） | ✅ 通过 | 同上 |
| 复用 `TFCBlockEntities.CROP` / `.BERRY_BUSH` 作方块实体 | ✅ 通过 | 同上 |
| 实现 `RegistryWood` + 用 `Wood.BlockType.create/nameFor/createBlockItem` 生成整套木材方块 | ✅ 通过（修正 1 处后） | `demo-mymod/.../common/blocks/MyWoods.java`、`MyWoodsBlocks.java` |
| 果树四件套（sapling + growing_branch + branch + leaves）全部直接 `new`，循环引用用 `Supplier` 打破 | ✅ 通过 | `demo-mymod/.../common/blocks/MyFruitTrees.java` |
| 自定义 `SeasonalPlantBlock` 子类（香蕉式高秆植物，但**气候自主**） | ✅ 通过 | `demo-mymod/.../common/blocks/MyTallPlantBlock.java` |
| 自建 `BlockEntityType`（§2.2.1 方案 B：BE 子类 + `Builder.of` 显式注入自己的类型） | ✅ 通过 | `demo-mymod/.../common/blockentities/MyBerryBushBlockEntity.java`、`MyBlockEntities.java` |

**过程中发现的唯一一个真实编译错误**（已修正，值得记录的坑）：

```java
// ❌ 这样写编译不过：
//    错误: 不兼容的类型: DeferredHolder<Block,CAP#1> 无法转换为 Supplier<Block>
@Override public Supplier<Block> getBlock(Wood.BlockType type) {
    return MyWoodsBlocks.WOODS.get(this).get(type);
}
// ✅ 必须用 lambda 包一层：
@Override public Supplier<Block> getBlock(Wood.BlockType type) {
    return () -> MyWoodsBlocks.WOODS.get(this).get(type).get();
}
```

TFC 自己能直接返回，是因为它的 `TFCBlocks.Id<Block>` record 本身实现了 `Supplier<Block>`；
附属模组拿到的 `DeferredHolder<Block, ? extends Block>` 带通配符，赋给 `Supplier<Block>` 不成立。

> 也就是说：**§3 作物、§4 果树、§5 灌木、§6 香蕉式植物、§7 新树种、§2.2.1 的两种 BE 方案
> 全部已在 `demo-mymod` 中编译验证通过**
> （最终产物 `MyMod-NeoForge-1.21.1-0.0.0-indev.jar`，21811 字节，零警告；
> 演示源码共 9 个类：`MyCropBlock`、`MyBushes`、`MyFruitTrees`、`MyTallPlantBlock`、`MyWoods`、
> `MyWoodsBlocks`、`MyBerryBushBlockEntity`、`MyBlockEntities`、`MyBlocks`）。
>
> ⚠️ 编译通过 ≠ 运行时正确：**BE 类型绑定（§2.2.1）与 TFC 静态 helper 的静默失效是运行时问题**，
> 需要实际进游戏验证（放置/采摘/季节推进）。这两点已在 §2.2.1 与 §9 标注。

---

## 1. TFC 植物内容的五套平行体系

这是理解一切的前提：TFC 的植物**不是一个统一体系**，而是五套独立实现，各自有自己的方块、方块实体、状态模型与注册表。

| 体系 | 种类来源 | 核心方块类 | 状态存哪 | 生命周期 | 数据驱动部分 |
|---|---|---|---|---|---|
| **野生植物** | `Plant` 枚举（507 行，上百种） | `PlantBlock` / `BodyPlantBlock` / `TallWaterPlantBlock` / `CreepingPlantBlock` / `EpiphytePlantBlock` … | BlockState（`AGE` 等） | 无 | `data/tfc/tfc/climate_range/*` 部分 |
| **作物** | `Crop` 枚举（29 种） | `DefaultCropBlock` / `DoubleCropBlock` / `SpreadingCropBlock` / `PickableCropBlock` / `FloodedCropBlock` / `ClimbingCropBlock` | **`CropBlockEntity`**（growth/yield/expiry/NPK） | 无（按生长进度） | `climate_range` 必填 |
| **果树** | `FruitBlocks.Tree` 枚举（8 种） | `FruitTreeSaplingBlock` + `GrowingFruitTreeBranchBlock` + `FruitTreeBranchBlock` + `FruitTreeLeavesBlock` | `TickCounterBlockEntity`（树苗）/ `BerryBushBlockEntity`（树叶） | `Lifecycle[12]` | `climate_range` 必填 |
| **灌木** | `FruitBlocks.StationaryBush`（6）+ `SpreadingBush`（4）+ 蔓越莓（单独） | `StationaryBerryBushBlock` / `SpreadingBushBlock`+`SpreadingCaneBlock` / `WaterloggedBerryBushBlock` | `BerryBushBlockEntity` | `Lifecycle[12]` | `climate_range` 必填 |
| **大型热带植物** | 香蕉（单独，非枚举） | `BananaPlantBlock` + `BananaSaplingBlock` | `BerryBushBlockEntity` / `TickCountingPlantBlockEntity` | `Lifecycle[12]` | 无（气候写死在代码里？见 §6） |
| **木材/树** | `Wood` 枚举（20 种） | `Wood.BlockType` 枚举一次性生成 40+ 种方块（log/planks/fence/barrel/…） | 无 | 无 | 树形由 `configured_feature/tree/*.json` 决定 |

**关键洞察**：
- 「果树」「灌木」「香蕉」三者**共用同一个基类** `SeasonalPlantBlock`（public abstract）+ 同一个 `BerryBushBlockEntity` + 同一个 `Lifecycle` 季节模型。
- 「作物」是唯一把生长进度放在**方块实体**里的体系（`CropBlockEntity`），也是唯一需要 NPK 养分与农田的体系。
- 「树（Wood）」与其他四套**完全无关**：它是「一个枚举 × 一个 BlockType 枚举」的批量生成器。

---

## 2. 通用基础设施（所有植物内容都会碰到）

### 2.1 方块属性：`ExtendedProperties` + `ExtendedBlock`

植物方块几乎都接收 `ExtendedProperties`（而不是原版 `BlockBehaviour.Properties`），
通过它绑定方块实体与 ticker：

```java
ExtendedProperties.of(MapColor.PLANT)
    .noCollission()
    .randomTicks()
    .strength(0.4f)
    .sound(SoundType.CROP)
    .flammable(60, 30)
    .pushReaction(PushReaction.DESTROY)
    .blockEntity(TFCBlockEntities.CROP)              // 关键：绑定生长用 BE
    .serverTicks(CropBlockEntity::serverTick)        // 关键：绑定 ticker
```

TFC 的作物/果树/灌木属性能否直接用，取决于方块类是否实现了 `IForgeBlockExtension`（TFC 的植物类都实现了）。

### 2.2 相关方块实体（**复用性已核实**）

| BE 类 | 构造器可见性 | 用途 | 附属模组能否复用 |
|---|---|---|---|
| `CropBlockEntity` | `public (BlockPos, BlockState)` 与 `public (BlockEntityType<?>, BlockPos, BlockState)` | 存作物生长进度；`onCalendarUpdate` 里回调 `ICropBlock.growthTick(...)` | ✅ **完全可复用**（它只依赖 `ICropBlock` 接口，不依赖 `Crop` 枚举） |
| `BerryBushBlockEntity` | `protected (BlockPos, BlockState)` / `protected (BlockEntityType<?>, ...)` | 存 `lastPickedTick`、`stemPos`、`growthsRemaining` | ✅ **可继承**（protected 构造器对子类可见） |
| `TickCounterBlockEntity` | 需实测 | 计时（树苗长成、枯萎判定） | ✅ 可直接用 `TFCBlockEntities.TICK_COUNTER` |
| `TickingPlantBlockEntity` | 需实测 | `BerryBushBlockEntity` 的父类 | ✅ 同上 |
| `TFCBlockEntities.BERRY_BUSH` / `.CROP` / `.TICK_COUNTER` / `.TICK_COUNTING_PLANT` | — | 现成的 BE 类型注册项 | ✅ **直接引用即可**，无需自己注册 BE |

> **重要**：`CropBlockEntity.onCalendarUpdate` 内部是
> `if (block instanceof ICropBlock crop) crop.growthTick(level, pos, state, this);`
> —— 只要你的方块实现了 `ICropBlock`，TFC 的作物生长推进就会自动作用到你的作物上。

#### 2.2.1 ⚠️ 必须做的决定：方块实体类型能不能「借用」TFC 的？

TFC 的方块实体类型是**按方块绑定**的（`BlockEntityType.Builder.of(factory, blocks...)`，见
`RegistrationHelpers.register(BlockEntityDeferredRegister, name, factory, block)`），
所以 `tfc:crop` / `tfc:berry_bush` 这些类型**只认 TFC 自己的方块**。这产生一个分叉：

| 方案 | 写法 | 优点 | 代价 |
|---|---|---|---|
| **A. 借用 TFC 类型**（demo 用的） | `ExtendedProperties...blockEntity(TFCBlockEntities.BERRY_BUSH)` | 极省事；TFC 的静态 helper（`BerryBushBlockEntity.reset` / `resetPickedTick`、`TickingPlantBlockEntity.*`）**全部正常工作** | 该类型的 `isValid(你的方块)` 返回 `false`——属于「非官方用法」，若有代码显式走 `isValid` 校验会不一致 |
| **B. 自建 BE 类型**（Firmalife 的做法） | 注册自己的 `BlockEntityType`，工厂用 lambda 注入自己的类型 | 规范、无隐患 | **必须同时覆写所有调用 TFC 静态 helper 的父类方法**，否则静默失效 |

**为什么方案 B 需要额外工作**：TFC 的静态 helper 把类型**写死**了——

```java
// BerryBushBlockEntity.java
public static void reset(Level level, BlockPos pos) {
    level.getBlockEntity(pos, TFCBlockEntities.BERRY_BUSH.get()).ifPresent(TickCounterBlockEntity::resetCounter);
}
public static void resetPickedTick(Level level, BlockPos pos) {
    level.getBlockEntity(pos, TFCBlockEntities.BERRY_BUSH.get()).ifPresent(TickingPlantBlockEntity::resetLastPickedCounter);
}
// TickingPlantBlockEntity 同样写死 TFCBlockEntities.TICK_COUNTING_PLANT
```

而 `Level.getBlockEntity(pos, type)` 是 **`==` 比较类型引用**：自建类型 → 返回 `empty` →
**不报错、不生效**。受影响的父类方法：
- `SeasonalPlantBlock.setPlacedBy(...)`（放置时重置计数器）
- `SeasonalPlantBlock.useItemOn(...)` 里的 `BerryBushBlockEntity.resetPickedTick(level, pos)`（**采摘后重置计时**，不生效会导致结果节奏错乱）

Firmalife 的应对是：自建 `FLTickingPlantBlockEntity`（复制一套自己的静态 helper）
+ `FLFruitTreeSaplingBlock` 里覆写 `setPlacedBy`/`createTree`/`randomTick` 并调用自己的 helper
（见 `_work/g-firmalife-plants.md`，以及 Firmalife 源码 `common/blocks/plant/FLFruitTreeSaplingBlock.java`）。

**本项目的建议**：
1. 先用**方案 A** 快速做出可玩内容（`demo-mymod` 已验证编译通过）；
2. 若运行中发现「采摘后不再结果」这类异常，再切到方案 B：
   ```java
   // 1) 自己的 BE 子类（BerryBushBlockEntity 的构造器是 protected，可被子类调用）
   public class MyBerryBushBlockEntity extends BerryBushBlockEntity {
       public MyBerryBushBlockEntity(BlockPos pos, BlockState state) { super(MyBlockEntities.MY_BUSH.get(), pos, state); }
   }
   // 2) 注册自己的类型（工厂必须显式注入自己的 type，不能直接用 BerryBushBlockEntity::new）
   public static final DeferredHolder<BlockEntityType<?>, BlockEntityType<MyBerryBushBlockEntity>> MY_BUSH =
       BLOCK_ENTITIES.register("my_bush", () -> BlockEntityType.Builder.of(
           MyBerryBushBlockEntity::new, MyBlocks.MY_BUSH.get()).build(null));
   ```
   ⚠️ 注意 `BerryBushBlockEntity::new` 会匹配到那个用 `TFCBlockEntities.BERRY_BUSH.get()` 的单参构造器 →
   **必须写自己的子类**，否则 BE 类型仍然是 TFC 的，自建类型形同虚设。

### 2.3 气候：`ClimateRange`（**完全数据驱动**）

```java
public record ClimateRange(int minHydration, int maxHydration, int hydrationWiggleRange,
                           float minTemperature, float maxTemperature, float temperatureWiggleRange) {
    public static final DataManager<ClimateRange> MANAGER =
        new DataManager<>(Helpers.identifier("climate_range"), CODEC, STREAM_CODEC);
    public static final ClimateRange NOOP = new ClimateRange(0, 100, 0, -100f, 100f, 0f);
    // checkHydration / checkTemperature / checkBoth → Result{LOW, VALID, HIGH}
}
```

**数据包路径**：`data/<你的命名空间>/tfc/climate_range/<名字>.json`

```json
{
  "min_hydration": 20,
  "max_hydration": 85,
  "hydration_wiggle_range": 5,
  "min_temperature": -5.0,
  "max_temperature": 25.0,
  "temperature_wiggle_range": 3.0
}
```

**取用方式**（TFC 用固定命名空间，附属模组要换成自己的）：

```java
// TFC 的做法（ClimateRanges.java）
private static DataManager.Reference<ClimateRange> register(String name) {
    return ClimateRange.MANAGER.getReference(Helpers.identifier(name.toLowerCase(Locale.ROOT)));  // tfc:xxx
}
// 附属模组的做法
public static final DataManager.Reference<ClimateRange> MY_CROP_RANGE =
    ClimateRange.MANAGER.getReference(ResourceLocation.fromNamespaceAndPath("mymod", "my_crop"));
```

> `DataManager.Reference<T>` 是**惰性引用**（可安全用于静态字段初始化期）。
> `ClimateRange.NOOP` 表示「无气候限制」。

### 2.4 季节：`Lifecycle`（12 个月的生命周期表）

```java
public enum Lifecycle implements StringRepresentable {
    DORMANT, HEALTHY, FLOWERING, FRUITING;   // ordinal 顺序有意义
    public boolean active();                  // != DORMANT
    public Lifecycle advanceTowards(Lifecycle other);   // 逐级推进（不会从 FRUITING 继续升）
}
```

TFC 的用法是**一个长度必须等于 12 的数组**（代表 12 个月，`Month.ordinal()` 索引）：

```java
// 例：葡萄？（取自 FruitBlocks.Tree.RED_APPLE）
new Lifecycle[]{ DORMANT, DORMANT, HEALTHY, HEALTHY, HEALTHY, HEALTHY, HEALTHY,
                 FLOWERING, FLOWERING, FRUITING, DORMANT, DORMANT }
```

`SeasonalPlantBlock` 构造器里有硬断言：
```java
Preconditions.checkArgument(lifecycle.length == 12, "Lifecycle length must be 12");
```
**长度不是 12 会直接抛异常**。

植物的每月行为：`SeasonalPlantBlock.onUpdate(...)` 会取
`Calendars.SERVER.getHemispheralCalendarMonthOfYear(SolarCalculator.getInNorthernHemisphere(pos, level))`
得到当月应有的 `Lifecycle`，再与当前状态比对推进；同时用 `ClimateRange.checkBoth(水合, 平均温度, false)` 判定，
不满足则强制回到 `DORMANT`。

> **南北半球会自动取反**（`getHemispheralCalendarMonthOfYear`），所以生命周期表按**北半球**写即可。

### 2.5 物品侧：`PlantableInfo`（tooltip 自动显示生长条件）

```java
public interface PlantableInfo {
    default @Nullable PlantNutrients getNutrientsInfo()  { return null; }  // record(float nitrogen, float phosphorus, float potassium)
    default @Nullable ClimateRange getClimateRangeInfo() { return null; }
    default @Nullable List<Lifecycle> getLifecycleInfo() { return null; }
    default int getGrowthTimeInfo() { return -1; }
}
```

TFC 的 tooltip 逻辑（`PlantableInfo.addTooltipInfo`，由 `TFCItems` 侧的 tooltip 注册调用）会：
按住 Shift 时显示**气候温度区间、水合区间、NPK 消耗、生长耗时、以及「健康/结果」的起始季节**。
**附属模组只要让自己的种子/树苗物品实现这个接口，就能免费获得这套 tooltip**（含中文语言键复用 `tfc.tooltip.plantable.*`）。

`TFCItems.SeedItem` 的实现（可直接照抄）：

```java
public class SeedItem extends ItemNameBlockItem implements PlantableInfo {
    protected final Block deadBlock;
    private final PlantableInfo.PlantNutrients nutrients;
    private final Supplier<ClimateRange> climateRange;

    public SeedItem(Crop crop, Block block, Block deadBlock, Item.Properties properties) {
        super(block, properties);
        this.deadBlock = deadBlock;
        this.nutrients = new PlantableInfo.PlantNutrients(crop.getNitrogen(), crop.getPhosphorous(), crop.getPotassium());
        this.climateRange = crop.getClimateRange();
    }
    @Override public PlantNutrients getNutrientsInfo() { return nutrients; }
    @Override public ClimateRange getClimateRangeInfo() { return climateRange.get(); }
    @Override public void registerBlocks(Map<Block, Item> blockToItemMap, Item item) {
        super.registerBlocks(blockToItemMap, item);
        blockToItemMap.put(deadBlock, item);     // 死株掉种子
    }
}
```

> 注意它把 `deadBlock` 也映射到同一个物品（死掉的作物被破坏时掉回种子）。

---

## 3. 添加新作物

### 3.1 TFC 是怎么做的

`Crop` 枚举（29 种）用**重载构造器**选出 6 种形态，每种形态一次性决定三件事
（正常方块 / 死株 / 野生株）：

```java
// 单格作物（小麦、胡萝卜…）
private Crop(float n, float p, float k, int singleBlockStages) {
    this(n, p, k,
        self -> DefaultCropBlock.create(crop(), singleBlockStages, self),
        self -> new DeadCropBlock(dead(), self.getClimateRange()),
        self -> new WildCropBlock(dead().randomTicks()));
}
// 蔓延型结果作物（南瓜、甜瓜）
private Crop(float n, float p, float k, int stages, Supplier<Supplier<? extends Block>> fruit) { ... SpreadingCropBlock.create(...) ... }
// 可采摘型（番茄、甜椒）
private Crop(float n, float p, float k, int stages, Supplier<Supplier<? extends Item>> fruit1, Supplier<Supplier<? extends Item>> fruit2) { ... PickableCropBlock.create(...) ... }
// 水田作物（水稻）
private Crop(..., boolean flooded) { ... FloodedCropBlock.create(...) ... }
// 双格/攀爬作物（玉米、大豆、甘蔗…）
private Crop(..., int bottom, int top, boolean requiresStick) { ... DoubleCropBlock/ClimbingCropBlock ... }
```

**注册（`TFCBlocks.java:288-290`）**：

```java
public static final Map<Crop, Id<Block>> CROPS      = Helpers.mapOf(Crop.class, crop -> registerNoItem("crop/" + crop.name(), crop::create));
public static final Map<Crop, Id<Block>> DEAD_CROPS = Helpers.mapOf(Crop.class, crop -> registerNoItem("dead_crop/" + crop.name(), crop::createDead));
public static final Map<Crop, Id<Block>> WILD_CROPS = Helpers.mapOf(Crop.class, crop -> register("wild_crop/" + crop.name(), crop::createWild));
```

**种子与食物（`TFCItems.java:145`）**：

```java
public static final Map<Crop, ItemId> CROP_SEEDS = Helpers.mapOf(Crop.class,
    crop -> register("seeds/" + crop.name(), () -> new SeedItem(crop, TFCBlocks.CROPS.get(crop).get(), TFCBlocks.DEAD_CROPS.get(crop).get(), new Item.Properties())));
```

### 3.2 可复用性（实测的构造器可见性）

| 类 | 构造器 | 可用 `create(...)` 静态工厂？ |
|---|---|---|
| `CropBlock`（抽象基类） | `protected CropBlock(ExtendedProperties, int maxAge, Supplier<Block> dead, Supplier<Item> seeds, float n, float p, float k, Supplier<ClimateRange>)` | — |
| `DefaultCropBlock` | **protected**（需子类） | `public static DefaultCropBlock create(ExtendedProperties, int stages, Crop crop)` ← **要求 TFC 的 `Crop` 枚举** |
| `DoubleCropBlock` | **protected** | `create(..., Crop)` ← 同样要求枚举 |
| `SpreadingCropBlock` | **protected** | 同上 |
| `PickableCropBlock` | **protected** | 同上 |

**结论**：`create(...)` 工厂全部要求 `Crop` 枚举 → 附属模组**不能用工厂**；
但 `CropBlock` 的 protected 构造器对子类可见 → **写一个自己的子类即可**，并且能完整复用生长逻辑。

### 3.2.1 补充实测（`javap -p`，逐个类核对了构造器可见性）

| 类 | 构造器 | 附属模组能否直接用 |
|---|---|---|
| `DeadCropBlock`（死株） | `public (ExtendedProperties, Supplier<ClimateRange>)` 与 `public (ExtendedProperties, Crop)` | ✅ **可以直接 `new`**（用第一个重载即可完全绕开 `Crop` 枚举） |
| `WildCropBlock`（野生单格） | `public (ExtendedProperties)` | ✅ 可直接 `new` |
| `WildDoubleCropBlock`（野生双格） | `public (ExtendedProperties)` | ✅ 可直接 `new` |
| `WildSpreadingCropBlock`（野生蔓延） | `public (ExtendedProperties, Supplier<Supplier<Block>> fruit)` | ✅ 可直接 `new` |
| `DefaultCropBlock` / `DoubleCropBlock` / `SpreadingCropBlock` / `PickableCropBlock` / `FloodedCropBlock` / `ClimbingCropBlock` / `PickableClimbingCropBlock` | 全部 **protected** | ❌ **需要写子类** |

> **这是本节最有价值的一条**：新增一种作物，**你只需要写 1 个类**（继承某个 `*CropBlock` 的子类），
> 死株可以直接 `new DeadCropBlock(props, 气候引用)`，野生株可以直接 `new WildCropBlock(props)`。
>
> 示例（死株与野生株都不用自己写）：
> ```java
> // TFC 的 Crop.dead() 是 private，附属模组照它的内容自己写一份等价的属性工厂即可：
> private static ExtendedProperties deadProps() {
>     return ExtendedProperties.of(MapColor.PLANT).noCollission().randomTicks().strength(0.4f)
>         .sound(SoundType.CROP).flammable(60, 30).pushReaction(PushReaction.DESTROY);
> }
>
> MY_DEAD_CROP = registerNoItem("dead_crop/my_crop",
>     () -> new DeadCropBlock(deadProps(), MY_CROP_RANGE));        // ← 绕开 Crop 枚举的 public 重载
> MY_WILD_CROP = register("wild_crop/my_crop",
>     () -> new WildCropBlock(deadProps().randomTicks()));
> ```
> （两者都不需要绑定方块实体。）

### 3.3 实施骨架

```java
package com.example.mymod.common.blocks.crop;

/** 新增一种作物：单格、6 个生长阶段。 */
public class MyCropBlock extends CropBlock {
    private static final IntegerProperty AGE = TFCBlockStateProperties.getAgeProperty(5); // stages-1

    public MyCropBlock(ExtendedProperties properties,
                       Supplier<? extends Block> dead, Supplier<? extends Item> seeds,
                       float n, float p, float k, Supplier<ClimateRange> climateRange) {
        super(properties, 5, dead, seeds, n, p, k, climateRange);
    }

    @Override public IntegerProperty getAgeProperty() { return AGE; }

    /** 生长推进后由 ICropBlock.growthTick 调用（把 BE 里的 growth 同步到 BlockState） */
    @Override protected void postGrowthTick(Level level, BlockPos pos, BlockState state, CropBlockEntity crop) {
        int age = crop.getGrowth() == 1.0f ? getMaxAge() : (int) (crop.getGrowth() * getMaxAge());
        level.setBlockAndUpdate(pos, state.setValue(getAgeProperty(), age));
    }

    /** 气候不适宜时变成死株 */
    @Override public void die(Level level, BlockPos pos, BlockState state, boolean fullyGrown) {
        level.setBlockAndUpdate(pos, MyBlocks.MY_DEAD_CROP.get().defaultBlockState()
            .setValue(DeadCropBlock.MATURE, fullyGrown));
    }
}
```

注册（**注意：作物方块本身没有物品，物品是"种子"**）：

```java
// 自己的枚举/常量表（不能用 TFC 的 Crop 枚举）
public static final DeferredHolder<Block, MyCropBlock> MY_CROP =
    RegistrationHelpers.registerBlock(BLOCKS, null, "crop/my_crop",
        () -> new MyCropBlock(
            ExtendedProperties.of(MapColor.PLANT).noCollission().randomTicks().strength(0.4f)
                .sound(SoundType.CROP).flammable(60, 30).pushReaction(PushReaction.DESTROY)
                .blockEntity(TFCBlockEntities.CROP)                    // ★ 复用 TFC 的作物 BE
                .serverTicks(CropBlockEntity::serverTick),             // ★ 复用 TFC 的 ticker
            MyBlocks.MY_DEAD_CROP, MyItems.MY_SEEDS, 0.4f, 0.3f, 0.5f,
            MyClimateRanges.MY_CROP_RANGE),
        null);   // 第二个参数为 null → 不生成方块物品
```

> ⚠️ `RegistrationHelpers.registerBlock(blocks, items, name, supplier, blockItemFactory)` 的
> `items` 与 `blockItemFactory` 允许传 `null`（TFC 内部的 `registerNoItem` 就是这么做的）。

种子物品（复用 TFC 的 `PlantableInfo` 机制）：

```java
public class MySeedItem extends ItemNameBlockItem implements PlantableInfo {
    private final PlantableInfo.PlantNutrients nutrients = new PlantableInfo.PlantNutrients(0.4f, 0.3f, 0.5f);
    public MySeedItem(Block crop, Item.Properties properties) { super(crop, properties); }
    @Override public PlantNutrients getNutrientsInfo() { return nutrients; }
    @Override public ClimateRange getClimateRangeInfo() { return MyClimateRanges.MY_CROP_RANGE.get(); }
}
```

### 3.4 必须提供的资源与数据

| 类型 | 路径 | 说明 |
|---|---|---|
| 气候数据 | `data/mymod/tfc/climate_range/my_crop.json` | **必需**，否则气候恒为 NOOP（作物到处能种） |
| 食物数据 | `data/mymod/tfc/food/<产物>.json` | 若产物是可食用收获物，必需（否则无营养/不腐烂） |
| 方块状态 | `assets/mymod/blockstates/crop/my_crop.json` | 每个 age 一个模型（TFC 用 `crop/<name>_stage<N>` 贴图约定） |
| 模型 | `assets/mymod/models/block/crop/my_crop_stage0..5.json` | 6 个阶段 |
| 贴图 | `assets/mymod/textures/block/crop/my_crop_stage0..5.png` | 同上 |
| 物品模型 | `assets/mymod/models/item/seeds/my_crop.json` | 种子物品 |
| 掉落表 | `data/mymod/loot_table/blocks/crop/my_crop.json` | 成熟收获；TFC 用 `CropYieldProvider` 处理产量 |
| 语言 | `assets/mymod/lang/zh_cn.json` | `block.mymod.crop.my_crop`、`item.mymod.seeds.my_crop` |

---

## 4. 添加新果树

### 4.1 TFC 的四件套结构

一棵 TFC 果树由 **4 个方块**组成，形成一条生长链：

```
树苗(sapling)  --随机tick/计时-->  生长中的枝条(growing_branch)  -->  枝条(branch)  +  树叶(leaves)
   ↑ TickCounterBlockEntity              ↑ TickCountingPlantBlockEntity        ↑ BerryBushBlockEntity（结果/采摘）
```

`FruitBlocks.Tree` 枚举（8 种）为每种果树一次性创建这 4 个（外加盆栽树苗）：

```java
public Block createSapling()       { return new FruitTreeSaplingBlock(props, FRUIT_TREE_GROWING_BRANCHES.get(this), TFCConfig.SERVER.fruitSaplingGrowthTicks.get(this), ClimateRanges.FRUIT_TREES.get(this), stages); }
public Block createGrowingBranch() { return new GrowingFruitTreeBranchBlock(props, FRUIT_TREE_BRANCHES.get(this), FRUIT_TREE_LEAVES.get(this), ClimateRanges.FRUIT_TREES.get(this)); }
public Block createBranch()        { return new FruitTreeBranchBlock(props, ClimateRanges.FRUIT_TREES.get(this)); }
public Block createLeaves()        { return new FruitTreeLeavesBlock(props, TFCItems.FOOD.get(product), stages, ClimateRanges.FRUIT_TREES.get(this), floweringLeavesColor); }
```

### 4.2 可直接 `new`（**实测结论**）

以下构造器**全部是 public**，附属模组不需要继承，直接实例化即可：

```java
FruitTreeSaplingBlock(ExtendedProperties, Supplier<? extends Block> growingBranch, Supplier<Integer> ticksToGrow, Supplier<ClimateRange>, Lifecycle[])
FruitTreeLeavesBlock (ExtendedProperties, Supplier<? extends Item> product, Lifecycle[], Supplier<ClimateRange>, int floweringLeavesColor)
GrowingFruitTreeBranchBlock(ExtendedProperties, Supplier<? extends Block> branch, Supplier<? extends Block> leaves, Supplier<ClimateRange>)
FruitTreeBranchBlock(ExtendedProperties, Supplier<ClimateRange>)
```

### 4.3 实施骨架

```java
// 1) 气候（数据驱动）
public static final DataManager.Reference<ClimateRange> MY_TREE_RANGE =
    ClimateRange.MANAGER.getReference(ResourceLocation.fromNamespaceAndPath("mymod", "my_tree"));

// 2) 季节表（12 个月，按北半球）
private static final Lifecycle[] MY_TREE_STAGES = {
    DORMANT, DORMANT, HEALTHY, HEALTHY, HEALTHY, HEALTHY, HEALTHY, FLOWERING, FLOWERING, FRUITING, DORMANT, DORMANT
};

// 3) 四个方块（注意树叶要引用枝条/生长枝，枝条要引用树叶 → 用 Supplier 打破循环）
public static final DeferredHolder<Block, ?> MY_TREE_SAPLING = reg("plant/my_tree_sapling",
    () -> new FruitTreeSaplingBlock(plantProps().blockEntity(TFCBlockEntities.TICK_COUNTING_PLANT),
        MY_TREE_GROWING_BRANCH, () -> 8 * 24000, MY_TREE_RANGE, MY_TREE_STAGES), true);

public static final DeferredHolder<Block, ?> MY_TREE_GROWING_BRANCH = regNoItem("plant/my_tree_growing_branch",
    () -> new GrowingFruitTreeBranchBlock(plantProps().blockEntity(TFCBlockEntities.TICK_COUNTING_PLANT).cloneEmpty(),
        MY_TREE_BRANCH, MY_TREE_LEAVES, MY_TREE_RANGE));

public static final DeferredHolder<Block, ?> MY_TREE_BRANCH = regNoItem("plant/my_tree_branch",
    () -> new FruitTreeBranchBlock(woodProps(), MY_TREE_RANGE));

public static final DeferredHolder<Block, ?> MY_TREE_LEAVES = reg("plant/my_tree_leaves",
    () -> new FruitTreeLeavesBlock(leafProps().blockEntity(TFCBlockEntities.BERRY_BUSH),
        MyItems.MY_FRUIT, MY_TREE_STAGES, MY_TREE_RANGE, 0xFFC0CB), false);
```

> ⚠️ **关键约束**：`FruitTreeLeavesBlock` 通过 `BerryBushBlockEntity.getStemPos()` 找到「树干位置」，
> 并据此计算水合与温度。所以树叶必须与 `TFCBlockEntities.BERRY_BUSH` 绑定，且**结构必须是
> 「树干（枝条）在下、树叶在上」**这种 TFC 约定形态，否则水合/温度判定会取错位置
> （源码里取不到 BE 会打 `LOGGER.error("Fruit tree leaf block entity not present at ...")`）。

### 4.4 结果与采摘

结果的判定与采摘全部由 `SeasonalPlantBlock` 处理，不需要自己写：

- 当月生命周期 == `FLOWERING` 且距上次采摘超过 `TFCConfig.SERVER.fruitPickBloomDelayTicks` → `useItemOn` 会把生命周期推进到 `FRUITING`；
- `FRUITING` 状态下右键 → 播放浆果采摘音效 + `ItemHandlerHelper.giveItemToPlayer(...)` 给出产物 + 状态回到 `HEALTHY`。
- 产物物品由构造器参数 `Supplier<? extends Item> productItem` 决定（TFC 传 `TFCItems.FOOD.get(Food.XXX)`；附属模组传自己的物品）。

---

## 5. 添加新灌木

三种植物的差别只在「生长形态」，机制完全一致，**构造器全部 public**：

| 类型 | 类 | 构造器 | 配套 |
|---|---|---|---|
| 固定丛 | `StationaryBerryBushBlock` | `(ExtendedProperties, Supplier<Item> product, Lifecycle[], Supplier<ClimateRange>)` | 需 `BERRY_BUSH` BE |
| 蔓延丛 | `SpreadingBushBlock` | `(ExtendedProperties, Supplier<Item>, Lifecycle[], Supplier<Block> cane, int maxHeight, Supplier<ClimateRange>)` | 需配套 `SpreadingCaneBlock` |
| 蔓延藤 | `SpreadingCaneBlock` | 同上（参数与 bush 互为引用） | 需配套 `SpreadingBushBlock` |
| 水生丛（蔓越莓式） | `WaterloggedBerryBushBlock` | `(ExtendedProperties, Supplier<Item>, Lifecycle[], Supplier<ClimateRange>)` | 可种在水里 |

注册要点（照抄 TFC 的命名与配套关系）：

```java
// TFC: TFCBlocks.java:307-310
STATIONARY_BUSHES = mapOf(StationaryBush.class, bush -> register("plant/" + bush.name() + "_bush", bush::create, bush::createItem));
SPREADING_CANES   = mapOf(SpreadingBush.class,   bush -> registerNoItem("plant/" + bush.name() + "_bush_cane", bush::createCane));
SPREADING_BUSHES  = mapOf(SpreadingBush.class,   bush -> register("plant/" + bush.name() + "_bush", bush::createBush, bush::createItem));
CRANBERRY_BUSH    = register("plant/cranberry_bush", FruitBlocks::createCranberry, FruitBlocks::createCranberryItem);
```

- 蔓延型必须**两个方块互相引用**（bush ↔ cane）→ 用 `Supplier` 延迟。
- 物品需要实现 `PlantableInfo`（TFC 的做法是自定义 `BlockItem` 子类，见 `FruitBlocks.BushBlockItem`）。
- 可种植表面由 tag 决定：`mayPlaceOn(...)` 检查 `TFCTags.Blocks.BUSH_PLANTABLE_ON`。
- 荆棘类（`TFCTags.Blocks.THORNY_BUSHES`）会自动伤害踩上去的实体、并把寻路代价设为 `DAMAGE_OTHER`。

---

## 6. 添加棕榈式大型植物（香蕉模式）

### 6.1 香蕉的特殊之处

香蕉**不是** `FruitBlocks.Tree` 的成员，而是独立注册的两个方块（`TFCBlocks.java:319-321`）：

```java
BANANA_PLANT          = registerNoItem("plant/banana_plant", FruitBlocks::createBananaPlant);
BANANA_SAPLING        = register("plant/banana_sapling", FruitBlocks::createBananaSapling, FruitBlocks::createBananaSaplingItem);
BANANA_POTTED_SAPLING = registerNoItem("plant/potted/banana_sapling", FruitBlocks::createPottedBananaSapling);
```

它用的类与构造函数（**都是 public**）：

```java
BananaPlantBlock(ExtendedProperties, Supplier<? extends Item> product, Lifecycle[])
BananaSaplingBlock(ExtendedProperties, Lifecycle[], Supplier<? extends Block> plant, Supplier<Integer> ticksToGrow)
```

它的构造风格（源码 `FruitBlocks.createBananaPlant`）：

```java
new BananaPlantBlock(ExtendedProperties.of(MapColor.PLANT).strength(0.5f).sound(SoundType.GRASS)
        .randomTicks().noOcclusion().forceSolidOn()
        .blockEntity(TFCBlockEntities.BERRY_BUSH)     // 用浆果丛 BE 存采摘计时
        .flammableLikeLeaves()
        .cloneItem(TFCBlocks.BANANA_SAPLING),         // 破坏时掉树苗
    TFCItems.FOOD.get(Food.BANANA), BANANA_STAGES);
```

### 6.2 为什么这对「棕榈式植物」重要

**香蕉模式是「一株多格 + 会结果 + 可采摘」这类热带大型植物的现成模板**，
而且它是 TFC 里**唯一不依赖枚举**的果树类内容 —— 也就是说，**附属模组要加同类植物，完全不需要碰任何枚举**。

> **注意 TFC 里的 "PALM（棕榈）" 并不属于这一类**：`Wood.PALM` 是**木材**枚举的成员
> （`PALM(false, 0.0f, MapColor.COLOR_ORANGE, MapColor.COLOR_BROWN, 7, 255)`），
> 它是一棵**普通的 TFC 树**（有 log/planks/barrel 全套木制品），树形由
> `data/tfc/worldgen/configured_feature/tree/palm.json` 决定。
> 所以「加一棵棕榈」有两种完全不同的理解，见下表：

| 你想要的是 | 走哪条路 |
|---|---|
| 一棵像棕榈一样「有原木、木板、能砍」的**新树种** | §7「新树种（RegistryWood）」 |
| 一株像香蕉一样「一丛高秆、能采果」的**热带植物** | 本节「香蕉模式」（但注意 §6.3 的限制） |

### 6.3 ⚠️ 必须知道的限制：香蕉模式的气候写死在代码里

实测源码（`BananaPlantBlock.java:100`、`BananaSaplingBlock.java:51`）：

```java
// BananaPlantBlock 构造器内部：
super(properties, ClimateRanges.BANANA_PLANT, productItem, stages);        // ← 硬编码 TFC 的香蕉气候
// BananaSaplingBlock 构造器内部：
super(properties, block, ticksToGrow, ClimateRanges.BANANA_PLANT, stages); // ← 同上
```

**结论**：直接 `new BananaPlantBlock(...)` 得到的植物，气候约束**永远跟随
`data/tfc/tfc/climate_range/plant/banana_tree.json`**，附属模组没有参数可以传自己的范围。
（两个类的构造器都只有这一个重载，没有带 `Supplier<ClimateRange>` 的版本。）

三条出路：

| 方案 | 做法 | 代价 |
|---|---|---|
| A. 接受香蕉气候 | 直接 `new`，并**覆盖** `data/tfc/tfc/climate_range/plant/banana_tree.json` | 会连带改掉 TFC 原本的香蕉；与其它模组可能冲突（同名文件互相覆盖） |
| B. 自己继承 `SeasonalPlantBlock`（**推荐**） | 写一个自己的高秆植物类，构造器里传自己的气候引用 | 约 50 行代码，但气候/生命周期完全自主 |
| C. 只借外观 | 用 `BananaPlantBlock` 的模型/贴图，行为自己实现 | 工作量最大 |

方案 B 骨架（`SeasonalPlantBlock` 是 **public abstract**、构造器 **public**）：

```java
public class MyTallPlantBlock extends SeasonalPlantBlock {
    public MyTallPlantBlock(ExtendedProperties properties, Supplier<? extends Item> product,
                            Lifecycle[] stages, Supplier<ClimateRange> climateRange) {
        super(properties, climateRange, product, stages);     // ★ 气候由自己传（香蕉做不到这点）
    }

    /** 基类提供的是 5 参数辅助方法，子类要把它接到原版的 randomTick 上 */
    @Override
    public void randomTick(BlockState state, ServerLevel level, BlockPos pos, RandomSource random) {
        randomTick(this, state, level, pos, random);          // ← 调用基类辅助方法，不是递归
    }
}
```

> 同理，`SeasonalPlantBlock` 的其它 protected 扩展点（`stateAfterPicking`、`getProductItem`、
> `getLifecycleForMonth`、`mayPlaceOn`）都可以在子类里覆写，用来做「采摘后保留果实格」
> 「产物按随机数变化」这类自定义行为。

---

## 7. 添加新树种（含棕榈式的完整木材树）

### 7.1 TFC 的实现：一个枚举 × 一个 BlockType 枚举

```java
// TFCBlocks.java:278 —— 整套木材方块（40+ 种）只用这一行注册
public static final Map<Wood, Map<Wood.BlockType, Id<Block>>> WOODS =
    Helpers.mapOf(Wood.class, wood -> Helpers.mapOf(Wood.BlockType.class, type ->
        register(type.nameFor(wood), type.create(wood), type.createBlockItem(wood, new Item.Properties()))));
```

`Wood.BlockType` 枚举有 40+ 个成员（LOG、STRIPPED_LOG、PLANKS、LEAVES、SAPLING、DOOR、FENCE、BARREL、
CHEST、AXLE、WINDMILL、WATER_WHEEL、CRATE、SHELF…），每个成员自带工厂函数。

### 7.2 关键：`Wood.BlockType` 的三个方法都是 public

```java
public Supplier<Block> create(RegistryWood wood);                                  // 造方块（惰性）
public String nameFor(RegistryWood wood);                                          // 造注册名，如 "wood/log/mywood"
public @Nullable Function<Block, BlockItem> createBlockItem(RegistryWood wood, Item.Properties properties);  // 造方块物品（部分类型返回 null）
public boolean needsItem();                                                        // 表示某些类型不需要物品
```

而 `RegistryWood` 是 **public 接口**：

```java
public interface RegistryWood extends StringRepresentable {
    MapColor woodColor();
    MapColor barkColor();
    TreeGrower tree();
    Supplier<Integer> ticksToGrow();
    int autumnIndex();
    Supplier<Block> getBlock(Wood.BlockType type);      // ★ 回指自己的方块表
    BlockSetType getBlockSet();
    WoodType getVanillaWoodType();
    boolean isConifer();
    float getFlowerOffset();
}
```

**结论：附属模组可以完整复用 TFC 的整套木材方块生成器。**

### 7.3 实施骨架

```java
public enum MyWoods implements RegistryWood {
    PALM_LIKE(false, 0.0f, MapColor.COLOR_ORANGE, MapColor.COLOR_BROWN, 7, 255);

    private final String serializedName = name().toLowerCase(Locale.ROOT);
    private final boolean conifer;
    private final float flowerOffset;
    private final MapColor woodColor, barkColor;
    private final TreeGrower tree;
    private final int defaultTicksToGrow;
    private final BlockSetType blockSet;
    private final WoodType woodType;
    private final int autumnIndex;

    MyWoods(boolean conifer, float flowerOffset, MapColor woodColor, MapColor barkColor, int daysToGrow, int autumnIndex) {
        this.conifer = conifer; this.flowerOffset = flowerOffset;
        this.woodColor = woodColor; this.barkColor = barkColor;
        this.autumnIndex = autumnIndex;
        this.defaultTicksToGrow = daysToGrow * 24000;
        this.blockSet = BlockSetType.register(new BlockSetType("mymod_" + serializedName));
        this.woodType = WoodType.register(new WoodType("mymod_" + serializedName, blockSet));
        // 树形：指向你自己的 configured_feature
        this.tree = new TreeGrower(serializedName, Optional.empty(),
            Optional.of(ResourceKey.create(Registries.CONFIGURED_FEATURE,
                ResourceLocation.fromNamespaceAndPath("mymod", "tree/" + serializedName))),
            Optional.empty());
    }

    // ★ 必须用 lambda 包一层：附属模组的 DeferredHolder<Block, ? extends Block> 不能直接当 Supplier<Block> 用
    @Override public Supplier<Block> getBlock(Wood.BlockType type) { return () -> MyWoodBlocks.WOODS.get(this).get(type).get(); }
    // …其余 getter 照抄 TFC 的 Wood.java

    public static MyWoods[] VALUES = values();
}

// 注册：与 TFC 那一行完全同构
public static final Map<MyWoods, Map<Wood.BlockType, Id<Block>>> WOODS =
    Helpers.mapOf(MyWoods.class, wood -> Helpers.mapOf(Wood.BlockType.class, type ->
        RegistrationHelpers.registerBlock(BLOCKS, MyItems.ITEMS, type.nameFor(wood), type.create(wood),
            type.createBlockItem(wood, new Item.Properties()))));
```

### 7.4 必须注意的六件事

1. **`BlockSetType` / `WoodType` 必须注册**（原版要求），且**只在客户端/服务端各注册一次**。
   TFC 在 `FMLCommonSetupEvent` 里集中做：`Wood.registerBlockSetTypes()`（`Wood.java:217`）→ 你的模组也要照做。
2. **注册名带 `wood/` 前缀**：`nameFor` 内部硬编码 `"wood/%s/%s".formatted(type, wood.getSerializedName())`，
   所以你会得到 `mymod:wood/log/mywood`、`mymod:wood/planks/mywood`。命名空间是自己的，不会冲突。
3. **部分类型不需要物品**（`needsItem()` 对 SAPLING? / POTTED_SAPLING / WALL_SIGN / etc. 返回 false），
   `createBlockItem` 会返回 `null` → 这与 `RegistrationHelpers.registerBlock` 的 `@Nullable blockItemFactory` 正好对上。
4. **树形是数据驱动的**：`TreeGrower` 只存 ResourceKey，真正的形状在
   `data/mymod/worldgen/configured_feature/tree/mywood.json`（+ 一个 `placed_feature`）。见 §8。
5. **`getBlock` 必须用 lambda 包一层**（见 §0.1 的实测错误），否则报
   `不兼容的类型: DeferredHolder<Block,CAP#1> 无法转换为 Supplier<Block>`。
6. **`Wood.BlockType` 全部 40+ 个类型都会被注册**：附属模组很难只取一部分
   （枚举是 `public`，可以 `switch` 过滤，但 `create(wood)` 内部会互相引用 strippd/leaves 等，
   建议整套生成，再按需删掉不想要的资源文件）。

---

## 8. 自然生成（野生植物 / 野树 / 野果丛）

> 完整调研见 `_work/h-worldgen-plants.md`（1142 行，H-0~H-12，含全部字段表与真实 JSON）。

### 8.1 三层结构

```
configured_feature（怎么生成：feature 类型 + 参数）
      ↓ 被引用
placed_feature（在哪生成、生成多少次：placement modifier 列表）
      ↓ 被引用
生物群系的 features 数组 / tag（挂到哪些群系）
```

### 8.2 TFC 的植物 feature（实测 20 个 + 树的 6 个）

`world/feature/plant` 包实测 **20 个 feature 类 + 3 个 config 类**，注册总表在 `TFCFeatures.java:133-164`。
常用的几个：

| 注册名（`tfc:` 下） | 用途 |
|---|---|
| `tfc:tall_plant` / `tfc:tall_wild_crop` | 高草 / 高野生作物 |
| `tfc:spreading_crop` | 蔓延型野生作物（南瓜、甜瓜） |
| `tfc:fruit_tree` | 野果树 |
| `tfc:banana` | 野香蕉 |
| `tfc:creeping_plant` / `tfc:creeping_ocean_plant` | 爬藤 / 海生爬藤 |
| `tfc:epiphyte_plant` | 附生植物 |
| `tfc:column_plant` | 柱状植物 |
| `tfc:rotatable_water_plant` / `tfc:submerged_tall_plant` / `tfc:emergent_plant` | 水生植物 |
| `tfc:forest` / `tfc:krummholz` / `tfc:random_tree` / `tfc:overlay_tree` / `tfc:stacked_tree` | 树 |

### 8.3 ⚠️ 关键约束：复用 TFC feature 时方块类型被强校验

TFC 的植物 feature 用 `BlockConfig`（本质是 `state` 字段）指定要放的方块，**加载期会校验方块类型**：
你的方块必须**继承对应的 TFC 方块类**，否则报 `Must be a <类名>` 而加载失败。

| 想生成 | 你的方块必须继承 |
|---|---|
| 野生作物 | `WildCropBlock` / `WildDoubleCropBlock` / `WildSpreadingCropBlock` |
| 野果树 | TFC 的果树四件套类 |
| 浆果丛 | `StationaryBerryBushBlock` / `SpreadingBushBlock` |
| 一般植物 | `PlantBlock` 及其子类 |

> 这条与 §5「直接 `new` TFC 的灌木类」正好吻合 —— **直接实例化 TFC 的类，天然满足类型校验**，
> 这也是为什么推荐「复用 TFC 的行为类」而不是自己从 `Block` 重写。

### 8.4 挂到生物群系：推荐「往 TFC 的 tag 追加」

**为什么不用 `BiomeModifier`**：实测生物群系的 `features` 数组**不是固定 11 项**
（11 项 57 个 / 12 项 55 个 / 13 项 13 个，多出来的层是 `veins/kaolin|river|montane`）。
NeoForge 的 `FeatureSorter` 取所有群系的最大层数逐层遍历（`FeatureSorter.java:44`、`:103`），
所以**同一个 `step` 在不同群系落到不同下标**，`BiomeModifier` 的行为不稳定。

**推荐做法（零冲突）**：往 TFC 已有的 placed_feature tag 里追加自己的条目。
tag 是 `replace: false` 的**合并语义**，多个模组写同一个 tag 文件不会互相覆盖：

```
src/main/resources/data/tfc/tags/worldgen/placed_feature/feature/land_plants.json
```
```json
{
  "replace": false,
  "values": [
    "mymod:my_wild_plant"
  ]
}
```

TFC 原本的 `land_plants.json`（实测，共 100+ 条目）长这样：

```json
{"replace":false,"values":["tfc:plant/hanging_vines", "...", "#tfc:feature/crops",
 "#tfc:feature/forest_plants", "tfc:surface_grasses", "#tfc:feature/berry_bushes",
 "#tfc:feature/fruit_trees"]}
```

**可选挂载点**：

| tag | 覆盖范围 |
|---|---|
| `#tfc:feature/land_plants` | **99 个群系共用**（最省事，推荐首选） |
| `#tfc:feature/berry_bushes` / `#tfc:feature/fruit_trees` / `#tfc:feature/crops` | 更精确分类 |
| `#tfc:in_biome/surface_decoration/<biome名>` | 单个群系（如 `.../plains`、`.../hills`） |

> ⚠️ **这是唯一可以安全写入 `tfc:` 命名空间的资源类型**。非 tag 文件（如 `data/tfc/recipe/x.json`）
> 是**整文件覆盖**语义，写进去会改掉 TFC 本体内容并与其他模组冲突。
> 备选方案是 NeoForge 的 `neoforge:add_features`（21.1 可用、未废弃），但在 TFC 的层数不定问题上有风险；
> **覆盖 biome JSON 是危险做法**，不要用。

### 8.5 最小文件集合（让新植物自然生成）

```
src/main/java/...                       ← 方块类（必须继承对应 TFC 类，见 §8.3）+ 注册
src/main/resources/
├── data/mymod/worldgen/configured_feature/my_wild_plant.json    ← 怎么生成
├── data/mymod/worldgen/placed_feature/my_wild_plant.json        ← 在哪生成、多少次
└── data/tfc/tags/worldgen/placed_feature/feature/land_plants.json ← 追加挂载（replace:false）
```

`placed_feature` 的常用字段（实测使用频次：`heightmap` 430、`in_square` 284、`tfc:climate` 249、`rarity_filter` 237）：

```json
{
  "feature": "mymod:my_wild_plant",
  "placement": [
    { "type": "minecraft:rarity_filter", "chance": 90 },
    { "type": "minecraft:in_square" },
    { "type": "tfc:climate", "min_temperature": -9.4, "max_temperature": 15.8,
      "min_groundwater": 100, "max_groundwater": 400, "max_forest": 2 }
  ]
}
```

> ⚠️ 注意 `tfc:climate` 的湿度字段是 **`min_groundwater`/`max_groundwater`**（不是 `min_rainfall`），
> 另有 `min_forest`/`max_forest` 等；上面这份是 TFC 真实文件
> `data/tfc/worldgen/placed_feature/plant/wild_crop/wheat_patch.json` 的原文。14 个字段的完整表见 `_work/h-worldgen-plants.md`。

TFC 自定义的 15 个 placement modifier 与 4 个 block predicate（`tfc:air_or_empty_fluid`、
`tfc:would_survive_with_fluid`、`tfc:replaceable`、`tfc:dry_replaceable`）的完整字段表见 `_work/h-worldgen-plants.md`。

### 8.6 野生作物的掉落

**不存在 `CropYieldProvider` 之类的自定义 loot function** —— 实测掉落是**纯原版两池战利品表**
（`data/tfc/loot_table/blocks/wild_crop/*.json`，29 个）：

- 食物池：条件 `block_state_property{mature: true}`，掉成熟产物；
- 种子池：无条件掉 2~3 个种子；
- 双格作物额外要求 `part: bottom`。

成熟与否由 TFC 日历 + `TFCConfig.SERVER.wildCropMaturityStartMonth/EndMonth` 决定，
`randomTick` 只负责翻转 `MATURE` 属性。

### 8.7 树的生成

- `Wood.tree()` 返回的 `TreeGrower` 指向 `tfc:tree/<wood>`（**种苗生长**路径）；
- **世界生成**走另一套：`tfc:tree/<wood>_entry` + `tfc:forest` feature；
- `data/tfc/worldgen/configured_feature/tree/` 共 101 个文件，构成已量化：
  普通 20 / entry 20 / dead_entry 20 / dead 20 / large 16 / krummholz 5；
- **棕榈的差异**（可作为"棕榈式新树种"的直接参照）：`placement.ground_type = "sand"`，
  且它的 entry 里**没有** `bush_*` 与 `old_growth_tree` 字段；
- `data/tfc/structure/**.nbt` 共 539 个（TFC 的树用到结构模板时会引用，缺失会抛异常）。

### 8.8 世界生成的坑

1. **`BlockConfig` 类型强校验**（§8.3）—— 最容易踩，加载期直接失败；
2. **`BiomeModifier` 层数不稳**（§8.4）；
3. **只有 tag 能安全写进 `tfc:` 命名空间**；
4. `tree/*.json` 里常见的 `radius` 字段在 `RandomTreeConfig`/`StackedTreeConfig`/`OverlayTreeConfig`
   的 codec 中**不存在**，会被静默忽略（TFC 自己的数据里就有这个冗余字段，照抄时别以为它有用）；
5. `ColumnPlantConfig.head` 的 `forGetter` 在 TFC 源码里误写成了 `bodyState`（`ColumnPlantConfig.java:24`），
   datagen 写出的 `head` 是错的 —— 手写 JSON 时别依赖它；
6. 树的 `configured_feature` 若引用结构模板（`.nbt`），模板缺失会直接抛异常。

---

## 9. 风险与限制清单

| 风险 | 说明 | 规避 |
|---|---|---|
| **不能扩展 TFC 的枚举** | `Crop`、`FruitBlocks.Tree`、`FruitBlocks.StationaryBush/SpreadingBush`、`Plant`、`Wood` 都是 `enum` | 自建枚举/映射；**不要**用 Mixin 往枚举里塞（`values()` 有静态缓存，且存档/网络同步会错乱） |
| **`create(...)` 工厂绑定 `Crop` 枚举** | `DefaultCropBlock.create(props, stages, Crop)` 之类 | 写自己的 `CropBlock` 子类 |
| **`Lifecycle` 数组长度必须 = 12** | `Preconditions.checkArgument` 会抛异常 | 严格写 12 个元素 |
| **果树叶必须能取到 `BerryBushBlockEntity`** | 取不到会记 error 日志并退化为用自身位置算水合 → 生长判定错误 | 结构照抄 TFC（枝条在下、树叶在上），并给树叶绑定 `TFCBlockEntities.BERRY_BUSH` |
| **气候数据缺失时是 NOOP** | 作物/果树在全世界都能种 | 必须提供 `data/<ns>/tfc/climate_range/*.json` |
| **食物数据缺失** | 收获物没有营养/不会腐烂，TFC 的食物 tooltip 为空 | 提供 `data/<ns>/tfc/food/*.json` |
| **可种植表面受 tag 限制** | 作物要在 `tfc:farmlands` 上、灌木要在 `tfc:bush_plantable_on` 上 | 复用 TFC 的 tag，或在自己的数据包里往 tag 追加条目 |
| **`BlockSetType`/`WoodType` 注册时机** | 必须在 setup 阶段注册一次 | 仿 `Wood.registerBlockSetTypes()` 放在 `FMLCommonSetupEvent` 的 `enqueueWork` 里 |
| **客户端类隔离** | 植物的模型/渲染类不能在服务端加载 | 沿用 `Dist.CLIENT` 分支规范 |
| **BE 类型绑定**（最隐蔽） | TFC 的 `tfc:crop`/`tfc:berry_bush` 只认 TFC 自己的方块；而自建类型会让 TFC 的静态 helper 静默失效 | 见 §2.2.1 的两方案对比；先借用，出问题再自建 + 覆写 helper |
| **TFC 的 `BushBlockItem` / `FruitTreeSaplingItem` 是 private** | 这两个 `PlantableInfo` 实现**不能复用**，也不能继承 | 自己写 `BlockItem` 子类实现 `PlantableInfo`（可参考 public 的 `SeedItem`） |
| **`Clay`/`Plant` 等枚举同样不可扩展** | `Plant` 枚举有上百种野生植物，也不能加 | 实现 public 的 `RegistryPlant` 接口自建（Firmalife 的 `FLPlant` 就是范例） |
| **复用 TFC 的植物 feature 时方块类型被强校验** | 加载期报 `Must be a <类名>` | 你的方块必须继承对应的 TFC 方块类（§8.3）；用 `new` TFC 的类天然满足 |
| **`BiomeModifier` 在 TFC 群系上层数不稳** | `features` 数组长度 11/12/13 不等，`step` 落层不一致 | 改用「往 TFC 的 placed_feature tag 追加」（§8.4） |
| **往 `tfc:` 命名空间写非 tag 文件** | 非 tag 资源是整文件覆盖，会改坏 TFC 本体并与其它模组冲突 | **只有 tag 文件可以安全写 `tfc:`**（tag 是 `replace:false` 合并语义） |

---

## 10. 参考实现：Firmalife 是怎么做的（强烈建议先读）

Firmalife 是当前 TFC 生态里最完整的「加植物」范例，它的做法与本文结论完全吻合，而且踩过的坑都已经解决了。
详细调研见 `_work/g-firmalife-plants.md`（1180 行，逐条附源码行号）。

**它的做法**：
- **一个 TFC 式作物都没加**（全库只有 2 处引用 TFC 的 `blocks.crop` 包）；
- 自建 5 个枚举：`FLPlant`（实现 TFC 的 public 接口 `RegistryPlant`）、`Herb`、`FLFruit`、
  `FLFruitBlocks.Tree`、`FLFruitBlocks.StationaryBush`；
- 用 TFC 的公开 `Helpers.mapOf(...)` 自建 `Map<枚举, Id<Block>>` 注册表（`common/blocks/FLBlocks.java`）；
- 直接复用 TFC 的 `SeasonalPlantBlock` 子类、`Lifecycle`、`ClimateRange.MANAGER`、
  `PlantableInfo`（**只读**复用 —— TFC 的 `BushBlockItem`/`FruitTreeSaplingItem` 是 private，实现不了）；
- **自建 `BlockEntityType`**，并为 `TickingPlantBlockEntity` 复制了一套自己的静态 helper。

**可直接照抄的文件**（Firmalife 源码，路径相对仓库根）：

| 目标 | 参考文件 |
|---|---|
| 加新果树（五件套：树苗 / 生长枝 / 枝条 / 树叶 / 盆栽） | `common/blocks/plant/FLFruitBlocks.java` + `FLFruitTreeSaplingBlock.java` |
| 自建 BE 类型并绕开 helper 失效 | `common/blockentities/FLTickingPlantBlockEntity.java` |
| 自建植物枚举 + 注册表 | `common/blocks/FLBlocks.java`（`FLPlant` / `Herb` 段） |
| 数据包侧（气候 / 食物） | `src/main/resources/data/firmalife/tfc/climate_range/*.json`、`.../tfc/food/*.json` |
| 完全自建的复杂植物（葡萄） | `common/blocks/plant/grape/*` + `IGrape` + `GrapePlantBlockEntity` |

> **葡萄是「TFC 里没有的复杂植物」的完整示范**：6 个方块类 + 自己的 BE；季节**硬编码**
> （6 月开花 / 7 月结果，**不走 12 元 `Lifecycle[]`**）；只检查温度不检查湿度；
> 一条藤由多段 BE 组成，用 `getBrainPos()` 定位「大脑」并汇总 7×7×2 范围的土壤/蜂箱数据，
> 产出 4 种 `FoodTrait`（`BEE_POLLINATED`/`DIRT_GROWN`/`GRAVEL_GROWN`/`SLOPE_GROWN`）。
> 如果你的植物比「标准果树」复杂，**葡萄比 `FruitBlocks.Tree` 更值得参考**。

---

## 11. 建议的实施顺序

1. **先做数据驱动部分**（零 Java）：`climate_range` + `food` JSON，用 `/reload` 验证能被解析。
2. **再做灌木/果树**（最简单）：直接 `new` TFC 的方块类，只写注册与物品。
3. **然后做作物**：需要一个 `CropBlock` 子类 + 种子物品。
4. **最后做树种**：实现 `RegistryWood` + 树形 JSON，工作量集中在资源文件（40+ 种方块的模型/贴图/掉落表）。
5. **自然生成放在最后**：它只影响「能不能在世界里找到」，不影响机制本身。

> 资源文件是这四类内容里**最大的工作量**：TFC 的一种木材 = 40+ 方块 × (blockstate + model + item model)，
> 建议一开始就写 datagen 或脚本来批量生成，而不是手写 JSON。
