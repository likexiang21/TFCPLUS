package com.example.tfcfarmingplus.common.blocks;

import net.dries007.tfc.common.blockentities.BerryBushBlockEntity;
import net.dries007.tfc.common.TFCTags;
import net.dries007.tfc.common.blocks.plant.fruit.SpreadingCaneBlock;
import net.dries007.tfc.common.blockentities.TickCounterBlockEntity;
import net.minecraft.core.BlockPos;
import net.minecraft.world.ItemInteractionResult;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.state.BlockState;

/**
 * 季节性植物（浆果灌木 / 果树树叶 / 树干果实）的**计时补丁** ——
 * 补的是 TFC 里两句「按 TFC 类型查表」的静态 helper 在本模组自建 BE 上的失效。
 *
 * <h2>失效机制</h2>
 * 这类静态 helper 的内部一律是
 * <pre>
 * level.getBlockEntity(pos, TFCBlockEntities.XXX.get())
 * </pre>
 * —— 即**按 TFC 自己的 {@code BlockEntityType} 查找**。本模组的所有季节性植物都挂
 * {@link com.example.tfcfarmingplus.common.MyBlockEntities#BERRY_BUSH}
 * （1.21 的原版 {@code validateBlockState} 不允许借用 TFC 的类型），
 * 于是这些查找必然落空 → 静默变成空操作。
 *
 * <p>受影响的两句：
 * <table border="1">
 *   <tr><th>失效句</th><th>调用点</th><th>后果</th></tr>
 *   <tr><td>{@code BerryBushBlockEntity.resetPickedTick(level,pos)}</td>
 *       <td>{@code SeasonalPlantBlock.useItemOn}（采收成功时）</td>
 *       <td>{@code lastPickedTick} 停在哨兵值 → 采摘冷却失效</td></tr>
 *   <tr><td>{@code BerryBushBlockEntity.reset(level,pos)}</td>
 *       <td>{@code SeasonalPlantBlock.setPlacedBy}（放下方块时）</td>
 *       <td>{@code lastUpdateTick} 停在哨兵值 {@code -2147483648L} → 生长计时器从未被播种</td></tr>
 * </table>
 *
 * <h2>⚠️ 第二句曾被误判为「无影响」，实机证伪了</h2>
 * 早期版本的注释论证过：读 {@code getTicksSinceUpdate()} 的只有
 * {@code StationaryBerryBushBlock.tick}，而「全类没有任何 {@code scheduleTick} 调用者」。
 * <b>这个前提是错的</b> —— 反汇编 {@code StationaryBerryBushBlock.randomTick} 可以看到它
 * <b>直接调用</b> {@code tick(...)}，不需要任何 scheduled tick。于是：
 * <pre>
 * getTicksSinceUpdate() = Calendars.SERVER.getTicks() - (-2147483648L) ≈ 2.1e9
 * growths = min(sinceUpdate / berryBushGrowthTicks, 8) = 8
 * </pre>
 * 也就是**放下方块的第一次随机刻就直接长到满级 STAGE**，缓苗期完全消失。
 *
 * <p>实机证据（{@code /tfcfarmingplus probe}，2026 本轮）：
 * <pre>
 * probe … BE=BlockEntityType@…  lastUpdateTick=-2147483648 sinceUpdate=2148161268  &lt;-- 哨兵值
 * </pre>
 * 而 {@code TickCounterBlockEntity} 的构造器字节码确认它**只把字段置为哨兵值**
 * （{@code ldc2_w -2147483648L; putfield lastUpdateTick}），
 * 唯一播种方式是实例方法 {@code resetCounter()}（{@code lastUpdateTick = Calendars.SERVER.getTicks()}）。
 *
 * <h2>为什么用实例方法而不是补 TFC 的静态 helper</h2>
 * 静态 helper 写死了 TFC 的类型，补不了；实例方法走 {@code instanceof TickCounterBlockEntity}
 * （{@code BerryBushBlockEntity extends TickingPlantBlockEntity extends TickCounterBlockEntity}），
 * 对本模组的所有季节性植物一次性成立。
 *
 * @see MyFruitTreeSaplingBlock §5.13 里同源问题的完整推导
 */
public final class MySeasonalPlantFix {

    /**
     * 采收成功后补一次采摘计时重置。
     * <p>
     * 用 {@code consumesAction()} 兜住「真的摘到了」这一种结果 —— TFC 的 {@code useItemOn}
     * 在采收成功时返回 {@code ItemInteractionResult.sidedSuccess(isClientSide)}，
     * 其它情况返回 {@code PASS_TO_DEFAULT_BLOCK_INTERACTION}，两者恰好可区分。
     */
    public static ItemInteractionResult afterUse(Level level, BlockPos pos, ItemInteractionResult result) {
        if (!level.isClientSide() && result.consumesAction()
            && level.getBlockEntity(pos) instanceof BerryBushBlockEntity be) {
            be.resetLastPickedCounter();
        }
        return result;
    }

    /**
     * 放下方块后补一次生长计时器播种。
     * <p>
     * 必须由每个季节性植物方块在自己的 {@code setPlacedBy} 里调用
     * （父类那次调用走的是失效的静态 helper）。
     * 播种后 {@code getTicksSinceUpdate()} 从 0 开始累计，
     * 生长节奏才与 TFC 的 {@code berryBushGrowthTicks} 一致。
     */
    public static void afterPlace(Level level, BlockPos pos) {
        if (!level.isClientSide() && level.getBlockEntity(pos) instanceof TickCounterBlockEntity be) {
            be.resetCounter();
        }
    }

    /**
     * Initialize only missing ages; native propagation already transfers initialized counters.
     * This entry point is called only by the three project bush classes, never tree leaves.
     */
    public static void prepareBush(Level level, BlockPos pos) {
        if (level.isClientSide() || !(level.getBlockEntity(pos) instanceof BerryBushBlockEntity bush)) {
            return;
        }
        if (bush.getLastUpdateTick() == Integer.MIN_VALUE) {
            bush.resetCounter();
        }
        if (bush.getStemPos().equals(pos)) {
            final BlockPos root = findBushRoot(level, pos);
            if (root != null && !root.equals(pos)) {
                bush.setStemPos(root);
            }
        }
    }

    /** Follow only a matching cane support or the same species' vertical main stems. */
    private static BlockPos findBushRoot(Level level, BlockPos origin) {
        BlockPos cursor = origin;
        for (int depth = 0; depth < 32; depth++) {
            if (!level.isLoaded(cursor)) return null;
            final BlockState state = level.getBlockState(cursor);
            if (state.getBlock() instanceof MySpreadingCaneBlock cane) {
                final BlockPos support = cursor.relative(state.getValue(SpreadingCaneBlock.FACING).getOpposite());
                if (!level.isLoaded(support) || level.getBlockState(support).getBlock() != cane.getCane()) {
                    return null;
                }
                cursor = support;
            } else if (state.getBlock() instanceof MySpreadingBushBlock) {
                if (!cursor.equals(origin) && level.getBlockEntity(cursor) instanceof BerryBushBlockEntity source
                    && !source.getStemPos().equals(cursor)) {
                    return source.getStemPos();
                }
                final BlockPos below = cursor.below();
                if (!level.isLoaded(below)) return null;
                final BlockState support = level.getBlockState(below);
                if (support.is(TFCTags.Blocks.SPREADING_FRUIT_GROWS_ON)) return cursor;
                if (support.getBlock() != state.getBlock()) return null;
                cursor = below;
            } else {
                return null;
            }
        }
        return null;
    }

    private MySeasonalPlantFix() {}
}
