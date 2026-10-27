package io.github.likexiang21.tfcplus.agriculture.common.registry;

import io.github.likexiang21.tfcplus.agriculture.TFCAgriculturePlus;
import io.github.likexiang21.tfcplus.agriculture.common.blockentity.CookingPanBlockEntity;
import io.github.likexiang21.tfcplus.agriculture.common.blockentity.CuttingBoardBlockEntity;
import io.github.likexiang21.tfcplus.agriculture.common.blockentity.DoughFormingTableBlockEntity;
import io.github.likexiang21.tfcplus.agriculture.common.blockentity.DryingRackBlockEntity;
import io.github.likexiang21.tfcplus.agriculture.common.blockentity.KitchenStorageBlockEntity;
import io.github.likexiang21.tfcplus.agriculture.common.blockentity.KnifeRackBlockEntity;
import io.github.likexiang21.tfcplus.agriculture.common.blockentity.MeltingPotBlockEntity;
import io.github.likexiang21.tfcplus.agriculture.common.blockentity.MortarBlockEntity;
import io.github.likexiang21.tfcplus.agriculture.common.blockentity.PlaceableFoodBlockEntity;
import io.github.likexiang21.tfcplus.agriculture.common.blockentity.SilkwormRackBlockEntity;
import io.github.likexiang21.tfcplus.agriculture.common.timber.BurningTimberPileBlockEntity;
import io.github.likexiang21.tfcplus.agriculture.common.timber.TimberBlocks;
import io.github.likexiang21.tfcplus.agriculture.common.timber.TimberPileBlockEntity;
import java.util.stream.Stream;
import net.dries007.tfc.util.registry.RegistrationHelpers;
import net.minecraft.core.registries.Registries;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.entity.BlockEntityType;
import net.neoforged.bus.api.IEventBus;
import net.neoforged.neoforge.registries.DeferredHolder;
import net.neoforged.neoforge.registries.DeferredRegister;

/**
 * B 层的方块实体注册表。
 *
 * <p>🛑 **本类是全项目最容易崩的地方**（A 层实测，126 §〇.3 红线 9）：
 * <ul>
 *   <li>凡有 BE 的方块，**必须**在这里的 {@code validBlocks} 里登记 ——
 *       否则**放置即崩**：{@code IllegalStateException: Invalid block entity}</li>
 *   <li>⚠️ TFC 的**静态 helper 一律按 TFC 自己的 BE 类型查表**（如 {@code setStemPos} / {@code resetPickedTick}），
 *       在**自建 BE 上静默失效** ⇒ 必须改用**实例方法**</li>
 *   <li>性能（126 §3.4）：空闲零开销 · **不 tick** · 不轮询邻居 · 一切循环有上限</li>
 * </ul>
 *
 * <p>⭐ <b>注册方式：复用 TFC 的 {@link RegistrationHelpers#register}</b>（实测 TFC 与 Firmalife 都这么做）。
 * 它的签名是：
 * <pre>
 * register(DeferredRegister&lt;BlockEntityType&lt;?&gt;&gt; reg, String name,
 *          BlockEntitySupplier&lt;T&gt; factory, Stream&lt;? extends Supplier&lt;? extends Block&gt;&gt; blocks)
 * </pre>
 * ⚠️ 我第一版试图直接 {@code new BlockEntityType<>(...)} ⇒ **编译失败**（构造器不可用，
 *    必须走 vanilla 的 {@code BlockEntityType.Builder}，而 TFC 的 helper 已经包好了）。
 *
 * <p>📌 <b>批次 1 rev4</b>：新增 {@link #KNIFE_BLOCK}（刀具架的 9 格存储，34 个木材变体共用）。
 */
public final class AgricultureBlockEntities {

    public static final DeferredRegister<BlockEntityType<?>> BLOCK_ENTITIES =
        DeferredRegister.create(Registries.BLOCK_ENTITY_TYPE, TFCAgriculturePlus.MOD_ID);

