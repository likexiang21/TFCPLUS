from pathlib import Path

p = Path("mod_rebuild/tfcagricultureplus/src/main/java/io/github/likexiang21/tfcplus/agriculture/common/timber/LumberPileBlockEntity.java")
t = p.read_text(encoding="utf-8")
t = t.replace("final int amount = Math.min(available, all ? held.getCount() : held.getCount());",
              "final int amount = Math.min(1, available);")
t = t.replace("final int count = Math.max(1, Math.min(16, (lumberCount() + 3) / 4));",
              "final int count = Math.max(1, Math.min(64, lumberCount()));")
t = t.replace("level.setBlock(worldPosition, state.setValue(LumberPileBlock.COUNT, count), Block.UPDATE_CLIENTS);",
              "final String wood = lumberCount() == 0 ? state.getValue(LumberPileBlock.WOOD) : LumberPileBlock.woodOf(inventory.getStackInSlot(0));\n"
              "            level.setBlock(worldPosition, state.setValue(LumberPileBlock.COUNT, count).setValue(LumberPileBlock.WOOD, wood), Block.UPDATE_CLIENTS);")
p.write_text(t, encoding="utf-8")
print("updated LumberPileBlockEntity")
