# 115 · 第 49 轮：插棍 44 张贴图的「杆」逐像素归位（承接 docs/114 的唯一 P0）

> 本文承接 `docs/114-session-handoff-texture-and-models.md`（资源制作对话交接）。
> 用户的入口指令是「**继承有关资源制作内容的对话文档**」⇒ 先读 `docs/114`/`113`/`111`，
> 再按 `docs/114` §十一 拿基线、收口它列出的**唯一 P0**。
>
> ⚠️ 本轮**未构建 jar、未做任何实机验证**（用户明令）。所有结论来自离线渲染 + `read_image` 实看 + 脚本审计。
> ⚠️ 本文不改 `AGENTS.md`（用户明令：主文档由别人维护）。

---

## 一、继承（114 说了什么 + 我自己重跑的基线）

`docs/114` 的结论是：结球/莲座几何与 UV 已全部到位，**唯一进行中的工作是 44 张插棍贴图的杆换成原版逐像素真值**。
我不引用它的数字，全部自己重跑一遍：

| 校验 | 继承时的实测 | 本轮结束时 |
|---|---|---|
| `check-geom.ps1` | 越界模型 **0** · uv 非 1:1 **0 / 31** | 同（未动几何） |
| `face-axis-audit.ps1` | 0 错配 | 同 |
| `seam-audit.ps1` | 对齐 **172** / 错位 **0** | 同 |
| `audit-all.ps1` | 尺寸非 16×16 **0**；未达标 = sunchoke 7 / okra 4 / artichoke 2 / sunchoke_age 3 / okra_age 1 | 同（未新增） |
| `stick-pole-audit.ps1` | **identical 4 / differ 40 · wrong 295 / 995** | **identical 44 / differ 0 · wrong 0 · holes 0 · stray 0** |
| `tools/verify.ps1` | 全部交叉引用有效 | 同 |

---

## 二、🛑🛑 先修审计：原审计有一个致命盲区（本轮最重要的技术发现）

原 `stick-pole-audit.ps1` **只比较 x7/x8 这两列**。后果：

- `pea` 的杆整根在 **x4/x5**、`cowpea` 在 **x9/x10**、`common_bean` 在 **x6/x7**
  ⇒ x7/x8 上根本没有杆像素 ⇒ `wrong = 0` ⇒ **被算进"identical"，报 OK**。
  我实测：那 4 张 `pea` 就是"identical 4"里的 4 张。**审计把最严重的错判成了合格。**
- 同理 `yam` 的杆是 **x7/x8/x9（宽 3px）**，x7/x8 两列都"对"，只多出一列 → 也不报。

⇒ **"列内像素对不对"这条判据，永远发现不了"杆根本不在这一列"。**

### 2.1 增强后的三条检查（已写进 `stick-pole-audit.ps1`）

| # | 判据 | 为什么 |
|---|---|---|
| 1 | x7/x8 上的木色像素 == canonical 木纹 | 与上半格接续的那两列必须逐像素等于原版 |
| 2 | **x7/x8 不许有洞**（alpha<128 的格子） | TFC 自己的杆列只有"木纹"与"植物"两种像素，**从无透明**（8 张 TFC 插棍贴图 + `stick_top` 实测） |
| 3 | **x7/x8 之外不许有 ≥4 连续行的木色段**（= 第二根杆） | 杆整根偏列 / 多一列都会被抓到 |

**阈值为什么是 4 行**：植物里本来就有棕/红紫色的部件 —— hops 基部叶鞘（x6 的 y13-15，3 行）、
malabar 的紫红茎（`7E2A48`/`A63A62`，1~3 行）、各类 1px 茎点。**它们必须不被报成"第二根杆"**，
所以阈值取 4 行，并且把它们排除在外。

### 2.2 口径自检（必做，否则就是"永远绿"的假审计）

把同一套增强检查跑在**修复前的备份** `bak-stick-pole-r49-20260928/` 上：

```
PRE-FIX: identical=0  differ=44  wrongCells=295  holes=291  strayCols=25
```

⇒ 它确实抓得住旧状态（**不是**只会在修好后报绿的假判据）。

---

## 三、canonical 表本身也要复核（不能只信文档）

我把 TFC 自己的 **8 张插棍贴图 + `stick_top.png`** 逐格 dump，与 `docs/113` §1.2 的 canonical 表对照：

| TFC 贴图 | 与 canonical 表 |
|---|---|
| `green_bean_0/1/2/3_stick.png` | **全部 MATCH**（canonical 表就是从它读的，复核通过） |
| `tomato_3_stick.png` | MATCH |
| `tomato_0/1/2_stick.png` | **2~3 格不同**（y1/y2 的 x7、y7 的 x8 是 `513E0C`，表里是 `58481D`） |
| **`stick_top.png`（上半格专用）** | **14 格不同** —— 它是**另一套相位**的木纹 |

