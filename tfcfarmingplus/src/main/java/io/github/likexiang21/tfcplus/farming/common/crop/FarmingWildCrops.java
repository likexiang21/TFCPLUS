package io.github.likexiang21.tfcplus.farming.common.crop;

import io.github.likexiang21.tfcplus.farming.common.registry.FarmingBlocks;
import io.github.likexiang21.tfcplus.farming.common.registry.FarmingItems;
import java.util.ArrayList;
import java.util.List;
import net.dries007.tfc.common.blocks.crop.FloodedWildCropBlock;
import net.dries007.tfc.common.blocks.crop.WildCropBlock;
import net.dries007.tfc.util.registry.RegistrationHelpers;
import net.minecraft.world.item.BlockItem;
import net.minecraft.world.item.Item;
import net.minecraft.world.level.block.Block;
import net.neoforged.neoforge.registries.DeferredHolder;

/**
 * 批次 2.5：野生作物（8 种）—— <b>种子的唯一原版式来源</b>。
 * <p>
 * 为什么必须做：TFC 的作物种子只能通过打掉野生作物获得（没有种子合成配方）。
 * 只注册作物方块而不注册野生版本，玩家将永远拿不到种子，作物形同不存在。
 * <p>
 * <b>零新方块类</b> —— 直接实例化 TFC 的 {@link WildCropBlock}（构造器 public）。
 * 该方块不含方块实体，靠 {@code randomTick} 依据 TFC 服务器配置的
 * {@code wildCropMaturityStartMonth / EndMonth} 在两个状态间切换：
 * <ul>
 *   <li>{@code mature=true} → 掉产物（1~3）+ 1 个种子</li>
 *   <li>{@code mature=false} → 只掉 1 个种子</li>
 * </ul>
 * 生存条件由 TFC 写死为下方方块属于 {@code #tfc:wild_crop_grows_on}（= {@code #minecraft:dirt}）。
 * <p>
 * 世界生成注入点（与 TFC 完全同构）：
 * <pre>
 * data/tfcfarmingplus/worldgen/configured_feature/plant/wild_crop/&lt;name&gt;.json        (simple_block 单株)
 * data/tfcfarmingplus/worldgen/configured_feature/plant/wild_crop/&lt;name&gt;_patch.json  (random_patch)
 * data/tfcfarmingplus/worldgen/placed_feature/plant/wild_crop/&lt;name&gt;_patch.json      (+ tfc:climate 筛选)
 * data/tfc/tags/worldgen/placed_feature/feature/crops.json                      ← 追加式写入
 * </pre>
 * 最后那个 tag 被 TFC 的 {@code #tfc:feature/land_plants} 引用，而 land_plants 又被各
 * {@code #tfc:in_biome/surface_decoration/&lt;地形&gt;} 引用 —— 因此只需追加一次，
 * 8 种野生作物就会按各自的气候区间出现在全部陆地生物群系中。
 */
public final class FarmingWildCrops {

    /**
     * 全部野生作物的 holder —— 由工厂方法**自动收集**，新增野生作物时无需改任何列表。
     * <p>
     * 之所以要这个：客户端要在**两处**用到全部野生作物（渲染层 cutout 登记、草色着色），
     * 过去两处都是手写常量表，新增作物忘了同步就会被渲染成黑块 / 不随生物群系着色。
     * 现在只有这一份，且是自动的。
     * <p>
     * ⚠️ 存 holder 而不是 {@code .get()} 的结果：本类的静态字段在**类初始化期**执行，
     * 那时注册表还没绑定完，直接 {@code get()} 会抛异常。解引用推迟到 {@link #wildBlocks()}。
     */
    private static final List<DeferredHolder<Block, ? extends Block>> ALL = new ArrayList<>();

