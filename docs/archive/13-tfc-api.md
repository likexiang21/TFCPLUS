# TFC 4.2.10 公开 API、组件体系与事件

> 依据：`moddev/src-ref/TFC-decompiled`（CFR 反编译，对应 jar 4.2.10）
> 与 `moddev/inventory/api-dump/TFC-public-api.txt`（javap 签名转储）。
> 所有类名均为完整包路径，可直接用于 `import`。

---

## 0. 需求 → API 速查

| 我想做什么 | 用哪个 API |
|---|---|
| 读取/写入「食物」数据 | `stack.get(TFCComponents.FOOD.get())` 或 `FoodCapability.get(stack)` |
| 给物品加温度 | `HeatCapability`（`IHeat`、`HeatComponent`） |
| 读气候（温度/降雨/风） | `ClimateModels.REGISTRY` + `ClimateModel`，世界级：`IClimateModel` 由 `ClimateModel` 提供 |
| 读游戏内日历（日期/季节） | `Calendars.get(level)` / `Calendars.SERVER` / `Calendars.CLIENT` |
| 让物品参与 TFC 的「尺寸/重量」系统 | 实现 `IItemSize` 或加 `data/tfc/tfc/item_size/*.json` |
| 注册一个右键交互 | `InteractionManager.register(...)` 或 NeoForge 的 `PlayerInteractEvent` |
| 监听 TFC 事件 | `NeoForge.EVENT_BUS.addListener(...)`，事件类在 `net.dries007.tfc.util.events` |
| 注册自定义能力 | `RegisterCapabilitiesEvent`（模组总线） |
| 拿 TFC 的方块实体基类 | `TFCBlockEntity` / `TickableBlockEntity` / `InventoryBlockEntity` / `TickableInventoryBlockEntity` |
| 拿 TFC 的菜单基类 | `Container` / `BlockEntityContainer` / `ItemStackContainer` + `ISlotCallback` |
| 复用 TFC 的方块属性 DSL | `ExtendedProperties` + `ExtendedBlock` |
| 注册工具类助手 | `RegistrationHelpers` |
| 常用工具（tag 判断、NBT、物品堆、随机） | `Helpers` |

---

## 1. 数据组件（DataComponent）体系 —— 1.21 时代的核心

TFC 4.2.10 完全迁移到原版 1.21 的 **DataComponent** 系统，不用旧 NBT capability。
所有 TFC 组件定义在 `net.dries007.tfc.common.component.TFCComponents`。

### 1.1 注册方式（`TFCComponents.java`）

```java
public final class TFCComponents {
    public static final DeferredRegister<DataComponentType<?>> COMPONENTS =
        DeferredRegister.create(Registries.DATA_COMPONENT_TYPE, "tfc");

    private static <T> Id<T> register(String name, Codec<T> codec,
                                      StreamCodec<? super RegistryFriendlyByteBuf, T> streamCodec) {
        return new Id<>(COMPONENTS.register(name, () -> new DataComponentType.Builder()
            .persistent(codec)                 // 存档持久化用 Codec
            .networkSynchronized(streamCodec)  // 网络同步用 StreamCodec
            .build()));
    }

    public record Id<T>(DeferredHolder<DataComponentType<?>, DataComponentType<T>> holder)
        implements RegistryHolder<DataComponentType<?>, DataComponentType<T>> {}
}
```

附属模组要加自己的组件，完全照抄这个模板即可（`.persistent()` 与 `.networkSynchronized()` 按需省略）。

### 1.2 组件清单（实测于 javap，字段名即 Java 字段）

| 常量 | 泛型类型 | 说明 |
|---|---|---|
| `FORGING` | `ForgingComponent` | 锻打进度与工序 |
| `FORGING_BONUS` | `ForgingBonusComponent` | 锻造加成（耐久/攻击等） |
| `GLASS` | `GlassOperations` | 玻璃加工工序链 |
| `HEAT` | `HeatComponent` | 温度与热容 |
| `FOOD` | `FoodComponent` | 食物（营养、衰减、词条） |
| `BOWL` | `ItemComponent` | 碗内容 |
| `INGREDIENTS` | `ItemListComponent` | 原料列表（如炖菜配料） |
| `DEPOSIT` | `ItemComponent` | 淘洗/矿床内容 |
| `BAIT` | `ItemComponent` | 鱼饵 |
| `PLANT` | `ItemComponent` | 植物内容（如种子） |
| `EGG` | `EggComponent` | 蛋（孵化数据） |
| `FLUID` | `FluidComponent` | 物品内流体 |
| `VESSEL` | `VesselComponent` | 大缸内容 |
| `CONTENTS` | `ItemListComponent` | 通用内容列表 |
| `BARREL` | `BarrelComponent` | 方块实体内嵌桶数据 |
| `CRUCIBLE` | `CrucibleComponent` | 坩埚内嵌数据 |

