package io.github.likexiang21.tfcplus.farming.common.crop;

import io.github.likexiang21.tfcplus.farming.common.block.FarmingBerryBushBlock;
import io.github.likexiang21.tfcplus.farming.common.block.FarmingSpreadingBushBlock;
import io.github.likexiang21.tfcplus.farming.common.block.FarmingSpreadingCaneBlock;
import io.github.likexiang21.tfcplus.farming.common.item.FarmingBushBlockItem;
import io.github.likexiang21.tfcplus.farming.common.registry.FarmingBlockEntities;
import io.github.likexiang21.tfcplus.farming.common.registry.FarmingBlocks;
import io.github.likexiang21.tfcplus.farming.common.registry.FarmingClimateRanges;
import io.github.likexiang21.tfcplus.farming.common.registry.FarmingItems;
import java.util.function.Supplier;
import net.dries007.tfc.common.blocks.ExtendedProperties;
import net.dries007.tfc.common.blocks.plant.fruit.Lifecycle;
import net.dries007.tfc.util.climate.ClimateRange;
import net.dries007.tfc.util.registry.RegistrationHelpers;
import net.minecraft.world.item.Item;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.SoundType;
import net.minecraft.world.level.material.MapColor;
import net.neoforged.neoforge.registries.DeferredHolder;
import static net.dries007.tfc.common.blocks.plant.fruit.Lifecycle.DORMANT;
import static net.dries007.tfc.common.blocks.plant.fruit.Lifecycle.FLOWERING;
import static net.dries007.tfc.common.blocks.plant.fruit.Lifecycle.FRUITING;
import static net.dries007.tfc.common.blocks.plant.fruit.Lifecycle.HEALTHY;

/**
 * 批次 1：灌木浆果（10 种）。
 * <p>
 * TFC 的浆果丛有**两种形态**，是不同的方块类、外观与采摘方式都不同。
 * 本类按各浆果的**现实习性**分别归入，与 TFC 的分法一致：
 *
 * <table border="1">
 *   <tr><th>形态</th><th>方块类</th><th>外形</th><th>注册名</th><th>TFC 原版实例</th></tr>
 *   <tr><td><b>矮丛</b>（4 种）</td><td>{@link FarmingBerryBushBlock}</td>
 *       <td>最高 1 格，贴地一丛</td><td>{@code plant/<name>_bush}</td><td>云莓、矮丛蓝莓、雪果</td></tr>
 *   <tr><td><b>蔓生</b>（6 种）</td><td>{@link FarmingSpreadingBushBlock}</td>
 *       <td>1 格起步，向外/向上长出藤蔓</td><td>{@code plant/<name>_bush} + {@code plant/<name>_bush_cane}</td>
 *       <td>黑莓、树莓、蓝莓、接骨木莓</td></tr>
 * </table>
 *
 * 矮丛适合**匍匐/垫状**的极地小灌木（越橘、熊果、岩高兰、山蓝莓）；
 * 蔓生适合**枝条外展或半攀援**的灌木（加仑类、蓝靛果、枸杞、唐棣、野樱莓）。
 * <p>
 * 每个灌木只需：一张 12 月 {@code Lifecycle[]} 表 + 一个气候引用 + 一个产物物品。
 * {@code Lifecycle[]} 长度为 12（对应 1~12 月，按北半球书写，南半球由 TFC 自动取反），
 * 长度不为 12 会在构造期抛异常。
 * <p>
 * ⚠️ <b>蔓生形态的贴图借用 TFC 的现成藤蔓美术</b>（本工程统一的「占位借用」策略）：
 * 每种高灌木在 {@code blockstates/} 里直接引用某个 TFC 高灌木的模型，
 * 「外观捐助者」见 {@link #highBush} 的调用注释。将来换自有美术时只改那些 JSON。
 */
public final class FarmingBushes {

    // ---------------- 12 个月生命周期表 ----------------

