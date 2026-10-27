# 76 交接补遗：更早一轮（flash-vision 期间）

> **定位**：`75-session-handoff.md` 明确声明「只覆盖**最近一轮**（2026-09-22 上午）」。
> 本文补上**它未覆盖的再往前一轮** —— 即
> **贴图覆盖修复 → 渲染层清单自动化 → 莲座作物 → 树的形状重设计 → 树干果实初版 → 台座初版**。
>
> **读法**：先读 `AGENTS.md`（自动加载，硬约束 18 条）→ 再读 `75`（最近一轮）→ 最后读本文。
> 逐轮施工细节在 `71-flora-implementation-log.md` **§5.52 ~ §5.56**；本文是**交接视角的浓缩**。
>
> ⚠️ **本文最有价值的是第 2 节「后来被推翻的结论」** —— 那一轮的许多判断在
> 最近一轮被实测推翻，接手时若只看施工细节会重犯。

---

## 0. 这一轮的起点与终点

| | 状态 |
|---|---|
| 起点 | 作物 74 种 / 果树 33 种 / 自有贴图 1330 / `verify.ps1` 全绿 |
| 终点 | 作物 **77 种**（+莲座 3）/ 果树 **39 种**（+树干果实 6）/ 方块 **395** / 贴图 **1378+** |
| 新增机制 | **莲座作物**（第 7 种作物形状）、**树干果实**（老茎结果）、**自有树干几何** |
| 建立的约束 | `AGENTS.md` 从无到有，硬约束 **1~15 条**全部来自这一轮 |

用户的四个原始诉求（按时间序）：

1. 「贴图修改**覆盖不彻底且修改不明显**」
2. 「**树干结果是要你自己编写的新机制**」
3. 「**整个树的形状也要重新设计**」
4. 「本来应该是**台座**模型的作物压根没有台座模型；新添加的几种特殊果树也压根**连树苗都没有**」

---

## 1. 这一轮做了什么（五个阶段）

### 1.1 阶段一：贴图覆盖修复（§5.52）

**排查出的三个真实漏洞（共 319 处）**：

| # | 漏洞 | 数量 | 后果 |
|---|---|---|---|
| ① | `models/item/**` **物品贴图完全没处理** | 238 | 地里改了、**手上没改** —— 物品栏里仍是 TFC 贴图 |
| ② | 野生作物**漏掉杂草层槽 `"1"`** | 74 | 父模型 `tfc:block/wild_crop/crop` 里 `"1"` 是硬编码的 TFC 杂草贴图，旧脚本只替换 `crop` 槽 |
| ③ | **7 个灌木零槽覆盖** | 7 | `{"parent":"tfc:block/plant/cloudberry_bush_2"}` 无 `textures`，直接漏出 TFC 云莓/枯枝贴图 |

**关键工具**：`tools/localize-all-models.ps1`（新增）——
扫描**所有**模型，只替换 `textures` 块里的 `tfc:` 引用，**绝不碰 `parent`**（父模型是几何体，必须继续借用）。

**同时加强色调变换**（`TintTextures.java`）：

| 维度 | 第一版（被用户判为"不明显"） | 这一版 |
|---|---|---|
| 色相 | ±20° | **±55°** |
| 饱和度 | 0.85~1.15 | **0.45~1.55** |
| 明度 | 0.90~1.10 | **0.72~1.32** |
| 对比度 | 无 | **0.80~1.28**（围绕中灰） |
| 水平镜像 | 无 | **约 50% 物种** —— 连形状朝向都不同 |

平均色差 ΔRGB 从约 18 → **47~81**。哈希要用**雪崩混合**（直接取 `hashCode` 不同位段会相关，导致维度间互相抵消）。

### 1.2 阶段二：渲染层清单自动化（§35.4-⑥）

**症状**：实机自检报「6 个方块没有登记渲染层」（3 莲座 + 3 野生莲座）→ 会被渲染成**黑块**。

**根因**：`TFCFarmingPlusClient.cutoutBlocks()` 是**逐行手写的常量表**，不是遍历数据源。
⚠️ §33.1 曾声称"渲染层清单自动化已完成"——**实际只做了果树**，作物/野生/灌木仍是手写。

**修法**：三处改为单一权威来源派生

