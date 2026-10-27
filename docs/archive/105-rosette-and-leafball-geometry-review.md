# 105 · 莲座 / 结球几何与贴图的重新审查（2026-09-27 第 48 轮）

> 用户指令：**「你的莲座模型（包括原模型和渲染）重新进行审查，确保模型的合理性以及贴图的正确性」**
> 本次审查的方法：**不改一行就下结论之前，先用真实几何 + 渲染器出图并 `read_image` 实看**
> （渲染器 `.probe/ref-tfc/render-tfc.ps1 -AssetRoot <src>` 直接吃 `src` 里的模型，
> 工具 `.probe/texture-design/rr-review.ps1` 批量出带标签的检查图）。
> 全部证据图在 `.probe/texture-design/px/`，文件名在下面逐条标注。

---

## 一、审查范围

「莲座」在本项目里是**两套共享几何**，物种数比文档里记的多：

| 共享几何 | 使用它的物种 | 模型数 |
|---|---|---|
| `rosette_age_0..5` / `_5_fruiting` / `rosette_dead{,_young}` | `kale` `cardoon` `agave` `purslane` `sisal`（**5 个**，Java 里都是 `RosetteCropBlock`） | 5×12 + 5×2 枯死 |
| `leafball_age_0..5`（credit 写着 “after the rosette pedestal v1”） | `broccoli` `cabbage` `cauliflower` `lettuce` `napa_cabbage`（**5 个**） | 5×6 |

⚠️ `leafball_age_*` 之前没有被算进「莲座」范围里审查过 —— 它其实是**莲座第一版几何的遗留**，
莲座本体已经升到第三版（竖直面片），**它从来没有跟着升级**。这是本次审查最大的发现来源。

---

## 二、发现（按严重度）

### R-A 🛑 P0 · 真 bug：莲座一半的叶片**在游戏里根本没有渲染出来**

`rosette_age_*.json` 的 12 个元素里，E/W 方向那 6 片的几何是 **x 零厚度**：

```json
{"from":[8,0,4],"to":[8,8,12],"rotation":{"angle":-45,"axis":"z",...},
 "faces":{"north":{...},"south":{...}}}
```

`from.x == to.x == 8`，而面却声明成 `north`/`south`。MC 的 `FaceBakery` 烘 north 面时取的是
`(x1..x2, y1..y2) @ z1` —— **x1 == x2 ⇒ 四边形宽度为 0**，渲染出来什么都没有。
（零厚度在 Z 上的元素才该用 north/south；零厚度在 X 上的元素必须用 east/west。
权威对照：`tfc:block/plant/sword_fern` 的 12 个元素里，x 零厚度的 4 片全部都写 `east`/`west`。）

**证据（修复前 → 修复后，同一渲染器）**：

```
修复前  kale_age_5  faces=12/24   ← 12 个元素只有一半的面被真正生成
修复后  kale_age_5  faces=24/24
```

> ⚠️ 按 AGENTS.md 第 42 轮记录，`faces=N/M` 这个计数器**在面循环末尾无条件自增**，
> 一般不能当证据；但**本次的差值恰好来自退化面的顶点重合**（同一条线上的 4 个点），
> 且渲染图（`ROSETTE-REVIEW-TOP.png` vs `ROSETTE-V4-TOP.png`）里
> **从「两片斜板」变成了「四瓣放射」**，两者互为佐证。

- 修复前实看（`px/ROSETTE-REVIEW-3D.png`、`ROSETTE-REVIEW-TOP.png`）：
  俯视下 kale 只有**两个方向**的板（一片朝 −z 倾、一片朝 +z 倾），画面读起来是
  **「几片斜放的绿纸板」**，中心是空的。
- 修复后实看（`px/ROSETTE-V4-3D.png`、`ROSETTE-V4-TOP.png`）：
  **四个方向都长出叶片**，俯视是明确的**四瓣/星形**，age0 是四瓣张开，
  age5 是 12 片交错（外层 45°、中层 22.5°、内层直立）。
