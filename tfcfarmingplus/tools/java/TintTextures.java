import javax.imageio.ImageIO;
import java.awt.Color;
import java.awt.image.BufferedImage;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * 贴图变体生成器 —— 把「借用的 TFC 贴图」变成「我们自己的、一眼能与原版区分开的」贴图。
 *
 * <h2>为什么需要它</h2>
 * 本工程的美术是占位方案：模型<b>跨命名空间直接引用 TFC 的贴图</b>（见 docs/74 §14.15）。
 * 好处是零 PNG、立即可用；代价是<b>新内容与原版长得一模一样</b>，而且<b>同一个 donor 被多个物种共用</b>
 * （芜菁 / 防风 / 鸦葱 / 生姜 / 姜黄原本全都借 beet，五者外观完全一致）。
 *
 * <h2>第一版的教训（2025 本次会话）</h2>
 * 第一版只做「色相 ±20°、饱和度 0.85~1.15、明度 0.90~1.10」——
 * 幅度太小，玩家反馈「<b>修改覆盖不彻底且修改不明显</b>」：调色后和 TFC 原版几乎分不出来。
 * 本版据此重做，把差异从「需要并排比对」提升到「一眼可辨」。
 *
 * <h2>做法（每个物种一组确定性参数）</h2>
 * <ul>
 *   <li><b>色相</b> ±55°：绿色 120° 最多漂到 65°（黄绿）或 175°（青绿），仍是自然的植物色，
 *       但已经不是原来那株了；</li>
 *   <li><b>饱和度</b> 0.45 ~ 1.55：灰绿 / 艳绿两个极端；</li>
 *   <li><b>明度</b> 0.72 ~ 1.32：深墨绿 / 浅嫩绿；</li>
 *   <li><b>对比度</b> 0.80 ~ 1.28（围绕中灰缩放）：让明暗结构本身也不同；</li>
 *   <li><b>水平镜像</b>（约一半物种）：连<b>形状朝向</b>都不一样了 —— 这是最直观的一条，
 *       因为人眼对「叶子朝哪边长」远比对着色敏感。</li>
 * </ul>
 * 五条叠加之后，同一 donor 派生出的物种在色相、浓淡、明暗、结构、朝向上都被拉开。
 *
 * <p>参数全部来自 <code>seed</code>（物种名）的哈希 —— 所以<b>同名永远得到同一组参数</b>（可重复生成），
 * 而<b>不同物种之间必然不同</b>。同一物种的方块贴图 / 物品贴图 / 种子贴图共用同一个 seed，
 * 因此配色天然一致（生姜的作物、种子、食材看起来是同一株生姜）。
 * 透明像素原样保留（十字模型的镂空全靠 alpha）。
 *
 * <h2>哈希为什么要 mix</h2>
 * 直接用 <code>hashCode()</code> 的不同位段会相关（尤其是名字相近的物种，如 ginger / ginger_seeds），
 * 导致色相与饱和度同步漂移、差异被抵消。这里对每个维度用不同的 32 位混合常量做雪崩混合，
 * 让五个维度互相独立。
 *
 * <h2>用法</h2>
 * <pre>
 * java TintTextures.java &lt;TFC贴图根&gt; &lt;输出根&gt; &lt;任务清单.json&gt;
 * </pre>
 * 清单由生成器脚本导出，形如：
 * <pre>
 * {"jobs":[{"src":"crop/beet_0.png","dst":"crop/ginger_0.png","seed":"ginger"}, ...]}
 * </pre>
 * <b>用「逐文件对」而不是「物种 + 参考」</b>：作物贴图有 <code>_&lt;i&gt;</code>、<code>_&lt;i&gt;_stick</code>、
 * <code>_side</code>、<code>_wild</code>、<code>_dead</code> 等多种变体，双格/蔓延/攀爬/水田各有各的组合，
 * 让调用方直接列出「要哪个、生成成哪个」比在工具里复刻那套命名规则可靠得多 ——
 * 而且调用方本来就掌握全部信息（生成器表里的 ref 与形态）。
 */
public final class TintTextures {

    /** 一个「源贴图 → 目标贴图」的任务 */
    private record Job(String src, String dst, String seed) {}

