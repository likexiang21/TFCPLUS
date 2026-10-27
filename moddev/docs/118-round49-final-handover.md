# 118 · 第 49 轮最终交接（贴图资源绘制 · 2026-09-28）

> ✅ **总验收已执行（04:18）**：见 `docs/117` §十二 —— 用户点名 5 项全部完成并逐项有图；
> 本轮新发现并修掉 7 类缺陷共 **105 张贴图 + 30 个 json**；全量 **2394 张贴图 100% 进过接触表并被实看**；
> 7 项校验门全绿。⏱ 因 goal 轮次预算（40）先于 06:00 耗尽，验收在 04:18 执行；
> **每一批改动在当轮就已逐张渲染 `read_image` 实看**（§十二 12.0 有说明）。
> 🛑 **仍未构建 jar、未实机验证**（用户明令）——接手后第一件事见 §六 末条。
>
> 🎬 **追加：逐模型总验收（04:2x，用户点名）** —— 把本轮亲手重做的 **131 张贴图**
> 反查引用得到 **130 个模型**，按**真几何**渲染成 7 张表 `px/R49-FINAL-M1..M7.png`（130 格，0 warning / 0 failed），
> 逐格 `read_image` 实看：门框 / 环形 / 横梁**一格都没有再出现**。
> 全文见 `docs/117` **§十四**（含 7 表逐表"看到了什么"与一条如实的边界说明）。
>
> 🧭 **再追加：更早批次补齐 + 全作物缺陷分析（用户第二次点名）** —— 更早 A~H 批次的 **373 个模型**
> （`px/R49-ALL-E1..E16.png`）+ 全族 crop/dead_crop/wild_crop **531 个模型**（`px/R49-REST-R1..R15.png`）
> 已全部渲染并逐格实看；本轮共 **1034 个模型 / 38 张总表 + 7 张放大表**。
> 新发现并**已修 38 张**（低龄细拱/圆环/X 29 张 · 双段实心墙 2 张 · buckwheat 竖条纹幕 7 张）；
> **确认未修**：branch_fruit 规则十字纹（13）· dead_crop 马蹄/条纹 · wild_crop 大块白斑 · 749 张死贴图 · 5 张 live asym=0。
> 全文与逐表证据见 **`docs/119-round49-model-sweep-and-defect-analysis.md`**。
>
> 🧾 **再追加：全渲染图缺陷台账 + 野生作物占位清查（用户第三次点名）** —— 59 张渲染图 / 1034 格全部记账
> （`docs/120-render-defect-ledger-and-wild-crop-placeholders.md`）。
> 🔴 实测：**`wild_crop` 172 张里 83 张与 TFC 原版剪影 IoU=1.00**（86 张 `*_grass` 全是同一张 TFC 图的复制；
> live 里 38 张纯占位 + 7 张仅改 1~2px；6 个豆科共用 `soybean_6`、野生茄子 = `wheat_7`）；
> `crop` 家族也有 227 张 IoU≥0.95（live 43）。✅ 已重画第一批 8 张野生作物（`px/R49-WILD-B1B.png`）。
> 📋 `dead_crop` 缺陷最集中：≈43 张 `*_young` 全是"细拱"、7 处亮色马蹄/圆环、7 处过饱和火焰条、6 类枯色发粉/发亮。

> 上一份交接：`docs/114-session-handoff-texture-and-models.md`（资源制作总纲）·
> 本轮过程与验收：`docs/115`（插棍规格）· `docs/116`（自治重画与工具教训）· `docs/117`（验收报告，含 §六~§八 本轮追加）。
> ⚠️ 用户明令：**不构建 jar、不做实机验证**；**视觉实看是第一标准**；**禁止函数/脚本批量生成贴图**。

## 一、本轮（第 49 轮）做完的事

### 1.1 插棍 44 张（点名项）
- 44 张 `<sp>_age_N_stick` 的**杆**逐像素对齐 TFC canonical 表（x7/x8、16 行、1197 格 0 错）；
- 11 个物种的**植物层**全部重画 / 复核（cowpea 青绿·malabar 洋红茎·hops 米色球花·snake_gourd 灰绿叶·
  loofah 换成互生叶序以区别于 bitter_melon），证据 `px/LEAD-R49-STICK-A3.png`（11 格 p28）。

