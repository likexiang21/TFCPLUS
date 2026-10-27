# 116 · 稳定性与完备性审查（代码层第 3 轮）

> 用户指令：**「检查代码稳定性以及是否能够实现要求的内容」** + **「暂时不要构建 jar 进行实机测试」**。
> 本轮**只读审查 + 沙盒验证**，**未编译、未构建、未启动游戏**（遵守明令）。
> 前置：`docs/115`（生成器分叉修复 + 影子跑事故）已完成并复验。
>
> 结论速览：**生成器链稳定且经受了真实并发写入的实战检验；86 种作物的注册/资源闭环完整；
> 但发现 3 个影响游戏行为的既存缺陷（攀爬作物的掉落表），未修，待裁决。**

---

## 一、稳定性结论

### 1.1 已验证稳定 ✅

| 检查 | 方法 | 结果 |
|---|---|---|
| 三个专用生成器 ↔ 真值 | 沙盒重跑 + 逐字节 diff | **116 / 116 identical，differ 0** |
| `gen-crops` 治本 | `-Root` 沙盒跑 + 比对 108 个受保护文件 | **改动 0 个**（此前 78 个） |
| 几何越界 / UV 1:1 | `check-geom.ps1` | 越界 **0**、uv 非 1:1 **0 / 31** |
| 零厚度面类型 | `face-axis-audit.ps1` | 154 元素 **0 错配** |
| 双段接缝 | `seam-audit.ps1` | **172 对齐 / 0 错位** |
| 资源交叉引用 | `tools/verify.ps1` | **全部有效**（blockstate 475 / 模型 2052 / 掉落表 475 / 物品模型 429） |
| 脚本编码 / 语法 | BOM 首 3 字节 + `[Parser]::ParseFile` | 4 个脚本全部 `239,187,191` + 语法 OK |

### 1.2 🛡️ 实战检验（本轮最重要的证据）

审查期间**另一个对话窗口一直在写**（贴图/模型会话，02:18~02:45 持续写入 110+ 个文件），
其中 **02:42:32 它真的跑了一次 `gen-crops.ps1`（真实路径）**。这正是 `docs/112 §3.1` 描述的
"谁后跑谁赢"竞争场景 —— 而结果：

- 莲座 5 物种 × 12 + 叶球 5 物种 × 6 = **90 个 wrapper 全部完好**，`parent` 仍指向自定义几何；
- `crops-manifest.json` 重写后 `kale.rosette` **仍为 true**（说明我改的表生效）；
- 我清理过的 tag 孤儿 `dead_crop/kale` **没有被加回**。

⇒ **治本不是纸面结论，是在真实并发重跑下守住了。**

### 1.3 ⚠️ 不稳定源（3 个，按危险度）

| # | 项 | 现状 | 影响 |
|---|---|---|---|
| 1 | **并发写入者**（另一个对话窗口） | 02:18~02:45 持续写入，最近 3 分钟仍有 33 个文件 | **"脚本 ↔ 真值"对齐是移动靶**。本轮就实测到一次：对方 02:43:08 改了 `sunflower_age_3/4_top.json`（3 元素 → 2 元素），使 `docs/115` 的 116/116 一度失效 → 我已按新真值同步脚本（§三.3） |
| 2 | **`gen-batch2.ps1` 是第三个竞争者** | 物种表含 `kale / lettuce / napa_cabbage / broccoli / cauliflower`，写作物模型时一律 `parent='block/crop'` + TFC 贴图、blockstate 只写 `age=0..maxAge` | 跑它 ⇒ 莲座 5 种 + 叶球 4 种的模型被打回十字，**kale blockstate 从 12 变体退回 6 变体**（第 48 轮修过的 bug 复现）。它**不在重跑链上**，但**没有任何技术屏障**阻止被误跑 |
| 3 | **14 个脚本硬编码 root** | `verify.ps1` `verify-book.ps1` `gen-tags.ps1` `gen-patchouli-book.ps1` `polish-book.ps1` `gen-firmalife-plantable.ps1` `gen-fruit-trees.ps1` `gen-high-bushes.ps1` `gen-batch2.ps1` `gen-batch2x-wild.ps1` `finalize.ps1` `fix-wild-single-placed.ps1` `fix-batch1-food-models.ps1` `gen-dead-and-wild-bushes.ps1` | 无法沙盒试跑（`docs/115 §四` 的事故根因） |

---

## 二、"能否实现要求的内容" —— 完备性结论

### 2.1 注册与资源闭环：完整 ✅

