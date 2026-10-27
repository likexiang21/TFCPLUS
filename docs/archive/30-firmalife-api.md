# Firmalife v3.0.14 技术文档（面向 MC 1.21.1 / NeoForge 21.1.x 附属模组开发）

> 本文档由源码静态分析产出，供后续编写 Firmalife 附属模组的 AI 代理直接查阅。
> 所有结论均标注来源文件（相对 Firmalife 仓库根目录）。凡标注「未能核实」之处，均已在文中说明检查过的位置。

---

## 0. 环境事实与文档口径

| 项目 | 值 | 来源 |
| --- | --- | --- |
| 源码根目录 | `D:\111\最强服务器\.minecraft\versions\Essential TerraFirmaCraft (TFC)\moddev\src-ref\Firmalife` | 环境提供 |
| 模组版本 | `3.0.14`（对应 `mods\Firmalife-NeoForge-1.21.1-3.0.14.jar`） | 环境提供 |
| modId | `firmalife` | `src/main/java/com/eerussianguy/firmalife/FirmaLife.java` |
| 主类 | `com.eerussianguy.firmalife.FirmaLife`（注意类名是大写 `L` 的 `FirmaLife`，而包名/模组名是 `firmalife`） | `FirmaLife.java` |
| Minecraft | `1.21.1` | `build.gradle.kts` L10 |
| NeoForge | `21.1.234`（构建脚本 pin 的版本） | `build.gradle.kts` L11 |
| Parchment 映射 | `2024.11.17`（MC `1.21.1`） | `build.gradle.kts` L12-13 |
| Java | `21` | `build.gradle.kts` L23 |
| 构建插件 | **NeoForge ModDevGradle**：`id("net.neoforged.moddev") version "2.0.107"`（不是 ForgeGradle） | `build.gradle.kts` L4-6 |
| 产物名 | `Firmalife-NeoForge-1.21.1`（`base.archivesName`），group `com.eerussianguy.firmalife` | `build.gradle.kts` L48-52 |
| 数据生成输出 | `src/generated/resources` | `build.gradle.kts` L25 |
| 编译期 TFC 依赖 | `curse.maven:terrafirmacraft-302973:8666972`（`build.gradle.kts` L19 注释标注为 4.2.8） | `build.gradle.kts` L156-157 |
| Patchouli 依赖 | `vazkii.patchouli:Patchouli:1.21.1-92-NEOFORGE`，且是 **implementation（全量 jar，非 api）** | `build.gradle.kts` L18、L150-153 |

**重要口径差异**：`build.gradle.kts` 里 pin 的 TFC 是 4.2.8、Patchouli 是 `1.21.1-92`，而运行实例里实际装的是 TFC `4.2.10` 与 Patchouli `1.21.1-93`。本文中凡引用 TFC 侧签名，均通过 `javap` 从实例内实际 jar（`mods\TerraFirmaCraft-NeoForge-1.21.1-4.2.10.jar`）导出，因此与运行环境一致。

### TFC 源码可用性

写作本文时 GitHub 不可达，`...\moddev\src-ref\TerraFirmaCraft` 目录不存在（已用 `Test-Path` 检查，返回 `False`）。因此 TFC 侧的结论一律通过以下两种方式交叉验证：

1. `moddev\inventory\TFC.classes.txt`（TFC jar 内 2051 个类的全清单）；
2. `javap` 反编译实例内 TFC jar 得到的**真实方法签名**。

> **补注（后续已补齐）**：GitHub 拉取失败后，已改用 CFR 0.152 反编译实例内 TFC jar，
> 产出**完整 TFC 源码**：`moddev\src-ref\TFC-decompiled\`（1672 个 `.java`，与 4.2.10 完全对应，
> 文件头部的 “Could not load the following classes” 只是 classpath 提示，可忽略）。
> 本文中凡标注「未能核实 TFC 方法体语义 / 未能核实可选字段默认值」之处，
> 现在都可以在该目录中直接查证；TFC 侧的完整整理见同目录的
> `10-tfc-overview.md`、`11-tfc-registry-catalog.md`、`12-tfc-data-driven.md`、`13-tfc-api.md`。

---

## 1. 项目骨架与注册入口

### 1.1 源码目录结构

```
src/
├── main/java/com/eerussianguy/firmalife/
│   ├── FirmaLife.java                 # @Mod 主类
│   ├── client/                        # 客户端：screen、render、model、helpers、events
│   ├── common/
│   │   ├── FLTags.java  FLCreativeTabs.java  FLHelpers.java
│   │   ├── FLEvents.java  FLForgeEvents.java
│   │   ├── blockentities/  blocks/  capabilities/  container/
│   │   ├── entities/  items/  misc/  recipes/  util/  worldgen/
│   ├── compat/  (jei, patchouli, tooltip)
│   ├── config/  FLConfig.java  FLServerConfig.java
│   └── mixin/   (BarrelRackMixin, BeeMixin, ServerConfigMixin)
├── main/resources/    # assets/firmalife, assets/tfc（覆盖 TFC 的 field_guide 等）, data/*
├── main/templates/META-INF/neoforge.mods.toml   # 模板，由 gradle expand 替换占位符
├── data/java/com/eerussianguy/firmalife/        # datagen（独立 sourceSet "data"）
└── generated/resources/                          # datagen 输出（也作为 main 的 resources srcDir）
```

来源：`build.gradle.kts` L83-91（`sourceSets` 把 `src/generated/resources` 与 `generateModMetadata` 的输出加入 main 的 resources）。

### 1.2 主类 `FirmaLife.java` 完整解剖

主类构造签名是 **`(ModContainer mod, IEventBus bus)`**，不是无参构造。NeoForge 允许 `@Mod` 类的构造器注入 `IEventBus`（mod event bus）与 `ModContainer`。

```java
@Mod(FirmaLife.MOD_ID)
public class FirmaLife
{
    public static final String MOD_ID = "firmalife";
    public static final Logger LOGGER = LogUtils.getLogger();

    public static final boolean JEI           = ModList.get().isLoaded("jei");
    public static final boolean EMI           = ModList.get().isLoaded("emi");
    public static final boolean JADE          = ModList.get().isLoaded("jade");
    public static final boolean THE_ONE_PROBE = ModList.get().isLoaded("theoneprobe");

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

    public void setup(FMLCommonSetupEvent event)
    {
        event.enqueueWork(() -> {
            FLInteractionManager.init();
            FLBlocks.registerFlowerPotFlowers();
        });
        FLPatchouliIntegration.registerMultiBlocks();
    }
}
```

来源：`src/main/java/com/eerussianguy/firmalife/FirmaLife.java` 全文（110 行）。

**必须注意的执行顺序陷阱**（Firmalife 自身的写法就是范例）：

1. **`DeferredRegister.register(bus)` 必须在类加载阶段完成**，因为它们依赖各注册类的静态初始化。
2. **`FLDataManagers.init()` 在 `FLFoodTraits.TRAITS.register(bus)` 之后**调用；`FLDataManagers.init()` 内部把 `DataManager` 塞进 TFC 的 `DataManagers.MANAGERS`（一个 `DeferredRegister`），因此它自身不需要再 `.register(bus)`——`MANAGERS` 已由 TFC 注册到 mod bus。
3. **`bus.addListener(FLComponents::register)`**：`FLComponents.register(RegisterCapabilitiesEvent)` 用 `RegisterCapabilitiesEvent`（NeoForge 的 **mod bus** 事件，不是 game bus）。
4. **`ModList.get().isLoaded(...)` 在静态字段里求值**：`JEI/EMI/JADE/THE_ONE_PROBE` 是 `public static final boolean`，在 `FirmaLife` 类初始化时求值。附属模组若在 `@Mod` 构造器之外的更早时机（如另一个 mod 的静态初始化）触发 `FirmaLife` 类加载，`ModList` 可能尚未就绪——**不要**在自己的静态字段里引用 `FirmaLife.JEI` 等。
5. **`FMLEnvironment.dist == Dist.CLIENT` 分支**：客户端注册类（`FLClientEvents`）只在客户端加载，避免服务端类加载 `net.minecraft.client.*`。
6. **`FMLCommonSetupEvent.enqueueWork(...)`**：源码注释明确写 `// Vanilla registries are not thread safe`，因此 `FLInteractionManager.init()`（内部操作 `InteractionManager`）与 `FLBlocks.registerFlowerPotFlowers()`（操作原版 `Blocks.FLOWER_POT` 的 `FlowerPotBlock.addPlant`）必须放在 `enqueueWork` 里。
7. **`FLPatchouliIntegration.registerMultiBlocks()` 不在 `enqueueWork` 内**，直接在 `setup` 中同步执行（调用 `PatchouliAPI.get()`）。

### 1.3 全部 `DeferredRegister` 清单

| 注册表类型 | 字段 | 目标 registry | 声明位置 |
| --- | --- | --- | --- |
| `Item` | `FLItems.ITEM` | `Registries.ITEM` | `common/items/FLItems.java` L38 |
| `Block` | `FLBlocks.BLOCK` | `Registries.BLOCK` | `common/blocks/FLBlocks.java` L120 |
| `Fluid` | `FLFluids.FLUID` | `Registries.FLUID` | `common/blocks/FLFluids.java` L31 |
| `FluidType` | `FLFluids.FLUID_TYPES` | `NeoForgeRegistries.FLUID_TYPES` | `common/blocks/FLFluids.java` L32 |
| `BlockEntityType<?>` | `FLBlockEntities.BLOCK_ENTITY` | `Registries.BLOCK_ENTITY_TYPE` | `common/blockentities/FLBlockEntities.java` L19 |
| `RecipeType<?>` | `FLRecipeTypes.RECIPE_TYPE` | `Registries.RECIPE_TYPE` | `common/recipes/FLRecipeTypes.java` L17 |
| `PotOutput.OutputType` | `FLRecipeTypes.POT_OUTPUT_TYPE` | `PotOutput.KEY`（TFC 自定义 registry） | `common/recipes/FLRecipeTypes.java` L18 |
| `RecipeSerializer<?>` | `FLRecipeSerializers.RECIPE_SERIALIZER` | `Registries.RECIPE_SERIALIZER` | `common/recipes/FLRecipeSerializers.java` L18 |
| `ItemStackModifierType<?>` | `FLItemStackModifiers.TYPES` | `ItemStackModifiers.KEY`（TFC 自定义 registry） | `common/recipes/data/FLItemStackModifiers.java` L23 |
| `MenuType<?>` | `FLMenuTypes.MENU` | `Registries.MENU` | `common/container/FLMenuTypes.java` L25 |
| `MobEffect` | `FLEffects.EFFECT` | `Registries.MOB_EFFECT` | `common/misc/FLEffects.java` |
| `EntityType<?>` | `FLEntities.ENTITY` | `Registries.ENTITY_TYPE` | `common/entities/FLEntities.java` L17 |
| `ParticleType<?>` | `FLParticles.PARTICLE_TYPE` | `Registries.PARTICLE_TYPE` | `common/misc/FLParticles.java` |
| `Feature<?>` | `FLFeatures.FEATURE` | `Registries.FEATURE` | `common/worldgen/FLFeatures.java` L19 |
| `SoundEvent` | `FLSounds.SOUND` | `Registries.SOUND_EVENT` | `common/misc/FLSounds.java` |
| `CreativeModeTab` | `FLCreativeTabs.CREATIVE_TAB` | `Registries.CREATIVE_MODE_TAB` | `common/FLCreativeTabs.java` L39 |
| `CriterionTrigger<?>` | `FLAdvancements.TRIGGER_TYPE` | `Registries.TRIGGER_TYPE` | `common/util/FLAdvancements.java` L13 |
| `ArmorMaterial` | `FLArmorMaterials.ARMOR_MATERIAL` | `Registries.ARMOR_MATERIAL` | `common/util/FLArmorMaterials.java` L23 |
| `DataComponentType<?>` | `FLComponents.COMPONENT` | `Registries.DATA_COMPONENT_TYPE` | `common/capabilities/FLComponents.java` L34 |
| `PoiType` | `FLPOIs.TYPES` | `Registries.POINT_OF_INTEREST_TYPE` | `common/misc/FLPOIs.java` |
| `MapCodec<? extends IGlobalLootModifier>` | `FLLoot.MODIFIER_SERIALIZER` | `NeoForgeRegistries.Keys.GLOBAL_LOOT_MODIFIER_SERIALIZERS` | `common/misc/FLLoot.java` L20 |
| `LootItemConditionType` | `FLLoot.CONDITION` | `Registries.LOOT_CONDITION_TYPE` | `common/misc/FLLoot.java` L21 |
| `FoodTrait` | `FLFoodTraits.TRAITS` | `FoodTraits.KEY`（TFC 自定义 registry） | `common/items/FLFoodTraits.java` L65 |

注意 `FLLoot` 是唯一不直接暴露给主类 `.register(bus)` 的模块——它用 `FLLoot.registerAll(bus)` 把两个 `DeferredRegister` 一起注册（`common/misc/FLLoot.java` L39-43）。

### 1.4 事件注册汇总

#### mod bus（`IEventBus bus`，即 `@Mod` 构造器注入的那个）

| 事件 | 监听方法 | 位置 |
| --- | --- | --- |
| `FMLCommonSetupEvent` | `FirmaLife::setup` | `FirmaLife.java` L83 |
| `RegisterCapabilitiesEvent` | `FLComponents::register` | `FirmaLife.java` L84 |
| `BuildCreativeModeTabContentsEvent` | `FLCreativeTabs::setAllTabContentAsNonDecaying` | `FirmaLife.java` L85 |
| `AddPackFindersEvent` | `FLEvents::onPackFinder` | `common/FLEvents.java` L27 |
| `EntityAttributeCreationEvent` | `FLEvents::onEntityAttributeCreation` | `common/FLEvents.java` L28 |
| `InterModEnqueueEvent` | lambda → `InterModComms.sendTo("theoneprobe", "getTheOneProbe", ...)` | `compat/tooltip/TheOneProbeIntegration.java` L25 |

客户端（仅 `Dist.CLIENT`，见 `client/FLClientEvents.java` L96-108）：

| 事件 | 监听方法 |
| --- | --- |
| `FMLClientSetupEvent` | `FLClientEvents::clientSetup` |
| `EntityRenderersEvent.RegisterRenderers` | `FLClientEvents::registerEntityRenderers` |
| `EntityRenderersEvent.RegisterLayerDefinitions` | `FLClientEvents::onLayers` |
| `RegisterMenuScreensEvent` | `FLClientEvents::onMenuRegister` |
| `RegisterColorHandlersEvent.Item` | `FLClientEvents::onItemColors` |
| `RegisterParticleProvidersEvent` | `FLClientEvents::registerParticleFactories` |
| `ModelEvent.RegisterAdditional` | `FLClientEvents::registerModels` |
| `ModelEvent.RegisterGeometryLoaders` | `FLClientEvents::registerLoaders` |
| `RegisterClientExtensionsEvent` | `FLClientEvents::registerExtensions` |
| `BuildCreativeModeTabContentsEvent` | `FLCreativeTabs::onBuildCreativeTab` |

来源：`src/main/java/com/eerussianguy/firmalife/client/FLClientEvents.java` L96-108。

#### game bus（`NeoForge.EVENT_BUS`，通过 `FLForgeEvents.init()` 注册）

```java
public static void init()
{
    final IEventBus bus = NeoForge.EVENT_BUS;
    bus.addListener(FLForgeEvents::onFireStart);
    bus.addListener(FLForgeEvents::onFireStop);
    bus.addListener(FLForgeEvents::onAnimalProduce);
    bus.addListener(FLForgeEvents::onLevelLoad);
}
```

来源：`src/main/java/com/eerussianguy/firmalife/common/FLForgeEvents.java` L40-48。

| 事件 | 用途 | 位置 |
| --- | --- | --- |
| `LevelEvent.Load` | 首次进入主世界时跑 `FLSelfTests.runServerSelfTests` | `FLForgeEvents.java` L50-56 |
| `StartFireEvent`（TFC） | 点燃 `OvenBottomBlock` / 把 `CarvedPumpkinBlock` 换成 `JackOLanternBlock`（`firmalife:lit_pumpkin/*`）/ 用蜡烛点亮 `JarbnetBlock` | `FLForgeEvents.java` L58-96 |
| `DouseFireEvent`（TFC） | 熄灭烤箱底部/顶部与灶台锅 | `FLForgeEvents.java` L98-122 |
| `AnimalProductEvent`（TFC） | `tfc:yak` 产出 `firmalife:yak_milk`、`tfc:goat` 产出 `firmalife:goat_milk`（各 1000 mB） | `FLForgeEvents.java` L124-135 |

**注意**：Firmalife 使用的是 TFC 的 `StartFireEvent` / `DouseFireEvent`，其包名是 `net.dries007.tfc.util.events.*`（不是 NeoForge 的 `BlockEvent`）。

---

## 2. 注册工具类与 Id 包装体系

### 2.1 结论：Firmalife **没有**自己的 `RegistrationHelpers`

全仓库搜索 `RegistrationHelpers` 只有 4 个文件命中，且**全部 import 的是 TFC 的** `net.dries007.tfc.util.registry.RegistrationHelpers`：

| 文件 | 用法 |
| --- | --- |
| `common/blocks/FLBlocks.java` L115、L359 | `RegistrationHelpers.registerBlock(BLOCK, FLItems.ITEM, name, blockSupplier, blockItemFactory)` |
| `common/blockentities/FLBlockEntities.java` L15、L73、L78 | `RegistrationHelpers.register(BLOCK_ENTITY, name, factory, block\|blocks)` |
| `common/blocks/FLFluids.java` L25、L107 | `RegistrationHelpers.registerFluid(...)` |
| `common/container/FLMenuTypes.java` L19、L34 | `RegistrationHelpers.registerBlockEntityContainer(MENU, name, type, factory)` |

来源：对 `src/**` 全量 `grep RegistrationHelpers`。

### 2.2 TFC `RegistrationHelpers` 的完整签名

以下签名由 `javap -cp TerraFirmaCraft-NeoForge-1.21.1-4.2.10.jar net.dries007.tfc.util.registry.RegistrationHelpers` 导出（`javap` 输出中省略了参数名，此处补上由调用点推出的参数语义）：

```java
public final class net.dries007.tfc.util.registry.RegistrationHelpers
{
    // 注册方块 + 可选 BlockItem；blockItemFactory == null 时只注册方块
    public static <T extends Block> DeferredHolder<Block, T> registerBlock(
        DeferredRegister<Block> blockRegistry,
        DeferredRegister<Item> itemRegistry,
        String name,
        Supplier<T> blockSupplier,
        Function<T, ? extends BlockItem> blockItemFactory);

    // 注册 FluidType + Fluid(源/流动)
    public static <F extends FlowingFluid> FluidHolder<F> registerFluid(
        DeferredRegister<FluidType> fluidTypes,
        DeferredRegister<Fluid> fluids,
        String typeName, String sourceName, String flowingName,
        Consumer<BaseFlowingFluid.Properties> builder,
        Supplier<FluidType> fluidType,
        Function<BaseFlowingFluid.Properties, F> sourceFactory,
        Function<BaseFlowingFluid.Properties, F> flowingFactory);

    // BlockEntityType，单方块
    public static <T extends BlockEntity> DeferredHolder<BlockEntityType<?>, BlockEntityType<T>> register(
        DeferredRegister<BlockEntityType<?>> registry, String name,
        BlockEntityType.BlockEntitySupplier<T> factory,
        Supplier<? extends Block> block);

    // BlockEntityType，多方块
    public static <T extends BlockEntity> DeferredHolder<BlockEntityType<?>, BlockEntityType<T>> register(
        DeferredRegister<BlockEntityType<?>> registry, String name,
        BlockEntityType.BlockEntitySupplier<T> factory,
        Stream<? extends Supplier<? extends Block>> blocks);

    // MenuType，绑定 BlockEntityContainer
    public static <T extends InventoryBlockEntity<?>, C extends BlockEntityContainer<T>>
    DeferredHolder<MenuType<?>, MenuType<C>> registerBlockEntityContainer(
        DeferredRegister<MenuType<?>> registry, String name,
        Supplier<BlockEntityType<T>> type,
        BlockEntityContainer.Factory<T, C> factory);

    // MenuType，绑定 ItemStackContainer
    public static <C extends ItemStackContainer> DeferredHolder<MenuType<?>, MenuType<C>> registerItemStackContainer(
        DeferredRegister<MenuType<?>> registry, String name,
        ItemStackContainer.Factory<C> factory);

    // 通用 MenuType
    public static <C extends AbstractContainerMenu> DeferredHolder<MenuType<?>, MenuType<C>> registerContainer(
        DeferredRegister<MenuType<?>> registry, String name, IContainerFactory<C> factory);
}
```

### 2.3 `RegistryHolder` / `IdHolder` / `HolderHolder`

由 `javap` 导出（TFC jar）：

```java
public interface net.dries007.tfc.util.registry.IdHolder<T> extends Supplier<T>
{
    DeferredHolder<? super T, T> holder();
    default ResourceLocation getId();   // = holder().getId()
}

public interface net.dries007.tfc.util.registry.HolderHolder<R>
{
    DeferredHolder<R, ? extends R> holder();
    default ResourceKey<R> key();
}

public interface net.dries007.tfc.util.registry.RegistryHolder<R, T extends R>
    extends IdHolder<T>, HolderHolder<R>
{
    @Override DeferredHolder<R, T> holder();
    default T get();                    // = holder().get()
}
```

**用法约定**：TFC 与 Firmalife 的每个内容模块都定义一个实现 `RegistryHolder` 的 `record Id<...>(DeferredHolder<...> holder)`，从而同时获得 `get()`、`getId()`、`key()`、`holder()`。这是全仓库统一模式。

### 2.4 Firmalife 复用的 Id 包装 record 对照表

**关键事实：Firmalife 完全复用 TFC 的 Id record，没有定义自己的一套**（唯一例外见表格末两行）。

| Firmalife 模块 | 使用的 Id 类型（TFC 提供） | Id 泛型形态 |
| --- | --- | --- |
| `FLItems` | `net.dries007.tfc.common.items.TFCItems.ItemId` | `record ItemId(DeferredHolder<Item, Item>) implements RegistryHolder<Item, Item>, ItemLike` |
| `FLBlocks` | `net.dries007.tfc.common.blocks.TFCBlocks.Id<T>` | `record Id<T extends Block>(DeferredHolder<Block, T>) implements RegistryHolder<Block, T>, ItemLike` |
| `FLBlockEntities` | `net.dries007.tfc.common.blockentities.TFCBlockEntities.Id<T>` | `record Id<T extends BlockEntity>(DeferredHolder<BlockEntityType<?>, BlockEntityType<T>>)` |
| `FLFluids` | `net.dries007.tfc.common.fluids.FluidHolder<F>` | TFC 的流体包装（含 source/flowing 两个 holder） |
| `FLMenuTypes` | `net.dries007.tfc.common.container.TFCContainerTypes.Id<C>` | `record Id<C extends AbstractContainerMenu>(DeferredHolder<MenuType<?>, MenuType<C>>)` |
| `FLRecipeTypes` | `net.dries007.tfc.common.recipes.TFCRecipeTypes.Id<T>` | `record Id<T extends Recipe<?>>(DeferredHolder<RecipeType<?>, RecipeType<T>>)` |
| `FLRecipeSerializers` | `net.dries007.tfc.common.recipes.TFCRecipeSerializers.Id<T>` | `record Id<T extends Recipe<?>>(DeferredHolder<RecipeSerializer<?>, RecipeSerializer<T>>)` |
| `FLEntities` | `net.dries007.tfc.common.entities.TFCEntities.Id<E>` | `record Id<E extends Entity>(DeferredHolder<EntityType<?>, EntityType<E>>)` |
| `FLFeatures` | `net.dries007.tfc.world.feature.TFCFeatures.Id<F>` | `record Id<F extends Feature<?>>(DeferredHolder<Feature<?>, F>)` |
| `FLComponents` | `net.dries007.tfc.common.component.TFCComponents.Id<T>` | `record Id<T>(DeferredHolder<DataComponentType<?>, DataComponentType<T>>)` |
| `FLAdvancements` | `net.dries007.tfc.util.advancements.TFCAdvancements.Id` | `record Id(DeferredHolder<CriterionTrigger<?>, GenericTrigger>)`，另有 `void trigger(ServerPlayer)` |
| `FLArmorMaterials` | `net.dries007.tfc.common.TFCArmorMaterials.Id` | `record Id(Holder<ArmorMaterial>, int feetDamage, int legDamage, int chestDamage, int headDamage)` |
| `FLCreativeTabs` | `net.dries007.tfc.common.TFCCreativeTabs.Id` | `record Id(DeferredHolder<CreativeModeTab, CreativeModeTab> tab, CreativeModeTab.DisplayItemsGenerator generator)`；用 `tab().get()` 取标签页 |
| `FLLoot`（条件部分） | `net.dries007.tfc.util.loot.TFCLoot.Id<T>` | `record Id<T>(DeferredHolder<T, T>) implements RegistryHolder<T, T>` |
| `FLLoot`（GLM 部分） | **自定义**：`FLLoot.GLMId<T>` | `record GLMId<T extends IGlobalLootModifier>(DeferredHolder<MapCodec<? extends IGlobalLootModifier>, MapCodec<T>> holder) implements RegistryHolder<...>`（`common/misc/FLLoot.java` L36-37） |
| `FLItemStackModifiers` | **自定义**：`FLItemStackModifiers.Id<T>` | `record Id<T extends ItemStackModifier>(DeferredHolder<ItemStackModifierType<?>, ItemStackModifierType<T>> holder) implements RegistryHolder<...>`（`common/recipes/data/FLItemStackModifiers.java` L36-37，注释写明「Copied from TFC」） |

