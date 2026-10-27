package io.github.likexiang21.tfcplus.agriculture.common.registry;

import io.github.likexiang21.tfcplus.agriculture.TFCAgriculturePlus;
import io.github.likexiang21.tfcplus.agriculture.common.item.ServingBowlItem;
import net.minecraft.world.item.Item;
import net.neoforged.bus.api.IEventBus;
import net.neoforged.neoforge.registries.DeferredHolder;
import net.neoforged.neoforge.registries.DeferredRegister;

public final class AgricultureBowls {
    public static final DeferredRegister.Items ITEMS = DeferredRegister.createItems(TFCAgriculturePlus.MOD_ID);

    public static final DeferredHolder<Item, Item> WOOD_BOWL =
        ITEMS.register("bowl/wood", () -> new ServingBowlItem(new Item.Properties().stacksTo(1)));
    public static final DeferredHolder<Item, Item> CERAMIC_BOWL =
        ITEMS.register("bowl/ceramic", () -> new ServingBowlItem(new Item.Properties().stacksTo(1)));

    public static void register(IEventBus bus) { ITEMS.register(bus); }

    private AgricultureBowls() {}
}
