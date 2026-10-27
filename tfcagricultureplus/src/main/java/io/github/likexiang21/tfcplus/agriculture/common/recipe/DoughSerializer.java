package io.github.likexiang21.tfcplus.agriculture.common.recipe;

import com.mojang.serialization.MapCodec;
import net.minecraft.network.RegistryFriendlyByteBuf;
import net.minecraft.network.codec.ByteBufCodecs;
import net.minecraft.network.codec.StreamCodec;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.crafting.Ingredient;
import net.minecraft.world.item.crafting.RecipeSerializer;

public final class DoughSerializer implements RecipeSerializer<DoughRecipe> {
    public static final MapCodec<DoughRecipe> CODEC = com.mojang.serialization.codecs.RecordCodecBuilder.mapCodec(inst -> inst.group(
        Ingredient.CODEC.fieldOf("ingredient").forGetter(DoughRecipe::ingredient),
        ItemStack.STRICT_CODEC.fieldOf("result").forGetter(DoughRecipe::result),
        com.mojang.serialization.Codec.INT.optionalFieldOf("work_ticks", 20).forGetter(DoughRecipe::workTicks)
    ).apply(inst, DoughRecipe::new));
    public static final StreamCodec<RegistryFriendlyByteBuf, DoughRecipe> STREAM_CODEC = StreamCodec.composite(
        Ingredient.CONTENTS_STREAM_CODEC, DoughRecipe::ingredient,
        ItemStack.STREAM_CODEC, DoughRecipe::result,
        ByteBufCodecs.VAR_INT, DoughRecipe::workTicks,
        DoughRecipe::new);
    @Override public MapCodec<DoughRecipe> codec() { return CODEC; }
    @Override public StreamCodec<RegistryFriendlyByteBuf, DoughRecipe> streamCodec() { return STREAM_CODEC; }
}
