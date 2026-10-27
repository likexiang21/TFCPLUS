package com.example.tfcfarmingplus.expansion.common.recipe.inworld;

import com.mojang.serialization.Codec;
import com.mojang.serialization.MapCodec;
import com.mojang.serialization.codecs.RecordCodecBuilder;
import io.netty.buffer.ByteBuf;
import net.dries007.tfc.common.TFCTags;
import net.minecraft.core.BlockPos;
import net.minecraft.core.registries.BuiltInRegistries;
import net.minecraft.core.registries.Registries;
import net.minecraft.network.RegistryFriendlyByteBuf;
import net.minecraft.network.codec.ByteBufCodecs;
import net.minecraft.network.codec.StreamCodec;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.sounds.SoundEvent;
import net.minecraft.sounds.SoundSource;
import net.minecraft.tags.ItemTags;
import net.minecraft.tags.TagKey;
import net.minecraft.util.StringRepresentable;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.item.Item;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.crafting.Ingredient;
import net.minecraft.world.item.crafting.RecipeInput;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.state.BlockState;

import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.function.Predicate;

/** Small values for this project's block-processing contract, independently specified in docs/131. */
public final class InWorldComponents {
    private InWorldComponents() {}

    public record Input(BlockState state, ItemStack stack) implements RecipeInput {
        @Override public int size() { return 1; }
        @Override public ItemStack getItem(int slot) {
            if (slot == 0) return stack;
            throw new IndexOutOfBoundsException("Block processing has one held-item slot: " + slot);
        }
    }

    public record SoundInstance(SoundEvent sound, float volume, float pitch) {
        public static final Codec<SoundInstance> CODEC = RecordCodecBuilder.create(fields -> fields.group(
            ResourceLocation.CODEC.xmap(SoundEvent::createVariableRangeEvent, SoundEvent::getLocation)
                .fieldOf("sound").forGetter(SoundInstance::sound),
            Codec.floatRange(0, 1).fieldOf("volume").forGetter(SoundInstance::volume),
            Codec.floatRange(0, 1).fieldOf("pitch").forGetter(SoundInstance::pitch)
        ).apply(fields, SoundInstance::new));
        public static final StreamCodec<ByteBuf, SoundInstance> STREAM_CODEC = StreamCodec.of(
            SoundInstance::write, SoundInstance::read);

        private static void write(ByteBuf buffer, SoundInstance value) {
            SoundEvent.DIRECT_STREAM_CODEC.encode(buffer, value.sound);
            buffer.writeFloat(value.volume);
            buffer.writeFloat(value.pitch);
        }
        private static SoundInstance read(ByteBuf buffer) {
            SoundEvent event = SoundEvent.DIRECT_STREAM_CODEC.decode(buffer);
            float volume = buffer.readFloat();
            return new SoundInstance(event, volume, buffer.readFloat());
        }
        public void play(Level level, Player excludedPlayer, BlockPos pos) {
            level.playSound(excludedPlayer, pos, sound, SoundSource.BLOCKS, volume, pitch);
        }
    }

    public static final class BlockStatePredicate implements Predicate<BlockState> {
        private static final StreamCodec<RegistryFriendlyByteBuf, Block> BLOCK_STREAM =
            ByteBufCodecs.registry(Registries.BLOCK);
        private static final StreamCodec<ByteBuf, BlockState> STATE_STREAM =
            ByteBufCodecs.idMapper(Block.BLOCK_STATE_REGISTRY);
        public static final MapCodec<BlockStatePredicate> CODEC = RecordCodecBuilder.mapCodec(fields -> fields.group(
            BuiltInRegistries.BLOCK.byNameCodec().fieldOf("block").forGetter(BlockStatePredicate::getBlock),
            BlockState.CODEC.listOf().optionalFieldOf("acceptableStates", List.of())
                .forGetter(BlockStatePredicate::getAcceptableStates)
        ).apply(fields, BlockStatePredicate::new));
        public static final StreamCodec<RegistryFriendlyByteBuf, BlockStatePredicate> STREAM_CODEC =
            StreamCodec.of(BlockStatePredicate::write, BlockStatePredicate::read);

        private final Block target;
        private final List<BlockState> states;
        private final Set<BlockState> lookup;

        private BlockStatePredicate(Block target, List<BlockState> states) {
            this.target = target;
            this.states = List.copyOf(states);
            this.lookup = Set.copyOf(states);
        }
        public Block getBlock() { return target; }
        public List<BlockState> getAcceptableStates() { return states; }
        public static BlockStatePredicate forBlock(Block block) {
            return new BlockStatePredicate(block, List.of());
        }
        @Override public boolean test(BlockState candidate) {
            return candidate.is(target) && (lookup.isEmpty() || lookup.contains(candidate));
        }
        private static void write(RegistryFriendlyByteBuf buffer, BlockStatePredicate value) {
            BLOCK_STREAM.encode(buffer, value.target);
            buffer.writeVarInt(value.states.size());
            value.states.forEach(state -> STATE_STREAM.encode(buffer, state));
        }
        private static BlockStatePredicate read(RegistryFriendlyByteBuf buffer) {
            Block block = BLOCK_STREAM.decode(buffer);
            int count = buffer.readVarInt();
            if (count < 0) throw new IllegalArgumentException("Negative accepted-state count: " + count);
            List<BlockState> states = new ArrayList<>(count);
            for (int remaining = count; remaining > 0; remaining--) states.add(STATE_STREAM.decode(buffer));
            return new BlockStatePredicate(block, states);
        }
    }

    public enum Tool implements StringRepresentable {
        // Stable wire order, names and tag memberships.
        AXE("axe", ItemTags.AXES),
        SAW("saw", TFCTags.Items.TOOLS_SAW),
        KNIFE("knife", TFCTags.Items.TOOLS_KNIFE);

        public static final Tool[] VALUES = values();
        public static final Codec<Tool> CODEC = StringRepresentable.fromEnum(Tool::values);
        public static final StreamCodec<ByteBuf, Tool> STREAM_CODEC =
            ByteBufCodecs.VAR_INT.map(Tool::fromNetworkId, Tool::ordinal);
        private final String key;
        private final TagKey<Item> tag;
        private final Ingredient ingredient;

        Tool(String key, TagKey<Item> tag) {
            this.key = key;
            this.tag = tag;
            this.ingredient = Ingredient.of(tag);
        }
        public static Tool fromNetworkId(int id) {
            if (id < 0 || id >= VALUES.length) throw new IllegalArgumentException("Unknown processing-tool id: " + id);
            return VALUES[id];
        }
        @Override public String getSerializedName() { return key; }
        public TagKey<Item> getToolTagKey() { return tag; }
        public Ingredient getInputItem() { return ingredient; }
    }
}
