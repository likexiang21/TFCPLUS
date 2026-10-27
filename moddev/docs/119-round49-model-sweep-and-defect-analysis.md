# 119 · 第 49 轮「逐模型渲染补齐 + 全作物缺陷分析」（2026-09-28）

> 用户指令：**「更早的也要渲染补齐，并且你也要详细对比观察分析全部作物不足之处和不符合要求的点」**。
> 本文是回答这一条的两部分：① 把本轮**所有**相关模型都渲出来（含更早的 A~H 批次）；② 逐类／逐物种的**不足与不符合项**分析。
>
> 🛑 仍然**未构建 jar、未实机验证**（用户明令）。所有判断都来自**离线真几何渲染 + `read_image` 实看**。
> 数字只用来"挑候选"，从不作为验收结论（AGENTS.md 第一标准）。

---

## 一、覆盖范围（这次到底渲了什么、看了什么）

| 批次 | 内容 | 模型数 | 出图 | 状态 |
|---|---|---|---|---|
| M1~M7 | 本轮 Lead 亲画 131 张贴图 → 反查引用的模型 | **130** | `px/R49-FINAL-M1..M7.png` | ✅ 逐格实看（docs/117 §十四） |
| E1~E16 | **更早的 A~H 批次**（09-27 22:00 之后改过的贴图）所引用的模型 | **373** | `px/R49-ALL-E1..E16.png` | ✅ 逐格实看（本文 §三） |
| R1~R15 | 其余**全部** crop / dead_crop / wild_crop 模型（补齐全族） | **531** | `px/R49-REST-R1..R15.png` | ✅ 逐格实看（本文 §四） |
| Z1~Z7 | 可疑项的**放大复核**（Cell 300~430） | 40 格 | `px/R49-ZOOM-Z1..Z7.png` | ✅ 用作"确认/排除"证据 |

**合计 1034 个模型 / 38 张总表 + 7 张放大表**，全部用**真几何**（`rr-review.ps1 -UseLab`，p28/y40）渲染，`missingTexFaces=0`，无 warning、无失败。
清单：`px/R49-ALL-MODELS.txt`（503）· `R49-REST-MODELS.txt`（531）· 对应关系 `R49-MODEL-TEX-MAP.txt` · 格子对照 `R49-ALL-E-sheetmap.txt`。

---

## 二、结论速览

- **更早批次不是"没问题"**：373 个模型里至少 **29 张贴图**在低龄段渲染成**细拱 / 圆环 / X 交叉**（"门框"家族的轻量版），另有 **2 张双段下半是实心墙**、**1 个物种整条序列是竖条纹幕**。
- 已**亲手重画并逐张实看通过 38 张**（§五，全部有改后渲染证据）。
- 仍**确认存在、尚未修**的缺陷集中在两族：**dead_crop（枯死态）的马蹄形／竖条纹**与 **wild_crop 的大块白斑**（§四·3、§四·4）；另有资源层问题 **749 张死贴图**（§六）。
- **方法学教训（重要）**：200px 总表会**误读**——我在总表里判为"拱"的 `fenugreek_age_0` / `rhubarb_age_0`，翻开设计稿与放大图后发现本来就是"离散小点／红茎"，**没有问题**。所以本文所有"确认"都附**放大证据**；只有 200px 证据的，明确标注为"候选"。

---

## 三、更早批次（A~H）逐表实看记录

写"在图上看到了什么"，不是指标。

