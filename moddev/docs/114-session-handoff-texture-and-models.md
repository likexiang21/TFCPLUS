# 114 · 对话交接：**贴图资源生成 + 方块模型修改**

> **本文是本对话的迁移交接。** 本对话的核心是**贴图资源的生成/重画**与**方块模型（几何 + UV + 贴图槽）的修改**。
>
> ⏭️ **后续轮次见 `docs/115-stick-pole-exact-fix-round49.md`**：本文 §八 的 **P0（44 张插棍贴图的杆）已在第 49 轮收口** ——
> 杆逐像素归位（identical 44 / differ 0）、原审计的盲区被修掉、canonical 表被独立复核；
> 并记下一条硬警告：**插棍的设计稿（`px/<sp>_age_N_stick.txt`、`px/sl-*`、`px/sh-*`）与落盘 PNG 已经分叉，插棍绘制链不可重跑**。
> - 🔗 另有 `docs/112-session-handoff-code-layer.md`：**代码层**（Java 注册 / 生成器脚本 / 工具链）的交接，
>   美术结论不在那里。
> - 🔗 `docs/110`（中心立方体三项修复）、`docs/111`（插棍 + 死资源审计）、`docs/113`（杆的逐像素真值规范）
>   是本对话的过程文档，本文是**汇总索引 + 继续工作所需的全部上下文**。
> - 🛑 **本文不修改 `AGENTS.md`**（用户明令：不要动主文档）。AGENTS.md 里与本对话相关的段落由**别人**在其流程里维护。
> - ⚠️ 本对话**全程未构建 jar、未做任何实机验证**（用户明令）。所有结论来自离线渲染器 + `read_image` 实看 + 脚本审计。

---

## 一、用户指令全清单（按时间顺序，含裁决）

| # | 原话（要点） | 我的执行 | 落地文档 |
|---|---|---|---|
| 1 | 继承最新文档的工作和进度，以及学习经验教训 | 读 `docs/105`~`109`、定基线 | `docs/106` |
| 2 | 自主推进（到上午十点 / 到下午六点，不要停） | 多轮并行推进贴图打磨 | `docs/106`~`109` |
| 3 | **「开始推进其他工作」+「你的莲座模型（包括原模型和渲染）重新进行审查，确保模型的合理性以及贴图的正确性」+「jar 先不构建」** | 逐几何渲染审查，抓出 4 个真 bug | `docs/105` |
| 4 | 「自己看看你的工作是否合格」 | 写自查，纠正"验收通过"的越权措辞 | `docs/107` |
| 5 | 🎯 **裁决①**：「结球类参考自己的模型 / 且 minecraft 本身不存在"球"，是方块来表现球，**所以请不要执着于画个球**」 | 结球 head 与莲座结果态改为**立方体** | AGENTS.md（他人维护）+ `docs/105` |
| 6 | 「现在叶子还是和整个叶球穿模，尽可能不要穿模 / 并且继续优化材质」 | 叶板移到立方体**外面**（零相交） | `docs/105` |
| 7 | **「叶球模型存在问题，进行修复 / 除了瓜方块以外的贴图继续进行打磨和优化」** | 修几何 + 大批贴图打磨 | `docs/109` |
| 8 | 「效果很好，继续推进其他内容」 | 插棍贴图 + sisal/agave + 死资源审计 | `docs/111` |
| 9 | **「俯视图能看出来叶子底部并没有汇集到一起，不像是一棵植物长出来的 / 之前强调你不要乱动UV导致像素放大和缩小，你没有听 / 以及中心球体不要六面用同一张贴图 / 继续优化」** | 几何 v7/v8（径向叶）+ UV 全量 1:1 + 立方体分面贴图 | `docs/110` |
| 10 | **「继续优化贴图，别忘了攀缘植物的贴图是双方块」** | 查出 17/44 张杆列错位，与上半格接不上 | `docs/111` §四 |
| 11 | **「加入新要求：杆的绘画必须和原版资源完全一致，像素严格对应。在此基础上重新绘制资源，以及别忘了参考现实原型」** | 从 TFC jar 取出杆的逐像素真值 + 审计 + 派单重画 | `docs/113` |
| 12 | 「写对话迁移文档…不要动主文档，核心是贴图资源生成和方块模型修改」 | **本文** | `docs/114` |

### 用户已明确的红线（违反过并造成返工）
- 🛑 **不许乱动 UV 造成像素放大/缩小** —— 任何面必须 `UV 跨度 == 该面世界尺寸`（见 §三.3）。
- 🛑 **中心立方体不许六面共用同一张贴图** —— 必须 top / side 分面（见 §三.4）。
- 🛑 **攀缘作物是双方块** —— 下半格我们的贴图，上半格 TFC 的 `tfc:block/crop/stick`；**两半的杆必须同列、同像素**。
- 🛑 **杆的绘画必须与原版资源完全一致、像素严格对应**（见 §三.6 / `docs/113`）。
- 🛑 **不要推翻重来**（chili 0~4 基线、fenugreek 是认可作品，不动）。
- 🛑 **TFC 是学审美的教材，不是照搬的目标**。
- 🛑 **看真实渲染图**来判定，不看设计稿/指标臆测。

