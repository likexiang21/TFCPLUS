# 第 48 轮（子任务）：结球 head / 莲座果实 —— 方块表皮贴图重画

> 执行者：贴图子代理（独立工作、自主迭代）。**未改任何 `.json`；未构建 jar；无实机验证。**
> 依据的用户裁决：**「minecraft 本身不存在"球"，是方块来表现球，所以请不要执着于画个球」**
> + **「结球类参考自己的模型」** ⇒ 几何回到**立方体**，贴图必须是**不透明的方块表皮**。

## 一、反查确认的 10 个文件名（先 grep `models/**/*.json`，不猜）

`models/block/crop/*.json` 里 `textures."1"`（head / fruit 槽）的引用：

| 物种 | 模型文件 | 贴图名（写入目标） |
|---|---|---|
| cabbage | `cabbage_age_2..5.json` | `cabbage_leafball_head.png` |
| lettuce | `lettuce_age_2..5.json` | `lettuce_leafball_head.png` |
| napa_cabbage | `napa_cabbage_age_2..5.json` | `napa_cabbage_leafball_head.png` |
| cauliflower | `cauliflower_age_2..5.json` | `cauliflower_leafball_head.png` |
| broccoli | `broccoli_age_2..5.json` | `broccoli_leafball_head.png` |
| kale | `kale_age_5_fruiting.json` | `kale_rosette_fruit.png` |
| cardoon | `cardoon_age_5_fruiting.json` | `cardoon_rosette_fruit.png` |
| agave | `agave_age_5_fruiting.json` | `agave_rosette_fruit.png` |
| purslane | `purslane_age_5_fruiting.json` | `purslane_rosette_fruit.png` |
| sisal | `sisal_age_5_fruiting.json` | `sisal_rosette_fruit.png` |

与任务给的 10 个名字**完全一致**，无命名错位。

## 二、几何（只读，未改动）

| 宿主模型 | 立方体尺寸 | uv |
|---|---|---|
| `leafball_age_2` | 4×3×4（`6,0,6 → 10,3,10`） | 六面 `[0,0,16,16]` |
| `leafball_age_3` | 5×4×5 | 同上 |
| `leafball_age_4` | 6×5×6 | 同上 |
| `leafball_age_5` | 8×7×8（`4,0,4 → 12,7,12`） | 同上 |
| `rosette_age_5_fruiting` | 4×5×4（`6,0,6 → 10,5,10`） | 同上 |

⇒ 贴图被**非等比拉伸**；**六面共用同一张**（四边会在棱上相接）。所有贴图做成 **op=256 全不透明**，
并把最外一圈做成"中等偏暗的同一档色"，让相邻面在棱上颜色相接（不出现"越靠边越黑"的硬棱）。

## 三、迭代记录（每轮只改一件事，每轮都 `read_image` 实看）

| 轮 | 改的一件事 | 看渲染后发现的 |
|---|---|---|
| R1 | 初稿：同心分层 + **逐像素随机跳档** | 3D 下是"**迷彩布箱子**"：图案碎成噪点；cauliflower/napa 对比太低 → 白箱子 / 米色箱子 |
| R2 | 改成**分层 + 层内平铺块面**（去掉逐像素抖动），并**加深暗部** | cauliflower 出**颗粒**、napa 出**竖菜心**、agave 出**纵棱** ✓；但 cabbage/lettuce/kale/cardoon/sisal 变成"**平的色块**"，没有结构；broccoli 太暗看不出颗粒 |
| R3 | 给弱图加**结构线**（叶缘环 / 波浪缝 / 鳞片横线 / 纵纤维线），broccoli 只改调色板拉对比 | cabbage 的环太规整=**虚线圆**；kale 的两条竖线=**三条绿竖条**；broccoli 中心仍是**一整块亮板**（不是颗粒） |
| R4 | 把结构线**有机化**：环改成断续单边、竖线改成斜弧、broccoli 中心**切出 2×2 花球团块** | 三处都改善 ✓（broccoli 终于读成"花球"而不是"绿石头"） |
| R5 | **只调 agave 果实调色板**（暖沙褐 → 灰绿褐） | agave 果实与自己的莲座叶层（灰绿 `749880`）**同色系**了 ✓ |

## 四、最终每张"在渲染图上看到什么"

**叶球（`px/CUBEHEAD-R4*.png`，p28 / p5 / p70 三角度都看过）**

