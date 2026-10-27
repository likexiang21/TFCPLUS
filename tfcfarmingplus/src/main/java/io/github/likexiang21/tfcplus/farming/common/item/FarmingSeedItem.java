package io.github.likexiang21.tfcplus.farming.common.item;

import java.util.function.Supplier;
import net.dries007.tfc.common.items.PlantableInfo;
import net.dries007.tfc.util.climate.ClimateRange;
import net.minecraft.world.item.Item;
import net.minecraft.world.item.ItemNameBlockItem;
import net.minecraft.world.level.block.Block;
import org.jetbrains.annotations.Nullable;

/**
 * 通用种子物品。
 * <p>
 * TFC 的 {@code SeedItem} 构造器要求它私有的 {@code Crop} 枚举，所以附属模组必须自己写。
 * 这里实现 {@link PlantableInfo} 即可白拿 TFC 的 tooltip 渲染
 * （按住 Shift 显示气候区间、NPK 收支、生长耗时）。
 */
public class FarmingSeedItem extends ItemNameBlockItem implements PlantableInfo {
    private final PlantableInfo.PlantNutrients nutrients;
    private final Supplier<ClimateRange> climateRange;

    public FarmingSeedItem(Block cropBlock, float nitrogen, float phosphorous, float potassium,
                      Supplier<ClimateRange> climateRange, Item.Properties properties) {
        super(cropBlock, properties);
        this.nutrients = new PlantableInfo.PlantNutrients(nitrogen, phosphorous, potassium);
        this.climateRange = climateRange;
    }

    @Override
    @Nullable
    public PlantableInfo.PlantNutrients getNutrientsInfo() {
        return nutrients;
    }

    @Override
    @Nullable
    public ClimateRange getClimateRangeInfo() {
        return climateRange.get();
    }
}
