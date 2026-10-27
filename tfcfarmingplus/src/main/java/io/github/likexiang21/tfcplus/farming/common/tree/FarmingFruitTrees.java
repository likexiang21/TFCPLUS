package io.github.likexiang21.tfcplus.farming.common.tree;

import io.github.likexiang21.tfcplus.farming.TFCFarmingPlus;
import io.github.likexiang21.tfcplus.farming.common.block.FarmingFruitTreeLeavesBlock;
import io.github.likexiang21.tfcplus.farming.common.block.FarmingFruitTreeSaplingBlock;
import io.github.likexiang21.tfcplus.farming.common.block.FarmingFruitingBranchBlock;
import io.github.likexiang21.tfcplus.farming.common.block.FarmingGrowingFruitTreeBranchBlock;
import io.github.likexiang21.tfcplus.farming.common.item.FarmingFruitTreeSaplingItem;
import io.github.likexiang21.tfcplus.farming.common.registry.FarmingBlockEntities;
import io.github.likexiang21.tfcplus.farming.common.registry.FarmingBlocks;
import io.github.likexiang21.tfcplus.farming.common.registry.FarmingItems;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.function.Supplier;
import net.dries007.tfc.common.blocks.ExtendedProperties;
import net.dries007.tfc.common.blocks.plant.fruit.FruitTreeBranchBlock;
import net.dries007.tfc.common.blocks.plant.fruit.FruitTreeLeavesBlock;
import net.dries007.tfc.common.blocks.plant.fruit.FruitTreeSaplingBlock;
import net.dries007.tfc.common.blocks.plant.fruit.GrowingFruitTreeBranchBlock;
import net.dries007.tfc.common.blocks.plant.fruit.Lifecycle;
import net.dries007.tfc.util.climate.ClimateRange;
import net.dries007.tfc.util.data.DataManager;
import net.dries007.tfc.util.registry.RegistrationHelpers;
import net.minecraft.core.registries.BuiltInRegistries;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.world.item.BlockItem;
import net.minecraft.world.item.Item;
import net.minecraft.world.item.Items;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.SoundType;
import net.minecraft.world.level.material.MapColor;
import net.minecraft.world.level.material.PushReaction;
import net.neoforged.neoforge.registries.DeferredHolder;
import static net.dries007.tfc.common.blocks.plant.fruit.Lifecycle.DORMANT;
import static net.dries007.tfc.common.blocks.plant.fruit.Lifecycle.FLOWERING;
import static net.dries007.tfc.common.blocks.plant.fruit.Lifecycle.FRUITING;
import static net.dries007.tfc.common.blocks.plant.fruit.Lifecycle.HEALTHY;

