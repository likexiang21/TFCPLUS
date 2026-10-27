package io.github.likexiang21.tfcplus.agriculture.common.block;

import io.github.likexiang21.tfcplus.agriculture.common.blockentity.CuttingBoardBlockEntity;
import io.github.likexiang21.tfcplus.agriculture.common.interaction.CuttingBoardInteractions;
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
 * <b>案板</b> —— 食品加工的第一道工序（切 · 剁 · 切片 · 去核 · 切丝）。
 *
 * <p>🆕 <b>几何与碰撞箱</b>（用户口径：「碰撞箱和实际模型不贴切」）：
 * <ul>
 *   <li>板身：{@code [0,0,0] → [16,2,16]}（2 像素厚）</li>
 *   <li><b>四周挡边</b>：{@code y=2→3} 的四条窄边（让它在视觉上是一块"砧板"而不是一张纸）</li>
 *   <li>碰撞箱：{@code box(0,0,0,16,2,16)}（**只到板身**，挡边不挡人）</li>
 * </ul>
 */
public class CuttingBoardBlock extends HorizontalDirectionalBlock
    implements net.minecraft.world.level.block.EntityBlock {

    /** 🆕 碰撞箱：台面 14×1×14 + 四周 1px 包边（顶到 y=2）。 */
    private static final VoxelShape SHAPE = Shapes.box(0.0625, 0.0, 0.0625, 0.9375, 0.125, 0.9375);

    public CuttingBoardBlock(BlockBehaviour.Properties props) {
        super(props);
        registerDefaultState(stateDefinition.any().setValue(AgricultureBlocks.FACING, Direction.NORTH));
    }

    @Override
    public BlockState getStateForPlacement(net.minecraft.world.item.context.BlockPlaceContext context) {
        return defaultBlockState().setValue(AgricultureBlocks.FACING, context.getHorizontalDirection().getOpposite());
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
        return simpleCodec(CuttingBoardBlock::new);
    }
    /** 🆕 破坏时掉落内部物品（用户口径）—— 注意返回类型是 BlockState，不是 void。 */
    @Override
    public BlockState playerWillDestroy(net.minecraft.world.level.Level level, BlockPos pos,
                                        BlockState state, net.minecraft.world.entity.player.Player player) {
        AgricultureBlocks.dropContentsOnBreak(level, pos);
        return super.playerWillDestroy(level, pos, state, player);
    }

    // ---------------- 🆕 耐久（BE） ----------------

    @Override
    public io.github.likexiang21.tfcplus.agriculture.common.blockentity.CuttingBoardBlockEntity newBlockEntity(
        BlockPos pos, BlockState state) {
        return new io.github.likexiang21.tfcplus.agriculture.common.blockentity.CuttingBoardBlockEntity(pos, state);
    }

    /** 🛑 返回 null ⇒ 不 tick。 */
    @Override
    public <T extends net.minecraft.world.level.block.entity.BlockEntity> net.minecraft.world.level.block.entity.BlockEntityTicker<T> getTicker(
        net.minecraft.world.level.Level level, BlockState state,
        net.minecraft.world.level.block.entity.BlockEntityType<T> type) {
        return null;
    }

    /**
     * 🆕 <b>右键：把食材摊到板上 / 从板上取回</b>
     * —— 用户口径：「砧板交互也要保证**物品的可见性**」（放上去的东西必须能看见）。
     * <ol>
     *   <li>手持物品 ⇒ **放到板上**（之后由 {@code CuttingBoardBlockEntityRenderer} **直接渲染**出来）</li>
     *   <li>空手 ⇒ **取回**板上的物品；板也是空的时候 ⇒ 提示剩余耐久</li>
     * </ol>
     * Cutting is handled by the board recipe type; block transformations use in_world.
     */
    @Override
    protected net.minecraft.world.InteractionResult useWithoutItem(
        BlockState state, net.minecraft.world.level.Level level, BlockPos pos,
        net.minecraft.world.entity.player.Player player, net.minecraft.world.phys.BlockHitResult hit) {

        if (!level.isClientSide()) {
            CuttingBoardInteractions.interact(level, pos, player, net.minecraft.world.InteractionHand.MAIN_HAND);
        }
        return net.minecraft.world.InteractionResult.sidedSuccess(level.isClientSide());
    }

    @Override
    protected net.minecraft.world.ItemInteractionResult useItemOn(net.minecraft.world.item.ItemStack stack,
        BlockState state, net.minecraft.world.level.Level level, BlockPos pos,
        net.minecraft.world.entity.player.Player player, net.minecraft.world.InteractionHand hand,
        net.minecraft.world.phys.BlockHitResult hit) {
        if (!level.isClientSide()) CuttingBoardInteractions.interact(level, pos, player, hand);
        return net.minecraft.world.ItemInteractionResult.sidedSuccess(level.isClientSide());
    }

    @Override
    protected void onRemove(BlockState state, net.minecraft.world.level.Level level, BlockPos pos,
                            BlockState replacement, boolean moving) {
        if (!state.is(replacement.getBlock())) AgricultureBlocks.dropContentsOnBreak(level, pos);
        super.onRemove(state, level, pos, replacement, moving);
    }
}