    /** 越橘：4~6 月生长，7 月开花，8~9 月结果（北极圈浆果，晚夏成熟） */
    private static final Lifecycle[] LINGONBERRY = {
        DORMANT, DORMANT, DORMANT, HEALTHY, HEALTHY, HEALTHY, FLOWERING, FRUITING, FRUITING, DORMANT, DORMANT, DORMANT
    };
    /** 熊果：5~6 月生长，7 月开花，8~9 月结果 */
    private static final Lifecycle[] BEARBERRY = {
        DORMANT, DORMANT, DORMANT, DORMANT, HEALTHY, HEALTHY, FLOWERING, FRUITING, FRUITING, DORMANT, DORMANT, DORMANT
    };
    /** 岩高兰：极地短季，5~6 月生长，7 月开花，8 月结果 */
    private static final Lifecycle[] CROWBERRY = {
        DORMANT, DORMANT, DORMANT, DORMANT, HEALTHY, HEALTHY, FLOWERING, FRUITING, DORMANT, DORMANT, DORMANT, DORMANT
    };
    /** 山蓝莓：4~6 月生长，7 月开花，8 月结果 */
    private static final Lifecycle[] BILBERRY = {
        DORMANT, DORMANT, DORMANT, HEALTHY, HEALTHY, HEALTHY, FLOWERING, FRUITING, DORMANT, DORMANT, DORMANT, DORMANT
    };
    /** 黑加仑：4~5 月生长，6 月开花，7~8 月结果（夏初成熟） */
    private static final Lifecycle[] BLACKCURRANT = {
        DORMANT, DORMANT, DORMANT, HEALTHY, HEALTHY, FLOWERING, FRUITING, FRUITING, DORMANT, DORMANT, DORMANT, DORMANT
    };
    /** 红加仑：5 月生长，6 月开花，7~8 月结果 */
    private static final Lifecycle[] REDCURRANT = {
        DORMANT, DORMANT, DORMANT, DORMANT, HEALTHY, FLOWERING, FRUITING, FRUITING, DORMANT, DORMANT, DORMANT, DORMANT
    };
    /** 蓝靛果：3~4 月生长，5 月开花，6 月结果（本组最早熟） */
    private static final Lifecycle[] HASKAP = {
        DORMANT, DORMANT, HEALTHY, HEALTHY, FLOWERING, FRUITING, DORMANT, DORMANT, DORMANT, DORMANT, DORMANT, DORMANT
    };
    /** 枸杞：4~5 月生长，6 月开花 7 月结果，8 月二度开花 9 月结果（夏秋双季） */
    private static final Lifecycle[] GOJI = {
        DORMANT, DORMANT, DORMANT, HEALTHY, HEALTHY, FLOWERING, FRUITING, FLOWERING, FRUITING, DORMANT, DORMANT, DORMANT
    };
    /** 唐棣：4 月生长，5 月开花，6 月结果（早夏成熟） */
    private static final Lifecycle[] SERVICEBERRY = {
        DORMANT, DORMANT, DORMANT, HEALTHY, FLOWERING, FRUITING, DORMANT, DORMANT, DORMANT, DORMANT, DORMANT, DORMANT
    };
    /** 野樱莓：5~7 月生长，8 月开花，9~10 月结果（秋果） */
    private static final Lifecycle[] ARONIA = {
        DORMANT, DORMANT, DORMANT, DORMANT, HEALTHY, HEALTHY, HEALTHY, FLOWERING, FRUITING, FRUITING, DORMANT, DORMANT
    };

    // ---------------- 批次 4：茶树 / 咖啡树 ----------------
    // 两者都是**灌木**，不是耕地作物：它们要多年生长、年年采收，用耕地作物的
    // 「播种—收割」模型表达不了，所以走蔓生灌木（主丛 + 枝叶）。

    /** 茶树：3~5 月抽新芽，6~7 月开花，8~10 月采叶（采叶期借 FRUITING 状态表示可采收） */
    private static final Lifecycle[] TEA_LIFECYCLE = {
        DORMANT, DORMANT, HEALTHY, HEALTHY, HEALTHY, FLOWERING, FLOWERING, FRUITING, FRUITING, FRUITING, HEALTHY, DORMANT
    };
    /** 咖啡树：3 月返青，4~5 月开花，6~8 月结果（怕霜，只长在温暖无霜的地方） */
    private static final Lifecycle[] COFFEE = {
        DORMANT, DORMANT, HEALTHY, FLOWERING, FLOWERING, FRUITING, FRUITING, FRUITING, HEALTHY, HEALTHY, DORMANT, DORMANT
    };

    // ---------------- 矮丛形态（4 种） ----------------

