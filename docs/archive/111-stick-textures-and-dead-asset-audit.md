# 111 · 插棍贴图 `_stick` 重画 + sisal/agave 区分 + 死贴图全量审计

> 用户 2026-09-28「效果很好，继续推进其他内容」。
> ⚠️ 本轮**未构建 jar、未实机验证**（用户明令）。

---

## 一、侦察：`_stick` 是当前最大的活缺口

`*_stick*.png` 共 **72 张**，分两类：
| 类别 | 数量 | 状态 |
|---|---|---|
| `<sp>_age_N_stick.png`（N=0..3） | **44** | ✅ **活资源**：44 个模型 `<sp>_age_N_stick.json` 引用；11 个 blockstate 有 `stick=true` 变体 |
| `<sp>_N_stick.png`（N=0..3） | 28 | ☠️ 死资源（无人引用的旧命名家族） |

blockstate 结构（以 `cowpea` 为例）：
```
age=0..3, stick=false          -> <sp>_age_N
age=0..3, stick=true, part=bottom -> <sp>_age_N_stick     ← 我们的图
age=0..3, stick=true, part=top    -> tfc:block/crop/stick ← TFC 自己的支架
age=4..7, part=bottom/top         -> <sp>_age_N_bottom/_top（双段，无 stick 变体）
```
模型本身是最简单的 `{"parent":"block/crop","textures":{"crop":"...<sp>_age_N_stick"}}`
⇒ **原版十字、UV 整张铺满，这里没有缩放问题**。

### 1.1 实看：11 个物种共用同一张画（`px/STICK-RECON.png`）
现在的 `_stick` 贴图是**一根浅桃色/肉色的粗棒 + 3~5px 的绿色大方块**，
`cowpea` / `hops` / `yam` / `loofah` / `malabar_spinach` / `snake_gourd` **六个物种看上去几乎一样**。

### 1.2 学 TFC 教材（`px/LEAD-TFC-STICK-REF.png`）
TFC 自带 `green_bean_0..3_stick.png`（**豆科**）与 `tomato_0..3_stick.png`，画法与我们完全不同：

| | TFC 教材 | 我们 |
|---|---|---|
| 支架 | **棕色**、约 3px 宽、**偏一侧**、顶端不顶满 | 浅桃色、更粗 |
| 叶 | **1~3px 的小枝叶**，沿支架左右交错稀疏挂着 | **3~5px 的大绿方块** |
| 逐龄 | `age0` 近乎光支架 + 底部极小嫩芽 → 叶**沿支架往上爬** → `age3` 爬到上部 | 一坨渐变大的绿 |

⇒ **44 张全部要按 TFC 的语言重画**，并按物种区分叶形。已派 3 个子代理：
- **葫芦科**：`bitter_melon`（深裂掌状叶）/ `chayote`（宽心形）/ `loofah`（掌状浅裂）/ `snake_gourd`（深裂细长）—— 16 张
- **其他攀援**：`hops`（掌状粗齿叶 + 缠绕茎 + age3 淡黄绿球状花穗）/ `yam`（宽心形叶带明显叶脉）/
  `malabar_spinach`（肥厚圆叶 + **暗红紫肉质茎**）—— 12 张
- **豆科**：`common_bean`（暗橄榄绿）/ `cowpea`（深蓝绿、叶细）/ `pea`（深蓝绿、叶更窄）/
  `winged_bean`（青绿 + 四棱侧翼点），并要求画出**缠绕的细茎**与**三出复叶** —— 16 张

---

## 二、sisal vs agave：两个物种几乎分不出

`px/LEAD-ROSETTE-A5.png` 实看：第 2 格 `sisal` 与第 4 格 `agave` **都是"灰绿 + 尖叶莲座"**，
既共用几何（共享模型，允许），又**色彩几乎相同** ⇒ 玩家分不出。