- `cabbage_leafball_head` — 中绿实心方块。p28 正面中央是一块亮绿，四周由**断续的深色叶缘点**围住，
  左多右少（不呈环）；p5 侧视是一整面中绿带深点；p70 俯视顶面是绿底 + 零星深点。**读成"包心菜的芯"**。
- `lettuce_leafball_head` — 黄绿。p28 正面中央亮黄绿被一条**左上→右下的深色折线**切开，叶缘比 cabbage 碎；
  p70 顶面上这条斜缝最清楚。**读成"卷起来的松散叶球"**。
- `napa_cabbage_head` — 米黄近白。三角度都能看到**正中间一条竖向的浅色菜心带**，两侧是稍暗的米色包裹叶，
  最外是暗黄边。**读成"竖长的白菜"**（与其它四个一眼可分）。
- `cauliflower_head` — 白。整面是**灰白小方块（花球颗粒）**，缝比 R1 深得多；p70 俯视颗粒最密。
  **读成"白色花球"**（唯一允许偏白的一张）。
- `broccoli_leafball_head` — 深绿。中央亮绿被深缝**切成 4~5 个 2×2 团块**，缝隙近黑绿，团块中心偶有更亮的小点。
  **读成"深绿花球"**（R3 时还是"绿石头"）。

**果实（`px/FRUITCUBE-R4/R5*.png`，p28 / p5 / p70 三角度都看过）**

莲座场景里果实方块被四周张开的叶片托着、只露出一部分，所以"是不是实心"比 head 更容易看清 —— 五个都是实心。
同色系对照见 `px/FRUIT-LEAF-PAIR.png`（奇数格是果实、偶数格是该物种自己的莲座叶层）。

- `kale_rosette_fruit` — 深绿。亮核只占 8×8，左边一条短暗弧；与 kale 的中绿叶层**同色相、深一档**（紧实小叶球）。
- `cardoon_rosette_fruit` — 橄榄绿。能看到几道**断续的横向深色苞片交叠线**；与 cardoon 的灰橄榄叶层同族。
- `agave_rosette_fruit` — 灰绿褐。**三~四条纵向棱**（棱脊亮、棱沟暗），上下收窄；R5 调色后与 agave 的灰绿叶层统一。
- `purslane_rosette_fruit` — 土黄/橙褐。最小的一个，中央亮核约 6×6，**左下一个红点**（对应叶层里的暗红 `7C3327`）。
- `sisal_rosette_fruit` — 灰褐。**六~七条纵纤维线**贯穿亮部（比 agave 细而密）；与 sisal 的灰绿叶层同调。

## 五、5 个叶球的区分依据

色相 + 明度 + 图案语法三重区分，不靠单一维度：

| | 色相 | 明度 | 图案语法 |
|---|---|---|---|
| cabbage | 中绿 | 中（LUM≈98） | 断续叶缘点围亮核 |
| lettuce | 黄绿 | 亮（≈120） | 斜向折缝切亮核、叶缘碎 |
| napa_cabbage | 米黄白 | 很亮（≈195） | 竖向菜心带（唯一纵向） |
| cauliflower | 纯白偏灰 | 最亮（≈207） | 小方块颗粒（唯一"非叶"结构） |
| broccoli | 深绿 | 暗（≈67） | 深缝切出的 2×2 花球团块 |

## 六、逐张数据（`draw2.ps1` 打印，仅作参考，不作验收）

全部 `op=256`（完全不透明）、`asym 39~93`（无一张镜像对称）、色数 5~7。

## 七、遗留问题（不隐瞒）

1. **p5（近水平）角度下仍偏"有花纹的箱子"** —— 三面的方向 shading（up 100% / 侧面 80%）本身产生硬棱，
   这是几何+渲染机制决定的，用户已拍板立方体，未再追求。
2. **cabbage / cardoon 的图案仍偏"色块"**，叶缘的有机程度不如 lettuce/broccoli；再提升需要逐像素重画叶形轮廓。
3. **cardoon 果实下半部（y10~y13）大片同色**，鳞片感集中在上半部。
4. **未构建 jar、无实机验证**（用户明令不构建）。构建后需核 `Unable to load variant` 与本模组贴图缺失。
5. 设计稿与 PNG 的对应关系：`.probe/texture-design/px/cubehead/<name>.txt` → `src/.../block/crop/<sp>_<slot>.png`，
   可用 `draw2.ps1 -Design ... -Out ...` 复现。

## 八、备份

10 张被覆盖前的旧 PNG 存于 `.probe/texture-design/bak-cubehead-20260927/`（各 191~261 bytes）。
