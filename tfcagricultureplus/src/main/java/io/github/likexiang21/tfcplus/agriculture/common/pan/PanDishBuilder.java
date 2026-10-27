package io.github.likexiang21.tfcplus.agriculture.common.pan;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import net.dries007.tfc.common.component.food.FoodData;
import net.dries007.tfc.common.component.food.Nutrient;
import net.minecraft.util.Mth;
import net.minecraft.world.item.ItemStack;

/** Builds a dynamic dish from the pan contents. */
public final class PanDishBuilder {
    private static final String[] CATEGORY_ORDER = {"meat", "fish", "vegetable", "grain", "fruit", "dairy", "mixed"};

    public static PanDishData build(List<PanCookingEntry> entries, long now, int oilAmount) {
        if (entries.isEmpty()) return null;
        final List<ItemStack> ingredients = new ArrayList<>();
        final Set<String> categories = new LinkedHashSet<>();
        final Map<String, Integer> categoryCounts = new LinkedHashMap<>();
        int totalHunger = 0;
        float totalWater = 0;
        float totalSaturation = 0;
        int totalIntoxication = 0;
        final float[] nutrients = new float[Nutrient.VALUES.length];
        int penalty = 0;
        for (final PanCookingEntry entry : entries) {
            ingredients.add(entry.stack());
            final String category = entry.category();
            categories.add(category);
            categoryCounts.merge(category, 1, Integer::sum);
            final FoodData food = entry.food();
            totalHunger += food.hunger();
            totalWater += food.water();
            totalSaturation += food.saturation();
            totalIntoxication += food.intoxication();
            final float[] values = food.nutrients();
            for (int i = 0; i < Math.min(values.length, nutrients.length); i++) nutrients[i] += values[i];
            penalty += entry.penalty(now);
        }
        int score = Mth.clamp(100 - penalty, 0, 100);
        // Variety is a real scoring axis: a mixed dish gets a small bonus, capped at 100.
        score = Mth.clamp(score + Math.max(0, categories.size() - 1) * 4, 0, 100);
        if (oilAmount <= 0) score = Math.max(0, score - 40);
        final int servings = Math.max(1, entries.size());
        final float quality = 0.45f + score / 180.0f; // 0.45 .. 1.0, never a free full-strength dish
        final int hunger = Math.max(1, Math.round(totalHunger * quality / servings));
        final float water = totalWater * quality / servings;
        final float saturation = totalSaturation * quality / servings;
        final int intoxication = Math.round(totalIntoxication * quality / servings);
        for (int i = 0; i < nutrients.length; i++) nutrients[i] = nutrients[i] * quality / servings;
        final FoodData perServing = new FoodData(hunger, water, saturation, intoxication, nutrients, 0.75f);
        final String category = dominant(categoryCounts);
        return new PanDishData(servings, score, perServing, category, PanDishData.ingredientStacks(ingredients));
    }

    private static String dominant(Map<String, Integer> counts) {
        String best = "mixed";
        int bestCount = 0;
        for (final String key : CATEGORY_ORDER) {
            final int count = counts.getOrDefault(key, 0);
            if (count > bestCount) {
                best = key;
                bestCount = count;
            }
        }
        return bestCount == 0 ? "mixed" : best;
    }

    public static String categoryTranslationKey(PanDishData dish) {
        return "item.tfcagricultureplus.pan_dish." + dish.category();
    }

    public static String qualityTranslationKey(PanDishData dish) {
        return "item.tfcagricultureplus.pan_quality." + dish.qualityKey();
    }

    private PanDishBuilder() {}
}
