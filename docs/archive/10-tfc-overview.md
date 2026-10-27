# TFC 4.2.10 架构总览与注册体系

> 适用环境（本机实例实测，来自 `logs/latest.log` 与各 jar 的 `META-INF/neoforge.mods.toml`）：
>
> | 项目 | 值 |
> |---|---|
> | Minecraft | 1.21.1 |
> | NeoForge | 21.1.248（`--fml.neoForgeVersion 21.1.248`） |
> | FML | 4.0.43 |
> | Java | 21.0.3（Microsoft OpenJDK） |
> | TFC | 4.2.10（`TerraFirmaCraft-NeoForge-1.21.1-4.2.10.jar`，mod id `tfc`） |
> | Firmalife | 3.0.14（mod id `firmalife`，要求 `tfc >= 4.2.8`、`patchouli >= 1.21.1-92-NEOFORGE`） |
> | Patchouli | 1.21.1-93（mod id `patchouli`，要求 `neoforge >= 21.0.31-beta`、`minecraft [1.21.1,1.21.2)`） |
>
> TFC 自身把 `patchouli` 声明为**硬依赖**（`type = "required"`，`versionRange = "[1.21.1-92-NEOFORGE,)"`）。
> 因此任何依赖 TFC 的附属模组都可以直接假定 Patchouli 存在。
>
> 本文所有代码事实来自两个来源，二者版本完全一致：
> 1. CFR 0.152 反编译产物：`moddev/src-ref/TFC-decompiled/net/dries007/tfc/...`（1672 个 .java）
> 2. jar 直接 javap 转储：`moddev/inventory/api-dump/TFC-public-api.txt`（284 个类的 public 签名）

---

## 1. 顶层结构

TFC 的入口类只有两个：

| 类 | 作用 |
|---|---|
| `net.dries007.tfc.TerraFirmaCraft` | `@Mod("tfc")` 主类，负责全部注册与配置 |
| `net.dries007.tfc.ForgeEventHandler` | 全局事件总线（`NeoForge.EVENT_BUS`）监听器集合 |

主类声明（`net/dries007/tfc/TerraFirmaCraft.java`）：

```java
@Mod("tfc")
public final class TerraFirmaCraft {
    public static final String MOD_ID = "tfc";
    public static final String MOD_NAME = "TerraFirmaCraft";
    public static final Logger LOGGER = LogUtils.getLogger();
    public static final boolean JEI  = ModList.get().isLoaded("jei");
    public static final boolean EMI  = ModList.get().isLoaded("emi");
    public static final boolean JADE = ModList.get().isLoaded("jade");
    public static final boolean THE_ONE_PROBE = ModList.get().isLoaded("theoneprobe");
    public static final ResourceKey<WorldPreset> PRESET =
        ResourceKey.create(Registries.WORLD_PRESET, Helpers.identifier("overworld"));

    public TerraFirmaCraft(ModContainer mod, IEventBus bus) { ... }
}
```

关键点：NeoForge 支持把 `ModContainer` 与 `IEventBus` 直接注入 `@Mod` 构造器，TFC 用的正是这个签名
`public TerraFirmaCraft(ModContainer mod, IEventBus bus)`。附属模组应当照抄这一签名。

---

## 2. 包结构（按类数量排序，来自 `moddev/inventory/TFC.classes.txt`）

