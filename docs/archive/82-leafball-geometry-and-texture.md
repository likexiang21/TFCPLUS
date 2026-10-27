# 82 叶球类作物：几何改造 + 贴图重绘（lettuce / broccoli 两个代表）

> 依据 `.probe/texture-design/SPEC.md`（v2「整块板 + uv 1:1」，用户 2026-09-24 指令）。
> 本轮**只落盘 lettuce / broccoli（Standalone 模式）**，kale / napa_cabbage / cauliflower /
> cabbage 的旧几何与旧贴图**一个字节都没动**（原因见 §8）。
> ⚠️ **未做实机验证** —— 全部结论来自离线等轴测渲染（`preview-model.ps1` / `preview-lab.ps1`，
> 无光照、无 AO、无染色）。不要把它当成「实机通过」。

## 0. 产出清单

| 路径 | 内容 |
|---|---|
| `.probe/texture-design/leafball/*.txt` | 4 张**逐像素手写设计稿**（调色板 + ASCII 网格） |
| `.probe/texture-design/leafball/out/*.png` | 4 张 16×16 成品 + `-zoom20.png` 放大图 |
| `.probe/texture-design/leafball/out/LB5-REAL-*.png` | 用**真实 moddev 资源**渲染的最终验收图 |
| `.probe/texture-design/leafball/deliverable/` | 可落盘包：`models/`（18 个 json）+ `textures/`（21 张）+ `APPLY.ps1` |
| `.probe/lab-assets/.../lab_lb_*.json` | lab 环境几何（3 个 age × 2 物种，供反复试渲染） |
| `moddev/.../models/block/crop/lettuce_age_*.json` | **已落盘**：内嵌 elements 的新几何（12 个） |
| `moddev/.../textures/block/crop/{lettuce,broccoli}_leafball_*.png` | **已落盘**：14 张贴图 |

## 1. 现状探查（全部读文件确认）

### 1.1 旧 `leafball_age_*` 的真实结构

`leafball_age_0..5.json` 是**共享几何**，元素数 10（age0/1）或 11（age2~5）。以 `age_5` 为例：

| 元素 | 内容 | 问题 |
|---|---|---|
| 4 片 **未旋转**的板 | `from[6,0,8] to[10,0,18]`、`from[6,0,-2] to[10,0,8]`、`from[8,0,6] to[18,0,10]`、`from[-2,0,6] to[8,0,10]` | 只有 4px 宽却拉满 16 高；**水平方向伸到 -2 / 18，出了方块** |
| 4 片绕 x/z ±22.5° 的板 | `from[6,0,8] to[10,0,15.5]` 等 | 同上 |
| 2 片绕 y ±45° 的板 | `from[6,0,8] to[10,0,18]` | 同上 |
| head（age≥2） | `from[4,0,4] to[12,7,12]` 立方体，6 面 `uv:[0,0,16,16]` | 整张贴图压进 8×8 的面（**压缩 2 倍**） |

三条硬伤：
1. **全部叶片是 `y:0→0` 的水平零厚度面片，且 `faces` 里只有 `up` / `down`** ——
   平视时只剩一条线；
2. **uv 是「把 16×16 切成 4 条 4×16 竖条」**（`up:[0,0,4,16]` / `down:[4,0,0,16]` …）
   ⇒ 贴图横向**压缩 4 倍**；
3. **水平方向出了方块**（-2 ~ 18）。

### 1.2 谁在共用

- `assets/tfcfarmingplus/models/block/crop/`：**broccoli / cabbage / cauliflower / kale / lettuce /
  napa_cabbage** × 6 个 age = **36 个模型**，全部形如
  `{"parent":"tfcfarmingplus:block/crop/leafball_age_N","textures":{"0":"…_leafball_N","1":"…_leafball_head"}}`
  ⇒ **几何完全共享，物种只改 textures**。`lettuce` 不例外。