- 📌 **对照总览图：`px/ROSETTE-V3-VS-V4.png`**（上图 = 修复前、下图 = 修复后，
  同一渲染器、同一 `yaw 40 / pitch 28`；左边 age0→右 age5、第二行最后一格是 TFC `sword_fern` 参照）。
  上图前四格是"两片斜放的绿纸板 + 中心空洞"，下图前四格是"四瓣张开的叶丛"。

**结论**：玩家此前在游戏里看到的莲座，**只有一半的叶片存在**。这一条单独就足以判「模型不合理」。

**负对照（证明这个 bug 是被"抓出来"的，不是事后描述）**：
新写的审计脚本 `.probe\texture-design\face-axis-audit.ps1`（判据：恰好一个轴零厚度时，
面只允许是垂直于该轴的两个方向）——
- 跑**修复前的备份** `bak-rosette-geom-20260927\rosette_age_5.json`：
  ```
  tfcfarmingplus\models\block\crop\rosette_age_5.json
    -> e3:zero-x illegal=[north,south]  e4:zero-x illegal=[north,south]
       e7:...  e8:...  e11:...  e12:...        ← 正好 6 片，就是 E/W 那 6 片
  ```
- 跑**修复后的当前 src**：`25 个手写模型 / 172 个元素 ⇒ 错配 0`。
（`leafball_age_5` 的 v1 备份是 0 错配 —— 它的 `up`/`down` 对水平板是**合法**的，
它的问题是形态，不是面类型。）

---

### R-B 🛑 P0 · 真 bug：`kale` 的 blockstate 少了一半变体

`RosetteCropBlock` 的 `createBlockStateDefinition` 是 `builder.add(AGE, FRUITING)`
（`common/blocks/RosetteCropBlock.java:57`），也就是说 **kale 方块一定带 `fruiting` 属性**。

而 `blockstates/crop/kale.json` 只有 6 个变体：`age=0` … `age=5`，
**没有任何 `fruiting` 维度**；同族的 `cardoon/agave/purslane/sisal.json` 都是 12 个变体。

后果：`kale_age_0_fruiting` … `kale_age_5_fruiting` 这 6 个模型**永远不显示**，
`kale_rosette_5_fruiting.png` 与 `kale_rosette_fruit.png` 是**死资源**；
而且只要 MC 侧对「变体 key 未覆盖全部属性」的处理是严格模式，kale 成熟后就是**模型丢失**。

- 修复：`blockstates/crop/kale.json` 重写为 **12 变体**（照 `cardoon.json` 的写法）。
  备份 `.probe/texture-design/bak-rosette-geom-20260927/blockstate_kale.json`。

---

### R-C ⚠️ P1 · UV 与实际板高不匹配（纵向压缩）

`rosette_age_*` 的**每一个面**都用 `uv v = 0..16`，而板高只有 6~12：

| 龄 | 外层 45° | 中层 22.5° | 内层 0° |
|---|---|---|---|
| age0/1 | 6 / 7 | — | — |
| age2 | 5 | 7 | 8 |
| age3 | 5 | 7 | 9 |
| age4 | 6 | 8 | 10 |
| age5 | 8 | 10 | 12 |

⇒ 同一张贴图在 12 片叶上以 **最多 3 种不同的纵向压缩率**显示（外倾短叶被压到 43%），
叶形全部失真。`check-geom.ps1` 修复前：**UVBad 24/24**。

- 修复：v 段改为 **底对齐的 1:1**：`v = (16-h) .. 16`（叶基永远落在贴图 y15，叶尖在 y0）。
  修复后 `UVBad 0/24`，`越界模型 0`。
- 顺带把**左右半贴图都利用起来**：N/S 的 6 片读左半（`u 0..8`），E/W 的 6 片读右半（`u 8..16`）。
  修复前 12 片叶全部读左半，贴图右半完全浪费。

---

### R-D 🛑 P0 · 真 bug：`leafball_age_*` 仍是莲座 v1 的**水平零厚度板**（5 物种 × 6 龄 = 30 个模型）

