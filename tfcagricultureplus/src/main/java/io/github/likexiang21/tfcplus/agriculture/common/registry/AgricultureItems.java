package io.github.likexiang21.tfcplus.agriculture.common.registry;

import io.github.likexiang21.tfcplus.agriculture.TFCAgriculturePlus;
import io.github.likexiang21.tfcplus.agriculture.common.item.AdultSilkwormItem;
import io.github.likexiang21.tfcplus.agriculture.common.item.SawdustSoupBowlItem;
import java.util.LinkedHashMap;
import java.util.Map;
import net.minecraft.world.item.Item;
import net.minecraft.world.item.ItemStack;
import net.neoforged.bus.api.IEventBus;
import net.neoforged.neoforge.registries.DeferredHolder;
import net.neoforged.neoforge.registries.DeferredRegister;

/**
 * B 层的物品注册表。
 *
 * <p>🛑 约束（126 §3.1）：
 * <ul>
 *   <li>**手持工具**（石臼+杵 / 簸箕 / 筛 / 连枷）注册在这里 —— 它们是**物品不是方块**（126 §13.8）</li>
 *   <li>方块的 BlockItem 由 {@link AgricultureBlocks#registerWithItem} 一并注册，**不要**在这里重复注册</li>
 *   <li>新增物种必须**闭环**（种子→可种→可长→可收→产物有用途）—— 红线 10</li>
 * </ul>
 *
 * <p>📌 <b>批次 1（本批）</b>：先做 **1 个手持工具**验证物品链路。
 * 🆕 为什么先做手持工具：126 §13.8 的结论 —— **"手持工具"是"少方块"与"有实感"之间的第三条路**，
 * 它比合成有操作感、比专用方块轻量（不用注册方块 / BE / 贴图集）。
 */
public final class AgricultureItems {

    public static final DeferredRegister.Items ITEMS =
        DeferredRegister.createItems(TFCAgriculturePlus.MOD_ID);

    /** B-owned woodwork byproducts migrated from the MIT-licensed TFC Woodworking content. */
    public static final Map<String, DeferredHolder<Item, Item>> WOOD_BARK = new LinkedHashMap<>();
    public static final Map<String, DeferredHolder<Item, Item>> WOOD_BAST = new LinkedHashMap<>();

    // ------------------------------------------------------------------
    // 物品属性
    // ------------------------------------------------------------------

    /** 普通材料（纤维 / 中间产物 / 散装食材）。 */
    public static Item.Properties materialProps() {
        return new Item.Properties();
    }

    /** 食物（营养与保质期走 TFC 的 food 数据 + 我们的 FoodTrait）。 */
    public static Item.Properties foodProps() {
        return new Item.Properties().stacksTo(64);
    }

    /**
     * 手持工具。
     * ⚠️ v1 起**石杵有耐久**（用户口径：「只不过**石杵会消耗耐久**」）。
     * 其它手持工具（簸箕/筛/连枷）在批次 5 加入时再决定。
     */
    public static Item.Properties toolProps() {
        return new Item.Properties().stacksTo(1);
    }

    /**
     * 🆕 <b>石杵的耐久</b> —— 每次研磨扣 1。
     * <p>取值依据：石臼 + 杵是**可长期使用的工具**，但石头终究会磨损；
     * Firmalife 的同类工具（如 knife）耐用度在 100~250 之间 ⇒ 取 <b>160</b>（≈ 半组）。
     */
    public static Item.Properties pestleProps() {
        return new Item.Properties().stacksTo(1).durability(160);
    }

    /** 第一批石臼产物：可直接食用，也可作为后续调味链的原料。 */
    public static final DeferredHolder<Item, Item> GROUND_GINGER =
        ITEMS.registerSimpleItem("food/ground_ginger", foodProps());
    public static final DeferredHolder<Item, Item> GROUND_TURMERIC =
        ITEMS.registerSimpleItem("food/ground_turmeric", foodProps());
    public static final DeferredHolder<Item, Item> GROUND_BLACK_PEPPER =
        ITEMS.registerSimpleItem("food/ground_black_pepper", foodProps());