- `assets/tfc/models/block/crop/cabbage_age_0..5.json`：**TFC 原版 cabbage 被本模组覆盖**，
  也 parent 到同一几何（TFC jar 里原版是 `{"parent":"block/crop"}`，即原版小麦十字）。
- blockstate：`blockstates/crop/{lettuce,broccoli,kale,napa_cabbage,cauliflower}.json`
  各 6 个 `age=0..5` 变体；cabbage 走 TFC 的 blockstate。
- `dead_crop/*`、`wild_crop/*` 是**另一套**模型，不使用这个几何。

### 1.3 渲染出来是什么样（read_image 看到的）

- `leafball_age_5`（`LBOLD-age5-p45.png`）：中央一个**方盒子**（就是那个 head 立方体），
  四周伸出一圈**放射状的扁平细条**，像「笼子 / 扫帚条」，看不出是叶子；
- 旧贴图放大图（`LBOLD-textures-zoom20.png`）：8 张里 6 张物种贴图全是
  **「4 条并排的竖条」**，只有颜色差别（lettuce 亮绿、broccoli 深绿、kale 灰绿带白点…），
  与 `docs/79 §3.5` 记录的「用户判定不合格：画出来是 4 条并排的柱状条，6 个物种无法区分」一致。

## 2. 新几何

### 2.1 叶片 = 4 片整块板（照 SPEC §1）

```
{"from":[0,0,0],"to":[16,0,16],
 "rotation":{"angle":22.5,"axis":"x","origin":[8,0,8]},"shade":false,
 "faces":{"up":{"uv":[0,0,16,16],"texture":"#0"},"down":{"uv":[0,16,16,0],"texture":"#0"}}}
```
角度组合 `x:+22.5 / x:-22.5 / z:+45 / z:-45`，全部 `shade:false`，`ambientocclusion:false`。

### 2.2 head = 8×8×8 立方体 + **4 象限 uv**

叶球必须有球。做法：
- 几何仍是一个立方体（`from[4,0,4] to[12,8,12]`），**但每个面只画直径 6 的圆**
  （8×8 象限内居中、四边各留 1px 透明）⇒ 立方体的棱全部落在透明区，**可见部分等于内切球**；
- 16×16 贴图切成 **4 个 8×8 象限**，每个面取 8×8 ⇒ **uv 1:1，不压缩也不放大**：

| 面 | uv | 象限 |
|---|---|---|
| north / south | `[0,0,8,8]` | A |
| east / west | `[8,0,16,8]` | B |
| up | `[0,8,8,16]` | C |
| down | `[8,8,16,16]` | D |

（「6 面共用中心一块」也可行，但那样贴图只用掉 64 像素、opaque 只有 64，达不到 100~160。）

### 2.3 生长阶段：**板尺寸 + uv 同步放大**，贴图 6 个 age 共用

| age | 板 from→to | uv | head |
|---|---|---|---|
| 0 | 4→12 | `[4,4,12,12]` | — |
| 1 | 3→13 | `[3,3,13,13]` | — |
| 2 | 2→14 | `[2,2,14,14]` | 5×5×5 |
| 3 | 1.5→14.5 | `[1.5,1.5,14.5,14.5]` | 6×6×6 |
| 4 | 1→15 | `[1,1,15,15]` | 7×7×7 |
| 5 | 0→16 | `[0,0,16,16]` | 8×8×8 |

因为**贴图也跟着放大**，每个 age 都是 1:1 ⇒ 与莲座类同一套思路（几何表达阶段、贴图共用），
6 个 age **只需要画 1 张叶片贴图**。

### 2.4 边界与角度自检（脚本跑过，18 个 json 全过）

```
leafball_age_0   X[  4.00, 12.00] Y[ -2.83,  2.83] Z[  4.00, 12.00]  H-OK
leafball_age_5   X[  0.00, 16.00] Y[ -5.66,  8.00] Z[  0.00, 16.00]  H-OK
…（全 18 个 H-OK，角度全部 ∈ {-45,-22.5,0,22.5,45}）
=== 自检失败项: 0 ===
```

