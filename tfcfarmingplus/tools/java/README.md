# Java helpers

| 文件 | 用途 |
|---|---|
| `TintTextures.java` | 由 `localize-all-models.ps1` / `localize-fruit-tree-models.ps1` / `localize-textures.ps1` 调用，给 TFC 果树贴图做本地命名空间染色并写出。 |
| `TextureAverage.java` | 独立的贴图平均色统计小工具，手工分析用。 |
| `TextureStats.java` | 独立的贴图像素/颜色统计小工具，手工分析用。 |

这些是工具辅助程序，不是模组源码，不进入 `src/main/java`。用 Java 21 单文件源码方式运行；调用方应使用 `tools/java/<File>.java` 路径。

Archive 里的 `GenFruitTexture.java` 只属于已归档的树干果实旧生成器，不参与活动工具链。
