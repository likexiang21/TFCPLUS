# 106 · 第 48 轮小结与交接（2026-09-27 晚）

> ➡️ **本文之后还有一轮（第 48 轮尾）：`docs/109-round48-tail-geometry-v5-and-texture-findings.md`**
> —— 结球几何 **v5**（把 head 立方体抬成植株最高器官，因为 v4 里球被叶板挡得**一个面都看不见**）
> + 结球 head / napa 叶层的实看发现。**先读 109 再看本文的几何结论**（本文记的是 v4 状态）。

> 本轮用户两条指令：
> ① **「开始推进其他工作」** ② **「你的莲座模型（包括原模型和渲染）重新进行审查，确保模型的合理性以及贴图的正确性」**
> ③ 附加：**「jar 先不构建」**（本轮所有改动**都没有构建、没有实机验证**）

---

## 一、一句话状态

莲座（5 物种）与结球（5 物种）两套共享几何的**4 个真 bug 已修并逐项渲染实看验收**；
`chili` age3、`spinach` 全龄、`age_6` 语义、野生态贴图来源 4 项工作已结；
**5 路贴图重画子代理在途**（莲座 / 结球 / 野生态 / winter_melon age6）。
详细审查报告见 **`docs/105-rosette-and-leafball-geometry-review.md`**。

---

## 二、本轮已落盘（可直接复查）

### 2.1 几何（Lead 亲自改 + 亲自渲染验收）

| 文件 | 改动 | 备份 |
|---|---|---|
| `models/block/crop/rosette_age_0..5.json`、`rosette_age_5_fruiting.json`、`rosette_dead{,_young}.json` | ① E/W 板的面从 `north/south` 改成 **`east/west`**（原先是零宽度退化面 ⇒ **一半叶片从未渲染**）；② UV 改 **1:1 底对齐** `v=(16-h)..16`；③ N/S 读贴图左半、E/W 读右半；④ 果实立方体 → **交叉板球** | `.probe/texture-design/bak-rosette-geom-20260927/`（15 个原文件，**首次备份不会被覆盖**） |
| `models/block/crop/leafball_age_0..5.json` | 莲座 v1 遗留的水平零厚度板（y=0 与耕地共面 + 越界 −2..18）→ **竖直面片 v2** + 交叉板球 head；**每龄严格单调** | 同上 |
| `blockstates/crop/kale.json` | 6 变体 → **12 变体**（补 `fruiting` 维度；`RosetteCropBlock` 一定带 FRUITING） | 同上（`blockstate_kale.json`） |
| `models/block/crop/leafball_age_2..5.json`、`rosette_age_5_fruiting.json` | **按用户裁决把"交叉板球"改回立方体**（= 我们自己的 v1 模型）：leafball head = 4×3×4 / 5×4×5 / 6×5×6 / 8×7×8，莲座果实 = 4×5×4；六面整张贴图 `uv[0,0,16,16]` | 同上（`bak-rosette-geom-20260927/` 里保留的是**v3 原版**，v1 立方体规格从备份 JSON 读出） |

⚠️ 对用户裁决的理解与执行边界（**写清判断依据，便于复核**）：
- 用户说「结球类参考自己的模型」+「MC 没有球、用方块表现球」⇒ **head/果实改回立方体**（我们 v1 就是立方体）；
- 但 **v1 的叶层是"水平零厚度板"**（侧视不可见 + 与耕地共面 + 越界），那是**真 bug**，
  所以**叶层保留本轮修好的"竖直面片"**，不回退 —— 这一点用户没有点名否定，且回退会复现已修的缺陷。
- `rosette` 的果实同理改回立方体（4×5×4）。

校验（`check-geom.ps1`）：**越界 0**；莲座/结球 UVBad **0**（修复前 18/18 模型不合格）。

### 2.2 贴图（子代理产出，Lead 逐份 `read_image` 验收）