/**
 * 果树注册 —— 照 TFC 的果树「四件套」，用一张数据表驱动 14 种温带果树。
 *
 * <h2>生长链</h2>
 * <pre>
 * 树苗 --计时--&gt; 生长中的枝条 --&gt; 枝条 + 树叶（果实挂在「结果期」的树叶上，直接采摘）
 *   ↑ TickingPlantBlockEntity      ↑ TickingPlantBlockEntity     ↑ BerryBushBlockEntity
 * </pre>
 * <b>没有独立的「树干」方块</b>：TFC 的 {@code branch} 本身就是枝干，{@code stemPos}
 * 指向最下面那一节，树叶靠它找到自己的树。
 *
 * <h2>⚠️ 属性必须带 randomTicks 与方块实体</h2>
 * 这四个方块<b>不能</b>用 {@code FarmingBlocks.deadProps()}（那是给枯死作物的最简属性集）。
 * 第一版就是这么写错的，结果「种下去一动不动」：树苗没有 {@code randomTicks()} 不会尝试生长、
 * 没有计时 BE 无处记录进度、树叶没有 BE 连「树干在哪」都不知道。
 *
 * <h2>⚠️ 方块实体用「方案 B：自建类型」</h2>
 * TFC 的 {@code TFCBlockEntities.TICK_COUNTING_PLANT / BERRY_BUSH} 只登记了 TFC 自己的方块。
 * 实测 1.21 的 {@code BlockEntity} 构造器会调 {@code validateBlockState → type.isValid(state)
 * → validBlocks.contains(block)}，而 {@code Builder.of} 存的是 {@code ImmutableSet}、
 * {@code getValidBlocks()} 又包了 {@code Collections.unmodifiableSet} ——
 * <b>没有任何公开 API 能把外部方块加进去</b>。所以借用 TFC 类型必然在放下方块时抛
 * {@code Invalid block entity … got Block{tfcfarmingplus:…}}，只能自建：
 * <ul>
 *   <li>树叶 → {@link FarmingBlockEntities#BERRY_BUSH}（与灌木同源，正好合用）；</li>
 *   <li>树苗 / 生长枝干 → {@link FarmingBlockEntities#TICK_COUNTING_PLANT}。</li>
 * </ul>
 *
 * <h2>⚠️ 代价：TFC 的静态 helper 会静默失效 —— 而且它会打断整条生长链</h2>
 * 反汇编核对过，{@code TickingPlantBlockEntity.reset/addTicks/setStemPos} 与
 * {@code BerryBushBlockEntity.reset/resetPickedTick} 内部都是
 * {@code level.getBlockEntity(pos, TFC类型)}，而它按 {@code getType() == type} 比较 ——
 * 自建类型下必然返回 empty，于是这些 helper 变成空操作。
 *
 * <p><b>这里曾经被判轻了</b>，原文写的是「受影响的只有 createTree / setPlacedBy 里的重置动作，
 * 而那时方块与 BE 都是新建的，本来就是零状态，所以实际无损失」——
 * <b>这句是错的</b>：{@code TickCounterBlockEntity} 的构造器并不把 {@code lastUpdateTick}
 * 设成当前时间，而是写死哨兵值 {@code -2147483648L}，专门留给 {@code reset()} 去播种。
 * 静态 {@code reset()} 一失效，计时器就永远停在哨兵值，
 * {@code getTicksSinceUpdate()} 恒为约 21 亿 ≫ 8 天阈值（192000），
 * 于是<b>树苗在第一次随机刻就被判成「已经长够了」</b>。
 * 这正是「果树完整生长链从未走通」的真正原因。
 *
 * <p>失效清单（反汇编逐条核对）与处理：
 * <ul>
 *   <li>{@code FruitTreeSaplingBlock.setPlacedBy} → {@code reset()}：树苗计时器不播种
 *       → <b>已由 {@link FarmingFruitTreeSaplingBlock} 在正常放置时初始化，randomTick 仅补旧苗</b>；</li>
 *   <li>{@code FruitTreeSaplingBlock.createTree} → {@code reset()} / {@code addTicks()}：
 *       换上的枝条计时器不播种、超期时间不结转（会让树苗一判定成功就瞬间展开成整棵树）
 *       → <b>同上，已补</b>；</li>
 *   <li>{@code GrowingFruitTreeBranchBlock.randomTick} → {@code reset()}：
 *       人工种植的枝条在气候不符时不暂停计时，气候一恢复就一次补长好几节
 *       → <b>已由 {@link FarmingGrowingFruitTreeBranchBlock} 补上</b>；</li>
 *   <li>{@code FruitTreeFeature.place} → {@code getBlockEntity(pos, TFC类型).ifPresent(increaseCounter)}：
 *       世界生成的项目枝条不能接收原生类型查询写入的进度；
 *       {@link FarmingGrowingFruitTreeBranchBlock} 在首次 tick 中只给自然且未初始化的枝条
 *       设置有限初始年龄，随后委托原生生长。旧“哨兵值等效无需处理”的判断已撤回。</li>
 * </ul>
 * <p>教训：<b>「新生对象是零状态」这种想当然的假设必须去字节码里核实</b> ——
 * 这里零状态不是 0，而是一个专门用来触发兜底的哨兵值。
 *
 * @see io.github.likexiang21.tfcplus.farming.common.crop.FarmingCrops 作物注册
 * @see io.github.likexiang21.tfcplus.farming.common.item.FarmingFruitTreeSaplingItem 树苗物品（种植数据提示）
 */
public final class FarmingFruitTrees {

    private static final int TICKS_PER_DAY = 24000;
    /** 树苗长成枝干所需天数 —— 与 TFC 一致（8 天） */
    private static final int DAYS_TO_GROW = 8;

    /**
     * 一种果树的全部定义。{@code lifecycle} 是 12 个月的物候，<b>索引 0 = 一月</b>
     * （TFC 的 {@code Month} 枚举也是 JANUARY=0），南半球由 TFC 自动取反。
     *
     * @param textureDonor 占位美术借用的 TFC 果树（只有 cherry/green_apple/lemon/olive/orange/peach/plum/red_apple 八套）
     */
    public record FruitTreeDefinition(String name, String englishName, String textureDonor, Lifecycle[] lifecycle,
                       int floweringColor, int minTemp, int maxTemp) {}

