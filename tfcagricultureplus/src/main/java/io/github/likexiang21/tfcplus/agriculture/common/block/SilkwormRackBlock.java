package io.github.likexiang21.tfcplus.agriculture.common.block;

import io.github.likexiang21.tfcplus.agriculture.common.blockentity.SilkwormRackBlockEntity;
import io.github.likexiang21.tfcplus.agriculture.common.interaction.SilkwormRackInteractions;
import io.github.likexiang21.tfcplus.agriculture.common.registry.AgricultureBlockEntities;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.world.InteractionResult;
import net.minecraft.world.ItemInteractionResult;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.item.ItemStack;
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
import net.minecraft.world.level.block.state.properties.IntegerProperty;
import net.minecraft.world.phys.BlockHitResult;
import net.minecraft.world.phys.shapes.CollisionContext;
import net.minecraft.world.phys.shapes.Shapes;
import net.minecraft.world.phys.shapes.VoxelShape;

/** B-owned three-state silkworm rack. */
public final class SilkwormRackBlock extends HorizontalDirectionalBlock implements EntityBlock {
    public static final IntegerProperty STAGE = IntegerProperty.create("stage", 0, 2);
    private static final VoxelShape SHAPE = Shapes.box(0.0625, 0.0, 0.0625, 0.9375, 0.875, 0.9375);

    public SilkwormRackBlock(BlockBehaviour.Properties properties) {
        super(properties);
        registerDefaultState(stateDefinition.any().setValue(FACING, Direction.NORTH).setValue(STAGE, 0));
    }

    @Override
    protected void createBlockStateDefinition(StateDefinition.Builder<Block, BlockState> builder) {
        builder.add(FACING, STAGE);
    }

    @Override
    protected VoxelShape getShape(BlockState state, BlockGetter level, BlockPos pos, CollisionContext context) {
        return SHAPE;
    }

    @Override
    protected com.mojang.serialization.MapCodec<? extends HorizontalDirectionalBlock> codec() {
        return simpleCodec(SilkwormRackBlock::new);
    }

    @Override
    public BlockEntity newBlockEntity(BlockPos pos, BlockState state) {
        return new SilkwormRackBlockEntity(pos, state);
    }

    @Override
    public <T extends BlockEntity> BlockEntityTicker<T> getTicker(
        Level level, BlockState state, BlockEntityType<T> type) {
        if (level.isClientSide() || type != AgricultureBlockEntities.SILKWORM_RACK.get()) return null;
        return (l, p, s, be) -> SilkwormRackBlockEntity.serverTick(
            l, p, s, (SilkwormRackBlockEntity) be);
    }

    @Override
    protected InteractionResult useWithoutItem(BlockState state, Level level, BlockPos pos,
                                                Player player, BlockHitResult hit) {
        SilkwormRackInteractions.interact(level, pos, player, net.minecraft.world.InteractionHand.MAIN_HAND);
        return InteractionResult.sidedSuccess(level.isClientSide());
    }

    @Override
    protected ItemInteractionResult useItemOn(ItemStack stack, BlockState state, Level level, BlockPos pos,
                                               Player player, net.minecraft.world.InteractionHand hand,
                                               BlockHitResult hit) {
        SilkwormRackInteractions.interact(level, pos, player, hand);
        return ItemInteractionResult.sidedSuccess(level.isClientSide());
    }

    @Override
    protected void onRemove(BlockState state, Level level, BlockPos pos,
                            BlockState replacement, boolean moving) {
        if (!state.is(replacement.getBlock()) && level.getBlockEntity(pos) instanceof SilkwormRackBlockEntity rack) {
            rack.dropContents();
        }
        super.onRemove(state, level, pos, replacement, moving);
    }
}
