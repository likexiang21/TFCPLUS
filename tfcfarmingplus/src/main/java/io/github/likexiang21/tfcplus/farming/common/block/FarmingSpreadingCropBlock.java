package io.github.likexiang21.tfcplus.farming.common.block;

import java.util.function.Supplier;
import net.dries007.tfc.common.blocks.ExtendedProperties;
import net.dries007.tfc.common.blocks.TFCBlockStateProperties;
import net.dries007.tfc.common.blocks.crop.SpreadingCropBlock;
import net.dries007.tfc.util.climate.ClimateRange;
import net.minecraft.world.item.Item;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.state.properties.IntegerProperty;

/**
 * 蔓延型作物（自有实现）—— 瓜类专用：藤蔓会沿着地面向**四个水平方向**铺开。
 * <p>
 * 适用对象：哈密瓜、冬瓜、瓠瓜（佛手瓜是攀爬型，另走 {@code ClimbingCropBlock}）。
 * 与普通作物最大的不同是**产物不挂在作物自己身上**：
 * 藤长到最后一个 age 时，会在旁边的空地上放下一个**结果方块**（瓜），
 * 由那个方块保存并返还整瓜，已有案板负责切片。所以本类的掉落表**只掉种子**，
 * 藤蔓生长与整瓜食品状态分别交给对应的 TFC 原生机制。
 *
 * <h2>为什么写子类</h2>
 * 与 {@link FarmingCropBlock} 同理：TFC 的 {@code SpreadingCropBlock.create(props, stages, Crop, fruit)}
 * 要求 TFC 私有的 {@code Crop} 枚举，而它的构造器是 protected（对子类可见），所以只能自己包一层。
 *
 * <h2>⚠️ age 属性必须由匿名子类捕获</h2>
 * 原版 {@code Block} 的构造器末尾会调用虚方法 {@code createBlockStateDefinition(...)}，
 * TFC 的实现会在其中调用 {@code getAgeProperty()}。也就是说：这个方法会在子类自己的字段赋值
 * **之前**就被调用，读实例字段会拿到 {@code null} 并抛
 * {@code NullPointerException: ... "p_61100_" is null}，模组在注册阶段直接崩溃。
 * 正确做法见 {@link #create}：先把属性算好放进 final 局部变量，再交给匿名类捕获。
 *
 * <h2>为什么 fruit 是「Supplier 的 Supplier」</h2>
 * 结果方块与本作物互相引用（结果方块要知道自己是哪个瓜，作物要知道自己结哪个瓜），
 * Java 的静态初始化不允许这种前向引用，所以 TFC 用双层 Supplier 把取值推迟到第一次实际使用。
 * 调用方照 {@code () -> FarmingBlocks.MY_MELON} 这样传即可。
 *
 * @see io.github.likexiang21.tfcplus.farming.common.crop.FarmingCrops 用法示例
 */
public abstract class FarmingSpreadingCropBlock extends SpreadingCropBlock {

    protected FarmingSpreadingCropBlock(ExtendedProperties properties, int maxAge,
                                   Supplier<? extends Block> dead, Supplier<? extends Item> seeds,
                                   float nitrogen, float phosphorous, float potassium,
                                   Supplier<ClimateRange> climateRange,
                                   Supplier<Supplier<? extends Block>> fruit) {
        super(properties, maxAge, dead, seeds, nitrogen, phosphorous, potassium, climateRange, fruit);
    }

    /**
     * 唯一的创建入口。
     *
     * @param maxAge 最大年龄值（如 5 表示 age 0~5，共 6 个视觉阶段）
     * @param fruit  成熟后要放下的结果方块
     */
    public static FarmingSpreadingCropBlock create(ExtendedProperties properties, int maxAge,
                                              Supplier<? extends Block> dead, Supplier<? extends Item> seeds,
                                              float nitrogen, float phosphorous, float potassium,
                                              Supplier<ClimateRange> climateRange,
                                              Supplier<Supplier<? extends Block>> fruit) {
        // ⚠️ 这一行必须在 new 之前：它会被匿名类捕获为合成字段，从而在构造期立即可用
        final IntegerProperty property = TFCBlockStateProperties.getAgeProperty(maxAge);
        return new FarmingSpreadingCropBlock(properties, maxAge, dead, seeds,
            nitrogen, phosphorous, potassium, climateRange, fruit) {
            @Override
            public IntegerProperty getAgeProperty() {
                return property;
            }
        };
    }
}
