package com.example.tfcfarmingplus.expansion.common.timber;

import com.example.tfcfarmingplus.expansion.common.MyBlockEntities;
import com.example.tfcfarmingplus.expansion.TFCAgriculturePlus;
import com.mojang.serialization.MapCodec;
import net.minecraft.core.*;
import net.minecraft.core.registries.Registries;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.tags.*;
import net.minecraft.util.RandomSource;
import net.minecraft.world.*;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.item.*;
import net.minecraft.world.item.context.BlockPlaceContext;
import net.minecraft.world.level.*;
import net.minecraft.world.level.block.*;
import net.minecraft.world.level.block.entity.*;
import net.minecraft.world.level.block.state.*;
import net.minecraft.world.level.block.state.properties.*;
import net.minecraft.world.phys.BlockHitResult;
import net.minecraft.world.phys.shapes.*;

public final class TimberPileBlock extends Block implements EntityBlock {
    public static final EnumProperty<Direction.Axis> AXIS = BlockStateProperties.HORIZONTAL_AXIS;
    /** One state step equals one quarter-log layer, matching TFC Woodworking's 1..16 count. */
    public static final IntegerProperty LAYERS = IntegerProperty.create("layers", 1, 16);
    public static final TagKey<Item> LOGS = TagKey.create(Registries.ITEM, ResourceLocation.fromNamespaceAndPath(TFCAgriculturePlus.MOD_ID, "log_pile_logs"));
    public final boolean burning;
    public TimberPileBlock(Properties properties, boolean burning) {
        super(properties); this.burning = burning;
        registerDefaultState(stateDefinition.any().setValue(AXIS, Direction.Axis.Z).setValue(LAYERS, 1));
    }
    @Override protected MapCodec<? extends Block> codec() { return simpleCodec(p -> new TimberPileBlock(p, burning)); }
    @Override protected void createBlockStateDefinition(StateDefinition.Builder<Block, BlockState> builder) { builder.add(AXIS, LAYERS); }
    @Override public BlockState getStateForPlacement(BlockPlaceContext context) { return defaultBlockState().setValue(AXIS, context.getHorizontalDirection().getAxis()); }
    @Override protected boolean canSurvive(BlockState state, LevelReader level, BlockPos pos) {
        return level.getBlockState(pos.below()).getBlock() instanceof TimberPileBlock || Block.canSupportRigidBlock(level, pos.below());
    }
    @Override protected BlockState updateShape(BlockState state, Direction direction, BlockState neighbor, LevelAccessor level, BlockPos pos, BlockPos neighborPos) {
        return direction == Direction.DOWN && !canSurvive(state, level, pos) ? Blocks.AIR.defaultBlockState() : state;
    }
    @Override public BlockEntity newBlockEntity(BlockPos pos, BlockState state) { return burning ? new BurningTimberPileBlockEntity(pos, state) : new TimberPileBlockEntity(pos, state); }
    @Override public <T extends BlockEntity> BlockEntityTicker<T> getTicker(Level level, BlockState state, BlockEntityType<T> type) {
        return !level.isClientSide && burning && type == MyBlockEntities.BURNING_TIMBER_PILE.get() ? (l,p,s,be) -> ((BurningTimberPileBlockEntity)be).tick((ServerLevel)l) : null;
    }
    @Override protected RenderShape getRenderShape(BlockState state) { return RenderShape.ENTITYBLOCK_ANIMATED; }
    @Override protected VoxelShape getShape(BlockState state, BlockGetter level, BlockPos pos, CollisionContext context) {
        if (!burning && level.getBlockEntity(pos) instanceof TimberPileBlockEntity be) {
            VoxelShape shape = Shapes.empty();
            for(int slot=0;slot<16;slot++) {
                ItemStack stack=be.get(slot); if(stack.isEmpty()) continue;
                int weight=TimberBlocks.weight(stack);
                boolean piece=stack.getItem() instanceof BlockItem item && item.getBlock() instanceof TimberPieceBlock;
                double width=weight==1?.09375:(piece?.21875:.25), height=weight<4?.09375:width;
                for(int part=0;part<stack.getCount();part++) {
                    double cross=slot%4*.25+.125+(weight==1?(part%2==0?-.055:.055):0);
                    double y=slot/4*.25+.125+(weight==2?(part==0?-.055:.055):weight==1?(part/2==0?-.055:.055):0);
                    shape=Shapes.or(shape,state.getValue(AXIS)==Direction.Axis.Z
                        ? Shapes.box(cross-width/2,y-height/2,0,cross+width/2,y+height/2,1)
                        : Shapes.box(0,y-height/2,cross-width/2,1,y+height/2,cross+width/2));
                }
            }
            return shape;
        }
        final int height = ((state.getValue(LAYERS) + 3) / 4) * 4;
        return Block.box(0, 0, 0, 16, height, 16);
    }
    @Override public void setPlacedBy(Level level, BlockPos pos, BlockState state, net.minecraft.world.entity.LivingEntity entity, ItemStack stack) {
        if (!level.isClientSide && level.getBlockEntity(pos) instanceof TimberPileBlockEntity be) be.insert(stack.copyWithCount(1));
    }
    @Override protected ItemInteractionResult useItemOn(ItemStack held, BlockState state, Level level, BlockPos pos, Player player, InteractionHand hand, BlockHitResult hit) {
        if (held.isEmpty()) return ItemInteractionResult.PASS_TO_DEFAULT_BLOCK_INTERACTION;
        if (burning) return ItemInteractionResult.PASS_TO_DEFAULT_BLOCK_INTERACTION;
        boolean handled = false;
        if (!level.isClientSide && level.getBlockEntity(pos) instanceof TimberPileBlockEntity be) {
            if (held.is(LOGS)) {
                insertIntoColumn(level, state, pos, be, held, player.isShiftKeyDown(), player);
                handled = true;
            } else if (held.is(Items.FLINT_AND_STEEL) || held.is(Items.FIRE_CHARGE)) {
                ignite((ServerLevel)level, pos);
                if (!player.isCreative()) { if (held.is(Items.FLINT_AND_STEEL)) held.hurtAndBreak(1, player, net.minecraft.world.entity.EquipmentSlot.MAINHAND); else held.shrink(1); }
                handled = true;
            }
        }
        // Irrelevant held items must keep the normal block interaction path (for
        // example, a shovel or a block placed against the pile).
        if (!handled && level.isClientSide && (held.is(LOGS) || held.is(Items.FLINT_AND_STEEL) || held.is(Items.FIRE_CHARGE))) {
            handled = true;
        }
        return handled ? ItemInteractionResult.sidedSuccess(level.isClientSide) : ItemInteractionResult.PASS_TO_DEFAULT_BLOCK_INTERACTION;
    }

