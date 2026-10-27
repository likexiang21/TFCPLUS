# 112 · 会话迁移交接（**代码层**）

> **本文档的定位**：本对话以 **代码 / 数据 / 工具链** 工作为中心。
> **贴图与几何的美术细节不在本文范围** —— 那些主要发生在之后的第 42~48 轮，
> 见 `docs/94` ~ `docs/113`；**最新整体状态先读 `docs/106` 与 `docs/111`**。
>
> 本文只回答四件事：**本会话在代码层改了什么** · **留下什么** · **哪些坑必须记住** ·
> **重跑生成器之前必须先做什么**（§2，本次核查新增，P0）。
>
> **时间锚点**（全部为文件系统实测，非回忆）：
> `MyCrops.java` 09-26 14:34 · `MyFruitTrees.java` 09-26 14:26 · `MyBranchFruits.java` 09-26 14:18 ·
> `tools/*.ps1` 最后改动 **09-26**；此后 `src/main/java` 与 `tools/` **零改动**，
> 09-27 16:00 之后的改动**全部是资源**（textures 336 · models/block/other 95 · models/block/crop 46 · blockstates 1）。

---

## 0. 30 秒版

| # | 代码层产出 | 核查依据 | 状态 |
|---|---|---|---|
| 1 | **Java：9 种作物 + 8 种果树 + 黑胡椒**（3 个文件） | `cropBlocks()` 86 项 · `new Tree(` 48 · `SPECIES` 7 条 | ✅ 编译通过、构建成功 |
| 2 | **4 张生成器表同步**（`gen-crops` 86 / `gen-fruit-trees` 48 / `gen-branch-fruits` 7 / `gen-patchouli-book` 两张表） | 表项计数 | ✅ 全链路跑通 |
| 3 | **新增脚本 `gen-sunflower-disc.ps1`**（向日葵大花盘几何） | 文件存在、BOM=True | ✅（产物已被后续轮次改动，见 §2.3） |
| 4 | **`gen-rosette-models.ps1` / `gen-leafball-models.ps1` 加 `-WrappersOnly`** | 脚本内 `if ($WrappersOnly) { return }` | ✅ |
| 5 | **A 档资源修复**：`dead_cane` 掉落表 / 23 个 json 去 BOM / 16 个 `.bak` 归档 / 1 个脚本补 BOM | 见 §1.3 | ✅ |
| 6 | **P0 架构问题：4 个生成器竞争同一批文件** | `models/block/crop/*_age_*.json` 有 4 个写入者 | ⚠️ 部分加固，**未治本** |
| 7 | **🛑 P0（本次核查新增）：专用生成器脚本与已修复的 JSON 全面分叉** | `tools/` 09-27 之后改动数 = **0**，但 46 个 crop 模型被改 | 🔴 **未处理，重跑会破坏已有修复** |
| 8 | **构建 5 次**（日志 `build.log`~`build5.log`），最后一次 09-26 15:29:47 | jar 2,504,896 B，`build/libs` 与 `mods/` **大小+时间完全一致** | ✅ 已同步 ⚠️ 此后未再构建 |
| — | 物种缺口 | 作物 86 / 果树 48 / 灌木 12 | **17/17 补齐**（含黑胡椒 18/18） |

---

## 1. 代码层产出（逐文件，可直接核对）

### 1.1 Java 改动（3 个文件）

**`common/MyCrops.java`**（86,893 B，09-26 14:34）
- **kale 改莲座**：删 `DEAD_KALE`（实测 `Contains('DEAD_KALE')` = False）；
  `KALE_CROP` 类型 `MyCropBlock` → **`RosetteCropBlock`**，调用改 `rosette("kale", …)`。
  ⚠️ `kale` 的 blockstate 需要 **12 变体**（含 `fruiting`）。本对话做的是 12 变体，
  但被后续 `gen-crops.ps1` 重跑覆盖回 6 变体，已在第 48 轮回补 —— **当前实测 12 变体**。
  这是"生成器竞争"的典型案例（§3.1）。
- **补 9 种作物**（豆科攀爬 4 + 木豆 + 向日葵 + 大麻 + 高粱 + 剑麻），实测 9/9 个 `*_CROP` 均在：
  `*_CLIMATE` / `DEAD_*`（8 个，**剑麻除外** —— 莲座走共享 `DEAD_ROSETTE`）/
  产物物品（`food(...)` 或 `fibre(...)`）/ `*_SEEDS` / `*_CROP` / `cropBlocks()` / `seedFor()`。
  实测 `cropBlocks()` **86 项**、`seedFor()` **86 个 case**（一一对应）。
