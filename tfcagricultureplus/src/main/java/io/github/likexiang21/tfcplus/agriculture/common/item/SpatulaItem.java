package io.github.likexiang21.tfcplus.agriculture.common.item;

import io.github.likexiang21.tfcplus.agriculture.common.pan.SpatulaMaterial;
import net.minecraft.world.item.Item;

public final class SpatulaItem extends Item {
    private final SpatulaMaterial material;

    public SpatulaItem(SpatulaMaterial material) {
        super(material.properties());
        this.material = material;
    }

    public SpatulaMaterial material() { return material; }
}