修复前的 11 个元素里有 **4 片完全没旋转的水平板**（`from.y == to.y == 0`，只给 `up`/`down` 面），
另有 **2 片绕 y 轴 ±45° 的板，y 仍然是 0**。三个后果叠在一起：

1. **与耕地顶面共面**：y=0 正是耕地顶面的平面 ⇒ z-fighting，且会被地形面盖住；
2. **侧视几乎不可见**：零厚度水平板从水平方向看投影为一条线；
3. **越界**：age4 `X/Z −1..17`、age5 `X/Z −2..18` —— **伸进相邻方块**。

- 修复前实看（`px/ROSETTE-REVIEW-SIDE.png` 第 2、4 格 = `cabbage_age_5` / `lettuce_age_5`）：
  **一个绿色方箱，底部只剩一圈白色碎屑** —— 那些碎屑就是贴在 y=0 上的水平板。
  整株高度只有 5~7（`rosette_age_5` 是 12），玩家看到的是「贴着地的纸片 + 一个箱子」。
- 修复：整体重做为 **竖直面片 v2**（外层 4 片 45° + 内层 4 片 22.5° + 中心的球），
  与 `rosette` v4 同构，元素 8~13 个；`check-geom` 修复后 **越界 0 / UVBad 0**。
- 修复后实看（`px/LEAFBALL-V4-3D.png`、`ROSETTE-V4-SIDE.png` 第 2/4/5/6 格）：
  cabbage 是**中央叶球 + 四方向张开的叶片**、cauliflower 是**白球 + 外叶**、
  broccoli 是**绿球 + 外叶**、lettuce 是**黄绿球 + 外叶**，
  侧视下**不再是箱子**，底部那圈碎屑消失。
- 📌 **对照总览图：`px/LEAFBALL-V1-VS-V2.png`**（上图 = v1 侧视：只剩一个绿箱 + 底部碎屑；
  下图 = v2 侧视：kale/cardoon 莲座 + cabbage/lettuce/broccoli/cauliflower 的"叶球 + 外叶"）。

---

### R-E ⚠️ P1 · 果实 / 叶球是立方体 + 整张球面贴图 = 「一个贴着圆点的箱子」

`rosette_age_5_fruiting` 的果实是 `from[6,0,6] to[10,5,10]` 的**立方体**，
六个面各贴**一整张**程序化球面贴图 ⇒ 每一面都显示一个完整的圆斑，
拼起来读作「一个贴了圆点的绿箱子」。`leafball` 的 head 同理（8×8×7 的立方体）。

- 修复：改成 **交叉板球**（4 片竖直板 0°/45°/90°/135° + 1 片水平板），
  uv 取**整张**球面贴图（圆形 alpha）⇒ 无论从哪个角度看轮廓都是**圆**。
- 修复后实看（`px/ROSETTE-V4-3D.png` 第 7 格 `kale_age_5_fruiting`）：
  叶丛中央是一颗**浅灰白色的球**（原来是深色方块）；
  `px/LEAFBALL-V4-3D.png` 的 age2→age5 可以看到**球随龄长大**。

---

### R-F ⚠️ P1 · 贴图本身：程序化产物 + 与几何语义不匹配

这一条几何修不了，必须重画。实测证据：

1. **它们是批量/程序化产物**：`cardoon`/`agave`/`kale_rosette_0..4` 全是 **09-24 22:53~23:03**
   同一时刻落盘（生成器 `gen-rosette-models.ps1` 的 `New-LeafAtlas`：同一函数 × 3 个颜色参数），
   `sisal_rosette_*` 是 **09-26 14:37 那次批量覆盖事件**的产物。
2. **sisal 的贴图是洋红色占位**：`sisal_rosette_4.png` 42 色里 **24 色是红系**、
   `_5` 里 7 色有 3 色红系。实看（`px/ROSETTE-SPECIES-TEX.png` 第 5、10 格）：
   **深红色的爪状块 + 亮绿顶** —— 剑麻（sisal）现实是灰绿硬叶，绝无洋红。