### 1.3 `ModifyDefaultComponentsEvent`：给原版物品挂 TFC 组件

`TFCComponents.onModifyDefaultComponents(ModifyDefaultComponentsEvent event)` 做的事情（源码行 90-103）：

```java
event.modify(Items.FLINT_AND_STEEL, b -> b.set(DataComponents.MAX_DAMAGE, TFCTiers.STEEL.getUses()));
event.modify(Items.EGG,            b -> b.set(EGG.get(), EggComponent.DEFAULT));
event.modify(Items.MINECART,       b -> b.set(DataComponents.MAX_STACK_SIZE, 64));
```

此外还有一个**资源重载后**再跑一遍的方法 `onModifyDefaultComponentsAfterResourceReload()`：
它会遍历 `BuiltInRegistries.ITEM`，依据数据驱动表（`FoodDefinition`、`ItemSizeManager`）修正每个物品的
`DataComponents.FOOD` 与 `DataComponents.MAX_STACK_SIZE`，并用 `item.modifyDefaultComponentsFrom(patch)` 提交。
—— **这是 TFC「让所有物品自动获得食物/堆叠属性」的机制**，附属模组若添加了 `data/tfc/tfc/food/...` 或
`item_size/...` 条目，物品会在下一次资源重载时自动被改写。

### 1.4 组件读写范式：`ComponentView`

TFC 不为每个组件写 setter，而是用 `ComponentView<T>`（`net.dries007.tfc.common.component.ComponentView`）做**可变视图**：

```java
public abstract class ComponentView<T> {
    private final Supplier<DataComponentType<T>> type;
    protected final ItemStack stack;
    protected T component;

    protected ComponentView(ItemStack stack, T value, Supplier<DataComponentType<T>> type) { ... }
    protected ComponentView(ItemStack stack, Supplier<DataComponentType<T>> type, T defaultValue) {
        this(stack, stack.getOrDefault(type, defaultValue), type);
    }

    /** 写回物品堆（空堆不写） */
    protected void apply(T newValue) {
        if (!stack.isEmpty()) { this.component = newValue; this.stack.set(this.type, this.component); }
    }
}
```

典型视图类：`HeatView`、`HeatContainer`、`FluidContainer`、`ItemContainer`、`Mold`、`Vessel`、`Barrel`。
它们都在构造时**从 ItemStack 读取组件**，把 `stack` 与组件值缓存为字段，通过 `apply(...)` 写回。

> 附属模组若要在自己的物品上复用 TFC 行为，最省力的方式是让自己的 `Item` 实现
> `ComponentView` 的对应子类接口，或在 `Item.inventoryTick` 里用 `new HeatView(stack)` 直接操作。

### 1.5 食物组件

**接口 `IFood`（`common.component.food.IFood`）** —— 只读视图：

```java
public interface IFood {
    long TRANSIENT_NEVER_DECAY_FLAG = -1L;   // 永不腐烂（不显示提示）
    long INVISIBLE_NEVER_DECAY_FLAG = -2L;   // 永不腐烂（不显示提示，内部用）
    long NEVER_DECAY_FLAG          = -3L;    // 永不腐烂（金名提示）
    long ROTTEN_FLAG               = -4L;    // 已腐烂

    long getCreationDate();
    default long getRottenDate();            // 创建时间 + 保质期
    boolean isRotten();
    FoodData getData();
    default float getDecayDateModifier();    // 综合衰减系数
    List<FoodTrait> getTraits();
    default boolean hasTrait(FoodTrait trait);
    default void addTooltipInfo(ItemStack stack, Consumer<Component> tooltip);
}
```

**实现 `FoodComponent`** —— 持久化形态（`common.component.food.FoodComponent`）：

```java
public final class FoodComponent implements IFood {
    public static final Codec<FoodComponent> CODEC = RecordCodecBuilder.create(i -> i.group(
        FoodTraits.REGISTRY.byNameCodec().listOf().optionalFieldOf("traits", List.of()).forGetter(c -> c.traits),
        FoodData.CODEC.optionalFieldOf("food").forGetter(c -> c.food),
        Codec.LONG.fieldOf("creation_date").forGetter(c -> c.creationDate)
    ).apply(i, FoodComponent::new)).xmap(Function.identity(), FoodComponent::sanitize);

    public FoodComponent(FoodDefinition parent);            // 由数据定义构造（推荐）
    public long getCreationDate();
    public boolean isRotten();
    public FoodData getData();
    public List<FoodTrait> getTraits();
    public FoodComponent sanitize();
    public void capture(ItemStack stack);                   // 惰性绑定 parent 定义 + 写入创建日期
}
```

