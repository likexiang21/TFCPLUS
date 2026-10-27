package io.github.likexiang21.tfcplus.agriculture.common.recipe.inworld;

import com.mojang.datafixers.util.Pair;
import com.mojang.serialization.Codec;
import com.mojang.serialization.MapCodec;
import com.mojang.serialization.codecs.RecordCodecBuilder;
import io.github.likexiang21.tfcplus.agriculture.common.recipe.AgricultureRecipeSerializers;
import io.github.likexiang21.tfcplus.agriculture.common.recipe.AgricultureRecipeTypes;
import io.github.likexiang21.tfcplus.agriculture.common.recipe.inworld.InWorldComponents.BlockStatePredicate;
import io.github.likexiang21.tfcplus.agriculture.common.recipe.inworld.InWorldComponents.InWorldInput;
import io.github.likexiang21.tfcplus.agriculture.common.recipe.inworld.InWorldComponents.SoundSpec;
import io.github.likexiang21.tfcplus.agriculture.common.recipe.inworld.InWorldComponents.Tool;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import net.minecraft.core.HolderLookup;
import net.minecraft.core.NonNullList;
import net.minecraft.network.RegistryFriendlyByteBuf;
import net.minecraft.network.codec.ByteBufCodecs;
import net.minecraft.network.codec.StreamCodec;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.crafting.Ingredient;
import net.minecraft.world.item.crafting.Recipe;
import net.minecraft.world.item.crafting.RecipeSerializer;
import net.minecraft.world.item.crafting.RecipeType;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.state.BlockState;

/** Block input, retained tool, replacement state and item emissions. Protocol: docs/131. */
public record InWorldRecipe(BlockStatePredicate inputState, Tool tool, BlockState resultState,
                            Optional<SoundSpec> soundInstance, List<Pair<ItemStack, InWorldAction>> resultItems)
    implements Recipe<InWorldInput> {
    public static final String NAME = "in_world";
    private static final StreamCodec<io.netty.buffer.ByteBuf, BlockState> STATE_STREAM =
        ByteBufCodecs.idMapper(Block.BLOCK_STATE_REGISTRY);
    public static final Codec<Pair<ItemStack, InWorldAction>> RESULT_ITEM_CODEC = RecordCodecBuilder.create(fields -> fields.group(
        ItemStack.STRICT_CODEC.fieldOf("item").forGetter(Pair::getFirst),
        InWorldAction.CODEC.fieldOf("action").forGetter(Pair::getSecond)
    ).apply(fields, Pair::of));
    public static final MapCodec<InWorldRecipe> CODEC = RecordCodecBuilder.mapCodec(fields -> fields.group(
        BlockStatePredicate.CODEC.fieldOf("input_state").forGetter(InWorldRecipe::inputState),
        Tool.CODEC.fieldOf("tool").forGetter(InWorldRecipe::tool),
        BlockState.CODEC.fieldOf("result_state").forGetter(InWorldRecipe::resultState),
        SoundSpec.CODEC.optionalFieldOf("sound").forGetter(InWorldRecipe::soundInstance),
        RESULT_ITEM_CODEC.listOf().optionalFieldOf("result_items", List.of()).forGetter(InWorldRecipe::resultItems)
    ).apply(fields, InWorldRecipe::new));
    public static final StreamCodec<RegistryFriendlyByteBuf, List<Pair<ItemStack, InWorldAction>>> RESULT_ITEMS_STREAM =
        StreamCodec.of(InWorldRecipe::writeOutputs, InWorldRecipe::readOutputs);
    public static final StreamCodec<RegistryFriendlyByteBuf, InWorldRecipe> STREAM_CODEC =
        StreamCodec.of(InWorldRecipe::writeRecipe, InWorldRecipe::readRecipe);

    public InWorldRecipe {
        resultItems = List.copyOf(resultItems);
    }

    private static void writeRecipe(RegistryFriendlyByteBuf buffer, InWorldRecipe value) {
        BlockStatePredicate.STREAM_CODEC.encode(buffer, value.inputState);
        Tool.STREAM_CODEC.encode(buffer, value.tool);
        STATE_STREAM.encode(buffer, value.resultState);
        buffer.writeBoolean(value.soundInstance.isPresent());
        value.soundInstance.ifPresent(sound -> SoundSpec.STREAM_CODEC.encode(buffer, sound));
        RESULT_ITEMS_STREAM.encode(buffer, value.resultItems);
    }
    private static InWorldRecipe readRecipe(RegistryFriendlyByteBuf buffer) {
        BlockStatePredicate input = BlockStatePredicate.STREAM_CODEC.decode(buffer);
        Tool tool = Tool.STREAM_CODEC.decode(buffer);
        BlockState replacement = STATE_STREAM.decode(buffer);
        Optional<SoundSpec> sound = buffer.readBoolean()
            ? Optional.of(SoundSpec.STREAM_CODEC.decode(buffer)) : Optional.empty();
        return new InWorldRecipe(input, tool, replacement, sound, RESULT_ITEMS_STREAM.decode(buffer));
    }
    private static void writeOutputs(RegistryFriendlyByteBuf buffer, List<Pair<ItemStack, InWorldAction>> outputs) {
        buffer.writeVarInt(outputs.size());
        outputs.forEach(output -> {
            ItemStack.STREAM_CODEC.encode(buffer, output.getFirst());
            InWorldAction.STREAM_CODEC.encode(buffer, output.getSecond());
        });
    }
    private static List<Pair<ItemStack, InWorldAction>> readOutputs(RegistryFriendlyByteBuf buffer) {
        int count = buffer.readVarInt();
        if (count < 0) throw new IllegalArgumentException("Negative processing-output count: " + count);
        List<Pair<ItemStack, InWorldAction>> outputs = new ArrayList<>(count);
        for (int remaining = count; remaining > 0; remaining--) {
            ItemStack stack = ItemStack.STREAM_CODEC.decode(buffer);
            outputs.add(Pair.of(stack, InWorldAction.STREAM_CODEC.decode(buffer)));
        }
        return outputs;
    }

    @Override public boolean matches(InWorldInput input, Level level) {
        return tool.getInputItem().test(input.stack()) && inputState.test(input.state());
    }
    @Override public NonNullList<Ingredient> getIngredients() {
        NonNullList<Ingredient> ingredients = NonNullList.create();
        ingredients.add(tool.getInputItem());
        return ingredients;
    }
    @Override public ItemStack getResultItem(HolderLookup.Provider registries) {
        return resultItems.isEmpty() ? ItemStack.EMPTY : resultItems.getFirst().getFirst().copy();
    }
    @Override public ItemStack assemble(InWorldInput input, HolderLookup.Provider registries) { return getResultItem(registries); }
    @Override public boolean canCraftInDimensions(int width, int height) { return true; }
    @Override public boolean isSpecial() { return true; }
    @Override public RecipeType<?> getType() { return AgricultureRecipeTypes.IN_WORLD.get(); }
    @Override public RecipeSerializer<?> getSerializer() { return AgricultureRecipeSerializers.IN_WORLD.get(); }

    
}