    public static final DeferredHolder<Block, FarmingBerryBushBlock> LINGONBERRY_BUSH =
        bush("lingonberry", FarmingItems.LINGONBERRY, LINGONBERRY, FarmingClimateRanges.LINGONBERRY_BUSH);
    public static final DeferredHolder<Block, FarmingBerryBushBlock> BEARBERRY_BUSH =
        bush("bearberry", FarmingItems.BEARBERRY, BEARBERRY, FarmingClimateRanges.BEARBERRY_BUSH);
    public static final DeferredHolder<Block, FarmingBerryBushBlock> CROWBERRY_BUSH =
        bush("crowberry", FarmingItems.CROWBERRY, CROWBERRY, FarmingClimateRanges.CROWBERRY_BUSH);
    public static final DeferredHolder<Block, FarmingBerryBushBlock> BILBERRY_BUSH =
        bush("bilberry", FarmingItems.BILBERRY, BILBERRY, FarmingClimateRanges.BILBERRY_BUSH);

    // ---------------- 蔓生形态（6 种） ----------------
    // 每种都是「主丛 + 藤蔓」一对；两者通过 companion 互相引用，
    // 用限定名 lambda 延迟取值以规避 Java 的「前向引用」编译错误。

    /** 黑加仑 —— 外观捐助者 {@code tfc:elderberry}（接骨木莓，深色果串），藤蔓最高 3 格 */
    public static final DeferredHolder<Block, FarmingSpreadingBushBlock> BLACKCURRANT_BUSH =
        highBush("blackcurrant", FarmingItems.BLACKCURRANT, BLACKCURRANT, FarmingClimateRanges.BLACKCURRANT_BUSH,
            () -> FarmingBushes.BLACKCURRANT_BUSH_CANE.get(), 3);
    public static final DeferredHolder<Block, FarmingSpreadingCaneBlock> BLACKCURRANT_BUSH_CANE =
        highCane("blackcurrant", FarmingItems.BLACKCURRANT, BLACKCURRANT, FarmingClimateRanges.BLACKCURRANT_BUSH,
            () -> FarmingBushes.BLACKCURRANT_BUSH.get(), 3);

    /** 红加仑 —— 外观捐助者 {@code tfc:raspberry}（树莓，红色小果），藤蔓最高 3 格 */
    public static final DeferredHolder<Block, FarmingSpreadingBushBlock> REDCURRANT_BUSH =
        highBush("redcurrant", FarmingItems.REDCURRANT, REDCURRANT, FarmingClimateRanges.REDCURRANT_BUSH,
            () -> FarmingBushes.REDCURRANT_BUSH_CANE.get(), 3);
    public static final DeferredHolder<Block, FarmingSpreadingCaneBlock> REDCURRANT_BUSH_CANE =
        highCane("redcurrant", FarmingItems.REDCURRANT, REDCURRANT, FarmingClimateRanges.REDCURRANT_BUSH,
            () -> FarmingBushes.REDCURRANT_BUSH.get(), 3);

    /** 蓝靛果 —— 外观捐助者 {@code tfc:blueberry}（蓝莓，本组最矮的蔓生型），藤蔓最高 2 格 */
    public static final DeferredHolder<Block, FarmingSpreadingBushBlock> HASKAP_BUSH =
        highBush("haskap", FarmingItems.HASKAP, HASKAP, FarmingClimateRanges.HASKAP_BUSH,
            () -> FarmingBushes.HASKAP_BUSH_CANE.get(), 2);
    public static final DeferredHolder<Block, FarmingSpreadingCaneBlock> HASKAP_BUSH_CANE =
        highCane("haskap", FarmingItems.HASKAP, HASKAP, FarmingClimateRanges.HASKAP_BUSH,
            () -> FarmingBushes.HASKAP_BUSH.get(), 2);

    /** 枸杞 —— 外观捐助者 {@code tfc:blackberry}（黑莓，最高最蔓生的原型），藤蔓最高 4 格 */
    public static final DeferredHolder<Block, FarmingSpreadingBushBlock> GOJI_BUSH =
        highBush("goji", FarmingItems.GOJI, GOJI, FarmingClimateRanges.GOJI_BUSH,
            () -> FarmingBushes.GOJI_BUSH_CANE.get(), 4);
    public static final DeferredHolder<Block, FarmingSpreadingCaneBlock> GOJI_BUSH_CANE =
        highCane("goji", FarmingItems.GOJI, GOJI, FarmingClimateRanges.GOJI_BUSH,
            () -> FarmingBushes.GOJI_BUSH.get(), 4);