**NBT/JSON 形态**（`FoodComponent.CODEC`）：

```json
{
  "traits": ["tfc:brined"],
  "food": { "...": "FoodData 序列化形态，见 12-tfc-data-driven.md" },
  "creation_date": 123456
}
```

**`capture(stack)` 的语义**非常关键：TFC 的物品在「第一次被创建」时调用它，
绑定 `FoodDefinition`（数据驱动）与创建日期；`creation_date == -1` 表示尚未初始化。

常用静态入口在 `FoodCapability`：

```java
FoodCapability.get(ItemStack)         // 取 IFood（无则返回 null / 空实现，见源码 231 行）
FoodCapability.getDefinition(ItemStack)
FoodCapability.getRoundedCreationDate()
FoodCapability.getLifeTime(float decayModifier)
FoodCapability.isRotten(long creationDate, float decayModifier)
FoodCapability.setStackFood / applyTrait / removeTrait ...（见源码）
```

### 1.6 热量组件

```java
public final class HeatComponent implements IHeatView {
    public static final Codec<HeatComponent> CODEC = RecordCodecBuilder.create(i -> i.group(
        Codec.FLOAT.optionalFieldOf("capacity",    0.0f).forGetter(c -> c.heatCapacity),
        Codec.FLOAT.optionalFieldOf("temperature", 0.0f).forGetter(c -> c.lastTemperature),
        Codec.LONG.optionalFieldOf("tick",         0L).forGetter(c -> c.lastTick)
    ).apply(i, HeatComponent::new)).xmap(Function.identity(), HeatComponent::sanitize);

    public static final HeatComponent EMPTY = new HeatComponent(null, 0f, 0f, 0L);

    public static HeatComponent of(float heatCapacity);
    public static HeatComponent of(float heatCapacity, float temperatureNow);
    public static HeatComponent of(HeatDefinition parent);   // 从数据驱动定义构造

    public void capture(ItemStack stack);                    // 绑定 HeatDefinition
    @Override public float getTemperature();                 // 会根据 lastTick 推算当前温度
}
```

配合 `HeatCapability`（183 行）与 `HeatDefinition`（数据驱动，`data/tfc/tfc/item_heat/*.json`）使用。
`IHeat` 是容量接口，`IHeatView` 是只读视图，`IHeatConsumer` 是耗热接口。

### 1.7 尺寸与重量：一个完整的数据驱动范例

`ItemSizeManager`（`common.component.size.ItemSizeManager`）演示了 TFC 数据驱动的三大要件：

```java
public final class ItemSizeManager {
    // 1) DataManager：绑定语义 id（tfc:item_size）与 Codec/StreamCodec
    public static final DataManager<ItemSizeDefinition> MANAGER =
        new DataManager<>(Helpers.identifier("item_size"), ItemSizeDefinition.CODEC, ItemSizeDefinition.STREAM_CODEC);

    // 2) IndirectHashCollection：按「物品 key」建立倒排索引，避免每次线性扫描
    public static final IndirectHashCollection<Item, ItemSizeDefinition> CACHE =
        IndirectHashCollection.create(r -> RecipeHelpers.itemKeys(r.ingredient()), MANAGER::getValues);

    // 3) 硬编码回退顺序
    public static IItemSize get(ItemStack stack) {
        if (stack.getItem() instanceof IItemSize size) return size;                  // 物品自身实现优先
        if (stack.getItem() instanceof BlockItem bi && bi.getBlock() instanceof IItemSize size) return size; // 方块实现
        return getDefinition(stack);                                                 // 数据驱动
    }

    public static ItemSizeDefinition getDefinition(ItemStack stack) {
        for (ItemSizeDefinition def : CACHE.getAll(stack.getItem()))
            if (def.ingredient().test(stack)) return def;
        if (item instanceof TieredItem || item instanceof BucketItem) return TOOL_SIZE;   // LARGE / MEDIUM
        if (item instanceof ArmorItem  || item instanceof AnimalArmorItem) return ARMOR_SIZE; // LARGE / VERY_HEAVY
        if (item instanceof BlockItem) return BLOCK_SIZE;                                  // SMALL / LIGHT
        return DEFAULT_SIZE;                                                              // VERY_SMALL / VERY_LIGHT
    }
}
```

**这是附属模组仿写自定义「物品属性系统」的最佳模板**：
`DataManager` + `IndirectHashCollection` + 接口优先 + 硬编码回退。

