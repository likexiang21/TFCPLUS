package com.example.tfcfarmingplus.expansion.common;

import com.example.tfcfarmingplus.expansion.common.blockentities.PlaceableFoodBlockEntity;
import net.dries007.tfc.common.component.food.FoodCapability;
import net.minecraft.core.BlockPos;
import net.minecraft.world.InteractionResult;
import net.minecraft.world.entity.LivingEntity;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.context.BlockPlaceContext;
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

/** Whole pie block. Remaining servings live in the TFC BE, never in blockstate. */
public final class PlaceableFoodBlock extends Block implements EntityBlock {
    public PlaceableFoodBlock(BlockBehaviour.Properties properties) { super(properties); }
    @Override protected com.mojang.serialization.MapCodec<? extends Block> codec() { return simpleCodec(PlaceableFoodBlock::new); }
    @Override public BlockEntity newBlockEntity(net.minecraft.core.BlockPos pos, BlockState state) { return new PlaceableFoodBlockEntity(pos, state); }
    @Override public <T extends BlockEntity> BlockEntityTicker<T> getTicker(Level level, BlockState state, BlockEntityType<T> type) { return null; }
    @Override public BlockState getStateForPlacement(BlockPlaceContext context) {
        if (this == MyBlocks.WHOLE_PIE.get() && FoodCapability.isRotten(context.getItemInHand())) return null;
        return super.getStateForPlacement(context);
    }
    @Override public void setPlacedBy(Level level, BlockPos pos, BlockState state, LivingEntity placer, ItemStack stack) {
        super.setPlacedBy(level, pos, state, placer, stack);
        if (!level.isClientSide() && state.is(MyBlocks.WHOLE_PIE.get())
            && level.getBlockEntity(pos) instanceof PlaceableFoodBlockEntity food) food.setPieFood(stack);
    }
    @Override protected InteractionResult useWithoutItem(BlockState state, Level level, net.minecraft.core.BlockPos pos, Player player, BlockHitResult hit) {
        return level.getBlockEntity(pos) instanceof PlaceableFoodBlockEntity pie && pie.takeServing(player) ? InteractionResult.sidedSuccess(level.isClientSide()) : InteractionResult.PASS;
    }
    @Override protected void onRemove(BlockState state, Level level, net.minecraft.core.BlockPos pos, BlockState replacement, boolean moving) {
        if (!state.is(replacement.getBlock()) && level.getBlockEntity(pos) instanceof PlaceableFoodBlockEntity pie) pie.dropContents();
        super.onRemove(state, level, pos, replacement, moving);
    }
}