    /** 第一批案板预处理产物：切片和切丝，供后续调味、汤和沙拉配方使用。 */
    public static final DeferredHolder<Item, Item> GINGER_SLICES =
        ITEMS.registerSimpleItem("food/ginger_slices", foodProps());
    public static final DeferredHolder<Item, Item> TURMERIC_SLICES =
        ITEMS.registerSimpleItem("food/turmeric_slices", foodProps());
    public static final DeferredHolder<Item, Item> NAPA_CABBAGE_SHREDS =
        ITEMS.registerSimpleItem("food/napa_cabbage_shreds", foodProps());

    /** K2 pan output; the recipe copies the input freshness onto this food. */
    public static final DeferredHolder<Item, Item> PAN_SEASONED_VEGETABLES =
        ITEMS.registerSimpleItem("food/pan_seasoned_vegetables", foodProps());

    /** K3 dough and a served slice from the placeable whole pie. */
    public static final DeferredHolder<Item, Item> DOUGH =
        ITEMS.registerSimpleItem("material/dough", materialProps());
    /** K3 cake dough; this is the only new dough item retained by the rework. */
    public static final DeferredHolder<Item, Item> CAKE_DOUGH =
        ITEMS.registerSimpleItem("food/cake_dough", foodProps());
    public static final DeferredHolder<Item, Item> RAW_CAKE_BASE =
        ITEMS.registerSimpleItem("food/raw_cake_base", foodProps());
    public static final DeferredHolder<Item, Item> RAW_CUPCAKE =
        ITEMS.registerSimpleItem("food/raw_cupcake", foodProps());
    public static final DeferredHolder<Item, Item> CAKE_BASE =
        ITEMS.registerSimpleItem("food/cake_base", foodProps());
    public static final DeferredHolder<Item, Item> CUPCAKE =
        ITEMS.registerSimpleItem("food/cupcake", foodProps());
    public static final DeferredHolder<Item, Item> RAW_SWEET_PANCAKE =
        ITEMS.registerSimpleItem("food/raw_sweet_pancake", foodProps());
    public static final DeferredHolder<Item, Item> SWEET_PANCAKE =
        ITEMS.registerSimpleItem("food/sweet_pancake", foodProps());
    public static final DeferredHolder<Item, Item> RAW_BAGEL =
        ITEMS.registerSimpleItem("food/raw_bagel", foodProps());
    public static final DeferredHolder<Item, Item> RAW_PIZZA =
        ITEMS.registerSimpleItem("food/raw_pizza", foodProps());
    public static final DeferredHolder<Item, Item> NOODLES =
        ITEMS.registerSimpleItem("food/noodles", foodProps());
    public static final Map<String, DeferredHolder<Item, Item>> RAW_NAAN = new LinkedHashMap<>();
    public static final Map<String, DeferredHolder<Item, Item>> NAAN = new LinkedHashMap<>();
    public static final Map<String, DeferredHolder<Item, Item>> RAW_BUN = new LinkedHashMap<>();
    public static final Map<String, DeferredHolder<Item, Item>> BUN = new LinkedHashMap<>();
    public static final DeferredHolder<Item, Item> PIE_SLICE =
        ITEMS.registerSimpleItem("food/pie_slice", foodProps());
    public static final DeferredHolder<Item, Item> CAKE_SLICE =
        ITEMS.registerSimpleItem("food/cake_slice", foodProps());
    public static final DeferredHolder<Item, Item> CREAM_CAKE_SLICE =
        ITEMS.registerSimpleItem("food/cream_cake_slice", foodProps());
    public static final DeferredHolder<Item, Item> CHOCOLATE_CAKE_SLICE =
        ITEMS.registerSimpleItem("food/chocolate_cake_slice", foodProps());
    public static final DeferredHolder<Item, Item> CHEESE_SLICE =
        ITEMS.registerSimpleItem("food/cheese_slice", foodProps());
    public static final DeferredHolder<Item, Item> BUTTER_SLICE =
        ITEMS.registerSimpleItem("food/butter_slice", foodProps());
    /** K3 placeable jam/jelly block serving. The source uses the canonical TFC jam tag. */
    public static final DeferredHolder<Item, Item> JELLY_SLICE =
        ITEMS.registerSimpleItem("food/jelly_slice", foodProps());
    /** K3 placeable sweetener block serving. Inputs remain canonical TFC sweeteners. */
    public static final DeferredHolder<Item, Item> SUGAR_PIECE =
        ITEMS.registerSimpleItem("food/sugar_piece", foodProps());

