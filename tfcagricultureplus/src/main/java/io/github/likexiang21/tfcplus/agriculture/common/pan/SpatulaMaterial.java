package io.github.likexiang21.tfcplus.agriculture.common.pan;

import net.minecraft.world.item.Item;

public enum SpatulaMaterial {
    COPPER("copper", 128),
    BISMUTH_BRONZE("bismuth_bronze", 192),
    BRONZE("bronze", 256),
    WROUGHT_IRON("wrought_iron", 384),
    STEEL("steel", 640),
    BLACK_STEEL("black_steel", 1024);

    private final String id;
    private final int durability;

    SpatulaMaterial(String id, int durability) {
        this.id = id;
        this.durability = durability;
    }

    public String id() { return id; }
    public String itemId() { return "spatula/" + id; }
    public String translationKey() { return "item.tfcagricultureplus.spatula." + id; }
    public String texture() { return "tfc:item/metal/knife/" + id; }
    public int durability() { return durability; }
    public Item.Properties properties() {
        return new Item.Properties().stacksTo(1).durability(durability);
    }
}
