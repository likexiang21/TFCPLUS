package io.github.likexiang21.tfcplus.agriculture.common.pan;

import io.github.likexiang21.tfcplus.agriculture.common.registry.AgricultureDataComponents;
import io.github.likexiang21.tfcplus.agriculture.common.registry.AgricultureFoodTraits;
import java.util.ArrayList;
import java.util.List;
import net.dries007.tfc.common.component.TFCComponents;
import net.dries007.tfc.common.component.food.FoodCapability;
import net.dries007.tfc.common.component.food.FoodComponent;
import net.dries007.tfc.common.component.food.FoodData;
import net.dries007.tfc.common.component.food.FoodDefinition;
import net.minecraft.core.registries.BuiltInRegistries;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.nbt.ListTag;
import net.minecraft.nbt.NbtOps;
import net.minecraft.nbt.Tag;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.crafting.Ingredient;

/**
 * A dynamic plated dish. {@link #food()} is the TFC nutrition for one serving.
 * The TFC FoodComponent on the plate stack owns the creation date and therefore
 * the shelf life; the compound component owns composition and serving count.
 */
public record PanDishData(int servings, int score, FoodData food,
                          String category, List<ItemStack> ingredients) {

    public PanDishData {
        servings = Math.max(1, servings);
        score = Math.clamp(score, 0, 100);
        ingredients = List.copyOf(ingredients);
    }

    public boolean isPerfect() {
        return score >= 90;
    }

    public String qualityKey() {
        if (score < 45) return "poor";
        if (score < 70) return "plain";
        if (score < 90) return "good";
        return "perfect";
    }

    public CompoundTag toTag() {
        final CompoundTag tag = new CompoundTag();
        tag.putInt("servings", servings);
        tag.putInt("score", score);
        tag.putString("category", category);
        tag.put("food", FoodData.CODEC.encodeStart(NbtOps.INSTANCE, food).getOrThrow());
        final ListTag list = new ListTag();
        for (final ItemStack stack : ingredients) {
            list.add(ItemStack.CODEC.encodeStart(NbtOps.INSTANCE, stack).getOrThrow());
        }
        tag.put("ingredients", list);
        return tag;
    }

    public static PanDishData fromTag(CompoundTag tag) {
        final FoodData food = FoodData.CODEC.parse(NbtOps.INSTANCE, tag.get("food")).getOrThrow();
        final List<ItemStack> ingredients = new ArrayList<>();
        final ListTag list = tag.getList("ingredients", Tag.TAG_COMPOUND);
        for (int i = 0; i < list.size(); i++) {
            ItemStack.CODEC.parse(NbtOps.INSTANCE, list.getCompound(i)).result().ifPresent(ingredients::add);
        }
        return new PanDishData(tag.getInt("servings"), tag.getInt("score"), food,
            tag.getString("category"), ingredients);
    }

    public static PanDishData read(ItemStack stack) {
        final CompoundTag tag = stack.get(AgricultureDataComponents.DISH.get());
        return tag == null ? null : fromTag(tag);
    }

    /** Writes both our composition component and TFC's shelf-life component. */
    public static void write(ItemStack stack, PanDishData data) {
        stack.set(AgricultureDataComponents.DISH.get(), data.toTag());
        final FoodDefinition def = new FoodDefinition(Ingredient.of(stack.getItem()), data.food, true);
        stack.set(TFCComponents.FOOD.holder().get(), new FoodComponent(def));
        FoodCapability.applyTrait(stack, AgricultureFoodTraits.SEASONED);
    }

    /** Removes dish and food components, leaving the empty plate/bowl. */
    public static void clear(ItemStack stack) {
        stack.remove(AgricultureDataComponents.DISH.get());
        stack.remove(TFCComponents.FOOD.holder().get());
    }

    public static List<ItemStack> ingredientStacks(List<ItemStack> input) {
        final List<ItemStack> out = new ArrayList<>(input.size());
        for (final ItemStack stack : input) out.add(stack.copyWithCount(1));
        return out;
    }

    public static String ingredientName(ItemStack stack) {
        return BuiltInRegistries.ITEM.getKey(stack.getItem()).toString();
    }

    public static ResourceLocation id(String path) {
        return ResourceLocation.fromNamespaceAndPath("tfcagricultureplus", path);
    }
}
