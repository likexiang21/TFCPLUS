package com.example.tfcfarmingplus.expansion.common.blockentities;

import com.example.tfcfarmingplus.expansion.common.MyBlockEntities;
import com.eerussianguy.firmalife.common.recipes.DryingRecipe;
import com.eerussianguy.firmalife.config.FLConfig;
import net.dries007.tfc.common.blockentities.TickableInventoryBlockEntity;
import net.dries007.tfc.util.calendar.Calendars;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.core.HolderLookup;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.sounds.SoundEvents;
import net.minecraft.sounds.SoundSource;
import net.minecraft.world.Containers;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.state.BlockState;
import net.neoforged.neoforge.items.IItemHandler;
import net.neoforged.neoforge.items.ItemStackHandler;

/**
 * One-slot outdoor processor backed by Firmalife's public drying recipe API.
 * The rack owns only its calendar state and container policy; the recipe owns
 * the output item, food components and the firmalife:dried trait.
 */
public final class DryingRackBlockEntity extends TickableInventoryBlockEntity<ItemStackHandler> {
    public static final int MAX_BATCH = 8;
    private long startTick;
    private boolean finished;
    private final IItemHandler automationView;

    public DryingRackBlockEntity(BlockPos pos, BlockState state) {
        super(MyBlockEntities.DRYING_RACK.get(), pos, state, defaultInventory(1),
            com.example.tfcfarmingplus.expansion.TFCAgriculturePlus.MOD_ID);
        automationView = new RackItemHandler();
    }

    public ItemStack getContent() { return inventory.getStackInSlot(0); }
    public boolean isEmpty() { return inventory.getStackInSlot(0).isEmpty(); }
    public boolean isFinished() { return finished; }

    /** Existing renderer/debug callers can still display calendar progress. */
    public int getProgress() {
        if (finished || isEmpty() || level == null) return finished ? getDuration() : 0;
        return (int) Math.clamp(elapsedTicks(), 0L, (long) getDuration());
    }

    public static boolean hasRecipe(ItemStack stack) {
        return !stack.isEmpty() && DryingRecipe.getRecipe(stack) != null;
    }

    /** Inserts as many matching items as fit, sharing one drying timer for the batch. */
    public int insertCount(ItemStack stack) {
        // Keep direct callers on the same contract as the player and automation
        // paths.  The internal handler must never be a way to mix recipes or
        // exceed the eight-item batch limit.
        if (!canAccept(stack)) return 0;
        final int before = getContent().getCount();
        final ItemStack remainder = inventory.insertItem(0, stack.copy(), false);
        final int inserted = getContent().getCount() - before;
        if (!remainder.isEmpty() && inserted == 0) return 0;
        if (inserted > 0 && before == 0) beginWork();
        return inserted;
    }

    /** Compatibility helper for existing callers that only need success/failure. */
    public boolean insert(ItemStack stack) {
        return insertCount(stack) > 0;
    }

    public ItemStack extract() {
        if (!finished) return ItemStack.EMPTY;
        final ItemStack output = inventory.extractItem(0, inventory.getStackInSlot(0).getCount(), false);
        if (!output.isEmpty()) resetWork();
        return output;
    }

    /** Firmalife semantics: rain resets progress; an indoor rack takes twice as long. */
    public static void serverTick(Level level, BlockPos pos, BlockState state, DryingRackBlockEntity rack) {
        if (rack.isEmpty() || rack.finished || level.getGameTime() % 20L != 0L) return;
        final ItemStack input = rack.getContent();
        final DryingRecipe recipe = DryingRecipe.getRecipe(input);
        if (recipe == null || net.dries007.tfc.common.component.food.FoodCapability.isRotten(input)) {
            rack.resetWork();
            return;
        }
        if (level.getGameTime() % 60L == 0L && level.isRainingAt(pos)) {
            rack.resetCounter();
            return;
        }
        if (rack.elapsedTicks() >= rack.getDuration()) {
            rack.inventory.setStackInSlot(0, recipe.assemble(input));
            rack.finished = true;
            rack.sync();
            level.playSound(null, pos, SoundEvents.ITEM_PICKUP, SoundSource.BLOCKS, 0.7F, 0.8F);
        }
    }

