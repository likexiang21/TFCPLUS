package io.github.likexiang21.tfcplus.agriculture.common.recipe;

import com.eerussianguy.firmalife.common.blockentities.MixingBowlBlockEntity;
import com.eerussianguy.firmalife.common.recipes.MixingBowlRecipe;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import net.dries007.tfc.common.component.food.FoodCapability;
import net.minecraft.core.HolderLookup;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.crafting.Ingredient;
import net.minecraft.world.item.crafting.RecipeSerializer;
import net.minecraft.world.level.Level;
import net.neoforged.neoforge.fluids.FluidStack;
import net.neoforged.neoforge.fluids.crafting.SizedFluidIngredient;

/** Project food recipes using the native bowl, matching rules and JEI recipe type. */
public final class FoodMixingBowlRecipe extends MixingBowlRecipe {
    private final ItemStack output;
    private final SizedFluidIngredient fluid;

    public FoodMixingBowlRecipe(List<Ingredient> ingredients, SizedFluidIngredient fluid, ItemStack output) {
        super(List.copyOf(ingredients), Optional.of(fluid), output.copy(), FluidStack.EMPTY);
        if (ingredients.isEmpty() || ingredients.size() > MixingBowlBlockEntity.SLOTS || output.isEmpty() || output.getCount() > MixingBowlBlockEntity.SLOTS) {
            throw new IllegalArgumentException("Food mixing requires 1-5 ingredients and a nonempty item result");
        }
        this.fluid = fluid;
        this.output = output.copy();
    }

    /** Public accessors used by the extracted serializer. */
    public SizedFluidIngredient fluidIngredient() { return fluid; }
    public ItemStack outputItem() { return output.copy(); }
    @Override
    public boolean matches(MixingBowlBlockEntity.MixingBowlInventory inventory, Level level) {
        for (int slot = 0; slot < MixingBowlBlockEntity.SLOTS; slot++) {
            if (FoodCapability.isRotten(inventory.getStackInSlot(slot))) {
                return false;
            }
        }
        return super.matches(inventory, level);
    }

    @Override
    public ItemStack assemble(MixingBowlBlockEntity.MixingBowlInventory inventory, HolderLookup.Provider registries) {
        final List<ItemStack> inputs = new ArrayList<>();
        for (int slot = 0; slot < MixingBowlBlockEntity.SLOTS; slot++) {
            final ItemStack stack = inventory.getStackInSlot(slot);
            if (FoodCapability.isRotten(stack)) {
                return ItemStack.EMPTY;
            }
            if (!stack.isEmpty()) {
                inputs.add(stack);
            }
        }
        // Start with a real dated stack, then let TFC carry the oldest input history.
        // Native bowl code alone owns consumption, fluid use and container remainders.
        return FoodCapability.updateFoodFromAllPrevious(inputs, FoodCapability.setCreatedNow(output.copy()));
    }

    @Override
    public RecipeSerializer<?> getSerializer() {
        return AgricultureRecipeSerializers.FOOD_MIXING_BOWL.get();
    }

    
}
