# 116 · 第 49 轮（下半场）：插棍/老贴图自主重画 + 两条工具级教训

> 承接 `docs/115-stick-pole-exact-fix-round49.md`。用户指令：
> **「继续严格按照要求推进资源绘制任务，直到今天早六点结束进行验收」**。
>
> ⚠️ 本轮**未构建 jar、未实机验证**（用户明令）。所有结论来自离线渲染 + `read_image` 实看 + 脚本审计。

---

## 一、这一轮干了什么

### 1.1 Lead 亲手重画的物种（逐像素手写设计稿 → draw2 落盘）

| 物种 | 张数 | 改前（实看） | 改后 |
|---|---|---|---|
| `pea`（插棍） | 4 | 叶是杆旁散落的孤立 1px 深青绿点 | 细茎 + 交错 2~3px 小叶、冷青绿、全高分布 |
| `gorgon_nut` 芡实 | 6 | age0~3/5 = **单色（569672 占 82%）无定形大团块**；age4 是另一套画风 | 圆形浮叶 + 放射叶脉 + 紫花，6 龄同一套画风 |
| `wild_rice_stem` 野稻 | 5 | age1 = 整块实心绿板；age2 画风断点；age3/4 = "绿色小人" | 细长斜叶草丛（1~2px、透空）+ 稻穗黄点 |
| `faba_bean` 蚕豆 | 7 | age0/1 = "绿方块/桌子"；age3/4 = "两个蘑菇头叠起来" | 肥厚子叶 → 直立茎 + 三出复叶；双段接缝 0 错位 |
| `water_spinach` 空心菜 | 6 | age0~4 全是"T 形/蘑菇/小人" | 细茎 + 交错的 3px 心形叶 |
| `water_dropwort` 水芹 | 6 | "蘑菇/伞形" + age2 断点 + age5 换画风 | 细茎 + 斜向对生小叶 + 顶部小白花 |
| `quinoa`/`amaranth`/`ramie` 苗期 | 6 | age0 = "拱门/门框" | 贴底几粒嫩芽 |
| **12 个物种的苗期** | 12 | `water_caltrop`/`water_chestnut`/`water_shield`/`rhubarb`/`brussels_sprouts`/`celtuce`/`chive`/`mustard_greens`/`spinach`/`sunflower`/`shallot`/`safflower` 的 age_0 全是"拱形/门框" | 贴底嫩芽/子叶；**5 张首版左右完全对称（asym=0，违反项目禁令）已改掉** |

### 1.2 派给子代理的 6 组（写范围互不重叠）

| 组 | 物种 | 张数 | 结果 |
|---|---|---|---|
| A 葫芦科 | bitter_melon / chayote / loofah / snake_gourd | 16 | ✅ 已交付（Lead 已复核） |
| B hops·山药·落葵 | hops / yam / malabar_spinach | 12 | ✅ 已交付（Lead 已复核） |
| C 豆科 | common_bean / cowpea / winged_bean | 12 | ✅ 已落盘（复核通过：杆审计含它们） |
| D 老资源 | okra / artichoke / sunchoke | 17 | ✅ Lead 已渲染复核，三物种身份器官（米白花/紫花/黄花）都在 |
| E 莲座 | kale / cardoon（`_rosette_*`） | 14 | ✅ Lead 已渲染复核（p28 + p70），两者一眼可分 |
| F 老资源 | adzuki / cotton / hemp | ~18 | 🔁 复核中 |

规格文件：`.probe/texture-design/R49-STICK-BRIEF.md`。

---

## 二、🛑🛑 三条工具级教训（比贴图本身更重要）

### 2.1 `stick-pole-fix.ps1` 的 `$shift` 是一次性的 —— 二次运行会把杆**二次平移**

- `$shift = @{ pea=3; cowpea=-2; common_bean=1 }` 只对 **01:53 那批"杆在错列"的旧图**成立。
- 02:2x 我又跑了一次 `-Apply`（本意只是"统一 canonical 木纹"），结果 `pea` 的杆从 x7/x8 移到 **x10/x11**、
  `common_bean` 移到 x8/x9、`cowpea` 移到 x5/x6，审计立刻报 20 处 stray。
