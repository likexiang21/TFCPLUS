package com.example.tfcfarmingplus.expansion.common.recipe;

import com.mojang.serialization.Codec;
import com.mojang.serialization.MapCodec;
import com.mojang.serialization.codecs.RecordCodecBuilder;
import net.dries007.tfc.common.TFCTags;
import net.dries007.tfc.common.component.food.FoodCapability;
import net.dries007.tfc.common.recipes.outputs.ItemStackProvider;
import net.minecraft.core.HolderLookup;
import net.minecraft.core.NonNullList;
import net.minecraft.network.RegistryFriendlyByteBuf;
import net.minecraft.network.codec.ByteBufCodecs;
import net.minecraft.network.codec.StreamCodec;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.crafting.Ingredient;
import net.minecraft.world.item.crafting.Recipe;
import net.minecraft.world.item.crafting.RecipeInput;
import net.minecraft.world.item.crafting.RecipeSerializer;
import net.minecraft.world.item.crafting.RecipeType;
import net.minecraft.world.level.Level;

import java.util.List;

/** One board ingredient and a retained tool, with TFC output modifiers. */
public record CuttingBoardRecipe(Ingredient ingredient, Ingredient tool,
                                 ItemStackProvider result, List<ItemStackProvider> byproducts)
    implements Recipe<CuttingBoardRecipe.Input> {

    public record Input(ItemStack ingredient, ItemStack tool) implements RecipeInput {
        @Override
        public ItemStack getItem(int slot) {
            return switch (slot) {
                case 0 -> ingredient;
                case 1 -> tool;
                default -> throw new IndexOutOfBoundsException(slot);
            };
        }

        @Override
        public int size() { return 2; }
    }

    @Override
    public boolean matches(Input input, Level level) {
        return !FoodCapability.isRotten(input.ingredient())
            && ingredient.test(input.ingredient()) && tool.test(input.tool());
    }

    @Override
    public ItemStack assemble(Input input, HolderLookup.Provider registries) {
        final ItemStack output = result.getSingleStack(input.ingredient());
        return FoodCapability.has(input.ingredient()) ? output : FoodCapability.setCreatedNow(output);
    }

    @Override
    public NonNullList<Ingredient> getIngredients() {
        final var ingredients = NonNullList.<Ingredient>create();
        ingredients.add(ingredient);
        ingredients.add(tool);
        return ingredients;
    }

    @Override
    public boolean canCraftInDimensions(int width, int height) { return false; }

    @Override
    public boolean isSpecial() { return true; }

    @Override
    public ItemStack getResultItem(HolderLookup.Provider registries) { return result.getEmptyStack(); }

    @Override
    public RecipeSerializer<?> getSerializer() { return MyRecipeSerializers.CUTTING_BOARD.get(); }

    @Override
    public RecipeType<?> getType() { return MyRecipeTypes.CUTTING_BOARD.get(); }

    public static final class Serializer implements RecipeSerializer<CuttingBoardRecipe> {
        private static final Ingredient DEFAULT_TOOL = Ingredient.of(TFCTags.Items.TOOLS_KNIFE);
        private static final MapCodec<CuttingBoardRecipe> CODEC = RecordCodecBuilder.mapCodec(instance -> instance.group(
            Ingredient.CODEC.fieldOf("ingredient").forGetter(CuttingBoardRecipe::ingredient),
            Ingredient.CODEC.optionalFieldOf("tool", DEFAULT_TOOL).forGetter(CuttingBoardRecipe::tool),
            ItemStackProvider.CODEC.fieldOf("result").forGetter(CuttingBoardRecipe::result),
            ItemStackProvider.CODEC.listOf().optionalFieldOf("byproducts", List.of()).forGetter(CuttingBoardRecipe::byproducts)
        ).apply(instance, CuttingBoardRecipe::new));
        private static final StreamCodec<RegistryFriendlyByteBuf, CuttingBoardRecipe> STREAM_CODEC = StreamCodec.composite(
            Ingredient.CONTENTS_STREAM_CODEC, CuttingBoardRecipe::ingredient,
            Ingredient.CONTENTS_STREAM_CODEC, CuttingBoardRecipe::tool,
            ItemStackProvider.STREAM_CODEC, CuttingBoardRecipe::result,
            ItemStackProvider.STREAM_CODEC.apply(ByteBufCodecs.list()), CuttingBoardRecipe::byproducts,
            CuttingBoardRecipe::new);

        @Override
        public MapCodec<CuttingBoardRecipe> codec() { return CODEC; }

        @Override
        public StreamCodec<RegistryFriendlyByteBuf, CuttingBoardRecipe> streamCodec() { return STREAM_CODEC; }
    }
}
