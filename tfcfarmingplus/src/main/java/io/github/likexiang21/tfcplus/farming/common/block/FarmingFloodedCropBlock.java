package io.github.likexiang21.tfcplus.farming.common.block;

import java.util.function.Supplier;
import net.dries007.tfc.common.blocks.ExtendedProperties;
import net.dries007.tfc.common.blocks.TFCBlockStateProperties;
import net.dries007.tfc.common.blocks.crop.FloodedCropBlock;
import net.dries007.tfc.util.climate.ClimateRange;
import net.minecraft.world.item.Item;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.state.properties.IntegerProperty;

/**
 * 水田作物（自有实现）—— 种在**积水**的农田上，即 TFC 的 {@code FloodedCropBlock}。
 * <p>
 * 适用对象：芋头、荸荠、菱角、茭白、莲藕、水芹、空心菜、慈菇、芡实、莼菜。
 * 与普通作物相比，多实现一个 {@code IFluidLoggable}：方块本身可以含水，
 * 因此播种位置必须预先有淡水水源，下方是耕地；无水状态的生长上限为 0。
 *
 * <h2>为什么写子类</h2>
 * 与 {@link FarmingCropBlock} 同理：TFC 的 {@code FloodedCropBlock.create(props, stages, Crop)} 要求
 * TFC 私有的 {@code Crop} 枚举，而它的构造器是 protected（对子类可见），所以只能自己包一层。
 *
 * <h2>⚠️ age 属性必须由匿名子类捕获</h2>
 * 原版 {@code Block} 的构造器末尾会调用虚方法 {@code createBlockStateDefinition(...)}，
 * TFC 的实现会在其中调用 {@code getAgeProperty()}。也就是说：这个方法会在子类自己的字段赋值
 * **之前**就被调用，读实例字段会拿到 {@code null} 并抛
 * {@code NullPointerException: ... "p_61100_" is null}，模组在注册阶段直接崩溃。
 * 正确做法见 {@link #create}：先把属性算好放进 final 局部变量，再交给匿名类捕获。
 *
 * <h2>流体属性与渲染变体</h2>
 * 原生类将 {@code fluid=empty/water} 加入方块状态并据此派生 FluidState，存档中也会保存该值。
 * 模型 JSON 只写 age 时，表示两种流体状态共用同龄模型，并不表示方块没有 fluid 属性。
 *
 * @see io.github.likexiang21.tfcplus.farming.common.crop.FarmingCrops 用法示例
 */
public abstract class FarmingFloodedCropBlock extends FloodedCropBlock {

    protected FarmingFloodedCropBlock(ExtendedProperties properties, int maxAge,
                                 Supplier<? extends Block> dead, Supplier<? extends Item> seeds,
                                 float nitrogen, float phosphorous, float potassium,
                                 Supplier<ClimateRange> climateRange) {
        super(properties, maxAge, dead, seeds, nitrogen, phosphorous, potassium, climateRange);
    }

    /**
     * 唯一的创建入口。
     *
     * @param maxAge 最大年龄值（如 6 表示 age 0~6，共 7 个视觉阶段）
     */
    public static FarmingFloodedCropBlock create(ExtendedProperties properties, int maxAge,
                                            Supplier<? extends Block> dead, Supplier<? extends Item> seeds,
                                            float nitrogen, float phosphorous, float potassium,
                                            Supplier<ClimateRange> climateRange) {
        // ⚠️ 这一行必须在 new 之前：它会被匿名类捕获为合成字段，从而在构造期立即可用
        final IntegerProperty property = TFCBlockStateProperties.getAgeProperty(maxAge);
        return new FarmingFloodedCropBlock(properties, maxAge, dead, seeds,
            nitrogen, phosphorous, potassium, climateRange) {
            @Override
            public IntegerProperty getAgeProperty() {
                return property;
            }
        };
    }
}
