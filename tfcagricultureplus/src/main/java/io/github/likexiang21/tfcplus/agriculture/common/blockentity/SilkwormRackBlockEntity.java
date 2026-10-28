package io.github.likexiang21.tfcplus.agriculture.common.blockentity;

import io.github.likexiang21.tfcplus.agriculture.common.container.BContainer;

import io.github.likexiang21.tfcplus.agriculture.TFCAgriculturePlus;
import io.github.likexiang21.tfcplus.agriculture.common.block.SilkwormRackBlock;
import io.github.likexiang21.tfcplus.agriculture.common.menu.SilkwormRackMenu;
import io.github.likexiang21.tfcplus.agriculture.common.registry.AgricultureBlockEntities;
import io.github.likexiang21.tfcplus.agriculture.common.registry.AgricultureItems;
import io.github.likexiang21.tfcplus.agriculture.common.registry.AgricultureTags;
import io.github.likexiang21.tfcplus.agriculture.common.silkworm.SilkwormData;
import java.util.ArrayList;
import java.util.List;
import net.dries007.tfc.common.blockentities.TickableInventoryBlockEntity;
import net.dries007.tfc.util.climate.Climate;
import net.minecraft.core.BlockPos;
import net.minecraft.core.HolderLookup;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.network.chat.Component;
import net.minecraft.world.Containers;
import net.minecraft.world.entity.player.Inventory;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.inventory.AbstractContainerMenu;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.state.BlockState;
import net.neoforged.neoforge.items.ItemStackHandler;

/** An 11-slot TFC inventory with daily silkworm lifecycle processing. */
public final class SilkwormRackBlockEntity extends TickableInventoryBlockEntity<ItemStackHandler>  implements BContainer {
    public static final int BIOLOGICAL_SLOTS = 8;
    public static final int FEED_START = 8;
    public static final int FEED_SLOTS = 2;
    public static final int OUTPUT_SLOT = 10;
    private static final int HATCH_MIN_DAYS = 2;
    private static final int COCOON_MIN_DAYS = 3;

    private long lastProcessedDay = Long.MIN_VALUE;
    private final List<ItemStack> legacyOverflow = new ArrayList<>();

    public SilkwormRackBlockEntity(BlockPos pos, BlockState state) {
        super(AgricultureBlockEntities.SILKWORM_RACK.get(), pos, state,
            defaultInventory(BIOLOGICAL_SLOTS + FEED_SLOTS + 1), TFCAgriculturePlus.MOD_ID);
    }

    @Override
    public AbstractContainerMenu createMenu(int containerId, Inventory playerInventory, Player player) {
        return SilkwormRackMenu.create(this, playerInventory, containerId);
    }

    @Override
    public Component getDisplayName() {
        return Component.translatable("block_entity.tfcagricultureplus.silkworm_rack");
    }

    public static void serverTick(Level level, BlockPos pos, BlockState state,
                                  SilkwormRackBlockEntity rack) {
        if (level.isClientSide()) return;
        rack.refreshStages();
        if (!rack.legacyOverflow.isEmpty()) {
            for (ItemStack stack : rack.legacyOverflow) Containers.dropItemStack(level,
                pos.getX() + 0.5, pos.getY() + 0.5, pos.getZ() + 0.5, stack);
            rack.legacyOverflow.clear();
            rack.persist();
        }
        final long today = SilkwormData.currentDay(level);
        if (rack.lastProcessedDay == Long.MIN_VALUE) {
            rack.lastProcessedDay = today;
            rack.initializeStacks(level);
            rack.persist();
            return;
        }
        if (today <= rack.lastProcessedDay) {
            boolean changed = false;
            for (int slot = 0; slot < BIOLOGICAL_SLOTS; slot++) {
                ItemStack adult = rack.inventory.getStackInSlot(slot);
                if (SilkwormData.ageAdult(adult, today)) {
                    rack.inventory.setStackInSlot(slot, adult);
                    changed = true;
                }
            }
            if (changed) rack.persist();
            return;
        }

        // Settle every elapsed TFC day, including days while the chunk was unloaded.
        // The cap bounds one tick's work; the cursor retains the remaining days.
        int settled = 0;
        while (rack.lastProcessedDay < today && settled++ < 32) {
            rack.processOneDay(level, ++rack.lastProcessedDay);
        }
        rack.refreshStages();
        rack.persist();
    }