---

## 二、一句话现状

结球 / 莲座两族共享几何的**几何与 UV 已全部改到位并通过全部校验**（`check-geom` 越界 0、uv 非 1:1 = 0/31）；
中心立方体已**分面贴图**；一大批贴图已按 1:1 采样区重画并逐批 `read_image` 复核；
**当前唯一的进行中工作**是把 44 张插棍贴图的**杆换成原版逐像素真值** + 植物按现实原型重画（3 个子代理在跑）。

---

## 三、方块模型修改（本对话核心之一）

> 所有模型都在 `moddev/tfcfarmingplus/src/main/resources/assets/tfcfarmingplus/models/block/crop/`。
> 改完**必须用 `.probe/texture-design/rr-review.ps1` 渲染真实几何**并 `read_image` 实看。

### 3.1 `leafball_age_2..5`（结球 5 物种共用几何）—— v5 → v7 → v8
**v5（球可见）**：cube 从 `y=1..7` 抬到"比内层叶板高 2"：
`age2 [6,7,6]→[10,10,10]` · `age3 [5.5,7,5.5]→[10.5,11,10.5]` · `age4 [5,7,5]→[11,12,11]` · `age5 [5,7,5]→[11,13,11]`。
> ⚠️ 改前**球一个面都看不见**（被 4 面叶板包成一口井，画面正中只有叶筒内部的阴影方块）。
> 我起初把那个暗方块**误读成"球顶面陷在坑底"** —— 教训见 §六.1。

**v7（叶从中心汇集）**：叶板改成**径向**（与已验收的莲座族同构）：`from.z==to.z` 绕 x 轴 / `from.x==to.x` 绕 z 轴，
**底板边落在旋转轴上（origin `[8,0,8]`）** ⇒ 底边不动、基部天然汇集于中心；立方体底面抬到 **y=8**。
| 龄 | 0° 层高 | 22.5° 层高（顶 / 外伸） | 45° 层高（顶 / 外伸） | 立方体 |
|---|---|---|---|---|
| age2 | 4 | 11（10.16 / 4.21） | 7（4.95 / 4.95） | 4×3×4 @ y8..11 |
| age3 | 5 | 12（11.09 / 4.59） | 8（5.66 / 5.66） | 5×4×5 @ y8..12 |
| age4 | 6 | 13（12.01 / 4.97） | 9（6.36 / 6.36） | 6×5×6 @ y8..13 |
| age5 | 8 | 14（12.93 / 5.36） | 10（7.07 / 7.07） | 6×6×6 @ y8..14 |
**零相交**：0° 层顶 ≤8 = 球底；22.5° 层在 y=8 处横向已偏到 `8+8·tan22.5=11.31 > 11`；45° 层顶 4.95~7.07 <8。

**v8（补对角方位）**：v7 只有 ±x/±z 四个方位（MC 元素一个只能有一个 rotation，无法叠加"倾斜+偏航"）。
补 **2 片对角竖直叶**（`axis:"y"` 转 ±45°，把落在 `z=8` 面的竖直叶偏航到对角平面），高 = 0° 层高（4/5/6/8，**必须 ≤8** 否则切到球）。
⇒ 元素数 11 → **13**，`faces=30/30`，俯视是 **8 向星芒**（证据 `px/V8-P70.png`、`px/V7B-P70-BIG.png`）。

### 3.2 `rosette_age_5_fruiting`（莲座 5 物种结果态）—— v6
- 果实立方体 `y=1..6` 时被 12 片叶板**从正中切成四块**、完全不可见；
- **两对逐字节完全相同的重复元素**（0° 层，会 z-fighting）；
- 修：0° 叶板 **h 12→10**（uv 随 `v=(16-h)..16` 改成 `v6..16`，保持 1:1）⇒ 所有叶板实际最高点 = 10；
  **删掉两对重复元素**（13 → **11** 元素）；立方体抬到 **`[6,10,6]→[10,15,10]`**（**用户裁决的 4×5×4 原样保留**），与所有叶板零相交。
- 全项目**只有这一个**共享模型带果实立方体（`<sp>_age_0..4_fruiting` 都 parent 到**不带果实**的 `rosette_age_0..4`）。