| 清单 | 来源 |
|---|---|
| 作物 | `MyCrops.cropBlocks()` |
| 野生作物 | **`MyWildCrops.wildBlocks()`（工厂自动收集，新增零维护）** |
| 灌木 | `MyBushes.bushBlocks()` |
| 死株/树苗/树叶 | 原本就已自动 |

**关键点**：`MyWildCrops` 收集的是 **holder 而非 `.get()` 结果** —— 静态初始化期注册表未绑定，直接解引用会抛异常。

**验证**：去重后覆盖数 **317 前后一致**（顺带清掉手写表里 4 个重复条目：`FLAX`/`SESAME`/`SAFFLOWER`/`RAMIE` 各写了两遍）。

### 1.3 阶段三：莲座作物（第 7 种形状，§35）

`RosetteCropBlock` 是早期批次遗留的空壳，这一轮才真正接入：

- **机制**：`AGE 0~5`（**叶片轮数**）+ 独立的 `FRUITING`（中心是否结果）—— 与 TFC 六种形态的"线性拔高"本质不同
- **物种**：`cardoon` 刺菜蓟 / `agave` 龙舌兰 / `purslane` 马齿苋
  - ⚠️ 设计注释里的首选 `pineapple`（菠萝）**已被 Firmalife 占用** —— 又一次三方对照的必要性证明
- **接入点**：`gen-crops.ps1` 6 处 + `MyCrops.java` 9 处 + `MyWildCrops.java` 3 处 + 手册 3 行
- **结果态要有可见差异**：`localize-textures.ps1` 给 `_fruiting` 模型换独立 seed，否则结果态与未结果态**色调完全一样**

### 1.4 阶段四：树的形状重设计 + 树干果实初版（§5.54）

**树的形状**：原先 132 个枝干模型的 `parent` 全部指向 `tfc:block/plant/branch_*`（**几何借 TFC**）。
改为 4 个**共享**自有几何 `trunk_{core,side,up,down}`，**截面 6×6 → 8×8**；
33 种树各用 `textures.bark` 区分（与 TFC 自己的做法一致）。
⚠️ 必须同步改 `localize-fruit-tree-models.ps1`，否则跑一次本地化就把 parent 退回 TFC。

**树干果实**（初版）：

- `TrunkFruitBlock`（当时是 `HorizontalDirectionalBlock` + 自创 `AGE 0~2`）—— ⚠️ **后来被整体重写**，见 §2.1
- `MyTrunkFruits`（注册）+ `gen-trunk-fruits.ps1`（资源）
- 6 种树进果树管线：`jabuticaba` / `soursop` / `mangosteen` / `cupuacu` / `bael` / `canistel`
- **核心设计约定**：这 6 种的 `Lifecycle[12]` **刻意不含 `FRUITING`** —— 叶只开花，果在干上
  （这条约定在后续重写后**依然成立**）

### 1.5 阶段五：台座几何初版 + 快速检查开关（§5.56）

**台座**：`gen-rosette-models.ps1`（新增）—— 手法取自 **`tfc:block/plant/bird_nest_fern`（鸟巢蕨）**：
4 片**水平面**元素绕 x/z 轴倾斜、origin 居中，形成向外铺开的叶轮。
这是"先读 TFC 模型再动手"的直接产物（用户明确要求过）。

**快速检查开关**：`FastGrow.java` + `-Dtfcfarmingplus.fastgrow=true`（启动脚本带）。
⚠️ 这一轮对它有过**错误认知**，见 §2.5。

---

## 2. ⚠️⚠️ 后来被推翻的结论（接手时最该看的一节）

> 这一轮的多个判断在最近一轮被**实测推翻**。只看施工细节会重犯。

### 2.1 树干果实：从「自创 AGE 方块」→ TFC 原生 `SeasonalPlantBlock`

初版 `extends HorizontalDirectionalBlock` + 自创 `AGE 0~2` + `randomTick` 生长。
**推翻理由**：TFC 已有完整的物候/气候/采收机制（`StationaryBerryBushBlock` 用的就是），
自创一套既重复又与体系不一致。

**现形态**（详见 `75` §2.1）：`extends SeasonalPlantBlock`，只保留「四向 `FACING` + 背面判枝干」这一处差异。