    /**
     * 14 种温带果树。物候按各树种的真实习性写（北半球）：
     * 杏最先开，梨/桑/唐棣春末，柿/石榴/枣/山楂/欧楂/巴婆果初夏，枇杷是唯一冬花夏果的。
     */
    public static final FruitTreeDefinition[] TREES = {
        new FruitTreeDefinition("pear", "Pear", "cherry",
            new Lifecycle[]{ DORMANT, DORMANT, HEALTHY, FLOWERING, FLOWERING, HEALTHY, FRUITING, FRUITING, HEALTHY, DORMANT, DORMANT, DORMANT },
            0xF0F0E6, -14, 28),
        new FruitTreeDefinition("apricot", "Apricot", "peach",
            new Lifecycle[]{ DORMANT, HEALTHY, FLOWERING, HEALTHY, HEALTHY, FRUITING, HEALTHY, DORMANT, DORMANT, DORMANT, DORMANT, DORMANT },
            0xF5D5DC, -14, 30),
        new FruitTreeDefinition("quince", "Quince", "green_apple",
            new Lifecycle[]{ DORMANT, DORMANT, HEALTHY, FLOWERING, FLOWERING, HEALTHY, HEALTHY, HEALTHY, FRUITING, FRUITING, HEALTHY, DORMANT },
            0xF2B8C6, -12, 30),
        new FruitTreeDefinition("persimmon", "Persimmon", "orange",
            new Lifecycle[]{ DORMANT, DORMANT, HEALTHY, HEALTHY, FLOWERING, HEALTHY, HEALTHY, HEALTHY, FRUITING, FRUITING, HEALTHY, DORMANT },
            0xF0E8C0, -10, 32),
        new FruitTreeDefinition("pomegranate", "Pomegranate", "red_apple",
            new Lifecycle[]{ DORMANT, DORMANT, HEALTHY, HEALTHY, FLOWERING, FLOWERING, HEALTHY, HEALTHY, FRUITING, FRUITING, HEALTHY, DORMANT },
            0xE86050, -8, 34),
        // 枇杷是唯一「冬花夏果」的：10~12 月开花，次年 5~6 月成熟
        new FruitTreeDefinition("loquat", "Loquat", "lemon",
            new Lifecycle[]{ HEALTHY, HEALTHY, HEALTHY, HEALTHY, FRUITING, FRUITING, HEALTHY, HEALTHY, HEALTHY, HEALTHY, FLOWERING, FLOWERING },
            0xF0E6D0, -6, 32),
        // ⚠️ 这里**不放** fig（无花果）与 elderberry（接骨木）：
        //    fig 已由 Firmalife 实现（firmalife:plant/fig_sapling + firmalife:food/fig），
        //    elderberry 已由 TFC 实现（tfc:plant/elderberry_bush，属于浆果灌木）。
        //    最初我只把 plantable 重名当「文件名撞车」用 fpt_ 前缀绕过，那是错判 ——
        //    重名说明该物种已被占用，正确做法是不新增，否则游戏里会有两套同种植物。
        //    替代品选两边都没占的花楸与山茱萸。
        new FruitTreeDefinition("sorb", "Sorb", "cherry",
            new Lifecycle[]{ DORMANT, DORMANT, HEALTHY, FLOWERING, FLOWERING, HEALTHY, HEALTHY, HEALTHY, FRUITING, FRUITING, HEALTHY, DORMANT },
            0xF0F0E6, -20, 26),
        new FruitTreeDefinition("mulberry", "Mulberry", "cherry",
            new Lifecycle[]{ DORMANT, DORMANT, HEALTHY, FLOWERING, FLOWERING, FRUITING, FRUITING, HEALTHY, DORMANT, DORMANT, DORMANT, DORMANT },
            0xD8E8A8, -14, 32),
        new FruitTreeDefinition("jujube", "Jujube", "red_apple",
            new Lifecycle[]{ DORMANT, DORMANT, DORMANT, HEALTHY, FLOWERING, FLOWERING, HEALTHY, HEALTHY, FRUITING, FRUITING, HEALTHY, DORMANT },
            0xDCE8A0, -10, 34),
        new FruitTreeDefinition("hawthorn", "Hawthorn", "cherry",
            new Lifecycle[]{ DORMANT, DORMANT, HEALTHY, HEALTHY, FLOWERING, HEALTHY, HEALTHY, HEALTHY, FRUITING, FRUITING, HEALTHY, DORMANT },
            0xF5E8E8, -18, 28),
        new FruitTreeDefinition("medlar", "Medlar", "green_apple",
            new Lifecycle[]{ DORMANT, DORMANT, HEALTHY, HEALTHY, FLOWERING, FLOWERING, HEALTHY, HEALTHY, HEALTHY, FRUITING, FRUITING, DORMANT },
            0xF5F0E6, -14, 28),
        new FruitTreeDefinition("pawpaw", "Pawpaw", "lemon",
            new Lifecycle[]{ DORMANT, DORMANT, HEALTHY, FLOWERING, FLOWERING, HEALTHY, HEALTHY, HEALTHY, FRUITING, FRUITING, HEALTHY, DORMANT },
            0xC8A0B0, -14, 30),
        new FruitTreeDefinition("crabapple", "Crabapple", "red_apple",
            new Lifecycle[]{ DORMANT, DORMANT, HEALTHY, FLOWERING, FLOWERING, HEALTHY, HEALTHY, HEALTHY, FRUITING, FRUITING, HEALTHY, DORMANT },
            0xF8E0E8, -20, 28),
        new FruitTreeDefinition("cornelian_cherry", "Cornelian Cherry", "plum",
            new Lifecycle[]{ DORMANT, DORMANT, HEALTHY, FLOWERING, FLOWERING, HEALTHY, HEALTHY, HEALTHY, FRUITING, FRUITING, HEALTHY, DORMANT },
            0xF0E8C8, -18, 30),

        // ---------------- 热带果树 14 种 ----------------
        // 物候按「旱季开花、雨季结果」的热带节律写，多数全年不落叶（DORMANT 很少）；
        // 温度区间整体偏暖，与温带那批互补 —— 温带树种在热带会因越界枯死，反之亦然。
        new FruitTreeDefinition("mango", "Mango", "orange",
            new Lifecycle[]{ HEALTHY, HEALTHY, FLOWERING, FLOWERING, HEALTHY, HEALTHY, FRUITING, FRUITING, FRUITING, HEALTHY, HEALTHY, HEALTHY },
            0xF0F0C0, 10, 40),
        new FruitTreeDefinition("papaya", "Papaya", "lemon",
            new Lifecycle[]{ HEALTHY, FLOWERING, FLOWERING, FRUITING, FRUITING, HEALTHY, HEALTHY, FLOWERING, FLOWERING, FRUITING, FRUITING, HEALTHY },
            0xF8F0E0, 12, 42),
        new FruitTreeDefinition("guava", "Guava", "cherry",
            new Lifecycle[]{ HEALTHY, HEALTHY, FLOWERING, FLOWERING, FRUITING, FRUITING, FRUITING, HEALTHY, HEALTHY, FLOWERING, FRUITING, FRUITING },
            0xF8F8F0, 8, 40),
        new FruitTreeDefinition("lychee", "Lychee", "red_apple",
            new Lifecycle[]{ DORMANT, HEALTHY, FLOWERING, FLOWERING, HEALTHY, FRUITING, FRUITING, HEALTHY, DORMANT, DORMANT, DORMANT, DORMANT },
            0xE8F0C0, 5, 38),
        new FruitTreeDefinition("longan", "Longan", "peach",
            new Lifecycle[]{ DORMANT, HEALTHY, FLOWERING, FLOWERING, HEALTHY, HEALTHY, FRUITING, FRUITING, HEALTHY, DORMANT, DORMANT, DORMANT },
            0xF0E8C0, 5, 38),
        new FruitTreeDefinition("avocado", "Avocado", "plum",
            new Lifecycle[]{ HEALTHY, FLOWERING, FLOWERING, HEALTHY, HEALTHY, FRUITING, FRUITING, FRUITING, HEALTHY, HEALTHY, HEALTHY, HEALTHY },
            0xE0E8B0, 8, 36),
        new FruitTreeDefinition("starfruit", "Starfruit", "lemon",
            new Lifecycle[]{ HEALTHY, FLOWERING, FLOWERING, FRUITING, FRUITING, HEALTHY, HEALTHY, FLOWERING, FLOWERING, FRUITING, FRUITING, HEALTHY },
            0xE8C0D0, 12, 40),
        new FruitTreeDefinition("tamarind", "Tamarind", "plum",
            new Lifecycle[]{ DORMANT, HEALTHY, HEALTHY, FLOWERING, FLOWERING, HEALTHY, HEALTHY, FRUITING, FRUITING, FRUITING, HEALTHY, DORMANT },
            0xF0E0C0, 12, 42),
        new FruitTreeDefinition("sapodilla", "Sapodilla", "orange",
            new Lifecycle[]{ HEALTHY, FLOWERING, FLOWERING, FRUITING, FRUITING, FRUITING, HEALTHY, HEALTHY, FLOWERING, FLOWERING, FRUITING, FRUITING },
            0xF0E8D8, 12, 40),
        new FruitTreeDefinition("cherimoya", "Cherimoya", "green_apple",
            new Lifecycle[]{ DORMANT, HEALTHY, FLOWERING, FLOWERING, HEALTHY, HEALTHY, FRUITING, FRUITING, HEALTHY, DORMANT, DORMANT, DORMANT },
            0xE8E8C8, 10, 34),
        new FruitTreeDefinition("rambutan", "Rambutan", "red_apple",
            new Lifecycle[]{ HEALTHY, HEALTHY, FLOWERING, FLOWERING, FRUITING, FRUITING, HEALTHY, HEALTHY, HEALTHY, FLOWERING, FRUITING, FRUITING },
            0xE8F0C8, 15, 42),
        new FruitTreeDefinition("durian", "Durian", "green_apple",
            new Lifecycle[]{ HEALTHY, FLOWERING, FLOWERING, FRUITING, FRUITING, HEALTHY, HEALTHY, HEALTHY, FLOWERING, FLOWERING, FRUITING, FRUITING },
            0xF0E8C8, 16, 42),
        new FruitTreeDefinition("jackfruit", "Jackfruit", "orange",
            new Lifecycle[]{ HEALTHY, FLOWERING, FLOWERING, FRUITING, FRUITING, FRUITING, HEALTHY, FLOWERING, FLOWERING, FRUITING, FRUITING, HEALTHY },
            0xE8F0C0, 15, 42),
        new FruitTreeDefinition("breadfruit", "Breadfruit", "olive",
            new Lifecycle[]{ HEALTHY, FLOWERING, FLOWERING, FRUITING, FRUITING, FRUITING, HEALTHY, HEALTHY, FLOWERING, FLOWERING, FRUITING, FRUITING },
            0xF0F0D0, 16, 42),

        // ---------------- 坚果 5 种（§7.1「坚果待改树」的落地） ----------------
        // 为什么要走果树机制：**TFC 里没有任何「树干果实 / 树冠果实」方块**（已反汇编确认），
        // 而「坚果要挂在树上」这个需求恰好就是果树四件套的形态 —— 果实结在树叶上。
        // 差异通过物候（坚果多在秋季成熟）与营养字段（protein 而非 fruit）体现。
        // 种子/树苗/枝条/树叶/掉落表/世界生成全部由生成器自动产出，这里只需登记数据。
        new FruitTreeDefinition("walnut", "Walnut", "green_apple",
            new Lifecycle[]{ DORMANT, DORMANT, HEALTHY, FLOWERING, FLOWERING, HEALTHY, HEALTHY, HEALTHY, FRUITING, FRUITING, HEALTHY, DORMANT },
            0xE8F0C0, -20, 30),
        new FruitTreeDefinition("hazelnut", "Hazelnut", "cherry",
            new Lifecycle[]{ FLOWERING, FLOWERING, HEALTHY, HEALTHY, FRUITING, FRUITING, HEALTHY, HEALTHY, DORMANT, DORMANT, DORMANT, DORMANT },
            0xE8E0B0, -24, 26),
        new FruitTreeDefinition("almond", "Almond", "peach",
            new Lifecycle[]{ DORMANT, FLOWERING, FLOWERING, HEALTHY, HEALTHY, FRUITING, FRUITING, HEALTHY, DORMANT, DORMANT, DORMANT, DORMANT },
            0xF8E0E8, -6, 36),
        new FruitTreeDefinition("pecan", "Pecan", "orange",
            new Lifecycle[]{ DORMANT, DORMANT, HEALTHY, FLOWERING, FLOWERING, HEALTHY, HEALTHY, FRUITING, FRUITING, FRUITING, HEALTHY, DORMANT },
            0xE0E8C0, -10, 34),
        new FruitTreeDefinition("macadamia", "Macadamia", "lemon",
            new Lifecycle[]{ HEALTHY, HEALTHY, FLOWERING, FLOWERING, FRUITING, FRUITING, HEALTHY, HEALTHY, FLOWERING, FLOWERING, FRUITING, FRUITING },
            0xF8F0E0, 8, 38),
        // ── 批次 10：老茎结果（cauliflory）6 种 ──
        //    ⚠️ Lifecycle 里**刻意不含 FRUITING** —— 这 6 种的果实长在**树干**上
        //       （由 FarmingFruitingBranchBlock 的 fruit 属性承载），树叶只开花不结果。
        //       若这里写进 FRUITING，树叶也会结果，就退化成普通果树、
        //       让「树干结果」这个机制失去意义 —— 这是本批次的**核心约定**。
        new FruitTreeDefinition("jabuticaba", "Jabuticaba", "cherry",
            new Lifecycle[]{ HEALTHY, HEALTHY, FLOWERING, FLOWERING, HEALTHY, HEALTHY, HEALTHY, HEALTHY, FLOWERING, FLOWERING, HEALTHY, HEALTHY },
            0xF0F0F0, 12, 38),
        new FruitTreeDefinition("soursop", "Soursop", "green_apple",
            new Lifecycle[]{ HEALTHY, FLOWERING, FLOWERING, HEALTHY, HEALTHY, HEALTHY, HEALTHY, FLOWERING, FLOWERING, HEALTHY, HEALTHY, HEALTHY },
            0xE8E8B0, 15, 40),
        new FruitTreeDefinition("mangosteen", "Mangosteen", "red_apple",
            new Lifecycle[]{ HEALTHY, HEALTHY, HEALTHY, FLOWERING, FLOWERING, HEALTHY, HEALTHY, HEALTHY, FLOWERING, FLOWERING, HEALTHY, HEALTHY },
            0xF0D8E0, 16, 42),
        new FruitTreeDefinition("cupuacu", "Cupuacu", "orange",
            new Lifecycle[]{ HEALTHY, HEALTHY, FLOWERING, FLOWERING, FLOWERING, HEALTHY, HEALTHY, HEALTHY, HEALTHY, FLOWERING, FLOWERING, HEALTHY },
            0xC86070, 18, 42),
        new FruitTreeDefinition("bael", "Bael", "orange",
            new Lifecycle[]{ DORMANT, HEALTHY, HEALTHY, FLOWERING, FLOWERING, HEALTHY, HEALTHY, HEALTHY, HEALTHY, FLOWERING, HEALTHY, DORMANT },
            0xE0E8C8, 14, 40),
        new FruitTreeDefinition("canistel", "Canistel", "peach",
            new Lifecycle[]{ HEALTHY, HEALTHY, FLOWERING, FLOWERING, HEALTHY, HEALTHY, HEALTHY, FLOWERING, FLOWERING, HEALTHY, HEALTHY, HEALTHY },
            0xF0E8C0, 15, 40),
        // 保留旧 cocoa 注册名以兼容存档，但它不再作为可可生产入口；可可统一由 cupuacu 产出。
        new FruitTreeDefinition("cocoa", "Cocoa", "orange",
            new Lifecycle[]{ HEALTHY, HEALTHY, FLOWERING, FLOWERING, HEALTHY, HEALTHY, HEALTHY, HEALTHY, HEALTHY, HEALTHY, FLOWERING, FLOWERING },
            0xE8D8B0, 12, 38),
        new FruitTreeDefinition("black_pepper", "Black Pepper", "green_apple",
            new Lifecycle[]{ HEALTHY, FLOWERING, FLOWERING, HEALTHY, HEALTHY, FLOWERING, FLOWERING, HEALTHY, HEALTHY, HEALTHY, HEALTHY, HEALTHY },
            0xD8E8A0, 18, 38),   // 批次 10 续：黑胡椒 —— 藤本，果穗成串垂挂（叶只开花，果在干上）
        new FruitTreeDefinition("waxberry", "Waxberry", "red_apple",
            new Lifecycle[]{ DORMANT, DORMANT, HEALTHY, FLOWERING, FLOWERING, HEALTHY, FRUITING, FRUITING, HEALTHY, DORMANT, DORMANT, DORMANT },
            0xC8D8A0, 5, 30),
        new FruitTreeDefinition("lime", "Lime", "lemon",
            new Lifecycle[]{ HEALTHY, FLOWERING, FLOWERING, HEALTHY, FRUITING, FRUITING, FRUITING, HEALTHY, FLOWERING, FLOWERING, HEALTHY, HEALTHY },
            0xF0F0D0, 12, 38),
        new FruitTreeDefinition("grapefruit", "Grapefruit", "orange",
            new Lifecycle[]{ DORMANT, HEALTHY, FLOWERING, FLOWERING, HEALTHY, HEALTHY, HEALTHY, HEALTHY, FRUITING, FRUITING, HEALTHY, DORMANT },
            0xF8E8E0, 10, 36),
        new FruitTreeDefinition("kiwi", "Kiwi", "plum",
            new Lifecycle[]{ DORMANT, DORMANT, HEALTHY, HEALTHY, FLOWERING, FLOWERING, HEALTHY, HEALTHY, FRUITING, FRUITING, HEALTHY, DORMANT },
            0xE8E0C0, -5, 28),
        new FruitTreeDefinition("wax_apple", "Wax Apple", "red_apple",
            new Lifecycle[]{ HEALTHY, HEALTHY, FLOWERING, FLOWERING, HEALTHY, FRUITING, FRUITING, HEALTHY, HEALTHY, FLOWERING, FLOWERING, HEALTHY },
            0xF0D8D8, 18, 38),
        new FruitTreeDefinition("wampee", "Wampee", "lemon",
            new Lifecycle[]{ HEALTHY, FLOWERING, FLOWERING, HEALTHY, HEALTHY, HEALTHY, FRUITING, FRUITING, HEALTHY, HEALTHY, HEALTHY, HEALTHY },
            0xE8E8B0, 12, 34),
        new FruitTreeDefinition("amla", "Amla", "green_apple",
            new Lifecycle[]{ HEALTHY, HEALTHY, FLOWERING, FLOWERING, HEALTHY, HEALTHY, HEALTHY, HEALTHY, HEALTHY, FRUITING, FRUITING, HEALTHY },
            0xD8E8B0, 15, 40),
        new FruitTreeDefinition("sea_buckthorn", "Sea Buckthorn", "orange",
            new Lifecycle[]{ DORMANT, DORMANT, DORMANT, HEALTHY, FLOWERING, FLOWERING, HEALTHY, FRUITING, FRUITING, HEALTHY, DORMANT, DORMANT },
            0xD8E0A8, -15, 24),
    };

