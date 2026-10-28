from pathlib import Path

p = Path("mod_rebuild/tfcagricultureplus/src/main/java/io/github/likexiang21/tfcplus/agriculture/common/pan/DishEating.java")
t = p.read_text(encoding="utf-8")
t = t.replace("dish.category(), dish.ingredients());", "dish.category(), dish.oil(), dish.ingredients());")
p.write_text(t, encoding="utf-8")

p = Path("mod_rebuild/tfcagricultureplus/src/main/java/io/github/likexiang21/tfcplus/agriculture/common/pan/PanDishBuilder.java")
t = p.read_text(encoding="utf-8")
t = t.replace("public static PanDishData build(List<PanCookingEntry> entries, long now, int oilAmount) {",
              "public static PanDishData build(List<PanCookingEntry> entries, long now, String oil) {")
t = t.replace("if (oilAmount <= 0) score = Math.max(0, score - 40);",
              "if (oil == null || oil.isBlank()) score = Math.max(0, score - 40);")
t = t.replace("return new PanDishData(servings, score, perServing, category, PanDishData.ingredientStacks(ingredients));",
              "return new PanDishData(servings, score, perServing, category, oil, PanDishData.ingredientStacks(ingredients));")
p.write_text(t, encoding="utf-8")
print("updated constructors")
