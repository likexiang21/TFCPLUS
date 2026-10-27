package io.github.likexiang21.tfcplus.farming.common.block;

import io.github.likexiang21.tfcplus.farming.common.registry.FarmingBlocks;
import io.github.likexiang21.tfcplus.farming.common.support.SeasonalPlantTimers;
import java.util.function.Supplier;
import net.dries007.tfc.common.blocks.ExtendedProperties;
import net.dries007.tfc.common.blocks.plant.fruit.Lifecycle;
import net.dries007.tfc.common.blocks.plant.fruit.SeasonalPlantBlock;
import net.dries007.tfc.common.blocks.plant.fruit.StationaryBerryBushBlock;
import net.dries007.tfc.util.climate.ClimateRange;
import net.minecraft.core.BlockPos;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.util.RandomSource;
import net.minecraft.world.InteractionHand;
import net.minecraft.world.ItemInteractionResult;
import net.minecraft.world.entity.LivingEntity;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.item.Item;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.phys.BlockHitResult;

/**
 * 浆果灌木（自有实现）。
 * <p>
 * 为什么要写子类：TFC 的 {@code StationaryBerryBushBlock.randomTick} 会在气候不适宜时执行
 * <pre>
 * level.setBlockAndUpdate(pos, this.getDeadState(state));
 * </pre>
 * 而它继承自 TFC 的 {@code getDeadState} 返回的是 **{@code TFCBlocks.DEAD_BERRY_BUSH}** ——
 * 也就是说本模组的灌木枯死后会变成「TFC 的死灌木」，掉落物也跟着变成 TFC 的（一根木棍 + TFC 的判定），
 * 与方块来源不一致。这里覆写它，指向本模组的 {@link FarmingBlocks#DEAD_BERRY_BUSH}。
 * <p>
 * <b>环境/气候行为完全由 TFC 提供，无需我们实现</b>：
 * <ul>
 *   <li>{@code randomTick} 里读取 {@code Climate.getAverageTemperature} 与下垫面的湿度，
 *       用我们传入的 {@link ClimateRange} 做 {@code checkBoth} 判定；</li>
 *   <li>它实现了 {@code HoeOverlayBlock}，按住锄头查看时会显示「湿度 / 平均温度」两行环境信息。</li>
 * </ul>
 * 前提是 {@code ExtendedProperties} 里绑定了气候数据能解析的引用，且方块实体存在
 * （{@code addHoeOverlayInfo} 里检查 {@code blockEntity instanceof BerryBushBlockEntity}）。
 * <p>
 * <b>采摘计时</b>：见 {@link SeasonalPlantTimers} —— TFC 采摘后调的是静态 helper，
 * 在自建 BE 类型下静默失效，必须在这里用实例方法补上。
 */
public class FarmingBerryBushBlock extends StationaryBerryBushBlock {

    public FarmingBerryBushBlock(ExtendedProperties properties, Supplier<? extends Item> productItem,
                            Lifecycle[] lifecycle, Supplier<ClimateRange> climateRange) {
        super(properties, productItem, lifecycle, climateRange);
    }

    /** Prepare project counters before either native climate checks or scheduled growth. */
    @Override
    protected void randomTick(BlockState state, ServerLevel level, BlockPos pos, RandomSource random) {
        SeasonalPlantTimers.prepareBush(level, pos);
        super.randomTick(state, level, pos, random);
    }

    @Override
    public void tick(BlockState state, ServerLevel level, BlockPos pos, RandomSource random) {
        SeasonalPlantTimers.prepareBush(level, pos);
        super.tick(state, level, pos, random);
    }

    /** 气候不适宜 → 变成**本模组**的枯死灌木（保留原有的生长阶段 stage） */
    @Override
    protected BlockState getDeadState(BlockState state) {
        return FarmingBlocks.DEAD_BERRY_BUSH.get().defaultBlockState()
            .setValue(SeasonalPlantBlock.STAGE, state.getValue(SeasonalPlantBlock.STAGE));
    }

    /** 采摘成功后补上 TFC 那句失效的采摘计时重置（详见 {@link SeasonalPlantTimers}） */
    @Override
    protected ItemInteractionResult useItemOn(ItemStack stack, BlockState state, Level level, BlockPos pos,
                                              Player player, InteractionHand hand, BlockHitResult hit) {
        return SeasonalPlantTimers.afterUse(level, pos,
            super.useItemOn(stack, state, level, pos, player, hand, hit));
    }

    /**
     * 放下后补上生长计时器的**播种**（详见 {@link SeasonalPlantTimers}）。
     * <p>
     * 缺这一句的后果是实测过的：{@code StationaryBerryBushBlock.tick} 用
     * {@code getTicksSinceUpdate() / berryBushGrowthTicks} 算生长次数，
     * 而计时器从未播种时该值约 2.1e9 → 取上限 8 → **第一次随机刻直接长满三阶段**。
     */
    @Override
    public void setPlacedBy(Level level, BlockPos pos, BlockState state, LivingEntity placer, ItemStack stack) {
        super.setPlacedBy(level, pos, state, placer, stack);
        SeasonalPlantTimers.afterPlace(level, pos);
    }
}