### 3.3 UV 1:1 全量修复（用户点名的"像素放大缩小"）
**规则**：一个面的 `UV 跨度` 必须等于该面在世界里的尺寸（1 贴图像素 = 1 格）。
自写审计（扫 `models/**` 2052 个 json、逐面比对）查得 **108 个面违规 / 11 个模型**：

| 模型 | 违规面 | 原写法 → 改法 |
|---|---|---|
| `leafball_age_2..5` | 24 | 立方体六面 `uv[0,0,16,16]` → **以贴图中心为锚、跨度=面尺寸**（见下表） |
| `rosette_age_5_fruiting` | 6 | 4×5×4 立方体 → 侧面 `[6,5,10,10]`、顶/底 `[6,6,10,10]` |
| `branch_fruit` / `_ripe` / `_unripe` | 12 / 24 / 24 | 按各自真实尺寸取中心矩形（6×6 / 4×5 / 3×4） |
| `sunflower_age_3/4/5_top` | 18 | 十字板 14.4 宽 → **整格宽 0..16**（`uv 16×16` 天然 1:1，**无需改贴图**）；花盘 14×12 → `uv [1,4,15,16]` |

**结球立方体 1:1 后的采样矩形**（以中心为锚，随年龄变大）：

| 面 | age2 | age3 | age4 | age5 |
|---|---|---|---|---|
| 侧面 `#2` | `[6,6,10,9]`（4×3） | `[5,6,10,10]`（5×4） | `[5,5,11,10]`（6×5） | `[5,5,11,11]`（**6×6**） |
| 顶面 `#1` | `[6,6,10,10]`（4×4） | `[5,5,10,10]`（5×5） | `[5,5,11,11]`（6×6） | `[5,5,11,11]`（**6×6**） |

⇒ **贴图必须按"中央 6×6 单独就是一个完整图案"来画**（更小的 4×3/5×4/6×5 也要说得通），
采样区之外永不显示。这也是为什么"球随年龄变大而图案不被裁掉"（证据 `px/LEAD-SPLIT-AGES.png`）。

### 3.4 立方体改成分面贴图（用户点名"不要六面同一张"）
| 模型 | 顶面 `#1` | 侧面 + 底面 `#2` |
|---|---|---|
| `leafball_age_2..5` | `<sp>_leafball_head_top.png`（新建） | `<sp>_leafball_head.png`（**沿用原文件名，不留孤儿**） |
| `rosette_age_5_fruiting` | `<sp>_rosette_fruit_top.png`（新建） | `<sp>_rosette_fruit.png`（沿用原名） |

- 基模型默认槽指共享的 `leafball_head_top` / `leafball_head`、`rosette_fruit_top` / `rosette_fruit`；
- **20 个结球包装模型**（5 物种 × age2..5）+ **5 个莲座结果态包装模型**已改成覆盖 `0/1/2` 三个槽。
- ⚠️ 改槽名时**基模型与 30 个包装模型必须一起核对** —— 我曾把基模型写成 `leafball_head_side`（实际决定沿用 `leafball_head`），
  `verify.ps1` 报 4 个"贴图不存在"，改回后才绿。

### 3.5 `rosette_age_2..5` / `rosette_dead_young` 去重
各有**2 个逐字节完全相同的重复元素**（0° 层）⇒ `rosette_age_2..5` 12→**10** 元素、`rosette_dead_young` 4→**2** 元素。
与 §3.2 修 fruiting 时发现的是同一个 bug。备份 `bak-rosette-dedupe-20260927/`。

### 3.6 攀缘作物的杆（进行中，规范见 `docs/113`）
- **结构（与 TFC 逐条一致）**：`stick=true, part=bottom → <sp>_age_N_stick`；`part=top → tfc:block/crop/stick`（贴图 `stick_top`，杆在 **x7/x8**、只占该贴图 y8..y15）。
- **杆的逐像素真值**（TFC 全部插棍贴图共用同一套 16 行木纹，三个颜色 `58481D/513E0C/3E2F0A`）：
  ```
  y0  58481D 3E2F0A      y8  58481D 3E2F0A
  y1  58481D 3E2F0A      y9  513E0C 3E2F0A
  y2  58481D 513E0C      y10 513E0C 513E0C
  y3  513E0C 513E0C      y11 513E0C 513E0C
  y4  513E0C 513E0C      y12 58481D 513E0C
  y5  58481D 513E0C      y13 58481D 3E2F0A
  y6  58481D 513E0C      y14 58481D 3E2F0A
  y7  58481D 58481D      y15 58481D 3E2F0A
  ```
  （y14 的 x7 是唯一在 TFC 全部贴图里都被植物盖住、推得的格子；其余 31 格是 TFC 原始像素。）
- **现状**：44 张里只有 **4 张**与原版逐像素一致；`995` 个杆像素中 `295` 个错。工具 `stick-pole-audit.ps1`。

