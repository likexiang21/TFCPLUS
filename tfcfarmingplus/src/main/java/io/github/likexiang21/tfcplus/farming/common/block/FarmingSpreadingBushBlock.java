package io.github.likexiang21.tfcplus.farming.common.block;

import io.github.likexiang21.tfcplus.farming.common.registry.FarmingBlocks;
import io.github.likexiang21.tfcplus.farming.common.support.SeasonalPlantTimers;
import java.util.function.Supplier;
import net.dries007.tfc.common.blocks.ExtendedProperties;
import net.dries007.tfc.common.blocks.plant.fruit.Lifecycle;
import net.dries007.tfc.common.blocks.plant.fruit.SeasonalPlantBlock;
import net.dries007.tfc.common.blocks.plant.fruit.SpreadingBushBlock;
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
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.phys.BlockHitResult;

/**
 * 蔓生浆果灌木的**主丛**（自有实现）。
 * <p>
 * TFC 的浆果丛有两种形态，二者是不同的方块类、不能互相替换：
 * <table border="1">
 *   <tr><th>形态</th><th>方块类</th><th>格高</th><th>TFC 实例</th></tr>
 *   <tr><td>矮丛</td><td>{@link net.dries007.tfc.common.blocks.plant.fruit.StationaryBerryBushBlock}</td>
 *       <td>1 格（{@code HALF_PLANT} / {@code Shapes.block()}）</td><td>云莓、矮丛蓝莓、雪果</td></tr>
 *   <tr><td><b>蔓生</b></td><td>{@link SpreadingBushBlock}</td>
 *       <td>1 格起步，会向四周/上方长出 {@code *_bush_cane} 藤蔓</td><td>黑莓、树莓、蓝莓、接骨木莓</td></tr>
 * </table>
 * <p>
 * 本类用于**现实中呈蔓生/攀援习性**的浆果（枸杞、蓝靛果、唐棣、野樱莓、黑加仑、红加仑）：
 * 它们会像 TFC 黑莓那样向相邻方块蔓延出藤蔓（{@code companion} 即配套的 {@code *_bush_cane} 方块），
 * 长满 {@code maxHeight} 格后停止，果实结在藤蔓上。
 * <p>
 * 构造器照抄 TFC {@code FruitBlocks.SpreadingBush.createBush()} 的参数顺序：
 * {@code (properties, productItem, stages, companion, maxHeight, climateRange)}。
 * <p>
 * 覆写 {@link #getDeadState} 的理由与 {@link FarmingBerryBushBlock} 完全相同：
 * TFC 的默认实现返回 **TFC 的**死灌木，会让本模组的植物枯死后变成别人的方块。
 * <p>
 * <b>采摘计时</b>：见 {@link SeasonalPlantTimers}。
 */
public class FarmingSpreadingBushBlock extends SpreadingBushBlock {

    public FarmingSpreadingBushBlock(ExtendedProperties properties, Supplier<? extends Item> productItem,
                                Lifecycle[] lifecycle, Supplier<? extends Block> companion,
                                int maxHeight, Supplier<ClimateRange> climateRange) {
        super(properties, productItem, lifecycle, companion, maxHeight, climateRange);
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
    @Override
    public void setPlacedBy(Level level, BlockPos pos, BlockState state, LivingEntity placer, ItemStack stack) {
        super.setPlacedBy(level, pos, state, placer, stack);
        SeasonalPlantTimers.afterPlace(level, pos);
        SeasonalPlantTimers.prepareBush(level, pos);
    }

}
