package io.github.likexiang21.tfcplus.farming.common.block;

import io.github.likexiang21.tfcplus.farming.common.blockentity.FarmingDecayingBlockEntity;
import io.github.likexiang21.tfcplus.farming.common.registry.FarmingBlockEntities;
import java.util.function.Supplier;
import net.dries007.tfc.common.blockentities.DecayingBlockEntity;
import net.dries007.tfc.common.blocks.ExtendedProperties;
import net.dries007.tfc.common.blocks.crop.DecayingBlock;
import net.dries007.tfc.common.component.food.FoodCapability;
import net.minecraft.core.BlockPos;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.entity.BlockEntity;
import net.minecraft.world.level.block.entity.BlockEntityTicker;
import net.minecraft.world.level.block.entity.BlockEntityType;
import net.minecraft.world.level.block.state.BlockState;

/**
 * Whole fruit uses the project BE type and TFC's stored-food lifecycle.
 * Native spreading growth and player placement both seed the stored stack.
 * Only missing legacy stacks start a new food date; existing dates are retained.
 * Native removal returns the whole stored fruit, so block loot must be empty.
 */
public class FarmingDecayingBlock extends DecayingBlock {
    public FarmingDecayingBlock(ExtendedProperties properties, Supplier<? extends Block> rotten) {
        super(properties, rotten);
    }

    @Override
    public BlockEntity newBlockEntity(BlockPos pos, BlockState state) {
        return new FarmingDecayingBlockEntity(pos, state);
    }

    @Override
    public <T extends BlockEntity> BlockEntityTicker<T> getTicker(Level level, BlockState state, BlockEntityType<T> type) {
        if (level.isClientSide || type != FarmingBlockEntities.DECAYING.get()) {
            return null;
        }
        return (world, pos, blockState, entity) -> {
            if (entity instanceof FarmingDecayingBlockEntity fruit) {
                if (fruit.getStack().isEmpty()) {
                    fruit.setStack(FoodCapability.setCreatedNow(new ItemStack(asItem())));
                }
                DecayingBlockEntity.serverTick(world, pos, blockState, fruit);
            }
        };
    }
}