### 3.7 本对话前半段（已压缩）的其它模型改动
| 项 | 内容 | 依据 |
|---|---|---|
| `blockstates/crop/kale.json` | **6 变体 → 12 变体**：`RosetteCropBlock` 一定有 `FRUITING`（`createBlockStateDefinition` 里 add(AGE, FRUITING)），原来只写 `age=0..5` ⇒ 6 个 `kale_age_N_fruiting` 模型**永远不显示**、`kale_rosette_5_fruiting` / `kale_rosette_fruit` 成了死资源 | `docs/105` §④ |
| 瓜类果实方块模型 | `winter_melon`/`cantaloupe`/`bottle_gourd`/`rotten_*` 原本是 `{"parent":"minecraft:block/melon"}` 且**没有任何贴图覆盖** ⇒ 在游戏里统统显示成 **vanilla 西瓜**；已改成**自包含立方体 + 各物种自己的 `_fruit_side`/`_fruit_top` 贴图** | `docs/105` |
| 莲座 15 个 `_fruiting` + 2 个枯死模型 | 曾长期停留在占位形态（原版小麦十字），已全量覆盖 | `docs/105` / 硬约束 §16 |
| `leafball_age_3` vs `age_4` | 参数曾**完全一样**（两龄是同一个模型）⇒ 现改成严格单调增长 | `docs/105` §⑤ |
> ⚠️ `MyCrops.java:35-38` 的 `maxAge` **只决定视觉阶段数**；`age_6` 是 `maxAge ≥ 6` 作物的**正常一龄**（3 个物种：brussels_sprouts / buckwheat / winter_melon），**不是"过熟期"**。
> 另有 6 个双段作物在**混合来源**（`_top` 手绘 09-27、`_bottom` 占位 09-26）—— 本对话已把 `sorghum`/`sunflower`/`cotton`/`hemp`/`pigeon_pea`/`ramie` 六者收口（见 §4.5）。

---

## 四、贴图资源改动（本对话核心之二）

> 判定标准一律是 **`read_image` 实看渲染图**（2D + 3D，双段要拼整株）。

### 4.1 结球 head（立方体贴图）—— 两轮 + 分面
| 轮次 | 内容 | 结果 |
|---|---|---|
| 第 1 轮 | 5 物种 `_leafball_head` | ⚠️ 部分是"中心苍白大板 + 绿边"的渐晕构图 ⇒ 渲成**白盒子/奶油方块**；broccoli 有 74 个 LUM<45 暗像素 ⇒ **4 个黑点** |
| 第 2 轮 | 改成"切开的白菜断面"同心环构图 | ✅ 4/5 通过；**napa 仍有 12 个 LUM=141 的镜像排布暗点** ⇒ 读作"白盒子上的脏点" |
| napa 定点 | 去掉那 12 个暗点，改成"**脉最亮 + 两侧叶肉淡黄绿**"的结构 | ✅ 通过（`pxBelow150 = 0`） |
| 分面 | 采样区变 1:1 后重画 `_head`(侧) + 新建 `_head_top`（5 物种×2=10 张） | ✅ 顶/侧**确实是两张不同的画**（cabbage 顶面同心包叶环 vs 侧面纵向包叶缝） |

### 4.2 结球 30 张叶层（5 物种 × age0..5）
- ✅ 复核：**30 张全部被模型引用**（不是死资源）；贴图行与几何对应正确（内层板读 `v8/7/6/5..16`、外层 `v11/10/10/9..16`，**底对齐 v16 = 地面**）。
- napa 6 张返工：原米白中脉是 **1px 近纯白竖条直顶叶尖** ⇒ 3D 里是"一排白色尖桩"；
  改成 **2~3px 宽、两侧各留 ≥1px 叶肉绿、颜色米白偏淡黄绿两档、最上 2~3 行留绿叶尖、数量降到 3~4 条且长短错开**。

### 4.3 生长序列断点（逐个修）
- `brussels_sprouts_age_3`：原来是 **3 色 + 零叶球**的另一套画风（序列断点）⇒ 按 age5 的**同一套 7 色**重画，**主茎锚 x7**、3 个叶球。
- `brussels_sprouts_age_4`：主茎 x7 列在 y10/y13 有缺口、y14 落在 x6 ⇒ **定点纠正只改 8 个像素**，现在 x7 连续。
- `common_bean_age_3` / `winged_bean_age_3`：仍是 09-26 占位图（3 龄土黄突变）⇒ 用同物种 age2 ∪ age4_bottom 的调色板重画（零新色）。

