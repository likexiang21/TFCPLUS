package io.github.likexiang21.tfcplus.agriculture.client;

import io.github.likexiang21.tfcplus.agriculture.TFCAgriculturePlus;
import io.github.likexiang21.tfcplus.agriculture.client.screen.KitchenStorageScreen;
import io.github.likexiang21.tfcplus.agriculture.client.screen.SilkwormRackScreen;
import io.github.likexiang21.tfcplus.agriculture.common.registry.AgricultureMenuTypes;
import net.neoforged.api.distmarker.Dist;
import net.neoforged.bus.api.SubscribeEvent;
import net.neoforged.fml.common.EventBusSubscriber;
import net.neoforged.neoforge.client.event.RegisterMenuScreensEvent;

@EventBusSubscriber(modid = TFCAgriculturePlus.MOD_ID, bus = EventBusSubscriber.Bus.MOD, value = Dist.CLIENT)
public final class ClientEvents {
    @SubscribeEvent
    public static void registerScreens(RegisterMenuScreensEvent event) {
        event.register(AgricultureMenuTypes.SILKWORM_RACK.get(), SilkwormRackScreen::new);
        event.register(AgricultureMenuTypes.KITCHEN_STORAGE.get(), KitchenStorageScreen::new);
    }

    private ClientEvents() {}
}