### 2.2 台座：只覆盖 6 个模型 → 必须**全量覆盖 12 个 blockstate 组合**

初版生成器只写 `age_5_fruiting`，结果 **`fruiting=true` 的 age 0~4 共 15 个模型**
**长期留在原版小麦十字形态**（因为 `gen-crops.ps1` 先写了 `parent: block/crop` 占位）。
枯死台座 `dead_rosette{,_young}` 同源，也没人覆盖。

**判据**（已写入 `AGENTS.md` 硬约束 16）：
「占位 + 事后覆盖」的生成器，覆盖必须按 **blockstate 变体空间逐组合核对**，
不能按「我生成了几种几何」来算。

### 2.3 结果态中心是一块绿方块（因为共用贴图槽）

初版中心果实体块与叶片共用贴图槽 `#0` → 看起来就是"一块绿方块"。
现改为**独立槽 `#1`** + `GenFruitTexture` 程序化球体（`<n>_rosette_fruit.png`）。

### 2.4 `lastUpdateTick = -2147483648` 曾被我「论证为无影响」—— 实为真 bug

日志里一直能见到这个哨兵值。早期我靠「那段代码是 scheduled tick、没人 schedule」论证无害。
反汇编后发现 **`randomTick` 直接调用 `tick(...)`**，前提根本不成立：
计时器从未播种 → `getTicksSinceUpdate()` ≈ 2.1e9 → **放下方块的第一次随机刻就长满 STAGE**，缓苗期消失。

**教训**（`AGENTS.md` 硬约束 18）：凡「论证为无影响」的异常值，**必须在实机里真的读一次**再下结论。

### 2.5 ⚠️ 机制认知错误：我曾把「作物」和「随机刻」混为一谈

我一度让用户执行 `/gamerule randomTickSpeed 300` 来加速**作物**，用户当即指出：

> **「TFC 的作物生长压根不捆绑随机刻」**

**第二版错误（本文原稿）**：我把结论写成"**只有**走 `randomTick` 的东西（树干果实、果树枝条）
才受它影响" —— **仍然错**。

**第三版（源码复核，2026-09-22）—— 准确的表述必须分两类**：
- **A 类（随机刻触发结算、按真实 tick 差生长）**：TFC 作物、浆果丛、果树树叶/生长枝、树苗、树干果实。
  生长量 = 经过的日历 tick 数（`TickCounterBlockEntity.getTicksSinceUpdate()` =
  `Calendars.get(level).getTicks() - lastUpdateTick`），结算后 `resetCounter()` 对齐"现在"。
  → `randomTickSpeed` 调高**不加速**；但 **`=0` 会让它们停止生长**（区块保持加载也一样）。
- **B 类（每次随机刻按概率 +1 age）**：`PlantBlock` 家族（草、高草、水生/附生植物、仙人掌、海带顶…），
  `PlantBlock.java:263-273`：`if (random.nextDouble() < plantGrowthChance && age < maxAge) age + 1`，
  默认 0.04 → **会被 `randomTickSpeed` 线性加速**。
  ⚠️ 所以"TFC 所有植物的生长完全不依赖随机刻"这句**有反例**，不要当全称真理写进文档。
- **作物不是走 serverTick**：`Crop.java:107` 的 `dead()` 显式 `.randomTicks()`，
  `CropBlock.randomTick → tick → growthTick` 才是生长路径；`CropBlockEntity.serverTick`
  只调 `checkForCalendarUpdate()`，正常每 tick 时短路，属"卸载重载后的补账"。

**另一个被否掉的念头**：「把树干果实改成 serverTick 驱动以与 TFC 对齐」——
**错的**。TFC 的浆果丛与果树树叶**同样在 `randomTick` 里算时间差**，
树干果实现在就是 `SeasonalPlantBlock`，本就与它们一致。

### 2.6 「批次 10/11 决议关闭」—— 被用户直接推翻

我曾反汇编确认「TFC 与 Firmalife 都没有树干果实方块类」，据此**关闭整个批次**。

用户纠正：**「树干结果是要你自己编写的新机制」**。

**我的错误**：把「上游没有这个类」当成了「这个玩法不该存在」。
而项目既定原则恰恰相反 —— **缺失的机制就自己写**
（`RosetteCropBlock`、`MyCropBlock`、`MyClimbingCropBlock` 全是这么来的）。