- **⚠️ Java 前向引用（踩过，编译失败）**：`DEAD_<X> = dead("x", <X>_CLIMATE)` 里的 `<X>_CLIMATE`
  是**简单名**，而它在文件里定义在**更后面** ⇒ **illegal forward reference**。
  **死株定义必须紧跟它对应的气候定义**（本对话为此把 8 行整体移位）。

**`common/MyFruitTrees.java`**（27,954 B，09-26 14:26）
- `TREES` 表 **39 → 48**（实测 `new Tree(` = 48）：`black_pepper`（树干果实型）+ 8 种
  （`waxberry` `lime` `grapefruit` `kiwi` `wax_apple` `wampee` `amla` `sea_buckthorn`）。
- 参数顺序：`Tree(name, en, donor, Lifecycle[12], 开花色, minT, maxT)`（**注意没有 zh**，中文在生成器表里）。

**`common/MyBranchFruits.java`**（4,842 B，09-26 14:18）
- `SPECIES` **7 条**（含 `black_pepper`）；`LIFECYCLES` + 黑胡椒的 12 月表（**必须含 `FRUITING`**）。
- ⚠️ **两份物候表语义相反，别合并**：
  `MyFruitTrees.TREES` 的 lifecycle **刻意不含 `FRUITING`**（叶只开花，果在干上）；
  `MyBranchFruits.LIFECYCLES` **必须含 `FRUITING`**（否则永不结果）。
- ⚠️ `LIFECYCLES` 用 `Map.of(...)`，**最多 10 对键值** —— 当前 7 对，还有余量。

### 1.2 生成器脚本（7 个改动 + 1 个新增）

| 脚本 | 改动 | 实测 |
|---|---|---|
| `gen-crops.ps1` | 作物表 +9 行 | 表项 **86** |
| `gen-fruit-trees.ps1` | 果树表 +9 行（黑胡椒 + 8） | 表项 **48** |
| `gen-branch-fruits.ps1` | 物种表 +1（黑胡椒） | **7** |
| `gen-patchouli-book.ps1` | **两张表**：`$treeLifecycles` +9、`$crops` +9 | ⚠️ 漏第一张会 `$lc` 为 null 崩掉 |
| `gen-rosette-models.ps1` | ① 几何第三版（竖直面片 = "方案 A"）② 加 `-GeometryOnly` ③ 加 `-WrappersOnly` ④ 物种表 +kale/sisal | ⚠️ **几何逻辑已与 JSON 分叉，见 §2** |
| `gen-leafball-models.ps1` | 加 `-WrappersOnly`；物种表移除 `kale` | ⚠️ 同上 |
| `localize-fruit-tree-models.ps1` | **补 UTF-8 BOM**（含 443 个中文字符却无 BOM，PS 5.1 下必乱码） | ✅ |
| **`gen-sunflower-disc.ps1`（新增）** | 向日葵"茎干 + 大花盘"上半格几何（age3/4/5）。**必须排在 `gen-crops` 之后跑** | ⚠️ 产物已改，见 §2.3 |

⚠️ **双格作物在 `gen-crops` 表里必须显式写 `age=5`** —— 漏了只生成单格段（本对话踩过，
9 个新物种里 4 个受影响：`sunflower` `sorghum` `hemp` `pigeon_pea`）。

### 1.3 代码级资源修复

- **`data/tfcfarmingplus/loot_table/blocks/plant/dead_cane.json`（新增）** ——
  `dead_cane` 方块已注册、blockstate/lang 齐全，但**缺掉落表** ⇒ 破坏/自然消亡的枯藤蔓**什么都不掉**
  （TFC 原版掉 1 木棍）。修复后 `verify.ps1` 掉落表计数 412 → 413。
- **23 个 crop 模型 json 去 BOM**（`broccoli/leafball/lettuce/rosette_*`）——
  全部是早期手工改动遗留（生成器本身用 `UTF8Encoding($false)`，不会再引入）。
  实测 `resources/**/*.json` 4024 个 / 含 BOM **0** 个。
- **16 个 `.bak` 归档**到 `moddev/_archive/bak-20260926/`（**无 git，故不删**）。
- 本对话产出的 8 个 `.ps1` 全部 **BOM=True**（实测首 3 字节 `EF BB BF`）。

