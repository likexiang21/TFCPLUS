package io.github.likexiang21.tfcplus.agriculture.common.blockentity;

import io.github.likexiang21.tfcplus.agriculture.common.block.LogCuttingBoardBlock;
import io.github.likexiang21.tfcplus.agriculture.TFCAgriculturePlus;
import io.github.likexiang21.tfcplus.agriculture.common.registry.AgricultureBlockEntities;
import io.github.likexiang21.tfcplus.agriculture.common.registry.AgricultureBlocks;
import net.dries007.tfc.common.blockentities.InventoryBlockEntity;
import net.minecraft.core.BlockPos;
import net.minecraft.core.HolderLookup;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.level.block.state.BlockState;
import net.neoforged.neoforge.items.ItemStackHandler;

/**
 * 🆕 <b>案板的方块实体</b> —— 只做一件事：<b>记耐久</b>。
 *
 * <p>用户口径：「**案板要设计耐久特性**」+「案板的主要功能是**切割和分片食材**，
 * 其次也能**处理原木或者分解石砖块**」
 *
 * <h2>耐久设计</h2>
 * <ul>
 *   <li>{@link #MAX_USES} = <b>128 次</b>加工 —— 木案板与石案板同一个数值（v1 不细分）</li>
 *   <li>每次**成功加工**（切割 / 处理原木 / 分解石砖）扣 1</li>
 *   <li>扣到 0 ⇒ **方块消失**（掉落一个"用坏的案板"？v1 先直接消失并发出破坏音）</li>
 *   <li>⚠️ 耐久**只记在 BE 里**（不占 blockstate 属性）—— 避免状态数爆炸（§7.2.4 的 ≤8 红线）</li>
 * </ul>
 *
 * <p>🛑 <b>性能</b>（126 §3.4）：**不 tick**（不实现 {@code serverTick}）⇒ 空闲零开销。
 */
public class CuttingBoardBlockEntity extends InventoryBlockEntity<ItemStackHandler> {

    /** 最大使用次数（= 耐久）。 */
    public static final int MAX_USES = 128;

    private int usesLeft = MAX_USES;
    private int pressCount;
    private int kneadCount;

    /**
     * 🆕 <b>案板上放着的物品</b>（1 格）—— 用户口径：
     * 「砧板交互也要保证**物品的可见性**，而且是**直接渲染**不是绘画或者建模」。
     *
     * <p>⇒ 案板需要一个**可见的承载格**，才能渲染出"摊在板上待切的食材"。
     */
    public CuttingBoardBlockEntity(BlockPos pos, BlockState state) {
        this(state.getBlock() instanceof io.github.likexiang21.tfcplus.agriculture.common.block.LogCuttingBoardBlock
            ? AgricultureBlockEntities.LOG_CUTTING_BOARD.get() : AgricultureBlockEntities.CUTTING_BOARD.get(), pos, state);
    }

    /**
     * 🆕 <b>可指定 BE 类型的构造器</b> —— 原木案板用的是**另一个 BE 类型**
     * （{@code log_cutting_board}），必须走这个构造器。
     *
     * <p>🛑 <b>本轮实测的真实 bug</b>：{@code LogCuttingBoardBlock.newBlockEntity} 一开始
     * 返回了"用 {@code CUTTING_BOARD} 类型构造的"BE ⇒ 放下去立刻崩：
     * {@code IllegalStateException: Invalid block entity tfcagricultureplus:cutting_board}
     * （堆栈直指 {@code BlockEntity.validateBlockState}）。
     * <p>⇒ 与 TFC 的 {@code PlacedItemBlockEntity} 同一个模式：**基类持有类型参数**。
     */
    public CuttingBoardBlockEntity(net.minecraft.world.level.block.entity.BlockEntityType<?> type,
                                   BlockPos pos, BlockState state) {
        super(type, pos, state, InventoryBlockEntity.defaultInventory(1),
            io.github.likexiang21.tfcplus.agriculture.TFCAgriculturePlus.MOD_ID);
    }

    // ---------------- 🆕 板面物品 ----------------

    public ItemStack getOnBoard() {
        return inventory.getStackInSlot(0);
    }

