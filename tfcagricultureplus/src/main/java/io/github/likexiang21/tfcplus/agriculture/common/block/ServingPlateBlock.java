package io.github.likexiang21.tfcplus.agriculture.common.block;

import io.github.likexiang21.tfcplus.agriculture.common.blockentity.ServingPlateBlockEntity;
import io.github.likexiang21.tfcplus.agriculture.common.item.ServingBowlItem;
import io.github.likexiang21.tfcplus.agriculture.common.pan.DishEating;
import io.github.likexiang21.tfcplus.agriculture.common.pan.PlateVariant;
import io.github.likexiang21.tfcplus.agriculture.common.registry.AgriculturePlates;
import java.util.List;
import net.minecraft.core.BlockPos;
import net.minecraft.world.InteractionHand;
import net.minecraft.world.InteractionResult;
import net.minecraft.world.ItemInteractionResult;
import net.minecraft.world.entity.LivingEntity;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.BaseEntityBlock;
import net.minecraft.world.level.block.RenderShape;
import net.minecraft.world.level.block.entity.BlockEntity;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.StateDefinition;
import net.minecraft.world.level.storage.loot.LootParams;
import net.minecraft.world.phys.BlockHitResult;

/** A plate block; the full plate ItemStack (including dish components) lives in its BE. */
public final class ServingPlateBlock extends BaseEntityBlock {
    public ServingPlateBlock(Properties properties) {
        super(properties);
        registerDefaultState(stateDefinition.any().setValue(AgriculturePlates.VARIANT, PlateVariant.WOOD));
    }

    @Override protected com.mojang.serialization.MapCodec<? extends net.minecraft.world.level.block.BaseEntityBlock> codec() {
        return simpleCodec(ServingPlateBlock::new);
    }

    @Override protected void createBlockStateDefinition(StateDefinition.Builder<net.minecraft.world.level.block.Block, BlockState> builder) {
        builder.add(AgriculturePlates.VARIANT);
    }

    @Override public BlockEntity newBlockEntity(BlockPos pos, BlockState state) {
        return new ServingPlateBlockEntity(pos, state);
    }

    @Override public RenderShape getRenderShape(BlockState state) { return RenderShape.MODEL; }

    @Override public void setPlacedBy(Level level, BlockPos pos, BlockState state, LivingEntity placer, ItemStack stack) {
        super.setPlacedBy(level, pos, state, placer, stack);
        if (!level.isClientSide() && level.getBlockEntity(pos) instanceof ServingPlateBlockEntity plate) {
            plate.setPlateStack(stack);
        }
    }

    @Override protected ItemInteractionResult useItemOn(ItemStack stack, BlockState state, Level level, BlockPos pos,
                                                       Player player, InteractionHand hand, BlockHitResult hit) {
        if (stack.getItem() instanceof ServingBowlItem && !level.isClientSide()
            && level.getBlockEntity(pos) instanceof ServingPlateBlockEntity plate) {
            if (DishEating.transferToBowl(player, plate, hand)) {
                return ItemInteractionResult.sidedSuccess(false);
            }
            return ItemInteractionResult.FAIL;
        }
        return ItemInteractionResult.PASS_TO_DEFAULT_BLOCK_INTERACTION;
    }

    @Override protected InteractionResult useWithoutItem(BlockState state, Level level, BlockPos pos,
                                                        Player player, BlockHitResult hit) {
        if (level.isClientSide()) return InteractionResult.SUCCESS;
        if (level.getBlockEntity(pos) instanceof ServingPlateBlockEntity plate) {
            return DishEating.eatFromPlateBlock(player, plate)
                ? InteractionResult.CONSUME
                : InteractionResult.PASS;
        }
        return InteractionResult.PASS;
    }

    @Override public List<ItemStack> getDrops(BlockState state, LootParams.Builder params) {
        final net.minecraft.world.phys.Vec3 origin = params.getOptionalParameter(
            net.minecraft.world.level.storage.loot.parameters.LootContextParams.ORIGIN);
        if (origin != null) {
            final BlockPos pos = BlockPos.containing(origin);
            if (params.getLevel().getBlockEntity(pos) instanceof ServingPlateBlockEntity plate) {
                return List.of(plate.dropStack());
            }
        }
        return List.of(new ItemStack(AgriculturePlates.itemFor(state.getValue(AgriculturePlates.VARIANT)).get()));
    }

    @Override public ItemStack getCloneItemStack(net.minecraft.world.level.LevelReader level, BlockPos pos, BlockState state) {
        if (level.getBlockEntity(pos) instanceof ServingPlateBlockEntity plate) {
            return plate.dropStack();
        }
        return new ItemStack(AgriculturePlates.itemFor(state.getValue(AgriculturePlates.VARIANT)).get());
    }
}
