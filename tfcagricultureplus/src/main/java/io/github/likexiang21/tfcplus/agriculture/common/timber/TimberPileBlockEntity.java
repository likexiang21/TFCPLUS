package io.github.likexiang21.tfcplus.agriculture.common.timber;

import io.github.likexiang21.tfcplus.agriculture.TFCAgriculturePlus;
import io.github.likexiang21.tfcplus.agriculture.common.registry.AgricultureBlockEntities;
import java.util.ArrayList;
import java.util.List;
import net.dries007.tfc.common.blockentities.InventoryBlockEntity;
import net.dries007.tfc.common.capabilities.InventoryItemHandler;
import net.minecraft.core.BlockPos;
import net.minecraft.core.HolderLookup;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.world.Containers;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.state.BlockState;
import net.neoforged.neoforge.items.ItemStackHandler;

/** B-owned TFC container: one log, two halves or four quarters per cell.
 * Column settling adapts the MIT-licensed TFC Woodworking behavior; callbacks
 * are suspended during transfers so source and destination commit together.
 */
public final class TimberPileBlockEntity extends InventoryBlockEntity<ItemStackHandler> {
    private static final int SLOTS = 16;
    private static final int MAX_COLUMN_HEIGHT = 64;
    private final int[] stackLimitBySlot = new int[SLOTS];
    private boolean updatingInventory;

    public TimberPileBlockEntity(BlockPos pos, BlockState state) {
        super(AgricultureBlockEntities.TIMBER_PILE.get(), pos, state,
            self -> new PileInventory((TimberPileBlockEntity) self), TFCAgriculturePlus.MOD_ID);
    }

    public ItemStack get(int slot) { return inventory.getStackInSlot(slot); }

    public int units() {
        int total = 0;
        for (int slot = 0; slot < inventory.getSlots(); slot++) {
            final ItemStack stack = get(slot);
            total += stack.getCount() * TimberBlocks.weight(stack);
        }
        return total;
    }

    public boolean isFull() { return units() >= 64; }

    public String woodIdentity() {
        for (int slot = 0; slot < SLOTS; slot++) {
            if (!get(slot).isEmpty()) return TimberBlocks.woodIdentity(get(slot));
        }
        return null;
    }

    public boolean acceptsWood(ItemStack stack) {
        if (stack.isEmpty() || !stack.is(TimberPileBlock.LOGS)) return false;
        final String incoming = TimberBlocks.woodIdentity(stack);
        for (int slot = 0; slot < SLOTS; slot++) {
            if (!get(slot).isEmpty() && !incoming.equals(TimberBlocks.woodIdentity(get(slot)))) return false;
        }
        return true;
    }

    public boolean canInsert(ItemStack held) {
        if (!acceptsWood(held)) return false;
        for (int slot = 0; slot < SLOTS; slot++) {
            if (inventory.insertItem(slot, held.copyWithCount(1), true).isEmpty()) return true;
        }
        return false;
    }

    /** The caller owns consuming the held item after successful insertion. */
    public boolean insert(ItemStack held) {
        if (!acceptsWood(held)) return false;
        for (int slot = 0; slot < SLOTS; slot++) {
            if (inventory.insertItem(slot, held.copyWithCount(1), false).isEmpty()) return true;
        }
        return false;
    }

    public ItemStack extract() {
        for (int slot = SLOTS - 1; slot >= 0; slot--) {
            if (!get(slot).isEmpty()) return inventory.extractItem(slot, 1, false);
        }
        return ItemStack.EMPTY;
    }

    /** Clearing for ignition/removal must never pull in wood from another pile. */
    public void clear() {
        final boolean previous = updatingInventory;
        updatingInventory = true;
        try { super.clearContent(); }
        finally { updatingInventory = previous; }
        setChanged();
    }

    @Override public void clearContent() { clear(); }

    public void dropContents() {
        if (level == null || level.isClientSide()) return;
        final List<ItemStack> drops = new ArrayList<>();
        for (int slot = 0; slot < SLOTS; slot++) {
            if (!get(slot).isEmpty()) drops.add(get(slot).copy());
        }
        clear();
        for (ItemStack stack : drops) drop(stack);
    }

    private void drop(ItemStack stack) {
        if (level != null && !stack.isEmpty()) {
            Containers.dropItemStack(level, worldPosition.getX() + .5,
                worldPosition.getY() + .5, worldPosition.getZ() + .5, stack);
        }
    }

    @Override public void loadAdditional(CompoundTag tag, HolderLookup.Provider registries) {
        updatingInventory = true;
        try {
            super.loadAdditional(tag, registries);
            for (int slot = 0; slot < SLOTS; slot++) {
                stackLimitBySlot[slot] = get(slot).isEmpty() ? 0 : itemLimit(get(slot));
            }
        } finally { updatingInventory = false; }
    }

    @Override protected void onLoadAdditional() {
        // Empty newly placed piles must survive until setPlacedBy supplies wood.
        if (level != null && !level.isClientSide() && units() > 0) settleColumn();
    }

