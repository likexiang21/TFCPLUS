package com.example.tfcfarmingplus.expansion.common.recipe;

import net.dries007.tfc.common.component.food.FoodCapability;
import net.minecraft.core.HolderLookup;
import net.minecraft.network.RegistryFriendlyByteBuf;
import net.minecraft.network.codec.StreamCodec;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.crafting.Ingredient;
import net.minecraft.world.item.crafting.Recipe;
import net.minecraft.world.item.crafting.RecipeInput;
import net.minecraft.world.item.crafting.RecipeSerializer;
import net.minecraft.world.item.crafting.RecipeType;
import net.minecraft.world.level.Level;
import com.mojang.serialization.MapCodec;
import com.mojang.serialization.codecs.RecordCodecBuilder;

/** K3 melting-pot recipe for canonical Firmalife chocolate blends. */
public record MeltingRecipe(Ingredient powder, Ingredient sweetener, ItemStack result, int meltTicks)
    implements Recipe<MeltingRecipe.Input> {
    public MeltingRecipe {
        if (meltTicks < 1) throw new IllegalArgumentException("melt_ticks must be positive");
        result = result.copy();
    }
    public record Input(ItemStack powder, ItemStack sweetener) implements RecipeInput {
        @Override public ItemStack getItem(int slot) { return switch (slot) { case 0 -> powder; case 1 -> sweetener; default -> throw new IndexOutOfBoundsException(slot); }; }
        @Override public int size() { return 2; }
    }
    @Override public boolean matches(Input input, Level level) {
        return !FoodCapability.isRotten(input.powder()) && !FoodCapability.isRotten(input.sweetener())
            && powder.test(input.powder()) && sweetener.test(input.sweetener());
    }
    @Override public ItemStack assemble(Input input, HolderLookup.Provider registries) {
        final ItemStack out = result.copy();
        return FoodCapability.has(input.powder()) ? FoodCapability.updateFoodFromPrevious(input.powder(), out) : FoodCapability.setCreatedNow(out);
    }
    @Override public boolean canCraftInDimensions(int width, int height) { return false; }
    @Override public ItemStack getResultItem(HolderLookup.Provider registries) { return result.copy(); }
    @Override public RecipeSerializer<?> getSerializer() { return MyRecipeSerializers.MELTING.get(); }
    @Override public RecipeType<?> getType() { return MyRecipeTypes.MELTING.get(); }
    public static final class Serializer implements RecipeSerializer<MeltingRecipe> {
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
}
