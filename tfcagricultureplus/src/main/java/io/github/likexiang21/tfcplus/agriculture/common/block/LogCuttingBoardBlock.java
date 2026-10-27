package io.github.likexiang21.tfcplus.agriculture.common.block;

import io.github.likexiang21.tfcplus.agriculture.common.registry.AgricultureBlockEntities;
import io.github.likexiang21.tfcplus.agriculture.common.blockentity.CuttingBoardBlockEntity;
import io.github.likexiang21.tfcplus.agriculture.common.registry.AgricultureBlocks;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.world.level.BlockGetter;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.HorizontalDirectionalBlock;
import net.minecraft.world.level.block.state.BlockBehaviour;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.StateDefinition;
import net.minecraft.world.phys.shapes.CollisionContext;
import net.minecraft.world.phys.shapes.Shapes;
import net.minecraft.world.phys.shapes.VoxelShape;

/**
 * 🆕 <b>原木案板</b> —— 用户口径：「原木类型的案板应该显示为一个"**木桩子**"」+「模型太高，**压扁**」。
 *
 * <p>所以它**不复用案板的几何**，而是**矮的一段原木（树桩）**：
 * <ul>
 *   <li>柱身：{@code [2,0,2] → [14,5,14]}（12×**5**×12 —— 已按用户口径从 10 压到 5）</li>
 *   <li><b>侧面 = 树皮</b>（{@code tfc/afc:block/wood/log/<wood>}）</li>
 *   <li><b>顶面 = 年轮截面</b>（{@code tfc/afc:block/wood/log_top/<wood>}）</li>
 *   <li>碰撞箱：{@code box(0.125, 0, 0.125, 0.875, 0.3125, 0.875)}</li>
 * </ul>
 * Shares cutting, storage and durability with the other boards, with a separate BE type.
 */
public class LogCuttingBoardBlock extends CuttingBoardBlock {

    /** 树桩的碰撞箱（与几何一致：12 宽 × 5 高）。 */
    private static final VoxelShape SHAPE = Shapes.box(0.125, 0.0, 0.125, 0.875, 0.3125, 0.875);

    public LogCuttingBoardBlock(BlockBehaviour.Properties props) {
        super(props);
        registerDefaultState(stateDefinition.any().setValue(AgricultureBlocks.FACING, Direction.NORTH));
    }

    @Override
    protected void createBlockStateDefinition(StateDefinition.Builder<Block, BlockState> builder) {
        builder.add(AgricultureBlocks.FACING);
    }

    @Override
    protected VoxelShape getShape(BlockState state, BlockGetter level, BlockPos pos, CollisionContext ctx) {
        return SHAPE;
    }

    @Override
    protected com.mojang.serialization.MapCodec<? extends HorizontalDirectionalBlock> codec() {
        return simpleCodec(LogCuttingBoardBlock::new);
    }
    /** 🆕 破坏时掉落内部物品（用户口径）—— 注意返回类型是 BlockState，不是 void。 */
    @Override
    public BlockState playerWillDestroy(net.minecraft.world.level.Level level, BlockPos pos,
                                        BlockState state, net.minecraft.world.entity.player.Player player) {
        AgricultureBlocks.dropContentsOnBreak(level, pos);
        return super.playerWillDestroy(level, pos, state, player);
    }

    // 🆕 耐久（用户口径：「原木案板也要做耐久」）
    // 🛑 必须用 **LOG_CUTTING_BOARD** 这个 BE 类型（不是 CUTTING_BOARD）——
    //    用错类型会立刻崩：IllegalStateException: Invalid block entity（本轮实测）
    @Override
    public io.github.likexiang21.tfcplus.agriculture.common.blockentity.CuttingBoardBlockEntity newBlockEntity(
        BlockPos pos, BlockState state) {
        return new io.github.likexiang21.tfcplus.agriculture.common.blockentity.CuttingBoardBlockEntity(
            AgricultureBlockEntities.LOG_CUTTING_BOARD.get(), pos, state);
    }

    @Override
    public <T extends net.minecraft.world.level.block.entity.BlockEntity> net.minecraft.world.level.block.entity.BlockEntityTicker<T> getTicker(
        net.minecraft.world.level.Level level, BlockState state,
        net.minecraft.world.level.block.entity.BlockEntityType<T> type) {
        return null;
    }
}