**⚠️ 顺带查清一件容易搞错的事**：这两个物种**真正的活贴图是 `<sp>_rosette_N.png`**（09-27 重画），
而 `<sp>_age_N.png` / `<sp>_age_N_fruiting.png`（09-26 那批）**是死资源**。
⇒ 已明确告知子代理：只改 `_rosette_0..5` + `_rosette_5_fruiting`（**14 张**），不要碰 `_age_*`。

现实依据与改法：
| 物种 | 叶形 | 颜色 | 标志器官 |
|---|---|---|---|
| `sisal` 剑麻 | 笔直狭长的**剑形叶**，叶缘**光滑无齿** | **冷调蓝绿**（白霜感） | 叶尖 1px 短刺 |
| `agave` 龙舌兰 | **较宽、外弯**的叶，**叶缘有锯齿** | **暖调灰绿/橄榄** | ① **中央淡黄奶白纵纹带**；② 叶缘 1px 齿；③ 顶端 2px 粗刺 |

---

## 三、🛑 全量「死贴图」审计（第一次做，结果很值得记）

方法：扫 `models/**` 全部 json 的 `textures` 值，取出所有 `tfcfarmingplus:block/...` 引用，
再与 `textures/block/**` 的 PNG 逐一对账。

| 指标 | 数值 |
|---|---|
| `textures/block` 下 PNG 总数 | **2083** |
| 被模型引用的 | 1337 |
| **无任何模型引用（死贴图）** | **746（36%）** |

死贴图按形态分类：
| 形态 | 数量 | 说明 |
|---|---|---|
| `crop/X_N`（旧命名家族） | **397** | 第 42 轮记录的"两套命名"里的旧那套 |
| `crop other` | **179** | 例如 `<sp>_age_N_fruiting`（莲座作物的真实活名是 `<sp>_rosette_N`）、`amaranth_4_bottom`（活名是 `amaranth_age_4_bottom`）等 |
| 非 crop | 88 | 果树/浆果等其他目录 |
| `crop/X_age_N` | 54 | 被新名取代 |
| `*_stick`（旧 `X_N` 家族） | 28 | 见 §一 |

⚠️ **结论：36% 的贴图是死资源**，其中大量是"同一张图的两个命名版本"。
**这与第 42 轮的教训完全一致**（`X_N` 与 `X_age_N` 两套并存，模型只引用后者）——
本轮 `_stick` 与 `sisal/agave` 的作业范围**都已按这条核对过**，避免把人力投到死文件上。
🛑 **本轮不删任何死贴图**：硬约束 §二-4 —— 从 `src/main/resources` 删除文件后必须 `gradle clean build`，
而用户明令本轮不构建。⇒ 只记录，**等用户允许构建时再集中清理**。

---

## 四、🛑🛑 用户点出的**真错误**：「攀缘植物的贴图是双方块」

### 4.1 从 TFC jar 里查到的权威结构
用户 2026-09-28 提醒「别忘了攀缘植物的贴图是双方块」。我从 `mods/TerraFirmaCraft-NeoForge-1.21.1-4.2.10.jar` 导出了 TFC 的资源来核对：

```jsonc
// assets/tfc/blockstates/crop/green_bean.json （节选）
"age=0..3,stick=true,part=bottom": "tfc:block/crop/green_bean_age_N_stick",   // 植物 + 支架
"age=0..3,stick=true,part=top":    "tfc:block/crop/stick"                     // 一根光杆
// assets/tfc/models/block/crop/stick.json
{"parent":"block/crop","textures":{"crop":"tfc:block/crop/stick_top"}}
```
⇒ **插棍后是双方块**：下半格是我们的 `<sp>_age_N_stick`，上半格是 TFC 的 `tfc:block/crop/stick`。
（本模组的变体表与 TFC **逐条一致**，这部分没有问题。）

### 4.2 🛑 真问题：**下半格的杆没有和上半格对齐**
逐像素量 TFC 的 `stick_top.png`：**杆固定在 x7 / x8 两列**（且只占该贴图的下半 8 行）；
TFC 自己的 `green_bean_0..3_stick` **四张全是 x7/x8**。
⇒ 下半格的杆**必须**也在 x7/x8，否则世界里杆会在方块交界处**错位/断开**。

