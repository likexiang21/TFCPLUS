package io.github.likexiang21.tfcplus.agriculture.common.item;

import net.dries007.tfc.common.TFCTags;
import net.dries007.tfc.common.items.FluidContainerItem;
import net.minecraft.tags.TagKey;
import net.minecraft.world.level.material.Fluid;

/** A 500 mB metal can: larger than the 100 mB ceramic jug, smaller than a 1000 mB bucket. */
public final class MetalCanItem extends FluidContainerItem {
    public static final int CAPACITY = 500;
    public static final TagKey<Fluid> CAN_FLUIDS = TagKey.create(
        net.minecraft.core.registries.Registries.FLUID,
        net.minecraft.resources.ResourceLocation.fromNamespaceAndPath("tfcagricultureplus", "metal_can_fluids"));

    public MetalCanItem(Properties properties) {
        super(properties, () -> CAPACITY, CAN_FLUIDS, false, () -> false);
    }
}
