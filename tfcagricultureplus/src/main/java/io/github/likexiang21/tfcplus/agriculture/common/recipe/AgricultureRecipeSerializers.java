package io.github.likexiang21.tfcplus.agriculture.common.recipe;

import io.github.likexiang21.tfcplus.agriculture.TFCAgriculturePlus;
import io.github.likexiang21.tfcplus.agriculture.common.recipe.inworld.InWorldRecipe;
import io.github.likexiang21.tfcplus.agriculture.common.recipe.inworld.InWorldSerializer;
import net.minecraft.core.registries.Registries;
import net.minecraft.world.item.crafting.RecipeSerializer;
import net.neoforged.bus.api.IEventBus;
import net.neoforged.neoforge.registries.DeferredHolder;
import net.neoforged.neoforge.registries.DeferredRegister;

/** Serializers for the three enabled B recipe types. Public registration API; see docs/131. */
public final class AgricultureRecipeSerializers {

    public static final DeferredRegister<RecipeSerializer<?>> SERIALIZERS =
        DeferredRegister.create(Registries.RECIPE_SERIALIZER, TFCAgriculturePlus.MOD_ID);

    
    public static final DeferredHolder<RecipeSerializer<?>, RecipeSerializer<MortarRecipe>> MORTAR =
        SERIALIZERS.register("mortar", MortarSerializer::new);

    public static final DeferredHolder<RecipeSerializer<?>, RecipeSerializer<PanRecipe>> PAN =
        SERIALIZERS.register("pan", PanSerializer::new);

    public static final DeferredHolder<RecipeSerializer<?>, RecipeSerializer<CuttingBoardRecipe>> CUTTING_BOARD =
        SERIALIZERS.register("cutting_board", CuttingBoardSerializer::new);

    
    public static final DeferredHolder<RecipeSerializer<?>, RecipeSerializer<io.github.likexiang21.tfcplus.agriculture.common.recipe.inworld.InWorldRecipe>> IN_WORLD =
        SERIALIZERS.register("in_world", InWorldSerializer::new);

    public static final DeferredHolder<RecipeSerializer<?>, RecipeSerializer<FoodMixingBowlRecipe>> FOOD_MIXING_BOWL =
        SERIALIZERS.register("food_mixing_bowl", FoodMixingBowlSerializer::new);

    public static void register(IEventBus bus) {
        SERIALIZERS.register(bus);
    }

    private AgricultureRecipeSerializers() {}
}
