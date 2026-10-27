package com.example.tfcfarmingplus.expansion.common;

import com.example.tfcfarmingplus.expansion.common.blockentities.CookingPanBlockEntity;
import net.minecraft.core.Direction;
import net.minecraft.world.InteractionResult;
import net.minecraft.world.ItemInteractionResult;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.level.BlockGetter;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.EntityBlock;
import net.minecraft.world.level.block.HorizontalDirectionalBlock;
import net.minecraft.world.level.block.entity.BlockEntity;
import net.minecraft.world.level.block.entity.BlockEntityTicker;
import net.minecraft.world.level.block.entity.BlockEntityType;
import net.minecraft.world.level.block.state.BlockBehaviour;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.StateDefinition;
import net.minecraft.world.phys.BlockHitResult;
import net.minecraft.world.phys.shapes.CollisionContext;
import net.minecraft.world.phys.shapes.Shapes;
import net.minecraft.world.phys.shapes.VoxelShape;

/** Low-profile K2 pan. Interaction is direct, while storage stays TFC-backed. */
public final class CookingPanBlock extends HorizontalDirectionalBlock implements EntityBlock {
    private static final VoxelShape SHAPE = Shapes.box(0.0625, 0.0, 0.0625, 0.9375, 0.25, 0.9375);

    public CookingPanBlock(BlockBehaviour.Properties properties) {
        super(properties);
        registerDefaultState(stateDefinition.any().setValue(FACING, Direction.NORTH));
    }

    @Override protected void createBlockStateDefinition(StateDefinition.Builder<Block, BlockState> builder) { builder.add(FACING); }
    @Override protected VoxelShape getShape(BlockState state, BlockGetter level, net.minecraft.core.BlockPos pos, CollisionContext context) { return SHAPE; }
    @Override protected com.mojang.serialization.MapCodec<? extends HorizontalDirectionalBlock> codec() { return simpleCodec(CookingPanBlock::new); }
    @Override public BlockEntity newBlockEntity(net.minecraft.core.BlockPos pos, BlockState state) { return new CookingPanBlockEntity(pos, state); }
    @Override public <T extends BlockEntity> BlockEntityTicker<T> getTicker(Level level, BlockState state, BlockEntityType<T> type) {
        if (level.isClientSide() || type != MyBlockEntities.COOKING_PAN.get()) return null;
        return (l, p, s, be) -> CookingPanBlockEntity.serverTick(l, p, s, (CookingPanBlockEntity) be);
    }
    @Override protected InteractionResult useWithoutItem(BlockState state, Level level, net.minecraft.core.BlockPos pos, Player player, BlockHitResult hit) {
        PanInteractions.interact(level, pos, player, net.minecraft.world.InteractionHand.MAIN_HAND);
        return InteractionResult.sidedSuccess(level.isClientSide());
    }
    @Override protected ItemInteractionResult useItemOn(net.minecraft.world.item.ItemStack stack, BlockState state, Level level,
                                                         net.minecraft.core.BlockPos pos, Player player,
                                                         net.minecraft.world.InteractionHand hand, BlockHitResult hit) {
        PanInteractions.interact(level, pos, player, hand);
        return ItemInteractionResult.sidedSuccess(level.isClientSide());
    }
    @Override protected void onRemove(BlockState state, Level level, net.minecraft.core.BlockPos pos,
                                      BlockState replacement, boolean moving) {
        if (!state.is(replacement.getBlock()) && level.getBlockEntity(pos) instanceof CookingPanBlockEntity pan) pan.dropContents();
        super.onRemove(state, level, pos, replacement, moving);
    }
}
