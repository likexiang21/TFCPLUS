package io.github.likexiang21.tfcplus.agriculture.common.block;

import io.github.likexiang21.tfcplus.agriculture.common.blockentity.KitchenStorageBlockEntity;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.server.level.ServerPlayer;
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

/** A small family of wood kitchen furniture sharing one TFC inventory contract. */
public final class KitchenStorageBlock extends HorizontalDirectionalBlock implements EntityBlock {
    public enum StorageKind {
        COUNTER_CABINET("counter_cabinet", 1.0),
        HALF_CABINET("half_cabinet", 0.5),
        SINK_CABINET("sink_cabinet", 0.9375),
        SPICE_RACK("spice_rack", 0.75),
        FOOD_DISPLAY("food_display", 0.8125),
        FRUIT_BOWL("fruit_bowl", 0.5);

        private final String storageId;
        private final double height;

        StorageKind(String storageId, double height) {
            this.storageId = storageId;
            this.height = height;
        }

        public String storageId() { return storageId; }
        public double height() { return height; }
    }

    private final StorageKind storageKind;
    private final VoxelShape shape;

    public KitchenStorageBlock(BlockBehaviour.Properties properties, StorageKind storageKind) {
        super(properties);
        this.storageKind = storageKind;
        this.shape = Shapes.box(0.03125, 0.0, 0.03125, 0.96875, storageKind.height(), 0.96875);
        registerDefaultState(stateDefinition.any().setValue(FACING, Direction.NORTH));
    }

    public StorageKind storageKind() { return storageKind; }

    @Override
    protected void createBlockStateDefinition(StateDefinition.Builder<Block, BlockState> builder) {
        builder.add(FACING);
    }

    @Override
    protected VoxelShape getShape(BlockState state, BlockGetter level, BlockPos pos, CollisionContext context) {
        return shape;
    }

    @Override
    protected com.mojang.serialization.MapCodec<? extends HorizontalDirectionalBlock> codec() {
        return simpleCodec(properties -> new KitchenStorageBlock(properties, storageKind));
    }

    @Override
    public BlockState getStateForPlacement(net.minecraft.world.item.context.BlockPlaceContext context) {
        return defaultBlockState().setValue(FACING, context.getHorizontalDirection().getOpposite());
    }

    @Override
    public BlockEntity newBlockEntity(BlockPos pos, BlockState state) {
        return new KitchenStorageBlockEntity(pos, state);
    }

    @Override
    public <T extends BlockEntity> BlockEntityTicker<T> getTicker(Level level, BlockState state,
                                                                   BlockEntityType<T> type) {
        return null;
    }

    @Override
    protected InteractionResult useWithoutItem(BlockState state, Level level, BlockPos pos,
                                                Player player, BlockHitResult hit) {
        return open(level, pos, player);
    }

    @Override
    protected ItemInteractionResult useItemOn(net.minecraft.world.item.ItemStack stack, BlockState state,
                                               Level level, BlockPos pos, Player player,
                                               net.minecraft.world.InteractionHand hand, BlockHitResult hit) {
        return ItemInteractionResult.sidedSuccess(open(level, pos, player).consumesAction());
    }

    private static InteractionResult open(Level level, BlockPos pos, Player player) {
        if (level.isClientSide()) return InteractionResult.SUCCESS;
        if (player instanceof ServerPlayer serverPlayer
            && level.getBlockEntity(pos) instanceof KitchenStorageBlockEntity storage) {
            serverPlayer.openMenu(storage, pos);
        }
        return InteractionResult.CONSUME;
    }

    @Override
    public BlockState playerWillDestroy(Level level, BlockPos pos, BlockState state, Player player) {
        dropContents(level, pos);
        return super.playerWillDestroy(level, pos, state, player);
    }

    @Override
    protected void onRemove(BlockState state, Level level, BlockPos pos, BlockState replacement, boolean moving) {
        if (!state.is(replacement.getBlock())) dropContents(level, pos);
        super.onRemove(state, level, pos, replacement, moving);
    }

    private static void dropContents(Level level, BlockPos pos) {
        if (!level.isClientSide() && level.getBlockEntity(pos) instanceof KitchenStorageBlockEntity storage) {
            storage.dropContents();
        }
    }
}