| 维度 | 实测 |
|---|---|
| 作物数 | **86** |
| `_CROP` 定义 | **86** |
| `cropBlocks()` 引用 | **172** = 86 作物 + 86 死株引用 |
| `seedFor()` case | **86**（一一对应） |
| 种子物品模型 | **0 缺失** |
| 种子物品贴图 | **0 缺失** |
| 作物掉落表 | **0 缺失** |
| 无食物数据的 9 种 | 全部是**非食用**产物：`cotton`→`cotton_boll`、`flax/hemp/ramie/sisal`→`fiber/*`、`hops`（酿酒原料）、3 个瓜类→**果实方块**（掉落表 + blockstate 均在） |
| Java 死株 | `DEAD_*` **82** = 81 个 per-crop + 1 个共享 `DEAD_ROSETTE`；两个 tag 各引用 **81** 个 `dead_crop/*` ⇒ **精确吻合** |

### 2.2 blockstate 属性 ↔ Java 方块类型：一一对应 ✅

| 属性组合 | 数量 | 对应 Java 类型 | 判定 |
|---|---|---|---|
| `age` | 51 | `MyCropBlock` | ✅ 单格 |
| `age,part` | 16 | `MyDoubleCropBlock` | ✅ 双格 |
| `age,part,stick` | 11 | `MyClimbingCropBlock`（`singleAge=4, maxAge=7` 全部一致） | ✅ 攀爬 |
| `age,fruiting` | 5 | `RosetteCropBlock`（cardoon/agave/purslane/kale/sisal） | ✅ 莲座 |
| （multipart，无 `age=` 键） | 3 | `SpreadingCropBlock`（winter_melon/cantaloupe/bottle_gourd） | ✅ 蔓延 |

> 3 个"无 `age=` 变体键"的作物**不是异常**：它们的 blockstate 用 `multipart` + `when:{age:N}`，
> 与 TFC `crop/melon.json` 同构。

### 2.3 🛑 发现的真缺陷（**未修**，全部集中在 11 个攀爬作物）

对照 TFC 原版 `green_bean` / `tomato` 掉落表（**权威做法**）：

```jsonc
// TFC 的三个池
{ "properties": { "age": "7", "part": "bottom" } }                    // 产物
{ "properties": { "part": "bottom" } }                                 // 种子
{ "properties": { "part": "bottom", "stick": "true" } } → minecraft:stick  // 回收支架
```

我们（`pea` 为例，**11 个攀爬作物全部相同**）：

```jsonc
{ "properties": { "age": "7" } }        // ❌ 缺 part=bottom
{ }                                     // ❌ 种子无条件（任何 age/part 破坏都掉）
（无木棍池）                              // ❌ 插的棍子不回收
```

| # | 缺陷 | 后果 | 严重度 |
|---|---|---|---|
| 1 | 产物掉落缺 `part=bottom` | 破坏**上格**也掉产物 ⇒ 可反复破坏上格刷产物（TFC 明确用 `part=bottom` 拦住） | 🟠 高 |
| 2 | 种子掉落无 `part=bottom` | 破坏上格也掉种子 | 🟡 中 |
| 3 | 缺木棍回收池 | 玩家插棍消耗木棍，拆掉作物**不返还**（TFC 返还 1 木棍） | 🟡 中 |

> 依据：`MyClimbingCropBlock` 的类注释明确"给作物插棍是它的 `useItemOn` 做的（拿木棍右键幼苗）"，
> blockstate 也确有 `stick` 属性（`pea`/`cowpea` 各 12 处）⇒ 消耗是真、回收缺失也是真。
> 根因：`gen-crops.ps1` 的 `$prodProps` 只判 `$rosette` / `$double`，**漏了 `$climb`**
> （种子池同样只给 `$double` 加 `part=bottom` 条件，且**从未生成木棍池**）。
> 注：16 个双格作物（如 `sorghum`）的 `{age,part=bottom}` + `{part=bottom}` 是**正确**的，
> 问题只在攀爬族。

### 2.4 无法覆盖的一环（遵守明令）

**未编译、未构建 jar、未实机** ⇒ "能否在游戏里真正跑起来"仍缺最终判据。
本轮所有结论都是**静态 + 离线沙盒**级。已知需要在实机里核对的点：
`Unable to load variant`（kale 12 变体）、`Unable to load model`（曾出现字符串型 `"angle":"-45"`）、
莲座是否真有四向叶片、以及 §2.3 的掉落行为。

---

## 三、本次审查阶段的改动（3 项，均已复验）