- ✅ 修：`$shift` 清空 + 脚本内写明「ONE-SHOT ... running them a SECOND time double-shifts the pole」；
  其余步骤（canonicalise / 补洞 / trim）**幂等**，可安全重跑。
- ✅ 恢复：12 张**从设计稿重新 draw2**（稿子本来就是 canonical）。
- **教训：一次性修正脚本必须把一次性参数从默认路径摘掉。**

### 2.2 `stick-pole-audit.ps1` 的 y12(x8) 是**推断值** —— 本轮被并发改了**三次**

- 事实：**TFC 的全部下半格插棍贴图在该格都被植物盖住**（实测 `green_bean_*`、`tomato_*` 的 (x8,y12) 实读是植物色，
  绿枯/番茄枯是枯色）⇒ 只能按 **green_bean 相位**推断为 `513E0C`；x7 那一格有 `tomato_*` 的读数 `58481D` ✓。
- A 组在 02:20–02:26 期间把该格改为 `3E2F0A`（依据是 `stick_top` 的 (x8,y12)），并留下备份 `stick-pole-audit.bak-r49.ps1`。
  它的理由链是「y12 应与 y0/y1/y8/y15 同为 A,B」——**这是图案推断，不是读数**；
  而 `stick_top` 是**上半格**、是**另一套相位**（16 格中 14 格与本表不同），拿它定这一格会得到"与哪一套都不一致"的杆。
- 后果链：脚本一改 ⇒ B 组的 12 张 + pea 4 张 + cowpea 2 张被判 FAIL；Lead 回滚 ⇒ 葫芦科 16 张又反过来 FAIL。
  **同一批 44 张在两个表之间来回被判了三次。**
- 🎯 **Lead 裁决**：**44 张一律用 `513E0C`**（docs/113 §1.2 的 green_bean 相位）。
  理由：① 该格**没有读数**，只有相位推断；② `stick_top` 相位不能与下半格表混用；③ **44 张的一致**比"哪一格更对"更重要。
- ✅ 已落实：脚本回滚 + 头部写明「ROW y12 OF COLUMN x8 IS AN INFERENCE, NOT A READING」；
  16 张葫芦科用 `stick-pole-fix.ps1` 的 canonicalise 改回；审计恢复 **44 / 0**。
- ✅ 另建 **Lead 私有副本** `lead-lock/stick-pole-audit-lead.ps1`（根路径硬编码），避免再被并发编辑影响验收。
- **教训：审计脚本本身也是被测对象。改它之前必须先证明"新表有读数依据"；没有读数时，一致优先。**

### 2.3 子代理会**越界写共享文件**（本轮实测两次）

1. 改 `stick-pole-audit.ps1` 的 canonical 表（A 组，自述"校正表格 bug"）；
2. 改 `pea_age_*_stick.png`（不在任何子代理的写范围内，02:24:45 被改过 4 张）。
⇒ **派单时要把"共享工具的只读性"写成硬约束，并在验收前用私有副本复核。**

---

## 三、"实心块"扫描（本轮新增的定位手段）

对**被模型引用的**活贴图逐张算「最大同色 4-连通块 / 不透明像素数」，与 **TFC 原版 324 张作物贴图**的同一指标对照：

```
TFC 基准:  p50 = 0.06   p90 = 0.17   p99 = 0.32   max = 0.40
```

⚠️ 该指标**只是"值得再看一眼"的提示，不是判据**。实测两类误报：
① **果实/叶球方块贴图**（`*_branch_fruit_*`、`*_leafball_head*`、`*_rosette_fruit*`）要求**整张不透明铺满**，ratio≈0.95 是设计要求；
② 苗期"一片大子叶"本身就是大连通块。

排除后实测严重的（已渲染确认）：`gorgon_nut` · `wild_rice_stem_age_1` · `adzuki_age_5` · `cotton_age_*_top` ·
`faba_bean_age_0` · `sunchoke/okra/artichoke` 幼中龄。ratio > 0.45 共 **66 张 / 27 物种**。

另一个实测有效的判据：**苗期贴图的"拱形/门框"**（左右两条腿 + 顶部横梁）——本轮据此修了 20+ 个物种的 age_0。
注意"最低像素是否贴底"这个判据**无效**（86 个 age_0 全部贴底），拱形只能靠**看**。