两条修正（写进档，免得下一个人重犯）：

1. 🛑 `docs/113` §1.2 那句「**TFC 全部插棍贴图共用同一套 16 行木纹**」**不准确**：
   green_bean 那一套是 canonical；tomato 有 2~3 格差异；`stick_top` 的 8 行是另一套排列。
2. 🛑🛑 **接缝处那 1px 色阶差是 TFC 自身行为，不要去"修"**：
   我们的下半格 y0 = `58481D/3E2F0A`，上半格 `stick_top` 的 y15 = `513E0C/3E2F0A` —— 差一档；
   **TFC 自己的 `green_bean` y0 也是 `58481D`**，与它的 `stick_top` y15 同样差一档。
   ⇒ 跟 canonical 表就是"与原版完全一致"，**不要为了让接缝像素相同而改 y0**。

---

## 四、修复方案（新工具 `.probe/texture-design/stick-pole-fix.ps1`）

按文件三步，**顺序不可换**：

1. **整张水平平移**，让杆落到 x7/x8：`pea +3` · `cowpea −2` · `common_bean +1`
   - 🛑 **不是只搬杆** —— 叶子是挂在杆上的，只搬杆会让叶脱节/悬空；整张平移保持植物与杆的相对关系。
   - 平移前先查过溢出列是空的（pea x14/x15 = 0、cowpea x0/x1 = 0、common_bean x15 = 0）。
2. **删多余杆列**：`bitter_melon` x6（2~4 行的段）、`yam` x9（整列 15~16 行）。
3. **x7/x8 归位**：木色像素 → canonical；**透明像素 → canonical（补洞）**；植物像素（绿 / 紫红）原样保留。

实测统计（dry-run 与 apply 完全一致）：

```
files: 44   moved: 742   lost: 5   trimmed: 70   holes filled: 59   recolored: 397
```

- `moved 742` = 三个物种整张平移的非透明像素；`lost 5` = pea age2/age3 最右列 x13 的 5 个叶点（平移后越界丢弃，3D 里确认无影响）。
- `trimmed 70` = bitter_melon x6 共 9 格 + yam x9 共 61 格。
- 🛑 `holes filled 59` 是**真 bug 的修复**：`hops`/`yam`/`malabar_spinach`/`winged_bean` 的 **x8,y0 全部缺失**，
  `common_bean`/`pea` 平移后 x7/x8 的 y0、以及若干 x8 中段也有洞 ⇒ 世界里**杆的顶端与上半格之间断 1px**。
- `recolored 397` = 把"自己编的木纹"换回 canonical：`yam` 是 x7 整列 `58481D` / x8 整列 `513E0C`（无木纹节律）、
  `malabar`、`hops` 同病；`winged_bean` 是"58481D/513E0C 规则棋盘交替"；`bitter_melon`/`chayote`/`loofah`/`snake_gourd` 只差 1~3 格。

备份：`.probe/texture-design/bak-stick-pole-r49-20260928/`（44 张改前原样）。

---

## 五、验收（全部实跑 + `read_image` 实看）

1. **`stick-pole-audit.ps1`** → `textures: 44  identical: 44  differ: 0` / `pole cells 1306, wrong 0, holes 0, stray 0`。
2. **2D 网格（带 x7/x8 青色导引带，修复后）**：`px/LEAD-R49-STK-GRID-A-FIX.png`、`px/LEAD-R49-STK-GRID-B-FIX.png`
   —— 44 格**全部绿框**。我在这两张图上看到的三件事：
   - `yam` 的杆**由 3px 变成 2px**，与 TFC green_bean 的杆同宽；
   - `common_bean` / `cowpea` / `pea` 的杆**回到青色导引带正中**（改前分别在左偏 1 格 / 右偏 2 格 / 左偏 3 格）；
   - `bitter_melon` age2/age3 杆**左侧那一段多出来的棕色消失**（改前看起来是 3px 宽、左缘毛糙）。
3. **前后对照**：`px/LEAD-R49-STK-BEFORE-AFTER.png`（11 物种 age3，左改前 / 右改后）。
4. **双方块装配 3D**：`px/LEAD-R49-TWOBLOCK-AGE3.png`
   （上格 = `tfc:block/crop/stick`，下格 = 我们的 `<sp>_age_3_stick`，红线 = 方块交界）。
   我看到的：11 个物种**红线上下两根杆同列、同宽、连成一体**，没有横向错位、没有纵向断裂；
   `hops` 的奶黄绿色花穗、`malabar_spinach` 的品红茎点都还在。
   （3D 里每根杆渲染成"两根柱"是 `block/crop` 四片板几何的固有表现，TFC 原版同样如此，见 `docs/111` §5.2。）
