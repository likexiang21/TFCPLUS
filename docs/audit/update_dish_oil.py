from pathlib import Path

p = Path("mod_rebuild/tfcagricultureplus/src/main/java/io/github/likexiang21/tfcplus/agriculture/common/pan/PanDishData.java")
t = p.read_text(encoding="utf-8")
t = t.replace("public record PanDishData(int servings, int score, FoodData food,\n                          String category, List<ItemStack> ingredients) {",
              "public record PanDishData(int servings, int score, FoodData food,\n                          String category, String oil, List<ItemStack> ingredients) {")
t = t.replace('        tag.putString("category", category);', '        tag.putString("category", category);\n        tag.putString("oil", oil);')
t = t.replace('        return new PanDishData(tag.getInt("servings"), tag.getInt("score"), food,\n            tag.getString("category"), ingredients);',
              '        return new PanDishData(tag.getInt("servings"), tag.getInt("score"), food,\n            tag.getString("category"), tag.getString("oil"), ingredients);')
t = t.replace('        FoodCapability.applyTrait(stack, AgricultureFoodTraits.SEASONED);',
              '        FoodCapability.applyTrait(stack, AgricultureFoodTraits.SEASONED);\n        if (data.oil != null && !data.oil.isBlank()) FoodCapability.applyTrait(stack, oilTrait(data.oil));')
t = t.replace('    public static List<ItemStack> ingredientStacks(List<ItemStack> input) {',
              '    public static net.minecraft.core.Holder<net.dries007.tfc.common.component.food.FoodTrait> oilTrait(String oil) {\n'
              '        return switch (oil) {\n'
              '            case "olive" -> AgricultureFoodTraits.OLIVE_OIL;\n'
              '            case "canola" -> AgricultureFoodTraits.CANOLA_OIL;\n'
              '            case "soybean" -> AgricultureFoodTraits.SOYBEAN_OIL;\n'
              '            case "butter" -> AgricultureFoodTraits.BUTTER_OIL;\n'
              '            default -> AgricultureFoodTraits.COOKING_OIL;\n'
              '        };\n'
              '    }\n\n'
              '    public static List<ItemStack> ingredientStacks(List<ItemStack> input) {')
p.write_text(t, encoding="utf-8")
print("updated PanDishData")