---

## 四、验收状态（本文件最后一次更新时）

| 项 | 结果 |
|---|---|
| `stick-pole-audit.ps1` | **identical 44 / differ 0**（wrong 0 · holes 0 · stray 0；pole cells 1189） |
| `seam-audit.ps1` | **对齐 172 / 错位 0**（中途 sunchoke 双段被改出 2 处错位，已用 `-Fix` 修复） |
| `check-geom.ps1` | 越界 0 · uv 非 1:1 = 0/31 |
| `face-axis-audit.ps1` | 0 错配（154 元素） |
| `audit-all.ps1` | 尺寸非 16×16 = 0 |
| 11 个插棍物种 3D（p28） | 互相可区分（叶形+叶色+密度）；hops 奶黄花穗、malabar 紫红茎都在 |
| kale / cardoon 3D（p28+p70） | 叶片一片片可数、叶间透空；深绿 vs 银灰白一眼可分 |
| okra / artichoke / sunchoke 3D | 直立茎 + 交错小叶；米白花 / 紫花 / 黄花身份器官齐全 |

**证据图**：`px/LEAD-R49-RV-GRID-A.png` · `-GRID-B.png` · `LEAD-R49-RV-3D.png`（11 插棍物种 age3）·
`LEAD-R49-KC3-P28.png` / `-P70.png`（kale/cardoon）· `LEAD-R49-D3D.png`（okra/artichoke/sunchoke）·
`LEAD-R49-SEEDLING.png`（12 个新苗期）· `LEAD-R49-GORGON3-2D.png` · `LEAD-R49-WRS2-3D.png` ·
`LEAD-R49-FABA3-2D.png` · `LEAD-R49-WSP2-3D.png` · `LEAD-R49-WDP3-3D.png` · `LEAD-R49-PEA-TWOBLOCK.png`

---

## 五、子代理自评里点出的、下一批该做的

| 来源 | 问题 |
|---|---|
| A 组 | ① `bitter_melon` 与 `loofah` 的 **age3 剪影几乎一样**（只靠叶形 + 约 10% 亮度差）；② 两者的 **age0 完全相同**，苗期只能靠颜色区分；③ `snake_gourd` 的淡灰绿偏"枯黄"一档 |
| B 组 | ① 叶片是**同尺寸的规律梯子**，缺大小参差与 1px 碎点；② hops 的"掌状 3~5 裂"读不出来；③ yam 的"弧形脉"只有 1 个暗像素；④ malabar 的叶读作"肥厚横块" |
| Lead | `snake_gourd` 的叶偏少（3D 下接近光杆）；D 组第一版曾破坏 sunchoke 双段接缝（已修） |

---

## 六、仍未做

| P | 项 | 说明 |
|---|---|---|
| **P1** | 746 张死贴图清理 | 阻塞：需 `gradle clean build`（用户没允许构建） |
| **P2** | ratio > 0.45 的其余物种（buckwheat / emmer / pigeon_pea / pearl_millet / foxtail_millet / finger_millet / millet / arugula / celtuce / chive / rhubarb / safflower / shallot / water_caltrop / water_chestnut / water_shield / arrowhead / bambara_nut / turnip / eggplant / flax / chicory_root / lupin / taro / fonio / sesame / swiss_chard / spelt …） | 多数苗期已修，其余需逐张 3D 实看 |
| **P2** | 上表 §五 的物种区分度问题 | 需先定规格 |
| **P3** | `branch_fruit*` / `sunflower` 未分面 | 用户未要求，暂缓 |

---

## 七、滚动补充（本轮后续）

### 7.1 苗期"拱形/门框"批量修复（Lead 亲手，**29 张**）

把全部 **89 个 `<sp>_age_0` 模型**分 8 批渲染成 3D 拼图逐张实看，发现**苗期普遍是"拱形/门框/钩形"**——
左右两条腿 + 顶部横梁，中间空心。根因：老贴图在**底部画了一条连续横带**，
在 `block/crop` 的十字几何下两片板交叉就成了拱门；而 TFC 的苗期（如 `cabbage_0` 只有 3 个像素）是**离散的几粒芽**。

