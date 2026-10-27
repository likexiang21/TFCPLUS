package com.example.tfcfarmingplus.common;

import com.example.tfcfarmingplus.TFCFarmingPlus;
import com.example.tfcfarmingplus.common.blocks.MyCropBlock;
import com.example.tfcfarmingplus.common.blocks.MyFloodedCropBlock;
import net.dries007.tfc.common.blocks.crop.FloodedDeadCropBlock;
import com.example.tfcfarmingplus.common.blocks.MyDoubleCropBlock;
import com.example.tfcfarmingplus.common.blocks.MySpreadingCropBlock;
import com.example.tfcfarmingplus.common.blocks.MyClimbingCropBlock;
import com.example.tfcfarmingplus.common.blocks.MyDecayingBlock;
import net.dries007.tfc.common.blocks.crop.DeadClimbingCropBlock;
import net.dries007.tfc.common.blocks.crop.DeadDoubleCropBlock;
import net.dries007.tfc.common.blockentities.DecayingBlockEntity;
import net.dries007.tfc.common.blocks.crop.DecayingBlock;
import net.minecraft.world.level.block.state.BlockBehaviour;
import com.example.tfcfarmingplus.common.blocks.MyPickableCropBlock;
import com.example.tfcfarmingplus.common.blocks.RosetteCropBlock;
import com.example.tfcfarmingplus.common.items.MySeedItem;
import net.dries007.tfc.common.blockentities.CropBlockEntity;
import net.dries007.tfc.common.blocks.crop.DeadCropBlock;
import net.dries007.tfc.util.climate.ClimateRange;
import net.dries007.tfc.util.data.DataManager;
import net.dries007.tfc.util.registry.RegistrationHelpers;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.world.item.BlockItem;
import net.minecraft.world.item.Item;
import net.minecraft.world.level.block.Block;
import net.neoforged.neoforge.registries.DeferredHolder;

import java.util.function.Supplier;

/**
 * 批次 2：单格蔬菜（8 种）。
 * <p>
 * 使用自有的 {@link MyCropBlock}（TFC 的工厂绑定 {@code Crop} 枚举，附属模组用不了）。
 * 生长速率由 TFC 全局统一（约 24 天），{@code maxAge} 只决定视觉阶段数：
 * <ul>
 *   <li>{@code maxAge = 5} → age 0~5，6 个阶段（24÷6 = 每阶段 4 天）</li>
 *   <li>{@code maxAge = 6} → age 0~6，7 个阶段（每阶段约 3.4 天）</li>
 * </ul>
 */
public final class MyCrops {

    /** 气候引用（惰性绑定，可安全用于静态初始化期） */
    private static DataManager.Reference<ClimateRange> climate(String path) {
        return ClimateRange.MANAGER.getReference(ResourceLocation.fromNamespaceAndPath(TFCFarmingPlus.MOD_ID, path));
    }

    // ---------------- 气候引用 ----------------
    public static final DataManager.Reference<ClimateRange> SPINACH_CLIMATE = climate("crop/spinach");
    public static final DataManager.Reference<ClimateRange> LETTUCE_CLIMATE = climate("crop/lettuce");
    public static final DataManager.Reference<ClimateRange> CELERY_CLIMATE = climate("crop/celery");
    public static final DataManager.Reference<ClimateRange> KALE_CLIMATE = climate("crop/kale");
    public static final DataManager.Reference<ClimateRange> NAPA_CABBAGE_CLIMATE = climate("crop/napa_cabbage");
    public static final DataManager.Reference<ClimateRange> MUSTARD_GREENS_CLIMATE = climate("crop/mustard_greens");
    public static final DataManager.Reference<ClimateRange> BROCCOLI_CLIMATE = climate("crop/broccoli");
    public static final DataManager.Reference<ClimateRange> CAULIFLOWER_CLIMATE = climate("crop/cauliflower");
    /** 第 14 步：草莓普通作物气候。 */
    public static final DataManager.Reference<ClimateRange> STRAWBERRY_CLIMATE = climate("crop/strawberry");
    public static final DataManager.Reference<ClimateRange> BRUSSELS_SPROUTS_CLIMATE = climate("crop/brussels_sprouts");
    public static final DataManager.Reference<ClimateRange> SWISS_CHARD_CLIMATE = climate("crop/swiss_chard");
    public static final DataManager.Reference<ClimateRange> CELTUCE_CLIMATE = climate("crop/celtuce");
    public static final DataManager.Reference<ClimateRange> GARLAND_CHRYSANTHEMUM_CLIMATE = climate("crop/garland_chrysanthemum");
    public static final DataManager.Reference<ClimateRange> PERILLA_CLIMATE = climate("crop/perilla");
    public static final DataManager.Reference<ClimateRange> ARUGULA_CLIMATE = climate("crop/arugula");
    public static final DataManager.Reference<ClimateRange> TURNIP_CLIMATE = climate("crop/turnip");
    public static final DataManager.Reference<ClimateRange> PARSNIP_CLIMATE = climate("crop/parsnip");
    public static final DataManager.Reference<ClimateRange> SUNCHOKE_CLIMATE = climate("crop/sunchoke");
    public static final DataManager.Reference<ClimateRange> SHALLOT_CLIMATE = climate("crop/shallot");
    public static final DataManager.Reference<ClimateRange> CELERIAC_CLIMATE = climate("crop/celeriac");
    public static final DataManager.Reference<ClimateRange> SALSIFY_CLIMATE = climate("crop/salsify");
    // ── 批次 13：香料类根茎（姜科）── TFC 没有香料机制，按蔬菜接入食物体系
    public static final DataManager.Reference<ClimateRange> GINGER_CLIMATE = climate("crop/ginger");
    public static final DataManager.Reference<ClimateRange> TURMERIC_CLIMATE = climate("crop/turmeric");
    public static final DataManager.Reference<ClimateRange> YACON_CLIMATE = climate("crop/yacon");
    public static final DataManager.Reference<ClimateRange> CHICORY_ROOT_CLIMATE = climate("crop/chicory_root");

    // 批次 3：谷物（12 种）
    public static final DataManager.Reference<ClimateRange> MILLET_CLIMATE = climate("crop/millet");
    public static final DataManager.Reference<ClimateRange> FOXTAIL_MILLET_CLIMATE = climate("crop/foxtail_millet");
    public static final DataManager.Reference<ClimateRange> BUCKWHEAT_CLIMATE = climate("crop/buckwheat");
    public static final DataManager.Reference<ClimateRange> FONIO_CLIMATE = climate("crop/fonio");
    public static final DataManager.Reference<ClimateRange> SPELT_CLIMATE = climate("crop/spelt");
    public static final DataManager.Reference<ClimateRange> EMMER_CLIMATE = climate("crop/emmer");
    public static final DataManager.Reference<ClimateRange> EINKORN_CLIMATE = climate("crop/einkorn");
    public static final DataManager.Reference<ClimateRange> PEARL_MILLET_CLIMATE = climate("crop/pearl_millet");
    public static final DataManager.Reference<ClimateRange> AMARANTH_CLIMATE = climate("crop/amaranth");
    public static final DataManager.Reference<ClimateRange> QUINOA_CLIMATE = climate("crop/quinoa");
    public static final DataManager.Reference<ClimateRange> FINGER_MILLET_CLIMATE = climate("crop/finger_millet");
    public static final DataManager.Reference<ClimateRange> JOBS_TEARS_CLIMATE = climate("crop/jobs_tears");
    public static final DataManager.Reference<ClimateRange> CHICKPEA_CLIMATE = climate("crop/chickpea");
    public static final DataManager.Reference<ClimateRange> FABA_BEAN_CLIMATE = climate("crop/faba_bean");
    public static final DataManager.Reference<ClimateRange> LUPIN_CLIMATE = climate("crop/lupin");
    public static final DataManager.Reference<ClimateRange> ADZUKI_CLIMATE = climate("crop/adzuki");
    public static final DataManager.Reference<ClimateRange> BAMBARA_NUT_CLIMATE = climate("crop/bambara_nut");
    public static final DataManager.Reference<ClimateRange> FENUGREEK_CLIMATE = climate("crop/fenugreek");
    public static final DataManager.Reference<ClimateRange> FLAX_CLIMATE = climate("crop/flax");
    public static final DataManager.Reference<ClimateRange> SESAME_CLIMATE = climate("crop/sesame");
    public static final DataManager.Reference<ClimateRange> SAFFLOWER_CLIMATE = climate("crop/safflower");
    public static final DataManager.Reference<ClimateRange> RAMIE_CLIMATE = climate("crop/ramie");
    public static final DataManager.Reference<ClimateRange> CHILI_CLIMATE = climate("crop/chili");
    public static final DataManager.Reference<ClimateRange> EGGPLANT_CLIMATE = climate("crop/eggplant");
    public static final DataManager.Reference<ClimateRange> OKRA_CLIMATE = climate("crop/okra");
    public static final DataManager.Reference<ClimateRange> COTTON_CLIMATE = climate("crop/cotton");
    public static final DataManager.Reference<ClimateRange> ASPARAGUS_CLIMATE = climate("crop/asparagus");
    public static final DataManager.Reference<ClimateRange> CHIVE_CLIMATE = climate("crop/chive");
    public static final DataManager.Reference<ClimateRange> RHUBARB_CLIMATE = climate("crop/rhubarb");
    public static final DataManager.Reference<ClimateRange> ARTICHOKE_CLIMATE = climate("crop/artichoke");
    public static final DataManager.Reference<ClimateRange> TARO_CLIMATE = climate("crop/taro");
    public static final DataManager.Reference<ClimateRange> WATER_CHESTNUT_CLIMATE = climate("crop/water_chestnut");
    public static final DataManager.Reference<ClimateRange> WATER_CALTROP_CLIMATE = climate("crop/water_caltrop");
    public static final DataManager.Reference<ClimateRange> WILD_RICE_STEM_CLIMATE = climate("crop/wild_rice_stem");
    public static final DataManager.Reference<ClimateRange> LOTUS_CLIMATE = climate("crop/lotus");
    public static final DataManager.Reference<ClimateRange> WATER_DROPWORT_CLIMATE = climate("crop/water_dropwort");
    public static final DataManager.Reference<ClimateRange> WATER_SPINACH_CLIMATE = climate("crop/water_spinach");
    public static final DataManager.Reference<ClimateRange> ARROWHEAD_CLIMATE = climate("crop/arrowhead");
    public static final DataManager.Reference<ClimateRange> GORGON_NUT_CLIMATE = climate("crop/gorgon_nut");
    public static final DataManager.Reference<ClimateRange> WATER_SHIELD_CLIMATE = climate("crop/water_shield");
    // 批次 12：莲座类 3 种（第 7 种作物形状，RosetteCropBlock）
    public static final DataManager.Reference<ClimateRange> CARDOON_CLIMATE = climate("crop/cardoon");
    public static final DataManager.Reference<ClimateRange> AGAVE_CLIMATE = climate("crop/agave");
    public static final DataManager.Reference<ClimateRange> PURSLANE_CLIMATE = climate("crop/purslane");