### 1.8 `ItemStackHooks`：物品堆行为钩子

```java
public final class ItemStackHooks {
    public static void onModifyItemStackComponents(ItemStack);
    public static void onCompareItemStackComponents(ItemStack, ItemStack);
    public static boolean shouldFoodStacksStack(ItemStack, ItemStack);   // 食物是否可堆叠
    public static PatchedDataComponentMap onCopyItemStackComponents(ItemStack, PatchedDataComponentMap);
}
```

这些由 TFC 的 Mixin（`mixin/ItemStackMixin`）调用，用于实现「食物按创建日期不堆叠」等行为。
另有 `public static boolean ENABLED` 开关，在资源重载后才启用（避免加载期误伤）。

---

## 2. NeoForge 能力（Capability）

TFC 用 NeoForge 1.21 的能力系统，定义在 `net.dries007.tfc.common.capabilities`：

```java
public final class ItemCapabilities {
    public static final ItemCapability<IHeat, Void>             HEAT  = ItemCapability.createVoid(Helpers.identifier("heat"), IHeat.class);
    public static final ItemCapability<IMold, Void>             MOLD  = ItemCapability.createVoid(Helpers.identifier("mold"), IMold.class);
    public static final ItemCapability<IFluidHandlerItem, Void> FLUID = Capabilities.FluidHandler.ITEM;
    public static final ItemCapability<IItemHandler, Void>      ITEM  = Capabilities.ItemHandler.ITEM;

    public static void register(RegisterCapabilitiesEvent event) {
        event.registerItem(MOLD,  ItemCapabilities::forMold,  molds);
        event.registerItem(HEAT,  ItemCapabilities::forMold,  molds);
        event.registerItem(FLUID, ItemCapabilities::forMold,  molds);
        event.registerItem(FLUID, (stack, ctx) -> new Barrel(stack), barrels);
        ...
    }
}
```

读能力的便捷方法（`Helpers`）：

```java
Helpers.getCapability(BlockCapability<T, C> capability, Level level, BlockPos pos);
Helpers.getCapability(BlockCapability<T, C> capability, BlockEntity entity);
Helpers.getCapability(BlockCapability<T, C> capability, BlockEntity entity, C context);
Helpers.mightHaveCapability(ItemStack stack, ItemCapability<T, Void> capability);
```

`BlockCapabilities`（同包）是对应的方块能力注册类，通过主类的 `bus.addListener(BlockCapabilities::register)` 挂载。

---

## 3. 事件

### 3.1 TFC 自定义事件（`net.dries007.tfc.util.events`，共 8 个）

| 事件类 | 可取消 | 静态触发入口 | 关键 getter |
|---|---|---|---|
| `StartFireEvent` | `ICancellableEvent` | `startFire(...)`、`startFireWithSound(...)`、`startFire(..., FireStrength, double)` | `getLevel/getPos/getState/getTargetedFace/getPlayer/getItemStack/isStrong` |
| `DouseFireEvent` | `ICancellableEvent` | `douse(Level, BlockPos, Player)`、`douse(Level, AABB, Player)` | `getLevel/getPos/getBounds/getState/getPlayer` |
| `LoggingEvent` | `ICancellableEvent` | 由 `AxeLoggingHelper.shouldLog(...)` 路径投递 | `getLevel/getPos/getState/getAxe` |
| `CollapseEvent` | 否 | 由塌方逻辑投递 | `getLevel/getCenterPos/getNextPositions/getRadiusSquared/isFake` |
| `ProspectedEvent` | 否 | 由探矿锤投递 | `getPlayer/getType/getBlock` |
| `AnimalProductEvent` | `ICancellableEvent` | `produce(Level, BlockPos, [Player], TFCAnimalProperties, ItemStack|FluidStack, ItemStack, int)` | `getAnimalProperties/getEntity/getPlayer/getTool/getProduct/getFluidProduct/getUses`，可 `setProduct(...)`、`setUses(...)` |
| `NutritionDataEvent` | 否 | 营养数据刷新时投递 | `getSupplier/setSupplier/getPlayer` |
| `SelectClimateModelEvent` | 否 | 世界加载时投递（TFC 自己以 `EventPriority.HIGHEST` 监听） | `level()`、`getModel()/setModel(...)` |

监听示例（附属模组）：

```java
NeoForge.EVENT_BUS.addListener((StartFireEvent event) -> {
    if (event.isStrong()) return;
    if (Helpers.isBlock(event.getState(), TFCTags.Blocks.FIREPIT_...) ) { /* ... */ }
});
```

### 3.2 TFC 监听的全局事件（`ForgeEventHandler.init()`，源码行 367-414）

