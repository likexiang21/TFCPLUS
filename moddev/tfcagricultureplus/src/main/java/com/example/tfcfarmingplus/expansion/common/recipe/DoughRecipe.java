package com.example.tfcfarmingplus.expansion.common.recipe;

import net.dries007.tfc.common.component.food.FoodCapability;
import net.minecraft.network.RegistryFriendlyByteBuf;
import net.minecraft.network.codec.ByteBufCodecs;
import net.minecraft.network.codec.StreamCodec;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.crafting.Ingredient;
import net.minecraft.world.item.crafting.Recipe;
import net.minecraft.world.item.crafting.RecipeSerializer;
import net.minecraft.world.item.crafting.RecipeType;
import net.minecraft.world.item.crafting.RecipeInput;
import net.minecraft.world.item.crafting.SingleRecipeInput;
import net.minecraft.world.level.Level;
import com.mojang.serialization.MapCodec;

/** K3 dough-forming recipe. The input may be any TFC/common-tag flour. */
public record DoughRecipe(Ingredient ingredient, ItemStack result, int workTicks)
    implements Recipe<SingleRecipeInput> {
    public DoughRecipe {
        if (workTicks < 1) throw new IllegalArgumentException("work_ticks must be positive");
        result = result.copy();
    }
    @Override public boolean matches(SingleRecipeInput input, Level level) {
        return !FoodCapability.isRotten(input.item()) && ingredient.test(input.item());
    }
    @Override public ItemStack assemble(SingleRecipeInput input, net.minecraft.core.HolderLookup.Provider registries) {
        final ItemStack output = result.copy();
        return FoodCapability.has(input.item())
            ? FoodCapability.updateFoodFromPrevious(input.item(), output)
            : FoodCapability.setCreatedNow(output);
    }
    @Override public boolean canCraftInDimensions(int width, int height) { return true; }
    @Override public ItemStack getResultItem(net.minecraft.core.HolderLookup.Provider registries) { return result.copy(); }
    @Override public RecipeSerializer<?> getSerializer() { return MyRecipeSerializers.DOUGH.get(); }
    @Override public RecipeType<?> getType() { return MyRecipeTypes.DOUGH.get(); }

    public static final class Serializer implements RecipeSerializer<DoughRecipe> {
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
}
