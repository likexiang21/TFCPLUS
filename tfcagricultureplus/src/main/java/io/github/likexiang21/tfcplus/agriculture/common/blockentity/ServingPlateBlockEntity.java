package io.github.likexiang21.tfcplus.agriculture.common.blockentity;

import io.github.likexiang21.tfcplus.agriculture.common.pan.PanDishData;
import io.github.likexiang21.tfcplus.agriculture.common.registry.AgriculturePlates;
import net.minecraft.core.BlockPos;
import net.minecraft.core.HolderLookup;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.level.block.entity.BlockEntity;
import net.minecraft.world.level.block.state.BlockState;

/** Stores the whole plated dish stack so TFC's creation date survives placement. */
public final class ServingPlateBlockEntity extends BlockEntity {
    private ItemStack plateStack = ItemStack.EMPTY;

    public ServingPlateBlockEntity(BlockPos pos, BlockState state) {
        super(AgriculturePlates.PLATE_BE.get(), pos, state);
    }

    public ItemStack plateStack() { return plateStack; }
    public boolean hasDish() { return PanDishData.read(plateStack) != null; }

    public void setPlateStack(ItemStack stack) {
        this.plateStack = stack.copyWithCount(1);
        setChanged();
        if (level != null && !level.isClientSide()) {
            level.sendBlockUpdated(worldPosition, getBlockState(), getBlockState(), 3);
        }
    }

    public void clearPlate() {
        plateStack = ItemStack.EMPTY;
        setChanged();
    }

    public ItemStack dropStack() {
        return plateStack.isEmpty()
            ? new ItemStack(AgriculturePlates.itemFor(getBlockState().getValue(AgriculturePlates.VARIANT)).get())
            : plateStack.copyWithCount(1);
    }

    @Override
    protected void saveAdditional(CompoundTag tag, HolderLookup.Provider registries) {
        super.saveAdditional(tag, registries);
        if (!plateStack.isEmpty()) tag.put("plate", plateStack.save(registries));
    }

    @Override
    protected void loadAdditional(CompoundTag tag, HolderLookup.Provider registries) {
        super.loadAdditional(tag, registries);
        plateStack = tag.contains("plate") ? ItemStack.parseOptional(registries, tag.getCompound("plate")) : ItemStack.EMPTY;
    }
}
