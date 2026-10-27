package com.example.tfcfarmingplus.expansion.common.blockentities;

import com.example.tfcfarmingplus.expansion.common.MyBlockEntities;
import com.example.tfcfarmingplus.expansion.common.MyTags;
import net.minecraft.core.BlockPos;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.level.block.state.BlockState;
import net.dries007.tfc.common.blockentities.InventoryBlockEntity;
import net.neoforged.neoforge.items.ItemStackHandler;

/** Project rack policy: first vacant slot receives one allowed item; retrieval uses the highest occupied slot.
 * NeoForge owns item-handler persistence. Source comparison and fixed contracts: docs/131. */
public class KnifeBlockBlockEntity extends InventoryBlockEntity<ItemStackHandler> {

    /** 🆕 格数 —— **4**，与 TFC 的工具架一致（原为 9）。 */
    public static final int SLOTS = 4;

    public KnifeBlockBlockEntity(BlockPos pos, BlockState state) {
        super(MyBlockEntities.KNIFE_BLOCK.get(), pos, state, defaultInventory(SLOTS),
            com.example.tfcfarmingplus.expansion.TFCAgriculturePlus.MOD_ID);
    }

    // ------------------------------------------------------------------
    // ⭐ 白名单（使用本模块白名单）
    // ------------------------------------------------------------------

    /** Accept only the project's rack item tag. */
    public boolean isItemValid(ItemStack stack) {
        return !stack.isEmpty() && stack.is(MyTags.Items.USABLE_ON_KNIFE_BLOCK);
    }

    @Override public int getSlotStackLimit(int slot) { return 1; }
    @Override public boolean isItemValid(int slot, ItemStack stack) { return isItemValid(stack); }

    // ------------------------------------------------------------------
    // 存取
    // ------------------------------------------------------------------

    /** 存一件（**只接受白名单物品**；返回是否成功）。 */
    public boolean store(ItemStack stack) {
        if (!isItemValid(stack)) {
            return false;
        }
        for (int i = 0; i < SLOTS; i++) {
            if (inventory.getStackInSlot(i).isEmpty()) {
                inventory.insertItem(i, stack.copyWithCount(1), false);
                return true;
            }
        }
        return false;
    }

    /** 取最后放入的一件。 */
    public ItemStack takeLast() {
        for (int i = SLOTS - 1; i >= 0; i--) {
            final ItemStack s = inventory.getStackInSlot(i);
            if (!s.isEmpty()) {
                return inventory.extractItem(i, 1, false);
            }
        }
        return ItemStack.EMPTY;
    }

    public boolean isEmpty() {
        for (int i = 0; i < SLOTS; i++) {
            if (!inventory.getStackInSlot(i).isEmpty()) {
                return false;
            }
        }
        return true;
    }

}
