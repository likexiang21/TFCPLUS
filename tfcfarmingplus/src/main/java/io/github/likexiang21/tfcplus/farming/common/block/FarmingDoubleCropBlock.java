package io.github.likexiang21.tfcplus.farming.common.block;

import java.util.function.Supplier;
import net.dries007.tfc.common.blocks.ExtendedProperties;
import net.dries007.tfc.common.blocks.TFCBlockStateProperties;
import net.dries007.tfc.common.blocks.crop.DoubleCropBlock;
import net.dries007.tfc.util.climate.ClimateRange;
import net.minecraft.world.item.Item;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.state.properties.IntegerProperty;

/**
 * 双格作物（自有实现）—— 高秆作物专用，占**上下两格**。
 * <p>
 * 现实里栽培高度常态超过 1 米的作物（高粱、苋米、珍珠粟、棉花、洋姜……）用单格表现会明显失真，
 * 因此走 TFC 的 {@link DoubleCropBlock}：前几个 age 是矮的单格苗，之后长成「下格 + 上格」两段。
 *
 * <h2>为什么写子类</h2>
 * 与 {@link FarmingCropBlock} 同理：TFC 的 {@code DoubleCropBlock.create(...)} 要求 TFC 私有的
 * {@code Crop} 枚举，而它的构造器是 protected（对子类可见），所以只能自己包一层。
 *
 * <h2>⚠️ age 属性必须由匿名子类捕获</h2>
 * 原版 {@code Block} 的构造器末尾会调用虚方法 {@code createBlockStateDefinition(...)}，
 * TFC 的实现在其中调用 {@code getAgeProperty()}。也就是说：这个方法会在子类自己的字段赋值
 * **之前**就被调用。若实现成读取实例字段，那一刻字段还是 {@code null}，
 * 会抛 {@code NullPointerException: ... "p_61100_" is null} 让模组在注册阶段崩溃。
 * 正确做法见 {@link #create}：先把属性算好放进 final 局部变量，再交给匿名类捕获。
 *
 * <h2>为什么不覆盖 die() / postGrowthTick()</h2>
 * 父类 {@code DoubleCropBlock} 自己维护「上下两格同步」的逻辑（生长时补上格、被破坏时连带移除、
 * 枯萎时按成熟度处理上下格），这些细节**必须交给父类**。我们只负责把 age 属性接上，
 * 任何行为方法的覆盖都可能破坏双格状态的一致性。
 *
 * @see io.github.likexiang21.tfcplus.farming.common.crop.FarmingCrops 用法示例
 */
public abstract class FarmingDoubleCropBlock extends DoubleCropBlock {

    protected FarmingDoubleCropBlock(ExtendedProperties properties, int maxSingleAge, int maxAge,
                                Supplier<? extends Block> dead, Supplier<? extends Item> seeds,
                                float nitrogen, float phosphorous, float potassium,
                                Supplier<ClimateRange> climateRange) {
        super(properties, maxSingleAge, maxAge, dead, seeds,
            nitrogen, phosphorous, potassium, climateRange);
    }

    /**
     * 唯一的创建入口。
     *
     * @param singleStages 还能用单格模型表示的最后一个 age + 1，例如 3 表示 age 0~2 是单格苗、
     *                     age 3~maxAge 是「下格 + 上格」（与 TFC 的玉米一致）
     * @param maxAge       最大年龄值（如 5 表示 age 0~5）
     */
    public static FarmingDoubleCropBlock create(ExtendedProperties properties, int singleStages, int maxAge,
                                           Supplier<? extends Block> dead, Supplier<? extends Item> seeds,
                                           float nitrogen, float phosphorous, float potassium,
                                           Supplier<ClimateRange> climateRange) {
        // ⚠️ 这一行必须在 new 之前：它会被匿名类捕获为合成字段，从而在构造期立即可用
        if (singleStages < 2 || singleStages > maxAge) {
            throw new IllegalArgumentException("Invalid single-stage count: " + singleStages);
        }
        final IntegerProperty property = TFCBlockStateProperties.getAgeProperty(maxAge);
        return new FarmingDoubleCropBlock(properties, singleStages - 1, maxAge, dead, seeds,
            nitrogen, phosphorous, potassium, climateRange) {
            @Override
            public IntegerProperty getAgeProperty() {
                return property;
            }
        };
    }
}