### 4.4 豆科四物种双段（`cowpea`/`pea`/`common_bean`/`winged_bean`）
- `cowpea`/`pea` 16 张（age0..3 单段 + age4..7_bottom）、`common_bean`/`winged_bean` 10 张（age0/1/2 + age4/5_bottom）。
- 接缝：`_bottom` 的 y0 行**逐像素照抄** `_top` 的 y15 行 ⇒ `seam-audit` **172 对齐 / 0 错位**。
- 我自建 **2D 整株拼图**（`_top` 在上、`_bottom` 在下，红线=方块交界）复核：改前"下段土黄缎带 vs 上段暗褐骨干"，改后**茎在红线处连续、颜色不再突变**。
- 遗留：`cowpea`/`pea` 的 `_top` 上半段是**深红近裸露的茎**；`common_bean`/`winged_bean` 的茎是**很直很显眼的淡金色 2px 柱**（都源于 `_top`，本轮被定为基准不许改）。

### 4.5 六个双段物种的整株收口（都是用"拼成整株"才发现的问题）
| 物种 | 发现的问题 | 处理 |
|---|---|---|
| `sorghum` | 下段是**4 根紫色竖条**（与向日葵同一张画）；上段是"绿网 + 紫斑" | 下段重画成绿茎+斜垂楔形叶+红褐叶鞘；上段重画成**红棕色紧密穗**；另由 Lead 定点修掉下段 y12 的 1px 主茎台阶 |
| `sunflower` | 下段同款紫条；花盘**悬空**接不上茎 | 下段重画；`_top` 补上缺失的茎 ⇒ 花盘**挂在茎上** |
| `cotton`/`hemp` | 下段与另两个物种**共用同一张画**；`cotton_top` 读作"3 根绿柱顶白方块"（像白栅栏） | 下段重画（棉花阔叶 / 大麻斜窄叶）；`cotton_age_5_top` 改成"叶腋里的白棉桃"；后续又修 `cotton_age_3/4_top`、`hemp_age_3/4/5_top` |
| `pigeon_pea`/`ramie` | 下段同样四物种共用；`ramie_top` 读作"绿柱上盖米白板" | 下段重画（木豆分叉灌木+三出复叶+黄花/褐荚；苎麻直立丛生+阔叶+叶背白+淡绿白穗）；`ramie_age_5_top` 改为"细茎+顶端花穗" |

### 4.6 枝干果实（7 树种 × ripe/unripe = 14 张）
- 背景：把立方体 UV 改成 1:1 后，旧贴图只显示中心一小块 ⇒ 渲成"棕/绿光板方盒"，其中一个显示成"棕底绿十字"。
- 按新采样窗重画（`*_ripe` 侧面 `u6..9,y5..9`、顶面 `u6..6..9`；`*_unripe` 3×4/3×3）。**未分面**（用户点名的是"中心球体"）。

### 4.7 莲座果实分面（5 物种 × side/top = 10 张）
采样区固定：侧面 `u6..10, v5..10`（4×5）、顶面 `u6..10, v6..10`（4×4）。
顶面画**果顶 + 中央蒂痕**，侧面画**上亮下暗的果皮**；5 物种色相身份不变（kale 绿 / sisal 灰褐 / cardoon 橄榄黄绿 / agave 灰绿土黄 / purslane 橙褐）。

### 4.8 `sisal` 与 `agave` 区分（14 张）
改前两者**既共用几何又几乎同色**，p28/p70 都分不出。现在：
- **sisal 剑麻** = **冷青蓝绿**、叶 1px 宽笔直狭长、**叶缘毫无杂点**、只有叶尖 1px 深刺；
- **agave 龙舌兰** = **暖灰橄榄**、叶 3px 宽、**每片叶中央一条贯穿的淡黄白纵纹带**、叶缘奶白齿点、叶尖 2px 粗刺。
- ⚠️ 关键事实：这两个物种**真正的活贴图是 `<sp>_rosette_N.png`**；`<sp>_age_N.png` / `_age_N_fruiting.png` 是**死资源**。

### 4.9 插棍 44 张（进行中，见 §三.6）
已完成一轮：11 个物种 44 张都改成"棕色杆 + 1~3px 小枝叶沿杆往上爬"，**与 TFC 同一套语言**、11 物种不再共用剪影。
正在做：**杆换成原版逐像素真值** + 植物按现实原型重画。

### 4.10 本对话前半段（已压缩）的其它贴图工作
| 项 | 内容 |
|---|---|
| 莲座叶层打磨（21 张） | `cardoon` 的中脉由"1/3 宽白带"改成**细中脉**；`agave` 由整行色带改成**交错的 1~2px 奶白短划 + 剑形叶**；`purslane` 由 11 行红柱改成**断续的红褐斑点**；`kale`/`sisal` 未动（证据 `px/ROSETTE-POLISH-R4-SP5-3D.png`、`px/ROSETTE-R1B-VS-BASE-CARDOON5.png`） |
| `chili` / `spinach` / 野生态贴图 | 前半段已结（见 `docs/106`）；野生态贴图确认是 **TFC 换色拷贝**，属待裁决范围 |
| `age_6` 语义核对 | 3 个物种的 `age_6` 是正常一龄，不宜当"过熟"处理 |
| 双段"混合来源"发现 | 6 个物种 `_top` 手绘 / `_bottom` 占位 ⇒ 本对话逐一收口（§4.5） |

