package io.github.likexiang21.tfcplus.agriculture.common.block;

import io.github.likexiang21.tfcplus.agriculture.common.blockentity.DoughFormingTableBlockEntity;
import io.github.likexiang21.tfcplus.agriculture.common.interaction.DoughFormingInteractions;
import net.minecraft.world.InteractionResult;
import net.minecraft.world.ItemInteractionResult;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.EntityBlock;
import net.minecraft.world.level.block.entity.BlockEntity;
import net.minecraft.world.level.block.entity.BlockEntityTicker;
import net.minecraft.world.level.block.entity.BlockEntityType;
import net.minecraft.world.level.block.state.BlockBehaviour;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.phys.BlockHitResult;

/** A compact K3 table; all inventory state lives in a TFC inventory block entity. */
public final class DoughFormingTableBlock extends Block implements EntityBlock {
    public DoughFormingTableBlock(BlockBehaviour.Properties properties) { super(properties); }
    @Override protected com.mojang.serialization.MapCodec<? extends Block> codec() { return simpleCodec(DoughFormingTableBlock::new); }
    @Override public BlockEntity newBlockEntity(net.minecraft.core.BlockPos pos, BlockState state) { return new DoughFormingTableBlockEntity(pos, state); }
    @Override public <T extends BlockEntity> BlockEntityTicker<T> getTicker(Level level, BlockState state, BlockEntityType<T> type) { return null; }
    @Override protected InteractionResult useWithoutItem(BlockState state, Level level, net.minecraft.core.BlockPos pos, Player player, BlockHitResult hit) {
        DoughFormingInteractions.interact(level, pos, player, net.minecraft.world.InteractionHand.MAIN_HAND);
        return InteractionResult.sidedSuccess(level.isClientSide());
    }
    @Override protected ItemInteractionResult useItemOn(net.minecraft.world.item.ItemStack stack, BlockState state, Level level,
        net.minecraft.core.BlockPos pos, Player player, net.minecraft.world.InteractionHand hand, BlockHitResult hit) {
        DoughFormingInteractions.interact(level, pos, player, hand);
        return ItemInteractionResult.sidedSuccess(level.isClientSide());
    }
    @Override protected void onRemove(BlockState state, Level level, net.minecraft.core.BlockPos pos, BlockState replacement, boolean moving) {
        if (!state.is(replacement.getBlock()) && level.getBlockEntity(pos) instanceof DoughFormingTableBlockEntity table) table.dropContents();
        super.onRemove(state, level, pos, replacement, moving);
    }
}