### 1.4 构建记录

| 日志 | 时间 | 大小 |
|---|---|---|
| `build.log` | 09-26 14:33 | 10,246 B |
| `build2.log` | 09-26 14:34 | 2,098 B |
| `build3.log` | 09-26 14:35 | 2,744 B |
| `build4.log` | 09-26 14:40 | 2,744 B |
| `build5.log` | **09-26 15:29:47** | 2,744 B |

**产物**：`build/libs/TFCFarmingPlus-*.jar` = `mods/` 同名文件 = **2,504,896 B / 09-26 15:29:47**
（大小与时间一致 ⇒ 已同步）。

⚠️ **这之后第 41~48 轮全部未构建** ⇒ 当前 `mods/` 里的 jar **不含 09-26 15:29 之后的资源改动**
（`src` 最后改动 09-28 01:11，落后约 **1.5 天**）。

---

## 2. 🛑 P0（本次核查新增）· 生成器脚本与已修复的 JSON **全面分叉**

**核查方法**：`tools/` 与 `src/main/java` 在 **09-27 16:00 之后改动数 = 0**；
而同期 `models/block/crop` 有 **46 个**文件被改（09-27 23:28 ~ 09-28 00:33）。
⇒ **第 48 轮的几何修复只落在 JSON 上，生成器脚本一行未同步。**

### 2.1 `gen-rosette-models.ps1` —— 零厚度板的面类型仍写死 `north/south`

| 位置 | 脚本内容 | 当前 JSON（已被第 48 轮修复） |
|---|---|---|
| :50 注释 | "...法线朝 ±Z（N/S）**或 ±X（E/W）**，因此面给 north/south"（**注释自相矛盾**） | — |
| :56-64 `New-LeafFaces` | 只返回 `north` / `south` 两个面 | — |
| :79-80 `Add-Leaf 'E'` 分支 | **沿用同一个 `$faces`** ⇒ 零厚度 **X** 板配 `north/south` | `rosette_age_5.json` 的 5 片 X 零厚度板全部 **`east`+`west`** |

**重跑后果**：X 零厚度板的面**静默退化、什么也不画** ⇒ 回到
"**一半的叶片在游戏里从来没有渲染出来**"（`faces=12/24`）。
判据与权威对照见 `docs/105` / `AGENTS.md` 第 48 轮条目（`tfc:block/plant/sword_fern` 的 x 零厚度板全部写 `east/west`）。

⚠️ **`-GeometryOnly` 不救**：它只跳过贴图与 wrapper，**共享几何 json 照样重写**
（实测当前 `rosette_age_0..5` + `rosette_dead` + `rosette_dead_young` = 8 个文件是 09-28 00:33 版）。
⇒ **跑 `gen-rosette-models.ps1`（含 `-GeometryOnly` / `-WrappersOnly`）之前必须先修 :56-80 的面类型逻辑。**

### 2.2 `gen-leafball-models.ps1` —— 仍是"坐在地上的方盒 + y 零厚度板"

| 位置 | 脚本内容 | 当前 JSON（第 48 轮 v5） |
|---|---|---|
| :70-79 | 4 片板 `from.y = 0, to.y = 0`（**y 零厚度**）却配 `north/south`（**应为 `up/down`**） | 叶板改为**每面一片、在立方体外面**，零相交 |
| :94-99 | 立方体 `from = (8-rad, 0, 8-rad)` / `to = (8+rad, h, 8+rad)` ⇒ **坐地在 y=0** | `leafball_age_5.json` 13 个元素，立方体 **`from=5,8,5` / `to=11,14,11`**（抬高到植株顶部） |

**重跑后果**：退回用户三次点名否定的形态 ——"**一个坐在地上的方盒、顶上插着几片叶**"，
且 4 片 y 零厚度板配错面 ⇒ 同样退化不渲染。
（当前 `leafball_age_2..5` 均为 09-28 00:31 版，影响 5 物种 × 4 龄。）

### 2.3 `gen-sunflower-disc.ps1` —— 花盘高度的分龄参数已丢失

- 脚本 :38 设计：`$sizes = @{ 3 = @(4,12); 4 = @(3,13); 5 = @(2,14) }` ⇒ 花盘高 **8 / 10 / 12px**（随龄长大）。
- **当前 JSON 实测**：`sunflower_age_3/4/5_top.json` 三个文件**完全一样**
  （都 1023 B、都 `from=(11.5,2,1)` / `to=(11.5,14,15)` = **12px**，即 age5 的参数），mtime 均 **09-28 00:25**。