| 包 | 类数 | 内容 |
|---|---|---|
| `net.dries007.tfc.common.blocks.plant` | 92 | 植物方块（含果树、树苗、作物外观） |
| `net.dries007.tfc.common.blockentities` | 89 | 方块实体（+ `rotation` 子包 24 个） |
| `net.dries007.tfc.client.model.entity` | 74 | 客户端实体模型 |
| `net.dries007.tfc.common.blocks` | 73 | 通用方块与方块属性体系 |
| `net.dries007.tfc.common.container` | 57 | 菜单/容器（Menu） |
| `net.dries007.tfc.common.items` | 56 | 物品 |
| `net.dries007.tfc.common.blocks.devices` | 49 | 工艺方块（砧、桶、炉、锅……） |
| `net.dries007.tfc.common.recipes` | 47 | 配方类型与序列化器（+ `outputs` 子包 32 个） |
| `net.dries007.tfc.util` | 46 | 工具类、注册辅助、数据、气候、日历 |
| `net.dries007.tfc.common.entities.*` | 24+28+23+45 | 实体、牲畜、水生生物、AI |
| `net.dries007.tfc.compat.*` | ~100 | JEI / EMI / Jade / TOP / Patchouli / Vivecraft 集成 |
| `net.dries007.tfc.world.*` | ~300 | 世界生成（region / river / biome / surface / feature） |
| `net.dries007.tfc.network` | 26 | 网络包 |
| `net.dries007.tfc.mixin` | 33 | Mixin |

**记忆锚点**：附属模组 95% 的时间只会接触 `common.blocks`、`common.items`、`common.blockentities`、
`common.container`、`common.recipes`、`util.*` 这六个区域。

---

## 3. 启动流程（主类构造器内的严格顺序）

`TerraFirmaCraft(ModContainer mod, IEventBus bus)` 的步骤（源码行号即反编译文件行号）：

1. **配置注册**（`TerraFirmaCraft.java:126-128`）
   ```java
   mod.registerConfig(ModConfig.Type.CLIENT, TFCConfig.CLIENT.spec());
   mod.registerConfig(ModConfig.Type.SERVER, TFCConfig.SERVER.spec());
   mod.registerConfig(ModConfig.Type.COMMON, TFCConfig.COMMON.spec());
   ```
   → 对应实例中的 `config/tfc-client.toml`、`tfc-common.toml`（SERVER 配置落在世界存档的 `serverconfig/`）。
2. **模组总线事件监听器**（`:129-140`）：`setup`、`registerRegistries`、`registerDatapackRegistries`、`loadComplete`，
   以及一批静态方法引用（`TFCEntities::onEntityAttributeCreation`、`TFCComponents::onModifyDefaultComponents`、
   `ItemCapabilities::register`、`BlockCapabilities::register`、`TFCCreativeTabs::addToVanillaTabs`、
   `Faunas::registerSpawnPlacements`、`PacketHandler::setup`）。
3. **一次性注册 40+ 个 `DeferredRegister`**（`:141-185`），全部调用 `.register(bus)`。
4. **事件处理类初始化**（`:186-187`）：`CalendarEventHandler.init()`、`ForgeEventHandler.init()`。
5. **客户端分支**（`:188-192`）：`if (FMLEnvironment.dist == Dist.CLIENT) { ClientEventHandler.init(mod, bus); ... }`
   —— 附属模组必须照抄这个「客户端类只在 Dist.CLIENT 下引用」的模式，否则专用服务器会因缺失客户端类而崩溃。
6. **可选集成分支**（`:193-195`）：`if (THE_ONE_PROBE) TheOneProbeIntegration.init(bus);`
   —— 用 `ModList.get().isLoaded("...")` 得到的静态布尔量做门控。

### `setup(FMLCommonSetupEvent)`（`:199-223`）

```java
public void setup(FMLCommonSetupEvent event) {
    PropickItem.registerDefaultRepresentativeBlocks();
    InteractionManager.registerDefaultInteractions();
    ServerCalendar.overrideDoDaylightCycleCallback();
    ChiselMode.setupOrdering();
    event.enqueueWork(() -> {
        DispenserBehaviors.registerDispenserBehaviors();
        TFCFluids.registerFluidInteractions();
        IBellowsConsumer.registerDefaultOffsets();
        Wood.registerBlockSetTypes();
        TFCBrain.initializeScheduleContents();
        MetalItem.init();
        TFCBlocks.registerFlowerPotFlowers();
        TFCBlocks.editBlockRequiredTools();
    }).exceptionally(e -> { ... });
    PatchouliIntegration.registerMultiBlocks();   // ← 注意：不在 enqueueWork 内
    if (JADE) JadeIntegration.registerToolHandlers();
}
```