    /** 第 9～13 步可可闭环：树上可可荚 → 可可豆 → 密封桶发酵 → 烘焙 → 可可碎/粉/巧克力。 */
    public static final DeferredHolder<Item, Item> COCOA_BEANS =
        ITEMS.registerSimpleItem("food/cocoa_beans", foodProps());
    /** 密封桶发酵后的中间物；保留食品数据以便烘焙阶段复制新鲜度。 */
    public static final DeferredHolder<Item, Item> FERMENTED_COCOA_BEANS =
        ITEMS.registerSimpleItem("food/fermented_cocoa_beans", foodProps());
    public static final DeferredHolder<Item, Item> COCOA_NIBS =
        ITEMS.registerSimpleItem("food/cocoa_nibs", foodProps());
    public static final DeferredHolder<Item, Item> ROASTED_COCOA_BEANS =
        ITEMS.registerSimpleItem("food/roasted_cocoa_beans", foodProps());
    public static final DeferredHolder<Item, Item> COCOA_POWDER =
        ITEMS.registerSimpleItem("food/cocoa_powder", foodProps());
    public static final DeferredHolder<Item, Item> DARK_CHOCOLATE =
        ITEMS.registerSimpleItem("food/dark_chocolate", foodProps());

    /** B silkworm lifecycle items. The feed itself remains Firmalife/A-owned. */
    public static final DeferredHolder<Item, Item> SILKWORM_EGG =
        ITEMS.registerSimpleItem("silkworm_egg", materialProps());
    public static final DeferredHolder<Item, Item> SILKWORM =
        ITEMS.registerSimpleItem("silkworm", materialProps());
    public static final DeferredHolder<Item, Item> COCOON =
        ITEMS.registerSimpleItem("cocoon", materialProps());
    public static final DeferredHolder<Item, Item> ADULT_SILKWORM =
        ITEMS.register("adult_silkworm", () -> new AdultSilkwormItem());
    public static final DeferredHolder<Item, Item> COOKED_SILKWORM =
        ITEMS.registerSimpleItem("cooked_silkworm", materialProps());
    /** Silk thread extracted from a cocoon in the TFC pot and consumed by the TFC loom. */
    public static final DeferredHolder<Item, Item> SILK_THREAD =
        ITEMS.registerSimpleItem("silk_thread", materialProps());

    /** TFC Woodworking food byproducts, now owned by B and independent of tfcwoodwork. */
    public static final DeferredHolder<Item, Item> SAWDUST =
        ITEMS.registerSimpleItem("sawdust", materialProps());
    public static final DeferredHolder<Item, Item> SAWDUST_SOUP =
        ITEMS.register("sawdust_soup", () -> new SawdustSoupBowlItem(foodProps()));
    public static final DeferredHolder<Item, Item> SAWDUST_DOUGH =
        ITEMS.registerSimpleItem("sawdust_dough", foodProps());
    public static final DeferredHolder<Item, Item> SAWDUST_BREAD =
        ITEMS.registerSimpleItem("sawdust_bread", foodProps());

    static {
        registerBakingItems();
        for (final String wood : AgricultureBlocks.TFC_WOODS) registerWoodworkByproducts(wood);
        for (final String wood : AgricultureBlocks.AFC_WOODS) registerWoodworkByproducts(wood);
    }

    private static void registerBakingItems() {
        for (final String grain : java.util.List.of("wheat", "oat", "barley", "maize", "rye", "rice")) {
            RAW_NAAN.put(grain, ITEMS.registerSimpleItem("food/raw_" + grain + "_naan", foodProps()));
            NAAN.put(grain, ITEMS.registerSimpleItem("food/" + grain + "_naan", foodProps()));
            RAW_BUN.put(grain, ITEMS.registerSimpleItem("food/raw_" + grain + "_bun", foodProps()));
            BUN.put(grain, ITEMS.registerSimpleItem("food/" + grain + "_bun", foodProps()));
        }
    }