TFC 在 `NeoForge.EVENT_BUS` 上注册了 40+ 个监听器。以下清单可直接作为「TFC 关心哪些事件」的参考——
如果你要 Hook 同类逻辑，理解优先级很重要：

```
EventPriority.LOW    → registerCommands
EventPriority.LOWEST → onPlayerRightClickBlockLowestPriority
EventPriority.HIGHEST→ onSelectClimateModel
EventPriority.HIGHEST→ （其余全部为默认优先级）

LevelEvent.CreateSpawnPosition       onCreateWorldSpawn
ChunkWatchEvent.Sent                 onChunkWatch
BlockEvent.BreakEvent                onBlockBroken
BlockEvent.EntityPlaceEvent          onBlockPlace
PlayerEvent.BreakSpeed               onBreakSpeed
BlockEvent.NeighborNotifyEvent       onNeighborUpdate
ExplosionEvent.Detonate              onExplosionDetonate
LevelTickEvent.Pre                   onWorldTick
LevelEvent.Load                      onWorldLoad
BlockEvent.PortalSpawnEvent          onCreateNetherPortal
BlockEvent.FluidPlaceBlockEvent      onFluidPlaceBlock
CreateFluidSourceEvent               onFluidCreateSource
LivingBreatheEvent                   onLivingBreathe
StartFireEvent / DouseFireEvent      onFireStart / onFireStop
ProjectileImpactEvent                onProjectileImpact
PlayerTickEvent.Pre                  onPlayerTick
LivingEvent.LivingJumpEvent          onLivingJump
LivingIncomingDamageEvent            onLivingHurt
LivingShieldBlockEvent               onShieldBlock
ItemStackedOnOtherEvent              onItemStacked
FinalizeSpawnEvent                   onLivingSpawnCheck
EntityJoinLevelEvent                 onEntityJoinLevel
ItemExpireEvent                      onItemExpire
PlayerEvent.PlayerLoggedInEvent      onPlayerLoggedIn
PlayerEvent.PlayerRespawnEvent       onPlayerRespawn
PlayerEvent.Clone                    onPlayerDeath
PlayerEvent.PlayerChangedDimensionEvent onPlayerChangeDimension
ServerChatEvent                      onServerChat
PlayerInteractEvent.RightClickBlock  onPlayerRightClickBlock
PlayerInteractEvent.RightClickItem   onPlayerRightClickItem
PlayerInteractEvent.RightClickEmpty  onPlayerRightClickEmpty
UseItemOnBlockEvent                  onUseItemOnBlock
LivingEntityUseItemEvent.Finish      onItemUseFinish
AddReloadListenerEvent               addReloadListeners
OnDatapackSyncEvent                  onDataPackSync
TagsUpdatedEvent                     onTagsUpdated
BonemealEvent                        onBoneMeal
SelectClimateModelEvent              onSelectClimateModel
PlayerInteractEvent.EntityInteract   onEntityInteract
EntityMountEvent                     onMount
AnimalTameEvent                      onAnimalTame
PlayerContainerEvent.Open            onContainerOpen
CropGrowEvent.Pre                    onCropsGrow
```

> 结论：**几乎所有的原版交互都被 TFC 接管过**。附属模组若要改 TFC 行为，
> 应优先监听**同样的 NeoForge 事件**并注意优先级（TFC 用 LOWEST/HIGHEST 抢占两端），
> 或者使用 TFC 提供的可取消自定义事件（上面 3.1）来「叠加」而非「覆盖」。

---

## 4. 气候 API（`net.dries007.tfc.util.climate`）

```java
public interface ClimateModel {
    float MIN_AVERAGE_RAINFALL, MAX_AVERAGE_RAINFALL;
    int   NUM_SAMPLES_FOR_DELTAS;
    float MAX_CROP_RAINFALL, MAX_INSTANTANEOUS_RAINFALL;

    ClimateModelType<?> type();
    default float hemisphereScale();

    float getAverageTemperature(LevelReader, BlockPos);
    default float getInstantTemperature(LevelReader, BlockPos);
    default float getInstantTemperature(LevelReader, BlockPos, long, int);
    default float getTimeAverageTemperature(LevelReader, BlockPos, long, long, int);

    float getAverageRainfall(LevelReader, BlockPos);
    default float getRainfallVariance(LevelReader, BlockPos);
    default float getInstantRainfall(LevelReader, BlockPos);
    default float getTimeAverageRainfall(LevelReader, BlockPos, long, long, int);

    default float getBaseGroundwater(LevelReader, BlockPos);
    default float getAverageGroundwater(LevelReader, BlockPos);

    default float   getRain(long);
    default boolean getThunder(long);
    default boolean supportsRain();
    default Vec2    getWind(Level level, BlockPos pos);
    default float   getFog(LevelReader, BlockPos);
}
```

