import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.File;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Arrays;
import java.util.Comparator;

/**
 * 打印一个目录下所有 PNG/WebP 的平均不透明 RGB —— 用于批量评估贴图色系
 * （判断"树皮是不是棕色""叶片是不是绿色"这类问题，比逐张看图快得多）。
 *
 * 用法: java TextureAverage.java &lt;目录&gt; [名字过滤子串]
 */
public final class TextureAverage {
    public static void main(String[] args) throws Exception {
        if (args.length < 1) { System.err.println("用法: TextureAverage <目录> [过滤]"); System.exit(2); }
        final Path dir = Paths.get(args[0]);
        final String filter = args.length > 1 ? args[1] : "";
        final File[] files = dir.toFile().listFiles();
        if (files == null) { System.err.println("目录不存在: " + dir); System.exit(2); }
        Arrays.sort(files, Comparator.comparing(File::getName));
        for (File f : files) {
            final String n = f.getName();
            if (!n.endsWith(".png") && !n.endsWith(".webp")) continue;
            if (!filter.isEmpty() && !n.contains(filter)) continue;
            final BufferedImage img = ImageIO.read(f);
            if (img == null) { System.out.printf("%-32s <读不出>%n", n); continue; }
            long r = 0, g = 0, b = 0; int cnt = 0;
            for (int y = 0; y < img.getHeight(); y++) {
                for (int x = 0; x < img.getWidth(); x++) {
                    final int p = img.getRGB(x, y);
                    if (((p >>> 24) & 0xFF) == 0) continue;   // 跳过透明
                    r += (p >> 16) & 0xFF; g += (p >> 8) & 0xFF; b += p & 0xFF; cnt++;
                }
            }
            if (cnt == 0) { System.out.printf("%-32s <全透明>%n", n); continue; }
            final long R = r / cnt, G = g / cnt, B = b / cnt;
            // 粗略判断色系：棕= R>G>B 且差距明显；绿= G 最大
            final String family;
            if (G >= R && G >= B) family = "绿";
            else if (R > G && G >= B) family = (R - B > 40 ? "棕/橙" : "灰褐");
            else if (B >= G && B >= R) family = "蓝/紫";
            else family = "其它";
            System.out.printf("%-32s R=%3d G=%3d B=%3d   %s%n", n, R, G, B, family);
        }
    }
    private TextureAverage() {}
}
