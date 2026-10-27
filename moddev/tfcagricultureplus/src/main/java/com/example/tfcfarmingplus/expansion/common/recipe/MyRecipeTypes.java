package com.example.tfcfarmingplus.expansion.common.recipe;

import com.example.tfcfarmingplus.expansion.TFCAgriculturePlus;
import net.minecraft.core.registries.Registries;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.world.item.crafting.Recipe;
import net.minecraft.world.item.crafting.RecipeType;
import net.neoforged.bus.api.IEventBus;
import net.neoforged.neoforge.registries.DeferredHolder;
import net.neoforged.neoforge.registries.DeferredRegister;

/** B recipe type IDs registered through public NeoForge and Minecraft APIs. See docs/131. */
public final class MyRecipeTypes {

    public static final DeferredRegister<RecipeType<?>> RECIPE_TYPES =
        DeferredRegister.create(Registries.RECIPE_TYPE, TFCAgriculturePlus.MOD_ID);

    
    public static final DeferredHolder<RecipeType<?>, RecipeType<MortarRecipe>> MORTAR =
        register("mortar");

    public static final DeferredHolder<RecipeType<?>, RecipeType<PanRecipe>> PAN =
        register("pan");

    public static final DeferredHolder<RecipeType<?>, RecipeType<DoughRecipe>> DOUGH =
        register("dough");

    public static final DeferredHolder<RecipeType<?>, RecipeType<MeltingRecipe>> MELTING =
        register("melting");

    public static final DeferredHolder<RecipeType<?>, RecipeType<CuttingBoardRecipe>> CUTTING_BOARD =
        register("cutting_board");

    
    public static final DeferredHolder<RecipeType<?>, RecipeType<com.example.tfcfarmingplus.expansion.common.recipe.inworld.InWorldRecipe>> IN_WORLD =
        register("in_world");

    private static <T extends Recipe<?>> DeferredHolder<RecipeType<?>, RecipeType<T>> register(String name) {
        return RECIPE_TYPES.register(name, () -> RecipeType.simple(
            ResourceLocation.fromNamespaceAndPath(TFCAgriculturePlus.MOD_ID, name)));
    }

    public static void register(IEventBus bus) {
        RECIPE_TYPES.register(bus);
    }

    private MyRecipeTypes() {}
}
