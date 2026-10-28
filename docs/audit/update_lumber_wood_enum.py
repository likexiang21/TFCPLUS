from pathlib import Path

p = Path("mod_rebuild/tfcagricultureplus/src/main/java/io/github/likexiang21/tfcplus/agriculture/common/timber/LumberPileBlock.java")
t = p.read_text(encoding="utf-8")
t = t.replace("import io.github.likexiang21.tfcplus.agriculture.common.registry.AgricultureBlocks;\n", "")
t = t.replace("import java.util.LinkedHashSet;\nimport java.util.Set;\nimport java.util.stream.Stream;\n", "")
t = t.replace("import net.minecraft.world.level.block.state.properties.StringProperty;\n", "")
t = t.replace("    public static final Set<String> WOODS = new LinkedHashSet<>();\n"
              "    static {\n"
              "        Stream.concat(AgricultureBlocks.TFC_WOODS.stream(), AgricultureBlocks.AFC_WOODS.stream()).forEach(WOODS::add);\n"
              "        WOODS.add(\"oak\");\n"
              "    }\n"
              "    public static final StringProperty WOOD = StringProperty.create(\"wood\", WOODS);",
              "    public static final EnumProperty<LumberWood> WOOD = EnumProperty.create(\"wood\", LumberWood.class);")
t = t.replace(".setValue(WOOD, \"oak\"));", ".setValue(WOOD, LumberWood.OAK));")
t = t.replace(".setValue(WOOD, \"oak\");", ".setValue(WOOD, LumberWood.OAK);")
t = t.replace("    public static String woodOf(ItemStack stack) {",
              "    public static LumberWood woodOf(ItemStack stack) {")
t = t.replace("        return WOODS.contains(wood) ? wood : \"oak\";", "        return LumberWood.byId(wood);")
p.write_text(t, encoding="utf-8")

p = Path("mod_rebuild/tfcagricultureplus/src/main/java/io/github/likexiang21/tfcplus/agriculture/common/timber/LumberPileBlockEntity.java")
t = p.read_text(encoding="utf-8")
t = t.replace("final String wood = lumberCount() == 0 ? state.getValue(LumberPileBlock.WOOD) : LumberPileBlock.woodOf(inventory.getStackInSlot(0));",
              "final LumberWood wood = lumberCount() == 0 ? state.getValue(LumberPileBlock.WOOD) : LumberPileBlock.woodOf(inventory.getStackInSlot(0));")
p.write_text(t, encoding="utf-8")
print("updated lumber wood property")