    public boolean isBoardEmpty() {
        return inventory.getStackInSlot(0).isEmpty();
    }

    /** 放到板上（只在空时成功）。 */
    public boolean placeOnBoard(ItemStack stack) {
        if (!inventory.getStackInSlot(0).isEmpty()) {
            return false;
        }
        final boolean placed = inventory.insertItem(0, stack.copyWithCount(1), false).isEmpty();
        if (placed) clearDoughProgress();
        return placed;
    }

    public void setOnBoard(ItemStack stack) {
        inventory.setStackInSlot(0, stack.copy());
        clearDoughProgress();
    }

    /** 从板上取走。 */
    public ItemStack takeFromBoard() {
        final ItemStack result = inventory.extractItem(0, inventory.getStackInSlot(0).getCount(), false);
        if (!result.isEmpty()) clearDoughProgress();
        return result;
    }

    public int getPressCount() { return pressCount; }

    public int getKneadCount() { return kneadCount; }

    public boolean isDoughProcessing() {
        final ItemStack stack = getOnBoard();
        if (stack.isEmpty()) return false;
        final String id = net.minecraft.core.registries.BuiltInRegistries.ITEM.getKey(stack.getItem()).toString();
        return id.equals("tfcagricultureplus:food/cake_dough")
            || (id.endsWith(":food/wheat_dough") || id.endsWith(":food/oat_dough")
                || id.endsWith(":food/barley_dough") || id.endsWith(":food/maize_dough")
                || id.endsWith(":food/rye_dough") || id.endsWith(":food/rice_dough"));
    }

    public void incrementPress() {
        if (isDoughProcessing()) {
            pressCount = Math.min(16, pressCount + 1);
            markForSync();
        }
    }

    public void incrementKnead() {
        if (isDoughProcessing()) {
            kneadCount = Math.min(16, kneadCount + 1);
            markForSync();
        }
    }

    public void clearDoughProgress() {
        if (pressCount != 0 || kneadCount != 0) {
            pressCount = 0;
            kneadCount = 0;
            markForSync();
        }
    }

    public int getUsesLeft() {
        return usesLeft;
    }

    /** 还剩多少比例（0~1），供将来的 UI / 贴图变化用。 */
    public float wearRatio() {
        return (float) usesLeft / (float) MAX_USES;
    }

    /**
     * 消耗一次耐久。
     *
     * @return {@code true} = 还能用；{@code false} = **这次用完就坏**
     */
    public boolean consume() {
        if (usesLeft > 0) {
            usesLeft--;
        }
        markForSync();
        return usesLeft > 0;
    }

    /** 修一下（v1 未接配方，先留接口）。 */
    public void repair() {
        usesLeft = MAX_USES;
        markForSync();
    }

    @Override
    public void saveAdditional(CompoundTag tag, HolderLookup.Provider registries) {
        super.saveAdditional(tag, registries);
        tag.putInt("uses_left", usesLeft);
        tag.putInt("press_count", pressCount);
        tag.putInt("knead_count", kneadCount);
    }

    @Override
    public void loadAdditional(CompoundTag tag, HolderLookup.Provider registries) {
        super.loadAdditional(tag, registries);
        if (tag.contains("uses_left")) {
            usesLeft = Math.clamp(tag.getInt("uses_left"), 0, MAX_USES);
        }
        pressCount = Math.clamp(tag.getInt("press_count"), 0, 16);
        kneadCount = Math.clamp(tag.getInt("knead_count"), 0, 16);
        // Migrate the pre-container field once; new saves are written by TFC InventoryBlockEntity.
        if (inventory.getStackInSlot(0).isEmpty() && tag.contains("on_board")) {
            ItemStack.parse(registries, tag.getCompound("on_board"))
                .ifPresent(stack -> inventory.setStackInSlot(0, stack));
        }
        if (!isDoughProcessing()) {
            pressCount = 0;
            kneadCount = 0;
        }
    }

    @Override public int getSlotStackLimit(int slot) { return 1; }

    @Override public boolean isItemValid(int slot, ItemStack stack) {
        return slot == 0 && !stack.isEmpty();
    }
}