### 2.5 Firmalife 自己的注册辅助方法

`FLBlocks` 内部提供 4 个私有重载，供仓库内部使用（**全部是 `private static`，外部不可复用**）：

```java
private static <T extends Block> Id<T> registerNoItem(String name, Supplier<T> blockSupplier);
private static <T extends Block> Id<T> register(String name, Supplier<T> blockSupplier);
private static <T extends Block> Id<T> register(String name, Supplier<T> blockSupplier, Item.Properties blockItemProperties);
private static <T extends Block> Id<T> register(String name, Supplier<T> blockSupplier,
                                               @Nullable Function<T, ? extends BlockItem> blockItemFactory);
private static <T1 extends SlabBlock, T2 extends StairBlock, T3 extends WallBlock>
        DecorationBlockHolder registerDecorations(String baseName, Supplier<T1> slab, Supplier<T2> stair,
                                                  Supplier<T3> wall, Item.Properties properties);
```

来源：`src/main/java/com/eerussianguy/firmalife/common/blocks/FLBlocks.java` L332-360。

`FLItems` 同样只有私有重载：

```java
private static ItemId register(String name);                                   // 普通 new Item(new Item.Properties())
private static ItemId register(String name, Item.Properties properties);
private static ItemId register(String name, Supplier<Item> item);
```

来源：`src/main/java/com/eerussianguy/firmalife/common/items/FLItems.java` L142-155。注意物品名会被 `name.toLowerCase(Locale.ROOT)`。

---

## 3. TFC 集成点（逐条证据）

### 3.1 复用 TFC 的数据驱动枚举

Firmalife 大量以「枚举键 → 注册表 Map」的方式复用 TFC 的枚举，使用 `net.dries007.tfc.util.Helpers.mapOf(EnumClass.class, fn)`：

| TFC 枚举 | Firmalife 用法 | 来源 |
| --- | --- | --- |
| `net.dries007.tfc.common.blocks.wood.Wood` | `FLBlocks.FOOD_SHELVES / HANGERS / JARBNETS / KEG_SUBS / KEGS / WINE_SHELVES / STOMPING_BARRELS / BARREL_PRESSES`，注册名形如 `wood/keg/<wood>` | `common/blocks/FLBlocks.java` L220-227 |
| `net.dries007.tfc.common.blocks.rock.Rock` + `net.dries007.tfc.common.blocks.rock.Ore.Grade` | `FLBlocks.CHROMITE_ORES`：`Map<Rock, Map<Ore.Grade, Id<Block>>>`，注册名 `ore/<grade>_chromite/<rock>` | `FLBlocks.java` L249-253 |
| `net.dries007.tfc.util.Metal.BlockType` | `FLBlocks.METALS`：`Map<FLMetal, Map<Metal.BlockType, Id<Block>>>`，通过 `type.has(Metal.BISMUTH)` 过滤掉 TFC 不支持的方块类型 | `FLBlocks.java` L261-265 |
| `net.dries007.tfc.common.items.TFCItems` | 直接引用 `TFCItems.WOOL_YARN`、`TFCItems.EMPTY_JAR`、`TFCItems.WROUGHT_IRON_GRILL`、`TFCItems.POT`、`TFCItems.WOOL` | `FLBlocks.java` L163、`FLItems.java` L49/L97-102、`FLInteractionManager.java` L25/L49/L68 |
| `net.dries007.tfc.common.TFCCreativeTabs` | 把 Firmalife 内容塞进 TFC 的创造标签页：`TFC_FOODS_DRINKS`、`TFC_METALS_INGREDIENTS`、`TFC_FLORA_CROPS`、`TFC_FUNCTIONAL_BLOCKS`、`TFC_NATURAL_BLOCKS` | `common/FLCreativeTabs.java` L197-273 |
| `net.dries007.tfc.common.TFCTiers` | `FLMetal.toolTier()` 返回 `TFCTiers.STEEL` | `common/util/FLMetal.java` L59-62 |
| `net.dries007.tfc.common.blocks.TFCBlockStateProperties` | `FLPlant` 用 `TFCBlockStateProperties.getAgeProperty(maxStage)` | `common/util/FLPlant.java` L38 |
| `net.dries007.tfc.common.blocks.TFCBlocks` | `FLPatchouliIntegration` 里用 `TFCBlocks.SOIL`；`FLTooltips` 里用作参考 | `compat/patchouli/FLPatchouliIntegration.java` L21、L68 |
| `net.dries007.tfc.common.entities.TFCEntities` | `TFCEntities.YAK`、`TFCEntities.GOAT` 的挤奶产物替换 | `common/FLForgeEvents.java` L127-134 |

### 3.2 数据管理器（`DataManager` / `DataManagers`）扩展

Firmalife 的 `FLDataManagers.init()` 把两个自定义 `DataManager` 注册到 TFC 的共享注册表：

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

来源：`src/main/java/com/eerussianguy/firmalife/common/util/FLDataManagers.java`（全 18 行）。

TFC 侧签名（`javap`）：

```java
public class net.dries007.tfc.util.data.DataManager<T> extends SimpleJsonResourceReloadListener
{
    public DataManager(ResourceLocation name, Codec<T> codec);
    public DataManager(ResourceLocation name, Codec<T> codec,
                       StreamCodec<RegistryFriendlyByteBuf, T> streamCodec);
    public DataManager.Reference<T> getReference(ResourceLocation id);
    public DataManager.Reference<T> getCheckedReference(ResourceLocation id);
    public final Codec<DataManager.Reference<T>> byIdReferenceCodec();
    public final StreamCodec<ByteBuf, DataManager.Reference<T>> byIdStreamCodec();
}

public final class net.dries007.tfc.util.data.DataManagers
{
    public static final ResourceKey<Registry<DataManager<?>>> KEY;
    public static final Registry<DataManager<?>> REGISTRY;
    public static final DeferredRegister<DataManager<?>> MANAGERS;
}
```

因此，**自定义 DataManager 的注册路径 = `new DataManager<>(FLHelpers.identifier("xxx"), CODEC, STREAM_CODEC)`，然后 `DataManagers.MANAGERS.register(name, () -> manager)`**。数据文件目录由 `DataManager` 的构造参数（`ResourceLocation`）决定：`data/<namespace>/<path>/*.json`。

Firmalife 还大量使用 `DataManager.Reference<T>` 做「数据驱动引用」：

```java
public static final Map<FLFruitBlocks.Tree, DataManager.Reference<ClimateRange>> FRUIT_TREES =
    Helpers.mapOf(FLFruitBlocks.Tree.class, tree -> register("plant/" + tree.name() + "_tree"));

private static DataManager.Reference<ClimateRange> register(String name)
{
    return ClimateRange.MANAGER.getReference(FLHelpers.identifier(name.toLowerCase(Locale.ROOT)));
}
```

来源：`src/main/java/com/eerussianguy/firmalife/common/util/FLClimateRanges.java`（全 23 行）。它引用的是 **TFC 自己的 `ClimateRange.MANAGER`**，即 Firmalife 只是往 `data/firmalife/tfc/climate_range/plant/*.json` 里补 TFC 格式的数据。

`DataManager` 之上的性能优化约定：`IndirectHashCollection`（TFC）用作「从某个键反查数据对象」的缓存：

```java
public static final IndirectHashCollection<Block, GreenhouseType> CACHE =
    IndirectHashCollection.create(s -> s.ingredient.blocks(), MANAGER::getValues);
```

来源：`common/util/GreenhouseType.java` L37；`IndirectHashCollection` 的 `create(Function<R, Iterable<K>>, Supplier<Collection<R>>)` 签名由 `javap` 从 TFC jar 确认。

### 3.3 配方体系集成

#### （a）Firmalife 自己注册的 recipe type / serializer

```java
// common/recipes/FLRecipeTypes.java
public static final DeferredRegister<RecipeType<?>> RECIPE_TYPE = DeferredRegister.create(Registries.RECIPE_TYPE, MOD_ID);
public static final DeferredRegister<PotOutput.OutputType> POT_OUTPUT_TYPE = DeferredRegister.create(PotOutput.KEY, MOD_ID);

public static final Id<DryingRecipe>     DRYING      = register("drying");
public static final Id<SmokingRecipe>    SMOKING     = register("smoking");
public static final Id<MixingBowlRecipe> MIXING_BOWL = register("mixing_bowl");
public static final Id<OvenRecipe>       OVEN        = register("oven");
public static final Id<VatRecipe>        VAT         = register("vat");
public static final Id<StompingRecipe>   STOMPING    = register("stomping");
public static final Id<PressRecipe>      PRESS       = register("press");
public static final Id<CentrifugeRecipe> CENTRIFUGE  = register("centrifuge");

public static final DeferredHolder<PotOutput.OutputType, PotOutput.OutputType> STINKY_SOUP =
    POT_OUTPUT_TYPE.register("stinky_soup", () -> StinkySoupRecipe.OUTPUT_TYPE);
public static final DeferredHolder<PotOutput.OutputType, PotOutput.OutputType> BOWL =
    POT_OUTPUT_TYPE.register("bowl", () -> BowlPotRecipe.OUTPUT_TYPE);
```

来源：`src/main/java/com/eerussianguy/firmalife/common/recipes/FLRecipeTypes.java` L15-43。

```java
// common/recipes/FLRecipeSerializers.java
public static final Id<DryingRecipe>      DRYING       = register("drying", DryingRecipe.CODEC, DryingRecipe.STREAM_CODEC);
public static final Id<SmokingRecipe>     SMOKING      = register("smoking", SmokingRecipe.CODEC, SmokingRecipe.STREAM_CODEC);
public static final Id<StompingRecipe>    STOMPING     = register("stomping", StompingRecipe.CODEC, StompingRecipe.STREAM_CODEC);
public static final Id<MixingBowlRecipe>  MIXING_BOWL  = register("mixing_bowl", MixingBowlRecipe.CODEC, MixingBowlRecipe.STREAM_CODEC);
public static final Id<OvenRecipe>        OVEN         = register("oven", OvenRecipe.CODEC, OvenRecipe.STREAM_CODEC);
public static final Id<StinkySoupRecipe>  STINKY_SOUP  = register("stinky_soup", StinkySoupRecipe.CODEC, StinkySoupRecipe.STREAM_CODEC);
public static final Id<BowlPotRecipe>     BOWL_POT     = register("bowl_pot", BowlPotRecipe.CODEC, BowlPotRecipe.STREAM_CODEC);
public static final Id<VatRecipe>         VAT          = register("vat", VatRecipe.CODEC, VatRecipe.STREAM_CODEC);
public static final Id<PressRecipe>       PRESS        = register("press", PressRecipe.P_CODEC, PressRecipe.P_STREAM_CODEC);
public static final Id<CentrifugeRecipe>  CENTRIFUGE   = register("centrifuge", CentrifugeRecipe.CODEC, CentrifugeRecipe.STREAM_CODEC);
```

来源：`src/main/java/com/eerussianguy/firmalife/common/recipes/FLRecipeSerializers.java` L20-39。

**注意**：注册配方类型必须在**两处**同时进行（`Registries.RECIPE_TYPE` 与 `Registries.RECIPE_SERIALIZER`），Firmalife 用 TFC 的 `RecipeSerializerImpl<>`（`javap` 确认为 `record`，构造 `(MapCodec<R>, StreamCodec<RegistryFriendlyByteBuf, R>)` 或 `(R singleInstance)`）来简化：

```java
private static <R extends Recipe<?>> Id<R> register(String name, MapCodec<R> codec,
                                                    StreamCodec<RegistryFriendlyByteBuf, R> stream)
{
    return register(name, new RecipeSerializerImpl<>(codec, stream));
}
```

来源：`FLRecipeSerializers.java` L31-39。

#### （b）Firmalife **复用** TFC 的配方类型（而不是新建）

| 机制 | 实际使用的配方类型 | 证据 |
| --- | --- | --- |
| 酒桶 `Keg`（大型多方块酒桶） | **TFC 的** `tfc:barrel_instant`、`tfc:barrel_instant_fluid`、`tfc:barrel_sealed`；`KegRecipe` 只是一个静态工具类（**不是**注册的 RecipeType） | `common/recipes/KegRecipe.java` L27-…；L29-52 直接调用 `level.getRecipeManager().getAllRecipesFor(TFCRecipeTypes.BARREL_INSTANT.get())` 等 |
| 烤箱加热 / 灶台 | **TFC 的** `HeatingRecipe` + Firmalife 的 `OvenRecipe` 被 `WrappedHeatingRecipe` 统一包装 | `common/recipes/WrappedHeatingRecipe.java` L13-32：`getRecipe` 先试 `OvenRecipe.getRecipe`，失败再试 `HeatingRecipe.getRecipe` |
| 锅（`tfc:pot`）产出米饭/汤等 | `StinkySoupRecipe extends PotRecipe`、`BowlPotRecipe extends PotRecipe`，用 `tfc:pot` 配方类型，注册的是 **serializer** 与 **`PotOutput.OutputType`** | `common/recipes/StinkySoupRecipe.java` L34-44、`common/recipes/BowlPotRecipe.java` L28-50、`FLRecipeTypes.java` L29-30 |
| 果汁/酒的配方目录 `data/firmalife/recipe/pot/*` | 生成的是 `"type": "tfc:pot"` 的 JSON | `src/generated/resources/data/firmalife/recipe/pot/chocolate.json` |
| `press` 配方 | 注册了 `firmalife:press` 类型与 JEI 类目，但**没有任何 datagen provider 生成 press 配方**（`src/data/.../recipes/` 下没有 `PressRecipes.java`，`src/generated/.../recipe/` 下也没有 `press/` 目录） | `src/data/java/com/eerussianguy/firmalife/providers/BuiltinRecipes.java` L106-142（`buildRecipes` 里调用了 21 个 `*Recipes()` 方法，其中没有 `pressRecipes()`）；`common/blocks/FLBlocks.java` L227 与 `compat/jei/FLJEIPlugin.java` L87 证明该类型仍被使用 |

#### （c）`IRecipePredicate` 与「无输入库存」配方

`OvenRecipe` 是 Firmalife 中唯一直接实现 TFC 两个配方接口的类：

```java
public class OvenRecipe implements INoopInputRecipe, IRecipePredicate<ItemStack>
{
    @Override public boolean matches(ItemStack itemStack) { return getIngredient().test(itemStack); }
    ...
}
```

来源：`common/recipes/OvenRecipe.java` L28、L121-125。TFC 侧定义（`javap`）：

```java
public interface IRecipePredicate<C> { /* 泛型谓词 */ }
public interface ISimpleRecipe<C extends RecipeInput> extends Recipe<C> { }
public interface INoopInputRecipe extends ISimpleRecipe<NoopInput> {
    static <R extends IRecipePredicate<C>, C, K> R getRecipe(IndirectHashCollection<K, R> cache, C input, K key);
    static <R extends IRecipePredicate<C>, C> R getRecipe(Collection<R> recipes, C input);
    static <R extends Recipe<?> & IRecipePredicate<C>, C> RecipeHolder<R> getHolder(Level, Supplier<RecipeType<R>>, C);
    static <R extends Recipe<?> & IRecipePredicate<C>, C> RecipeHolder<R> getHolder(RecipeManager, Supplier<RecipeType<R>>, C);
}
public abstract class ItemRecipe implements INoopInputRecipe, IRecipePredicate<ItemStack> { protected final Ingredient ingredient; ... }
public abstract class BlockRecipe implements INoopInputRecipe, IRecipePredicate<BlockState> { ... }
```

`IndirectHashCollection.createForRecipe(Function<R, Iterable<K>>, Supplier<RecipeType<R>>)` + `RecipeHelpers.getRecipe(cache, input, key)` 是 TFC/Firmalife 的「按物品快速查配方」标准范式（见 3.4）。

### 3.4 配方缓存范式（每个「按物品查配方」机制都这么做）

```java
public class DryingRecipe extends ItemRecipe
{
    public static final IndirectHashCollection<Item, DryingRecipe> CACHE =
        IndirectHashCollection.createForRecipe(DryingRecipe::getValidItems, FLRecipeTypes.DRYING);

    @Nullable
    public static DryingRecipe getRecipe(ItemStack input)
    {
        return RecipeHelpers.getRecipe(CACHE, input, input.getItem());
    }
}
```

来源：`common/recipes/DryingRecipe.java` L33、L40-44。同型代码见 `CentrifugeRecipe.java` L33、`OvenRecipe.java` L45、`StompingRecipe.java` L44、`PressRecipe.java` L42。

TFC 侧相关签名（`javap`）：

```java
public class IndirectHashCollection<K, R>
{
    public static <K, R> IndirectHashCollection<K, R> create(Function<R, Iterable<? extends K>>, Supplier<Collection<R>>);
    public static <K, R extends Recipe<?>> IndirectHashCollection<K, R> createForRecipe(Function<R, Iterable<? extends K>>, Supplier<RecipeType<R>>);
    public static <R extends Recipe<?>> BiMap<ResourceLocation, R> createForRecipeId(Supplier<RecipeType<R>>);
    public Collection<R> getAll(K key);
    public void reload(Collection<R>);
    public void clear();
}

public final class RecipeHelpers
{
    public static Collection<Item> itemKeys(Ingredient);
    public static Stream<Item> stream(Ingredient);
    public static <R extends IRecipePredicate<C>, C, K> R getRecipe(IndirectHashCollection<K, R> cache, C input, K key);
    public static <R, C> R getRecipe(Collection<R> recipes, C input, BiPredicate<R, C> predicate);
    public static <R extends Recipe<?>> Collection<RecipeHolder<R>> getRecipes(Level, Supplier<RecipeType<R>>);
    public static Player getCraftingPlayer();
    public static void setCraftingInput(IItemHandler, int, int);
    ...
}
```

### 3.5 `ItemStackProvider` 与 `ItemStackModifier`（TFC 输出系统）

Firmalife 的所有「按物品」配方都用 TFC 的 `ItemStackProvider` 作为输出（支持 `copy_input`、`add_trait` 等修饰符链）：

```json
"result": {
  "modifiers": [
    { "type": "tfc:copy_input" },
    { "type": "tfc:add_trait", "trait": "firmalife:dried" }
  ]
}
```

来源：`src/generated/resources/data/firmalife/recipe/drying/dry_fruits.json`。

Firmalife 自己新增了 4 个 `ItemStackModifier`：

```java
public static final DeferredRegister<ItemStackModifierType<?>> TYPES =
    DeferredRegister.create(ItemStackModifiers.KEY, FirmaLife.MOD_ID);

public static final Id<AddPiePanModifier>       ADD_PIE_PAN        = register("add_pie_pan", AddPiePanModifier.INSTANCE);
public static final Id<CopyDynamicFoodModifier> COPY_DYNAMIC_FOOD  = register("copy_dynamic_food", CopyDynamicFoodModifier.INSTANCE);
public static final Id<CopyBowlModifier>        COPY_BOWL          = register("copy_bowl", CopyBowlModifier.INSTANCE);
public static final Id<EmptyPanModifier>        EMPTY_PAN          = register("empty_pan", EmptyPanModifier.INSTANCE);

private static <T extends ItemStackModifier> Id<T> register(String name, T singleInstance)
{
    return new Id<>(TYPES.register(name, () -> new ItemStackModifierType<>(
        MapCodec.unit(singleInstance), StreamCodec.unit(singleInstance))));
}
```

来源：`src/main/java/com/eerussianguy/firmalife/common/recipes/data/FLItemStackModifiers.java` L23-37。

实现一个 modifier 只需 `enum X implements ItemStackModifier { INSTANCE; apply(ItemStack, ItemStack input, Context) ; type() }`：

```java
public enum CopyDynamicFoodModifier implements ItemStackModifier
{
    INSTANCE;

    @Override
    public ItemStack apply(ItemStack stack, ItemStack input, Context context)
    {
        IFood inputFood = FoodCapability.get(input);
        ItemComponent inputBowl = input.get(TFCComponents.BOWL);
        if (inputFood != null)
        {
            FoodCapability.setFoodForDynamicItemOnCreate(stack, inputFood.getData());
            FoodCapability.setCreationDate(stack, inputFood.getCreationDate());
        }
        ...
        return stack;
    }

    @Override
    public ItemStackModifierType<?> type() { return FLItemStackModifiers.COPY_DYNAMIC_FOOD.get(); }
}
```

来源：`common/recipes/data/CopyDynamicFoodModifier.java` L15-48。

`ItemStackProvider` 的 public API（`javap`）：

```java
public final class ItemStackProvider extends Record
{
    public static final Codec<ItemStackProvider> CODEC;
    public static final StreamCodec<RegistryFriendlyByteBuf, ItemStackProvider> STREAM_CODEC;
    public static ItemStackProvider empty();
    public static ItemStackProvider copyInput();
    public static ItemStackProvider of(ItemLike);
    public static ItemStackProvider of(ItemStack, ItemStackModifier...);
    public static ItemStackProvider of(ItemStack, List<ItemStackModifier>);
    public ItemStack getSingleStack(ItemStack input);
    public ItemStack getStack(ItemStack input);
    public ItemStack getStack(ItemStack input, ItemStackModifier.Context ctx);
    public ItemStack getEmptyStack();
    public boolean dependsOnInput();
    public ItemStack stack();
    public List<ItemStackModifier> modifiers();
}
```

### 3.6 组件（DataComponent）与食物系统

```java
public final class FLComponents
{
    public static final DeferredRegister<DataComponentType<?>> COMPONENT =
        DeferredRegister.create(Registries.DATA_COMPONENT_TYPE, FirmaLife.MOD_ID);

    public static final Id<BeeComponent>  BEE  = register("bee", BeeComponent.CODEC, BeeComponent.STREAM_CODEC);
    public static final Id<WineComponent> WINE = register("wine", WineComponent.CODEC, WineComponent.STREAM_CODEC);

    private static <T> Id<T> register(String name, Codec<T> codec, StreamCodec<? super RegistryFriendlyByteBuf, T> streamCodec)
    {
        return new Id<>(COMPONENT.register(name, () -> new DataComponentType.Builder<T>()
            .persistent(codec).networkSynchronized(streamCodec).build()));
    }
}
```

来源：`common/capabilities/FLComponents.java` L34-106。

同一文件中的 `register(RegisterCapabilitiesEvent)` 是**附属模组必须照抄的模板**：它把 `BlockCapabilities.ITEM`（`IItemHandler`）挂到所有 `InventoryBlockEntity`、把 `BlockCapabilities.FLUID` / `BlockCapabilities.HEAT` 挂到特定 BE：

```java
private static void registerInventory(RegisterCapabilitiesEvent event,
        Supplier<? extends BlockEntityType<? extends InventoryBlockEntity<?>>> type)
{
    event.registerBlockEntity(BlockCapabilities.ITEM, type.get(), InventoryBlockEntity::getSidedInventory);
}
```

并注册物品流体能力：

```java
event.registerItem(ItemCapabilities.FLUID, FLComponents::forWine,
    FLItems.HEMATITIC_WINE_BOTTLE, FLItems.OLIVINE_WINE_BOTTLE, FLItems.VOLCANIC_WINE_BOTTLE);
event.registerItem(ItemCapabilities.FLUID, ItemCapabilities::forBucket, FLItems.HOLLOW_SHELL, FLItems.WINE_GLASS);
```

来源：`common/capabilities/FLComponents.java` L39-98。

食物特性（TFC `FoodTrait`）用 **Firmalife 自己的 namespace**：

```java
// Need to use our own DR to have the correct namespace on traits
public static final DeferredRegister<FoodTrait> TRAITS = DeferredRegister.create(FoodTraits.KEY, MOD_ID);

private static DeferredHolder<FoodTrait, FoodTrait> register(FLFoodTraits.Default trait)
{
    return TRAITS.register(trait.name.toLowerCase(Locale.ROOT),
        () -> new FoodTrait(FLConfig.SERVER.foodTraits.get(trait), MOD_ID + ".tooltip.food_trait." + trait.name.toLowerCase(Locale.ROOT)));
}
```

