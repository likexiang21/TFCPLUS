package com.example.tfcfarmingplus.common.items;

import net.dries007.tfc.common.blocks.plant.fruit.Lifecycle;
import net.dries007.tfc.common.items.PlantableInfo;
import net.dries007.tfc.util.climate.ClimateRange;
import net.minecraft.world.item.BlockItem;
import net.minecraft.world.item.Item;
import net.minecraft.world.level.block.Block;
import org.jetbrains.annotations.Nullable;

import java.util.List;
import java.util.function.Supplier;

/**
 * 浆果灌木的方块物品 —— <b>实现 TFC 的 {@link PlantableInfo} 接口</b>。
 *
 * <h2>为什么必须有这个类</h2>
 * TFC 本体给浆果灌木用的物品是它自己的私有类 {@code FruitBlocks.BushBlockItem}，
 * 它实现了 {@link PlantableInfo}。而 {@code PlantableInfo.addTooltipInfo} 会在
 * {@code ClientForgeEventHandler.onItemTooltip} 里被调用，于是**按住 Shift 时**物品提示会多出两段：
 *
 * <pre>
 * 气候：
 *   温度： -3°C - 19°C
 *   湿度： 11% - 90%
 *
 * 生命周期：
 *   可种植： 仲秋
 *   开始结果： 初春
 * </pre>
 *
 * 本模组此前直接用普通 {@code BlockItem}，所以这两段完全缺失 —— 物品提示与 TFC 本体长得不一样。
 * 照 TFC 的写法实现本接口后，这两段由 **TFC 自己的代码**生成（含温度单位配置、
 * 季节名本地化、缩进等全部细节），因此格式与本体逐字一致。
 *
 * 「可种植」/「开始结果」两行是由 {@code Lifecycle[]} 自动推算出来的：
 * TFC 从 12 月往前扫，找出 {@code HEALTHY} 与 {@code FRUITING} 各自的起始月份。
 * 所以只要这里返回真实的物候数组，提示就会与灌木实际行为一致。
 */
public class MyBushBlockItem extends BlockItem implements PlantableInfo {

    private final Supplier<ClimateRange> climateRange;
    private final Lifecycle[] lifecycle;

    public MyBushBlockItem(Block block, Supplier<ClimateRange> climateRange, Lifecycle[] lifecycle) {
        super(block, new Item.Properties());
        this.climateRange = climateRange;
        this.lifecycle = lifecycle;
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

    /**
     * 生命周期段。索引 0 = 1 月，与 {@code MyBushes} 里写的 12 月数组顺序一致
     * （TFC 的 {@code Month} 枚举也是 JANUARY=0）。
     */
    @Override
    @Nullable
    public List<Lifecycle> getLifecycleInfo() {
        return List.of(lifecycle);
    }

    // 灌木不消耗养分，也不显示「生长速度」—— 与 TFC 的 BushBlockItem 一致（两者都不覆写）
}
