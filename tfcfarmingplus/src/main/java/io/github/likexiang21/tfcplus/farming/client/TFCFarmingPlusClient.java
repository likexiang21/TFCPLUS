package io.github.likexiang21.tfcplus.farming.client;

import io.github.likexiang21.tfcplus.farming.TFCFarmingPlus;
import io.github.likexiang21.tfcplus.farming.common.crop.FarmingBushes;
import io.github.likexiang21.tfcplus.farming.common.crop.FarmingCrops;
import io.github.likexiang21.tfcplus.farming.common.crop.FarmingWildCrops;
import io.github.likexiang21.tfcplus.farming.common.registry.FarmingBlocks;
import io.github.likexiang21.tfcplus.farming.common.tree.FarmingFruitTrees;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Stream;
import net.dries007.tfc.client.TFCColors;
import net.minecraft.client.color.block.BlockColor;
import net.minecraft.client.color.item.ItemColor;
import net.minecraft.client.renderer.ItemBlockRenderTypes;
import net.minecraft.client.renderer.RenderType;
import net.minecraft.world.level.block.Block;
import net.neoforged.bus.api.IEventBus;
import net.neoforged.fml.event.lifecycle.FMLClientSetupEvent;
import net.neoforged.fml.loading.FMLEnvironment;
import net.neoforged.neoforge.client.event.RegisterColorHandlersEvent;
import net.neoforged.neoforge.registries.DeferredHolder;

/**
 * 客户端注册 —— 参考 TFC 的 {@code net.dries007.tfc.client.ClientEventHandler} 公开行为；本项目独立实现。
 * <p>
 * <b>为什么附属模组的植物必须做这两件事：</b>
 * <ol>
 *   <li><b>渲染层</b>：植物贴图都是带透明像素的十字/交叉模型。不注册 cutout，就会走默认的
 *       solid 渲染，透明区被当作不透明，画面里出现黑块或白块。
 *       TFC 对 {@code CROPS / DEAD_CROPS / WILD_CROPS} 用 {@code cutout}，
 *       对 {@code STATIONARY_BUSHES} 用 {@code cutoutMipped}（浆果丛贴图带半透明边缘）。</li>
 *   <li><b>草色着色</b>：TFC 的野生作物模型 {@code tfc:block/wild_crop/crop} 里，
 *       十字草丛那一层贴图带 {@code tintindex: 0}，需要由
 *       {@link TFCColors#getGrassColor} 提供生物群系草色。不注册的话草丛会是灰白色。</li>
 * </ol>
 * 直接复用 TFC 的 {@link TFCColors}，保证与 TFC 原版作物在同一个生物群系里颜色完全一致。
 * <p>
 * ⚠️ 本类**不是** {@code @Mod} 入口：一个 mod 在同一加载端只能有一个 {@code @Mod} 类，
 * 再加一个 {@code @Mod(dist = Dist.CLIENT)} 会与主类撞同一个 modId（FML 会判定入口冲突）。
 * 正确做法是主类在确认 {@code FMLEnvironment.dist.isClient()} 后调用 {@link #register(IEventBus)}——
 * 服务端永远不会执行到那一行，因此本类（引用了 {@code net.minecraft.client.*}）不会被加载。
 * <p>
 * <b>方块清单已全部自动化（不再有手写常量）</b>：
 * <ul>
 *   <li>作物 → {@link FarmingCrops#cropBlocks()}；</li>
 *   <li>野生作物 → {@link FarmingWildCrops#wildBlocks()}（工厂自动收集）；</li>
 *   <li>浆果灌木 → {@link FarmingBushes#bushBlocks()}；</li>
 *   <li>作物死株 → {@link #deadCropBlocks()}（按 {@code dead_crop/} 前缀自动收集）；</li>
 *   <li>果树树苗 / 树叶 → {@link FarmingFruitTrees#SAPLINGS} / {@link FarmingFruitTrees#LEAVES}。</li>
 * </ul>
 * ⚠️ 这段自动化是**被批次 12 的教训逼出来的**：当时 3 个莲座作物加进了
 * {@code FarmingCrops.cropBlocks()}，但这里仍是手写常量，结果实机自检报
 * 「6 个方块没有登记渲染层」（3 作物 + 3 野生），会被渲染成黑块。
 * 教训：**「能注册」不等于「能被正确渲染」**，清单必须有唯一权威来源。
 * <p>
 * 仍保留 {@link #auditRenderLayers()} 作为兜底护栏 —— 万一将来又有新的方块类别没接进清单，
 * 开发期启动日志会直接点名。
 */
public final class TFCFarmingPlusClient {

    /** 草色（方块）——tintIndex 不为 0 时 TFC 会返回 -1（不染色） */
    private static final BlockColor GRASS_COLOR =
        (state, level, pos, tintIndex) -> TFCColors.getGrassColor(pos, tintIndex);