- ✅ **水平方向完全在 0~16 内**（age5 恰好贴边）——这是相对旧几何（-2 ~ 18）的实质修复；
- ⚠️ **Y 最低到 -5.66**：45° 板绕 `origin[8,0,8]` 旋转的必然结果（`y' = x·sin45`，x 半宽 8）。
  **SPEC 的参考模板 `lab_fp_mix.json` 与 TFC 的 `bird_nest_fern` 同样如此**（它们都把 pivot 放在 y=0）。
  垂直下探的部分在游戏里落在下方方块的空间内，会被耕地的面遮挡。若要严格 y≥0，
  只能把板整体抬高（叶丛会浮空 0.35 格）或去掉 45° 那两片 —— 与 SPEC §1 冲突，需用户裁决。

## 3. 贴图（逐像素手写）

### 3.1 设计稿（纯文本、可 diff、每个像素手工决定）

| 设计稿 | 用途 |
|---|---|
| `.probe/texture-design/leafball/lettuce_plate_5.txt` | 结球生菜外层叶（8 瓣宽圆叶、亮黄绿） |
| `.probe/texture-design/leafball/lettuce_ball_5.txt` | 生菜叶球（4 象限，光滑同心球面） |
| `.probe/texture-design/leafball/broccoli_plate_5.txt` | 西兰花外叶（十字状灰绿裂叶） |
| `.probe/texture-design/leafball/broccoli_ball_5.txt` | 西兰花花球（4 象限，3/4/5 交错的花蕾颗粒） |

### 3.2 叶片贴图按**径向分层**画，一份贴图覆盖 6 个 age

- 半径 0~2：嫩叶心（5 色）—— age0/1 的板只取 uv 中心 8×8，看到的就是这一小丛；
- 半径 2~4：内层叶（3 色）；
- 半径 4~7：外层叶（3/4）+ 叶尖（4/5）。

age5 时中心恰好被 head 遮住，所以「中心画嫩叶」不会浪费。

## 4. 迭代记录（head 改了 4 轮，plate 改了 2 轮；每轮都真的 read_image 看过）

| 轮 | 改动 | 看图后判定 |
|---|---|---|
| **v1** | head 象限画**直径 8 的圆**（四角削 2px），侧面「上亮下暗」，底部用 1(最深) | 削角后仍像**削了角的方块**；平视出现**一条黑缝**把球和叶子割开（底部 1 色所致） |
| **v2** | 改画**直径 6 的圆**（四边各留 1px 透明） | head 明显变圆 ✓ 但**平视时竖直棱上出现 2px 透明缝**（相邻两面各留 1px），球被看成两根柱子 |
| **v3** | ① 图案改**上下左右对称的同心圆**；② 圆最宽两行**画到左右边界** | 竖缝基本消失 ✓ 平视仍是「两瓣」，但已不是「两根柱子」 |
| **v4** | A/B 象限最宽两行的**左右端点 2→3**（消除相邻面共棱处的深色带） | 最终版。平视能看到「球 + 外叶」，不再是方块 |
| plate v2 | 中心 4×4 改成嫩叶（原来是最深的 1/2 色） | 使 age0/1 的小板显示为「幼苗丛」而不是一块暗斑 |

**v3 那条为什么必须做**：MC 侧面的 uv 里 `v=0` 落在模型**底部**（`preview-model.ps1` 的
`faceDefs.north = @(0,1,5,4)` + uv 按顶点顺序映射 ⇒ 贴图上下翻转贴上侧面）。
v2 画的「上亮下暗」在模型上变成「下亮上暗」，球像是从下面打光。
改成**对称的同心圆**后无论 uv 方向如何都成立，方向感交给引擎的 `shade` 去给。

## 5. 量化指标（门槛：opaque 100~160 / colors ≤8 / LUM avg 110~140）

