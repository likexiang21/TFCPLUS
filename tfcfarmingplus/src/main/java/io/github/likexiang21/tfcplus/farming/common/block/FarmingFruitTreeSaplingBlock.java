package io.github.likexiang21.tfcplus.farming.common.block;

import java.util.function.Supplier;
import net.dries007.tfc.common.TFCTags;
import net.dries007.tfc.common.blockentities.TickingPlantBlockEntity;
import net.dries007.tfc.common.blocks.ExtendedProperties;
import net.dries007.tfc.common.blocks.plant.fruit.FruitTreeSaplingBlock;
import net.dries007.tfc.common.blocks.plant.fruit.Lifecycle;
import net.dries007.tfc.util.climate.ClimateRange;
import net.minecraft.core.BlockPos;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.util.RandomSource;
import net.minecraft.world.entity.LivingEntity;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.state.BlockState;

/**
 * 项目树苗的生命周期接线。形状、生长判定和树形仍交给 TFC；
 * 放置、旧苗恢复和转枝三个边界使用当前实体的实例接口写入计时与根坐标。
 * 旧版失效静态 helper 的排查历史见工作区 71、76 和 226 号记录。
 */
public class FarmingFruitTreeSaplingBlock extends FruitTreeSaplingBlock {
    private static final long UNINITIALIZED_TICK = Integer.MIN_VALUE;

    public FarmingFruitTreeSaplingBlock(ExtendedProperties properties, Supplier<? extends Block> block,
                                   Supplier<Integer> ticksToGrow, Supplier<ClimateRange> climateRange,
                                   Lifecycle[] stages) {
        super(properties, block, ticksToGrow, climateRange, stages);
    }

    @Override
    public void setPlacedBy(Level level, BlockPos pos, BlockState state, LivingEntity placer, ItemStack stack) {
        super.setPlacedBy(level, pos, state, placer, stack);
        if (!level.isClientSide()) {
            prepareSapling(level, pos, true);
        }
    }

    @Override
    protected void randomTick(BlockState state, ServerLevel level, BlockPos pos, RandomSource random) {
        // 旧存档中的嫁接苗也校正根坐标；已有有效计时不重置。
        prepareSapling(level, pos, false);
        super.randomTick(state, level, pos, random);
    }

    @Override
    public void createTree(Level level, BlockPos pos, BlockState state, RandomSource random,
                           long ticksToAdd, BlockPos stemPos) {
        if (level.isClientSide()) {
            return;
        }
        super.createTree(level, pos, state, random, ticksToAdd, stemPos);
        // 此回调接到 TFC 算出的实际剩余时间，避免另算阈值或重复结转。
        if (level.getBlockState(pos).is(block.get())
            && level.getBlockEntity(pos) instanceof TickingPlantBlockEntity branch) {
            branch.setStemPos(stemPos);
            branch.resetCounter();
            branch.increaseCounter(Math.max(0L, ticksToAdd));
        }
    }

    private void prepareSapling(Level level, BlockPos pos, boolean newlyPlaced) {
        if (!(level.getBlockEntity(pos) instanceof TickingPlantBlockEntity counter)) {
            return;
        }
        BlockPos belowPos = pos.below();
        BlockState support = level.getBlockState(belowPos);
        BlockPos root = support.is(TFCTags.Blocks.FRUIT_TREE_BRANCH)
            ? findBaseOfTree(level, belowPos, support) : pos;
        if (!root.equals(counter.getStemPos())) {
            counter.setStemPos(root);
        }
        if (newlyPlaced || counter.getLastUpdateTick() == UNINITIALIZED_TICK) {
            counter.resetCounter();
        }
    }
}