| 表 | 看到的东西 | 判定 |
|---|---|---|
| **E1** | adzuki 0~5 由疏到密、age_4/5 挂橙荚 ✓；agave 0~5+_fruiting 是**灰绿剑叶莲座**，age_5_fruiting 顶上**方块露出两三个面** ✓；`arrowhead_age_1` = **一圈细绿方框（镂空环）** ✗；`arrowhead_age_2~4` 是直立茎 ✓ | 1 处缺陷 |
| **E2** | `bitter_melon_age_0/1_stick` = **两根光杆 + 底部一撮绿**（age_0/1 属正常苗期）✓；broccoli 2~5 = 莲座 + **青绿菜球**且球在叶上方 ✓；brussels_sprouts 0~4 偏小但确实是"小苗→小叶丛" | 无确认缺陷 |
| **E3** | `buckwheat_age_6` = **红/白/绿竖条纹幕**（严重）✗；cabbage 0~5 = 莲座 + 绿球 ✓；cantaloupe_age_4 偏小；cardoon 0~5 = **银灰尖刺叶** ✓ | 1 处严重 |
| **E4** | cauliflower 1~5 = **奶白菜球**逐龄变大 ✓；celeriac/celery/celtuce 中低龄**偏稀**（op 4~8）；chive 0~2 苗期 ✓；chayote 插棍 0~3 = 杆 + 藤 ✓ | 偏稀（见 §四·5） |
| **E5** | common_bean/cowpea 苗期→藤 ✓；`common_bean_age_3` 呈**环状叶团**（候选）；cotton 0~5 = **白絮 + 茎** ✓；`cotton_age_0` 呈小弧（候选） | 2 候选 |
| **E6** | `emmer_age_1/2` = **两根淡色杆交叉成 X** ✗✗；`foxtail_millet_age_1/2` = **X 交叉** ✗；`pearl_millet_age_1` = **拱环** ✗；`fenugreek_age_0`（总表看像弧，实际是好稿）；fonio 3~5 金穗 ✓；garland_chrysanthemum 2~5 黄花 ✓ | 5 处确认 |
| **E7** | hops 插棍 0~3 ✓（杆 + 米色球花）；`jobs_tears_age_1` = **门形拱** ✗；kale 0~5 + fruiting = **皱边灰绿叶球** ✓；lettuce 0~5 = 逐龄变大的叶球 ✓ | 1 处确认 |
| **E8** | loofah 插棍 0~3 ✓；`lotus_age_0` = **环** ✗；`lupin_age_1` 拱（候选）；lupin 4/5 紫花 ✓；malabar_spinach 洋红茎 + 绿 ✓；`mustard_greens_age_1/2` = **门形拱** ✗✗；napa_cabbage 2~5 = 白球 ✓ | 3 处确认 |
| **E9** | `okra_age_1` 弧（候选）；`pearl_millet_age_1` 拱环 ✗；`perilla_age_0/1` = **洋红细弧** ✗；parsnip 2 = 叶冠 + 奶白根 ✓；pea 插棍全龄 ✓ | 3 处确认 |
| **E10** | perilla 3~5 紫红叶丛 ✓；`pigeon_pea_age_0/1` 小拱（候选）；purslane 0~5(+fruiting) = **低矮肉质莲座 + 棕果球** ✓；`quinoa_age_0/1` = **环/拱** ✗ | 2 处确认 |
| **E11** | `ramie_age_0/1` = **对称双翼拱** ✗；**`ramie_age_4_bottom/5_bottom` = 4px 宽实心绿墙** ✗✗；`rhubarb_age_0`（总表像弧，实际是好稿）；`safflower_age_0`、`salsify_age_0/1`、`shallot_age_0` 呈弧（候选）；sesame 3~5 白花 ✓ | 2 确认 + 4 候选 |
| **E12** | sisal 0~5+fruiting = **灰绿剑叶 + 棕果块**（果块偏"土块"色，见 §四·6）；snake_gourd 插棍 ✓；`sorghum_age_0` 小拱（候选）；sorghum 4/5 = **大棕穗** ✓；`spelt_age_1` 淡色 V（候选） | 3 候选 |
| **E13** | `spelt_age_2` 弯茎（候选）；`spinach_age_0`、`sunchoke_age_0`、`sunflower_age_0/1`、`swiss_chard_age_0`、`taro_age_1/2`、`turmeric_age_0`、`water_caltrop_age_0` 均呈弧（候选）；sunchoke 3/4 = 向日葵状黄花 ✓；taro 4/5 大叶 ✓ | 10 候选 |
| **E14** | `water_chestnut_age_0`、`water_dropwort_age_1`、`water_shield_age_0/1/2`、`water_spinach_age_0/1`、`wild_rice_stem_age_0` 呈拱（候选）；water_dropwort 4/5 白花 ✓；water_shield 3~5 大浮叶 ✓ | 8 候选 |
| **E15** | `winged_bean_age_0/1(+_stick)` 拱（候选）；winged_bean 4~7 藤 ✓；`winter_melon_age_3` **叶团偏实**（见 §四·7）；yacon 0/2 拱（候选）；yam 插棍 ✓；**branch_fruit 4 格 = 方块状果 + 棋盘十字纹**（§四·2） | 候选 + 1 类 |
| **E16** | 13 张 branch_fruit（bael/canistel/cupuacu/jabuticaba/mangosteen/soursop/black_pepper + 通用）：**每一面都是规则"十字/棋盘"高光**，读作"骰子"而非果皮 ✗ | 1 类（13 张） |