    private void processOneDay(Level level, long day) {
        int adults = 0;
        // Egg incubation still requires a non-freezing environment. Once an
        // egg has hatched, larvae and cocoons are no longer temperature-gated.
        final float temperature = Climate.getInstantTemperature(level, worldPosition);
        final boolean hatchTemperature = temperature >= 0.0F;
        for (int slot = 0; slot < BIOLOGICAL_SLOTS; slot++) {
            ItemStack stack = inventory.getStackInSlot(slot);
            if (stack.isEmpty()) continue;
            SilkwormData.initialize(stack, day);
            if (stack.is(AgricultureItems.SILKWORM_EGG.get())) {
                if (hatchTemperature
                    && SilkwormData.ageDays(stack, day) >= HATCH_MIN_DAYS + level.random.nextInt(3)) {
                    final ItemStack silkworm = new ItemStack(AgricultureItems.SILKWORM.get());
                    SilkwormData.initialize(silkworm, day);
                    inventory.setStackInSlot(slot, silkworm);
                }
            } else if (stack.is(AgricultureItems.SILKWORM.get())) {
                final boolean feedSucceeded = consumeOneFeed();
                if (feedSucceeded) {
                    SilkwormData.setGrowth(stack, SilkwormData.growth(stack) + 1);
                    if (SilkwormData.growth(stack) >= 10) {
                        final ItemStack cocoon = new ItemStack(AgricultureItems.COCOON.get());
                        SilkwormData.initialize(cocoon, day);
                        inventory.setStackInSlot(slot, cocoon);
                    }
                } else {
                    SilkwormData.setHunger(stack, SilkwormData.hunger(stack) + 1);
                    if (SilkwormData.hunger(stack) >= 3) inventory.setStackInSlot(slot, ItemStack.EMPTY);
                }
            } else if (stack.is(AgricultureItems.COCOON.get())) {
                if (SilkwormData.ageDays(stack, day) >= COCOON_MIN_DAYS + level.random.nextInt(3)) {
                    inventory.setStackInSlot(slot, SilkwormData.adult(day));
                }
            } else if (stack.is(AgricultureItems.ADULT_SILKWORM.get())) {
                SilkwormData.ageAdult(stack, day);
                if (!stack.isEmpty()) adults++;
            }
        }
        if (adults >= 2) produceEggs(level, day);
        refreshStages();
    }

    private void produceEggs(Level level, long day) {
        final ItemStack output = inventory.getStackInSlot(OUTPUT_SLOT);
        if (!output.isEmpty() && !output.is(AgricultureItems.SILKWORM_EGG.get())) return;
        final int capacity = output.isEmpty() ? 64 : 64 - output.getCount();
        if (capacity <= 0) return;
        final int upperBound = Math.min(5, Math.max(1, countAdults()));
        final int amount = Math.min(capacity, 1 + level.random.nextInt(upperBound));
        if (output.isEmpty()) {
            final ItemStack eggs = new ItemStack(AgricultureItems.SILKWORM_EGG.get(), amount);
            SilkwormData.initialize(eggs, day);
            inventory.setStackInSlot(OUTPUT_SLOT, eggs);
        } else {
            SilkwormData.initialize(output, day);
            inventory.setStackInSlot(OUTPUT_SLOT, output.copyWithCount(output.getCount() + amount));
        }
    }

    private int countAdults() {
        int count = 0;
        for (int slot = 0; slot < BIOLOGICAL_SLOTS; slot++) {
            if (inventory.getStackInSlot(slot).is(AgricultureItems.ADULT_SILKWORM.get())) count++;
        }
        return count;
    }

    private boolean consumeOneFeed() {
        for (int slot = FEED_START; slot < FEED_START + FEED_SLOTS; slot++) {
            if (!inventory.getStackInSlot(slot).isEmpty()) {
                inventory.extractItem(slot, 1, false);
                return true;
            }
        }
        return false;
    }

    private void initializeStacks(Level level) {
        for (int slot = 0; slot < BIOLOGICAL_SLOTS; slot++) {
            SilkwormData.initialize(inventory.getStackInSlot(slot), level);
        }
    }

    public boolean isBiological(ItemStack stack) {
        return stack.is(AgricultureItems.SILKWORM_EGG.get()) || stack.is(AgricultureItems.SILKWORM.get())
            || stack.is(AgricultureItems.COCOON.get()) || stack.is(AgricultureItems.ADULT_SILKWORM.get());
    }

    public boolean isFeed(ItemStack stack) {
        return !stack.isEmpty() && stack.is(AgricultureTags.Items.SILKWORM_FEED);
    }

    @Override
    public int getSlotStackLimit(int slot) {
        return slot < BIOLOGICAL_SLOTS ? 1 : 64;
    }