来源：`common/items/FLFoodTraits.java` L64-89。18 个 trait：`dried, fresh, aged, vintage, oven_baked, smoked, rancid_smoked, shelved, shelved_2, shelved_3, hung, hung_2, hung_3, fermented, bee_pollinated, dirt_grown, gravel_grown, slope_grown`（同一文件 L17-37）。

**关键陷阱**：`FoodTrait` 的 modifier 通过 `Supplier<Float>` 从配置读取（`FLConfig.SERVER.foodTraits`），所以 `FLConfig.SERVER` 必须在 `FLFoodTraits.TRAITS.register(bus)` **之前**构造完成。Firmalife 在构造器里先 `mod.registerConfig(...)`，之后才 `FLFoodTraits.TRAITS.register(bus)`（`FirmaLife.java` L78-80）。

### 3.7 配置系统

Firmalife 复用 TFC 的 `BaseConfig` / `ConfigBuilder`（而不是 NeoForge 的 `ModConfigSpec.Builder` 原样使用）：

```java
public class FLConfig
{
    public static final FLServerConfig SERVER = register(FLServerConfig::new, ConfigBuilder.ServerValue::new, "server");

    private static <C extends BaseConfig> C register(Function<ConfigBuilder, C> factory, ConfigBuilder.Factory value, String prefix)
    {
        final Pair<C, ModConfigSpec> pair = new ModConfigSpec.Builder()
            .configure(builder -> factory.apply(new ConfigBuilder(builder, value, prefix)));
        pair.getKey().updateSpec(pair.getValue());
        return pair.getKey();
    }
}
```

来源：`src/main/java/com/eerussianguy/firmalife/config/FLConfig.java`（全 21 行）。

`FLServerConfig extends BaseConfig` 只有 server 端配置，字段全部是 `Supplier<T>`，在配置重新加载时会自动更新。完整字段清单（含默认值）见 `common/../config/FLServerConfig.java` L14-83，例如：

| 字段 | 默认值 | 说明 |
| --- | --- | --- |
| `cheeseAgedDays` | 28 | 地窖中变 Aged 的天数 |
| `cheeseVintageDays` | 112 | 变 Vintage 的天数 |
| `dryingTicks` | 12000 | 晾晒垫时长 |
| `solarDryingTicks` | 1000 | 太阳能干燥器时长 |
| `smokingTicks` | 8000 | 烟熏时长 |
| `smokingFirepitRange` | 6 | 毛线向下找火坑的范围 |
| `compostTumblerTicks` | 96000 | 堆肥桶时长 |
| `ovenCureTicks` | 2000 | 烤箱烧制（cure）时长 |
| `ovenCureTemperature` | 600 | 达到该温度才开始 cure |
| `ovenRequirePeel` | true | 无披萨铲接触烤箱会受伤 |
| `ovenAshChance` | 0.5 | 燃料烧完掉灰的概率 |
| `enableSeedBalls` | true | 允许扔种子球 |
| `enableBeeAttack` | true | 蜜蜂可攻击玩家 |
| `beeUseHoneyDays` | 12 | 不能产蜜的蜜蜂消耗 1 份蜂蜜的周期 |
| `hollowShellCapacity` | 100 (mB) | 空心贝壳容量 |
| `wineGlassCapacity` | 250 (mB) | 酒杯容量（注意源码里 `define` 的 key 误写成 `"hollowShellCapacity"`，`FLServerConfig.java` L62） |
| `cellarLevel2Temperature` | 0.0 | 二级地窖温度阈值 |
| `cellarLevel3Temperature` | -12.0 | 三级地窖温度阈值 |
| `greenhouseGrowthModifier` | 1.0 | 温室生长时间倍率 |
| `greenhouseWaterDays` | 14.0 | 温室作物耗水天数 |
| `greenhouseNutrientDays` | 8.0 | 温室养分耗尽天数（TFC 普通作物为 12） |
| `greenhouseRadius` | 15 | 温室墙距气候站的半径上限 |
| `cellarRadius` | 15 | 地窖墙距气候站的半径上限 |
| `mechanicalPowerCheatMode` | false | 堆肥桶/抽水站能否仅用红石驱动 |
| `usePipesForSprinklers` | true | 喷头是否只接受 Firmalife 管道 |

### 3.8 交互注册（`InteractionManager`）

```java
public class FLInteractionManager
{
    public static void init()
    {
        InteractionManager.registerBlock(new BlockItemPlacement(TFCItems.WOOL_YARN, FLBlocks.WOOL_STRING) {
            @Override public InteractionResult postPlacement(BlockPlaceContext context) { ... }
        });
        InteractionManager.registerBlock(new BlockItemPlacement(FLItems.PINEAPPLE_YARN, FLBlocks.PINEAPPLE_YARN) { ... });
        InteractionManager.register(Ingredient.of(TFCItems.WROUGHT_IRON_GRILL), InteractionManager.Target.BLOCKS, (stack, context) -> { ... });
        InteractionManager.register(Ingredient.of(TFCItems.POT), InteractionManager.Target.BLOCKS, (stack, context) -> { ... });
    }
}
```

来源：`src/main/java/com/eerussianguy/firmalife/common/misc/FLInteractionManager.java`（全 87 行）。用途：把 TFC 的熟铁烤架 / 锅放在烤箱底部上方，自动变成 `firmalife:stovetop_grill` / `firmalife:stovetop_pot`，并触发成就 `FLAdvancements.STOVETOP_GRILL/POT`。

### 3.9 Mixin

`src/main/resources/firmalife.mixins.json` 真实内容：

```json
{
  "required": true,
  "minVersion": "0.8",
  "package": "com.eerussianguy.firmalife.mixin",
  "compatibilityLevel": "JAVA_17",
  "injectors": { "defaultRequire": 1 },
  "mixins": ["BarrelRackMixin", "BeeMixin", "ServerConfigMixin"],
  "refmap": "firmalife.refmap.json"
}
```

`src/main/templates/META-INF/neoforge.mods.toml` L56-57 声明：

```toml
[[mixins]]
    config = "${modId}.mixins.json"
```

mixins 列表在 `build.gradle.kts` 之外**没有另外的 gradle mixin 插件配置**（`settings.gradle` 里的 spongepowered resolutionStrategy 是仓库遗留，`build.gradle.kts` 中没有 `mixin { }` 块）。因此 Firmalife 使用的是 NeoForge 内置的混入支持（`[[mixins]]` 块 + `refmap` 字段）。

3 个 mixin 的目标与注入点（全部已逐行核实）：

| Mixin | 目标类 | 注入点 | 作用 |
| --- | --- | --- | --- |
| `mixin/BarrelRackMixin.java` | `net.dries007.tfc.common.blocks.devices.BarrelRackBlock`（TFC） | `@Inject(method = "canBeReplaced", at = @At("HEAD"), cancellable = true)` | 手持 `CheeseWheelBlock` 的 `BlockItem` 时强制返回 `true`，从而把奶酪轮放到 TFC 的酒桶架上 |

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

| Mixin | 目标类 | 注入点 | 作用 |
| --- | --- | --- | --- |
| `mixin/BeeMixin.java` | `net.minecraft.world.entity.animal.Bee`（**原版**） | `@Inject(method = "tick", at = @At("TAIL"))` + `@Shadow abstract void setHasNectar(boolean)` | 仅对 `instanceof FLBee` 的实例生效：每 600 tick（30 秒）调用 `setHasNectar(false)`，即 Firmalife 蜜蜂会定期「失去花粉」，用于控制授粉节奏 |

```java
@Mixin(Bee.class)
public abstract class BeeMixin extends Animal implements NeutralMob, FlyingAnimal
{
    @Shadow abstract void setHasNectar(boolean pHasNectar);

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

| Mixin | 目标类 | 注入点 | 作用 |
| --- | --- | --- | --- |
| `mixin/ServerConfigMixin.java` | `net.dries007.tfc.config.ServerConfig`（TFC） | `@Inject(method = "<init>", at = @At("TAIL"), remap = false)` + `@Shadow(remap = false) @Mutable @Final` | 在 TFC 的 `ServerConfig` 构造完成后把 `enablePumpkinCarving` **无条件强制为 `() -> false`**，即关闭 TFC 自带的南瓜雕刻（Firmalife 用 `firmalife:pumpkin_knapping` 数据表与 `CarvedPumpkinBlock` 系统接管了该功能，见 §4.3 的 `knapping_type/pumpkin.json`） |

```java
@Mixin(ServerConfig.class)
public abstract class ServerConfigMixin
{
    @Shadow(remap = false) @Mutable @Final
    public Supplier<Boolean> enablePumpkinCarving;

    @Inject(method = "<init>", at = @At("TAIL"), remap = false)
    private void inject$init(ConfigBuilder builder, CallbackInfo ci)
    {
        enablePumpkinCarving = () -> false;
    }
}
```

**`remap = false` 是必须的**：TFC 的类不在原版混淆映射中，不写会导致 mixin 按混淆后的名字找不到字段/方法。

### 3.10 Patchouli 集成（**硬依赖**）

`neoforge.mods.toml` 把 patchouli 声明为 `required`：

```toml
[[dependencies.firmalife]]
    modId = "patchouli"
    type = "required"
    versionRange = "${patchouliVersionRange}"
    ordering = "NONE"
    side = "BOTH"
```

`build.gradle.kts` L151 注释说明为何用全量 jar 而非 api：

```kotlin
// Patchouli
// We need to compile against the full JAR, not just the API, because we do some egregious hacks.
implementation("vazkii.patchouli:Patchouli:$patchouliVersion")
```

证据（用到了 Patchouli 的**内部 API**，不只是 `api` 包）：

```java
import vazkii.patchouli.api.TriPredicate;   // common/util/Mechanics.java L23
...
public static Set<BlockPos> floodfill(Level level, BlockPos startPos, BlockPos.MutableBlockPos mutable,
        BoundingBox bounds, TriPredicate<BlockState, BlockPos, Direction> wallPredicate,
        Predicate<BlockState> interiorPredicate, boolean testOrigin, int lastSize, Direction[] checkDirections)
