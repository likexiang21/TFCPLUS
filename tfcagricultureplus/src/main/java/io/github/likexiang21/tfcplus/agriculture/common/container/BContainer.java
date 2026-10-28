package io.github.likexiang21.tfcplus.agriculture.common.container;

import net.minecraft.world.Container;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.item.ItemStack;
import net.neoforged.neoforge.items.IItemHandler;

/**
 * Adapter exposing a B block entity's NeoForge item handler through the vanilla
 * {@link Container} interface. This keeps hoppers, droppers, comparators and
 * other vanilla container users compatible without replacing TFC's inventory
 * base classes.
 */
public interface BContainer extends Container {
    IItemHandler bItemHandler();

    @Override default int getContainerSize() { return bItemHandler().getSlots(); }

    @Override default boolean isEmpty() {
        for (int i = 0; i < getContainerSize(); i++) if (!getItem(i).isEmpty()) return false;
        return true;
    }

    @Override default ItemStack getItem(int slot) {
        return slot >= 0 && slot < getContainerSize() ? bItemHandler().getStackInSlot(slot) : ItemStack.EMPTY;
    }

    @Override default ItemStack removeItem(int slot, int amount) {
        return slot >= 0 && slot < getContainerSize()
            ? bItemHandler().extractItem(slot, amount, false) : ItemStack.EMPTY;
    }

    @Override default ItemStack removeItemNoUpdate(int slot) {
        if (slot < 0 || slot >= getContainerSize()) return ItemStack.EMPTY;
        final ItemStack stack = bItemHandler().getStackInSlot(slot);
        bItemHandler().extractItem(slot, stack.getCount(), false);
        return stack;
    }

    @Override default void setItem(int slot, ItemStack stack) {
        if (slot < 0 || slot >= getContainerSize()) return;
        if (bItemHandler() instanceof net.neoforged.neoforge.items.IItemHandlerModifiable modifiable) {
            modifiable.setStackInSlot(slot, stack);
        }
    }

    @Override default boolean stillValid(Player player) { return true; }

    @Override default void clearContent() {
        for (int i = 0; i < getContainerSize(); i++) setItem(i, ItemStack.EMPTY);
    }

    @Override default int getMaxStackSize() { return 64; }

    @Override default boolean canPlaceItem(int slot, ItemStack stack) {
        return slot >= 0 && slot < getContainerSize() && bItemHandler().isItemValid(slot, stack);
    }
}
