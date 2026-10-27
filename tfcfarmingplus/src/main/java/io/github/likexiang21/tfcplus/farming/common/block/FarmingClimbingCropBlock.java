package io.github.likexiang21.tfcplus.farming.common.block;

import java.util.function.Supplier;
import net.dries007.tfc.common.blocks.ExtendedProperties;
import net.dries007.tfc.common.blocks.TFCBlockStateProperties;
import net.dries007.tfc.common.blocks.crop.ClimbingCropBlock;
import net.dries007.tfc.util.climate.ClimateRange;
import net.minecraft.world.item.Item;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.state.properties.IntegerProperty;

/**
 * 攀爬型作物（自有实现）—— 佛手瓜等攀爬物种：需要一根**木棍**才能往上爬。
 * <p>
 * 它继承的 TFC {@link ClimbingCropBlock} **本身就是双格作物**（{@code extends DoubleCropBlock}），
 * 并额外带一个 {@code STICK} 布尔属性，所以方块状态是**三维**的：
 *
 * <pre>
 *   age &lt; singleStages, stick=false            → 单格幼苗
 *   age &lt; singleStages, stick=true,  part=bottom → 插了棍的下格
 *   age &lt; singleStages, stick=true,  part=top    → 上格（模型就是那根棍）
 *   age &ge; singleStages,             part=bottom → 长高后的下格
 *   age &ge; singleStages,             part=top    → 长高后的上格
 * </pre>
 *
 * 对照 TFC 的 {@code blockstates/crop/tomato.json}：age 0~3 那几组都带 `stick` 两个分支，
 * age 4~7 才只有 `part`。给作物插棍是它的 {@code useItemOn} 做的（拿木棍右键幼苗）。
 *
 * <h2>为什么写子类</h2>
 * 与其它作物同理：{@code ClimbingCropBlock.create(props, singleStages, doubleStages, Crop)} 要求
 * TFC 私有的 {@code Crop} 枚举，而构造器是 protected（对子类可见）。
 *
 * <h2>⚠️ age 属性必须由匿名子类捕获</h2>
 * 原版 {@code Block} 的构造器末尾会调用虚方法 {@code createBlockStateDefinition(...)}，
 * TFC 的实现会在其中调用 {@code getAgeProperty()}。这个方法会在子类自己的字段赋值**之前**被调用，
 * 读实例字段会拿到 {@code null} 并抛 {@code NullPointerException: ... "p_61100_" is null}。
 * 正确做法见 {@link #create}：先把属性算好放进 final 局部变量，再交给匿名类捕获。
 *
 * <h2>与其它四种瓜的关系</h2>
 * 哈密瓜 / 冬瓜 / 瓠瓜走的是 {@link FarmingSpreadingCropBlock}（藤在地面铺开、**自动放下结果方块**）；
 * 佛手瓜走攀爬，**产物由成熟植株掉落表给出**（破坏采收），
 * 所以它不需要结果方块的那套机制；当前佛手瓜收获物是食品物品。
 *
 * @see io.github.likexiang21.tfcplus.farming.common.crop.FarmingCrops 用法示例
 */
public abstract class FarmingClimbingCropBlock extends ClimbingCropBlock {

    protected FarmingClimbingCropBlock(ExtendedProperties properties, int maxSingleAge, int maxAge,
                                  Supplier<? extends Block> dead, Supplier<? extends Item> seeds,
                                  float nitrogen, float phosphorous, float potassium,
                                  Supplier<ClimateRange> climateRange) {
        super(properties, maxSingleAge, maxAge, dead, seeds,
            nitrogen, phosphorous, potassium, climateRange);
    }

    /**
     * 唯一的创建入口。
     *
     * @param singleStages 还能用单格模型表示的最后一个 age + 1（照 TFC 番茄的 4）
     * @param maxAge       最大年龄值（照 TFC 番茄的 7）
     */
    public static FarmingClimbingCropBlock create(ExtendedProperties properties, int singleStages, int maxAge,
                                             Supplier<? extends Block> dead, Supplier<? extends Item> seeds,
                                             float nitrogen, float phosphorous, float potassium,
                                             Supplier<ClimateRange> climateRange) {
        // ⚠️ 这一行必须在 new 之前：它会被匿名类捕获为合成字段，从而在构造期立即可用
        if (singleStages < 2 || singleStages > maxAge) {
            throw new IllegalArgumentException("Invalid single-stage count: " + singleStages);
        }
        final IntegerProperty property = TFCBlockStateProperties.getAgeProperty(maxAge);
        return new FarmingClimbingCropBlock(properties, singleStages - 1, maxAge, dead, seeds,
            nitrogen, phosphorous, potassium, climateRange) {
            @Override
            public IntegerProperty getAgeProperty() {
                return property;
            }
        };
    }
}
