package com.example.tfcfarmingplus.common.blocks;

import com.example.tfcfarmingplus.common.MyBlocks;
import net.dries007.tfc.common.blocks.ExtendedProperties;
import net.dries007.tfc.common.blocks.plant.fruit.Lifecycle;
import net.dries007.tfc.common.blocks.plant.fruit.SeasonalPlantBlock;
import net.dries007.tfc.common.blocks.plant.fruit.SpreadingBushBlock;
import net.dries007.tfc.common.blocks.plant.fruit.SpreadingCaneBlock;
import net.dries007.tfc.util.climate.ClimateRange;
import net.minecraft.core.BlockPos;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.util.RandomSource;
import net.minecraft.world.InteractionHand;
import net.minecraft.world.ItemInteractionResult;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.item.Item;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.phys.BlockHitResult;

import java.util.function.Supplier;

/**
 * 蔓生浆果灌木的**藤蔓段**（自有实现）。
 * <p>
 * 由 {@link MySpreadingBushBlock} 通过构造器里的 {@code companion} 引用在生长时放置：
 * 主丛长满 stage 2 后会向相邻方块蔓延出藤蔓，藤蔓再自行向上/向旁延伸，直到 {@code maxHeight} 格。
 * <p>
 * 与主丛的差别（照 TFC {@link SpreadingCaneBlock}）：
 * <ul>
 *   <li>额外一个 {@code facing}（水平朝向）属性，配合 4 个 {@code *_bush_side_*} 侧向模型；</li>
 *   <li>{@code getStateForPlacement} 按玩家朝向设置 facing；</li>
 *   <li><b>没有方块物品</b> —— 不能像主丛那样被整株挖回家，因为藤蔓靠主丛生长获得。</li>
 * </ul>
 * <p>
 * 它同样绑**自建的** {@code BERRY_BUSH} 方块实体类型（存采摘计时与 stemPos），
 * 这样按住锄头能像 TFC 一样看到「湿度 / 平均温度」环境提示。
 * <p>
 * <b>采摘计时</b>：见 {@link MySeasonalPlantFix} —— 果实结在藤蔓上，采摘路径与主丛相同。
 */
public class MySpreadingCaneBlock extends SpreadingCaneBlock {

    public MySpreadingCaneBlock(ExtendedProperties properties, Supplier<? extends Item> productItem,
                                Lifecycle[] lifecycle, Supplier<? extends Block> companion,
                                int maxHeight, Supplier<ClimateRange> climateRange) {
        super(properties, productItem, lifecycle, companion, maxHeight, climateRange);
    }

    /** Prepare project counters before either native climate checks or scheduled growth. */
    @Override
    protected void randomTick(BlockState state, ServerLevel level, BlockPos pos, RandomSource random) {
        MySeasonalPlantFix.prepareBush(level, pos);
        super.randomTick(state, level, pos, random);
    }

    @Override
    public void tick(BlockState state, ServerLevel level, BlockPos pos, RandomSource random) {
        MySeasonalPlantFix.prepareBush(level, pos);
        super.tick(state, level, pos, random);
    }

    /**
     * 气候不适宜 → 变成**本模组**的枯死藤蔓。
     * <p>
     * 与主丛不同，藤蔓要保留 {@code facing}：枯藤的模型是侧向的，
     * 丢掉朝向会让整片枯藤的贴图方向错乱。
     */
    @Override
    protected BlockState getDeadState(BlockState state) {
        return MyBlocks.DEAD_CANE.get().defaultBlockState()
            .setValue(SeasonalPlantBlock.STAGE, state.getValue(SeasonalPlantBlock.STAGE))
            .setValue(SpreadingCaneBlock.FACING, state.getValue(SpreadingCaneBlock.FACING));
    }

    /** 采摘成功后补上 TFC 那句失效的采摘计时重置（详见 {@link MySeasonalPlantFix}） */
    @Override
    protected ItemInteractionResult useItemOn(ItemStack stack, BlockState state, Level level, BlockPos pos,
                                              Player player, InteractionHand hand, BlockHitResult hit) {
        return MySeasonalPlantFix.afterUse(level, pos,
            super.useItemOn(stack, state, level, pos, player, hand, hit));
    }
}