    // ---------------------------------------------------------------- 注册结果
    // name → 各部件。用 LinkedHashMap 保持 TREES 的顺序，便于调试与创造标签页。

    public static final Map<String, DeferredHolder<Item, Item>> FRUITS = new LinkedHashMap<>();
    public static final Map<String, DeferredHolder<Block, FruitTreeBranchBlock>> BRANCHES = new LinkedHashMap<>();
    public static final Map<String, DeferredHolder<Block, FruitTreeLeavesBlock>> LEAVES = new LinkedHashMap<>();
    public static final Map<String, DeferredHolder<Block, GrowingFruitTreeBranchBlock>> GROWING_BRANCHES = new LinkedHashMap<>();
    public static final Map<String, DeferredHolder<Block, FruitTreeSaplingBlock>> SAPLINGS = new LinkedHashMap<>();
    public static final Map<String, DataManager.Reference<ClimateRange>> CLIMATES = new LinkedHashMap<>();

    static {
        for (final FruitTreeDefinition treeDefinition : TREES) {
            final String speciesName = treeDefinition.name();
            final boolean legacyCocoa = "cocoa".equals(speciesName);
            final DataManager.Reference<ClimateRange> climateReference = climate("plant/" + speciesName + "_tree");
            CLIMATES.put(speciesName, climateReference);

            // 果实物品（食物数据由 tools/gen-fruit-trees.ps1 写成 data/tfcfarmingplus/tfc/food/<speciesName>.json）
            FRUITS.put(speciesName, FarmingItems.ITEMS.register("food/" + speciesName, () -> new Item(new Item.Properties())));

            // 枝干：无物品（TFC 也没有它的物品模型）
            final DeferredHolder<Block, FruitTreeBranchBlock> branch = registerNoItem(
                "plant/" + speciesName + "_branch",
                () -> FarmingBranchFruits.isBranchFruit(speciesName)
                    ? new FarmingFruitingBranchBlock(branchFruitProps(), climateReference, fruitProduct(speciesName), FarmingBranchFruits.lifecycle(speciesName))
                    : new FruitTreeBranchBlock(branchProps(), climateReference));

            // 树叶：有物品，果实就挂在它的结果期上
            final DeferredHolder<Block, FruitTreeLeavesBlock> leaves = register(
                "plant/" + speciesName + "_leaves",
                () -> new FarmingFruitTreeLeavesBlock(leavesProps(), fruitProduct(speciesName), treeDefinition.lifecycle(), climateReference, treeDefinition.floweringColor()),
                b -> new BlockItem(b, new Item.Properties()));

            // 生长枝干：无物品。⚠️ 必须用 FarmingGrowingFruitTreeBranchBlock（补 TFC 失效的「气候不符暂停」）
            final DeferredHolder<Block, GrowingFruitTreeBranchBlock> growing = registerNoItem(
                "plant/" + speciesName + "_growing_branch",
                () -> (GrowingFruitTreeBranchBlock) new FarmingGrowingFruitTreeBranchBlock(growingProps(),
                    legacyCocoa ? () -> BRANCHES.get("cupuacu").get() : branch,
                    legacyCocoa ? () -> LEAVES.get("cupuacu").get() : leaves, climateReference));

            // 树苗：有物品；物品类实现 PlantableInfo 才有「气候 / 生命周期 / 生长时间」提示
            // ⚠️ 必须用 FarmingFruitTreeSaplingBlock（补 TFC 失效的计时器初始化，否则树苗放下即「长够」）
            final DeferredHolder<Block, FruitTreeSaplingBlock> sapling = register(
                "plant/" + speciesName + "_sapling",
                // Keep the old block/state/BE IDs readable. Legacy saplings and
                // growth tips mature into cupuacu through the existing TFC pipeline.
                () -> (FruitTreeSaplingBlock) new FarmingFruitTreeSaplingBlock(saplingProps(),
                    legacyCocoa ? () -> GROWING_BRANCHES.get("cupuacu").get() : growing,
                    () -> DAYS_TO_GROW * TICKS_PER_DAY, climateReference, treeDefinition.lifecycle()),
                b -> new FarmingFruitTreeSaplingItem(b, () -> climateReference.get(), treeDefinition.lifecycle(),
                    () -> ((FruitTreeSaplingBlock) b).getTicksToGrow()));

            BRANCHES.put(speciesName, branch);
            LEAVES.put(speciesName, leaves);
            GROWING_BRANCHES.put(speciesName, growing);
            SAPLINGS.put(speciesName, sapling);
        }
    }

