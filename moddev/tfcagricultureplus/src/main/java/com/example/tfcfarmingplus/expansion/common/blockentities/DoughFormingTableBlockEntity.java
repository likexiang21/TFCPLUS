package com.example.tfcfarmingplus.expansion.common.blockentities;

import com.example.tfcfarmingplus.expansion.TFCAgriculturePlus;
import com.example.tfcfarmingplus.expansion.common.MyBlockEntities;
import com.example.tfcfarmingplus.expansion.common.recipe.MyRecipeTypes;
import com.example.tfcfarmingplus.expansion.common.recipe.DoughRecipe;
import net.dries007.tfc.common.blockentities.InventoryBlockEntity;
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

/** Two-slot TFC inventory contract for the dough table: input and finished output. */
public final class DoughFormingTableBlockEntity extends InventoryBlockEntity<ItemStackHandler> {
    public static final int INPUT_SLOT = 0, OUTPUT_SLOT = 1;
    private final IItemHandler automationView = new TableItemHandler();
    public DoughFormingTableBlockEntity(BlockPos pos, BlockState state) {
        super(MyBlockEntities.DOUGH_TABLE.get(), pos, state, defaultInventory(2), TFCAgriculturePlus.MOD_ID);
    }
    public boolean insertInput(ItemStack stack) {
        if (stack.isEmpty() || !output().isEmpty() || !input().isEmpty() || FoodCapability.isRotten(stack)) return false;
        if (level == null || level.getRecipeManager().getRecipeFor(MyRecipeTypes.DOUGH.get(), new net.minecraft.world.item.crafting.SingleRecipeInput(stack), level).isEmpty()) return false;
        inventory.setStackInSlot(INPUT_SLOT, stack.copyWithCount(1)); setChanged(); return true;
    }
    public boolean formDough() {
        if (level == null || input().isEmpty() || !output().isEmpty()) return false;
        final var holder = level.getRecipeManager().getRecipeFor(MyRecipeTypes.DOUGH.get(), new net.minecraft.world.item.crafting.SingleRecipeInput(input()), level);
        if (holder.isEmpty()) return false;
        inventory.setStackInSlot(OUTPUT_SLOT, holder.get().value().assemble(new net.minecraft.world.item.crafting.SingleRecipeInput(input()), level.registryAccess()));
        inventory.setStackInSlot(INPUT_SLOT, ItemStack.EMPTY); setChanged(); return true;
    }
    public ItemStack input() { return inventory.getStackInSlot(INPUT_SLOT); }
    public ItemStack output() { return inventory.getStackInSlot(OUTPUT_SLOT); }
    public ItemStack takeInput() { return inventory.extractItem(INPUT_SLOT, 1, false); }
    public ItemStack takeOutput() { return inventory.extractItem(OUTPUT_SLOT, 1, false); }
    public void dropContents() { if (level == null || level.isClientSide()) return; for (int i = 0; i < 2; i++) { final ItemStack s = inventory.extractItem(i, 1, false); if (!s.isEmpty()) Containers.dropItemStack(level, worldPosition.getX()+0.5, worldPosition.getY()+0.5, worldPosition.getZ()+0.5, s); } }
    @Override public int getSlotStackLimit(int slot) { return 1; }
    @Override public boolean isItemValid(int slot, ItemStack stack) { return slot == INPUT_SLOT && !FoodCapability.isRotten(stack); }
    @Override public IItemHandler getSidedInventory(Direction side) { return automationView; }
    @Override public void saveAdditional(CompoundTag tag, HolderLookup.Provider registries) { super.saveAdditional(tag, registries); }
    @Override public void loadAdditional(CompoundTag tag, HolderLookup.Provider registries) { super.loadAdditional(tag, registries); }
    private final class TableItemHandler implements IItemHandler {
        @Override public int getSlots() { return 2; }
        @Override public ItemStack getStackInSlot(int slot) { return slot < 0 || slot > 1 ? ItemStack.EMPTY : inventory.getStackInSlot(slot); }
        @Override public int getSlotLimit(int slot) { return 1; }
        @Override public boolean isItemValid(int slot, ItemStack stack) { return slot == INPUT_SLOT && input().isEmpty() && output().isEmpty() && DoughFormingTableBlockEntity.this.isItemValid(slot, stack); }
        @Override public ItemStack insertItem(int slot, ItemStack stack, boolean simulate) { if (!isItemValid(slot, stack)) return stack; if (simulate) return ItemStack.EMPTY; inventory.setStackInSlot(INPUT_SLOT, stack.copyWithCount(1)); setChanged(); final ItemStack r = stack.copy(); r.shrink(1); return r; }
        @Override public ItemStack extractItem(int slot, int amount, boolean simulate) { return slot == OUTPUT_SLOT ? inventory.extractItem(OUTPUT_SLOT, Math.min(amount,1), simulate) : ItemStack.EMPTY; }
    }
}