5. **全套校验复跑**：`check-geom` 越界 0 / uv 非 1:1 = 0/31 · `face-axis-audit` 0 错配 ·
   `seam-audit` 172 对齐 / 0 错位 · `audit-all` 尺寸错 0（未达标仍是 sunchoke/okra/artichoke，与基线一致）·
   `verify.ps1` 全部交叉引用有效。
6. **写入范围审计**：最近 30 分钟内 `src` 下被改的**恰好 44 个文件，全部是 `*_age_*_stick.png`**，
   无意外文件名、无新建孤儿文件。

---

## 六、⚠️⚠️ 两条必须先看的警告（给下一个接手者）

1. 🛑🛑 **设计稿与落盘 PNG 已经分叉 —— 不要重跑插棍的绘制链**。
   `px/<sp>_age_N_stick.txt` 与 `px/sl-*`、`px/sh-*`（09-28 01:06~01:11 那批）是这批 PNG 的来源，
   但它们里面的杆**还是旧列 / 旧木纹**；本轮只改 PNG（PNG 是最终产物）。
   ⇒ 重跑 `climb-draw.ps1` / `climb-render.ps1` 会把这轮修复**覆盖回去**。
   若将来确要重跑，必须先把稿子 x7/x8 两列改成 canonical（本轮的 `stick-pole-fix.ps1` 逻辑可复用）。
   （另：`climb-render.ps1` 会写 `.probe/lab-assets` —— 那是覆盖前快照，本来就不该写。）
2. 🛑 **杆的审计口径 = `stick-pole-audit.ps1` 的三条**，不要再退回"只比 x7/x8"。

---

## 七、本轮**没有**做的事（按优先级）

| P | 项 | 说明 |
|---|---|---|
| **P1** | 746 张死贴图清理 | 仍阻塞：删 `src/main/resources` 后必须 `gradle clean build`，用户没允许构建（`docs/111` §三） |
| **P2** | 插棍**植物层**是否再打磨 | 本轮**只动杆，没动植物**（每轮只改一件事）。3D 下 `chayote`/`loofah`/`snake_gourd` 的 age3 仍偏"两条竖绿带"，豆科的叶偏块状；要动需先定规格 |
| **P2** | `kale` 与 `cardoon` 的区分度复核 | 未做（`docs/114` §八 的遗留） |
| **P3** | `branch_fruit*` / `sunflower` 未分面（六面同图） | 未做 |
| **P3** | `sunchoke` / `okra` / `artichoke` 的 LUM/色数未达标 | `audit-all` 未达标榜上的剩余项 |

---

## 八、工具与证据索引

| 工具 | 变化 | 说明 |
|---|---|---|
| `.probe/texture-design/stick-pole-fix.ps1` | **新增** | 三步修复（平移 / 删余列 / 归位+补洞）；默认 dry-run，`-Apply` 才写 |
| `.probe/texture-design/stick-pole-audit.ps1` | **增强** | 原三条中的第 1 条保留，**新增"洞"与"越列"两条**；`-Fix` 仍在 |
| `.probe/texture-design/rr-review.ps1` | 复用 | `-UseLab` 把模型+贴图镜像进 `.probe/rr-lab`（本轮靠它渲染双方块） |
| `.probe/ref-tfc/render-tfc.ps1` | 复用 | 渲染 `tfc:block/crop/stick`（`.probe/rr-lab` 里已有它的模型与贴图） |

**证据图**（`.probe/texture-design/px/`）：
`LEAD-R49-STK-GRID-A-FIX.png` · `LEAD-R49-STK-GRID-B-FIX.png` · `LEAD-R49-STK-BEFORE-AFTER.png` ·
`LEAD-R49-TWOBLOCK-AGE3.png`（改动前同一套网格图是不带 `-FIX` 的同名文件，可作对照）

**渲染命令模板**：
```powershell
$v = 'D:\111\最强服务器\.minecraft\versions\Essential TerraFirmaCraft (TFC)'
Set-Location "$v\.probe\texture-design"
& .\stick-pole-audit.ps1                  # 期望 identical 44 / differ 0
& .\stick-pole-fix.ps1                    # dry-run 看计划（-Apply 才写）
# 双方块 3D：先镜像，再分别渲染上/下半格
& .\rr-review.ps1 -Model 'pea_age_3_stick' -Out 'px\_tmp.png' -UseLab
& "$v\.probe\ref-tfc\render-tfc.ps1" -Model 'tfc:block/crop/stick' -Out 'px\_top.png' -AssetRoot "$v\.probe\rr-lab" -Scale 20 -PitchDeg 28 -YawDeg 40
```