**全量审计结果：44 张里只有 27 张对齐，17 张错位**：
| 物种 | 实际杆列 | 偏差 |
|---|---|---|
| `pea` ×4 | **x4,x5** | 左移 3 格 |
| `cowpea` ×4 | **x9,x10** | 右移 2 格 |
| `common_bean` ×4 | **x6,x7** | 左移 1 格 |
| `yam` ×4 | **x7,x8,x9** | 杆宽 3px（多 1 列） |
| `malabar_spinach_age_3` | **x6,x7,x8** | 多 1 列 |

**视觉证据** `px/LEAD-STICK-MISALIGN-PROOF.png`（上半格 = TFC `tfc:block/crop/stick`，下半格 = 我们的贴图，红线 = 方块交界）：
`pea` 的杆在左下、上半格的杆居中 ⇒ **红线处断成两截**；`cowpea` 同样右偏断开；
`bitter_melon`（x7/x8）则**上下连成一根**。⇒ 错位是肉眼可见的，不是理论问题。

**已派单修复 17 张**：把杆重新锚定到 x7/x8（**不是整张平移** —— 叶子本来挂在杆上，
平移会让叶子脱节；要求"保持植物设计、把杆与挂在杆上的茎一起重新锚定，并检查没有悬空绿像素"），
并把 `yam` 的 3px 收到 2px、`malabar_spinach_age_3` 去掉多余那列。

### 4.3 顺带量出的第二处质量差距（同一批一起改）
「支架列被绿叶覆盖的行数（16 行里）」：
```
TFC  green_bean_0/1_stick : 4 行      TFC  green_bean_2/3_stick : 10 行
ours bitter_melon a0..a3  : 4/4/4/3 行  ← 完全不增长；其余物种同为 3~7 行
```
⇒ TFC 成熟期**叶片盖住约 10 行支架**，整株读作"爬满杆的植物"；我们成熟期只有 3~4 行，
杆基本全裸 ⇒ 读作"两根光杆 + 旁边几片叶"。已并入同一单：age_2/age_3 让叶片**适度压过杆**
（目标 8~10 行 / 16，**不盖满**，TFC 也留 6 行裸杆）。

### 4.4 我在这条上犯的错（记档）
派单时我只写了"支架用棕色"，**没有把"杆必须落在 x7/x8"写成硬约束** ——
葫芦科与 hops/yam 两组自己从 TFC 量出了 x7/x8 并锁死（做对了），
但豆科组把杆列**当成了物种区分手段**（x6/x7、x9/x10、x4/x5），于是三组之间不一致。
⇒ **教训：跨方块拼接的资源，对齐锚点必须在派单时写成硬约束**（与"新增方块族必须显式接入清单"同类）。

---

## 五、本轮作业结果（4 组全部落盘，Lead 已逐批复核）

| 作业 | 规模 | 状态 |
|---|---|---|
| 葫芦科 `_stick`（bitter_melon/chayote/loofah/snake_gourd） | 16 张 | ✅ 已复核 |
| hops/yam/落葵 `_stick` | 12 张 | ✅ 已复核 |
| 豆科 `_stick`（common_bean/cowpea/pea/winged_bean） | 16 张 | ✅ 已复核 |
| sisal / agave 区分 | 14 张 | ✅ 已复核 |

### 5.1 `_stick` 44 张：结构已与 TFC **逐格对齐**
Lead 自己 dump 了字符网格做对照（B=棕、g=绿）：

```
TFC green_bean_0_stick          OURS bitter_melon_age_0_stick
.......BB.......  (x7-x8)       .......BB.......  (x7-x8)
.......BB.......  ×11 行裸杆     .......BB.......  ×12 行裸杆
.......BBg......                .......Bg.......
.......ggg......                ....gg.gB.......
.......gg.g.....                .....gggB.......
.......gB.......                ....ggggB.......
```
⇒ **支架列（x7-x8）、裸杆长度、底部小芽的位置与形态，两边基本一致**。
棕柱是三色 `#58481D/#513E0C/#3E2F0A` **逐行换色**（TFC `stick_top.png` 同族），不是固定三列同色 —— 这就是"木棍质感"的来源。