| # | 项 | 原因 | 证据 |
|---|---|---|---|
| 1 | `tools/crops-manifest.json`：`kale.rosette` `false → true` | 这是**我上一轮引入的不一致**：改了生成器表却没同步 manifest，下游 `gen-tags.ps1`（L29 按 `$_.rosette` 过滤）仍把 kale 当非莲座 | 用生成器自己重写（`gen-crops.ps1 -Root <临时目录>`），逐项比对确认**仅 kale 一项变化**（86 项其余不变） |
| 2 | 清理 tag 孤儿：`data/minecraft/tags/block/mineable/hoe.json` 与 `data/tfc/tags/block/crops.json` 里的 `tfcfarmingplus:dead_crop/kale` | `kale` 是莲座、Java 侧**没有** `DEAD_KALE`，该方块不存在 ⇒ tag 引用是孤儿（与 4 个莲座物种正确排除形成对照） | 引用数 82 → **81**，与 `DEAD_*` 82 − 共享 `DEAD_ROSETTE` 精确吻合；JSON 解析 OK、无 BOM；改后 `verify.ps1` 全绿 |
| 3 | `tools/gen-sunflower-disc.ps1` 同步为新真值：**花盘只在 age5**（age3/4 = 2 元素、age5 = 3 元素） | 对方 02:43:08 改了 `sunflower_age_3/4_top.json`，使脚本与之分叉 | 该改动顺带**解决了 `docs/112 §2.3` 的开放项**（"三龄花盘同大"）⇒ 每龄不同、且花盘只在成熟期出现；同步后 116/116 |

> ⚠️ 第 3 项说明一条纪律：**模型几何的最终形态由贴图/模型会话与用户裁决，代码层负责"生成器 = 真值"**。
> 所以脚本要**跟随**对方的最新真值，而不是坚持旧版本。

**本轮改动文件的备份**：`.probe/texture-design/bak-gen-realign-20260928/`
（`crops-manifest.json.before`、`tags/`、以及上一轮的 18 个模型与 4 个脚本）。

---

## 四、建议的下一步（三选一，需用户裁决）

| 优先级 | 项 | 说明 |
|---|---|---|
| **A** | **修 §2.3 的 3 个攀爬作物掉落缺陷** | 改 `gen-crops.ps1`（`$prodProps` 加 `$climb`、种子池加条件、新增木棍池）+ 同步 11 个掉落表。对齐 TFC 权威做法，但属**掉落机制变更**（产物不再能刷、木棍可回收） |
| **B** | **给 14 个硬编码脚本加 `-Root`** | 纯增量加固（默认行为不变），照 `gen-crops.ps1` 的写法；做完后整条重跑链都可沙盒试跑 |
| **C** | **给 `gen-batch2.ps1` 加护栏** | 最省事的两种：① 文件头加醒目"已废弃，会覆盖莲座/叶球，不要跑"；② 让它写完就报错退出（更硬） |
| — | 编译 + 实机 | 本轮被明令禁止，**未做**；这是唯一能把"资源正确"变成"游戏里正确"的一步 |

---

## 五、复现命令

```powershell
$v   = 'D:\111\最强服务器\.minecraft\versions\Essential TerraFirmaCraft (TFC)'
$mod = "$v\moddev\tfcfarmingplus"

# 稳定性：三生成器 vs 真值（沙盒，安全）
$sb = "$v\.probe\gen-sandbox"
Remove-Item "$sb\src" -Recurse -Force -EA SilentlyContinue
New-Item -ItemType Directory -Force -Path "$sb\src\main\resources" | Out-Null
Copy-Item "$mod\tools\gen-rosette-models.ps1","$mod\tools\gen-leafball-models.ps1","$mod\tools\gen-sunflower-disc.ps1" "$sb\tools\" -Force
Set-Location "$sb\tools"
& .\gen-rosette-models.ps1 -WrappersOnly ; & .\gen-leafball-models.ps1 -WrappersOnly ; & .\gen-sunflower-disc.ps1
& "$v\.probe\texture-design\model-json-diff.ps1" -Left "$sb\src\main\resources" -Right "$mod\src\main\resources"
#   预期：files 116 / identical 116 / differ 0

# gen-crops 治本（必须带 -Root，且 -Root 需指向**完整副本**：lang/tag 是合并式写入）
& .\gen-crops.ps1 -Root "$sb\src\main\resources"

# 四项审计
Set-Location "$v\.probe\texture-design"
& .\check-geom.ps1 -Path "$mod\src\main\resources\assets\tfcfarmingplus\models"
& .\face-axis-audit.ps1 ; & .\seam-audit.ps1
Set-Location $mod ; & .\tools\verify.ps1
```

🛑 **动手前先查并发**：`Get-ChildItem "$mod\src" -Recurse -File | Where-Object { $_.LastWriteTime -gt (Get-Date).AddMinutes(-5) }`
—— 另一对话窗口仍在活动时，**任何全量覆盖都可能吞掉它的成果**。