- ⇒ **三龄花盘同大**，违反第 48 轮自己的 ⑤"**每个龄必须与相邻龄不同**"。重跑脚本会**恢复**分龄，
  但会同时丢掉第 48 轮对该文件的其它改动 —— **改之前先 diff**。

### 2.4 结论（写进操作纪律）

> **在修好 §2.1~2.3 之前，任何一次重跑 `gen-rosette-models.ps1` / `gen-leafball-models.ps1`
> 都会静默回退第 42~48 轮的几何成果，而且回退后画面症状是"叶片凭空少了一半"，
> 极难与贴图问题区分。**
> 修法方向（未做）：把面类型按**零厚度的轴**自动选择
> （`from.x==to.x` ⇒ `east/west`；`from.z==to.z` ⇒ `north/south`；`from.y==to.y` ⇒ `up/down`），
> 并把第 48 轮 v5 的立方体/叶板参数回写进脚本。

---

## 3. 关键发现（实测，影响**后续所有新增物种**）

### 3.1 🛑 P0 · 4 个生成器竞争同一批文件（架构问题，**只做了部分加固**）

`models/block/crop/*_age_*.json` 被 **4 个脚本**同时写，**没有任何顺序约定 ⇒ 谁后跑谁赢**：

| 脚本 | 写什么 |
|---|---|
| `gen-crops.ps1` | **普通十字** wrapper |
| `gen-rosette-models.ps1` | **莲座** wrapper（`parent: rosette_age_N`） |
| `gen-leafball-models.ps1` | **叶球** wrapper |
| `gen-batch2.ps1` | — |

本对话为加 9 个物种跑了 3 次 `gen-crops.ps1`，结果把**莲座与叶球的自定义几何全部打回普通十字**
（`parent=rosette` 从 60 → 6、`leafball` 从 30 → 6）。

**本对话的加固**：给两个专用生成器加 `-WrappersOnly`（只写 wrapper、**不碰贴图**），
并跑它们恢复 wrapper（rosette 6→60、leafball 6→30，且**手工贴图时间戳未变**）。

**🛑 未治本**：**没有**改 `gen-crops.ps1` 让它跳过莲座/叶球物种。

**正确重跑链**（顺序有依赖；⚠️ 执行前先读 §2）：

```
【前置】修 §2 的脚本分叉，否则下面的第 2、3 步会破坏已有几何修复
gen-crops
  → gen-rosette-models -WrappersOnly
  → gen-leafball-models -WrappersOnly
  → gen-sunflower-disc
  → gen-tags → gen-wild-injection → gen-patchouli-book → polish-book
  → gen-firmalife-plantable → localize-fruit-tree-models → localize-all-models
  → localize-textures → verify
```

### 3.2 `localize-*` 两套脚本的命名规则**不一致**

| 脚本 | 目标贴图名 | 是否直接产图 |
|---|---|---|
| `localize-textures.ps1` | **去掉 `_age`**（`ginger_age_3` → `ginger_3.png`） | 走 jobs 列表 |
| `localize-all-models.ps1` | **模型全路径**（`ginger_age_3.png`） | ✅ L146 直接调 Java `TintTextures` 产图 |

两者都会处理 `models/block/crop` ⇒ **谁先跑谁定命名**。
**用户已明令：这条不再触碰**（贴图残余作为经验教训保留 —— 见 `docs/111`）。
**接手时只需知道**：模型当前引用 `X_age_N`；`X_N` 是另一套命名，**不要据此判断"哪个是手绘"**
（第 47 轮实测更正：09-26 14:37 **同一分钟**同时重写了 467 张 `X_N` 与 455 张 `X_age_N`）。

### 3.3 新增一个物种要同步的清单（**比文档写的多**）

除 `docs/74` 列的那些，本对话实测还发现：

1. `gen-patchouli-book.ps1` 有**独立的 `$treeLifecycles` 表**（与 `MyFruitTrees.TREES` 必须一致）
2. `gen-patchouli-book.ps1` 的 `$crops` 表**顺序必须与 `crops-manifest.json` 一致**（脚本会自检）
3. 双格作物在 `gen-crops` 表里**必须写 `age=`**，否则不生成双格段
4. 莲座作物的 wrapper 由 `gen-rosette-models.ps1` 负责；叶球由 `gen-leafball-models.ps1`；
   **两者都会被 `gen-crops.ps1` 覆盖**（见 §3.1），**且两者自身已与 JSON 分叉**（见 §2）
