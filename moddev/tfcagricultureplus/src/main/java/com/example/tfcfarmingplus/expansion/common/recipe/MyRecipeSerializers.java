package com.example.tfcfarmingplus.expansion.common.recipe;

import com.example.tfcfarmingplus.expansion.TFCAgriculturePlus;
import net.minecraft.core.registries.Registries;
import net.minecraft.world.item.crafting.RecipeSerializer;
import net.neoforged.bus.api.IEventBus;
import net.neoforged.neoforge.registries.DeferredHolder;
import net.neoforged.neoforge.registries.DeferredRegister;

/** Serializers for the three enabled B recipe types. Public registration API; see docs/131. */
public final class MyRecipeSerializers {

    public static final DeferredRegister<RecipeSerializer<?>> SERIALIZERS =
        DeferredRegister.create(Registries.RECIPE_SERIALIZER, TFCAgriculturePlus.MOD_ID);

    
    public static final DeferredHolder<RecipeSerializer<?>, RecipeSerializer<MortarRecipe>> MORTAR =
        SERIALIZERS.register("mortar", MortarRecipe.Serializer::new);

    public static final DeferredHolder<RecipeSerializer<?>, RecipeSerializer<PanRecipe>> PAN =
        SERIALIZERS.register("pan", PanRecipe.Serializer::new);

    public static final DeferredHolder<RecipeSerializer<?>, RecipeSerializer<DoughRecipe>> DOUGH =
        SERIALIZERS.register("dough", DoughRecipe.Serializer::new);

    public static final DeferredHolder<RecipeSerializer<?>, RecipeSerializer<MeltingRecipe>> MELTING =
        SERIALIZERS.register("melting", MeltingRecipe.Serializer::new);

    public static final DeferredHolder<RecipeSerializer<?>, RecipeSerializer<CuttingBoardRecipe>> CUTTING_BOARD =
        SERIALIZERS.register("cutting_board", CuttingBoardRecipe.Serializer::new);

    
    public static final DeferredHolder<RecipeSerializer<?>, RecipeSerializer<com.example.tfcfarmingplus.expansion.common.recipe.inworld.InWorldRecipe>> IN_WORLD =
        SERIALIZERS.register("in_world", com.example.tfcfarmingplus.expansion.common.recipe.inworld.InWorldRecipe.Serializer::new);

    public static final DeferredHolder<RecipeSerializer<?>, RecipeSerializer<FoodMixingBowlRecipe>> FOOD_MIXING_BOWL =
        SERIALIZERS.register("food_mixing_bowl", FoodMixingBowlRecipe.Serializer::new);

    public static void register(IEventBus bus) {
        SERIALIZERS.register(bus);
    }

    private MyRecipeSerializers() {}
}