### 1.2 枯萎/幼苗 29 张 + 16 个物种的"拱门"
低龄段"两条竖边 + 顶梁"的门框逐物种改掉（`docs/117` §四）。**根因最终定为**：
> `block/crop` 是 4 片平行竖板、两对 x 偏移相差 4 ⇒ 贴图里 **4~10px 宽 × ≥9 行高** 的实心竖块
> 会被画成"两条粗腿 + 顶梁 + 中间黑洞"。

### 1.3 G 组四个物种的 age_3/4/5（12 张，门框）
`celeriac`（Lead 样板）· `celery` · `parsnip` · `salsify`，全部按 TFC 成熟根菜语法重画：
**顶部留空 → 中段宽叶冠铺到 x1~x14（行内 1px 洞）→ 底部彼此分开的基部/根块**。
身份器官：celeriac 棕色根球 · celery 淡黄绿叶柄 · parsnip **奶白根冠** · salsify **灰绿草叶 + 紫花**。

### 1.4 "光杆"物种（sunflower · hemp）
`sunflower`（7 张）与 `hemp`（9 张）原本是"一根竖条 + 几粒碎叶"。
改为**茎 1~2px 锚在同一列 + 沿茎节节长叶**（sunflower 粗叶、hemp 掌状叶扇）；sunflower 成熟期能看到**黄色花盘**。

### 1.5 豆类 5 张 + faba 全段
`chickpea_age_2`（绿环→斜排羽叶）· `cowpea_age_4_bottom` · `pigeon_pea_age_3_bottom` ·
`faba_bean_age_3_bottom`（棕梯子→叶丛）；Lead 追加 `faba_bean_age_3/4/5_top`（等距横档→不规则叶）与
`age_4/5_bottom`（三根竖柱→**茎逐段倾斜**的叶丛）。

### 1.5b 谷物与攀援豆类（本轮最后两批，都是"对照 TFC 后动手"）

- **spelt / emmer age_4/5（8 张）**：改前是"一根贯穿 32 行的 2px 光杆 + 几粒碎点"，且两个物种几乎一样。
  先 dump TFC `wheat_7`（3 档金穗 + 2 档橄榄 + 1 档暗色、~85 不透明像素/16×16、茎逐行 1px 游走），
  再按同一读法重画：2~3 个分蘖、**茎列逐段游走**、金黄穗（spelt 长穗带芒 / emmer 短穗无芒、位置更低）、穗间补旗叶。
  op 从 ~50 提到 **223 / 175**。证据 `px/LEAD-R49-SPELL/EMMER-SEQ3.png` · `LEAD-R49-CEREAL-3D.png`。
- **pea / cowpea / common_bean / winged_bean 的 `_age_4~7_top`（16 张）**：改前是**同一套模板**且**上 8 行全空**（op 20~40）
  ⇒ 双段作物第二格几乎看不见，3D 里只剩两根棕色小棍。重画为**藤蔓贯穿上半格**（逐龄从行 15 爬到行 0）+ 物种器官
  （pea 卷须白花 / cowpea 三出复叶+荚 / common_bean 大叶白花 / winged_bean 三出叶+淡紫花），op 26~75。
  证据 `px/LEAD-R49-LEG-TOP3D.png`。

### 1.5c 三类缺陷族的系统清算（本轮方法论产出）

本轮把"贴图在 4 片平行板几何下会变成什么"总结成**三类可检测、可复现的缺陷**，并各配一个**只排候选、不作验收**的检测器：

| 缺陷 | 检测器 | 判据 | 本轮修掉 |
|---|---|---|---|
| **实心竖块 ⇒ 门框** | `arch-detect.ps1` | 最大 4-连通块 `4≤BW≤10 且 BH≥9 且 fill≥0.55` | G 组 12 张 + 豆类 5 张 |
| **细线拱 ⇒ 门框** | `arch2-detect.ps1` | 连续 ≥4 行"恰好 2 段不透明、中间有缝" | chive 3 · flax 2 · water_chestnut 4 · fonio 2 · gorgon_nut 1 · finger_millet 2 |
| **光杆 / 上半格空** | 无（靠 2D/3D 实看） | 一列茎贯穿多行且叶极少；`_top` 顶空 ≥5 行且 op<60 | sunflower 7 · hemp 9 · spelt/emmer 8 · 攀援豆 `_top` 16 |

⚠️ **两个检测器都只是"挑候选"**：候选 259~263 张里抽验 43 张，真缺陷 8 张；
其余是**叶丛中的自然缝隙**（例：`ramie_age_4_bottom` · `arugula_age_3` · `fonio_age_7` · `buckwheat_age_6`）——
**数值命中 ≠ 缺陷，必须拉动到 p28 亲眼看**。

