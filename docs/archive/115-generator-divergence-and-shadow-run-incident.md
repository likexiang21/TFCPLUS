# 115 · 生成器分叉修复 + 影子跑事故（代码层第 2 轮）

> **本文档定位**：接手 `docs/112`（代码层交接）后的**第一轮实际施工**记录。
> 用户指令：**「继承有关代码实现的对话和文档」** → 实测基线后选定
> **「修生成器分叉 + 治本竞争」**（docs/112 §2 / §3.1 的两个 P0）。
>
> ⚠️ 本轮**未构建 jar、未实机验证**（沿用用户明令）。所有结论来自影子沙盒 + 逐字节 diff + 只读审计脚本。
> 🛑 **本文档记录了一次真实事故**（§四）：我用"影子沙盒"跑 `gen-crops.ps1`，它**照写真实资源树**，
> 2416 个文件被重写，只能从快照全量回滚。根因与防线都写在文里，**动手前必读**。

---

## 一、一句话结论

`gen-crops.ps1`（核心生成器）与三个专用几何生成器（`gen-rosette-models` / `gen-leafball-models` /
`gen-sunflower-disc`）**已与磁盘上的真值完全对齐**：
三个专用生成器在沙盒里重跑，产出与真实资源 **116/116 逐字节一致**；
`gen-crops.ps1` 重跑**不再改动任何莲座 / 叶球模型、blockstate、掉落表**（108 个受保护文件 0 改动）。
顺带修掉 **4 类真 bug**（§三），其中 `kale` 的两处会影响游戏行为（已明确标注）。

---

## 二、三个专用生成器的分叉修复（docs/112 §2.1~2.3）

### 2.1 `gen-rosette-models.ps1` —— 面类型按零厚度轴自动选择

**修复前**：`New-LeafFaces` 只返回 `north`/`south`，`Add-Leaf 'E'` 分支沿用同一份 faces
⇒ **X 零厚度板配 north/south 面**，面静默退化（第 48 轮实测 `faces=12/24`，"一半叶片从未渲染"）。

**修复后**：几何改由**层表字符串**驱动，面类型与轴严格绑定：

```powershell
$stageSpec = @(
    '45:6',                 # age0        ← "角度:叶长"，层序 45 -> 22.5 -> 0
    '45:7',                 # age1
    '45:5;22.5:7;0:8',      # age2
    '45:6;22.5:8;0:9',      # age3
    '45:6;22.5:8;0:10',     # age4
    '45:8;22.5:10;0:12'     # age5
)
$fruitSpec = '45:8;22.5:10;0:10'   # 结果态：0° 层 12 -> 10，给果实立方体让位
```
- `from.z == to.z` ⇒ 只发 `north`/`south`；`from.x == to.x` ⇒ 只发 `east`/`west`；
- **`angle == 0` 的层只发一片/平面**（N/S 共面、E/W 共面会 z-fighting；
  这正是真值 `rosette_dead_young` 只有 2 个元素、`rosette_age_*` 的 0° 层只有 2 片的原因）；
- UV 与板长 1:1：`v0 = 16 - L`（底对齐 v16 = 地面线）；
- **所有整数值一律走 `Norm-Num`**：`ConvertTo-Json` 会把 `[double]4` 写成 `4.0`，
  而 MC 自己的 json 与磁盘真值都写 `4` —— 用 `[int]` 才能逐字节一致，只有 `22.5` 保持 double。

### 2.2 `gen-leafball-models.ps1` —— v3/v8 两套布局 + 立方体抬高

**修复前**：4 片 `from.y = to.y = 0` 的水平板（**y 零厚度却配 north/south**）
＋ 立方体 `from = (8-rad, 0, 8-rad)`（**坐地在 y=0**）⇒ 正是用户三次点名否定的
"一个坐在地上的方盒、顶上插着几片叶"。

**修复后**：按真值分成两套布局（**它们的元素顺序本来就不同**，不能合并）：