    /**
     * 🆕 <b>原木案板的 BE</b>（耐久）—— 用户口径：「**原木案板也要做耐久**」。
     * <p>⚠️ 与木板/石板案板**共用同一个 BE 类型**（`CuttingBoardBlockEntity` 的行为完全一致），
     * 只是 validBlocks 多注册 34 个原木变体。
     */
    public static final DeferredHolder<BlockEntityType<?>, BlockEntityType<CuttingBoardBlockEntity>> LOG_CUTTING_BOARD =
        RegistrationHelpers.register(
            BLOCK_ENTITIES,
            "log_cutting_board",
            CuttingBoardBlockEntity::new,
            AgricultureBlocks.LOG_CUTTING_BOARDS.values().stream()
                .map(h -> (java.util.function.Supplier<? extends Block>) h)
        );
    /**
     * 🆕 <b>刀具架的 BE</b> —— 34 个木材变体**共用同一个类型**。
     * <p>🛑 必须把**全部 34 个变体**都塞进 validBlocks，否则放置时崩。
     */
    public static final DeferredHolder<BlockEntityType<?>, BlockEntityType<KnifeRackBlockEntity>> KNIFE_BLOCK =
        RegistrationHelpers.register(
            BLOCK_ENTITIES,
            "knife_block",
            KnifeRackBlockEntity::new,
            AgricultureBlocks.KNIFE_BLOCKS.values().stream()
                .map(h -> (java.util.function.Supplier<? extends Block>) h)
        );

    /**
     * 🆕 <b>案板的 BE</b>（只记耐久）—— **55 个变体共用**（木 34 + 石 21）。
     * <p>⚠️ 只覆盖"木板/石板案板"，**原木案板暂时不接 BE**（它是早期廉价工具，先不做耐久）。
     */
    public static final DeferredHolder<BlockEntityType<?>, BlockEntityType<CuttingBoardBlockEntity>> CUTTING_BOARD =
        RegistrationHelpers.register(
            BLOCK_ENTITIES,
            "cutting_board",
            CuttingBoardBlockEntity::new,
            java.util.stream.Stream.concat(
                AgricultureBlocks.WOODEN_CUTTING_BOARDS.values().stream(),
                AgricultureBlocks.STONE_CUTTING_BOARDS.values().stream()
            ).map(h -> (java.util.function.Supplier<? extends Block>) h)
        );

    /**
     * 🆕 <b>石臼的 BE</b>（容器 + 研磨）—— **15 个岩石变体共用**。
     */
    public static final DeferredHolder<BlockEntityType<?>, BlockEntityType<MortarBlockEntity>> MORTAR =
        RegistrationHelpers.register(
            BLOCK_ENTITIES,
            "mortar",
            MortarBlockEntity::new,
            AgricultureBlocks.MORTARS.values().stream()
                .map(h -> (java.util.function.Supplier<? extends Block>) h)
        );

    /** 第一台持续加工设备：34 个木材变体共用一个干燥架类型。 */
    public static final DeferredHolder<BlockEntityType<?>, BlockEntityType<DryingRackBlockEntity>> DRYING_RACK =
        RegistrationHelpers.register(
            BLOCK_ENTITIES,
            "drying_rack",
            DryingRackBlockEntity::new,
            AgricultureBlocks.DRYING_RACKS.values().stream()
                .map(h -> (java.util.function.Supplier<? extends Block>) h)
        );

    /** B silkworm rack; one block state family and one TFC inventory contract. */
    public static final DeferredHolder<BlockEntityType<?>, BlockEntityType<SilkwormRackBlockEntity>> SILKWORM_RACK =
        RegistrationHelpers.register(
            BLOCK_ENTITIES,
            "silkworm_rack",
            SilkwormRackBlockEntity::new,
            java.util.stream.Stream.of(AgricultureBlocks.SILKWORM_RACK)
        );

