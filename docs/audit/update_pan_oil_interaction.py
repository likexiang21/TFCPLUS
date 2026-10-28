from pathlib import Path
p = Path("mod_rebuild/tfcagricultureplus/src/main/java/io/github/likexiang21/tfcplus/agriculture/common/interaction/PanInteractions.java")
t = p.read_text(encoding="utf-8")
old = """        if (held.getItem() instanceof SpatulaItem) {
            if (pan.stir((SpatulaItem) held.getItem(), held, player)) {
                level.playSound(null, pos, SoundEvents.ITEM_PICKUP, SoundSource.BLOCKS, 0.4F, 1.4F);
            } else {
                message(player, "no_heat");
            }
            return;
        }
"""
new = """        if (held.getItem() instanceof SpatulaItem) {
            if (scoopOil(player, pan)) {
                pan.refreshOilType();
                level.playSound(null, pos, SoundEvents.BREWING_STAND_BREW, SoundSource.BLOCKS, 0.5F, 1.1F);
                return;
            }
            if (pan.addSolidOil(held)) {
                if (!player.isCreative()) held.shrink(1);
                level.playSound(null, pos, SoundEvents.WOOD_PLACE, SoundSource.BLOCKS, 0.5F, 1.1F);
                return;
            }
            if (pan.stir((SpatulaItem) held.getItem(), held, player)) {
                level.playSound(null, pos, SoundEvents.ITEM_PICKUP, SoundSource.BLOCKS, 0.4F, 1.4F);
            } else {
                message(player, "no_heat");
            }
            return;
        }
        if (pan.addSolidOil(held)) {
            if (!player.isCreative()) held.shrink(1);
            level.playSound(null, pos, SoundEvents.WOOD_PLACE, SoundSource.BLOCKS, 0.5F, 1.1F);
            return;
        }
"""
if old not in t: raise SystemExit("spatula block missing")
t = t.replace(old, new)
t = t.replace("""            if (FluidUtil.interactWithFluidHandler(player, hand, pan.oilTank())) {
                level.playSound(null, pos, SoundEvents.BREWING_STAND_BREW, SoundSource.BLOCKS, 0.5F, 1.1F);
                return;
            }""", """            if (FluidUtil.interactWithFluidHandler(player, hand, pan.oilTank())) {
                pan.refreshOilType();
                level.playSound(null, pos, SoundEvents.BREWING_STAND_BREW, SoundSource.BLOCKS, 0.5F, 1.1F);
                return;
            }""")
t = t.replace("    private static boolean isOil(FluidStack stack) {",
              "    /** Scoops exactly one 5 mB oil dose from the off-hand container into the pan. */\n"
              "    private static boolean scoopOil(Player player, CookingPanBlockEntity pan) {\n"
              "        if (pan.hasOil()) return false;\n"
              "        final ItemStack offhand = player.getOffhandItem();\n"
              "        final var handler = FluidUtil.getFluidHandler(offhand).orElse(null);\n"
              "        if (handler == null) return false;\n"
              "        final FluidStack contained = handler.getFluidInTank(0);\n"
              "        if (contained.isEmpty() || !isOil(contained)) return false;\n"
              "        final FluidStack moved = FluidUtil.tryFluidTransfer(pan.oilTank(), handler, CookingPanBlockEntity.OIL_REQUIRED, false);\n"
              "        return !moved.isEmpty();\n"
              "    }\n\n"
              "    private static boolean isOil(FluidStack stack) {")
p.write_text(t, encoding="utf-8")
print("updated PanInteractions")
