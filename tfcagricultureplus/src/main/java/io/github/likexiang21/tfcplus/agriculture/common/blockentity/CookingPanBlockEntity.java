package io.github.likexiang21.tfcplus.agriculture.common.blockentity;

import io.github.likexiang21.tfcplus.agriculture.TFCAgriculturePlus;
import io.github.likexiang21.tfcplus.agriculture.common.interaction.PanInteractions;
import io.github.likexiang21.tfcplus.agriculture.common.recipe.AgricultureRecipeTypes;
import io.github.likexiang21.tfcplus.agriculture.common.recipe.PanRecipe;
import io.github.likexiang21.tfcplus.agriculture.common.registry.AgricultureBlockEntities;
import net.dries007.tfc.common.blockentities.TickableInventoryBlockEntity;
import net.dries007.tfc.common.component.food.FoodCapability;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.core.HolderLookup;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.world.Containers;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.state.BlockState;
import net.neoforged.neoforge.items.IItemHandler;
import net.neoforged.neoforge.items.ItemStackHandler;

/** K2 pan state machine with two input slots and one finished-output slot. */
public final class CookingPanBlockEntity extends TickableInventoryBlockEntity<ItemStackHandler> {
    public static final int FOOD_SLOT = 0;
    public static final int SPICE_SLOT = 1;
    public static final int OUTPUT_SLOT = 2;
    public static final int SLOTS = 3;

    private long startTick;
    private int stirCount;
    private boolean cooking;
    private boolean finished;
    private final IItemHandler automationView;

    public CookingPanBlockEntity(BlockPos pos, BlockState state) {
        super(AgricultureBlockEntities.COOKING_PAN.get(), pos, state, defaultInventory(SLOTS), TFCAgriculturePlus.MOD_ID);
        automationView = new PanItemHandler();
    }

    public ItemStack food() { return inventory.getStackInSlot(FOOD_SLOT); }
    public ItemStack spice() { return inventory.getStackInSlot(SPICE_SLOT); }
    public ItemStack output() { return inventory.getStackInSlot(OUTPUT_SLOT); }
    public boolean isCooking() { return cooking; }
    public boolean isFinished() { return finished; }
    public int getStirCount() { return stirCount; }
    public boolean isEmpty() { return food().isEmpty() && spice().isEmpty() && output().isEmpty(); }

    public boolean insertFood(ItemStack stack) {
        if (level == null || cooking || finished || !food().isEmpty() || !PanInteractions.isPanFood(stack)
            || FoodCapability.isRotten(stack)) return false;
        inventory.setStackInSlot(FOOD_SLOT, stack.copyWithCount(1));
        sync();
        return true;
    }

    public boolean insertSpice(ItemStack stack) {
        if (level == null || cooking || finished || food().isEmpty() || !spice().isEmpty()
            || !PanInteractions.isPanSpice(stack) || FoodCapability.isRotten(stack)) return false;
        inventory.setStackInSlot(SPICE_SLOT, stack.copyWithCount(1));
        sync();
        return true;
    }

    /** One deliberate stir. Cooking starts only after a valid recipe is present. */
    public boolean stir() {
        if (level == null || finished || food().isEmpty() || spice().isEmpty()) return false;
        final var holder = level.getRecipeManager().getRecipeFor(
            AgricultureRecipeTypes.PAN.get(), new PanRecipe.PanInput(food(), spice()), level);
        if (holder.isEmpty()) return false;
        if (!cooking) {
            cooking = true;
            startTick = level.getGameTime();
        }
        stirCount = Math.min(holder.get().value().requiredStirs(), stirCount + 1);
        sync();
        return true;
    }

    public ItemStack extractOutput() {
        if (!finished) return ItemStack.EMPTY;
        final ItemStack extractedStack = inventory.extractItem(OUTPUT_SLOT, inventory.getStackInSlot(OUTPUT_SLOT).getCount(), false);
        if (extractedStack.isEmpty()) return extractedStack;
        finished = false;
        stirCount = 0;
        startTick = 0L;
        sync();
        return extractedStack;
    }

