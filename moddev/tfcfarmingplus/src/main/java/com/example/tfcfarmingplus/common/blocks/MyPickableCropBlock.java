package com.example.tfcfarmingplus.common.blocks;

import net.dries007.tfc.common.blocks.ExtendedProperties;
import net.dries007.tfc.common.blocks.TFCBlockStateProperties;
import net.dries007.tfc.common.blocks.crop.PickableCropBlock;
import net.dries007.tfc.util.climate.ClimateRange;
import net.minecraft.world.item.Item;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.state.properties.IntegerProperty;

import java.util.function.Supplier;

/**
 * 可采摘作物（自有实现）—— 同时用于表达「多年生」。
 * <p>
 * TFC 的 {@code PickableCropBlock} 已经实现了「采摘后退回成长状态、植株保留」的逻辑，
 * 只要气候合适它就会继续生长 —— 这正是芦笋/韭菜/大黄这类**多年生作物**在游戏里的自然表达，
 * 不需要专门的方块类。
 * <p>
 * 构造器参数中的 {@code fruit1} / {@code fruit2} 用于「未熟果 → 成熟果」的两段式产物
 * （照 TFC 的甜椒：青椒 → 红/黄椒）。
 *
 * <h2>⚠️ age 属性必须由匿名子类捕获</h2>
 * 与 {@link MyCropBlock} 完全相同的陷阱：原版 {@code Block} 构造器末尾会回调
 * {@code createBlockStateDefinition} → {@code getAgeProperty()}，那一刻实例字段尚未赋值。
 * 详见 {@link MyCropBlock} 的类注释。
 */
public abstract class MyPickableCropBlock extends PickableCropBlock {

    protected MyPickableCropBlock(ExtendedProperties properties, int maxAge,
                                  Supplier<? extends Block> dead, Supplier<? extends Item> seeds,
                                  float nitrogen, float phosphorous, float potassium,
                                  Supplier<ClimateRange> climateRange,
                                  Supplier<Supplier<? extends Item>> fruit1,
                                  Supplier<Supplier<? extends Item>> fruit2) {
        super(properties, maxAge, dead, seeds, nitrogen, phosphorous, potassium, climateRange, fruit1, fruit2);
    }

    /** 唯一的创建入口（属性先算好再交给匿名子类捕获） */
    public static MyPickableCropBlock create(ExtendedProperties properties, int maxAge,
                                             Supplier<? extends Block> dead, Supplier<? extends Item> seeds,
                                             float nitrogen, float phosphorous, float potassium,
                                             Supplier<ClimateRange> climateRange,
                                             Supplier<Supplier<? extends Item>> fruit1,
                                             Supplier<Supplier<? extends Item>> fruit2) {
        final IntegerProperty property = TFCBlockStateProperties.getAgeProperty(maxAge);
        return new MyPickableCropBlock(properties, maxAge, dead, seeds, nitrogen, phosphorous, potassium,
            climateRange, fruit1, fruit2) {
            @Override
            public IntegerProperty getAgeProperty() {
                return property;
            }
        };
    }
}
