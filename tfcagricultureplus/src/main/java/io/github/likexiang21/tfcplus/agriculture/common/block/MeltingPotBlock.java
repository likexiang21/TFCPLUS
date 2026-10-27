package io.github.likexiang21.tfcplus.agriculture.common.block;

import io.github.likexiang21.tfcplus.agriculture.common.blockentity.MeltingPotBlockEntity;
import io.github.likexiang21.tfcplus.agriculture.common.interaction.MeltingPotInteractions;
import io.github.likexiang21.tfcplus.agriculture.common.registry.AgricultureBlockEntities;
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

/** K3 melting pot using the same direct interaction pattern as the pan. */
public final class MeltingPotBlock extends Block implements EntityBlock {
    public MeltingPotBlock(BlockBehaviour.Properties properties) { super(properties); }
    @Override protected com.mojang.serialization.MapCodec<? extends Block> codec() { return simpleCodec(MeltingPotBlock::new); }
    @Override public BlockEntity newBlockEntity(net.minecraft.core.BlockPos pos, BlockState state) { return new MeltingPotBlockEntity(pos, state); }
    @Override public <T extends BlockEntity> BlockEntityTicker<T> getTicker(Level level, BlockState state, BlockEntityType<T> type) {
        if (level.isClientSide() || type != AgricultureBlockEntities.MELTING_POT.get()) return null;
        return (l, p, s, be) -> MeltingPotBlockEntity.serverTick(l, p, s, (MeltingPotBlockEntity) be);
    }
    @Override protected InteractionResult useWithoutItem(BlockState state, Level level, net.minecraft.core.BlockPos pos, Player player, BlockHitResult hit) {
        MeltingPotInteractions.interact(level, pos, player, net.minecraft.world.InteractionHand.MAIN_HAND);
        return InteractionResult.sidedSuccess(level.isClientSide());
    }
    @Override protected ItemInteractionResult useItemOn(net.minecraft.world.item.ItemStack stack, BlockState state, Level level,
        net.minecraft.core.BlockPos pos, Player player, net.minecraft.world.InteractionHand hand, BlockHitResult hit) {
        MeltingPotInteractions.interact(level, pos, player, hand);
        return ItemInteractionResult.sidedSuccess(level.isClientSide());
    }
    @Override protected void onRemove(BlockState state, Level level, net.minecraft.core.BlockPos pos, BlockState replacement, boolean moving) {
        if (!state.is(replacement.getBlock()) && level.getBlockEntity(pos) instanceof MeltingPotBlockEntity pot) pot.dropContents();
        super.onRemove(state, level, pos, replacement, moving);
    }
}