```

来源：`common/util/Mechanics.java` L23、L32。

多块结构注册（在 `FMLCommonSetupEvent` 中同步调用）：

```java
public static void registerMultiBlocks()
{
    registerMultiblock("treated_wood_greenhouse", api -> greenhouse(api, Greenhouse.TREATED_WOOD, FLTags.Blocks.ALL_TREATED_WOOD_GREENHOUSE));
    registerMultiblock("copper_greenhouse", api -> greenhouse(api, Greenhouse.COPPER, FLTags.Blocks.ALL_COPPER_GREENHOUSE));
    registerMultiblock("iron_greenhouse", api -> greenhouse(api, Greenhouse.IRON, FLTags.Blocks.ALL_IRON_GREENHOUSE));
    registerMultiblock("stainless_steel_greenhouse", api -> greenhouse(api, Greenhouse.IRON, FLTags.Blocks.STAINLESS_STEEL_GREENHOUSE));
    registerMultiblock("cellar", FLPatchouliIntegration::cellar);
}
```

来源：`compat/patchouli/FLPatchouliIntegration.java` L30-101。注册出的 Patchouli 多块 ID 是 `firmalife:treated_wood_greenhouse`、`firmalife:copper_greenhouse`、`firmalife:iron_greenhouse`、`firmalife:stainless_steel_greenhouse`、`firmalife:cellar`。

Patchouli 书页内容以**资源包覆盖**的方式写进 TFC 的 field guide：

```
src/main/resources/assets/tfc/patchouli_books/field_guide/<lang>/entries/firmalife/*.json
src/main/resources/assets/tfc/patchouli_books/field_guide/<lang>/categories/*.json
```

存在 `en_us`、`ja_jp`、`ru_ru`、`zh_cn`、`zh_tw` 五个语言目录（`en_us/entries` 下含 `firmalife/` 与 `mechanics/` 两个子目录）。来源：`src/main/resources/assets/tfc/patchouli_books/field_guide/` 目录树。

配套的 Patchouli 自定义组件（把配方渲染成书页）位于 `compat/patchouli/DryingComponent.java`、`SmokingComponent.java`；集成入口见 `compat/patchouli/package-info.java`。

### 3.11 Jade / The One Probe / JEI

| 集成 | 接入方式 | 位置 |
| --- | --- | --- |
| The One Probe | `InterModEnqueueEvent` → `InterModComms.sendTo("theoneprobe", "getTheOneProbe", TheOneProbeIntegration::new)`；类实现 `Function<ITheOneProbe, Void>`，并把 `FLTooltips.BlockEntities` / `FLTooltips.Entities` 的注册回调转成 TOP 的 `IProbeInfoProvider` | `compat/tooltip/TheOneProbeIntegration.java` L19-45+ |
| Jade | `compat/tooltip/JadeIntegration.java`（与 `FLTooltips` 共享 tooltip 定义） | `compat/tooltip/` |
| JEI | `@JeiPlugin public class FLJEIPlugin implements IModPlugin`，UID 为 firmalife；为 11 个配方类别注册 `RecipeType<RecipeHolder<T>>`，并在 `registerRecipeCatalysts` 里把方块挂为催化剂 | `compat/jei/FLJEIPlugin.java` L37-110 |
| EMI | 仅编译期依赖 `dev.emi:emi-neoforge:...:api`，`runtimeOnly` 被注释掉（`build.gradle.kts` L142-143）；`FirmaLife.EMI` 仅作探测 | — |

`FLJEIPlugin` 里注册的类别 ID（`compat/jei/FLJEIPlugin.java` L47-57）：`drying`、`smoking`、`stomping`、`press`、`centrifuge`、`mixing_bowl`、`pumpkin_knapping`、`oven`、`vat`、`bowl_pot`、`stinky_soup`。其中 `pumpkin_knapping` 用的是 **TFC 的 `KnappingRecipe`**，`bowl_pot` / `stinky_soup` 用的是 **TFC 的 `PotRecipe`**。

### 3.12 资源覆盖包（`AddPackFindersEvent`）

```java
public static void onPackFinder(AddPackFindersEvent event)
{
    if (event.getPackType() == PackType.CLIENT_RESOURCES)
    {
        final IModFileInfo info = ModList.get().getModFileById(FirmaLife.MOD_ID);
        event.addRepositorySource(consumer ->
            consumer.accept(Pack.readMetaAndCreate(
                new PackLocationInfo("firmalife_data", Component.literal("Firmalife Resources"), PackSource.BUILT_IN, Optional.empty()),
                ResourcePackLoader.createPackForMod(info),
                PackType.CLIENT_RESOURCES,
                new PackSelectionConfig(true, Pack.Position.TOP, false))));
    }
}
```

来源：`common/FLEvents.java` L31-43。作用：把自己 jar 内的资源以 `Position.TOP` 覆盖 TFC 的同名资源（例如 `assets/tfc/...` 下的 TFC 材质与 Patchouli 书页）。**附属模组若要覆盖 TFC/Firmalife 的资源，必须使用同样的手法**（或依赖资源包优先级）。

### 3.13 `FLHelpers` 公开工具方法清单

`FLHelpers` 是 Firmalife 中最常被内部与可能被外部引用的工具类（`public class FLHelpers`，非 final、构造器未显式定义，可继承——但源码无任何继承者）。全部 public 成员签名（来源：`src/main/java/com/eerussianguy/firmalife/common/FLHelpers.java`）：

```java
public static final boolean ASSERTIONS_ENABLED;
public static final Codec<KoppenClimateClassification> KOPPEN_CODEC;
public static final StreamCodec<ByteBuf, KoppenClimateClassification> KOPPEN_STREAM_CODEC;

public static ResourceLocation identifier(String id);                                   // = ResourceLocation.fromNamespaceAndPath(MOD_ID, id)
public static FluidStack getFluidInTank(BlockEntity blockEntity);
public static void resetCounter(Level level, BlockPos pos);
public static BlockState copyProperties(BlockState copyTo, BlockState copyFrom, Property<?>... properties);
public static <T> Optional<T> getRandomElement(Registry<T> registry, TagKey<T> tag, RandomSource random);
public static void writeTraitList(List<Holder<FoodTrait>> list, CompoundTag nbt, String key);
public static void readTraitList(List<Holder<FoodTrait>> list, CompoundTag nbt, String key);
public static void writeItemStackList(List<ItemStack> list, CompoundTag nbt, String key, HolderLookup.Provider access);
public static void readItemStackList(List<ItemStack> list, CompoundTag nbt, String key, HolderLookup.Provider access);
public static Component blockEntityName(String name);
public static <T extends BlockEntity> void readInventory(Level level, BlockPos pos, Supplier<BlockEntityType<T>> type, BiConsumer<T, IItemHandler> consumer);
public static <T extends BlockEntity> InteractionResult consumeInventory(Level level, BlockPos pos, Supplier<BlockEntityType<T>> type, BiFunction<T, IItemHandler, InteractionResult> consumer);
public static <T extends InventoryBlockEntity<?>> ItemInteractionResult consumeItemInventory(Level level, BlockPos pos, Supplier<BlockEntityType<T>> type, BiFunction<T, IItemHandler, ItemInteractionResult> consumer);
public static ItemInteractionResult swapOne(Level level, ItemStack item, int slot, IItemHandler inv, Player player);
public static BlockPos getPoint(Level level, BlockPos origin, int radius, Holder<PoiType> type);
public static BlockPos getPoint(Level level, BlockPos origin, int radius, Holder<PoiType> type, BiPredicate<Level, BlockPos> predicate);
public static ItemInteractionResult insertOne(Level level, ItemStack item, int slot, IItemHandler inv, Player player);
public static ItemInteractionResult takeOne(Level level, int slot, IItemHandler inv, Player player);
public static ItemInteractionResult insertOneAny(Level level, ItemStack item, int start, int end, IItemHandler inv, Player player);
public static ItemStack mergeInsertStack(IItemHandler inventory, int slot, ItemStack stack);
public static void spawnParticlesOnBlockFaces(Level level, BlockPos pos, ParticleOptions particle, IntProvider count);
public static void spawnParticlesInBlock(Level level, BlockPos pos, int count, ParticleOptions particle);
public static int getRedstoneSignalFromContainer(Level level, BlockPos pos);
public static int getRedstoneSignalFromContainer(IItemHandler inv);
public static boolean stackableExceptHeatAndFood(ItemStack stack1, ItemStack stack2);
public static <T extends Comparable<T>> boolean hasPropertyAndValue(BlockState state, Property<T> property, T value);
public static NonNullList<ItemStack> extractAllItems(IItemHandlerModifiable inventory);
public static void insertAllItems(IItemHandlerModifiable inventory, NonNullList<ItemStack> from);
public static ItemInteractionResult takeOneAny(Level level, int start, int end, IItemHandler inv, Player player);
public static ResourceLocation res(String string);
public static ResourceLocation res(String namespace, String path);
public static Iterable<BlockPos> allPositionsCentered(BlockPos center, int radius, int height);
public static MutableComponent translateEnum(Enum<?> anEnum);
public static String getEnumTranslationKey(Enum<?> anEnum);
public static String getEnumTranslationKey(Enum<?> anEnum, String enumName);
public static void roundCreationDate(ItemStack stack);
public static <T> void fakeDataManager(DataManager<T> manager, Map<String, T> values);
public static boolean aabbContainsPoint(AABB shape, Vec3 pos);
public static VoxelShape[][] computeHorizontalShapeGroup(List<Function<Direction, VoxelShape>> shapes);
public static <B, C, T1..T10> StreamCodec<B, C> composite(...);   // 最多支持 10 个元素的 StreamCodec.composite
```

其中 `FLHelpers.composite` 是 Firmalife 为突破原版 `StreamCodec.composite` 的 6 参上限而自写的 10 参版本（`Plantable.STREAM_CODEC` 用它）。

---

## 4. 数据驱动内容（目录、格式、真实 JSON 示例、逐字段说明）

### 4.0 目录总清单一览

`src/generated/resources/data/` 下出现 5 个命名空间：`c/`（通用标签）、`firmalife/`、`minecraft/`、`neoforge/`、`tfc/`。

| 数据目录 | 归属类型 | Java 端类型 / 管理器 | 生成者（datagen） |
| --- | --- | --- | --- |
| `data/firmalife/firmalife/greenhouse/*.json` | **Firmalife 自定义 DataManager** `firmalife:greenhouse` | `common.util.GreenhouseType` | `DataEntryPoint` 内匿名 `DataManagerProvider<GreenhouseType>` |
| `data/firmalife/firmalife/plantable/*.json` | **Firmalife 自定义 DataManager** `firmalife:plantable` | `common.util.Plantable` | `providers/BuiltinPlantables` |
| `data/firmalife/recipe/**` | 原版配方 registry | 见 §4.2 | `providers/BuiltinRecipes` |
| `data/firmalife/damage_type/*.json` | 原版 registry | 原版 `DamageType` | `providers/BuiltinDamageTypes`（经 `DatapackBuiltinEntriesProvider`） |
| `data/firmalife/loot_table/blocks/**` | 原版 registry | 原版 `LootTable` | `providers/BuiltinBlockLootTables` |
| `data/firmalife/loot_modifiers/*.json` | NeoForge GLM | `neoforge:add_table` / `firmalife:add_item` | `providers/BuiltinLootModifiers` |
| `data/firmalife/tags/{block,entity_type,fluid,item}/**` | 原版 tag registry | — | `BuiltinBlockTags` / `BuiltinEntityTypeTags` / `BuiltinFluidTags` / `BuiltinItemTags` |
| `data/firmalife/tags/tfc/food_trait/*.json` | **TFC 自定义 registry 的标签** | `FoodTraits.KEY` | `DataEntryPoint` 内匿名 `TagsProvider<FoodTrait>` |
| `data/firmalife/tfc/climate_range/**` | **TFC DataManager** `tfc:climate_range` | `net.dries007.tfc.util.climate.ClimateRange` | `BuiltinClimateRanges` |
| `data/firmalife/tfc/drinkable/*.json` | **TFC DataManager** `tfc:drinkable` | `net.dries007.tfc.util.data.Drinkable` | `DataEntryPoint` 匿名 provider |
| `data/firmalife/tfc/fluid_heat/*.json` | **TFC DataManager** `tfc:fluid_heat` | `net.dries007.tfc.util.data.FluidHeat` | `BuiltinFluidHeats` |
| `data/firmalife/tfc/food/**` | **TFC DataManager** `tfc:food` | `net.dries007.tfc.common.component.food.FoodDefinition` | `BuiltinFoods` |
| `data/firmalife/tfc/item_heat/**` | **TFC DataManager** `tfc:item_heat` | `HeatDefinition`（`HeatCapability.MANAGER`） | `BuiltinItemHeat` |
| `data/firmalife/tfc/item_size/*.json` | **TFC DataManager** `tfc:item_size` | `ItemSizeDefinition`（`ItemSizeManager.MANAGER`） | `BuiltinItemSizes` |
| `data/firmalife/tfc/knapping_type/*.json` | **TFC DataManager** `tfc:knapping_type` | `net.dries007.tfc.util.data.KnappingType` | `DataEntryPoint` 匿名 provider |
| `data/firmalife/tfc/lamp_fuel/*.json` | **TFC DataManager** `tfc:lamp_fuel` | `net.dries007.tfc.util.data.LampFuel` | `DataEntryPoint` 匿名 provider |
| `data/firmalife/advancement/story/*.json` | 原版 registry | 原版 `Advancement` | **手工维护**（在 `src/main/resources` 内，37 个文件） |
| `data/firmalife/worldgen/{configured,placed}_feature/**` | 原版 registry | 原版 `Feature` | **手工维护** |
| `data/tfc/recipe/{barrel,crafting,heating}/**` | 原版配方 registry，写进 `tfc` 命名空间 | — | `BuiltinRecipes` 的**删除占位**（见 §4.4） |
| `data/tfc/tags/**`、`data/tfc/tags/worldgen/placed_feature/**` | 原版 tag registry | — | 向 TFC 的标签追加 Firmalife 条目 |
| `data/c/tags/**` | 通用标签 | — | 金属/矿石/食物条目 |
| `data/minecraft/tags/**` | 原版标签 | — | 方块/物品/伤害类型标签 |
| `data/neoforge/loot_modifiers/global_loot_modifiers.json` | NeoForge | — | `BuiltinLootModifiers` |

**「`data/firmalife/tfc/...` 双层命名空间」的成因**（`providers/DataManagerProvider.java` L37）：

```java
this.path = output.createPathProvider(PackOutput.Target.DATA_PACK, domain + "/" + manager.getName());
```

`manager.getName()` 是 TFC `DataManager` 的**完整 id（含命名空间）**，例如 `tfc:climate_range`；而 `domain` 是生成时传入的命名空间。当 `domain = "firmalife"` 时就得到 `data/firmalife/tfc/climate_range/`；Firmalife 自己的 manager（`firmalife:greenhouse`）配 `domain = "firmalife"` 得到 `data/firmalife/firmalife/greenhouse/`。对照 TFC jar 内的原生位置是 `data/tfc/tfc/climate_range/`（见 `moddev/inventory/TFC.resources.txt`）。

### 4.1 Firmalife 的两个自定义 DataManager

#### （a）`firmalife:greenhouse` — `GreenhouseType`

Codec 定义（`common/util/GreenhouseType.java` L21-37）：

```java
public record GreenhouseType(BlockIngredient ingredient, int tier, Component translationKey)
{
    public static final Codec<GreenhouseType> CODEC = RecordCodecBuilder.create(instance -> instance.group(
        BlockIngredient.CODEC.fieldOf("ingredient").forGetter(c -> c.ingredient),
        Codecs.POSITIVE_INT.fieldOf("tier").forGetter(c -> c.tier),
        ComponentSerialization.CODEC.fieldOf("translation_key").forGetter(c -> c.translationKey)
    ).apply(instance, GreenhouseType::new));

    public static final DataManager<GreenhouseType> MANAGER =
        new DataManager<>(FLHelpers.identifier("greenhouse"), CODEC, STREAM_CODEC);
    public static final IndirectHashCollection<Block, GreenhouseType> CACHE =
        IndirectHashCollection.create(s -> s.ingredient.blocks(), MANAGER::getValues);
}
```

真实文件 `src/generated/resources/data/firmalife/firmalife/greenhouse/iron.json` 全文：

```json
{
  "ingredient": "#firmalife:all_iron_greenhouse",
  "tier": 15,
  "translation_key": {
    "translate": "greenhouse.firmalife.iron"
  }
}
```

| 字段 | 类型 | 必需 | 默认值 | 说明 |
| --- | --- | --- | --- | --- |
| `ingredient` | `BlockIngredient` | **必需** | — | 构成该温室等级的方块集合。示例用标签形式 `#firmalife:all_iron_greenhouse`；也可用单方块 `{ "block": "..." }` 等 TFC `BlockIngredient` 的全部形式 |
| `tier` | int > 0 | **必需** | — | 温室等级。现有 4 个文件的值：`treated_wood = 5`、`copper = 10`（见 `copper.json`）、`iron = 15`、`stainless_steel = 20`（见 `stainless_steel.json`） |
| `translation_key` | `Component`（`ComponentSerialization.CODEC`） | **必需** | — | 显示名组件，示例为 `{"translate": "greenhouse.firmalife.iron"}` |

共 4 个文件：`copper.json`、`iron.json`、`stainless_steel.json`、`treated_wood.json`。
另有 `treated_wood.json`：

```json
{
  "ingredient": "#firmalife:all_treated_wood_greenhouse",
  "tier": 5,
  "translation_key": { "translate": "greenhouse.firmalife.treated_wood" }
}
```

#### （b）`firmalife:plantable` — `Plantable`

Codec 定义（`common/util/Plantable.java` L48-76）：

```java
public record Plantable(Ingredient ingredient, PlanterType planter, int tier, int stages, float extraSeedChance,
                        ItemStack seed, ItemStack crop, NutrientList nutrient,
                        List<ResourceLocation> textures, List<ResourceLocation> specials)
{
    public record NutrientList(float nitrogen, float phosphorous, float potassium) {}

    public static final Codec<Plantable> CODEC = RecordCodecBuilder.create(i -> i.group(
        Ingredient.CODEC_NONEMPTY.fieldOf("ingredient").forGetter(c -> c.ingredient),
        PlanterType.CODEC.fieldOf("planter").forGetter(c -> c.planter),
        Codecs.POSITIVE_INT.optionalFieldOf("tier", 0).forGetter(c -> c.tier),
        Codecs.POSITIVE_INT.optionalFieldOf("stages", 0).forGetter(c -> c.stages),
        Codecs.POSITIVE_FLOAT.optionalFieldOf("extra_seed_chance", 0.5f).forGetter(c -> c.extraSeedChance),
        ItemStack.CODEC.fieldOf("seed").forGetter(c -> c.seed),
        ItemStack.CODEC.fieldOf("crop").forGetter(c -> c.crop),
        NUTRIENT_LIST_CODEC.fieldOf("nutrient").forGetter(c -> c.nutrient),
        ResourceLocation.CODEC.listOf().fieldOf("textures").forGetter(c -> c.textures),
        ResourceLocation.CODEC.listOf().fieldOf("specials").forGetter(c -> c.specials)
    ).apply(i, Plantable::new));

    public static final DataManager<Plantable> MANAGER =
        new DataManager<>(FLHelpers.identifier("plantable"), CODEC, STREAM_CODEC);
    public static final IndirectHashCollection<Item, Plantable> CACHE =
        IndirectHashCollection.create(c -> RecipeHelpers.itemKeys(c.ingredient), MANAGER::getValues);
}
```

真实文件 `src/generated/resources/data/firmalife/firmalife/plantable/banana.json` 全文：

```json
{
  "crop": { "count": 1, "id": "tfc:food/banana" },
  "extra_seed_chance": 0.08,
  "ingredient": { "item": "tfc:plant/banana_sapling" },
  "nutrient": { "nitrogen": 0.25, "phosphorous": 0.3, "potassium": 0.3 },
  "planter": "hanging",
  "seed": { "count": 1, "id": "tfc:plant/banana_sapling" },
  "specials": [ "firmalife:block/crop/banana_fruit" ],
  "stages": 4,
  "textures": [
    "firmalife:block/crop/banana_0",
    "firmalife:block/crop/banana_1",
    "firmalife:block/crop/banana_2",
    "firmalife:block/crop/banana_3",
    "firmalife:block/crop/banana_4"
  ],
  "tier": 15
}
```

| 字段 | 类型 | 必需 | 默认值 | 说明 |
| --- | --- | --- | --- | --- |
| `ingredient` | `Ingredient`（`CODEC_NONEMPTY`，不可为空） | **必需** | — | 用来「识别」这种可种植物的物品（通常是种子或树苗）；`Plantable.get(ItemStack)` 用它匹配 |
| `planter` | enum `PlanterType` | **必需** | — | 可种的盆类型，取值 `quad` / `large` / `hanging` / `trellis` / `bonsai` / `hydroponic`（`common/blocks/greenhouse/PlanterType.java` L11-19） |
| `tier` | int > 0 | 可选 | `0` | 所需温室等级下限；未写时为 0（任何环境可种）。示例 `banana = 15`、`barley = 10`、`alfalfa` 未写 |
| `stages` | int > 0 | 可选 | `0` | 生长阶段数（与 `textures` 的索引上限配合） |
| `extra_seed_chance` | float > 0 | 可选 | `0.5` | 收获时额外掉落种子的概率 |
| `seed` | `ItemStack` | **必需** | — | 播种时消耗的物品堆 |
| `crop` | `ItemStack` | **必需** | — | 收获产物。`Plantable.getCrop()` 会对它调用 `FoodCapability.setCreatedNow(...)`，**自动盖创建日期** |
| `nutrient` | `{nitrogen, phosphorous, potassium}`（三字段均为 float，全部必需） | **必需** | — | 每阶段消耗/补充的养分；负值表示消耗。见下方 `alfalfa.json`（全负）与 `banana.json`（全正） |
| `textures` | `ResourceLocation` 数组 | **必需** | — | 各生长阶段的模型贴图。`Plantable.getTexture(float growth)`：若长度为 2 则按 `growth >= 1` 二选一，否则按 `clamp((int)(growth * stages), 0, size-1)` 索引 |
| `specials` | `ResourceLocation` 数组 | **必需** | — | 「特殊」贴图（例如果实层），通过 `getSpecialTexture(int id)` 使用；无特殊贴图时写 `[]` |

`src/generated/resources/data/firmalife/firmalife/plantable/alfalfa.json`（养分全为负值的例子）：

```json
{
  "crop": { "count": 1, "id": "tfc:alfalfa" },
  "ingredient": { "item": "tfc:seeds/alfalfa" },
  "nutrient": { "nitrogen": -0.8, "phosphorous": -0.5, "potassium": -0.6 },
  "planter": "quad",
  "seed": { "count": 1, "id": "tfc:seeds/alfalfa" },
  "specials": [],
  "stages": 5,
  "textures": [
    "tfc:block/crop/alfalfa_0", "tfc:block/crop/alfalfa_1", "tfc:block/crop/alfalfa_2",
    "tfc:block/crop/alfalfa_3", "tfc:block/crop/alfalfa_4", "tfc:block/crop/alfalfa_5"
  ]
}
```

共 **63 个** plantable 文件（`src/generated/resources/data/firmalife/firmalife/plantable/`）。注意：`stages` 与 `textures` 的长度不必相等（`alfalfa` 为 `stages=5` 而 `textures` 有 6 项）。

### 4.2 Firmalife 自定义配方类型的 JSON（每类 1 个真实示例）

#### `firmalife:drying`

`src/generated/resources/data/firmalife/recipe/drying/dry_fruits.json`：

```json
{
  "type": "firmalife:drying",
  "ingredient": {
    "type": "tfc:and",
    "children": [
      { "tag": "c:foods/fruit" },
      { "type": "tfc:not_rotten" },
      { "type": "tfc:lacks_trait", "trait": "firmalife:dried" }
    ]
  },
  "result": {
    "modifiers": [
      { "type": "tfc:copy_input" },
      { "type": "tfc:add_trait", "trait": "firmalife:dried" }
    ]
  }
}
```

| 字段 | 类型 | 必需 | 说明 |
| --- | --- | --- | --- |
| `type` | string | 必需 | `firmalife:drying` |
| `ingredient` | `Ingredient` | 必需 | 支持 TFC 扩展 ingredient 类型：`tfc:and`（`children` 数组）、`tfc:not_rotten`、`tfc:lacks_trait`（`trait`）、`tfc:has_trait`、`tfc:rotten`、`tfc:heat` 等 |
| `result` | `ItemStackProvider` | 必需 | `modifiers` 数组 + 可选 `stack`；只用 `modifiers` 时输出即输入（经 `tfc:copy_input`） |

#### `firmalife:smoking`

`src/generated/resources/data/firmalife/recipe/smoking/smoke_cheeses.json`：

```json
{
  "type": "firmalife:smoking",
  "ingredient": {
    "type": "tfc:and",
    "children": [
      { "tag": "firmalife:foods/cheeses" },
      { "type": "tfc:not_rotten" },
      { "type": "tfc:lacks_trait", "trait": "firmalife:smoked" }
    ]
  },
  "result": {
    "modifiers": [
      { "type": "tfc:copy_input" },
      { "type": "tfc:add_trait", "trait": "firmalife:smoked" }
    ]
  }
}
```

字段与 `drying` 完全一致（同为 `ItemRecipe` 派生，只有 `type` 不同）。

#### `firmalife:oven`

`src/generated/resources/data/firmalife/recipe/oven/cook_pie.json`：

```json
{
  "type": "firmalife:oven",
  "duration": 1000,
  "ingredient": {
    "type": "tfc:and",
    "children": [
      { "item": "firmalife:food/filled_pie" },
      { "type": "tfc:not_rotten" }
    ]
  },
  "result": {
    "modifiers": [ { "type": "firmalife:copy_dynamic_food" } ],
    "stack": { "count": 1, "id": "firmalife:food/cooked_pie" }
  },
  "temperature": 400.0
}
```

| 字段 | 类型 | 必需 | 说明 |
| --- | --- | --- | --- |
| `type` | string | 必需 | `firmalife:oven` |
| `ingredient` | `Ingredient` | 必需 | 输入 |
| `result` | `ItemStackProvider` | 必需 | 输出；示例用 Firmalife 自注册的 `firmalife:copy_dynamic_food` 修饰符把动态食物数据（营养/创建日期/碗）复制到产物 |
| `temperature` | float | 必需 | 达到该温度才可烤（`isValidTemperature(t) = t >= temperature`） |
| `duration` | int > 0 | 必需 | 烤制时长（tick） |

`OvenRecipe.assembleItem(ItemStack)` 会**无条件**把输入的热量（`HeatCapability`）带到输出（`common/recipes/OvenRecipe.java` L89-99）。

#### `firmalife:vat`

`src/generated/resources/data/firmalife/recipe/vat/black_dye.json`：

```json
{
  "type": "firmalife:vat",
  "input_fluid": { "amount": 1000, "fluid": "minecraft:water" },
  "input_item": { "count": 1, "tag": "c:dyes/black" },
  "length": 600,
  "output_fluid": { "amount": 1000, "id": "tfc:black_dye" },
  "temperature": 300.0
}
```

| 字段 | 类型 | 必需 | 默认值 | 说明 |
| --- | --- | --- | --- | --- |
| `type` | string | 必需 | — | `firmalife:vat` |
| `input_item` | `SizedIngredient` | 必需 | — | `count` + (`item` / `tag` / TFC 扩展 ingredient)。`count = 0` 时表示只按流体匹配 |
| `input_fluid` | `SizedFluidIngredient` | 必需 | — | `amount` + (`fluid` / `tag`)。`amount = 0` 时表示只按物品匹配 |
| `length` | int > 0 | 必需 | — | 处理时长（tick） |
| `temperature` | float | 必需 | — | 所需温度 |
| `output_item` | `ItemStackProvider` | 可选 | 空 | 主产物（放入溢出槽 `excess`） |
| `output_fluid` | `FluidStack` | 可选 | 空 | 输出流体；为空时保留尽可能多的输入流体（否则多余的输入被 void） |
| `jar_output` | `ItemStack` | 可选 | 空 | 「装罐产物」，由 `JarringStationBlockEntity` 取走 |
| `output_texture` | `ResourceLocation` | 可选 | 空 | 装罐产物的渲染贴图 |

`VatRecipe.assemble(...)` 恒定返回 `null`，真实产出走 `assembleOutputs(VatBlockEntity, VatInventory)`（`common/recipes/VatRecipe.java` L167-170、L75-153）——**附属模组实现自定义机器时不要依赖 `assemble`**。

#### `firmalife:stomping` / `firmalife:press`

`src/generated/resources/data/firmalife/recipe/stomping/food/smashed_red_grapes.json`：

```json
{
  "type": "firmalife:stomping",
  "ingredient": {
    "type": "tfc:and",
    "children": [
      { "item": "firmalife:food/red_grapes" },
      { "type": "tfc:not_rotten" },
      { "type": "tfc:lacks_trait", "trait": "firmalife:dried" }
    ]
  },
  "input_texture": "firmalife:block/red_unsmashed_grapes",
  "output_texture": "firmalife:block/red_smashed_grapes",
  "result": { "count": 1, "id": "firmalife:food/smashed_red_grapes" },
  "sound": "minecraft:entity.slime.squish"
}
```

| 字段 | 类型 | 必需 | 说明 |
| --- | --- | --- | --- |
| `type` | string | 必需 | `firmalife:stomping` 或 `firmalife:press`（两者 JSON 结构完全相同） |
| `ingredient` | `Ingredient` | 必需 | 输入 |
| `input_texture` | `ResourceLocation` | 必需 | 踩踏前的贴图 |
| `output_texture` | `ResourceLocation` | 必需 | 踩踏后的贴图 |
| `result` | `ItemStackProvider` | 必需 | 输出（示例用简写 `{count, id}`；`ItemStackProvider.CODEC` 兼容该简写） |
| `sound` | `ResourceLocation`（`BuiltInRegistries.SOUND_EVENT.byNameCodec()`） | 必需 | 触发音效 |

**`firmalife:press` 没有任何内置 JSON 示例**：`src/data/java/.../recipes/` 下没有 `PressRecipes.java`，`src/generated/resources/data/firmalife/recipe/` 下没有 `press/` 目录，全仓库也搜不到 `"type": "firmalife:press"`；其结构只能按上面的 `stomping` 推断（`PressRecipe.P_CODEC` 与 `StompingRecipe.CODEC` 字段逐一相同）。

#### `firmalife:centrifuge`

`src/generated/resources/data/firmalife/recipe/centrifuge/sugar.json`：

```json
{
  "type": "firmalife:centrifuge",
  "ingredient": { "item": "firmalife:sugared_beehive_frame" },
  "result": { "count": 1, "id": "minecraft:sugar" }
}
```

| 字段 | 类型 | 必需 | 说明 |
| --- | --- | --- | --- |
| `type` | string | 必需 | `firmalife:centrifuge` |
| `ingredient` | `Ingredient` | 必需 | 输入 |
| `result` | `ItemStackProvider` | 必需 | 输出（简写 `{count, id}` 或 `{"stack": ..., "modifiers": [...]}`） |

#### `firmalife:mixing_bowl`

`src/generated/resources/data/firmalife/recipe/mixing_bowl/food/butter.json`：

```json
{
  "type": "firmalife:mixing_bowl",
  "fluid_ingredients": { "amount": 1000, "fluid": "firmalife:cream" },
  "item_ingredients": [ { "item": "tfc:powder/salt" } ],
  "result_item": { "count": 1, "id": "firmalife:food/butter" }
}
```

| 字段 | 类型 | 必需 | 默认值 | 说明 |
| --- | --- | --- | --- | --- |
| `type` | string | 必需 | — | `firmalife:mixing_bowl` |
| `item_ingredients` | `Ingredient` 数组 | **必需** | — | 无序匹配（用 `Helpers.perfectMatchExists`）；空数组表示为「只按流体匹配，且要求物品栏为空」 |
| `fluid_ingredients` | `SizedFluidIngredient`（`FLAT_CODEC`） | 可选 | 空 | 用 `optionalFieldOf`；用 FluidIngredient 空匹配时无法序列化（源码 TODO 注明） |
| `result_item` | `ItemStack` | 可选 | `ItemStack.EMPTY` | 产物物品；构造时自动 `FoodCapability.setNonDecaying(resultItem)` |
| `result_fluid` | `FluidStack` | 可选 | `FluidStack.EMPTY` | 产物流体 |

#### `tfc:pot` 的两种 Firmalife 输出（`stinky_soup` / `bowl_pot`）

`src/generated/resources/data/firmalife/recipe/pot/chocolate.json`（普通 TFC 锅配方）：

```json
{
  "type": "tfc:pot",
  "duration": 2000,
  "fluid_ingredient": { "amount": 1000, "tag": "firmalife:milks" },
  "fluid_output": { "amount": 1000, "id": "firmalife:chocolate" },
  "ingredients": [
    { "tag": "tfc:foods/sweeteners" },
    { "type": "tfc:and", "children": [
        { "tag": "firmalife:foods/chocolate" },
        { "type": "tfc:not_rotten" } ] }
  ],
  "temperature": 300.0,
  "uses_all_fluid": false
}
```

原理：`StinkySoupRecipe` / `BowlPotRecipe` 都 `extends PotRecipe`，**沿用 TFC 的 `tfc:pot` 配方类型**，只额外注册 serializer（`firmalife:stinky_soup` / `firmalife:bowl_pot`）和一个 `PotOutput.OutputType`（`firmalife:stinky_soup` / `firmalife:bowl`）。它们的 JSON 因此完全遵循 TFC `tfc:pot` 的格式（`ingredients` + `fluid_ingredient` + `duration` + `temperature` + 可选的 `fluid_output` / `uses_all_fluid`）。

`StinkySoupRecipe.CODEC` 的实现方式是把 TFC 的 codec 直接 `xmap`：

```java
public static final MapCodec<StinkySoupRecipe> CODEC = PotRecipe.CODEC.xmap(StinkySoupRecipe::new, Function.identity());
public static final StreamCodec<RegistryFriendlyByteBuf, StinkySoupRecipe> STREAM_CODEC =
    PotRecipe.STREAM_CODEC.map(StinkySoupRecipe::new, Function.identity());
```

来源：`common/recipes/StinkySoupRecipe.java` L41-42。

### 4.3 Firmalife 使用的 TFC 数据目录（每类 1 个真实示例）

TFC 这些类型在 `javap` 下的 record 组件（字段名即 JSON key 的 snake_case 形式）：

| TFC 类型 | record 组件（accessor 方法） |
| --- | --- |
| `net.dries007.tfc.util.climate.ClimateRange` | `minHydration`、`maxHydration`、`hydrationWiggleRange`、`minTemperature`、`maxTemperature`、`temperatureWiggleRange` |
| `net.dries007.tfc.util.data.Drinkable` | `ingredient`(FluidIngredient)、`consumeChance`(float)、`mayDrinkWhenFull`(boolean)、`food`(FoodData)、`effects`(List\<Drinkable.Effect\>) |
| `net.dries007.tfc.util.data.FluidHeat` | `fluid`(Fluid)、`meltTemperature`(float)、`specificHeatCapacity`(float) |
| `net.dries007.tfc.common.component.food.FoodDefinition` | `ingredient`(Ingredient)、`food`(FoodData)、`edible`(boolean) |
| `net.dries007.tfc.common.component.size.ItemSizeDefinition` | `ingredient`(Ingredient)、`size`(Size)、`weight`(Weight) |
| `net.dries007.tfc.util.data.KnappingType` | `inputItem`(SizedIngredient)、`amountToConsume`(int)、`clickSound`(Holder\<SoundEvent\>)、`consumeAfterComplete`、`hasOffTexture`、`spawnsParticles`、`icon`(ItemStack) |
| `net.dries007.tfc.util.data.LampFuel` | `fluid`(FluidIngredient)、`lamps`(BlockIngredient)、`burnRate`(int) |
| `net.dries007.tfc.common.recipes.outputs.ItemStackProvider` | `stack`(ItemStack)、`modifiers`(List\<ItemStackModifier\>) |

#### `firmalife/tfc/climate_range/plant/*`（5 个文件）

`.../climate_range/plant/cocoa_tree.json`：

```json
{
  "max_hydration": 80,
  "max_temperature": 35.0,
  "min_hydration": 44,
  "min_temperature": 20.0
}
```

| 字段 | 类型 | 必需 | 说明 |
| --- | --- | --- | --- |
| `min_hydration` / `max_hydration` | int | 必需 | 降雨量范围 |
| `min_temperature` / `max_temperature` | float | 必需 | 温度范围 |
| `hydration_wiggle_range` / `temperature_wiggle_range` | int / float | **未能核实是否可选** | 对应 record 组件 `hydrationWiggleRange`、`temperatureWiggleRange`；本仓库生成的文件中**未出现**，故从 TFC 端默认值未能核实（TFC 源码未 checkout） |

文件列表：`cocoa_tree.json`、`fig_tree.json`、`pineapple_bush.json`、`red_grapes.json`、`white_grapes.json`。

#### `firmalife/tfc/food/*`（88 个文件）

`.../food/aged_cheeses.json`：

```json
{
  "dairy": 3.0,
  "decay_modifier": 2.0,
  "hunger": 4,
  "ingredient": { "tag": "firmalife:foods/aged_cheeses" },
  "saturation": 0.3
}
```

| 字段 | 类型 | 必需 | 说明 |
| --- | --- | --- | --- |
| `ingredient` | `Ingredient` | 必需 | 适用物品（此处用标签） |
| `hunger` | int | 必需 | 饥饿值恢复 |
| `saturation` | float | 必需 | 饱和度 |
| `decay_modifier` | float | 可选（示例已给出） | 腐烂速度倍率 |
| `dairy` / `fruit` / `grain` / `protein` / `vegetables` | float | 可选 | 营养类别（TFC `FoodData` 的字段）；本示例只出现 `dairy`，具体可选集合与默认值**未能核实** |

#### `firmalife/tfc/drinkable/*`（1 个文件）

`.../drinkable/chocolate.json`：

```json
{
  "ingredient": { "fluid": "firmalife:chocolate" },
  "water": 10.0
}
```

| 字段 | 类型 | 必需 | 说明 |
| --- | --- | --- | --- |
| `ingredient` | `FluidIngredient` | 必需 | 可饮用的流体 |
| `water` | float | 必需 | 补水量（`FoodData` 的内联形式之一） |
| `consume_chance` / `may_drink_when_full` / `effects` | — | 可选 | 对应 `Drinkable` 的其余组件；本仓库未生成，默认值**未能核实** |

#### `firmalife/tfc/fluid_heat/*`（2 个文件）

`.../fluid_heat/chromium.json`：

```json
{
  "fluid": "firmalife:metal/chromium",
  "melt_temperature": 1250.0,
  "specific_heat_capacity": 0.008571429
}
```

| 字段 | 类型 | 必需 | 说明 |
| --- | --- | --- | --- |
| `fluid` | `Fluid` | 必需 | 目标流体（注意这里不是 FluidIngredient，而是单个 fluid id） |
| `melt_temperature` | float | 必需 | 熔化温度 |
| `specific_heat_capacity` | float | 必需 | 比热容 |

另一文件为 `stainless_steel.json`。

#### `firmalife/tfc/item_heat/**`（39 个文件）

`.../item_heat/copper_pipe.json`：

```json
{
  "forging_temperature": 0.21000001,
  "heat_capacity": 43200.0,
  "ingredient": { "item": "firmalife:copper_pipe" },
  "welding_temperature": 0.28
}
```

| 字段 | 类型 | 必需 | 说明 |
| --- | --- | --- | --- |
| `ingredient` | `Ingredient` | 必需 | 适用物品 |
| `heat_capacity` | float | 必需 | 热容 |
| `forging_temperature` | float | 必需 | 锻造温度（0..1 归一化） |
| `welding_temperature` | float | 必需 | 焊接温度 |

（`item_heat` 的 TFC 类型 `HeatDefinition` 的完整组件集**未能核实**——本清单按 39 个实际生成文件归纳，未在其他文件中发现额外字段。）

#### `firmalife/tfc/item_size/*`（8 个文件）

`.../item_size/beehive_frame.json`：

```json
{
  "ingredient": { "tag": "firmalife:beehive_frames" },
  "size": "very_small",
  "weight": "very_heavy"
}
```

| 字段 | 类型 | 必需 | 说明 |
| --- | --- | --- | --- |
| `ingredient` | `Ingredient` | 必需 | 适用物品 |
| `size` | enum `Size` | 必需 | 尺寸（示例 `very_small`） |
| `weight` | enum `Weight` | 必需 | 重量（示例 `very_heavy`） |

#### `firmalife/tfc/knapping_type/*`（1 个文件）

`.../knapping_type/pumpkin.json`：

```json
{
  "click_sound": "tfc:item.knapping.leather",
  "consume_after_complete": false,
  "has_off_texture": false,
  "icon": { "count": 1, "id": "tfc:pumpkin" },
  "input": {
    "type": "tfc:and",
    "children": [
      { "tag": "firmalife:pumpkin_knapping" },
      { "type": "tfc:not_rotten" }
    ],
    "count": 1
  },
  "spawns_particles": false
}
```

| 字段 | 类型 | 必需 | 说明 |
| --- | --- | --- | --- |
| `input` | `SizedIngredient`（`SizedIngredient` 内联了 `count`） | 必需 | 可打制的输入（对应 record 组件 `inputItem`） |
| `click_sound` | `SoundEvent` holder | 必需 | 点击音效 |
| `consume_after_complete` | boolean | 必需 | 完成后是否消耗 |
| `has_off_texture` | boolean | 必需 | 是否使用 off 贴图 |
| `spawns_particles` | boolean | 必需 | 是否生成粒子 |
| `icon` | `ItemStack` | 必需 | JEI 显示图标 |
| `amount_to_consume` | int（record 组件 `amountToConsume`，构造器有 `Optional<Integer>` 重载） | 可选 | 消耗数量 |

#### `firmalife/tfc/lamp_fuel/*`（1 个文件）

`.../lamp_fuel/soybean_oil.json`：

```json
{
  "burn_rate": 7000,
  "fluid": { "fluid": "firmalife:soybean_oil" },
  "lamps": "#tfc:lamps"
}
```

| 字段 | 类型 | 必需 | 说明 |
| --- | --- | --- | --- |
| `fluid` | `FluidIngredient` | 必需 | 燃料流体（此处为 `FluidIngredient` 的单流体形式） |
| `lamps` | `BlockIngredient` | 必需 | 适用灯具方块（示例为标签 `#tfc:lamps`） |
| `burn_rate` | int | 必需 | 燃烧速率 |

#### `firmalife/tags/tfc/food_trait/*`（TFC 自定义 registry 的标签）

注意路径是 `data/firmalife/tags/tfc/food_trait/`（tags 目录下再按 registry 的命名空间/路径分目录），**不是** `data/firmalife/tfc/food_trait/`。来源：`src/generated/resources/data/firmalife/tags/tfc/food_trait/`。

### 4.4 `data/tfc/recipe/**` —— 配方「删除占位」

Firmalife **没有**在 `data/tfc/recipe/` 里新增可用配方；该目录下的文件全部是「把 TFC 原配方禁用」的占位，由 `BuiltinRecipes.remove(...)` 生成：

```java
final Codec<Unit> emptyRecipeCodec = Codec.STRING.fieldOf("type")
    .codec()
    .listOf()
    .fieldOf("neoforge:conditions")
    .xmap(l -> Unit.INSTANCE, r -> List.of("neoforge:false"))
    .codec();
...
removedRecipes.stream().map(id -> DataProvider.saveStable(output, lookup, emptyRecipeCodec, Unit.INSTANCE, recipePathProvider.json(id)))
```

来源：`src/data/java/com/eerussianguy/firmalife/providers/BuiltinRecipes.java` L73-102。

生成的 JSON 形如：

```json
{ "neoforge:conditions": [ { "type": "neoforge:false" } ] }
```

目录：`data/tfc/recipe/barrel/*`、`data/tfc/recipe/barrel/food/*`、`data/tfc/recipe/crafting/*`、`data/tfc/recipe/heating/food/*`。

### 4.5 `loot_modifiers`

`src/generated/resources/data/firmalife/loot_modifiers/cherry_leaves.json`：

```json
{
  "type": "neoforge:add_table",
  "conditions": [
    { "condition": "neoforge:loot_table_id", "loot_table_id": "tfc:blocks/plant/cherry_leaves" }
  ],
  "table": "firmalife:blocks/fruit_leaves"
}
```

`src/generated/resources/data/neoforge/loot_modifiers/global_loot_modifiers.json`：

```json
{
  "entries": [
    "firmalife:cherry_leaves", "firmalife:green_apple_leaves", "firmalife:lemon_leaves",
    "firmalife:olive_leaves", "firmalife:orange_leaves", "firmalife:peach_leaves",
    "firmalife:plum_leaves", "firmalife:red_apple_leaves", "firmalife:ice_shavings",
    "firmalife:rennet", "firmalife:more_rennet"
  ],
  "replace": false
}
```

| 字段 | 类型 | 必需 | 说明 |
| --- | --- | --- | --- |
| `type` | string | 必需 | 示例用 **NeoForge 内置**的 `neoforge:add_table`；Firmalife 另注册了 `firmalife:add_item`（`AddItemModifier`，字段 `codecStart` + `item` + `chance`（默认 1.0）） |
| `conditions` | 条件数组 | 必需（GLM 约定） | 示例用 `neoforge:loot_table_id`；Firmalife 还注册了自定义条件 `firmalife:block_ingredient`（字段 `ingredient`，`BlockIngredient`） |
| `table` | 战利品表 id | `neoforge:add_table` 专有 | 要追加的额外战利品表 |
| `replace` | boolean | 必需（在 global 索引里） | `false` 表示追加而非替换整个列表 |

### 4.6 `damage_type`

`src/generated/resources/data/firmalife/damage_type/oven.json`：

```json
{
  "effects": "burning",
  "exhaustion": 0.1,
  "message_id": "firmalife.oven",
  "scaling": "when_caused_by_living_non_player"
}
```

| 字段 | 类型 | 必需 | 说明 |
| --- | --- | --- | --- |
| `message_id` | string | 必需 | 死亡消息键 |
| `exhaustion` | float | 必需 | 饥饿消耗 |
| `scaling` | enum | 必需 | 伤害缩放方式 |
| `effects` | string | 可选 | 施加的原版效果；`burning` 表示着火 |

另一文件为 `swarm.json`（对应 `FLDamageTypes.SWARM`）。配套的标签写入 `data/minecraft/tags/damage_type/bypasses_armor.json` 与 `bypasses_effects.json`。

### 4.7 `worldgen`

`src/main/resources/data/firmalife/worldgen/placed_feature/beehive.json`（**手工维护**，带 datagen 遗留注释）：

```json
{
  "__comment__": "This file was automatically created by mcresources",
  "feature": "firmalife:beehive",
  "placement": [
    { "type": "minecraft:heightmap", "heightmap": "WORLD_SURFACE_WG" },
    { "type": "minecraft:in_square" },
    { "type": "tfc:climate", "min_temperature": 5, "max_temperature": 30,
      "min_groundwater": 150, "max_groundwater": 450, "min_forest": 2 },
    { "type": "minecraft:rarity_filter", "chance": 5 }
  ]
}
```

| 字段 | 类型 | 必需 | 说明 |
| --- | --- | --- | --- |
| `feature` | `ResourceLocation` | 必需 | 指向 `configured_feature`；此处 `firmalife:beehive` 是 `FLFeatures.BEEHIVE`（`NoneFeatureConfiguration`） |
| `placement` | 放置修饰符数组 | 必需 | 顺序执行；示例用了原版 `heightmap`、`in_square`、`rarity_filter` 与 **TFC 自定义**的 `tfc:climate`（`min_temperature`/`max_temperature`/`min_groundwater`/`max_groundwater`/`min_forest`） |
| `__comment__` | string | 可选 | 仅注释，`minifyJson` 任务会删除 |

目录结构：`worldgen/configured_feature/{plant,vein}/**`、`worldgen/placed_feature/{plant,vein}/**`；向 TFC 世界生成标签注入的路径是 `data/tfc/tags/worldgen/placed_feature/feature/*.json` 与 `.../in_biome/*.json`。

### 4.8 标签（tag）命名规律与示例

| 命名空间 | 路径 | 规律 |
| --- | --- | --- |
| `firmalife` | `data/firmalife/tags/{block,item,fluid,entity_type}/**` | 与 `FLTags` 中的常量一一对应；分层用 `/`，例如 `ores/chromite/poor`、`foods/cheeses`、`wood/keg` 相关用 `kegs`/`stomping_barrels`/`barrel_presses` |
| `firmalife` | `data/firmalife/tags/tfc/food_trait/*` | 针对 **TFC 自定义 registry** `tfc:food_trait` 的标签（见 §4.3 末） |
| `tfc` | `data/tfc/tags/{block,item,fluid}/**` | Firmalife 向 TFC 标签**追加**自己的条目，例如 `data/tfc/tags/item/compost_greens.json` |
| `c` | `data/c/tags/{block,item,fluid}/**` | 通用（Convention）标签：`ores/*`、`ingots/*`、`double_ingots/*`、`sheets/*`、`double_sheets/*`、`rods/*`、`foods/*`、`molten_*` |
| `minecraft` | `data/minecraft/tags/{block,item,damage_type}/**` | 原版标签：`mineable/*`、`climbable`、`doors`、`leaves`、`slabs`、`stairs`、`trapdoors`、`walls`、`flower_pots`、`damage_type/bypasses_*` |

`data/tfc/tags/item/compost_greens.json` 全文（向 TFC 标签追加的典型形式）：

```json
{
  "values": [
    "firmalife:food/nightshade_berry",
    "firmalife:blue_mold"
  ]
}
```

标签 JSON 的字段（原版约定）：

| 字段 | 类型 | 必需 | 说明 |
| --- | --- | --- | --- |
| `values` | 字符串数组 | 必需 | 条目；`"#namespace:path"` 表示引用另一个标签，`"!x"` 表示排除（原版 1.21 用 `{"id": "...", "required": false}` 形式表达可选） |
| `replace` | boolean | 可选（默认 `false`） | `true` 时替换而非合并该标签 |

### 4.9 datagen Provider 清单与生成顺序

`src/data/java/com/eerussianguy/firmalife/providers/`（14 个文件）：

| Provider | 基类/接口 | 生成的目录 |
| --- | --- | --- |
| `DataManagerProvider<T>` | `net.minecraft.data.DataProvider`（抽象） | 由 `domain + "/" + manager.getName()` 决定 |
| `BuiltinBlockLootTables` | `BlockLootSubProvider` + `Accessors`；内部 `PartialProvider implements LootTableSubProvider` | `data/firmalife/loot_table/blocks/**` |
| `BuiltinBlockTags` | `TagsProvider<Block>` | `data/firmalife/tags/block/**` |
| `BuiltinClimateRanges` | `DataManagerProvider<ClimateRange>` | `data/firmalife/tfc/climate_range/**` |
| `BuiltinDamageTypes` | 普通类（由 `RegistrySetBuilder::add` 调用） | `data/firmalife/damage_type/*` |
| `BuiltinEntityTypeTags` | `TagsProvider<EntityType<?>>` | `data/firmalife/tags/entity_type/**` |
| `BuiltinFluidHeats` | `DataManagerProvider<FluidHeat>` | `data/firmalife/tfc/fluid_heat/*` |
| `BuiltinFluidTags` | `TagsProvider<Fluid>` | `data/firmalife/tags/fluid/**` |
| `BuiltinFoods` | `DataManagerProvider<FoodDefinition>` | `data/firmalife/tfc/food/**` |
| `BuiltinItemHeat` | `DataManagerProvider<HeatDefinition>` | `data/firmalife/tfc/item_heat/**`；向 `BuiltinRecipes` 暴露 `meltingRecipes` |
| `BuiltinItemSizes` | `DataManagerProvider<ItemSizeDefinition>` | `data/firmalife/tfc/item_size/*` |
| `BuiltinItemTags` | `TagsProvider<Item>` | `data/firmalife/tags/item/**`（并追加 `data/tfc`、`data/c`、`data/minecraft`） |
| `BuiltinLootModifiers` | `GlobalLootModifierProvider` | `data/firmalife/loot_modifiers/*` + `data/neoforge/loot_modifiers/global_loot_modifiers.json` |
| `BuiltinPlantables` | `DataManagerProvider<Plantable>` | `data/firmalife/firmalife/plantable/*` |
| `BuiltinRecipes` | `RecipeProvider` + `Recipes` + 21 个配方接口 | `data/firmalife/recipe/**` + `data/tfc/recipe/**`（删除占位） |

`BuiltinRecipes` 的接口组合（`src/data/java/com/eerussianguy/firmalife/providers/BuiltinRecipes.java` L48-69）：

```java
public class BuiltinRecipes extends RecipeProvider implements Recipes,
    AlloyRecipes, AnvilRecipes, BarrelRecipes, CastingRecipes, CentrifugeRecipes, ChiselRecipes,
    CollapseRecipes, CraftingRecipes, DryingRecipes, GlassworkingRecipes, HeatingRecipes,
    KnappingRecipes, LoomRecipes, MixingBowlRecipes, OvenRecipes, PotRecipes, QuernRecipes,
    SmokingRecipes, StompingRecipes, VatRecipes, WeldingRecipes
```

**用 Firmalife 材料生成 TFC 配方** 的映射（`buildRecipes` 中的调用 → `src/data/java/.../recipes/` 下的接口）：

| TFC 配方类型 | 调用方法 | 接口 | Firmalife 输出目录 |
| --- | --- | --- | --- |
| `tfc:alloy` | `alloyRecipes()` | `AlloyRecipes` | `recipe/alloy/*` |
| `tfc:anvil` | `anvilRecipes()` | `AnvilRecipes` | `recipe/anvil/**` |
| `tfc:barrel_instant` / `barrel_instant_fluid` / `barrel_sealed` | `barrelRecipes()` | `BarrelRecipes` | `recipe/barrel_instant/*`、`recipe/barrel_instant_fluid/*`、`recipe/barrel_sealed/**` |
| `tfc:casting` | `castingRecipes()` | `CastingRecipes` | `recipe/casting/ceramic/**` |
| `tfc:chisel` | `chiselRecipes()` | `ChiselRecipes` | `recipe/chisel/*` |
| `tfc:collapse` | `collapseRecipes()` | `CollapseRecipes` | `recipe/collapse/rock/cobble/*` |
| `tfc:crafting` | `craftingRecipes()` | `CraftingRecipes` | `recipe/crafting/**` |
| `tfc:glassworking` | `glassworkingRecipes()` | `GlassworkingRecipes` | `recipe/glassworking/*` |
| `tfc:heating` | `heatingRecipes()` | `HeatingRecipes` | `recipe/heating/**` |
| `tfc:knapping` | `knappingRecipes()` | `KnappingRecipes` | `recipe/knapping/**` |
| `tfc:loom` | `loomRecipes()` | `LoomRecipes` | `recipe/loom/*` |
| `tfc:welding` | `weldingRecipes()` | `WeldingRecipes` | `recipe/welding/metal/**` |
| `tfc:quern` | `quernRecipes()` | `QuernRecipes` | `recipe/quern/**` |
| `tfc:pot` | `potRecipes()` | `PotRecipes` | `recipe/pot/**` |
| `firmalife:centrifuge` | `centrifugeRecipes()` | `CentrifugeRecipes` | `recipe/centrifuge/**` |

**自动推导**：`item_heat` + `fluid_heat` 会自动推导出 TFC 熔化加热配方（`BuiltinRecipes.java` L132-141）：

```java
for (BuiltinItemHeat.MeltingRecipe melt : meltingRecipes)
{
    add(nameOf(melt.item()), new HeatingRecipe(
        Ingredient.of(melt.item()), ItemStackProvider.empty(),
        new FluidStack(fluidOf(melt.metal()), melt.units()), temperatureOf(melt.metal()), false));
}
```

datagen 依赖顺序（有显式 `CompletableFuture` 链）：

```
DatapackBuiltinEntriesProvider(damage_type)
  → BuiltinBlockTags → BuiltinItemTags
  → BuiltinEntityTypeTags、BuiltinFluidTags
  → 匿名 TagsProvider(damage_type)、匿名 TagsProvider(food_trait)
  → BuiltinLootModifiers、BuiltinClimateRanges、BuiltinPlantables、BuiltinFoods、BuiltinItemSizes
  → 匿名 LampFuel / Drinkable / GreenhouseType / KnappingType provider
  → BuiltinFluidHeats → BuiltinItemHeat（依赖 fluidHeat）
  → BuiltinRecipes（依赖 fluidHeat + itemHeat 的 contentDone）
  → LootTableProvider(BuiltinBlockLootTables, BuiltinBlockLootTables.PartialProvider)
```

此外 datagen 输出会被 `minifyJson` 任务压缩，并删除 `"__comment__":"This file was automatically created by mcresources"`（`build.gradle.kts` L171-216）。


## 5. 注册清单：配方类型 / 方块实体 / 菜单 / GUI / 主要机制

> 本章所有「注册名」的命名空间均为 `firmalife`（除特别标注）。

### 5.1 配方类型与序列化器

来源：`src/main/java/com/eerussianguy/firmalife/common/recipes/FLRecipeTypes.java`、`FLRecipeSerializers.java`。

**关键事实：一共注册 8 个 `RecipeType`，但有 10 个 `RecipeSerializer`。**

| 类名（`common.recipes.X`） | RecipeType | Serializer | 基类 / 接口 | 输入类型 | 说明 |
| --- | --- | --- | --- | --- | --- |
| `DryingRecipe` | `firmalife:drying` | `firmalife:drying` | `extends ItemRecipe`（`INoopInputRecipe` + `IRecipePredicate<ItemStack>`） | `ItemStack` | 晾晒垫 / 太阳能干燥器；JSON 字段 `ingredient`、`result` |
| `SmokingRecipe` | `firmalife:smoking` | `firmalife:smoking` | `extends ItemRecipe` | `ItemStack` | 毛线/菠萝线挂在火坑上烟熏；同字段 |
| `StompingRecipe` | `firmalife:stomping` | `firmalife:stomping` | `extends ItemRecipe` | `ItemStack` | 踩踏木桶；额外字段 `input_texture`、`output_texture`、`sound` |
| `PressRecipe` | `firmalife:press` | `firmalife:press` | `extends StompingRecipe` | `ItemStack` | 木桶压榨机；用独立的 `P_CODEC` / `P_STREAM_CODEC` 与独立 `PRESS_CACHE`。**源码内没有任何 datagen 生成 press 配方** |
| `CentrifugeRecipe` | `firmalife:centrifuge` | `firmalife:centrifuge` | `extends ItemRecipe` | `ItemStack` | 离心机；字段 `ingredient`、`result` |
| `OvenRecipe` | `firmalife:oven` | `firmalife:oven` | `implements INoopInputRecipe, IRecipePredicate<ItemStack>` | `ItemStack` | 烤炉；字段 `ingredient`、`result`、`temperature`(float)、`duration`(int) |
| `MixingBowlRecipe` | `firmalife:mixing_bowl` | `firmalife:mixing_bowl` | `implements ISimpleRecipe<MixingBowlBlockEntity.MixingBowlInventory>` | `MixingBowlInventory`（5 物品槽 + 1 流体罐） | 字段 `item_ingredients`(List\<Ingredient\>)、`fluid_ingredients`(可选 `SizedFluidIngredient`)、`result_item`(可选)、`result_fluid`(可选) |
| `VatRecipe` | `firmalife:vat` | `firmalife:vat` | `implements ISimpleRecipe<VatBlockEntity.VatInventory>` | `VatInventory`（1 物品槽 + 10000 mB） | 字段 `input_item`、`input_fluid`、`output_item`(可选)、`output_fluid`(可选)、`length`(int)、`temperature`(float)、`jar_output`(可选)、`output_texture`(可选) |
| `StinkySoupRecipe` | **无独立类型**（走 TFC `tfc:pot`） | `firmalife:stinky_soup` | `extends PotRecipe` | `IPotInventory` | 注册的是 serializer + `PotOutput.OutputType` `firmalife:stinky_soup` |
| `BowlPotRecipe` | **无独立类型**（走 TFC `tfc:pot`） | `firmalife:bowl_pot` | `extends PotRecipe` | `IPotInventory` | 注册 serializer + `PotOutput.OutputType` `firmalife:bowl` |
| `KegRecipe` | **无（纯工具类）** | 无 | 静态工具类（无 `Recipe` 实现） | `BarrelInventory` | 复用 TFC 的 `tfc:barrel_instant` / `tfc:barrel_instant_fluid` / `tfc:barrel_sealed` |
| `WrappedHeatingRecipe` | **无（record 适配器）** | 无 | `record WrappedHeatingRecipe(Function<ItemStack,ItemStack> output, float temperature, int duration, boolean oven)` | `ItemStack` | 统一 `OvenRecipe` 与 TFC `HeatingRecipe`，供炉顶使用 |

`PotOutput.OutputType` 注册（`FLRecipeTypes.java` L29-30）：

```java
public static final DeferredHolder<PotOutput.OutputType, PotOutput.OutputType> STINKY_SOUP =
    POT_OUTPUT_TYPE.register("stinky_soup", () -> StinkySoupRecipe.OUTPUT_TYPE);
public static final DeferredHolder<PotOutput.OutputType, PotOutput.OutputType> BOWL =
    POT_OUTPUT_TYPE.register("bowl", () -> BowlPotRecipe.OUTPUT_TYPE);
```

TFC 侧 `PotOutput` 的 registry key 与 `DeferredRegister`（`javap`）：

```java
public interface PotOutput
{
    ResourceKey<Registry<PotOutput.OutputType>> KEY;
    ResourceKey<PotOutput.OutputType> DEFAULT;
    DefaultedRegistry<PotOutput.OutputType> REGISTRY;
    DeferredRegister<PotOutput.OutputType> TYPES;      // Firmalife 用 PotOutput.KEY 自建 DR
    PotOutput EMPTY_INSTANCE;
    DeferredHolder<PotOutput.OutputType, PotOutput.OutputType> EMPTY, SOUP, JAM;
    ...
}
```

### 5.2 方块实体（42 个注册项）

来源：`common/blockentities/FLBlockEntities.java`。

| 注册名 | BE 类 | 关联方块 | 继承 / 接口要点 | Ticker |
| --- | --- | --- | --- | --- |
| `tick_counter` | `FLTickCounterBlockEntity` | 7 种奶酪轮 + 全部 `JACK_O_LANTERNS` | `extends TickCounterBlockEntity`（TFC） | 由方块驱动 |
| `ticking_plant` | `FLTickingPlantBlockEntity` | `FRUIT_TREE_SAPLINGS`、`FRUIT_TREE_GROWING_BRANCHES` | `extends TickingPlantBlockEntity`（TFC） | 是 |
| `oven_bottom` | `OvenBottomBlockEntity` | `CLAY_OVEN_BOTTOM` + `CURED_OVEN_BOTTOM` + `INSULATED_OVEN_BOTTOM` | `extends TickableInventoryBlockEntity<ItemStackHandler> implements ICalendarTickable, OvenLike` | `serverTick` |
| `oven_top` | `OvenTopBlockEntity` | `CLAY_OVEN_TOP` + `INSULATED_OVEN_TOP` + `CURED_OVEN_TOP` | `extends ApplianceBlockEntity<ApplianceInventory> implements ICalendarTickable, OvenLike` | 是 |
| `oven_hopper` | `OvenHopperBlockEntity` | `CLAY_OVEN_HOPPER` + `CURED_OVEN_HOPPER` | `extends TickableInventoryBlockEntity<ItemStackHandler>` | `serverTick` |
| `drying_mat` | `DryingMatBlockEntity` | `DRYING_MAT` | `extends SimpleItemRecipeBlockEntity<DryingRecipe>` | `serverTick` |
| `solar_drier` | `DryingMatBlockEntity` | `SOLAR_DRIER` | 同上（静态工厂 `solarDrier`） | `serverTick` |
| `beehive` | `WoodenBeehiveBlockEntity` | `BEEHIVE` | `extends FLBeehiveBlockEntity` | 是 |
| `skep` | `SkepBlockEntity` | `SKEP` | `extends FLBeehiveBlockEntity` | 是 |
| `centrifuge` | `CentrifugeBlockEntity` | `CENTRIFUGE` | `extends TickableInventoryBlockEntity<ItemStackHandler> implements RotationSinkBlockEntity`（TFC 旋转） | `serverTick` + `clientTick` |
| `compost_tumbler` | `CompostTumblerBlockEntity` | `COMPOST_TUMBLER` | 同上，`implements RotationSinkBlockEntity` | `serverTick` |
| `string` | `StringBlockEntity` | `WOOL_STRING`、`PINEAPPLE_YARN` | `extends SimpleItemRecipeBlockEntity<SmokingRecipe>` | `serverTick` |
| `mixing_bowl` | `MixingBowlBlockEntity` | `MIXING_BOWL` | `extends TickableInventoryBlockEntity<MixingBowlInventory>` | `serverTick` + `clientTick` |
| `berry_bush` | `FLBerryBushBlockEntity` | `FRUIT_TREE_LEAVES`、`STATIONARY_BUSHES` | `extends BerryBushBlockEntity`（TFC） | 继承 |
| `food_shelf` | `FoodShelfBlockEntity` | `FOOD_SHELVES.values()` | `extends InventoryBlockEntity<ItemStackHandler> implements ClimateReceiver` | 否 |
| `hanger` | `HangerBlockEntity` | `HANGERS.values()` | `extends FoodShelfBlockEntity`（HUNG 系列 trait） | 否 |
| `jarbnet` | `JarbnetBlockEntity` | `JARBNETS.values()`（6 槽） | `extends InventoryBlockEntity<ItemStackHandler>` | 否 |
| `keg` | `KegBlockEntity` | `KEGS.values()` | `extends TickableInventoryBlockEntity<KegInventory> implements BarrelInventoryCallback, IRecipeTimer, ICalendarTickable`；`SLOTS=38`、`CAPACITY=80000` | `serverTick` |
| `keg_sub` | `KegSubBlockEntity` | `KEG_SUBS.values()` | `extends TFCBlockEntity`（把能力代理到核心） | 否 |
| `wine_shelf` | `WineShelfBlockEntity` | `WINE_SHELVES.values()`（4 槽） | `extends InventoryBlockEntity<ItemStackHandler>` | 否 |
| `stomping_barrel` | `StompingBarrelBlockEntity` | `STOMPING_BARRELS.values()`；`MAX_GRAPES=16` | `extends InventoryBlockEntity<ItemStackHandler>` | 实体踩踏触发 |
| `barrel_press` | `BarrelPressBlockEntity` | `BARREL_PRESSES.values()`；`SLOTS=9`、`TIME=40L` | `extends TickableInventoryBlockEntity<ItemStackHandler>` | `tick` |
| `vat` | `VatBlockEntity` | `VAT`；`CAPACITY=10_000` | `extends BoilingBlockEntity<VatInventory>` | `serverTick` |
| `ashtray` | `AshTrayBlockEntity` | `ASHTRAY` | `extends InventoryBlockEntity<ItemStackHandler>`（1 槽 ×16，仅木灰） | 否 |
| `stovetop_grill` | `StovetopGrillBlockEntity` | `STOVETOP_GRILL`；`SLOTS=5` | `extends ApplianceBlockEntity<GrillInventory>` | `serverTick` |
| `stovetop_pot` | `StovetopPotBlockEntity` | `STOVETOP_POT`；`SLOTS=5`、`DURATION=1000` | `extends BoilingBlockEntity<StovetopPotInventory>`；`StovetopPotInventory implements IPotInventory` | `serverTick` |
| `jarring_station` | `JarringStationBlockEntity` | `JARRING_STATION`；`SLOTS=9` | `extends TickableInventoryBlockEntity<ItemStackHandler>` | `tick` |
| `plate` | `PlateBlockEntity` | `PLATE` | `extends InventoryBlockEntity<ItemStackHandler>` | 否 |
| `grape_plant` | `GrapePlantBlockEntity` | `GRAPE_STRING_PLANT_RED`、`GRAPE_STRING_PLANT_WHITE` | `extends TickableBlockEntity implements ICalendarTickable` | `serverTick` |
| `large_planter` | `LargePlanterBlockEntity` | `LARGE_PLANTER` | `extends TickableInventoryBlockEntity<ItemStackHandler> implements ICalendarTickable, ClimateReceiver, IFarmland`（**同时实现 TFC 耕地接口，复用 TFC 营养系统**） | `serverTick` |
| `bonsai_planter` | `BonsaiPlanterBlockEntity` | `BONSAI_PLANTER` | `extends LargePlanterBlockEntity` | 是 |
| `hanging_planter` | `HangingPlanterBlockEntity` | `HANGING_PLANTER` | `extends LargePlanterBlockEntity` | 是 |
| `quad_planter` | `QuadPlanterBlockEntity` | `QUAD_PLANTER` | `extends LargePlanterBlockEntity`（4 槽） | 是 |
| `hydroponic_planter` | `HydroponicPlanterBlockEntity` | `HYDROPONIC_PLANTER` | `extends QuadPlanterBlockEntity` | `hydroponicServerTick` |
| `trellis_planter` | `TrellisPlanterBlockEntity` | `TRELLIS_PLANTER` | `extends LargePlanterBlockEntity` | 是 |
| `climate_station` | `ClimateStationBlockEntity` | `CLIMATE_STATION` | `extends TFCBlockEntity` | 否 |
| `sprinkler` | `SprinklerBlockEntity` | `SPRINKLER`、`FLOOR_SPRINKLER`；`MAX_COST=32` | `extends TFCBlockEntity implements FluidTankCallback, ClimateReceiver` | `serverTick` |
| `pumping_station` | `PumpingStationBlockEntity` | `PUMPING_STATION` | `extends TFCBlockEntity implements RotationSinkBlockEntity` | 否 |
| `picker` | `PickerBlockEntity` | `PICKER` | `extends TickableBlockEntity` | `tick` |
| `sweeper` | `SweeperBlockEntity` | `SWEEPER` | `extends TickableBlockEntity implements RotationSinkBlockEntity` | `serverTick` |

**未注册的抽象/接口 BE（可复用基类）**：

| 类名 | 形态 | 说明 |
| --- | --- | --- |
| `ApplianceBlockEntity<C extends IItemHandlerModifiable & INBTSerializable<CompoundTag> & IHeatConsumer>` | `public abstract class extends TickableInventoryBlockEntity<C> implements ICalendarTickable` | 带热量模拟的「器具」基类；提供 `getSyncableData()`、`tickTemperature()`、`onTemperatureAdjusted()`、`advanceForCalendar(long)`；嵌套 `public static class ApplianceInventory implements IHeatConsumer, DelegateItemHandler, INBTSerializable<CompoundTag>, CrucibleLikeHeatBlock` |
| `BoilingBlockEntity<C extends ... & IFluidHandler>` | `public abstract class extends ApplianceBlockEntity<C> implements ICalendarTickable, FluidTankCallback` | 增加「沸腾」语义：`abstract boolean isBoiling()`；嵌套 `public static class BoilingInventory extends ApplianceInventory implements DelegateFluidHandler, FluidTankCallback`（沸腾时 `extractItem` 返回空） |
| `SimpleItemRecipeBlockEntity<T extends ItemRecipe>` | `public abstract class extends InventoryBlockEntity<ItemStackHandler>` | 「单物品 + 单配方」基类，`DryingMatBlockEntity` 与 `StringBlockEntity` 都继承它；**附属模组新增类似机器时首选继承这个** |
| `OvenLike` | `public interface` | `static void regularBlockUpdate(Level, BlockPos, BlockState, OvenLike, boolean cured, int updateInterval)`；`float getTemperature()`、`int getCureTicks()`、`void addCureTicks(int)` |
| `ClimateReceiver` | `public interface` | `static ClimateReceiver get(Level, BlockPos)`；`default boolean addWater(float)`、`default boolean addWater(float, Direction)`（默认 false）、`void setValid(Level, BlockPos, boolean valid, int tier, ClimateType climate)`、`default void findClimateStation(Level, BlockPos)`（通过 POI `firmalife:climate_stations` 搜索） |
| `ClimateType` | `public enum` | `GREENHOUSE`、`CELLAR`；`static ClimateType byId(int)`（越界回退 `GREENHOUSE`） |
| `CrucibleLikeHeatBlock` | `public interface extends IHeatConsumer` | `void setTargetTemperature(float)`、`float getTargetTemperature()`、`void resetStability()`、`default void setTemperature(float)`、`default void setTemperatureIfWarmer(float)` |

来源：`common/blockentities/OvenLike.java`、`ClimateReceiver.java`、`SimpleItemRecipeBlockEntity.java`、`ApplianceBlockEntity.java`、`BoilingBlockEntity.java`。

### 5.3 菜单（Menu / Container）与 GUI 屏幕

来源：`common/container/FLMenuTypes.java`、`common/container/*.java`、`client/screen/*.java`。4 个菜单**全部**通过 `RegistrationHelpers.registerBlockEntityContainer(...)` 注册，即都是 `BlockEntityContainer<T>` 子类。

| 菜单注册名 | 绑定 BE | Container 类 | 创建方法 | Screen 类 |
| --- | --- | --- | --- | --- |
| `firmalife:stovetop_grill` | `FLBlockEntities.STOVETOP_GRILL` | `StovetopGrillContainer` | `static StovetopGrillContainer create(StovetopGrillBlockEntity, Inventory, int)` | `client.screen.StovetopGrillScreen`（含温度条） |
| `firmalife:stovetop_pot` | `FLBlockEntities.STOVETOP_POT` | `StovetopPotContainer` | `static StovetopPotContainer create(StovetopPotBlockEntity, Inventory, int)` | `client.screen.StovetopPotScreen`（温度 + 流体 + 锅输出贴图） |
| `firmalife:keg` | `FLBlockEntities.KEG` | `KegContainer implements ButtonHandlerContainer` | `static KegContainer create(KegBlockEntity, Inventory, int)`（`init(playerInv, 76)`） | `client.screen.KegScreen` + `client.screen.KegSealButton` |
| `firmalife:barrel_press` | `FLBlockEntities.BARREL_PRESS` | `BarrelPressContainer` | `static BarrelPressContainer create(BarrelPressBlockEntity, Inventory, int)` | `client.screen.BarrelPressScreen` |

Screen 在客户端 `RegisterMenuScreensEvent` 里绑定（`client/FLClientEvents.java` L198-204）：

```java
public static void onMenuRegister(RegisterMenuScreensEvent event)
{
    event.register(FLMenuTypes.BARREL_PRESS.get(), BarrelPressScreen::new);
    event.register(FLMenuTypes.STOVETOP_GRILL.get(), StovetopGrillScreen::new);
    event.register(FLMenuTypes.STOVETOP_POT.get(), StovetopPotScreen::new);
    event.register(FLMenuTypes.KEG.get(), KegScreen::new);
}
```

所有 Screen 都继承 TFC 的 `BlockEntityScreen<T extends BlockEntity, C extends BlockEntityContainer<T>>`，底图用 `FLHelpers.identifier("textures/gui/xxx.png")`：

```java
public class BarrelPressScreen extends BlockEntityScreen<BarrelPressBlockEntity, BarrelPressContainer>
{
    private static final ResourceLocation TEXTURE = FLHelpers.identifier("textures/gui/barrel_press.png");

    public BarrelPressScreen(BarrelPressContainer container, Inventory playerInventory, Component name)
    {
        super(container, playerInventory, name, TEXTURE);
    }
}
```

来源：`client/screen/BarrelPressScreen.java` L17-24。

### 5.4 GUI / 模型 / 渲染注册（客户端）

| 注册点 | 内容 | 来源 |
| --- | --- | --- |
| `RegisterMenuScreensEvent` | 4 个 Screen（见上） | `client/FLClientEvents.java` L198-204 |
| `EntityRenderersEvent.RegisterRenderers` | 17 个 `BlockEntityRenderer`（`OVEN_TOP`、`DRYING_MAT`、`SOLAR_DRIER`、`STRING`、`VAT`、`MIXING_BOWL`、`STOVETOP_GRILL`、`STOVETOP_POT`、`PLATE`、`HYDROPONIC_PLANTER`、`COMPOST_TUMBLER`、`STOMPING_BARREL`、`BARREL_PRESS`、`PUMPING_STATION`、`PICKER`、`SWEEPER`、`CENTRIFUGE`）+ `FLEntities.FLBEE` → `FLBeeRenderer` | `FLClientEvents.java` L297-317 |
| `EntityRenderersEvent.RegisterLayerDefinitions` | `PeelModel` 层（`FLClientHelpers.modelIdentifier("peel")`） | `FLClientEvents.java` L320-323 |
| `RegisterColorHandlersEvent.Item` | `DynamicFluidContainerModel.Colors()` 应用到所有流体桶 + `HOLLOW_SHELL` + `WINE_GLASS` | `FLClientEvents.java` L206-219 |
| `RegisterParticleProvidersEvent` | `FLParticles.GROWTH`（`GlintParticleProvider`，绿色）、`FLParticles.SPRINKLER`（`SprinklerParticle`） | `FLClientEvents.java` L221-225 |
| `ModelEvent.RegisterAdditional` | 独立的动态模型：全部 `block/jar/<fruit>[_unsealed]`、`block/jar/{compost,rotten_compost,guano,honey}`、`block/beehive_frame`、`block/filled_beehive_frame`、全部酒瓶模型、以及各 Renderer 的静态模型（`MixingBowlBlockEntityRenderer.SPOON_LOCATION`、`BarrelPressBlockEntityRenderer.PRESS` 等） | `FLClientEvents.java` L227-262 |
| `ModelEvent.RegisterGeometryLoaders` | 16 个自定义 `IGeometryLoader`：`large_planter`、`hanging_planter`、`bonsai_planter`、`quad_planter`、`hydroponic_planter`、`trellis_planter`（`DynamicBlockModel.Loader`）、`jarbnet`、`jarring_station`、`food_shelf`、`hanger`、`wine_shelf`、`beehive`（`InventoryBlockModel.Loader`）、`greenhouse_panel_wall`、`greenhouse_panel_roof`（`GreenhouseBlockModel.Loader`） | `FLClientEvents.java` L265-286 |
| `RegisterClientExtensionsEvent` | `PeelItem.Extension.INSTANCE` → `FLItems.PEEL`；全部金属/额外/酒流体的 `IClientFluidTypeExtensions` | `FLClientEvents.java` L325-338 |
| `FMLClientSetupEvent` | `ItemBlockRenderTypes.setRenderLayer(...)`（cutout/translucent，对所有温室方块与 `BARREL_PRESSES` 等） | `FLClientEvents.java` L111-195 |

### 5.5 主要机制 → 核心类对照（检索用）

| 机制 | 核心类 | 关键说明 |
| --- | --- | --- |
| 温室 | `blocks/greenhouse/Greenhouse.java`（9 材质 × 8 `BlockType`）、`GreenhouseType`（数据驱动 tier）、`ClimateStationBlockEntity`、`Mechanics.getGreenhouse(...)`、`LargePlanterBlockEntity` | 温室有效性 = 用 `Mechanics.floodfill` 从结构内部泛洪填充，墙体由 `GreenhouseConnectable` + `FLTags.Blocks.*_GREENHOUSE` 判定；`GreenhouseType` 提供 `tier` |
| 地窖 | `Mechanics.getCellar(...)`、`ClimateType.CELLAR`、`FLTags.Blocks.CELLAR_INSULATION`、`FLServerConfig.cellarLevel2Temperature/Level3Temperature` | 用 `SEALED_BRICKS` 系列 + `Mechanics.CELLAR` 谓词；温度分级影响食物保存 |
| 酒桶（Keg） | `KegCoreBlock` + `KegSubBlock`（2×2×2 多方块，`BARREL_PART` 1..7）、`KegBlockEntity`、`KegSubBlockEntity`、`KegRecipe`（工具类）、`KegContainer`、`KegScreen`、`KegSealButton` | 复用 TFC 木桶配方；`CAPACITY=80000`、`SLOTS=38`；密封状态由 `KegCoreBlock.toggleSeal` 切换 |
| 木桶压榨机 | `BarrelPressBlock`、`BarrelPressBlockEntity`（`WineOutput` 记录）、`PressRecipe`、`BarrelPressContainer`、`BarrelPressScreen` | 5 个葡萄槽 + 酒瓶入/出 + 软木塞 + 标签；`TIME=40L` |
| 踩踏木桶 | `StompingBarrelBlock`、`StompingBarrelBlockEntity`、`StompingRecipe` | 实体踩踏触发；`MAX_GRAPES=16` |
| 烤箱 | `blocks/oven/` 下 `AbstractOvenBlock`、`OvenBottomBlock`、`OvenTopBlock`、`OvenChimneyBlock`、`OvenHopperBlock`、`InsulatedOven*Block`、`AshtrayBlock`、`StovetopGrillBlock`、`StovetopPotBlock`、`VatBlock`、`OvenType`、`ICure`；BE：`OvenBottomBlockEntity`、`OvenTopBlockEntity`、`OvenHopperBlockEntity`、`AshTrayBlockEntity` | `OvenType = {BRICK, RUSTIC, TILE, STONE}`；黏土炉通过 `ICure` 固化为 `BRICK` 变体；`OvenLike.regularBlockUpdate` 处理烟囱检测与 cure |
| 炉灶 | `StovetopGrillBlockEntity`、`StovetopPotBlockEntity`（`implements IPotInventory`）、`StovetopGrillContainer`、`StovetopPotContainer`、两个 Screen | 由 `FLInteractionManager` 把 TFC 烤架/锅放到烤箱底上自动生成 |
| 酒与葡萄 | `blocks/plant/` 下 `GrapeFluffBlock`、`GrapeStringBlock`、`GrapeStringWithPlantBlock`、`GrapeTrellisPostBlock`、`GrapeTrellisPostWithPlantBlock`、`GrapeGroundPlantOnStringBlock`、`IGrape`；`GrapePlantBlockEntity`；`capabilities/wine/WineType`、`WineComponent`；`WineBottleItem`、`FilledWineBottleItem`、`WineGlassItem`、`WineShelfBlockEntity` | `WineType = {RED, WHITE, ROSE, SPARKLING, DESSERT}`；`WineComponent` 记录 `creation_date`/`open_date`/`label_text`/`wine`/`climate`/`traits` |
| 养蜂 | `blocks/bee/`（`BaseBeehiveBlock`、`WoodenBeehiveBlock`、`SkepBlock`、`WildBeehiveBlock`、`CentrifugeBlock`）、`FLBeehiveBlockEntity`（685 行）、`SkepBlockEntity`、`WoodenBeehiveBlockEntity`、`entities/FLBee`、`capabilities/bee/*` | `BeeAbility`/`BeeSpecies`（11 种）/`GeneticDisease`/`ParasiticInfection`；区域扫描（±5 格）、分蜂、蜂种加权随机 |
| 种植盆 | `PlanterType = {QUAD, LARGE, HANGING, TRELLIS, BONSAI, HYDROPONIC}`；`LargePlanterBlockEntity` + 5 个子类；`Plantable`（数据驱动） | `Plantable` 的 `planter` 字段决定该作物能种在哪种盆里；`planter` 与 `tier` 影响可用性 |
| 灌溉 | `PumpingStationBlock`/`PumpingStationBlockEntity`、`SprinklerBlock`/`FloorSprinklerBlock`/`SprinklerBlockEntity`、`SprinklerPipeBlock`、`AbstractSprinklerBlock`、`SprinklerItem` | `SprinklerBlockEntity.searchForFluid` 沿管道 BFS 找水源（`MAX_COST=32`） |
| 采摘/清扫 | `PickerBlock`/`PickerBlockEntity`（向下取成熟作物）、`SweeperBlock`/`SweeperBlockEntity`（按旋转角扫 8 向的 `LargePlanterBlockEntity`） | 两者都可用于温室自动化 |
| 奶酪 | `CheeseWheelBlock`（7 种）、`FLTickCounterBlockEntity`（`tick_counter`）、`FoodAge = {FRESH, AGED, VINTAGE}`、`FLConfig.SERVER.cheeseAgedDays/cheeseVintageDays` | 奶酪轮以方块形式存在，靠 tick counter 记录陈化时间 |
| 食物保存 | `FoodShelfBlockEntity`（`SHELVED`/`SHELVED_2`/`SHELVED_3`）、`HangerBlockEntity`（`HUNG`/`HUNG_2`/`HUNG_3`）、`JarbnetBlockEntity`、`WineShelfBlockEntity`、`PlateBlockEntity` | 保存效果通过 `FoodTrait` 的 `Supplier<Float>` modifier 实现（见 §3.6） |
| 堆肥 | `CompostTumblerBlock`/`CompostTumblerBlockEntity`（`AdditionType`、`Compost` 记录）、`FLServerConfig.compostTumblerTicks` | 也可仅靠红石（`mechanicalPowerCheatMode`） |


## 6. 公开 API、扩展点与「如何新写一个 Firmalife 风格配方」

### 6.1 可复用的公开 API 一览

| 类型 | 全限定名 | 形态 | 关键 public 成员 |
| --- | --- | --- | --- |
| 配方基类（物品→物品） | `net.dries007.tfc.common.recipes.ItemRecipe` | `public abstract class implements INoopInputRecipe, IRecipePredicate<ItemStack>` | 字段 `protected final Ingredient ingredient`、`protected final ItemStackProvider result`；`assembleItem(ItemStack)`、`getValidItems()`、`matches(ItemStack)` |
| 配方基类（方块→方块） | `net.dries007.tfc.common.recipes.BlockRecipe` | `public abstract class implements INoopInputRecipe, IRecipePredicate<BlockState>` | 静态工厂 `codec`/`streamCodec`/`serializer`（TFC 的 `CollapseRecipe` 是范例） |
| 配方接口（自定义容器） | `net.dries007.tfc.common.recipes.ISimpleRecipe<C extends RecipeInput>` | `public interface extends Recipe<C>` | `boolean matches(C, Level)`、`ItemStack assemble(C, HolderLookup.Provider)`、`ItemStack getResultItem(HolderLookup.Provider)`（后两者为 `Recipe` 的抽象方法） |
| 配方接口（无输入） | `net.dries007.tfc.common.recipes.INoopInputRecipe` | `public interface extends ISimpleRecipe<NoopInput>` | 4 个静态工具：`getRecipe(IndirectHashCollection, C, K)`、`getRecipe(Collection, C)`、`getHolder(Level, Supplier<RecipeType<R>>, C)`、`getHolder(RecipeManager, ...)` |
| 配方谓词 | `net.dries007.tfc.common.recipes.IRecipePredicate<C>` | `public interface` | 查询入口 `RecipeHelpers.getRecipe(cache, input, key)` 需要它 |
| 序列化器 | `net.dries007.tfc.common.recipes.RecipeSerializerImpl<R>` | `public final record implements RecipeSerializer<R>` | 构造 `(MapCodec<R>, StreamCodec<RegistryFriendlyByteBuf, R>)` 或 `(R singleInstance)` |
| 配方索引 | `net.dries007.tfc.util.collections.IndirectHashCollection<K, R>` | `public class` | `static create(Function<R, Iterable<K>>, Supplier<Collection<R>>)`、`static createForRecipe(Function<R, Iterable<K>>, Supplier<RecipeType<R>>)`、`getAll(K)`、`reload(...)`、`clear()` |
| 配方查询 | `net.dries007.tfc.common.recipes.RecipeHelpers` | `public final class` | `getRecipe(...)` 重载、`itemKeys(Ingredient)`、`getRecipes(Level, Supplier<RecipeType<R>>)`、`getCraftingPlayer()`、`setCraftingInput(...)` |
| 输出系统 | `net.dries007.tfc.common.recipes.outputs.ItemStackProvider` | `public final record` | `empty()`、`copyInput()`、`of(...)`、`getSingleStack(ItemStack)`、`getStack(ItemStack)`、`dependsOnInput()` |
| 输出修饰符 | `net.dries007.tfc.common.recipes.outputs.ItemStackModifier` / `ItemStackModifierType` | `public interface` / `public record` | 实现 `apply(ItemStack, ItemStack input, Context)` 与 `type()`；注册到 `ItemStackModifiers.KEY` |
| 锅输出 | `net.dries007.tfc.common.recipes.outputs.PotOutput` / `PotOutput.OutputType` | `public interface` | 注册表 key `PotOutput.KEY`；`read`/`write`、`getFluidColor()`、`getRenderTexture()`、`onFinish(IPotInventory)` |
| 数据管理器 | `net.dries007.tfc.util.data.DataManager<T>` / `DataManagers` | `public class` / `public final class` | 构造 `(ResourceLocation, Codec<T>[, StreamCodec])`；`getReference(id)`、`getCheckedReference(id)`；`DataManagers.MANAGERS` 是 `DeferredRegister<DataManager<?>>` |
| 注册接口 | `IdHolder<T>` / `HolderHolder<R>` / `RegistryHolder<R, T>` | `public interface` | `holder()`（抽象）、`getId()`/`key()`/`get()`（default） |
| 内容注册 | `net.dries007.tfc.util.registry.RegistrationHelpers` | `public final class` | 7 个 static 方法（见 §2.2） |
| 枚举注册接口 | `RegistryMetal` / `RegistryWood` / `RegistryPlant` / `RegistryRock` | `public interface` | `RegistryMetal`：`toolTier()`、`armorMaterial()`、`armorDurability(ArmorItem.Type)`、`getBlock(Metal.BlockType)`、`mapColor()`、`rarity()`、`default weatheredParts()`、`weatheringResistance()`、`default isPiglinCurrency()` |
| 方块属性 | `net.dries007.tfc.common.blocks.ExtendedProperties` / `ExtendedBlock` | `public class` | `ExtendedProperties.of()...blockEntity(...)/serverTicks(...)/ticks(...)/flammable(...)`；`ExtendedBlock(ExtendedProperties)` |
| 方块实体基类 | `net.dries007.tfc.common.blockentities.InventoryBlockEntity<I>` / `TickableInventoryBlockEntity<I>` / `TickCounterBlockEntity` / `TickingPlantBlockEntity` | `public abstract class` | `InventoryBlockEntity` 提供 `inventory`、`getSidedInventory(...)`、`defaultInventory(int)`、`markForSync()`；TFC 的 `TickableInventoryBlockEntity` 用于 `serverTick`/`clientTick` 静态回调 |
| 菜单基类 | `net.dries007.tfc.common.container.BlockEntityContainer<T>` | `public abstract class` | `protected abstract void addContainerSlots()`、`protected abstract boolean moveStack(ItemStack, int)`、`init(Inventory[, int])`；`BlockEntityContainer.Factory<T, C>` 函数式接口 |
| 界面基类 | `net.dries007.tfc.client.screen.BlockEntityScreen<T, C>` | `public abstract class` | 构造 `(C container, Inventory, Component name, ResourceLocation texture)` |
| 交互注册 | `net.dries007.tfc.util.InteractionManager` / `BlockItemPlacement` | `public class` | `registerBlock(BlockItemPlacement)`、`register(Ingredient, InteractionManager.Target, callback)` |
| 工具 | `net.dries007.tfc.util.Helpers` | `public final class` | `mapOf(Class, Function)`、`mapOf(Class, Predicate, BiFunction)`、`isBlock(...)`、`getCapability(...)`、`consumeInStackSizeIncrements(...)`、`fireSpreaderTick(...)`、`playSound(...)`、`copyProperty(...)`、`iterate(...)`、`perfectMatchExists(...)`、`removeStack(...)` |

#### Firmalife 自身的可继承扩展点

| 类型 | 全限定名 | 形态 | 关键 public 成员 |
| --- | --- | --- | --- |
| `TwoByTwoCoreBlock` | `common.blocks` | `public class extends FourWayDeviceBlock` | `static boolean coreBlockSurvives(LevelReader, BlockPos, BlockState)`；构造 `(ExtendedProperties, Supplier<? extends Block> sub)`；`getStateForPlacement`/`setPlacedBy`/`getShape`。子类示例：`KegCoreBlock` |
| `FourWayDeviceBlock` | `common.blocks` | `public class` | `public static final DirectionProperty FACING`；构造 `(ExtendedProperties, InventoryRemoveBehavior)`；`rotate`/`mirror`/`getStateForPlacement`。11 个子类：`CompostTumblerBlock`、`WineShelfBlock`、`TwoByTwoSubBlock`、`TwoByTwoCoreBlock`、`CentrifugeBlock`、`BaseBeehiveBlock` 系列、`JarringStationBlock`、`JarbnetBlock`、`FoodShelfBlock`、`AbstractOvenBlock`、`PumpingStationBlock` |
| `ConsumingBlock` | `common.blocks` | `public class extends BottomSupportedDeviceBlock`（**是类不是接口**） | `static ConsumingBlock plate(ExtendedProperties)`；`public static final VoxelShape PLATE_SHAPE`；`protected ItemInteractionResult useItemOn(...)` |
| `ApplianceBlockEntity<C>` | `common.blockentities` | `public abstract class extends TickableInventoryBlockEntity<C> implements ICalendarTickable` | 见 §5.2；嵌套 `public static class ApplianceInventory implements IHeatConsumer, DelegateItemHandler, INBTSerializable<CompoundTag>, CrucibleLikeHeatBlock` |
| `GreenhouseConnectable` | `common.blocks.greenhouse` | `public interface` | `BlockState withConnection(BlockState, Direction, BlockState, LevelAccessor, BlockPos, BlockPos)`（抽象）；`default BlockState updateConnections(...)`；`@Deprecated default boolean canConnectTo(...)`、`@Deprecated Set<Direction> getConnectionFaces(...)`；嵌套 `enum DualSide {NONE, LEFT, RIGHT, BOTH}`（含 `combine`/`subtract`/`opposite`/`contains`/`resolve`）、`enum Side {LEFT, RIGHT, NONE}`、`enum Size {NONE, THIN, THICK}` |
| `OvenLike` | `common.blockentities` | `public interface` | `static void regularBlockUpdate(...)`；`getTemperature()`、`getCureTicks()`、`addCureTicks(int)` |
| `ClimateReceiver` | `common.blockentities` | `public interface` | 见 §5.2；Firmalife 中由 `FoodShelfBlockEntity`、`LargePlanterBlockEntity`（含 5 个子类）、`SprinklerBlockEntity`、`CheeseWheelBlock`（**方块**也实现它）实现 |
| `ICure` | `common.blocks.oven` | `public interface` | 黏土炉 → 固化炉的转换契约（由 `OvenBottomBlock`/`OvenTopBlock`/`OvenChimneyBlock`/`OvenHopperBlock` 的黏土变体实现） |
| `IWeatherable` | `common.blocks` | `public interface` | 风化方块契约（温室、金属块使用） |
| `IGrape` | `common.blocks.plant` | `public interface` | 葡萄作物方块契约 |
| `FLHelpers` | `common` | `public class`（非 final） | 40+ 个 static 工具方法，见 §3.13；其中 `FLHelpers.composite(...)` 支持 **10 个** 组件的 `StreamCodec.composite`（原版只支持 6 个） |
| `Greenhouse` / `Greenhouse.BlockType` | `common.blocks.greenhouse` | `public enum` | 枚举 + 工厂式 `BlockType`（`create(Greenhouse)`、`createBlockItem(Item.Properties)`、`getNext(Greenhouse)`） |

### 6.2 **不可**直接复用的类型（重要陷阱）

#### （a）包私有抽象方法造成的「继承屏障」—— 最容易误判的一处

| 类 | 包私有抽象方法 | 文件 |
| --- | --- | --- |
| `SimpleItemRecipeBlockEntity<T extends ItemRecipe>` | `abstract void updateCache();`（无修饰符 = 包私有） | `common/blockentities/SimpleItemRecipeBlockEntity.java` L58 |
| `BoilingBlockEntity<C>` | `abstract boolean isBoiling();`（同上） | `common/blockentities/BoilingBlockEntity.java` L68 |

**Java 语言规定包外子类无法实现包私有抽象方法**，因此这两个「看起来像公开扩展点」的抽象类，**实际上只能在 `com.eerussianguy.firmalife.common.blockentities` 包内继承**。第三方模组在自己的包里 `extends SimpleItemRecipeBlockEntity<DryingRecipe>` 会**编译失败**。

这也是为什么 `DryingMatBlockEntity`、`StringBlockEntity`、`VatBlockEntity`、`StovetopPotBlockEntity` 全部写在 Firmalife 自己的包内。
（本文已通过阅读 `SimpleItemRecipeBlockEntity.java` L58 的 `abstract void updateCache();` 声明核实。）

#### （b）`public final class`（11 个，可调用但不可继承）

`FLClientHelpers`、`FLClientSelfTests`、`RenderUtils`、`FLTooltips`、`FLFruitBlocks`、`FLComponents`、`FLCreativeTabs`、`FLArmorMaterials`、`FLAdvancements`、`Mechanics`、`FLPOIs`。
（来源：各文件的 `public final class` 声明；例如 `common/util/Mechanics.java` L30、`common/blocks/plant/FLFruitBlocks.java`。）

#### （c）包私有/私有构造与嵌套类型

| 项 | 位置 | 说明 |
| --- | --- | --- |
| `KegBlockEntity.KegInventory` 的两个构造 | `common/blockentities/KegBlockEntity.java` | 包私有，外部无法构造 |
| `KegContainer(int windowId, KegBlockEntity)` | `common/container/KegContainer.java` L30 | Firmalife 中唯一的 `private` 构造器；外部入口是 `static KegContainer create(KegBlockEntity, Inventory, int)` |
| `FLItemStackModifiers.Id` | `common/recipes/data/FLItemStackModifiers.java` L36 | 无 `public` 修饰符的嵌套 record |
| `SprinklerBlockEntity.Path` | `common/blockentities/SprinklerBlockEntity.java` | `private record Path(BlockState, BlockPos, int)` |

#### （d）Mixin 与自检代码

`mixin/BarrelRackMixin`、`mixin/BeeMixin`、`mixin/ServerConfigMixin` 是 `@Mixin` 载体，不能被继承或实例化；`common/util/FLSelfTests` 与 `client/FLClientSelfTests` 属内部测试设施（后者为 `final`）。

### 6.3 如何新写一个 Firmalife 风格配方类型（完整步骤）

#### 步骤 0：按输入形态选择基类

| 输入 | 基类 | Firmalife 中的范例 |
| --- | --- | --- |
| 单个物品 → 物品 | `ItemRecipe`（TFC） | `DryingRecipe`、`SmokingRecipe`、`CentrifugeRecipe`、`StompingRecipe`（+ `PressRecipe`） |
| 方块状态 → 方块状态 | `BlockRecipe`（TFC） | Firmalife 未使用；TFC 的 `CollapseRecipe` / `LandslideRecipe` 是范例 |
| 自定义带状态容器（物品 + 流体） | `ISimpleRecipe<你的容器类型>` | `VatRecipe`、`MixingBowlRecipe` |
| 无输入（纯条件 + 温度） | `INoopInputRecipe` + `IRecipePredicate<ItemStack>` | `OvenRecipe` |

#### 步骤 1：写配方类（以 `ItemRecipe` 为例，与 `DryingRecipe` 同构）

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

public class RoastingRecipe extends ItemRecipe
{
    public static final MapCodec<RoastingRecipe> CODEC = RecordCodecBuilder.mapCodec(i -> i.group(
        Ingredient.CODEC.fieldOf("ingredient").forGetter(c -> c.ingredient),
        ItemStackProvider.CODEC.fieldOf("result").forGetter(c -> c.result)
    ).apply(i, RoastingRecipe::new));

    public static final StreamCodec<RegistryFriendlyByteBuf, RoastingRecipe> STREAM_CODEC = StreamCodec.composite(
        Ingredient.CONTENTS_STREAM_CODEC, c -> c.ingredient,
        ItemStackProvider.STREAM_CODEC, c -> c.result,
        RoastingRecipe::new
    );

    public static final IndirectHashCollection<Item, RoastingRecipe> CACHE =
        IndirectHashCollection.createForRecipe(RoastingRecipe::getValidItems, ExampleRecipeTypes.ROASTING);

    public RoastingRecipe(Ingredient ingredient, ItemStackProvider result)
    {
        super(ingredient, result);
    }

    @Nullable
    public static RoastingRecipe getRecipe(ItemStack input)
    {
        return RecipeHelpers.getRecipe(CACHE, input, input.getItem());
    }

    @Override
    public RecipeSerializer<?> getSerializer()
    {
        return ExampleRecipeSerializers.ROASTING.get();
    }

    @Override
    public RecipeType<?> getType()
    {
        return ExampleRecipeTypes.ROASTING.get();
    }
}
```

> 注意：`ItemRecipe` 的字段是 `protected final Ingredient ingredient` / `protected final ItemStackProvider result`，因此子类可以直接用 `c -> c.ingredient` 这种 lambda 访问。`getValidItems()` 由 `ItemRecipe` 提供（`DryingRecipe::getValidItems` 就是直接继承的方法引用）。

#### 步骤 2：自定义容器型配方（`ISimpleRecipe`）的写法

与 `MixingBowlRecipe` 同构（`common/recipes/MixingBowlRecipe.java` L25-122）：

```java
public class MyMachineRecipe implements ISimpleRecipe<MyBlockEntity.MyInventory>
{
    public static final MapCodec<MyMachineRecipe> CODEC = RecordCodecBuilder.mapCodec(i -> i.group(
        Ingredient.CODEC.listOf().fieldOf("item_ingredients").forGetter(c -> c.itemIngredients),
        ItemStack.CODEC.optionalFieldOf("result_item", ItemStack.EMPTY).forGetter(c -> c.resultItem)
    ).apply(i, MyMachineRecipe::new));

    public static final StreamCodec<RegistryFriendlyByteBuf, MyMachineRecipe> STREAM_CODEC = StreamCodec.composite(
        Ingredient.CONTENTS_STREAM_CODEC.apply(ByteBufCodecs.list(5)), c -> c.itemIngredients,
        ItemStack.OPTIONAL_STREAM_CODEC, c -> c.resultItem,
        MyMachineRecipe::new
    );

    private final List<Ingredient> itemIngredients;
    private final ItemStack resultItem;

    public MyMachineRecipe(List<Ingredient> itemIngredients, ItemStack resultItem)
    {
        this.itemIngredients = itemIngredients;
        this.resultItem = resultItem;
        FoodCapability.setNonDecaying(resultItem);   // Firmalife 的做法：产物不腐烂
    }

    @Override
    public boolean matches(MyBlockEntity.MyInventory inventory, Level level) { /* 无序匹配 */ }

    @Override
    public ItemStack assemble(MyBlockEntity.MyInventory inventory, HolderLookup.Provider provider)
    {
        return resultItem.copy();
    }

    @Override
    public ItemStack getResultItem(HolderLookup.Provider access) { return resultItem.copy(); }

    @Override public RecipeSerializer<?> getSerializer() { return ExampleRecipeSerializers.MY_MACHINE.get(); }
    @Override public RecipeType<?> getType() { return ExampleRecipeTypes.MY_MACHINE.get(); }
}
```

容器类型需要实现 `RecipeInput`（`MixingBowlBlockEntity.MixingBowlInventory` 与 `VatBlockEntity.VatInventory` 都是 BE 的嵌套类，实现 `NonEmptyInput`、`DelegateItemHandler`、`DelegateFluidHandler` 等 TFC 组件接口）。

#### 步骤 3：注册 RecipeType

```java
public class ExampleRecipeTypes
{
    public static final DeferredRegister<RecipeType<?>> RECIPE_TYPE =
        DeferredRegister.create(Registries.RECIPE_TYPE, ExampleMod.MOD_ID);