    public static final DeferredHolder<Block, WildCropBlock> WILD_SPINACH = wild("spinach");
    public static final DeferredHolder<Block, WildCropBlock> WILD_LETTUCE = wild("lettuce");
    public static final DeferredHolder<Block, WildCropBlock> WILD_CELERY = wild("celery");
    public static final DeferredHolder<Block, WildCropBlock> WILD_KALE = wild("kale");
    public static final DeferredHolder<Block, WildCropBlock> WILD_NAPA_CABBAGE = wild("napa_cabbage");
    public static final DeferredHolder<Block, WildCropBlock> WILD_MUSTARD_GREENS = wild("mustard_greens");
    public static final DeferredHolder<Block, WildCropBlock> WILD_BROCCOLI = wild("broccoli");
    public static final DeferredHolder<Block, WildCropBlock> WILD_CAULIFLOWER = wild("cauliflower");
    public static final DeferredHolder<Block, WildCropBlock> WILD_BRUSSELS_SPROUTS = wild("brussels_sprouts");
    public static final DeferredHolder<Block, WildCropBlock> WILD_SWISS_CHARD = wild("swiss_chard");
    public static final DeferredHolder<Block, WildCropBlock> WILD_CELTUCE = wild("celtuce");
    public static final DeferredHolder<Block, WildCropBlock> WILD_GARLAND_CHRYSANTHEMUM = wild("garland_chrysanthemum");
    public static final DeferredHolder<Block, WildCropBlock> WILD_PERILLA = wild("perilla");
    public static final DeferredHolder<Block, WildCropBlock> WILD_ARUGULA = wild("arugula");
    public static final DeferredHolder<Block, WildCropBlock> WILD_TURNIP = wild("turnip");
    public static final DeferredHolder<Block, WildCropBlock> WILD_PARSNIP = wild("parsnip");
    public static final DeferredHolder<Block, WildCropBlock> WILD_SUNCHOKE = wild("sunchoke");
    public static final DeferredHolder<Block, WildCropBlock> WILD_SHALLOT = wild("shallot");
    public static final DeferredHolder<Block, WildCropBlock> WILD_CELERIAC = wild("celeriac");
    public static final DeferredHolder<Block, WildCropBlock> WILD_SALSIFY = wild("salsify");
    public static final DeferredHolder<Block, WildCropBlock> WILD_GINGER = wild("ginger");
    public static final DeferredHolder<Block, WildCropBlock> WILD_TURMERIC = wild("turmeric");
    public static final DeferredHolder<Block, WildCropBlock> WILD_YACON = wild("yacon");
    public static final DeferredHolder<Block, WildCropBlock> WILD_CHICORY_ROOT = wild("chicory_root");
    // 批次 3：谷物（12 种）
    public static final DeferredHolder<Block, WildCropBlock> WILD_MILLET = wild("millet");
    public static final DeferredHolder<Block, WildCropBlock> WILD_FOXTAIL_MILLET = wild("foxtail_millet");
    public static final DeferredHolder<Block, WildCropBlock> WILD_BUCKWHEAT = wild("buckwheat");
    public static final DeferredHolder<Block, WildCropBlock> WILD_FONIO = wild("fonio");
    public static final DeferredHolder<Block, WildCropBlock> WILD_SPELT = wild("spelt");
    public static final DeferredHolder<Block, WildCropBlock> WILD_EMMER = wild("emmer");
    public static final DeferredHolder<Block, WildCropBlock> WILD_EINKORN = wild("einkorn");
    public static final DeferredHolder<Block, WildCropBlock> WILD_PEARL_MILLET = wild("pearl_millet");
    public static final DeferredHolder<Block, WildCropBlock> WILD_AMARANTH = wild("amaranth");
    public static final DeferredHolder<Block, WildCropBlock> WILD_QUINOA = wild("quinoa");
    public static final DeferredHolder<Block, WildCropBlock> WILD_FINGER_MILLET = wild("finger_millet");
    public static final DeferredHolder<Block, WildCropBlock> WILD_JOBS_TEARS = wild("jobs_tears");
    public static final DeferredHolder<Block, WildCropBlock> WILD_CHICKPEA = wild("chickpea");
    public static final DeferredHolder<Block, WildCropBlock> WILD_FABA_BEAN = wild("faba_bean");
    public static final DeferredHolder<Block, WildCropBlock> WILD_LUPIN = wild("lupin");
    public static final DeferredHolder<Block, WildCropBlock> WILD_ADZUKI = wild("adzuki");
    public static final DeferredHolder<Block, WildCropBlock> WILD_BAMBARA_NUT = wild("bambara_nut");
    public static final DeferredHolder<Block, WildCropBlock> WILD_FENUGREEK = wild("fenugreek");
    public static final DeferredHolder<Block, WildCropBlock> WILD_CHILI = wild("chili");
    public static final DeferredHolder<Block, WildCropBlock> WILD_EGGPLANT = wild("eggplant");
    public static final DeferredHolder<Block, WildCropBlock> WILD_OKRA = wild("okra");
    public static final DeferredHolder<Block, WildCropBlock> WILD_COTTON = wild("cotton");
    public static final DeferredHolder<Block, WildCropBlock> WILD_ASPARAGUS = wild("asparagus");
    public static final DeferredHolder<Block, WildCropBlock> WILD_CHIVE = wild("chive");
    public static final DeferredHolder<Block, WildCropBlock> WILD_RHUBARB = wild("rhubarb");
    public static final DeferredHolder<Block, WildCropBlock> WILD_ARTICHOKE = wild("artichoke");
    public static final DeferredHolder<Block, WildCropBlock> WILD_FLAX = wild("flax");
    public static final DeferredHolder<Block, WildCropBlock> WILD_SESAME = wild("sesame");
    public static final DeferredHolder<Block, WildCropBlock> WILD_SAFFLOWER = wild("safflower");
    public static final DeferredHolder<Block, WildCropBlock> WILD_RAMIE = wild("ramie");
    // ------------------------------------------------------------------
    // 🆕 2026-09-29 修复：批次 3 漏注册的 9 个（5 豆类 + 2 纤维 + 2 高秆）
    // ------------------------------------------------------------------
    // 症状：世界生成报 `Unknown registry key ... minecraft:block]: tfcfarmingplus:wild_crop/<name>`
    //       ⇒ `Failed to load registries due to above errors` ⇒ **存档彻底打不开**。
    // 成因：`blockstates/wild_crop/` 已生成 **86** 个（且 `data/tfc/tags/worldgen/**/crops.json`
    //       已把 86 条全部写进世界生成），但本类只注册了 **77** 个（67 wild + 10 wildFlooded）
    //       ⇒ 有 9 个 patch 引用了**不存在的方块**。
    // ⚠️ 为什么 `tools/verify.ps1` 查不出来：它只校验**资源之间**的交叉引用，
    //    不校验「资源引用的方块是否在 Java 里注册过」。**这一类只能靠实机验证暴露。**
    public static final DeferredHolder<Block, WildCropBlock> WILD_COMMON_BEAN = wild("common_bean");
    public static final DeferredHolder<Block, WildCropBlock> WILD_COWPEA = wild("cowpea");
    public static final DeferredHolder<Block, WildCropBlock> WILD_PEA = wild("pea");
    public static final DeferredHolder<Block, WildCropBlock> WILD_PIGEON_PEA = wild("pigeon_pea");
    public static final DeferredHolder<Block, WildCropBlock> WILD_WINGED_BEAN = wild("winged_bean");
    public static final DeferredHolder<Block, WildCropBlock> WILD_HEMP = wild("hemp");
    public static final DeferredHolder<Block, WildCropBlock> WILD_SISAL = wild("sisal");
    public static final DeferredHolder<Block, WildCropBlock> WILD_SORGHUM = wild("sorghum");
    public static final DeferredHolder<Block, WildCropBlock> WILD_SUNFLOWER = wild("sunflower");
    // ---------------- 批次 5：水田作物的野生形态（10 种，含水方块） ----------------
    public static final DeferredHolder<Block, FloodedWildCropBlock> WILD_TARO = wildFlooded("taro");
    public static final DeferredHolder<Block, FloodedWildCropBlock> WILD_WATER_CHESTNUT = wildFlooded("water_chestnut");
    public static final DeferredHolder<Block, FloodedWildCropBlock> WILD_WATER_CALTROP = wildFlooded("water_caltrop");
    public static final DeferredHolder<Block, FloodedWildCropBlock> WILD_WILD_RICE_STEM = wildFlooded("wild_rice_stem");
    public static final DeferredHolder<Block, FloodedWildCropBlock> WILD_LOTUS = wildFlooded("lotus");
    public static final DeferredHolder<Block, FloodedWildCropBlock> WILD_WATER_DROPWORT = wildFlooded("water_dropwort");
    public static final DeferredHolder<Block, FloodedWildCropBlock> WILD_WATER_SPINACH = wildFlooded("water_spinach");
    public static final DeferredHolder<Block, FloodedWildCropBlock> WILD_ARROWHEAD = wildFlooded("arrowhead");
    public static final DeferredHolder<Block, FloodedWildCropBlock> WILD_GORGON_NUT = wildFlooded("gorgon_nut");
    public static final DeferredHolder<Block, FloodedWildCropBlock> WILD_WATER_SHIELD = wildFlooded("water_shield");
    // 批次 6：瓜类的野生形态（TFC 的野生西瓜也是普通方块，不是藤）
    public static final DeferredHolder<Block, WildCropBlock> WILD_CANTALOUPE = wild("cantaloupe");
    public static final DeferredHolder<Block, WildCropBlock> WILD_WINTER_MELON = wild("winter_melon");
    public static final DeferredHolder<Block, WildCropBlock> WILD_BOTTLE_GOURD = wild("bottle_gourd");
    public static final DeferredHolder<Block, WildCropBlock> WILD_CHAYOTE = wild("chayote");
    public static final DeferredHolder<Block, WildCropBlock> WILD_HOPS = wild("hops");
    public static final DeferredHolder<Block, WildCropBlock> WILD_LOOFAH = wild("loofah");
    public static final DeferredHolder<Block, WildCropBlock> WILD_BITTER_MELON = wild("bitter_melon");
    public static final DeferredHolder<Block, WildCropBlock> WILD_SNAKE_GOURD = wild("snake_gourd");
    public static final DeferredHolder<Block, WildCropBlock> WILD_YAM = wild("yam");
    public static final DeferredHolder<Block, WildCropBlock> WILD_MALABAR_SPINACH = wild("malabar_spinach");
    // 批次 12：莲座类的野生形态（野生版仍是普通 WildCropBlock —— 莲座的两个状态只影响栽培方块）
    public static final DeferredHolder<Block, WildCropBlock> WILD_CARDOON = wild("cardoon");
    public static final DeferredHolder<Block, WildCropBlock> WILD_AGAVE = wild("agave");
    public static final DeferredHolder<Block, WildCropBlock> WILD_PURSLANE = wild("purslane");
    public static final DeferredHolder<Block, WildCropBlock> WILD_STRAWBERRY = wild("strawberry");