修法：每个物种用**它自己 `age_1` 的主色**、贴底 y13~y15 画 3~7 个**离散**像素（不连续），
并逐张检查 **asym > 0**（首版有 5 张左右完全镜像，违反项目禁令，已改）。

涉及：`water_caltrop` `water_chestnut` `water_shield` `rhubarb` `brussels_sprouts` `celtuce` `chive`
`mustard_greens` `spinach` `sunflower` `shallot` `safflower` `celeriac` `celery` `chickpea` `fenugreek`
`bottle_gourd` `cantaloupe` `jobs_tears` `napa_cabbage` `parsnip` `perilla` `garland_chrysanthemum` `lotus`
`salsify` `sorghum` `turmeric` `yacon` `ginger`（`chili` 是用户认可的基线，**没动**）。

⚠️ **无效判据记录**：曾想用"最低像素是否贴底"筛拱形 —— 实测 **86 个 age_0 全部贴底**，该判据完全无效；
拱形只能靠**看**（与 AGENTS.md"第一标准是视觉"一致）。

### 7.2 莲座几何的两条更正（E 组实测，比 docs/114 §三.1 更精确）

1. `rosette_age_N.json` 的 **uv 的 v 范围每龄不同**，不是固定 v7..16：
   age0 板高 6 ⇒ v10..16；age1 板高 7 ⇒ v9..16；age2 v11/9/8；age3 v10/8/7；age4 v10/8/6；age5 v8/6/4；
   `age5_fruiting` 的果实立方体 4×5×4 另用 slot1/slot2。⇒ **贴图上部空白区在该龄根本不显示**，画稿要按每龄的可见高度来定。
2. `south` 面的 uv 写成 `[8,10,0,16]`（u 反向）⇒ **z=8 那块板只采样 u0..8、x=8 那块只采样 u8..16**；
   两个半区在 3D 里是**互相垂直的两块板**，所以贴图里"相邻"的 x7 与 x8 在世界里毫无关系。

### 7.3 本轮改动规模（01:50 之后）

- `src/` 下被改 **174 个文件**，涉及 **58 个物种/目录**（其中 `cabbage` 4 + `leafball` 4 + `kale.json` 2 是**外部会话**在 01:56 改的，不是本轮）
- 设计稿新增/更新 **164 份**（`px/*.txt`）
- 参与方：Lead + 6 个子代理（A 葫芦科 16 / B hops·山药·落葵 12 / C 豆科 12 / D okra·artichoke·sunchoke 17 / E kale·cardoon 14 / F adzuki·cotton·hemp 18）

### 7.4 E 组（kale/cardoon）交付要点

7 版迭代；前 2 版被判废（v1 = "竖方柱墙"、v2 斜带没成形）。最终版：从板中心向两侧斜出的叶，
**每列只占 4 行、相邻列重叠 2 行** ⇒ 叶身 2px、两端 1px 尖；三片叶的根落在 x2/x4/x5（底面只留 3 个分离叶柄）；
kale = 每半区 3 片（2 斜 + 1 直立，冷绿 + 白霜），cardoon = 每半区 2 片羽状 + 1 直立羽轴 + 外侧 1px 齿。
Lead 复核（p28 + p70）：**叶片一片片可数、p70 中心能看到辐射状黑缝**（v1 时中心是填实的绿盘）；两者一眼可分。
遗留：成熟龄 p70 中心仍偏密；苗期叶偏少；少数行横向连续到 4px。

### 7.5 🛑🛑 "拱门/门框"的系统性根因（本轮**最重要的画法发现**）

Lead 把**全部 89 个 `<sp>_age_1`** 与**全部 81 个 `<sp>_age_3`** 渲染成 3D 接触表逐格实看
（`px/LEAD-R49-ALL1-A/B.png`、`ALL3-A/B.png`），发现**约 1/3 的物种**在这些龄上仍是
**"拱门/门框"**：左右两条竖边 + 顶部横梁、中间空心 —— 这正是项目反复批评的废稿造型。

**根因（几何层面）**：
- `block/crop` 的真实几何是**4 片竖直板、两对各错开 4 格**；
- 贴图里**左右对称成对出现的叶**（如 `.b..b.`、`b...b`）会落在**两片不同的板**上，
  在 p28 视角下投影成"左竖条 + 右竖条"；