注册：`ClimateModels` 是一个**自定义注册表**（`KEY`/`REGISTRY` + `DeferredRegister TYPES`），
内置两个模型 `OVERWORLD`、`BIOME_BASED`。
要让某个维度使用自定义气候模型，监听 `SelectClimateModelEvent` 并 `setModel(...)`（TFC 自己以 `HIGHEST` 优先级处理）。

附属模组常见用法：
- 只读查询：`ClimateModel model = ...; float t = model.getInstantTemperature(level, pos);`
- 需要「按时间采样」时用 `getInstantTemperature(level, pos, calendarTicks, daysIn)` 形式。

---

## 5. 日历 API（`net.dries007.tfc.util.calendar`）

```java
public final class Calendars {
    public static final ServerCalendar SERVER;
    public static final ClientCalendar CLIENT;
    public static ICalendar get(LevelReader level);
    public static ICalendar get(boolean isClientSide);
    public static ICalendar get();          // 依据当前线程/环境推断
}
```

`ICalendar` 关键成员：

| 类别 | 成员 |
|---|---|
| 常量 | `HOURS_IN_DAY`、`MONTHS_IN_YEAR`、`TICKS_IN_DAY`、`CALENDAR_TICKS_IN_HOUR`、`CALENDAR_TICKS_IN_DAY`、`PLAYER_TICKS_IN_DEFAULT_HOUR`、`PLAYER_TICKS_IN_DEFAULT_DAY` |
| 静态工具 | `getTimeAndDate(long, long)`、`getDayTime(long)`、`getTimeDelta(long, int)`、`getHourOfDay(long)`、`getTotalCalendarDays(long)`、`getFractionOfHour/Day/Month/Year(...)`、`getMonthOfYear(long, long)` |
| 实例抽象 | `transaction()`、`getTicks()`、`getCalendarTicks()`、`getCalendarDaysInMonth()`、`getCalendarTickFromOffset(long)`、`getFixedCalendarTicksFromTick(long)` |
| 实例默认方法 | `getTotalCalendarDays()`、`getCalendarYear()`、`getCalendarDayOfMonth()`、`getCalendarFractionOfHour/Day/Month/Year()`、`getCalendarDayOfYear()`、`getBirthday()`、`getHemispheralCalendarMonthOfYear(boolean)`、`getAbsoluteCalendarMonthOfYear()`、`getCalendarTicksInMonth()/Year()`、`getTimeAndDate()`、`getDayTime()`、`getHourOfDay()`、`getMinuteOfHour()`、`getExactTimeAndDate(long)`、`getOffsetTimeAndDate(long)`、`getTimeDelta(long)`、`getCalendarTimeDelta(long)` |

**重点**：`getHemispheralCalendarMonthOfYear(boolean southernHemisphere)` —— 农业/季节逻辑必须用它，
否则南北半球季节会反。`Calendars.get(level)` 会自动区分服务端/客户端实现（`ServerCalendar` / `ClientCalendar`）。

相关：`CalendarEventHandler`（主类构造器中 `CalendarEventHandler.init()` 初始化）负责日历推进与同步包。

---

## 6. 交互扩展：`InteractionManager`

```java
public final class InteractionManager {
    public static void registerBlock(BlockItemPlacement placement);
    public static void registerBlock(Ingredient ingredient, OnItemUseAction action);
    public static void registerBlock(KeyedIngredient ingredient, OnItemUseAction action);
    public static void register(Ingredient ingredient, Target target, OnItemUseAction action);
    public static synchronized void register(ItemAbility ability, Target target, OnItemUseAction action);
    public static void registerDefaultInteractions();
    public static Optional<InteractionResult> onItemUse(ItemStack stack, UseOnContext context, boolean isInside);
}
```

- `registerDefaultInteractions()` 在 `FMLCommonSetupEvent` 中被调用（主类 `setup` 第一段），
  附属模组若也想用这套机制，应在自己的 `FMLCommonSetupEvent` 里调用 `InteractionManager.register(...)`。
- `Target` 是嵌套枚举/接口，描述「对空气 / 对方块 / 对实体」。
- 该机制最终由 `ForgeEventHandler.onUseItemOnBlock` 等事件驱动，所以注册时机必须早于世界加载。

---

## 7. `Helpers` 工具方法速查（`net.dries007.tfc.util.Helpers`）