**重要约定**：FML 官方要求「跨模组、可能触发并行加载问题」的工作放进 `event.enqueueWork(...)`；
TFC 把与 Patchouli 的多块结构注册放在 `enqueueWork` **之外**，因为它需要在工作队列之前与 Patchouli 交互。

### `registerRegistries(NewRegistryEvent)`（`:225-235`）

注册 TFC 自建的 9 个**自定义注册表**（非原版注册表，位于 `ResourceKey<Registry<T>>`）：

```java
event.register(FoodTraits.REGISTRY);        // 食物词条（FoodTrait）
event.register(ItemStackModifiers.REGISTRY); // 物品堆修改器（配方输出用）
event.register(PotOutput.REGISTRY);          // 锅输出类型
event.register(ClimateModels.REGISTRY);      // 气候模型
event.register(DataManagers.REGISTRY);       // 数据管理器注册表
event.register(BarSystem.REGISTRY);          // 血条系统（客户端）
event.register(TFCBiomes.REGISTRY);          // 群系扩展
event.register(ChiselMode.REGISTRY);         // 凿子模式
event.register(GlassOperation.REGISTRY);     // 玻璃加工工序
```

### `registerDatapackRegistries(DataPackRegistryEvent.NewRegistry)`（`:237-239`）

```java
event.dataPackRegistry(RockSettings.KEY, RockSettings.CODEC);
```

这是**数据包级注册表**：内容由数据包 JSON 提供（`data/tfc/tfc/worldgen/...`），
服务端加载时会同步给客户端。附属模组若要新增「由数据包定义的注册表」，必须用这个事件，而不是 `NewRegistryEvent`。

### `loadComplete(FMLLoadCompleteEvent)`（`:241-245`）

把 `setup` 中 `enqueueWork` 抛出的异常延迟抛出，保证不影响其它模组加载。

---

## 4. 七大注册层

TFC 的「注册」并不只有 `DeferredRegister`。按生命周期从早到晚：

| 层 | 注册手段 | 事件/时机 | 典型例子 |
|---|---|---|---|
| L1 | `DeferredRegister<T>` | 主类构造器内 `.register(bus)` | 方块、物品、方块实体、菜单、实体、流体、音效、粒子、创造标签 |
| L2 | 自定义 `Registry<T>` | `NewRegistryEvent` | `FoodTraits`、`ClimateModels`、`GlassOperation` |
| L3 | 数据包注册表 | `DataPackRegistryEvent.NewRegistry` | `RockSettings` |
| L4 | `DataComponentType` | `DeferredRegister<DataComponentType<?>>` + `ModifyDefaultComponentsEvent` | `TFCComponents.FOOD/HEAT/FORGING/...` |
| L5 | 数据驱动管理器 | `DataManager` + `SimpleJsonResourceReloadListener` | `data/tfc/tfc/fuel|food|item_heat|...` |
| L6 | 能力（Capability） | `RegisterCapabilitiesEvent` | `ItemCapabilities.HEAT/MOLD/FLUID/ITEM`、`BlockCapabilities` |
| L7 | 网络负载 | `RegisterPayloadHandlersEvent` | `PacketHandler.setup` |

### L1 全部 `DeferredRegister` 清单（源码 `TerraFirmaCraft.java:141-185`）