---

## 四、逐类"不足与不符合项"（含未修）

### 1. ✅ 低龄"细拱 / 圆环 / X 交叉"（已修 29 张）

**这是什么**：贴图里两行以上出现"左右各一小段、中间留空"，或一条 1px 的封闭曲线；在 4 片平行板（两对错开 4px）几何下，图案与自己的 +4 副本**拼合成拱门／圆环／交叉**。

**放大证据（改前）**：`px/R49-ZOOM-Z1.png`（arrowhead_age_1 细方框 · perilla_age_0/1 洋红弧）· `Z2`（jobs_tears_age_1 门形 · pearl_millet_age_1 粗拱 · shallot_age_0 拱）· `Z3`（lotus_age_0 环 · water_shield_age_1 · yacon_age_1 **两块棕色板** · mustard_greens_age_1 **大门框** · emmer_age_1/foxtail_millet_age_1 **X**）· `Z6`（fonio_age_0 环 · quinoa_age_0/1 环 · ramie_age_0/1 拱）。

**改后证据**：`px/R49-FIX-B1A/B1B.png`（emmer 1/2 · foxtail 1/2 · pearl_millet_1 · mustard_greens_1 · jobs_tears_1 · arrowhead_1）· `B2A/B2B/B2C.png`（perilla 0/1 · lotus_0 · shallot_0 · spinach_0 · sunchoke_0 · sunflower 0/1 · swiss_chard_0 · taro 1/2 · turmeric_0 · water_caltrop_0 · water_shield_1 · yacon 1/2）· `B3A/B3B.png`（fonio_0 · quinoa 0/1 · ramie 0/1）——全部读作"**贴地散开的几粒小芽**"。

**做法**：把封闭曲线拆成**互不相邻的 1px 点**（苗期语法，同 TFC `lentil_0`），或在底部放**两撮小叶**（每撮 ≤3px，两色）。落盘前用脚本自检 **封闭洞=0 / 同色连通块≤3**（本轮 38 张全部通过）。

### 2. ⚠️ branch_fruit 果实贴图：规则"十字/棋盘"（13 张，未修）

`px/R49-ZOOM-Z5.png`（jabuticaba 紫 · canistel 金 · cupuacu 青）：每个面都是**正中一块亮色 + 四角同色的规则十字**，读作"骰子/方糖"，不是果皮。几何本身是 **4 个 4×5×4 方盒**（`models/block/plant/branch_fruit_ripe.json`，UV 1:1 正确），所以"方块感"来自建模；但**贴图"规则对称图案"是画法问题**（AGENTS.md 明令禁止"色阶规则交替→棋盘格"）。
**建议**：改成**不规则高光 + 果点**，并把十字对称打破；几何若要更像果，可把方盒改成 2 层小盒或切角。

### 3. ⚠️ dead_crop 家族（164 张）：马蹄形 / 竖条纹（未修，本轮新发现）