- **`chili_age_3.png`**（7 轮）：p28 下 age2→3→4 是同一株长大；主茎锚在 x7（dump 实测）。
- **`spinach_age_0..5.png` + 野生 + 枯死**（9 张，11 轮）：六龄序列 = 两片贴底子叶 → 真叶 → 开展 → 抽薹 → 散布黄绿花穗；3D 能透光。

### 2.3 结论级发现（都写进了 `docs/105`）

| # | 发现 | 级别 |
|---|---|---|
| R-A | 莲座 E/W 六片叶的面类型错配 ⇒ **游戏里只有一半叶片**（`faces=12/24` → 修复后 24/24；负对照抓到 6 个元素） | 🛑 P0 |
| R-B | `kale` blockstate 缺 `fruiting` 变体（6 个模型 + 2 张贴图永远不显示） | 🛑 P0 |
| R-C | 莲座 UV 纵向压缩（同一贴图在 12 片叶上有 3 种压缩率） | ⚠️ P1 |
| R-D | `leafball_age_*` 是莲座 v1 遗留，被 **5 物种 × 6 龄 = 30 个模型**用着：y=0 共面 + 侧视不可见 + 越界 | 🛑 P0 |
| R-E | 果实/叶球是立方体贴整张球面图 = "贴着圆点的箱子" → 交叉板球 | ⚠️ P1 |
| R-F | 莲座/结球贴图是程序化与占位产物（`sisal` 还带洋红）⇒ 已重画在途 | ⚠️ P1 |
| R-G | 死资源：`kale_leafball_*` 7 + `leafball_leafball_*` 7 + `dead_crop/dead_rosette*` 2 + **`dead_crop/kale` 三件套**（Java 里没有 `DEAD_KALE` 方块） + `leafball_0..5`/`leafball_head`（永不显示） | ℹ️ P2（**不删**：删了必须 `gradle clean build`） |
| R-H | **野生态贴图**也是 TFC 换色拷贝：`cardoon/agave/purslane/sisal` = `beet_wild`（**带甜菜红根**）、`lettuce`=`onion_wild`、`cauliflower`=`cabbage_wild` | ⚠️ P1（重画在途） |
| ✅ | `age_6` 语义结案：`MyCrops.java:35-38` 写明 `maxAge` 只决定阶段数，`age_6` 是 **maxAge≥6 作物的正常龄**（86 个 blockstate 里 max=5/6/7 分别 59/3/24，**无缺口**） | 结论 |
| ✅ | 野生态外围草贴图**确实是 TFC 原版**（`#1` 未覆盖 → `tfc:block/crop/wild_crop_grass` + tint） | 硬要求已满足 |
| ✅ | 孤儿模型 **0**；面类型错配 **0**（172 个元素）；`verify.ps1` 全绿（blockstate 475 / 模型 2052 / 掉落表 475 / 物品模型 429） | 结论 |

---

## 三、本轮新增工具（都在 `.probe/texture-design/`）

| 工具 | 用途 |
|---|---|
| `rr-review.ps1` | 用**真实几何**批量渲染带标签检查图（`-AssetRoot` 可指向任意资源根，如 `.probe/lab-wild`）；`-Model` 要传**数组** |
| `face-axis-audit.ps1` | 全量扫「零厚度轴 vs 面类型」错配（判据：x 零厚度只能用 east/west…） |
| `rosette-geom-v4.ps1` | 可复跑的莲座/结球几何生成器（默认 dry-run，`-Apply` 才落盘；备份只写一次） |
| `.probe/lab-wild/` | 从 TFC jar 导出的野生态几何沙盒（`tfc:block/wild_crop/crop` + `wild_crop_grass` + 我方 wild 模型/贴图副本） |

⚠️ **流程教训**：几何**必须先定稿、并用脚本从落盘 json 里实测导出 UV 表**，再把表贴进贴图子代理的 prompt。
本轮我手算的表有两行错（莲座 age3 应为 6/8/9、结球 age4/age5 各偏小 1），而 subagent **不是 teammate**
（`send_message` 报 `active teammate not found`）⇒ **开工后无法更正**，只能事后按实测表复核顶端 1~2 行。

