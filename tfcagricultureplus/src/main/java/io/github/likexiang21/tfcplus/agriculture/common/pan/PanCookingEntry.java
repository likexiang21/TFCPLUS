package io.github.likexiang21.tfcplus.agriculture.common.pan;

import net.dries007.tfc.common.component.food.FoodCapability;
import net.dries007.tfc.common.component.food.FoodData;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.tags.ItemTags;
import net.minecraft.tags.TagKey;
import net.minecraft.world.item.Item;
import net.minecraft.world.item.ItemStack;

/** Per-ingredient cooking state in the pan. */
public final class PanCookingEntry {
    private static final TagKey<Item> RAW_MEAT = tag("foods/raw_meat");
    private static final TagKey<Item> COOKED_MEAT = tag("foods/cooked_meat");
    private static final TagKey<Item> RAW_FISH = tag("foods/raw_fish");
    private static final TagKey<Item> COOKED_FISH = tag("foods/cooked_fish");
    private static final TagKey<Item> VEGETABLE = tag("foods/vegetable");
    private static final TagKey<Item> GRAIN = tag("foods/grain");
    private static final TagKey<Item> FRUIT = tag("foods/fruit");
    private static final TagKey<Item> DAIRY = tag("foods/dairy");

    private final ItemStack stack;
    private final long addedTick;
    private long lastStirTick;
    private final int minTicks;
    private final int maxTicks;
    private final int stirTicks;

    private PanCookingEntry(ItemStack stack, long addedTick, long lastStirTick,
                            int minTicks, int maxTicks, int stirTicks) {
        this.stack = stack.copyWithCount(1);
        this.addedTick = addedTick;
        this.lastStirTick = lastStirTick;
        this.minTicks = minTicks;
        this.maxTicks = maxTicks;
        this.stirTicks = stirTicks;
    }

    public static PanCookingEntry create(ItemStack stack, long now) {
        final Profile p = Profile.of(stack);
        return new PanCookingEntry(stack, now, now, p.min, p.max, p.stir);
    }

    public ItemStack stack() { return stack; }
    public long addedTick() { return addedTick; }
    public long lastStirTick() { return lastStirTick; }
    public int minTicks() { return minTicks; }
    public int maxTicks() { return maxTicks; }
    public int stirTicks() { return stirTicks; }

    public void stir(long now) { lastStirTick = now; }

    public long elapsed(long now) { return Math.max(0L, now - addedTick); }

    public boolean raw(long now) { return elapsed(now) < minTicks; }
    public boolean overcooked(long now) { return elapsed(now) > maxTicks; }
    public boolean burnt(long now) { return now - lastStirTick > stirTicks; }

    public int penalty(long now) {
        int p = 0;
        if (raw(now)) p += 35;
        if (overcooked(now)) p += 25;
        if (burnt(now)) p += 45;
        return p;
    }

    public FoodData food() {
        final var food = FoodCapability.get(stack);
        return food == null ? FoodData.EMPTY : food.getData();
    }

    public String category() { return Profile.categoryOf(stack); }

    public CompoundTag save() {
        final CompoundTag tag = new CompoundTag();
        tag.put("item", ItemStack.CODEC.encodeStart(net.minecraft.nbt.NbtOps.INSTANCE, stack).getOrThrow());
        tag.putLong("added", addedTick);
        tag.putLong("stir", lastStirTick);
        tag.putInt("min", minTicks);
        tag.putInt("max", maxTicks);
        tag.putInt("stir_ticks", stirTicks);
        return tag;
    }

    public static PanCookingEntry load(CompoundTag tag) {
        final ItemStack stack = ItemStack.CODEC.parse(net.minecraft.nbt.NbtOps.INSTANCE, tag.get("item"))
            .result().orElse(ItemStack.EMPTY);
        return new PanCookingEntry(stack, tag.getLong("added"), tag.getLong("stir"),
            tag.getInt("min"), tag.getInt("max"), tag.getInt("stir_ticks"));
    }

    private static TagKey<Item> tag(String path) {
        return ItemTags.create(ResourceLocation.fromNamespaceAndPath("c", path));
    }

    private record Profile(int min, int max, int stir) {
        static Profile of(ItemStack stack) {
            if (stack.is(RAW_MEAT)) return new Profile(1200, 3600, 400);
            if (stack.is(COOKED_MEAT)) return new Profile(0, 1200, 600);
            if (stack.is(RAW_FISH)) return new Profile(600, 1800, 300);
            if (stack.is(COOKED_FISH)) return new Profile(0, 1200, 600);
            if (stack.is(VEGETABLE)) return new Profile(300, 1500, 250);
            if (stack.is(GRAIN)) return new Profile(600, 2400, 350);
            if (stack.is(FRUIT)) return new Profile(200, 1200, 300);
            if (stack.is(DAIRY)) return new Profile(200, 900, 500);
            return new Profile(400, 2400, 400);
        }

        static String categoryOf(ItemStack stack) {
            if (stack.is(RAW_MEAT) || stack.is(COOKED_MEAT)) return "meat";
            if (stack.is(RAW_FISH) || stack.is(COOKED_FISH)) return "fish";
            if (stack.is(VEGETABLE)) return "vegetable";
            if (stack.is(GRAIN)) return "grain";
            if (stack.is(FRUIT)) return "fruit";
            if (stack.is(DAIRY)) return "dairy";
            return "mixed";
        }
    }
}
