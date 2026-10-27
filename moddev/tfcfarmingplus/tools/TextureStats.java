import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.File;

/**
 * 贴图统计小工具 —— 用于**用数字确认**色调变换真的生效。
 *
 * <p>背景：本次会话所用的模型不支持图片输入，没法目视比对，
 * 所以改成打印每张贴图的「不透明像素数 + 平均 RGB」。
 * 用法：<code>java TextureStats.java &lt;a.png&gt; &lt;b.png&gt; ...</code>
 */
public final class TextureStats {

    public static void main(String[] args) throws Exception {
        for (final String a : args) {
            final File f = new File(a);
            final BufferedImage img = ImageIO.read(f);
            if (img == null) {
                System.out.printf("%-30s 读取失败%n", f.getName());
                continue;
            }
            long r = 0, g = 0, b = 0;
            int n = 0;
            for (int y = 0; y < img.getHeight(); y++) {
                for (int x = 0; x < img.getWidth(); x++) {
                    final int p = img.getRGB(x, y);
                    if ((p >>> 24) == 0) {
                        continue;
                    }
                    r += (p >> 16) & 0xFF;
                    g += (p >> 8) & 0xFF;
                    b += p & 0xFF;
                    n++;
                }
            }
            System.out.printf("%-30s %2dx%-2d 不透明=%3d  平均RGB=(%3d,%3d,%3d)%n",
                f.getName(), img.getWidth(), img.getHeight(), n,
                n == 0 ? 0 : r / n, n == 0 ? 0 : g / n, n == 0 ? 0 : b / n);
        }
    }

    private TextureStats() {}
}
