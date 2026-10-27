package io.github.likexiang21.tfcplus.agriculture.common.recipe;

import com.eerussianguy.firmalife.common.blockentities.MixingBowlBlockEntity;
import com.mojang.serialization.MapCodec;
import com.mojang.serialization.codecs.RecordCodecBuilder;
import net.minecraft.network.RegistryFriendlyByteBuf;
import net.minecraft.network.codec.ByteBufCodecs;
import net.minecraft.network.codec.StreamCodec;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.crafting.Ingredient;
import net.minecraft.world.item.crafting.RecipeSerializer;
import net.neoforged.neoforge.fluids.crafting.SizedFluidIngredient;

public final class FoodMixingBowlSerializer implements RecipeSerializer<FoodMixingBowlRecipe> {
    public static final MapCodec<FoodMixingBowlRecipe> CODEC = RecordCodecBuilder.mapCodec(fields -> fields.group(
        Ingredient.CODEC.listOf(1, MixingBowlBlockEntity.SLOTS).fieldOf("item_ingredients")
            .forGetter(FoodMixingBowlRecipe::getItemIngredients),
        SizedFluidIngredient.FLAT_CODEC.fieldOf("fluid_ingredients").forGetter(recipe -> recipe.fluidIngredient()),
        ItemStack.STRICT_CODEC.fieldOf("result_item").forGetter(recipe -> recipe.outputItem())
    ).apply(fields, FoodMixingBowlRecipe::new));

    public static final StreamCodec<RegistryFriendlyByteBuf, FoodMixingBowlRecipe> STREAM_CODEC = StreamCodec.composite(
        Ingredient.CONTENTS_STREAM_CODEC.apply(ByteBufCodecs.list(MixingBowlBlockEntity.SLOTS)), FoodMixingBowlRecipe::getItemIngredients,
        SizedFluidIngredient.STREAM_CODEC, recipe -> recipe.fluidIngredient(),
        ItemStack.STREAM_CODEC, recipe -> recipe.outputItem(),
        FoodMixingBowlRecipe::new);

    @Override
    public MapCodec<FoodMixingBowlRecipe> codec() {
        return CODEC;
    }

    @Override
    public StreamCodec<RegistryFriendlyByteBuf, FoodMixingBowlRecipe> streamCodec() {
        return STREAM_CODEC;
    }
}
