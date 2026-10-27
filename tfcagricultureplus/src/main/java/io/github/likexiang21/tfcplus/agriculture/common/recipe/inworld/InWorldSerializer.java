package io.github.likexiang21.tfcplus.agriculture.common.recipe.inworld;

import com.mojang.serialization.MapCodec;
import net.minecraft.network.RegistryFriendlyByteBuf;
import net.minecraft.network.codec.StreamCodec;
import net.minecraft.world.item.crafting.RecipeSerializer;

public final class InWorldSerializer implements RecipeSerializer<InWorldRecipe> {
    @Override public MapCodec<InWorldRecipe> codec() { return InWorldRecipe.CODEC; }
    @Override public StreamCodec<RegistryFriendlyByteBuf, InWorldRecipe> streamCodec() { return InWorldRecipe.STREAM_CODEC; }
}