    public static void serverTick(Level level, BlockPos pos, BlockState state, CookingPanBlockEntity pan) {
        if (!pan.cooking || pan.finished || level.getGameTime() % 20L != 0L) return;
        if (pan.food().isEmpty() || pan.spice().isEmpty()
            || FoodCapability.isRotten(pan.food()) || FoodCapability.isRotten(pan.spice())) {
            pan.failWork();
            return;
        }
        final var holder = level.getRecipeManager().getRecipeFor(
            AgricultureRecipeTypes.PAN.get(), new PanRecipe.PanInput(pan.food(), pan.spice()), level);
        if (holder.isEmpty()) {
            pan.failWork();
            return;
        }
        final PanRecipe recipe = holder.get().value();
        if (pan.stirCount < recipe.requiredStirs()) return;
        if (level.getGameTime() - pan.startTick < recipe.cookTicks()) return;
        pan.inventory.setStackInSlot(OUTPUT_SLOT,
            recipe.assemble(new PanRecipe.PanInput(pan.food(), pan.spice()), level.registryAccess()));
        pan.inventory.setStackInSlot(FOOD_SLOT, ItemStack.EMPTY);
        pan.inventory.setStackInSlot(SPICE_SLOT, ItemStack.EMPTY);
        pan.cooking = false;
        pan.finished = true;
        pan.sync();
    }

    private void failWork() {
        // A failed or rotten spice is the explicit failure penalty; the main food stays recoverable.
        inventory.setStackInSlot(SPICE_SLOT, ItemStack.EMPTY);
        cooking = false;
        finished = false;
        startTick = 0L;
        stirCount = 0;
        sync();
    }

    public void dropContents() {
        if (level == null || level.isClientSide()) return;
        for (int slot = 0; slot < SLOTS; slot++) {
            final ItemStack stack = inventory.extractItem(slot, inventory.getStackInSlot(slot).getCount(), false);
            if (!stack.isEmpty()) {
                Containers.dropItemStack(level, worldPosition.getX() + 0.5, worldPosition.getY() + 0.5,
                    worldPosition.getZ() + 0.5, stack);
            }
        }
        setChanged();
    }

    @Override public int getSlotStackLimit(int slot) { return 1; }

    @Override public boolean isItemValid(int slot, ItemStack stack) {
        return switch (slot) {
            case FOOD_SLOT -> PanInteractions.isPanFood(stack) && !FoodCapability.isRotten(stack);
            case SPICE_SLOT -> PanInteractions.isPanSpice(stack) && !FoodCapability.isRotten(stack);
            default -> false;
        };
    }

    @Override public IItemHandler getSidedInventory(Direction context) { return automationView; }

    @Override public void saveAdditional(CompoundTag tag, HolderLookup.Provider registries) {
        super.saveAdditional(tag, registries);
        tag.putLong("start_tick", startTick);
        tag.putInt("stir_count", stirCount);
        tag.putBoolean("cooking", cooking);
        tag.putBoolean("finished", finished);
    }

    @Override public void loadAdditional(CompoundTag tag, HolderLookup.Provider registries) {
        super.loadAdditional(tag, registries);
        startTick = tag.getLong("start_tick");
        stirCount = Math.max(0, tag.getInt("stir_count"));
        cooking = tag.getBoolean("cooking");
        finished = tag.getBoolean("finished");
        if (output().isEmpty() && (food().isEmpty() || spice().isEmpty())) {
            cooking = false;
            finished = false;
        }
    }

    private final class PanItemHandler implements IItemHandler {
        @Override public int getSlots() { return SLOTS; }
        @Override public ItemStack getStackInSlot(int slot) { return slot >= 0 && slot < SLOTS ? inventory.getStackInSlot(slot) : ItemStack.EMPTY; }
        @Override public int getSlotLimit(int slot) { return 1; }
        @Override public boolean isItemValid(int slot, ItemStack stack) {
            return slot == FOOD_SLOT ? !cooking && !finished && food().isEmpty() && isItemValid(FOOD_SLOT, stack)
                : slot == SPICE_SLOT && !cooking && !finished && foodPresent() && spice().isEmpty() && isItemValid(SPICE_SLOT, stack);
        }
        @Override public ItemStack insertItem(int slot, ItemStack stack, boolean simulate) {
            if (!isItemValid(slot, stack)) return stack;
            if (simulate) return ItemStack.EMPTY;
            inventory.setStackInSlot(slot, stack.copyWithCount(1));
            sync();
            ItemStack remainder = stack.copy();
            remainder.shrink(1);
            return remainder;
        }
        @Override public ItemStack extractItem(int slot, int amount, boolean simulate) {
            if (slot != OUTPUT_SLOT || !finished || amount < 1) return ItemStack.EMPTY;
            return inventory.extractItem(OUTPUT_SLOT, Math.min(amount, 1), simulate);
        }
        private boolean foodPresent() { return !food().isEmpty(); }
    }

    private void sync() {
        setChanged();
        if (level != null && !level.isClientSide()) {
            final BlockState state = getBlockState();
            level.sendBlockUpdated(worldPosition, state, state, net.minecraft.world.level.block.Block.UPDATE_CLIENTS);
        }
    }
}