    /**
     * 贴图类别 —— <b>不同类别能承受的变换幅度完全不同</b>。
     *
     * <p>这是本项目踩过的一个大坑：早期对所有贴图一律套 ±55° 色相，
     * 结果<b>树皮被染成深紫/深红/黄绿</b>（实测 jujube R=76 G=11 B=3、
     * papaya R=104 G=143 B=42、pear R=59 G=43 B=61），整棵树的树干颜色都不对。
     * 树皮是「木质色」，色相只能在棕/灰区间里微调；叶片与果实才允许较大变化。
     */
    private enum Kind {
        /** 树皮 / 树干 —— 必须保持木质色 */
        BARK,
        /** 叶片 / 莲座叶丛 —— 保持绿色系 */
        LEAF,
        /** 果实 —— 可以鲜艳一些 */
        FRUIT,
        /** 其它（作物、种子、树叶等） */
        OTHER;

        static Kind of(final String dst) {
            // ⚠️ 顺序有讲究：trunk_fruit 里也含 "trunk"，必须先判果实
            if (dst.contains("trunk_fruit")) return FRUIT;
            if (dst.contains("_branch") || dst.contains("trunk_")) return BARK;
            if (dst.contains("leaves") || dst.contains("rosette")) return LEAF;
            if (dst.contains("fruit") || dst.contains("food/")) return FRUIT;
            return OTHER;
        }
    }

    /**
     * 一项变换参数 —— 由 seed 与贴图类别共同决定。
     *
     * @param hue      色相偏移（度）
     * @param sat      饱和度倍率
     * @param val      明度倍率
     * @param contrast 对比度倍率（围绕中灰 128 缩放）
     * @param flip     是否水平镜像
     */
    private record Tune(double hue, double sat, double val, double contrast, boolean flip) {

        static Tune of(final String seed, final String dst) {
            final int h = seed.hashCode();
            return switch (Kind.of(dst)) {
                // ── 树皮：只在棕/灰区间微调，且**不镜像**（保留纹理方向，树皮有纵向纹） ──
                case BARK -> new Tune(
                    span(h, 0x9E3779B9, 21) - 10,          // ±10°
                    0.90 + span(h, 0x85EBCA6B, 21) / 100.0, // 0.90 ~ 1.10
                    0.92 + span(h, 0xC2B2AE35, 17) / 100.0, // 0.92 ~ 1.08
                    0.94 + span(h, 0x27D4EB2F, 13) / 100.0, // 0.94 ~ 1.06
                    false);
                // ── 叶片：保持绿色系，但允许明显的深浅/浓淡差异 ──
                case LEAF -> new Tune(
                    span(h, 0x9E3779B9, 61) - 30,           // ±30°
                    0.75 + span(h, 0x85EBCA6B, 51) / 100.0, // 0.75 ~ 1.25
                    0.88 + span(h, 0xC2B2AE35, 25) / 100.0, // 0.88 ~ 1.12
                    0.90 + span(h, 0x27D4EB2F, 21) / 100.0, // 0.90 ~ 1.10
                    span(h, 0x165667B1, 2) == 1);
                // ── 果实：可以鲜艳，色相范围最大 ──
                case FRUIT -> new Tune(
                    span(h, 0x9E3779B9, 81) - 40,           // ±40°
                    0.80 + span(h, 0x85EBCA6B, 61) / 100.0, // 0.80 ~ 1.40
                    0.86 + span(h, 0xC2B2AE35, 25) / 100.0, // 0.86 ~ 1.10
                    0.90 + span(h, 0x27D4EB2F, 21) / 100.0, // 0.90 ~ 1.10
                    span(h, 0x165667B1, 2) == 1);
                // ── 其它（作物、种子、树叶）：居中 ──
                default -> new Tune(
                    span(h, 0x9E3779B9, 51) - 25,           // ±25°
                    0.80 + span(h, 0x85EBCA6B, 41) / 100.0, // 0.80 ~ 1.20
                    0.90 + span(h, 0xC2B2AE35, 21) / 100.0, // 0.90 ~ 1.10
                    0.92 + span(h, 0x27D4EB2F, 17) / 100.0, // 0.92 ~ 1.08
                    span(h, 0x165667B1, 2) == 1);
            };
        }

        /** 取 [0, n) 区间的稳定值 */
        private static int span(final int h, final int k, final int n) {
            return Math.floorMod(mix(h, k), n);
        }

