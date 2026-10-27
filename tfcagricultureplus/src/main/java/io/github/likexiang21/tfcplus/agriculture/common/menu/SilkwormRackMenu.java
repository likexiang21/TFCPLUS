package io.github.likexiang21.tfcplus.agriculture.common.menu;

import io.github.likexiang21.tfcplus.agriculture.common.blockentity.SilkwormRackBlockEntity;
import io.github.likexiang21.tfcplus.agriculture.common.registry.AgricultureMenuTypes;
import net.dries007.tfc.common.container.BlockEntityContainer;
import net.dries007.tfc.common.container.Container;
import net.dries007.tfc.common.container.slot.CallbackSlot;
import net.minecraft.world.entity.player.Inventory;
import net.minecraft.world.inventory.MenuType;
import net.minecraft.world.item.ItemStack;

/** Three-zone menu: 8 biological slots, 2 stackable feed slots, and one output slot. */
public final class SilkwormRackMenu extends BlockEntityContainer<SilkwormRackBlockEntity> {
    public static SilkwormRackMenu create(SilkwormRackBlockEntity rack, Inventory playerInventory, int windowId) {
        return new SilkwormRackMenu(rack, playerInventory, windowId).init(playerInventory);
    }

    private SilkwormRackMenu(SilkwormRackBlockEntity rack, Inventory playerInventory, int windowId) {
        super((MenuType<?>) AgricultureMenuTypes.SILKWORM_RACK.get(), windowId, rack);
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
        for (int i = 0; i < SilkwormRackBlockEntity.BIOLOGICAL_SLOTS; i++) {
            this.addSlot(new CallbackSlot(this.blockEntity, i, 8 + i * 18, 18));
        }
        for (int i = 0; i < SilkwormRackBlockEntity.FEED_SLOTS; i++) {
            this.addSlot(new CallbackSlot(this.blockEntity,
                SilkwormRackBlockEntity.FEED_START + i, 8 + i * 18, 54));
        }
        this.addSlot(new CallbackSlot(this.blockEntity, SilkwormRackBlockEntity.OUTPUT_SLOT, 152, 54));
    }
}
