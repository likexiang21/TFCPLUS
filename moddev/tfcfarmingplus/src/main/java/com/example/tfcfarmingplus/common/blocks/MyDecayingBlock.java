package com.example.tfcfarmingplus.common.blocks;

import com.example.tfcfarmingplus.common.MyBlockEntities;
import com.example.tfcfarmingplus.common.blockentities.MyDecayingBlockEntity;
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
import java.util.function.Supplier;

/**
 * Whole fruit uses the project BE type and TFC's stored-food lifecycle.
 * Native spreading growth and player placement both seed the stored stack.
 * Only missing legacy stacks start a new food date; existing dates are retained.
 * Native removal returns the whole stored fruit, so block loot must be empty.
 */
public class MyDecayingBlock extends DecayingBlock {
    public MyDecayingBlock(ExtendedProperties properties, Supplier<? extends Block> rotten) {
        super(properties, rotten);
    }

    @Override
    public BlockEntity newBlockEntity(BlockPos pos, BlockState state) {
        return new MyDecayingBlockEntity(pos, state);
    }

    @Override
    public <T extends BlockEntity> BlockEntityTicker<T> getTicker(Level level, BlockState state, BlockEntityType<T> type) {
        if (level.isClientSide || type != MyBlockEntities.DECAYING.get()) {
            return null;
        }
        return (world, pos, blockState, entity) -> {
            if (entity instanceof MyDecayingBlockEntity fruit) {
                if (fruit.getStack().isEmpty()) {
                    fruit.setStack(FoodCapability.setCreatedNow(new ItemStack(asItem())));
                }
                DecayingBlockEntity.serverTick(world, pos, blockState, fruit);
            }
        };
    }
}