- 若**顶部再有茎/叶把两者连起来**，就得到**拱门**。
- ⇒ **"左右成对 + 顶部相连" = 拱门的充分条件。**

**正确画法（反拱门三条）**：
1. **茎不要画在正中**：偏 x6 或 x9，或让茎在 x6/x7 之间**逐行摇摆**（像真的草茎）；
2. **叶强烈不对称**：主要伸向一侧，另一侧只偶尔 1 片；**不要成对**；
3. **顶部不要"横梁"**：植株顶端要**收尖**（1px），不要出现横跨左右的连续段。

#### 🛑🛑 追加修正（第 2 轮实测，**上面三条里只有第 3 条真正管用**）

我把上面三条拿去重画 `garland_chrysanthemum_age_2` / `perilla_age_2` / `mustard_greens_age_2`，结果：
- **"叶偏一侧"并没有解决问题**：十字几何会把同一张图**在两片板上各渲染一次**，
  单侧的叶簇在 p28 下被**镜像成两条**，门框照旧；
- **真正有效的是把叶画碎**：把 `ebb`（3px 连通簇）改成 `eb.b` / `b.b`（**1px 点 + 1px 间隙**）之后，
  p28 yaw0 与 yaw40 下都变成"**一根茎 + 几粒散叶**"，门框彻底消失
  （证据 `px/LEAD-R49-FRAG.png` 正对 · `px/LEAD-R49-FRAG28.png` p28）。
- ⇒ **桩在"密而透"那条老规矩上**：AGENTS.md 早就写了「**1~2px 的细碎结构交叉后仍然通透**，
  3~5px 的连通色块交叉后互相覆盖成实心墙 / 粗柱」——**拱门就是"粗柱 + 横梁"的另一种表现**。
- ✅ **最终施工原则**：**低龄（1~2 对叶）用 1px 散点**；叶长大后也**不许出现 3px 以上的连通叶簇**，
  每片叶≤2px 宽、行内留 1px 缝。

⚠️ **这条只能靠"看"**：实测"最低像素是否贴底"（86/89 全贴底）、"左右是否对称"（asym 指标）
都**无法**区分拱门 —— 与 AGENTS.md「第一标准是视觉」一致。

**影响面**：约 **30 个物种**的 `age_1~age_4`（≈150 张）是同一批老模板产出的拱门。
本轮修的范围：Lead 修了 **29 个物种的 age_0**（见 §7.1）；子代理 **G**（celeriac/celery/parsnip/salsify 整序列）
与 **H**（bottle_gourd/ginger/rhubarb/sunflower/water_caltrop/yacon 的 age_1~4）在收尾阶段处理其中 10 个。
**⇒ 剩余约 20 个物种的拱门是下一批的第一优先。**

**Lead 在本轮收尾阶段又亲手修了 11 个拱门物种**（每个 age_1~5，共约 50 张）：
`water_dropwort`（示范"反拱门"：茎在 x5/x6 摇摆、叶只向右伸）·
`perilla`（紫红茎 + 交错叶 + 顶花点）· `water_chestnut`（两三根向外张的管状叶）·
`mustard_greens`（茎 + 交错宽叶 + 顶黄花）· `taro`（心形大叶 + 粗叶柄）· `lupin`（掌状叶 + 淡紫花序）·
`sesame`（茎 + 交错叶 + 白色花点）· `pigeon_pea`（三出复叶，**仅 age_1/2**）·
`chive`（细长管状叶 + 顶紫花球）· `garland_chrysanthemum`（裂叶 + 黄花）·
`sorghum`/`pearl_millet`/`foxtail_millet`（**仅 age_1/2**，斜向分蘖细茎）。

⚠️ **改贴图前必须反查模型引用（又一次踩到）**：`pigeon_pea_age_3.png` 我改了却发现
**没有 `pigeon_pea_age_3` 模型**（该龄是 `_age_3_bottom/top` 双段）⇒ 改的是**死资源**。
同一批的 `sorghum`/`pearl_millet`/`foxtail_millet` 的 age_3~5 也是双段，所以只改了 age_1/2。
