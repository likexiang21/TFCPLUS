package com.example.tfcfarmingplus.common.blocks;

import net.dries007.tfc.common.blockentities.TickingPlantBlockEntity;
import net.dries007.tfc.common.blocks.ExtendedProperties;
import net.dries007.tfc.common.blocks.plant.fruit.GrowingFruitTreeBranchBlock;
import net.dries007.tfc.util.climate.Climate;
import net.dries007.tfc.util.climate.ClimateRange;
import net.minecraft.core.BlockPos;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.util.RandomSource;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.state.BlockState;

import java.util.function.Supplier;

/**
 * Project entity bridge for native fruit-tree growth callbacks.
 * Cultivated climate pauses use the actual entity instance. Natural branches with
 * the uninitialized tick sentinel receive a finite starting age before growth.
 * Existing ages and root coordinates are retained; native code owns tree shape,
 * child initialization, climate rules and subsequent progress.
 * Independently implemented against the installed TFC callback/API contract.
 */
public class MyGrowingFruitTreeBranchBlock extends GrowingFruitTreeBranchBlock {

    private static final long UNINITIALIZED_TICK = Integer.MIN_VALUE;
    // Project recovery budget, using the installed feature's 7.2M tick advance.
    // Reset first: adding to a sentinel is not a valid finite starting age.
    private static final long NATURAL_INITIAL_TICKS = 7_200_000L;

    /** 父类的同名字段是 private，这里另存一份引用（就是我们构造时传进去的那个 Supplier） */
    private final Supplier<ClimateRange> climateRange;

    public MyGrowingFruitTreeBranchBlock(ExtendedProperties properties, Supplier<? extends Block> body,
                                         Supplier<? extends Block> leaves, Supplier<ClimateRange> climateRange) {
        super(properties, body, leaves, climateRange);
        this.climateRange = climateRange;
    }

    @Override
    public void tick(BlockState state, ServerLevel level, BlockPos pos, RandomSource random) {
        if (state.getValue(NATURAL)
            && level.getBlockEntity(pos) instanceof TickingPlantBlockEntity counter
            && counter.getLastUpdateTick() == UNINITIALIZED_TICK) {
            counter.resetCounter();
            counter.increaseCounter(NATURAL_INITIAL_TICKS);
        }
        super.tick(state, level, pos, random);
    }

    /** Public bridge to the installed native root hydration calculation. */
    public static int rootHydration(Level level, BlockPos pos) {
        return getFruitBranchHydration(level, pos);
    }

    @Override
    public void grow(BlockState state, ServerLevel level, BlockPos pos, RandomSource random, int cyclesLeft) {
        BlockPos root = level.getBlockEntity(pos) instanceof TickingPlantBlockEntity source ? source.getStemPos() : pos;
        super.grow(state, level, pos, random, cyclesLeft);
        if (level.getBlockState(pos).getBlock() instanceof MyFruitingBranchBlock
            && level.getBlockEntity(pos) instanceof TickingPlantBlockEntity mature) {
            mature.setStemPos(root);
            if (mature.getLastUpdateTick() == UNINITIALIZED_TICK) mature.resetCounter();
        }
    }

    @Override
    protected void randomTick(BlockState state, ServerLevel level, BlockPos pos, RandomSource random) {
        if (!state.getValue(NATURAL)
            && level.getBlockEntity(pos) instanceof TickingPlantBlockEntity be
            && !climateRange.get().checkBoth(getFruitBranchHydration(level, pos),
                                             Climate.getAverageTemperature(level, pos), false)) {
            be.resetCounter();
        }
        super.randomTick(state, level, pos, random);

        // 快速检查开关：额外推进计时器，让枝条在几次 randomTick 内抽条/长叶
        // （TFC 自然生长需数百万 tick）。用**实例**方法 increaseCounter ——
        // 静态 helper addTicks 与 reset 一样会按 TFC 的 BE 类型做比较，在自建 BE 上静默失效。
        if (com.example.tfcfarmingplus.common.FastGrow.ENABLED
            && level.getBlockEntity(pos) instanceof TickingPlantBlockEntity be) {
            be.increaseCounter(com.example.tfcfarmingplus.common.FastGrow.BRANCH_TICKS);
        }
    }
}