---

## 五、工具（新增 / 复用）

| 工具 | 用途 | 备注 |
|---|---|---|
| `.probe/texture-design/stick-pole-audit.ps1` | **本对话新增**：逐格比对 44 张插棍贴图的杆与 TFC 真值；`-Fix` 可自动写入正确像素 | 本对话核心验收工具 |
| `.probe/texture-design/rr-review.ps1` | 渲染真实几何出带标签拼图 | `-Model` 必须传**数组**；`parent: block/crop` 的作物必须加 `-UseLab`；临时图**按 `-Out` 名隔离子目录** |
| `.probe/ref-tfc/render-tfc.ps1` | 渲染 TFC 原版资源 | 配合 `-AssetRoot` |
| 自写 UV 1:1 审计（内联脚本） | 扫 2052 个模型逐面比对 `UV 跨度 vs 世界尺寸` | 见 §三.3，结论 0 违规 |
| 各子代理产出的拼图工具 | `lg-stack.ps1`（双段拼整株）/`dbl-sheet.ps1`/`whole2d.ps1`/`ss-whole.ps1`/`head-split-2d.ps1`/`fruit-uvsheet.ps1`/`bf-*.ps1`/`bean-*.ps1` | 都在 `.probe/texture-design/` |
| **已导出到 `.probe/rr-lab/`** | `tfc/models/block/crop/stick.json` + `tfc/textures/block/crop/stick_top.png`（还有 `green_bean_age_3_stick`） | **双方块终于可以渲染验证**（此前子代理报"没有模型 json、无法验证"，卡点已解除） |

**渲染命令模板**：
```powershell
Set-Location 'D:\111\最强服务器\.minecraft\versions\Essential TerraFirmaCraft (TFC)\.probe\texture-design'
# 普通作物（parent: block/crop）必须 -UseLab
& .\rr-review.ps1 -Model 'cowpea_age_3_stick','hops_age_3_stick' -Out 'px\X.png' -Pitch 28 -Yaw 40 -UseLab
# 上半格的 TFC 杆
& .\rr-review.ps1 -Model 'tfc:block/crop/stick' -Out 'px\TOP.png' -Pitch 0 -Yaw 0 -AssetRoot '..\rr-lab' -Per 1 -Scale 30 -Cell 400
# 杆审计
& .\stick-pole-audit.ps1
```

---

## 六、踩过的坑与教训（本对话实测，按重要性）

1. 🛑🛑 **"几何合法" ≠ "玩家看得见"**。我确认了"零相交、不越界、面无退化"就收工，结果球被叶板挡得**一个面都没露**。
   而且我把"叶筒内部的阴影"**误读成"球顶面"**。⇒ **判断"某个体块看起来是什么"之前，先把它单独标定渲染一次**；
   判据要写成"画面上必须看到什么"，不能只写"几何约束满足"。
2. 🛑🛑 **跨方块/跨文件的资源，对齐锚点必须在派单时写成硬约束**。插棍那一轮我只写了"支架用棕色"，
   豆科组就把杆列当成物种区分手段（x4/x5、x9/x10、x6/x7）⇒ 上下半格的杆在世界里断成两截。
3. 🛑 **`@()` 数组字面量里不能写二元表达式**：`@($u0,$v0c,$u0+$W,$v0c+$H)` 被解析成 **6 个元素**，
   我这次**又犯了一次**（AGENTS.md 早记着这条）⇒ 先算到变量再放进数组。
4. 🛑 **`[int]` 是"四舍六入五成双"，不是截断**：`[int]9.5 = 10`、`[int]6.5 = 6`。
   算 `6.5..9.5` 的宽度得 4（实为 3）⇒ 16 个面白改一遍。**尺寸一律用 `[double]` 相减**。
5. 🛑 **`Set-Content -Encoding UTF8` 会给 JSON 加 BOM**（原文件无 BOM，MC 解析可能失败）⇒
   必须 `[System.IO.File]::WriteAllText($p,$t,(New-Object System.Text.UTF8Encoding($false)))` 并核首 3 字节。
6. 🛑 **`Bitmap.FromFile()` 会锁住文件** ⇒ 对同一路径 `Save()` 直接抛 `A generic error occurred in GDI+`，
   **而内存里的位图是改好的、极易误判为"已保存"**（我实测中招）。✅ 用 `MemoryStream` 载入 → 存到 `MemoryStream` → `WriteAllBytes` → **重新从磁盘读回复验**。
