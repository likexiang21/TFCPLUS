package io.github.likexiang21.tfcplus.agriculture.common.recipe;

import net.dries007.tfc.common.component.food.FoodCapability;
import net.minecraft.core.HolderLookup;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.crafting.Ingredient;
import net.minecraft.world.item.crafting.Recipe;
import net.minecraft.world.item.crafting.RecipeInput;
import net.minecraft.world.item.crafting.RecipeSerializer;
import net.minecraft.world.item.crafting.RecipeType;
import net.minecraft.world.level.Level;

/**
 * K2 two-input pan recipe. The food and spice stay separate in the block
 * entity until the state machine finishes; recipe data owns the output.
 */
public record PanRecipe(Ingredient food, Ingredient spice, ItemStack result,
                        int cookTicks, int requiredStirs)
    implements Recipe<PanRecipe.PanInput> {

    public static final int DEFAULT_COOK_TICKS = 100;
    public static final int DEFAULT_REQUIRED_STIRS = 3;

    public PanRecipe {
        if (cookTicks < 1) throw new IllegalArgumentException("cook_ticks must be at least 1");
        if (requiredStirs < 1) throw new IllegalArgumentException("required_stirs must be at least 1");
        result = result.copy();
    }

    public record PanInput(ItemStack food, ItemStack spice) implements RecipeInput {
        @Override public ItemStack getItem(int slot) {
            return switch (slot) {
                case 0 -> food;
                case 1 -> spice;
                default -> throw new IndexOutOfBoundsException(slot);
            };
        }

        @Override public int size() { return 2; }
    }

    @Override
    public boolean matches(PanInput input, Level level) {
        return !FoodCapability.isRotten(input.food())
            && !FoodCapability.isRotten(input.spice())
            && food.test(input.food()) && spice.test(input.spice());
    }

    @Override
    public ItemStack assemble(PanInput input, HolderLookup.Provider registries) {
        final ItemStack output = result.copy();
        return FoodCapability.has(input.food())
            ? FoodCapability.updateFoodFromPrevious(input.food(), output)
            : FoodCapability.setCreatedNow(output);
    }

    @Override public boolean canCraftInDimensions(int width, int height) { return false; }

    @Override public ItemStack getResultItem(HolderLookup.Provider registries) { return result.copy(); }
    @Override public RecipeSerializer<?> getSerializer() { return AgricultureRecipeSerializers.PAN.get(); }
    @Override public RecipeType<?> getType() { return AgricultureRecipeTypes.PAN.get(); }

    
}