- **马蹄/圆环**：`R49-REST-R9.png` 第 3 行第 3 格是**亮黄圆环**、同行第 5 格**橙色马蹄**；`R10` 第 3 行第 3 格橙色马蹄；`R11` 第 1 行第 3 格**黄环**、第 4 行第 1 格**黄马蹄**、第 5 行第 5 格**红马蹄**；`R12` 第 1 行第 1 格、第 4 行第 5 格拱形。
- **竖条纹幕**：`R10` 第 1 行第 2 格（粉/棕竖条）· `R13` 第 3 行第 5 格（绿/白竖条）。
- **过饱和"火焰条"**：`R10` 第 4 行第 1/5 格、`R11` 第 2 行第 1 格、`R13` 第 1 行第 2/4 格（亮黄/亮橙粗竖条，读作"火"而不是"枯草"）。
⇒ 枯死态整体"整株换枯色、留收获器官"是对的（chili 仍挂红椒 ✓），但这三种形态在该族里**成规模存在**，建议下一轮按 §1 的语法逐族修。

### 4. ⚠️ wild_crop 家族（86 张）：大块白斑 / 条纹（未修）

`R49-REST-R14.png` 第 4 行第 4 格有一道**贯穿的纯白竖条**，`R13` 第 4 行第 1 格、`R15` 第 2 行第 1 格同类；多格出现**淡粉/淡黄竖条**。野生株整体是"密而透"的 ✓，但**白色花序被画成大块**，在 16px 尺度上非常抢眼，与 TFC 野生株的克制配色不符。

### 5. ⚠️ 低龄"过稀"（op 4~8）——需要逐物种再判

`R49-LIVE-AUDIT.csv` 里 live 贴图 op<8 的共 **48 张**（celeriac_age_1=4 · parsnip_age_1=4 · yacon_age_1=4 · ginger_age_1=4 · celery_age_1=4 …）。
TFC 苗期本来就是"3~7 个像素"（`lentil_0` 5px、`cabbage_0` 3px），**所以不能一律判废**；但在 3D 里 op=4 的根菜苗几乎看不见（E4 里 celeriac/celery/celtuce 的 age_0/1 就是"几个飘着的绿点"）。**建议**：根菜类 age_1 提到 6~10px。

### 6. ⚠️ 果实方块"土块色"

`sisal_age_4/5_fruiting`（E12 第 2 行）与 `purslane_*_fruiting`（E10 第 4 行）顶上的收获方块是**棕/土黄**，与旁边的枝叶对比后读作"顶着一块泥土"。建议给果实/纤维球加 1~2 档明度或改成物种特征色（剑麻纤维偏奶白、马齿苋果偏褐绿）。

### 7. ⚠️ 叶团过实（少数）

`winter_melon_age_3`（E15 第 2 行第 6 格）是一整团绿，看不出"藤 + 叶"；`ramie_age_3_bottom`（Z6 第 6 格）是**密不透风的绿墙**（age_4/5 已修，age_3 未修）。判据：**退开看能不能看透枝叶**。

### 8. ✅ 头部方块（叶球/莲座果）——判为**可接受**

`px/R49-ZOOM-Z4.png`：cabbage_age_5 的球顶面有**亮心 + 暗环**、侧面有竖向色带；cauliflower_age_5 是**奶白球带台阶纹**；kale_age_5_fruiting 是深绿球带亮斑。虽 `maxSame` 达 220~246/256（白皮书口径），**但实看不是"纯色死方块"**，且"立方体 + 整张贴图"是用户裁决要求的，判**通过**。

---

## 五、本轮修掉的 38 张（逐张有改后渲染证据）

| 类别 | 张数 | 文件 |
|---|---|---|
| 低龄细拱/环/X → 散点小芽 | **29** | arrowhead_age_1 · emmer_age_1/2 · fonio_age_0 · foxtail_millet_age_1/2 · jobs_tears_age_1 · lotus_age_0 · mustard_greens_age_1 · pearl_millet_age_1 · perilla_age_0/1 · quinoa_age_0/1 · ramie_age_0/1 · shallot_age_0 · spinach_age_0 · sunchoke_age_0 · sunflower_age_0/1 · swiss_chard_age_0 · taro_age_1/2 · turmeric_age_0 · water_caltrop_age_0 · water_shield_age_1 · yacon_age_1/2 |
| 双段下半"实心墙" → 可透茎叶 | **2** | ramie_age_4_bottom · ramie_age_5_bottom（**保留了接缝行 y0**，seam-audit 172/0 复验通过） |
| 整条"竖条纹幕" → 真实植株 | **7** | buckwheat_age_0/1/2/3/4/5/6（**同株生长序列**：苗→两茎→抽叶→开花，age_4 起出第一朵白花） |