    private int getDuration() {
        return level != null && !level.canSeeSky(worldPosition.above())
            ? FLConfig.SERVER.dryingTicks.get() * 2
            : FLConfig.SERVER.dryingTicks.get();
    }

    private long elapsedTicks() {
        return level == null ? 0L : Math.max(0L, Calendars.get(level).getTicks() - startTick);
    }

    private void beginWork() {
        startTick = level == null ? 0L : Calendars.get(level).getTicks();
        finished = false;
        sync();
    }

    private void resetCounter() {
        startTick = level == null ? 0L : Calendars.get(level).getTicks();
        finished = false;
        sync();
    }

    private void resetWork() {
        startTick = 0L;
        finished = false;
        sync();
    }

    public void dropContents() {
        if (level != null && !level.isClientSide() && !inventory.getStackInSlot(0).isEmpty()) {
            Containers.dropItemStack(level, worldPosition.getX() + 0.5, worldPosition.getY() + 0.5,
                worldPosition.getZ() + 0.5, inventory.extractItem(0, inventory.getStackInSlot(0).getCount(), false));
            resetWork();
        }
    }

    @Override
    public IItemHandler getSidedInventory(Direction context) {
        return automationView;
    }

    private void sync() {
        setChanged();
        if (level != null && !level.isClientSide()) {
            final BlockState state = getBlockState();
            level.sendBlockUpdated(worldPosition, state, state, net.minecraft.world.level.block.Block.UPDATE_CLIENTS);
        }
    }

    @Override
    public void saveAdditional(CompoundTag tag, HolderLookup.Provider registries) {
        super.saveAdditional(tag, registries);
        tag.putLong("start_tick", startTick);
        tag.putBoolean("finished", finished);
    }

    @Override
    public void loadAdditional(CompoundTag tag, HolderLookup.Provider registries) {
        super.loadAdditional(tag, registries);
        if (inventory.getStackInSlot(0).isEmpty() && tag.contains("content")) {
            ItemStack.parse(registries, tag.getCompound("content"))
                .ifPresent(stack -> inventory.setStackInSlot(0, stack));
        }
        if (inventory.getStackInSlot(0).isEmpty()) {
            startTick = 0L;
            finished = false;
            return;
        }
        final long now = level == null ? 0L : Calendars.get(level).getTicks();
        startTick = tag.contains("start_tick")
            ? tag.getLong("start_tick")
            : Math.max(0L, now - Math.max(0, tag.getInt("progress")));
        finished = tag.getBoolean("finished");
    }

    @Override public int getSlotStackLimit(int slot) { return slot == 0 ? MAX_BATCH : 0; }

    @Override public boolean isItemValid(int slot, ItemStack stack) {
        if (slot != 0 || finished || !hasRecipe(stack)) return false;
        final ItemStack current = getContent();
        return current.isEmpty()
            || ItemStack.isSameItemSameComponents(current, stack) && current.getCount() < MAX_BATCH;
    }

    public boolean canAccept(ItemStack stack) {
        return isItemValid(0, stack);
    }

    /** Automation follows the same recipe and completion rules as mouse interaction. */
    private final class RackItemHandler implements IItemHandler {
        @Override public int getSlots() { return 1; }
        @Override public ItemStack getStackInSlot(int slot) { return slot == 0 ? inventory.getStackInSlot(0) : ItemStack.EMPTY; }
        @Override public ItemStack insertItem(int slot, ItemStack stack, boolean simulate) {
            if (slot != 0 || !canAccept(stack)) return stack;
            final int before = getContent().getCount();
            final ItemStack remainder = inventory.insertItem(0, stack, simulate);
            if (!simulate && before == 0 && remainder.getCount() < stack.getCount()) beginWork();
            return remainder;
        }
        @Override public ItemStack extractItem(int slot, int amount, boolean simulate) {
            if (slot != 0 || !finished) return ItemStack.EMPTY;
            final ItemStack out = inventory.extractItem(0, Math.min(amount, inventory.getStackInSlot(0).getCount()), simulate);
            if (!simulate && !out.isEmpty() && inventory.getStackInSlot(0).isEmpty()) resetWork();
            return out;
        }
        @Override public int getSlotLimit(int slot) { return slot == 0 ? MAX_BATCH : 0; }
        @Override public boolean isItemValid(int slot, ItemStack stack) { return canAccept(stack); }
    }
}
