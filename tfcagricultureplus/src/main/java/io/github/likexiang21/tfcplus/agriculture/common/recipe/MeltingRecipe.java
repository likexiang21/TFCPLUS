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

/** K3 melting-pot recipe for canonical Firmalife chocolate blends. */
public record MeltingRecipe(Ingredient powder, Ingredient sweetener, ItemStack result, int meltTicks)
    implements Recipe<MeltingRecipe.MeltingInput> {
    public MeltingRecipe {
        if (meltTicks < 1) throw new IllegalArgumentException("melt_ticks must be positive");
        result = result.copy();
    }
    public record MeltingInput(ItemStack powder, ItemStack sweetener) implements RecipeInput {
        @Override public ItemStack getItem(int slot) { return switch (slot) { case 0 -> powder; case 1 -> sweetener; default -> throw new IndexOutOfBoundsException(slot); }; }
        @Override public int size() { return 2; }
    }
    @Override public boolean matches(MeltingInput input, Level level) {
        return !FoodCapability.isRotten(input.powder()) && !FoodCapability.isRotten(input.sweetener())
            && powder.test(input.powder()) && sweetener.test(input.sweetener());
    }
    @Override public ItemStack assemble(MeltingInput input, HolderLookup.Provider registries) {
        final ItemStack foodResult = result.copy();
        return FoodCapability.has(input.powder()) ? FoodCapability.updateFoodFromPrevious(input.powder(), foodResult) : FoodCapability.setCreatedNow(foodResult);
    }
    @Override public boolean canCraftInDimensions(int width, int height) { return false; }
    @Override public ItemStack getResultItem(HolderLookup.Provider registries) { return result.copy(); }
    @Override public RecipeSerializer<?> getSerializer() { return AgricultureRecipeSerializers.MELTING.get(); }
    @Override public RecipeType<?> getType() { return AgricultureRecipeTypes.MELTING.get(); }
    
}