| 贴图 | opaque | colors | LUM avg | min~max |
|---|---|---|---|---|
| `lettuce_plate_5` | 156 | 5 | **122.6** | 65.2~180.4 |
| `lettuce_ball_5` | 144 | 4 | **135.1** | 90.6~180.4 |
| `broccoli_plate_5` | 138 | 5 | **125.4** | 62.3~177.1 |
| `broccoli_ball_5` | 144 | 4 | **125.6** | 76.4~162.9 |

（TFC `bird_nest_fern` 基准：opaque 116 / colors 5 / LUM 96~146 avg **123**。）
四张全部落在门槛内，色数 5 / 5 / 4 / 4，LUM 全部贴近 TFC 的 123。

几何：18 个 json，角度合法 18/18，水平边界 18/18，失败 0。

## 6. 落地状态 / 应用 / 回滚

- **已落盘（Standalone）**：`lettuce_age_0..5.json`、`broccoli_age_0..5.json`（内嵌 elements，
  **不 parent 共享几何**）+ 14 张贴图。备份在
  `.probe/backup-pre-leafball-<时间戳>/`。
- `verify.ps1` 落盘后重跑：**「全部交叉引用有效，未发现问题」**（blockstate 413 / 模型 1745 /
  掉落表 412 / 物品模型 375）。
- 还需：`cd moddev\tfcfarmingplus && gradle build --console=plain`，再把 jar 复制到 `mods\`。
- 回滚：把备份目录里的文件复制回原位置。
- 交付包里的 **Shared 模式**（`APPLY.ps1 -Mode Shared`）会把 `leafball_age_*` 换成新几何 ——
  **在那 4 个物种的贴图重画之前不要用**（见 §8）。

## 7. 剩余问题

1. **Y 到 -5.66**（见 §2.4）—— SPEC 模板固有，需用户裁决是否接受。
2. **平视(p8)时 head 仍偏「两瓣」**：正交等轴测下两个侧面各显示一个同心圆。
   实机有透视 + 光照 + AO，实际观感应好于此，但**未验证**。
3. **head 上方会看到一片翘起的叶子**（45° 板远端的投影）。TFC 蕨类同样如此，本轮未处理。
4. **未做实机验证**：离线渲染无光照/AO/染色，不能替代游戏内画面。
5. **4 个物种贴图未重画**（见 §8）。

## 8. 对其它 4 个叶球物种的建议

### 可以直接套用同一几何，只需新画 2 张贴图（plate + head）

| 物种 | head 该画成什么 | 叶片该画成什么 |
|---|---|---|
| **cabbage**（卷心菜，TFC 覆盖） | 灰蓝绿的**光滑球**，带**白粉/蜡质感**与粗叶脉，比 lettuce 更冷、更暗 | 宽厚灰绿叶、叶柄粗、叶缘微波 |
| **napa_cabbage**（大白菜） | **直立的长卵形**包叶（不是圆球）：竖向叶脉、顶部浅黄白、帮子白 | 长卵形叶、**白色中脉**贯穿、叶缘波状 |
| **cauliflower**（花菜） | **象牙白/乳白**颗粒团（比 broccoli 颗粒更细更密），与 broccoli 只差调色板 | 灰绿长叶、叶柄**包住花球**（可把 plate 的中心留空） |

三者都能**直接复用** `lettuce_age_*.json` 的 elements（把 `textures` 换掉即可），
不需要新几何。cauliflower 与 broccoli 的差别**只在 head 的调色板**（绿 → 乳白），是最省力的一个。

### 需要单独处理

- **kale（羽衣甘蓝）**：kale **不结球**，是散开的**高度皱褶叶丛**。
  用带 head 的叶球几何形态上就不对。建议二选一：
  1. 改用莲座几何 `rosette_age_*`（已有 6 阶段 + 枯死态，`tools/gen-rosette-models.ps1` 生成），
     只需再画一张 kale 的皱叶贴图；
  2. 或做一套「无 head 的叶球几何」（就是本轮的 age0/1 那 4 片板）+ 极度皱褶的叶贴图。
  **推荐第 1 条**（复用现成管线，成本最低）。