| 分组 | 方法 |
|---|---|
| 资源定位 | `identifier(String)`（→ `tfc:` 命名空间）、`identifierMC(String)`、`resourceLocation(String)`、`resourceLocation(String,String)` |
| 能力 | `getCapability(...)`（3 个重载）、`mightHaveCapability(ItemStack, ItemCapability)` |
| 集合/枚举 | `mapOf(Class<E>, Function)`、`mapOf(Class<E>, Predicate, Function)`、`mapValue(Map, Function)`、`getRandomValue(Map, RandomSource)`、`translateEnum(Enum)`、`getEnumTranslationKey(Enum)` |
| 方块属性 | `copyProperties(BlockState, BlockState)`、`copyProperty(...)`、`setProperty(...)`、`getSupportedDirectionalStateForPlacement(...)` |
| 物品 | `damageItem(...)`（5 个重载）、`isItem(ItemStack, ItemLike/TagKey)`、`randomItem(TagKey, RandomSource)`、`allItems(TagKey)` |
| 方块/流体/实体 tag | `isBlock(...)`、`randomBlock(...)`、`allBlocks(...)`、`isFluid(...)`、`allFluids(...)`、`isEntity(...)`、`randomEntity(...)`、`isDamageSource(...)` |
| 容器/物品栏 | `iterate(IItemHandler[, start, end])`、`iterate(RecipeInput)`、`removeStack`、`mergeInsertStack`、`insertAllSlots`、`insertSlots`、`mergeInsertAll`、`insertOne(...)`、`isEmpty(Iterable<ItemStack>)`、`hasOpenSlot(...)`、`copyTo(...)`、`copyToAndClear(...)`、`copyFrom(...)`、`addInventoryTooltipInfo(...)` |
| 世界操作 | `removeBlock(LevelAccessor, BlockPos, int flags)`、`spawnItem(...)`（3 个重载）、`dropWithContext(...)`、`destroyBlockAndDropBlocksManually(...)`、`playPlaceSound(...)`、`playSound(...)`、`fireSpreaderTick(...)` |
| NBT | `writeItemStacksToNbt(HolderLookup.Provider, List<ItemStack>)`、`readItemStacksFromNbt(...)`、`readFixedSizeItemStacksFromNbt(...)` |
| 数学/噪声 | `lerp`、`lerp4`、`inverseLerp`、`hash(long, ...)`、`fork(RandomSource)`、`triangle(...)`、`uniform(...)`、`easeInOutCubic`、`ceilDiv`、`diamondAngle`、`hyperbolicSection`、`mix64`、`SeedLargeFeatures` 等 |
| 形状 | `rotateShape(Direction, ...)`、`computeHorizontalShapes(Function<Direction, VoxelShape>)`、`quartToBlock(int,int,int)` |
| 异常/其它 | `uncheck(ThrowingSupplier/ThrowingRunnable)`、`throwAsUnchecked(Throwable)`、`adjustAverageTemperatureByElevation(int, float, float)`、`perfectMatchExists(List, List<Predicate>)` |

**注意**：`Helpers.identifier(String)` 固定使用 `tfc` 命名空间；附属模组应用自己模组的命名空间构造 `ResourceLocation`。

---

## 8. 网络

TFC 的网络包类型共 20 个（`net.dries007.tfc.network`）：`ChunkWatchPacket`、`CalendarUpdatePacket`、
`PlayerInfoPacket`、`ProspectedPacket`、`UpdateClimateModelPacket`、`DataManagerSyncPacket`（以上 playToClient），
以及 `SwitchInventoryTabPacket`、`PlaceBlockSpecialPacket`、`CycleChiselModePacket`、`ScreenButtonPacket`、
`PlayerDrinkPacket`、`RequestClimateModelPacket`、`ScribingTablePacket`、`StackFoodPacket`、`OpenFieldGuidePacket`、
`PetCommandPacket`、`PourFasterPacket`、`SelectAnvilPlanPacket`（playToServer）。

照抄模板（`PacketHandler`）：

```java
public static <T extends CustomPacketPayload> CustomPacketPayload.Type<T> type(String id) {
    return new CustomPacketPayload.Type<>(ResourceLocation.fromNamespaceAndPath("mymod", id));
}
public static void setup(RegisterPayloadHandlersEvent event) {
    PayloadRegistrar r = event.registrar(ModList.get().getModFileById("mymod").versionString());
    r.playToClient(MyPacket.TYPE, MyPacket.CODEC, (payload, ctx) -> ctx.enqueueWork(() -> payload.handle()));
    r.playToServer(MyPacket2.TYPE, MyPacket2.CODEC, (payload, ctx) -> ctx.enqueueWork(() -> payload.handle(ctx.player())));
}
```