| 龄 | 布局 | 元素 | 说明 |
|---|---|---|---|
| age0/1 | **v3** | 4 | 单层 45°，顺序 **N-, S+, E-, W+** |
| age2..5 | **v8** | 13 | 0° 层(N,E，**无 rotation 节点**) → 22.5°(N-,E-,N+,E+) → 45°(N-,E-,N+,E+) → **2 片对角叶(yaw ±45)** → 立方体 |

- 立方体**一律 `y1 = 8`**（植株顶部，比 0° 叶板高 2，成为最高器官 ⇒ 顶面 + 侧面可见）；
- 对角叶长度 = **0° 层长度**（`len0`），保证不切进立方体；
- 立方体 **`up` 用槽 `#1`（顶面贴图）、`down` 用槽 `#2`（侧面贴图）**，UV 与 `up` 相同 —— 这是真值，
  我第一版写成 `down = $top`（`#1`）被 diff 抓出来；
- 立方体 1:1 采样矩形随龄变大（`side` 4×3 / 5×4 / 6×5 / 6×6，`top` 4×4 / 5×5 / 6×6 / 6×6）。

### 2.3 `gen-sunflower-disc.ps1` —— 回到真值（含 `rescale` 与 UV 1:1）

**修复前**：十字茎 `0.8..15.2`（无 `rescale`）、花盘按 age 分龄 **8/10/12px**、花盘 uv 整张 16×16。

**修复后**：按磁盘真值 —— 茎 `0..16` + `rescale:true`；花盘 `[11.5, 2, 1] → [11.5, 14, 15]`，
uv `east [1,4,15,16]` / `west [15,4,1,16]`（14×12，与板的世界尺寸 1:1）。

🛑 **一个开放的决策点（留给用户 / 贴图对话裁决）**：真值里 **age3/4/5 的花盘同为 12px**，
即第 48 轮"每龄必须与相邻龄不同"在花盘尺寸上**不成立**（三龄贴图仍不同）。
脚本**按真值输出**并在文件头写明这个矛盾 —— 恢复分龄要同时改 `from/to` + UV 窗口 + 贴图采样区，
属于**美术/几何决策**，不是生成器 bug。**我没有擅自恢复分龄**。

### 2.4 `gen-crops.ps1` 竞争治本（docs/112 §3.1）

**修复前**：`[7] 作物模型` 的 `if ($rosette)` 分支会把莲座模型写成
`{parent:"block/crop", textures:{crop:"tfc:block/crop/<ref>_N"}}`（普通十字 + TFC 占位贴图）
⇒ **谁后跑谁赢**，把自定义几何静默打回原形。

**修复后**：莲座与叶球在模型段**短路**（不写任何模型），只保留 blockstate / 掉落表 / 物品模型的生成：

```powershell
$leafballSpecies = @('lettuce', 'cauliflower', 'broccoli', 'napa_cabbage')
if ($rosette) {
    # 莲座：12 个模型由 gen-rosette-models.ps1 生成 —— 不要在这里写模型
} elseif ($leafballSpecies -contains $n) {
    # 叶球：6 个模型由 gen-leafball-models.ps1 生成
} elseif ($climb) {
```

### 2.5 贴图保护（新增，防第二类静默回退）

两个专用生成器内嵌的**程序化占位贴图**函数（`New-LeafAtlas` / `New-FruitTexture` / `New-HeadTexture`）
现在**不覆盖已存在的文件**，除非显式给 `-Force`：

```powershell
if ((Test-Path $out) -and (-not $Force)) { return }
```

⇒ 裸跑 `gen-rosette-models.ps1` 也不再有覆盖第 42~48 轮手绘贴图的风险（此前是有风险的）。

---

## 三、顺带发现的 4 类真 bug（已全部修复）