```java
TFCBlocks.BLOCKS            TFCItems.ITEMS             TFCContainerTypes.CONTAINERS
TFCEntities.ENTITIES        TFCFluids.FLUIDS           TFCRecipeTypes.RECIPE_TYPES
TFCRecipeSerializers.RECIPE_SERIALIZERS                TFCSounds.SOUNDS
TFCParticles.PARTICLE_TYPES TFCBlockEntities.BLOCK_ENTITIES
TFCCreativeTabs.CREATIVE_TABS
TFCLoot.CONDITIONS          TFCLoot.NUMBER_PROVIDERS   TFCLoot.LOOT_FUNCTIONS
TFCEffects.EFFECTS
TFCBrain.ACTIVITIES         TFCBrain.MEMORY_TYPES      TFCBrain.SCHEDULES
TFCBrain.SENSOR_TYPES       TFCBrain.POI_TYPES
TFCAdvancements.TRIGGERS    TFCComponents.COMPONENTS
TFCArmorMaterials.ARMOR_MATERIALS                      TFCPoiTypes.TYPES
TFCBlockPredicates.BLOCK_PREDICATES                    TFCPlacements.PLACEMENT_MODIFIERS
TFCFeatures.FEATURES        TFCCarvers.CARVERS
TFCWorldGen.CHUNK_GENERATOR TFCWorldGen.BIOME_SOURCE
TFCStateProviders.BLOCK_STATE_PROVIDERS                TFCStructureHooks.STRUCTURE_PLACEMENTS
TFCDensityFunctions.TYPES
FoodTraits.TRAITS           ItemStackModifiers.TYPES   PotOutput.TYPES
ClimateModels.TYPES         DataManagers.MANAGERS      BarSystem.BARS
TFCBiomes.EXTENSIONS        ChiselMode.MODES           GlassOperation.OPERATIONS
TFCFluids.FLUID_TYPES       TFCIngredients.TYPES       TFCAttachments.TYPES
```

> 注意 `TFCFluids.FLUIDS` 与 `TFCFluids.FLUID_TYPES` 是**两个独立的 `DeferredRegister`**，
> 且 `FLUID_TYPES` 的 `.register(bus)` 出现在第 183 行（晚于 `FLUIDS`），顺序有意义（见 `RegistrationHelpers.registerFluid`）。

### L6 能力注册（`net/dries007/tfc/common/capabilities/ItemCapabilities.java`）

```java
public static final ItemCapability<IHeat, Void>            HEAT  = ItemCapability.createVoid(Helpers.identifier("heat"), IHeat.class);
public static final ItemCapability<IMold, Void>            MOLD  = ItemCapability.createVoid(Helpers.identifier("mold"), IMold.class);
public static final ItemCapability<IFluidHandlerItem, Void> FLUID = Capabilities.FluidHandler.ITEM;  // NeoForge 内置
public static final ItemCapability<IItemHandler, Void>      ITEM  = Capabilities.ItemHandler.ITEM;    // NeoForge 内置

public static void register(RegisterCapabilitiesEvent event) {
    event.registerItem(MOLD,  ItemCapabilities::forMold,  molds);
    event.registerItem(HEAT,  ItemCapabilities::forMold,  molds);
    event.registerItem(FLUID, ItemCapabilities::forMold,  molds);
    ...
}
```

要点：
- TFC 用 **NeoForge Capability**（不是旧版 Forge `Capability`，也不是 1.20 的 `ICapabilityProvider`）。
- `ItemCapability.createVoid(id, Class)` 是 NeoForge 的「无上下文」物品能力工厂；ID 直接由 `Helpers.identifier(String)` 生成，即 `tfc:heat`、`tfc:mold`。
- 注册用 `event.registerItem(capability, factory, itemLikes...)` / `event.registerBlockEntity(...)`。

### L7 网络（`net/dries007/tfc/network/PacketHandler.java`）

```java
public static <T extends CustomPacketPayload> CustomPacketPayload.Type<T> type(String id) {
    return new CustomPacketPayload.Type<>(Helpers.identifier(id));
}

public static void setup(RegisterPayloadHandlersEvent event) {
    PayloadRegistrar register = event.registrar(ModList.get().getModFileById("tfc").versionString());
    register.playToClient(ChunkWatchPacket.TYPE, ChunkWatchPacket.CODEC, onClient(ChunkWatchPacket::handle));
    ...
    register.playToServer(ScreenButtonPacket.TYPE, ScreenButtonPacket.CODEC, onServer(ScreenButtonPacket::handle));
}

private static <T extends CustomPacketPayload> IPayloadHandler<T> onClient(Consumer<T> handler) {
    return (payload, context) -> context.enqueueWork(() -> handler.accept(payload));
}
private static <T extends CustomPacketPayload> IPayloadHandler<T> onServer(BiConsumer<T, ServerPlayer> handler) {
    return (payload, context) -> context.enqueueWork(() -> handler.accept(payload, context.player()));
}
```