    public static final TFCRecipeTypes.Id<RoastingRecipe> ROASTING = register("roasting");

    private static <R extends Recipe<?>> TFCRecipeTypes.Id<R> register(String name)
    {
        return new TFCRecipeTypes.Id<>(RECIPE_TYPE.register(name, () -> new RecipeType<>()
        {
            @Override public String toString() { return name; }
        }));
    }
}
```

（照抄 `common/recipes/FLRecipeTypes.java` L32-41：`RecipeType` 用匿名实现，`toString()` 返回裸名。）

#### 步骤 4：注册 RecipeSerializer

```java
public class ExampleRecipeSerializers
{
    public static final DeferredRegister<RecipeSerializer<?>> RECIPE_SERIALIZER =
        DeferredRegister.create(Registries.RECIPE_SERIALIZER, ExampleMod.MOD_ID);

    public static final TFCRecipeSerializers.Id<RoastingRecipe> ROASTING =
        new TFCRecipeSerializers.Id<>(RECIPE_SERIALIZER.register("roasting",
            () -> new RecipeSerializerImpl<>(RoastingRecipe.CODEC, RoastingRecipe.STREAM_CODEC)));
}
```

（照抄 `common/recipes/FLRecipeSerializers.java` L31-39。）

#### 步骤 5：在构造器里 `register(bus)`

```java
ExampleRecipeTypes.RECIPE_TYPE.register(bus);
ExampleRecipeSerializers.RECIPE_SERIALIZER.register(bus);
```

#### 步骤 6：写数据包 JSON（放在 `data/<你的modid>/recipe/<你的类型>/xxx.json`）

```json
{
  "type": "examplemod:roasting",
  "ingredient": { "item": "minecraft:potato" },
  "result": {
    "modifiers": [ { "type": "tfc:copy_input" } ],
    "stack": { "count": 1, "id": "examplemod:roasted_potato" }
  }
}
```

（`type` 必须与步骤 3/4 的注册名一致；Firmalife 自己完全依赖 datagen 生成，datagen 目标目录是 `src/generated/resources/data/...`，见 §4.9。）

#### 步骤 7（可选）：加 JEI 类目

```java
@JeiPlugin
public class ExampleJEIPlugin implements IModPlugin
{
    public static final RecipeType<RecipeHolder<RoastingRecipe>> ROASTING =
        RecipeType.createRecipeHolderType(ResourceLocation.fromNamespaceAndPath(ExampleMod.MOD_ID, "roasting"));