| # | 位置 | 症状 | 性质 |
|---|---|---|---|
| 1 | `leafball_age_2/3/4/5.json` | 各 1 处 **`"angle":"-45"`（字符串型数字）**，其余 4 处同款写的是数字。Gson 可能宽容解析，也可能报 `Unable to load model` | 脏数据，**已修为数字** |
| 2 | `assets/tfc/models/block/crop/cabbage_age_2..5.json` | 只有 **2 个贴图槽**：槽 1 错指 `cabbage_leafball_head`（侧面），**缺槽 2** ⇒ 球的顶面用侧面贴图、侧面回落到**共享占位贴图** `leafball_head.png`（第 48 轮 §3.4 的"20 个包装模型改分面"漏了 tfc 命名空间这 4 个） | **真 bug**，已修为 3 槽 |
| 3 | `gen-crops.ps1` 物种表的 `kale` 行 | **漏 `rosette=$true`**（Java 侧 `KALE_CROP` 明确是 `RosetteCropBlock`）⇒ 重跑会把 `kale` 的 blockstate 从 **12 变体退回 6 变体**、6 个 `kale_age_N` 打回十字（第 48 轮刚修过的 bug 复现）、6 个 `_fruiting` 模型变死资源 | **真 bug**，已补标志 |
| 4 | `loot_table/blocks/crop/kale.json` | 产物掉落条件只有 `{"age":"5"}`，**漏 `"fruiting":"true"`**；4 个莲座物种（cardoon/agave/purslane/sisal）**全都有** ⇒ **未结果的 kale 被破坏也会掉产物** | **真 bug + 游戏机制变更**（见下） |

> ⚠️ **机制变更声明（第 4 条）**：本类改动会影响掉落行为（由"age=5 即掉"改为"结果后才掉"）。
> 与 4 个莲座物种保持一致，但**它是行为变更，不是纯资源格式修复**，请用户知悉。
> 备份：`.probe/texture-design/bak-gen-realign-20260928/loot_crop_kale.json.before`。

---

## 四、🛑🛑 影子跑事故（根因 + 恢复 + 防线）

### 4.1 发生了什么

我建了影子沙盒 `.probe/gen-sandbox/`（结构 `tools/` + `src/main/resources/`）来**试跑**生成器，
理由是三个专用生成器的 `$root = Join-Path $PSScriptRoot '..\src\main\resources'` —— 沙盒有效，实测通过。

**但 `gen-crops.ps1` 不是这样**。它的 root 是**硬编码绝对路径**：

```powershell
$root = "D:\111\最强服务器\.minecraft\versions\Essential TerraFirmaCraft (TFC)\moddev\tfcfarmingplus\src\main\resources"
```

⇒ 我以为在沙盒里跑，它却**直接重写了真实资源树**（两次，旧版 + 新版各一次）。

**损失面**：真实 `src` 下 **2416 个文件**被重写，其中包括
**莲座 4 物种 × 12 = 48 + 叶球 4 物种 × 6 = 24 = 72 个自定义几何 wrapper 被打回普通十字**，
外加 blockstate / 掉落表 / 世界生成 / lang 等（模型 742、placed_feature 172、configured_feature 172、
dead_crop 模型 164、…）。

### 4.2 为什么能完全恢复

A/B 脚本在跑之前**先把真实 `resources` 复制成了两份沙盒副本**（`gen-crops-ab/old|new`）
⇒ 这两份副本恰好是**破坏前的完整快照**（4024 json + 2375 png）。

恢复后复核：与快照**全量 6399 个文件逐个 SHA256 比对，差异 0**；四项审计全绿（§五）。
`Copy-Item` 保留源文件 mtime ⇒ **时间戳考古也一并复原**（否则"哪些是贴图对话改的"将永久失真）。

### 4.3 防线（已落地 + 必须遵守）

1. ✅ **`gen-crops.ps1` 已加 `-Root <dir>` 参数**（默认空 = 真实树，行为不变）：
   ```powershell
   param([string]$Root = '')
   $root = $Root
   if ([string]::IsNullOrEmpty($root)) { $root = "D:\...\src\main\resources" }
   ```
   沙盒试跑：`& .\gen-crops.ps1 -Root '<sandbox>\src\main\resources'`
