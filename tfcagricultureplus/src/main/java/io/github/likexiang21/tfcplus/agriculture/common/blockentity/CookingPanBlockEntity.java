package io.github.likexiang21.tfcplus.agriculture.common.blockentity;

import io.github.likexiang21.tfcplus.agriculture.TFCAgriculturePlus;
import io.github.likexiang21.tfcplus.agriculture.common.item.ServingPlateItem;
import io.github.likexiang21.tfcplus.agriculture.common.item.SpatulaItem;
import io.github.likexiang21.tfcplus.agriculture.common.pan.DishEating;
import io.github.likexiang21.tfcplus.agriculture.common.pan.PanCookingEntry;
import io.github.likexiang21.tfcplus.agriculture.common.pan.PanDishBuilder;
import io.github.likexiang21.tfcplus.agriculture.common.pan.PanDishData;
import io.github.likexiang21.tfcplus.agriculture.common.registry.AgricultureBlockEntities;
import java.util.ArrayList;
import java.util.List;
import net.dries007.tfc.common.blockentities.TickableInventoryBlockEntity;
import net.dries007.tfc.common.blockentities.IHeatable;
import net.dries007.tfc.common.component.food.FoodCapability;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.core.HolderLookup;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.nbt.ListTag;
import net.minecraft.nbt.Tag;
import net.minecraft.network.chat.Component;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.tags.FluidTags;
import net.minecraft.tags.TagKey;
import net.minecraft.world.Containers;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.state.BlockState;
import net.neoforged.neoforge.fluids.FluidStack;
import net.neoforged.neoforge.fluids.capability.IFluidHandler;
import net.neoforged.neoforge.fluids.capability.templates.FluidTank;
import net.neoforged.neoforge.items.IItemHandler;
import net.neoforged.neoforge.items.ItemStackHandler;

/**
 * Cuisine-Delight-inspired pan, independently implemented for TFC:
 * heat from a TFC IHeatable below, oil tank, multiple timed ingredients,
 * spatula stirring, and a dynamic dish with TFC FoodData.
 */
public final class CookingPanBlockEntity extends TickableInventoryBlockEntity<ItemStackHandler> {
    public static final int INGREDIENT_SLOTS = 8;
    public static final int OIL_REQUIRED = 100;
    public static final float MIN_HEAT = 200.0F;

    private static final TagKey<net.minecraft.world.level.material.Fluid> OIL =
        TagKey.create(net.minecraft.core.registries.Registries.FLUID,
            ResourceLocation.fromNamespaceAndPath("c", "plantoil"));
    private static final TagKey<net.minecraft.world.level.material.Fluid> FIRMALIFE_OIL =
        TagKey.create(net.minecraft.core.registries.Registries.FLUID,
            ResourceLocation.fromNamespaceAndPath("firmalife", "oils"));

    private final List<PanCookingEntry> entries = new ArrayList<>();
    private final FluidTank oilTank = new FluidTank(1000, stack -> stack.is(OIL) || stack.is(FIRMALIFE_OIL));
    private final IItemHandler automationView;

    public CookingPanBlockEntity(BlockPos pos, BlockState state) {
        super(AgricultureBlockEntities.COOKING_PAN.get(), pos, state, defaultInventory(INGREDIENT_SLOTS),
            TFCAgriculturePlus.MOD_ID);
        automationView = inventory;
    }

    public FluidTank oilTank() { return oilTank; }
    public int ingredientCount() { return entries.size(); }
    public boolean hasOil() { return oilTank.getFluidAmount() >= OIL_REQUIRED; }

    public boolean hasHeat() {
        if (level == null) return false;
        final var below = level.getBlockEntity(worldPosition.below());
        return below instanceof IHeatable heat && heat.getTemperature() >= MIN_HEAT;
    }

    public boolean addIngredient(ItemStack held) {
        if (level == null || level.isClientSide() || held.isEmpty() || !hasHeat() || !hasOil()) return false;
        if (!FoodCapability.has(held)) return false;
        if (entries.size() >= INGREDIENT_SLOTS) return false;
        final int slot = firstEmptySlot();
        if (slot < 0) return false;
        final ItemStack one = held.copyWithCount(1);
        inventory.setStackInSlot(slot, one);
        entries.add(PanCookingEntry.create(one, level.getGameTime()));
        sync();
        return true;
    }

