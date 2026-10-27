package io.github.likexiang21.tfcplus.agriculture.common.kitchen;

import net.minecraft.core.registries.BuiltInRegistries;
import net.minecraft.world.item.ItemStack;

/** Baking rules for this mod's fifteen uncooked oven inputs. */
public final class BakingOvenRules {
    public static final float BAKING_TEMPERATURE_C = 400.0F;

    public static boolean isOurUnbakedFood(ItemStack stack) {
        if (stack.isEmpty()) return false;
        final var id = BuiltInRegistries.ITEM.getKey(stack.getItem());
        if (!id.getNamespace().equals("tfcagricultureplus")) return false;
        final String path = id.getPath();
        if (path.equals("food/raw_cake_base") || path.equals("food/raw_cupcake")
            || path.equals("food/raw_sweet_pancake")) return true;
        if (!path.startsWith("food/raw_")) return false;
        for (final String grain : new String[] {"wheat", "oat", "barley", "maize", "rye", "rice"}) {
            if (path.equals("food/raw_" + grain + "_naan")
                || path.equals("food/raw_" + grain + "_bun")) return true;
        }
        return false;
    }

    private BakingOvenRules() {}
}