**逐龄"往上爬"**（Lead 自建 2D 全龄图 `px/LEAD-STICK-AGES-CUCURBIT.png`、`px/LEAD-STICK-AGES-HYM.png`）：
4 个葫芦科 + hops/yam 都是 `age0` 近乎光杆 + 底部小芽 → `age1` 下部几片小叶 → `age2` 叶到中部 →
`age3` 叶爬到上部左右铺开，**中间那根棕支架始终可见** ✓ 与 TFC 的 `gb0→gb3` 同一套语法。

**物种区分**（Lead 自渲 `px/LEAD-STICK-A3-FINAL.png`，11 物种 age3 —— ⚠️ 用的是**最终版**贴图；
早先那张 `LEAD-STICK-A3-3D.png` 生成于葫芦科重画之前，**已作废、不要引用**）：叶色/叶形/杆位三重拉开 ——
苦瓜深裂掌状 / 佛手瓜宽心形偏亮 / 丝瓜掌状小簇 / 蛇瓜最稀疏 / hops 深绿碎叶 + **2 个奶黄花穗** /
yam 亮黄绿宽叶带叶脉 / 落葵**暗红紫肉质茎**（`#A63A62`/`#7E2A48`）盘旋 + 圆钝亮绿叶 /
菜豆暗橄榄 / 豇豆深绿更细 / 豌豆青绿更窄 / 四棱豆暗青 + 1px 翼点。**11 个不再共用剪影** ✓

### 5.2 ⚠️ 一个**被证伪的怀疑**（值得记）：3D 里的"两根柱子"不是 bug
Lead 最初在 3D 图上看到"两根棕柱并排"，怀疑支架画重了。子代理做了对照：
**把 TFC 自己的 `green_bean_0..3_stick` 贴图塞进本项目完全相同的几何**（`px/SH-REF-TFC-GB3D.png`），
TFC 原版**同样渲染成两根柱 + 底部小撮绿**。
⇒ 这是 `block/crop` 父模型（4 片板、两对各错开 4 格）的**固有表现**，TFC 也一样；
**贴图里其实只有一根柱**（Lead 用字符网格复核确认：只有 x7-x8 两列棕色）。**未改几何，也不该改。**

### 5.3 sisal / agave：色彩 + 叶宽 + 纵纹三重拉开
Lead 自渲 `px/LEAD-SA-AFTER.png`（p28）实看：
- **sisal（左）**：**冷青蓝绿**、叶 1px 宽笔直狭长、**叶缘毫无杂点**、只有叶尖 1px 深刺 ⇒ 通透的青绿星芒；
- **agave（右）**：**暖灰橄榄**、叶 3px 宽、**每片叶中央一条贯穿的淡黄白纵纹带**、叶缘有奶白齿点、叶尖 2px 粗刺。
⇒ 一眼可分 ✓（改前两格都是灰绿放射莲座，确实分不出）。
- 遗留：agave 的奶白纵纹在 3D 里占叶宽约 1/3，面积偏大（要显眼的直接结果）；`agave_1` LUM 145 略高于提示区间。

### 5.4 本轮校验链（贴图批次后复跑，全绿）
`check-geom` **越界 0 / uv 非 1:1 = 0 / 31** · `face-axis-audit` 154 元素 **0 错配** ·
`seam-audit` **172 对齐 / 0 错位** · `audit-all` **尺寸错误 0** · `verify.ps1` **全部交叉引用有效**。
写入范围审计：近 30 分钟内 `src` 下**只有** 44 张 `_stick` + 7 张 `sisal_rosette_*` + 7 张 `agave_rosette_*` 被改（58 张，与目标完全一致），**无意外文件名、无新建孤儿**。