### 1.6 其它点名项
- `kale` / `cardoon` **区分**：kale 蓝绿卷叶 vs cardoon 银白尖叶（p70 下黑缝可见）；
- `branch_fruit` **分面**：基模型加 `top` 槽（up/down 用 `#top`），14 个树种包装模型各加 `top`，
  新画 16 张果顶贴图（top 面 UV 只有 `[6,6,10,10]` ⇒ 只采样中央 4×4）；
- `sunflower` **分面**：删掉 age_3/4 的花盘元素（3→2 elements），只有 age_5 开花。

### 1.7 后期龄与"结球/莲座结果态"复核（本轮最后一段）

- **spelt/emmer age_6/7 + 三种小米 age_6/7 上半格（14 张）**：旧文件是"光杆 + 顶部相连"（拱）或
  "两把锤子（两三根光杆各顶一穗）"。统一按 age_4/5 的语法重画（游走茎列 + 穗 + 旗叶，越老越密），
  三种小米的穗形**互相区分**（米黄下垂 / 奶白粗棒 / 金黄带芒毛）。证据 `px/LEAD-R49-CEREAL67.png` ·
  `px/LEAD-R49-MILLET-TOPS.png`。
- **莲座结果态 6 张**（`agave/cardoon/kale/purslane/sisal/rosette_age_5_fruiting`）p28 实看
  （`px/LEAD-R49-FRUITING.png`）：**六个立方体果实都露在叶丛上方、能看到两三个面** ✓
  （第 48 轮"球被叶筒挡死"的判据在本轮复核通过）。

## 二、当前真实状态（数字都是本轮实测）

### 1.8 新增审计工具与枯死态复核

- `tex-ref-audit.ps1`（**只读**）：核对**每条"模型 → 贴图"引用是否真的存在**（`verify.ps1` 不做这件事）。
  实测 **2022 条自有引用，缺失 0**；另 9 条指向 tfc/minecraft。⚠️ 写它时踩了 `'tfcfarmingplus:'.Length = 15`（不是 16）的坑，
  用 16 会得出"164 张全缺"的假警报 —— **先自证工具，再信结论**。
- **枯死态 166 张**（`textures/block/dead_crop/`，164 个模型 / 171 个 blockstate 变体）本轮**首次全量实看**
  （`px/CT-R49-DEAD-p1/p2.png`）：都是"整株枯黄 + 收获器官保留色" ✓；**只发现并修掉 1 张画错的**
  （`dead_crop/artichoke.png` 原本是**绿色活株**，已按"同株型换枯色 + 保留紫花"重画，
  设计稿 `px/artichoke_dead.txt`，证据 `px/LEAD-R49-DEAD-ART.png`）。

| 项 | 数值 |
|---|---|
| crop 贴图总数 | **1425 张** |
| 本会话改动（对 `bak-src-20260927` 全量比对） | **725 张改 + 15 张新增** |
| 设计稿（`px/*.txt`） | **1355 份**（本轮新增/更新约 120 份） |
| 证据图 | 接触表 **38 页**（`CT-R49-*`）· 逐项证据 **253 张**（`LEAD-R49-*`） |
| `check-geom`（自有几何 31 个 / 1623 json） | 越界 **0** / uv 非 1:1 **0/31** |
| `face-axis-audit` | 152 个 element，面类型不匹配 **0** |
| `seam-audit` | 双段 **172 对，对齐 172 / 错位 0** |
| `lead-lock/stick-pole-audit-lead.ps1` | 44 张全同 · 1197 格 **0 错 / 0 洞 / 0 杂列** |
| `tools/verify.ps1` | blockstate 475 / 模型 2052 / 掉落表 475 / feature 244+244 / 物品模型 429 —— **全部有效** |
| 门框候选（`arch-detect.ps1`） | 104 → **94**（实测确认的都已修） |

### 1.9 全量覆盖补齐（本轮）：750 张从未看过的贴图

前几轮的接触表只覆盖了 `block/crop`（1425）。本轮把剩下三个族全部扫完：

- `block/wild_crop` **172 张**（86 野生态 + 86 灰度草色覆盖层——**灰度是设计如此**，靠群系草色染色）；
- `block/fruit_tree` **288 张**（48 树种 × 枝干/枯叶/花叶/果叶/绿叶/树苗）；
- `item/*` **292 张**（果实图标 / 种子 / 树苗 / 浆果丛枝条）；
- `block/dead_crop` **166 张**（见 §1.8）。