    /** 唐棣 —— 外观捐助者 {@code tfc:elderberry}（接骨木莓，灌丛较高），藤蔓最高 3 格 */
    public static final DeferredHolder<Block, FarmingSpreadingBushBlock> SERVICEBERRY_BUSH =
        highBush("serviceberry", FarmingItems.SERVICEBERRY, SERVICEBERRY, FarmingClimateRanges.SERVICEBERRY_BUSH,
            () -> FarmingBushes.SERVICEBERRY_BUSH_CANE.get(), 3);
    public static final DeferredHolder<Block, FarmingSpreadingCaneBlock> SERVICEBERRY_BUSH_CANE =
        highCane("serviceberry", FarmingItems.SERVICEBERRY, SERVICEBERRY, FarmingClimateRanges.SERVICEBERRY_BUSH,
            () -> FarmingBushes.SERVICEBERRY_BUSH.get(), 3);

    /** 野樱莓 —— 外观捐助者 {@code tfc:blackberry}（枝条外展、易生根蔓延），藤蔓最高 4 格 */
    public static final DeferredHolder<Block, FarmingSpreadingBushBlock> ARONIA_BUSH =
        highBush("aronia", FarmingItems.ARONIA, ARONIA, FarmingClimateRanges.ARONIA_BUSH,
            () -> FarmingBushes.ARONIA_BUSH_CANE.get(), 4);
    public static final DeferredHolder<Block, FarmingSpreadingCaneBlock> ARONIA_BUSH_CANE =
        highCane("aronia", FarmingItems.ARONIA, ARONIA, FarmingClimateRanges.ARONIA_BUSH,
            () -> FarmingBushes.ARONIA_BUSH.get(), 4);

    // ---------------- 蔓生形态（批次 4：茶树 / 咖啡树） ----------------

    /** 茶树 —— 外观捐助者 {@code tfc:blueberry}（常绿小圆叶，本组最矮的蔓生型），枝叶最高 2 格 */
    public static final DeferredHolder<Block, FarmingSpreadingBushBlock> TEA_BUSH =
        highBush("tea", FarmingItems.TEA_LEAF, TEA_LIFECYCLE, FarmingClimateRanges.TEA_BUSH,
            () -> FarmingBushes.TEA_BUSH_CANE.get(), 2);
    public static final DeferredHolder<Block, FarmingSpreadingCaneBlock> TEA_BUSH_CANE =
        highCane("tea", FarmingItems.TEA_LEAF, TEA_LIFECYCLE, FarmingClimateRanges.TEA_BUSH,
            () -> FarmingBushes.TEA_BUSH.get(), 2);

    /** 咖啡树 —— 外观捐助者 {@code tfc:elderberry}（枝条直立的灌木，成串结果），枝叶最高 3 格 */
    public static final DeferredHolder<Block, FarmingSpreadingBushBlock> COFFEE_BUSH =
        highBush("coffee", FarmingItems.COFFEE_BEAN, COFFEE, FarmingClimateRanges.COFFEE_BUSH,
            () -> FarmingBushes.COFFEE_BUSH_CANE.get(), 3);
    public static final DeferredHolder<Block, FarmingSpreadingCaneBlock> COFFEE_BUSH_CANE =
        highCane("coffee", FarmingItems.COFFEE_BEAN, COFFEE, FarmingClimateRanges.COFFEE_BUSH,
            () -> FarmingBushes.COFFEE_BUSH.get(), 3);

    // ---------------- 注册辅助 ----------------

    /**
     * 注册一个**矮丛**浆果灌木（含方块物品，使其可被搬运）。
     * <p>
     * 属性组合参考 TFC {@code FruitBlocks.StationaryBush.create()} 的公开行为，由本项目独立实现：
     * 绑 {@code TFCBlockEntities.BERRY_BUSH}（存采摘计时与 stemPos），可燃性同树叶。
     * <p>
     * 用 {@link RegistrationHelpers#registerBlock} 一次注册方块 + 方块物品 —— 这是 TFC 的做法，
     * 保证掉落表可以引用方块自身（玩家能用锋利工具把灌木整株挖回家）。
     */
    private static DeferredHolder<Block, FarmingBerryBushBlock> bush(
            String name, Supplier<? extends Item> product, Lifecycle[] stages,
            Supplier<ClimateRange> climateRange) {
        return RegistrationHelpers.registerBlock(FarmingBlocks.BLOCKS, FarmingItems.ITEMS, "plant/" + name + "_bush",
            () -> new FarmingBerryBushBlock(
                bushProps(), product, stages, climateRange),
            b -> new FarmingBushBlockItem(b, climateRange, stages));
    }

