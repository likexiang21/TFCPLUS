package io.github.likexiang21.tfcplus.agriculture.common.menu;

import io.github.likexiang21.tfcplus.agriculture.common.blockentity.KitchenStorageBlockEntity;
import io.github.likexiang21.tfcplus.agriculture.common.registry.AgricultureMenuTypes;
import net.dries007.tfc.common.container.BlockEntityContainer;
import net.dries007.tfc.common.container.Container;
import net.dries007.tfc.common.container.slot.CallbackSlot;
import net.minecraft.world.entity.player.Inventory;
import net.minecraft.world.inventory.MenuType;
import net.minecraft.world.item.ItemStack;

/** Nine-slot TFC menu shared by the first kitchen furniture batch. */
public final class KitchenStorageMenu extends BlockEntityContainer<KitchenStorageBlockEntity> {
    public static KitchenStorageMenu create(KitchenStorageBlockEntity storage,
                                             Inventory playerInventory, int windowId) {
        return new KitchenStorageMenu(storage, playerInventory, windowId).init(playerInventory);
    }

    private KitchenStorageMenu(KitchenStorageBlockEntity storage, Inventory playerInventory, int windowId) {
        super((MenuType<?>) AgricultureMenuTypes.KITCHEN_STORAGE.get(), windowId, storage);
    }

    @Override
    protected boolean moveStack(ItemStack stack, int slotIndex) {
        if (this.typeOf(slotIndex) == Container.IndexType.CONTAINER) {
            return !this.moveItemStackTo(stack, this.containerSlots, this.slots.size(), false);
        }
        return !this.moveItemStackTo(stack, 0, this.containerSlots, false);
    }

    @Override
    protected void addContainerSlots() {
        for (int slot = 0; slot < KitchenStorageBlockEntity.SLOTS; slot++) {
            this.addSlot(new CallbackSlot(this.blockEntity, slot,
                8 + (slot % 9) * 18, 18 + (slot / 9) * 18));
        }
    }
}