⇒ **`assets/tfcfarmingplus/textures` 全量 2394 张，每张都至少进过一次接触表实看**（证据 `px/CT-R49-*.png`，共 24 页）。
⚠️ 教训：**"扫过 crop 目录"≠"扫过全部贴图"** —— 目录清单要按 `textures` 根递归统计（`Get-ChildItem -Directory -Recurse`），
不要凭印象认为只有 crop 一族。

### 1.10 全模型渲染审计 + 渲染器缺陷修复（本轮）

- 把**每一个模型**都过一遍 `rr-review.ps1`（真几何 + 真贴图），只抓 `WARNING/missingTexFaces`：
  `block/crop` **765/765** ✓ · `block/dead_crop` **164/164** ✓ · `block/*.json` **8/8** ✓ · `block/plant` **357/600**。
- 🛠 **修好渲染器一个真缺陷**：`rr-review.ps1 -UseLab` 的镜像函数只处理 `tfcfarmingplus:`（第 57 行 return），
  导致**父模型是 `tfc:block/plant/cross_2` 等的一律渲染失败**。已加 **donor 根**
  （`.probe/ref-tfc/assets` + `.probe/lab-assets`）⇒ 可渲模型 213 → **357**（+144）。
- ⚠️ 剩下 243 个**不是资源缺陷**：240 个父模型是 vanilla `minecraft:block/leaves`、3 个是 `tfc:block/plant/dead_berry_bush_*`，
  而本地**没有 1.21.1 vanilla 素材索引**、TFC 导出里也没那 3 个模型。这批的引用链/贴图存在性/外观
  分别由 `verify.ps1`、`tex-ref-audit.ps1`、2D 接触表覆盖。
- 🛑 **禁止**为了"能渲染"而手写假的 vanilla 父模型 —— 第 42 轮"假 `block/crop` 模型"的教训（docs/94）。

## 三、验收是怎么做的（**必须沿用这套**）

1. **全量接触表**：`contact.ps1 -Cols 12 -Scale 6 -PerPage 144` ⇒ `px/CT-R49-FIN-p1..p10.png`
   （1425 格，10 页逐页 `read_image`）。
2. **成熟期 3D 全物种**：89 个 `*_age_5(_top)` 模型分 6 张 p28 图
   （`px/LEAD-R49-MAT3D-1..4.png` + 之前的 `LEAD-R49-MATURE-A.png` 等），逐个说出"看到了什么"。
3. **改动项逐张 3D 复验**：门框 12 张、sunflower/hemp、faba、四组子代理交付 —— 每张都有 Lead 自己重渲的证据图。
4. **可疑项 3D 复核**：缩略图像"帐篷"的 4 张（chive / water_chestnut / fonio / winter_melon_age_4）
   拉到 p28 实看，判为**物种本身株型，不是缺陷**（`px/LEAD-R49-SUSPECT3D.png`）。
5. **回归校验**：每改完一批必跑 `seam-audit`（双段）与 `stick-pole-audit-lead`（插棍），收尾跑全量 5 项。

## 四、踩过的坑（下一位务必先读，全部是本轮真实损失）

1. 🛑 **二维数组 + 算术表达式 = 静默灾难**：`$out[$x, $y - 1]` 会被解析成"索引数组 `($x,$y)` 再减 1"，
   报 `op_Subtraction`；更隐蔽的是**函数多返回值 + 二维索引**混用 ⇒ 整行变成 `". .. .."`（每像素 3 字符）。
   ⇒ 新版 `r49-seq2.ps1` **全部用一维 `char[]` 行数组**；旧的 `r49-seq.ps1` 有坑，**不要再用**。
2. 🛑 **共享审计脚本被子代理改过**（`stick-pole-audit.ps1` 的 canonical y12 被改成 `3E2F0A`，导致 28 张误判 FAIL）。
   ⇒ 最终验收**只用 `lead-lock/stick-pole-audit-lead.ps1`**（Lead 私有副本）；给子代理派单时**必须写明"不许改共享 .ps1"**。
3. 🛑 **子代理会越界**（本轮两次：改了审计脚本、改了 `pea_age_*_stick.png`）。
   ⇒ 派单必须写清"只许写这几张 PNG + 设计稿"，并在收尾**抽查 mtime**。