2. 🛑 **跑任何生成器之前，先确认它的 `$root` 是 `$PSScriptRoot` 派生的还是硬编码的**。
   本仓库**仍有 14 个脚本是硬编码**（见 §六）：
   `verify.ps1` `verify-book.ps1` `gen-tags.ps1` `gen-patchouli-book.ps1` `polish-book.ps1`
   `gen-firmalife-plantable.ps1` `gen-fruit-trees.ps1` `gen-high-bushes.ps1` `gen-batch2.ps1`
   `gen-batch2x-wild.ps1` `finalize.ps1` `fix-wild-single-placed.ps1` `fix-batch1-food-models.ps1`
   `gen-dead-and-wild-bushes.ps1`
3. 🛑 **任何"全量覆盖"操作之前，先确认有没有并发写入者**。本轮期间**另一个对话窗口在 01:53:06
   一次性写入 44 张插棍贴图**（`*_age_N_stick.png`，正是 docs/114 §八 P0 的交付）。
   我的快照复制于 01:56 ⇒ 恰好包含它，**没有丢数据**；但这是运气，不是设计。

### 4.4 证据链

- 破坏证据：真实 `cardoon_age_0.json` 一度变成 `{"parent":"block/crop","textures":{"crop":"tfc:block/crop/beet_0"}}`（mtime 01:57:51）
- 恢复证据：快照 vs 真实 **6399 文件 0 差异**（含 PNG）
- 恢复源保留：`.probe/gen-crops-ab/old/`（**未删，作为破坏前快照**）

---

## 五、验收证据（全部可复跑）

| 项 | 命令 | 结果 |
|---|---|---|
| 三生成器 vs 真值 | `model-json-diff.ps1 -Left <sandbox> -Right <resources>` | **116 / 116 逐字节一致，differ 0** |
| gen-crops 治本 | 沙盒 `gen-crops.ps1 -Root <sandbox>` 跑后比对 108 个受保护文件 | **改动 0 个**（此前 78 个） |
| 写入量对照 | 同上（日志"本次写入 N 个文件"） | 2375 → **2293**（少写 82 个莲座/叶球文件） |
| 几何越界 / UV | `check-geom.ps1` | 越界 **0**、uv 非 1:1 **0 / 31** |
| 面类型 vs 轴 | `face-axis-audit.ps1` | 154 元素 **0 错配** |
| 双段接缝 | `seam-audit.ps1` | **172 对齐 / 0 错位** |
| 资源交叉引用 | `tools/verify.ps1` | **全部交叉引用有效**（blockstate 475 / 模型 2052 / 掉落表 475 / 物品模型 429） |

**新增工具**：`.probe/texture-design/model-json-diff.ps1`（两棵资源树逐字节 + 结构路径 + **标量类型**比对；
⚠️ 它一开始漏报类型差异 —— `"-45"`(String) vs `-45`(Int32) 在 `"$a" -cne "$b"` 下相等，现已加类型检查）。

---

## 六、仍未解决 / 风险清单

| 级别 | 项 | 说明 |
|---|---|---|
| 🔴 | **jar 停在 09-26 15:29** | 比 `src` 落后约 1.5 天；**项目至今零有效实机验证**。构建后必查 `Unable to load variant`（kale 12 变体）、`Unable to load model`（`"angle":"-45"` 曾在此列） |
| 🟠 | **14 个脚本硬编码 root** | §4.3 已列全。建议逐个加 `-Root`（纯增量、默认行为不变），但**本轮只改了 gen-crops.ps1** |
| 🟠 | **并发写入者存在** | 贴图对话窗口仍在活动（01:53 写入 44 张贴图）。**任何全量覆盖前先查 mtime** |
| 🟡 | `sunflower` 花盘三龄同大 | 设计决策待裁决（§2.3），脚本已按真值输出并注明 |
| 🟡 | `dead_crop/kale` 孤儿 | 模型 2 个（`kale.json` / `kale_young.json`）＋ 掉落表 1 个，**已无对应方块**（kale 用共享 `dead_rosette`）。**未删**：删 `src/main/resources` 下文件必须 `gradle clean build`，用户明令不构建 |
| 🟡 | 746 张死贴图 | docs/111 §三 记录，同样等构建许可 |
| ⬜ | 44 张插棍贴图的杆像素 | 由**另一个对话窗口**负责（`stick-pole-audit.ps1` 目标 `differ: 0`），本轮未触碰 |