5. 新增莲座物种要为它准备 `<sp>_rosette_N.png` 系列（否则 wrapper 引用缺失）
6. **创造栏与渲染层清单是全自动的**（`MyItems.ITEMS` 遍历 / `MyFruitTrees.SAPLINGS+LEAVES` 派生）
   ⇒ **新增物种零手工接入**（这一点是好的）

---

## 4. 踩过的坑（每条都付了代价，**按"下次最容易再踩"排序**）

| # | 坑 | 症状 / 代价 | 正确做法 |
|---|---|---|---|
| 1 | **JS 模板里的 `${x}` 被插值**（`String.raw` 也一样） | PowerShell 的 `${a}`/`${i}`/`${sp}` 被 JS 求值 ⇒ 脚本或文件名**静默改坏**。本对话踩 **6 次** | PowerShell 里一律写 **`$($x)`**；或不用模板字符串 |
| 2 | **PowerShell 变量名大小写不敏感** | `$P = ...` 覆盖了 `$p`（路径）⇒ `ReadAllText` 报"参数个数不对" | 变量名**不要只靠大小写区分**（`$scriptPath` vs `$patch`） |
| 3 | **改 `.ps1` 用 `UTF8Encoding($false)` 写回会剥 BOM** | PowerShell 按 ANSI 解中文 ⇒ 报**一堆假语法错**（实测 32 个）。本对话踩 2 次 | 读写保持 BOM：`ReadAllBytes` 判首 3 字节，写回时**补 `EF BB BF`**，并 `[Parser]::ParseFile` 复验 |
| 4 | **`IndexOf` 锚点会命中第一个匹配** | 用 `WATER_SHIELD_CROP.get()` 定位 `cropBlocks()`，命中的却是前面 `seed(...)` 里的同名调用 ⇒ **写坏了 seed 调用** | 先定位**方法**（`IndexOf("public static Block[] cropBlocks()")`），再在**其内部**找锚点 |
| 5 | **Java 静态字段前向引用** | `DEAD_PEA = dead("pea", PEA_CLIMATE)` 而 `PEA_CLIMATE` 在后面 ⇒ **编译失败** | 简单名引用必须**先定义后使用** |
| 6 | **`gen-crops.ps1` 的表漏 `age=`** | 双格作物只生成 `age_0..2`，**没有双格段模型** | 对照 `faba_bean`：`age=5; double=$true; singleAge=3;` |
| 7 | **PowerShell `-match` 大小写不敏感** | 用 `'[a-z]'` 判"有无小写"⇒ **恒为真**，86 项全部误报 | 需要区分大小写时用 **`-cmatch` / `-ccontains` / `-ceq`** |
| 8 | **`@(...)` 数组字面量里不能写二元表达式** | `@($hi, $baseY + $h, $hi)` 被解析成 **4 个元素** ⇒ 立方体变零高度、只剩 4 个面 | 表达式**先赋值到变量**再放进数组 |
| 9 | **生成器表与 Java 表必须双改** | 只改一边 ⇒ 资源与注册不一致 | 每次新增物种：**Java 表 + 生成器表 + 手册表**一起改 |
| 10 | **本 PowerShell 里 `if` 不能当表达式用**（本次核查踩到） | `('x' + (if($c){}else{}))` 报 `The term 'if' is not recognized` | 先算到变量再拼字符串 |

---

## 5. 现状与未完成（代码层视角）

### 5.1 现状（实测）
- **`src/main/java` 自 09-26 14:34、`tools/` 自 09-26 未再改动** ⇒ 代码层稳定
- 资源规模：作物 blockstate **86** / 果树 sapling blockstate **48** / `resources/**/*.json` 4024 个（BOM 0）
- `verify.ps1` **全绿**：blockstate 475 / 模型 2052 / 掉落表 475 / 物品模型 429
- `verify-book.ps1` 784 页
- **jar 停在 09-26 15:29**（2,504,896 B），**落后约 1.5 天资源改动**

### 5.2 未完成（按对"可玩性"的影响排序）