**反汇编的正确用途**：判断「API 是否存在、该借还是该自己写」；
**不能**用来判断「这个玩法要不要做」—— 后者是产品决策。

### 2.7 快速检查开关已还原

`-Dtfcfarmingplus.fastgrow=true` 在最近一轮按用户要求**已注释掉**（`launch-client.ps1`）。
这一轮我把它加进来时，还错误地以为它能加速作物（见 §2.5）。

---

## 3. 这一轮产出的经验教训（全部已写入 `AGENTS.md` 1~15）

| 类 | 教训 | 硬化编号 |
|---|---|---|
| 流程 | 同一文件的连续改动之间**必须重新 `read`**（工具观察策略），否则白跑一轮 | 2 |
| 流程 | **后台构建必须先确认完成再启动游戏** —— 否则游戏读到 `clean` 后的残缺 jar，报一片 `FileNotFoundException`，极易误判成模型 bug | 3 |
| 流程 | 动手前先出**改动清单**（先反汇编 + 读清单，再动手） | 4 |
| 流程 | 验证按**批次**做，不要每个小改动都构建+启动+扫日志 | 5 |
| 路径 | `.ps1` 必须 **UTF-8 with BOM**；`edit` 会剥离 BOM，改完要补 + 语法检查 | 1 |
| 路径 | 命名空间用 `"${NS}:xxx"`，写成 `"$NS:xxx"` 会被当成作用域变量 | 2 |
| 路径 | `Substring` 切 `FullName` 前**必须 `Resolve-Path`**（`..` 未规范化会切错）—— 曾把 234 个模型引用写成 `tfcfarmingplus:/celeriac`，115 张贴图落到 `D:\` 根 | 3 |
| 资源 | 从 `src/main/resources` **删文件后必须 `clean build`**（增量构建会保留旧副本并打进 jar） | 4 |
| 资源 | 「跳过某类」的判断必须覆盖该类的**全部**生成段（只包一半出孤儿） | 5 |
| 资源 | **新增方块族**必须显式接进客户端渲染层清单（自动化只覆盖已知类别） | 6 |
| 资源 | `manifest` 新增形态时要**同步扩充它携带的字段**，否则下游按默认形态处理 | 7 |
| 资源 | **新增物种必须闭环**：种子/树苗 → 可种植 → 可生长 → 可收获 → 产物有用途 | 12 |
| 资源 | 验证不能只看「资源有没有缺」——自查清单若是自己列的，天然漏掉没想到的东西（**自证式验证**） | 13 |
| 工具 | `read` 与 `Get-Content` **行数口径不同**（`\r` vs `\n`），定位末尾时不能混用 | 14 |
| 模型 | 方块模型 `rotation.angle` **只能取 `-45/-22.5/0/22.5/45`**；非法值会让游戏报成 `FileNotFoundException`，**极易误判成打包问题** | 15 |
| 验证 | 实机启动**必须真的进世界**（日志里有 `open world`）；停在主菜单时数据包/随机刻/命令全不跑，但日志照样有模组加载信息 → 会误以为验证过了 | 见 `AGENTS.md` §三 |
| 认知 | 反汇编只判断「API 存在性」，不判断「玩法要不要做」 | 见底部 |
| 协作 | **重复注册**（两个类都注册 `food/<n>`）→ 游戏启动即崩；依附已有体系时应**复用其管线** | 12/13 |
| 协作 | 方块必须带**方块物品**（用 `RegistrationHelpers.registerBlock` 而非 `BLOCKS.register`），否则玩家拿不到 | 12 |
| 协作 | 资源路径必须与**注册名**一致（`plant/<n>_trunk_fruit` → `models/item/plant/...`） | — |

### 3.1 ⚠️ 本段最严重的问题：**思维链碎片化导致界面内存爆炸**

这一轮我的内部思考里出现了**大量重复循环**（「好 / 执行 / 发出 / stop / 我现在输出」
反复数百次），每次都在生成 token，**直接把 DSH 工作界面的内存打爆**，用户两次点名批评。

**后果**：不只是观感，而是**物理性损害**（界面失效）+ 有效推理被淹没。

**约束**（`AGENTS.md` 纪律 1）：**思考只写判断与依据**，禁止零信息填充；
每条思考必须能对应一个决策，写不出决策就别写。

---

## 4. 这一轮遗留给后续的问题（多数已在最近一轮解决）

| 问题 | 状态 |
|---|---|
| 台座只覆盖 6 个模型 | ✅ 最近一轮已修（全量 12 组合 + 枯死台座） |
| 树干果实自创 AGE、与 TFC 不一致 | ✅ 最近一轮已重写为 `SeasonalPlantBlock` |
| `lastUpdateTick` 哨兵值 | ✅ 最近一轮已定位并修（`MySeasonalPlantFix.afterPlace`） |
| 结果态中心是绿方块 | ✅ 最近一轮已修（独立贴图槽 + `GenFruitTexture`） |
| `fastgrow` 开着 | ✅ 最近一轮已还原为关闭 |
| 树干果实 `setPlacedBy` 两条路径**未用真实放置验证** | ⚠️ **仍未验证**，见 `75` §4.1 |
| 6 物种的 12 月物候表是拟的，未经用户确认 | ⚠️ **仍未确认**，见 `75` §4.2 |
| 台座/果实的**实机观感没人看过** | ⚠️ **仍未评估**，见 `75` §4.3 |
| 批次 11（树冠果实）| ⏸️ 暂缓，不要擅自开工 |

---

## 5. 这一轮新增/改动的文件索引

```
Java（moddev/tfcfarmingplus/src/main/java/com/example/tfcfarmingplus/）
  common/blocks/TrunkFruitBlock.java      树干果实（初版 HorizontalDirectionalBlock，后重写）
  common/blocks/RosetteCropBlock.java     莲座作物（AGE 0~5 + FRUITING）
  common/MyTrunkFruits.java               树干果实注册（初版自注册产物，后改为复用果树管线）
  common/MyCrops.java                     +莲座 9 处注册
  common/MyWildCrops.java                 +野生莲座 3 处；新增 wildBlocks() 自动收集
  client/TFCFarmingPlusClient.java        3 处手写清单 → 单一权威来源派生
  common/FastGrow.java                    快速检查开关（当前已关闭）
  TFCFarmingPlus.java                     +MyTrunkFruits.init()