⚠️ **工具并发教训**：`rr-review.ps1` 原先把所有调用的中间 PNG 都放在同一个 `px\_rr\`，
Lead 与 4 路 subagent 同时调用时**互相删文件**（实测：拼图阶段 `FromFile` 抛 `FileNotFoundException`，
一张 15 格的中间检查图报废）。已改成**按输出名隔离子目录** `px\_rr\<Out 名>\`。
⇒ 凡"多个 agent 会同时跑"的工具，临时产物一律按调用者/输出名隔离。

⚠️ **工具缺陷修复**：`rr-review.ps1` 的 `-AssetRoot` 默认指向 src，而 vanilla 父模型
`minecraft:block/crop` **不在 src 下** ⇒ 所有 `parent: block/crop` 的普通作物（chili / spinach /
winter_melon / brussels_sprouts / buckwheat … 绝大多数物种）都渲染失败（`model not found or has no elements`）。
已新增 **`-UseLab`**：把请求的模型 ∪ 其 parent 链 ∪ 它们引用的贴图**镜像到 `.probe\rr-lab`**
（那里放一份 vanilla `crop.json` 的拷贝），再按真实模型 id 渲染。
🛑 它**只读** `.probe\lab-assets`（那份 09-26 14:37 覆盖前的快照必须保持原样），
写入的是自己的 `.probe\rr-lab`。烟测证据 `px/USELAB-TEST.png`（wm 4/5/6 + brussels 6 + buckwheat 6 全部渲染成功）。

### 3.1 中间态观察（19:15 实看，供最终验收对照）

- 莲座 5 物种（`px/ROSETTE-MIDCHECK-3D.png`，5 物种 × age0/3/5）：
  kale=绿叶丛、cardoon=灰绿宽叶、agave=青灰细长放射叶、sisal=银灰尖叶，**都已读得出是植物**；
  ⚠️ `purslane` 的红色偏重（age0 上有一块很显眼的"红色 V 形"），需要它自己再压。
- 结球 5 物种（`px/LEAFBALL-MIDCHECK-3D.png`）：形态是"外叶 + 中心球"，方向正确；
  ⚠️ 需要盯三点：`napa_cabbage` 中心**白得过多**（像白纸团）、`broccoli` 中心球**颜色太浅**
  （西兰花应为深绿）、`age0` 太小且 5 物种难以区分。

---

## 四、在途 / 待办

**在途（4 路贴图子代理）**
1. ✅ **已完成并验收**：莲座 5 物种 × (6 龄 + `_5_fruiting` + 果球) = **40 张**（4 轮迭代）。
   Lead 自出验收图 `px/ROSETTE-ACCEPT-3D.png`（5 物种 × age0–5，p28）、
   `px/ROSETTE-ACCEPT-FRUIT.png`（5 个结果态）、`px/ROSETTE-ACCEPT-TOP.png`（俯视）并 `read_image`：
   **每行从左到右逐龄变大、是同一株的延续**；5 行颜色与叶形一眼可区分
   （深冷绿皱叶 / 橄榄灰宽脉 / 蓝灰+米黄横带 / 亮黄绿+暗红茎 / 冷灰细尖叶）；
   叶尖逐个分开、能看见中脉，**不再是实心方板**；`sisal` 的洋红已彻底消失（实测红像素 0）。
   结果态的果球从 p28 看是**圆的**。⚠️ 遗留（不阻塞）：`purslane` 的红茎偏粗、
   `cardoon`/`agave` 叶面细节密度仍不如 TFC `sword_fern`、果球在 agave/sisal 某些角度读作"十字板"。
2. ✅ **已完成并验收**：结球 5 物种 × (6 龄 + head 球) = **35 张**（6 轮迭代）。
   Lead 自出 `px/LEAFBALL-ACCEPT-3D.png`（age0/3/5，p28）、`LEAFBALL-ACCEPT-SIDE.png`（p5）、
   `LEAFBALL-ACCEPT-TOP.png`（p70）并 `read_image`：**5 个中心球一眼可区分**
   （cabbage 浅绿圆 / lettuce 黄白圆 / napa 奶白**竖长** / cauliflower **纯白颗粒** /
   broccoli **深绿粗粒带孔**）；age0 小苗 → age3 叶丛+球 → age5 更大更满，是同一株延续；
   叶球已从"立方体箱子"变成**交叉板球**。
   ⚠️ 子代理的关键发现：**叶层贴图的中心列必须留空**——贴图左半 x0..7 映射到世界 x 12→5，
   而 x=8 正是 head 所在，中心列画了叶子就会把球盖死（它前两版"折纸风车/凤梨"的根因）。已写进
   下一次重画贴图时必须遵守的约束。遗留：叶片仍偏"向上抱合的绿板"，cabbage 与 broccoli
   远景剪影相近（靠球色区分）。
3. ✅ **已完成并验收**：`winter_melon_age_6`（7 轮）——原来是"上半整片黄 + 右下米白瓜块"，
   现在是**一丛深绿到中绿的叶子 + 外缘零星枯黄老叶 + 一条穿过的藤**，`opaque=156 / 9 色 /
   近白像素 0`（确认无瓜）。Lead 用 `px/USELAB-TEST.png` 实看 age4→5→6 是同一丛叶子连续放大。
4. ✅ **已完成并验收**：9 张野生态贴图（莲座 5 + 结球 4，4 轮）。Lead 实看
   `px/WILD-ACCEPT-9x2.png`（上排=新野生、下排=对应成熟态）：
   9 个剪影互不相同（深绿穹顶 / 亮灰绿宽扁丛+白脉 / 三束灰绿厚叶 / 极矮贴地丛+暗红细茎 /
   灰白细长纵纹剑叶 / 中央亮绿球+蓝绿叶 / 中央近白圆球+竖立包叶 / 明黄绿蓬松球 / 奶白长筒+深绿外叶），
   **与各自成熟态同色同形**；**甜菜红根已消除**（红像素审计：8 张 = 0，`purslane` 只剩 5 px 断续暗红细茎，
   与它成熟态的红茎同源；洋红全 0）。
   遗留：顶视 p70 下 cauliflower/napa 的白球被 4 片板切过（几何决定）、LUM 两端
   （kale 101 / lettuce·napa 153–161，按植物真实色相保留未拉平）、野生几何 Ymin=−1（TFC 原版亦然）。

## 4.2 用户第 48 轮追加裁决后的**新一轮在途**（2026-09-27 晚）

| 任务 | 状态 |
|---|---|
| **几何**：head/果实"交叉板球" → **立方体**（leafball 4×3×4 / 5×4×5 / 6×5×6 / 8×7×8，莲座果实 4×5×4） | ✅ Lead 已落盘并验证（越界 0 / 面类型错配 0） |
| **10 张贴图重画**：`*_leafball_head.png` + `*_rosette_fruit.png` 从"圆球 + 透明"改成**不透明方块表皮**（透明会把立方体挖成镂空盒子） | ✅ 已落盘；Lead 实看 `px/LEADCHECK-CUBEHEAD.png`（cabbage age2→5 的立方体**逐龄变大**、cauliflower 是白花球、broccoli 是深绿花球）+ `px/LEADCHECK-FRUITCUBE.png`（莲座 5 果实立方体**颜色各异且都可见**）⇒ **方块读起来是叶球/果实，不再是镂空盒** |
| **瓜类去瓜**：`winter_melon_age_4/age_5`（实测有白色瓜块）、`bottle_gourd_age_4/age_5`（米白块）；`cantaloupe` 实测无瓜但要复核 | ✅ 已完成并验收：改 4 张（**只换颜色、轮廓未动**），18 张逐龄扫描后**只剩 1 个橙花像素**；Lead 实看 `px/MELONFIX-FINAL-wm.png` / `-cg.png` 确认藤上无瓜。⚠️ 子代理还发现我漏看的 **`cantaloupe_age_5` 是"左右完全镜像的蘑菇树"**，已按 age4 的株型重画 |
| **⚠️ 新发现（由用户的"瓜藤+瓜方块"提示查出）**：`crop/<sp>_side.png` 曾被误判为"瓜本身" | ⚠️ **那个判断是错的**：查 TFC 源码后确认 `side` 属性 = 「这一侧的方块是果实方块」（`SpreadingCropBlock.java:122`），TFC 原版 `melon_side.png` 画的是**斜向藤叶** ⇒ `crop/<sp>_side.png` 该画**藤**。已改回藤（3 张），Lead 实看 `px/LEADCHECK-VINESIDE-FINAL.png`（yaw90 正对板面）：**波浪藤+叶簇 / 斜藤三叶 / 斜藤两叶**，全部读作藤叶 |
| 🛑🛑 **P0：果实方块在游戏里显示的是 vanilla 西瓜** | `models/block/{winter_melon,cantaloupe,bottle_gourd,rotten_*}.json` 原本只有 `{"parent":"minecraft:block/melon"}`、**没有任何贴图覆盖** ⇒ 冬瓜/哈密瓜/葫芦/**三种腐烂瓜全是同一个 vanilla 西瓜外观**。已由 Lead 改成**自包含立方体模型** + 各物种自己的 `_fruit_side`/`_fruit_top` 贴图；`rotten_*` 三个模型也已指到新画的腐烂贴图。Lead 实看 `px/LEADCHECK-FRUITBLOCKS-FINAL.png`：**上排=深绿带霜的冬瓜 / 黄褐网纹的哈密瓜 / 纵向奶油条纹的葫芦，下排=各自压暗转褐+霉斑+裂缝的腐烂版**，六块都实心不镂空、正常与腐烂可辨 |

⚠️ 这两批做完后仍要：**重出三视角验收图**（p28/p5/p70）并 `read_image`，
确认"方块读起来像叶球/果实"且"藤上确实没有瓜"。

## 4.3 用户第二次点名「叶球模型存在问题」+「除瓜方块外继续打磨」（2026-09-27 深夜）

### ✅ 叶球几何已修（Lead 亲自诊断 + 修 + 实看）
**诊断**（证据 `px/DIAG-CABBAGE-AGES.png`、`px/DIAG-CABBAGE-VS-TFC.png`）：原来的 head 是
`from y=0` + age5 `8×7×8` ⇒ 渲染出来是「**一个坐在地上的方盒，顶上插着几片叶**」——
球在下、叶冠在上，叶只在球的**顶部**冒头。

**修法**（`rosette-geom-v4.ps1`，已 `-Apply`）：
- head/果实**抬高到 `from y=1`**（不再坐地）
- age5 head 由 `8×7×8` 缩到 **`7×6×7`**（其余龄 4×3 / 5×4 / 6×5 不变）
- 叶层不动（仍从 y=0 的竖直面片）
⇒ 叶现在从**球的下方与四周**露出来（证据 `px/FIXED-LEAFBALL-3D.png`、`px/FIXED-LEAFBALL-P5.png`）。
校验：越界 0、面类型错配 0。**判据（已写进 AGENTS.md）：叶要在球的下方与四周露出来，不是只在球顶上冒头。**

### 🔄 三路并行打磨（用户：除瓜方块以外的贴图继续打磨优化）
| 路 | 范围 | 目标 |
|---|---|---|
| A | 结球**叶层** 30 张（`<sp>_leafball_0..5`，不含 `_head`） | 叶层现在"向上抱合成一整块绿板" → 要读得出**几片可分辨的外层叶**；cabbage 与 broccoli 的远景剪影要拉开 |
| B | 莲座**叶层** 35 张（`<sp>_rosette_0..5` + `_5_fruiting`，不含 `_fruit`） | ✅ **已完成并验收**（改 21 张：cardoon/agave/purslane；kale/sisal 保留）：<br>① cardoon 的根因是叶面每行重复同一段 `BAWA` 循环 ⇒ 渲染成"平涂绿 + 占叶宽 1/3 的宽白带"；改成**每行只亮一列、逐行摆动**的细纵脉（证据 `px/ROSETTE-R1B-VS-BASE-CARDOON5.png`：左新=细脉+碎色阶，右旧=宽白带）<br>② agave 的米黄原本是**整行横带**（其余行全平）+ 2×2 黑洞；改成 **1–2px 短横划逐行错开** + 叶尖端刺 + 叶形收窄成剑形<br>③ purslane 原本在 x3 列**连续 11 行红**（3D 下是两根红棒）；改成**断续红褐点**（每列最多 2 个且不相邻行、红总量降到约 1/6）<br>Lead 实看 `px/ROSETTE-POLISH-R4-SP5-3D.png`：5 物种仍一眼可分（饱和深绿皱叶 / 银灰绿细纵脉 / 青灰+米黄横斑剑叶 / 亮黄绿+红褐点 / 灰白细纵纹） |
| C | 4 处具体缺陷 | `brussels_sprouts` age5→6 断裂（细杆→圆球）、`buckwheat` age5→6 断裂（斜生→红褐棍）、`winter_melon_age_3` 中央浅竖缝、`cantaloupe_age_4` 主茎 1px 漂移 |

🛑 三路都**明令禁止**触碰 `*_fruit_*.png`（瓜方块，用户排除）与 `<sp>_leafball_head.png` / `<sp>_rosette_fruit.png`（刚验收）。

## 4.4 🔍 用时间戳做全量筛查，又发现一类系统性问题：**双段作物上下半段来源不一致**

**方法**：把每个物种的 `*_age_*.png` 按修改时间分类——"09-26 14:36~14:39 那批"= 占位换色拷贝，其余 = 手绘/恢复版；
再与"被模型真正引用"的贴图取交集（排除死贴图）。

**结果**：
- **混合来源的物种 16 个**（同一条龄序列里既有占位又有手绘）；
- 其中 **10 个是双段作物**，且**占位图集中在 `_bottom` 一侧**（`_top` 是 09-27 的恢复版）：
  `cotton`(5/9 占位)、`cowpea`/`pea`/`common_bean`/`winged_bean`(各 12/16)、
  `pigeon_pea`/`ramie`/`sorghum`/`hemp`(各 6/9)、`sunflower`(6/15，其中 6 张是活贴图)
  ⇒ **约 77 张活版贴图仍是占位图**；
- 「全部龄都是占位」的 6 个物种（agave / broccoli / cardoon / napa_cabbage / purslane / sisal）
  的 `_age_N.png` **其实是死贴图**（它们的活贴图是 `_rosette_*` / `_leafball_*`），无影响。

**实看确认**（`px/HALF-CHECK-1.png`，cowpea/pea/common_bean 的 bottom vs top 并排）：
两者虽然都是"绿叶 + 褐色茎"，但 **`_bottom` 的茎是黄褐色、`_top` 的茎是红褐色** ⇒
拼成一株时**茎色在腰部突变**。`seam-audit` 查的是"接缝行像素是否对齐"，**查不出这种风格差**。

**处置**：已派两路（每路 2 物种 × 6 张）以 `_top` 为基准重画 bottom，要求**拼成整株再验收** + 收尾跑 `seam-audit`；
剩余 6 个物种（cotton / pigeon_pea / ramie / sorghum / hemp / sunflower）待前几路完成后再铺开。
⚠️ 旧版快照（`bak-lab-20260927`）里**几乎没有**这些 `_bottom`（它只含被 `lab-render` 渲染过的贴图）⇒ **无法恢复，只能重画**。

### 4.1 本轮实测到的**其他物种缺陷**（不在本轮改动范围，留作下一轮入口）

| 物种 | 现象（真实几何 p28 实看） | 证据 |
|---|---|---|
| `winter_melon` | **`age_5` 右下角仍有一块米白色板**（age_4 只有左下一个小白角、新 age_6 已无）⇒ 与旧 age_6 是同一处问题，建议一并清掉 | `px/USELAB-TEST.png`、`px/WM6-GEO-FINAL.png` |
| `brussels_sprouts` | **age_5 = 两根竖直、几乎光秃的绿杆**（中下部大片空白）→ **age_6 = 一大团亮绿密叶球**，中间没有过渡，**不是同一株的延续** | `px/WM6-GEO-FINAL.png`、`px/USELAB-TEST.png` |
| `buckwheat` | **age_5 = 斜生植株（白花簇 + 棕褐茎 + 大量亮绿叶）→ age_6 = 几根竖直红褐粗杆 + 顶部残白 + 底部两块小绿叶**，叶片几乎消失；3D 下就是"几根红褐色棍子" | 同上 |
| 瓜类**野生**贴图 | `bitter_melon` / `bottle_gourd` / `cantaloupe` / `chayote` / `loofah` / `snake_gourd` 的 `wild_crop/*.png` 仍是 **09-26 14:37 的占位换色拷贝**（`winter_melon` 已于本轮重画）。⚠️ 野生瓜类是普通 `WildCropBlock`、**没有瓜方块机制**，所以野生贴图**画瓜是合理的**（与攀爬类同理），只是"占位图质量"待重画 | `wild_crop/*.png` 时间戳 + `MyWildCrops.WILD_WINTER_MELON = wild("winter_melon")` |

⇒ 三处都属于 `docs/104` §11.4 那类"最高龄与前一龄接不上"的问题，且**都不是本轮用户点名的范围**，
一句话即可复现（用 `rr-review.ps1 -UseLab` 渲染 `age_5` 与 `age_6` 并排看）。

## 四、本轮跑过的**全部**校验与结果（收尾核对）

| 校验 | 命令 | 结果 |
|---|---|---|
| 几何包围盒 / 角度白名单 / UV | `.probe\texture-design\check-geom.ps1` | **越界 0**；莲座与结球 **UVBad 0**（修复前 18/18 模型不合格、2 个越界）；仅剩 `sunflower_age_3/4/5_top` 报 UVBad —— 那是"整张贴图铺 14.4×16 的板"的**刻意缩放**，非缺陷 |
| 零厚度轴 vs 面类型 | `.probe\texture-design\face-axis-audit.ps1` | 25 个手写模型 / 172 个元素 ⇒ **错配 0**（修复前在备份上抓到 6 个） |
| 孤儿模型 | （内联脚本）blockstate 引用 ∪ 模型 parent 引用 | 2194 个模型 ⇒ **孤儿 0** |
| 资源交叉引用 | `tools\verify.ps1` | **全部有效**：blockstate 475 / 模型 2052 / 掉落表 475 / 物品模型 429 |
| 双段接缝 | `.probe\texture-design\seam-audit.ps1` | **172 对全对齐 / 0 错位** |
| 贴图总审计 | `.probe\texture-design\audit-all.ps1` | 1410 张、尺寸错 0、`asym=0` **37 张**、色数>8 **156 张**、LUM 出 110~140 **520 张**（⚠️ 指标只用于挑下一轮候选，**不能当验收**；最集中的是 loofah 16 / chayote 15 / yam 14 / sunflower 14） |
| ❗实机 | — | **未构建、未实机验证**（用户本轮明令"jar 先不构建"） |

---

## 五、待办
1. 子代理交付后：**按 `docs/105` §四的实测 UV 表复核顶端 1~2 行**（我 prompt 里那两行写小了）；
   然后按 §六-1 的判据做最终验收（每片板看得出是叶子 / 物种一眼可区分 / 生长序列连续）。
2. `winter_melon` age3 中央"很浅的竖向分界"、age5 顶部 1px 白（`docs/104` §11.4-2）。
3. 未重画的其余 ~20 个物种（先按 `audit-all.ps1` 的提示挑，但**指标只用于挑候选、不能当验收**）。
4. ❗**构建后必查**（本轮全部未构建）：`Unable to load variant`（kale 12 变体）、
   `Unable to load model`、以及实机里莲座是否真有 **4 个方向**的叶片。
5. `docs/104` §11.4 与 `docs/99` 的待办清单需要与本文件对齐（本文件更新）。
