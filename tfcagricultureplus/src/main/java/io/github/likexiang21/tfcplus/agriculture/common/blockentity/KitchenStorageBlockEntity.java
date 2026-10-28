package io.github.likexiang21.tfcplus.agriculture.common.blockentity;

import io.github.likexiang21.tfcplus.agriculture.common.container.BContainer;

import io.github.likexiang21.tfcplus.agriculture.TFCAgriculturePlus;
import io.github.likexiang21.tfcplus.agriculture.common.menu.KitchenStorageMenu;
import io.github.likexiang21.tfcplus.agriculture.common.registry.AgricultureBlockEntities;
import net.dries007.tfc.common.blockentities.InventoryBlockEntity;
import net.minecraft.core.BlockPos;
import net.minecraft.network.chat.Component;
import net.minecraft.world.Containers;
import net.minecraft.world.entity.player.Inventory;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.inventory.AbstractContainerMenu;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.level.block.state.BlockState;
import net.neoforged.neoforge.items.ItemStackHandler;

/**
 * Shared TFC inventory contract for the first kitchen furniture batch.
 * The block kind is visual/semantic metadata; inventory data never lives in blockstate.
 */
public final class KitchenStorageBlockEntity extends InventoryBlockEntity<ItemStackHandler>  implements BContainer {
    public static final int SLOTS = 9;

    public KitchenStorageBlockEntity(BlockPos pos, BlockState state) {
        super(AgricultureBlockEntities.KITCHEN_STORAGE.get(), pos, state,
            defaultInventory(SLOTS), TFCAgriculturePlus.MOD_ID);
    }

    @Override
    public AbstractContainerMenu createMenu(int containerId, Inventory playerInventory, Player player) {
        return KitchenStorageMenu.create(this, playerInventory, containerId);
    }

    @Override
    public Component getDisplayName() {
        return Component.translatable("block_entity.tfcagricultureplus.kitchen_storage");
    }

    @Override
    public int getSlotStackLimit(int slot) {
        return 64;
    }

    @Override
    public boolean isItemValid(int slot, ItemStack stack) {
        return slot >= 0 && slot < SLOTS && !stack.isEmpty();
    }

    public void dropContents() {
        if (level == null || level.isClientSide()) return;
        for (int slot = 0; slot < SLOTS; slot++) {
            final ItemStack stack = inventory.extractItem(slot, inventory.getStackInSlot(slot).getCount(), false);
            if (!stack.isEmpty()) {
                Containers.dropItemStack(level, worldPosition.getX() + 0.5,
                    worldPosition.getY() + 0.5, worldPosition.getZ() + 0.5, stack);
            }
        }
        setChanged();
    }

    @Override public net.neoforged.neoforge.items.IItemHandler bItemHandler() { return inventory; }
}
