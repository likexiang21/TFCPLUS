package io.github.likexiang21.tfcplus.agriculture.common.registry;

import io.github.likexiang21.tfcplus.agriculture.TFCAgriculturePlus;
import io.github.likexiang21.tfcplus.agriculture.common.item.SpatulaItem;
import io.github.likexiang21.tfcplus.agriculture.common.pan.SpatulaMaterial;
import java.util.LinkedHashMap;
import java.util.Map;
import net.minecraft.world.item.Item;
import net.neoforged.bus.api.IEventBus;
import net.neoforged.neoforge.registries.DeferredHolder;
import net.neoforged.neoforge.registries.DeferredRegister;

public final class AgricultureSpatulas {
    public static final DeferredRegister.Items ITEMS = DeferredRegister.createItems(TFCAgriculturePlus.MOD_ID);
    public static final Map<SpatulaMaterial, DeferredHolder<Item, Item>> ALL = new LinkedHashMap<>();

    static {
        for (final SpatulaMaterial material : SpatulaMaterial.values()) {
            ALL.put(material, ITEMS.register(material.itemId(), () -> new SpatulaItem(material)));
        }
    }

    public static void register(IEventBus bus) { ITEMS.register(bus); }

    private AgricultureSpatulas() {}
}
