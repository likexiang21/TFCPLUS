package io.github.likexiang21.tfcplus.agriculture.common.block;

import io.github.likexiang21.tfcplus.agriculture.common.blockentity.KnifeRackBlockEntity;
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
 * <b>刀具架</b> —— 与案板配套（放刀 / 取刀）。
 *
 * <p>🆕 <b>几何与碰撞箱</b>：
 * <ul>
 *   <li>背板：{@code [0,0,10] → [16,15,12]}（贴墙的立板）</li>
 *   <li>底座：{@code [0,0,6] → [16,3,12]}</li>
 *   <li>两道横档：{@code y=4→5} 与 {@code y=9→10}（视觉上"插着刀"）</li>
 *   <li>碰撞箱：{@code box(0,0,6/16,16,15/16,12/16)}（背板 + 底座的整体）</li>
 * </ul>
 */
public class KnifeRackBlock extends HorizontalDirectionalBlock
    implements net.minecraft.world.level.block.EntityBlock {

    private static final VoxelShape SHAPE = Shapes.box(0.0625, 0.0, 0.3125, 0.9375, 0.875, 0.75);

    public KnifeRackBlock(BlockBehaviour.Properties props) {
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
        return simpleCodec(KnifeRackBlock::new);
    }
    /** 🆕 破坏时掉落内部物品（用户口径）—— 注意返回类型是 BlockState，不是 void。 */
    @Override
    public BlockState playerWillDestroy(net.minecraft.world.level.Level level, BlockPos pos,
                                        BlockState state, net.minecraft.world.entity.player.Player player) {
        AgricultureBlocks.dropContentsOnBreak(level, pos);
        return super.playerWillDestroy(level, pos, state, player);
    }

    // ---------------- 🆕 存储功能（BE） ----------------

    @Override
    public io.github.likexiang21.tfcplus.agriculture.common.blockentity.KnifeRackBlockEntity newBlockEntity(
        BlockPos pos, BlockState state) {
        return new io.github.likexiang21.tfcplus.agriculture.common.blockentity.KnifeRackBlockEntity(pos, state);
    }

    /** 🛑 返回 null ⇒ **不 tick**（性能红线：空闲零开销）。 */
    @Override
    public <T extends net.minecraft.world.level.block.entity.BlockEntity> net.minecraft.world.level.block.entity.BlockEntityTicker<T> getTicker(
        net.minecraft.world.level.Level level, BlockState state,
        net.minecraft.world.level.block.entity.BlockEntityType<T> type) {
        return null;
    }

    /**
     * 🆕 右键交互（**第一版的"无 GUI 存取"**）：
     * <ul>
     *   <li>手持物品 ⇒ **存入**（放不下则提示）</li>
     *   <li>空手 ⇒ **取出**最后放入的一件</li>
     * </ul>
     * ⚠️ GUI 留到批次 9（调料系统）一起做。
     */
    @Override
    protected net.minecraft.world.InteractionResult useWithoutItem(
        BlockState state, net.minecraft.world.level.Level level, BlockPos pos,
        net.minecraft.world.entity.player.Player player, net.minecraft.world.phys.BlockHitResult hit) {

        if (level.isClientSide()) {
            return net.minecraft.world.InteractionResult.SUCCESS;
        }
        if (!(level.getBlockEntity(pos)
                instanceof io.github.likexiang21.tfcplus.agriculture.common.blockentity.KnifeRackBlockEntity blockEntity)) {
            return net.minecraft.world.InteractionResult.PASS;
        }

        final net.minecraft.world.item.ItemStack held = player.getMainHandItem();

        if (!held.isEmpty()) {
            // 存入（🆕 现在走**白名单**：只能放工具与调料罐，见 AgricultureTags）
            if (blockEntity.store(held)) {
                if (!player.isCreative()) {
                    held.shrink(1);
                }
                level.playSound(null, pos, net.minecraft.sounds.SoundEvents.ITEM_PICKUP,
                    net.minecraft.sounds.SoundSource.BLOCKS, 0.6F, 1.2F);
                return net.minecraft.world.InteractionResult.CONSUME;
            }
            // 🆕 区分"满了"与"这个物品不能放"
            player.displayClientMessage(
                net.minecraft.network.chat.Component.translatable(
                    blockEntity.isItemValid(held)
                        ? "message.tfcagricultureplus.knife_block.full"
                        : "message.tfcagricultureplus.knife_block.invalid"), true);
            return net.minecraft.world.InteractionResult.CONSUME;
        }

        // 取出
        final net.minecraft.world.item.ItemStack droppedStack = blockEntity.takeLast();
        if (droppedStack.isEmpty()) {
            player.displayClientMessage(
                net.minecraft.network.chat.Component.translatable(
                    "message.tfcagricultureplus.knife_block.empty"), true);
            return net.minecraft.world.InteractionResult.CONSUME;
        }
        if (!player.getInventory().add(droppedStack)) {
            player.drop(droppedStack, false);
        }
        level.playSound(null, pos, net.minecraft.sounds.SoundEvents.ITEM_PICKUP,
            net.minecraft.sounds.SoundSource.BLOCKS, 0.6F, 0.9F);
        return net.minecraft.world.InteractionResult.CONSUME;
    }

    @Override
    protected void onRemove(BlockState state, net.minecraft.world.level.Level level, BlockPos pos,
                            BlockState replacement, boolean moving) {
        if (!state.is(replacement.getBlock())) AgricultureBlocks.dropContentsOnBreak(level, pos);
        super.onRemove(state, level, pos, replacement, moving);
    }
}
