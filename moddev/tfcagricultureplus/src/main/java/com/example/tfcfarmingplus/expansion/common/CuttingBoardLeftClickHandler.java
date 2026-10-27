package com.example.tfcfarmingplus.expansion.common;

import com.example.tfcfarmingplus.expansion.TFCAgriculturePlus;
import net.neoforged.fml.common.EventBusSubscriber;
import net.neoforged.neoforge.event.entity.player.PlayerInteractEvent;

/** Routes empty-hand left clicks on dough boards before Minecraft starts mining. */
@EventBusSubscriber(modid = TFCAgriculturePlus.MOD_ID)
public final class CuttingBoardLeftClickHandler {
    private CuttingBoardLeftClickHandler() {}

    @net.neoforged.bus.api.SubscribeEvent
    public static void onLeftClick(PlayerInteractEvent.LeftClickBlock event) {
        if (event.getHand() != net.minecraft.world.InteractionHand.MAIN_HAND) return;
        if (CuttingBoardInteractions.handleLeftClick(event.getLevel(), event.getPos(), event.getEntity())) {
            event.setCanceled(true);
        }
    }
}