    public boolean stir(SpatulaItem spatula, ItemStack spatulaStack, net.minecraft.world.entity.player.Player player) {
        if (level == null || level.isClientSide() || entries.isEmpty() || !hasHeat()) return false;
        final long now = level.getGameTime();
        for (final PanCookingEntry entry : entries) entry.stir(now);
        spatulaStack.hurtAndBreak(1, player, net.minecraft.world.entity.EquipmentSlot.MAINHAND);
        sync();
        return true;
    }

    public ItemStack serve(ItemStack plate) {
        if (level == null || level.isClientSide() || entries.isEmpty() || !hasOil()) return ItemStack.EMPTY;
        if (!(plate.getItem() instanceof ServingPlateItem)) return ItemStack.EMPTY;
        final PanDishData dish = PanDishBuilder.build(entries, level.getGameTime(), oilTank.getFluidAmount());
        if (dish == null) return ItemStack.EMPTY;
        final ItemStack result = plate.copyWithCount(1);
        PanDishData.write(result, dish);
        oilTank.drain(OIL_REQUIRED, IFluidHandler.FluidAction.EXECUTE);
        entries.clear();
        for (int i = 0; i < inventory.getSlots(); i++) inventory.setStackInSlot(i, ItemStack.EMPTY);
        sync();
        return result;
    }

    public Component status() {
        if (!hasHeat()) return Component.translatable("message.tfcagricultureplus.pan.no_heat");
        if (!hasOil()) return Component.translatable("message.tfcagricultureplus.pan.no_oil");
        if (entries.isEmpty()) return Component.translatable("message.tfcagricultureplus.pan.empty");
        return Component.translatable("message.tfcagricultureplus.pan.contents", entries.size(), oilTank.getFluidAmount());
    }

    private int firstEmptySlot() {
        for (int i = 0; i < inventory.getSlots(); i++) if (inventory.getStackInSlot(i).isEmpty()) return i;
        return -1;
    }

    public static void serverTick(Level level, BlockPos pos, BlockState state, CookingPanBlockEntity pan) {
        // Cooking state is evaluated when ingredients are added/stirred/served.
    }

    public void dropContents() {
        if (level == null || level.isClientSide()) return;
        for (int i = 0; i < inventory.getSlots(); i++) {
            final ItemStack stack = inventory.extractItem(i, inventory.getStackInSlot(i).getCount(), false);
            if (!stack.isEmpty()) Containers.dropItemStack(level, worldPosition.getX() + 0.5,
                worldPosition.getY() + 0.5, worldPosition.getZ() + 0.5, stack);
        }
        entries.clear();
        oilTank.setFluid(FluidStack.EMPTY);
    }

    @Override public int getSlotStackLimit(int slot) { return 1; }

    @Override public boolean isItemValid(int slot, ItemStack stack) {
        return FoodCapability.has(stack) && !FoodCapability.isRotten(stack);
    }

    @Override public IItemHandler getSidedInventory(Direction context) { return automationView; }

    @Override public void saveAdditional(CompoundTag tag, HolderLookup.Provider registries) {
        super.saveAdditional(tag, registries);
        final ListTag list = new ListTag();
        for (final PanCookingEntry entry : entries) list.add(entry.save());
        tag.put("entries", list);
        tag.put("oil", oilTank.writeToNBT(registries, new CompoundTag()));
    }

    @Override public void loadAdditional(CompoundTag tag, HolderLookup.Provider registries) {
        super.loadAdditional(tag, registries);
        entries.clear();
        final ListTag list = tag.getList("entries", Tag.TAG_COMPOUND);
        for (int i = 0; i < list.size(); i++) entries.add(PanCookingEntry.load(list.getCompound(i)));
        if (tag.contains("oil")) oilTank.readFromNBT(registries, tag.getCompound("oil"));
    }

    private void sync() {
        setChanged();
        if (level != null && !level.isClientSide()) {
            final BlockState state = getBlockState();
            level.sendBlockUpdated(worldPosition, state, state, Block.UPDATE_CLIENTS);
        }
    }
}
