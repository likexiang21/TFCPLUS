package com.example.tfcfarmingplus.common;

import net.dries007.tfc.common.blocks.plant.fruit.Lifecycle;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 「枝干结果」的 7 个物种 —— 果实的<b>物候表</b>与物种名单。
 *
 * <p>果实本身不再是方块：它是 {@link com.example.tfcfarmingplus.common.blocks.MyFruitingBranchBlock}
 * 的 {@code fruit} 属性（见该类注释）。本类只提供两样东西：
 * <ol>
 *   <li>{@link #SPECIES} —— 哪些树用「会结果的枝干」注册（其余果树保持 TFC 的普通枝干）；</li>
 *   <li>{@link #LIFECYCLES} —— 每个物种的 12 月物候表（<b>必须含 FRUITING</b>，否则永远结不出果）。</li>
 * </ol>
 *
 * <p>⚠️ 树叶那一份物候（{@code MyFruitTrees.TREES} 的 {@code lifecycle}）**刻意不含 FRUITING**：
 * 叶只开花，果在干上。两份表是独立的，不要合并。
 *
 * <p>这 7 个物种原产热带/亚热带，DORMANT 月份少、结果期长，贴合「老茎结果植物一年多熟」。
 */
public final class MyBranchFruits {

    /** 会结果的树种（必须与 {@link MyFruitTrees#TREES} 中的名字一致） */
    public static final List<String> SPECIES = List.of(
        "jabuticaba",   // 嘉宝果（树葡萄）—— 果实密密麻麻贴满主干
        "soursop",      // 刺果番荔枝 —— 果实垂挂在主干与粗枝上
        "mangosteen",   // 山竹 —— 果实贴着粗枝生长
        "cupuacu",      // 大花可可 —— 可可的近亲，同样老茎结果
        "bael",         // 木橘 —— 果实成串挂在枝干上
        "canistel",     // 蛋黄果 —— 果实密生于枝干
        "black_pepper"  // 黑胡椒 —— 藤本，果穗成串垂挂（叶只开花，果在干上）
    );

    /** 12 月物候表（长度必须正好 12） */
    private static final Map<String, Lifecycle[]> LIFECYCLES = Map.of(
        "jabuticaba", new Lifecycle[]{
            Lifecycle.DORMANT, Lifecycle.HEALTHY, Lifecycle.FLOWERING, Lifecycle.FLOWERING,
            Lifecycle.HEALTHY, Lifecycle.HEALTHY, Lifecycle.FRUITING, Lifecycle.FRUITING,
            Lifecycle.HEALTHY, Lifecycle.FLOWERING, Lifecycle.FLOWERING, Lifecycle.DORMANT },
        "soursop", new Lifecycle[]{
            Lifecycle.HEALTHY, Lifecycle.FLOWERING, Lifecycle.FLOWERING, Lifecycle.FRUITING,
            Lifecycle.FRUITING, Lifecycle.FRUITING, Lifecycle.HEALTHY, Lifecycle.HEALTHY,
            Lifecycle.FLOWERING, Lifecycle.FLOWERING, Lifecycle.FRUITING, Lifecycle.FRUITING },
        "mangosteen", new Lifecycle[]{
            Lifecycle.HEALTHY, Lifecycle.HEALTHY, Lifecycle.FLOWERING, Lifecycle.FLOWERING,
            Lifecycle.FRUITING, Lifecycle.FRUITING, Lifecycle.HEALTHY, Lifecycle.HEALTHY,
            Lifecycle.HEALTHY, Lifecycle.FLOWERING, Lifecycle.FRUITING, Lifecycle.FRUITING },
        "cupuacu", new Lifecycle[]{
            Lifecycle.HEALTHY, Lifecycle.HEALTHY, Lifecycle.FLOWERING, Lifecycle.FLOWERING,
            Lifecycle.FRUITING, Lifecycle.FRUITING, Lifecycle.FRUITING, Lifecycle.HEALTHY,
            Lifecycle.HEALTHY, Lifecycle.FLOWERING, Lifecycle.FLOWERING, Lifecycle.FRUITING },
        "bael", new Lifecycle[]{
            Lifecycle.DORMANT, Lifecycle.HEALTHY, Lifecycle.HEALTHY, Lifecycle.FLOWERING,
            Lifecycle.FLOWERING, Lifecycle.HEALTHY, Lifecycle.FRUITING, Lifecycle.FRUITING,
            Lifecycle.HEALTHY, Lifecycle.HEALTHY, Lifecycle.FLOWERING, Lifecycle.DORMANT },
        "canistel", new Lifecycle[]{
            Lifecycle.HEALTHY, Lifecycle.HEALTHY, Lifecycle.FLOWERING, Lifecycle.FLOWERING,
            Lifecycle.HEALTHY, Lifecycle.FRUITING, Lifecycle.FRUITING, Lifecycle.FRUITING,
            Lifecycle.HEALTHY, Lifecycle.FLOWERING, Lifecycle.FLOWERING, Lifecycle.HEALTHY },
        "black_pepper", new Lifecycle[]{
            Lifecycle.HEALTHY, Lifecycle.FLOWERING, Lifecycle.FLOWERING, Lifecycle.FRUITING,
            Lifecycle.FRUITING, Lifecycle.FRUITING, Lifecycle.FRUITING, Lifecycle.HEALTHY,
            Lifecycle.FLOWERING, Lifecycle.FLOWERING, Lifecycle.FRUITING, Lifecycle.FRUITING }
    );

    /** 该物种是否用「会结果的枝干」 */
    public static boolean isBranchFruit(final String name) {
        return SPECIES.contains(name);
    }

    /** 该物种的 12 月物候表（未登记则抛异常，避免静默用了错表） */
    public static Lifecycle[] lifecycle(final String name) {
        final Lifecycle[] table = LIFECYCLES.get(name);
        if (table == null || table.length != 12) {
            throw new IllegalStateException("枝干结果物种 " + name + " 缺少 12 月物候表");
        }
        return table;
    }

    /** 触发静态初始化 */
    public static void init() {}

    private MyBranchFruits() {}
}
