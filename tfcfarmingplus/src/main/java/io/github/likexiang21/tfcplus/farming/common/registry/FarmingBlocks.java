package io.github.likexiang21.tfcplus.farming.common.registry;

import io.github.likexiang21.tfcplus.farming.TFCFarmingPlus;
import net.dries007.tfc.common.blocks.ExtendedProperties;
import net.dries007.tfc.common.blocks.crop.DeadCropBlock;
import net.dries007.tfc.common.blocks.plant.fruit.DeadBerryBushBlock;
import net.dries007.tfc.common.blocks.plant.fruit.DeadCaneBlock;
import net.dries007.tfc.util.climate.ClimateRange;
import net.minecraft.core.registries.Registries;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.SoundType;
import net.minecraft.world.level.material.MapColor;
import net.minecraft.world.level.material.PushReaction;
import net.neoforged.neoforge.registries.DeferredHolder;
import net.neoforged.neoforge.registries.DeferredRegister;

/**
 * 方块注册总入口。
 * <p>
 * 命名约定（照 TFC）：
 * <ul>
 *   <li>作物 {@code <ns>:crop/<name>}</li>
 *   <li>作物枯萎状态 {@code <ns>:dead_crop/<name>}（<b>每种作物一个</b>，见 {@link FarmingCrops}）</li>
 *   <li>浆果灌木 {@code <ns>:plant/<name>_bush>}、枯死灌木 {@code <ns>:plant/dead_berry_bush}</li>
 * </ul>
 */
public final class FarmingBlocks {
    public static final DeferredRegister<Block> BLOCKS = DeferredRegister.create(Registries.BLOCK, TFCFarmingPlus.MOD_ID);

    // ---------------- 枯萎 / 枯死状态 ----------------

    /**
     * 浆果灌木枯死后的方块（照 TFC 的 {@code tfc:plant/dead_berry_bush}）。
     * <p>
     * 由 {@code StationaryBerryBushBlock.randomTick} 在气候不适宜时切换过来：
     * {@code climateRange.checkBoth(...) == false → level.setBlockAndUpdate(pos, getDeadState(state))}。
     * 我们在 {@code FarmingBerryBushBlock} 里覆写 {@code getDeadState} 指向这个方块，
     * 否则灌木枯死时会变成 **TFC 的** 死灌木（掉落物也变成 TFC 的）。
     * <p>
     * ⚠️ 刻意**不绑方块实体**：TFC 原版给死灌木挂了 {@code TFCBlockEntities.TICK_COUNTER}
     * （用于随机自然消失的计时），但借用 TFC 的 BE 类型会被原版
     * {@code BlockEntity.validateBlockState} 拦下（详见 {@link FarmingBlockEntities}）。
     * 不绑 BE 的唯一后果是「死灌木不会自己随机消失」，对玩法无影响。
     */
    public static final DeferredHolder<Block, DeadBerryBushBlock> DEAD_BERRY_BUSH =
        BLOCKS.register("plant/dead_berry_bush", () -> new DeadBerryBushBlock(
            ExtendedProperties.of(MapColor.PLANT)
                .strength(0.6f)
                .noOcclusion()
                .sound(SoundType.SWEET_BERRY_BUSH)
                .randomTicks()
                .flammable(120, 90)));

    /**
     * 蔓生灌木**藤蔓**枯死后的方块（照 TFC 的 {@code tfc:plant/dead_cane}）。
     * <p>
     * 由 {@code SpreadingCaneBlock.randomTick} 在气候不适宜时切换过来，见
     * {@code FarmingSpreadingCaneBlock#getDeadState}。
     * <p>
     * 直接实例化 TFC 的 {@link DeadCaneBlock}（构造器 public，内部已写死
     * {@code productItem=AIR / companion=AIR / maxHeight=0}，正是枯藤应有的语义），
     * 因此这里**零新方块类**。它带 {@code stage} + {@code facing} 两个属性，
     * 对应 12 个侧向模型变体。
     * <p>
     * ⚠️ 与 {@link #DEAD_BERRY_BUSH} 同样刻意**不绑方块实体**：TFC 原版给枯藤挂了
     * {@code TICK_COUNTER}（用于 1920000 tick 后随机自然消失），借用会被原版
     * {@code BlockEntity.validateBlockState} 拦下。不绑 BE 的后果仅是「枯藤不会自己消失」。
     */
    public static final DeferredHolder<Block, DeadCaneBlock> DEAD_CANE =
        BLOCKS.register("plant/dead_cane", () -> new DeadCaneBlock(
            ExtendedProperties.of(MapColor.PLANT)
                .strength(0.6f)
                .noOcclusion()
                .sound(SoundType.SWEET_BERRY_BUSH)
                .randomTicks()
                .flammable(120, 90)));

    /** 莲座式死株（{@code RosetteCropBlock} 专用；普通作物改为每种一个独立死株） */
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_ROSETTE = BLOCKS.register("dead_rosette",
        () -> new DeadCropBlock(deadProps(), () -> ClimateRange.NOOP));

    /** TFC 的 {@code Crop.dead()} 是 private，这里写一份等价的属性 */
    public static ExtendedProperties deadProps() {
        return ExtendedProperties.of(MapColor.PLANT)
            .noCollission()
            .randomTicks()
            .strength(0.4f)
            .sound(SoundType.CROP)
            .flammable(60, 30)
            .pushReaction(PushReaction.DESTROY);
    }

    /** 作物通用属性（含方块实体与 ticker 绑定） */
    public static ExtendedProperties cropProps() {
        return ExtendedProperties.of(MapColor.PLANT)
            .noCollission()
            .randomTicks()
            .strength(0.4f)
            .sound(SoundType.CROP)
            .flammable(60, 30)
            .pushReaction(PushReaction.DESTROY);
    }

    private FarmingBlocks() {}
}
