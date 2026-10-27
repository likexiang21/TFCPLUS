package io.github.likexiang21.tfcplus.agriculture.common.recipe;

import java.util.List;
import net.dries007.tfc.common.component.food.FoodCapability;
import net.dries007.tfc.common.recipes.outputs.ItemStackProvider;
import net.minecraft.core.HolderLookup;
import net.minecraft.core.NonNullList;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.crafting.Ingredient;
import net.minecraft.world.item.crafting.Recipe;
import net.minecraft.world.item.crafting.RecipeInput;
import net.minecraft.world.item.crafting.RecipeSerializer;
import net.minecraft.world.item.crafting.RecipeType;
import net.minecraft.world.level.Level;

/** One board ingredient and a retained tool, with TFC output modifiers. */
public record CuttingBoardRecipe(Ingredient ingredient, Ingredient tool,
                                 ItemStackProvider result, List<ItemStackProvider> byproducts)
    implements Recipe<CuttingBoardRecipe.CuttingBoardInput> {

    public record CuttingBoardInput(ItemStack ingredient, ItemStack tool) implements RecipeInput {
        @Override
        public ItemStack getItem(int slot) {
            return switch (slot) {
                case 0 -> ingredient;
                case 1 -> tool;
                default -> throw new IndexOutOfBoundsException(slot);
            };
        }

        @Override
        public int size() { return 2; }
    }

    @Override
    public boolean matches(CuttingBoardInput input, Level level) {
        return !FoodCapability.isRotten(input.ingredient())
            && ingredient.test(input.ingredient()) && tool.test(input.tool());
    }

    @Override
    public ItemStack assemble(CuttingBoardInput input, HolderLookup.Provider registries) {
        final ItemStack output = result.getSingleStack(input.ingredient());
        return FoodCapability.has(input.ingredient()) ? output : FoodCapability.setCreatedNow(output);
    }

    @Override
    public NonNullList<Ingredient> getIngredients() {
        final var ingredients = NonNullList.<Ingredient>create();
        ingredients.add(ingredient);
        ingredients.add(tool);
        return ingredients;
    }

    @Override
    public boolean canCraftInDimensions(int width, int height) { return false; }

    @Override
    public boolean isSpecial() { return true; }

    @Override
    public ItemStack getResultItem(HolderLookup.Provider registries) { return result.getEmptyStack(); }

    @Override
    public RecipeSerializer<?> getSerializer() { return AgricultureRecipeSerializers.CUTTING_BOARD.get(); }

    @Override
    public RecipeType<?> getType() { return AgricultureRecipeTypes.CUTTING_BOARD.get(); }

    
}
