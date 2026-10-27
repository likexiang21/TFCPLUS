package io.github.likexiang21.tfcplus.farming.common.registry;

import io.github.likexiang21.tfcplus.farming.TFCFarmingPlus;
import io.github.likexiang21.tfcplus.farming.common.blockentity.FarmingBerryBushBlockEntity;
import io.github.likexiang21.tfcplus.farming.common.blockentity.FarmingDecayingBlockEntity;
import io.github.likexiang21.tfcplus.farming.common.crop.FarmingBushes;
import io.github.likexiang21.tfcplus.farming.common.crop.FarmingCrops;
import io.github.likexiang21.tfcplus.farming.common.tree.FarmingFruitTrees;
import net.dries007.tfc.common.blockentities.CropBlockEntity;
import net.dries007.tfc.common.blockentities.DecayingBlockEntity;
import net.dries007.tfc.common.blockentities.TickingPlantBlockEntity;
import net.minecraft.core.registries.Registries;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.entity.BlockEntityType;
import net.neoforged.neoforge.registries.DeferredHolder;
import net.neoforged.neoforge.registries.DeferredRegister;

/**
 * 方块实体类型注册 —— <b>必须自建，不能借用 TFC 的</b>。
 *
 * <h2>为什么必须自建（实测崩溃记录）</h2>
 * 1.21 的原版 {@code BlockEntity} 构造器会调用 {@code validateBlockState(...)}，
 * 校验 {@code BlockEntityType.isValid(state)} —— 也就是「这个方块是否被登记在该 BE 类型的 validBlocks 里」。
 * TFC 的 {@code TFCBlockEntities.CROP} / {@code BERRY_BUSH} 在注册时只登记了 TFC 自己的方块，
 * 所以只要把 {@code tfcfarmingplus:crop/*} 或 {@code tfcfarmingplus:plant/*_bush} 挂到 TFC 的类型上，
 * 玩家一放下方块就会：
 * <pre>
 * java.lang.IllegalStateException: Invalid block entity tfc:crop // CropBlockEntity state offset BlockPos{...},
 *     got Block{tfcfarmingplus:crop/cauliflower}[age=0]
 *   offset net.minecraft.world.level.block.entity.BlockEntity.validateBlockState(BlockEntity.java:52)
 * </pre>
 * 而且 TFC 的两个 BE 便捷构造器都把类型写死成自己的：
 * <pre>
 * CropBlockEntity(BlockPos, BlockState)   → this(TFCBlockEntities.CROP.get(), pos, state)
 * BerryBushBlockEntity(BlockPos, BlockState) → this(TFCBlockEntities.BERRY_BUSH.get(), pos, state)
 * </pre>
 * 因此正确做法是注册自己的类型，并在工厂里显式传入自己的类型。
 *
 * <h2>自建后的代价（已核对，均为零）</h2>
 * <ul>
 *   <li>{@code CropBlockEntity} 带类型参数的构造器是 {@code public}，直接用即可；
 *       {@code TFCBlockEntities.CROP} 在 TFC 源码里只出现在该便捷构造器中，没有任何「按类型查找」的调用。</li>
 *   <li>{@code BerryBushBlockEntity} 带类型参数的构造器是 {@code protected}，故用
 *       {@link FarmingBerryBushBlockEntity} 子类转发。它的两个静态 helper
 *       {@code reset} / {@code resetPickedTick} 是**按 TFC 类型查找**的，在自建类型上静默失效 ——
 *       其中 {@code resetPickedTick} 确有影响（采收冷却不重置），由
 *       {@link io.github.likexiang21.tfcplus.farming.common.support.SeasonalPlantTimers} 用实例方法补上。</li>
 * </ul>
 *
 * 树干果实要引用这里的 {@link #BERRY_BUSH}（挂在 TFC 的物候机制上），
 * 而这里又要在 {@code validBlocks} 里登记树干果实方块 —— 看起来是循环。
 * 破解点是 {@code DeferredRegister.register(name, supplier)} 的 supplier <b>延迟执行</b>：
 * 只在真正注册 BE 类型时才求值，那时两个类的静态初始化都已跑完，不存在环。
 */