`event.registrar(version)` 传入版本字符串即可获得**版本校验**：客户端与服务端该模组的版本不一致时直接拒绝连接。
附属模组写网络包时应照抄 `onClient`/`onServer` 包装（`context.enqueueWork` 保证线程安全）。

---

## 5. 注册辅助类型体系（`net.dries007.tfc.util.registry`）

TFC 不直接返回 `DeferredHolder`，而是包一层自己的接口/record。理解这套体系是读懂 TFC 注册代码的前提。

```java
// IdHolder.java —— 能拿到自己的注册名
public interface IdHolder<T> extends Supplier<T> {
    DeferredHolder<? super T, T> holder();
    default ResourceLocation getId() { ... }   // 由 holder().getId() 派生
}

// HolderHolder.java —— 能拿到自己的 ResourceKey
public interface HolderHolder<R> {
    DeferredHolder<R, ? extends R> holder();
    default ResourceKey<R> key() { ... }
}

// RegistryHolder.java —— 两者合并
public interface RegistryHolder<R, T extends R> extends IdHolder<T>, HolderHolder<R> {
    @Override DeferredHolder<R, T> holder();
    default T get() { return holder().get(); }
}
```

实际使用的形态是**每个注册类内部的 `Id` record**，例如 `TFCBlocks`：

```java
public record Id<T extends Block>(DeferredHolder<Block, T> holder)
        implements RegistryHolder<Block, T>, ItemLike {
    @Override public Item asItem() { return get().asItem(); }
}
```

`TFCItems.ItemId`、`TFCEntities.Id`、`TFCContainerTypes.Id`、`TFCComponents.Id`、`TFCRecipeTypes.Id`、
`TFCRecipeSerializers.Id` 都是同一套模式的复制品。**附属模组不需要复刻这套包装，直接返回 `DeferredHolder` 即可**；
但如果要接收 TFC 的类型，要知道 `TFCBlocks.Id<Block>` 是 `Supplier<Block>` 且 `ItemLike`。

### `RegistrationHelpers`（完整签名，来自 `RegistrationHelpers.java`）

```java
public final class RegistrationHelpers {
    // 方块 + 可选方块物品
    public static <T extends Block> DeferredHolder<Block, T> registerBlock(
        DeferredRegister<Block> blocks, DeferredRegister<Item> items,
        String name, Supplier<T> blockSupplier,
        @Nullable Function<T, ? extends BlockItem> blockItemFactory);

    // 流体（同时注册 FluidType + source + flowing，用 MutableObject 解决循环依赖）
    public static <F extends FlowingFluid> FluidHolder<F> registerFluid(
        DeferredRegister<FluidType> fluidTypes, DeferredRegister<Fluid> fluids,
        String typeName, String sourceName, String flowingName,
        Consumer<BaseFlowingFluid.Properties> builder,
        Supplier<FluidType> typeFactory,
        Function<BaseFlowingFluid.Properties, F> sourceFactory,
        Function<BaseFlowingFluid.Properties, F> flowingFactory);

    // 方块实体（单个方块 / 多方块共享一个 BE 类型）
    public static <T extends BlockEntity> DeferredHolder<BlockEntityType<?>, BlockEntityType<T>> register(
        DeferredRegister<BlockEntityType<?>> blockEntities, String name,
        BlockEntityType.BlockEntitySupplier<T> factory, Supplier<? extends Block> block);
    public static <T extends BlockEntity> DeferredHolder<BlockEntityType<?>, BlockEntityType<T>> register(
        DeferredRegister<BlockEntityType<?>> blockEntities, String name,
        BlockEntityType.BlockEntitySupplier<T> factory, Stream<? extends Supplier<? extends Block>> blocks);

    // 菜单：绑定到方块实体 / 绑定到物品堆（背包内物品 GUI）
    public static <T extends InventoryBlockEntity<?>, C extends BlockEntityContainer<T>>
        DeferredHolder<MenuType<?>, MenuType<C>> registerBlockEntityContainer(
            DeferredRegister<MenuType<?>> containers, String name,
            Supplier<BlockEntityType<T>> type, BlockEntityContainer.Factory<T, C> factory);

    public static <C extends ItemStackContainer> DeferredHolder<MenuType<?>, MenuType<C>> registerItemStackContainer(
        DeferredRegister<MenuType<?>> containers, String name, ItemStackContainer.Factory<C> factory);

    public static <C extends AbstractContainerMenu> DeferredHolder<MenuType<?>, MenuType<C>> registerContainer(
        DeferredRegister<MenuType<?>> containers, String name, IContainerFactory<C> factory);
}
```

