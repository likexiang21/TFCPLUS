package io.github.likexiang21.tfcplus.agriculture.common.blockentity;

import io.github.likexiang21.tfcplus.agriculture.TFCAgriculturePlus;
import io.github.likexiang21.tfcplus.agriculture.common.registry.AgricultureBlockEntities;
import io.github.likexiang21.tfcplus.agriculture.common.registry.AgricultureBlocks;
import io.github.likexiang21.tfcplus.agriculture.common.registry.AgricultureItems;
import net.dries007.tfc.common.blockentities.InventoryBlockEntity;
import net.dries007.tfc.common.component.food.FoodCapability;
import net.minecraft.core.BlockPos;
import net.minecraft.core.HolderLookup;
import net.minecraft.core.registries.BuiltInRegistries;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.world.Containers;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.level.block.state.BlockState;
import net.neoforged.neoforge.items.ItemStackHandler;

/** Stores remaining servings in a TFC inventory block entity. */
public final class PlaceableFoodBlockEntity extends InventoryBlockEntity<ItemStackHandler> {
    private static final int PIE_SERVINGS = 8;
    private static final int CREAM_CAKE_SERVINGS = 6;
    private static final int CHOCOLATE_CAKE_SERVINGS = 6;
    private static final int CHEESE_SERVINGS = 6;
    private static final int BUTTER_SERVINGS = 6;
    private static final int JELLY_SERVINGS = 6;
    private static final int SUGAR_SERVINGS = 8;
    private int servings;
    // Food metadata only: never exposed through the automation inventory or dropped as a second whole pie.
    private ItemStack pieFood = ItemStack.EMPTY;
    public PlaceableFoodBlockEntity(BlockPos pos, BlockState state) {
        super(AgricultureBlockEntities.PLACEABLE_FOOD.get(), pos, state, defaultInventory(1), TFCAgriculturePlus.MOD_ID);
        servings = maxServings();
        // Keep the TFC inventory contract, but do not mutate it during construction.
        // InventoryBlockEntity synchronizes changes immediately; before the BE is attached
        // to a level that path dereferences a null level while the block is being placed.
    }
    private boolean isPie() { return getBlockState().is(AgricultureBlocks.WHOLE_PIE.get()); }
    public void setPieFood(ItemStack source) {
        if (level == null || level.isClientSide() || !isPie() || !source.is(AgricultureBlocks.WHOLE_PIE.get().asItem())) return;
        pieFood = source.copyWithCount(1);
        setChanged();
    }
    @Override protected void onLoadAdditional() {
        super.onLoadAdditional();
        if (level != null && !level.isClientSide()) ensurePieFood();
    }
    private void ensurePieFood() {
        if (isPie() && pieFood.isEmpty() && servings > 0) {
            // Old placed pies have no historical date. Initialize once, then persist it.
            pieFood = FoodCapability.setCreatedNow(new ItemStack(AgricultureBlocks.WHOLE_PIE.get()));
            setChanged();
        }
    }
    private ItemStack newServing() {
        ItemStack slice = new ItemStack(servingItem());
        if (isPie()) {
            ensurePieFood();
            FoodCapability.updateFoodFromPrevious(pieFood, slice);
        }
        return slice;
    }
    private boolean isCreamCake() { return getBlockState().is(AgricultureBlocks.CREAM_CAKE.get()); }
    private boolean isChocolateCake() { return getBlockState().is(AgricultureBlocks.CHOCOLATE_CAKE.get()); }
    private boolean isCheese() { return getBlockState().is(AgricultureBlocks.WHOLE_CHEESE.get()); }
    private boolean isButter() { return getBlockState().is(AgricultureBlocks.BUTTER_BLOCK.get()); }
    private boolean isJelly() { return getBlockState().is(AgricultureBlocks.JELLY_BLOCK.get()); }
    private boolean isSugar() { return getBlockState().is(AgricultureBlocks.SUGAR_BLOCK.get()); }
    private int maxServings() { return isCreamCake() ? CREAM_CAKE_SERVINGS : isChocolateCake() ? CHOCOLATE_CAKE_SERVINGS : isCheese() ? CHEESE_SERVINGS : isButter() ? BUTTER_SERVINGS : isJelly() ? JELLY_SERVINGS : isSugar() ? SUGAR_SERVINGS : PIE_SERVINGS; }
    private net.minecraft.world.item.Item servingItem() { return isCreamCake() ? AgricultureItems.CREAM_CAKE_SLICE.get() : isChocolateCake() ? AgricultureItems.CHOCOLATE_CAKE_SLICE.get() : isCheese() ? AgricultureItems.CHEESE_SLICE.get() : isButter() ? firmalifeButter() : isJelly() ? AgricultureItems.JELLY_SLICE.get() : isSugar() ? AgricultureItems.SUGAR_PIECE.get() : AgricultureItems.PIE_SLICE.get(); }
    private net.minecraft.world.item.Item firmalifeButter() {
        return BuiltInRegistries.ITEM.get(ResourceLocation.parse("firmalife:food/butter"));
    }
    public boolean takeServing(Player player) {
        if (level == null || level.isClientSide() || servings <= 0) return false;
        if (isPie()) {
            ensurePieFood();
            if (FoodCapability.isRotten(pieFood)) return false;
        }
        final ItemStack slice = newServing();
        if (!player.getInventory().add(slice)) player.drop(slice, false);
        servings--; setChanged();
        if (servings == 0) level.removeBlock(worldPosition, false);
        return true;
    }
    public void dropContents() {
        if (level == null || level.isClientSide()) return;
        for (int i = 0; i < servings; i++) Containers.dropItemStack(level, worldPosition.getX()+0.5, worldPosition.getY()+0.5, worldPosition.getZ()+0.5, newServing());
        servings = 0;
        pieFood = ItemStack.EMPTY;
        setChanged();
    }
    @Override public int getSlotStackLimit(int slot) { return 1; }
    @Override public boolean isItemValid(int slot, ItemStack stack) { return false; }
    @Override public void saveAdditional(CompoundTag tag, HolderLookup.Provider registries) { super.saveAdditional(tag, registries); tag.putInt("servings", servings); if (!pieFood.isEmpty()) tag.put("pie_food", pieFood.save(registries)); }
    @Override public void loadAdditional(CompoundTag tag, HolderLookup.Provider registries) { super.loadAdditional(tag, registries); servings = Math.max(0, Math.min(maxServings(), tag.getInt("servings"))); if (!tag.contains("servings")) servings = maxServings();
        pieFood = ItemStack.parseOptional(registries, tag.getCompound("pie_food"));
        if (!isPie() || !pieFood.is(AgricultureBlocks.WHOLE_PIE.get().asItem())) pieFood = ItemStack.EMPTY;
    }
}
