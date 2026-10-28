package io.github.likexiang21.tfcplus.agriculture.common.timber;

import com.mojang.serialization.MapCodec;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.core.registries.Registries;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.sounds.SoundEvents;
import net.minecraft.sounds.SoundSource;
import net.minecraft.tags.TagKey;
import net.minecraft.world.InteractionHand;
import net.minecraft.world.InteractionResult;
import net.minecraft.world.ItemInteractionResult;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.item.Item;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.context.BlockPlaceContext;
import net.minecraft.world.level.BlockGetter;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.EntityBlock;
import net.minecraft.world.level.block.RenderShape;
import net.minecraft.world.level.block.entity.BlockEntity;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.StateDefinition;
import net.minecraft.world.level.block.state.properties.BlockStateProperties;
import net.minecraft.world.level.block.state.properties.EnumProperty;
import net.minecraft.world.level.block.state.properties.IntegerProperty;
import net.minecraft.world.phys.BlockHitResult;
import net.minecraft.world.phys.shapes.CollisionContext;
import net.minecraft.world.phys.shapes.VoxelShape;

/**
 * A stack of one full stack (64) of TFC lumber. There is no block item: shift-use
 * lumber on the ground (TFC log-pile behavior) to create it. COUNT has 64 values;
 * the block model uses the matching wood's planks texture.
 */
public final class LumberPileBlock extends Block implements EntityBlock {
    public static final EnumProperty<Direction.Axis> AXIS = BlockStateProperties.HORIZONTAL_AXIS;
    public static final IntegerProperty COUNT = IntegerProperty.create("count", 1, 64);
    public static final TagKey<Item> LUMBER = TagKey.create(Registries.ITEM,
        ResourceLocation.fromNamespaceAndPath("tfc", "lumber"));
    public static final EnumProperty<LumberWood> WOOD = EnumProperty.create("wood", LumberWood.class);

    public LumberPileBlock(Properties properties) {
        super(properties);
        registerDefaultState(stateDefinition.any()
            .setValue(AXIS, Direction.Axis.Z).setValue(COUNT, 1).setValue(WOOD, LumberWood.OAK));
    }

    @Override protected MapCodec<? extends Block> codec() {
        return simpleCodec(LumberPileBlock::new);
    }

    @Override protected void createBlockStateDefinition(StateDefinition.Builder<Block, BlockState> builder) {
        builder.add(AXIS, COUNT, WOOD);
    }

    @Override public BlockState getStateForPlacement(BlockPlaceContext context) {
        return defaultBlockState()
            .setValue(AXIS, context.getHorizontalDirection().getAxis())
            .setValue(COUNT, 1)
            .setValue(WOOD, LumberWood.OAK);
    }

    @Override public BlockEntity newBlockEntity(BlockPos pos, BlockState state) {
        return new LumberPileBlockEntity(pos, state);
    }

    @Override protected RenderShape getRenderShape(BlockState state) {
        return RenderShape.MODEL;
    }

    @Override protected VoxelShape getShape(BlockState state, BlockGetter level, BlockPos pos, CollisionContext context) {
        return Block.box(0, 0, 0, 16, state.getValue(COUNT) / 4.0D, 16);
    }

    @Override protected ItemInteractionResult useItemOn(ItemStack held, BlockState state, Level level, BlockPos pos,
                                                         Player player, InteractionHand hand, BlockHitResult hit) {
        if (!held.is(LUMBER)) return ItemInteractionResult.PASS_TO_DEFAULT_BLOCK_INTERACTION;
        if (!level.isClientSide && level.getBlockEntity(pos) instanceof LumberPileBlockEntity pile) {
            if (pile.insert(held, false) > 0) {
                if (!player.isCreative()) held.shrink(1);
                level.playSound(null, pos, SoundEvents.WOOD_PLACE, SoundSource.BLOCKS, 0.8F, 1.0F);
            }
        }
        return ItemInteractionResult.sidedSuccess(level.isClientSide);
    }

    @Override protected InteractionResult useWithoutItem(BlockState state, Level level, BlockPos pos, Player player, BlockHitResult hit) {
        if (!level.isClientSide && level.getBlockEntity(pos) instanceof LumberPileBlockEntity pile) {
            final ItemStack removed = pile.extract(1);
            if (!removed.isEmpty() && !player.getInventory().add(removed)) player.drop(removed, false);
            level.playSound(null, pos, SoundEvents.WOOD_HIT, SoundSource.BLOCKS, 0.7F, 1.0F);
        }
        return InteractionResult.sidedSuccess(level.isClientSide);
    }

    @Override protected void onRemove(BlockState state, Level level, BlockPos pos, BlockState replacement, boolean moving) {
        if (!state.is(replacement.getBlock()) && level.getBlockEntity(pos) instanceof LumberPileBlockEntity pile) {
            pile.dropContents();
        }
        super.onRemove(state, level, pos, replacement, moving);
    }

    public static LumberWood woodOf(ItemStack stack) {
        final ResourceLocation id = net.minecraft.core.registries.BuiltInRegistries.ITEM.getKey(stack.getItem());
        final String path = id.getPath();
        final String wood = path.substring(path.lastIndexOf('/') + 1);
        return LumberWood.byId(wood);
    }
}
