package io.github.likexiang21.tfcplus.agriculture.common.timber;

import io.github.likexiang21.tfcplus.agriculture.TFCAgriculturePlus;
import io.github.likexiang21.tfcplus.agriculture.common.container.BContainer;
import io.github.likexiang21.tfcplus.agriculture.common.registry.AgricultureBlockEntities;
import net.dries007.tfc.common.blockentities.InventoryBlockEntity;
import net.minecraft.core.BlockPos;
import net.minecraft.world.Containers;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.state.BlockState;
import net.neoforged.neoforge.items.ItemStackHandler;

/** One slot for one full stack of lumber; the blockstate COUNT is derived from it. */
public final class LumberPileBlockEntity extends InventoryBlockEntity<ItemStackHandler> implements BContainer {
    public LumberPileBlockEntity(BlockPos pos, BlockState state) {
        super(AgricultureBlockEntities.LUMBER_PILE.get(), pos, state, defaultInventory(1), TFCAgriculturePlus.MOD_ID);
    }

    public int lumberCount() { return inventory.getStackInSlot(0).getCount(); }

    public int insert(ItemStack held, boolean all) {
        if (held.isEmpty() || !held.is(LumberPileBlock.LUMBER)) return 0;
        final ItemStack current = inventory.getStackInSlot(0);
        if (!current.isEmpty() && !ItemStack.isSameItemSameComponents(current, held)) return 0;
        final int available = 64 - current.getCount();
        if (available <= 0) return 0;
        final int amount = Math.min(1, available);
        if (amount <= 0) return 0;
        final ItemStack added = held.copyWithCount(current.isEmpty() ? amount : current.getCount() + amount);
        inventory.setStackInSlot(0, added);
        updateState();
        setChanged();
        return amount;
    }

    public ItemStack extract(int amount) {
        final ItemStack current = inventory.getStackInSlot(0);
        if (current.isEmpty()) return ItemStack.EMPTY;
        final int taken = Math.min(amount, current.getCount());
        final ItemStack result = current.copyWithCount(taken);
        final int left = current.getCount() - taken;
        inventory.setStackInSlot(0, left == 0 ? ItemStack.EMPTY : current.copyWithCount(left));
        updateState();
        setChanged();
        return result;
    }

    public void dropContents() {
        if (level == null || level.isClientSide()) return;
        final ItemStack stack = inventory.getStackInSlot(0);
        if (!stack.isEmpty()) {
            Containers.dropItemStack(level, worldPosition.getX() + 0.5, worldPosition.getY() + 0.5,
                worldPosition.getZ() + 0.5, stack.copy());
            inventory.setStackInSlot(0, ItemStack.EMPTY);
        }
    }

    private void updateState() {
        if (level == null || level.isClientSide()) return;
        final int count = Math.max(1, Math.min(64, lumberCount()));
        final BlockState state = getBlockState();
        final LumberWood wood = lumberCount() == 0 ? state.getValue(LumberPileBlock.WOOD) : LumberPileBlock.woodOf(inventory.getStackInSlot(0));
        if (state.getValue(LumberPileBlock.COUNT) != count || state.getValue(LumberPileBlock.WOOD) != wood) {
            level.setBlock(worldPosition, state.setValue(LumberPileBlock.COUNT, count).setValue(LumberPileBlock.WOOD, wood), Block.UPDATE_CLIENTS);
        }
    }

    @Override public void setAndUpdateSlots(int slot) {
        setChanged();
        updateState();
    }

    @Override protected void onLoadAdditional() {
        updateState();
    }

    @Override public int getSlotStackLimit(int slot) { return 64; }

    @Override public boolean isItemValid(int slot, ItemStack stack) {
        return stack.is(LumberPileBlock.LUMBER);
    }

    @Override public net.neoforged.neoforge.items.IItemHandler bItemHandler() { return inventory; }
}