    /** 草色（物品栏里的野生作物） */
    private static final ItemColor GRASS_ITEM_COLOR =
        (stack, tintIndex) -> TFCColors.getGrassColor(null, tintIndex);

    /** 仅由主类在客户端调用一次 */
    public static void register(IEventBus bus) {
        bus.addListener(TFCFarmingPlusClient::onClientSetup);
        bus.addListener(TFCFarmingPlusClient::registerBlockColors);
        bus.addListener(TFCFarmingPlusClient::registerItemColors);

    }

    @SuppressWarnings("deprecation") // 与 TFC 4.2.10 一致：NeoForge 仍支持该 API
    private static void onClientSetup(FMLClientSetupEvent event) {
        event.enqueueWork(() -> {
            for (Block block : cutoutBlocks()) {
                ItemBlockRenderTypes.setRenderLayer(block, RenderType.cutout());
            }
            for (Block block : cutoutMippedBlocks()) {
                ItemBlockRenderTypes.setRenderLayer(block, RenderType.cutoutMipped());
            }
            // 开发期自检：把「没登记渲染层」的方块直接报到日志里。
            // 用与 /tfcfarmingplus 调试命令同一个开关 —— 注意本工程平时是用
            // launch-client.ps1 启动**正式客户端**的（production == true），
            // 只判断 production 的话这段永远不会执行，自检就形同虚设。
            if (!FMLEnvironment.production || Boolean.getBoolean("tfcfarmingplus.debug")) {
                auditRenderLayers();
            }
        });
    }

    private static void registerBlockColors(RegisterColorHandlersEvent.Block event) {
        event.register(GRASS_COLOR, wildCrops());
    }

    private static void registerItemColors(RegisterColorHandlersEvent.Item event) {
        event.register(GRASS_ITEM_COLOR, wildCrops());
    }

    // ---------------- 方块清单（全部由单一权威来源派生，无手写常量） ----------------

    /** 作物、野生作物、死株、果树树苗 —— 十字模型，用 cutout */
    private static Block[] cutoutBlocks() {
        final Stream.Builder<Block> blockStream = Stream.builder();
        // 枯萎 / 枯死状态。作物死株**不在这里手写** —— 见 deadCropBlocks()：
        // 按注册名前缀 dead_crop/ 自动收集，新增作物自动覆盖（§6.3）。
        blockStream.add(FarmingBlocks.DEAD_ROSETTE.get());
        blockStream.add(FarmingBlocks.DEAD_BERRY_BUSH.get());
        blockStream.add(FarmingBlocks.DEAD_CANE.get());
        // 全部作物。cropBlocks() 同时也是 FarmingBlockEntities 的 validBlocks 来源 ——
        // 新增作物时那边漏了会被原版校验当场拦下，所以它必然是最新且完整的。
        for (final Block block : FarmingCrops.cropBlocks()) {
            blockStream.add(block);
        }
        // 全部野生作物 —— FarmingWildCrops 的工厂自动收集，新增时零维护。
        for (final Block block : FarmingWildCrops.wildBlocks()) {
            blockStream.add(block);
        }
        // 全部作物死株 —— 按前缀自动收集。
        for (final Block block : deadCropBlocks()) {
            blockStream.add(block);
        }
        // 果树树苗。
        for (final DeferredHolder<Block, ?> holder : FarmingFruitTrees.SAPLINGS.values()) {
            blockStream.add(holder.get());
        }
        return blockStream.build().toArray(Block[]::new);
    }

    /**
     * 浆果灌木 + 果树树叶 —— 与 TFC 的 STATIONARY_BUSHES / SPREADING_BUSHES 一致，用 cutoutMipped。
     * <p>
     * ⚠️ 树叶必须**显式**登记：原版 {@code ItemBlockRenderTypes} 只对
     * {@code block instanceof LeavesBlock} 自动返回 cutoutMipped，而我们的（与 TFC 的）
     * {@code FruitTreeLeavesBlock} 继承链是 BushBlock → SeasonalPlantBlock，**不是** LeavesBlock，
     * 拿不到那份自动处理，漏登记就会渲染成黑块。
     */
    private static Block[] cutoutMippedBlocks() {
        final Stream.Builder<Block> blockStream = Stream.builder();
        // 全部浆果灌木（矮丛 + 蔓生主丛 + 蔓生藤蔓）
        for (final Block block : FarmingBushes.bushBlocks()) {
            blockStream.add(block);
        }
        // 果树树叶（33 种）
        for (final DeferredHolder<Block, ?> holder : FarmingFruitTrees.LEAVES.values()) {
            blockStream.add(holder.get());
        }
        return blockStream.build().toArray(Block[]::new);
    }

