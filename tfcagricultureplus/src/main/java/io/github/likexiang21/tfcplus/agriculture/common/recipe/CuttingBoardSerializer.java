package io.github.likexiang21.tfcplus.agriculture.common.recipe;

import com.mojang.serialization.MapCodec;
import com.mojang.serialization.codecs.RecordCodecBuilder;
import java.util.List;
import net.dries007.tfc.common.TFCTags;
import net.dries007.tfc.common.recipes.outputs.ItemStackProvider;
import net.minecraft.network.RegistryFriendlyByteBuf;
import net.minecraft.network.codec.ByteBufCodecs;
import net.minecraft.network.codec.StreamCodec;
import net.minecraft.world.item.crafting.Ingredient;
import net.minecraft.world.item.crafting.RecipeSerializer;

public final class CuttingBoardSerializer implements RecipeSerializer<CuttingBoardRecipe> {
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