`registerBlockEntityContainer` 生成了一个 `IContainerFactory`，它的关键行为是**从网络缓冲区读取 `BlockPos` 再解析方块实体**：

```java
(windowId, playerInventory, buffer) -> {
    Level level = playerInventory.player.level();
    BlockPos pos = buffer.readBlockPos();
    InventoryBlockEntity entity = level.getBlockEntity(pos, type.get()).orElseThrow();
    return factory.create(entity, playerInventory, windowId);
}
```

因此附属模组若要在服务端打开 TFC 风格 GUI，只需：
`player.openMenu(blockEntity)`（`InventoryBlockEntity` 已实现 `MenuProvider`）。

---

## 6. `ExtendedProperties` / `ExtendedBlock` 体系

TFC 的方块几乎都继承 `ExtendedBlock`，构造器接收 `ExtendedProperties`（而不是原版 `BlockBehaviour.Properties`）：

```java
public class ExtendedBlock extends Block implements IForgeBlockExtension {
    private final ExtendedProperties extendedProperties;
    public ExtendedBlock(ExtendedProperties properties) { super(properties.properties()); ... }
    @Override public ExtendedProperties getExtendedProperties() { return extendedProperties; }
}
```

`ExtendedProperties` 是原版属性的**包装器 + 扩展**，链式 API 全部返回 `this`。重要的 TFC 专属方法：

| 方法 | 作用 |
|---|---|
| `ExtendedProperties.of()` / `.of(MapColor)` / `.of(DyeColor)` / `.of(BlockBehaviour)` / `.of(BlockBehaviour.Properties)` | 工厂方法 |
| `.blockEntity(Supplier<? extends BlockEntityType<?>>)` | 记录并自动设置 `hasBlockEntity()` |
| `.ticks(BlockEntityTicker<T>)` | 同时注册服务端 + 客户端 ticker |
| `.serverTicks(BlockEntityTicker<T>)` / `.clientTicks(BlockEntityTicker<T>)` | 单侧 ticker |
| `.ticks(@Nullable server, @Nullable client)` | 双侧显式写法 |
| `.flammable(int flammability, int fireSpread)`、`.flammableLikeLogs()`、`.flammableLikePlanks()`、`.flammableLikeLeaves()`、`.flammableLikeWool()` | 可燃性预设 |
| `.cloneItem(@Nullable ItemLike)` / `.cloneEmpty()` | 方块被破坏时掉落什么（TFC 的 `cloneItem` 用于「破坏后变成另一个方块」） |
| `.dynamicShape()`、`.isViewBlocking(...)`、`.isSuffocating(...)`、`.hasPostProcess(...)`、`.emissiveRendering(...)` | 原版谓词透传 |
| `.enchantPower(float)` / `.enchantPower(ToDoubleFunction<BlockState>)` | 附魔台加成 |
| `.pathType(PathType)` | 寻路代价 |
| `.properties()` | 取回 `BlockBehaviour.Properties` |
| `.hasBlockEntity()` / `.blockEntity()` | 读取记录的 BE 类型 |