    @Override public int getSlotStackLimit(int slot) {
        if (slot < 0 || slot >= SLOTS) return 0;
        final ItemStack stack = get(slot);
        return stack.isEmpty() ? (stackLimitBySlot[slot] == 0 ? 4 : stackLimitBySlot[slot]) : itemLimit(stack);
    }

    private static int itemLimit(ItemStack stack) {
        return Math.min(stack.getMaxStackSize(), 4 / TimberBlocks.weight(stack));
    }

    @Override public boolean isItemValid(int slot, ItemStack stack) {
        return slot >= 0 && slot < SLOTS && acceptsWood(stack);
    }

    @Override public void setAndUpdateSlots(int slot) {
        setChanged();
        if (slot >= 0 && slot < SLOTS && get(slot).isEmpty()) stackLimitBySlot[slot] = 0;
        if (!updatingInventory && level != null && !level.isClientSide()) settleColumn();
    }

    /** Pack the loaded connected column from its bottom, preserving components.
     * Both empty cells and old oversized stacks are redistributed under one guard.
     * Any excess legacy items are dropped once rather than silently truncated.
     */
    private void settleColumn() {
        if (level == null || level.isClientSide() || isRemoved()) return;
        final String species = woodIdentity();
        if (species == null) return;
        BlockPos bottom = worldPosition;
        for (int i = 1; i < MAX_COLUMN_HEIGHT; i++) {
            if (!level.hasChunkAt(bottom.below())
                || !(level.getBlockEntity(bottom.below()) instanceof TimberPileBlockEntity below)
                || !species.equals(below.woodIdentity())) break;
            bottom = bottom.below();
        }
        final List<TimberPileBlockEntity> column = new ArrayList<>();
        final List<ItemStack> contents = new ArrayList<>();
        for (int i = 0; i < MAX_COLUMN_HEIGHT; i++) {
            final BlockPos pos = bottom.above(i);
            if (!level.hasChunkAt(pos)
                || !(level.getBlockEntity(pos) instanceof TimberPileBlockEntity pile)
                || !species.equals(pile.woodIdentity())) break;
            if (pile.updatingInventory) return;
            column.add(pile);
            for (int slot = 0; slot < SLOTS; slot++) {
                if (!pile.get(slot).isEmpty()) contents.add(pile.get(slot).copy());
            }
        }
        for (TimberPileBlockEntity pile : column) pile.updatingInventory = true;
        try {
            for (TimberPileBlockEntity pile : column) pile.clear();
            for (ItemStack stack : contents) {
                ItemStack remainder = stack;
                for (TimberPileBlockEntity pile : column) {
                    for (int slot = 0; slot < SLOTS && !remainder.isEmpty(); slot++) {
                        // Preserve saved items even if a later tag revision excludes them.
                        final ItemStack current = pile.get(slot);
                        if (!current.isEmpty() && !ItemStack.isSameItemSameComponents(current, remainder)) continue;
                        final int moved = Math.min(itemLimit(remainder) - current.getCount(), remainder.getCount());
                        if (moved <= 0) continue;
                        pile.inventory.setStackInSlot(slot, remainder.copyWithCount(current.getCount() + moved));
                        remainder = remainder.copyWithCount(remainder.getCount() - moved);
                    }
                    if (remainder.isEmpty()) break;
                }
                if (!remainder.isEmpty()) drop(remainder);
            }
        } finally {
            for (TimberPileBlockEntity pile : column) pile.updatingInventory = false;
        }
        // Remove emptied segments from the top to keep support updates safe.
        for (int i = column.size() - 1; i >= 0; i--) {
            final TimberPileBlockEntity pile = column.get(i);
            if (pile.units() == 0) level.removeBlock(pile.worldPosition, false);
            else pile.sync();
        }
    }

    public void sync() {
        setChanged();
        if (level == null || level.isClientSide() || isRemoved()) return;
        final BlockState state = getBlockState();
        final BlockState next = state.setValue(TimberPileBlock.LAYERS, Math.clamp((units() + 3) / 4, 1, 16));
        if (state != next) level.setBlock(worldPosition, next, Block.UPDATE_ALL);
        markForSync();
    }

    private static final class PileInventory extends InventoryItemHandler {
        private final TimberPileBlockEntity owner;
        private PileInventory(TimberPileBlockEntity owner) {
            super(owner, SLOTS);
            this.owner = owner;
        }

        @Override public ItemStack insertItem(int slot, ItemStack stack, boolean simulate) {
            if (slot >= 0 && slot < SLOTS && owner.get(slot).isEmpty()) {
                final int previous = owner.stackLimitBySlot[slot];
                owner.stackLimitBySlot[slot] = itemLimit(stack);
                try { return super.insertItem(slot, stack, simulate); }
                finally { if (simulate) owner.stackLimitBySlot[slot] = previous; }
            }
            return super.insertItem(slot, stack, simulate);
        }
    }
}