    /**
     * The large-flowered cupuacu tree is the sole cocoa source.  Resolve the
     * Firmalife item from the runtime registry so A stays loadable without a
     * compile-time Firmalife dependency. Legacy cocoa leaves also use this item
     * when an old save still contains a harvestable fruiting state.
     */
    private static Supplier<? extends Item> fruitProduct(final String name) {
        if ("cupuacu".equals(name) || "cocoa".equals(name)) {
            return () -> {
                final Item cocoaBeans = BuiltInRegistries.ITEM.get(
                    ResourceLocation.fromNamespaceAndPath("firmalife", "food/cocoa_beans"));
                if (cocoaBeans == Items.AIR) {
                    throw new IllegalStateException("Firmalife cocoa beans are required for cupuacu harvests");
                }
                return cocoaBeans;
            };
        }
        return () -> FRUITS.get(name).get();
    }

    // ---------------------------------------------------------------- 属性集
    // 全部照 TFC 的 FruitBlocks.Tree.createXxx()，逐项核对过。

    private static ExtendedProperties branchProps() {
        return ExtendedProperties.of(MapColor.WOOD).sound(SoundType.SCAFFOLDING).randomTicks()
            .strength(1.0f).pushReaction(PushReaction.DESTROY).flammableLikeLogs();
    }

