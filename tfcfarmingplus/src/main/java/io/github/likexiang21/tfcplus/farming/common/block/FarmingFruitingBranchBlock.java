package io.github.likexiang21.tfcplus.farming.common.block;

import java.util.function.Supplier;
import net.dries007.tfc.client.overworld.SolarCalculator;
import net.dries007.tfc.common.TFCTags;
import net.dries007.tfc.common.blockentities.TickingPlantBlockEntity;
import net.dries007.tfc.common.blocks.EntityBlockExtension;
import net.dries007.tfc.common.blocks.ExtendedProperties;
import net.dries007.tfc.common.blocks.plant.fruit.FruitTreeBranchBlock;
import net.dries007.tfc.common.blocks.plant.fruit.Lifecycle;
import net.dries007.tfc.config.TFCConfig;
import net.dries007.tfc.util.calendar.Calendars;
import net.dries007.tfc.util.climate.Climate;
import net.dries007.tfc.util.climate.ClimateRange;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.sounds.SoundEvents;
import net.minecraft.sounds.SoundSource;
import net.minecraft.util.RandomSource;
import net.minecraft.world.InteractionHand;
import net.minecraft.world.ItemInteractionResult;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.item.Item;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.LevelReader;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.StateDefinition;
import net.minecraft.world.level.block.state.properties.EnumProperty;
import net.minecraft.world.phys.BlockHitResult;
import net.neoforged.neoforge.items.ItemHandlerHelper;

/**
 * Project trunk-fruit state machine, independently implemented against public TFC APIs.
 * Serialized fruit states and ticking-plant NBT remain compatible. Native code owns
 * the tree geometry; this block owns fruit eligibility, two timed stages and harvest.
 */
public class FarmingFruitingBranchBlock extends FruitTreeBranchBlock implements EntityBlockExtension {
    public static final EnumProperty<FruitState> FRUIT = EnumProperty.create("fruit", FruitState.class);
    private static final long UNINITIALIZED_TICK = Integer.MIN_VALUE;
    private final Supplier<ClimateRange> climateRange;
    private final Supplier<? extends Item> productItem;
    private final Lifecycle[] lifecycle;

    public FarmingFruitingBranchBlock(ExtendedProperties properties, Supplier<ClimateRange> climateRange,
                                Supplier<? extends Item> productItem, Lifecycle[] lifecycle) {
        super(properties, climateRange);
        this.climateRange = climateRange;
        this.productItem = productItem;
        this.lifecycle = lifecycle;
        registerDefaultState(defaultBlockState().setValue(FRUIT, FruitState.NONE));
    }

    @Override
    protected void createBlockStateDefinition(StateDefinition.Builder<Block, BlockState> builder) {
        super.createBlockStateDefinition(builder);
        builder.add(FRUIT);
    }

    public static boolean canBearFruit(BlockState state, LevelReader level, BlockPos pos) {
        if (!state.getValue(UP) || !state.getValue(DOWN)) return false;
        for (Direction direction : Direction.values()) {
            if (level.getBlockState(pos.relative(direction)).is(TFCTags.Blocks.FRUIT_TREE_LEAVES)) return false;
        }
        return true;
    }

    // Only repair the former default-to-self root when a complete vertical route
    // ends on native plantable soil. Never follow an unloaded chunk or guess a
    // horizontal graft's root, and never replace an already explicit root.
    private void repairLegacyRoot(ServerLevel level, BlockPos pos, TickingPlantBlockEntity counter) {
        if (!counter.getStemPos().equals(pos)) return;
        BlockPos cursor = pos;
        for (int depth = 0; depth < 64; depth++) {
            BlockPos below = cursor.below();
            if (!level.hasChunkAt(below)) return;
            BlockState support = level.getBlockState(below);
            if (support.is(TFCTags.Blocks.FRUIT_TREE_BRANCH)) {
                cursor = below;
            } else {
                if (support.is(TFCTags.Blocks.BUSH_PLANTABLE_ON) && !cursor.equals(pos)) counter.setStemPos(cursor);
                return;
            }
        }
    }

    @Override
    protected void randomTick(BlockState state, ServerLevel level, BlockPos pos, RandomSource random) {
        super.randomTick(state, level, pos, random);
        BlockState currentState = level.getBlockState(pos);
        if (!currentState.is(this) || !(level.getBlockEntity(pos) instanceof TickingPlantBlockEntity counter)) return;
        repairLegacyRoot(level, pos, counter);
        FruitState current = currentState.getValue(FRUIT);
        BlockPos root = counter.getStemPos().below();
        Lifecycle month = lifecycle[Calendars.SERVER.getHemispheralCalendarMonthOfYear(
            SolarCalculator.getInNorthernHemisphere(root, level)).ordinal()];
        boolean suitable = canBearFruit(currentState, level, pos) && month == Lifecycle.FRUITING
            && climateRange.get().checkBoth(FarmingGrowingFruitTreeBranchBlock.rootHydration(level, pos),
                Climate.getAverageTemperature(level, root), false);
        if (!suitable) {
            if (current != FruitState.NONE) level.setBlock(pos, currentState.setValue(FRUIT, FruitState.NONE), 3);
            counter.resetCounter();
            return;
        }
        if (counter.getLastUpdateTick() == UNINITIALIZED_TICK) {
            counter.resetCounter();
            return;
        }
        if (current == FruitState.RIPE) return;
        long interval = TFCConfig.SERVER.berryBushGrowthTicks.get();
        if (interval <= 0L) { counter.resetCounter(); return; }
        long elapsed = Math.max(0L, counter.getTicksSinceUpdate());
        int steps = (int) Math.min(2 - current.ordinal(), elapsed / interval);
        if (steps == 0) return;
        FruitState next = FruitState.values()[current.ordinal() + steps];
        if (level.setBlock(pos, currentState.setValue(FRUIT, next), 3)) {
            // Consume completed stages only; keep the fractional interval.
            counter.setLastUpdateTick(counter.getLastUpdateTick() + steps * interval);
        }
    }

    @Override
    protected ItemInteractionResult useItemOn(ItemStack stack, BlockState state, Level level,
                                               BlockPos pos, Player player, InteractionHand hand, BlockHitResult hitResult) {
        if (state.getValue(FRUIT) != FruitState.RIPE) return super.useItemOn(stack, state, level, pos, player, hand, hitResult);
        if (level.isClientSide()) return ItemInteractionResult.sidedSuccess(true);
        BlockState currentState = level.getBlockState(pos);
        if (!currentState.is(this) || currentState.getValue(FRUIT) != FruitState.RIPE || !canBearFruit(currentState, level, pos)
            || !(level.getBlockEntity(pos) instanceof TickingPlantBlockEntity counter)) return ItemInteractionResult.FAIL;
        // Commit removal before awarding the item. A stale/off-hand request or
        // unsuccessful state change cannot award another copy.
        if (!level.setBlock(pos, currentState.setValue(FRUIT, FruitState.NONE), 3)) return ItemInteractionResult.FAIL;
        counter.resetCounter();
        counter.resetLastPickedCounter();
        ItemHandlerHelper.giveItemToPlayer(player, new ItemStack(productItem.get()));
        level.playSound(null, pos, SoundEvents.SWEET_BERRY_BUSH_PICK_BERRIES, SoundSource.PLAYERS, 1.0f, 1.0f);
        return ItemInteractionResult.sidedSuccess(false);
    }
}