3. **贴图与几何的 UV 语义不匹配**：几何把「贴图左半 8px」当作**一片叶**，
   而贴图画的是「4 条 4px 竖条并排」/「上下横带中间镂空」，且几乎铺满不透明
   ⇒ 3D 下每片板变成**一块实心绿方板**。`cardoon` 的「上下横带」在 4 方向重复后
   甚至在中心围出一个**明显的方框**（`px/ROSETTE-V4b-3D.png` 第 5 格）。
4. **5 个物种共用剪影**：`kale_rosette_0..4` 是**同一个团块**只换色；
   `agave_rosette_0..5` 六张同构。

- 修复：**已派两路子代理**按 v4 的 UV 规格重画（莲座 5 物种 / 结球 5 物种），
  规格已写进它们的 prompt：贴图左半给 N/S 板、右半给 E/W 板；叶基在 y15、越往上越收尖；
  **必须留透明包出叶缘**（不许再涂满）。

---

### R-G ℹ️ P2 · 死资源盘点（本次实测，未删）

| 贴图 | 状态 |
|---|---|
| `kale_leafball_0..5` + `kale_leafball_head`（7 张） | **无任何模型引用**（kale 是莲座作物，这批是历史遗留） |
| `leafball_leafball_0..5` + `leafball_leafball_head`（7 张） | **无任何模型引用** |
| `dead_crop/dead_rosette.png`、`dead_crop/dead_rosette_young.png`（2 张） | **无任何模型引用** —— 共享死株模型 `block/dead_rosette{,_young}` 用的是 `crop/rosette_dead{,_young}` |
| `leafball_0..5` + `leafball_head`（7 张） | 被共享几何 `leafball_age_*.json` 的默认 `textures` 引用，但 5 个物种的 wrapper 都覆盖了 `#0`/`#1` ⇒ **永远不会显示** |
| `blockstates/dead_crop/kale.json` + `models/block/dead_crop/kale.json` + `textures/block/dead_crop/kale.png`（3 件） | **Java 里根本没有 `dead("kale")` 方块**（莲座 5 物种统一走 `RosetteCropBlock.die()` → 共享 `MyBlocks.DEAD_ROSETTE`，见 `RosetteCropBlock.java:85`）⇒ 这一组 blockstate / 模型 / 贴图**没有任何方块会用到**。对比：`dead_crop/lettuce.json`、`dead_crop/spinach.json` 都有对应的 `DEAD_LETTUCE` / `DEAD_SPINACH` 方块，是正常的 |

另外两项顺路做的全量审计（都干净）：

- **孤儿模型 = 0**：src 里 2194 个模型，全部被 blockstate 或其它模型的 `parent` 引用到；
- **面类型错配 = 0**：25 个手写模型 / 172 个元素（`face-axis-audit.ps1`）。

---

### R-H ⚠️ P1 · **野生态贴图**也是换色占位，其中 4 张**带着甜菜的红根**

审查野生态时（用真实 TFC 几何渲染：把 jar 里的 `tfc:block/wild_crop/crop` 与
`tfc:block/crop/wild_crop_grass` 导出到 `.probe/lab-wild`，再 `rr-review.ps1 -AssetRoot`），
5 个莲座物种的野生贴图**在 3D 里底部都有一坨暗红**。实测签名（不透明像素 / 色数 / 偏红像素）：

| 我方贴图 | 签名 | 与 TFC 哪张完全相同 |
|---|---|---|
| `cardoon` / `agave` / `purslane` / `sisal` 野生 | **116 / 7 / 48** | **`tfc:beet_wild` = 116 / 7 / 48**（甜菜，红根就在里面） |
| `lettuce` 野生 | 41 / 41 / 0 | `tfc:onion_wild` = 41 / 41 / 0 |
| `cauliflower` 野生 | 45 / 42 / 0 | `tfc:cabbage_wild` = 45 / 42 / 0 |
| `kale` 野生 | 43 / 37 / 0 | 近似 `cabbage_wild` |
| `broccoli` / `napa_cabbage` 野生 | 43 / 39/40 / 0 | 近似 `cabbage_wild` |