    /** K1 kitchen furniture; every wood variant points to the same TFC inventory BE type. */
    public static final DeferredHolder<BlockEntityType<?>, BlockEntityType<KitchenStorageBlockEntity>> KITCHEN_STORAGE =
        RegistrationHelpers.register(
            BLOCK_ENTITIES,
            "kitchen_storage",
            KitchenStorageBlockEntity::new,
            java.util.stream.Stream.of(
                AgricultureBlocks.KITCHEN_COUNTER_CABINETS.values(),
                AgricultureBlocks.KITCHEN_HALF_CABINETS.values(),
                AgricultureBlocks.KITCHEN_SINK_CABINETS.values(),
                AgricultureBlocks.KITCHEN_SPICE_RACKS.values(),
                AgricultureBlocks.KITCHEN_FOOD_DISPLAYS.values(),
                AgricultureBlocks.KITCHEN_FRUIT_BOWLS.values()
            ).flatMap(java.util.Collection::stream)
                .map(h -> (java.util.function.Supplier<? extends Block>) h)
        );

    /** K2 pan state machine; one block uses the TFC inventory/tick contract. */
    public static final DeferredHolder<BlockEntityType<?>, BlockEntityType<CookingPanBlockEntity>> COOKING_PAN =
        RegistrationHelpers.register(
            BLOCK_ENTITIES,
            "cooking_pan",
            CookingPanBlockEntity::new,
            java.util.stream.Stream.of(AgricultureBlocks.COOKING_PAN)
        );

    public static final DeferredHolder<BlockEntityType<?>, BlockEntityType<DoughFormingTableBlockEntity>> DOUGH_TABLE =
        RegistrationHelpers.register(BLOCK_ENTITIES, "dough_forming_table", DoughFormingTableBlockEntity::new,
            java.util.stream.Stream.of(AgricultureBlocks.DOUGH_FORMING_TABLE));

    public static final DeferredHolder<BlockEntityType<?>, BlockEntityType<PlaceableFoodBlockEntity>> PLACEABLE_FOOD =
        RegistrationHelpers.register(BLOCK_ENTITIES, "placeable_food", PlaceableFoodBlockEntity::new,
            java.util.stream.Stream.of(AgricultureBlocks.WHOLE_PIE, AgricultureBlocks.WHOLE_CAKE, AgricultureBlocks.CREAM_CAKE, AgricultureBlocks.CHOCOLATE_CAKE,
                AgricultureBlocks.WHOLE_CHEESE, AgricultureBlocks.BUTTER_BLOCK, AgricultureBlocks.JELLY_BLOCK, AgricultureBlocks.SUGAR_BLOCK));

    public static final DeferredHolder<BlockEntityType<?>, BlockEntityType<MeltingPotBlockEntity>> MELTING_POT =
        RegistrationHelpers.register(BLOCK_ENTITIES, "melting_pot", MeltingPotBlockEntity::new,
            java.util.stream.Stream.of(AgricultureBlocks.MELTING_POT));

    public static void register(IEventBus bus) {
        BLOCK_ENTITIES.register(bus);
    }

    public static final DeferredHolder<BlockEntityType<?>, BlockEntityType<io.github.likexiang21.tfcplus.agriculture.common.timber.TimberPileBlockEntity>> TIMBER_PILE =
        RegistrationHelpers.register(BLOCK_ENTITIES, "log_pile", io.github.likexiang21.tfcplus.agriculture.common.timber.TimberPileBlockEntity::new,
            Stream.of(io.github.likexiang21.tfcplus.agriculture.common.timber.TimberBlocks.PILE));
    public static final DeferredHolder<BlockEntityType<?>, BlockEntityType<io.github.likexiang21.tfcplus.agriculture.common.timber.BurningTimberPileBlockEntity>> BURNING_TIMBER_PILE =
        RegistrationHelpers.register(BLOCK_ENTITIES, "burning_log_pile", io.github.likexiang21.tfcplus.agriculture.common.timber.BurningTimberPileBlockEntity::new,
            Stream.of(io.github.likexiang21.tfcplus.agriculture.common.timber.TimberBlocks.BURNING));

    private AgricultureBlockEntities() {}
}