    @Override public ResourceLocation getPluginUid() { return ResourceLocation.fromNamespaceAndPath(ExampleMod.MOD_ID, "jei"); }
    @Override public void registerCategories(IRecipeCategoryRegistration r) { r.addRecipeCategories(new RoastingCategory(ROASTING, r.getJeiHelpers().getGuiHelper())); }
    @Override public void registerRecipes(IRecipeRegistration r) { r.addRecipes(ROASTING, recipes(ExampleRecipeTypes.ROASTING)); }
}
```

（照抄 `compat/jei/FLJEIPlugin.java` L47-90 的形式；Firmalife 的类别类多继承 TFC 的 `SimpleItemRecipeCategory<T>` 或 `BaseRecipeCategory<T>`。）

#### 步骤 8（可选）：扩展 `ItemStackProvider` 的输出修饰符

```java
public enum MyModifier implements ItemStackModifier
{
    INSTANCE;

    @Override
    public ItemStack apply(ItemStack stack, ItemStack input, Context context) { /* ... */ return stack; }

    @Override
    public ItemStackModifierType<?> type() { return ExampleModifiers.MY_MODIFIER.get(); }
}

public final class ExampleModifiers
{
    public static final DeferredRegister<ItemStackModifierType<?>> TYPES =
        DeferredRegister.create(ItemStackModifiers.KEY, ExampleMod.MOD_ID);