        /** 雪崩混合：让不同维度之间不相关（直接取 hashCode 的不同位段会相关） */
        private static int mix(final int x, final int k) {
            int v = x ^ k;
            v *= 0x85EBCA6B;
            v ^= v >>> 13;
            v *= 0xC2B2AE35;
            v ^= v >>> 16;
            return v;
        }
    }

    public static void main(final String[] args) throws IOException {
        if (args.length < 3) {
            System.err.println("用法: TintTextures <TFC贴图根> <输出根> <任务清单.json>");
            System.exit(2);
        }
        final Path srcRoot = Paths.get(args[0]);
        final Path outRoot = Paths.get(args[1]);
        final String json = Files.readString(Paths.get(args[2]), StandardCharsets.UTF_8);

        final List<Job> jobs = parse(json);
        int made = 0;
        final List<String> missing = new ArrayList<>();
        double deltaMin = Double.MAX_VALUE, deltaMax = 0, deltaSum = 0;
        int flipped = 0;

        // 同源分组 —— 用于事后校验「同一 donor 派生出的物种是否真的被拉开了」
        final Map<String, List<Job>> bySrc = new LinkedHashMap<>();

        for (final Job job : jobs) {
            final Path in = srcRoot.resolve(job.src());
            final Path out = outRoot.resolve(job.dst());
            final Tune tune = Tune.of(job.seed(), job.dst());
            final double delta = convert(in, out, tune);
            if (delta < 0) {
                missing.add(job.src());
                continue;
            }
            made++;
            if (tune.flip()) {
                flipped++;
            }
            deltaMin = Math.min(deltaMin, delta);
            deltaMax = Math.max(deltaMax, delta);
            deltaSum += delta;
            bySrc.computeIfAbsent(job.src(), k -> new ArrayList<>()).add(job);
        }

        System.out.println("  [贴图变体] 生成 " + made + " 个 PNG"
            + (missing.isEmpty() ? "（无缺源）" : "；缺源 " + missing.size() + " 个"));
        if (!missing.isEmpty()) {
            missing.stream().distinct().limit(8).forEach(m -> System.out.println("    缺源: " + m));
        }
        if (made > 0) {
            System.out.printf("  与原版平均色差 ΔRGB：最小 %.1f / 平均 %.1f / 最大 %.1f（镜像 %d 个，占 %.0f%%）%n",
                deltaMin, deltaSum / made, deltaMax, flipped, 100.0 * flipped / made);
            reportSpread(bySrc);
        }
    }

    /**
     * 校验「同一个 donor 派生出的多个物种」是否被足够拉开。
     *
     * <p>这是第一版翻车的直接原因：五个物种共用一个 beet，参数又都在窄区间内，
     * 结果五者肉眼无法区分。这里把「色相极差 / 饱和度极差 / 明度极差」当作硬指标报出来 ——
     * 只要有任一维度足够宽，人眼就能分辨。三者都窄才告警。
     */
    private static void reportSpread(final Map<String, List<Job>> bySrc) {
        int worstGroups = 0, multiGroups = 0;
        double worstSpan = Double.MAX_VALUE;
        String worstName = null;

        for (final Map.Entry<String, List<Job>> e : bySrc.entrySet()) {
            final List<Job> group = e.getValue();
            if (group.size() < 2) {
                continue;
            }
            multiGroups++;
            double hueLo = 999, hueHi = -999, satLo = 9, satHi = -9, valLo = 9, valHi = -9;
            for (final Job j : group) {
                final Tune t = Tune.of(j.seed(), j.dst());
                hueLo = Math.min(hueLo, t.hue());
                hueHi = Math.max(hueHi, t.hue());
                satLo = Math.min(satLo, t.sat());
                satHi = Math.max(satHi, t.sat());
                valLo = Math.min(valLo, t.val());
                valHi = Math.max(valHi, t.val());
            }
            final double hueSpan = hueHi - hueLo, satSpan = satHi - satLo, valSpan = valHi - valLo;
            // 「可分辨」的判据：色相拉开 ≥20°，或饱和度拉开 ≥0.20，或明度拉开 ≥0.15
            final boolean ok = hueSpan >= 20 || satSpan >= 0.20 || valSpan >= 0.15;
            if (!ok) {
                worstGroups++;
                if (hueSpan < worstSpan) {
                    worstSpan = hueSpan;
                    worstName = e.getKey() + "（" + group.size() + " 个物种:" + group.get(0).seed() + "…）";
                }
            }
        }

        if (multiGroups == 0) {
            return;
        }
        if (worstGroups == 0) {
            System.out.println("  共用同一 donor 的 " + multiGroups
                + " 组物种：全部已拉开到可肉眼分辨（色相 ≥20° 或 饱和度 ≥0.20 或 明度 ≥0.15）");
        } else {
            System.out.println("  ⚠ 共用同一 donor 的 " + multiGroups + " 组中，有 " + worstGroups
                + " 组差异偏小，最差：" + worstName + "（色相极差仅 " + String.format("%.0f", worstSpan) + "°）");
        }
    }