---

## 七、命令速查

```powershell
$v   = 'D:\111\最强服务器\.minecraft\versions\Essential TerraFirmaCraft (TFC)'
$mod = "$v\moddev\tfcfarmingplus"

# ---- 验收：三生成器 vs 真值（沙盒，安全）----
$sb = "$v\.probe\gen-sandbox"
Remove-Item "$sb\src" -Recurse -Force -EA SilentlyContinue
New-Item -ItemType Directory -Force -Path "$sb\src\main\resources" | Out-Null
Copy-Item "$mod\tools\gen-rosette-models.ps1","$mod\tools\gen-leafball-models.ps1","$mod\tools\gen-sunflower-disc.ps1" "$sb\tools\" -Force
Set-Location "$sb\tools"
& .\gen-rosette-models.ps1 -WrappersOnly
& .\gen-leafball-models.ps1 -WrappersOnly
& .\gen-sunflower-disc.ps1
& "$v\.probe\texture-design\model-json-diff.ps1" -Left "$sb\src\main\resources" -Right "$mod\src\main\resources"
#   预期：files 116 / identical 116 / differ 0

# ---- 验收：gen-crops 不再回退（必须带 -Root，否则会写真实树！）----
& .\gen-crops.ps1 -Root "$sb\src\main\resources"

# ---- 四项只读审计 ----
Set-Location "$v\.probe\texture-design"
& .\check-geom.ps1 -Path "$mod\src\main\resources\assets\tfcfarmingplus\models"
& .\face-axis-audit.ps1 ; & .\seam-audit.ps1 ; & .\stick-pole-audit.ps1
Set-Location $mod ; & .\tools\verify.ps1
```

**重跑链（docs/112 §3.1，前置条件已解除）**：

```
gen-crops
  → gen-rosette-models -WrappersOnly      # 莲座 wrapper（含 kale）
  → gen-leafball-models -WrappersOnly     # 叶球 wrapper + tfc cabbage
  → gen-sunflower-disc
  → gen-tags → gen-wild-injection → gen-patchouli-book → polish-book
  → gen-firmalife-plantable → localize-fruit-tree-models → localize-all-models
  → localize-textures → verify
```
⚠️ 除 `gen-crops` 外，链上 `gen-tags` / `gen-patchouli-book` / `polish-book` / `gen-firmalife-plantable`
**仍是硬编码 root** ⇒ **不要用沙盒试跑它们**（会直接写真实树）。

---

## 八、给接手者的第一件事

1. **读本文 §四**（事故）与 `docs/112`（代码层总交接）。
2. 若目标是"让它能玩"：`gradle build` + 同步 jar + 实机（P0，需用户许可）。
3. 若目标是"继续加固工具链"：把 §4.3 的 14 个脚本逐个加 `-Root`（照 `gen-crops.ps1` 的写法）。
4. 若目标是"改几何/贴图"：**动 `gen-*` 之前先修 §4.3 第 2 条的检查习惯**，
   跑完立刻用 `model-json-diff.ps1` 对真值做 0 差异验收。
5. 🛑 **不要动 `AGENTS.md`**（用户明令）；🛑 **不要擅自删 `src/main/resources` 下的文件**（需 `gradle clean build`）；
   🛑 **不要删 `.probe/gen-crops-ab/old/`**（它是本轮事故的破坏前快照）。
