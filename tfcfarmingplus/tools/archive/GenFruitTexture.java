import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * 果实方块纹理生成器 —— 画一个**带球面光照的果实**（16×16）。
 *
 * <h2>为什么需要它</h2>
 * 树干果实的方块贴图一度是**直接拿 {@code tfc:item/food/cherry.png}**（物品图标：
 * 两颗樱桃加梗）来用 —— 那是给物品栏画的小图标，贴到方块六个面上就成了
 * 「方块表面反复出现两颗樱桃」，明显不对（用户指出的贴图问题之一）。
 *
 * <p>而 TFC 的 {@code block/berry_bush/*_bush.png} 是「整丛浆果」（含枝叶），
 * 也不适合当单个果实的方块纹理；TFC 本身没有「树干果实」这种方块，
 * 没有现成贴图可借。<b>所以自己画</b>。
 *
 * <h2>画法：整张不透明 + 球面光照</h2>
 * ⚠️ 早期版本把球外的像素留成**透明**，结果贴在立方体上时，每个面都只显示一个圆片、
 * 四个角透空 —— 方块看上去像「六张圆形贴纸」而不是一颗果实。
 * 方块模型的贴图<b>必须铺满整张</b>，立体感靠**光照**而不是靠 alpha 轮廓来做：
 *
 * <ul>
 *   <li>对每个像素求到球心的距离 d：令 {@code t = min(1, d/R)}；</li>
 *   <li>球内按球面法线 {@code z = sqrt(R²−d²)/R} 做 Lambert 光照（光源左上偏前）；</li>
 *   <li>球外（t = 1）不再透明，而是把亮度压到最低，形成「变暗的边缘」——
 *       立方体六个面拼起来就是一颗有明暗的果实。</li>
 * </ul>
 *
 * 用法: java GenFruitTexture.java &lt;任务清单.json&gt;
 * 清单形如 {"jobs":[{"out":"block/plant/x.png","r":60,"g":20,"b":70,"radius":6}]}
 */
public final class GenFruitTexture {

    private record Job(String out, int r, int g, int b, int radius) {}

    public static void main(final String[] args) throws IOException {
        if (args.length < 1) {
            System.err.println("用法: GenFruitTexture <任务清单.json>");
            System.exit(2);
        }
        final String json = Files.readString(Paths.get(args[0]), StandardCharsets.UTF_8);
        int made = 0;
        for (final Job job : parse(json)) {
            final Path out = Paths.get(job.out());
            Files.createDirectories(out.getParent());
            ImageIO.write(render(job), "PNG", out.toFile());
            made++;
        }
        System.out.println("  [果实纹理] 生成 " + made + " 张（整张不透明）");
    }

    /** 画一颗果实 */
    private static BufferedImage render(final Job job) {
        final int size = 16;
        final BufferedImage img = new BufferedImage(size, size, BufferedImage.TYPE_INT_ARGB);
        final double cx = (size - 1) / 2.0, cy = (size - 1) / 2.0;
        final double R = Math.max(1.0, job.radius());

        // 光源方向（左上偏前），归一化
        final double lx = -0.45, ly = -0.50, lz = 0.74;

        for (int y = 0; y < size; y++) {
            for (int x = 0; x < size; x++) {
                final double dx = x - cx, dy = y - cy;
                final double d2 = dx * dx + dy * dy;
                final double d = Math.sqrt(d2);
                // t: 0 = 正对球心，1 = 已在球外（压暗区）
                final double t = Math.min(1.0, d / R);

                // ⚠️ 只在**球内**取法线。球外的 dx/dy 可以远远大于 R
                //    （例如 dx=11、R=5 → nx=2.2），照算会让 lambert 溢出、
                //    高光项 pow(lambert,18) 爆掉，在左上角糊出一块纯白 —— 实测踩过两次。
                final boolean inside = d2 < R * R;
                final double nz = inside ? Math.sqrt(R * R - d2) / R : 0.0;
                final double nx = inside ? dx / R : 0.0;
                final double ny = inside ? dy / R : 0.0;

                double lambert = inside ? (nx * lx + ny * ly + nz * lz) : 0.0;
                if (lambert < 0) lambert = 0;
                else if (lambert > 1) lambert = 1;

                // 环境光 0.5 + 漫反射 0.7；再按 t 压暗，但保底 0.2 使其成为「暗边缘」而非黑边
                double light = 0.50 + 0.70 * lambert;
                light *= (1.0 - 0.45 * t * t);
                if (light < 0.20) light = 0.20;

                // 左上角高光：同样只在球内 —— 球外给高光就会在角上糊出一块白斑
                final double spec = inside ? Math.pow(lambert, 18) * 0.35 : 0.0;

                final int r = clamp((int) Math.round(job.r() * light + 255 * spec));
                final int g = clamp((int) Math.round(job.g() * light + 255 * spec));
                final int b = clamp((int) Math.round(job.b() * light + 255 * spec));

                // ⚠️ 整张不透明：方块模型没有「圆形轮廓」，立体感只能来自明暗
                img.setRGB(x, y, (255 << 24) | (r << 16) | (g << 8) | b);
            }
        }
        return img;
    }

    private static int clamp(final int v) { return v < 0 ? 0 : Math.min(255, v); }

    /** 极简解析：清单是本工具自己约定的扁平结构，不值得引入 JSON 库 */
    private static List<Job> parse(final String json) {
        final List<Job> out = new ArrayList<>();
        final Matcher m = Pattern.compile(
            "\\{\\s*\"out\"\\s*:\\s*\"([^\"]+)\"\\s*,\\s*\"r\"\\s*:\\s*(\\d+)\\s*,\\s*\"g\"\\s*:\\s*(\\d+)\\s*,"
            + "\\s*\"b\"\\s*:\\s*(\\d+)\\s*,\\s*\"radius\"\\s*:\\s*(\\d+)\\s*\\}")
            .matcher(json);
        while (m.find()) {
            out.add(new Job(m.group(1), Integer.parseInt(m.group(2)),
                Integer.parseInt(m.group(3)), Integer.parseInt(m.group(4)), Integer.parseInt(m.group(5))));
        }
        return out;
    }

    private GenFruitTexture() {}
}