    private static DeferredHolder<Block, WildCropBlock> wild(String name) {
        final DeferredHolder<Block, WildCropBlock> holder =
            RegistrationHelpers.registerBlock(FarmingBlocks.BLOCKS, FarmingItems.ITEMS, "wild_crop/" + name,
                () -> new WildCropBlock(FarmingBlocks.deadProps()),
                block -> new BlockItem(block, new Item.Properties()));
        ALL.add(holder);
        return holder;
    }
    /** 水田作物的野生形态：多实现 IFluidLoggable，自然生成在水边（照 TFC 的 FloodedWildCropBlock） */
    private static DeferredHolder<Block, FloodedWildCropBlock> wildFlooded(String name) {
        final DeferredHolder<Block, FloodedWildCropBlock> holder =
            RegistrationHelpers.registerBlock(FarmingBlocks.BLOCKS, FarmingItems.ITEMS, "wild_crop/" + name,
                () -> new FloodedWildCropBlock(FarmingBlocks.deadProps()),
                block -> new BlockItem(block, new Item.Properties()));
        ALL.add(holder);
        return holder;
    }

    /**
     * 全部野生作物方块 —— <b>自动收集</b>，新增野生作物无需改任何列表。
     * <p>
     * 供客户端做两件事：渲染层 {@code cutout} 登记，以及野生作物的<b>草色着色</b>
     * （TFC 对 {@code WILD_CROPS} 整体应用生物群系草色）。
     * <p>
     * 这两个用途过去各有一份手写常量表，漏同步就是「渲染成黑块」或「不随群系着色」。
     */
    public static Block[] wildBlocks() {
        return ALL.stream().map(DeferredHolder::get).toArray(Block[]::new);
    }

    /** 触发静态初始化 —— 主类必须调用一次 */
    public static void init() {}

    private FarmingWildCrops() {}
}