    public static final FLItemStackModifiers.Id<MyModifier> MY_MODIFIER =
        new FLItemStackModifiers.Id<>(TYPES.register("my_modifier",
            () -> new ItemStackModifierType<>(MapCodec.unit(MyModifier.INSTANCE), StreamCodec.unit(MyModifier.INSTANCE))));
}
```

> `FLItemStackModifiers.Id` 是**包私有**的（见 §6.2c），第三方**不能**直接复用它——请自带一个同形状的 public record：
> ```java
> public record Id<T extends ItemStackModifier>(DeferredHolder<ItemStackModifierType<?>, ItemStackModifierType<T>> holder)
>     implements RegistryHolder<ItemStackModifierType<?>, ItemStackModifierType<T>> {}
> ```
> （这正是 `FLItemStackModifiers.java` L36-37 的做法，注释写着「Copied from TFC」。）

### 6.4 如何新写 BlockEntity + Menu + Screen（基于 `BarrelPress` 三件套）

#### （a）BlockEntity

```java
public class MyMachineBlockEntity extends TickableInventoryBlockEntity<ItemStackHandler>
{
    public static final int SLOTS = 4;

    public static void tick(Level level, BlockPos pos, BlockState state, MyMachineBlockEntity machine) { /* ... */ }

    public MyMachineBlockEntity(BlockPos pos, BlockState state)
    {
        super(ExampleBlockEntities.MY_MACHINE.get(), pos, state, defaultInventory(SLOTS), ExampleMod.MOD_ID);
    }

    @Override
    public AbstractContainerMenu createMenu(int windowId, Inventory playerInv, Player player)
    {
        return MyMachineContainer.create(this, playerInv, windowId);
    }

    @Override
    public int getSlotStackLimit(int slot) { return 1; }

    @Override
    public boolean isItemValid(int slot, ItemStack stack) { return true; }
}
```

注册 BE 时用 TFC 的 `RegistrationHelpers.register(...)` 并把 ticker 绑在方块上（Firmalife 的做法是在 `ExtendedProperties` 里写 `.serverTicks(MyMachineBlockEntity::tick)` 或 `.ticks(serverTick, clientTick)`，见 `common/blocks/FLBlocks.java` L154-171）：

```java
public static final TFCBlockEntities.Id<MyMachineBlockEntity> MY_MACHINE =
    new TFCBlockEntities.Id<>(RegistrationHelpers.register(
        BLOCK_ENTITY, "my_machine", MyMachineBlockEntity::new, MY_MACHINE_BLOCK));

// 方块端：
public static final TFCBlocks.Id<Block> MY_MACHINE_BLOCK = new TFCBlocks.Id<>(RegistrationHelpers.registerBlock(
    BLOCK, ITEM, "my_machine",
    () -> new Block(ExtendedProperties.of().strength(2f).blockEntity(ExampleBlockEntities.MY_MACHINE)
        .serverTicks(MyMachineBlockEntity::tick)),
    block -> new BlockItem(block, new Item.Properties())));
```

#### （b）Container

```java
public class MyMachineContainer extends BlockEntityContainer<MyMachineBlockEntity>
{
    public static MyMachineContainer create(MyMachineBlockEntity machine, Inventory playerInventory, int windowId)
    {
        return new MyMachineContainer(machine, playerInventory, windowId).init(playerInventory);
    }

    public MyMachineContainer(MyMachineBlockEntity machine, Inventory playerInv, int windowId)
    {
        super(ExampleMenuTypes.MY_MACHINE.get(), windowId, machine);
    }

    @Override
    protected void addContainerSlots()
    {
        IItemHandler inventory = Helpers.getCapability(BlockCapabilities.ITEM, blockEntity);
        if (inventory != null)
        {
            addSlot(new CallbackSlot(blockEntity, inventory, 0, 62, 20));
            // ... 其余槽位
        }
    }

    @Override
    protected boolean moveStack(ItemStack stack, int slotIndex)
    {
        return switch (typeOf(slotIndex))
        {
            case MAIN_INVENTORY, HOTBAR -> !moveItemStackTo(stack, 0, MyMachineBlockEntity.SLOTS, false);
            case CONTAINER -> !moveItemStackTo(stack, containerSlots, slots.size(), false);
        };
    }
}
```

（照抄 `common/container/BarrelPressContainer.java` L13-50。）

注册菜单：

```java
public static final TFCContainerTypes.Id<MyMachineContainer> MY_MACHINE =
    new TFCContainerTypes.Id<>(RegistrationHelpers.registerBlockEntityContainer(
        MENU, "my_machine", ExampleBlockEntities.MY_MACHINE, MyMachineContainer::create));
```

（照抄 `common/container/FLMenuTypes.java` L27-34。）

#### （c）Screen

```java
public class MyMachineScreen extends BlockEntityScreen<MyMachineBlockEntity, MyMachineContainer>
{
    private static final ResourceLocation TEXTURE = ExampleHelpers.identifier("textures/gui/my_machine.png");

    public MyMachineScreen(MyMachineContainer container, Inventory playerInventory, Component name)
    {
        super(container, playerInventory, name, TEXTURE);
    }