⇒ 与 `docs/95` 记录的「活版贴图 = TFC `lentil_5` 换色拷贝」是**同一批 09-26 14:37 事件**的产物：
**9 个物种的野生贴图全是 TFC 野生贴图的换色拷贝**，其中 4 张**连甜菜的红根一起搬了过来**
（`cardoon` / `agave` / `sisal` 现实中都没有红根；`purslane` 只有茎带红褐色）。

✅ 顺带确认一条**硬要求已满足**：野生态外围的草贴图**确实是 TFC 原版**——
我方 `models/block/wild_crop/<sp>.json` 只覆盖 `crop` 槽、不覆盖 `#1`，
渲染时 `#1` 落回父模型 `tfc:block/wild_crop/crop` 的 `tfc:block/crop/wild_crop_grass`
（带 `tintindex:0`，按平原草色染色；渲染日志 `textures=2 / tintedFaces=16` 可证）。
📌 证据图 `px/WILD-ROSETTE-3D.png`（5 个莲座物种，能同时看到"外围 TFC 草叶"与"中间物种贴图"）。
⇒ 已派子代理重画这 9 张野生贴图（几何是 TFC 的：4 片作物板 16×16 **UV 严格 1:1**，
所以"一张 16×16 = 一株成熟植株的完整侧视"）。

🛑 **不删**（删 `src/main/resources` 下的文件必须 `gradle clean build`，用户本轮明确「jar 先不构建」）。

---

## 三、本次落盘的修复

| 文件 | 改动 | 备份 |
|---|---|---|
| `models/block/crop/rosette_age_0..5.json` | E/W 元素面改 `east`/`west`；UV 改 1:1 底对齐；N/S 读左半、E/W 读右半 | `.probe/texture-design/bak-rosette-geom-20260927/`（15 个原文件） |
| `models/block/crop/rosette_age_5_fruiting.json` | 同上 + 果实立方体 → 交叉板球 | 同上 |
| `models/block/crop/rosette_dead.json`、`rosette_dead_young.json` | 同上（单层） | 同上 |
| `models/block/crop/leafball_age_0..5.json` | 水平零厚度板 → 竖直面片 v2 + 交叉板球 head | 同上 |
| `blockstates/crop/kale.json` | 6 变体 → **12 变体**（补 `fruiting` 维度） | `bak-rosette-geom-20260927/blockstate_kale.json` |
| `tools/../.probe/texture-design/rosette-geom-v4.ps1` | 新增：可复跑的几何生成器（`-Apply` 才落盘，备份永不覆盖第一次的原件） | — |
| `.probe/texture-design/rr-review.ps1` | 新增：用**真实几何**批量渲染带标签检查图的工具 | — |
| `.probe/texture-design/face-axis-audit.ps1` | 新增：全量扫描「零厚度轴 vs 面类型」错配（判据见 R-A） | — |

校验（`check-geom.ps1`，修复前后）：

```
修复前：越界模型 2（leafball_age_4/5  X/Z −1..17 与 −2..18）
        uv 非 1:1：18 / 18（rosette 24/24 面、leafball 26/26 面全部不合格）
修复后：越界模型 0
        uv 非 1:1：3 / 18（只剩 sunflower_age_3/4/5_top，与莲座无关）
```

---

## 四、几何最终参数（从落盘后的 json 实测导出，供后续贴图/维护对照）

**`rosette_age_N`（5 个莲座物种共用）**：元素 = 层数 × 4 方向；板宽 8（世界单位）；
`north/south` 读贴图**左半**（u0–8）、`east/west` 读**右半**（u8–16）。

| 龄 | 45° 外层 | 22.5° 中层 | 0° 内层 | 元素数 |
|---|---|---|---|---|
| 0 | h=6 → v10–16 | — | — | 4 |
| 1 | h=7 → v9–16 | — | — | 4 |
| 2 | h=5 → v11–16 | h=7 → v9–16 | h=8 → v8–16 | 12 |
| 3 | h=6 → v10–16 | h=8 → v8–16 | h=9 → v7–16 | 12 |
| 4 | h=6 → v10–16 | h=8 → v8–16 | h=10 → v6–16 | 12 |
| 5 | h=8 → v8–16 | h=10 → v6–16 | h=12 → v4–16 | 12 |
| 5_fruiting | 同 age5 + 交叉板球（4×8² 板 + 1 水平板，整张 `#1`） | | | 17 |
| `rosette_dead` / `_young` | 单层 h=6 / h=4 | | | 4 |

