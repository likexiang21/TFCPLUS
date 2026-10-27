package io.github.likexiang21.tfcplus.agriculture.common.recipe;

import com.mojang.serialization.MapCodec;
import net.minecraft.network.RegistryFriendlyByteBuf;
import net.minecraft.network.codec.StreamCodec;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.crafting.Ingredient;
import net.minecraft.world.item.crafting.RecipeSerializer;

public final class MortarSerializer implements RecipeSerializer<MortarRecipe> {

    public static final MapCodec<MortarRecipe> CODEC = com.mojang.serialization.codecs.RecordCodecBuilder.mapCodec(inst -> inst.group(
        Ingredient.CODEC.fieldOf("ingredient").forGetter(MortarRecipe::ingredient),
        ItemStack.STRICT_CODEC.fieldOf("result").forGetter(MortarRecipe::result),
        com.mojang.serialization.Codec.INT.optionalFieldOf("grind_time", MortarRecipe.DEFAULT_GRIND_TIME).forGetter(MortarRecipe::grindTime)
    ).apply(inst, MortarRecipe::new));

    public static final StreamCodec<RegistryFriendlyByteBuf, MortarRecipe> STREAM_CODEC =
        StreamCodec.composite(
            Ingredient.CONTENTS_STREAM_CODEC, MortarRecipe::ingredient,
            ItemStack.STREAM_CODEC, MortarRecipe::result,
            net.minecraft.network.codec.ByteBufCodecs.VAR_INT, MortarRecipe::grindTime,
            MortarRecipe::new);

    @Override
    public MapCodec<MortarRecipe> codec() {
        return CODEC;
    }

    @Override
    public StreamCodec<RegistryFriendlyByteBuf, MortarRecipe> streamCodec() {
        return STREAM_CODEC;
    }
}