    @Override
    protected void renderLabels(GuiGraphics graphics, int mouseX, int mouseY)
    {
        super.renderLabels(graphics, mouseX, mouseY);
        // 额外信息
    }
}
```

（照抄 `client/screen/BarrelPressScreen.java` L17-44。）

注册：

```java
public static void onMenuRegister(RegisterMenuScreensEvent event)
{
    event.register(ExampleMenuTypes.MY_MACHINE.get(), MyMachineScreen::new);
}
```

#### （d）把能力挂上去（只需在做机器时加一次）

```java
public static void registerCapabilities(RegisterCapabilitiesEvent event)
{
    event.registerBlockEntity(BlockCapabilities.ITEM, ExampleBlockEntities.MY_MACHINE.get(),
        InventoryBlockEntity::getSidedInventory);
    event.registerBlockEntity(BlockCapabilities.FLUID, ExampleBlockEntities.MY_MACHINE.get(),
        MyMachineBlockEntity::getSidedFluidInventory);
}
```

（照抄 `common/capabilities/FLComponents.java` L95-98。）

### 6.5 如何新增一个数据驱动的 TFC 风格数据表（DataManager）

```java
public record MyPlantType(BlockIngredient ingredient, int tier, Component translationKey)
{
    public static final Codec<MyPlantType> CODEC = RecordCodecBuilder.create(i -> i.group(
        BlockIngredient.CODEC.fieldOf("ingredient").forGetter(MyPlantType::ingredient),
        Codecs.POSITIVE_INT.fieldOf("tier").forGetter(MyPlantType::tier),
        ComponentSerialization.CODEC.fieldOf("translation_key").forGetter(MyPlantType::translationKey)
    ).apply(i, MyPlantType::new));

    public static final StreamCodec<RegistryFriendlyByteBuf, MyPlantType> STREAM_CODEC = StreamCodec.composite(
        BlockIngredient.STREAM_CODEC, MyPlantType::ingredient,
        ByteBufCodecs.VAR_INT, MyPlantType::tier,
        ComponentSerialization.STREAM_CODEC, MyPlantType::translationKey,
        MyPlantType::new
    );

    // 第 1 个参数决定数据文件目录：data/<namespace>/<path>/*.json
    public static final DataManager<MyPlantType> MANAGER =
        new DataManager<>(ExampleHelpers.identifier("my_plant_type"), CODEC, STREAM_CODEC);

    public static final IndirectHashCollection<Block, MyPlantType> CACHE =
        IndirectHashCollection.create(s -> s.ingredient.blocks(), MANAGER::getValues);
}

// 在 @Mod 构造器里（与 FirmaLife 的 FLDataManagers.init() 同一时机）
DataManagers.MANAGERS.register(MyPlantType.MANAGER.getName(), () -> MyPlantType.MANAGER);
```

> 关键点（全部来自 `common/util/GreenhouseType.java`、`common/util/FLDataManagers.java`、`net.dries007.tfc.util.data.DataManager` 的真实签名）：
> - `DataManager` 的第一个参数是**数据表名字**，`SimpleJsonResourceReloadListener` 会据此确定 `data/<ns>/<path>` 目录；
> - `STREAM_CODEC` **可选**——不传也可以，但传了才能同步到客户端（`GreenhouseType`、`Plantable` 都传了）；
> - 注册进 `DataManagers.MANAGERS`（TFC 的 `DeferredRegister`）即可，**不要**新建自己的 `DeferredRegister<DataManager<?>>`，否则 TFC 的 reload 不会带上它；
> - 若数据表之间要互相引用，用 `MANAGER.getReference(id)` 返回的 `DataManager.Reference<T>` 作为字段类型（Firmalife 的 `FLClimateRanges` 就是引用 TFC 的 `ClimateRange.MANAGER`）。


---

## 7. 附属模组开发要点（第三方依赖 Firmalife + TFC）

### 7.1 必须声明的依赖

照抄 Firmalife 自己的 `src/main/templates/META-INF/neoforge.mods.toml`（占位符由 gradle `expand` 替换）：

```toml
modLoader = "javafml"
loaderVersion = "[4,)"
license = "MIT"

[[mods]]
    modId = "yourmod"
    version = "${modVersion}"
    displayName = "Your Mod"

[[dependencies.yourmod]]
    modId = "tfc"
    type = "required"
    versionRange = "[4.2.8,)"
    ordering = "AFTER"          # 关键：必须在 TFC 之后加载
    side = "BOTH"

[[dependencies.yourmod]]
    modId = "firmalife"
    type = "required"           # 或 optional，取决于你的功能
    versionRange = "[3.0.14,)"
    ordering = "AFTER"
    side = "BOTH"

[[dependencies.yourmod]]
    modId = "patchouli"
    type = "required"           # 只有当你复用 Firmalife 的 Patchouli 多块/书页时才需要
    versionRange = "[1.21.1-92,)"
    ordering = "NONE"
    side = "BOTH"

[[dependencies.yourmod]]
    modId = "neoforge"
    type = "required"
    versionRange = "[21.1.234,)"
    ordering = "AFTER"
    side = "BOTH"

[[dependencies.yourmod]]
    modId = "minecraft"
    type = "required"
    versionRange = "[1.21.1]"
    ordering = "AFTER"
    side = "BOTH"
```

来源：`src/main/templates/META-INF/neoforge.mods.toml` L1-58。

**是否必须把 patchouli 设为 `required`？** Firmalife 自己是 required（L28-33）。若你的模组直接 `import vazkii.patchouli.api.*`（例如调用 `PatchouliAPI.get().registerMultiblock(...)`），则必须 required——否则 NoClassDefFoundError。

### 7.2 构建脚本要点（ModDevGradle）

```kotlin
plugins {
    id("net.neoforged.moddev") version "2.0.107"
}

val minecraftVersion = "1.21.1"
val neoForgeVersion  = "21.1.234"
val modId            = "yourmod"
val modVersion       = System.getenv("VERSION") ?: "0.0.0-indev"
val modJavaVersion   = "21"

neoForge {
    version = neoForgeVersion
    validateAccessTransformers = true
    parchment {
        minecraftVersion.set("1.21.1")
        mappingsVersion.set("2024.11.17")
    }
    runs {
        register("client") { client(); gameDirectory = file("run/client") }
        register("server") { server(); gameDirectory = file("run/server"); programArgument("--nogui") }
        register("data") {
            data()
            programArguments.addAll("--all", "--mod", modId,
                "--output", file("src/generated/resources").absolutePath,
                "--existing", file("src/main/resources").absolutePath,
                "--existing-mod", "tfc")
        }
    }
    mods { create(modId) { sourceSet(sourceSets.main.get()) } }
    ideSyncTask(generateModMetadata)
}

sourceSets {
    main { resources { srcDir("src/generated/resources") } }
    create("data")                      // 独立 datagen sourceSet
}

neoForge { addModdingDependenciesTo(sourceSets["data"]) }   // 关键：让 data sourceSet 能见到 MC/TFC

java { toolchain.languageVersion.set(JavaLanguageVersion.of(modJavaVersion)) }
```

来源：`build.gradle.kts` L4-138。

依赖坐标（TFC 从 CurseForge maven 拉取，Firmalife 用的是）：

```kotlin
repositories {
    exclusiveContent { forRepository { maven("https://www.cursemaven.com") } filter { includeGroup("curse.maven") } }
    exclusiveContent { forRepository { maven("https://maven.blamejared.com") } filter { includeGroup("vazkii.patchouli"); includeGroup("mezz.jei") } }
}

dependencies {
    implementation(group = "curse.maven", name = "terrafirmacraft-302973", version = "8666972")  // TFC 4.2.8
    "dataImplementation"(group = "curse.maven", name = "terrafirmacraft-302973", version = "8666972")
    implementation("vazkii.patchouli:Patchouli:1.21.1-92-NEOFORGE")
    compileOnly("mezz.jei:jei-1.21.1-common-api:19.25.0.321")
    compileOnly("mezz.jei:jei-1.21.1-neoforge-api:19.25.0.321")
    runtimeOnly("mezz.jei:jei-1.21.1-neoforge:19.25.0.321")
}
```

来源：`build.gradle.kts` L58-169。

**`--existing-mod tfc` 参数的含义**（`build.gradle.kts` L120）：datagen 时把 TFC 已有的数据当作「existence provider」加载，这样 Firmalife 可以**在 datagen 中读取并覆盖 TFC 的配方**（例如 `BuiltinRecipes` 里的 `remove(...)` 与写入 `data/tfc/recipe/**`）。附属模组若想覆盖 TFC 配方也必须加这一项。

### 7.3 注册时序与类加载陷阱（基于 Firmalife 自身证据）

1. **`@Mod` 构造器注入**：`public FirmaLife(ModContainer mod, IEventBus bus)`（`FirmaLife.java` L54）。NeoForge 支持注入 `IEventBus`、`ModContainer`、`Dist`、`FMLModContainer` 等。**不要**在 `@Mod` 类里写无参构造器。
2. **`DeferredRegister` 必须在构造器里 `register(bus)`**；若注册表在静态字段中创建（Firmalife 全部如此），则静态初始化顺序 = 类加载顺序。**先 `register(bus)` 再 `FLDataManagers.init()`**（`FirmaLife.java` L56-81）。
3. **数据包注册**：`InventoryBlockEntity` 的 inventory 大小、`DataComponentType` 等通过 `DeferredRegister` 注册，**不需要** `DataPackRegistryEvent`。Firmalife 全仓库**没有**使用 `DataPackRegistryEvent` / `NewRegistryEvent`（已用 `grep` 确认）。TFC 的 `DataManager` 系统同样不使用它——它用的是 `DataManagers.MANAGERS`（一个 `DeferredRegister`）+ 普通 JSON reload listener。
4. **能力注册用 `RegisterCapabilitiesEvent`（mod bus）**，Firmalife 通过 `bus.addListener(FLComponents::register)` 挂载（`FirmaLife.java` L84）。
5. **`FMLCommonSetupEvent` 中的原版注册表操作要 `enqueueWork`**（`FirmaLife.java` L100-108 的注释：`// Vanilla registries are not thread safe`）。
6. **可选模组探测**：`ModList.get().isLoaded("jei")` 等放在静态字段里（`FirmaLife.java` L49-52），在 `@Mod` 类初始化后即可安全使用；但**不要**在更早的类（例如你的 `@Mod` 类的静态字段）里引用 `FirmaLife.JEI`，否则会强制提前加载 `FirmaLife` 并触发它的一整套注册。
7. **客户端类隔离**：`FMLEnvironment.dist == Dist.CLIENT` 分支（`FirmaLife.java` L89-93）保证 `client/*` 与服务端专用类不会在专用服务端被加载。你自己的 Screen / Renderer 必须遵守同一约定。
8. **Registry 与 Registry 之间的依赖顺序**：`FLBlocks` 依赖 `FLItems`（BlockItem 的注册），`FLBlockEntities` 依赖 `FLBlocks`（`Stream.of(FLBlocks.X)`），`FLFluids` 依赖 `FLBlocks`/`FLItems`。Firmalife 在构造器里按 **ITEM → BLOCK → FLUID → FLUID_TYPE → BLOCK_ENTITY** 的顺序注册；因为 `DeferredRegister` 只是收集 supplier、实际在 registry 事件里按 registry 类型执行，所以这个顺序本身不构成硬约束，但**跨注册表的静态字段引用**（例如 `FLBlockEntities` 的静态初始化读取 `FLBlocks.CHEDDAR_WHEEL`）要求 `FLBlocks` 类先加载。
9. **`FLDataManagers.init()` 必须在 `FirmaLife` 构造器中被调用一次**；如果你的附属模组也注册自己的 `DataManager`，请在自己的构造器中调用 `DataManagers.MANAGERS.register(name, () -> manager)`，**不要**试图在 `FMLCommonSetupEvent` 里做（那时 `MANAGERS` 已经冻结）。
10. **不要 `import static` 别人的主类**。`common/FLHelpers.java` L73 有 `import static com.eerussianguy.firmalife.FirmaLife.*;`，这使任何调用 `FLHelpers.identifier(...)` 的类都会触发 `FirmaLife` 的**类初始化**，从而在与调用者相同的时机求值 `ModList.get().isLoaded("jei"/"emi"/"jade"/"theoneprobe")` 四次。第三方应只静态引用自己 mod 的 `MOD_ID`，并把可选模组探测收敛到单点。
11. **`compileOnly` 依赖 + 接口实现的类必须加运行时守卫**。`FirmaLife.java` L95-96 的写法是：

    `if (THE_ONE_PROBE) TheOneProbeIntegration.init(bus);`

    而 `compat/tooltip/TheOneProbeIntegration.java` L19 是 `public class TheOneProbeIntegration implements Function<ITheOneProbe, Void>`，其中 `mcjty.theoneprobe` 在 `build.gradle.kts` L161 里只是 `compileOnly`。JVM 在**加载**该类时会解析方法签名引用的 `ITheOneProbe`，运行期缺失时抛 `NoClassDefFoundError`。因此：

    - 该类的**首次主动使用**必须被 `THE_ONE_PROBE` 守卫（Firmalife 做到了，并且把它藏在 `init(bus)` 内部的方法引用里）；
    - **不要**在别的公共类里写 `private static final Function<...> TOP = TheOneProbeIntegration::new;`（类初始化即崩）；
    - 只写 `import` 语句是安全的——`import` 不触发类加载。
    - 同理适用于 Jade（`JadeIntegration implements IWailaPlugin`）。Jade 在 Firmalife 的 Gradle 里是 `implementation`（`build.gradle.kts` L160），运行期一定存在；若第三方把它改成 `compileOnly`，就必须自己加守卫。
12. **Mixin 配置的严格性**：`src/main/resources/firmalife.mixins.json` 使用 `"required": true` + `"injectors": { "defaultRequire": 1 }` + `"refmap": "firmalife.refmap.json"`。含义是：mixin 应用失败或任一 `@Inject` 未命中都会**直接崩溃**而不是告警。若你的附属模组注入 TFC 的方法（Firmalife 的 `BarrelRackMixin` 就注入了 TFC 的酒桶架方块），TFC 更新改名后会导致启动崩溃——要么接受这个代价，要么把 `require` 降为 0 并自行运行时检测。`ServerConfigMixin` 还示范了改写 TFC 的 `final` 配置字段必须写 `@Shadow(remap = false) @Mutable @Final`（TFC 类不在原版混淆映射内，`remap = false` 不可省）。

### 7.4 一个最小附属模组的骨架

```java
package com.example.mymod;

import net.neoforged.bus.api.IEventBus;
import net.neoforged.fml.ModContainer;
import net.neoforged.fml.common.Mod;
import net.neoforged.fml.event.lifecycle.FMLCommonSetupEvent;

@Mod(MyMod.MOD_ID)
public class MyMod
{
    public static final String MOD_ID = "mymod";

    public MyMod(ModContainer mod, IEventBus bus)
    {
        MyBlocks.BLOCK.register(bus);
        MyItems.ITEM.register(bus);
        MyBlockEntities.BLOCK_ENTITY.register(bus);
        MyRecipeTypes.RECIPE_TYPE.register(bus);
        MyRecipeSerializers.RECIPE_SERIALIZER.register(bus);

        bus.addListener(this::setup);
        bus.addListener(MyComponents::registerCapabilities);
    }

    private void setup(FMLCommonSetupEvent event)
    {
        event.enqueueWork(() -> {
            // 原版注册表操作必须在这里
        });
    }
}
```

```json
// src/main/resources/data/mymod/recipe/drying/my_recipe.json
{
  "type": "firmalife:drying",
  "ingredient": { "item": "minecraft:apple" },
  "result": { "count": 1, "id": "mymod:dried_apple" }
}
```

（上面这条 JSON 直接复用 Firmalife 已注册的 `firmalife:drying` 类型，是**最省事**的扩展方式：不要新建配方类型，直接往 Firmalife 的类型里塞数据即可。）

---

## 8. 未能核实 / 检查记录

| 事项 | 状态 | 已检查的位置 |
| --- | --- | --- |
| TFC 的 `RegistrationHelpers` 源码实现细节（只有签名可确认） | 部分核实 | TFC 源码未克隆（`Test-Path ...\src-ref\TerraFirmaCraft` 返回 `False`）；签名来自 `javap` 读取 `mods\TerraFirmaCraft-NeoForge-1.21.1-4.2.10.jar` |
| `net.dries007.tfc.common.recipes.TFCRecipeTypes$Id` 的 record 组件名 | 已核实 | `javap` 输出显示其唯一组件为 `DeferredHolder<RecipeType<?>, RecipeType<T>>`，与 `holder()` 方法对应 |
| 3 个 mixin 的具体注入目标方法 | 待补 | 见 `_work\c-integration.md`；本文只保证 `firmalife.mixins.json` 的注册内容 |
| Firmalife 是否使用 `NewRegistryEvent` / `DataPackRegistryEvent` | 已核实为**否** | 对 `src/**` 全量 grep `NewRegistryEvent`、`DataPackRegistryEvent`，无命中 |
| `press` 配方为何没有内置数据 | 已核实现象、未核实作者意图 | `src/data/.../recipes/` 无 `PressRecipes.java`；`src/generated/resources/data/firmalife/recipe/` 无 `press/` 目录；但 `FLRecipeTypes.PRESS`、`FLRecipeSerializers.PRESS`、`compat/jei/FLJEIPlugin.PRESS` 均存在 |
| `build.gradle.kts` L19 的 `tfcVersion = "4.2.8"` 与实例内 4.2.10 的差异 | 已记录为环境差异 | 见 §0 |
| TFC 全部类的方法体语义（例如 `InventoryBlockEntity`、`BlockEntityContainer`、`BlockEntityScreen`、`RegistrationHelpers` 的内部实现） | **未能核实** | `moddev/src-ref/TerraFirmaCraft/` 只有 `.git`、无工作树，`git` 报 `HEAD` 损坏；只有 jar 可 `javap`（只能得到签名） |
| TFC `DataManager` 各类型的**可选字段与默认值**（`ClimateRange.hydration_wiggle_range`、`FoodDefinition` 的营养字段全集、`Drinkable` 的 `consume_chance`/`may_drink_when_full`/`effects`、`HeatDefinition` 的完整组件集、`KnappingType.amount_to_consume` 的默认值） | **未能核实**：字段名已由 `javap` 得到 record 组件确认，但「是否 `optionalFieldOf`」与默认值不可见 | TFC jar 的 `javap` 输出（无常量值）；对照 `src/generated/resources/data/firmalife/tfc/**` 实际生成的文件归纳 |
| `firmalife:press` 的真实 JSON 示例 | **未能核实（不存在）** | 全仓库 grep `"type": "firmalife:press"` 无命中；`src/data/java/.../recipes/` 无 `PressRecipes.java`；`src/generated/resources/data/firmalife/recipe/` 无 `press/` 目录 |
| `Plantable` 的完整 `PlanterType` 取值集合 | 已核实 | `common/blocks/greenhouse/PlanterType.java` L11-19：`QUAD, LARGE, HANGING, TRELLIS, BONSAI, HYDROPONIC` |
| `RegistryOre` 接口、`Metal$Tier`、`net.dries007.tfc.common.recipes.inventory.ItemStackInventory`、`net.dries007.tfc.util.Env` 是否存在 | **经核实不存在**（在 TFC jar 中检索为 0 命中） | 对应正确名称为 `RegistryRock`、`TFCTiers`/`LevelTier`、`recipes.input.NonEmptyInput`、`util.EnvironmentHelpers` |
| Jade / JEI 插件的自动发现机制 | 未反编译（Firmalife jar 内无 descriptor 文件） | 只核对了 Firmalife 侧的 `@JeiPlugin`、`IWailaPlugin`、`IProbeInfoProvider` 实现方式 |
| Patchouli 的「同名文件覆盖 + 多包合并」实现细节 | 只 `javap` 了 `BookContentResourceListenerLoader`、`ClientBookRegistry`，未反编译方法体 | `Patchouli-1.21.1-93-NEOFORGE.jar` |
| datagen 未实测 | **未运行 `runData`** | 「目录 → provider」的映射来自 `src/data/java/.../DataEntryPoint.java` 的注册顺序 + 各 provider 的 `domain` 参数 + 实际已生成文件的三方对照 |

---

## 9. 一页速查（写给附属模组开发者的最短路径）

| 需求 | 用什么 |
| --- | --- |
| 注册方块 + 方块物品 | `RegistrationHelpers.registerBlock(BLOCK_DR, ITEM_DR, name, supplier, blockItemFactory)`；`blockItemFactory` 传 `null` = 不注册物品 |
| 注册方块实体 | `RegistrationHelpers.register(BLOCK_ENTITY_DR, name, factory, block)` 或 `(..., Stream<Supplier<Block>>)` 多方块重载 |
| 注册 MenuType | `RegistrationHelpers.registerBlockEntityContainer(MENU_DR, name, beTypeSupplier, factory)` |
| 注册流体 | `RegistrationHelpers.registerFluid(FLUID_TYPE_DR, FLUID_DR, typeName, sourceName, flowingName, builder, fluidType, sourceFactory, flowingFactory)` |
| 批量按枚举生成内容 | `Helpers.mapOf(EnumClass.class, fn)` / `Helpers.mapOf(EnumClass.class, predicate, fn)` |
| 方块属性 | `ExtendedProperties.of()...`；方块基类 `ExtendedBlock`；装置类可用 `FourWayDeviceBlock` / `TwoByTwoCoreBlock` |
| 配方基类 | 物品→物品 `ItemRecipe`；方块→方块 `BlockRecipe`；自定义容器 `ISimpleRecipe<C>`；无输入 `INoopInputRecipe` + `IRecipePredicate<ItemStack>` |
| 配方序列化器 | `RecipeSerializerImpl<>(mapCodec, streamCodec)` |
| 配方快速查询 | `IndirectHashCollection.createForRecipe(Type::getValidItems, RECIPE_TYPE)` + `RecipeHelpers.getRecipe(CACHE, input, key)` |
| 配方产物后处理 | `ItemStackProvider`（`of`/`copyInput`/`getSingleStack`）+ `ItemStackModifier`（`CopyInputModifier`、`AddTraitModifier`、`CopyFoodModifier` …）+ 自建的 modifier 类型 |
| 数据表（datapack） | `new DataManager<>(identifier, CODEC, STREAM_CODEC)` + `DataManagers.MANAGERS.register(name, () -> manager)` |
| 食物特性 | `DeferredRegister.create(FoodTraits.KEY, MOD_ID)` + `new FoodTrait(Supplier<Float> mod, String translationKey)` |
| 物品数据组件 | 自建 `DeferredRegister<DataComponentType<?>>`（或复用 TFC 的 `TFCComponents.BOWL` / `FLComponents.WINE` 等） |
| 方块实体基类 | TFC 的 `InventoryBlockEntity` / `TickableInventoryBlockEntity`；Firmalife 的 `ApplianceBlockEntity`（**可继承**） |
| 容器 / 界面 | TFC 的 `BlockEntityContainer` + `BlockEntityScreen`；以 `BarrelPressContainer` / `BarrelPressScreen` 为模板 |
| 能力注册 | `bus.addListener(event -> event.registerBlockEntity(BlockCapabilities.ITEM, TYPE.get(), InventoryBlockEntity::getSidedInventory))` |
| 提示信息（Jade / TOP） | 复用 TFC 的 `BlockEntityTooltip` 常量 + 分别实现 `IWailaPlugin` / `IProbeInfoProvider`（参考 `compat/tooltip/`） |
| Patchouli 结构预览 | `PatchouliAPI.get().makeMultiblock(...)` + `predicateMatcher(..., 你的判据谓词)`；注意 Patchouli 是**硬依赖** |
| 直接复用 Firmalife 的机制 | 往 `firmalife:drying` / `firmalife:smoking` / `firmalife:oven` / `firmalife:vat` / `firmalife:centrifuge` / `firmalife:mixing_bowl` / `firmalife:stomping` / `firmalife:press` 里加数据包 JSON —— **最快、最安全**的扩展方式，无需写任何 Java |

### 最容易踩的 5 个坑（本文实测结论）

1. `SimpleItemRecipeBlockEntity` / `BoilingBlockEntity` 因**包私有抽象方法**（`abstract void updateCache();` / `abstract boolean isBoiling();`）**无法在包外继承**（§6.2a）。
2. `firmalife:press` 配方类型已注册、JEI 也有类目，但**既无内置 JSON 也不在 datagen 中**（§4.2、§3.3b）；`KegRecipe` / `WrappedHeatingRecipe` 也**不是**注册型配方类型。
3. Firmalife 的 `DataManager` 必须在 `FLDataManagers.init()` **之前**注册；所有 `DeferredRegister.register(bus)` 必须在 `@Mod` 构造器内完成（§7.3）。
4. Firmalife **没有**自己的 `RegistrationHelpers` 与 Id record —— 全部复用 TFC 的（§2.1、§2.4）；照着 TFC 的 `Id` record 形状写自己的一份也是标准做法。
5. `FLItemStackModifiers.Id` 是**包私有**的，第三方必须自带同形状的 public record 才能注册自己的 `ItemStackModifier`（§6.3 步骤 8）。