**`leafball_age_N`（broccoli / cabbage / cauliflower / lettuce / napa_cabbage 共用）**：

| 龄 | 45° 外层 | 22.5° 内层 | 中心球直径 | 元素数 |
|---|---|---|---|---|
| 0 | h=5 → v11–16 | h=7 → v9–16 | — | 8 |
| 1 | h=6 → v10–16 | h=8 → v8–16 | — | 8 |
| 2 | h=7 → v9–16 | h=9 → v7–16 | 4 | 13 |
| 3 | h=8 → v8–16 | h=10 → v6–16 | 6 | 13 |
| 4 | h=9 → v7–16 | h=11 → v5–16 | 8 | 13 |
| 5 | h=10 → v6–16 | h=12 → v4–16 | 10 | 13 |

⚠️ **贴图被真正显示的行 = v4–16**（y15 = 叶基，越往上越收尖）；
`head`/果球贴图**整张映射**到 2r×2r 的板 ⇒ 必须是"顶满 16×16 的圆 + 四周透明"。

⚠️ 流程教训：本轮两路贴图子代理**开工后我才发现 UV 表要更正**，而 subagent 不是 teammate、
`send_message` 报 `active teammate not found` ⇒ **无法中途更正**。
⇒ 以后**几何必须先定稿并实测导出 UV 表，再派贴图任务**；派任务时把"实测导出的表"贴进 prompt，
不要贴自己手算的表（本轮我手算的 age3 那行就错了）。

---

## 五、附带查证两件（都是本轮顺路做掉的）

### 5.1 `age_6` 是什么 —— `docs/104` §10.4 的悬案结案 ✅

**答案就在本项目自己的注释里**：`common/MyCrops.java:35-38`

> 生长速率由 TFC 全局统一（约 24 天），`maxAge` **只决定视觉阶段数**：
> `maxAge = 5` → age 0~5，6 个阶段（24÷6 = 每阶段 4 天）
> `maxAge = 6` → age 0~6，**7 个阶段**（每阶段约 3.4 天）

⇒ **`age_6` 不是"过熟期"，而是 maxAge ≥ 6 的作物的**一个正常龄**
（对 maxAge=6 的物种来说它就是最高龄 = 成熟态）。
全量实测（86 个作物 blockstate）：

```
max age = 5  : 59 个物种
max age = 6  :  3 个（brussels_sprouts / buckwheat / winter_melon）
max age = 7  : 24 个（谷物类与番茄式攀爬类，与 TFC 的 8 阶段一致）
age 集合缺口  : 无（每一个都是连续的 0..max）
```

（`docs/104` §11.4 把"~25 个物种有 `age_6`"当成疑点，是因为 `age=6` 在那 27 个 blockstate 里
大多是**中间龄**（max=7 的作物），只有 3 个物种的 `age_6` 是**最高龄**。）

⚠️ 但 `winter_melon_age_6` 确实**画错了内容**（不是语义错）：它是蔓延型作物，
年龄贴图**只画藤叶**，而它被画成了"绿球 + 短茎"的果实图标 ⇒ 已派子代理按
"最成熟的藤叶（不要画瓜）"重画。

### 5.2 `kale` blockstate 缺变体是不是普遍现象 —— 不是 ✅

- 有 `_fruiting` 模型的物种只有 6 个：`agave` / `cardoon` / `kale` / `purslane` / `sisal`
  （+ 共享几何 `rosette_age_5_fruiting`）；
- 其中 **`kale` 是唯一一个 blockstate 漏了 `fruiting` 维度的**（其余 4 个都是 12 变体）⇒ 已修；
- 全项目 86 个作物 blockstate 的 age 变体**没有缺口**；`verify.ps1` 交叉引用**全绿**
  （blockstate 475 / 模型 2052 / 掉落表 475 / 物品模型 429）。

