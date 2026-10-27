package io.github.likexiang21.tfcplus.agriculture.common.blockentity;

import io.github.likexiang21.tfcplus.agriculture.TFCAgriculturePlus;
import io.github.likexiang21.tfcplus.agriculture.common.interaction.MeltingPotInteractions;
import io.github.likexiang21.tfcplus.agriculture.common.recipe.AgricultureRecipeTypes;
import io.github.likexiang21.tfcplus.agriculture.common.recipe.MeltingRecipe;
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

/** Three-slot TFC inventory and bounded melting state machine. */
public final class MeltingPotBlockEntity extends TickableInventoryBlockEntity<ItemStackHandler> {
    public static final int POWDER_SLOT = 0, SWEETENER_SLOT = 1, OUTPUT_SLOT = 2;
    private long startTick;
    private boolean melting;
    private final IItemHandler automationView = new PotItemHandler();
    public MeltingPotBlockEntity(BlockPos pos, BlockState state) { super(AgricultureBlockEntities.MELTING_POT.get(), pos, state, defaultInventory(3), TFCAgriculturePlus.MOD_ID); }
    public boolean insertPowder(ItemStack stack) { return insert(POWDER_SLOT, stack); }
    public boolean insertSweetener(ItemStack stack) { return insert(SWEETENER_SLOT, stack); }
    private boolean insert(int slot, ItemStack stack) {
        if (melting || stack.isEmpty() || !inventory.getStackInSlot(slot).isEmpty() || !output().isEmpty() || FoodCapability.isRotten(stack)) return false;
        if ((slot == POWDER_SLOT && !MeltingPotInteractions.isPowder(stack)) || (slot == SWEETENER_SLOT && !MeltingPotInteractions.isSweetener(stack))) return false;
        inventory.setStackInSlot(slot, stack.copyWithCount(1)); setChanged(); return true;
    }
    private ItemStack inputPowder() { return inventory.getStackInSlot(POWDER_SLOT); }
    private ItemStack inputSweetener() { return inventory.getStackInSlot(SWEETENER_SLOT); }
    public ItemStack output() { return inventory.getStackInSlot(OUTPUT_SLOT); }
    public boolean startMelting() {
        if (level == null || melting || !output().isEmpty() || inputPowder().isEmpty() || inputSweetener().isEmpty()) return false;
        if (level.getRecipeManager().getRecipeFor(AgricultureRecipeTypes.MELTING.get(), new MeltingRecipe.MeltingInput(inputPowder(), inputSweetener()), level).isEmpty()) return false;
        melting = true; startTick = level.getGameTime(); setChanged(); return true;
    }
    public ItemStack extractOutput() { if (melting || output().isEmpty()) return ItemStack.EMPTY; return inventory.extractItem(OUTPUT_SLOT, 1, false); }
    public ItemStack takeAnyInput() { for (int i = 0; i < 2; i++) { final ItemStack s = inventory.extractItem(i, 1, false); if (!s.isEmpty()) return s; } return ItemStack.EMPTY; }
    public static void serverTick(Level level, BlockPos pos, BlockState state, MeltingPotBlockEntity pot) {
        if (!pot.melting || level.getGameTime() - pot.startTick < 1L || level.getGameTime() % 20L != 0L) return;
        final var holder = level.getRecipeManager().getRecipeFor(AgricultureRecipeTypes.MELTING.get(), new MeltingRecipe.MeltingInput(pot.inputPowder(), pot.inputSweetener()), level);
        if (holder.isEmpty() || FoodCapability.isRotten(pot.inputPowder()) || FoodCapability.isRotten(pot.inputSweetener())) { pot.fail(); return; }
        if (level.getGameTime() - pot.startTick < holder.get().value().meltTicks()) return;
        pot.inventory.setStackInSlot(OUTPUT_SLOT, holder.get().value().assemble(new MeltingRecipe.MeltingInput(pot.inputPowder(), pot.inputSweetener()), level.registryAccess()));
        pot.inventory.setStackInSlot(POWDER_SLOT, ItemStack.EMPTY); pot.inventory.setStackInSlot(SWEETENER_SLOT, ItemStack.EMPTY); pot.melting = false; pot.startTick = 0L; pot.setChanged();
    }
    private void fail() { inventory.setStackInSlot(SWEETENER_SLOT, ItemStack.EMPTY); melting = false; startTick = 0L; setChanged(); }
    public void dropContents() { if (level == null || level.isClientSide()) return; for (int i=0;i<3;i++) { final ItemStack s=inventory.extractItem(i,1,false); if(!s.isEmpty()) Containers.dropItemStack(level,worldPosition.getX()+0.5,worldPosition.getY()+0.5,worldPosition.getZ()+0.5,s); } }
    @Override public int getSlotStackLimit(int slot) { return 1; }
    @Override public boolean isItemValid(int slot, ItemStack stack) { return slot == POWDER_SLOT ? MeltingPotInteractions.isPowder(stack) : slot == SWEETENER_SLOT && MeltingPotInteractions.isSweetener(stack); }
    @Override public IItemHandler getSidedInventory(Direction side) { return automationView; }
    @Override public void saveAdditional(CompoundTag tag, HolderLookup.Provider registries) { super.saveAdditional(tag, registries); tag.putLong("start_tick",startTick); tag.putBoolean("melting",melting); }
    @Override public void loadAdditional(CompoundTag tag, HolderLookup.Provider registries) { super.loadAdditional(tag, registries); startTick=tag.getLong("start_tick"); melting=tag.getBoolean("melting"); }
    private final class PotItemHandler implements IItemHandler {
        @Override public int getSlots(){return 3;}
        @Override public ItemStack getStackInSlot(int slot){return slot<0||slot>2?ItemStack.EMPTY:inventory.getStackInSlot(slot);}
        @Override public int getSlotLimit(int slot){return 1;}
        @Override public boolean isItemValid(int slot, ItemStack stack){return !melting && output().isEmpty() && (slot==POWDER_SLOT?inputPowder().isEmpty():slot==SWEETENER_SLOT&&inputSweetener().isEmpty()) && MeltingPotBlockEntity.this.isItemValid(slot,stack);}
        @Override public ItemStack insertItem(int slot,ItemStack stack,boolean simulate){if(!isItemValid(slot,stack))return stack;if(simulate)return ItemStack.EMPTY;inventory.setStackInSlot(slot,stack.copyWithCount(1));setChanged();final ItemStack r=stack.copy();r.shrink(1);return r;}
        @Override public ItemStack extractItem(int slot,int amount,boolean simulate){return slot==OUTPUT_SLOT?inventory.extractItem(OUTPUT_SLOT,Math.min(amount,1),simulate):ItemStack.EMPTY;}
    }
}
