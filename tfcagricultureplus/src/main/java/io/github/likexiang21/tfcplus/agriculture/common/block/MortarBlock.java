package io.github.likexiang21.tfcplus.agriculture.common.block;

import io.github.likexiang21.tfcplus.agriculture.common.blockentity.MortarBlockEntity;
import io.github.likexiang21.tfcplus.agriculture.common.interaction.MortarInteractions;
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
 * 🆕 <b>石臼</b>（{@code mortar}）—— 手持研磨的**固定版**（磨香料 · 磨粉 · 捣碎）。
 *
 * <p>几何：底座 + 四周壁（中间凹），碰撞箱为**整方块**（玩家站上去/靠着都自然）。
 * <p>⚠️ 与 TFC {@code quern} 的分工见 {@link AgricultureItems}（臼=小批量/粗磨，磨=大批量/细粉）。
 */
public class MortarBlock extends HorizontalDirectionalBlock
    implements net.minecraft.world.level.block.EntityBlock {

    /** 碰撞箱：整方块（凹槽只是视觉）。 */
    private static final VoxelShape SHAPE = Shapes.box(0.0625, 0.0, 0.0625, 0.9375, 0.5625, 0.9375);

    public MortarBlock(BlockBehaviour.Properties props) {
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
        return simpleCodec(MortarBlock::new);
    }
    /** 🆕 破坏时掉落内部物品（用户口径）—— 注意返回类型是 BlockState，不是 void。 */
    @Override
    public BlockState playerWillDestroy(net.minecraft.world.level.Level level, BlockPos pos,
                                        BlockState state, net.minecraft.world.entity.player.Player player) {
        AgricultureBlocks.dropContentsOnBreak(level, pos);
        return super.playerWillDestroy(level, pos, state, player);
    }

    // ---------------- 🆕 容器（参考 Firmalife 的搅拌碗） ----------------

    @Override
    public io.github.likexiang21.tfcplus.agriculture.common.blockentity.MortarBlockEntity newBlockEntity(
        BlockPos pos, BlockState state) {
        return new io.github.likexiang21.tfcplus.agriculture.common.blockentity.MortarBlockEntity(pos, state);
    }

    /** 🛑 返回 null ⇒ 不 tick。 */
    @Override
    public <T extends net.minecraft.world.level.block.entity.BlockEntity> net.minecraft.world.level.block.entity.BlockEntityTicker<T> getTicker(
        net.minecraft.world.level.Level level, BlockState state,
        net.minecraft.world.level.block.entity.BlockEntityType<T> type) {
        return null;
    }

    /**
     * 🆕 右键交互（**无 GUI**，与刀架同一套思路）：
     * <ol>
     *   <li>手持<b>石杵</b> ⇒ <b>研磨</b>：按 {@code grind_time} 记录敲击次数，完成后
     *       ① 消耗内容物 ② <b>石杵每次敲击消耗 1 点耐久</b> ③ 产物直接给玩家</li>
     *   <li>手持<b>其他物品</b> ⇒ <b>放入</b>（石臼空时）</li>
     *   <li><b>空手</b> ⇒ 取出内容物</li>
     * </ol>
     */
    @Override
    protected net.minecraft.world.InteractionResult useWithoutItem(
        BlockState state, net.minecraft.world.level.Level level, BlockPos pos,
        net.minecraft.world.entity.player.Player player, net.minecraft.world.phys.BlockHitResult hit) {
        io.github.likexiang21.tfcplus.agriculture.common.interaction.MortarInteractions.interact(
            level, pos, player, net.minecraft.world.InteractionHand.MAIN_HAND);
        return net.minecraft.world.InteractionResult.sidedSuccess(level.isClientSide());
    }

    @Override
    protected net.minecraft.world.ItemInteractionResult useItemOn(
        net.minecraft.world.item.ItemStack stack, BlockState state,
        net.minecraft.world.level.Level level, BlockPos pos,
        net.minecraft.world.entity.player.Player player, net.minecraft.world.InteractionHand hand,
        net.minecraft.world.phys.BlockHitResult hit) {
        io.github.likexiang21.tfcplus.agriculture.common.interaction.MortarInteractions.interact(level, pos, player, hand);
        return net.minecraft.world.ItemInteractionResult.sidedSuccess(level.isClientSide());
    }

    @Override
    protected void onRemove(BlockState state, net.minecraft.world.level.Level level, BlockPos pos,
                            BlockState replacement, boolean moving) {
        if (!state.is(replacement.getBlock())) AgricultureBlocks.dropContentsOnBreak(level, pos);
        super.onRemove(state, level, pos, replacement, moving);
    }
}