    private static void registerWoodworkByproducts(String wood) {
        WOOD_BARK.put(wood, ITEMS.register("bark/" + wood, () -> new Item(materialProps())));
        WOOD_BAST.put(wood, ITEMS.register("bast/" + wood, () -> new Item(materialProps())));
    }

    /** 🆕 全部石杵（供"这是不是石杵"的判断，以及创造页遍历）。 */
    private static final java.util.List<DeferredHolder<Item, Item>> PESTLES = new java.util.ArrayList<>();

    public static java.util.List<DeferredHolder<Item, Item>> allGroundSpices() {
        return java.util.List.of(GROUND_GINGER, GROUND_TURMERIC, GROUND_BLACK_PEPPER);
    }

    public static java.util.List<DeferredHolder<Item, Item>> allBoardPreparations() {
        return java.util.List.of(GINGER_SLICES, TURMERIC_SLICES, NAPA_CABBAGE_SHREDS);
    }

    public static java.util.List<DeferredHolder<Item, Item>> allCocoaPreparations() {
        // Firmalife owns the canonical cocoa beans, dried trait, roasted beans and powder.
        // B retains only its fermentation intermediate as an active creative/JEI entry.
        return java.util.List.of(FERMENTED_COCOA_BEANS);
    }

    /** 注册一个石杵并记进 {@link #PESTLES}。 */
    private static DeferredHolder<Item, Item> pestle(String name) {
        final DeferredHolder<Item, Item> holder = ITEMS.registerSimpleItem(name, pestleProps());
        PESTLES.add(holder);
        return holder;
    }

    /**
     * 🆕 这个物品是不是石杵 —— 石臼的右键交互靠它分流
     * （见 {@code AgricultureBlocks.MortarBlock#useWithoutItem}）。
     */
    public static boolean isPestle(ItemStack stack) {
        if (stack.isEmpty()) {
            return false;
        }
        for (final DeferredHolder<Item, Item> holder : PESTLES) {
            if (stack.is(holder.get())) {
                return true;
            }
        }
        return false;
    }

    /** 全部石杵（只读）。 */
    public static java.util.List<DeferredHolder<Item, Item>> allPestles() {
        return java.util.Collections.unmodifiableList(PESTLES);
    }

    // ------------------------------------------------------------------
    // 🛑 批次 1 rev3 修订：石臼**不再注册为物品**
    // ------------------------------------------------------------------
    //
    // 用户口径：「石臼根本不能放出，进行修复」+「石臼也应该存在多种变体」
    // ⇒ 石臼已改为**方块**：见 AgricultureBlocks.MORTARS（14 种硬质岩石变体）。
    // ⚠️ 这里**故意保留注释而不删方法**，是为了让后续维护者知道：
    //    "曾经有一个同名物品，它无法放置" —— 不要再把它加回来。
    //
    // public static final DeferredHolder<Item, Item> STONE_MORTAR = ...;   // ❌ 已废弃

    // ------------------------------------------------------------------
    // 🆕 批次 1 rev4：石杵（打制工具）
    // ------------------------------------------------------------------

