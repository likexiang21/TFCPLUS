package io.github.likexiang21.tfcplus.agriculture.common.recipe;

import com.mojang.serialization.MapCodec;
import com.mojang.serialization.codecs.RecordCodecBuilder;
import net.minecraft.network.RegistryFriendlyByteBuf;
import net.minecraft.network.codec.StreamCodec;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.crafting.Ingredient;
import net.minecraft.world.item.crafting.RecipeSerializer;

public final class MeltingSerializer implements RecipeSerializer<MeltingRecipe> {
    private static final MapCodec<MeltingRecipe> CODEC = RecordCodecBuilder.mapCodec(i -> i.group(
        Ingredient.CODEC.fieldOf("powder").forGetter(MeltingRecipe::powder),
        Ingredient.CODEC.fieldOf("sweetener").forGetter(MeltingRecipe::sweetener),
        ItemStack.STRICT_CODEC.fieldOf("result").forGetter(MeltingRecipe::result),
        com.mojang.serialization.Codec.INT.optionalFieldOf("melt_ticks", 60).forGetter(MeltingRecipe::meltTicks)
    ).apply(i, MeltingRecipe::new));
    private static final StreamCodec<RegistryFriendlyByteBuf, MeltingRecipe> STREAM_CODEC = StreamCodec.composite(
        Ingredient.CONTENTS_STREAM_CODEC, MeltingRecipe::powder,
        Ingredient.CONTENTS_STREAM_CODEC, MeltingRecipe::sweetener,
        ItemStack.STREAM_CODEC, MeltingRecipe::result,
        net.minecraft.network.codec.ByteBufCodecs.VAR_INT, MeltingRecipe::meltTicks,
        MeltingRecipe::new);
    @Override public MapCodec<MeltingRecipe> codec() { return CODEC; }
    @Override public StreamCodec<RegistryFriendlyByteBuf, MeltingRecipe> streamCodec() { return STREAM_CODEC; }
}
