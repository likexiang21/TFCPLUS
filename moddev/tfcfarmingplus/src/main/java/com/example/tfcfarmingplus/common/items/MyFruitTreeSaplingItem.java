package com.example.tfcfarmingplus.common.items;

import net.dries007.tfc.common.blocks.plant.fruit.Lifecycle;
import net.dries007.tfc.common.items.PlantableInfo;
import net.dries007.tfc.util.climate.ClimateRange;
import net.minecraft.world.item.BlockItem;
import net.minecraft.world.item.Item;
import net.minecraft.world.level.block.Block;
import org.jetbrains.annotations.Nullable;

import java.util.List;
import java.util.function.LongSupplier;
import java.util.function.Supplier;

/**
 * 果树树苗的方块物品 —— <b>实现 TFC 的 {@link PlantableInfo} 接口</b>。
 *
 * <h2>为什么必须有这个类</h2>
 * TFC 本体给果树树苗用的物品是它自己的**包级私有**类 {@code FruitBlocks.FruitTreeSaplingItem}
 * （实测 {@code class FruitTreeSaplingItem extends BlockItem implements PlantableInfo}，
 * 没有 {@code public} 修饰符），所以外部模组**无法直接 new 它**，只能照它自己写一个。
 *
 * <p>它比灌木物品多一项：<b>生长时间</b>。TFC 的树苗提示（按住 Shift）长这样：
 * <pre>
 * 气候：
 *   温度： -14°C - 28°C
 *   湿度： 20% - 90%
 *
 * 生命周期：
 *   可种植： 初春
 *   开始结果： 盛夏
 *
 * 生长时间： 8 天
 * </pre>
 *
 * <p>本模组此前给树苗用的是普通 {@code BlockItem}，于是这三段**全部缺失**，物品提示与 TFC 本体不一致。
 *
 * <h2>单位说明</h2>
 * {@link #getGrowthTimeInfo()} 返回 tick。TFC 的提示系统负责按当前日历显示时长，
 * 这里不能预先换成天数。供应器读取实际树苗的配置后阈值，避免提示与生长判定脱节。
 *
 * @see MyBushBlockItem 浆果灌木的同款物品
 */
public class MyFruitTreeSaplingItem extends BlockItem implements PlantableInfo {

    private final Supplier<ClimateRange> climateRange;
    private final Lifecycle[] lifecycle;
    private final LongSupplier ticksToGrow;

    public MyFruitTreeSaplingItem(Block block, Supplier<ClimateRange> climateRange,
                                  Lifecycle[] lifecycle, LongSupplier ticksToGrow) {
        super(block, new Item.Properties());
        this.climateRange = climateRange;
        this.lifecycle = lifecycle;
        this.ticksToGrow = ticksToGrow;
    }

    /** 气候段：温度范围 + 湿度范围（数据未加载时返回 null，提示里就不显示这一段） */
    @Override
    @Nullable
    public ClimateRange getClimateRangeInfo() {
        try {
            return climateRange.get();
        } catch (Throwable t) {
            return null;
        }
    }

    /** 生命周期段。「可种植」/「开始结果」两行由 TFC 从这 12 个月的数组自动推算 */
    @Override
    @Nullable
    public List<Lifecycle> getLifecycleInfo() {
        return List.of(lifecycle);
    }

    /** 生长时间（tick）；非正值隐藏，过大的配置值限制到接口可表示的上限。 */
    @Override
    public int getGrowthTimeInfo() {
        try {
            final long ticks = ticksToGrow.getAsLong();
            return ticks <= 0L ? -1 : (int) Math.min(ticks, Integer.MAX_VALUE);
        } catch (Throwable t) {
            return -1;
        }
    }
}
