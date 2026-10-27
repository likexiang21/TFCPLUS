package io.github.likexiang21.tfcplus.agriculture.common.recipe;

import com.mojang.serialization.MapCodec;
import com.mojang.serialization.codecs.RecordCodecBuilder;
import net.minecraft.network.RegistryFriendlyByteBuf;
import net.minecraft.network.codec.StreamCodec;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.crafting.Ingredient;
import net.minecraft.world.item.crafting.RecipeSerializer;

public final class PanSerializer implements RecipeSerializer<PanRecipe> {
    private static final MapCodec<PanRecipe> CODEC = RecordCodecBuilder.mapCodec(instance -> instance.group(
        Ingredient.CODEC.fieldOf("food").forGetter(PanRecipe::food),
        Ingredient.CODEC.fieldOf("spice").forGetter(PanRecipe::spice),
        ItemStack.STRICT_CODEC.fieldOf("result").forGetter(PanRecipe::result),
        com.mojang.serialization.Codec.INT.optionalFieldOf("cook_ticks", PanRecipe.DEFAULT_COOK_TICKS)
            .forGetter(PanRecipe::cookTicks),
        com.mojang.serialization.Codec.INT.optionalFieldOf("required_stirs", PanRecipe.DEFAULT_REQUIRED_STIRS)
            .forGetter(PanRecipe::requiredStirs)
    ).apply(instance, PanRecipe::new));

    private static final StreamCodec<RegistryFriendlyByteBuf, PanRecipe> STREAM_CODEC =
        StreamCodec.composite(
            Ingredient.CONTENTS_STREAM_CODEC, PanRecipe::food,
            Ingredient.CONTENTS_STREAM_CODEC, PanRecipe::spice,
            ItemStack.STREAM_CODEC, PanRecipe::result,
            net.minecraft.network.codec.ByteBufCodecs.VAR_INT, PanRecipe::cookTicks,
            net.minecraft.network.codec.ByteBufCodecs.VAR_INT, PanRecipe::requiredStirs,
            PanRecipe::new);

    @Override public MapCodec<PanRecipe> codec() { return CODEC; }
    @Override public StreamCodec<RegistryFriendlyByteBuf, PanRecipe> streamCodec() { return STREAM_CODEC; }
}