    private static ExtendedProperties leavesProps() {
        return ExtendedProperties.of().mapColor(MapColor.PLANT).strength(0.5f).sound(SoundType.GRASS)
            .randomTicks().noOcclusion()
            .blockEntity(FarmingBlockEntities.BERRY_BUSH)     // ★ 结果期判定 / 采摘计时 / stemPos 靠它，必须绑
            .flammableLikeLeaves();
    }

    private static ExtendedProperties growingProps() {
        return ExtendedProperties.of(MapColor.WOOD).sound(SoundType.SCAFFOLDING).randomTicks()
            .strength(1.0f).pushReaction(PushReaction.DESTROY)
            .blockEntity(FarmingBlockEntities.TICK_COUNTING_PLANT).flammableLikeLogs().cloneEmpty();
    }

    /**
     * 会结果的枝干属性 —— 在普通枝干之上挂计时器。
     * 果实状态（{@code fruit}）的推进靠它：{@code TickingPlantBlockEntity} 提供
     * {@code getTicksSinceUpdate()} / {@code resetCounter()} 与 {@code stemPos}。
     */
    private static ExtendedProperties branchFruitProps() {
        return branchProps().blockEntity(FarmingBlockEntities.TICK_COUNTING_PLANT);
    }

    private static ExtendedProperties saplingProps() {
        return ExtendedProperties.of(MapColor.PLANT).noCollission().randomTicks().strength(0.0f)
            .sound(SoundType.GRASS)
            .blockEntity(FarmingBlockEntities.TICK_COUNTING_PLANT).flammableLikeLeaves();
    }