| 级别 | 项 | 说明 |
|---|---|---|
| 🔴 P0 | **构建 + 实机** | 项目**至今零有效实机验证**；构建后必查 `Unable to load variant`（kale 12 变体）、`Unable to load model`、莲座是否真有 4 方向叶片 |
| 🔴 P0 | **修 §2 的生成器分叉** | 不修 ⇒ 任何重跑都会静默回退第 42~48 轮几何 |
| 🟠 P1 | **`gen-crops.ps1` 跳过逻辑**（治本 §3.1） | 需要动核心生成器，风险中等 |
| 🟠 P1 | 产物链（**0 配方**） | 谷物 7 件套等；用户说放后面 |
| 🟡 P2 | `build.gradle.kts` 未开 `-Xlint`/`-Werror` | 编译警告不可见 |
| 🟡 P2 | `plantable` 12 组冗余（`pear` + `fpt_pear`） | 155 文件 / 143 唯一 |
| ⬜ P3 | 批次 11 `CrownFruitBlock` | 用户明令暂缓 |

---

## 6. 复现命令（本文所有结论都可复跑）

```powershell
$v = 'D:\111\最强服务器\.minecraft\versions\Essential TerraFirmaCraft (TFC)'
$mod = "$v\moddev\tfcfarmingplus"

# ---- 核查本文结论（只读，安全） ----
# Java 表规模
Select-String "$mod\src\main\java\com\example\tfcfarmingplus\common\MyCrops.java" -Pattern 'KALE_CROP ='
Select-String "$mod\src\main\java\com\example\tfcfarmingplus\common\MyFruitTrees.java" -Pattern 'new Tree\(' | Measure-Object

# §2 的分叉判据：tools 与 java 的改动时间
Get-ChildItem "$mod\tools" -File | Where-Object { $_.LastWriteTime -gt (Get-Date '2026-09-26 16:00') }   # 应为空
Get-ChildItem "$mod\src\main\resources\assets\tfcfarmingplus\models\block\crop" -File |
  Where-Object { $_.LastWriteTime -gt (Get-Date '2026-09-26 16:00') } | Measure-Object               # 46

# ---- 构建 + 同步（⚠️ 先确认没有正在跑的生成器；不要先跑生成器） ----
Set-Location $mod; gradle build --console=plain
Copy-Item "$mod\build\libs\TFCFarmingPlus-NeoForge-1.21.1-0.1.0.jar" "$v\mods\" -Force

# ---- 校验 ----
& "$mod\tools\verify.ps1"; & "$mod\tools\verify-book.ps1"

# ---- 几何审计（第 48 轮新增） ----
& "$v\.probe\texture-design\check-geom.ps1"       # 越界 / UV
& "$v\.probe\texture-design\face-axis-audit.ps1"  # 零厚度轴 vs 面类型（§2 的自动判据）
& "$v\.probe\texture-design\seam-audit.ps1"       # 双段接缝
& "$v\.probe\texture-design\rr-review.ps1"        # 批量带标签检查图 → read_image 实看

# ---- 查"模型到底引用哪个贴图"（最有效的排查） ----
Get-ChildItem "$mod\src\main\resources\assets\tfcfarmingplus\models" -Recurse -Filter '*.json' |
  Select-String -Pattern 'tfcfarmingplus:block/crop/([A-Za-z0-9_]+)' |
  ForEach-Object { $_.Matches[0].Groups[1].Value } | Sort-Object -Unique
```

---

## 7. 给新对话的第一件事

1. **读 `docs/111`（09-28 01:29，最新）+ `docs/109` / `docs/110`** 拿最新整体状态；
   本文只保证**代码层**结论，资源层以它们为准。
2. **若目标是"让它能玩"**：先 `gradle build` + 同步 jar + 实机（P0）。
   **不要先跑生成器** —— 见 §2。这是唯一能证明"前面所有几何/贴图工作在游戏里生效"的动作。
3. **若目标是"改几何"**：先修 §2.1/§2.2 的面类型逻辑，**再**跑生成器；否则会静默回退。
4. **若目标是"继续加物种"**：先读 §3.3 ——
   **新增一个物种要改 3 张 Java/生成器表 + 2 张手册表**，且**必须按 §3.1 的重跑链顺序跑**。
5. **不要用 `X_N` vs `X_age_N` 判断"哪套是手绘"**（§3.2，以及 `docs/103` 的更正）。
6. **不要动 `AGENTS.md`**（用户要拆两个对话窗口，该文件被两边自动加载）；
   窗口专属内容一律写进 `docs/*.md`。**不要动贴图的"死资源"**（用户要求作为教训保留）。