    @Override
    public boolean isItemValid(int slot, ItemStack stack) {
        if (slot < 0 || slot >= OUTPUT_SLOT) return false;
        return slot < BIOLOGICAL_SLOTS ? isBiological(stack) : isFeed(stack);
    }

    @Override
    public void setAndUpdateSlots(int slot) {
        refreshStages();
        super.setAndUpdateSlots(slot);
    }

    private void refreshStages() {
        if (level == null || level.isClientSide()) return;
        int stage = 0;
        for (int slot = 0; slot < BIOLOGICAL_SLOTS; slot++) {
            ItemStack stack = inventory.getStackInSlot(slot);
            if (stack.is(AgricultureItems.COCOON.get())) stage = 2;
            else if (!stack.isEmpty()) stage = Math.max(stage, 1);
        }
        if (getBlockState().getValue(SilkwormRackBlock.STAGE) != stage) {
            level.setBlock(worldPosition, getBlockState().setValue(SilkwormRackBlock.STAGE, stage),
                Block.UPDATE_CLIENTS | Block.UPDATE_NEIGHBORS);
        }
    }

    private void persist() {
        setChanged();
        markForSync();
    }

    public void dropContents() {
        if (level == null || level.isClientSide()) return;
        for (int slot = 0; slot <= OUTPUT_SLOT; slot++) {
            ItemStack stack = inventory.extractItem(slot, inventory.getStackInSlot(slot).getCount(), false);
            if (!stack.isEmpty()) Containers.dropItemStack(level, worldPosition.getX() + 0.5,
                worldPosition.getY() + 0.5, worldPosition.getZ() + 0.5, stack);
        }
        setChanged();
    }

    @Override
    public void saveAdditional(CompoundTag tag, HolderLookup.Provider registries) {
        super.saveAdditional(tag, registries);
        if (lastProcessedDay != Long.MIN_VALUE) tag.putLong("last_processed_day", lastProcessedDay);
        if (!legacyOverflow.isEmpty()) {
            net.minecraft.nbt.ListTag overflow = new net.minecraft.nbt.ListTag();
            for (ItemStack stack : legacyOverflow) overflow.add(stack.save(registries));
            tag.put("legacy_feed_overflow", overflow);
        }
    }

    @Override
    public void loadAdditional(CompoundTag tag, HolderLookup.Provider registries) {
        super.loadAdditional(tag, registries);
        lastProcessedDay = tag.contains("last_processed_day") ? tag.getLong("last_processed_day") : Long.MIN_VALUE;
        legacyOverflow.clear();
        for (net.minecraft.nbt.Tag entry : tag.getList("legacy_feed_overflow", 10)) {
            ItemStack.parse(registries, entry).ifPresent(legacyOverflow::add);
        }
        if (inventory.getSlots() > OUTPUT_SLOT + 1) {
            List<ItemStack> previousItems = new ArrayList<>();
            for (int slot = 0; slot < inventory.getSlots(); slot++) previousItems.add(inventory.getStackInSlot(slot).copy());
            inventory.setSize(OUTPUT_SLOT + 1);
            for (int slot = 0; slot < BIOLOGICAL_SLOTS; slot++) inventory.setStackInSlot(slot, previousItems.get(slot));
            for (int slot = FEED_START; slot < Math.min(16, previousItems.size()); slot++) storeLegacyFeed(previousItems.get(slot));
            if (previousItems.size() > 16) inventory.setStackInSlot(OUTPUT_SLOT, previousItems.get(16));
        }
        ItemStack legacy = inventory.getStackInSlot(0);
        if (isFeed(legacy)) {
            inventory.setStackInSlot(0, ItemStack.EMPTY);
            storeLegacyFeed(legacy);
        }
    }

    private void storeLegacyFeed(ItemStack stack) {
        if (stack.isEmpty()) return;
        for (int slot = FEED_START; slot < FEED_START + FEED_SLOTS; slot++) {
            ItemStack stored = inventory.getStackInSlot(slot);
            if (stored.isEmpty()) {
                inventory.setStackInSlot(slot, stack.copy());
                return;
            }
            if (ItemStack.isSameItemSameComponents(stored, stack) && stored.getCount() + stack.getCount() <= 64) {
                inventory.setStackInSlot(slot, stored.copyWithCount(stored.getCount() + stack.getCount()));
                return;
            }
        }
        legacyOverflow.add(stack.copy());
    }

    @Override public net.neoforged.neoforge.items.IItemHandler bItemHandler() { return inventory; }
}