    /**
     * Inserts one item for a normal click or the whole compatible hand stack for a
     * crouch click.  Each pass resolves the destination again so a full lower pile
     * can create and fill the next pile above it.
     */
    private static void insertIntoColumn(Level level, BlockState state, BlockPos pos,
                                         TimberPileBlockEntity start, ItemStack held,
                                         boolean all, Player player) {
        if (!start.acceptsWood(held)) return;
        int inserted = 0;
        do {
            TimberPileBlockEntity target = start;
            for (int i = 0; i < 64 && !target.canInsert(held); i++) {
                if (!target.acceptsWood(held)) break;
                BlockPos above = target.getBlockPos().above();
                if (!level.hasChunkAt(above)) break;
                if (level.isEmptyBlock(above)) {
                    level.setBlockAndUpdate(above, TimberBlocks.PILE.get().defaultBlockState().setValue(AXIS, state.getValue(AXIS)));
                }
                if (level.getBlockEntity(above) instanceof TimberPileBlockEntity next && next.acceptsWood(held)) target = next;
                else break;
            }
            if (!target.insert(held)) break;
            inserted++;
            if (!player.isCreative()) held.shrink(1);
        } while (all && !held.isEmpty());

        if (inserted > 0 && level instanceof net.minecraft.server.level.ServerLevel server) {
            level.playSound(null, pos, net.minecraft.sounds.SoundEvents.WOOD_PLACE,
                net.minecraft.sounds.SoundSource.BLOCKS, 0.8f, 1.0f);
        }
    }
    @Override protected InteractionResult useWithoutItem(BlockState state, Level level, BlockPos pos, Player player, BlockHitResult hit) {
        if (!level.isClientSide && !burning && level.getBlockEntity(pos) instanceof TimberPileBlockEntity be) {
            TimberPileBlockEntity target = be;
            for (int i=0; i<64; i++) {
                if (level.getBlockEntity(target.getBlockPos().above()) instanceof TimberPileBlockEntity next) target = next; else break;
            }
            ItemStack out = target.extract();
            if (!out.isEmpty() && !player.getInventory().add(out)) player.drop(out, false);
        }
        return InteractionResult.sidedSuccess(level.isClientSide);
    }
    @Override protected void onRemove(BlockState state, Level level, BlockPos pos, BlockState replacement, boolean moving) {
        if (!state.is(replacement.getBlock()) && level.getBlockEntity(pos) instanceof TimberPileBlockEntity be) be.dropContents();
        super.onRemove(state, level, pos, replacement, moving);
    }
    @Override protected void neighborChanged(BlockState state, Level level, BlockPos pos, Block block, BlockPos neighbor, boolean moving) {
        if (!burning && !level.isClientSide && (level.getBlockState(neighbor).is(BlockTags.FIRE) || level.getBlockState(neighbor).is(TimberBlocks.BURNING.get()))) level.scheduleTick(pos, this, 30);
    }
    @Override protected void tick(BlockState state, ServerLevel level, BlockPos pos, RandomSource random) {
        // This tick is scheduled only after adjacent fire: sealing the opening must not cancel ignition.
        if (!burning) ignite(level, pos);
    }
    public static void ignite(ServerLevel level, BlockPos pos) {
        if (!(level.getBlockEntity(pos) instanceof TimberPileBlockEntity)) return;
        BlockPos bottom = pos;
        for (int i = 0; i < 63 && level.getBlockEntity(bottom.below()) instanceof TimberPileBlockEntity; i++) bottom = bottom.below();
        final java.util.List<BlockPos> column = new java.util.ArrayList<>();
        for (int i = 0; i < 64; i++) {
            BlockPos current = bottom.above(i);
            if (!(level.getBlockEntity(current) instanceof TimberPileBlockEntity)) break;
            column.add(current);
        }
        for (BlockPos current : column) {
            TimberPileBlockEntity pile = (TimberPileBlockEntity) level.getBlockEntity(current);
            if (pile == null) continue;
            int units = pile.units();
            BlockState state = pile.getBlockState();
            pile.clear();
            level.setBlockAndUpdate(current, TimberBlocks.BURNING.get().defaultBlockState()
                .setValue(AXIS, state.getValue(AXIS)).setValue(LAYERS, state.getValue(LAYERS)));
            if (level.getBlockEntity(current) instanceof BurningTimberPileBlockEntity burningBe) burningBe.light(units);
        }
    }
    @Override public void animateTick(BlockState state, Level level, BlockPos pos, RandomSource random) {
        if (burning && random.nextInt(4) == 0) level.addParticle(net.minecraft.core.particles.ParticleTypes.CAMPFIRE_COSY_SMOKE, pos.getX()+random.nextDouble(),pos.getY()+1,pos.getZ()+random.nextDouble(),0,0.03,0);
    }
}
