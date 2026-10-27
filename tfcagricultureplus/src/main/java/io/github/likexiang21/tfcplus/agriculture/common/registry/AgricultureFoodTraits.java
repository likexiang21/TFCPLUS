package io.github.likexiang21.tfcplus.agriculture.common.registry;

import io.github.likexiang21.tfcplus.agriculture.TFCAgriculturePlus;
import net.dries007.tfc.common.component.food.FoodTrait;
import net.dries007.tfc.common.component.food.FoodTraits;
import net.neoforged.bus.api.IEventBus;
import net.neoforged.neoforge.registries.DeferredHolder;
import net.neoforged.neoforge.registries.DeferredRegister;

/** Food traits owned by B; kept separate from TFC's built-in trait semantics. */
public final class AgricultureFoodTraits {
    private static final DeferredRegister<FoodTrait> TRAITS =
        DeferredRegister.create(FoodTraits.KEY, TFCAgriculturePlus.MOD_ID);

    /** Seasoning is a preparation marker and does not change decay by itself. */
    public static final DeferredHolder<FoodTrait, FoodTrait> SEASONED =
        TRAITS.register("seasoned", () -> new FoodTrait(() -> 1.0D,
            "tfcagricultureplus.tooltip.food_trait.seasoned"));

    public static void register(IEventBus bus) {
        TRAITS.register(bus);
    }

    private AgricultureFoodTraits() {}
}