**特别注意**：`DataManagerSyncPacket` 说明 TFC 会把**数据驱动内容同步到客户端**。
附属模组如果注册了带 `StreamCodec` 的 `DataManager`（例如自定义数据表需要在客户端读取），
就必须走同样的同步路径（`DataManager` 构造时传入 streamCodec → `isSynced()` 为 true）。

---

## 9. 附属模组常见任务的 API 组合（配方表）

| 任务 | 需要调用的东西 |
|---|---|
| 新增一个 TFC 风格方块（含 BE、GUI、配方） | `TFCBlocks` 式注册类（自己写）+ `RegistrationHelpers.registerBlock` + `register(BE)` + `registerBlockEntityContainer` + `Container`/`BlockEntityContainer` + `ExtendedProperties` |
| 让我的方块能装 TFC 物品（尺寸/重量受限） | 在 `Container` 里用 `ItemSizeManager.get(stack)` 校验 + `Helpers.hasOpenSlot` |
| 新增一种 TFC 配方 | 实现 `Recipe`/`RecipeSerializer`（参考 `ISimpleRecipe`、`IRecipePredicate`），注册进自己的 `RecipeType`/`RecipeSerializer` `DeferredRegister`，并让方块实体调用 `level.getRecipeManager().getRecipeFor(...)` |
| 给已有 TFC 配方类型加内容 | 不需要代码：往数据包 `data/<ns>/recipe/<type>/...` 放 JSON（格式见 `12-tfc-data-driven.md`） |
| 让物品参与食物系统 | `data/<ns>/tfc/food/*.json` + 资源重载自动应用；或用 `FoodCapability` 手动 `applyTrait` |
| 让物品有温度 | `data/<ns>/tfc/item_heat/*.json` + `HeatCapability` |
| 让物品有尺寸/重量 | `data/<ns>/tfc/item_size/*.json`，或物品实现 `IItemSize` |
| 自定义气候 | 注册 `ClimateModelType`（`ClimateModels` 式自定义注册表）+ 监听 `SelectClimateModelEvent` |
| 写 Patchouli 手册 | 见 `40-patchouli-api.md`；TFC 侧还提供 `PatchouliIntegration` 与自定义 page 组件（`net.dries007.tfc.compat.patchouli.component.*`） |

> 关于 TFC 侧的 Patchouli 集成（已用反编译源码 + jar 内真实 JSON 双向核实，纠正一个常见误解）：
>
> 1. TFC 在 `FMLCommonSetupEvent` 中调用 `PatchouliIntegration.registerMultiBlocks()`，通过
>    `PatchouliAPI.get().registerMultiblock(id, multiblock)` 注册 **12 个多块结构**：
>    `bloomery`、`blast_furnace`、`full_blast_furnace`、`rock_anvil`、`charcoal_forge`、`channel_casting`、
>    `windmill`、`water_wheel`、`clutch_off`、`clutch_on`、`crankshaft`、`rotating_quern`（命名空间 `tfc`）。
> 2. TFC **没有注册任何新的 Patchouli page（页面）类型** —— Patchouli 1.21.1 本身也不提供页面类型注册 API。
>    TFC 用的是「**模板 JSON + 自定义渲染组件**」方案：jar 内
>    `assets/tfc/patchouli_books/field_guide/en_us/templates/` 下有 13 个模板
>    （`anvil_recipe`、`glassworking_recipe`、`heat_recipe`、`instant_barrel_recipe`、`knapping_recipe`、
>    `loom_recipe`、`multimultiblock`、`quern_recipe`、`rock_knapping_recipe`、`sealed_barrel_recipe`、
>    `table`、`table_small`、`welding_recipe`）。
>    例如 `heat_recipe.json` 的全部内容就是：
>    ```json
>    {"components":[
>      {"type":"patchouli:custom","x":0,"y":0,
>       "class":"net.dries007.tfc.compat.patchouli.component.HeatingComponent","recipe":"#recipe"},
>      {"type":"patchouli:text","x":0,"y":45,"text":"#text"}]}
>    ```
>    条目里写 `"type": "tfc:heat_recipe"` 即可套用该模板，并通过 `"recipe": "tfc:heating/xxx"` 把值传给 `#recipe` 变量。
> 3. 这些渲染组件都继承 `net.dries007.tfc.compat.patchouli.component.CustomComponent`（抽象类，
>    实现 `vazkii.patchouli.api.ICustomComponent`），基类提供 `renderItemStacks`、`renderFluidStack`、
>    `asRecipe(String, RecipeType<T>)`、`asMultiblock(IVariable)`、`asTextComponent(JsonElement)` 等工具。
>
> 详见 `50-tfc-patchouli-integration.md` 与 `40-patchouli-api.md`。
