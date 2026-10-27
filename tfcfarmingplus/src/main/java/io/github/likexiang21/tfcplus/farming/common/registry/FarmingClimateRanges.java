package io.github.likexiang21.tfcplus.farming.common.registry;

import io.github.likexiang21.tfcplus.farming.TFCFarmingPlus;
import net.dries007.tfc.util.climate.ClimateRange;
import net.dries007.tfc.util.data.DataManager;
import net.minecraft.resources.ResourceLocation;

/**
 * 气候范围引用。
 * <p>
 * TFC 的 {@code ClimateRange.MANAGER} 是数据驱动管理器，目录规则由语义 id 决定：
 * {@code Helpers.identifier("climate_range")} → 数据文件路径恒为
 * {@code data/<你的命名空间>/tfc/climate_range/<子路径>.json}。
 * <p>
 * 注意：{@code DataManager.Reference} 是**惰性绑定**，可以安全地在静态初始化期使用。
 */
public final class FarmingClimateRanges {
    /** 解析 {@code tfcfarmingplus:<path>} 对应的气候引用 */
    private static DataManager.Reference<ClimateRange> register(String path) {
        return ClimateRange.MANAGER.getReference(
            ResourceLocation.fromNamespaceAndPath(TFCFarmingPlus.MOD_ID, path));
    }

    // ---------------- 批次 1：灌木（10 种） ----------------
    public static final DataManager.Reference<ClimateRange> LINGONBERRY_BUSH = register("plant/lingonberry_bush");
    public static final DataManager.Reference<ClimateRange> BEARBERRY_BUSH = register("plant/bearberry_bush");
    public static final DataManager.Reference<ClimateRange> CROWBERRY_BUSH = register("plant/crowberry_bush");
    public static final DataManager.Reference<ClimateRange> BILBERRY_BUSH = register("plant/bilberry_bush");
    public static final DataManager.Reference<ClimateRange> BLACKCURRANT_BUSH = register("plant/blackcurrant_bush");
    public static final DataManager.Reference<ClimateRange> REDCURRANT_BUSH = register("plant/redcurrant_bush");
    public static final DataManager.Reference<ClimateRange> HASKAP_BUSH = register("plant/haskap_bush");
    public static final DataManager.Reference<ClimateRange> GOJI_BUSH = register("plant/goji_bush");
    public static final DataManager.Reference<ClimateRange> SERVICEBERRY_BUSH = register("plant/serviceberry_bush");
    public static final DataManager.Reference<ClimateRange> ARONIA_BUSH = register("plant/aronia_bush");

    // ---------------- 批次 4：茶树 / 咖啡树（蔓生灌木形态） ----------------
    public static final DataManager.Reference<ClimateRange> TEA_BUSH = register("plant/tea_bush");
    public static final DataManager.Reference<ClimateRange> COFFEE_BUSH = register("plant/coffee_bush");

    private FarmingClimateRanges() {}
}
