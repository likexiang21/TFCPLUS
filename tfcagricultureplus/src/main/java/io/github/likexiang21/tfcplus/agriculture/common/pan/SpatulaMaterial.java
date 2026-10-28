package io.github.likexiang21.tfcplus.agriculture.common.pan;

import net.minecraft.world.item.Item;

/** Spatula materials: wood plus the iron-family TFC metals. */
public enum SpatulaMaterial {
    WOOD("wood", 64, "tfc:item/wood/lumber"),
    WROUGHT_IRON("wrought_iron", 256, "tfc:item/metal/knife/wrought_iron"),
    STEEL("steel", 512, "tfc:item/metal/knife/steel"),
    BLACK_STEEL("black_steel", 768, "tfc:item/metal/knife/black_steel"),
    BLUE_STEEL("blue_steel", 1024, "tfc:item/metal/knife/blue_steel"),
    RED_STEEL("red_steel", 1024, "tfc:item/metal/knife/red_steel");

    private final String id;
    private final int durability;
    private final String texture;

    SpatulaMaterial(String id, int durability, String texture) {
        this.id = id;
        this.durability = durability;
        this.texture = texture;
    }

    public String id() { return id; }
    public String itemId() { return "spatula/" + id; }
    public String translationKey() { return "item.tfcagricultureplus.spatula." + id; }
    public String texture() { return texture; }
    public int durability() { return durability; }
    public Item.Properties properties() {
        return new Item.Properties().stacksTo(1).durability(durability);
    }
}
