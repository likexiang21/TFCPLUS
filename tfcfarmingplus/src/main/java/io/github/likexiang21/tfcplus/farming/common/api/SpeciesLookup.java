package io.github.likexiang21.tfcplus.farming.common.api;

import io.github.likexiang21.tfcplus.farming.TFCFarmingPlus;
import io.github.likexiang21.tfcplus.farming.common.registry.FarmingBlocks;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.TreeMap;
import java.util.TreeSet;
import net.dries007.tfc.util.climate.ClimateRange;
import net.dries007.tfc.util.data.DataManager;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.world.level.block.Block;
import net.neoforged.neoforge.registries.DeferredHolder;

/**
 * 【可选的稳定只读查询 API】——供外部附属模组查询 A 的物种/代表方块。
 *
 * <p>当前 {@code tfcagricultureplus} 不对本类做 Java import；B 的运行时依赖由
 * {@code mods.toml} 声明。本类保留为公共 API，不代表 B 已经接入。
 *
 * <h2>🛑 契约（改动前必须读）</h2>
 *
 * <p>契约（改动前必须读）：
 * <ol>
 *   <li>🛑 <b>只增不改</b>：新增方法可以，<b>改签名 / 删方法会让外部调用方编译失败</b></li>
 *   <li>🛑 <b>只读</b>：不做任何注册、不持有可变状态、不参与 tick</li>
 *   <li>🛑 <b>A 单独运行时存在感为零</b>：不改变任何现有行为</li>
 * </ol>
 *
 * <p>⚠️ 实现上刻意采用<b>惰性初始化</b>：{@code FarmingBlocks.BLOCKS.getEntries()} 在
 * <b>类初始化期</b>还不完整（注册表尚未绑定），因此所有缓存都在<b>首次调用</b>时才构建，
 * 且构建后<b>不再变化</b>（返回不可变集合）。
 */
public final class SpeciesLookup {

    /** 物种名 → 它的代表方块 ID。惰性构建，不可变。 */
    private static volatile Map<String, ResourceLocation> speciesBlocks = null;

    /** 全部物种名（排序后）。惰性构建，不可变。 */
    private static volatile List<String> speciesNames = null;

    // ------------------------------------------------------------------
    // 公开 API
    // ------------------------------------------------------------------

    /**
     * 全部物种名（87 作物 + 49 树类 + 12 灌木），按字典序。
     *
     * <p>口径：从**已注册的方块 ID** 反推，只取 {@code crop/<name>}、
     * {@code plant/<name>_tree_sapling} 和 {@code plant/<name>_bush} 三类代表方块。
     * 枝干、树叶、藤蔓、枯死和野生派生方块不单独计数。
     *
     * @return <b>不可变</b>列表；若注册表尚未就绪则返回空列表（不抛异常，方便 B 的早期调用）
     */
    public static List<String> species() {
        ensureBuilt();
        return speciesNames;
    }

    /**
     * 某个物种的方块 ID；不存在时返回空。
     *
     * @param species 物种名（如 {@code wheat} · {@code lingonberry}）
     */
    public static Optional<ResourceLocation> blockOf(String species) {
        ensureBuilt();
        return Optional.ofNullable(speciesBlocks.get(species));
    }

    /**
     * 某个物种的气候区间。
     *
     * <p>实现：作物和灌木的代表路径可直接作为气候 ID；果树代表方块的
     * {@code _tree_sapling} 后缀会转换为 TFC 使用的 {@code _tree} 气候 ID。
     * （数据管理器规则：{@code data/<ns>/tfc/climate_range/<path>.json}。）
     *
     * <p>⚠️ 返回值是 {@link DataManager.Reference}（**惰性绑定**），
     * 调用方需要 {@code .get()} 才拿到实例；**数据包未加载时可能为 null**。
     *
     * @param species 物种名
     * @return 气候引用；物种不存在时返回空
     */
    public static Optional<DataManager.Reference<ClimateRange>> climateOf(String species) {
        return blockOf(species).map(id -> {
            String path = id.getPath();
            if (path.endsWith("_tree_sapling")) {
                path = path.substring(0, path.length() - "_sapling".length());
            }
            return ClimateRange.MANAGER.getReference(
                ResourceLocation.fromNamespaceAndPath(TFCFarmingPlus.MOD_ID, path));
        });
    }

    /**
     * 这个名字是不是 A 的物种。
     *
     * @param name 物种名（**不带命名空间**）
     */
    public static boolean isOurSpecies(String name) {
        ensureBuilt();
        return name != null && speciesBlocks.containsKey(name);
    }

    /**
     * 物种总数 —— 与 {@link #species()}{@code .size()} 等价，供快速自检。
     */
    public static int speciesCount() {
        ensureBuilt();
        return speciesNames.size();
    }

    // ------------------------------------------------------------------
    // 惰性构建（只在第一次调用时执行一次）
    // ------------------------------------------------------------------

    private static void ensureBuilt() {
        if (speciesNames != null) {
            return;
        }
        synchronized (SpeciesLookup.class) {
            if (speciesNames != null) {
                return;
            }

            final Map<String, ResourceLocation> blocks = new TreeMap<>();
            // ⚠️ 用 Set 去重：同一物种可能同时有 crop/x 与 wild_crop/x
            final var names = new TreeSet<String>();

            for (final DeferredHolder<Block, ? extends Block> holder : FarmingBlocks.BLOCKS.getEntries()) {
                final ResourceLocation id = holder.getId();
                if (!TFCFarmingPlus.MOD_ID.equals(id.getNamespace())) {
                    continue;
                }
                final String path = id.getPath();

                // 只取三个代表形态；wild/dead、果树枝叶藤蔓都不是独立物种。
                final String name;
                if (path.startsWith("crop/")) {
                    name = path.substring("crop/".length());
                } else if (path.startsWith("plant/") && path.endsWith("_tree_sapling")) {
                    name = path.substring("plant/".length(), path.length() - "_tree_sapling".length());
                } else if (path.startsWith("plant/") && path.endsWith("_bush")) {
                    name = path.substring("plant/".length(), path.length() - "_bush".length());
                } else {
                    continue;
                }

                names.add(name);
                // 优先记录 crop/；其余代表形态只在没有更直接的代表时记录。
                blocks.putIfAbsent(name, id);
            }

            speciesBlocks = Collections.unmodifiableMap(blocks);
            speciesNames = Collections.unmodifiableList(new ArrayList<>(names));
        }
    }

    /** 供 A 的调试命令使用：打印物种数量（ASCII-only，避免 GBK 控制台乱码）。 */
    public static String describe() {
        return "SpeciesLookup: species=" + speciesCount();
    }

    private SpeciesLookup() {}
}
