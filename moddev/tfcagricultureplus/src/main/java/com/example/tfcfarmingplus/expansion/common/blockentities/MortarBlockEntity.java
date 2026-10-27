package com.example.tfcfarmingplus.expansion.common.blockentities;

import com.example.tfcfarmingplus.expansion.common.MyBlockEntities;
import net.minecraft.core.BlockPos;
import net.minecraft.core.HolderLookup;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.level.block.state.BlockState;
import net.dries007.tfc.common.blockentities.InventoryBlockEntity;
import net.neoforged.neoforge.items.ItemStackHandler;

/**
 * 🆕 <b>石臼的方块实体</b> —— 参考 <b>Firmalife 的 {@code MixingBowlBlockEntity}</b> 的"容器"语义。
 *
 * <p>用户口径：「**石臼的实现参考搅拌碗（firmalife）**，只不过**石杵会消耗耐久**」
 *
 * <h2>与 Firmalife 搅拌碗的对照</h2>
 * <table border="1">
 *   <tr><th></th><th>Firmalife 搅拌碗</th><th>本模组石臼</th></tr>
 *   <tr><td>容器</td><td>物品 + 流体（多输入）</td><td><b>1 格物品</b>（v1 只做干磨，不接流体）</td></tr>
 *   <tr><td>触发</td><td>GUI 里放入材料</td><td><b>右键</b>：手持食材放入 · 手持石杵研磨</td></tr>
 *   <tr><td>消耗</td><td>材料被配方消耗</td><td>材料被配方消耗 + <b>石杵消耗耐久</b>（用户口径）</td></tr>
 *   <tr><td>配方类型</td><td>{@code firmalife:mixing_bowl}</td><td>{@code tfcagricultureplus:mortar}（已建，见 {@code MortarRecipe}）</td></tr>
 * </table>
 *
 * <p>🛑 <b>性能</b>：**不 tick** · 不做任何循环扫描 ⇒ 空闲零开销。
 */
public class MortarBlockEntity extends InventoryBlockEntity<ItemStackHandler> {

    /** 石臼内部只放 1 格（= 一次研磨的量）。 */
    public static final int SLOTS = 1;

    private int grindProgress;

    public MortarBlockEntity(BlockPos pos, BlockState state) {
        super(MyBlockEntities.MORTAR.get(), pos, state, InventoryBlockEntity.defaultInventory(SLOTS),
            com.example.tfcfarmingplus.expansion.TFCAgriculturePlus.MOD_ID);
    }

    public ItemStack getContent() {
        return inventory.getStackInSlot(0);
    }

    public boolean isEmpty() {
        return inventory.getStackInSlot(0).isEmpty();
    }

    /** 放入（只在空的时候成功）。 */
    public boolean insert(ItemStack stack) {
        if (!inventory.getStackInSlot(0).isEmpty()) {
            return false;
        }
        if (!inventory.insertItem(0, stack.copyWithCount(1), false).isEmpty()) return false;
        grindProgress = 0;
        markForSync();
        return true;
    }

    /** 取出。 */
    public ItemStack extract() {
        final ItemStack out = inventory.extractItem(0, inventory.getStackInSlot(0).getCount(), false);
        grindProgress = 0;
        markForSync();
        return out;
    }

    /** 研磨成功后消耗内容物。 */
    public void consumeContent() {
        inventory.setStackInSlot(0, ItemStack.EMPTY);
        grindProgress = 0;
        markForSync();
    }

    public int getGrindProgress() {
        return grindProgress;
    }

    /** Count one deliberate pestle strike; returns true when the recipe is complete. */
    public boolean advanceGrinding(int requiredStrikes) {
        if (requiredStrikes < 1) {
            throw new IllegalArgumentException("requiredStrikes must be at least 1");
        }
        grindProgress = Math.min(requiredStrikes, grindProgress + 1);
        markForSync();
        return grindProgress >= requiredStrikes;
    }

    @Override
    public void saveAdditional(CompoundTag tag, HolderLookup.Provider registries) {
        super.saveAdditional(tag, registries);
        
        tag.putInt("grind_progress", grindProgress);
    }

    @Override
    public void loadAdditional(CompoundTag tag, HolderLookup.Provider registries) {
        super.loadAdditional(tag, registries);
        if (inventory.getStackInSlot(0).isEmpty() && tag.contains("content")) {
            ItemStack.parse(registries, tag.getCompound("content"))
                .ifPresent(stack -> inventory.setStackInSlot(0, stack));
        }
        grindProgress = inventory.getStackInSlot(0).isEmpty() ? 0 : Math.max(0, tag.getInt("grind_progress"));
    }

    @Override public int getSlotStackLimit(int slot) { return 1; }

    @Override public boolean isItemValid(int slot, ItemStack stack) {
        return slot == 0 && !stack.isEmpty();
    }

}
