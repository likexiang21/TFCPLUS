from pathlib import Path

p = Path("mod_rebuild/tfcagricultureplus/src/main/java/io/github/likexiang21/tfcplus/agriculture/common/blockentity/CookingPanBlockEntity.java")
t = p.read_text(encoding="utf-8")
t = t.replace("import net.minecraft.core.BlockPos;", "import net.minecraft.core.BlockPos;\nimport net.minecraft.core.registries.BuiltInRegistries;")
t = t.replace("public static final int OIL_REQUIRED = 10;", "public static final int OIL_REQUIRED = 5;")
t = t.replace("private final FluidTank oilTank = new FluidTank(100, stack -> stack.is(OIL) || stack.is(FIRMALIFE_OIL));",
              "private final FluidTank oilTank = new FluidTank(5, stack -> stack.is(OIL) || stack.is(FIRMALIFE_OIL));")
t = t.replace("    private final List<PanCookingEntry> entries = new ArrayList<>();",
              "    private final List<PanCookingEntry> entries = new ArrayList<>();\n    private String oilType;\n    private boolean solidOil;")
t = t.replace("    public FluidTank oilTank() { return oilTank; }\n    public int ingredientCount() { return entries.size(); }\n    public boolean hasOil() { return oilTank.getFluidAmount() >= OIL_REQUIRED; }",
              "    public FluidTank oilTank() { return oilTank; }\n    public int ingredientCount() { return entries.size(); }\n    public boolean hasOil() { return solidOil || oilTank.getFluidAmount() >= OIL_REQUIRED; }\n"
              "    public String oilType() { return oilType; }\n"
              "    public void refreshOilType() {\n"
              "        if (oilTank.getFluid().isEmpty()) { oilType = null; return; }\n"
              "        final var key = BuiltInRegistries.FLUID.getKey(oilTank.getFluid().getFluid());\n"
              "        final String path = key.getPath();\n"
              "        if (path.contains(\"olive\")) oilType = \"olive\";\n"
              "        else if (path.contains(\"canola\")) oilType = \"canola\";\n"
              "        else if (path.contains(\"soybean\")) oilType = \"soybean\";\n"
              "        else oilType = \"cooking\";\n"
              "    }\n"
              "    public boolean addSolidOil(ItemStack stack) {\n"
              "        if (level == null || level.isClientSide() || hasOil() || stack.isEmpty()) return false;\n"
              "        final var key = BuiltInRegistries.ITEM.getKey(stack.getItem());\n"
              "        if (!key.getNamespace().equals(\"firmalife\") || !key.getPath().equals(\"food/butter\")) return false;\n"
              "        solidOil = true; oilType = \"butter\"; sync(); return true;\n"
              "    }")
t = t.replace("final PanDishData dish = PanDishBuilder.build(entries, level.getGameTime(), oilTank.getFluidAmount());",
              "final PanDishData dish = PanDishBuilder.build(entries, level.getGameTime(), oilType);")
t = t.replace("        oilTank.drain(OIL_REQUIRED, IFluidHandler.FluidAction.EXECUTE);\n        entries.clear();",
              "        oilTank.drain(OIL_REQUIRED, IFluidHandler.FluidAction.EXECUTE);\n        solidOil = false;\n        oilType = null;\n        entries.clear();")
t = t.replace("        oilTank.setFluid(FluidStack.EMPTY);\n    }",
              "        oilTank.setFluid(FluidStack.EMPTY);\n        solidOil = false;\n        oilType = null;\n    }")
t = t.replace('        tag.put("oil", oilTank.writeToNBT(registries, new CompoundTag()));',
              '        tag.put("oil", oilTank.writeToNBT(registries, new CompoundTag()));\n        tag.putBoolean("solid_oil", solidOil);\n        if (oilType != null) tag.putString("oil_type", oilType);')
t = t.replace('        if (tag.contains("oil")) oilTank.readFromNBT(registries, tag.getCompound("oil"));',
              '        if (tag.contains("oil")) oilTank.readFromNBT(registries, tag.getCompound("oil"));\n        solidOil = tag.getBoolean("solid_oil");\n        oilType = tag.contains("oil_type") ? tag.getString("oil_type") : null;')
p.write_text(t, encoding="utf-8")
print("updated pan oil")