7. 🛑 **`System.Drawing` 的相对路径按 .NET 进程 cwd 解析，不认 PowerShell 的 `Set-Location`** ⇒
   一律传绝对路径；🛑 **绝不要对 `.probe/texture-design/px` 做批量移动/删除**（有子代理误移了 2706 个证据文件，虽已还原但风险极高）。
8. 🛑 **对设计稿网格做批量 `.Replace()` 会误伤其它行**：我想改 y12 的 `CBBBBEF`，结果 y5/y11 也变了、变成 **17 字符**（网格错位）。
   ✅ 正确做法：**用设计稿自己的调色板从 PNG 重新生成网格，再逐行 diff**（同时顺带证明稿与 PNG 逐像素一致）。
9. 🛑 **近白底上的孤立暗点一定被读成"脏"**，而且"12 个点亮度完全相同 + 完全镜像"本身就暴露是画上去的图案。
   浅色表面上表达结构要**靠"亮脉 + 微绿叶肉"的层次**，不能靠加深点。
10. 🛑 **死资源的两套命名**：模型引用的是 `X_age_N`（不是 `X_N`）；莲座作物的活名是 `<sp>_rosette_N`（`<sp>_age_N` 是死的）。
    **动手前先反查模型引用**，否则整个人力投在死文件上。全量审计见 §七。
11. **子代理无法用 `send_message` 通信**（报 `active teammate not found`）⇒ 派单时规格必须一次到位；
    改了校准条件只能等它交付后再补一轮。
12. **并发子代理会互相"顺手修"对方的文件**，也会误建文件（有一次误建 4 个 `_age_3_{bottom,top}.png` 后自行删除）。
    ⇒ 交付时必须**逐条核对"改动清单 vs 实际时间戳"**并检查孤儿文件。
13. **证据图会过期**：子代理可能在我取证之后又迭代一次。**核对"我的证据图 mtime" vs "贴图 mtime"**，
    过期就重渲（本对话真实发生过：`LEAD-STICK-A3-3D.png` 用的是葫芦科第一版）。
14. **PowerShell 5.1 的 `-f` 参数里不能写 `if` 表达式**（`"...{0}" -f (if(...){}else{})` 报 "The term 'if' is not recognized"）⇒ 先算到变量。
15. **中文引号/中文标点写在双引号字符串里会破坏解析**（`"…"确实是…"…"` 报 `Unexpected token`）⇒ 用单引号或改写。
16. **`Select-Object -First N` 会掐断上游脚本**（`audit-all.ps1` 结尾才 `Export-Csv`），截断输出会让 CSV 不更新。

---

## 七、死资源审计（第一次做，结论很重要）

扫 `models/**` 全部 json 的贴图引用，与 `textures/block/**` 的 PNG 对账：

| 指标 | 数值 |
|---|---|
| `textures/block` 下 PNG | **2083** |
| 被模型引用 | 1337 |
| **无任何模型引用（死贴图）** | **746（36%）** |

分类：`crop/X_N` 旧命名家族 **397** · 其他 crop **179**（如 `<sp>_age_N_fruiting`、`amaranth_4_bottom` 这类"活名之外的名字"）·
非 crop 88 · `crop/X_age_N` 54 · 旧 `_stick` 28。

🛑 **本对话一张都没删**：硬约束规定"从 `src/main/resources` 删除文件后必须 `gradle clean build`"，而用户明令不构建。
⇒ **等用户允许构建时可以一次收回 36% 的贴图体积**。

---

## 八、未完成项（按优先级）

| 优先级 | 项 | 状态 |
|---|---|---|
| **P0** | **44 张插棍贴图的杆换成原版逐像素真值 + 植物按现实原型重画** | 进行中：2 个子代理在做 27 张（葫芦科 16 / hops·yam·落葵·四棱豆 11）；另 1 个在修 17 张的杆列（pea/cowpea/common_bean/yam/malabar_age3），**完成后再统一跑 `stick-pole-audit.ps1` 要求 `differ: 0`** |
| **P1** | **746 张死贴图清理** | 阻塞：需用户允许 `gradle clean build` |
| **P2** | `kale` 与 `cardoon` 区分度复核（都偏绿，cardoon 有灰绿尖刺、kale 有淡色卷叶，目前"尚可"） | 未做 |
| **P2** | `branch_fruit*` / `sunflower` 的贴图按 1:1 采样区**已重画/已确认**，但**未分面**（六面同一张） | 若用户要求"所有球都分面"，需再做 3×2 张 |
| **P3** | 尚未逐像素重画的物种（`audit-all` 未达标榜上除 stick 家族外的其余项） | 未盘 |
| **P3** | `leafball_age_0/1` 仍是 4 片 ±45° 放射（无球，与 v7/v8 同源但层数少） | 观察项，未改 |