    // ---------------------------------------------------------------- 查询接口

    /** 需要 BERRY_BUSH 的方块（结果与采摘）—— 供 {@link FarmingBlockEntities#BERRY_BUSH} 登记 */
    public static Block[] fruitingBlocks() {
        final List<Block> blockList = new ArrayList<>();
        for (DeferredHolder<Block, FruitTreeLeavesBlock> holder : LEAVES.values()) {
            blockList.add(holder.get());
        }
        return blockList.toArray(new Block[0]);
    }

    /** 需要计时器的方块（树苗与生长枝干）—— 供 {@link FarmingBlockEntities#TICK_COUNTING_PLANT} 登记 */
    public static Block[] tickingBlocks() {
        final List<Block> blockList = new ArrayList<>();
        for (DeferredHolder<Block, FruitTreeSaplingBlock> holder : SAPLINGS.values()) {
            blockList.add(holder.get());
        }
        for (DeferredHolder<Block, GrowingFruitTreeBranchBlock> holder : GROWING_BRANCHES.values()) {
            blockList.add(holder.get());
        }
        // 会结果的成熟枝干：它们的 ExtendedProperties 带 TICK_COUNTING_PLANT，
        // 果实状态靠计时器推进（见 FarmingFruitingBranchBlock）。
        for (Map.Entry<String, DeferredHolder<Block, FruitTreeBranchBlock>> e : BRANCHES.entrySet()) {
            if (FarmingBranchFruits.isBranchFruit(e.getKey())) {
                blockList.add(e.getValue().get());
            }
        }
        return blockList.toArray(new Block[0]);
    }

    private static DataManager.Reference<ClimateRange> climate(String path) {
        return ClimateRange.MANAGER.getReference(
            ResourceLocation.fromNamespaceAndPath(TFCFarmingPlus.MOD_ID, path));
    }

    private static <T extends Block> DeferredHolder<Block, T> register(
            String name, Supplier<T> supplier, Function<T, ? extends BlockItem> factory) {
        return RegistrationHelpers.registerBlock(FarmingBlocks.BLOCKS, FarmingItems.ITEMS, name, supplier, factory);
    }

    private static <T extends Block> DeferredHolder<Block, T> registerNoItem(String name, Supplier<T> supplier) {
        return RegistrationHelpers.registerBlock(FarmingBlocks.BLOCKS, null, name, supplier, null);
    }

    /** 触发静态初始化 —— 主类必须调用一次 */
    public static void init() {}

    private FarmingFruitTrees() {}
}