    /**
     * 🆕 <b>石杵</b>（pestle）—— 与 {@link AgricultureBlocks} 的石臼配套的**碾磨工具**。
     *
     * <p>用户口径：「石臼的"石杵"使用**打制工艺**从**特定的石头类型**中制作
     * （**包括燧石和黑曜石质地**）」
     *
     * <h2>机制（实测 TFC）</h2>
     * {@code tfc:knapping} 的 {@code knapping_type: tfc:rock} —— 输入是**石头**，
     * 玩家在 5×5 的敲击界面里敲出形状。
     *
     * <h2>🛑 材料选择的硬约束（本轮实测出来的）</h2>
     * TFC 的打制界面**要求每种材料有一张 GUI 贴图**
     * （{@code tfc:textures/gui/knapping/<材料路径>.png}），实测 TFC 只提供了：
     * <ul>
     *   <li>✅ <b>{@code rock/loose/<rock>.png} × 21</b>（可捡起的散石 —— 正是现实里做石器的材料）</li>
     *   <li>✅ <b>{@code rock/mossy_loose/<rock>.png} × 21</b></li>
     *   <li>✅ <b>{@code groundcover/obsidian_shard.png}</b>（黑曜石碎片）</li>
     *   <li>❌ <b>没有 {@code flint.png}</b> ⇒ 用 {@code minecraft:flint} 会报
     *       {@code FileNotFoundException: tfc:textures/gui/knapping/flint.png}</li>
     * </ul>
     * 🛑 我们**不往 TFC 命名空间塞贴图**（红线 2 的同类问题：不覆盖邻居资源）⇒
     * **燧石版石杵暂缓**，改用**可打制的硬质散石 + 黑曜石**。
     *
     * <h2>7 种石杵</h2>
     * <table border="1">
     *   <tr><th>物品</th><th>打制材料</th><th>依据</th></tr>
     *   <tr><td>{@link #OBSIDIAN_PESTLE}</td><td>{@code tfc:groundcover/obsidian_shard}</td><td>黑曜石是火山玻璃，硬度 5~6 且断口锋利；TFC 已用它做刀/斧/锤</td></tr>
     *   <tr><td>{@link #BASALT_PESTLE}</td><td>{@code tfc:rock/loose/basalt}</td><td>玄武岩 —— 传统石臼/石杵的主力材质</td></tr>
     *   <tr><td>{@link #GRANITE_PESTLE}</td><td>{@code tfc:rock/loose/granite}</td><td>花岗岩 —— 硬度高、结晶致密</td></tr>
     *   <tr><td>{@link #DIORITE_PESTLE}</td><td>{@code tfc:rock/loose/diorite}</td><td>闪长岩</td></tr>
     *   <tr><td>{@link #GABBRO_PESTLE}</td><td>{@code tfc:rock/loose/gabbro}</td><td>辉长岩</td></tr>
     *   <tr><td>{@link #QUARTZITE_PESTLE}</td><td>{@code tfc:rock/loose/quartzite}</td><td>石英岩 —— 硬度接近石英</td></tr>
     *   <tr><td>{@link #SLATE_PESTLE}</td><td>{@code tfc:rock/loose/slate}</td><td>板岩 —— 易劈成薄片，便于成型</td></tr>
     * </table>
     *
     * <p>⚠️ 与 TFC {@code quern}（固定的手推磨）的分工：
     * <b>石臼+杵 = 小批量/随身/粗磨（香料 · 碎粒）</b>；
     * <b>quern = 大批量/固定/细粉（面粉）</b>。
     */
    public static final DeferredHolder<Item, Item> OBSIDIAN_PESTLE =
        pestle("obsidian_pestle");

    /** 见 {@link #OBSIDIAN_PESTLE}。 */
    public static final DeferredHolder<Item, Item> BASALT_PESTLE =
        pestle("basalt_pestle");

    /** 见 {@link #OBSIDIAN_PESTLE}。 */
    public static final DeferredHolder<Item, Item> GRANITE_PESTLE =
        pestle("granite_pestle");

    /** 见 {@link #OBSIDIAN_PESTLE}。 */
    public static final DeferredHolder<Item, Item> DIORITE_PESTLE =
        pestle("diorite_pestle");

    /** 见 {@link #OBSIDIAN_PESTLE}。 */
    public static final DeferredHolder<Item, Item> GABBRO_PESTLE =
        pestle("gabbro_pestle");

    /** 见 {@link #OBSIDIAN_PESTLE}。 */
    public static final DeferredHolder<Item, Item> QUARTZITE_PESTLE =
        pestle("quartzite_pestle");

    /** 见 {@link #OBSIDIAN_PESTLE}。 */
    public static final DeferredHolder<Item, Item> SLATE_PESTLE =
        pestle("slate_pestle");

    public static void register(IEventBus bus) {
        ITEMS.register(bus);
    }

    private AgricultureItems() {}
}