    // ---------------- 枯萎状态（每种作物一个独立死株，照 TFC 的 dead_crop/<name>） ----------------
    // TFC 的做法：TFCBlocks.DEAD_CROPS = mapOf(Crop, crop -> registerNoItem("dead_crop/" + crop.name(), crop::createDead))
    //   —— 每个死株自带气候引用（用于锄头 tooltip），掉落表掉回**对应的**种子。
    // 这里照做。注意方块无物品（registerNoItem 等价，传 null 给 items 与 blockItemFactory）。
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_SPINACH = dead("spinach", SPINACH_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_LETTUCE = dead("lettuce", LETTUCE_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_CELERY = dead("celery", CELERY_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_NAPA_CABBAGE = dead("napa_cabbage", NAPA_CABBAGE_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_MUSTARD_GREENS = dead("mustard_greens", MUSTARD_GREENS_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_BROCCOLI = dead("broccoli", BROCCOLI_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_CAULIFLOWER = dead("cauliflower", CAULIFLOWER_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_STRAWBERRY = dead("strawberry", STRAWBERRY_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_BRUSSELS_SPROUTS = dead("brussels_sprouts", BRUSSELS_SPROUTS_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_SWISS_CHARD = dead("swiss_chard", SWISS_CHARD_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_CELTUCE = dead("celtuce", CELTUCE_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_GARLAND_CHRYSANTHEMUM = dead("garland_chrysanthemum", GARLAND_CHRYSANTHEMUM_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_PERILLA = dead("perilla", PERILLA_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_ARUGULA = dead("arugula", ARUGULA_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_TURNIP = dead("turnip", TURNIP_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_PARSNIP = dead("parsnip", PARSNIP_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_SUNCHOKE = deadDouble("sunchoke", SUNCHOKE_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_SHALLOT = dead("shallot", SHALLOT_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_CELERIAC = dead("celeriac", CELERIAC_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_SALSIFY = dead("salsify", SALSIFY_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_GINGER = dead("ginger", GINGER_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_TURMERIC = dead("turmeric", TURMERIC_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_YACON = dead("yacon", YACON_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_CHICORY_ROOT = dead("chicory_root", CHICORY_ROOT_CLIMATE);

    // 批次 3：谷物（12 种）
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_MILLET = deadDouble("millet", MILLET_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_FOXTAIL_MILLET = deadDouble("foxtail_millet", FOXTAIL_MILLET_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_BUCKWHEAT = dead("buckwheat", BUCKWHEAT_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_FONIO = dead("fonio", FONIO_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_SPELT = deadDouble("spelt", SPELT_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_EMMER = deadDouble("emmer", EMMER_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_EINKORN = dead("einkorn", EINKORN_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_PEARL_MILLET = deadDouble("pearl_millet", PEARL_MILLET_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_AMARANTH = deadDouble("amaranth", AMARANTH_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_QUINOA = deadDouble("quinoa", QUINOA_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_FINGER_MILLET = dead("finger_millet", FINGER_MILLET_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_JOBS_TEARS = deadDouble("jobs_tears", JOBS_TEARS_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_CHICKPEA = dead("chickpea", CHICKPEA_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_FABA_BEAN = deadDouble("faba_bean", FABA_BEAN_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_LUPIN = dead("lupin", LUPIN_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_ADZUKI = dead("adzuki", ADZUKI_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_BAMBARA_NUT = dead("bambara_nut", BAMBARA_NUT_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_FENUGREEK = dead("fenugreek", FENUGREEK_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_FLAX = dead("flax", FLAX_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_SESAME = dead("sesame", SESAME_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_SAFFLOWER = dead("safflower", SAFFLOWER_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_RAMIE = deadDouble("ramie", RAMIE_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_CHILI = dead("chili", CHILI_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_EGGPLANT = dead("eggplant", EGGPLANT_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_OKRA = dead("okra", OKRA_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_COTTON = deadDouble("cotton", COTTON_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_ASPARAGUS = dead("asparagus", ASPARAGUS_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_CHIVE = dead("chive", CHIVE_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_RHUBARB = dead("rhubarb", RHUBARB_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_ARTICHOKE = dead("artichoke", ARTICHOKE_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_TARO = deadFlooded("taro", TARO_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_WATER_CHESTNUT = deadFlooded("water_chestnut", WATER_CHESTNUT_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_WATER_CALTROP = deadFlooded("water_caltrop", WATER_CALTROP_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_WILD_RICE_STEM = deadFlooded("wild_rice_stem", WILD_RICE_STEM_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_LOTUS = deadFlooded("lotus", LOTUS_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_WATER_DROPWORT = deadFlooded("water_dropwort", WATER_DROPWORT_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_WATER_SPINACH = deadFlooded("water_spinach", WATER_SPINACH_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_ARROWHEAD = deadFlooded("arrowhead", ARROWHEAD_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_GORGON_NUT = deadFlooded("gorgon_nut", GORGON_NUT_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_WATER_SHIELD = deadFlooded("water_shield", WATER_SHIELD_CLIMATE);

    // ---------------- 产物物品（营养与保质期见 data/tfcfarmingplus/tfc/food/*.json） ----------------
    public static final DeferredHolder<Item, Item> SPINACH = food("spinach");
    public static final DeferredHolder<Item, Item> LETTUCE = food("lettuce");
    public static final DeferredHolder<Item, Item> CELERY = food("celery");
    public static final DeferredHolder<Item, Item> KALE = food("kale");
    public static final DeferredHolder<Item, Item> NAPA_CABBAGE = food("napa_cabbage");
    public static final DeferredHolder<Item, Item> MUSTARD_GREENS = food("mustard_greens");
    public static final DeferredHolder<Item, Item> BROCCOLI = food("broccoli");
    public static final DeferredHolder<Item, Item> CAULIFLOWER = food("cauliflower");
    public static final DeferredHolder<Item, Item> BRUSSELS_SPROUTS = food("brussels_sprouts");
    public static final DeferredHolder<Item, Item> SWISS_CHARD = food("swiss_chard");
    public static final DeferredHolder<Item, Item> CELTUCE = food("celtuce");
    public static final DeferredHolder<Item, Item> GARLAND_CHRYSANTHEMUM = food("garland_chrysanthemum");
    public static final DeferredHolder<Item, Item> PERILLA = food("perilla");
    public static final DeferredHolder<Item, Item> ARUGULA = food("arugula");
    public static final DeferredHolder<Item, Item> TURNIP = food("turnip");
    public static final DeferredHolder<Item, Item> PARSNIP = food("parsnip");
    public static final DeferredHolder<Item, Item> SUNCHOKE = food("sunchoke");
    public static final DeferredHolder<Item, Item> SHALLOT = food("shallot");
    public static final DeferredHolder<Item, Item> CELERIAC = food("celeriac");
    public static final DeferredHolder<Item, Item> SALSIFY = food("salsify");
    public static final DeferredHolder<Item, Item> GINGER = food("ginger");
    public static final DeferredHolder<Item, Item> TURMERIC = food("turmeric");
    public static final DeferredHolder<Item, Item> YACON = food("yacon");
    public static final DeferredHolder<Item, Item> CHICORY_ROOT = food("chicory_root");

    // 批次 3：谷物（12 种）
    public static final DeferredHolder<Item, Item> MILLET = food("millet");
    public static final DeferredHolder<Item, Item> FOXTAIL_MILLET = food("foxtail_millet");
    public static final DeferredHolder<Item, Item> BUCKWHEAT = food("buckwheat");
    public static final DeferredHolder<Item, Item> FONIO = food("fonio");
    public static final DeferredHolder<Item, Item> SPELT = food("spelt");
    public static final DeferredHolder<Item, Item> EMMER = food("emmer");
    public static final DeferredHolder<Item, Item> EINKORN = food("einkorn");
    public static final DeferredHolder<Item, Item> PEARL_MILLET = food("pearl_millet");
    public static final DeferredHolder<Item, Item> AMARANTH = food("amaranth");
    public static final DeferredHolder<Item, Item> QUINOA = food("quinoa");
    public static final DeferredHolder<Item, Item> FINGER_MILLET = food("finger_millet");
    public static final DeferredHolder<Item, Item> JOBS_TEARS = food("jobs_tears");
    public static final DeferredHolder<Item, Item> CHICKPEA = food("chickpea");
    public static final DeferredHolder<Item, Item> FABA_BEAN = food("faba_bean");
    public static final DeferredHolder<Item, Item> LUPIN = food("lupin");
    public static final DeferredHolder<Item, Item> ADZUKI = food("adzuki");
    public static final DeferredHolder<Item, Item> BAMBARA_NUT = food("bambara_nut");
    public static final DeferredHolder<Item, Item> FENUGREEK = food("fenugreek");
    /** 纤维物品（非食物）：亚麻/苎麻的产物 */
    public static final DeferredHolder<Item, Item> FLAX_FIBRE = fibre("fiber/flax");
    public static final DeferredHolder<Item, Item> RAMIE_FIBRE = fibre("fiber/ramie");
    public static final DeferredHolder<Item, Item> SESAME = food("sesame");
    public static final DeferredHolder<Item, Item> SAFFLOWER = food("safflower");
    /** 棉铃：棉花的非食物产物 */
    public static final DeferredHolder<Item, Item> COTTON_BOLL = fibre("cotton_boll");
    public static final DeferredHolder<Item, Item> CHILI = food("chili");
    public static final DeferredHolder<Item, Item> EGGPLANT = food("eggplant");
    public static final DeferredHolder<Item, Item> OKRA = food("okra");
    public static final DeferredHolder<Item, Item> ASPARAGUS = food("asparagus");
    public static final DeferredHolder<Item, Item> CHIVE = food("chive");
    public static final DeferredHolder<Item, Item> RHUBARB = food("rhubarb");
    public static final DeferredHolder<Item, Item> ARTICHOKE = food("artichoke");

    // ---------------- 种子物品 ----------------
    // ---------------- 批次 5：水田作物产物（10 种） ----------------
    public static final DeferredHolder<Item, Item> TARO = food("taro");
    public static final DeferredHolder<Item, Item> WATER_CHESTNUT = food("water_chestnut");
    public static final DeferredHolder<Item, Item> WATER_CALTROP = food("water_caltrop");
    public static final DeferredHolder<Item, Item> WILD_RICE_STEM = food("wild_rice_stem");
    public static final DeferredHolder<Item, Item> LOTUS = food("lotus");
    public static final DeferredHolder<Item, Item> WATER_DROPWORT = food("water_dropwort");
    public static final DeferredHolder<Item, Item> WATER_SPINACH = food("water_spinach");
    public static final DeferredHolder<Item, Item> ARROWHEAD = food("arrowhead");
    public static final DeferredHolder<Item, Item> GORGON_NUT = food("gorgon_nut");
    public static final DeferredHolder<Item, Item> WATER_SHIELD = food("water_shield");
    // 批次 12：莲座类 3 种的产物（中心结果时收）
    public static final DeferredHolder<Item, Item> CARDOON = food("cardoon");
    public static final DeferredHolder<Item, Item> AGAVE = food("agave");
    public static final DeferredHolder<Item, Item> PURSLANE = food("purslane");
    // ⚠️ 这里必须用「限定名」MyCrops.XXX_CROP 而不是简单名 XXX_CROP：
    //    种子字段声明在作物方块字段之前，Java 禁止静态初始化器通过简单名前向引用后面的字段，
    //    但限定名（类名.字段）是允许的。DeferredRegister 的 lambda 本身是惰性的，不会造成初始化死锁。
    public static final DeferredHolder<Item, Item> SPINACH_SEEDS =
        seed("spinach", () -> MyCrops.SPINACH_CROP.get(), 0.7f, -0.2f, -0.2f, SPINACH_CLIMATE);
    public static final DeferredHolder<Item, Item> LETTUCE_SEEDS =
        seed("lettuce", () -> MyCrops.LETTUCE_CROP.get(), 0.6f, -0.2f, -0.2f, LETTUCE_CLIMATE);
    public static final DeferredHolder<Item, Item> CELERY_SEEDS =
        seed("celery", () -> MyCrops.CELERY_CROP.get(), 0.7f, 0.3f, 0.4f, CELERY_CLIMATE);
    public static final DeferredHolder<Item, Item> KALE_SEEDS =
        seed("kale", () -> MyCrops.KALE_CROP.get(), 0.7f, 0.2f, 0.3f, KALE_CLIMATE);
    public static final DeferredHolder<Item, Item> NAPA_CABBAGE_SEEDS =
        seed("napa_cabbage", () -> MyCrops.NAPA_CABBAGE_CROP.get(), 0.7f, 0.2f, 0.4f, NAPA_CABBAGE_CLIMATE);
    public static final DeferredHolder<Item, Item> MUSTARD_GREENS_SEEDS =
        seed("mustard_greens", () -> MyCrops.MUSTARD_GREENS_CROP.get(), 0.3f, 0.25f, 0.35f, MUSTARD_GREENS_CLIMATE);
    public static final DeferredHolder<Item, Item> BROCCOLI_SEEDS =
        seed("broccoli", () -> MyCrops.BROCCOLI_CROP.get(), 0.8f, 0.3f, 0.4f, BROCCOLI_CLIMATE);
    public static final DeferredHolder<Item, Item> CAULIFLOWER_SEEDS =
        seed("cauliflower", () -> MyCrops.CAULIFLOWER_CROP.get(), 0.8f, 0.3f, 0.4f, CAULIFLOWER_CLIMATE);
    public static final DeferredHolder<Item, Item> BRUSSELS_SPROUTS_SEEDS =
        seed("brussels_sprouts", () -> MyCrops.BRUSSELS_SPROUTS_CROP.get(), 0.8f, 0.3f, 0.4f, BRUSSELS_SPROUTS_CLIMATE);
    public static final DeferredHolder<Item, Item> SWISS_CHARD_SEEDS =
        seed("swiss_chard", () -> MyCrops.SWISS_CHARD_CROP.get(), 0.6f, 0.2f, 0.4f, SWISS_CHARD_CLIMATE);
    public static final DeferredHolder<Item, Item> CELTUCE_SEEDS =
        seed("celtuce", () -> MyCrops.CELTUCE_CROP.get(), 0.6f, -0.2f, -0.2f, CELTUCE_CLIMATE);
    public static final DeferredHolder<Item, Item> GARLAND_CHRYSANTHEMUM_SEEDS =
        seed("garland_chrysanthemum", () -> MyCrops.GARLAND_CHRYSANTHEMUM_CROP.get(), 0.6f, -0.2f, -0.2f, GARLAND_CHRYSANTHEMUM_CLIMATE);
    public static final DeferredHolder<Item, Item> PERILLA_SEEDS =
        seed("perilla", () -> MyCrops.PERILLA_CROP.get(), 0.6f, -0.2f, -0.2f, PERILLA_CLIMATE);
    public static final DeferredHolder<Item, Item> ARUGULA_SEEDS =
        seed("arugula", () -> MyCrops.ARUGULA_CROP.get(), 0.5f, -0.2f, -0.2f, ARUGULA_CLIMATE);
    public static final DeferredHolder<Item, Item> TURNIP_SEEDS =
        seed("turnip", () -> MyCrops.TURNIP_CROP.get(), 0.3f, 0.3f, 0.4f, TURNIP_CLIMATE);
    public static final DeferredHolder<Item, Item> PARSNIP_SEEDS =
        seed("parsnip", () -> MyCrops.PARSNIP_CROP.get(), 0.4f, 0.25f, 0.5f, PARSNIP_CLIMATE);
    public static final DeferredHolder<Item, Item> SUNCHOKE_SEEDS =
        seed("sunchoke", () -> MyCrops.SUNCHOKE_CROP.get(), 0.3f, 0.2f, 0.6f, SUNCHOKE_CLIMATE);
    public static final DeferredHolder<Item, Item> SHALLOT_SEEDS =
        seed("shallot", () -> MyCrops.SHALLOT_CROP.get(), 0.35f, 0.3f, 0.45f, SHALLOT_CLIMATE);
    public static final DeferredHolder<Item, Item> CELERIAC_SEEDS =
        seed("celeriac", () -> MyCrops.CELERIAC_CROP.get(), 0.6f, 0.3f, 0.5f, CELERIAC_CLIMATE);
    public static final DeferredHolder<Item, Item> SALSIFY_SEEDS =
        seed("salsify", () -> MyCrops.SALSIFY_CROP.get(), 0.4f, 0.3f, 0.5f, SALSIFY_CLIMATE);
    public static final DeferredHolder<Item, Item> GINGER_SEEDS =
        seed("ginger", () -> MyCrops.GINGER_CROP.get(), 0.5f, 0.3f, 0.6f, GINGER_CLIMATE);
    public static final DeferredHolder<Item, Item> TURMERIC_SEEDS =
        seed("turmeric", () -> MyCrops.TURMERIC_CROP.get(), 0.5f, 0.25f, 0.6f, TURMERIC_CLIMATE);
    public static final DeferredHolder<Item, Item> YACON_SEEDS =
        seed("yacon", () -> MyCrops.YACON_CROP.get(), 0.35f, 0.3f, 0.5f, YACON_CLIMATE);
    public static final DeferredHolder<Item, Item> CHICORY_ROOT_SEEDS =
        seed("chicory_root", () -> MyCrops.CHICORY_ROOT_CROP.get(), 0.4f, 0.2f, 0.5f, CHICORY_ROOT_CLIMATE);

    // 批次 3：谷物（12 种）—— 同样用限定名规避前向引用
    public static final DeferredHolder<Item, Item> MILLET_SEEDS =
        seed("millet", () -> MyCrops.MILLET_CROP.get(), 0.7f, -0.2f, -0.2f, MILLET_CLIMATE);
    public static final DeferredHolder<Item, Item> FOXTAIL_MILLET_SEEDS =
        seed("foxtail_millet", () -> MyCrops.FOXTAIL_MILLET_CROP.get(), 0.7f, -0.2f, -0.2f, FOXTAIL_MILLET_CLIMATE);
    public static final DeferredHolder<Item, Item> BUCKWHEAT_SEEDS =
        seed("buckwheat", () -> MyCrops.BUCKWHEAT_CROP.get(), 0.6f, 0.2f, 0.3f, BUCKWHEAT_CLIMATE);
    public static final DeferredHolder<Item, Item> FONIO_SEEDS =
        seed("fonio", () -> MyCrops.FONIO_CROP.get(), 0.6f, -0.2f, -0.2f, FONIO_CLIMATE);
    public static final DeferredHolder<Item, Item> SPELT_SEEDS =
        seed("spelt", () -> MyCrops.SPELT_CROP.get(), 0.7f, 0.1f, 0.3f, SPELT_CLIMATE);
    public static final DeferredHolder<Item, Item> EMMER_SEEDS =
        seed("emmer", () -> MyCrops.EMMER_CROP.get(), 0.7f, 0.1f, 0.3f, EMMER_CLIMATE);
    public static final DeferredHolder<Item, Item> EINKORN_SEEDS =
        seed("einkorn", () -> MyCrops.EINKORN_CROP.get(), 0.6f, 0.1f, 0.3f, EINKORN_CLIMATE);
    public static final DeferredHolder<Item, Item> PEARL_MILLET_SEEDS =
        seed("pearl_millet", () -> MyCrops.PEARL_MILLET_CROP.get(), 0.7f, -0.2f, -0.2f, PEARL_MILLET_CLIMATE);
    public static final DeferredHolder<Item, Item> AMARANTH_SEEDS =
        seed("amaranth", () -> MyCrops.AMARANTH_CROP.get(), 0.6f, 0.2f, 0.3f, AMARANTH_CLIMATE);
    public static final DeferredHolder<Item, Item> QUINOA_SEEDS =
        seed("quinoa", () -> MyCrops.QUINOA_CROP.get(), 0.6f, 0.2f, 0.3f, QUINOA_CLIMATE);
    public static final DeferredHolder<Item, Item> FINGER_MILLET_SEEDS =
        seed("finger_millet", () -> MyCrops.FINGER_MILLET_CROP.get(), 0.6f, -0.2f, -0.2f, FINGER_MILLET_CLIMATE);
    public static final DeferredHolder<Item, Item> JOBS_TEARS_SEEDS =
        seed("jobs_tears", () -> MyCrops.JOBS_TEARS_CROP.get(), 0.7f, 0.2f, 0.4f, JOBS_TEARS_CLIMATE);

    public static final DeferredHolder<Item, Item> CHICKPEA_SEEDS =
        seed("chickpea", () -> MyCrops.CHICKPEA_CROP.get(), -0.6f, 0.2f, 0.3f, CHICKPEA_CLIMATE);

    public static final DeferredHolder<Item, Item> FABA_BEAN_SEEDS =
        seed("faba_bean", () -> MyCrops.FABA_BEAN_CROP.get(), -0.7f, 0.15f, 0.25f, FABA_BEAN_CLIMATE);

    public static final DeferredHolder<Item, Item> LUPIN_SEEDS =
        seed("lupin", () -> MyCrops.LUPIN_CROP.get(), -0.5f, 0.15f, 0.2f, LUPIN_CLIMATE);

    public static final DeferredHolder<Item, Item> ADZUKI_SEEDS =
        seed("adzuki", () -> MyCrops.ADZUKI_CROP.get(), -0.6f, 0.2f, 0.3f, ADZUKI_CLIMATE);

    public static final DeferredHolder<Item, Item> BAMBARA_NUT_SEEDS =
        seed("bambara_nut", () -> MyCrops.BAMBARA_NUT_CROP.get(), -0.6f, 0.15f, 0.25f, BAMBARA_NUT_CLIMATE);

    public static final DeferredHolder<Item, Item> FENUGREEK_SEEDS =
        seed("fenugreek", () -> MyCrops.FENUGREEK_CROP.get(), -0.7f, 0.2f, 0.3f, FENUGREEK_CLIMATE);

    public static final DeferredHolder<Item, Item> FLAX_SEEDS =
        seed("flax", () -> MyCrops.FLAX_CROP.get(), 0.6f, 0.2f, 0.3f, FLAX_CLIMATE);

    public static final DeferredHolder<Item, Item> SESAME_SEEDS =
        seed("sesame", () -> MyCrops.SESAME_CROP.get(), 0.6f, 0.2f, 0.3f, SESAME_CLIMATE);

    public static final DeferredHolder<Item, Item> SAFFLOWER_SEEDS =
        seed("safflower", () -> MyCrops.SAFFLOWER_CROP.get(), 0.6f, 0.2f, 0.3f, SAFFLOWER_CLIMATE);

    public static final DeferredHolder<Item, Item> RAMIE_SEEDS =
        seed("ramie", () -> MyCrops.RAMIE_CROP.get(), 0.5f, 0.2f, 0.4f, RAMIE_CLIMATE);

    public static final DeferredHolder<Item, Item> CHILI_SEEDS =
        seed("chili", () -> MyCrops.CHILI_CROP.get(), 0.3f, 0.4f, 0.5f, CHILI_CLIMATE);

    public static final DeferredHolder<Item, Item> EGGPLANT_SEEDS =
        seed("eggplant", () -> MyCrops.EGGPLANT_CROP.get(), 0.35f, 0.4f, 0.5f, EGGPLANT_CLIMATE);

    public static final DeferredHolder<Item, Item> OKRA_SEEDS =
        seed("okra", () -> MyCrops.OKRA_CROP.get(), 0.4f, 0.35f, 0.5f, OKRA_CLIMATE);

    public static final DeferredHolder<Item, Item> COTTON_SEEDS =
        seed("cotton", () -> MyCrops.COTTON_CROP.get(), 0.6f, 0.3f, -0.3f, COTTON_CLIMATE);

    public static final DeferredHolder<Item, Item> ASPARAGUS_SEEDS =
        seed("asparagus", () -> MyCrops.ASPARAGUS_CROP.get(), 0.6f, 0.3f, 0.4f, ASPARAGUS_CLIMATE);

    public static final DeferredHolder<Item, Item> CHIVE_SEEDS =
        seed("chive", () -> MyCrops.CHIVE_CROP.get(), 0.6f, -0.2f, -0.2f, CHIVE_CLIMATE);

    public static final DeferredHolder<Item, Item> RHUBARB_SEEDS =
        seed("rhubarb", () -> MyCrops.RHUBARB_CROP.get(), 0.5f, 0.2f, 0.3f, RHUBARB_CLIMATE);

    public static final DeferredHolder<Item, Item> ARTICHOKE_SEEDS =
        seed("artichoke", () -> MyCrops.ARTICHOKE_CROP.get(), 0.7f, 0.3f, 0.5f, ARTICHOKE_CLIMATE);
    public static final DeferredHolder<Item, Item> TARO_SEEDS =
        seed("taro", () -> MyCrops.TARO_CROP.get(), 0.45f, 0.35f, 0.6f, TARO_CLIMATE);
    public static final DeferredHolder<Item, Item> WATER_CHESTNUT_SEEDS =
        seed("water_chestnut", () -> MyCrops.WATER_CHESTNUT_CROP.get(), 0.4f, 0.3f, 0.6f, WATER_CHESTNUT_CLIMATE);
    public static final DeferredHolder<Item, Item> WATER_CALTROP_SEEDS =
        seed("water_caltrop", () -> MyCrops.WATER_CALTROP_CROP.get(), 0.35f, 0.3f, 0.55f, WATER_CALTROP_CLIMATE);
    public static final DeferredHolder<Item, Item> WILD_RICE_STEM_SEEDS =
        seed("wild_rice_stem", () -> MyCrops.WILD_RICE_STEM_CROP.get(), 0.5f, 0.3f, 0.5f, WILD_RICE_STEM_CLIMATE);
    public static final DeferredHolder<Item, Item> LOTUS_SEEDS =
        seed("lotus", () -> MyCrops.LOTUS_CROP.get(), 0.45f, 0.35f, 0.6f, LOTUS_CLIMATE);
    public static final DeferredHolder<Item, Item> WATER_DROPWORT_SEEDS =
        seed("water_dropwort", () -> MyCrops.WATER_DROPWORT_CROP.get(), 0.5f, 0.3f, 0.4f, WATER_DROPWORT_CLIMATE);
    public static final DeferredHolder<Item, Item> WATER_SPINACH_SEEDS =
        seed("water_spinach", () -> MyCrops.WATER_SPINACH_CROP.get(), 0.8f, -0.2f, -0.2f, WATER_SPINACH_CLIMATE);
    public static final DeferredHolder<Item, Item> ARROWHEAD_SEEDS =
        seed("arrowhead", () -> MyCrops.ARROWHEAD_CROP.get(), 0.45f, 0.35f, 0.55f, ARROWHEAD_CLIMATE);
    public static final DeferredHolder<Item, Item> GORGON_NUT_SEEDS =
        seed("gorgon_nut", () -> MyCrops.GORGON_NUT_CROP.get(), 0.4f, 0.3f, 0.55f, GORGON_NUT_CLIMATE);
    public static final DeferredHolder<Item, Item> WATER_SHIELD_SEEDS =
        seed("water_shield", () -> MyCrops.WATER_SHIELD_CROP.get(), 0.4f, 0.2f, 0.3f, WATER_SHIELD_CLIMATE);
    // 批次 12：莲座类 3 种的「种子」= 侧芽（RosetteCropBlock 枯死时直接弹到地上）
    public static final DeferredHolder<Item, Item> CARDOON_SEEDS =
        seed("cardoon", () -> MyCrops.CARDOON_CROP.get(), 0.6f, 0.3f, 0.5f, CARDOON_CLIMATE);
    public static final DeferredHolder<Item, Item> AGAVE_SEEDS =
        seed("agave", () -> MyCrops.AGAVE_CROP.get(), 0.3f, 0.2f, 0.5f, AGAVE_CLIMATE);
    public static final DeferredHolder<Item, Item> PURSLANE_SEEDS =
        seed("purslane", () -> MyCrops.PURSLANE_CROP.get(), 0.4f, 0.2f, 0.3f, PURSLANE_CLIMATE);
    public static final DeferredHolder<Item, Item> STRAWBERRY_SEEDS =
        seed("strawberry", () -> MyCrops.STRAWBERRY_CROP.get(), 0.5f, 0.3f, 0.4f, STRAWBERRY_CLIMATE);

    // ---------------- 作物方块（无方块物品 —— 收获物是产物 + 种子） ----------------
    public static final DeferredHolder<Block, MyCropBlock> SPINACH_CROP =
        crop("spinach", 5, 0.7f, -0.2f, -0.2f, SPINACH_CLIMATE, () -> MyCrops.DEAD_SPINACH.get());
    public static final DeferredHolder<Block, MyCropBlock> LETTUCE_CROP =
        crop("lettuce", 5, 0.6f, -0.2f, -0.2f, LETTUCE_CLIMATE, () -> MyCrops.DEAD_LETTUCE.get());
    public static final DeferredHolder<Block, MyCropBlock> CELERY_CROP =
        crop("celery", 5, 0.7f, 0.3f, 0.4f, CELERY_CLIMATE, () -> MyCrops.DEAD_CELERY.get());
    public static final DeferredHolder<Block, RosetteCropBlock> KALE_CROP =
        rosette("kale", 0.7f, 0.2f, 0.3f, KALE_CLIMATE);   // 方案 A：羽衣甘蓝现实为莲座叶球，改用第 7 种形状
    public static final DeferredHolder<Block, MyCropBlock> NAPA_CABBAGE_CROP =
        crop("napa_cabbage", 5, 0.7f, 0.2f, 0.4f, NAPA_CABBAGE_CLIMATE, () -> MyCrops.DEAD_NAPA_CABBAGE.get());
    public static final DeferredHolder<Block, MyCropBlock> MUSTARD_GREENS_CROP =
        crop("mustard_greens", 5, 0.3f, 0.25f, 0.35f, MUSTARD_GREENS_CLIMATE, () -> MyCrops.DEAD_MUSTARD_GREENS.get());
    public static final DeferredHolder<Block, MyCropBlock> BROCCOLI_CROP =
        crop("broccoli", 5, 0.8f, 0.3f, 0.4f, BROCCOLI_CLIMATE, () -> MyCrops.DEAD_BROCCOLI.get());
    public static final DeferredHolder<Block, MyCropBlock> CAULIFLOWER_CROP =
        crop("cauliflower", 5, 0.8f, 0.3f, 0.4f, CAULIFLOWER_CLIMATE, () -> MyCrops.DEAD_CAULIFLOWER.get());
    public static final DeferredHolder<Block, MyCropBlock> STRAWBERRY_CROP =
        crop("strawberry", 5, 0.5f, 0.3f, 0.4f, STRAWBERRY_CLIMATE, () -> MyCrops.DEAD_STRAWBERRY.get());
    public static final DeferredHolder<Block, MyCropBlock> BRUSSELS_SPROUTS_CROP =
        crop("brussels_sprouts", 6, 0.8f, 0.3f, 0.4f, BRUSSELS_SPROUTS_CLIMATE, () -> MyCrops.DEAD_BRUSSELS_SPROUTS.get());
    public static final DeferredHolder<Block, MyCropBlock> SWISS_CHARD_CROP =
        crop("swiss_chard", 5, 0.6f, 0.2f, 0.4f, SWISS_CHARD_CLIMATE, () -> MyCrops.DEAD_SWISS_CHARD.get());
    public static final DeferredHolder<Block, MyCropBlock> CELTUCE_CROP =
        crop("celtuce", 5, 0.6f, -0.2f, -0.2f, CELTUCE_CLIMATE, () -> MyCrops.DEAD_CELTUCE.get());
    public static final DeferredHolder<Block, MyCropBlock> GARLAND_CHRYSANTHEMUM_CROP =
        crop("garland_chrysanthemum", 5, 0.6f, -0.2f, -0.2f, GARLAND_CHRYSANTHEMUM_CLIMATE, () -> MyCrops.DEAD_GARLAND_CHRYSANTHEMUM.get());
    public static final DeferredHolder<Block, MyCropBlock> PERILLA_CROP =
        crop("perilla", 5, 0.6f, -0.2f, -0.2f, PERILLA_CLIMATE, () -> MyCrops.DEAD_PERILLA.get());
    public static final DeferredHolder<Block, MyCropBlock> ARUGULA_CROP =
        crop("arugula", 5, 0.5f, -0.2f, -0.2f, ARUGULA_CLIMATE, () -> MyCrops.DEAD_ARUGULA.get());
    public static final DeferredHolder<Block, MyCropBlock> TURNIP_CROP =
        crop("turnip", 5, 0.3f, 0.3f, 0.4f, TURNIP_CLIMATE, () -> MyCrops.DEAD_TURNIP.get());
    public static final DeferredHolder<Block, MyCropBlock> PARSNIP_CROP =
        crop("parsnip", 5, 0.4f, 0.25f, 0.5f, PARSNIP_CLIMATE, () -> MyCrops.DEAD_PARSNIP.get());
    public static final DeferredHolder<Block, MyDoubleCropBlock> SUNCHOKE_CROP =
        dbl("sunchoke", 3, 5, 0.3f, 0.2f, 0.6f, SUNCHOKE_CLIMATE, () -> MyCrops.DEAD_SUNCHOKE.get());
    public static final DeferredHolder<Block, MyCropBlock> SHALLOT_CROP =
        crop("shallot", 5, 0.35f, 0.3f, 0.45f, SHALLOT_CLIMATE, () -> MyCrops.DEAD_SHALLOT.get());
    public static final DeferredHolder<Block, MyCropBlock> CELERIAC_CROP =
        crop("celeriac", 5, 0.6f, 0.3f, 0.5f, CELERIAC_CLIMATE, () -> MyCrops.DEAD_CELERIAC.get());
    public static final DeferredHolder<Block, MyCropBlock> SALSIFY_CROP =
        crop("salsify", 5, 0.4f, 0.3f, 0.5f, SALSIFY_CLIMATE, () -> MyCrops.DEAD_SALSIFY.get());
    public static final DeferredHolder<Block, MyCropBlock> GINGER_CROP =
        crop("ginger", 5, 0.5f, 0.3f, 0.6f, GINGER_CLIMATE, () -> MyCrops.DEAD_GINGER.get());
    public static final DeferredHolder<Block, MyCropBlock> TURMERIC_CROP =
        crop("turmeric", 5, 0.5f, 0.25f, 0.6f, TURMERIC_CLIMATE, () -> MyCrops.DEAD_TURMERIC.get());
    public static final DeferredHolder<Block, MyCropBlock> YACON_CROP =
        crop("yacon", 5, 0.35f, 0.3f, 0.5f, YACON_CLIMATE, () -> MyCrops.DEAD_YACON.get());
    public static final DeferredHolder<Block, MyCropBlock> CHICORY_ROOT_CROP =
        crop("chicory_root", 5, 0.4f, 0.2f, 0.5f, CHICORY_ROOT_CLIMATE, () -> MyCrops.DEAD_CHICORY_ROOT.get());

    // ---------------- 批次 3：谷物（12 种） ----------------
    // maxAge = 7（8 个视觉阶段），与 TFC 的谷物一致；生长速度由 TFC 的全局 GROWTH_FACTOR 决定，
    // maxAge 只影响外形阶段数，不影响成熟所需时间。
    public static final DeferredHolder<Block, MyDoubleCropBlock> MILLET_CROP =
        dbl("millet", 4, 7, 0.7f, -0.2f, -0.2f, MILLET_CLIMATE, () -> MyCrops.DEAD_MILLET.get());
    public static final DeferredHolder<Block, MyDoubleCropBlock> FOXTAIL_MILLET_CROP =
        dbl("foxtail_millet", 4, 7, 0.7f, -0.2f, -0.2f, FOXTAIL_MILLET_CLIMATE, () -> MyCrops.DEAD_FOXTAIL_MILLET.get());
    public static final DeferredHolder<Block, MyCropBlock> BUCKWHEAT_CROP =
        crop("buckwheat", 7, 0.6f, 0.2f, 0.3f, BUCKWHEAT_CLIMATE, () -> MyCrops.DEAD_BUCKWHEAT.get());
    public static final DeferredHolder<Block, MyCropBlock> FONIO_CROP =
        crop("fonio", 7, 0.6f, -0.2f, -0.2f, FONIO_CLIMATE, () -> MyCrops.DEAD_FONIO.get());
    public static final DeferredHolder<Block, MyDoubleCropBlock> SPELT_CROP =
        dbl("spelt", 4, 7, 0.7f, 0.1f, 0.3f, SPELT_CLIMATE, () -> MyCrops.DEAD_SPELT.get());
    public static final DeferredHolder<Block, MyDoubleCropBlock> EMMER_CROP =
        dbl("emmer", 4, 7, 0.7f, 0.1f, 0.3f, EMMER_CLIMATE, () -> MyCrops.DEAD_EMMER.get());
    public static final DeferredHolder<Block, MyCropBlock> EINKORN_CROP =
        crop("einkorn", 7, 0.6f, 0.1f, 0.3f, EINKORN_CLIMATE, () -> MyCrops.DEAD_EINKORN.get());
    public static final DeferredHolder<Block, MyDoubleCropBlock> PEARL_MILLET_CROP =
        dbl("pearl_millet", 4, 7, 0.7f, -0.2f, -0.2f, PEARL_MILLET_CLIMATE, () -> MyCrops.DEAD_PEARL_MILLET.get());
    public static final DeferredHolder<Block, MyDoubleCropBlock> AMARANTH_CROP =
        dbl("amaranth", 4, 7, 0.6f, 0.2f, 0.3f, AMARANTH_CLIMATE, () -> MyCrops.DEAD_AMARANTH.get());
    public static final DeferredHolder<Block, MyDoubleCropBlock> QUINOA_CROP =
        dbl("quinoa", 4, 7, 0.6f, 0.2f, 0.3f, QUINOA_CLIMATE, () -> MyCrops.DEAD_QUINOA.get());
    public static final DeferredHolder<Block, MyCropBlock> FINGER_MILLET_CROP =
        crop("finger_millet", 7, 0.6f, -0.2f, -0.2f, FINGER_MILLET_CLIMATE, () -> MyCrops.DEAD_FINGER_MILLET.get());
    public static final DeferredHolder<Block, MyDoubleCropBlock> JOBS_TEARS_CROP =
        dbl("jobs_tears", 4, 7, 0.7f, 0.2f, 0.4f, JOBS_TEARS_CLIMATE, () -> MyCrops.DEAD_JOBS_TEARS.get());

    public static final DeferredHolder<Block, MyCropBlock> CHICKPEA_CROP =
        crop("chickpea", 5, -0.6f, 0.2f, 0.3f, CHICKPEA_CLIMATE, () -> MyCrops.DEAD_CHICKPEA.get());

    public static final DeferredHolder<Block, MyDoubleCropBlock> FABA_BEAN_CROP =
        dbl("faba_bean", 3, 5, -0.7f, 0.15f, 0.25f, FABA_BEAN_CLIMATE, () -> MyCrops.DEAD_FABA_BEAN.get());

    public static final DeferredHolder<Block, MyCropBlock> LUPIN_CROP =
        crop("lupin", 5, -0.5f, 0.15f, 0.2f, LUPIN_CLIMATE, () -> MyCrops.DEAD_LUPIN.get());

    public static final DeferredHolder<Block, MyCropBlock> ADZUKI_CROP =
        crop("adzuki", 5, -0.6f, 0.2f, 0.3f, ADZUKI_CLIMATE, () -> MyCrops.DEAD_ADZUKI.get());

    public static final DeferredHolder<Block, MyCropBlock> BAMBARA_NUT_CROP =
        crop("bambara_nut", 5, -0.6f, 0.15f, 0.25f, BAMBARA_NUT_CLIMATE, () -> MyCrops.DEAD_BAMBARA_NUT.get());

    public static final DeferredHolder<Block, MyCropBlock> FENUGREEK_CROP =
        crop("fenugreek", 5, -0.7f, 0.2f, 0.3f, FENUGREEK_CLIMATE, () -> MyCrops.DEAD_FENUGREEK.get());
    public static final DeferredHolder<Block, MyCropBlock> FLAX_CROP =
        crop("flax", 5, 0.6f, 0.2f, 0.3f, FLAX_CLIMATE, () -> MyCrops.DEAD_FLAX.get());
    public static final DeferredHolder<Block, MyCropBlock> SESAME_CROP =
        crop("sesame", 5, 0.6f, 0.2f, 0.3f, SESAME_CLIMATE, () -> MyCrops.DEAD_SESAME.get());
    public static final DeferredHolder<Block, MyCropBlock> SAFFLOWER_CROP =
        crop("safflower", 5, 0.6f, 0.2f, 0.3f, SAFFLOWER_CLIMATE, () -> MyCrops.DEAD_SAFFLOWER.get());
    public static final DeferredHolder<Block, MyDoubleCropBlock> RAMIE_CROP =
        dbl("ramie", 3, 5, 0.5f, 0.2f, 0.4f, RAMIE_CLIMATE, () -> MyCrops.DEAD_RAMIE.get());
    public static final DeferredHolder<Block, MyPickableCropBlock> CHILI_CROP =
        pickable("chili", 0.3f, 0.4f, 0.5f, CHILI_CLIMATE, () -> MyCrops.DEAD_CHILI.get(), MyCrops.CHILI::get);
    public static final DeferredHolder<Block, MyPickableCropBlock> EGGPLANT_CROP =
        pickable("eggplant", 0.35f, 0.4f, 0.5f, EGGPLANT_CLIMATE, () -> MyCrops.DEAD_EGGPLANT.get(), MyCrops.EGGPLANT::get);
    public static final DeferredHolder<Block, MyPickableCropBlock> OKRA_CROP =
        pickable("okra", 0.4f, 0.35f, 0.5f, OKRA_CLIMATE, () -> MyCrops.DEAD_OKRA.get(), MyCrops.OKRA::get);
    // 棉花是一年生：成熟后连秆收割、只收一茬，所以用普通作物而不是可采摘作物。
    // 产物（棉铃）由掉落表给出，方块本身不需要产物参数。
    public static final DeferredHolder<Block, MyDoubleCropBlock> COTTON_CROP =
        dbl("cotton", 3, 5, 0.6f, 0.3f, -0.3f, COTTON_CLIMATE, () -> MyCrops.DEAD_COTTON.get());
    public static final DeferredHolder<Block, MyPickableCropBlock> ASPARAGUS_CROP =
        pickable("asparagus", 0.6f, 0.3f, 0.4f, ASPARAGUS_CLIMATE, () -> MyCrops.DEAD_ASPARAGUS.get(), MyCrops.ASPARAGUS::get);
    public static final DeferredHolder<Block, MyPickableCropBlock> CHIVE_CROP =
        pickable("chive", 0.6f, -0.2f, -0.2f, CHIVE_CLIMATE, () -> MyCrops.DEAD_CHIVE.get(), MyCrops.CHIVE::get);
    public static final DeferredHolder<Block, MyPickableCropBlock> RHUBARB_CROP =
        pickable("rhubarb", 0.5f, 0.2f, 0.3f, RHUBARB_CLIMATE, () -> MyCrops.DEAD_RHUBARB.get(), MyCrops.RHUBARB::get);
    public static final DeferredHolder<Block, MyPickableCropBlock> ARTICHOKE_CROP =
        pickable("artichoke", 0.7f, 0.3f, 0.5f, ARTICHOKE_CLIMATE, () -> MyCrops.DEAD_ARTICHOKE.get(), MyCrops.ARTICHOKE::get);

    // ---------------- 批次 5：水田作物（10 种，含水方块） ----------------
    public static final DeferredHolder<Block, MyFloodedCropBlock> TARO_CROP =
        flooded("taro", 6, 0.45f, 0.35f, 0.6f, TARO_CLIMATE, () -> MyCrops.DEAD_TARO.get());
    public static final DeferredHolder<Block, MyFloodedCropBlock> WATER_CHESTNUT_CROP =
        flooded("water_chestnut", 5, 0.4f, 0.3f, 0.6f, WATER_CHESTNUT_CLIMATE, () -> MyCrops.DEAD_WATER_CHESTNUT.get());
    public static final DeferredHolder<Block, MyFloodedCropBlock> WATER_CALTROP_CROP =
        flooded("water_caltrop", 5, 0.35f, 0.3f, 0.55f, WATER_CALTROP_CLIMATE, () -> MyCrops.DEAD_WATER_CALTROP.get());
    public static final DeferredHolder<Block, MyFloodedCropBlock> WILD_RICE_STEM_CROP =
        flooded("wild_rice_stem", 5, 0.5f, 0.3f, 0.5f, WILD_RICE_STEM_CLIMATE, () -> MyCrops.DEAD_WILD_RICE_STEM.get());
    public static final DeferredHolder<Block, MyFloodedCropBlock> LOTUS_CROP =
        flooded("lotus", 7, 0.45f, 0.35f, 0.6f, LOTUS_CLIMATE, () -> MyCrops.DEAD_LOTUS.get());
    public static final DeferredHolder<Block, MyFloodedCropBlock> WATER_DROPWORT_CROP =
        flooded("water_dropwort", 5, 0.5f, 0.3f, 0.4f, WATER_DROPWORT_CLIMATE, () -> MyCrops.DEAD_WATER_DROPWORT.get());
    public static final DeferredHolder<Block, MyFloodedCropBlock> WATER_SPINACH_CROP =
        flooded("water_spinach", 5, 0.8f, -0.2f, -0.2f, WATER_SPINACH_CLIMATE, () -> MyCrops.DEAD_WATER_SPINACH.get());
    public static final DeferredHolder<Block, MyFloodedCropBlock> ARROWHEAD_CROP =
        flooded("arrowhead", 5, 0.45f, 0.35f, 0.55f, ARROWHEAD_CLIMATE, () -> MyCrops.DEAD_ARROWHEAD.get());
    public static final DeferredHolder<Block, MyFloodedCropBlock> GORGON_NUT_CROP =
        flooded("gorgon_nut", 5, 0.4f, 0.3f, 0.55f, GORGON_NUT_CLIMATE, () -> MyCrops.DEAD_GORGON_NUT.get());
    public static final DeferredHolder<Block, MyFloodedCropBlock> WATER_SHIELD_CROP =
        flooded("water_shield", 5, 0.4f, 0.2f, 0.3f, WATER_SHIELD_CLIMATE, () -> MyCrops.DEAD_WATER_SHIELD.get());

    // ---------------- 批次 12：莲座类（第 7 种形状） ----------------
    // 叶丛贴地轮生，AGE=叶片轮数（0~5，6 个视觉阶段），FRUITING=中心是否结果。
    // 产物只在 fruiting=true 时掉（生成器的 $prodProps 已按这个条件写），且必定掉 1 个侧芽。
    public static final DeferredHolder<Block, RosetteCropBlock> CARDOON_CROP =
        rosette("cardoon", 0.6f, 0.3f, 0.5f, CARDOON_CLIMATE);
    public static final DeferredHolder<Block, RosetteCropBlock> AGAVE_CROP =
        rosette("agave", 0.3f, 0.2f, 0.5f, AGAVE_CLIMATE);
    public static final DeferredHolder<Block, RosetteCropBlock> PURSLANE_CROP =
        rosette("purslane", 0.4f, 0.2f, 0.3f, PURSLANE_CLIMATE);



    // ---------------- 批次 6：瓜类（蔓延型） ----------------
    // 瓜类的产物**不挂在藤上**：藤成熟时会在旁边放下一个结果方块（整瓜），
    // 整瓜按保质期腐烂，砍开才掉可食切片。所以这里有四样东西要注册：
    // 藤（spread）→ 结果方块（整瓜）→ 腐烂变体 → 切片物品。
    public static final DataManager.Reference<ClimateRange> CANTALOUPE_CLIMATE = climate("crop/cantaloupe");
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_CANTALOUPE =
        dead("cantaloupe", CANTALOUPE_CLIMATE);
    /** 可食切片（砍开整瓜得到） */
    public static final DeferredHolder<Item, Item> CANTALOUPE_SLICE = food("cantaloupe_slice");
    /** 腐烂的整瓜：食品过期后换成普通腐烂方块，不再计时。 */
    public static final DeferredHolder<Block, Block> ROTTEN_CANTALOUPE =
        MyBlocks.BLOCKS.register("rotten_cantaloupe",
            () -> new Block(BlockBehaviour.Properties.of().strength(1.0f)));
    /** 整瓜（结果方块）—— 砍开掉切片，过期变腐烂瓜 */
    public static final DeferredHolder<Block, DecayingBlock> CANTALOUPE =
        RegistrationHelpers.registerBlock(MyBlocks.BLOCKS, MyItems.ITEMS, "cantaloupe",
            () -> new MyDecayingBlock(
                MyBlocks.cropProps()
                    .blockEntity(MyBlockEntities.DECAYING)
                    .serverTicks(DecayingBlockEntity::serverTick),
                MyCrops.ROTTEN_CANTALOUPE),
            block -> new BlockItem(block, new Item.Properties()));
    public static final DeferredHolder<Item, Item> CANTALOUPE_SEEDS =
        seed("cantaloupe", () -> MyCrops.CANTALOUPE_CROP.get(), 0.4f, 0.35f, 0.55f, CANTALOUPE_CLIMATE);
    /** 藤：成熟后在旁边放下整瓜 {CANTALOUPE} */
    public static final DeferredHolder<Block, MySpreadingCropBlock> CANTALOUPE_CROP =
        spread("cantaloupe", 5, 0.4f, 0.35f, 0.55f, CANTALOUPE_CLIMATE,
            () -> MyCrops.DEAD_CANTALOUPE.get(), () -> MyCrops.CANTALOUPE);


    public static final DataManager.Reference<ClimateRange> WINTER_MELON_CLIMATE = climate("crop/winter_melon");
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_WINTER_MELON = dead("winter_melon", WINTER_MELON_CLIMATE);
    public static final DeferredHolder<Item, Item> WINTER_MELON_SLICE = food("winter_melon_slice");
    public static final DeferredHolder<Block, Block> ROTTEN_WINTER_MELON =
        MyBlocks.BLOCKS.register("rotten_winter_melon",
            () -> new Block(BlockBehaviour.Properties.of().strength(1.0f)));
    /** 整瓜（结果方块）—— 砍开掉切片，过期变腐烂瓜 */
    public static final DeferredHolder<Block, DecayingBlock> WINTER_MELON =
        RegistrationHelpers.registerBlock(MyBlocks.BLOCKS, MyItems.ITEMS, "winter_melon",
            () -> new MyDecayingBlock(
                MyBlocks.cropProps()
                    .blockEntity(MyBlockEntities.DECAYING)
                    .serverTicks(DecayingBlockEntity::serverTick),
                MyCrops.ROTTEN_WINTER_MELON),
            block -> new BlockItem(block, new Item.Properties()));
    public static final DeferredHolder<Item, Item> WINTER_MELON_SEEDS =
        seed("winter_melon", () -> MyCrops.WINTER_MELON_CROP.get(), 0.5f, 0.35f, 0.55f, WINTER_MELON_CLIMATE);
    public static final DeferredHolder<Block, MySpreadingCropBlock> WINTER_MELON_CROP =
        spread("winter_melon", 6, 0.5f, 0.35f, 0.55f, WINTER_MELON_CLIMATE, () -> MyCrops.DEAD_WINTER_MELON.get(), () -> MyCrops.WINTER_MELON);

    public static final DataManager.Reference<ClimateRange> BOTTLE_GOURD_CLIMATE = climate("crop/bottle_gourd");
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_BOTTLE_GOURD = dead("bottle_gourd", BOTTLE_GOURD_CLIMATE);
    public static final DeferredHolder<Item, Item> BOTTLE_GOURD_SLICE = food("bottle_gourd_slice");
    public static final DeferredHolder<Block, Block> ROTTEN_BOTTLE_GOURD =
        MyBlocks.BLOCKS.register("rotten_bottle_gourd",
            () -> new Block(BlockBehaviour.Properties.of().strength(1.0f)));
    /** 整瓜（结果方块）—— 砍开掉切片，过期变腐烂瓜 */
    public static final DeferredHolder<Block, DecayingBlock> BOTTLE_GOURD =
        RegistrationHelpers.registerBlock(MyBlocks.BLOCKS, MyItems.ITEMS, "bottle_gourd",
            () -> new MyDecayingBlock(
                MyBlocks.cropProps()
                    .blockEntity(MyBlockEntities.DECAYING)
                    .serverTicks(DecayingBlockEntity::serverTick),
                MyCrops.ROTTEN_BOTTLE_GOURD),
            block -> new BlockItem(block, new Item.Properties()));
    public static final DeferredHolder<Item, Item> BOTTLE_GOURD_SEEDS =
        seed("bottle_gourd", () -> MyCrops.BOTTLE_GOURD_CROP.get(), 0.4f, 0.3f, 0.5f, BOTTLE_GOURD_CLIMATE);
    public static final DeferredHolder<Block, MySpreadingCropBlock> BOTTLE_GOURD_CROP =
        spread("bottle_gourd", 5, 0.4f, 0.3f, 0.5f, BOTTLE_GOURD_CLIMATE, () -> MyCrops.DEAD_BOTTLE_GOURD.get(), () -> MyCrops.BOTTLE_GOURD);


    // ---------------- 批次 6：佛手瓜（攀爬型） ----------------
    // 与其它三种瓜不同：藤需要木棍才能往上爬，**产物直接挂在藤上**。
    // 而且佛手瓜现实只有 10~15cm，**不做整瓜方块** —— 产物就是可食的整个瓜。
    public static final DataManager.Reference<ClimateRange> CHAYOTE_CLIMATE = climate("crop/chayote");
    /** 死株用 DeadClimbingCropBlock —— 它比普通死株多一个 STICK 属性，必须配套 */
    public static final DeferredHolder<Block, Block> DEAD_CHAYOTE =
        MyBlocks.BLOCKS.register("dead_crop/chayote",
            () -> new DeadClimbingCropBlock(MyBlocks.deadProps(), CHAYOTE_CLIMATE));
    /** 可食的整个瓜（佛手瓜很小，不做方块） */
    public static final DeferredHolder<Item, Item> CHAYOTE = food("chayote");
    public static final DeferredHolder<Item, Item> CHAYOTE_SEEDS =
        seed("chayote", () -> MyCrops.CHAYOTE_CROP.get(), 0.4f, 0.35f, 0.5f, CHAYOTE_CLIMATE);
    /** 攀爬藤：maxSingleAge=4 / maxAge=7，与 TFC 的番茄同一套年龄切分 */
    public static final DeferredHolder<Block, MyClimbingCropBlock> CHAYOTE_CROP =
        climb("chayote", 4, 7, 0.4f, 0.35f, 0.5f, CHAYOTE_CLIMATE, () -> MyCrops.DEAD_CHAYOTE.get());


    // ---------------- 批次 7：攀爬作物（6 种） ----------------
    // 全部需要木棍攀爬（climb），产物直接挂在藤上；年龄切分照 TFC 番茄的 4+4。
    public static final DataManager.Reference<ClimateRange> HOPS_CLIMATE = climate("crop/hops");
    public static final DeferredHolder<Block, Block> DEAD_HOPS =
        MyBlocks.BLOCKS.register("dead_crop/hops",
            () -> new DeadClimbingCropBlock(MyBlocks.deadProps(), HOPS_CLIMATE));
    /** 产物不是食物：啤酒花是酿酒原料（表里 prod='hops' → 生成器不会给它食物数据） */
    public static final DeferredHolder<Item, Item> HOPS = material("hops");
    public static final DeferredHolder<Item, Item> HOPS_SEEDS =
        seed("hops", () -> MyCrops.HOPS_CROP.get(), 0.9f, 0.2f, -0.3f, HOPS_CLIMATE);
    public static final DeferredHolder<Block, MyClimbingCropBlock> HOPS_CROP =
        climb("hops", 4, 7, 0.9f, 0.2f, -0.3f, HOPS_CLIMATE, () -> MyCrops.DEAD_HOPS.get());

    public static final DataManager.Reference<ClimateRange> LOOFAH_CLIMATE = climate("crop/loofah");
    public static final DeferredHolder<Block, Block> DEAD_LOOFAH =
        MyBlocks.BLOCKS.register("dead_crop/loofah",
            () -> new DeadClimbingCropBlock(MyBlocks.deadProps(), LOOFAH_CLIMATE));
    public static final DeferredHolder<Item, Item> LOOFAH = food("loofah");
    public static final DeferredHolder<Item, Item> LOOFAH_SEEDS =
        seed("loofah", () -> MyCrops.LOOFAH_CROP.get(), 0.45f, 0.3f, 0.5f, LOOFAH_CLIMATE);
    public static final DeferredHolder<Block, MyClimbingCropBlock> LOOFAH_CROP =
        climb("loofah", 4, 7, 0.45f, 0.3f, 0.5f, LOOFAH_CLIMATE, () -> MyCrops.DEAD_LOOFAH.get());

    public static final DataManager.Reference<ClimateRange> BITTER_MELON_CLIMATE = climate("crop/bitter_melon");
    public static final DeferredHolder<Block, Block> DEAD_BITTER_MELON =
        MyBlocks.BLOCKS.register("dead_crop/bitter_melon",
            () -> new DeadClimbingCropBlock(MyBlocks.deadProps(), BITTER_MELON_CLIMATE));
    public static final DeferredHolder<Item, Item> BITTER_MELON = food("bitter_melon");
    public static final DeferredHolder<Item, Item> BITTER_MELON_SEEDS =
        seed("bitter_melon", () -> MyCrops.BITTER_MELON_CROP.get(), 0.4f, 0.35f, 0.5f, BITTER_MELON_CLIMATE);
    public static final DeferredHolder<Block, MyClimbingCropBlock> BITTER_MELON_CROP =
        climb("bitter_melon", 4, 7, 0.4f, 0.35f, 0.5f, BITTER_MELON_CLIMATE, () -> MyCrops.DEAD_BITTER_MELON.get());

    public static final DataManager.Reference<ClimateRange> SNAKE_GOURD_CLIMATE = climate("crop/snake_gourd");
    public static final DeferredHolder<Block, Block> DEAD_SNAKE_GOURD =
        MyBlocks.BLOCKS.register("dead_crop/snake_gourd",
            () -> new DeadClimbingCropBlock(MyBlocks.deadProps(), SNAKE_GOURD_CLIMATE));
    public static final DeferredHolder<Item, Item> SNAKE_GOURD = food("snake_gourd");
    public static final DeferredHolder<Item, Item> SNAKE_GOURD_SEEDS =
        seed("snake_gourd", () -> MyCrops.SNAKE_GOURD_CROP.get(), 0.4f, 0.35f, 0.5f, SNAKE_GOURD_CLIMATE);
    public static final DeferredHolder<Block, MyClimbingCropBlock> SNAKE_GOURD_CROP =
        climb("snake_gourd", 4, 7, 0.4f, 0.35f, 0.5f, SNAKE_GOURD_CLIMATE, () -> MyCrops.DEAD_SNAKE_GOURD.get());

    public static final DataManager.Reference<ClimateRange> YAM_CLIMATE = climate("crop/yam");
    public static final DeferredHolder<Block, Block> DEAD_YAM =
        MyBlocks.BLOCKS.register("dead_crop/yam",
            () -> new DeadClimbingCropBlock(MyBlocks.deadProps(), YAM_CLIMATE));
    public static final DeferredHolder<Item, Item> YAM = food("yam");
    public static final DeferredHolder<Item, Item> YAM_SEEDS =
        seed("yam", () -> MyCrops.YAM_CROP.get(), 0.5f, 0.3f, 0.6f, YAM_CLIMATE);
    public static final DeferredHolder<Block, MyClimbingCropBlock> YAM_CROP =
        climb("yam", 4, 7, 0.5f, 0.3f, 0.6f, YAM_CLIMATE, () -> MyCrops.DEAD_YAM.get());

    public static final DataManager.Reference<ClimateRange> MALABAR_SPINACH_CLIMATE = climate("crop/malabar_spinach");
    // ── 补齐物种缺口（2026-09-26）：豆科攀爬 4 + 木豆 + 向日葵 + 大麻 + 高粱 + 剑麻 ──
    public static final DataManager.Reference<ClimateRange> PEA_CLIMATE = climate("crop/pea");
    public static final DataManager.Reference<ClimateRange> COWPEA_CLIMATE = climate("crop/cowpea");
    public static final DataManager.Reference<ClimateRange> COMMON_BEAN_CLIMATE = climate("crop/common_bean");
    public static final DataManager.Reference<ClimateRange> WINGED_BEAN_CLIMATE = climate("crop/winged_bean");
    public static final DataManager.Reference<ClimateRange> PIGEON_PEA_CLIMATE = climate("crop/pigeon_pea");
    public static final DataManager.Reference<ClimateRange> SUNFLOWER_CLIMATE = climate("crop/sunflower");
    public static final DataManager.Reference<ClimateRange> HEMP_CLIMATE = climate("crop/hemp");
    public static final DataManager.Reference<ClimateRange> SORGHUM_CLIMATE = climate("crop/sorghum");
    public static final DataManager.Reference<ClimateRange> SISAL_CLIMATE = climate("crop/sisal");

    // ⚠️ 死株必须紧跟气候定义（Java 的 static final 前向引用是编译错误）
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_PEA = deadClimbing("pea", PEA_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_COWPEA = deadClimbing("cowpea", COWPEA_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_COMMON_BEAN = deadClimbing("common_bean", COMMON_BEAN_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_WINGED_BEAN = deadClimbing("winged_bean", WINGED_BEAN_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_PIGEON_PEA = deadDouble("pigeon_pea", PIGEON_PEA_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_SUNFLOWER = deadDouble("sunflower", SUNFLOWER_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_HEMP = deadDouble("hemp", HEMP_CLIMATE);
    public static final DeferredHolder<Block, DeadCropBlock> DEAD_SORGHUM = deadDouble("sorghum", SORGHUM_CLIMATE);
    public static final DeferredHolder<Block, Block> DEAD_MALABAR_SPINACH =
        MyBlocks.BLOCKS.register("dead_crop/malabar_spinach",
            () -> new DeadClimbingCropBlock(MyBlocks.deadProps(), MALABAR_SPINACH_CLIMATE));
    public static final DeferredHolder<Item, Item> MALABAR_SPINACH = food("malabar_spinach");
    public static final DeferredHolder<Item, Item> PEA = food("pea");
    public static final DeferredHolder<Item, Item> COWPEA = food("cowpea");
    public static final DeferredHolder<Item, Item> COMMON_BEAN = food("common_bean");
    public static final DeferredHolder<Item, Item> WINGED_BEAN = food("winged_bean");
    public static final DeferredHolder<Item, Item> PIGEON_PEA = food("pigeon_pea");
    public static final DeferredHolder<Item, Item> SUNFLOWER = food("sunflower");
    public static final DeferredHolder<Item, Item> HEMP_FIBER = fibre("fiber/hemp");
    public static final DeferredHolder<Item, Item> SORGHUM = food("sorghum");
    public static final DeferredHolder<Item, Item> SISAL_FIBER = fibre("fiber/sisal");
    public static final DeferredHolder<Item, Item> MALABAR_SPINACH_SEEDS =
        seed("malabar_spinach", () -> MyCrops.MALABAR_SPINACH_CROP.get(), 0.7f, -0.2f, -0.2f, MALABAR_SPINACH_CLIMATE);
    public static final DeferredHolder<Item, Item> PEA_SEEDS =
        seed("pea", () -> MyCrops.PEA_CROP.get(), -0.7f, 0.3f, 0.3f, PEA_CLIMATE);
    public static final DeferredHolder<Item, Item> COWPEA_SEEDS =
        seed("cowpea", () -> MyCrops.COWPEA_CROP.get(), -0.8f, 0.4f, 0.3f, COWPEA_CLIMATE);
    public static final DeferredHolder<Item, Item> COMMON_BEAN_SEEDS =
        seed("common_bean", () -> MyCrops.COMMON_BEAN_CROP.get(), -0.8f, 0.4f, 0.4f, COMMON_BEAN_CLIMATE);
    public static final DeferredHolder<Item, Item> WINGED_BEAN_SEEDS =
        seed("winged_bean", () -> MyCrops.WINGED_BEAN_CROP.get(), -1.0f, 0.3f, 0.4f, WINGED_BEAN_CLIMATE);
    public static final DeferredHolder<Item, Item> PIGEON_PEA_SEEDS =
        seed("pigeon_pea", () -> MyCrops.PIGEON_PEA_CROP.get(), -0.9f, 0.4f, 0.4f, PIGEON_PEA_CLIMATE);
    public static final DeferredHolder<Item, Item> SUNFLOWER_SEEDS =
        seed("sunflower", () -> MyCrops.SUNFLOWER_CROP.get(), 0.8f, -0.3f, -0.4f, SUNFLOWER_CLIMATE);
    public static final DeferredHolder<Item, Item> HEMP_SEEDS =
        seed("hemp", () -> MyCrops.HEMP_CROP.get(), 0.7f, -0.3f, -0.3f, HEMP_CLIMATE);
    public static final DeferredHolder<Item, Item> SORGHUM_SEEDS =
        seed("sorghum", () -> MyCrops.SORGHUM_CROP.get(), 1.0f, -0.3f, -0.3f, SORGHUM_CLIMATE);
    public static final DeferredHolder<Item, Item> SISAL_SEEDS =
        seed("sisal", () -> MyCrops.SISAL_CROP.get(), 0.4f, -0.4f, -0.4f, SISAL_CLIMATE);
    public static final DeferredHolder<Block, MyClimbingCropBlock> MALABAR_SPINACH_CROP =
        climb("malabar_spinach", 4, 7, 0.7f, -0.2f, -0.2f, MALABAR_SPINACH_CLIMATE, () -> MyCrops.DEAD_MALABAR_SPINACH.get());
    public static final DeferredHolder<Block, MyClimbingCropBlock> PEA_CROP =
        climb("pea", 4, 7, -0.7f, 0.3f, 0.3f, PEA_CLIMATE, () -> MyCrops.DEAD_PEA.get());
    public static final DeferredHolder<Block, MyClimbingCropBlock> COWPEA_CROP =
        climb("cowpea", 4, 7, -0.8f, 0.4f, 0.3f, COWPEA_CLIMATE, () -> MyCrops.DEAD_COWPEA.get());
    public static final DeferredHolder<Block, MyClimbingCropBlock> COMMON_BEAN_CROP =
        climb("common_bean", 4, 7, -0.8f, 0.4f, 0.4f, COMMON_BEAN_CLIMATE, () -> MyCrops.DEAD_COMMON_BEAN.get());
    public static final DeferredHolder<Block, MyClimbingCropBlock> WINGED_BEAN_CROP =
        climb("winged_bean", 4, 7, -1.0f, 0.3f, 0.4f, WINGED_BEAN_CLIMATE, () -> MyCrops.DEAD_WINGED_BEAN.get());
    public static final DeferredHolder<Block, MyDoubleCropBlock> PIGEON_PEA_CROP =
        dbl("pigeon_pea", 3, 5, -0.9f, 0.4f, 0.4f, PIGEON_PEA_CLIMATE, () -> MyCrops.DEAD_PIGEON_PEA.get());
    public static final DeferredHolder<Block, MyDoubleCropBlock> SUNFLOWER_CROP =
        dbl("sunflower", 3, 5, 0.8f, -0.3f, -0.4f, SUNFLOWER_CLIMATE, () -> MyCrops.DEAD_SUNFLOWER.get());
    public static final DeferredHolder<Block, MyDoubleCropBlock> HEMP_CROP =
        dbl("hemp", 3, 5, 0.7f, -0.3f, -0.3f, HEMP_CLIMATE, () -> MyCrops.DEAD_HEMP.get());
    public static final DeferredHolder<Block, MyDoubleCropBlock> SORGHUM_CROP =
        dbl("sorghum", 3, 5, 1.0f, -0.3f, -0.3f, SORGHUM_CLIMATE, () -> MyCrops.DEAD_SORGHUM.get());
    public static final DeferredHolder<Block, RosetteCropBlock> SISAL_CROP =
        rosette("sisal", 0.4f, -0.4f, -0.4f, SISAL_CLIMATE);

    // ---------------- 辅助方法 ----------------

    /** 非食物的材料类产物（纤维等）：不带任何食物数据 */
    private static DeferredHolder<Item, Item> fibre(String name) {
        return MyItems.ITEMS.register(name, () -> new Item(new Item.Properties()));
    }

    /** 可采摘作物（表达「多年生」）：采摘后退回成长状态、植株保留 */
    private static DeferredHolder<Block, MyPickableCropBlock> pickable(String name, float n, float p, float k,
            Supplier<ClimateRange> climateRange, Supplier<? extends Block> dead, Supplier<Item> fruit) {
        return RegistrationHelpers.registerBlock(MyBlocks.BLOCKS, null, "crop/" + name,
            () -> MyPickableCropBlock.create(
                MyBlocks.cropProps().blockEntity(MyBlockEntities.CROP).serverTicks(CropBlockEntity::serverTick),
                5, dead, seedFor(name), n, p, k, climateRange, () -> fruit, () -> fruit),
            null);
    }

    /** 注册一个**非食物**的材料物品（酿酒原料之类），走 tfcfarmingplus:<name> */
    private static DeferredHolder<Item, Item> material(String name) {
        return MyItems.ITEMS.register(name, () -> new Item(new Item.Properties()));
    }

    private static DeferredHolder<Item, Item> food(String name) {
        return MyItems.ITEMS.register("food/" + name, () -> new Item(new Item.Properties()));
    }

    private static DeferredHolder<Item, Item> seed(String name, Supplier<Block> cropBlock,
                                                   float n, float p, float k,
                                                   Supplier<ClimateRange> climateRange) {
        return MyItems.ITEMS.register("seeds/" + name,
            () -> new MySeedItem(cropBlock.get(), n, p, k, climateRange, new Item.Properties()));
    }

    /**
     * 注册一个作物方块。
     * <p>
     * 关键点（照 TFC 的 {@code Crop.crop()}）：
     * {@code .blockEntity(TFCBlockEntities.CROP)} + {@code .serverTicks(CropBlockEntity::serverTick)}
     * —— 生长进度存在方块实体里，而不是 BlockState。
     * <p>
     * 这里传 {@code null} 给 items 与 blockItemFactory，即「不生成方块物品」，
     * 与 TFC 的 {@code registerNoItem} 等价。
     */
    private static DeferredHolder<Block, MyCropBlock> crop(String name, int maxAge,
                                                           float n, float p, float k,
                                                           Supplier<ClimateRange> climateRange,
                                                           Supplier<? extends Block> dead) {
        return RegistrationHelpers.registerBlock(MyBlocks.BLOCKS, null, "crop/" + name,
            // ⚠️ 必须走 MyCropBlock.create()：age 属性要在 new 之前算好并由匿名子类捕获，
            //    否则 Block 构造器回调 createBlockStateDefinition 时会拿到 null 而崩溃（已实测）
            // ⚠️ BE 类型必须用 MyBlockEntities.CROP（自建），用 TFC 的会触发原版
            //    BlockEntity.validateBlockState 校验失败（已实测）
            () -> MyCropBlock.create(
                MyBlocks.cropProps()
                    .blockEntity(MyBlockEntities.CROP)
                    .serverTicks(CropBlockEntity::serverTick),
                maxAge, dead, seedFor(name), n, p, k, climateRange),
            null);
    }

    /**
     * 注册一个**莲座**作物 —— <b>本模组的第 7 种作物形状</b>（批次 12：刺菜蓟 / 龙舌兰 / 马齿苋）。
     * <p>
     * 与 {@link #crop} 的区别全在 {@link RosetteCropBlock}：
     * {@code AGE} 表示<b>叶片轮数</b>（横向规模）而不是「长得更高」，
     * 另有一个独立的 {@code FRUITING} 状态表示「中心是否已结果」——
     * 只有 {@code fruiting=true} 时才掉产物（见 gen-crops.ps1 的 $prodProps）。
     * <p>
     * <b>不需要 create() 捕获技巧</b>：{@code MyCropBlock} 要把 maxAge 在 {@code new} 之前算好传给匿名子类，
     * 而 {@code RosetteCropBlock} 的 AGE 是<b>类加载期就绪的静态字段</b>，基类构造器回调
     * {@code getAgeProperty()} 时它已经可用，所以直接 new 是安全的。
     * <p>
     * ⚠️ 死株走<b>共享的</b> {@code MyBlocks.DEAD_ROSETTE}：{@code RosetteCropBlock.die()} 里
     * 成功换成死株后把侧芽（种子）直接弹到地上，所以这类作物<b>没有</b> per-crop 的
     * {@code dead_crop/<name>} 方块，生成器也相应地跳过了它们的枯萎掉落表。
     */
    private static DeferredHolder<Block, RosetteCropBlock> rosette(String name,
                                                                   float n, float p, float k,
                                                                   Supplier<ClimateRange> climateRange) {
        return RegistrationHelpers.registerBlock(MyBlocks.BLOCKS, null, "crop/" + name,
            // ⚠️ BE 类型必须用 MyBlockEntities.CROP（自建），用 TFC 的会触发
            //    BlockEntity.validateBlockState 校验失败（已实测）
            () -> new RosetteCropBlock(
                MyBlocks.cropProps()
                    .blockEntity(MyBlockEntities.CROP)
                    .serverTicks(CropBlockEntity::serverTick),
                () -> MyBlocks.DEAD_ROSETTE.get(), seedFor(name), n, p, k, climateRange),
            null);
    }

    /**
     * 注册一个**双格**作物（高秆作物专用，占上下两格）。
     * <p>
     * 判据是**现实栽培株高常态超过 1 米**：黍、谷子、斯佩耳特麦、二粒麦、珍珠粟、苋米、藜麦、薏苡、
     * 蚕豆、苎麻、棉花、洋姜。用单格表现会明显失真，所以走 TFC 的 {@code DoubleCropBlock}。
     * <p>
     * ⚠️ <b>可采摘类作物（秋葵、洋蓟）现实虽高，但仍然保持单格</b> ——
     * TFC 只有 {@code PickableCropBlock} 与 {@code PickableClimbingCropBlock}，
     * <b>没有 PickableDoubleCropBlock</b>，两种机制无法组合。
     *
     * @param singleAge 还能用单格模型表示的最后一个 age + 1：
     *                  {@code maxAge=5} 的作物传 3（双格段 3~5），{@code maxAge=7} 的传 4（双格段 4~7）。
     *                  这两个切分点与 TFC 双格贴图的年龄区间一一对应（见 gen-crops.ps1 的 dblRef）。
     */
    private static DeferredHolder<Block, MyDoubleCropBlock> dbl(String name, int singleAge, int maxAge,
                                                                float n, float p, float k,
                                                                Supplier<ClimateRange> climateRange,
                                                                Supplier<? extends Block> dead) {
        return RegistrationHelpers.registerBlock(MyBlocks.BLOCKS, null, "crop/" + name,
            // ⚠️ 同 MyCropBlock：age 属性必须在 new 之前算好并由匿名子类捕获
            () -> MyDoubleCropBlock.create(
                MyBlocks.cropProps()
                    .blockEntity(MyBlockEntities.CROP)
                    .serverTicks(CropBlockEntity::serverTick),
                singleAge, maxAge, dead, seedFor(name), n, p, k, climateRange),
            null);
    }

    /**
     * 注册一个作物枯死后的方块（无方块物品，等价 TFC 的 {@code registerNoItem}）。
     *
     * @param climateRange 与作物一致的气候引用 —— TFC 的死株也这么做，用于锄头 tooltip 显示环境信息
     */
    // Keep the existing registry IDs; the native death transition needs matching properties.
    private static DeferredHolder<Block, DeadCropBlock> deadDouble(String name, Supplier<ClimateRange> climateRange) {
        return MyBlocks.BLOCKS.register("dead_crop/" + name,
            () -> new DeadDoubleCropBlock(MyBlocks.deadProps(), climateRange));
    }

    private static DeferredHolder<Block, DeadCropBlock> deadClimbing(String name, Supplier<ClimateRange> climateRange) {
        return MyBlocks.BLOCKS.register("dead_crop/" + name,
            () -> new DeadClimbingCropBlock(MyBlocks.deadProps(), climateRange));
    }

    private static DeferredHolder<Block, DeadCropBlock> dead(String name, Supplier<ClimateRange> climateRange) {
        return MyBlocks.BLOCKS.register("dead_crop/" + name,
            () -> new DeadCropBlock(MyBlocks.deadProps(), climateRange));
    }
    /**
     * 注册一个**蔓延型**作物（瓜类）：藤向四个水平方向铺开，成熟后放下结果方块。
     * <p>
     * 与其它作物的关键差别：产物不在藤身上，而在 {@code fruit} 指定的结果方块上，
     * 所以藤的掉落表只掉种子。
     *
     * @param fruit 「结果方块」的提供者。写成双层 Supplier 是因为藤与结果方块互相引用，
     *              直接引用会触发 Java 的静态初始化前向引用错误；调用方写 {@code () -> MyCrops.MY_MELON} 即可。
     */
    private static DeferredHolder<Block, MySpreadingCropBlock> spread(String name, int maxAge,
                                                                      float n, float p, float k,
                                                                      Supplier<ClimateRange> climateRange,
                                                                      Supplier<? extends Block> dead,
                                                                      Supplier<Supplier<? extends Block>> fruit) {
        return RegistrationHelpers.registerBlock(MyBlocks.BLOCKS, null, "crop/" + name,
            () -> MySpreadingCropBlock.create(
                MyBlocks.cropProps()
                    .blockEntity(MyBlockEntities.CROP)
                    .serverTicks(CropBlockEntity::serverTick),
                maxAge, dead, seedFor(name), n, p, k, climateRange, fruit),
            null);
    }

    /**
     * 注册一个**攀爬型**作物（佛手瓜）：需要木棍才能往上爬，方块状态是 age × stick × part 三维。
     * <p>
     * 与 {@link #spread} 的区别：攀爬作物的**产物直接挂在藤上**（成熟后采收），
     * 不会像瓜类那样自动在旁边放下结果方块，所以它的掉落表照普通作物写（产物 + 种子）。
     *
     * @param singleAge 还能用单格模型表示的最后一个 age + 1（照 TFC 番茄的 4）
     */
    private static DeferredHolder<Block, MyClimbingCropBlock> climb(String name, int singleAge, int maxAge,
                                                                   float n, float p, float k,
                                                                   Supplier<ClimateRange> climateRange,
                                                                   Supplier<? extends Block> dead) {
        return RegistrationHelpers.registerBlock(MyBlocks.BLOCKS, null, "crop/" + name,
            () -> MyClimbingCropBlock.create(
                MyBlocks.cropProps()
                    .blockEntity(MyBlockEntities.CROP)
                    .serverTicks(CropBlockEntity::serverTick),
                singleAge, maxAge, dead, seedFor(name), n, p, k, climateRange),
            null);
    }

    /** 水田作物的死株：多实现 IFluidLoggable，枯萎后仍保持含水（照 TFC 的 FloodedDeadCropBlock） */
    private static DeferredHolder<Block, DeadCropBlock> deadFlooded(String name, Supplier<ClimateRange> climateRange) {
        return MyBlocks.BLOCKS.register("dead_crop/" + name,
            () -> new FloodedDeadCropBlock(MyBlocks.deadProps(), climateRange));
    }

    /**
     * 注册一个**水田**作物（含水方块，必须种在积水的耕地上）。
     * <p>
     * 与 {@link #crop} 的唯一区别是方块类：{@link MyFloodedCropBlock} 额外实现 {@code IFluidLoggable}，
     * 无水状态的生长上限为 0，正常播种位置必须预先有淡水水源。
     * 原生方块状态包含 age 与 fluid；模型 JSON 省略 fluid 仅表示两种流体状态共用同龄模型。
     */
    private static DeferredHolder<Block, MyFloodedCropBlock> flooded(String name, int maxAge,
                                                                     float n, float p, float k,
                                                                     Supplier<ClimateRange> climateRange,
                                                                     Supplier<? extends Block> dead) {
        return RegistrationHelpers.registerBlock(MyBlocks.BLOCKS, null, "crop/" + name,
            () -> MyFloodedCropBlock.create(
                MyBlocks.cropProps()
                    .blockEntity(MyBlockEntities.CROP)
                    .serverTicks(CropBlockEntity::serverTick),
                maxAge, dead, seedFor(name), n, p, k, climateRange),
            null);
    }

    /**
     * 全部作物方块（供 {@link MyBlockEntities} 登记 BE 类型的 validBlocks 使用）。
     * <p>
     * 以后新增作物时，记得把新方块也加进这个数组，否则放下时会被原版校验拦下。
     */
    public static Block[] cropBlocks() {
        return new Block[] {
            SPINACH_CROP.get(), LETTUCE_CROP.get(), CELERY_CROP.get(), KALE_CROP.get(),
            STRAWBERRY_CROP.get(),
            NAPA_CABBAGE_CROP.get(), MUSTARD_GREENS_CROP.get(), BROCCOLI_CROP.get(), CAULIFLOWER_CROP.get(),
            BRUSSELS_SPROUTS_CROP.get(), SWISS_CHARD_CROP.get(), CELTUCE_CROP.get(), GARLAND_CHRYSANTHEMUM_CROP.get(), PERILLA_CROP.get(), ARUGULA_CROP.get(), TURNIP_CROP.get(), PARSNIP_CROP.get(), SUNCHOKE_CROP.get(), SHALLOT_CROP.get(), CELERIAC_CROP.get(), SALSIFY_CROP.get(), GINGER_CROP.get(), TURMERIC_CROP.get(), YACON_CROP.get(), CHICORY_ROOT_CROP.get(),
            // 批次 12：莲座类（RosetteCropBlock 也是 Block，渲染层登记一并覆盖）
            CARDOON_CROP.get(), AGAVE_CROP.get(), PURSLANE_CROP.get(),
            MILLET_CROP.get(), FOXTAIL_MILLET_CROP.get(), BUCKWHEAT_CROP.get(), FONIO_CROP.get(), SPELT_CROP.get(), EMMER_CROP.get(), EINKORN_CROP.get(), PEARL_MILLET_CROP.get(), AMARANTH_CROP.get(), QUINOA_CROP.get(), FINGER_MILLET_CROP.get(), JOBS_TEARS_CROP.get(),
            CHICKPEA_CROP.get(), FABA_BEAN_CROP.get(), LUPIN_CROP.get(), ADZUKI_CROP.get(), BAMBARA_NUT_CROP.get(), FENUGREEK_CROP.get(), FLAX_CROP.get(), SESAME_CROP.get(), SAFFLOWER_CROP.get(), RAMIE_CROP.get(), CHILI_CROP.get(), EGGPLANT_CROP.get(), OKRA_CROP.get(), COTTON_CROP.get(), ASPARAGUS_CROP.get(), CHIVE_CROP.get(), RHUBARB_CROP.get(), ARTICHOKE_CROP.get(), CANTALOUPE_CROP.get(), WINTER_MELON_CROP.get(), BOTTLE_GOURD_CROP.get(), CHAYOTE_CROP.get(), HOPS_CROP.get(), LOOFAH_CROP.get(), BITTER_MELON_CROP.get(), SNAKE_GOURD_CROP.get(), YAM_CROP.get(), MALABAR_SPINACH_CROP.get(), TARO_CROP.get(), WATER_CHESTNUT_CROP.get(), WATER_CALTROP_CROP.get(), WILD_RICE_STEM_CROP.get(), LOTUS_CROP.get(), WATER_DROPWORT_CROP.get(), WATER_SPINACH_CROP.get(), ARROWHEAD_CROP.get(), GORGON_NUT_CROP.get(), WATER_SHIELD_CROP.get(),
            // 补齐物种缺口（2026-09-26）：豆科攀爬 4 + 木豆 + 向日葵 + 大麻 + 高粱 + 剑麻
            PEA_CROP.get(), COWPEA_CROP.get(), COMMON_BEAN_CROP.get(), WINGED_BEAN_CROP.get(), PIGEON_PEA_CROP.get(), SUNFLOWER_CROP.get(), HEMP_CROP.get(), SORGHUM_CROP.get(), SISAL_CROP.get()
        };
    }

    /**
     * 全部**结果方块**（瓜类的整瓜与其腐烂变体），供 {@link MyBlockEntities#DECAYING} 登记
     * validBlocks 使用。
     * <p>
     * 三种正常瓜使用实体；三种旧腐烂宿主保留有效类型兼容，但当前腐烂方块是普通Block。
     * 腐烂替换会移除正常瓜实体，不要求腐烂方块继续创建或tick实体。
     */
    public static Block[] fruitBlocks() {
        return new Block[] {
            CANTALOUPE.get(), ROTTEN_CANTALOUPE.get(),
            WINTER_MELON.get(), ROTTEN_WINTER_MELON.get(),
            BOTTLE_GOURD.get(), ROTTEN_BOTTLE_GOURD.get()
        };
    }

    /** 按名字找到对应的种子物品（供死株掉落用） */
    private static Supplier<Item> seedFor(String name) {
        return switch (name) {
            case "spinach" -> SPINACH_SEEDS;
            case "lettuce" -> LETTUCE_SEEDS;
            case "celery" -> CELERY_SEEDS;
            case "kale" -> KALE_SEEDS;
            case "napa_cabbage" -> NAPA_CABBAGE_SEEDS;
            case "mustard_greens" -> MUSTARD_GREENS_SEEDS;
            case "broccoli" -> BROCCOLI_SEEDS;
            case "cauliflower" -> CAULIFLOWER_SEEDS;
            case "brussels_sprouts" -> BRUSSELS_SPROUTS_SEEDS;
            case "swiss_chard" -> SWISS_CHARD_SEEDS;
            case "celtuce" -> CELTUCE_SEEDS;
            case "garland_chrysanthemum" -> GARLAND_CHRYSANTHEMUM_SEEDS;
            case "perilla" -> PERILLA_SEEDS;
            case "arugula" -> ARUGULA_SEEDS;
            case "turnip" -> TURNIP_SEEDS;
            case "parsnip" -> PARSNIP_SEEDS;
            case "sunchoke" -> SUNCHOKE_SEEDS;
            case "shallot" -> SHALLOT_SEEDS;
            case "celeriac" -> CELERIAC_SEEDS;
            case "salsify" -> SALSIFY_SEEDS;
            case "ginger" -> GINGER_SEEDS;
            case "turmeric" -> TURMERIC_SEEDS;
            case "yacon" -> YACON_SEEDS;
            case "chicory_root" -> CHICORY_ROOT_SEEDS;
            case "millet" -> MILLET_SEEDS;
            case "foxtail_millet" -> FOXTAIL_MILLET_SEEDS;
            case "buckwheat" -> BUCKWHEAT_SEEDS;
            case "fonio" -> FONIO_SEEDS;
            case "spelt" -> SPELT_SEEDS;
            case "emmer" -> EMMER_SEEDS;
            case "einkorn" -> EINKORN_SEEDS;
            case "pearl_millet" -> PEARL_MILLET_SEEDS;
            case "amaranth" -> AMARANTH_SEEDS;
            case "quinoa" -> QUINOA_SEEDS;
            case "finger_millet" -> FINGER_MILLET_SEEDS;
            case "jobs_tears" -> JOBS_TEARS_SEEDS;
            case "chickpea" -> CHICKPEA_SEEDS;
            case "faba_bean" -> FABA_BEAN_SEEDS;
            case "lupin" -> LUPIN_SEEDS;
            case "adzuki" -> ADZUKI_SEEDS;
            case "bambara_nut" -> BAMBARA_NUT_SEEDS;
            case "fenugreek" -> FENUGREEK_SEEDS;
            case "flax" -> FLAX_SEEDS;
            case "sesame" -> SESAME_SEEDS;
            case "safflower" -> SAFFLOWER_SEEDS;
            case "ramie" -> RAMIE_SEEDS;
            case "chili" -> CHILI_SEEDS;
            case "eggplant" -> EGGPLANT_SEEDS;
            case "okra" -> OKRA_SEEDS;
            case "cotton" -> COTTON_SEEDS;
            case "asparagus" -> ASPARAGUS_SEEDS;
            case "chive" -> CHIVE_SEEDS;
            case "rhubarb" -> RHUBARB_SEEDS;
            case "artichoke" -> ARTICHOKE_SEEDS;
            case "cantaloupe" -> CANTALOUPE_SEEDS;
            case "winter_melon" -> WINTER_MELON_SEEDS;
            case "bottle_gourd" -> BOTTLE_GOURD_SEEDS;
            case "chayote" -> CHAYOTE_SEEDS;
            case "hops" -> HOPS_SEEDS;
            case "loofah" -> LOOFAH_SEEDS;
            case "bitter_melon" -> BITTER_MELON_SEEDS;
            case "snake_gourd" -> SNAKE_GOURD_SEEDS;
            case "yam" -> YAM_SEEDS;
            case "malabar_spinach" -> MALABAR_SPINACH_SEEDS;
            case "taro" -> TARO_SEEDS;
            case "water_chestnut" -> WATER_CHESTNUT_SEEDS;
            case "water_caltrop" -> WATER_CALTROP_SEEDS;
            case "wild_rice_stem" -> WILD_RICE_STEM_SEEDS;
            case "lotus" -> LOTUS_SEEDS;
            case "water_dropwort" -> WATER_DROPWORT_SEEDS;
            case "water_spinach" -> WATER_SPINACH_SEEDS;
            case "arrowhead" -> ARROWHEAD_SEEDS;
            case "gorgon_nut" -> GORGON_NUT_SEEDS;
            case "water_shield" -> WATER_SHIELD_SEEDS;
            case "pea" -> PEA_SEEDS;
            case "cowpea" -> COWPEA_SEEDS;
            case "common_bean" -> COMMON_BEAN_SEEDS;
            case "winged_bean" -> WINGED_BEAN_SEEDS;
            case "pigeon_pea" -> PIGEON_PEA_SEEDS;
            case "sunflower" -> SUNFLOWER_SEEDS;
            case "hemp" -> HEMP_SEEDS;
            case "sorghum" -> SORGHUM_SEEDS;
            case "sisal" -> SISAL_SEEDS;
            // 批次 12：莲座类 3 种
            case "cardoon" -> CARDOON_SEEDS;
            case "agave" -> AGAVE_SEEDS;
            case "purslane" -> PURSLANE_SEEDS;
            case "strawberry" -> STRAWBERRY_SEEDS;
            default -> throw new IllegalStateException("未知作物: " + name);
        };
    }

    /** 触发静态初始化 —— 主类必须调用一次 */
    public static void init() {}

    private MyCrops() {}
}