    /**
     * 作物死株 —— 按注册名前缀 {@code dead_crop/} **自动收集**。
     * <p>
     * 这是 §6.3 那笔技术债的第一个偿还点：原来这里是一长串手写常量，而批次 5/6/7
     * （水田 10 种、瓜类 3 种、攀爬 7 种）的 20 个死株**全被漏掉了** ——
     * 是开发期自检（{@link #auditRenderLayers()}）把它们抓出来的。
     * 死株模型是十字形、带透明像素，漏登记就会渲染成**黑块**。
     * <p>
     * 前缀自动收集之后，新增作物的死株无需再改这里。
     * <p>
     * ⚠️ 莲座作物（批次 12）**没有** per-crop 死株，它们用共享的 {@code dead_rosette}
     * 且不生成 {@code dead_crop/<n>} —— 所以它们不会出现在这里，这是正确的。
     */
    private static Block[] deadCropBlocks() {
        return FarmingBlocks.BLOCKS.getEntries().stream()
            .filter(h -> h.getId().getPath().startsWith("dead_crop/"))
            .map(DeferredHolder::get)
            .toArray(Block[]::new);
    }

    /**
     * 需要草色着色的方块 —— 全部野生作物（跨株整体染色）。
     * <p>
     * 取自 {@link FarmingWildCrops#wildBlocks()}（工厂**自动收集**），新增野生作物无需改这里。
     * <p>
     * ⚠️ 漏登记**不会报错**：只是草丛不随生物群系着色、显示为固定灰白，属静默错误。
     * 批次 12 之前这里也是手写常量，3 个野生莲座就是这么漏掉的。
     */
    private static Block[] wildCrops() {
        return FarmingWildCrops.wildBlocks();
    }

    // ---------------- 开发期自检 ----------------

    /**
     * 本就不需要登记渲染层的方块 —— 它们都是**完整立体模型**，没有透明像素。
     * <ul>
     *   <li>瓜类的整瓜与腐烂瓜：完整方块、六面贴图；</li>
     *   <li>果树枝干（{@code plant/*_branch}、{@code *_growing_branch}）：无方块物品、立体树干模型；
     *       它随树种增长（现在 33 种 × 2 = 66 个），所以用后缀判断而不是逐个列名。</li>
     * </ul>
     */
    private static final Set<String> NO_LAYER_NEEDED = Set.of(
        "cantaloupe", "winter_melon", "bottle_gourd",
        "rotten_cantaloupe", "rotten_winter_melon", "rotten_bottle_gourd");

    private static boolean noLayerNeeded(String path) {
        return NO_LAYER_NEEDED.contains(path)
            || path.endsWith("_branch") || path.endsWith("_growing_branch");
    }

    /**
     * 开发期自检 —— 逐个对照「已注册方块」与「渲染层清单」，把漏掉的报出来。
     *
     * <h2>为什么清单自动化之后还要保留自检</h2>
     * 清单现在是自动派生的（见类头说明），但自动化只覆盖**已知的方块类别**：
     * 将来若新增一类方块（比如新的作物形状、新的灌木族）而没有接进
     * {@link #cutoutBlocks()} / {@link #cutoutMippedBlocks()}，签名不会变、编译不会报错。
     * 自检是**唯一**能发现这种情况的护栏 —— 它不依赖任何人记得去改清单。
     *
     * <p>这个坑在本项目发作过三次（哈密瓜、果树树苗、批次 12 的 6 个莲座方块），
     * 而渲染问题在日志里没有任何痕迹。有了这条护栏就不必再靠运气。
     */
    private static void auditRenderLayers() {
        final Set<Block> covered = new HashSet<>();
        Collections.addAll(covered, cutoutBlocks());
        Collections.addAll(covered, cutoutMippedBlocks());

        final List<String> missing = new ArrayList<>();
        int total = 0;
        for (final DeferredHolder<Block, ?> holder : FarmingBlocks.BLOCKS.getEntries()) {
            total++;
            final String path = holder.getId().getPath();
            if (noLayerNeeded(path) || covered.contains(holder.get())) {
                continue;
            }
            missing.add(path);
        }
        if (missing.isEmpty()) {
            TFCFarmingPlus.LOGGER.info("[渲染层自检] 已注册方块 {} 个，全部有归属（cutout {} / cutoutMipped {} / 无需登记 {}）",
                total, cutoutBlocks().length, cutoutMippedBlocks().length, total - covered.size());
        } else {
            TFCFarmingPlus.LOGGER.warn("[渲染层自检] 有 {} 个方块没有登记渲染层；若它们的模型带透明像素就会渲染成黑块，"
                + "请把它们接入 cutoutBlocks() 或 cutoutMippedBlocks() 的权威来源：{}", missing.size(), missing);
        }
    }

    private TFCFarmingPlusClient() {}
}
