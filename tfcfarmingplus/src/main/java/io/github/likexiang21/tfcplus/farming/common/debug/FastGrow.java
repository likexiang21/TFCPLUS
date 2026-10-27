package io.github.likexiang21.tfcplus.farming.common.debug;

/**
 * 生长加速开关 —— <b>仅供快速检查用</b>，默认关闭。
 *
 * <h2>用途</h2>
 * TFC 的作物/果树按真实历法生长（一个作物周期约 24 游戏日），
 * 直接进游戏检查外观要等很久。打开本开关后：
 * <ul>
 *   <li>莲座作物：每次生长 tick 把进度放大 {@link #CROP_MULTIPLIER} 倍（受 {@code min(1.0)} 保护，约 3 次即成熟）；</li>
 *   <li>树干果实：{@code randomTick} 必定推进一个阶段（原本 1/5 概率）；</li>
 *   <li>果树枝条：每次 {@code randomTick} 额外推进计时器 {@link #BRANCH_TICKS}。</li>
 * </ul>
 *
 * <h2>怎么开、怎么还原</h2>
 * 由 JVM 属性 {@code -Dtfcfarmingplus.fastgrow=true} 打开 ——
 * <b>{@code tools/launch-client.ps1} 已默认带上</b>（它本就是无人值守检查用的）。
 * <b>检查完把启动脚本里那一行删掉即可完全还原</b>，不需要改任何生长逻辑常量、
 * 也不会影响正式包（{@code -D} 只在该次启动生效）。
 *
 * <p>刻意**不去改 TFC 的 {@code GROWTH_FACTOR}**：那需要反射或改上游，
 * 而且会污染「生长速率本身是否正确」的判断。本开关只做「多推几次」。
 */
public final class FastGrow {

    /** 是否开启加速 */
    public static final boolean ENABLED = Boolean.getBoolean("tfcfarmingplus.fastgrow");

    /** 莲座作物每次生长 tick 的进度倍率 */
    /** 莲座作物每次生长 tick 的进度倍率（TFC 一个周期约 576000 tick，×2000 后约 15 秒成熟） */
    public static final float CROP_MULTIPLIER = 2000.0f;

    /** 果树枝条每次 randomTick 额外推进的 tick 数（TFC 自然生长约需数百万 tick） */
    public static final long BRANCH_TICKS = 2000000L;

    private FastGrow() {}
}