改后证据：`px/R49-FIX-B1A/B1B · B2A/B2B/B2C · B3A/B3B`；buckwheat 有**改前/改后对照** `px/R49-BUCKWHEAT-LADDER.png`（旧）vs `px/R49-BUCKWHEAT-NEW.png`（新）。

**设计稿**（可复核/可重画）：`px/<同名>.txt`；批量落盘脚本 `r49-fix-b1-drafts.ps1` / `r49-fix-b2-drafts.ps1` / `r49-fix-b3-drafts.ps1` / `r49-buckwheat-ladder.ps1`（设计稿由**手工逐行指定**，脚本只做"落盘 + 自检"，没有函数刷图）。

---

## 六、资源层不符合项

| 项 | 数值 | 说明 |
|---|---|---|
| **死贴图（无任何模型引用）** | **749 张** | 661 `block/crop` + 86 `block/wild_crop` + 2 `block/dead_crop`；即 AGENTS.md 记录的 `X_N` 与 `X_age_N` 双套中的旧套。清单见 `R49-LIVE-AUDIT.csv` 里 `live=0` |
| live 贴图总数 | 1645 | 模型引用到的自有贴图（tex-ref-audit 2022 条引用 / 缺 0） |
| **live 且 asym=0** | **7 张** | agave_rosette_fruit_top · napa_cabbage_leafball_head_top（两者是方块顶面，可解释）· amaranth_age_4_bottom/top · amaranth_age_6_bottom/top · quinoa_age_4_bottom（**这 5 张应修**） |
| 同色连通块 > 3 | 22 张 | 全部是 `*_head/_rosette_fruit`（整张贴图的方块表皮），按用户裁决属**设计使然** |

⚠️ **删除死贴图需要 `gradle clean build`**（AGENTS.md 硬约束 §二-4），当前用户禁止构建 ⇒ 本轮**只列出、不删除**。

---

## 七、方法学教训（写给下一轮）

1. **200px 总表只能用来"挑候选"，不能下结论。** 本轮实证：`fenugreek_age_0`、`rhubarb_age_0/1` 在总表里像"拱"，翻开设计稿 + 放大图后是**离散小点 / 红茎**，本来就是好稿。凡要"确认缺陷"，**必须 Cell ≥300 单独渲一次**并写"在哪个位置看到了什么"。
2. **改之前先读设计稿**（`px/<name>.txt`）：本轮靠这一步避免了 3 次误修；同时发现 `buckwheat_age_6` **根本没有设计稿**（是别的流程生成的），所以直接重画。
3. **自检脚本要挡三类硬伤**：封闭 1px 洞（4 邻域）、同色 4 连通块 >3、行内 2 段且跨度 ≥12 且 ≤4px（窄拱/横梁）。本轮 38 张全部自动挡过（含一次真实拦截：`spinach_age_0` 第一稿右子叶形成封闭洞）。
4. **调色板键大小写不敏感**（PowerShell 哈希）：`l`/`L` 会被静默覆盖 —— 本轮 buckwheat 初稿就踩到，已改成 `G`/`L`。
5. **双段作物只改"下半"时，必须原样保留 y0 接缝行**，改完复跑 `seam-audit`（本轮 ramie 4/5 通过 172/0）。

---

## 八、校验门（改完 38 张后复跑）