---

## 九、验证命令速查（本对话每次都跑）

```powershell
$v = 'D:\111\最强服务器\.minecraft\versions\Essential TerraFirmaCraft (TFC)'
Set-Location "$v\.probe\texture-design"

# 几何 / UV
& .\check-geom.ps1 -Path "$v\moddev\tfcfarmingplus\src\main\resources\assets\tfcfarmingplus\models"
#   → 期望："越界模型: 0"、"uv 非 1:1 的模型: 0 / 31"
& .\face-axis-audit.ps1        # → "elements with a mis-matched face type: 0"
& .\seam-audit.ps1             # → "对齐 172 / 错位 0"
& .\audit-all.ps1              # → "尺寸非 16×16 : 0"
& .\stick-pole-audit.ps1       # → 目标 "identical: 44 / differ: 0"（当前 FAIL）

# 资源交叉引用
Set-Location "$v\moddev\tfcfarmingplus"; & .\tools\verify.ps1
#   → "结果: 全部交叉引用有效，未发现问题"
```
**渲染实看**：`rr-review.ps1`（见 §五模板）→ 必须 `read_image`；
结球/莲座要**同时看 p28 与 p70**，双段要**拼成整株**，插棍要看**双方块装配**。

---

## 十、可复用资产与证据索引

- **备份目录**（都在 `.probe/texture-design/`）：
  `bak-leafball-geom-v5-20260927/` `bak-leafball-geom-v7-20260927/` `bak-leafball-geom-v8-20260927/`
  `bak-rosette-fruiting-v6-20260927/` `bak-rosette-dedupe-20260927/`
  `bak-head-polish-20260927/` `bak-head-correct-20260927/` `bak-head-split-20260927/`
  `bak-napa-leaf-20260927/` `bak-napa-head-20260927/`
  `bak-bsseq3-20260927/` `bak-looseends-20260927/`
  `bak-legume-20260927/` `bak-bean-20260927/` `bak-dbl-*/`
  `bak-cotton-hemp-top-20260927/` `bak-sorghum-top-20260927/` `bak-sorghum-stemfix-20260927/`
  `bak-fruit-split-20260927/` `bak-branchfruit-1to1-20260927/`
  `bak-stick-*/` `bak-sisal-agave-20260928/`
- **关键证据图**（`.probe/texture-design/px/`）：
  - 结球：`LEAD-BALL-BIG28.png`（改前·球不可见）· `LEAD-BALL-V5-BIG28.png` / `V5-AGES.png` / `V5-TOP.png` ·
    `V8-P70.png`（8 向星芒）· `LEAD-BALL-V5-AGES.png`
  - UV/分面：`LEAD-SPLIT-P70.png` / `-P28.png` / `-AGES.png` · `LEAD-FRUIT-P60.png`
  - 莲座：`LEAD-ROSETTE-FRUIT.png`（改前·果实被切四块）· `LEAD-ROSETTE-FRUIT-V6.png` · `LEAD-ROSETTE-A5.png`
  - sisal/agave：`LEAD-SA-AFTER.png` / `-P70.png` · `SA-2D-AGES.png`
  - 双段整株：`LEAD-WHOLE-LEGUMES.png` · `LEAD-SS-WHOLE.png` / `-AFTER.png` · `LEAD-CH-WHOLE-BEFORE.png` / `-AFTER.png` · `LEAD-PR-WHOLE.png`
  - 插棍：`LEAD-TFC-STICK-REF.png`（TFC 教材）· `STICK-RECON.png`（改前 6 物种同一张）· `LEAD-STICK-TWOBLOCK.png`（双方块真样子）· `LEAD-STICK-MISALIGN-PROOF.png`（杆错位铁证）· `LEAD-STICK-A3-FINAL.png`
  - 序列断点：`LEAD-BS3-CHECK.png` · `LEAD-LOOSE-BEAN.png` / `-BS.png` · `LEAD-NAPA-CHECK.png`
- **设计稿**：各批次在 `.probe/texture-design/px/` 下按 `<批名>/` 或前缀归档（`headsplit/`、`napa_leaf/`、`bf1to1/`、`sl-*`、`sh-*`、`sl-*`、`sa-*` 等）。

---

## 十一、给接手者的第一句话

**先跑 §九 的五条命令拿基线，再跑 `stick-pole-audit.ps1`。**
当前唯一必须收口的是**插棍 44 张**（杆 = `docs/113` 那张表，植物 = 现实原型，验收 `differ: 0` + 双方块拼图红线对齐）。
其余都已通过校验，**不要回退**；`docs/110`/`111`/`113` 里有每一步的判据与证据图名。
