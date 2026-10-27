package io.github.likexiang21.tfcplus.agriculture.common.silkworm;

import io.github.likexiang21.tfcplus.agriculture.TFCAgriculturePlus;
import io.github.likexiang21.tfcplus.agriculture.common.registry.AgricultureItems;
import net.minecraft.world.inventory.AbstractContainerMenu;
import net.minecraft.world.inventory.Slot;
import net.minecraft.world.item.ItemStack;
import net.neoforged.bus.api.SubscribeEvent;
import net.neoforged.fml.common.EventBusSubscriber;
import net.neoforged.neoforge.event.entity.player.PlayerContainerEvent;

/** Settles adult lifespan whenever a player opens any inventory-backed menu. */
@EventBusSubscriber(modid = TFCAgriculturePlus.MOD_ID)
public final class SilkwormContainerEvents {
    @SubscribeEvent
    public static void onContainerOpen(PlayerContainerEvent.Open event) {
        if (event.getEntity().level().isClientSide()) return;
        final AbstractContainerMenu menu = event.getContainer();
        for (Slot slot : menu.slots) {
            final ItemStack stack = slot.getItem();
            if (!stack.is(AgricultureItems.ADULT_SILKWORM.get())) continue;
            SilkwormData.ageAdult(stack, event.getEntity().level());
            if (stack.isEmpty()) {
                slot.set(ItemStack.EMPTY);
            } else {
                slot.setChanged();
            }
        }
    }

    private SilkwormContainerEvents() {}
}
