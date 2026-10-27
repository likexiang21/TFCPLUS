package com.example.tfcfarmingplus.expansion.client;

import com.example.tfcfarmingplus.expansion.TFCAgriculturePlus;
import com.example.tfcfarmingplus.expansion.common.container.MyMenuTypes;
import net.neoforged.api.distmarker.Dist;
import net.neoforged.bus.api.SubscribeEvent;
import net.neoforged.fml.common.EventBusSubscriber;
import net.neoforged.neoforge.client.event.RegisterMenuScreensEvent;

@EventBusSubscriber(modid = TFCAgriculturePlus.MOD_ID, bus = EventBusSubscriber.Bus.MOD, value = Dist.CLIENT)
public final class ClientEvents {
    @SubscribeEvent
    public static void registerScreens(RegisterMenuScreensEvent event) {
        event.register(MyMenuTypes.SILKWORM_RACK.get(), SilkwormRackScreen::new);
        event.register(MyMenuTypes.KITCHEN_STORAGE.get(), KitchenStorageScreen::new);
    }

    private ClientEvents() {}
}
