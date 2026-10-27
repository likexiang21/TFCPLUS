package com.example.tfcfarmingplus.common.blocks;

import net.dries007.tfc.common.blockentities.CropBlockEntity;
import net.dries007.tfc.common.blocks.ExtendedProperties;
import net.dries007.tfc.common.blocks.TFCBlockStateProperties;
import net.dries007.tfc.common.blocks.crop.CropBlock;
import net.dries007.tfc.common.blocks.crop.DeadCropBlock;
import net.dries007.tfc.util.climate.ClimateRange;
import net.minecraft.core.BlockPos;
import net.minecraft.world.item.Item;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.properties.IntegerProperty;

import java.util.function.Supplier;

/**
 * 单格作物（自有实现）。
 * <p>
 * 为什么必须写子类：TFC 的 {@code DefaultCropBlock.create(props, stages, Crop)} 等工厂都要求
 * TFC 私有的 {@code Crop} 枚举，而 {@code CropBlock} 的构造器是 protected（对子类可见）。
 * <p>
 * 生长速率由 TFC 的 {@code CropHelpers} 全局统一（约 24 天），{@code maxAge} 只决定视觉阶段数。
 *
 * <h2>⚠️ 为什么 age 属性必须由匿名子类捕获，而不能存成实例字段</h2>
 * 原版 {@code Block} 的构造器末尾会调用虚方法 {@code createBlockStateDefinition(...)}，
 * 而 TFC 的 {@code CropBlock.createBlockStateDefinition} 正是调 {@link #getAgeProperty()}。
 * 也就是说：<b>{@code getAgeProperty()} 会在子类构造器自己的字段赋值语句被执行之前就被调用</b>
 * （Java 里 {@code super(...)} 必须第一行，字段初始化只能发生在其后）。
 * 若实现成 {@code return ageProperty;} 这种实例字段读取，那一刻字段仍是 {@code null}，
 * 于是 {@code StateDefinition.Builder.add(null)} 直接抛
 * {@code NullPointerException: ... because "p_61100_" is null}，整个模组在注册阶段崩溃
 * （实测于 2026-09-19 的首次进游戏验证）。
 * <p>
 * 正确做法（TFC 自己也这么做）见 {@link #create}：<b>先把属性算好存进 final 局部变量，
 * 再交给匿名子类捕获</b> —— javac 为匿名类生成的合成字段会在 {@code super(...)} 之前完成赋值，
 * 因此构造期回调能读到正确的属性。
 *
 * @see com.example.tfcfarmingplus.common.MyCrops 用法示例
 */
public abstract class MyCropBlock extends CropBlock {

    protected MyCropBlock(ExtendedProperties properties, int maxAge,
                          Supplier<? extends Block> dead, Supplier<? extends Item> seeds,
                          float nitrogen, float phosphorous, float potassium,
                          Supplier<ClimateRange> climateRange) {
        super(properties, maxAge, dead, seeds, nitrogen, phosphorous, potassium, climateRange);
    }

    /**
     * 唯一的创建入口。
     *
     * @param maxAge 最大年龄值（如 5 表示 age 0~5，共 6 个视觉阶段）
     */
    public static MyCropBlock create(ExtendedProperties properties, int maxAge,
                                     Supplier<? extends Block> dead, Supplier<? extends Item> seeds,
                                     float nitrogen, float phosphorous, float potassium,
                                     Supplier<ClimateRange> climateRange) {
        // ⚠️ 这一行必须在 new 之前：它会被匿名类捕获为合成字段，从而在构造期立即可用
        final IntegerProperty property = TFCBlockStateProperties.getAgeProperty(maxAge);
        return new MyCropBlock(properties, maxAge, dead, seeds, nitrogen, phosphorous, potassium, climateRange) {
            @Override
            public IntegerProperty getAgeProperty() {
                return property;
            }
        };
    }

    /** 把方块实体里的 growth 同步到 BlockState 的 age 上 */
    @Override
    protected void postGrowthTick(Level level, BlockPos pos, BlockState state, CropBlockEntity crop) {
        final int age = crop.getGrowth() == 1.0f ? getMaxAge() : (int) (crop.getGrowth() * getMaxAge());
        level.setBlockAndUpdate(pos, state.setValue(getAgeProperty(), age));
    }

    /**
     * 气候不适宜或过期时变成**该作物自己的**枯萎方块（{@code tfcfarmingplus:dead_crop/<name>}）。
     * <p>
     * 照 TFC 的做法：每种作物一个死株方块，死株被打掉时由**它自己的掉落表**掉回对应种子
     * （见 {@code data/tfcfarmingplus/loot_table/blocks/dead_crop/<name>.json}）。
     * 因此这里不再需要「把种子直接还回地面」那种兜底写法。
     */
    @Override
    public void die(Level level, BlockPos pos, BlockState state, boolean fullyGrown) {
        level.setBlockAndUpdate(pos, dead.get().defaultBlockState()
            .setValue(DeadCropBlock.MATURE, fullyGrown));
    }
}