    /** 极简解析：清单是本工具自己约定的扁平结构，不值得引入 JSON 库 */
    private static List<Job> parse(final String json) {
        final List<Job> out = new ArrayList<>();
        final Matcher m = Pattern.compile(
            "\"src\"\\s*:\\s*\"([^\"]+)\"\\s*,\\s*\"dst\"\\s*:\\s*\"([^\"]+)\"\\s*,\\s*\"seed\"\\s*:\\s*\"([^\"]+)\"")
            .matcher(json);
        while (m.find()) {
            out.add(new Job(m.group(1), m.group(2), m.group(3)));
        }
        return out;
    }

    /**
     * 读一张 PNG、施加确定性变换、写到目标位置。
     *
     * @return 源图与结果图之间「不透明像素的平均 RGB 欧氏距离」；源文件不存在或读不出时返回 -1
     */
    private static double convert(final Path in, final Path dst, final Tune tune) throws IOException {
        if (!Files.exists(in)) {
            return -1;
        }
        final BufferedImage img = ImageIO.read(in.toFile());
        if (img == null) {
            return -1;
        }

        final int w = img.getWidth(), hgt = img.getHeight();
        final BufferedImage out = new BufferedImage(w, hgt, BufferedImage.TYPE_INT_ARGB);
        double diffSum = 0;
        long diffCount = 0;

        for (int y = 0; y < hgt; y++) {
            for (int x = 0; x < w; x++) {
                final int argb = img.getRGB(x, y);
                final int a = (argb >>> 24);
                if (a == 0) {
                    out.setRGB(x, y, 0);          // 透明像素原样保留 —— 十字模型的镂空全靠它
                    continue;
                }
                final int r = (argb >> 16) & 0xFF, g = (argb >> 8) & 0xFF, b = argb & 0xFF;

                final float[] hsv = Color.RGBtoHSB(r, g, b, null);
                hsv[0] = (float) Math.floorMod((long) (hsv[0] * 360 + tune.hue()), 360L) / 360f;
                hsv[1] = (float) Math.min(1.0, hsv[1] * tune.sat());
                hsv[2] = (float) Math.min(1.0, hsv[2] * tune.val());
                int rgb = Color.HSBtoRGB(hsv[0], hsv[1], hsv[2]) & 0xFFFFFF;

                // 对比度：围绕中灰缩放（放在 HSV 之后，避免与明度倍率互相抵消）
                int nr = clamp((int) Math.round(128 + (((rgb >> 16) & 0xFF) - 128) * tune.contrast()));
                int ng = clamp((int) Math.round(128 + (((rgb >> 8) & 0xFF) - 128) * tune.contrast()));
                int nb = clamp((int) Math.round(128 + ((rgb & 0xFF) - 128) * tune.contrast()));
                rgb = (nr << 16) | (ng << 8) | nb;

                out.setRGB(tune.flip() ? (w - 1 - x) : x, y, (a << 24) | rgb);

                final int dr = nr - r, dg = ng - g, db = nb - b;
                diffSum += Math.sqrt((double) dr * dr + (double) dg * dg + (double) db * db);
                diffCount++;
            }
        }

        Files.createDirectories(dst.getParent());
        ImageIO.write(out, "PNG", dst.toFile());
        return diffCount == 0 ? 0 : diffSum / diffCount;
    }

    private static int clamp(final int v) {
        return v < 0 ? 0 : Math.min(v, 255);
    }

    private TintTextures() {}
}