    /**
     * 注册一个**蔓生**浆果灌木的**主丛**（含方块物品）。
     * <p>
     * {@code companion} 是配套的藤蔓方块，{@code maxHeight} 是藤蔓能爬升的最高格数
     * （与外观捐助者的取值一致，保证生长节奏和外形匹配）。
     */
    private static DeferredHolder<Block, FarmingSpreadingBushBlock> highBush(
            String name, Supplier<? extends Item> product, Lifecycle[] stages,
            Supplier<ClimateRange> climateRange, Supplier<? extends Block> companion, int maxHeight) {
        return RegistrationHelpers.registerBlock(FarmingBlocks.BLOCKS, FarmingItems.ITEMS, "plant/" + name + "_bush",
            () -> new FarmingSpreadingBushBlock(
                bushProps(), product, stages, companion, maxHeight, climateRange),
            b -> new FarmingBushBlockItem(b, climateRange, stages));
    }

    /**
     * 注册一个**蔓生**浆果灌木的**藤蔓**。
     * <p>
     * ⚠️ 藤蔓**没有方块物品**（照 TFC 的 {@code registerNoItem}）：
     * 它只能由主丛生长出来，因此不进创造模式物品栏，掉落表也只掉木棍。
     * 用原生 {@code DeferredRegister.register} 而非
     * {@link RegistrationHelpers#registerBlock}，正是为了不生成方块物品。
     */
    private static DeferredHolder<Block, FarmingSpreadingCaneBlock> highCane(
            String name, Supplier<? extends Item> product, Lifecycle[] stages,
            Supplier<ClimateRange> climateRange, Supplier<? extends Block> companion, int maxHeight) {
        return FarmingBlocks.BLOCKS.register("plant/" + name + "_bush_cane",
            () -> new FarmingSpreadingCaneBlock(
                bushProps(), product, stages, companion, maxHeight, climateRange));
    }

    /** 浆果灌木通用属性（照 TFC 的 {@code FruitBlocks}）；矮丛与蔓生共用 */
    private static ExtendedProperties bushProps() {
        return ExtendedProperties.of(MapColor.PLANT)
            .strength(0.6f)
            .noOcclusion()
            .randomTicks()
            .sound(SoundType.SWEET_BERRY_BUSH)
            // ⚠️ 必须是自建的 BE 类型：挂到 TFCBlockEntities.BERRY_BUSH 上会在
            //    放下方块时触发原版 BlockEntity.validateBlockState 校验失败（已实测）
            .blockEntity(FarmingBlockEntities.BERRY_BUSH)
            .flammableLikeLeaves();
    }

    /**
     * 全部浆果灌木方块（矮丛 + 蔓生主丛 + 蔓生藤蔓），
     * 供 {@link FarmingBlockEntities} 登记 BE 类型的 validBlocks 使用。
     * <p>
     * 以后新增灌木时记得同步加进来，否则放下时会被原版校验拦下。
     */
    public static Block[] bushBlocks() {
        return new Block[] {
            // 矮丛
            LINGONBERRY_BUSH.get(), BEARBERRY_BUSH.get(), CROWBERRY_BUSH.get(), BILBERRY_BUSH.get(),
            // 蔓生主丛
            BLACKCURRANT_BUSH.get(), REDCURRANT_BUSH.get(), HASKAP_BUSH.get(), GOJI_BUSH.get(),
            SERVICEBERRY_BUSH.get(), ARONIA_BUSH.get(), TEA_BUSH.get(), COFFEE_BUSH.get(),
            // 蔓生藤蔓（同样有 BE，漏了会在生长出藤蔓的瞬间崩服务端）
            BLACKCURRANT_BUSH_CANE.get(), REDCURRANT_BUSH_CANE.get(), HASKAP_BUSH_CANE.get(),
            GOJI_BUSH_CANE.get(), SERVICEBERRY_BUSH_CANE.get(), ARONIA_BUSH_CANE.get(),
            TEA_BUSH_CANE.get(), COFFEE_BUSH_CANE.get()
        };
    }

    /**
     * 触发本类的静态初始化。
     * <p>
     * ⚠️ Java 的类静态初始化是惰性的：如果没有任何代码引用 {@code FarmingBushes}，
     * 它上面的 {@code BLOCKS.register(...)} 调用**根本不会执行**，方块就不会被注册。
     * 所以主类必须显式调用一次这个方法。
     */
    public static void init() {}

    private FarmingBushes() {}
}
