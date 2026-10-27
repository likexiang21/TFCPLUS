package io.github.likexiang21.tfcplus.agriculture.common.recipe;

import net.dries007.tfc.common.component.food.FoodCapability;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.crafting.Ingredient;
import net.minecraft.world.item.crafting.Recipe;
import net.minecraft.world.item.crafting.RecipeSerializer;
import net.minecraft.world.item.crafting.RecipeType;
import net.minecraft.world.item.crafting.SingleRecipeInput;
import net.minecraft.world.level.Level;

/** K3 dough-forming recipe. The input may be any TFC/common-tag flour. */
public record DoughRecipe(Ingredient ingredient, ItemStack result, int workTicks)
    implements Recipe<SingleRecipeInput> {
    public DoughRecipe {
        if (workTicks < 1) throw new IllegalArgumentException("work_ticks must be positive");
        result = result.copy();
    }
    @Override public boolean matches(SingleRecipeInput input, Level level) {
        return !FoodCapability.isRotten(input.item()) && ingredient.test(input.item());
    }
    @Override public ItemStack assemble(SingleRecipeInput input, net.minecraft.core.HolderLookup.Provider registries) {
        final ItemStack output = result.copy();
        return FoodCapability.has(input.item())
            ? FoodCapability.updateFoodFromPrevious(input.item(), output)
            : FoodCapability.setCreatedNow(output);
    }
    @Override public boolean canCraftInDimensions(int width, int height) { return true; }
    @Override public ItemStack getResultItem(net.minecraft.core.HolderLookup.Provider registries) { return result.copy(); }
    @Override public RecipeSerializer<?> getSerializer() { return AgricultureRecipeSerializers.DOUGH.get(); }
    @Override public RecipeType<?> getType() { return AgricultureRecipeTypes.DOUGH.get(); }

    
}