| 门 | 结果 |
|---|---|
| `tex-ref-audit.ps1` | 自有引用 **2022** 条 / **缺失 0** |
| `seam-audit.ps1` | 有效接缝对 **172** · 对齐 **172** / 错位 **0** |
| `face-axis-audit.ps1` | 31 个模型 152 个元素 / 面类型不符 **0** |
| `lead-lock\stick-pole-audit-lead.ps1` | 44 张杆全同 / 1197 格 0 错 / 0 洞 / 0 杂列 |
| `moddev\tfcfarmingplus\tools\verify.ps1` | blockstate 475 · 模型 2052 · 掉落表 475 · feature 244+244 · 物品模型 429 ⇒ **全部交叉引用有效** |
| `check-geom.ps1 -Path <models>` | 扫描 31 个含 elements 的模型：越界 **0** · uv 非 1:1 **0/31**（叶球/莲座包围盒全部在方块内） |

---

## 九、仍未做 / 未验证（如实交接）

1. **未构建 jar、未实机**（用户明令）——所有结论都只是离线渲染。
2. **243 个 `block/plant` 模型的父模型是 vanilla**（`minecraft:block/leaves` 等），本地缺 1.21.1 资源索引，**无法离线渲染**；这批（含果树树叶）**没有 3D 证据**。
3. **item / seeds / food / fruit_tree 贴图**（292+ 张）本轮只做了 2D 接触表覆盖，**没有做"引用它的模型"级渲染**。
4. `check-geom.ps1` **已补跑**（越界 0 / uv 非 1:1 0-31，见 §八）。（首跑漏了必填参数 `-Path`，已记入教训。）
5. §四·2/3/4（branch_fruit 棋盘纹、dead_crop 马蹄/条纹、wild_crop 白斑）与 §六（749 死贴图、5 张 asym=0）**已定位、未修**。

---

## 十、"对比"部分：与 TFC 原版同条件并排（p28 / y40 / 同尺寸）

用 `rr-review.ps1` 直接渲染 **TFC 原版资源**（`-AssetRoot .probe\ref-tfc\assets`，模型 `tfc:block/crop/*`），
与我方**同科**作物并排：

- `px/R49-CMP-TFC.png`：TFC `lentil_age_0..5` · `cabbage_age_5` · `red_bell_pepper_age_6`
- `px/R49-CMP-OURS.png`：我方 `pea_age_0..3` · `pea_age_4/5_bottom` · `cabbage_age_5` · `chili_age_5`

**看出来的四条差距（都是"不足"，不是"指标不达标"）**：

1. **低龄密度**：TFC `lentil_age_0` 已经是一小丛带光的枝叶，`age_1` 半高；我方 `pea_age_0/1` 只有**几粒孤立小芽**，
   到 age_2→3 才"突然长出来" ⇒ 我方低龄段**偏空、有跳变**。建议：**苗期下沿再加 4~8px 的细枝/小叶**（仍保持不透支的 1px 结构）。
2. **色阶与高光**：TFC 每一龄的叶面上都散布**亮黄绿 1px 高光点**（`lentil_3/4/5` 尤其明显）；我方 `pea`/`chili` 几乎**没有高光**，
   整体偏暗偏闷（深墨绿一坨）。建议：**每株按 TFC 的做法撒 5~12 个亮色 1px 点**（不是整体提亮）。
3. **"环"不必然是缺陷，尺寸才是**：TFC `cabbage_age_5` 自己就是**叶围成一圈、中心偏亮**的形态；我方被判缺陷的是
   **1~2px 细线拼出的几何图形（方框/马蹄/圆环）**。判据：**轮廓要由叶片组成、且尺寸与植株相称**，不是"禁止闭合形状"。
4. **结球作物与 TFC 完全不同**：TFC 白菜是"叶球贴图 + 交叉板"，我方是**立方体 + 整张贴图**（用户 2026-09-27 裁决）。
   我方 `cabbage_age_5` 在 3D 里读作"**方块顶着一圈放射叶**"，识别要靠颜色 + 叶片；这是**裁决使然**，不作为缺陷，
   但下一轮若要更像植物，可在**叶片层数/朝向**上加强（几何不动）。

