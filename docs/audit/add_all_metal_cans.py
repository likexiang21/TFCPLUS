from pathlib import Path

p = Path("mod_rebuild/tfcagricultureplus/src/main/java/io/github/likexiang21/tfcplus/agriculture/common/registry/AgricultureItems.java")
t = p.read_text(encoding="utf-8")
old = '''    /** 500 mB metal can, crafted from an anvil-formed head/sheet. */
    public static final DeferredHolder<Item, Item> METAL_CAN =
        ITEMS.register("metal_can", () -> new MetalCanItem(new Item.Properties().stacksTo(1)));
'''
new = '''    /** 500 mB metal cans, one per sheet-capable TFC metal. */
    public static final Map<String, DeferredHolder<Item, Item>> METAL_CANS = new LinkedHashMap<>();
    static {
        for (final String metal : new String[]{
            "bismuth", "bismuth_bronze", "black_bronze", "bronze", "brass",
            "copper", "gold", "nickel", "rose_gold", "silver", "tin", "zinc",
            "sterling_silver", "wrought_iron", "cast_iron", "steel", "black_steel",
            "blue_steel", "red_steel"}) {
            METAL_CANS.put(metal, ITEMS.register("metal_can/" + metal,
                () -> new MetalCanItem(new Item.Properties().stacksTo(1))));
        }
    }
'''
if old not in t:
    raise SystemExit("metal can block missing")
t = t.replace(old, new)
p.write_text(t, encoding="utf-8")
print("metal cans registry updated")