工具（moddev/tfcfarmingplus/tools/）
  localize-all-models.ps1     新增：物品 238 + 野生草层 74 的本地化
  gen-trunk-fruits.ps1        新增：树干果实资源（初版 12 变体，后扩到 48）
  gen-rosette-models.ps1      新增：莲座台座几何（初版 7 模型，后扩到全量覆盖）
  TintTextures.java           加强：±55° / 对比度 / 镜像 / 雪崩哈希 / 分散度告警
  GenFruitTexture.java        后续新增：程序化球体果实贴图
  localize-textures.ps1       +_fruiting 独立 seed
  localize-fruit-tree-models.ps1  枝干几何改指自有 trunk_*

资源（assets/tfcfarmingplus/）
  models/block/plant/trunk_{core,side,up,down}.json   自有树干几何（截面 8×8）
  models/block/crop/rosette_age_*                     莲座台座几何

文档
  AGENTS.md                   本轮从无到有建立（纪律 7 条 + 硬约束 15 条）
  docs/71 §5.52~§5.56         逐轮施工细节
  docs/74 §34 / §35 / §33.4   贴图覆盖 / 莲座作物 / 批次 10 决策
```

---

## 6. 一句话给接手者

这一轮的价值不在"做成了什么"，而在**"从哪些错误里纠正过来"**：

1. **覆盖不彻底**源于「只改了自己想到的那部分」（作物方块），漏了物品、草层、灌木；
2. **不明显**源于参数太保守（±20° → ±55° + 对比度 + 镜像）；
3. **两个物种体系不闭环**（莲座无形态、果树无树）源于只做"能注册"没做"能玩到"；
4. **多次误判**（残缺 jar、打包问题、rotation 非法）源于**看到异常就下结论，没有看完整异常栈的 cause**；
5. **最严重的**是思维链碎片化到把界面跑爆 —— 这是**工程纪律问题**，不是能力问题。

**接手时的第一条原则**：`AGENTS.md` 的 18 条硬约束不是文档装饰，
每一条都对应一次实际损失。