public final class FarmingBlockEntities {

    public static final DeferredRegister<BlockEntityType<?>> BLOCK_ENTITIES =
        DeferredRegister.create(Registries.BLOCK_ENTITY_TYPE, TFCFarmingPlus.MOD_ID);

    /** 作物方块实体（tfcfarmingplus:crop/*） */
    public static final DeferredHolder<BlockEntityType<?>, BlockEntityType<CropBlockEntity>> CROP =
        BLOCK_ENTITIES.register("crop", () -> BlockEntityType.Builder
            .of((pos, state) -> new CropBlockEntity(FarmingBlockEntities.CROP.get(), pos, state),
                FarmingCrops.cropBlocks())
            .build(null));

    /** 浆果灌木方块实体（tfcfarmingplus:plant/*_bush） */
    public static final DeferredHolder<BlockEntityType<?>, BlockEntityType<FarmingBerryBushBlockEntity>> BERRY_BUSH =
        BLOCK_ENTITIES.register("berry_bush", () -> BlockEntityType.Builder
            // ⚠️ 三类方块共用它，漏任何一个都会在放下方块时抛 Invalid block entity：
            //    - 浆果灌木（季节物候 + 采收冷却）
            //    - 果树树叶（FruitTreeLeavesBlock 靠它存 stemPos / lastPickedTick / growthsRemaining）
            //    - 树干果实（SeasonalPlantBlock.onUpdate 要求 BE instanceof BerryBushBlockEntity）
            .of(FarmingBerryBushBlockEntity::new, concat(FarmingBushes.bushBlocks(),
                FarmingFruitTrees.fruitingBlocks()))
            .build(null));

    /**
     * 整瓜的食品状态实体。工厂和手动放置均创建项目自己的类型。
     * 腐烂目标是普通方块，不需要继续tick；有效宿主列表中的旧腐烂编号保留用于兼容。
     */
    public static final DeferredHolder<BlockEntityType<?>, BlockEntityType<DecayingBlockEntity>> DECAYING =
        BLOCK_ENTITIES.register("decaying", () -> BlockEntityType.Builder
            .<DecayingBlockEntity>of(FarmingDecayingBlockEntity::new, FarmingCrops.fruitBlocks())
            .build(null));

    /**
     * 果树树苗与生长枝干的**计时器**（对应 TFC 的 {@code TICK_COUNTING_PLANT}）。
     * <p>
     * 自建而非借用 TFC 的类型，理由见本类注释（§5.6 实测：1.21 的 {@code BlockEntity}
     * 构造器会调 {@code validateBlockState}，非本类型的方块会被判非法并抛
     * {@code Invalid block entity}）。
     * <p>
     * 好消息：{@code TickingPlantBlockEntity} 的带类型构造器是 **public**，
     * 所以这里不需要像 {@code BerryBushBlockEntity} 那样再包一层子类。
     */
    public static final DeferredHolder<BlockEntityType<?>, BlockEntityType<TickingPlantBlockEntity>> TICK_COUNTING_PLANT =
        BLOCK_ENTITIES.register("tick_counting_plant", () -> BlockEntityType.Builder
            .of((pos, state) -> new TickingPlantBlockEntity(FarmingBlockEntities.TICK_COUNTING_PLANT.get(), pos, state),
                FarmingFruitTrees.tickingBlocks())
            .build(null));

    /** 合并若干方块数组（BE 的 validBlocks 需要同时容纳灌木、树叶与树干果实） */
    private static Block[] concat(Block[]... arrays) {
        int total = 0;
        for (final Block[] blocks : arrays) {
            total += blocks.length;
        }
        final Block[] resultBlocks = new Block[total];
        int offset = 0;
        for (final Block[] blocks : arrays) {
            System.arraycopy(blocks, 0, resultBlocks, offset, blocks.length);
            offset += blocks.length;
        }
        return resultBlocks;
    }

    /** 触发静态初始化 —— 主类必须调用一次 */
    public static void init() {}

    private FarmingBlockEntities() {}
}