---

## 六、遗留项（下一轮入口）

1. **贴图重画在途**（两路子代理）：莲座 5 物种 × (6 龄 + fruiting + 果球)、结球 5 物种 × (6 龄 + 球)。
   验收判据：3D p28/p70/p5 下**每片板看得出是叶子**、5 物种**一眼能区分**、
   生长序列是同一株长大；`cardoon` 中心不许再出现方框、`sisal` 不许再有洋红。
2. ✅ 已修：`leafball` 的 age3 与 age4 原本参数完全相同（同一个模型）。
   现在 6 龄严格单调：外层 h1 = 5/6/7/8/9/10、内层 h2 = 7/8/9/10/11/12、球直径 = –/–/4/6/8/10。
   ⚠️ 后续若要再调，**必须保持"每一龄与相邻龄不同"**。
3. `age_6` 语义**已结案**（见 §5.1）：它是 maxAge≥6 作物的正常龄，不是过熟期；
   剩下只有 `winter_melon_age_6` 的**内容**要重画（在途）。
4. 未重画的其余 ~23 个物种（`lettuce` 之外的叶菜、`cauliflower` 之外的…）仍按 `docs/104` 的清单推进。
5. 本次所有改动**未构建 jar**（用户明令），因此**没有实机验证**；
   下一轮若构建，必须核对：`Unable to load variant`（kale 12 变体）、
   `Unable to load model`、以及实机里莲座是否真有 4 个方向的叶片。

---

## 七、本轮同时推进的其他工作（用户同一条指令的前半句「开始推进其他工作」）

| 工作 | 执行 | Lead 亲自实看验收（判据 = 能指出位置看到什么） |
|---|---|---|
| `chili` age3 重建 | 子代理 7 轮 | ✅ 看 `px/CHILI-AGE3-R8.png`（3 龄 × 4 视角）：p28 下 age2「矮聚一小丛」→ **age3「高一截宽一圈的蓬松斜枝叶丛，右侧中部一颗米白花，缝隙里能透到黑背景」** → age4「满冠大丛」，三者是同一株在长大；2D 不是实心块/竖条/蘑菇/黑色拱门。主茎逐龄锚点：dump 实测 age0 x8 / age1 x7–8 / age2 x7 / age4 x7 ⇒ 新 age3 锚在 **x7**，高度序列 10→12→14 行 |
| `spinach` 六龄 + 野生态 + 枯死态重画（9 张） | 子代理 11 轮 | ✅ 看 `px/SPINACH-SEQ.png`（6 龄 × 2D+p28）：age0 是**贴底的两片竖直小叶（左矮右高、中间隔一格缝）**，上面 12 行全空；age2 起叶向左右斜上方张开、中心 1px 细茎、**3D 里背景能从叶缝透出来**；age4 顶部出现淡黄绿花粒；age5 是**散开的黄绿花穗 + 大片叶丛**。改前是「左右对称的绿云 + 一根粗绿柱」，3D 渲染成拱门/两片实心绿板（子代理留证 `px/SPINACH-CURRENT.png`） |
| `winter_melon_age_6` 重画 | 子代理在途 | —（结论见 §5.1：年龄贴图只画藤叶、不画瓜） |
| 莲座 5 物种贴图 / 结球 5 物种贴图重画 | 2 路子代理在途 | —（验收判据见 §六-1） |

⚠️ 两路贴图子代理**开工后我才发现要给它们更正的 UV 表**，而 subagent 不是 teammate
（`send_message` 报 `active teammate not found`）⇒ 无法中途更正。
已核对差异：莲座那路我 prompt 里手算的 age3 行写错（应为 h=6/8/9，我写成 5/7/9），
结球那路的 age4/age5 两行也偏小 1 —— 影响是**每龄最上面约 1 行可能空缺**（那正是"叶尖"位置），
所以**子代理交付后要按 §四 的实测表复核一遍顶端 1~2 行**。