4. ⚠️ **一次性修正脚本的参数必须摘掉**：`stick-pole-fix.ps1` 的 `$shift` 曾二次执行 ⇒ 杆被二次平移（3 个物种位移）。
5. ⚠️ **"拱"的判据经过两次修正**：先是"两条竖边 + 顶梁"，后经 dump 证实是**"窄而高的实心竖块被 4 片板复制"**。
   不要用"左右只在一边画叶子"去修（会被几何镜像成两遍）。
6. ⚠️ **双段作物的接缝行只能"钉死"**：`_bottom` 行 0 ≡ `_top` 行 15（逐像素 RGBA）；
   改完必须跑 `seam-audit`（本轮多次因"整体错一列"被它抓到）。
7. ⚠️ **调色板符号大小写不敏感**（`B`/`b` 是同一个键）且**符号语义要先读清楚**
   （有人把 `K=48290F` 棕色当绿色用了 10 行）。
8. ⚠️ **不要相信"看起来细碎 = 质量好"**：占位贴图（TFC 形状拷贝）细碎但不是我们的作品；判质量只能逐张实看。

## 五、未完成项（按优先级）

- **P0**：无已知 P0。用户点名的四项（插棍植物层 · kale/cardoon · branch_fruit/sunflower 分面 · 门框物种）**均已完成并实看**。
- **P1**：**死资源清理**（`X_N` 旧命名 658 张中的一部分 + `_calib.png`/`_stripe*.png` 标定图 +
  `ramie_5_*`/`spinach_4`/`mustard_greens_5`/`cardoon_rosette_4`/`sunchoke_*` 等旧命名残留）。
  🛑 **删资源必须 `gradle clean build`**（AGENTS §二-4），本轮用户明令不构建 ⇒ **未删**。
- **P2**：子代理自述的**质量短板**（未改）：`faba` 叶仍偏细碎（离"大椭圆叶"差一步）·
  `adzuki_age_5` 叶丛偏密 · `okra` 叶只见两裂 · `kale` 卷边靠颜色而非形状 · `artichoke_age_4` 偏密 ·
  `celery_age_1/2` 偏矮 · `parsnip_age_5`/子代理组 op 偏高（更透可再加 1px 洞）。
- **P3**：`salsify_age_5` 的紫花会被 4 片板画成 2~4 个副本（**几何固有**，要唯一花头只能改几何，非贴图层能解）；
  `branch_fruit`/`sunflower` 的**其它面**（east/west/north/south 以外的组合）未逐个看；
  `spelt_age_5_top` 偏疏。

## 六、命令速查（`workdir = .probe\texture-design`）

```powershell
# 渲染真几何（普通作物必须 -UseLab；-Model 传数组）
& .\rr-review.ps1 -Model 'tfcfarmingplus:block/crop/kale_age_5' -Out px\X.png -Pitch 28 -Yaw 40 -UseLab
# 整株 2D（自动拼 _bottom/_top，ground 对齐）
& .\seq2d.ps1 -Dir <crop 贴图目录> -Species hemp -Ages 0,1,2,3,4,5 -Out px\X.png -Zoom 9
# 全量接触表
& .\contact.ps1 -Dir <crop 贴图目录> -Cols 12 -Scale 6 -PerPage 144 -Out px\CT.png
# 手写行图 -> 设计稿（禁批量刷图；落盘仍用 draw2.ps1 一张一张来）
& .\r49-seq2.ps1 -Maps .\r49-seq-maps-hemp.txt
& .\draw2.ps1 -Design px\hemp_age_3_top.txt -Out <...>\hemp_age_3_top.png
# 校验五件套
& .\seam-audit.ps1 ; & .\lead-lock\stick-pole-audit-lead.ps1
& .\check-geom.ps1 -Path <...>\models\block
& .\face-axis-audit.ps1 ; & ..\..\moddev\tfcfarmingplus\tools\verify.ps1
# 门框候选排序（只用来挑候选，不作验收）
& .\arch-detect.ps1 -Out .\ARCH-SUSPECTS.csv
```

## 七、给下一位的三句话

1. **先看 `docs/117` 的证据索引，再动手**；每改一张都要"渲染 → `read_image` → 写出看到了什么"。
2. **不要碰 `.probe/lab-assets` / `lab-old` / `lab-new`**（旧版快照，AGENTS 明令），
   也不要跑 `stick-pole-fix.ps1`（`$shift` 已清空，但重跑仍有风险）。
3. **构建后的第一件事**：核 `build/libs/*.jar` 与 `mods/` 一致，然后进存档看
   `Unable to load model` / `Missing textures` 是否指向 `tfcfarmingplus`（本轮**未构建、未实机**）。