其余 `.strength()`、`.sound()`、`.lightLevel()`、`.noOcclusion()`、`.randomTicks()`、`.instabreak()`、
`.requiresCorrectToolForDrops()`、`.pushReaction()`、`.instrument()`、`.mapColor()`、`.replaceable()`、
`.noLootTable()`、`.dropsLike()`、`.jumpFactor()`、`.speedFactor()`、`.friction()`、`.air()`、`.liquid()`、
`.forceSolidOn()`、`.forceSolidOff()`、`.offsetType()`、`.requiredFeatures()`、`.ignitedByLava()` 与原版一一对应。

用法示例（真实 TFC 代码，`TFCBlocks.java:348-352`）：

```java
public static final Id<Block> FIREPIT = register("firepit", () -> new FirepitBlock(
    ExtendedProperties.of(MapColor.DIRT)
        .strength(0.4f, 0.4f)
        .sound(SoundType.NETHER_WART)
        .randomTicks()
        .noOcclusion()
        .lightLevel(litBlockEmission(15))
        .blockEntity(TFCBlockEntities.FIREPIT)
        .pathType(PathType.DAMAGE_FIRE)
        .ticks(AbstractFirepitBlockEntity::serverTick, AbstractFirepitBlockEntity::clientTick)));
```

以及批量注册辅助（TFC 大量使用）：

```java
// 用 Helpers.mapOf 为每个枚举值注册一个资源
public static final Map<DyeColor, Id<Block>> RAW_ALABASTER = Helpers.mapOf(DyeColor.class,
    color -> register("alabaster/raw/" + color.getName(), () -> new Block(...)));

// 一次注册 slab + stairs + wall 三件套，返回 DecorationBlockHolder
private static <T1 extends SlabBlock, T2 extends StairBlock, T3 extends WallBlock>
DecorationBlockHolder registerDecorations(String baseName, Supplier<T1> slab, Supplier<T2> stair,
                                          Supplier<T3> wall, Item.Properties properties) { ... }
```

---

## 7. 附属模组应当遵守的时序规范（结论）

1. **注册一律用 `DeferredRegister` 并在 `@Mod` 构造器里 `.register(bus)`**；不要用 `RegisterEvent` 手动注册（TFC 也没用）。
2. **需要跨模组修改原版内容**（例如给已有方块加工具需求、注册熔炉燃料）放到 `FMLCommonSetupEvent`，且必须 `event.enqueueWork(...)`；
   TFC 自己在 `setup` 里就是这么改 `Blocks.GLASS` 等的（见 `TFCBlocks.editBlockRequiredTools()`）。
3. **能力注册**用 `RegisterCapabilitiesEvent`（模组总线）。
4. **网络包**用 `RegisterPayloadHandlersEvent`，并保留 `context.enqueueWork(...)`。
5. **数据组件**用 `DeferredRegister<DataComponentType<?>>` + 监听 `ModifyDefaultComponentsEvent` 给原版/自己物品加默认组件
   （参见 `TFCComponents.onModifyDefaultComponents`；TFC 还有一个 `onModifyDefaultComponentsAfterResourceReload()` 在资源重载后再次执行）。
6. **客户端类必须在 `Dist.CLIENT` 分支里引用**，绝不能让专用服务器加载到。
7. **软依赖**用 `ModList.get().isLoaded("id")` 的静态常量 + `if` 门控（TFC 对 jei/emi/jade/theoneprobe 的做法）。
   但 `patchouli` 不需要，TFC 已强制它存在。

---

## 8. 相关文档

| 文档 | 内容 |
|---|---|
| `11-tfc-registry-catalog.md` | 逐类列出 TFC 注册类与注册名规则 |
| `12-tfc-data-driven.md` | 数据驱动格式字典（28 种配方 + 17 类 `tfc/` 数据） |
| `13-tfc-api.md` | 公开 API、事件、组件、气候/日历、交互扩展点 |
| `20-addon-scaffold.md` | 附属模组工程骨架与可编译示例 |
| `30-firmalife-api.md` | Firmalife 源码调研 |
| `40-patchouli-api.md` | Patchouli JSON 与 Java API |
