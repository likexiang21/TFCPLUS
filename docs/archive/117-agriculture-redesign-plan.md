# 117 · 农业重做方案（四模组架构）

> **一句话**：把已有的 **146 种植物**接进/重制进一套以 TFC 为地基的农业体系；
> **最终目标是把已有农业体系完全重制** —— 判据不是"我们做得比邻居好"，而是"**这套系统归我们重做**"。
>
> **修订记录**：v1 未盘点邻居就设计新设备 → v2 补三模组基线 → v3 修"重复造轮子" →
> v4 双模组 + 草莓/可可列为接管 → v5 确立完全重制（系统级覆盖）→ v6 扩写主次产品/养蚕/调料/炒锅 →
> v7 四模组架构 → v8 通篇整理 → v9~v12 七轮事实核对与结构补齐（覆盖台账 197 文件 · 配方口径统一 ·
> 可行性推演 · §9.0 工程前提）。
>
> 🆕 **v13 / v14（本版）** —— 用户 11 条新指令 + **11 轮打磨**：
> ① **A/B 拆包**列为**最高优先级**（§〇.2）② 灵感来源**协议红线**（ARR/GPL/MIT 分级，§2.8）
> ③ tfcwoodwork 逐项分析 + **`in_world` 反编译设计**（§7.2~§7.2.5）
> ④ untamedwilds 重定位为"**丰富环境**"（§7.3）⑤ **深化三主轴**（§十三）
> ⑥ **施工清单**（物种 15 项 / **设备 18 台 + 1 个配方类型** / 物品 ~75，§9.1~9.4）⑦ **验证矩阵 + 回滚手册**（§9.0-C / §5.5.1）
> ⑧ **依赖方向修正**（🛑 **A 不是 C 的依赖**）⑨ **液体保质期六轮推演**（§6.9）
> ⑩ **86 种作物横向矩阵**（§13.2）⑪ 🛑 **mixin 改为必选项**（§12.6）
>
> ⚠️ 全部基线数字为 **2026-09-28 实测**（jar 盘点 / 反编译）；**本轮未构建、未实机**。

---

## 📌 执行摘要（5 分钟读完）

### 要做什么
把 TFC 的**农业**（作物 → 加工 → 食物 → 畜牧）从"接入"一路做到"**完全重制**"，拆成**四个独立模组**、分阶段交付。

### 四个模组与依赖（🛑 依赖方向已按用户口径修正）

| 模组 | mod id | 做什么 | 依赖 |
|---|---|---|---|
| **A** | `tfcfarmingplus`（**已存在**） | 146 种植物 · **仅接入**（纯数据；配方 0 / 设备 0 / 动物 0） | TFC · patchouli |
| **B** | **`tfcagricultureplus`**（新） | **完全重制**：197 文件覆盖 + **4~6 个 mixin** + **18 台设备** + 15 项物种工作 | **A** · TFC · Firmalife · afc |
| **C** | `tfcfarmingplus_husbandry` | 畜牧水产**新内容**（🆕 真空白 = **尸体处理链**） | 🆕 **仅 TFC** |
| **D** | `tfcfarmingplus_husbandry_overhaul` | 畜牧**体系重构** | 🆕 **仅 C** |

### 🛑 第一步做什么（用户点名的最高优先级）
**阶段 -1：先拆包**（§〇.2）—— 建 B 的 Gradle 子模块 + 六条红线门禁 + **空 B jar 进游戏** + B 接管草莓。
**零玩家可见内容，但它决定后面一切能否安全落地**；也是唯一"**现在做几乎免费、以后做极贵**"的事。

### 规模（实测，全部可用 §14.3 复现）

| 项 | 数字 |
|---|---|
| A 层现状 | **36 java / 6 包 / 6,418 资源** · 配方 **0** · 设备 **0** · 动物 **0** |
| 基线（三方，内容口径） | TFC **6,419** 条配方 · Firmalife **1,079** · afc **707** |
| B 要覆盖 | **197 个文件 / 10 组**（⚠️ 其中 **191 个是 A 层的接入工作**，只有 6 个是真"覆盖"） |
| B 要新增 | 物种 **15 项**（①覆盖 **2** / ②接管 **4** / ③补链 **6** / ④新增 **3**）· **设备 18 台 + 1 个 `in_world` 配方类型** · 物品 **~75** |
| 美术量 | **≈ 410 张贴图**（B）+ C 的实体模型（§7.3.3 三档待选） |
| mixin | **B 4~6 个**（🆕 **已下调**：~~TFC 腐坏推进~~ 降为 **P1**（只剩地窖保质期）· ~~作物生长~~ 与 ~~授粉~~ **作废** · 保留 Firmalife 三项**条件让位**）· **C/D 4 个** |
| 参考模组 | woodwork（**MIT**，240 条 `in_world`）· untamedwilds（**GPL**，225 物种）· extradelight · firmalifehardcore（**已安装**） |

### 三条最硬的红线

| # | 红线 | 出处 |
|---|---|---|
| 1 | **A 不得依赖 B/C/D**；🆕 **C 不得依赖 A**（用户纠正）；**D 只依赖 C** | §〇.2.6 · §〇 |
| 2 | 写邻居命名空间的标签**必须 `replace=false`** —— 唯一灾难性写法是 `replace: true` | §5.5.2 |
| 3 | **mixin 是必选项**，但须避开与 firmalifehardcore 的**目标冲突**（条件让位） | §12.6 · §12.6.4 |

### 三个最大的风险

| 风险 | 对策 |
|---|---|
| 覆盖 197 文件后**邻居更新**导致内容消失 | 台账 + 对齐检查 + **回滚演练**（§5.5） |
| 温室 / 地窖的**空间检测**拖垮服务器 | BFS + `SavedData` 缓存 + **4096 格上限**（§5.6.5） |
| **美术是瓶颈**（≈410 张贴图） | §9.0-D 预算 + C 分三档（§7.3.3） |

### 🗺 文档地图（要查什么去哪）

| 要查什么 | 去哪 |
|---|---|
| **数字怎么算出来的** | **§14.3 复现命令**（可自行跑出同样的数字） |
| 邻居到底有什么 | §三 基线 · §7.2 woodwork · §7.3 untamedwilds · §8.0 TFC 动物 |
| 每个覆盖文件归谁 | **§5.5.2 交叉映射**（197 个逐组归属） |
| 施工清单 | §9.1 物种 · §9.2 设备 · §9.3 物品 · §9.4 收尾 |
| 批次与顺序 | §9.0（工程前提）→ **§九 落地顺序** |
| **被推翻过的判断** | **§12.3（24 条自我修正）** |
| 可行性 / 稳定性 | §十二（含 6 条红线 · 性能 · 存档 · **mixin**） |

---

### 怎么读这份文档

| 你的目的 | 建议读这几节 |
|---|---|
| **第一次接手** | §〇（四模组架构）→ **§1.4（已实现地基）** → §三（邻居模组基线）→ §九（落地顺序） |
| **要动手做** | §1.3（既有决定 / 搁置登记）→ §二（对应模组的边界）→ 目标章节 → **§9.0 + §9.1~9.4（工程前提与施工清单）** |
| **要评审设计** | §十三（深化）→ §十（开放项与风险）→ §十一（基于地基的增量）→ **§12.3（自我修正）** |
| **只想看现状** | §一（现状与缺口）→ §1.4（做了什么）→ **§14.2（146 种植物去向）** |
| **要核对数字** | §三（基线）→ **§14.3（复现命令）** |
| **要知道踩过哪些坑** | **§12.3（24 条）** · §5.5.2（覆盖风险定级更正）· §6.9.4（液体腐坏结论反转） |

> 📌 **两条阅读纪律**：① 本文档的数字**全部来自 jar 盘点 / 反编译**，凡引用前请用 §14.3 复核
> （v8 曾因只查配方文件名把 `straw` 来源写成 2 条，实际 **23** 条）；
> ② 任何新设计先对照 **§1.4 已实现地基** —— 能扩展现有的类就扩展，不要新写一套。


---
## 用户口径（最高约束，2026-09-28 定稿）

1. **架构 = 四个模组**：**A 仅接入** / **B 完全重制（系统级覆盖）** / **C 新增畜牧水产内容** / **D 畜牧体系重构**。
2. **最终目标是完全重制**，**不要考虑"优势"** —— 判据是"这套系统归我们重做"。
3. 覆盖做到**系统级**；**养蜂不覆盖**（Firmalife 已完善）；**温室与灌溉以 firmalifehardcore 为参考**（已到位，§5.6）；**动力系统不动**（只加部分自动化机器）。
4. **草莓与可可都要接管**；**草莓做成普通作物（不是灌木）**；**无花果/菠萝等不动**；**果树不做大修改**（以 TFC 形式为主）。
5. 原"独立新模块"的茶 / 咖啡 / 药草 / 纤维 / 坚果 / hops **并入 B**；**坚果重新纳入橡子（oak）与栗子（chestnut）**。
6. **搁置项全部解禁**：蘑菇 → **菌包培养**、取汁、亚麻多用作物；**TFC 树改造不涉及**。
7. **新增内容**：**新鲜草体系**（野草收割 + 未成熟作物补偿）、**养蚕**（用 Firmalife `fruit_leaf`）、
   **调料可加入汤/沙拉/派**、**派的流程与填充重做**、**炒锅类设备**。
8. **`crate` 是 TFC 已有内容**（实测 141 条）⇒ 不新增；**保冷延长保质期需自己新建**（`chiller` 只做冷饮）。
9. 外部模组（untamedwilds / extradelight / DragN / 屠宰 / 水产 / 海岸 / 鸟类 / 炒锅）**只借鉴内容设计，自己实现，不直接使用**。

**2026-09-28 第二轮追加（v14，6 条，均为硬约束）：**

10. 🛑 **最高优先级 = 拆分「普通作物 A 层的包」与「后续 B 层的代码和作物」** ⇒ 见 **§〇.2**（**先于一切内容工作**）。
11. **untamedwilds 的用途 = 为 TFC 添加野生动物丰富环境**（**生态丰富度**，不是畜牧产出）⇒ 见 **§7.3**。
12. **分析 woodwork 模组，学习并纳入 B 层**（MIT 协议 ⇒ 可学实现细节）⇒ 见 **§7.2**。
13. 🛑 **DragN 系列模组、Aquaculture2 用的是 ARR 协议，所以只能借鉴其玩法，不要学习其他内容**（**写入硬性要求**）⇒ 见 **§2.8**。
14. **继续打磨剩下的部分，打磨完之后构思如何"深化"种植和加工内容** ⇒ 见 **§十三**。
15. **在真正开始工作之前一定要把计划打磨足够详尽**（⇒ §〇.2.8 的"零内容批次 0~3"不得跳过）。

---

## 〇、四模组架构（一页）

### 〇.1 四模组职责总表

| | **A · 接入** | **B · 重制** | **C · 新增畜牧水产** | **D · 畜牧体系重构** |
|---|---|---|---|---|
| 定位 | 简单的**仅接入**模组 | **完全重制**：系统级覆盖 + 推翻重做已有机制 | **新增**畜牧业与水产**内容** | **重构**畜牧业**体系** |
| 手段 | 纯数据 | 覆盖 + 自建机制 + 新设备 | 新实体 / 方块 / 物品 | 重做繁殖·成长·饲养·产出机制 |
| 覆盖邻居模组 | ❌ | ✅ 核心手段 | ❌ | ✅ 覆盖 TFC 的动物机制 |
| 新增方块 / 设备 | ❌ | ✅ 大量 | ✅ 畜舍 / 水产设施 | ✅ |
| 依赖 | 独立 | **依赖 A** | 🆕 **独立**（不依赖 A · 不依赖 B） | 🆕 **依赖 C** |
| 卸载后果 | 只丢加工出口 | 覆盖撤销，邻居恢复原貌 | 新动物消失 | 动物机制恢复 TFC 原样 |
| 现有内容 | **146 种植物**（内容基础） | — | — | — |
| 典型产出 | 汤 / 沙拉 / 果酱标签、逐条配方 | 接管草莓与可可、重做设备与系统 | 野生动物（§7.3.3 三档）· 6~8 鱼 · 4~6 鸟 · 家畜 | 繁殖 / 成长 / 饲养 / 尸体体系 |

**依赖方向（🆕 v14 第 10 轮按用户口径修正）：`A ← B` · **`C` 独立** · **`C ← D`**。**A 完全不知道 B/C/D 的存在；C 也不知道 A 与 B 的存在。**

**为什么要拆四个**：① 接入（A）是低风险纯数据，随时可卸；② 重制（B）是高风险机制替换；
③ **内容（C）与机制（D）必须分离** —— 只想要新动物的人不必接受畜牧体系被重构，只重构体系的人也不必接受新动物。

---

### 〇.2 🛑 工程落地：**先拆包，再写内容**（用户点名的最高优先级）

> **用户 2026-09-28 定稿口径**：「**方案的最高优先级应当是拆分普通作物 A 层的包和后续的 B 层代码和作物**」
> ⇒ **在写任何一条 B 层配方 / 任何一个 B 层物种之前**，先把 A 层（普通作物 · 仅接入）与
> B 层（代码 + 作物 · 完全重制）切成**两个可独立发布的交付物**。本节是整份文档的**第 0 步**。

#### 〇.2.1 为什么"拆"必须先于"做"（5 条，都是不可逆的）

| # | 不先拆的后果 | 具体会发生什么 |
|---|---|---|
| 1 | **B 的覆盖把 A 带塌** | B 要覆盖 **197 个文件**（§5.5），其中 6 个是 A 自己的资源；同一个 jar 里一次失误 = A 也一起不可用 |
| 2 | **A 不再"可单独发布"** | 用户口径 A = "简单的仅接入模组"，它必须能独立安装 / 独立卸载 / 独立回滚 |
| 3 | **依赖方向会被写反** | 一旦共包，B 的类会被 A"顺手"引用，A 就**永久无法脱离 B 编译**（且不会立刻报错） |
| 4 | **新机制渗进 A** | A 的边界是"纯数据 + 零新机制"；共包后 `in_world` 配方、新设备、新 BE 会被逐渐塞进 A |
| 5 | **回滚粒度消失** | §〇 表格承诺"卸载 B ⇒ 覆盖撤销、邻居恢复原貌"，共包时做不到 |

**成本判断**：A 层**今天已经**是一个干净的"仅接入"实现 —— **配方 0 / 设备 0 / 动物 0**（§1.1 已核实）。
⇒ **拆分的成本几乎全在"规划"上，不在"重构"上。这是本轮唯一一件"现在做几乎免费、以后做极贵"的事。**

#### 〇.2.2 现状清点（A 层 = 今天的全部内容，一个字节都不多）

| 项 | 数量 | 位置 / 证据 |
|---|---|---|
| Java | **36 个文件 / 6 个包** | 根 `1` · `client` `1` · `common` `12` · `common/blocks` `17` · `common/items` `3` · `common/blockentities` `2` |
| 资源 | **6,418 个文件** | `assets/**` 贴图 2,394 · 模型 2,052 · blockstate 475；`data/**` 掉落表 475 · 世界生成 488 · tfc 数据 286 · Firmalife 种植盆 155 |
| 对 TFC 数据类型的产出 | **2 类** | `tfc/climate_range` **146** · `tfc/food` **140** |
| 覆盖邻居模组 | **8 个文件 / 3 类** | `assets/tfc/models/block/crop/cabbage_age_*`(6) · `assets/tfc/patchouli_books/**`(14) · `data/{tfc,minecraft,c}/tags/**`(21) |
| 配方 / 加工设备 / 动物 | **0 / 0 / 0** | `data/**/recipe/**` 文件数 = 0 |
| 入口 | 3 个 | `TFCFarmingPlus`（主）· `TFCFarmingPlusClient`（客户端）· 5 个 `My*` 注册表 |

#### 〇.2.3 交付物与命名（🛑 候选，**待用户确认**后写进 `gradle.properties`）

| 模组 | mod id（候选） | 内容 | 依赖 |
|---|---|---|---|
| **A** | `tfcfarmingplus`（**不变**） | 146 种植物 · 36 类 · 6,418 资源 | TFC · patchouli |
| **B** | ✅ **`tfcagricultureplus`**（**用户 2026-09-28 定名**） | 覆盖 197 文件 + 新机制 + 新设备 + 草莓/可可/茶/咖啡/菌包/养蚕… | **A** · TFC · Firmalife · afc |
| **C** | `tfcfarmingplus_husbandry`（候选） | 畜牧与水产**新内容** | 🆕 **仅 TFC**（**不依赖 A** —— 用户口径） |
| **D** | `tfcfarmingplus_husbandry_overhaul`（候选） | 畜牧**体系重构** | 🆕 **仅 C** + TFC（**不依赖 A**） |

> ⚠️ **B 的包名与 mod id 不一致是刻意的**：mod id = `tfcagricultureplus`（对外标识，玩家可见），
> 包名沿用 `com.example.tfcfarmingplus.expansion`（§〇.2.4，内部路径）。
> 两者不必一致，**但代码里凡出现 `"${modId}:xxx"` 的地方必须用 `tfcagricultureplus`**（§二-2 的 `${NS}:` 写法陷阱）。

🛑 **C / D 既不依赖 A、也不依赖 B**（用户 2026-09-28 纠正：**A 不是 C 的依赖**）。C 只依赖 TFC；D 依赖 C；B 是"内容重制"旁支，**不是 C/D 的前置**；
**D 不得引用 B 的任何类**（这条要在批次 0 的门禁脚本里一起检查）。

⚠️ 顺带记录一个**非阻塞但早晚要处理**的问题：A 的包名是 `com.example.tfcfarmingplus`
（`com.example` = 模板占位域）。对外发布前应改为自有域名。**本轮不动**（改包名会让 6,418 个资源
的引用路径与 36 个文件的 import 全量 diff，风险远大于收益）；登记为 §10.1 待定项。

#### 〇.2.4 包结构

**A 层：原样保留，本轮一个路径都不改**（避免 6,418 资源的无谓 diff）：

```
com.example.tfcfarmingplus
├─ TFCFarmingPlus                 # 主入口 / 注册时机
├─ client/TFCFarmingPlusClient    # 方块渲染层 / 模型清单（§二-6 硬约束）
└─ common/
   ├─ MyBlocks · MyItems · MyBlockEntities · MyCreativeTab      # 注册表
   ├─ MyCrops · MyBushes · MyFruitTrees · MyBranchFruits · MyWildCrops   # 物种清单
   ├─ MyClimateRanges · MyDebugCommands
   ├─ blocks/        (17 类：MyCropBlock · MyDoubleCropBlock · MyClimbingCropBlock ·
   │                  MySpreadingCropBlock · MyFloodedCropBlock · MyPickableCropBlock ·
   │                  RosetteCropBlock · MyBerryBushBlock · MySpreadingBushBlock ·
   │                  MySpreadingCaneBlock · MyFruitTreeSaplingBlock ·
   │                  MyGrowingFruitTreeBranchBlock · MyFruitingBranchBlock ·
   │                  MyFruitTreeLeavesBlock · MyDecayingBlock · MySeasonalPlantFix · FruitState)
   ├─ items/         (3 类：MySeedItem · MyBushBlockItem · MyFruitTreeSaplingItem)
   └─ blockentities/ (2 类：MyBerryBushBlockEntity · MyDecayingBlockEntity)
```

**B 层：全新根包，与被覆盖的 A 层物理隔离**（`expansion` 段是唯一新增的顶层目录）：

```
com.example.tfcfarmingplus.expansion
├─ TFCFarmingPlusExpansion        # 入口：检测 A 不存在 ⇒ 抛 ModLoadingException（红线 5）
├─ client/…                       # 新方块族必须在此登记（§二-6）
└─ common/
   ├─ override/                   # 覆盖台账（§5.5）的代码侧：197 个覆盖项的开关与自检
   ├─ species/                    # B 层新物种：strawberry · cocoa · tea · coffee · hops · herbs · flax…
   ├─ machines/                   # 新加工设备（§5.4 / §6.6）：炒锅 · 榨汁 · 蒸发 · 研磨 …
   ├─ inworld/                    # 🆕 世界内加工（借鉴 tfcwoodwork，见 §7.2）
   ├─ system/                     # L-3 系统级：温室 · 地窖 · 灌溉 · 树液（§5.6）
   └─ food/                       # 调料 / 主次产品 / 新鲜草（§6.2 / §6.3 / §6.5）
```

#### 〇.2.5 A → B 的 API 表面（**B 只能用这些，多一个都不给**）

| B 需要的能力 | A 的现状 | 本轮动作 |
|---|---|---|
| 复用 A 的 17 个方块类与 3 个物品类 | 已 `public` | ✅ 直接 `new`；A 需在类注释里写明**这是给 B 的稳定接口**（改动 = B 崩） |
| 复用 A 的注册表（`MyBlocks` 等） | `public static` 字段 | ✅ **只读**；❌ 运行时写入 / 清空 |
| 复用 A 的 2 个 BE 类型 | `MyBlockEntities` | ✅ 只读引用；B 的新方块族**必须自建 BE**（§二-17 的静态 helper 陷阱） |
| 拿到 A 的 146 物种与气候数据 | `MyClimateRanges`（数据驱动） | 🆕 **新增 1 个只读查询类**（`species()` / `climateOf(name)` / `isOurSpecies(name)`）—— 这是本轮**唯一**为 B 新增的 A 侧代码 |
| 往 A 的创造模式页追加物品 | `MyCreativeTab` | ❌ **不开钩子**；B 自建创造页（解耦优先于便利） |
| 覆盖 A 的贴图 / 模型 / 掉落表 | — | 🛑 **明令禁止**（会破坏"A 单独可用"，见红线 2） |

#### 〇.2.6 六条依赖红线（违反任一条 = 拆分失效）

| # | 红线 | 为什么 | 怎么强制 |
|---|---|---|---|
| 1 | B 编译期依赖 A；**A 不得 import 任何 B / C / D 的类** | 否则 A 永远无法脱离它们编译 | 批次 0 写门禁脚本：grep A 的 `src/**` 出现 `expansion\|husbandry` 即失败 |
| 2 | **B 不得写 `assets/tfcfarmingplus/**`、`data/tfcfarmingplus/**`** | 覆盖 A 的资源 = 卸载 B 后 A 变成半成品 | 门禁脚本扫 B 的资源根目录白名单 |
| 3 | **B 的 mixin 不得指向 A 的类** | mixin 目标是字符串，编译期不报错、运行期**静默失效**（§二-17 同类坑） | B 的 mixin json 逐条人工核 |
| 4 | **A 不得为 B 预埋空钩子** | 这是 A 保持"纯数据 + 零新机制"的**唯一**保障 | 代码评审：A 里凡"以后可能用到"的接口一律不加 |
| 5 | **B 检测不到 A 时必须硬失败** | 静默降级 → 玩家看到的是"覆盖了一半的世界"，比崩溃更难查 | B 入口 `ModList.get().isLoaded("tfcfarmingplus")` 为假即抛错 |
| 6 | 🆕 **C 不得依赖 A 或 B；D 只依赖 C**（**不依赖 A、不依赖 B**） | 用户口径：**A 不是 C 的依赖** —— C 是畜牧水产内容，与 146 种植物无关 | 门禁脚本扫 C / D 的 `build.gradle` 与 import，出现 `tfcfarmingplus` 即失败 |

#### 〇.2.7 迁移清单：A 里**没有**要搬给 B 的东西（已核实，不是推测）

| 候选 | 核实方式与结果 | 结论 |
|---|---|---|
| **草莓** | `assets/tfcfarmingplus/blockstates/**`、`MyCrops.java`、`tools/crops-manifest.json` 三处**均无** `strawberr` 匹配 | ✅ **无迁移**；B 从零接管 TFC 的 `plant/strawberry_bush`（§5.2） |
| **可可** | 同上，三处均**无** `cocoa` / `cacao` | ✅ **无迁移**；B 从零接管 Firmalife 的 `plant/cocoa_*`（§5.2） |
| **树干果实** | `MyBranchFruits.SPECIES` = **7**（jabuticaba · soursop · mangosteen · cupuacu · bael · canistel · black_pepper） | 可可将是**第 8 个**，见下方边界判定 |
| 其余 144 物种 | 全部属于 A 的"仅接入"范围 | ✅ 留在 A，B 不得改动 |

🛑 **一个必须现在定的边界：可可作为"第 8 种枝干果实"，物种注册在 A 还是 B？**
- ✅ **方案 1（采用）**：**注册在 B**，A 的 `SPECIES` 保持 7。B 自己注册可可的方块 / 枝干 / 12 月物候，
  **直接复用 A 的 `MyFruitingBranchBlock` 类**（§〇.2.5 第 1 行）。→ A 完全不知道可可存在，红线 4 不被破坏。
- ❌ 方案 2：把可可塞进 A 的 `SPECIES`。→ 为了让 B 好用而改动 A = **正面违反红线 4**，否决。

#### 〇.2.8 拆分的落地批次（**先于 §九 的全部内容批次**）

| 批次 | 内容 | 前置 | 验收判据 |
|---|---|---|---|
| **0** | 建 B 的 Gradle 子项目（`moddev/tfcfarmingplus-expansion/`）+ 六条红线的门禁脚本 + **一个什么都不做的空 B jar** | 无 | 空 B 能进游戏：日志出现 B 的 mod 名、无 `Unable to load`、A 的 146 物种全部照常 |
| **1** | A 侧新增 1 个只读查询类（§〇.2.5） | 0 | A 单独跑 `verify.ps1` 全绿；A 的 jar 里**不出现**任何 B 字样 |
| **2** | B 接管草莓（**最小覆盖**，验证覆盖链路真的生效） | 0 · 1 | 游戏内 TFC 的草莓灌木**确实**变成普通作物；卸载 B 后恢复原状 |
| **3** | 覆盖台账机制（§5.5 的 197 项逐条登记 + 卸载还原自检） | 2 | `OVERRIDE-REGISTRY.md` 与 B 的实际资源**逐条对得上** |
| **4** | 之后才进 §九 的内容批次（B 的 L-1 / L-2 / L-3） | 0~3 | 见 §九 |

⚠️ **批次 0~3 是"零内容"批次** —— 它们不产出任何玩家可见的新东西，但**它们决定了后面所有内容能不能安全落地**。
不要为了"早点看到东西"跳过它们（用户口径：**在真正开始工作之前一定要把计划打磨足够详尽**）。

---

## 一、现状、缺口与既有决定

### 1.1 现状

| 类别 | 数量 | 证据 |
|---|---|---|
| 耕地作物 / 果树 / 浆果灌木 / 树干果实 | **86 / 48 / 12 / 7** | `_CROP` 86、`*_sapling` 48、`*_bush` 12、`MyBranchFruits.SPECIES` 7 |
| 营养 / 气候 / 掉落表 | 140 / 286 / 475 | `data/tfcfarmingplus/**` |
| Firmalife 种植盆 | 155 | `data/firmalife/firmalife/plantable/**` |
| **配方 / 加工设备 / 动物** | **0 / 0 / 0** | `data/**/recipe/**` 文件数 0 |

### 1.2 缺口（**A 层落地之后，还差什么**）

> A 层已交付 146 种植物本体与全部接入（§4.0），但**"种出来之后没有下文"**。
> 缺口分四类 —— 🛑 **第 4 类尤其重要：它防止我们把已经有的东西再造一遍**。

#### 1.2.1 🔴 致命缺口（不补就是半成品）

| # | 缺口 | 实测证据 | 后果 | 谁补 |
|---|---|---|---|---|
| 1 | **配方 = 0** | `data/**/recipe/**` 文件数 **0** | **全部产物只能生吃** —— 86 种作物收上来没有任何加工出口 | A（§4.2）+ B |
| 2 | **无任何自有设备** | 36 个 java 里**没有机器类** | 加工只能借 TFC / Firmalife 的设备 | B（§9.2 的 **18 台**） |
| 3 | **茶 / 咖啡 / hops / 纤维 5 种 = 有作物无出口** | `blockstates/{crop,wild_crop,dead_crop}/…` **三套齐全**，但**三方都没有任何配方用它们** | 5 种纤维作物 + 3 种特用作物的产物**直接进垃圾桶**（§5.1.1） | B（**补链型**） |
| 4 | **草莓 / 可可漏了接管** | 草莓是 TFC 矮灌木（**46 条**）· 可可是 Firmalife 果树（**58 条**）· **A 层 0 条** | 用户点名的两个物种**没做** | B（§5.2，**P0**） |
| 5 | **亚麻等多用作物被搁置** | `docs/74` §10.2-27 明确记录"记录并搁置（未来「深化作物处理体系」时重置）" | 纤维链断在"收下来就没了" | B（§13.3-5） |

#### 1.2.2 🟡 结构性缺口（有，但浅）

| # | 缺口 | 现状 | 目标 |
|---|---|---|---|
| 6 | **主 / 次产品** | 次产品**几乎只有"堆肥"一条出路** | **4 条出口** —— 堆肥 / 燃料 / 饲料 / 育苗（§13.2） |
| 7 | **调料** | TFC **没有调料机制**（汤 / 沙拉只有固定变体） | 汤 / 沙拉 / **派** 可变（§6.5） |
| 8 | **主动保存** | 只有 TFC 的物品腐坏，**没有任何"延长保质期"的手段** | 保冷设施 + 液体物品化（§5.6 · §6.9） |
| 9 | **畜牧的尸体环节** | TFC 有 **~90 种动物**，但**死亡直接掉物品、无尸体中间态**（§8.0） | C 的尸体链（3×3×3 → 屠刀三阶） |
| 10 | **野生植物状态未细分** | TFC 的 `straw` 掉落**不区分植株是否枯死** | 新鲜草 / 干草两态（§6.3） |
| 11 | **育秧 / 移栽 / 留种** | TFC 只有"种子 → 作物"一条直线 | 六环节深化（§6.8） |

#### 1.2.3 🟠 "已有但该我们重制"（**不是缺口，是归属问题**）

| # | 项 | 现在的归属 | 用户口径 |
|---|---|---|---|
| 12 | 温室 / 灌溉 / 种植容器 | Firmalife | **系统级重制**（§5.6） |
| 13 | 干燥 / 发酵 / 烘焙 / 混合 / 离心 | Firmalife | **系统级重制**（§5.3.1 逐链） |
| 14 | 食物 / 营养 / 腐烂 | TFC | **系统级重制**（§6.9 · §12.6） |
| 15 | TFC **29 种作物 · 11 种灌木** | TFC | **系统级重制**（§5.1） |
| 16 | 葡萄酒 / 奶酪 / 面食 / 豆制品 / 可可 | Firmalife | **系统级重制**（§5.3.1） |

#### 1.2.4 ✅ **明确"不是缺口"的**（🛑 防止重复造轮子 —— v14 实测抓出的一类错）

| 项 | 谁已经有了 | 实测 |
|---|---|---|
| `crate` 板条箱 | **TFC** | 141 条（`CrateBlock` + BE） |
| 踩踏 `stomping` | **Firmalife** | **4 条**配方 |
| 织机 `loom` | **Firmalife** | **1 条** |
| 榨油 | **TFC** | `olive_oil` / `canola_oil` + `pot` 煮 → `barrel` 油水分离 + `lamp_fuel` |
| 肥料 | **TFC** | 🆕 **`tfc:fertilizer` 数据类型（10 个）** |
| 养蜂 | **Firmalife** | 136 条目（蜂种 / 能力 / 寄生虫 / 遗传病四套系统） |
| 液体腐坏计时 | **TFC 也没有** | ⚠️ 但**可以做**，方案见 §6.9 六轮推演 |
| 动力系统（风车 / 水车 / 齿轮箱 / 曲轴 / 跳锤） | **TFC 本体** | 🛑 用户口径：**不动** |

⚠️ **本节的第 4 类是全篇最容易犯的错**：v14 的 11 轮打磨里，有 **6 处**误判都是"把邻居已有的当成缺口"
（香料 · 浆果灌木数 · 葡萄形态 · 踩踏 · 茶咖啡占位 · TFC 动物体系）—— 全部记在 **§12.3**。


### 1.3 🛑 既有决定与搁置登记（**动手前必读**）

> 出处：`docs/74` §10.2 / `docs/74` §10.3 / `docs/74` §32.8。**AGENTS.md §7.1：不要擅自实现用户主动搁置的项。**
> ⚠️ 本方案 v1~v3 都没有登记这一节，导致把已被否决 / 搁置的东西列成了 P0。

**A. 搁置项（本轮全部解禁，见 §6.1）**

| # | 项 | 状态 | 与本文档的关系 |
|---|---|---|---|
| 9 | 蘑菇 / 竹笋 | ⏸️ → ✅ **解禁** | 蘑菇走**菌包培养**（§6.1）；竹笋走竹林 |
| 16 | **取汁 / 果汁** | ⏸️ → ✅ **解禁**；`docs/74` §580 已论证基础路径 | 基础走 `BarrelRecipe` 纯数据（无需新方块）；B 层加压榨设备作批量升级 |
| 17 | TFC 树改造 | ⏸️ → ✅ **不涉及** | 用户指示：**TFC 的树不需要改造** |
| 27 | **亚麻这类多用作物**（"深化作物处理体系时重置"，`docs/71` §5.19） | ⏸️ → ✅ **解禁 = 本方案主体** | 见 §6.2 主 / 次产品体系 |

**B. 已定的取舍（不要重复做）**

| 项 | 结论 | 出处 |
|---|---|---|
| 椰子 / 椰枣 | ✗ 排除（棕榈形态不适配现有分枝模型） | `docs/74` L2408 |
| 开心果 / 巴西栗 | ⚠️ 与已落地的坚果 5 种无本质区别 | `docs/74` L2409 |
| 菠萝蜜 / 面包果 / 榴莲 | ✅ 已落地（热带果树 14 种） | `docs/74` L2406 |
| 杂交品种 | ✅ 未实现 | `docs/74` §10.2-8 |
| 不扩充新机制（TFC 已有的不重复做） | ✅ 贯穿全程 | `docs/74` §10.2-2 |
| 茶 / 咖啡占位物品 + 不做成耕地作物 | ✅ `food/tea_leaf`、`food/coffee_bean`，实现为多年生灌木 | `docs/74` §10.2-25/26 |
| 麻类新物品 | ✅ `fiber/flax`、`fiber/ramie`、`cotton_boll` | `docs/74` §10.2-24 |
| Firmalife 种植盆 | ✅ 灌木 12 + 作物 8 + 果树 14（实测共 155） | `docs/74` §10.3-34 |

**C. ⚠️ 被本轮推翻的两条旧结论**

| 项 | 旧结论 | 新结论 |
|---|---|---|
| **可可 `cocoa`** | `docs/74` L2407：「✗ Firmalife 已占用，链完整，**重做无意义**」 | 🛑 **推翻 → 要覆盖**（§5.2） |
| **草莓 `strawberry`** | §10.2-10 标"✅ 草莓转正为作物" | 🛑 **实为漏做**（本模组 0 条资源、155 个 plantable 里也没有）→ **要接管，且做成普通作物**（§5.2） |

---

### 1.4 ✅ 已实现内容（地基 —— 任何新设计都必须建立在这上面）

> ⚠️ 本节是对**本项目自己**的盘点。此前 v1~v11 只盘点了邻居模组的 jar，**从没系统盘点过自己做了什么**。

**Java 侧：17 个方块类 + 3 个物品类 + 2 个方块实体**

| 分类 | 已实现的类 | 覆盖 |
|---|---|---|
| **作物形状 6 种 + 莲座** | `MyCropBlock`（普通）· `MyDoubleCropBlock`（双格）· `MyClimbingCropBlock`（攀爬）· `MySpreadingCropBlock`（蔓延）· `MyFloodedCropBlock`（**淹水 / 水生**）· `MyPickableCropBlock`（**可采摘**）· `RosetteCropBlock`（莲座） | 86 作物 |
| 灌木 | `MyBerryBushBlock` · `MySpreadingBushBlock` · `MySpreadingCaneBlock` | 12 灌木 |
| 果树 | `MyFruitTreeSaplingBlock` · `MyGrowingFruitTreeBranchBlock` · `MyFruitingBranchBlock` · `MyFruitTreeLeavesBlock` + `FruitState` | 48 果树 + 7 树干果实 |
| **腐烂** | **`MyDecayingBlock` + `MyDecayingBlockEntity`** | 瓜类方块 + 死株 |
| 物候修复 | `MySeasonalPlantFix` | 全部季节性植物 |
| 物品 | `MySeedItem` · `MyBushBlockItem` · `MyFruitTreeSaplingItem` | 种子 / 灌木 / 树苗 |
| 方块实体 | `MyBerryBushBlockEntity` · `MyDecayingBlockEntity` | — |

**资源侧**：`blockstates/crop` **86** · `wild_crop` **86** · `dead_crop` **82** · `plant`（果树 / 灌木模型）**214** · 瓜类方块 3 + 腐烂变体 3 · 共享死株 `dead_rosette`

**数据侧**

| 机制 | 数量 | 说明 |
|---|---|---|
| `tfc/climate_range` | **146** | 气候区间（温度 / 降雨 / 森林度） |
| `tfc/food` | **140** | 营养与腐坏数据（`decay_modifier`）。口径：86 作物中 **9 个无食物数据**（`bottle_gourd` `cantaloupe` `cotton` `flax` `hemp` `hops` `ramie` `sisal` `winter_melon`，均为纤维 / 瓜类方块 / 非食用产物），其余来自果树、灌木与树干果实 |
| `loot_table/blocks` | **475** | 掉落表 |
| `worldgen/configured_feature` + `placed_feature` | **244 + 244** | 野生生成（单株 + 成片） |
| `loot_modifiers` | **49** | 果树叶子掉落修饰 |
| `firmalife/firmalife/plantable` | **155** | 种植盆适配 |
| **自洽性验证** ✅ | — | `climate_range` **146** = `crop/` 86 + `plant/` 60，而 **60 = 48 果树 + 12 灌木** ⇒ **文档里的"146 种植物"与数据完全吻合** |
| **配方** | **0** | 🛑 唯一缺口 |
| **跨命名空间覆盖** | **197 个文件** | ⚠️ 分 5 类（资源 6 / 手册 14 / 追加式 155 / 标签 21 / 世界生成标签 3），**完整台账见 §5.5** |

**⇒ 三条硬约束（后续所有设计都要遵守）**

1. **新增机制优先"扩展现有的类"，而不是新写一套** ——
   例：水田 ⇒ 扩展 `MyFloodedCropBlock`；主次产品 ⇒ 扩展掉落表 + 复用 TFC `extra_products`；腐坏类设计 ⇒ 先看 `MyDecayingBlock`。
2. **已有但闲置的产物必须先给出路**：`fiber/{flax,hemp,ramie,sisal}`（4）+ `cotton_boll` + `hops` + `food/{tea_leaf,coffee_bean}`（2）。
3. **"6 种形状 + 莲座"是已建成的方法论** —— 新作物只需选形状 + 填表，不需要新代码（这条极大降低 §5.1 物种覆盖的成本）。
## 二、设计原则

### 2.1 与邻居模组的分工（**前置检查**）

任何新增内容（设备 / 链 / 物品 / 物种）必须先回答：**① TFC 有吗？② Firmalife 有吗？③ AFC 有吗？**

- 任一为"有"且**不打算覆盖** ⇒ 归 **A**（接入）。
- 任一为"有"且**要替换成我们自己的实现** ⇒ 归 **B**（覆盖），并登记覆盖清单（§5.5）。
- 三方都无 ⇒ 归 **B**（扩展）或 **C**（新增内容）。

### 2.2 模组 A 的边界（只接入）

✅ 只写 `data/tfcfarmingplus/**` 的标签与配方；必要的新产物（谷物四件套等）可以新增。
❌ 不覆盖任何邻居文件、不新增设备、不改机制。**卸载 A = 只剩生食，无其它副作用。**

🆕 **越界判据**（可脚本检查，写进 §〇.2.6 的门禁）：

| 越界行为 | 判据 |
|---|---|
| A 依赖了 B/C/D | `src/main/java` 里出现 `expansion` / `husbandry` 的 import ⇒ **0** |
| A 新增了设备 | `MyBlockEntities` 的注册数相对基线（**2 个**）的增量 ⇒ **0** |
| A 改了邻居机制 | A 的 `src` 里 mixin 数 ⇒ **0** |
| A 的跨命名空间文件越界 | `src/main/resources` 下非 `tfcfarmingplus` 命名空间的文件应为 **197**（§5.5.2），且**全部是"接入"语义**（唯一例外：6 个 `cabbage_age_*` 模型） |

### 2.3 模组 B 的边界（覆盖式重制）

✅ 跨命名空间覆盖（`assets/tfc/**`、`assets/firmalife/**`、`data/firmalife/**` …）+ 自建方块 / 设备 / 机制。

🛑 **三条硬约束**：
1. **覆盖必登记** —— 每个被覆盖目录放登记文件，逐条列路径 / 用途 / 依赖 / 回滚动作（§5.5）。
2. **覆盖必可回滚** —— **只覆盖资源与数据，不改邻居模组的代码**；卸载 B 后邻居恢复原貌。
3. **一次只推翻一类机制** —— 按 §5.3.1 的**逐链清单**推进，不允许"整体重写 Firmalife"。

🆕 **越界判据**：

| 越界行为 | 判据 |
|---|---|
| 🛑 **B 覆盖了 A 的资源**（红线 2） | B 的资源树里出现 `assets/tfcfarmingplus/**` 或 `data/tfcfarmingplus/**` ⇒ **0**（§〇.2.6） |
| B 没登记覆盖 | `OVERRIDE-REGISTRY.md` 的文件数 ≠ 实际跨命名空间文件数 |
| B 一次推翻太多 | 一个批次里跨了 §5.3.1 的**多条链** |
| 🛑 **B 的 mixin 指向 A**（红线 3） | B 的 `mixins.json` 的目标类名里出现 A 的类 ⇒ **0** |

⚠️ **最后一条有个真实的坑**：B 的**包名本身**含 `tfcfarmingplus`（`com.example.tfcfarmingplus.expansion`）⇒
**门禁脚本不能简单 grep 这个词**，必须匹配 **mixin 的 `target` 类名**（而不是包名）。

### 2.4 模组 C 的边界（新增内容，不动机制）

✅ 新实体 / 方块 / 物品（动物、鱼、鸟、畜舍、水产设施、养蚕）。**只加内容，不改 TFC 的动物行为与繁殖逻辑** —— 那是 D 的活。
❌ 不覆盖邻居模组的动物数据。
🆕 ✅ **C 只依赖 TFC** —— **A 不是 C 的依赖**（用户 2026-09-28 纠正，§〇）。

🆕 **越界判据**：

| 越界行为 | 判据 |
|---|---|
| 🛑 **C 依赖 A 或 B** | C 的 import / `build.gradle` 里出现 `tfcfarmingplus` ⇒ **0** |
| C 改了 TFC 动物行为 | C 的 mixin **只允许 §12.6.3 的 2 项**（死亡落尸体 · 生成条件），**多一个即越界** |
| C 覆盖了邻居的动物数据 | C 的资源里 `data/tfc/**` 的动物相关文件 ⇒ **0** |

### 2.5 模组 D 的边界（覆盖动物机制）

✅ **覆盖 TFC 的动物机制**：繁殖 / 成长 / 饲养 / 产出 / 尸体 / 环境（§8.2）。
🛑 风险最高 ⇒ **必须在 C 完成之后单独立项**，且同样遵守"覆盖必登记 + 可回滚 + 不改代码"。

🆕 **越界判据**：

| 越界行为 | 判据 |
|---|---|
| D 在 C 之前开工 | C 的交付判据（§8.1）未全绿 |
| 🛑 D 依赖 A / B | import 检查 ⇒ **0**（D **只依赖 C**） |
| **D 把"改机制"做成了"加内容"** | 若 D 里出现**新的动物物种** ⇒ **放错层了**（那属于 C） |

⚠️ **最后一条是 C / D 最容易混的地方**：**C 加物种，D 改机制**。
D 若发现自己在注册新动物，说明这个需求**应该回到 C**。

### 2.6 通用原则

- **防滥用七条**：繁殖材料只取成熟 / 结果期 · 低堆叠 · 消耗工具耐久 · 母株恢复期 · 加工不可跳步 · 不可逆加工不回退 · 加工品接入腐烂。
- **造价一致四查**：材料可获取性 → 工序数量相当 → 造价与阶段相符 → 不产生跳步。
  ⚠️ 实测踩过：`tfc:farmland/silt` 不存在（TFC 只有 8 种土纲）、`crop/cabbage` 是 TFC 的。
- **新增准入 D1~D6**：填补邻居做不到的 · 输入→中间体→输出三段 · ≥2 条并行用途 · 能源落在 TFC 体系 ·
  副产品有去处 · 先 2~3 项验证再铺开。

🆕 **一条元原则（覆盖 A/B/C/D 四层的边界判断）**：

> **先问："这是「参数」还是「行为」？"** ——
> **参数**走数据 / 标签（第一优先）· **新对象**走继承 / 自建（第二）· **外挂行为**走 NeoForge 事件（第三）·
> 🛑 **已有类的内部逻辑** ⇒ **必须 mixin**（第四，§12.6.6）。
> 四层边界（§2.2~2.5）都是这条元原则的推论。


### 2.7 项目纪律（实测教训）

生成器是唯一产出源（手改 JSON 必须回写生成器）· 跑生成器前查 `$root` 是否硬编码（14 个脚本仍是）· 动手前查并发写入。

### 2.8 🛑 灵感来源的协议红线（**硬性要求，用户 2026-09-28 点名写入**）

> **用户口径**：「**DragN 系列模组、Aquaculture2 用的是 ARR 协议，所以只能借鉴其玩法，不要学习其他内容**（写入硬性要求）」

本节是**法律级约束**，与 §2.1 的"前置检查"配套：§2.1 管"邻居有没有做过"，本节管"**能不能学、能学到什么程度**"。
凡引用 §七 灵感来源库里的任何模组，**先查下表的协议列**。

> **本节是"红线表"，完整版见子文档 [`126-b-module-implementation.md`](126-b-module-implementation.md) §十九「协议合规专章」**
> —— 那里有 ① **全部接触过的模组的协议总表**（三级分类）② 🆕 **三个之前漏掉的风险**（**TFC 是 `EUPL-1.2` 不是 MIT** · **Patchouli 是 `CC BY-NC-SA 3.0`** · 另有 ARR 食品模组）③ 🛑 **"过度挪用"的 6 条可操作判据** ④ **门禁脚本**。
>
> 🆕 **2026-09-29 实测补充的关键协议**（本节表格下方已展开）：
> **TerraFirmaCraft = `EUPL-1.2`（弱 copyleft）** · **Firmalife / FirmaLife HardCore / afc / TFC Woodworking = `MIT`** ·
> **extradelight / extradelighttfc / Survivor's Butchery = `CC BY-NC-SA 4.0`** · **Cuisine TFC / FirmalifeEnhance = `ARR`** ·
> **Untamed Wilds / Survivor's Delight = `GPL`（有传染性）** · **Patchouli = `CC BY-NC-SA 3.0`**。

#### 协议实测（读 jar 内 `META-INF/(neoforge.)mods.toml` 的 `license` 字段 + `LICENSE*` 文件，不是猜的）

| 模组 | 实测协议 | 可借鉴程度 | 实测依据 |
|---|---|---|---|
| **tfcwoodwork**（TFC Woodworking 1.2.4） | ✅ **MIT** | **可学习实现细节 · 可参考数据组织 · 可借鉴机制设计**（须注明来源） | `license="MIT"` |
| **aquaculture**（Aquaculture 2 2.7.21 / 2.5.7） | 🛑 **All Rights Reserved** | ⚠️ **只借鉴玩法** ⇒ 自己实现 | `license="All Rights Reserved"` |
| **dragnlivestock**（DragN's Livestock Overhaul） | 🛑 **All Rights Reserved, DragN0007** | ⚠️ **只借鉴玩法** | 同上 |
| **dragnpets**（Pets Addon） | 🛑 **All Rights Reserved, DragN0007** | ⚠️ **只借鉴玩法** | 同上 |
| **permafrost**（DragN's Permafrost） | 🛑 **All Rights Reserved, DragN0007** | ⚠️ **只借鉴玩法** | 同上 |
| **livestocktfc**（LO × TFC Compat） | 🛑 **All Rights Reserved, DragN0007** | ⚠️ **只借鉴玩法** | 同上 |
| **farmersdragn** | 🛑 All Rights Reserved | ⚠️ 只借鉴玩法 | 同上 |
| **untamedwilds**（4.0.4） | 🛑 **GNU General Public License** | ⚠️⚠️ **只借鉴"生态设计"**（有哪些动物 · 分布 · 成群方式）⇒ **代码与资源一律不得拷贝** | `license="GNU General Public License"` |
| **survivorsaquaculture** | 🛑 GNU GPL v3 | ⚠️⚠️ 同 GPL 处置 | `license="GNU General Public License Version 3"` |
| **extradelight**（2.6.6 / 1.1.5） | 🛑🆕 **实测 `CC BY-NC-SA 4.0`**（署名 · **非商业性使用** · 相同方式共享） | 🛑 **只借鉴玩法与设计思路** —— ⚠️ **与我们的 MIT 不兼容**（MIT 允许商业使用，CC BY-NC-SA 不允许；且"相同方式共享"会传染）⇒ **不得复制其代码 / 资源 / JSON 配方** | 🆕 `license="CC BY-NC-SA 4.0 Deed "`（实测） |
| **extradelighttfc**（0.5.0-beta） | 🛑🆕 **实测 `Attribution-NonCommercial-ShareAlike 4.0 International`**（= CC BY-NC-SA） | 🛑 **只借鉴玩法** —— ⚠️ 但它是**「extradelight × TFC 整合」的现成范例**（§18），**方案思路值得学**（代码仍不得拷贝） | 🆕 `license="Attribution-NonCommercial-ShareAlike 4.0 International"`（实测） |
| **TFC / Firmalife / afc** | 邻居模组（本工作区依赖） | ✅ 按其自身许可（我们是互补而非拷贝） | — |
| **本项目 A/B/C/D** | **MIT** | — | `src/main/templates/META-INF/neoforge.mods.toml` 的 `license = "MIT"`（已核实） |

#### 三条硬性要求（**写进交付检查表，违反即返工**）

1. 🛑 **ARR 模组（Aquaculture 2 · DragN 全系列 · Farmer's DragN）** —— **只借鉴玩法**。
   禁止拷贝其**任何**：资源文件（贴图 / 模型 / 音效）· 数据文件（配方 / 标签 / 掉落表 / 世界生成）·
   代码 · 文本（lang / 手册）· **命名**（方块 / 物品 / 实体的 ID 与显示名）。
   产出必须**完全自研**；"设计灵感来源"写进 §七 的出处列即可。
2. 🛑 **GPL 模组（untamedwilds · survivorsaquaculture）** —— 除上述"只借鉴设计"外，
   **额外禁止拷贝代码**：GPL 具传染性，拷贝其代码会迫使**我们整个模组改为 GPL 发布**。
   本项目是 **MIT**，与 GPL 代码的直接引入**不兼容**。
3. ✅ **MIT 模组（tfcwoodwork）** —— 可学习实现细节与数据组织方式；
   **仍须在文档中注明来源**（学术诚信），且**不得整文件照搬**（保持我们自己的代码风格与命名）。

#### 每个 B / C / D 内容的"协议自检"（交付前逐条过）

| 检查项 | 判据 |
|---|---|
| 该内容的**设计灵感**是否来自 ARR / GPL 模组？ | 若是 ⇒ 出处写进 §七；实现从零写 |
| 有没有**直接引用**其 ID（`aquaculture:…` / `dragnlivestock:…` / `untamedwilds:…`）？ | 必须为 **0**（做成互补依赖除外，且需用户批准） |
| 有没有**照抄的数值**（饥饿值 / 生长时间 / 掉落数量 / 繁殖概率）？ | 有 ⇒ 必须给出**自己的推导**（现实原型或 TFC 内部一致性） |
| 贴图 / 模型是否**肉眼可见地相似**？ | 是 ⇒ 重做（判据见 AGENTS.md「第一标准」：真实渲染图对比） |

---

## 三、已有内容基线（实测，决定 A 接什么、B 覆盖什么）

### 3.1 TFC 4.2.11（62.3 MB）

- **配方（⚠️ 两个口径 —— v13 起以「内容口径」为准）**
  - **内容口径**（读文件里的 `"type"` 字段，共 **6,419** 条）：crafting 合计 **2,959**（shaped 1717 + shapeless 587 + advanced_shaped 372 + advanced_shapeless 283）· heating **883** · collapse **525** · chisel **513** · **`barrel_sealed` 308** · anvil **281** · **`pot` 145** · casting **111** · knapping **101** · quern **89** · welding **87** · **`pot_jam` 66** · 另有 **`neoforge:false` 195 条**（条件包装，未展开）
  - **目录口径**（配方文件所在子目录，仅作交叉参考）：crafting ~3001 · heating 951 · collapse 553 · chisel 532 · barrel 343 · anvil 311 · **pot 216** · casting 112 · knapping 110 · welding 97 · quern 93 · glassworking 61 · sewing 26 · landslide 24 · alloy 10 · scraping 8 · loom 6
  - **差异原因**：同一目录下可能放多种 type —— 例 `recipe/pot/` **216** 个文件里，type 为 `tfc:pot` 的只有 **145**（其余含 `pot_jam` 等）

- **密封桶 `barrel_sealed`：实测 308 条，但绝大多数是「染色 / 漂白」而非发酵**（⚠️ 本文档 v8 曾误写为"发酵 23 条"）：
  `alabaster` 49 · `ceramic` 32 · `candle` 17 · `windmill_blade` 15 · `bleach_*` 多条 ·
  16 色 × `banner` / `bed` / `carpet` / `concrete_powder` / `dyeable` / `glazed_terracotta` / `shulker_box` / `terracotta` / `wool`
  - **真正的发酵 / 加工只有少数几条**：`beer` · `medium_leather` · `large_leather` · `music_disc_mellohi`
  - ⇒ **修正认知**：TFC 的密封桶**主要是染色工具**；**发酵主力在 Firmalife 的 `vat`（52 条）** —— 这印证了 §3.2 的"Firmalife 是农业加工主体"
  - ✅ **设计机会**：我们的染料植物（`safflower` 红花 / `turmeric` 姜黄 / `garland_chrysanthemum`）可直接接这条成熟的染色链（§4.2 A6）
- **酒 8 种**（流体）：`beer` `cider` `rum` `rye_whiskey` `whiskey` `corn_whiskey` `vodka` `sake`；
  醋；`brine`/`brined`/`pickled`；`curdled_milk`→`cheese`；**`lye` / `limewater` / `tannin` / `tallow`**；16 色染料（各 16~32 条）
- **零配方接入点（A 的地基）**：`usable_in_{soup,salad,sandwich,jam_sandwich}` + `tfc:foods/*` 27 个
- **果酱**：`jar/*` 22 种果实（含 `strawberry`）；配方 —— 目录口径 `pot/jam_*` **176** 文件 + `crafting/jar/` **23** 文件；**内容口径 `tfc:pot_jam` 66 条**（⚠️ v8 曾写 366，v13 统一口径）
- **干草 `straw`：完整来源 23 条**（⚠️ 本文档 v8 曾误写为只有 2 条，已更正）：
  - ⭐ **13 种野生草的掉落表**：`beachgrass` `bluegrass` `bromegrass` `fountain_grass` `orchard_grass` `pampas_grass` `raddia_grass` `red_oat_grass` `ryegrass` `scutch_grass` `switchgrass` `tall_fescue_grass` `timothy_grass`
    —— 掉落表用 `alternatives`：**剪刀（`#c:tools/shear`）→ 草方块物品**；**利器（`#tfc:tools/sharp`）→ `tfc:straw`**
  - ⭐ **6 种谷物脱粒副产**（`crafting/food/{barley,maize,oat,rice,rye,wheat}_grain.json`）：
    `tfc:advanced_shapeless_crafting` + **`tfc:extra_products` modifier** ⇒ **主产品谷粒 + 次产品 1 straw**（`docs/70` L451 早有记录）
  - 合成 4 条：`straw_from_alfalfa`（苜蓿）· `straw_from_canola`（油菜）· `straw_from_hay`（干草块）· `straw`（`thatch` → 4 straw）
- **`straw` 的用途 8+ 项**：`hay_block` · `basket`（篮）· `daub`（抹墙）· `drying_bricks` × 8 土纲 · `nest_box` · `thatch`（茅草）· 标签 `firepit_kindling` · 标签 `pit_kiln_straw`
- **坚果**：只有 `peanut`；**无 acorn / chestnut 物品**（但 **oak 412 条、chestnut 434 条**树都在）
- **已有 `CrateBlock`（crate）141 条** —— 板条箱不需要我们做
- **可喂养动物 23 种**（✅ 已交叉核实：`data/tfc/tags/item/*_food.json` 恰好 23 个，含 `panda_food`）；设备 15 种（`firepit` `grill` `pot` `stove_pot` `barrel` `barrel_rack` `quern` `power_loom` `nest_box` `pit_kiln` `charcoal_forge` `crucible` `mold_table` `bloomery` `blast_furnace`）
- **草莓**：`plant/strawberry_bush`（矮灌木）+ **46 条** strawberry 资源

### 3.2 Firmalife 3.0.14（4.28 MB / 6,359 条目）

- **配方（内容口径，共 1,079 条；与目录口径基本一致 —— Firmalife 基本"一目录一 type"）**
  advanced_shaped 373 · crafting_shaped 205 · advanced_shapeless 91 · crafting_shapeless 67 · **`firmalife:vat` 52（发酵主力）** · chisel 46 · heating 38 · **`tfc:pot` 32** · **`tfc:barrel_sealed` 22** · collapse 21 · **`firmalife:drying` 16** · **`firmalife:oven` 15** · **`firmalife:mixing_bowl` 15** · knapping 13 · **`tfc:pot_jam` 8** · `neoforge:false` 10
  - 目录口径另有：anvil 8 · quern 7 · barrel_instant 5 · glassworking 5 · **stomping 4** · welding 4 · casting 4 · **centrifuge 3** · smoking 2 · loom 1 · alloy 1

- **设备 130+**：`drying_mat` `solar_drier` · **`vat`** · 5 材质烤箱（+ insulated 变体）· `mixing_bowl` `centrifuge` `compost_tumbler` ·
  **完整养蜂**（136 条目）—— ✅ 已交叉核实其深度：Java 侧有 `BeeSpecies`（**蜂种**）/ `BeeAbility`（**能力**）/
  `ParasiticInfection`（**寄生虫感染**）/ `GeneticDisease`（**遗传疾病**）/ `BeeComponent` + 三种蜂箱实体
  （`FLBeehiveBlockEntity` 含 `AreaScan` / `Flower`、`SkepBlockEntity`、`WoodenBeehiveBlockEntity`）；
  物品侧有 `beehive`/`wild_beehive`/`skep` + 蜂框 4 种（普通 / 绝缘 / 蜂蜜化 / 糖化）+ `raw_honey` / `beeswax` /
  `aromatic_honeycomb` + 养蜂人 4 件套；配方 17 条· **完整温室**（9 材质 × 8 部件）·
  灌溉 4 件 · 6 种种植容器 · 葡萄架 · `jarring_station` · `picker`/`sweeper` · `stovetop_*` · `climate_station` · **7 种奶酪轮**
- **自带植物**：香料 8 种（`basil` `bay_laurel` `cardamom` `cilantro` `cumin` `oregano` `pimento` `vanilla`）+
  `cocoa`（枝干型果树四件套）+ `fig` + `nightshade_bush` + `pineapple_bush` + 红 / 白葡萄
- **深加工**：可可→巧克力 · 面条 / 意面 / 披萨 / 派 / 饼干 / 扁面包 / 冰淇淋 · 豆腐 / 豆酱 · `spice/` 体系 ·
  33 项葡萄酒（含起泡酒 `tirage_mixture`）· `dried/<fruit>` 24+ 种
- **`fruit_leaf`**：通用果树叶**物品**（养蚕饲料直接用，§6.4）
- **可可 58 条 / 草莓 11 条**

### 3.3 AFC 2.1.3（6.18 MB / 11,539 条目）

- **60 个树种**（acacia_koa … weeping_willow）+ 每树 15 类方块（含 TFC 机械的**树种材质变体**：`axle` / `gear_box` / `water_wheel` / `windmill`）
- ⚠️ **机械装置本身是 TFC 本体的，不是 AFC 的**（本文档 v8 曾误判，已更正）：
  `crankshaft` `trip_hammer` `steel_pump` `vane` `anemometer` `power_loom` `quern` + `wood/sluice/<tree>`（每树种一套）；
  对应 Java 类 `AxleBlockEntityRenderer` / `WaterWheelBlockEntityRenderer` / `WindmillBlockEntityRenderer` /
  `BladedAxleBlockEntityRenderer` / `SluiceBlockEntityRenderer` / `WindmillBladeModel` ⇒ **AFC 只是给它们加树种材质**
- **`tree_tapping`（树液采集）**：`input_block` + `result_fluid` + 温度区间 + **`spring_only`** + **`requires_natural_log`**
- 产物链：`birch_sap` / `maple_sap` → `*_concentrate` → `*_syrup` → `*_sugar`；`latex`（hevea / rubber_fig）→（pot + 硫磺）→ **`rubber_bar`**
- **配方（内容口径，共 707 条）**：crafting_shaped 553 · advanced_shapeless 63 · crafting_shapeless 61 · advanced_shaped 21 · **`tfc:pot` 4** · **`afc:tree_tapping` 4** · anvil 1
- 含 **Firmalife 兼容层**（113 配方 + 108 掉落表）

### 3.4 能力矩阵（决定"接"还是"覆盖"）

| 工序 | TFC | Firmalife | AFC | 归属 |
|---|---|---|---|---|
| 磨粉 / 煮 / 汤 / 沙拉 | ✅ quern 93 / pot 216 / 6 标签 | ✅ | ✅ pot 4 | **A 接标签** |
| 发酵（酒 / 醋 / 酱） | ✅ barrel_sealed 23 | ✅ **vat 52** | — | A 接；⚠️ B 覆盖 |
| 腌制 / 凝乳 / 制碱 / 鞣革 | ✅ | — | — | A 接 |
| 干燥 | — | ✅ **drying 16 + drying_mat/solar_drier** | — | A 逐条配方；⚠️ B 覆盖 |
| 烘焙 | heating 951 | ✅ **oven 15 + 5 材质** | — | A 接；⚠️ B 覆盖 |
| 混合 / 分离 | — | ✅ mixing_bowl / centrifuge | — | ⚠️ B 覆盖 |
| 养蜂 | — | ✅ **完整（已完善）** | — | ❌ **不覆盖** |
| 温室 / 灌溉 | — | ✅ **完整** | — | ✅ **B 覆盖** —— 参考模组 = **firmalifehardcore（已安装）**，见 §5.6 |
| 奶酪 / 葡萄酒 / 可可 / 面食 / 豆制品 / 香料 | 部分 | ✅ 全部 | — | A 接；⚠️ B 覆盖 |
| **调理（调料入菜）** | ❌ 无调料机制 | ❌ | — | ⚠️ **B 覆盖 + 新增**（§6.5） |
| 树液 / 糖浆 / 橡胶 | — | — | ✅ tree_tapping | ⚠️ B 覆盖 |
| 动力传动 | — | — | ✅ windmill/water_wheel/gear_box | ❌ **不动**（只加自动化机器） |
| 染色 / 皮革 / 果酱 | ✅ | ✅ | — | A 接 |
| **草莓** | ✅ 46 条（矮灌木） | 11 条 | — | 🛑 **B 必须覆盖**（§5.2） |

---

## 四、模组 A：仅接入（纯数据）

> A 的定位：**在 B 的完全重制完成之前，先把 146 种植物接进现有加工体系**（低风险纯数据）；
> 它同时是"只要内容、不要重制"的轻量选择。B 重制到位后，A 的接入点会被 B 自己的体系逐步替换。

### 4.0 🛑 先澄清 A 的真实状态：**它已经落地了**（不是"待做"）

> ⚠️ 旧稿把 §四 写得像"待做清单"，会让读者以为 A 还没开工。**实际上 A 层已经是可运行的地基。**

| 项 | 实测 | 状态 |
|---|---|---|
| Java | **36 个文件 / 6 个包** | ✅ 已落地 |
| 资源 | **6,418 个文件**（贴图 2,394 · 模型 2,052 · blockstate 475 · 掉落表 475 · 世界生成 488 · `tfc` 数据 286 · Firmalife 种植盆 155） | ✅ 已落地 |
| 物种 | **86 作物 + 48 果树 + 12 浆果灌木 + 7 树干果实 = 146** | ✅ 已落地 |
| 对 TFC 数据类型的产出 | `tfc/climate_range` **146** · `tfc/food` **140** | ✅ 已落地 |
| 跨命名空间接入 | **197 个文件 / 10 组**（§5.5.2 逐组归属） | ✅ 已落地 |
| **配方** | **0** | ⏳ **这才是 §4.2 要做的** |
| 设备 / 动物 | **0 / 0** | ❌ 按设计不做 |

⇒ **"A = 仅接入"有三层含义，读的时候别混**：

| 层 | 内容 |
|---|---|
| **已完成** | 146 种植物本体 · 世界生成 · 掉落 · 气候范围 · 营养定义 · 197 个跨命名空间接入文件 |
| **待做** | **§4.2 的逐条加工配方**（让产物有出口）—— 做完这一层 A 就算交付 |
| **明确不做** | §4.3（不覆盖邻居文件 · 不新增设备 · 不改邻居机制） |

### 4.1 零配方接入（P0，一次交付覆盖 ~110 种产物）

| 目标标签 | 覆盖 |
|---|---|
| `tfc:usable_in_{soup,salad,sandwich}` | 蔬菜 34 + 水生 9 + 豆类 11 |
| `tfc:usable_in_jam_sandwich` + `tfc:foods/jam` | 果实 60 |
| `c:foods/{vegetable,fruit,grain,meat,…}` | 全部可食产物 |
| `tfc:foods/can_be_salted` | 蔬菜 / 瓜果 |
| `c:dyes/*` | 染料植物 3（供 Firmalife `vat` 用 —— 它的 `input_item` **是标签**） |
| 🆕 `tfc:compost_browns/{high,medium,low}` · `compost_greens/*` · `tfc:fuel` · `tfc:fertilizer` | **次产品的 4 条零代码出口**（§13.2）—— 这一条 v14 才补上，是横向深化的入口 |

### 4.2 逐条配方

| 目标 | 设备 / 类型 | 数量 |
|---|---|---|
| 谷物四件套 | TFC `quern` + `crafting` + `heating` | 14 × 4 ≈ 56 |
| 果实干燥 | Firmalife `drying`（按物品） | 60 |
| ~~香料干燥 / 研磨~~ | 🛑 **移出 A 层** —— A 层**没有香料**（实测 611 个 lang 键 + `MyItems.java` 零命中，§5.1 已更正）⇒ 香料的干燥 / 研磨是 **B 的接管工作**（§9.1 #4），**不属于"仅接入"** | **0**（A）→ 移入 B |
| 面食前处理 | Firmalife `oven`（`copy_dynamic_food`） | ~20 |
| 油料 | TFC pot+barrel / Firmalife `barrel_sealed` 范式 | ~6 |

### 4.3 A 模组明确不做

不覆盖任何邻居文件 · 不新增设备 · 不改邻居机制 · 不做果汁设备（`docs/74` L580 已论证纯数据即可）。

### 4.4 A 的收尾与验证（**做完 §4.2 就算交付**）

| 项 | 内容 |
|---|---|
| **交付判据** | ① §4.2 的配方全部落地 ② `verify.ps1` 全绿 ③ 🛑 **游戏内能真的做出一碗含我们蔬菜的汤**（"标签写出了"**不算**验证，见 §9.0-C） |
| **不阻塞 B** | ✅ **A 未完成也能开工 B** —— B 只依赖 A 的**物种与方块**，不依赖 A 的配方 |
| **与 B 的交接点** | 🛑 **B 不得覆盖 A 的资源**（§〇.2.6 红线 2）；A 层已有但未闭环的物种，B **只加链条、不碰方块**（§5.1.1） |
| ⚠️ **一处待确认** | A 写的 `data/tfc/tags/block/crops.json` **可能是死文件**（§5.5.2 的"A 层问题"表） |

---

## 五、模组 B（上）：覆盖与系统级重制

> **B 的最终目标是把已有农业体系完全重制**，不是"挑几处改进"。
> 判据**不是"我们做得比邻居好"**（不比较优势），而是"**这套系统归我们重做**"。
> 🛑 **唯一例外：养蜂不覆盖**（Firmalife 原内容已完善）。
> ✅ **温室与灌溉的参考模组已到位**：**firmalifehardcore 0.3.4（已安装）** ⇒ 设计见 **§5.6.1 ~ §5.6.5**。
> ⚠️ 它与 B 有 **mixin 目标冲突**（它已 mixin 了同一批类）⇒ 按 **§12.6.4 条件让位**。

### 5.1 覆盖对象总表（系统级）

> ⚠️ 表里的 ⭐/🟠/🟡 是**推进顺序**，不是"做不做"。**除养蜂与已标注"不动"的以外，全部都要完成。**

| 类别 | 覆盖对象 | 现状归属 | B 的做法 | 顺序 |
|---|---|---|---|---|
| **物种** | **草莓 `strawberry`** | TFC（46 条，矮灌木） | **接管**：做成**普通作物**（§5.2） | ⭐ **P0（点名）** |
| **物种** | **可可 `cocoa`** | Firmalife（58 条，枝干型果树四件套） | **完全重制**：可可树 / 果 / 加工链全部重建 | ⭐ **P0（点名）** |
| 物种 | ~~无花果 `fig`~~ / ~~菠萝 `pineapple`~~ / ~~茄 `nightshade`~~ | Firmalife | ❌ **不动**（用户指示） | — |
| 物种 | 红 / 白葡萄 | Firmalife —— 🛑 **不是果树，是一整套"棚架 + 绳子"藤本系统**（实测 **168 文件 / 9 个类**：`GrapeStringBlock`·`GrapeTrellisPostBlock`·`GrapeTrellisPostWithPlantBlock`·`GrapeGroundPlantOnStringBlock`·`GrapeFluffBlock`·`GrapeStringWithPlantBlock`·`GrapeSeedItem`·`GrapePlantBlockEntity`·`IGrape`；**10 个 blockstate**；27 条配方含 `stomping`/`quern`/`vat`/`barrel_sealed`） | **接管**：⛔ **不走果树管线** —— 用我们的 **`MyClimbingCropBlock` + 自建棚架**重制（对齐"系统级覆盖"口径） | 🟠 P1 |
| 物种 | Firmalife **8 种香料植物** | Firmalife：`plant/{basil · bay_laurel · cardamom · cilantro · cumin · oregano · pimento · vanilla}`；产出 7 种香料（刀切 / 磨 / 干燥三条工序） | **接管（从零做）** —— 🛑 **更正**：A 层**没有香料**（实测 611 个 lang 键 + `MyItems.java` 零命中），旧稿写的"我们已有 8 种香料作物"是**错的** | 🟠 P1 |
| 物种 | TFC 29 种作物 | TFC（实测 `assets/tfc/blockstates/crop/*.json` **恰好 29 个**：alfalfa · barley · beet · cabbage · canola · carrot · cassava · garlic · green_bean · jute · lentil · maize · melon · oat · onion · papyrus · peanut · potato · pumpkin · radish · red_bell_pepper · rice · rye · soybean · squash · sugarcane · tomato · wheat · yellow_bell_pepper） | **系统级重制**（几何 + 贴图 + 掉落；已覆盖 `cabbage` 为样板） | 🟠 P1 |
| 物种 | TFC **11 种**浆果灌木 | TFC（实测 13 个 `*_bush` blockstate，减去 2 个枯死态 `dead_berry_bush` / `dead_bush` ⇒ **11 种**：blackberry · blueberry · bunchberry · cloudberry · cranberry · elderberry · gooseberry · raspberry · snowberry · **strawberry** · wintergreen —— ⚠️ **草莓就在其中**，见上一行） | **系统级重制**（走我们的灌木管线；**草莓单独处理**） | 🟠 P1 |
| 物种 | **果树（TFC 8 种 + 本模组 48 种）** | TFC | ❌ **不做大修改**（以 TFC 形式为主，不作过多产物调整） | — |
| 物种 | **坚果挂树**（橡子 / 栗子） | TFC 有 oak / chestnut 树，但**无 acorn / chestnut 物品** | ✅ **新增**：橡子挂 **oak**、栗子挂 **chestnut**（§6.7 E6） | 🟠 P1 |
| 机制 | 干燥 / 发酵 / 烘焙 / 混合 / 离心 | Firmalife | **系统级重制**（自建替代设备，§5.4） | ⭐ P1 |
| 机制 | **温室 / 灌溉 / 种植容器** | Firmalife | **系统级重制**（参考 firmalifehardcore，见 §5.6；⚠️ 它与 B 的 mixin 目标冲突 ⇒ §12.6.4 条件让位） | ⭐ P1 |
| 机制 | **养蜂** | Firmalife（**136 条目 + 蜂种 / 能力 / 寄生虫 / 遗传病四套系统**） | ❌ **不覆盖** —— ✅ 已交叉核实：其深度远超"蜂箱产蜜"（`BeeSpecies` / `BeeAbility` / `ParasiticInfection` / `GeneticDisease`） | — |
| 机制 | 树液采集 / 糖浆 / 橡胶 | AFC | **系统级重制**（挂到我们的果树） | 🟠 P1 |
| 机制 | 动力传动（风车 / 水车 / 齿轮箱 / 曲轴 / 跳锤，**均为 TFC 本体**） | **TFC**（AFC 仅加树种材质） | ❌ **不动** —— 只在其上加**部分自动化机器**（§6.6） | — |
| 机制 | 食物 / 营养 / 腐烂 | TFC | **系统级重制** | 🟠 P1 |
| 机制 | 汤 / 沙拉 / 三明治（TFC 动态标签） | TFC | **系统级重制**（A 阶段先用标签过渡） | 🟠 P1 |
| 机制 | **调料加入汤 / 沙拉 / 派**（改原有内容） | TFC 无调料机制 | **覆盖 + 新增变体**（§6.5） | ⭐ P1 |
| 机制 | 果酱 / 装罐 / 奶酪 / 葡萄酒 | TFC + Firmalife | **系统级重制** | 🟠 P1 |
| 机制 | 可可 / 面食 / 豆制品 / 香料 | Firmalife | **系统级重制** | 🟠 P1 |
| 机制 | **派的制作流程与填充内容** | Firmalife | **重制**（§6.5 ④） | 🟠 P1 |

#### 5.1.1 🛑 A 层已有但**未闭环**的物种 —— B 该怎么接管（**否则会撞 §〇.2.6 红线 2**）

实测发现：**A 层已经有 5 类"占位 / 半成品"物种**，而 B 正要深化它们。
若 B 直接覆盖 A 的资源，就违反红线 2（"B 不得写 `assets/tfcfarmingplus/**`"）⇒ **A 就不再能单独发布**。

| A 层已有的 | 实测证据 | A 的状态 | ✅ B 的正确做法 | ❌ 错误做法 |
|---|---|---|---|---|
| **茶** `tea_bush` | `blockstates/plant/tea_bush.json` + `tea_bush_cane.json` | **占位灌木形态**（`docs/74` §10.2-25） | **只补加工链**：B 新增「茶叶 → 杀青 → 炒制 → 冲泡」的物品 / 配方 / 设备，**不动 A 的作物方块** | 覆盖 A 的 `tea_bush` 资源 |
| **咖啡** `coffee_bush` | 同上（`coffee_bush` + `coffee_bush_cane`） | **占位灌木形态**（§10.2-26） | 同上：补「咖啡豆 → 烘焙 → 研磨 → 冲泡」 | 覆盖 A 资源 |
| **啤酒花** `hops` | `blockstates/{crop,wild_crop,dead_crop}/hops.json`（三套齐全） | **完整作物，但 TFC / Firmalife 里无任何配方用它** | 补「hops → 啤酒」的工序（配合 §13.3-1 麦芽化） | 覆盖 A 资源 |
| **纤维 5 种** | `blockstates/{crop,wild_crop,dead_crop}/{cotton,flax,hemp,ramie,sisal}.json`（**三套齐全**） | **完整作物，但产物无出口**（§1.2 最明显的断链） | 补「沤麻 → 打麻 → 纤维 → 纺织」（§13.3-5，Firmalife 已有 `loom` 织机 1 条可对齐） | 覆盖 A 资源 |
| **桑树** `mulberry` | `blockstates/plant/mulberry_{sapling,branch,growing_branch,leaves}.json` | **完整果树，已进果树管线** | 作养蚕的**第二饲料**（与 Firmalife `fruit_leaf` 并列，§6.4） | — |

✅ **定则（写进 §〇.2.6 红线的执行细则）**：

> **A 层已存在的物种，B 一律"只加链条、不碰方块"** —— B 的新增内容全部落在
> **`tfcagricultureplus:`** 的新 ID 上，A 的物种仅作为**原料提供方**存在。
> 只有用户**点名要改造物种形态**的两处（**草莓**、**可可**）才允许覆盖，
> 而它们覆盖的是 **TFC / Firmalife 的资源**（不是 A 的），因此**仍然不违反红线 2**。

⚠️ 这条定则同时更正了 §6.7-E1 的措辞：**茶 / 咖啡 / hops 不是"新增物种"，而是"给 A 层已有的占位物种补链"**。

### 5.2 ★ 用户点名的两个接管

#### 草莓（接管 TFC）

| 项 | 内容 |
|---|---|
| 现状 | TFC `tfc:plant/strawberry_bush`（`StationaryBerryBushBlock` 矮灌木，3 stage）；**46 条**资源；Firmalife 另有 `plantable/strawberry` + 草莓冰淇淋等 11 条；**本模组 0 条**（这就是漏掉的部分） |
| B 的做法 | 🛑 **做成普通作物，不是灌木**（用户指示）—— 用已有的**耕地作物管线**（`MyCropBlock`，6 个龄阶段）：`tfcfarmingplus:crop/strawberry` + 几何 + 贴图 + 掉落 + `plantable` + 果酱 / 干燥 / 冰淇淋接入 |
| 覆盖方式 | 把 TFC 的 `plant/strawberry_bush` **替换为我们的作物形态**：`assets/tfc/**` 资源覆盖 + 数据侧追加式标签（**只覆盖资源与数据，不改 TFC 代码**） |
| 回滚 | 删除 B 的覆盖目录即恢复 TFC 原样 |
| 判据 | 世界里长出来的是**我们风格的草莓作物**（与 86 种作物同族、**不是矮灌木**），且能进果酱 / 干燥 / 冰淇淋链 |

#### 可可（接管 Firmalife）

| 项 | 内容 |
|---|---|
| 现状 | Firmalife `plant/cocoa_{sapling,leaves,branch,growing_branch}` —— **它把可可做成了普通果树四件套**（`docs/74` L2392 曾把它当"权威示范"）；**58 条**资源；完整可可→巧克力链 |
| B 的做法 | **完全重制**：可可树 / 果实 / 加工链全部由 B 重建（实现手段含已有的 `TrunkFruitBlock` 等部件，但**不以"有现成件"为理由**） |
| 具体 | ① `MyBranchFruits.SPECIES` 加第 8 种 `cocoa`（物候表须含 `FRUITING`）；② 覆盖 Firmalife 的 `plant/cocoa_*`；③ 加工链：可可豆 →（发酵）→ 烘焙 → 研磨 → 巧克力（**连链一起重制**，Firmalife 做法仅作参考） |
| 回滚 | 删除 B 的 `assets/firmalife/**`、`data/firmalife/**` 覆盖目录 |

### 5.3 推进分层（**目标级别 = 系统级，每层都要完成**）

> 分层只是**推进顺序**，不是"做到某一级就收工"。

| 层 | 范围 | 目标 |
|---|---|---|
| L-1 | **物种覆盖**（§5.1 物种行） | ✅ 必须完成 |
| L-2 | **加工链覆盖**（干燥 / 发酵 / 烘焙 / 混合 / 离心 / 食物体系 / 果酱 / 奶酪 / 酒 / 可可 / 面食 / 豆制品 / 香料） | ✅ 必须完成 |
| L-3 | **系统级覆盖**（温室 / 灌溉 / 种植容器 / 树液） | ✅ **必须完成** |
| — | 养蜂 · 动力系统 | ❌ 例外：不动 |

#### 5.3.1 L-2 逐链清单（**把"必须完成"落到每一条链上**）

> 全部数字来自 §3.1 / §3.2 的**内容口径**实测。下表回答"**这条链覆盖什么、新增什么、算谁的**"。

| # | 链 | 邻居现状（实测） | 覆盖对象 | B 的做法 | 新增内容 | 批次 |
|---|---|---|---|---|---|---|
| 1 | **干燥** | Firmalife `drying` **16 条** + 设备 `drying_mat` / `solar_drier` | `data/firmalife/recipe/drying/**` + 两台设备 | **重制设备**（自建干燥架，§9.2 #1 试点）+ 保留数据侧配方类型 | 干燥架 · 晒架（`in_world`） | P0 |
| 2 | **发酵** | Firmalife **`vat` 53 条（发酵主力）**；TFC `barrel_sealed` **308 条**（⚠️ 其中真发酵只有 beer / medium_leather / large_leather，其余是染色/漂白） | `firmalife:vat` 相关 + TFC 的 `barrel_sealed` | **保留两条发酵路径**，新增我们的原料（麦芽汁 / 果浆 / 茶 / 咖啡） | 麦芽化（§13.3-1）· 果汁取汁 | P1 |
| 3 | **烘焙 / 烤箱** | Firmalife `oven` **16 条** + **5 材质烤箱（含 insulated 变体）** | `data/firmalife/recipe/oven/**` + 烤箱方块 | **重制烤箱系统**（材质 / 保温 / 燃料） | 面团成型台（§9.2 #3） | P1 |
| 4 | **混合** | Firmalife `mixing_bowl` **15 条** | 同上 | **并入新设备**（研钵 / 混合碗），不做独立 GUI 体系 | 研钵（§9.2 #10） | P2 |
| 5 | **离心** | Firmalife `centrifuge` **3 条**（规模小） | 同上 | ⚠️ **规模太小，评估是否保留**（3 条配方撑不起一台设备的成本） | — | P3 |
| 6 | **果酱 / 装罐** | TFC `pot_jam` **66 条** · `crafting/jar/` 23 目录口径 · Firmalife `jarring_station` | TFC `pot_jam` 数据 + Firmalife 装罐站 | **系统级重制**：果酱 / 保鲜 / 罐装 三合一 | 保冷设施（§9.2 #8） | P1 |
| 7 | **奶酪** | Firmalife **7 奶酪轮** + 凝乳链 | Firmalife 奶酪方块与配方 | **重制熟成环节**（§13.3-4 熟成架） | 熟成架 | P2 |
| 8 | **酒** | Firmalife **33 条**（含 sparkling / `tirage_mixture`）；TFC **8 种酒** | 两边的酒链 | **保留酒的种类**，重制**原料供给**（我们的果实 / 谷物） | 葡萄（棚架接管） | P1 |
| 9 | **可可** | Firmalife **58 条**（可可→巧克力全链） | `plant/cocoa_*` + 可可加工配方 | ⭐ **完全重制**（用户点名，§5.2） | 可可第 8 种枝干果实 + 全链 | **P0** |
| 10 | **面食** | Firmalife 面食 / 比萨 / 面条 | 相关配方 | **重制**：14 谷物 → 面粉 → 面团 → 面食 | 面团成型台 | P1 |
| 11 | **豆制品** | Firmalife 豆腐 / 豆酱（soy paste） | 相关配方 | **重制**：大豆 → 豆浆 → 豆腐 / 发酵 | 与 `vat` 链合流 | P2 |
| 12 | **香料** | Firmalife **8 种香料植物** → 7 种香料（**刀切 / 磨 / 干燥三条工序**） | `plant/{basil,bay_laurel,cardamom,cilantro,cumin,oregano,pimento,vanilla}` | ⭐ **接管（从零做）** —— A 层**没有香料**（§5.1.1） | 8 种香料作物 + 香料架 | P1 |
| 13 | **派（流程 + 填充）** | Firmalife 派 | 派方块与配方 | ⭐ **重制制作流程与填充内容**（用户点名，§6.5 ④） | 派盘 · 填充物（我们的果实 / 蔬菜 / 调料） | P1 |
| 14 | **食物 / 营养 / 腐烂** | TFC 核心（`data/tfc/food/**`，A 层已写 **140** 个） | 🛑 **TFC 的 Java 逻辑**（数据改不了行为） | 🆕 **调料改走 `FoodTrait`（零 mixin，§6.5）** ⇒ mixin 只剩「**地窖 / 保冷延长保质期**」一个用途（P1） | ~~调料影响营养~~ → **调料只影响保质期 + 加"味道"标签**（用户口径） | P1 |
| 15 | **汤 / 沙拉 / 三明治** | TFC 动态标签（`usable_in_*`） | 标签（**追加式，非覆盖**） | A 层已做零配方接入（§4.1）⇒ B 只加**带调料的新变体** | 调料入汤 / 沙拉 | P1 |

⚠️ **第 5 行（离心）是本节唯一建议"评估砍掉"的链** —— 3 条配方不值得一台独立设备；
它的功能可以并入 `mixing_bowl` 的替代设备。**其余 14 条全部保留**（用户口径：完全重制）。


### 5.4 从 extradelight 汲取的设备灵感（B 重制后的设备实现参考）

extradelight 1.1.5（11,919 条目 / 26 配方类型）设备盘点后，**剔除三模组已有的**（`oven`/`vat`/`drying`/`mixing_bowl`），保留它独有的：

| # | 设备 | 借鉴自 | B 用它做什么 | 顺序 |
|---|---|---|---|---|
| 1 | **蒸发浓缩器** | `evaporator` | 糖浆 / 浓缩汁 / 树液浓缩（AFC 用 pot，效率低） | 🟠 P1 |
| 2 | **保冷设施（自建新内容）** | ⚠️ **不照搬 `chiller`** —— extradelight 的 `chiller` 主要用于**制造冷饮**；**延长保质期的保冷内容需我们自己设计新建**（冰窖 / 地窖 / 冰柜） | 主动延长腐烂（三方只有被动腐烂） | 🟠 P1 |
| 3 | **面团成型台** | `dough_shaping` | 14 谷物面食的前置工序 | 🟠 P1 |
| 4 | **油料压榨机** | `juicer` | ⚠️ **仅油料批量压榨**；果汁部分已否决（`docs/74` §580 纯数据即可） | 🟡 P2 |
| 5 | **研钵** | `mortar_stone` | 便携研磨（香料 / 药草少量） | 🟡 P2 |
| 6 | **香料架 / 调料柜** | `spice_rack` | 香料存储展示（配合 §6.5） | 🟠 P1 |
| 7 | ~~板条箱~~ | ~~`crate`~~ | ❌ **TFC 已有**（实测 141 条：`CrateBlock` + `CrateBlockEntity`）⇒ 不新增 | — |
| 8 | **大餐方块** | `feast` | 多人共享料理（三方无） | 🟡 P2 |
| 9 | **熔化锅** | `melting_pot` | 巧克力 / 糖 / 蜡（配合 §5.2 可可链） | 🟠 P1 |
| 10 | **漏斗 / 龙头** | `funnel` / `tap` | 流体与物品转运 | ⬜ P3 |

**不借鉴**：装饰体系（16 色壁纸 / 丝带 / 花环 / 野餐篮）· 独立农田维度 · 33 结构 · 画 / 旗帜图案 ·
它的 8 种自带作物（我们已有对应）· `result.id` 旧字段写法。

#### 5.4.1 🆕 从 **tfcwoodwork** 汲取的**机制**（不是设备）—— `in_world` 世界内加工

> §5.4 的设备表解决"**用什么机器**"；本小节解决"**在没有机器的地方怎么加工**"。逐项分析见 §7.2。

| # | 机制 | 借鉴自（✅ **MIT**，可学实现） | B 用它做什么 | 顺序 |
|---|---|---|---|---|
| 1 | ⭐ **`in_world` 配方类型** | `tfcwoodwork:in_world` —— **240 条**（= **12 类工序 × 20 种树**，实测） | **沤麻（水中浸数日）· 脱粒 · 晒干 · 碾米 · 剥壳 · 压榨** —— 🛑 TFC 的 24 类配方**没有这一类**（Firmalife 只有 `stomping` 踩踏 4 条 + `loom` 织机 1 条，覆盖不到"沤麻 / 晒干 / 脱粒"）；没有它，这些工序只能退化成合成台配方 | 🟠 **P1**（与 §13.3-5 纤维试点绑定） |
| 2 | **工具门控 `requiredTool`** | 同上 | 同一方块 + 不同工具 → **不同产物**（"主/次产品"的天然分叉点，配合 §6.2） | 🟡 P2 |
| 3 | ⭐ **`tfc:fuel` 数据类型** | `data/tfcwoodwork/tfc/fuel/bark_*.json`（**100** 条 fuel · TFC 数据类型共 **107** 条） | 给秸秆 / 藤蔓 / 干叶写燃料定义 —— **零代码**（§13.2 横向深化的第 2 条出口） | 🔴 **P0** |
| 4 | **标签覆盖接入范式** | 11 条 `data/{tfc,minecraft,c}/tags/**` | 与 §4.1「零配方接入」**同一套思路的独立验证** | 🔴 P0 |
| 5 | **配方覆盖范式** | **182** 条 `data/tfc/recipe/**`（crafting 180 + pot 1 + heating 1） | 为 §5.5 的 197 项覆盖台账提供**先例证据** | 🟠 P1 |

✅ **前置问题已确认**（§7.2.3 反编译）：① `inputState` **只能枚举完整 `BlockState`**，没有属性表达式
⇒ 🛑 **不能直接用在"收获成熟作物"上**（我们的蔓延型作物 `age×fruiting×4向side` = 192 个状态）
⇒ 正确用法是**专用载体方块**（沤麻池 / 脱粒垫 / 晒架 / 碾磨槽 / 压榨槽），见 **§7.2.4.2**。
② 处理器挂在 **NeoForge 的 `RightClickBlock` 事件**上 ⇒ **该机制本身零 mixin**（⚠️ 这是**局部事实**，不代表 B 整体零 mixin —— B 整体按 §12.6 **必须**用 mixin）。

❌ **不纳入**：原木堆扩展（`LogPileExBlock` / `BurningLogPileExBlock`）与 3 个投掷实体 ——
木材与动力系统不是农业重制的范围（用户口径：**动力系统不动**）。

### 5.5 覆盖台账与回滚（**实测 197 个文件，v12 前只登记了 6 个**）

> ⚠️ **本轮（v13）实测修正**：项目**已经在跨命名空间写 197 个文件**，而 v12 的登记表只有 6 个。
> 覆盖有 **5 种形态**，风险与回滚方式各不相同。

| 类型 | 实测数量 | 路径 / 例子 | 方式 | 风险 | 回滚 |
|---|---|---|---|---|---|
| **A 资源覆盖** | **6** | `assets/tfc/models/block/crop/cabbage_age_{0..5}.json` | 同路径**替换** | 低 | 删文件 |
| **B 手册覆盖** | **14** | `assets/tfc/patchouli_books/field_guide/**` | 同路径**替换**（把我们的作物写进 TFC 野外指南） | 中 | 删文件 |
| **C 追加式数据** | **155** | `data/firmalife/firmalife/plantable/**` | 往**邻居命名空间新增文件**（Firmalife 自带 63 个，与我们**同名 0**） | 🟡 **中**：邻居更新若新增同名文件 ⇒ 冲突（谁生效取决于加载顺序） | 删目录 |
| **D 标签覆盖（整文件）** | **21** | `data/tfc/tags/**` 13 · `data/minecraft/tags/**` 4 · `data/c/tags/**` 4 | 写入邻居命名空间 —— ⚠️ **实测更正（§5.5.2）**：我方 21 个文件**全部 `replace=false`**（合并语义）⇒ **漏抄不会清空邻居**；真实风险是"自己的条目没生效" | 🟡 **中**（原判 🔴 高，已更正） | 删文件 |
| **E 世界生成标签** | 含在 D 内 3 | `data/tfc/tags/worldgen/placed_feature/feature/{crops,berry_bushes,fruit_trees}.json`（**12 + 86 + 48 条**） | 写入邻居命名空间（`replace=false`） | 🟡 **中** —— ⚠️ **更正**：不会"全部不生成"；真实风险是**我们自己的 146 个 patch 没被引用到**（这个风险是真的，但成因不同） | 删文件 |

**必须建立的三条机制**

1. **`OVERRIDE-REGISTRY.md`**：按上表五类逐条登记（路径 / 类型 / 用途 / 依赖 / 回滚动作），**每批次更新**。
2. **D / E 类的"对齐检查"**：每次**邻居模组更新**后，把邻居的新条目**抄回我们的标签文件**（否则我们成了"内容黑洞"）。
   可写成脚本：对比邻居 jar 里的同路径文件 vs 我们的文件，列出**我们漏掉的条目**。
3. **C 类的"冲突预警"**：邻居更新后对比同名文件（当前 0 个冲突），一旦出现即需人工裁决。

**当前已知的回滚单位**

| 单位 | 回滚动作 | 影响面 |
|---|---|---|
| 单次覆盖批次 | 删对应目录 / 文件 | 邻居恢复原貌（无存档影响） |
| **整个 B 模组** | 卸载 | 邻居全部恢复原貌；A 的接入仍在 |

#### 5.5.1 回滚手册（**"卸载 B ⇒ 邻居恢复原貌"这句话必须能兑现**）

**回滚分三层，必须分开做**（混着做 = 出事后无法判断是哪一层的问题）：

| 层 | 内容 | 回滚动作 | 会不会伤存档 |
|---|---|---|---|
| **① 资源层** | A~E 五类覆盖（197 文件） | 删对应目录 / 文件 | ✅ **不伤** —— 邻居的原文件从未被改动，只是**加载时被我们盖住** |
| **② 数据层** | 我们往邻居命名空间**新增**的文件（C 类 155 个 `plantable`） | 删目录 | ✅ **不伤** —— 邻居根本不知道它们存在 |
| **③ 代码层** | B **自己注册**的方块 / 物品 / 实体 / BE / 配方类型 | 卸载 jar | 🛑 **会伤**（见下） |

🛑 **③ 层是唯一真正有存档风险的，必须提前设计**：

| 卸载 B 后，存档里存在… | MC / NeoForge 的实际行为 | 我们要做什么 |
|---|---|---|
| B 的**方块** | 变成**空气**（找不到 ID，`RemapHelper` 无法映射） | 文档写明；且**首次启动不往世界生成 B 独有方块**（保守） |
| B 的**物品**（在箱子 / 背包里） | **消失** | 同上 |
| B 的 **BE 数据**（设备内容物） | **丢失** | 同上 |
| B 的**配方** | 消失（正常，无副作用） | — |
| **A 的方块与物品**（B 只是加链条） | ✅ **完全不受影响** —— 这是 §5.1.1 定则的直接红利 | — |

⇒ **由此得出一条排期约束（不是巧合，是故意的）**：

> **B 的"新方块"（§9.2 的 18 台设备，含菌包 / 养蚕架 / 温室地窖）越晚铺开，存档风险越小。**
> §9.2 把设备分成 **P0 试点 → P1 → P2/P3** 三档，正好也是**存档风险递增**的顺序 ——
> 先让 §9.1 的**补链型**内容（只加物品与配方、不动世界）跑通，再铺设备。

**一键回滚脚本**（⏳ 待写：`moddev/tools/rollback-b.ps1`）

```
输入：批次 ID（对应 OVERRIDE-REGISTRY.md 里的一节）
动作：① 按台账列出该批次的全部文件
      ② 移动到 _rollback/<批次ID>/（不删，保留证据）
      ③ 复跑 verify.ps1
      ④ 输出"邻居哪些文件恢复了"的清单
判据：verify.ps1 全绿 + 游戏内邻居内容恢复原貌 + A 的 146 物种无变化
```

**演练频率**：**每个覆盖批次收口时必做一次**（§9.0-C 批次级验证表最后一行）。

#### 5.5.2 覆盖台账 ↔ 逐链清单的交叉映射（**197 个文件逐组归属**，v14 第 9 轮）

> 目的：§5.5 只登记了"**有多少个**"，本节回答"**每一个为什么改、归哪条链、谁负责**"。
> 明细来源：扫描 `src/main/resources` 下**非 `tfcfarmingplus` 命名空间**的全部文件（实测 197）。

| 组 | 文件数 | 实测路径 | 为什么改 | 归属 | 回滚 |
|---|---|---|---|---|---|
| **A1** 模型覆盖 | **6** | `assets/tfc/models/block/crop/cabbage_age_{0..5}.json` | 覆盖 TFC 卷心菜的几何（A 层样板） | §9.1 **②接管**（TFC 29 作物） | 删文件 |
| **B1** 手册 | **14** | `assets/tfc/patchouli_books/field_guide/{en_us,zh_cn}/…`（各 7 = 1 分类 + 6 条目） | 把我们的作物写进 **TFC 野外指南** | §9.4 收尾（手册） | 删文件 |
| **C1** Firmalife 种植盆 | **155** | `data/firmalife/firmalife/plantable/<species>.json` | 让物种能种进 Firmalife 种植盆（**Firmalife 自带 63，同名冲突 0** ✅） | §4.1 **A 层接入** | 删目录 |
| **C2** 蜜蜂叶子 | **1** | `data/firmalife/tags/block/buzzing_leaves.json`（**48 条果树叶子**） | 让 **Firmalife 的蜜蜂**会在我们的果树上活动 | §4.1 A 层接入 | 删文件 |
| **D1** TFC 方块标签 | **9** | `data/tfc/tags/block/{can_be_snow_piled, crops, fox_raidable, fruit_tree_branches, fruit_tree_leaves, fruit_tree_saplings, spreading_bushes, spreading_bushes/living, thorny_bushes}.json` | 让 TFC 机制认识我们的方块（积雪 / 狐狸偷吃 / 果树三件套 / 蔓延 / 带刺） | §4.1 A 层接入 | 删文件 |
| **D2** TFC 物品标签 | **1** | `data/tfc/tags/item/wild_crops.json` | 野生作物归类 | §4.1 | 删文件 |
| **D3** 世界生成标签 | **3** | `data/tfc/tags/worldgen/placed_feature/feature/{berry_bushes **12**, crops **86**, fruit_trees **48**}.json` | **让我们的野生植物真的生成到世界里** | §4.1 A 层（**最关键**，见下） | 删文件 |
| **D4** vanilla 标签 | **4** | `data/minecraft/tags/{block/{leaves, mineable/axe, mineable/hoe}, item/leaves}.json` | 方块能被斧 / 锄挖、叶子归类 | §4.1 | 删文件 |
| **D5** 通用标签 | **4** | `data/c/tags/item/{foods/{fruit, grain, vegetable}, seeds}.json` | 跨模组互认（`c:` 是通用约定） | §4.1 | 删文件 |

**合计 = 197** ✅（与 §5.5 一致：A 6 + B 14 + C 156 + D 21）

⭐ **一个此前没被点明的事实**：这 197 个文件里 **191 个属于 A 层的"接入"工作**（C/D 两组 156 + D 五组 21 = 177，
加 A1 的 6 与 B1 的 14 也都在 A 阶段落地）—— **只有 A1 那 6 个模型是"覆盖"语义**。
⇒ **B 的覆盖工作量被高估了**：B 真正的"覆盖"对象主要是 §5.3.1 逐链清单里那 15 条链的**配方与设备**，
而不是这 197 个已完成的接入文件。

##### 🛑 风险等级更正：D 类不是"🔴 高"（v14 第 9 轮实测推翻）

§5.5 把"整文件标签覆盖"定为 **🔴 漏抄原有条目就会清空原内容** —— **实测不成立**：

| 核实项 | 实测结果 |
|---|---|
| 我方 **21 个标签文件**的 `replace` 值 | ✅ **全部 `false`**（`replace = true` 的文件数 = **0**） |
| 邻居同路径文件（`worldgen/.../{berry_bushes, crops, fruit_trees}`） | ✅ 也是 **`replace = false`** |
| MC / NeoForge 规范 | `replace` **缺省即 `false`** ⇒ 「**追加 / 合并**」语义，**不是替换** |

⇒ **结论**：只要我方**始终写 `replace=false`**（现状如此），**漏抄邻居条目不会清空任何东西** ——
邻居的条目来自**邻居自己的文件**，两边是合并关系。
⇒ D 类风险应从 🔴 **下调为 🟡**：真实风险变成"**我们自己的条目没生效**"，而不是"清空邻居"。

🛑 **由此得到一条可检查的硬规则（补进 §9.0-C 的标签审计脚本）**：

> **我方写入邻居命名空间的每一个标签文件，`replace` 必须是 `false` 或缺省。**
> 一旦出现 `replace: true`，就会**真的清空**邻居同名标签 ⇒ **这是唯一的灾难性写法**，必须由脚本拦截。

##### 🆕 顺带查出的两个 A 层问题（v14 第 9 轮）

| # | 问题 | 依据 | 处置 |
|---|---|---|---|
| 1 | 🛑 **`data/tfc/tags/block/crops.json` 可能是死文件** | 反编译 `TFCTags$Blocks` 得到它的**全部**方块标签常量：`FRUIT_TREE_BRANCH` · `FRUIT_TREE_LEAVES` · `FRUIT_TREE_SAPLING` · `LIVING_SPREADING_BUSHES` · `SPREADING_BUSHES` · `THORNY_BUSHES` · `CAN_BE_SNOW_PILED` · `BUSH_PLANTABLE_ON` · `SEA_BUSH_PLANTABLE_ON` · `FOX_RAIDABLE` —— 🛑 **列表里没有 `CROPS`**（TFC 用的是 **`minecraft:crops`**，jar 内实测为 `data/minecraft/tags/block/crops.json`） | 标为**待确认**；确认无人引用后删除（⚠️ 删资源后必须 `gradle clean build`，§二-4） |
| 2 | 🆕 **两个标签我们没接**：`tfc:bush_plantable_on` 与 `tfc:sea_bush_plantable_on` | 同上反编译 —— `TFCTags$Blocks` 里**确实存在这两个常量**，但 §5.5 的 197 文件里**没有**它们 | ⚠️ 若 B 重制灌木时需要自定义种植介质，**必须补上** |

### 5.6 温室 / 地窖 / 灌溉的重制（参考模组 = **firmalifehardcore**，已安装）

**参考模组实测**（`firmalifehardcore-neoforge-0.3.4-beta.jar`，401 条目 / 51 class）：

| 维度 | 内容 |
|---|---|
| 命名空间 | `firmalifehardcore`（自身）+ **覆盖 Firmalife 的 114 条 crafting 配方** + 21 个 `assets/tfc` + 8 个 `data/tfc` |
| **地窖系统** | `CellarDetector` / `CellarSpace` / `CellarTracker` / `CellarSavedData` / `CellarAttachment` / `CellarInventoryHelper` / `CellarTierAccessor` / `CellarDebugInfo`（BFS 检测 `BfsNode` + 分级 `CellarDetector.Type`） |
| 地窖建材 | `ReinforcedSoilBlock`（8 土纲）+ `ReinforcedSoilBeamBlock`（梁）+ `ReinforcedSoilType` |
| 温度机制 | `ThermalConductivity`（热传导）· `CropTemperatureProvider` · `ThermometerTemperatureProvider` · `PumpTickManager` |
| **Mixin 改造**（关键范式） | `ClimateMixin`（气候）· `FoodShelfBlockEntityMixin` / `HangerBlockEntityMixin` / `LargeVesselBlockEntityMixin`（**保鲜容器接进地窖**）· `PumpingStationBlockEntityMixin` / `SprinklerBlockEntityMixin`（灌溉）· `AbstractSprinklerBlockMixin` · `ThermometerMixin` |
| 温室硬核化 | 气候校验（`climate_invalid`）· **需要自然光**（`no_sky`）· **需要上方空气**（`air_needed`）· **脱水**（`dehydrated`）· 氧化铜构件**需要清理**（`*_cleaning` 配方） |

**我们的重制方案**（✅ v14 已细化：§5.6.1 ~ §5.6.5）

| 项 | 做法 |
|---|---|
| 地窖 | 自建**地窖检测 + 分级**系统（不照搬其 `CellarAttachment` 实现）：加固建材 → 空间检测 → 分级 → **影响食物腐坏速率与作物温度** |
| 温室 | 自建温室方块组 + 气候校验；**采用其"硬核化"约束**（自然光 / 上方空气 / 脱水 / 构件维护）作为设计基线 |
| 灌溉 | 自建灌溉（水箱 / 喷淋 / 管道），**动力接 TFC 本体的机械**（⛔ 不重做动力） |
| 保鲜 | **自建容器**（食物架 / 挂架 / 大罐）**接进地窖分级** —— 参考它的**目的**（容器感知地窖等级 ⇒ 影响腐坏速率），但**实现走自建**：容器自己向地窖检测器查询"我在几级地窖里" |
| 🛑 边界与例外 | **默认自建容器**（不让邻居容器跟着我们改）；🆕 **但** §12.6.2 的 **#2** 已把"让**邻居的**保鲜容器受我们地窖分级影响"列入 **mixin 清单** ⇒ 若要做，**按 §12.6.4 处理与 firmalifehardcore 的目标冲突**（它已 mixin 了同一批类）。**B 的完整 mixin 清单与预算见 §12.6** |

#### 5.6.1 🛑 先解决一个被漏掉的冲突：**firmalifehardcore 已经装在这台服务器上了**

> 实测：`firmalifehardcore-neoforge-0.3.4-beta.jar` **在 `mods/` 里**（401 条目 / 51 class），
> 它已经提供了一整套**地窖 + 温室硬核化 + 灌溉**。而 B 的目标也是"系统级重制"这一块。
> ⇒ **两者同时启用 = 两套地窖/温室系统并存**，玩家会看到双重规则（甚至互相打架）。**旧稿完全没处理这个场景。**

| 场景 | 处置 | 理由 |
|---|---|---|
| **两者都装** | 🛑 **B 自动禁用自己的"地窖 / 温室 / 灌溉"三模块**，并在日志里明确提示"检测到 firmalifehardcore，B 的对应模块已让位" | 同一套玩法不该有两套实现；让位比打架好 |
| 只装 B | ✅ B 的三模块启用（**自包含**，不依赖 firmalifehardcore） | 玩家不该为了地窖被迫多装一个模组 |
| 只装 hardcore | ✅ 与 B 无关（B 不在场） | — |
| 🛑 **禁止** | B **不 mixin hardcore 的类、不覆盖它的资源**（§2.8 / §〇.2.6） | 它也是"邻居" |

⚠️ 这条要写进 **§〇.2.6 红线的执行细则**：**"邻居"不只是 TFC / Firmalife / afc，
还包括工作区里所有已安装的模组** —— B 的兼容检查必须覆盖它们。

#### 5.6.2 地窖：设计 + **性能策略**（§12.4 标记的最大风险）

| 维度 | 设计 | 依据 |
|---|---|---|
| **检测** | BFS 从"地窖入口方块"出发，判定封闭空间 | 学 hardcore 的 `CellarDetector` + `BfsNode` 思路 |
| 🛑 **缓存** | 结果存进 **`SavedData`**（学它的 `CellarSavedData`），**只在方块变化时重算** | ⚠️ **绝不每 tick 全量扫描** —— §12.4 红线 |
| **触发重算** | 监听方块更新事件（`BlockEvent`/`NeighbourNotify`）**并加节流**（同一区块 N tick 内合并） | 防"连续放方块时反复 BFS" |
| **分级依据** | **体积**（格数）+ **深度**（Y 与地表差）+ **封闭性**（有无漏气口）+ **建材**（加固土/梁，学它的 `ReinforcedSoilBlock` 8 土纲） | 玩家可理解的 4 个自变量 |
| **效果 1** | 食物**腐坏速率**按等级递减 | §5.6 保鲜 |
| **效果 2** | 内部**温度**影响作物（可用作"地窖育苗"） | 与温室互补 |
| **容器接入** | **自建容器**向地窖检测器查询"我在几级"；**邻居容器**若要一起受控 ⇒ 走 §12.6.2 **#2** 的 mixin | §5.6 边界 · §12.6.2 |
| ⚠️ **复杂度预算** | BFS 上限（建议 **≤ 4096 格**）+ 超限直接判"不是地窖" | 防巨型空间把服务器卡死 |

#### 5.6.3 温室：设计

| 维度 | 设计 |
|---|---|
| 方块组 | 框架（木/金属）+ 透光顶（玻璃/温室玻璃）+ 可选**加固土**墙基 |
| 气候校验（**采用 hardcore 的硬核化约束作为基线**） | 自然光（`no_sky`）· 上方需空气（`air_needed`）· 脱水（`dehydrated`）· 构件需维护（氧化铜清理 `*_cleaning`） |
| 效果 | **拓宽内部作物的气候忍受范围**（复用已有 `climate_range` 数据，**不改作物的定义**） |
| 与地窖的关系 | 温室 = 提温 / 地窖 = 保温 + 降腐坏；**两者共用同一套"空间检测 + 缓存"基建**（写一次，两处用） |
| 🛑 性能 | 同 §5.6.2：**事件驱动 + SavedData 缓存**，不每 tick 扫描 |

#### 5.6.4 灌溉：设计（**与 TFC 动力/流体的接口已证实可行**）

| 维度 | 设计 | 依据 |
|---|---|---|
| 水源 / 输水 | **接 TFC 本体的** `FluidPipeBlock` / `FluidPumpBlock` / `PumpBlockEntity` | §12.1（✅ 已证实） |
| 动力 | ⛔ **不重做动力** —— 用 TFC 的风车 / 水车 / 齿轮箱驱动泵 | 用户口径"动力系统不动" |
| 灌溉方式 | 喷淋（`sprinkler`）+ 水渠（`channel`）两种，**不做复杂管网** | 与 §13.4-4 的"水分分档"合并，**避免双重实现** |
| 效果 | 提高土壤**墒情**（§13.4-4 若立项，则灌溉是它的唯一实现入口） | — |

#### 5.6.5 三模块的性能预算（**动手前必须认账**）

| 项 | 策略 | 红线 |
|---|---|---|
| 空间检测 | BFS + `SavedData` 缓存 + 事件触发 + 节流 | 🛑 **禁止每 tick 全量扫描** |
| BFS 规模上限 | **≤ 4096 格**（超限判非地窖/温室） | 防巨型空间 |
| 温度重算 | 只在**空间边界变化**时重算，不随时钟 | — |
| 灌溉 | 只在**有作物需要水**时查询，不遍历全田 | — |
| 与 hardcore 并存 | §5.6.1 的让位机制 | 避免双重 tick 开销 |


---

## 六、模组 B（下）：重制与新增内容

> 本章 9 节：**搁置解禁**（6.1）· **主次产品体系**（6.2 = 核心）· **新鲜草**（6.3）· **养蚕**（6.4）· **调料系统**（6.5）·
> **炒锅类设备**（6.6）· **功能域外扩展**（6.7）· **育秧到收获全流程**（6.8）· **液体腐坏**（6.9，已降级为高风险项）。

### 6.1 搁置项解禁

| 原搁置项 | 出处 | 新方案 |
|---|---|---|
| **蘑菇 / 竹笋** | `docs/74` §10.2-9 | ✅ **解禁**：新增**菌包方块**（`tfcfarmingplus:mushroom_bag`）—— 接种孢子 / 菌种 → 控温控湿培养 → 收获蘑菇 |
| **取汁 / 果汁** | `docs/74` §10.2-16 | ✅ **解禁**：基础走 TFC `BarrelRecipe`（水果 + 桶，**纯数据无需新方块**）；B 层再加压榨设备作批量升级 |
| TFC 树改造 | `docs/74` §10.2-17 | ✅ **不涉及**（用户指示：TFC 的树不需要改造） |
| **亚麻类多用作物** | `docs/74` §10.2-27 | ✅ **解禁 = 本方案主体** ⇒ 见 §6.2 |

#### 6.1.1 菌包培养的设计（🆕 v14 第 14 轮：补实测底料与真实成本）

🛑 **先确认底料**（实测）：**TFC 没有蘑菇**（jar 内 `mushroom` 的 **8 条命中全是"珊瑚蘑菇"** + vanilla 蘑菇汤配方）·
**Firmalife 也没有** · **A 层也没有**。
⇒ 唯一现成的是 **vanilla 的 `minecraft:brown_mushroom` / `red_mushroom``**。

| 项 | 设计 |
|---|---|
| 方块 | `mushroom_bag`（菌包）· `stage`(0 空包 / 1 走菌 / 2 出菇 / 3 枯竭) = **4 个状态** ✅（≤8，§7.2.5） |
| 接种 | 菌包 + **孢子**（从野生蘑菇获得）→ 开始培养；`stage` 0 → 1 |
| **湿度 / 温度** | ⭐ **复用 §5.6 的温室 / 地窖模型**（湿度走灌溉、温度走地窖）—— **不新建一套环境系统** |
| 生长 | **随机刻推进**（与 TFC 作物同构，`AGENTS.md` 的 A 类机制） |
| 收获 | `stage=2` 右键 / 破坏 → 蘑菇 × N |
| 枯竭 | `stage=3` → 打碎得**废菌包** → 堆肥（回到 §13.2 的横向出口） |

**品种清单**（⚠️ 三方都没有 ⇒ **全部是新物种**）：

| 类 | 品种 | 现实原型 |
|---|---|---|
| **食用菌 5 种** | 平菇 `oyster` · 香菇 `shiitake` · 双孢菇 `button` · 金针菇 `enoki` · 木耳 `wood_ear` | 常见栽培种 |
| **药用菌 2 种** | 灵芝 `reishi` · 猴头菇 `lions_mane` | 配合 §6.7-**E3**（药草 / 药用） |
| **底料** | ⭐ **vanilla 的 `brown_mushroom` / `red_mushroom`** | **现成，零新增** |

🛑 **成本更正（旧稿低估了）**：旧稿写"1 方块 + 3~5 品种"，但实测底料只有 vanilla 的 2 种 ⇒
**7 个新物种 ×（方块 + 物品 + 贴图）≈ 7 方块 + 14 物品 + ~20 贴图** ——
**这不是一个小功能**，应排在 §9.1 的 **P2**（与养蚕同档）。

| 与竹笋区分 | 竹笋走**竹林**（借 AFC 60 树种的形态），**不属于菌包** |
|---|---|

#### 6.1.2 取汁 / 果汁的具体做法（🆕 补）

| 项 | 设计 |
|---|---|
| **基础路径** | ⭐ **纯数据**：TFC `BarrelRecipe`（水果 + 水 → 果汁）—— 复用 TFC 的 `barrel`，**无需新方块**（`docs/74` L580 已论证） |
| 中间产物 | `tfcagricultureplus:juice_bottle` —— 🛑 **按 §6.9 的 D 方案做成 TFC 食物物品** ⇒ **天然带保质期** |
| 加压榨设备 | §9.2 **#9**（P2，只做**油料**批量压榨；果汁已否决设备化） |
| ⭐ **与 §6.9 的关系** | **果汁是"液体保质期 D 方案"的第一个应用场景** —— 瓶装果汁会腐坏，且能进 §5.6 的保冷设施 |


### 6.2 ★ 主产品 / 次产品体系

**定义（用户澄清）**：主 / 次产品是**破坏作物方块时一次产生的多种产物**（不是加工出来的）。

**三类副产物（用户分类）**

| 类 | 用途 | 举例 |
|---|---|---|
| **① 只能堆肥**（无用的叶子） | 堆肥 `compost` | 大部分蔬菜的老叶、外皮 |
| **② 可用于扦插育苗** | **繁殖材料**（接 §6.8 育秧流程） | 红薯藤、草莓匍匐茎、木薯茎段、香草 / 薄荷插条、灌木枝条 |
| **③ 其它用途** | 食用 / 药用 / 纤维 / 油 / 燃料 / 染料 / 饲料 | **红薯叶（可食用）**· 萝卜 / 甜菜叶 · 豆荚 · 谷壳 · 秸秆 |

> ⭐ **这不是我们发明的概念 —— TFC 自己就有**：6 种谷物的脱粒配方（`crafting/food/*_grain.json`）用
> `tfc:advanced_shapeless_crafting` + **`tfc:extra_products` modifier** 实现「主产品谷粒 + 次产品 1 `straw`」。
> ⇒ 本体系**延续 TFC 的原生范式**，且**可直接复用这个 modifier**，无需自研机制。

**关键案例：块茎类的叶与藤（本文档 v8 漏掉的）**

- 现实里**红薯的嫩叶是可食用蔬菜** ⇒ 主产品（块根）+ 副产物（叶，**可食用**）+ 藤蔓（**可扦插育苗**）
- 同类作物：`sunchoke`（菊芋）· `yacon`（雪莲果）· `taro`（芋头）· `cassava`（TFC）· `ginger` / `turmeric`（根茎）
  —— **块茎 / 根茎类的叶与藤都有价值，不能一律当"无用叶子"**
- ⇒ 同一"叶"在不同族里可能分属不同类：**叶菜的叶是主产品；块茎类的叶是③可食用副产物；果菜的老叶是①堆肥**

**逐族设计表**（主产品 + 副产物 + 归类）

| 族 | 主产品 | 副产物 | 副产物归类 |
|---|---|---|---|
| 谷物（14） | 谷粒 | 秸秆 | ③ 饲料 / 编织 / 燃料 |
| 豆类（11） | 豆 | 荚 / 藤 | ③ 饲料；② 部分可扦插 |
| 纤维（5） | 长纤维 | 种子 / 短纤维 / 芯 | ③ 油 / 纸 |
| 油料（4） | 油 | 饼粕 | ③ 饲料 |
| **块茎 / 根茎**（sunchoke / yacon / taro / ginger / turmeric / celeriac / parsnip / turnip / salsify / chicory_root / shallot） | 块根 / 块茎 | **叶 / 藤** | ⭐ **③ 可食用**（红薯叶范式）+ **② 可扦插**（无性繁殖作物） |
| 叶菜（spinach / lettuce / kale / napa_cabbage / mustard_greens …） | 叶球 / 叶片 | 外叶 / 老叶 | ① 堆肥（主）；③ 部分可腌 |
| 果菜（chili / eggplant / okra / asparagus …） | 果 | 茎叶 | ① 堆肥；② 部分可扦插 |
| 瓜果藤（10） | 果 | 籽 / 皮 / 瓤 | ③ 籽（油 / 零食）；② 部分可扦插 |
| 水生（9） | 块茎 / 籽 | 叶 / 茎 | ③ 饲料 / 编织；② 部分可分株 |
| 果树（48） | 果 | 木 / 叶 / 核壳 | ③ 木料 / 燃料 / 叶（饲料 / 药） |
| 灌木（12） | 果 | 枝 / 叶 | ③ 染料 / 药用；**② 枝条可扦插育苗** |
| 树干果实（7） | 果 | 壳 / 木 | ③ 燃料 |
| 坚果 | 仁 | 壳 | ③ 燃料 / 活性炭 |

**多用作物清单**（副产物用途最丰富的 13 种，优先实现）

| 作物 | 用途 1 | 用途 2 | 用途 3 |
|---|---|---|---|
| **亚麻 `flax`** | 纤维（布） | 种子（油） | 秸秆（饲料） |
| **大麻 `hemp`** | 纤维（绳 / 布） | 种子（油） | 药用 |
| **棉花 `cotton`** | 纤维（布） | 种子（油） | 饲料 |
| **苎麻 `ramie`** | 纤维（高级布） | 纸 | 饲料 |
| **剑麻 `sisal`** | 纤维（绳） | 叶渣（饲料） | — |
| **红花 `safflower`** | 油 | 染料 | 药用 |
| **芝麻 `sesame`** | 油 | 食用 | 饲料 |
| **向日葵 `sunflower`** | 油 | 籽（食用） | 饲料 |
| **姜黄 `turmeric`** | 染料 | 药用 | 香料 |
| **葫芦巴 `fenugreek`** | 香料 | 药用 | 绿肥 |
| **紫苏 `perilla`** | 食用 | 药用 | 油 |
| **除虫菊 `garland_chrysanthemum`** | 杀虫 | 染料 | 观赏 |
| **高粱 `sorghum`** | 谷物 | 秸秆（饲料 / 编织） | 糖浆 |

> ⚠️ 副产物不要做成"多一个死物品"：① 类必须真能进 `compost`；② 类必须真能走 §6.8 的育苗流程；
> ③ 类必须在 TFC / Firmalife 已有体系里找到出口（饲料 → 23 种动物 food 标签；燃料 → `firepit`；
> 纸 → `unrefined_paper` 链；染料 → 16 色 barrel）。
### 6.3 新鲜草体系

> 🛑 **先纠正一个认知**：TFC 的 `straw` **本来就是"收割野草"的产物** ——
> 13 种野生草的掉落表是 `剪刀 → 草方块物品` / **`#tfc:tools/sharp` → `tfc:straw`**，而且**没有枯死状态判断**（§3.1）。
> ⇒ 本方案**不是**新增"从野草获得草"的第二条路径（那与 TFC 的 straw 掉落**重复**），
> 而是**把 TFC 的这份产出按植株状态细分**。

#### 6.3.1 实测：13 种野生草 + 掉落表原文

| # | 草 | # | 草 | # | 草 |
|---|---|---|---|---|---|
| 1 | `beachgrass` | 6 | `pampas_grass` | 11 | `switchgrass` |
| 2 | `bluegrass` | 7 | `raddia_grass` | 12 | `tall_fescue_grass` |
| 3 | `bromegrass` | 8 | `red_oat_grass` | 13 | `timothy_grass` |
| 4 | `fountain_grass` | 9 | `ryegrass` | | |
| 5 | `orchard_grass` | 10 | `scutch_grass` | | |

**掉落表真实结构**（`data/tfc/loot_table/blocks/plant/red_oat_grass.json` 原文）：

```json
{"type":"minecraft:block","pools":[{
  "name":"loot_pool","rolls":1,
  "entries":[{"type":"minecraft:alternatives","children":[
    {"type":"minecraft:item","name":"tfc:plant/red_oat_grass",
     "conditions":[{"condition":"minecraft:match_tool","predicate":{"items":"#c:tools/shear"}}]},
    {"type":"minecraft:item","name":"tfc:straw",
     "conditions":[{"condition":"minecraft:match_tool","predicate":{"items":"#tfc:tools/sharp"}}]}
  ]}],
  "conditions":[{"condition":"minecraft:survives_explosion"}]}]}
```

#### 6.3.2 🛑 一个必须先解决的矛盾：**TFC 的草"没有枯死状态"**

旧稿写"**活株（非枯死）→ 新鲜草；枯株（`dry_*`）→ 仍产 `tfc:straw`**"，但**实测不成立**：

| 实测 | 结论 |
|---|---|
| 13 种草的掉落表**只有 `match_tool` 条件**，**没有任何 block state 条件** | 掉落**不区分植株状态** |
| TFC 的 `plant/*_grass` 是 `PlantBlock` —— **只有 `AGE` 属性，没有"枯死"属性** | **没有"枯死"这个判据** |
| `dry_grass` 是**另一种独立的植物**（出现在 `compost_greens/low` 标签里） | 它**不是**这 13 种草的状态 |

⇒ 三个可行方案：

| 方案 | 判据 | 可行性 | 建议 |
|---|---|---|---|
| **A** | **按 `AGE`**：未成熟（`age < max`）→ **新鲜草**；成熟 → `tfc:straw` | ✅ **纯掉落表**（加 block state 条件） | ⭐ **推荐** —— 嫩草喂牲口、老草做秸秆，符合直觉 |
| **B** | **按工具**：**空手 / 剪刀 → 新鲜草**；利器 → `tfc:straw` | ✅ 纯掉落表 | 🟡 备选（但会改变现有工具语义） |
| **C** | 给草加"枯萎"状态 | ❌ 要改 TFC 的**方块** ⇒ **mixin** | ❌ 不值得（为一个小功能动 TFC 的作物方块） |

⚠️ **需用户裁决**：口径是"**在非枯死状态下收获野生草获得的是新鲜草**" ——
若"枯死"指的是 **`tfc:plant/dry_grass` 这类独立干旱植物**，则方案 A 的判据要从 `AGE` 换成
"**这是不是 dry 类植物**"（那反而更简单：**只改掉落表，连条件都不用加**）。

#### 6.3.3 设计（其余部分保持）

| 项 | 内容 |
|---|---|
| 新物品 | `tfcagricultureplus:fresh_grass`（新鲜草） |
| **改法（核心）** | **覆盖那 13 张野生草掉落表**（§5.5 的 D 类，⚠️ `replace=false`），在 `alternatives.children` **最前面**插入"→ 新鲜草"的分支；**保留**原有两条（剪刀 / 利器） |
| 来源 ② | **破坏未成熟作物的补偿产出**：复用 TFC 现成的 **`tfc:extra_products` modifier**（与谷物脱粒副产 straw **同一机制**）挂到作物掉落表 |
| 用途 ① | **饲料** —— 打进 TFC 的动物 food 标签（⚠️ **需先核对 `straw` 本身是否已在饲料标签里**） |
| 用途 ② | **晒干 → `tfc:straw`**（Firmalife `drying_mat` / `solar_drier`，或 TFC `heating`）⇒ 与 TFC 原有 straw 链**无缝衔接** |
| 用途 ③ | 堆肥（`compost_browns/low`）· 编织（先晒干再走 TFC 的 `basket` / `thatch` 链） |
| B 要做 | ① 注册物品 + 饲料标签；② **覆盖 13 张野草掉落表**；③ 作物掉落表加"未成熟补偿"（`extra_products`）；④ 干燥配方 |
| 🛑 不要做 | ❌ 不新增"野草 → 草"的第二条路径；❌ **不动 TFC 的 `straw` 用途链**（hay_block / basket / daub / drying_bricks / nest_box / thatch / 引火 / 坑窑） |


### 6.4 养蚕（"极低配的养蜂"）

| 项 | 内容 |
|---|---|
| 定位 | **简单的生产 + 繁殖机制，无育种**。⚠️ 参照物要比对准确：Firmalife 的养蜂有**蜂种 / 能力 / 寄生虫 / 遗传病**四套系统（§3.2），
所以养蚕不是"养蜂的 1/5"，而是**刻意砍掉全部育种与病害**的极简版 —— 只保留「喂 → 长 → 结茧 → 收」四步 |
| 载体 / 饲料 | ⭐ **直接用 Firmalife 已有的果树叶子物品 `firmalife:fruit_leaf`**（实测存在；另有方块形式 `plant/fig_leaves` / `plant/cocoa_leaves`）—— **不新增饲料物品**。🆕 第二饲料：**A 层已有 `mulberry`（桑树，果树四件套齐全）** ⇒ 桑叶可与 `fruit_leaf` 并列（更符合现实，且零新增物种） |
| 链路 | `fruit_leaf` → 喂蚕（蚕架方块）→ 蚕成长 → 结茧 → 收茧 →（煮茧缫丝）→ **丝线** → 织 **`tfc:silk_cloth`**（TFC 已有此布，无需新增布种） |
| 产出 | 丝线 · 蚕蛹（饲料 / 食用）· 蚕沙（肥料） |

#### 6.4.1 具体设计（**1 方块 + 4 物品 + 3~4 配方**，逐条到可开工）

| 项 | ID 候选 | 设计 |
|---|---|---|
| **蚕架**（方块） | `tfcagricultureplus:silkworm_rack` | `stage`(0 空 / 1 养蚕中 / 2 已结茧) = **3 个状态** ✅ 在 §7.2.5 的 ≤8 约束内；**需要 BE** 存生长进度（⚠️ 登记 `validBlocks`，否则放置即崩 —— §12.2 红线 1） |
| **蚕种**（物品） | `silkworm_egg` | **来源 = 掉落表**：`firmalife:fruit_leaf` 或桑叶的**稀有掉落**（**不改 TFC / Firmalife 的物品**，只改掉落表） |
| **蚕**（物品） | `silkworm` | 右键放到蚕架上（`stage=1`） |
| **茧**（物品） | `cocoon` | 蚕架 `stage=2` 时采收 |
| **丝线 / 丝绸** | ⭐ **不新增布种** | 煮茧 → **`tfc:silk_cloth`**（TFC 已有） |

| # | 配方 / 交互 | 类型 | 说明 |
|---|---|---|---|
| 1 | 桑叶 → 蚕种 | **掉落表**（不加配方） | 与 §6.3 新鲜草同一手法 |
| 2 | 蚕 + 蚕架 | **右键交互**（零配方） | `stage` 0 → 1 |
| 3 | 蚕架 + 饲料 → 成长 | **随机刻 + 消耗饲料** | 每消耗 1 份饲料推进一段（与 TFC 作物同构） |
| 4 | 茧 → 丝线 | `pot`（**煮茧缫丝**，比合成台更有仪式感） | 1 条 |

🛑 **刻意不做的三件事**（对照 §3.2 的养蜂**四套系统**）：

| 不做 | 对比养蜂 |
|---|---|
| ❌ **无育种** | 养蜂有 `BeeSpecies` 蜂种体系 |
| ❌ **无病害** | 养蜂有 `ParasiticInfection` + `GeneticDisease` 两套 |
| ❌ **无能力系统** | 养蜂有 `BeeAbility` |

⇒ 这正是用户说的"**极低配**"：养蜂 **136 条目**，养蚕控制在 **1 方块 + 4 物品 + 3~4 配方**。

| 复用 | TFC `sewing`（26 配方）/ `loom`（6 配方） |
| 规模 | 1 方块（蚕架）+ 3 物品（蚕 / 茧 / 丝）+ 3~4 配方 |
| 与养蜂的关系 | 养蜂**不覆盖**（保留 Firmalife）；养蚕是**新增**，两者并存 |

### 6.5 调料系统（**修改原有内容**）

> 用户指示：**调料可作为汤 / 沙拉 / 派的添加物**；**派的制作流程与填充内容同为重制目标**。

#### 6.5.1 🛑 先解决一个设计问题：**"能加"不等于"有意义"**

TFC 的汤 / 沙拉是**动态食物**：营养 = **所有成分的加总**（TFC 的 `FoodData` / Firmalife 的 `copy_dynamic_food`）。
而按 ①的设计，香料的营养是 **0**。
⇒ 🛑 **如果只是把香料塞进 `usable_in_soup`，玩家加了它，这碗汤一点变化都没有** —— 那就只是个空标签。

**"加调料"必须有可感知的效果**，三个可选（可叠加）：

| # | 效果 | 实现 | 成本 |
|---|---|---|---|
| ~~1~~ | ~~**营养加成**（调料 × 主料 ⇒ 营养提升）~~ | ❌ **用户口径否决**：「**调料只影响保质期，不影响营养值**（食物不会因为加了调料就变多）」 | — |
| **2** | ⭐ **保质期延长**（调过味的食物坏得慢） | ✅ 🆕 **零 mixin**：`FoodTrait` 就是「**名字 + `decayModifier` + tooltip**」，而 `FoodTraits.TRAITS` 是**可扩展的 `DeferredRegister`** ⇒ 注册我们自己的 trait + 配方挂 **`AddTraitModifier`** | **低** |
| **3** | ⭐ **「味道」标签**（用户口径的核心） | ✅ 同上 —— **trait 本身就是标签**（tooltip 显示风味），**无需任何额外机制** | **零** |

🆕 **2026-09-29 用户口径修正（重要）**：旧稿认为「调料系统必须配 mixin，否则只是空标签」—— **这个判断错了**。
实测 `FoodTrait` = **`{decayModifier: Supplier<Double>, translationKey}`**，且 `FoodTraits.TRAITS` **本身就是 `DeferredRegister`**
⇒ **注册自己的味道 trait（标准 NeoForge 注册）+ 配方挂 `AddTraitModifier`（TFC 现成修饰器）= 零 mixin**。
⇒ **调料系统的 mixin 需求归零**（§12.6.2 的 **#5 因此从 P0 降到 P1**）。

#### 6.5.2 四步落地

| 步 | 做法 | 依据 | 产出 |
|---|---|---|---|
| ① 注册调料 | 每种香料一份 **0 营养**的食物条目（`tfcagricultureplus:food/<spice>`） | extradelight 三套方案① | **8 种香料**的 food 定义 |
| ② 打标签 | `tfc:usable_in_{soup,salad}` + 自定义 `tfcagricultureplus:seasonings` | 方案② | 标签（**追加式，`replace=false`**） |
| ③ 改原有内容 | 覆盖 / 新增 **汤 · 沙拉 · 派** 的配方变体（产出"调味汤 / 调味沙拉 / 调味派"） | 用户指示 | 配方变体 |
| 🆕 ④ **让它可感知** | §6.5.1 的三选一（**至少做 #1**） | v14 补 | **mixin + 效果定义** |

#### 6.5.3 派的"流程 + 填充"重制（用户点名的第二项）

| 项 | Firmalife 现状 | 我们的重制 |
|---|---|---|
| **流程** | 派皮 + 填充 → 烤（一步） | **分层**：面团 → 派皮 → 填充 → **盖面** → 烤（多一步"盖面"，对应现实中的上下皮） |
| **填充** | 固定几种 | ⭐ **按 §13.2 的九个族开放**：果实 / 蔬菜 / 豆类 / 块根都能填，**调料是可选加成** |
| **切分** | 整个吃 | **大餐方块 `feast`**（§9.2 #11）—— 多人共享，切开分份 |
| **与调料的关系** | — | 派是调料三个载体（汤 / 沙拉 / 派）里**最能体现"填充内容重制"**的一个 |

#### 6.5.4 依赖关系（**动手顺序**）

```
§12.6.2 的 P0 mixin（腐坏推进 / 营养累积）
        ↓ 必须先做
§6.5 调料系统（否则是空标签）
        ↓
派的流程重制（§6.5.3）
```

| ④ **派的流程与填充重做** | `pie_pan` / `pie_dough` / `filled_pie` 的**制作流程与填充内容**：填充按作物族扩展（果实派 / 蔬菜派 / 肉派 / 鱼派），调料参与填充 | 用户指示 |
| ⑤ 数据驱动 | 若走炒锅类设备（§6.6），用其配置体系 | 方案③ |

🛑 顺序不能颠倒（0 营养条目 → 标签 → 配置），否则破坏营养与腐烂计算。

### 6.6 炒锅类新加工设备

| 设备 | 借鉴 | 用途 | 顺序 |
|---|---|---|---|
| **炒锅 `wok`** | extradelight 炒锅（数据驱动：`entries[]` + `min_time` / `max_time` / `stir_time` / `overcook_penalty` / `size`） | 快炒：蔬菜 / 肉 / 蛋组合 + **火候判定** | 🟠 P1 |
| **香料架 `spice_rack`** | extradelight | 调料存储（配合 §6.5） | 🟠 P1 |
| **大餐方块 `feast`** | extradelight（121 配方） | 多人共享料理 | 🟡 P2 |
| **模具与盛具** | `serving_pot` / `tray` / `pie_pan` / `loaf_pan` / `square_pan` / `muffin_tray` | 面食 / 派 / 面包成型 | 🟡 P2 |
| **部分自动化机器** | ⚠️ 建在 **TFC 本体的动力系统**之上（风车 / 水车 / 齿轮箱 / 曲轴；动力本身**不动** —— §3.3 实测 AFC 的 rotation 类 = **0**，动力是 TFC 的）：自动收割 / 自动喂食 / 灌溉泵 / 自动研磨 | **只做少数几台**，不追求全自动农场 | 🟠 P1 |

#### 6.6.1 炒锅 `wok` 的具体设计（🆕 v14 第 13 轮补）

| 项 | 设计 |
|---|---|
| 方块 | `tfcagricultureplus:wok` + **BE**（存内容物与计时） |
| 状态 | `heat`(0~3，来自下方热源) · `has_food`(bool) |
| **交互流程** | ① 放到热源上方（火塘 / 炉） ② **右键放食材**（可多次） ③ **在时间窗内右键翻炒** ④ **超时 → 焦糊**（惩罚） |
| 配方类型 | **自建** `tfcagricultureplus:wok`，数据驱动，字段：`entries[]{item/tag, min_time, max_time}` + `stir_time` + `overcook_penalty` + `size` |
| ⚠️ 借鉴边界 | **只借"数据驱动烹饪"这个玩法**（§2.8 红线 1）—— **字段名与数值自己定**，不照抄 extradelight |
| 前置 | 阶段 3 的"**数据驱动机器配方类型**"基建（§九 阶段 3.1） |

**两个必须说清的分工**：

| 问题 | 答案 |
|---|---|
| **为什么不直接用 extradelight 的炒锅？** | 用户口径"**只借鉴、不直接使用**"（§2.8）+ 我们要做**系统级重制**（§2.3） |
| **`wok` 与 TFC 的 `pot` 怎么分工？** | `pot` = **煮 / 炖**（**有液体**，无火候）· `wok` = **快炒**（**无液体**，**火候敏感**，超时焦糊）—— 二者互补，不重叠 |


### 6.7 功能域外扩展（原 E1~E8）

| # | 域 | **类型**（§9.1 的四类） | 三方实测 | 覆盖 / 落点 | 状态 |
|---|---|---|---|---|---|
| E1 | **茶** | **③ 补链** | 🆕 **更正：不是"三方 0"** —— A 层**已有 `tea_bush` + `tea_bush_cane`**（占位灌木形态） | **A 层已存在，B 不动它** | ✅ B 只加「茶叶 → 杀青 → 炒制 → 冲泡」（§5.1.1） |
| E2 | **咖啡** | **③ 补链** | 🆕 **同上更正** —— A 层**已有 `coffee_bush` + `coffee_bush_cane`**；Firmalife 有可可但无咖啡 | **A 层已存在，B 不动它** | ✅ B 只加「生豆 → 烘焙 → 研磨 → 冲泡」 |
| E3 | **药草 / 药用 / 驱虫** | **③ 补链** | 🆕 `herb` / `medicine` 三方 0，**但底料 A 层已有**（ginger · turmeric · perilla · garland_chrysanthemum · safflower · agave —— 都在 86 种作物里） | **A 层已存在，B 不动它们** | ✅ B 给这 6 种**加药用 / 驱虫出路**（`docs/74` §10.2-12） |
| E4 | **菌类栽培** | **④ 新增** | `mushroom` 三方 0 | **菌包**（新方块，§6.1） | ✅ 已解禁 |
| E5 | **纤维深加工** | **③ 补链** | 🆕 **A 层已有 5 种纤维作物**（`crop/` + `wild_crop/` + `dead_crop/` **三套齐全**）；TFC 只有 `jute`，Firmalife / AFC 0 | **A 层已存在，B 不动它们** | ✅ B 加「沤麻 → 打麻 → 纤维 → 纺织」（`docs/74` §10.2-27 授权） |
| E6 | **坚果深加工** | **④ 新增** | TFC 只有 `peanut`；**橡子 / 栗子物品 0** | ⭐ **挂树坚果**：**橡子**（挂 TFC `oak`，412 条）+ **栗子**（挂 TFC `chestnut`，434 条）+ A 层已有 4 种（almond · hazelnut · pecan · walnut）+ AFC 的 hardy_chestnut / chinquapin | ✅ 入 B |
| E7 | **hops 酒花** | **③ 补链** | 🆕 **A 层已有 `crop/hops`（三套齐全）**，但**三方都没有任何配方用它** | **A 层已存在，B 不动它** | ✅ B 加「hops → 啤酒」（配合 §13.3-1 麦芽化） |
| E8 | **宠物 / 驯化** | 🆕 **归 C（不归 B）** | 🛑 **更正**：TFC **已有 2 种宠物**（cat / dog，含性别）+ **`livestock/pet/TamableMammal` 驯化机制**（§8.0 实测）—— 旧稿写"TFC 无"是**错的** | **C**：补空缺宠物种类；D 改驯化机制 | ⚠️ **从 B 移出**（宠物属于"畜牧内容"，§〇） |

---

### 6.8 育秧到收获的全流程深化（用户指示）

> 用户指示：**育秧到收获的全流程要进行深化**。本节把"种下去 → 长出来 → 收回来"拆成六个可深化的环节。

| 环节 | 现状 | 深化方向 | 🆕 **实现手段**（v14 补） |
|---|---|---|---|
| ① **留种 / 采种** | 种子由作物掉落表给出 | 分**有性（种子）**与**无性（扦插 / 分株 / 块茎）**两条；无性苗保留母株性状 | **有性**：掉落表（零配方）· **无性**：`crafting` 或 `in_world` 扦插 · ⚠️ "保留母株性状"需要一个**母株标记** ⇒ 用 **DataComponent**（NeoForge 1.21 原生支持，不必 mixin） |
| ② **育苗** | Firmalife 有 6 种种植容器（`quad` / `large` / `hanging` / `hydroponic` / `bonsai` / `trellis`，本模组已填 155 个 plantable）；**本模组 0 自有育苗设施** | **自建育苗盘 / 苗床**：幼苗占位更小、成活率受温湿度影响、可移栽 | **新方块 + BE**（§9.2 **#17**）；温湿度**直接取 §5.6 的温室 / 地窖模型**（不重复实现） |
| ③ **移栽 / 定植** | TFC 直接把种子种在耕地上 | 苗 → 移栽到耕地：校验土壤与气候；**移栽后有缓苗期** | ⭐ **`in_world`**（手持苗右键耕地 ⇒ 落苗 + 校验）· 缓苗期复用 §5.1.1 的 `MySeasonalPlantFix` 经验（⚠️ 别用 TFC 的静态 helper，会静默失效 —— §12.2 红线 2） |
| ④ **生长管理** | TFC 随机刻生长（**无中途操作**） | **5 种农艺操作**：间苗 `thinning` · 培土 `hilling` · **搭架 `staking`（攀爬类）** · 打顶 `topping` · 除草 · 施肥（TFC 有 `compost` + 🆕 **`tfc:fertilizer` 10 个定义**） | ⭐ **`in_world`** 承载 4 种（间苗 / 培土 / 打顶 / 除草）· **搭架 = 新方块**（攀爬作物本来就要支架）· 施肥 = **复用 TFC 的 `compost` / `fertilizer`** |
| ⑤ **收获** | 破坏方块 / 右键（TFC 两种都有） | **主产品 + 次产品一次产出**（§6.2）；**未成熟破坏 → 新鲜草补偿**（§6.3） | ⭐ **`tfc:extra_products`** —— **TFC 已有的机制**（谷物脱粒副产就是它），**零新代码** |
| ⑥ **留种循环** | — | 成熟株可留种 / 扦插 ⇒ **闭环**（防滥用见 §2.6 第 1、4 条） | 掉落表 + ①的无性路径；闭环判据见 §2.6 |

⭐ **一个关键结论**：**②③④ 三个环节全部落在 `in_world` 上**（育苗后的移栽、4 种农艺操作），
⑤ 落在 **TFC 已有的 `extra_products`** 上。⇒ **`in_world` 不是"锦上添花"，而是这条全流程的承重墙**
（这也解释了为什么 §7.2.4 要为它专门设计 5 个载体方块）。

**分阶段交付**：先做 **② 育苗 + ③ 移栽**（价值最高、可独立验证），再做 **④ 农艺操作**，最后收口 ①⑥ 的留种闭环。


### 6.9 液体保质期机制（🆕 v14 第 10 轮：**六轮推演**，取代旧的"建议降级"）

> 用户指示：① **液体腐坏机制一定要慎重考虑实现方式，因为这极其复杂**；② 🆕 **多次推算液体保质期机制的实现方法**。
> 本节 = **反编译实测前提** → **六轮推演（A~F）** → **推荐组合** → **自我修正**。

#### 6.9.1 实测前提（v14 第 10 轮，全部来自反编译 / 盘点）

| # | 事实 | 依据 |
|---|---|---|
| 1 | 🛑 **TFC 没有液体腐坏计时** | 反编译 `MilkBucketItemMixin`：它 `@Inject(finishUsingItem, HEAD)` 后调 **`IPlayerInfo.get(player).eat(FoodData.MILK)`** —— `FoodData.MILK` 是**静态固定值**，**不追踪每个桶的腐坏进度**。它的真实作用只是"让原版牛奶桶走 TFC 的食物系统"（可被配置项 `enableVanillaDrinkingMilkClearsPotionEffects` 关闭） |
| 2 | ⭐ **但 TFC 有 `drinkable` 数据类型（5 个）** | `data/tfc/tfc/drinkable/*.json`：`ingredient`（实测支持 `fluid` **与** `tag`）+ `water`（**可为负**）+ `intoxication` + **`dairy`** + `may_drink_when_full` + `effects[]{effect, amplifier, chance, duration}` ⇒ **这是"液体 → 玩家效果"的现成挂载点** |
| 3 | 🛑 **`_unsealed` 不是"液体腐坏"** | TFC 的 **89 个** `unsealed` 文件**全部在 `assets/tfc/models/{item,block}/jar/`** ⇒ 它是**罐子（jar）未密封状态的模型**，属"**物品保存**"机制，**与液体无关**（旧稿曾把它当液体线索） |
| 4 | **TFC 的腐坏机制全在物品层** | `common/component/food/`：`FoodCapability`（能力）· `FoodTrait` / `FoodTraits`（**数据组件**）· `FoodDefinition` · `FoodData` · `IFood` · `INutritionData`；配方条件 `RottenIngredient` / `NotRottenIngredient`；输出修饰器 `AddTraitModifier` / `RemoveTraitModifier` / `ResetFoodModifier` / `CopyFoodModifier` / `CopyOldestFoodModifier` |
| 5 | **食物数据的真实路径与字段** | `data/tfc/tfc/food/`（**195 个** —— ⚠️ **不是** `data/tfc/food/`，我第一遍就查错了路径）· 字段 `{ingredient, hunger, saturation, decay_modifier, protein, grain, vegetable, fruit, dairy}` |
| 6 | 🆕 **TFC 的 16 种自定义数据类型（全清单）** | `item_heat` 343 · `food` **195** · `deposit` 84 · `fauna` 77 · `item_size` 67 · `fuel` 50 · `climate_range` 49 · **`fluid_heat` 28** · worldgen 21 · `item_damage_resistance` 11 · 🆕 **`fertilizer` 10** · 🆕 **`drinkable` 5** · `knapping_type` 5 · `lamp_fuel` 4 · `entity_damage_resistance` 2 · `support` 1 |
| 7 | **世界中的流体仍不带数据** | `FluidState`（方块状态）只表示"这是什么流体"；而容器内的 `FluidStack` 在 NeoForge 1.21 **支持 DataComponent** |

🆕 **附带发现（与液体无关，但同样重要）**：TFC 有 **`tfc:fertilizer` 数据类型（10 个）** ——
即 **TFC 本身就有肥料定义**，这直接关系 §13.4-1（土壤肥力）与 §6.2（次产品当肥料）。**旧稿完全没提这个数据类型。**

#### 6.9.2 六轮推演

**核心问题**：液体没有"物品腐坏进度"这种天然载体。六条路，逐条推。

| 轮 | 方案 | 做法 | 可行性 | 成本 | 风险 | 裁决 |
|---|---|---|---|---|---|---|
| **A** | **固定两态流体** | 不追踪进度，只做"新鲜 / 腐坏"两种流体（或两个物品），转换靠配方或时间 | ✅ 技术上无难点（纯数据） | 低 | 玩家看得出"一刀切"（第 5 天突然全坏） | 🟡 **备选** |
| **B** | **密封 / 未密封两态**（学 TFC 的 `jar`） | 密封容器里的液体不腐坏，未密封的腐坏 ⇒ **两套物品** | ✅ **有 TFC 现成先例**（`jar` vs `jar_unsealed`，89 个模型）；纯物品层 | 低 | 只管"容器"不管"大桶"；仍是两态 | ✅ **采用（作辅）** |
| **C** | **`FluidStack` DataComponent 带腐坏组件** | 给流体堆加 `creation_tick` 组件，读取时算腐坏 | ⚠️ 组件本身没问题，**但**：① 每次转移（桶→jug→大罐→瓶）都要**显式搬运组件**，**漏一个点就"洗白"** ② 世界中的流体**无法携带** ③ **所有读取端**（TFC 的桶 / 罐 / 管道 / Firmalife 的 `vat`）都要感知它 —— 而我们**改不了邻居的读取端**（除非 mixin） | 🔴 高 | 🔴 高（机制可被玩家绕过） | ❌ **否决** |
| **D** | ⭐ **桶装液体走 TFC 的食物系统**（复刻 `MilkBucketItemMixin` 的思路，但**自建物品**） | **不碰流体**：让"装液体的物品"（瓶 / 桶）成为 **TFC 的 `Food` 物品**（带 `FoodData` + `FoodTrait`）⇒ 直接获得 `decay_modifier` / 腐烂 / `RottenIngredient` / 地窖保鲜 | ✅ **完全复用 TFC 机制**；⭐ **零 mixin**（自建物品，不改 TFC 的类）；⭐ **与 §5.6 的保冷设施天然打通** | **低** | 🟡 只覆盖"装进容器"的液体（散装大桶不算）—— 但这恰好是玩家真正会储存的形态 | ⭐ **采用（主力）** |
| **E** | **给 TFC 的 `barrel` 加腐坏计时** | 覆盖"大容量散装存储" | ❌ 必须 **mixin TFC 的 `BarrelBlockEntity`** —— 收益（只覆盖散装大桶）远低于成本：它是最核心的方块之一、与 TFC 强耦合、邻居一更新就崩。**§12.6.2 的 mixin 名额要留给 P0 项（腐坏推进 / 气候）**；或自建 barrel（与 TFC 正面冲突） | 高 | 高 | ❌ **否决** |
| **F** | **保冷设施（正交方案）** | 不做"腐坏"，做"**延长保质期**"的设施（冰窖 / 地窖），作用于**已有的物品腐坏** | ✅ 零新机制（复用 §5.6 的地窖基建） | 低 | — | ✅ **采用（正交，不冲突）** |

##### 6.9.2.1 为什么 **D 是主力**（三条理由）

1. **它把"液体腐坏"这个难题，转化成了"物品腐坏"这个 TFC 已经解决的问题** ——
   我们**不需要发明任何新机制**，只需要**让液体以物品形态存在**（瓶 / 桶）。
2. **零 mixin**：自建 `Food` 物品即可（TFC 的 `common/items/Food.class` 是**公开类**，可直接继承）。
3. ⭐ **它与"喝下去"是同一个入口**：`drinkable`（前提 2）负责"喝的效果"，
   `Food`（物品腐坏）负责"保质期" —— 两者天然接得上。

##### 6.9.2.2 需要确认的一点（**不许猜**）

`tfc:drinkable` 的 `ingredient` 实测**支持 `fluid` 与 `tag`** —— 🛑 **是否也支持 `item`？**
- 若支持 ⇒ "瓶装果汁"可以直接复用 TFC 的 drinkable（**零代码**）
- 若不支持 ⇒ 要么走**流体**（瓶 → 倒出 → 喝），要么我们**自建 drinkable 等价物**

#### 6.9.3 推荐组合（**D 主力 + B 辅助 + F 正交 + A 可选**）

| 层 | 做什么 | 机制 | 代码量 |
|---|---|---|---|
| **① 主力** | **瓶装 / 桶装液体 = TFC 食物物品** | `Food` + `FoodData` + `decay_modifier` | 低（数据 + 少量物品注册） |
| **② 辅助** | **密封 / 未密封两态**（学 TFC `jar`） | 两套物品 + 一条"密封"配方 | 低 |
| **③ 正交** | **保冷设施**（冰窖 / 地窖）延长保质期 | §5.6 的地窖基建 | 中（已在计划内） |
| **④ 可选** | **腐坏液体喝了有负面效果** | `tfc:drinkable` 的 `effects[]`（实测有 `{effect, amplifier, chance, duration}`） | **0**（纯数据） |
| ❌ **不做** | 世界流体携带腐坏 · 大桶腐坏计时 · 全覆盖的 `FluidStack` 组件 | 见 C / E 的否决理由 | — |

🛑 **一句话结论**：

> **"液体保质期"不做在流体上，做在"装液体的物品"上** ——
> 即"**液体以物品形态储存时会腐坏**"，而不是"世界里的液体本身会腐坏"。
> 这既满足了玩法诉求（果汁会坏、要尽快喝、要冷藏），又把实现成本从"🔴 极高"降到"🟡 低"。

#### 6.9.4 与旧稿的差异（自我修正）

| 旧稿 | 本轮 | 依据 |
|---|---|---|
| "⚠️ 高复杂度 · 需慎重 · **建议降级**" | ✅ **可以做成，且不需要降级** —— 走 **D 方案** | 反编译证实 TFC 的物品腐坏体系**可以被自建物品直接复用** |
| 把 `_unsealed` 当作液体腐坏的线索 | 🛑 那是**罐子模型**（89 个全在 `assets/`） | 前提 3 |
| 没提 `drinkable` 数据类型 | ⭐ 它是**液体 → 效果**的现成挂载点（5 个定义） | 前提 2 |
| 没提 `fertilizer` 数据类型 | 🆕 TFC **有肥料定义（10 个）** ⇒ §13.4-1 可以直接复用 | 前提 6 |
| §12.3 写"液体腐坏**技术上并非不可行**" | 更准确：**在流体上不可行，在物品上可行** | 六轮推演 |

## 七、灵感来源库（服务 A / B / C / D 全部）

> 用户指示：**参考模组也是"完全重置"的灵感来源 —— 学习它们的内容，形成自己的计划。**
> 下表逐个拆开：**它贡献什么灵感 → 我们自建什么 → 归哪层**。
> 🛑 **参考源列里的协议徽章是硬约束（见 §2.8）**：`🛑ARR` / `🛑GPL` 的参考源
> **只能借鉴玩法与设计，不得拷贝任何文件**（代码 / 贴图 / 数据 / 文本 / 命名）；`✅MIT` 可学实现细节但须注明来源。

### 7.0 ⚡ 结论速查（**只想知道"学到了什么"就读这一节**）

> §7.2 有 **237 行**（woodwork 逐项分析），是为"动手时查"写的。**只要结论的话看这张表。**

| 参考源 | 协议 | **一句话结论** | 详情 |
|---|---|---|---|
| **tfcwoodwork** | ✅ **MIT** | ⭐ **`in_world` 世界内加工** —— B 层最缺的机制；⭐ **零 mixin 即可实现**（挂 NeoForge `RightClickBlock`）；🛑 但 `inputState` 只能枚举**完整方块状态** ⇒ 只能加工**专用载体方块**（状态数 ≤8），**不能直接加工作物** | §7.2 · §7.2.4 · §7.2.5 |
| **untamedwilds** | 🛑 **GPL** | ⭐ **"按属分组 + 亚种换皮"** = 225 物种的低成本做法；🛑 **不是"给空世界填动物"** —— TFC 自己已有 **~90 种** | §7.3 · §8.0 |
| **firmalifehardcore** | 邻居 | ⭐ **温室 / 地窖 / 灌溉的现成范式**（8 个 mixin · `"required": true`）；⚠️ **它已安装 ⇒ 与 B 的目标冲突，须条件让位** | §5.6 · §12.6.4 |
| **extradelight** | 见其许可 | 10 类设备形态 + **数据驱动烹饪**（`entries[]` + 时间窗 / 翻炒 / 惩罚）；❌ `crate` 是 TFC 已有的，**不新增** | §5.4 |
| **DragN 系列 · Aquaculture 2** | 🛑 **ARR** | ⚠️ **只借鉴玩法**（禁止拷贝任何文件 / 数据 / 文本 / 命名） | §2.8 |
| **TFC · Firmalife · afc** | 邻居 | 基线见 §三；⚠️ **机械与动力是 TFC 本体的，不动**；AFC 只加树种材质（rotation 类 = **0**） | §三 · §3.3 |

🛑 **三条最容易踩的**：

1. **协议**：ARR（DragN / Aquaculture）与 **GPL（untamedwilds）** 只能借"玩法 / 设计" ——
   后者**还禁止拷贝代码**（GPL 传染性会让我们的模组被迫 GPL 化）
2. **别重复造**：`crate` · `stomping`（踩踏）· `loom`（织机）· 榨油 · **肥料（`tfc:fertilizer` 10 个）**
   —— **TFC 与 Firmalife 都已经有了**（§7.2.2 · §6.9.1 · §13.3）
3. **别把生态模组当畜牧模组**：untamedwilds 的价值在**密度与分布**，不在产出（§7.3.1）

### 7.1 参考源总表

| 参考源 | 规模（实测） | 贡献的灵感 | 我们自建什么 | 归属 |
|---|---|---|---|---|
| **TFC 4.2.11** | 62.3 MB / 20 类配方 | 基础加工范式（`barrel_sealed` 发酵 / `pot` 煮 / `quern` 磨 / 动态标签汤·沙拉）· 8 种酒 · 凝乳制酪 · 制碱鞣革 · 16 色染料 · **堆肥三档标签**（`compost_browns` / `compost_greens` / `compost_poisons`） | 食物的**营养 / 腐烂**与**烹饪体系**系统级重制（A 先借标签过渡） | A + B |
| **Firmalife 3.0.14** | 6,359 条目 / 23 类配方 | **设备矩阵**（`vat`/`oven`/`drying_mat`/`mixing_bowl`/`centrifuge`/`jarring_station`）· **温室** · **灌溉** · 养蜂（**保留**）· 7 奶酪轮 · 葡萄酒 · 可可·面食·豆制品·香料 | 设备与系统**全部系统级重制**（温室 / 灌溉等新参考模组）；**养蜂不覆盖** | B |
| **AFC 2.1.3** | 11,539 条目 / 60 树种 | **树液采集**（温度 + `spring_only` + `requires_natural_log`）· 大量树种与木材 · 给 TFC 机械加树种材质 | 树液 / 糖浆 / 橡胶**系统级重制**；⛔ **机械与动力是 TFC 本体的，不动** | B |
| **firmalifehardcore 0.3.4**（**已安装**） | 401 条目 / 51 class | ⭐ **地窖系统**（`CellarDetector`/`CellarSpace`/`CellarTracker`/`CellarSavedData`/`CellarAttachment`）· **加固土 + 梁**（8 土纲）· **热传导与温度**（`ThermalConductivity`）· 用 mixin 改造 Firmalife 的保鲜容器（`FoodShelf` / `Hanger` / `LargeVessel`）与灌溉（`PumpingStation` / `Sprinkler`）· 温室硬核化（自然光 / 上方空气 / 脱水 / 氧化铜清理） | **温室与地窖的系统级重制参考**（§5.6） | B |
| **extradelight 1.1.5** | 11,919 条目 / 26 类配方 | **设备形态**（`juicer`/`evaporator`/`chiller`/`melting_pot`/`mortar_stone`/`dough_shaping`/**`wok`**/`feast`/模具 / 香料架）· **三层桥接范式** · **动态食物**（按工序推算营养）· **调味料三套方案** | 设备形态 + 数据驱动烹饪配置 + 动态食物机制（§5.4 / §6.6） | B |
| ✅ **tfcwoodwork 1.2.4** | **1,091** 文件（+130 目录 = 1,221 jar 条目）/ 53 class · **281** 自研配方 + **182** 条覆盖 TFC | ⭐⭐ **`tfcwoodwork:in_world` —— 一个全新的"世界内加工"配方类型**（`inputState` + `requiredTool` + `resultItems[]`（4 种投放动作）+ `resultState` + `sound`）· **树皮 / 韧皮纤维 / 锯末**三种木材副产物 · **11 条标签覆盖即完成接入**（`compost_browns/low` ← 锯末、`firepit_fuel` ← 树皮/韧皮）· 配方覆盖范式 | 见 **§7.2**（本项目 B 层最缺的一块拼图） | B |
| 🛑GPL **untamedwilds 4.0.4** | 2,230 条目 / **225 个物种实体**（199 个带亚种后缀）· 20+ 属 | ⭐ **"如何把世界的野生动物铺满"** —— 按属分组 + 每属 2~12 亚种（犀牛 7 · 熊 10 · 大猫 12 · 鲨鱼 11 · 蛇 20+ · 蝴蝶 20+）· 真实学名副标题 · 灭绝动物与现存并存 | 见 **§7.3**（C 的野生动物部分按此重定位） | C |
| 🛑ARR **DragN 牲畜** | 5,556 条目 / 551 物品键 / 45 实体键 | 品种 + **色变分组设计**（16 色 × N 款 = 320 项）· 家畜副产品矩阵 | 4~6 品种 + 16 色装饰（**不做载具**） | C |
| **屠宰系统** | 2,072 + 1,067 条目 | **尸体方块 3×3×3** + 挂肉钩五阶（放血→剥皮→去肢→去内脏→分割）· 部位细分 | 自建简化三阶（肉 / 皮 / 骨 / 脂） | C（+ D） |
| 🛑ARR **水产 Aquaculture 2** | 867 + 637 条目 / 32 实体 | **整鱼 vs 鱼片**两级产物 · 渔具（6 钓竿 / 14 鱼钩 / 鱼饵）· 41 个群系修饰 | ⚠️ **更正（§8.0）**：TFC **已有 22 种鱼 + 11 种水生** ⇒ C **不重复加鱼**（≤3 种），主做**水产加工链 + 渔具** | C |
| **海岸食物** | 1,018 + 153 条目 | **捕蟹笼**（3×3 水体 + 4000~8000 tick + 鱼饵槽）· 贝类分档 | 1 笼 + 3~4 种贝类 | C |
| **鸟类 fowlplay** | 785 条目 / 13 鸟 / **0 自定义方块** | **群系「可选引用」写法**（引用不到自动跳过）· 五类标签体系 · 稻草人 | 4~6 种鸟 + 稻草人 | C |
| **炒锅** | 338 条目 | **数据驱动烹饪**（`entries[]` + 时间窗 / 翻炒 / 惩罚 + 转换配置） | `wok` + 香料架 + 大餐方块（§6.6） | B |

### 7.2 ✅ tfcwoodwork 的逐项分析（**MIT ⇒ 可学实现细节**，用户点名要求纳入 B 层）

**实测规模**：**1,091 个文件**（jar 条目 1,221，其中 **130 个是目录条目** —— 🛑 见下方口径警示）
· **53 个 class**（顶层 39 + 内部 14）· **281 条自研配方**（`in_world` **240** + `crafting` **41**）
· **182 条覆盖 TFC 配方**（`crafting` **180** + `pot` 1 + `heating` 1）
· 标签覆盖 **11 条**（`data/tfc/tags` **7** + `data/minecraft/tags` **1** + `data/c/tags` **3**）
· **107 条** `data/tfcwoodwork/tfc/**`（TFC 数据类型：`fuel` **100** + `item_size` 4 + `food` 3）。

> 🛑 **口径警示（本轮实测踩到，与 §14.3 的"配方两个口径"同类）**：
> jar 的 `Entries` **包含目录条目**（本模组 1,221 条目里有 **130 个是目录**）。
> 用 `$z.Entries | Where-Object { $_.FullName -like "data/x/recipe/*" }` 统计会**把目录算成配方**，
> 每一层目录多算 1。⇒ **凡是统计文件数，必须先 `-not $_.FullName.EndsWith("/")`**。
> 本文档 v14 初稿的 `302 / 194 / 257 / 111 / 44 类` 五个数字**全部因此偏高**，已按文件口径重算并更正。

#### 7.2.1 ⭐ 它最值钱的东西：`in_world` —— "在世界里加工"的配方类型

它把"**拿着工具对着世界里的某个方块右键**"做成了一套**数据驱动的配方类型**（不是硬编码）：

```jsonc
// data/tfcwoodwork/recipe/in_world/axe/chop_log/oak.json（实测原文，节选）
{
  "type": "tfcwoodwork:in_world",
  "inputState":   { "block": "tfcwoodwork:debarked_log/oak" },   // 世界里必须是这个方块
  "requiredTool": "axe",                                          // 需要什么工具类别
  "resultItems": [ {                                              // 产物怎么出来（4 种投放动作）
      "action": "shoot_as_block",                                 //   当方块射出去
      "itemStack": { "count": 1, "id": "tfcwoodwork:debarked_half/oak" } } ],
  "resultState":  { "Name": "minecraft:air" },                    // 原方块变成什么
  "sound":        { "sound": { "sound_id": "tfcwoodwork:wood_chop" }, "volume": 0.6, "pitch": 1.0 }
}
```

**4 种投放动作**（从它的 lang 键实测）：`drop_above`（落到上方）· `drop_cardinal`（向四向抛出）·
`drop_center`（落在原地）· `shoot_as_block`（**当作方块实体射出去**，配 `LogHalfProjectile` / `LogQuarterProjectile` 两个实体）。
配套类：`InWorldRecipe` · `InWorldRecipeHandler` · `InWorldRecipeInput` · `Tool` · `Action`(5 个内部变体) ·
`BlockStatePredicate` · `SoundInstance` · `ModRecipeTypes` / `ModRecipeSerializers`。

#### 7.2.1.1 这 240 条配方实际做了什么（**12 类工序 × 20 种树**，实测分组）

| 工序（各 20 条） | 输入 → 输出 | 对我们的启示 |
|---|---|---|
| `debark_log` / `debark_wood` | 原木 / 木材 → **剥皮** | 一个动作改变世界方块的形态 |
| `chop_log` / `chop_log_half` | 原木 → 半木 → 四分之一木（**两级递进**，产物以实体射出） | ⭐ **同一方块可以连续加工** ⇒ 我们"脱粒 → 扬场"这类两级工序**有先例** |
| `strip_log` / `strip_wood` | 去皮（同时产出 `bast` 韧皮纤维） | ⭐ **主产品 + 次产品同时产出**的现成先例（正是 §6.2 要的） |
| `lumber` / `slab` / `stairs` / `trapdoor` / `log_fence` / `support` | 原木 → **6 种建筑构件** | ⭐⭐ **`in_world` 不止处理原料，它能直接产出成品** —— 这打开了"**在田间现场加工**"的设计空间（例：地里直接编草席 / 扎篱笆 / 搭支架） |

🛑 **最后一行是最容易被忽略、但对我们最有价值的一条**：农场里的"**就地取材、就地加工**"
（编草绳、扎稻草人、搭豆架、压榨、脱粒）本来全都只能回工作台做 —— `in_world` 证明这条路走得通。

🛑 **为什么这是我们 B 层最缺的一块拼图**：§6.8（育秧到收获）与 §6.7（纤维深化）里那一串
**"在世界上发生"的工序** —— **沤麻（retting，麻秆泡水数日）· 脱粒 · 晒干 · 碾米 · 剥壳 · 压榨**——
全都是"对着世界里的方块 + 工具"的操作。TFC 的 24 类配方（§3.1）**没有一类覆盖它**；
Firmalife 也没有。**没有 `in_world` 这一层，这些工序只能退化成"合成台配方"（玩家感受不到"在田里干活"）。**

✅ **MIT 协议 ⇒ 我们可以学它的数据组织方式与接口设计**（`inputState` / `requiredTool` / `resultItems[]` / `resultState` / `sound`
这套 schema 的**字段切分**是设计成果）。⚠️ 仍须**自己实现**（保持我们的代码风格与命名）、**注明来源**。

#### 7.2.2 我们从这个模组纳入 B 层的清单（逐项）

| # | woodwork 的项 | 我们怎么用 | 归 B 的哪节 | 优先级 |
|---|---|---|---|---|
| 1 | **`in_world` 配方类型** | ⭐ **自建一个等价的"世界内加工"配方类型**，承载沤麻 / 脱粒 / 晒干 / 碾米 / 剥壳 / 压榨（⚠️ 踩踏**不用自建**：Firmalife 已有 `stomping` 4 条） | §6.8 · §6.7-E4 | **P0** |
| 2 | **`requiredTool` 工具门控** | 用刀切、用斧劈、用槌砸 —— **同一方块不同工具不同产物**（这正好是"主产品/次产品"的分叉点） | §6.2 | P1 |
| 3 | **4 种投放动作** | `drop_center` 用于"原地留下"（如脱粒后留下秸秆）· `shoot_as_block` 用于"劈开的半边木料"（我们可用在"劈开的瓜"） | §6.2 | P2 |
| 4 | **韧皮纤维 `bast/<tree>`（20 种）** | ⭐ **直接对应 E4 纤维深化**（亚麻/大麻/苎麻/剑麻）—— "从韧皮部取纤维"的现成范式与工序编排 | §6.7-E4 | **P0** |
| 5 | **树皮 → 燃料 / 单宁** | TFC 已有 `tannin`（鞣革）与燃料体系；我们给**作物废料（秸秆 / 藤蔓 / 叶）**同等的燃料定义（`tfc:fuel` 数据类型，见下） | §6.2 | P1 |
| 6 | **锯末 → `tfc:compost_browns/low`** | ⭐ **实测证据**：往 TFC 的堆肥标签里加一个物品 = **零配方接入**。我们 86 种作物的次产品照此办理 | §4.1 · §6.2 | **P0** |
| 7 | **`tfc:fuel` 数据类型（该模组共 **100** 条 fuel 定义；`data/tfcwoodwork/tfc/**` 合计 107 条）** | ⭐ **不写代码就能给物品加燃料属性**：`{ingredient, duration, temperature, purity}`（实测 `bark/birch` = 700 tick / 109 °C / 0.25）。我方秸秆、藤蔓、干叶照抄这个格式 | §6.2 | **P0** |
| 8 | **182 条覆盖 TFC 配方的范式** | ⭐ **实测证据**：外部模组可以覆盖 TFC 的 `data/tfc/recipe/**`（它覆盖了 20 种树的栅栏配方）⇒ §5.5 的覆盖台账有先例 | §5.5 | P1 |
| 9 | **11 条标签覆盖完成整套接入** | ⭐ 与 §4.1「零配方接入」**同一套思路**的独立验证：`firepit_fuel` / `firepit_kindling` / `log_pile_logs` / `charcoal_pit_insulation` / `compost_browns/low` | §4.1 | **P0** |
| 10 | **"掺假食物"（`sawdust_dough` → `sawdust_bread` / `sawdust_soup`）** | 设计范式：**应急口粮**。我方作物次产品可以有一条"饥荒食物"支线（低营养但不为零） | §6.2 | P2 |
| 11 | 原木堆扩展（`LogPileExBlock` / `BurningLogPileExBlock`）+ 3 个投掷实体 | ⚠️ **观察项，不纳入** —— 木材与动力系统不是农业重制的范围（用户口径：动力系统不动） | — | ❌ |

#### 7.2.3 ✅ 两个前置问题**已反编译确认**（v14 第 6 轮，vineflower 1.10.1 实读）

> 方法：`java -jar vineflower-1.10.1.jar -dgs=1 <src> <out>` 反编译 `recipes/inworld/**` + `mixin/**` 共 19 个类。
> 🛑 **注**：`out` 目录**必须不存在或为空** —— 已存在的目录会得到一个空目录树（实测踩过）。

**问题 1：`inputState` 支持方块属性匹配吗？** —— ✅ 支持，但**方式受限**：

```java
// BlockStatePredicate.java 原文
CODEC = RecordCodecBuilder.mapCodec(inst -> inst.group(
      BuiltInRegistries.BLOCK.byNameCodec().fieldOf("block").forGetter(...),
      BlockState.CODEC.listOf().optionalFieldOf("acceptableStates", List.of()).forGetter(...)
   ).apply(inst, BlockStatePredicate::new));

public boolean test(BlockState thatState) {
   if (!thatState.is(this.block)) return false;
   return this.acceptableStates.isEmpty() ? true : this.acceptableStates.contains(thatState);
}
```

⇒ **`acceptableStates` 是「完整 `BlockState` 的枚举清单」**（`BlockState.CODEC` 反序列化出的**带全部属性值**的状态），
**不是「属性 → 值」的局部条件**。`where(Property, value)` 那个 builder 是**代码侧**的辅助（往列表里加
`defaultBlockState().setValue(...)`），JSON 里用不上。

🛑 **这条直接改变了我们的用法**（见 §7.2.4.2）：**不能写"任意 `age≥5`"或"age 属于 {3,4,5}"这种条件式匹配**。

**问题 2：`InWorldRecipeHandler` 挂在哪个事件上？** —— ✅ **NeoForge 公开事件，零 mixin**：

```java
// InWorldRecipeHandler.java 原文（节选）
@EventBusSubscriber(modid = "tfcwoodwork")
public final class InWorldRecipeHandler {
   @SubscribeEvent
   public static void onPlayerRightClickBlock(RightClickBlock event) { ... }
}
```

⚠️ **一个重要的认知更正**：`tfcwoodwork.mixins.json` 里的 `InteractionManagerMixin` **与 `in_world` 配方毫无关系** ——
它只是 `@Inject(method = "registerDefaultInteractions", at = @At("HEAD"))`，
去调用 **TFC 自己的公开 API `InteractionManager.registerBlock(Ingredient, callback)`** 来注册"原木堆"的交互。
⇒ **`in_world` 的实现路径上没有任何 mixin** ✅ —— ⚠️ 但这只是**局部事实**：B 整体**必须**用 mixin（§12.6 修订版），`in_world` 的"不需要"是它的优点，**不是全局策略**。

**处理器完整流程**（反编译原文，9 步）：

| 步 | 动作 | 复用价值 |
|---|---|---|
| 1 | 只处理 `InteractionHand.MAIN_HAND` | ✅ 照用 |
| 2 | `player.getCooldowns().isOnCooldown(item)` ⇒ 拒绝并 `setUseItem(FALSE)` | ✅ 照用 |
| 3 | **`checkFiveDirections(level, pos)`** —— 要求 `Direction.from3DDataValue(1..5)`（**UP + 四水平**）都**没有实心面阻挡** | ⭐ **照用思路**：防止在墙缝/夹层里加工。⚠️ **我们的"沤麻池"（水域）是否通过此检查需实测**（流体不是实心面，理论上通过） |
| 4 | 组 `InWorldRecipeInput(blockState, itemStack)` → `recipeManager.getRecipeFor(IN_WORLD, input, level)` | ✅ 照用（标准 `RecipeType` 查找） |
| 5 | 对每个 `resultItems` 执行 `Action.accept(level, pos, stack, playerDirection)` | ✅ 照用 |
| 6 | `level.setBlockAndUpdate(pos, recipe.resultState())` | ✅ 照用 |
| 7 | **`damageTool`**：`if (RNG.nextDouble() < 400.0 / tier.getUses()) hurtAndBreak(1, …)` | ⚠️ **只借"概率损伤"这个玩法**（§2.8 红线 1）—— **常数 400 是我们的，不是抄的** |
| 8 | **`setCooldownForItems`**：按 **TFC 的 `LevelTier.level()`** 索引配置数组，给该标签下所有工具设冷却 | ⭐ 照用思路（**用 TFC 的等级体系，数值自己定**） |
| 9 | `sound.play` + `player.swing` + `setCancellationResult(sidedSuccess)` + `event.setCanceled(true)` | ✅ 照用（必须取消，否则会同时触发放置/开 GUI） |

**`Action` 的 4 种投放动作（反编译原文语义）**：

| 枚举 | 实现 | 用途 |
|---|---|---|
| `DROP_CENTER` | `spawnDropsPrecise(level, pos, 0.5, 0.5, 0.5, stack, 0, 0, 0)` | **原地落下**（最常用） |
| `DROP_ABOVE` | `…, 0.5, 1.05, 0.5, …` | 落在方块**上方**（不卡进方块里） |
| `DROP_CARDINAL` | 4 次 `spawnDropsPrecise`，四个水平方向各一个 | 劈开的料**朝四向飞散** |
| `SHOOT_AS_BLOCK` | 读方块状态取木材类型 ⇒ 按 `FACING` 算 delta/offset ⇒ **生成投射物实体**（`LogHalfProjectile` / `LogQuarterProjectile`） | "劈开的一半木料**真的被劈飞出去**" |

**`Tool` 枚举（⚠️ 这条限制很关键）**：

```java
public enum Tool implements StringRepresentable {
   AXE("axe", ItemTags.AXES),
   SAW("saw", Items.TOOLS_SAW);     // ← 只有两个值，且写死在枚举里
}
```

⇒ 🛑 **`requiredTool` 不是通用的"工具标签门控"** —— 它**只有 axe / saw 两个硬编码值**。
我们要做「刀切 / 槌砸 / 镰割 / 手摘」时，**必须自己扩展这个枚举，或直接改成标签驱动**（见 §7.2.4.1）。

#### 7.2.4 🛠 我们要自建的 `in_world` 等价物（设计，依据 = §7.2.3 的反编译结论）

##### 7.2.4.1 设计表

| 设计项 | woodwork 的做法 | **我们的做法**（改进点加粗） |
|---|---|---|
| 挂载点 | `@EventBusSubscriber` + `RightClickBlock` | ✅ 照用 —— 该机制**零 mixin**（不是"为了省预算"，而是**它本来就够用**） |
| 配方类型 | `record InWorldRecipe implements Recipe<InWorldRecipeInput>` | ✅ 照用范式（`ModRecipeTypes` + `ModRecipeSerializers` + `MapCodec`/`StreamCodec` 双编解码器） |
| 工具门控 | **枚举写死 2 值**（`AXE`/`SAW`） | 🆕 **改成 `TagKey<Item>` 驱动**（刀 `#c:tools/knife` · 槌 `#c:tools/hammer` · 镰 `#c:tools/scythe` · 手空手）⇒ 可扩展、数据可配 |
| 输入匹配 | `block + acceptableStates`（完整状态枚举） | ⚠️ **见 §7.2.4.2 —— 这是我们与它最大的分歧点** |
| 结果方块 | `resultState`（必填） | ✅ 照用（例：麻秆 → 水；麦捆 → 空） |
| 产物投放 | 4 种 `Action` | ✅ 照用；**我们用 `DROP_CENTER` 为主**（`SHOOT_AS_BLOCK` 需要投射物实体，成本高） |
| 工具损伤 | `p = 400 / tier.getUses()` | ⚠️ **借玩法、不抄数值**（§2.8 红线 1）：概率损伤保留，常数与曲线**自己定**并写进设计文档 |
| 防滥用 | `checkFiveDirections`（UP + 四水平无实心面） | ✅ 照用思路；**沤麻在水里需实测** |
| 冷却 | 按 TFC `LevelTier` 索引数组 | ✅ 照用思路（**用 TFC 等级体系，数值自定**） |
| 多次连续加工 | `log → half → quarter`（两级递进，靠"产物又是下一条配方的输入方块"实现） | ⭐ **照用** —— 这正好是"脱粒 → 扬场"两级工序的现成范式 |

##### 7.2.4.2 🛑 最重要的结论：`in_world` **不能用来直接加工作物方块**

我原先设想"用 `in_world` 对**作物方块**做收获 / 脱粒" —— **反编译后判定不可行**：

| 理由 | 依据 |
|---|---|
| `acceptableStates` 只能**枚举完整状态**，没有属性表达式 | §7.2.3 问题 1 的 `test()` 原文 |
| 我们的**蔓延型作物**有 4 向 `side` 属性 ⇒ `age` 6 × `fruiting` 2 × 16 = **192 个状态** | `MySpreadingCropBlock`（`AGENTS.md` 记录其 blockstate 有四向 `side`） |
| 双段作物 / 莲座 / 浆果丛同样状态爆炸 | §1.4 已实现地基 |

⇒ ✅ **正确用法：`in_world` 加工的是「专用的、状态简单的载体方块」**：

| 载体方块（B 新增） | 状态数 | 承载工序 |
|---|---|---|
| **沤麻池 / 浸渍槽** | 2~3（空 / 有料 / 沤好） | **沤麻（retting）** —— §13.3-5 纤维试点 |
| **脱粒垫 / 打谷场** | 2~3（空 / 铺料 / 打完） | 脱粒 → 扬场（两级递进） |
| **晒架 / 晾晒台** | 2~4 | 晒干（配合 `drying`） |
| **碾磨槽 / 石臼** | 2~3 | 碾米 · 剥壳 |
| **压榨槽** | 2~3 | 油料压榨（§13.3-3，与 TFC 的 `pot`+`barrel` 范式并存） |

⭐ **这同时解释了一个疑问**："为什么 woodwork 用它做原木会成功？" ——
因为 `debarked_log/<tree>` **每棵树只有 1 个状态**，它的输入状态空间天然极小。
**我们照搬它的机制，但要照搬它的"适用场景"判断**，而不是照搬它的"对象选择"。

#### 7.2.5 五个载体方块的**具体设计**（可直接开工）

| # | 载体（ID 候选，前缀 `tfcagricultureplus:`） | blockstate 属性 | 状态数 | 承载工序 | `in_world` 配方 | 贴图 | 依赖 |
|---|---|---|---|---|---|---|---|
| 1 | **沤麻池** `retting_vat` | `filled`(0/1) × `stage`(0 空 / 1 沤制中 / 2 沤好) | **6** | **沤麻（retting）** | 2（放入 / 取出） | 1 方块 + 2 贴图 | §13.3-5 纤维试点 |
| 2 | **脱粒垫** `threshing_mat` | `stage`(0 空 / 1 铺料 / 2 打完) | **3** | **脱粒**（谷捆 → 谷粒 + 秸秆）· 可**两级递进**（脱粒 → 扬场） | 3 | 1 方块 + 3 贴图 | §13.3-1 麦芽化 |
| 3 | **晒架** `drying_rack` | `count`(0~4) | **5** | 晒干（与 Firmalife `drying` **并存**，不替代） | 2 | 1 方块 + 2 贴图 | §5.3.1 #1 |
| 4 | **碾磨槽** `grinding_hollow` | `stage`(0/1/2) | **3** | 碾米 · 剥壳 | 2 | 1 方块 + 2 贴图 | §13.3-2 淀粉提取 |
| 5 | **压榨槽** `press_trough` | `stage`(0/1/2) | **3** | 油料压榨（与 TFC `pot` + `barrel` 范式**并存**） | 2 | 1 方块 + 2 贴图 | §13.3-3 油料扩展 |

**合计**：**5 个方块 · 20 个状态 · 11 条 `in_world` 配方 · 11 张贴图**，
且 ⭐ **全部不需要新 BE**（状态直接存在 blockstate 里 ⇒ 零 `serverTick` 开销，与 §12.4 的性能红线一致）。

**配方 JSON 示例**（按 §7.2.3 反编译出的**真实 schema** 写，字段名与 woodwork 一致）：

```jsonc
// data/tfcagricultureplus/recipe/in_world/retting/put_flax.json
{
  "type": "tfcagricultureplus:in_world",
  "inputState":   { "block": "tfcagricultureplus:retting_vat",
                    "acceptableStates": [ { "Name": "tfcagricultureplus:retting_vat",
                                            "Properties": { "filled": "true", "stage": "0" } } ] },
  "requiredTool": "hand",
  "resultItems": [ { "action": "drop_center",
                     "itemStack": { "count": 1, "id": "tfcagricultureplus:retting_flax" } } ],
  "resultState":  { "Name": "tfcagricultureplus:retting_vat",
                    "Properties": { "filled": "true", "stage": "1" } },
  "sound":        { "sound": { "sound_id": "minecraft:block.bubble_column.bubble_pop" }, "volume": 0.6, "pitch": 1.0 }
}
```

⚠️ **三处与 woodwork 的刻意差异**（§2.8 红线 1：**只借玩法**）：
1. **`requiredTool` 改用 `TagKey<Item>` 驱动**（我们的注册表扩展成 `hand` / `knife` / `mallet` / `scythe` / `axe` / `saw`），
   而不是它那两个硬编码枚举值（§7.2.4.1）；
2. **数值全部自定**（工具损伤概率的常数、冷却数组、沤制所需 tick 数）；
3. **`acceptableStates` 逐条写明完整状态**（这是 §7.2.3 反编译出的**唯一可行写法**）。

**三条设计约束**：

| # | 约束 | 理由 |
|---|---|---|
| 1 | **每个载体的状态数 ≤ 8** | `acceptableStates` 必须**枚举**，状态一多配方就变成一堵墙（§7.2.4.2） |
| 2 | **一律不做 GUI** | `in_world` 的卖点就是"**在世界里直接操作**"；加 GUI 就退化成普通机器了 |
| 3 | **沤麻池可能要放宽 `checkFiveDirections`** | woodwork 要求 UP + 四水平**都无实心面**；沤麻池**泡在水里**，水面不是实心面（理论上通过）⇒ ⚠️ **必须实测确认**，必要时为该方块单独放宽 |


### 7.3 🛑 untamedwilds 的重新定位（**用户澄清：它是"为 TFC 添加野生动物丰富环境"的**）

> **用户口径**：「untamedwilds 是**为 TFC 添加野生动物丰富环境**的」

**实测规模（我此前把它写成"40 实体类 / 170 物品"，低估了一个数量级）**：
2,230 条目 · **225 个物种实体**（`assets/untamedwilds/lang/en_us.json` 里 `entity.untamedwilds.*` 去 `sciname` / `command` 后实测；其中 **199 个带亚种后缀**），分 20+ 个属：

| 类群 | 属与亚种数（实测） |
|---|---|
| 大型陆生 | 河马 · 野牛(2) · **犀牛(7)** · **鬣狗(6)** · 野猪(5) · 骆驼(3) · **熊(10)** · **大猫(12)** · 角马(2) · 土豚 · 负鼠 |
| 水生 | 海牛(5) · 须鲸(6) · **鲨鱼(11)** · 锯鳐(6) · 鲶鱼(5) · 鲹(7) · 翻车鱼(2) · 鲸鲨 · 巨蛤(4) · 帝王蟹(4) · 龙鱼(4) · 鳞鲀(8) · 燕鱼(5) · 鮟鱇 |
| 爬行 | **蛇(20+)** · 大蛇(3) · 巨蜥(7) · 鳖(7) · 陆龟(7) |
| 两栖 | 大鲵(3) · 蝾螈/水螈(10) |
| 昆虫 | **蝴蝶(20+)** · 捕鸟蛛(9) |
| **灭绝动物** | 恐鸟(6) · 披毛犀 · 洞熊 · 盲洞熊 · 泰坦巨蟒 · 袋狮 · 剑齿虎 · 星尾兽 |

#### 7.3.1 旧理解的偏差（自我修正）
- ❌ 旧方案（§八）把它当"**挑 8~12 种做成畜牧产出**"的参考 —— 这是**把生态模组当成了畜牧模组**。
- ✅ 正确定位：**它的价值在"密度与分布"，不在"产出"** —— 目标是让玩家在 TFC 的世界里
  **走得越远看到越多活物**，而不是"多几种肉"。

#### 7.3.2 三条只借"设计"的结论（🛑 GPL ⇒ 代码与资源一律不得拷贝）
| # | 可借鉴的设计 | 我们怎么用 |
|---|---|---|
| 1 | ⭐ **按属分组 + 每属 2~12 个亚种**（犀牛 7 · 熊 10 · 大猫 12 · 鲨鱼 11） | **一个属 = 一套 AI + 一个模型骨架**，亚种只换贴图 / 尺寸 / 少量参数 ⇒ **低成本高丰富度**。这是把"丰富环境"做得起的关键手法 |
| 2 | **真实学名作副标题**（`Hippopotamus amphibius`） | 手册（patchouli）里给每个物种写学名 —— "博物学"质感，成本极低 |
| 3 | **灭绝动物与现存动物并存**（恐鸟 · 披毛犀 · 剑齿虎） | TFC 的世界观本就偏史前（无现代文明）⇒ 少量灭绝物种**契合氛围**，且能复用一个属的骨架 |
| 4 | 观察价值（可命名 / 可喂食 / 可装饰） | 少数动物给"**观赏 / 装饰**"用途（如蝴蝶、鸟），不给肉 —— 不与 TFC 食物平衡打架 |

#### 7.3.3 ⇒ 修正 §8.1 的 C 模块野生动物目标（分三档，按成本选）
| 档 | 规模 | 说明 | 成本 |
|---|---|---|---|
| **P0 最小可行** | **6~8 种 / 3~4 属** | 纯环境，无产出；先验证"亚种换皮"管线跑得通 | 低 |
| **P1 推荐** | **12~16 种 / 5~6 属** | 每属 2~3 亚种；少数可猎（给肉/皮），多数纯环境 | 中 |
| **P2 对标 untamedwilds** | 30+ 种 / 10+ 属 | 需要"每属一套 AI + 亚种只换贴图"的管线完全成熟后才做 | 高 |

⚠️ **我建议先做 P0**（用户口径：**先检查已有和已实现内容，不要太过天马行空**；
且 §9.0-D 的美术工作量估算已把 C 列为"最大人力项"之一）。**上表三档写进 §九 的交由用户选择。**

---


## 八、模组 C / D：动物

### 8.0 🛑 先纠正一个重大误判：**TFC 自己就有 ~90 种动物**

> 实测方法：读 `assets/tfc/lang/en_us.json` 的 `entity.tfc.*` 键 + 统计 jar 内 `common/entities/**` 的类。
> **旧稿假设 TFC 的动物很少、C 要"从零加动物"——这个前提是错的。**

| 类群 | TFC 已有（实测） | 数量 |
|---|---|---|
| **家畜（有性别）** | pig（Pig/**Sow**）· cow（Cow/**Bull**）· goat（Nanny/Billy）· alpaca · sheep（Ewe/Ram）· musk_ox · yak | **7 种 × 2 性别** |
| **家禽（卵生）** | chicken（Rooster/Hen）· duck（Drake/Duck）· quail · peafowl（**Peacock/Peahen**）· turkey · grouse · pheasant | **7 种** |
| **役用 / 载具** | horse（Stallion/Mare）· donkey（Jack/Jenny）· mule · dromedary_camel · bactrian_camel | **5 种** |
| **宠物** | cat（Male/Female）· dog（Male/Female） | **2 种** |
| **鱼类** | bluegill · crappie · lake_trout · largemouth_bass · rainbow_trout · salmon · smallmouth_bass · arctic_char · burbot · muksun · northern_pike · spotted_gudgeon · tilapia · peacock_bass · pacu · red_piranha · cod · pufferfish · tropical_fish … | **22 种** |
| **水生其他** | jellyfish · manatee · **orca** · dolphin · isopod · lobster · crayfish · horseshoe_crab · leopard_seal · squid · octopoteuthis | **11 种** |
| **捕食者** | polar_bear · grizzly_bear · black_bear · cougar · panther · **lion** · **sabertooth** · **tiger** · crocodile · wolf · hyena · **direwolf** | **12 种** |
| **猎物 / 野生** | bison · wildebeest · boar · moose · caribou · deer · gazelle · bongo · panda · fox · ocelot · rabbit · rat · jerboa · lemming · mongoose · armadillo | **17+ 种** |
| **两栖 / 爬行** | frog · turtle | **2 种** |
| **鸟类** | penguin · + 上列家禽中的野生种 | — |

**它的机制也已经成套**（`common/entities/**` 实测包结构：`livestock` **31** 类 · `aquatic` **24** · `prey` **17** · `predator` **5** · `ai` **51** · `misc` **12**）：

| 机制 | TFC 的类 | 说明 |
|---|---|---|
| 动物基座 | `TFCAnimal` · `TFCAnimalProperties` | **可继承的公开基类** |
| 哺乳 | `Mammal` · `MammalProperties` · `Gender` | **性别是内建机制**（不是命名约定） |
| 产出 | `DairyAnimal` · `WoolyAnimal` · `ProducingAnimal` · `ProducingMammal` | 奶 / 毛 / 产出 |
| 卵生 | `OviparousAnimal` + `ai/livestock/OviparousAi` | 蛋生 |
| 繁殖 | `ai/livestock/BreedBehavior` | 独立行为类 |
| 群体捕猎 | `ai/predator/PackLeaderSensor` · `PackPredator` · `PackPredatorAi` | ⭐ **狼群 / 狮群** |
| 行为可配 | `CommonAnimalBehavior` · `CommonAnimalData` · `ConfigurableAnimalBehavior` | 数据驱动行为 |
| 宠物 | `livestock/pet/TamableMammal`（+`Command`） | 驯化 |
| 水生 | `aquatic/AmphibiousAnimal` | 两栖 |
| 野兽 | `prey/WildAnimal` | — |
| 渲染 | `GenderedRenderAnimal` | **按性别换模型** |
| 数据定义 | `data/tfc/tfc/fauna/*.json` —— **77 个文件** | 实测字段只有 `{max_temperature, min_temperature, min_groundwater}` ⇒ **决定"生成在哪"，不含繁殖/成长参数** |

#### 8.0.1 ⇒ 这个发现如何改变 C 与 D 的定位

| 旧稿的定位 | ❌ 问题 | ✅ 修正后的定位 |
|---|---|---|
| C = "**新增**畜牧与水产**内容**"，野生动物 6~8 种 / 鱼 6~8 种 / 鸟 4~6 种 / 家畜 4~6 品种 | 🛑 TFC **已有 22 种鱼 / 7 种家禽 / 17 种野生猎物 / 7 种有性别家畜** —— 再加同类只会**重复** | C = "**补生态位空缺 + 把已有属做厚**"：优先做 TFC **没有**的类型（如大型猫科以外的、灭绝物种、特定气候带的），并用 §7.3 的**亚种换皮**把已有属的数量做上去 |
| D = "畜牧**体系重构**"（暗示从零建） | 🛑 TFC 的体系**已经很完整**（性别 / 哺乳 / 卵生 / 毛 / 奶 / 群体捕猎 / 驯化 / 数据驱动行为） | D = "**重制 TFC 已有的机制**"：改的是**参数与耦合关系**（饲料品质 → 繁殖/产率），不是从零造机制 |

⚠️ **这条修正与 §7.3 的 untamedwilds 结论是一致的**：它那 225 个物种的价值在于
"**按属分组 + 亚种换皮**"，而**不是**"给一个空世界填动物" —— TFC 的世界本来就不空。

### 8.1 模组 C：新增畜牧与水产**内容**

| 类别 | **TFC 现状（实测）** | C 新增内容（**修正后**） | 规模 |
|---|---|---|---|
| **尸体处理** | ⚠️ TFC 只有"**死亡直接掉物品**"（`prey/WildAnimal`），**没有尸体中间态** | ⭐ **这一项才是真空白**（§8.0.1）⇒ **全流程**：死亡位置落 **3×3×3 尸体方块** → 屠刀三阶（**放血 → 剥皮 → 分割**）→ 肉 / 皮 / 骨 / 脂 | 1 套流程 —— **C 的 P0** |
| 野生动物 | **已有 29+ 种**（猎物 17 + 捕食者 12） | ⭐ **补空缺生态位，不做同类重复**：按属分组 + 亚种换皮（§7.3.2），优先 TFC **没有**的类群与气候带 | **6~8 / 12~16 / 30+** 三档（§7.3.3，**待选档**） |
| 水产 | **已有 22 种鱼 + 11 种水生**（含 orca · manatee · lobster · crayfish · horseshoe_crab） | 🛑 **鱼不要重复加** —— 改为做**水产加工链**（整鱼 / 鱼片两级）+ 渔具；TFC 的鱼已经很多，**缺的是"怎么用"** | 加工链为主 · 新鱼 **≤3 种** |
| 鸟类 | **已有 7 种**（chicken · duck · quail · peafowl · turkey · grouse · pheasant）+ penguin | 🛑 **鸟已够多** ⇒ 优先做**稻草人 / 羽毛 / 蛋**这类"周边内容" | 新鸟 **≤2 种** |
| 家畜 | **已有 14 种**（7 有性别 + 5 役用 + 2 宠物） | 🛑 **品种已够** ⇒ 优先做 **16 色装饰 / 畜舍 / 副产品矩阵**（借鉴 DragN 的分组色变设计） | 新家畜 **≤2 种** + 装饰 |
| **养蚕** | 无 | 见 §6.4 | 1 方块 + 3 物品 |

🛑 **修正后的优先级（与旧稿相反）**：
**① 尸体处理链**（真空白，且是 D 的前置）→ **② 补空缺生态位**（§7.3 三档）→ **③ 水产 / 鸟 / 家畜的"周边内容"**（加工链 / 稻草人 / 装饰）。
旧稿把"③ 加新动物"排在最前，是**建立在"TFC 动物很少"这个错误前提上**的。


### 8.2 模组 D：畜牧**体系重构**（重制 TFC **已有**的机制）

> ⚠️ **前提修正（§8.0）**：TFC 的畜牧体系**不是空白** —— 性别（`Gender`）· 哺乳（`Mammal`）·
> 卵生（`OviparousAnimal`）· 产出（`DairyAnimal` / `WoolyAnimal` / `ProducingAnimal`）·
> 繁殖行为（`BreedBehavior`）· 群体捕猎（`PackPredator`）· 驯化（`TamableMammal`）·
> 数据驱动行为（`ConfigurableAnimalBehavior`）**全都已有**。
> ⇒ **D 的任务是把这些机制"重制"（改耦合关系与参数），不是"从零造机制"。**

| 项 | TFC 现状（实测类） | D 重制什么（**改耦合，不改有无**） | 手段 |
|---|---|---|---|
| 繁殖 | `ai/livestock/BreedBehavior` + 固定配对冷却 | 繁殖条件与**饲料品质**挂钩（让 §6.2 次产品 / §6.3 新鲜草有去处） | 继承 `TFCAnimal` 自建 **或** mixin（§12.6 预算内） |
| 成长 | 幼年 → 成年（`MammalProperties`） | **分阶段成长**，饲养影响体型与产率 | 同上 |
| 饲养 | 单一食物标签 | **分层饲料体系**：新鲜草 / 干草 / 谷物 / 加工副产品 | **数据侧优先** |
| 产出 | `DairyAnimal` / `WoolyAnimal` / `ProducingAnimal` 定时产出 | 产出与**饲料 + 年龄 + 季节**挂钩 | 同上 |
| 尸体 | 🛑 **无**（死亡直接掉物品） | 统一尸体体系（§8.1 的 P0 流程） | ⭐ **C 就做掉了**，D 只接 |
| 环境 | `fauna/*.json`（**77 个**，`{max/min_temperature, min_groundwater}`） | 畜舍 / 温湿度（复用 §5.6 的空间检测基建） | **数据侧扩展**（加更多 fauna 定义，零代码） |
| 性别 | `Gender` + `GenderedRenderAnimal` | ✅ **保留**（这是 TFC 的优点，不动） | — |
| 群体捕猎 | `PackLeaderSensor` / `PackPredator` / `PackPredatorAi` | ✅ **保留** | — |

### 8.3 C / D 的技术路线（**基于 §8.0 的实测类结构**）

| 问题 | 答案（依据） |
|---|---|
| **C 的新动物怎么实现？** | ✅ **继承 TFC 的公开基座**：`TFCAnimal` / `Mammal` / `WoolyAnimal` / `DairyAnimal` / `OviparousAnimal` / `WildAnimal` ⇒ **天然融入 TFC 体系**（性别、产出、繁殖、渲染全都有） |
| **新动物的生成条件怎么配？** | ✅ **纯数据**：`data/tfc/tfc/fauna/<species>.json`（77 个的现成格式）—— 字段 `{max_temperature, min_temperature, min_groundwater}` |
| **D 改 TFC 自己的动物（牛 / 羊 / 鸡）怎么办？** | ⚠️ 只能 **mixin**（§12.6 预算总量 ≤5，**D 会用掉其中 2~3 个**）—— **或**继承 + 注册新物种来绕开 |
| **尸体系统要 mixin 吗？** | ✅ **不要** —— 它是**纯新增内容**（C 的方块 + 新 BE + 死亡事件监听），与 TFC 的动物类**零耦合** |
| **C 依赖什么？** | 🆕 ✅ **只依赖 TFC**（用户纠正：**A 不是 C 的依赖**）—— C 是畜牧水产内容，**不需要** A 的 146 种植物；D 只依赖 C |
| **C 的美术量** | ⚠️ 每个物种 = 模型 + 贴图（§7.3.3 的三档决定量级）；**"亚种换皮"是唯一能把成本摊薄的手法** |

> ⚠️ D **重制 TFC 已有的动物机制**，风险最高 ⇒ 必须在 **C 完成之后**单独立项，并遵守 §2.5 的覆盖硬约束。


---

### 9.0 工程结构、开发流程与验证（**落地前提，v12 前完全缺失**）

> 📌 **本节排在 §八 之后、§九 之前是刻意的** —— 它是"落地顺序"的**前提**（先讲前提，再讲顺序）。
> 🆕 v14：本节的 **A 小节（仓库与模块组织）已由 §〇.2 定案**，此处保留作为索引与其余三小节（B/C/D）的正文。

#### 9.0-A 仓库与模块组织（🆕 结论已按子文档 126 修正）

🆕 **2026-09-29 修正（以子文档 [`126-b-module-implementation.md`](126-b-module-implementation.md) §1.2 为准）**：
**不再采用"单仓多模块"，改为「并列双项目 + jar 依赖」** ——
A（`moddev/tfcfarmingplus/`）**一个字节都不动**；B 是独立目录 `moddev/tfcagricultureplus/`，
用 `files(aJar)` 依赖 A 的**构建产物**（与 A 现有的 TFC / Patchouli 依赖方式**同一风格**）。

> **修正理由**：A 刚通过实机验证（474 个方块 · 6460 条目）⇒ 动它的 `settings.gradle` + 目录结构 + 6,418 个资源路径**有回归风险**；
> 而阶段 -1 的目标是「**把 B 隔离出来**」，**不是「把 A 拆开」**。下面这张表保留为**决策记录**。

| 方案 | 结构 | 优点 | 缺点 | 裁决 |
|---|---|---|---|---|
| **甲：单仓多模块** | 现有 `moddev/tfcfarmingplus` 升级为 Gradle 多模块：`:core`（A）· `:remake`（B）· `:livestock`（C）· `:husbandry`（D） | 依赖关系由 Gradle 直接表达（B `implementation project(':core')`）⇒ **不会版本漂移**；一次构建出四个 jar | 需要改造现有工程结构 | ✅ **采用** |
| 乙：四独立工程 | 四个目录各一份 `build.gradle.kts` | 互不干扰、可独立发布 | 依赖 A 的模组要手工同步版本（§〇.2.6 的红线 3 / 6 无法自动强制） | ❌ 否决 |

⚠️ **实施顺序**：**:core（A）与 :remake（B）先拆**（§〇.2.8 的"阶段 -1"）；
`:livestock` / `:husbandry` 到 C / D 立项时再加，**不要一次性改四个模块**。

#### 9.0-B Java 开发规范（本项目硬约束，动手前必读）

| # | 约束 | 出处 |
|---|---|---|
| 1 | 新增**方块族**必须显式接进 `TFCFarmingPlusClient` 渲染层清单 + `MyBlockEntities` 注册（自动化只覆盖已知类别） | `AGENTS.md` §二-6 |
| 2 | 新增**物种必须闭环**：种子 / 树苗 → 可种植 → 可生长 → 可收获 → 产物有用途（缺一环即未完成） | §二-12 |
| 3 | 模型 `rotation.angle` **只允许** `-45 / -22.5 / 0 / 22.5 / 45`（其它值 ⇒ 模型解析失败，却报成 FileNotFoundException） | §二-15 |
| 4 | 从 `src/main/resources` **删除**文件后必须 `gradle clean build`（否则旧副本仍进 jar） | §二-4 |
| 5 | **静态 helper 一律按自己的 BE 类型查表** —— TFC 的静态方法（如 `setStemPos` / `resetPickedTick`）在自建类型上**静默失效** | §二-17 |
| 6 | 外部标识符（方块 ID / 属性名 / 标签）**先查定义再动手**，禁止猜测试错 | §二-19 |

🆕 **7~13：mixin 编码规范（v14 第 14 轮补）** —— 🛑 mixin 已从"最后手段"变成**必选项**（§12.6），
但规范里此前**一条 mixin 规则都没有**。以下 7 条与 §12.6.5 的 6 条硬规则**互补**（那 6 条讲"策略"，这 7 条讲"编码"）：

| # | 规范 | 理由 |
|---|---|---|
| 7 | **mixin 类统一放 `mixin/` 包**，混入配置默认 **`"required": true`**（⚠️ **条件让位组**例外，见 §12.6.4） | 让"目标方法不存在"变成**启动崩溃**而不是静默失效 |
| 8 | **目标方法签名写全**（`"foo(Lnet/minecraft/world/level/Level;)V"`），不用裸方法名 | 重载会歧义 ⇒ 注入到错的那个 |
| 9 | **禁止 `@Overwrite`**；优先 `@Inject(at = HEAD / TAIL)`，慎用 `@Redirect` | 冲突率（§12.6.5 规则 2/3） |
| 10 | **每个 mixin 单独登记进 `OVERRIDE-REGISTRY.md`** | 它**既不在 `assets/` 也不在 `data/`** ⇒ 是覆盖台账最容易漏的一类（§5.5 的 197 文件统计里**不含**它） |
| 11 | 🛑 **mixin 不得指向 A 的类** —— ⚠️ **检查要匹配 `target` 类名，不能 grep 包名** | B 的包名本身含 `tfcfarmingplus`（§2.3 的坑） |
| 12 | **client / server 侧分离**：只改渲染的写进 `"client"` 数组，只改逻辑的写进 `"server"` | 避免在错误侧加载 |
| 13 | **改邻居行为前，先依次问："数据 / 标签行不行？继承 / 自建行不行？NeoForge 事件行不行？"** 三个都不行才 mixin | §12.6.6 的手段优先级 |


#### 9.0-C 每阶段的验证动作（缺一不可）

**① 工具级（每次改动后立刻跑，秒级）**

| 动作 | 工具 | 频率 | 判据 |
|---|---|---|---|
| 资源交叉引用 | `tools/verify.ps1` | 每次改资源后 | 全绿 |
| 几何 / UV / 面类型 | `.probe/texture-design/check-geom.ps1` · `face-axis-audit.ps1` | 每次改模型后 | 无**新增** UVBad / 退化面（已知例外：4 个 `leafball` 立方体模型的 UVBad=6 是**按设计**） |
| 双段接缝 | `seam-audit.ps1` | 每次改双段贴图后 | 全对齐（现状 72/72） |
| **标签审计** | ⏳ **待补脚本** | 每次加标签后 | 每个 `{"replace":false}` 标签**只含自己的条目**、且引用的 ID 都存在 |
| 🆕 **注册一致性审计** | ⏳ **待补脚本**（`verify-registry.ps1`，实现见子文档 §5.2） | **每次新增方块后** | 🛑 每个 `blockstates/**` 里的方块都**在 Java 里注册过** —— 2026-09-29 实机验证抓到 9 个漏注册导致**存档打不开**；`verify.ps1` 查不出这一类 |
| **依赖红线门禁** | ⏳ **待补脚本**（§〇.2.6） | 每次提交前 | **六条全过** |
| 构建 | `gradle build --console=plain` | 每批次 | BUILD SUCCESSFUL |

**② 批次级（每批次收口跑一次）**

| 批次 | 额外验证 | 判据（**缺一不可**） |
|---|---|---|
| **阶段 -1 拆包** | 空 B jar 进游戏 | 日志出现 B 的 mod 名 · 无 `Unable to load` · **A 的 146 物种全部照常** · **卸载 B 后 A 仍完整可用** |
| **阶段 -1 B 接管草莓** | 覆盖链路是否真的生效 | 🛑 **画面里看到的是我们的草莓"作物"（6 龄、同族风格），不是 TFC 的矮灌木** |
| 阶段 1 A 标签接入 | 动态标签是否通 | 游戏内**真的能做出一碗含我们蔬菜的汤**（不是"标签写出了"） |
| 阶段 3 第一台设备 | 设备范式 | 设备可交互 · 配方可跑 · **无每 tick 全量扫描**（§12.4） |
| 阶段 4 L-1 物种批量 | 逐物种形态 | 每 10 个物种抽 1 个进游戏看形态（**必须 `read_image` 实看**） |
| **任意覆盖批次** | **回滚演练** | 删除覆盖目录 ⇒ 邻居恢复原貌（见 §5.5.1） |

**③ 实机验证的硬判据**（沿用 `AGENTS.md` §三，缺一不可）
1. 启动日志出现 `[渲染层自检] 已注册方块 N 个，全部有归属`
2. TagLoader 错误 **0**
3. 本模组归属 ERROR **0**
4. 无 `Unable to load model` / `Missing textures` 指向 `tfcfarmingplus` / `tfcagricultureplus`
5. 🛑 **画面里看到了预期的东西** —— **"日志里没有报错"不算验证**
   （`AGENTS.md` §二-20：本项目曾**三次**据此误报"验证通过"，三次全是假的）

**④ 构建纪律**（`AGENTS.md` §一-3 的实测教训，**违反过一次**）
- 后台构建**必须先确认完成**再启动游戏 —— 曾把 `gradle clean build` 丢后台后立刻启动，
  游戏在 `clean` 已删空 `build/`、重建尚未完成时读到**残缺 jar**，报一片
  `FileNotFoundException: models/block/crop/rosette_age_*.json`，
  而**源文件与最终 jar 都完好** ⇒ 极易误判成模型 bug。
- **判据**：启动前比对 `build/libs/*.jar` 与 `mods/` 下的**大小与时间一致**。

#### 9.0-D 美术工作量估算（**最大的人力项**）

> 🆕 v14：**本表已按 §9.1 施工清单重算**（旧版漏了葡萄棚架 / 8 香料 / 草莓 / 可可，且把灌木写成"7 种"）。

| 项 | 数量（估算） | 依据 |
|---|---|---|
| ① 草莓 + 可可（2 个**覆盖型**物种） | ≈ **16** | §9.1 #1 / #2 |
| ② TFC **29** 种作物（覆盖） | 29 × 6 龄 = **174** | §9.1 #5 |
| ② TFC **11** 种浆果灌木（覆盖） | 11 × 4 状态（活 / 花 / 果 / 枯）= **44** | §9.1 #6 ⚠️ 旧版写"7 种 = 28"是错的 |
| ② 葡萄**棚架**（覆盖，**不是果树**） | **10** 个 blockstate | §9.1 #3 |
| ② Firmalife **8** 种香料植物（接管） | 8 × 2~3 = **~20** | §9.1 #4 |
| ④ 橡子 / 栗子 | **2** | §9.1 #7 |
| 新**设备**（**18 台**） | 3~6 面/台 ⇒ **~70** | §9.2 |
| 新**物品**（~75 项） | **~75** | §9.3 |
| 🆕 **§十五 新品类产物**（12 品类） | **≈ 110** | §十五 |
| 🆕 **§十六 可放置食物**（8 整块 + 腌渍坛 + 挂晒串） | **≈ 25** | §十六 |
| 🆕 **§十七 厨房家具**（🛑 **全材质**） | ⭐ **仅 20~30**（⚠️ **木材/石材贴图复用 TFC 与 afc 的，不新增**） | §17.3 |
| 🆕 **§十四 手持工具 + 动力设备** | **≈ 15** | §14 |
| **B 侧小计** | **≈ 620 张贴图** | — |

🆕 **2026-09-29 材质修订（用户口径：家具要对应 TFC 及附属模组的全部木材和石材）**：

| 项 | 值 |
|---|---|
| **木材种类** | **34**（TFC **20** + afc **14**） |
| **岩石种类** | **21** |
| **木制家具注册项** | **7 类 × 34 = 238** |
| 石制家具注册项（可选） | **4 类 × 21 = 84** |
| ⭐ **但家具的自有贴图只有 20~30 张** | 实测依据：**Firmalife 的 `keg` 专属贴图 = 0 张**（全复用 TFC 木材贴图） |
| **模型 / blockstate 文件** | **≈ 375 个**（⚠️ **用生成器批量产出**，不是手写） |

⇒ 🛑 **结论：注册项从 53 涨到 ≈375，但美术成本只增 20~30 张** ——
**"全材质"不是美术灾难，因为木材/石材贴图可以复用**（这是本次修订最重要的发现）。
| **C 侧**实体模型 + 贴图 | 按 §7.3.3 **三档**：P0 6~8 · P1 12~16 · P2 30+ | §7.3.3（**待用户选档**，§10.1-8） |
| **合计** | **B ≈ 410 张 + C 的实体** | 参照：项目至今共 **2,375** 张 PNG |

> ⚠️ 这张表说明：**B / C 模组的瓶颈是美术，不是代码**。§九 的阶段划分据此把"资源活"与"Java 活"分开。
> ⚠️ 数字是**区间估算**，实际以 **§9.1 / §9.2 / §9.3 的三张清单**为准 —— 那三张才是可逐条核对的。

---
### 9.1 B 层**物种**施工清单（逐条可开工）

🛑 **先分清四类工作**（混在一起排期是旧稿最大的问题）：

| 类型 | 含义 | 是否覆盖邻居资源 | 物种 |
|---|---|---|---|
| **① 覆盖型** | 用户点名，改造**邻居**物种的形态 | ✅ 覆盖 **TFC / Firmalife**（**不是 A**） | 草莓 · 可可 |
| **② 接管型** | 重制邻居的**整套系统** | ✅ 覆盖 TFC / Firmalife | 葡萄（棚架）· 8 香料 · TFC 29 作物 · TFC 11 灌木 |
| **③ 补链型** | **A 层已有**占位物种，只加加工链 | ❌ **不覆盖任何资源**（§5.1.1 定则） | 茶 · 咖啡 · hops · 纤维 5 种 · 桑树 |
| **④ 新增型** | 三方都没有 | ❌ | 橡子 / 栗子 · 药草 · 蘑菇菌包 |

| # | 物种 | 类型 | 实现形态（用哪个现成方块类） | 覆盖对象 / 落点 | 产物 → 去向 | 批次 |
|---|---|---|---|---|---|---|
| 1 | **草莓** | ① | `MyCropBlock`（6 龄，**普通作物**，非灌木） | TFC `plant/strawberry_bush`（**46 条**） | 草莓 → 果酱 / 干燥 / 冰淇淋 | **P0** |
| 2 | **可可** | ① | 第 8 种枝干果实（`MyFruitingBranchBlock`，**注册在 B**，见 §〇.2.7） | Firmalife `plant/cocoa_*`（**58 条**） | 可可豆 → 发酵 → 烘焙 → 研磨 → 巧克力 | **P0** |
| 3 | **红 / 白葡萄** | ② | `MyClimbingCropBlock` + **自建棚架**（⛔ 不用果树管线） | Firmalife 棚架系统（**168 文件 / 9 类 / 10 blockstate / 27 配方**） | 葡萄 → 踩踏（Firmalife 已有 `stomping`）→ 发酵 → 酒；果酱 | P1 |
| 4 | **8 种香料植物** | ② | `MyCropBlock`（若做成田作物）或沿用 `plant/<name>` 形态 | Firmalife `plant/{basil,bay_laurel,cardamom,cilantro,cumin,oregano,pimento,vanilla}` | 香料 → 汤 / 沙拉 / **派**（§6.5） | P1 |
| 5 | **TFC 29 种作物** | ② | 复用 A 的 7 种形状（按物种选） | TFC `crop/<29 个 ID>`（见 §5.1 实测清单） | 不变（几何 + 贴图 + 掉落重制） | P1 |
| 6 | **TFC 11 种浆果灌木** | ② | `MyBerryBushBlock` / `MySpreadingBushBlock` | TFC `plant/<11>_bush`（**草莓除外**，见 #1） | 浆果 → 果酱 / 干燥 | P1 |
| 7 | **橡子 / 栗子** | ④ | 挂到已有树（`oak` / `chestnut`） | **无覆盖对象**（TFC **无** acorn / chestnut 物品） | 橡子 / 栗子 → 磨粉 / 烤食 / **饲料** | P1 |
| 8 | **茶** | ③ | **不动 A 的 `tea_bush`** | B 新增物品与配方 | 茶叶 → 杀青 → 炒制 → 冲泡 | P1 |
| 9 | **咖啡** | ③ | **不动 A 的 `coffee_bush`** | B 新增物品与配方 | 咖啡豆 → 烘焙 → 研磨 → 冲泡 | P1 |
| 10 | **啤酒花** `hops` | ③ | **不动 A 的 `crop/hops`** | B 新增配方 | 啤酒花 → 啤酒（配合 #11） | P1 |
| 11 | **谷物麦芽化** | ③/④ | 不加方块（`barrel` + `drying` 两步） | B 新增物品与配方 | 谷物 → 麦芽 → 麦芽粉 → 糖化 → 啤酒 | P1 |
| 12 | **纤维 5 种**（cotton · flax · hemp · ramie · sisal） | ③ | **不动 A 的 5 种作物** | B 新增 `in_world` **沤麻** + 打麻 + 纺织 | 纤维 → 线 → 布（对齐 Firmalife `loom`） | **P1** |
| 13 | **药草** | ③（**更正：原标 ④**） | **不动 A 层已有的 6 种底料**（ginger · turmeric · perilla · garland_chrysanthemum · safflower · agave，§6.7-E3） | B 新增物品与配方 | 药草 → 药物 / 杀虫剂 | P2 |
| 14 | **蘑菇菌包** | ④ | **新方块**（菌包，非作物） | 无 | 蘑菇（§6.1 解禁项） | P2 |
| 15 | **养蚕**（非物种） | ④ | 1 方块 + 3 物品 | 无 | `fruit_leaf` / **桑叶（A 层已有 `mulberry`）** → 茧 → 丝线 → 丝绸 | P2 |

⚠️ **美术工作量联动**：上表 15 项里 **#5 / #6 是"重制已有物种"（29 + 11 = 40 个物种的完整贴图集）**，
它是 §9.0-D 里"370+ 贴图"的主要来源。**排期时不要把 #5/#6 与"新增 6~8 个物种"当成同一量级。**

### 9.2 B 层**设备**施工清单

| # | 设备 | 是否需要 BE | 配方类型 | 动力接入 | 前置依赖 | 批次 |
|---|---|---|---|---|---|---|
| 1 | **干燥架**（第一台试点） | ✅ | 自建数据驱动 | ❌ 无 | 阶段 3.1/3.2 的配方类型与 BE 基类 | **P0**（试点） |
| 2 | 蒸发浓缩器 | ✅ | 自建 | 🟡 可选（`RotationSinkBlockEntity`） | #1 验证后的范式 | P1 |
| 3 | 面团成型台 | ✅ | 自建 | ❌ | #1 | P1 |
| 4 | 熔化锅 | ✅ | 自建（`pot` 变体） | ❌ | #1 | P1 |
| 5 | 香料架 / 调料柜 | 🟡 可用简单 BE | 无（存储 + 展示） | ❌ | 无 | P1 |
| 6 | **炒锅 `wok`** | ✅ | 自建（`entries[]` + 时间窗 / 翻炒 / 惩罚） | ❌ | #1 | P1 |
| 7 | **熟成架**（§13.3-4） | ✅ | 自建（时间 × 温度 → 品质） | ❌ | §5.6 地窖温度 | P2 |
| 8 | 保冷设施（冰窖，**自建新内容**） | ✅ | — | ❌ | §5.6 | P2 |
| 9 | 油料压榨机（**只做油料批量**） | ✅ | 自建 | 🟡 可选 | #1 | P2 |
| 10 | 研钵 | ❌（可无 BE） | 无（右键交互） | ❌ | 无 | P2 |
| 11 | 大餐方块 `feast` | ✅ | 无（多方块状态） | ❌ | 无 | P2 |
| 12 | 漏斗 / 龙头 | ✅ | — | ❌ | 无 | P3 |
| 13 | **`in_world` 世界内加工** | ❌（配方类型） | **自建**（借鉴 woodwork，§7.2.4 设计已出） | ❌ | ✅ 前置已确认，**可直接开工** | **P1** |
| 14 | 温室 | ✅ | — | ❌ | §5.6 | P1 |
| 15 | 地窖 | ✅ | — | ❌ | §5.6（参考 firmalifehardcore 的 BFS + 缓存） | P1 |
| 16 | 灌溉 | ✅ | — | ✅ **接 TFC 泵**（`FluidPipeBlock` / `PumpBlockEntity`） | §5.6 | P1 |
| 17 | 育秧 / 苗床 | ✅ | — | ❌ | §6.8 | P1 |
| 18 | 养蚕架 | ✅ | 自建（极简） | ❌ | §6.4 | P2 |
| 19 | 菌包 | ✅ | — | ❌ | §6.1 | P2 |
| **合计** | 🆕 **18 台设备 + 1 个 `in_world` 配方类型**（= 表内 **19 行**） | **17 台需 BE**（16 必做 + 1 可选 = 香料架） | 自建 **3 类** | 仅**灌溉**接 TFC 泵 | — | — |

🛑 **18 台设备里 17 台需要 BE**（**16 台必做 + 1 台可选** = 香料架；唯一无需 BE 的是**研钵**） ⇒ **§12.4 的性能红线（禁止每 tick 全量扫描）是排期的硬约束**，
不是"以后优化"。批次设计上必须**先做 #1 把范式定下来**，其余 14 台才允许铺开。

🆕 **不在上表内、但 §5.3.1 要求"重制"的项**（**只覆盖资源与数据、不新增方块** ⇒ 不计入设备数）：

| 项 | 对应 §5.3.1 的链 | 覆盖对象 | 说明 |
|---|---|---|---|
| **烤箱** | **#3 烘焙 / 烤箱** | Firmalife 的 **5 材质烤箱**（含 insulated 变体） | 链 #3 要"重制烤箱系统（材质 / 保温 / 燃料）" ⇒ **覆盖其资源 + 数据即可**。⚠️ 若决定**换成自建方块**，则**必须加进上表**（届时设备数变 **19**） |
| **发酵桶 `vat`** | #2 发酵 | `firmalife:vat`（**53 条**，发酵主力） | 保留两条发酵路径，**只加我们的原料**（麦芽汁 / 果浆 / 茶 / 咖啡） |
| **酒链 / 豆制品** | #8 酒 · #11 豆制品 | Firmalife 的对应链 | 同样**只覆盖数据、不加方块** |

⚠️ **这张小表补齐了一个真实的对应缺口**：§5.3.1 有 **15 条链**，§9.2 只有 **18 台设备** ——
两者**不是一一对应**（有些链靠覆盖资源解决）。**判断标准**：

> **要新方块 ⇒ 进 §9.2 表；只覆盖资源 / 数据 ⇒ 进上面这张小表。**

### 9.3 B 层**物品 / 流体**清单（按功能分组，避免漏项）

| 组 | 内容 | 数量级 | 备注 |
|---|---|---|---|
| **香料** | 8 种原料 + 7 种成品（刀切 / 磨 / 干燥三条工序） | ~15 | §6.5 |
| **茶 / 咖啡** | 鲜叶 · 杀青叶 · 炒制叶 · 茶汤 / 生豆 · 烘焙豆 · 咖啡粉 · 咖啡 | ~10 | **§9.1** #8 / #9 |
| **麦芽 / 酿造** | 麦芽 · 麦芽粉 · 麦汁 · （hops 接入） | ~5 | **§9.1** #11 + §13.3-1 |
| **纤维 / 纺织** | 生麻 · 沤麻 · 纤维 · 线 · 布（对齐 Firmalife `loom`） | ~8 | §13.3-5 |
| **次产品**（横向深化） | 秸秆 · 糠 · 藤 · 叶 · **新鲜草** · 干草 · 饲料 | ~12 | §6.2 / §6.3 / §13.2 |
| **坚果** | 橡子 · 栗子 · 橡子粉 · 栗子粉 | ~4 | **§9.1** #7 |
| **菌类** | 菌包 · 若干蘑菇 | ~5 | §6.1 |
| **养蚕** | 茧 · 丝线 · （丝绸复用 TFC `silk_cloth`） | 3 | §6.4 |
| **熟成 / 保冷** | 熟成产物分档（按 §13.3-4） | ~6 | **§9.2** #7 / #8（熟成架 / 保冷设施） |
| **流体** | 麦汁 · 茶汤 · 咖啡 · 果汁浓缩 · 各类油（**油不用新建，扩 TFC `olive_oil` 范式**） | ~8 | §13.3-3 |
| **合计** | — | **~75 项**（+ 贴图） | 与 **§9.0-D 的"新物品 ~75"** 一致 ✅（各组相加实测 ≈ **76**） |

### 9.4 配套收尾清单（**最容易被漏，且漏了就是半成品**）

| # | 项 | 要求 | 出处 |
|---|---|---|---|
| 1 | **`lang` 中英双语** | A 层是 611 键 × 2 语言 ⇒ B 新增 ~75 物品 + 19 设备 + 15 物种，**两套都要写** | A 层现状 |
| 2 | **创造模式标签页** | B 自建（不复用 A 的，§〇.2.5） | §〇.2.5 |
| 3 | **patchouli 手册** | A 已有 14 个手册覆盖文件；B 的新内容需要**自己的手册条目**（含 §7.3.2 的物种学名写法） | §5.5 |
| 4 | **方块族渲染层登记** | 每个新方块族必须显式接进 `TFCFarmingPlusClient` 的对应清单（自动化只覆盖已知类别） | `AGENTS.md` §二-6 |
| 5 | **BE 类型登记** | B 的新 BE 必须登记 `validBlocks`，否则**放置即崩** | §12.2 红线 1 |
| 6 | **标签审计** | 每批交付前跑一次（§9.0-C 目前唯一缺的工具） | §9.0-C |
| 7 | **覆盖台账登记** | 每个覆盖文件进 `OVERRIDE-REGISTRY.md`（§5.5 的 197 项） | §5.5 |
| 8 | **`gradle clean build`** | 凡删除过 `src/main/resources` 文件，必须 clean build（否则旧副本进 jar） | `AGENTS.md` §二-4 |
| 9 | **依赖红线门禁** | 每批跑 §〇.2.6 的六条检查脚本 | §〇.2.6 |
| 10 | **协议自检** | 每批过 §2.8 的四问表 | §2.8 |

---

## 九、落地顺序

> 🛑 **阶段 -1 是用户点名的最高优先级（§〇.2）** —— 它**先于**下面全部阶段。
> 理由：拆包是"现在做几乎免费、以后做极贵"的事；且 B 的覆盖一旦与 A 混在一个 jar 里，回滚粒度就永久丢失。

```
阶段 -1 🛑 拆包（最高优先级 · §〇.2.8）—— 零玩家可见内容，但决定后面一切能否安全落地
  -1.1 建 B 的 Gradle 子项目（moddev/tfcfarmingplus-expansion/）
  -1.2 六条依赖红线的门禁脚本（§〇.2.6）
  -1.3 **空 B jar 进游戏**：日志出现 B 的 mod 名 · 无 Unable to load · A 的 146 物种全部照常
  -1.4 A 侧新增**唯一**为 B 准备的只读查询类（§〇.2.5）
  -1.5 **B 接管草莓（最小覆盖）** ⇒ 验证"覆盖链路真的生效"+"卸载后恢复原状"
  -1.6 建立 OVERRIDE-REGISTRY.md（原阶段 0.2）并逐条登记

阶段 0  准备（共同）
  0.1 A 的标签追加模板验证 1 次（{"replace":false,...}）
  0.2 复跑 verify.ps1 拿基线（B 的 OVERRIDE-REGISTRY.md 已在 -1.6 建立）
  0.3 ~~工程结构决策~~ ✅ **已由 §〇.2 定案**（两 jar + 四模组依赖方向）
  0.4 **补「标签审计」脚本**（§9.0-C 唯一缺的工具）
  0.5 **美术预算确认**（§9.0-D：370+ 贴图 + 25 实体模型 ⇒ 谁来画、画多久）
  0.6 ~~`in_world` 前置确认~~ ✅ **已完成**（§7.2.3 反编译：挂在 `RightClickBlock` 事件、零 mixin；`inputState` 只能枚举完整状态 ⇒ 必须用专用载体方块）

阶段 1  A · 资源活（**纯数据，可与阶段 2 并行**）
  1.1 蔬菜 / 水生 / 豆 → usable_in_*；果实 → c:foods/fruit + jam
  1.2 染料 → 密封桶染色链（`barrel_sealed`，实测 308 条成熟体系）
  1.3 谷物四件套：先 3 种试点 → 铺开 14（§4.2）
  1.4 逐条配方：Firmalife `drying` 60 果实 + `spice` 8

阶段 2  B · P0 两个点名接管（**资源活，可与阶段 1 并行**）
  2.1 草莓：普通作物形态 → 覆盖 TFC 资源 → 登记 → 核对
  2.2 可可：TrunkFruitBlock 第 8 种 → 覆盖 Firmalife 资源 → 加工链重制
  ⇒ 产出「覆盖作业模板」，供阶段 4 复用

阶段 3  B · **Java 基础设施**（新设备的共同底座，v12 前没排）
  3.1 数据驱动机器配方类型（参考炒锅的 `entries[]` 格式）
  3.2 机器方块实体基类 + 与 TFC 机械（风车 / 水车）的动力接口
  3.3 **第一台设备试点**（干燥架或蒸发器）⇒ 验证范式后再铺开
  🆕 3.4 **mixin 基建**（§12.6）：混入配置 `"required": true` · **条件让位组**（§12.6.4，学 TFC 的 `TFCMixinPlugin`）
       · **每个 mixin 单独登记进 OVERRIDE-REGISTRY.md**（§12.6.5 规则 6）
  🆕 3.5 **P0 的两个 mixin 先行**：① TFC 腐坏推进（`FoodCapability` / `FoodData`）② Firmalife 温室气候
       —— 它们是 **§6.5 调料**与 **§5.6 温室**的前置；**不先做这两个，这两块内容都落不了地**

阶段 4  B · L-1 物种覆盖批量（**②接管型 + ④新增型**，§9.1）
  4.1 ②接管：葡萄（**棚架，不走果树管线**）/ 8 香料 / TFC **29** 作物 / TFC **11** 灌木（⚠️ 原写"7 种"是错的）
  4.2 ④新增：橡子 / 栗子（挂 TFC 已有 oak / chestnut）
  ⚠️ 这是**美术量最大**的一批（29 + 11 = **40 个物种的完整贴图集**），不要与"新增 6~8 个物种"混排

阶段 4.5 B · **③补链型**（**A 层已有物种，只加链条、不碰方块**，§5.1.1 定则）
  4.5.1 茶（E1）· 咖啡（E2）：茶叶/咖啡豆 → 加工链
  4.5.2 hops（E7）+ 谷物麦芽化（§13.3-1）→ 啤酒
  4.5.3 **纤维 5 种**（E5）：`in_world` 沤麻 → 打麻 → 纺织（✅ 前置已确认，见 §7.2.4；**载体 = 沤麻池**）
  4.5.4 药草 6 种（E3）：加药用 / 驱虫出路
  ✅ 这一批**不动世界、不动 A 的资源** ⇒ **零存档风险、零覆盖风险**（§5.5.1）

阶段 5  B · L-2 加工链覆盖（**Java + 数据，逐链单独立项**：干燥 / 发酵 / 烘焙 / 混合 / 离心 / 食物体系 / 果酱 / 奶酪 / 酒 / 可可 / 面食 / 豆制品 / 香料 / 派）

阶段 6  B · L-3 系统级覆盖（**目标级，必须完成**）
  6.1 温室 / 地窖 / 灌溉 —— 参考模组 **firmalifehardcore（已安装）**，见 §5.6
  6.2 树液 / 糖浆 / 橡胶（AFC 式）—— 系统级重制
  （养蜂不在列：❌ 保留 Firmalife；动力系统不动：❌ 只加自动化机器）

阶段 7  B · 新增内容
  7.1 主 / 次产品体系（§6.2）：先做 13 种多用作物，再铺开到全部族
  7.2 菌包培养（§6.1）：1 方块 + 3~5 品种
  7.3 养蚕（§6.4）：1 方块 + 3 物品 + 3~4 配方
  7.4 调料系统（§6.5）：0 营养条目 → 标签 → 改原有汤 / 沙拉 / 派
  7.5 炒锅类设备（§6.6）：`wok` + `spice_rack` + 自动化机器
  7.6 新鲜草（§6.3）：物品 + 掉落表改造 + 干燥配方
  7.7 取汁 / 果汁（§6.1 解禁项）：先纯数据 `BarrelRecipe`
  7.8 功能域外扩展 E1~E8（§6.7）
  7.9 育秧到收获全流程（§6.8）：育苗 + 移栽 → 农艺操作 → 留种闭环
  7.10 ⚠️ 液体腐坏（§6.9）：**默认不做**，改走"保冷设施接进 TFC 物品腐坏"；见 §6.9.4

阶段 8  C 模组：动物内容（野生动物 → 尸体流程 → 水产 → 鸟类 → 家畜 → 养蚕设施）
阶段 9  D 模组：畜牧体系重构（**必须在 C 之后**）
```

---

## 十、开放项与风险

### 10.1 待定

| # | 项 | 状态 |
|---|---|---|
| 1 | **温室 / 地窖 / 灌溉的重制** | ✅ 参考模组已到位：**firmalifehardcore 0.3.4（已安装）** ⇒ ✅ 已细化（§5.6.1 ~ §5.6.5） |
| 2 | 可可加工链 | ✅ 已定：按"完全重制"目标 **连链一起重制**（Firmalife 做法仅作参考） |
| 3 | E8 宠物 / 驯化 | 🆕 **更正（§6.7-E8）**：TFC **已有** 2 种宠物 + `TamableMammal` ⇒ 它属于 **C（畜牧内容）**，**不是 B** |
| 4 | D 模组立项时机 | ⚠️ 建议 **C 完成之后**单独立项（它覆盖 TFC 动物机制，风险最高） |
| 5 | 自动化机器的具体台数 | ⚠️ 待定（原则：**少数几台**，不追求全自动农场） |
| 6 | ~~B 的 mod id~~ | ✅ **已定（用户 2026-09-28）：`tfcagricultureplus`** ⇒ §〇.2.3 |
| 7 | ~~仓库与模块组织~~ | ✅ **已定：单仓多模块，先拆 A / B** ⇒ §〇.2.4 · §9.0-A |
| 8 | 🆕 **C 的野生动物规模** | ⚠️ **待用户选档**：P0（6~8 种 / 3~4 属）· P1（12~16 种 / 5~6 属）· P2（30+ 种）⇒ §7.3.3。**建议 P0 起步** |
| 9 | 🆕 **A 的包名 `com.example.tfcfarmingplus`** | ⚠️ `com.example` 是模板占位域，**对外发布前应改**；本轮不动（改动会让 6,418 资源的引用路径 + 36 个文件 import 全量 diff） |
| 10 | 🆕 **B 的包名与 mod id 不一致** | ⚠️ 已确认**刻意如此**（mod id = `tfcagricultureplus`，包名 = `…tfcfarmingplus.expansion`）；**代码里 `"${NS}:xxx"` 必须用 mod id**（§二-2 陷阱） |
| 11 | ~~`in_world` 的两点前置确认~~ | ✅ **已完成（v14 第 6 轮反编译，§7.2.3）**：挂在 `RightClickBlock`、零 mixin；`inputState` 只能枚举完整状态 ⇒ **必须用专用载体方块**（§7.2.4.2）。**纤维试点已解锁** |
| 12 | 🆕 **熟成架是否立项** | ⚠️ 待定（§13.3-4）：它是"纵向深化"里唯一需要新方块的项，成本中等 |
| 13 | 🆕 **默认不做的两项** | ✅ 已定：**液体腐坏**（§6.9.4 走保冷替代）· **覆盖物 / 地膜**（§13.4-5，TFC 无杂草机制，价值不足） |

### 10.2 风险与坑

> 🆕 v14 第 13 轮：**补「触发条件」与「早期信号」两列** ——
> 风险的应对写在"出事之后"没用；**要在能看出苗头的那一刻就停下来**。

| # | 风险 | **触发条件**（什么时候会发生） | **早期信号**（看到就停） | 对策 |
|---|---|---|---|---|
| 1 | **重复造轮子**（v1~v3 的根本错误） | 新增任何内容**前没查邻居** | 设计文档里出现"我们要做一个 X"，却**没写"邻居有没有 X"** | §2.1 前置检查 |
| 2 | **覆盖与邻居模组冲突** | 邻居更新 / 我们覆盖同名资源 | 启动日志出现 `Unable to load` / 模型缺失 / 注册冲突 | 只覆盖资源与数据，不动代码；每次覆盖后实机核对 |
| 3 | **覆盖清单漏登记** ⇒ 无法回滚 | 手工加文件**没进台账** | `OVERRIDE-REGISTRY.md` 的文件数**与资源树对不上** | 门禁脚本（§〇.2.6） |
| 4 | 违反搁置项 | 顺手实现了 §1.3 里搁置的内容 | — | §1.3 登记表 + 动手前核对 |
| 5 | **标签写 `replace: true`** | 复制粘贴邻居的标签模板 | 🛑 **邻居的原有内容在游戏里消失** | 🛑 **唯一的灾难性写法**（§5.5.2）⇒ 脚本拦截 |
| 6 | 跨版本配方字段（`result.id`） | 参考了**旧版**模组的 JSON | 配方加载报 `Unknown field` | 只用当前版本字段 |
| 7 | 空标签导致配方断链 | 标签值写错 / 引用了不存在的 ID | 配方加载报错 | 标签审计脚本（§9.0-C） |
| 8 | 成品营养逐一手写爆炸 | 给每种新食物手写 `tfc/food/*.json` | 文件数暴涨 | 复用 Firmalife `copy_dynamic_food` |
| 9 | 只做生物不做产物 ⇒ 死内容 | 先做方块 / 实体 | 内容"**能看不能用**" | 先定产物闭环（`AGENTS.md` §二-12） |
| 10 | 群系标签不匹配 ⇒ 内容不生成 | 世界生成标签写错 | **世界里什么都长不出来** | 「可选引用」写法 + 按 TFC 群系标签撒点 |
| 11 | 生成器与 JSON 分叉 | 手改 JSON **没回写生成器** | 重跑生成器后**改动消失** | 回写生成器；跑前查 `$root`；动手前查并发 |
| 12 | 未注册效果 / 物品 | 引用了没注册的 ID | **日志每 tick 刷屏** | 接入前核对注册表 |
| 13 | 状态标记过度乐观 | 用"应该能跑"代替实测 | 文档写"已验证"却**拿不出画面** | 三档：已注册 / 已补资源 / **已游戏内验证** |
| 🆕 14 | **mixin 静默失效** | **邻居更新改了方法签名** | 🛑 **功能无声消失、日志无报错** | `"required": true`（§12.6.5 规则 4）—— 让失败**变成启动崩溃**而不是静默 |
| 🆕 15 | **mixin 与已装模组冲突** | 与 firmalifehardcore **注入同一方法** | 行为叠加 / 偶发崩溃 | **条件让位组**（§12.6.4） |
| 🆕 16 | **空间检测拖垮服务器** | 地窖 / 温室 BFS **无上限** | **TPS 下降 / 卡顿** | 4096 格上限 + `SavedData` 缓存 + 节流（§5.6.5） |
| 🆕 17 | **美术成为瓶颈** | ≈**410 张贴图** + C 的实体模型 | 代码做完了但**没贴图**，内容上不了线 | §9.0-D 预算 + §7.3.3 分档 + **先做通 1 个再铺开** |
| 🆕 18 | **性能结论来自推理而非实测** | 写"这个循环开销可忽略" | 拿不出实测数据 | 🛑 `AGENTS.md` §二-18 的教训：`lastUpdateTick` 曾被"论证为无害"，反汇编后发现**前提不成立** ⇒ **必须实测** |

⚠️ **第 14 / 15 / 18 条是 v14 才出现的**（mixin 从"最后手段"变成"必选项"之后）——
它们都属于"**没有报错但功能不对**"这一类，**比崩溃更难查**。


---

## 十一、基于已有地基的增量建议（取代 v11 的"主动补充"）🆕

> ⚠️ **本版修正**：v11 的 §十一 写得**过于超前** —— 土壤 NPK 模拟、季节播种窗口、水田水位、灾害系统、成就引导……
> 都没有先对照 §1.4 的**已实现地基**。本版重写为：**每项先写"已有地基"→ 再写"最小增量"→ 最后给"成本与建议"**。
> 凡成本高或超出"农业重做"范畴的，直接降级为 ⏸️ 观察项 / ❌ 移除。

🆕 **与 §13.4 的关系（防止两节打架）**：

| | 本节（§十一） | §13.4（系统深化） |
|---|---|---|
| **筛选角度** | "**已有地基**能扩什么" | "**什么算「深化」**" |
| **项数** | **11 项**（+ 6 项显式移除） | **6 项**（3 采纳 / 3 排除） |
| **详细度** | 每项含"已有地基 → 最小增量 → 成本 → 建议"**四列** | 只有方向 |

**两者重叠 3 项，且判定一致**：

| 本节 | §13.4 | 结论 |
|---|---|---|
| #1 土壤肥力 / 轮作 | ~~#1 连作惩罚~~ | 🆕 **两者都作废** —— **TFC 已有完整机制**（`Fertilizer` 数据类型 10 个 + `FarmlandBlockEntity$NutrientType` + `PlantableInfo$PlantNutrients`）；用户口径：「**连作和适播内容已有，不要重复造轮子**」 |
| #2 季节 / 物候 | ~~#2 适播季~~ | 🆕 **两者都作废** —— TFC 已有 `Calendars` + `Month` + 果树的 `Lifecycle` **12 月物候表** |
| #3 水管理 | #4 水分（观察） | ⚠️ 本节判"建议做"、§13.4 判"观察" ⇒ **以本节为准**（本节有 `MyFloodedCropBlock` 的地基证据） |
| — | ~~#3 授粉~~ | ❌ **不做**（用户口径：「**授粉增产无必要，不需要添加**」） |

🛑 **动手时以本节为准**；§13.4 现已**整节作废**（保留为决策记录）。
🆕 **"深化"的新方向见子文档 [`126-b-module-implementation.md`](126-b-module-implementation.md) §十一** ——
从**现实原始农业加工**（40 项清单）+ **extradelight 实测**（19 种配方类型）反推出的 **7 项新增内容**。


| # | 项 | **已有地基**（§1.4） | **最小增量** | 成本 | 建议 |
|---|---|---|---|---|---|
| 1 | **土壤肥力 / 轮作** | TFC 8 土纲 + NPK；我们 86 种作物的表里**已写 `npk='0.6/0.3/0.5'` 字段**；`compost` / `rotten_compost` | 只做「**连作惩罚 + 绿肥还田**」，**不做 NPK 逐元素模拟** | 低~中 | ✅ **建议做**（体感最强、地基现成） |
| 2 | **季节 / 物候** | 已有 `tfc/climate_range` **146** 个 + `MySeasonalPlantFix` + 物候表 | 在现有气候数据里补「**适播季**」字段 + 霜冻判据 | 低 | ✅ 建议做 |
| 3 | **水管理** | **已有 `MyFloodedCropBlock`**，9 种水生作物在用 | 在现有淹水机制上加「**水位 0~2 格**」；**不做**灌溉渠 / 排水 / 水质 | 低~中 | ✅ 建议做（增量小） |
| 4 | **农具** | TFC 有锄 / 刀 / 剪；我们有 `MySeedItem` | 只加「**移栽铲**」一件（配合 §6.8 移栽） | 低 | 🟡 可选 |
| 5 | **农用建筑** | 无（温室 / 地窖见 §5.6） | 谷仓 / 堆肥场 | 中 | ⏸️ 观察项（排在 §5.6 之后） |
| 6 | **灾害** | **`MyDecayingBlock` 已有"腐烂"**；气候数据已有 | 只做「**霜冻**」一种，其余不做 | 低 | 🟡 可选 |
| 7 | **配置与难度开关** | **无** | 「**B 模组逐系统覆盖开关**」（四模组拆分的初衷所需）+ 少量速率开关 | 中 | ✅ **必做**（否则覆盖式重制无法被部分采用） |
| 8 | **成就 / 引导** | 无 | 一条农业线成就 + 手册引导页 | 低 | 🟡 可选 |
| 9 | **手册 / 图鉴** | **已有 Patchouli 手册（784 页）** | 补 146 种图鉴 + 加工链页 + 农艺操作页 | 中 | ✅ 建议做（手册基建已在） |
| 10 | **迁移路径** | 现有 146 种**已进存档**（方块 ID `tfcfarmingplus:crop/*`） | **ID 不变 + A 先做现有内容的超集 + 拆分前 ID 审计** | 低 | ✅ **必做** |
| 11 | **验收判据** | 项目已有「已注册 / 已补资源 / 已游戏内验证」三档惯例 | 每阶段补一条**可玩性判据** | 低 | ✅ **必做** |

**已从 v11 移除的项（天马行空 / 超范围）**

| 移除项 | 原因 |
|---|---|
| ❌ **NPK 精细模拟**（逐元素消耗与补充） | 成本远超收益；TFC 的 NPK 已够用 |
| ❌ **完整季节播种窗口 + 越冬机制** | TFC 已有物候与季节，重做是重复 |
| ❌ **灌溉渠 / 排水 / 水质** | Firmalife 已有灌溉，§5.6 会重制（不与邻居重复） |
| ❌ **病虫害 / 干旱 / 涝害** | 拟真与挫败感难以平衡，且需要全新系统 |
| ❌ **嫁接刀 / 脱粒棒 / 采集篮** | 农具扩张与用户"不过多拓展"的口径冲突 |
| ❌ **苗圃 / 筒仓 / 畜舍（建筑群）** | 等 C / D 模组落地后再评估 |

> **本节的判断标准**：能不能**建立在 §1.4 已有的类与数据上**；不能，就先不做。
## 十二、可行性推演（代码层）🆕 v13

> 本节回答"**方案里的设计在代码上落不落得下来**"。依据 = 邻居模组反汇编 + **本项目已有实现**（含实测崩溃日志）。

### 12.1 ✅ 已证实可行（有公开接口 / 有本项目先例）

| 设计 | 依据 | 结论 |
|---|---|---|
| **设备接入 TFC 动力**（自动化机器、研磨机等） | TFC 有公开的 `util/rotation/Rotation` + `RotationNetwork` + `RotationNetworkManager` + `Node`/`SourceNode`/`SinkNode` + **`RotationSinkBlockEntity`（消费端基类）** | ✅ 继承消费端即可，**不需要重做动力** |
| **流体管道 / 泵**（灌溉） | TFC 本体已有 `FluidPipeBlock` / `FluidPumpBlock` / `PumpBlockEntity` | ✅ 灌溉可建在 TFC 泵上（不必照抄 Firmalife） |
| **自定义配方类型**（数据驱动机器） | TFC 有 **24 种配方类** + **13 种自定义 ingredient**（`AndIngredient` / `HasTraitIngredient` / `NotRottenIngredient` / `HeatIngredient` …） | ✅ 照其范式注册 |
| **复用 TFC 的 BE 类** | 本项目**已解决**：`MyBlockEntities` 用 `CropBlockEntity` 的 **public 类型参数构造器**注册自己的类型；`BerryBushBlockEntity` 的构造器是 protected ⇒ 用 `MyBerryBushBlockEntity` 子类转发 | ✅ 有现成模式（见 12.2 红线 1） |
| **覆盖邻居资源**（草莓 / 可可） | 已有先例：`assets/tfc/models/block/crop/cabbage_age_*.json` 覆盖已生效 | ✅ 资源覆盖可行 |
| **新增物种** | 已有 **6 种作物形状 + 莲座** + 果树四件套；新作物只需**选形状 + 填表** | ✅ 不需要新代码 |
| 🆕 **`in_world` 世界内加工**（§7.2.2 / §7.2.4 / §13.3-5） | ✅ **已反编译证实**（§7.2.3）：MIT 的 tfcwoodwork 在**同一版本**用 **240 条**配方跑通；挂载点是 **NeoForge 公开事件 `RightClickBlock`**（⚠️ **与 `InteractionManagerMixin` 无关**，那个 mixin 只管原木堆）⇒ **零 mixin 即可实现** | ✅ 可行且路径明确；设计见 §7.2.4。⚠️ **限制**：`inputState` 只能枚举完整状态 ⇒ **只能加工"专用载体方块"**，不能直接加工作物方块 |
| 🆕 **次产品"零代码"出口**（§13.2 横向深化） | ✅ **三处独立实证**：① TFC 自带 `compost_browns/{high,medium,low}` + `compost_greens/*`（实测 `compost_greens/high` = `#c:foods/vegetable` + `#c:foods/fruit` + pumpkin + melon）② `tfc:fuel` 数据类型 `{ingredient, duration, temperature, purity}` ③ **tfcwoodwork 只用 11 条标签**就把锯末接进 `compost_browns/low`、把树皮/韧皮接进 `firepit_fuel` | ✅ **纯数据、零代码、零新配方** ⇒ 深化方案里性价比最高的一项 |

### 12.2 🛑 必须在代码上守住的稳定性红线

> 🆕 **与 §9.0-B 的关系（v14 第 21 轮对齐）**：本表 6 条与 **§9.0-B 的规范 1~6 是同一批约束**，
> 只是**视角不同** —— 本表讲"**违反的后果**"（崩溃 / 静默失效 / 不渲染），
> §9.0-B 讲"**怎么做**"（编码规范，且含 **7~13 的 mixin 规范**）。
> 🛑 **动手时以 §9.0-B 为权威版**；本表保留是为了让"稳定性"这一章能自洽。

| # | 红线 | 后果 | 依据 |
|---|---|---|---|
| 1 | **凡沿用 TFC 的 BE 类的新方块，必须在 `MyBlockEntities` 的 `validBlocks` 里登记** | **放置即崩**：`IllegalStateException: Invalid block entity tfc:crop // CropBlockEntity state at BlockPos{...}, got Block{tfcfarmingplus:crop/cauliflower}[age=0]` | 本项目实测崩溃日志（`MyBlockEntities.java` 注释） |
| 2 | **TFC 的静态 helper 在自建 BE 类型上静默失效**（它们按 TFC 自己的类型查表） | 例：`resetPickedTick` 不生效 ⇒ **采收冷却不重置** | 已用 `MySeasonalPlantFix` 的**实例方法**补上 |
| 3 | 新增方块族必须显式接进 `TFCFarmingPlusClient` 渲染层清单 | 客户端不渲染 / 报未注册 | `AGENTS.md` §二-6 |
| 4 | 模型 `rotation.angle` 只允许 `-45/-22.5/0/22.5/45` | 模型解析失败，却被报成 `FileNotFoundException` | §二-15 |
| 5 | 删 `src/main/resources` 文件后必须 `gradle clean build` | 旧副本仍进 jar | §二-4 |
| 6 | 外部标识符（方块 ID / 属性名 / 标签）**先查定义** | `/fill`、`/setblock` 静默失败或崩溃 | §二-19 |

### 12.3 ⚠️ 本轮推翻的技术判断（自我修正）

| 原判断（v10~v12） | 修正 | 影响 |
|---|---|---|
| §6.9.1 写「**流体本身没有 NBT** ⇒ 腐坏状态只能活在容器里」 | **不够准确**：`FluidState`（世界中的流体**方块状态**）确实不带数据；但 **`FluidStack`（容器内的流体堆）在 NeoForge 1.21 支持 DataComponent**，而 TFC 的 `FoodTrait` 恰好是 `common/component/food/` 下的**数据组件** | ⇒ 液体腐坏**技术上并非不可行**，难点转为：① `FoodTrait` 是为 `ItemStack` 设计的，能否复用到 `FluidStack` ② 跨容器转移要保持组件 ③ **世界中流动的液体仍无法携带状态**（只能在容器内腐坏） |
| §7.1 曾写「AFC 的动力传动」 | **AFC 的 rotation 相关 class = 0** —— 它**没有**继承 TFC 的 rotation API，只是给 TFC 机械加**木材材质变体** | 印证用户指正；§3.3 / §5.1 / §7.1 已改 |
| 🆕 §13.3 初稿写「**榨油**是缺口，深化要做榨油」 | **TFC 已经有榨油**：`tfc:olive_oil` / `tfc:canola_oil`，工艺是 `pot/olive_oil_water`（煮）→ `barrel/olive_oil_cooling`（**油水分离**），另有 `tfc/lamp_fuel/{olive_oil,canola_oil}.json` 灯燃料定义 | ⇒ §13.3-3 改为「**油料扩展**」（把同一范式套到花生/芝麻/亚麻籽/向日葵），**不是新建榨油**。教训：**先核 `data/tfc/recipe/**` 再断言"缺口"** |
| 🆕 §13.4 初稿写「覆盖物（地膜）可**抑制杂草**」 | 🛑 **TFC 没有杂草机制**（实测：jar 内 `weed` 的命中全是植物名 —— pickerelweed / milkweed / duckweed / gutweed / seaweed） | ⇒ §13.4-5 直接判 **❌ 不做**：只剩"保湿+保温"价值，与 §5.6 温室重复 |
| 🆕 旧 §七 把 untamedwilds 写成「**40 实体类 / 170 物品**」 | **低估一个数量级**：lang 内 `entity.untamedwilds.*` 实测 **225 个物种实体**（犀牛 7 · 熊 10 · 大猫 12 · 鲨鱼 11 · 蛇 20+ · 蝴蝶 20+，含灭绝动物） | ⇒ §7.3 重写：它是**生态模组**而非畜牧模组，C 的野生动物目标改为"**按属分组 + 亚种换皮**"（§7.3.3 三档） |

**v14 第二轮打磨追加（对**本模组自己**的 6 处误判）：**

| 原判断 | 修正（实测） | 影响 |
|---|---|---|
| §5.1 写「Firmalife 8 种香料植物 ⇒ 接管（**我们已有 8 种香料作物**，整体替换）」 | 🛑 **A 层根本没有香料**：611 个 lang 键 + `MyItems.java` **零命中**；真正有 8 种香料植物的是 **Firmalife**（`plant/{basil,bay_laurel,cardamom,cilantro,cumin,oregano,pimento,vanilla}`） | ⇒ §5.1 更正为"**从零接管**"。教训：**"我们已有"必须实测** —— 不能从"批次 13 ✅香料"这条旧进度记录反推 |
| §5.1 写「TFC **7** 种浆果灌木」 | 实测 `*_bush` blockstate **13 个**，减 2 个枯死态（`dead_berry_bush` / `dead_bush`）⇒ **11 种**；且 **草莓本人就在这 11 种里** | ⇒ §5.1 更正；草莓须从该批单独摘出（①覆盖型），其余 10 种才是②接管型 |
| §5.1 写「红/白葡萄 ⇒ 接管（**挂到果树管线**）」 | 🛑 **葡萄不是果树**：Firmalife 的葡萄是**棚架 + 绳子藤本系统** —— **168 文件 / 9 个类 / 10 blockstate / 27 配方**（`GrapeTrellisPostBlock` · `GrapeStringBlock` · `GrapeTrellisPostWithPlantBlock` · `GrapeGroundPlantOnStringBlock` · `GrapeFluffBlock` · `GrapeStringWithPlantBlock` · `GrapeSeedItem` · `GrapePlantBlockEntity` · `IGrape`） | ⇒ 改为「**`MyClimbingCropBlock` + 自建棚架**」，明确**不走果树管线**（§9.1 #3） |
| §7.2.2 / §13.2 把「**踩踏（葡萄/橄榄）**」列为 `in_world` 要承载的工序 | 🛑 **Firmalife 已经有 `stomping` 配方类型（实测 4 条）**，另还有 **`loom` 织机（1 条）** | ⇒ `in_world` 的承载范围收敛为**沤麻 / 脱粒 / 晒干 / 碾米 / 剥壳 / 压榨**（踩踏复用 Firmalife 的） |
| §6.7-E1 写「茶 `tea` **三方 0**」 | 🛑 **A 层已有 `tea_bush` + `tea_bush_cane`**（占位灌木形态，`docs/74` §10.2-25 其实记录过），**咖啡同理**（`coffee_bush`）；`hops` 与**纤维 5 种**（cotton/flax/hemp/ramie/sisal）也都在 A 层且三套 blockstate 齐全 | ⇒ 新增 **§5.1.1 定则**：**A 层已有物种，B 只加链条、不碰方块** —— 否则会撞 §〇.2.6 红线 2（B 不得覆盖 A 资源），A 就不再能单独发布 |
| **§九** 的排期把"新增物种"与"重制已有物种"混在一起 | 实操上两者差一个数量级：#5/#6 是 **29 + 11 = 40 个物种的完整贴图集** | ⇒ 新增 **§9.1 施工清单**，按 **①覆盖 / ②接管 / ③补链 / ④新增** 四类分开排期 |

**v14 第 6 轮追加（`in_world` 反编译后，4 条）：**

| 原判断 | 修正（**反编译原文**） | 影响 |
|---|---|---|
| §7.2.2 / §13.3-5 设想「用 `in_world` 对**作物方块**做收获 / 脱粒」 | 🛑 **判定不可行**：`BlockStatePredicate.acceptableStates` 只能**枚举完整 `BlockState`**，**没有属性表达式**（`test()` 只有 `is(block)` + `contains(state)` 两步）；我们的**蔓延型作物**有 `age` 6 × `fruiting` 2 × **4 向 `side`（16 组合）= 192 个状态** | ⇒ §7.2.4.2 改为「`in_world` 加工**专用载体方块**」（沤麻池 / 脱粒垫 / 晒架 / 碾磨槽 / 压榨槽）。这同时解释了**为什么 woodwork 选原木做对象**：`debarked_log/<tree>` 每棵树**只有 1 个状态** |
| 旧 §7.2.3 把 `InteractionManagerMixin` 当作 `in_world` 的实现线索（"提示是右键交互"） | 🛑 **两者无关**：该 mixin 只在 `@At("HEAD")` 注入 TFC 的 `registerDefaultInteractions`，用来调用 **TFC 公开 API `InteractionManager.registerBlock(...)`** 注册"原木堆"交互；`in_world` 的**真正处理器**是 `@EventBusSubscriber` + **NeoForge `RightClickBlock` 事件** | ⇒ §7.2.3 更正。**`in_world` 实现路径上零 mixin** ✅（局部事实；B 整体仍须 mixin，见 §12.6 修订版） |
| §7.2.2 表格写「`Action`（**5 个内部变体**）」 | 实测是 **4 个枚举常量**（`DROP_CENTER` / `DROP_ABOVE` / `DROP_CARDINAL` / `SHOOT_AS_BLOCK`）；5 个 class 文件 = 4 个匿名子类 + 1 个枚举本体 | 已按 **4 种**改写 |
| §7.2.2 表格写「`requiredTool` **工具门控**」（暗示通用） | 🛑 **是硬编码枚举，只有 `AXE(ItemTags.AXES)` 与 `SAW(Items.TOOLS_SAW)` 两个值** | ⇒ §7.2.4.1 改为**我们自己用 `TagKey<Item>` 驱动**（刀 / 槌 / 镰 / 空手），否则做不了"刀切""槌砸" |

**v14 第 9 轮追加（动物体系 + 覆盖风险，3 条）：**

| 原判断 | 修正（实测） | 影响 |
|---|---|---|
| §八 通篇假设 **TFC 的动物很少**，C 要"从零加动物"（野生动物 6~8 · 鱼 6~8 · 鸟 4~6 · 家畜 4~6 品种） | 🛑 **TFC 自己就有 ~90 种动物**：**22 种鱼** · 11 种水生（含 orca · manatee · lobster · horseshoe_crab）· **7 种家禽** · 7 种有性别家畜 · 5 种役用 · 2 宠物 · 12 捕食者 · 17+ 猎物 · 2 两栖。机制也成套：`livestock` **31** 类（`TFCAnimal`/`Mammal`/`Gender`/`DairyAnimal`/`WoolyAnimal`/`ProducingAnimal`/`OviparousAnimal`）· `ai` **51** 类（`BreedBehavior`/`PackPredator`）· `fauna/*.json` **77 个**数据定义 | ⇒ **§8.0 整节新增**：C 从"加动物"改为"**补生态位空缺 + 亚种换皮**"；**C 的真空白是"尸体处理链"**（TFC 死亡直接掉物品，无尸体中间态）⇒ 优先级反转（§8.1）。D 从"从零建体系"改为"**重制已有机制**" |
| §5.5 把"整文件标签覆盖"定为 **🔴 高**（"漏抄原有条目就会清空原内容"） | 🛑 **不成立**：我方 **21 个标签文件全部 `replace=false`**（`true` 的有 0 个），邻居同路径文件**也是 `false`**，而 MC 规范里 **`replace` 缺省即 `false`（合并语义）** | ⇒ §5.5.2 把 D 类从 🔴 下调为 **🟡**（真实风险变成"自己的条目没生效"）。**唯一灾难性写法是 `replace: true`** ⇒ 写进 §9.0-C 的标签审计脚本 |
| §5.5 的 197 个文件被笼统称作"**覆盖**" | 实测拆成 **10 组**：其中 **191 个是 A 层的"接入"工作**（155 plantable + 14 手册 + 21 标签 + 1 蜜蜂叶子），**只有 6 个 `cabbage_age_*` 模型是真正的"覆盖"语义** | ⇒ §5.5.2 新增交叉映射表；**B 的覆盖工作量被高估了** —— B 真正的覆盖对象是 §5.3.1 那 15 条链的配方与设备 |
| —（新发现） | 🆕 反编译 `TFCTags$Blocks` 得到**全部**方块标签常量，其中 🛑 **没有 `CROPS`**（TFC 用 `minecraft:crops`）⇒ 我方 `data/tfc/tags/block/crops.json` **可能是死文件**；同时发现 **`tfc:bush_plantable_on` / `tfc:sea_bush_plantable_on` 我方没接** | 两条都记进 §5.5.2 的"A 层问题"表，**待确认后处置** |

**v14 第 10 轮追加（依赖方向 + 液体保质期，4 条）：**

| 原判断 | 修正 | 影响 |
|---|---|---|
| 🛑 **依赖方向 `A ← C ← D`**（全篇） | 🛑 **用户纠正：A 不是 C 的依赖** ⇒ 正确方向是 **`A ← B` · `C` 独立（只依赖 TFC）· `C ← D`** | 已改 **7 处**：§〇 架构表与依赖说明 · §〇.2.3 交付物表 · §〇.2.6 红线 6 · §8.3 · §9.0-A。C 是畜牧水产内容，**与 A 的 146 种植物无关**，本就不该依赖它 |
| §6.9 判"液体腐坏 ⚠️ **极高复杂度 · 建议降级**" | 反编译后结论**反转**：① TFC **没有**液体腐坏计时（`MilkBucketItemMixin` 调的是**静态** `FoodData.MILK`）② ⭐ 但 TFC **有 `drinkable` 数据类型（5 个）**，且**物品腐坏体系可被自建 `Food` 物品直接复用** ⇒ **六轮推演**后定为「**做在"装液体的物品"上，不做在流体上**」 | ⇒ §6.9 **整节重写**为六轮推演（A~F）；结论从"建议降级"变为"**可以做成，成本 🟡 低**"（推荐组合 = D 主力 + B 辅助 + F 正交 + A 可选） |
| 旧稿把 `_unsealed` 当作液体腐坏的线索 | 🛑 TFC 的 **89 个** `unsealed` 文件**全在 `assets/tfc/models/{item,block}/jar/`** ⇒ 那是**罐子（jar）的未密封模型**，属"物品保存"机制，**与液体无关** | §6.9.1 前提 3 |
| 没提 `tfc:fertilizer` 数据类型 | 🆕 TFC 有 **`fertilizer` 数据类型（10 个）** —— **TFC 本身就有肥料定义** | 直接关系 §13.4-1（土壤肥力）与 §6.2（次产品当肥料）：**可以复用，不必自建**。已补进 §6.9.1 前提 6 |

**v14 第 11 轮追加（🛑 mixin 决策反转，1 条但影响全篇）：**

| 原判断 | 修正 | 影响 |
|---|---|---|
| §12.6（v14 第 6 轮）定「**主体阶段 0 mixin · 总量 ≤5**」，理由是"稳定性优先" | 🛑 **用户口径推翻**：「**mixin 是必选项，因为你本来就要动大量已有内容**」。**实测完全支持这一判断**：**TFC 自己用了 75 个 mixin**（`tfc.mixins.json` 声明：`mixins` **51** + `client` **23** + `server` **1**；含 `ItemStackMixin` · `PlayerMixin` · `MobMixin` · `EntityMixin` · `FlowingFluidMixin` · `RecipeManagerMixin` · 20 个 accessor · 7 个动物 accessor · `TFCMixinPlugin`）· **Firmalife 3 个** · **firmalifehardcore 8 个且 mixins.json 写 `"required": true`** | ⇒ **§12.6 整节重写**：新增 **B 的 9 项 mixin 清单**（P0 = TFC 腐坏推进 + Firmalife 温室气候）· **C/D 的 4 项** · 预算改为 **B 8~9 + C/D 4**；新增 **§12.6.4「与已安装模组的 mixin 目标冲突」**（hardcore 已 mixin 同一批类 ⇒ B 需条件让位）；§九 阶段 3 补 **3.4 mixin 基建 / 3.5 P0 两个 mixin 先行**；全篇 7 处"零 mixin"表述已按"局部事实 ≠ 全局策略"改写 |

### 12.4 性能推演（🆕 v14 第 12 轮：**修正 2 处过时 + 补验收判据**）

> ⚠️ **旧版有 3 处过时数字**：设备数写 "~12 台"（§9.2 已定 **18 台设备 + 1 个配方类型**）·
> 液体腐坏写 "🔴 高风险"（§6.9 已改为"**做在物品层**"，**不产生任何容器 tick**）。

| 项 | 量级 | 判断 | 🆕 设计约束 |
|---|---|---|---|
| 作物 BE | 复用 `CropBlockEntity`（TFC 同款，只是注册了自己的类型） | ✅ 与 TFC 原版**同量级** | — |
| 我们自建的 BE | 仅 **2 个**（`MyBerryBushBlockEntity` / `MyDecayingBlockEntity`） | ✅ 极简 | — |
| **新增设备 BE** | **18 台设备，其中 17 台需要 BE**（16 必做 + 1 可选；§9.2） | 🟡 必须避免"**每 tick 全量扫描**" | ① 优先**事件驱动**（方块变化时算，不主动轮询）② **无状态需求的设备不建 BE** —— §7.2.5 的 **5 个 `in_world` 载体全部把状态存在 blockstate 里** ⇒ 零 `serverTick` |
| **温室 / 地窖** | 需要**空间检测** | 🔴 **最大性能风险** | ① BFS + **`SavedData` 缓存**（学 firmalifehardcore）② **BFS ≤ 4096 格**上限（超限判"不是地窖"）③ 只在**空间边界变化**时重算 + **节流**（同区块 N tick 内合并） |
| 温度重算 | 与空间检测同源 | 🟡 | 复用同一套缓存，**不另开一路轮询** |
| 灌溉 | 按需求查询 | 🟡 | 只在**有作物需要水**时查询，**不遍历全田** |
| **液体保质期** | 🆕 **零容器 tick** | ✅ **不再是风险** | §6.9 的 **D 方案**把腐坏做在**物品**上 ⇒ 复用 TFC 的物品腐坏机制（TFC 原本就在跑），**我们不加任何 tick** |
| 与 hardcore 并存 | — | 🟢 | §5.6.1 的**让位机制**避免了双重 tick 开销 |

#### 12.4.1 🆕 每台设备的**性能验收判据**（交付时必须逐条过）

| # | 判据 | 反例（禁止） |
|---|---|---|
| 1 | 设备**空闲时零开销** —— `serverTick` 第一句先判"有没有活" | 每 tick 无条件遍历输入槽 |
| 2 | 用**事件 / 邻居更新**触发，不主动轮询 | `for (BlockPos p : BlockPos.betweenClosed(±10))` |
| 3 | 一切循环有**上限**（BFS 格数 / 缓存条目 / 队列长度） | 无上限的 BFS 或递推 |
| 4 | **实测**：放 100 台设备 + 100 个地窖，**TPS 不掉** | 只看代码不看实测（`AGENTS.md` §二-18：凡"论证为无影响"的，必须真的测一次） |

⚠️ 第 4 条是本项目的实测教训（`AGENTS.md` §二-18）：`lastUpdateTick` 的异常值曾被"论证为无害"，
后来反汇编发现**前提根本不成立**。⇒ **性能结论必须来自实测，不能来自推理。**


### 12.5 存档兼容推演

| 项 | 判断 |
|---|---|
| 拆分四模组时**方块 / 物品 ID 不变** | ✅ 旧存档可直接升级 |
| 新增方块（设备 / 菌包 / 蚕架…） | ✅ 前向兼容（旧存档里不存在即可） |
| **删除 / 改名任何已注册 ID** | ❌ **绝对禁止** —— 旧存档里的方块会丢失 |
| 数据包结构变化（配方 / 标签） | ✅ 数据包不进存档，随资源更新 |
| 覆盖邻居资源 | ✅ 不写存档，随时可回滚 |
| **D 模组覆盖 TFC 动物机制** | 🔴 动物状态**进存档** ⇒ 改机制必须考虑旧存档里已有动物的兼容（D 放最后的又一理由） |

---
### 12.6 🆕 Mixin 策略（🛑 **修订：mixin 是必选项**，v14 第 11 轮按用户口径改）

> 🛑 **用户口径（2026-09-28）**：「**mixin 是必选项，因为你本来就要动大量已有内容**」
> ⇒ 本节 v14 第 6 轮写的"**主体阶段 0 mixin / 总量 ≤5**"**作废**。
> 真实预算由"**要动多少已有内容**"决定，**不由"求稳"决定**。

#### 12.6.1 实测证据：三层邻居**都在大规模用 mixin**

| 模组 | mixin 数 | 说明 |
|---|---|---|
| **TFC** | **75 个**（`tfc.mixins.json` 声明：`mixins` **51** + `client` **23** + `server` **1**；class 文件 **76** = 75 顶层 + 1 内部类 `MobMixin$1`） | 含 **20 个 accessor**（`BiomeAccessor` · `BlockBehaviourAccessor` · `ChunkAccessAccessor` · **`FlowingFluidAccessor`** · **`PatchedDataComponentMapAccessor`** · `RecipeManagerAccessor` …）· 核心类 mixin（**`ItemStackMixin`** · **`PlayerMixin`** · **`MobMixin`** · `EntityMixin` · `LevelMixin` · `ServerLevelMixin` · `RecipeManagerMixin` · **`FlowingFluidMixin`** · `WaterMixin` · `LavaMixin` · `FishingHookMixin` · `SnowLayerBlockMixin` · `VineBlockMixin` · `TagLoaderMixin` · `SpawnPlacementsMixin` · `MilkBucketItemMixin` …）· **7 个动物 accessor**（`CamelAccessor` · `HorseAccessor` · `OcelotAccessor` · `AbstractSkeletonMixin` · `TadpoleMixin` · `SwimNodeEvaluatorMixin`）· 客户端 20+ · **`TFCMixinPlugin`**（条件加载插件） |
| **Firmalife** | **3 个** | `BarrelRackMixin` · **`BeeMixin`** · `ServerConfigMixin` |
| **firmalifehardcore** | **8 个**，且 mixins.json 写 **`"required": true`** | `ClimateMixin` · `FoodShelfBlockEntityMixin` · `HangerBlockEntityMixin` · `LargeVesselBlockEntityMixin` · `PumpingStationBlockEntityMixin` · `SprinklerBlockEntityMixin` · `AbstractSprinklerBlockMixin` · `ThermometerMixin` —— **全部集中在"温室气候 + 灌溉 + 保鲜容器"三个目的上** |

⇒ **结论**：要"**系统级覆盖**"邻居的机制，**mixin 是常规手段，不是最后手段**。
⭐ `"required": true` 这一条尤其值得学 —— 它让**任何一个 mixin 应用失败时直接启动崩溃**，
而不是静默失效（见 §12.6.5 规则 4）。

#### 12.6.2 B 的 mixin 清单（**逐条：目标 / 目的 / 先例**）

| # | 目标类 | 目的 | 有先例吗 | 优先级 |
|---|---|---|---|---|
| 1 | Firmalife 的**气候 / 温室**（`ClimateReceiver` 等） | 让**我们的温室方块**参与气候计算 | ✅ **hardcore 的 `ClimateMixin`** | **P0** |
| 2 | `FoodShelfBlockEntity` / `HangerBlockEntity` / `LargeVesselBlockEntity` | 让**邻居的保鲜容器**受我们地窖分级影响 | ✅ hardcore 的 3 个（⚠️ 见 §12.6.4 的冲突处理） | P1 |
| 3 | `PumpingStationBlockEntity` / `SprinklerBlockEntity` / `AbstractSprinklerBlock` | 我们的灌溉接入邻居的泵与喷淋 | ✅ hardcore 的 3 个（⚠️ 同上） | P1 |
| 4 | `ThermometerBlockEntity` | 温度计显示我们的温度模型 | ✅ hardcore 的 `ThermometerMixin` | P2 |
| 5 | TFC **`FoodCapability` / `FoodData`** | 🆕 **降级（原 P0）**：~~调料影响营养~~ **已被用户口径否决**；调料改走 `FoodTrait`（**零 mixin**，见 §6.5）⇒ 本条**只剩「地窖 / 保冷延长保质期」一个理由** | ❌ 无先例 | **P1** |
| 6 | TFC 的**烹饪**（`PotBlockEntity` / 动态食物计算） | 🆕 **降级（原 P1）**：~~调料参与烹饪与营养推算~~ 已否决 ⇒ 只在「要在**同一锅里**动态加料」时才需要 | ❌ 无先例 | **P2** |
| ~~7~~ | ~~TFC `CropBlock` / `CropHelpers`~~ | 🆕 **作废**：连作 / 适播 **TFC 已有**，授粉**不做**（用户口径，见 §13.4） | — | — |
| ~~8~~ | ~~Firmalife `BeehiveBlockEntity`~~ | 🆕 **作废**：~~授粉 → 产量修正~~ —— **用户口径：「授粉增产无必要，不需要添加」** | — | P2 |
| 9 | TFC `BarrelBlockEntity` | 大桶液体腐坏 —— 🛑 **已在 §6.9 否决**（改走"物品层"） | — | ❌ 不做 |

**B 的 mixin 预算：约 8~9 个**（其中 **P0 两个**：气候 + 腐坏推进）。

#### 12.6.3 C / D 的 mixin 清单

| # | 目标类 | 目的 | 先例 | 归属 |
|---|---|---|---|---|
| 1 | TFC `Animal` / `Mammal` / `BreedBehavior` | **饲料品质 → 繁殖 / 成长 / 产率**（§8.2） | TFC 自己有 **7 个动物 accessor**，说明该体系可 mixin（它自己也这么做） | **D** |
| 2 | `LivingEntity` / `Mob` 的死亡路径 | **落尸体方块**（§8.1 的 C 项 **P0**） | ✅ TFC 的 `MobMixin` | **C** |
| 3 | `EntityMixin`（掉落） | 尸体体系接掉落 | ✅ TFC 的 `EntityMixin` | C |
| 4 | TFC 的**生成**（`SpawnPlacements` / fauna） | 补空缺生态位的生成条件 | ✅ TFC 的 `SpawnPlacementsMixin` | C |

**C / D 的 mixin 预算：约 4 个**（C 的 2 个是 P0；D 的 1~2 个在 C 之后）。

#### 12.6.4 🛑 与已安装模组的 **mixin 目标冲突**（新问题，v14 第 11 轮）

⚠️ **firmalifehardcore 已经 mixin 了 §12.6.2 里的 #1~#4**。
若 B 也 mixin 同一批目标类 ⇒ **两个模组同时注入同一个方法**，轻则行为叠加，重则崩溃。

| 场景 | 处置 |
|---|---|
| **检测到 hardcore 在场** | 🛑 **B 自动停用 #1~#4 这 4 个 mixin**，并在日志明确提示"检测到 firmalifehardcore，B 的温室 / 灌溉 / 保鲜容器 mixin 已让位"（与 §5.6.1 的让位机制**同一处实现**） |
| 只装 B | ✅ #1~#4 启用 |
| 🛑 禁止 | B **不 mixin hardcore 的类**、**不覆盖它的资源**（它也是"邻居"，§2.8 / §〇.2.6） |

⇒ **实现手段**：把这 4 个放进**独立的 mixin 配置组 / 子模块**，用 `"required": false` + 一个**条件开关**
（学 TFC 的 `TFCMixinPlugin` 做法），由加载器按检测结果决定是否加载。

#### 12.6.5 🛑 mixin 的 6 条硬规则（**与"用不用"无关，永远有效**）

| # | 规则 | 理由 |
|---|---|---|
| 1 | **绝不 mixin A 的类** | §〇.2.6 红线 3。mixin 目标是**字符串**，指向 A 会让 B 绑定 A 的**内部实现**（编译期不报错、运行期崩） |
| 2 | **绝不 `@Overwrite`** | 它**整段替换**目标方法，与任何改同一方法的模组都冲突。**"完全重制"也不构成使用它的理由** |
| 3 | **优先 `@Inject(at = HEAD / TAIL)`，慎用 `@Redirect`** | `@Redirect` 抢占调用点，冲突率高 |
| 4 | 🛑 **mixin 配置写 `"required": true`**（或每个方法 `require = 1`） | 目标方法不存在时**启动即崩**，而不是**静默失效** —— 本项目已被静默失效坑过（`AGENTS.md` §二-17）。⚠️ **例外**：§12.6.4 的**条件让位组**必须用 `"required": false` |
| 5 | **方法签名写全**（`"foo(Lnet/minecraft/world/level/Level;)V"`） | 只写方法名会在**重载**时产生歧义 ⇒ 注入到错的那个 |
| 6 | **每个 mixin 单独登记进 `OVERRIDE-REGISTRY.md`** | mixin 既不在 `assets/` 也不在 `data/` ⇒ **是覆盖台账最容易漏的一类**（§5.5 的 197 文件统计里就不含它） |

#### 12.6.6 分工原则：**什么该 mixin，什么不该**（手段优先级重排）

| 手段 | 适用 | 例 |
|---|---|---|
| **数据 / 标签**（第一） | 改**参数**、加**条目**、加**配方** | 营养值 · 腐烂速率 · 堆肥档 · `tfc:fuel` · `drinkable` |
| **继承 + 自建**（第二） | 加**新对象**，或让新对象融入邻居体系 | 新作物 · 新设备 · 新动物（继承 `TFCAnimal`）· 自建保鲜容器 |
| **NeoForge 事件**（第三） | 加**外挂行为**，不改原逻辑 | 右键交互（§7.2.4 的 `in_world`）· 死亡时落尸体 |
| 🆕 **mixin**（**第四，且是必选项**） | 改**已有对象的行为逻辑本身** | 腐坏推进 · 营养累积 · 烹饪计算 · 作物生长 · 温室气候 · 动物繁殖 |

🛑 **判据一句话**：**"改的是「参数」还是「行为」？"** ——
**参数**走数据；**行为**（已有类的内部逻辑）**必须 mixin**，因为**数据包与事件都够不到它**。

## 十三、深化：种植与加工的"下一层"（用户指示：打磨完之后构思如何深化）🆕 v14

> **用户口径**：「继续打磨剩下的部分，**打磨完之后构思如何"深化"种植和加工内容**」

### 13.0 先说清楚"深化"**不是**什么

| ❌ 不是 | 为什么 |
|---|---|
| 再加 N 种作物 | §1.1 已有 **146 种植物 / 86 种作物** —— 数量不是瓶颈 |
| 再加 N 条配方 | §三 基线：TFC **6,419** 条 · Firmalife **1,079** 条 · afc **707** 条 —— 配方数不是瓶颈 |
| 再抄一个模组的设备清单 | §5.4 已有 extradelight 的 10 类设备参考 —— **设备本身不产生深度** |

✅ **"深化" = 让同一个内容产生更多「可操作的决策点」与「有意义的产出路径」。**
**判据**：玩家在**同一个物种**上是否有 **≥2 条**都合理的路线，且不同路线通往**不同结果**（而不是"多一步、结果一样"）。

### 13.1 三条主轴

| 主轴 | 一句话 | 手段 | 新增代码量 |
|---|---|---|---|
| **横向** | 一个原料**多条出路** | 主/次产品 × 去向矩阵 | **≈0**（几乎全是标签与数据） |
| **纵向** | 把一条链**拉长** | 补中间工序（麦芽化 · 淀粉 · 脱胶 · 熟成） | 中（多数是配方 + 1 个新配方类型） |
| ~~**系统**~~ | ❌ **已作废**（~~让种植本身成为决策~~：~~肥力 · 季相 · 授粉~~）—— TFC 已有肥力与季相、授粉不做 | — | — |

🛑 **推荐顺序：横向 → 纵向 → 系统。** 理由见 §13.6 的成本收益对照。

### 13.2 横向深化：主/次产品 × 去向矩阵（**性价比最高，建议先做**）

TFC 已经给了 **4 条"零配方"的次产品出口**（全部是 §7.2.2 实测过的机制）：

| 出口 | TFC 载体（已有） | 我们要做的 | 代码量 |
|---|---|---|---|
| **堆肥** | `tfc:compost_browns/{high,medium,low}` · `compost_greens/{high,medium,low}` · `compost_poisons` | 按碳氮比给次产品分档塞进标签 | **0**（纯数据） |
| **燃料** | `tfc:fuel` 数据类型 `{ingredient, duration, temperature, purity}` | 给秸秆 / 藤蔓 / 干叶写定义 | **0**（纯数据） |
| **饲料** | `tfc:foods/*` + 动物取食 | 新鲜草 / 叶 / 藤入标签 | **0**（纯数据） |
| **扦插 / 育苗** | TFC `flower_cutting` 先例 + §6.8 育秧 | 部分次产品可育苗 | 低 |

🛑 **这是"深化"的第一刀**：今天 86 种作物的次产品**绝大多数只有一个去处（堆肥）**。
把它们分流到 4 条出口后，玩家才会开始为"**留种 / 沤肥 / 喂牲口**"做选择 —— 这就是深度。

**设计表（🆕 v14 第 10 轮：已从"3 个示例"展开到「86 种作物全覆盖 / 9 个族」）**

> **为什么按族而不按物种**：同族作物在**形态管线、次产品种类、去向逻辑**上完全一致
> （例如 21 种叶菜的次产品都是"外叶 · 老叶"，去向都是 `greens/high` + 干叶燃料 + 外叶饲料）。
> 逐物种写会变成 86 行同义重复；**按族写既覆盖全部 86 种，又保持可读**。
> ⚠️ 族内**例外**单独标在"其他"列（如姜黄是染料、丝瓜络是纤维、辣椒是调料）。

| 族 | 数量 | 成员（**全部列出**） | 食用主产品 | 次产品（破坏方块时产出） | → 堆肥档 | → 燃料 | → 饲料 | → 育苗 | → 其他 |
|---|---|---|---|---|---|---|---|---|---|
| **谷类禾本** | **13** | einkorn · emmer · spelt · wild_rice_stem · millet · pearl_millet · finger_millet · foxtail_millet · fonio · sorghum · quinoa · buckwheat · amaranth | 籽粒 | **秸秆 · 糠** | `browns/low` | ✅ 秸秆 | ✅ 糠 | ❌ | 编织（草席 / 草帽）· ⭐ **麦芽化（§13.3-1）** |
| **豆类** | **9** | adzuki · chickpea · common_bean · cowpea · faba_bean · lupin · pea · pigeon_pea · winged_bean | 豆粒 | **豆荚 · 藤 · 叶** | `greens/medium` | ✅ 干藤 | ✅ 藤（**豆藤是高蛋白饲料**） | ❌ | **固氮**（§13.4-1 绿肥还田） |
| **块根块茎** | **16** | arrowhead · celeriac · chicory_root · ginger · lotus · parsnip · salsify · shallot · sunchoke · taro · turmeric · turnip · water_caltrop · water_chestnut · yacon · yam | 块根 / 块茎 | **藤 · 叶** | `greens/medium` | ✅ 干藤 | ✅ 藤（**红薯叶可食**） | ✅ **扦插 / 分株** | ⭐ **淀粉（§13.3-2）** · 姜黄 = 染料 / 药用（§6.7-E3） |
| **叶菜** | **21** | artichoke · arugula · asparagus · broccoli · brussels_sprouts · cardoon · cauliflower · celtuce · celery · kale · lettuce · malabar_spinach · mustard_greens · napa_cabbage · purslane · rhubarb · spinach · swiss_chard · water_dropwort · water_shield · water_spinach | 叶 / 花球 / 嫩茎 | **外叶 · 老叶** | `greens/high` | ✅ 干叶 | ✅ 外叶 | ❌ | **堆肥主力**（绿 N 最高） |
| **茄果瓜类** | **10** | bitter_melon · bottle_gourd · cantaloupe · chayote · chili · eggplant · loofah · okra · snake_gourd · winter_melon | 果实 | **藤 · 叶 ·（葫芦科）老果** | `greens/medium` | ✅ 干藤 | ⚠️ 部分（瓜藤饲料价值低） | ❌ | ⭐ **丝瓜络 = 纤维（§13.3-5）** · 葫芦 = **容器** · 辣椒 = **调料（§6.5）** |
| **纤维** | **5** | cotton · flax · hemp · ramie · sisal | 籽（油料）/ 部分可食 | **麻秆 · 韧皮 · 棉籽** | `browns/high` | ✅ 麻秆 | ⚠️ 棉籽饼粕 | ❌ | ⭐⭐ **沤麻 → 纤维 → 纺织（§13.3-5）** |
| **油料** | **3** | safflower · sesame · sunflower | 籽 | **秸秆 · 油饼** | `browns/low` | ✅ 秸秆 | ✅ **油饼粕**（榨油副产） | ❌ | ⭐ **榨油（§13.3-3）** · 红花 = 染料 |
| **香草香料** | **4** | chive · fenugreek · garland_chrysanthemum · perilla | 叶 / 花 | **茎 · 叶** | `greens/high` | ✅ 干茎 | ✅ | ❌ | ⭐ **调料（§6.5）** · 菊花 = 茶（E1）· 葫芦巴 = 香料 |
| **特用** | **5** | agave · bambara_nut · gorgon_nut · hops · jobs_tears | 视物种 | **纤维渣 · 壳** | `browns/medium` | ✅ | ✅ | ❌ | ⭐ **hops → 啤酒（E7）** · 龙舌兰 = 纤维 + 酒 · 薏苡 = 谷物 + 药用 |
| **合计** | **86** | ✅ **全覆盖**（与 §1.1 的 86 种作物一致） | — | — | — | — | — | — | — |

⚠️ **本表的分组由脚本核对过**：9 族成员合计 **86 / 86**，**未分组 0**。
（注：`barley · rye · oat · wheat · rice` 是 **TFC 的**作物，**不在我方 86 种里** ——
所以 §4.2 那条"谷物四件套 14"指的不是我方物种，而是给 **TFC 谷物**做的加工配方。）

### 13.3 纵向深化：补齐 TFC 加工链上"被跳过的那一环"

**逐条核过 §3.1 基线后的真实缺口**（下面 5 条里有 1 条是自我更正，见 #3）：

| # | 缺的环 | 现状（实测） | 深化后 | 需要的机制 |
|---|---|---|---|---|
| 1 | **麦芽化（malting）** | TFC 的啤酒线**没有"浸泡 → 发芽 → 烘干"**这道工序；`tfc:hops` 物品**未被任何配方使用** | 谷物 → 麦芽 → 麦芽粉 → 糖化 → 麦汁 → 啤酒（+ 酒花终于有用） | `barrel` + `drying`（**零新设备**） |
| 2 | **淀粉提取** | TFC **无** starch / 粉条（`noodle` 的命中只是洞穴噪声函数 `noodle_caves`） | 木薯/马铃薯 → 磨浆 → 沉淀 → 淀粉 → 粉条 / 芡粉 | `quern` + `barrel`（**零新设备**） |
| 3 | ⚠️ **油料扩展**（**自我更正**） | 🛑 **TFC 已经有榨油**：`tfc:olive_oil` / `tfc:canola_oil`（`pot/olive_oil_water` 煮 → `barrel/olive_oil_cooling` 油水分离）+ `tfc/lamp_fuel/*` 灯燃料定义 | 深化 = **把同一范式扩展到我们的油料作物**（花生 / 芝麻 / 亚麻籽 / 向日葵 / 棉籽），**不是新建榨油** | 复用 TFC 的 `pot`+`barrel` 两步范式 |
| 4 | **熟成（aging）** | Firmalife 有奶酪轮与葡萄酒，但**没有通用的"熟成"工序**（时间 × 温度 → 品质分档） | 熟成架：同一产物按熟成时长分 2~3 档品质 | 1 个新方块 + BE（§5.6 的地窖温度可复用） |
| 5 | **纤维脱胶（沤麻 / retting）** | **完全为零** —— 亚麻 / 大麻 / 苎麻 / 剑麻 / 棉花有产物但**无任何出口**（§1.2 最明显的断链） | 沤麻（水中浸数日）→ 打麻 → 纤维 → 纺线 → 织物 | ⭐ **`in_world` 配方类型（§7.2.2 第 1 项）** |

⚠️ **第 5 项同时是纵向（新工序）与横向（次产品出海口）** ⇒ **建议作为纵向深化的第一个试点**：
它已有 `docs/74` §10.2-27 的明确授权（"亚麻这类多用作物**记录并搁置**（未来「深化作物处理体系」时重置）"），
且 TFC 侧有 `tfc:jute_fiber`（已在 `compost_browns/high`）+ `tfc:straw` 的现成先例可对齐。

#### 13.3.1 五条链的**工序设计**（逐条到可开工）

**① 麦芽化（malting）** —— 🟢 **零新设备**

| 步 | 工序 | 设备 | 输入 → 输出 | 机制 |
|---|---|---|---|---|
| 1 | 浸泡 | `barrel` | 谷物 + 水 → 浸泡谷 | TFC `barrel`（数据驱动） |
| 2 | 发芽 | 地面 / `drying_mat` | 浸泡谷 → **绿麦芽**（数日） | `in_world` 或 `drying` |
| 3 | 烘干 | `firepit` / `oven` | 绿麦芽 → **麦芽**（加热终止发芽） | TFC `heating` 配方类型 |
| 4 | 研磨 | `quern` | 麦芽 → **麦芽粉** | TFC `quern` |
| 5 | 糖化 | `barrel` | 麦芽粉 + 热水 → **麦汁** | TFC `barrel` |
| 6 | 发酵 | `barrel_sealed` | 麦汁 + **hops** → 啤酒 | **复用 TFC 啤酒线，插入 hops 环节** |

⭐ **一箭双雕**：TFC 的啤酒**直接用面粉**（无麦芽工序），而 **`tfc:hops` 至今没有任何配方使用它** ——
这条链同时填两个洞。**配方量：约 6~10 条（纯数据）。**

**② 淀粉提取** —— 🟢 **零新设备**

| 步 | 工序 | 设备 | 输入 → 输出 |
|---|---|---|---|
| 1 | 磨浆 | `quern` | 木薯 / 马铃薯 → **薯浆** |
| 2 | 沉淀 | `barrel` | 薯浆 + 水 → **湿淀粉**（+ 废水） |
| 3 | 干燥 | `drying` | 湿淀粉 → **淀粉** |
| 4 | 成型 | `pot` / `crafting` | 淀粉 + 水 → **粉条 / 芡粉** |

**③ 油料扩展** —— 🟢 **复用 TFC 范式（不是新建榨油）**

| 步 | 工序 | 设备 | 输入 → 输出 | TFC 的现成先例 |
|---|---|---|---|---|
| 1 | 煮 | `pot` | 油料籽 + 水 → `X_oil_water` | `pot/olive_oil_water` |
| 2 | 冷却分离 | `barrel` | `X_oil_water` → `X_oil` | `barrel/olive_oil_cooling` |
| 3 | **副产** | — | **油饼粕 → 饲料** | 回到 §13.2 横向 |

**适用物种**：§13.2 的油料族 3 种（safflower · sesame · sunflower）+ 纤维族的籽（flax · cotton）+ TFC 的 peanut。

**④ 熟成（aging）** —— 🔴 **需 1 个新方块**（五条里唯一一个）

| 项 | 设计 |
|---|---|
| 方块 | **熟成架** `aging_rack` · 状态 `count`(0~4) + `tier`(0~2) = **15 个状态** ⚠️ 略超 §7.2.5 的 ≤8 约束 ⇒ 改用 `count`(0/1/2) 或拆两档 |
| 机制 | **时间 × 温度 → 品质分档**（2~3 档） |
| 温度来源 | ⭐ **直接用 §5.6 的地窖 / 温室温度模型**（**共用基建，不重复实现**） |
| 适用 | 奶酪（Firmalife 的 **7 种**轮）· 酒 · 火腿 · 干酪 |
| 前置 | §5.6 的温度基建 |

**⑤ 纤维脱胶（沤麻 / retting）** —— ⭐ **纵向 + 横向双料**

| 步 | 工序 | 载体 / 机制 | 输入 → 输出 |
|---|---|---|---|
| 1 | **沤麻** | **沤麻池**（§7.2.5 #1）· `in_world` | 麻秆 + 水 → **沤好的麻秆**（数日） |
| 2 | **打麻** | **脱粒垫**（§7.2.5 #2）· `in_world` | 沤好的麻秆 → **纤维** + 麻屑（燃料） |
| 3 | 纺线 | ⭐ Firmalife **`loom`**（**已有！** 实测 1 条配方） | 纤维 → **线** |
| 4 | 织布 | 同上 | 线 → **布** |
| 🛑 | **不新建织机** | Firmalife 已有 `loom` | 只加"纤维 → 线"的配方 |

**适用 5 种**：cotton · flax · hemp · ramie · sisal（**A 层三套 blockstate 齐全**，只缺这条链）
**授权**：`docs/74` §10.2-27（"记录并搁置，未来「深化作物处理体系」时重置"）。

#### 13.3.2 五条链的共同特征（**为什么它们算"纵向"而不是"新增内容"**）

| 特征 | 说明 |
|---|---|
| **不新增原料** | 全部用 A 层已有作物或 TFC 已有物品 —— **零物种工作** |
| **几乎零新设备** | **4 / 5 条**复用 TFC 与 Firmalife 的现有设备（只有 #4 熟成架是新方块） |
| **每条都对应 §1.2.1 的致命缺口** | #1↔hops 无用途 · #2↔淀粉空白 · #3↔油料扩展 · #5↔纤维断链 |
| **配方量小** | 合计约 **25~35 条**（相比 §4.2 的 ~140 条是小头） |
| **可独立交付** | 五条互不依赖，可**按任意顺序**单独立项 |


### 13.4 ~~系统深化：让种植本身成为决策~~ ❌ **已作废**（用户口径：连作与适播 TFC 已有、授粉不做）

| # | 系统 | 已有地基（§1.4 实测） | 最小增量 | 成本 | 建议 |
|---|---|---|---|---|---|
| 1 | **土壤肥力 / 连作** | 🆕 **TFC 已完整实现**：`FarmlandBlockEntity$NutrientType` + `PlantableInfo$PlantNutrients` + **`Fertilizer` 数据类型（10 个）**（`{nitrogen,phosphorus,potassium}`：compost · saltpeter · wood_ash · bone_meal · guano · sylvite · pure_* · shellfish） | — | — | ❌ **作废**（用户口径：「**连作和适播内容已有，不要重复造轮子**」） |
| 2 | **季节 / 物候** | 🆕 **TFC 已有**：`Calendars` + `Month` + 果树的 `Lifecycle` **12 月物候表** + `ClimateRange{min/max_temperature, min/max_hydration}` | — | — | ❌ **作废**（同上） |
| 3 | **授粉（蜜蜂增产）** | Firmalife 养蜂（**用户口径：不覆盖**） | — | — | ❌ **不做**（用户口径：「**授粉增产无必要，不需要添加**」） |
| 4 | **水分（旱涝分档）** | `MyFloodedCropBlock`（已有，但是**布尔**） | 分 3~4 档墒情 | 中 | ⚠️ 观察（与 §5.6 灌溉重叠，避免双重实现） |
| 5 | **覆盖物 / 地膜** | 🛑 **TFC 没有杂草机制**（实测：`weed` 的命中全是植物名 pickerelweed / milkweed / duckweed） | 只剩"保湿 + 保温"价值 ⇒ 与 §5.6 温室功能重叠 | 中 | ❌ **不做**（价值不足） |
| 6 | **病虫害** | 无 | — | 高 | ❌ **不做**（§十一 已移除） |

🛑 **本节 6 项里只有 3 项（#1 / #2 / #3）进入方案** —— 其余显式排除，避免"深化"变成"加系统"。

#### 13.4.1 ❌ 三项的实现方式 —— **已作废（仅保留为决策记录）**

> 🛑 **2026-09-29 用户口径**：「**连作和适播内容已有，不要重复造轮子**」·「**授粉增产无必要，不需要添加**」
> ⇒ **下面三小节（连作 / 适播 / 授粉）全部作废**，保留仅为记录"曾经的设计思路"，**不要据此开工**。
> 替代内容见子文档 [`126-b-module-implementation.md`](126-b-module-implementation.md) **§十一（现实农业加工 × extradelight 的灵感扩充）**。

**#1 连作惩罚 + 绿肥还田**

| 项 | 设计 |
|---|---|
| 机制 | 同一格**连续种同科**作物 ⇒ 产量 / 生长速率下降；**种豆科或还田** ⇒ 恢复 |
| 实现 | 🛑 **mixin `CropBlock` / `CropHelpers`**（§12.6.2 **#7**）—— **数据包够不到生长逻辑** |
| 数据 | 86 物种的 `npk` 字段**已经写好了**（`0.6/0.3/0.5`）⇒ **按 §13.2 的九个族**分组即可，**零新数据** |
| 存哪 | 每格的"连作计数"存 **`SavedData`** —— 🛑 **不存方块状态**（否则 86 物种的 blockstate 状态数会爆炸） |
| 数值 | ⚠️ **全部自定**（§2.8 红线 1：不照抄任何模组） |
| 防滥用 | 惩罚有**上限**（不能归零）· **换族即重置**（这才是"轮作"的意义） |

**#2 适播季 + 霜冻**

| 项 | 设计 |
|---|---|
| 机制 | 每种作物有"**适播季**"（春 / 夏 / 秋）；非适播季种下 ⇒ 生长慢或**冻死** |
| 实现 | ⭐ **主体是纯数据**：`tfc/climate_range` 已有 **146** 个 ⇒ **加一个 `season` 字段**；🆕 只有**霜冻判定**需要少量 mixin（改生长逻辑） |
| 霜冻 | **复用 TFC 的温度体系** —— `MySeasonalPlantFix`（§1.4 已实现）本就在处理气候休眠 |
| 归属 | 它是 §6.8 育秧流程「**④ 生长管理**」的一部分 |

**#3 授粉（蜜蜂增产）**

| 项 | 设计 |
|---|---|
| 机制 | 花期 + **蜂箱距离** → 产量修正 |
| 实现 | 🛑 **mixin Firmalife 的 `BeehiveBlockEntity`**（§12.6.2 **#8**）—— 让蜂箱"知道"周围有什么作物 |
| 🛑 不碰养蜂本体 | ✅ **只读**蜂箱状态；**不改**它的蜂种 / 能力 / 寄生虫 / 遗传病（用户口径：**养蜂不覆盖**） |
| 数据 | 作物的"**花期**"字段 —— **与 #2 的 `season` 是同一次数据改动**（一起做） |

#### 13.4.2 ❌ 三项的「共同点」分析 —— **已作废**

> 🛑 **2026-09-29 用户口径**：三项里 **#1 连作**与 **#2 适播 TFC 已有**（`Fertilizer` 数据类型 + `Calendars`/`Lifecycle` 物候），**#3 授粉不做**。
> ⇒ 本节原来「1 个 mixin 承载 3 套数据」的结论**失去对象**，`CropBlock` mixin **不再需要**（§12.6.2 **#7 已标作废**）。

| 原观察 | 现状 |
|---|---|
| 三项都要改生长逻辑 ⇒ 共享 `CropBlock` mixin | ❌ **三项都不做了** ⇒ **无需该 mixin** |
| 数据侧复用（`npk` / `season` / `flowering`） | ❌ 不再加这两个字段 |

⚠️ **顺带澄清一处概念混淆（旧稿的误读）**：A 层表里的 `npk='0.6/0.3/0.5'` 是**我们自己写的展示字段**，
与 **TFC 实际的农田养分机制**（`FarmlandBlockEntity$NutrientType` + `PlantableInfo$PlantNutrients`）
**不是同一个东西** —— 旧稿把它当成「我们已有 NPK 地基」是误读。


### 13.5 深化与已有章节的关系（**防重复建设**）

| 深化项 | 已有章节 | 本节补充了什么 |
|---|---|---|
| 13.2 横向 | §6.2 主/次产品 | 给它补上**4 条出口的完整清单**（原来只写了"堆肥"） |
| 13.3-1 麦芽 | §6.7-E1（茶/咖啡/药草）、hops | **hops 的出路**（TFC 里它至今无配方） |
| 13.3-5 脱胶 | §6.7-E4 纤维 | 给它补上**实现路径**（`in_world`）与**授权出处** |
| 13.4-1/2/3 | §十一 增量建议 | 与 §十一 一致；§十一 的其余项（NPK 模拟 / 灾害 / 成就）仍为"不做" |

### 13.6 成本收益对照（**决定动手顺序**）

| 序 | 做什么 | 代码量 | 玩家可感知度 | 风险 |
|---|---|---|---|---|
| 1 | **横向：次产品 4 出口** | ≈0（标签 + `tfc:fuel` 数据） | **高**（立刻改变"收完就扔"的行为） | 极低 |
| 2 | **纵向：油料扩展**（复用 TFC 范式） | 低（纯配方） | 中 | 极低 |
| 3 | **纵向：沤麻 + `in_world`** | 中（1 个新配方类型 + 配方） | **高**（"在田里干活"的实感） | 中（新配方类型需实测） |
| 4 | **纵向：麦芽化 + 淀粉** | 低（配方，零新设备） | 中 | 极低 |
| ~~5~~ | ~~**系统：#1 连作 + #2 适播季 + #3 授粉**~~ | ❌ **整行作废**（TFC 已有前两项、第三项不做） | — | — |
| 🆕 **5'** | **现实加工补齐**（子文档 126 §十一）：曲霉发酵（酱）· 烟熏 · 青贮 · 舂米 · 筛分 · 风干 · 糖渍/油浸 | 低~中（**7 项里 4 项零新方块**；新方块仅 3 个） | **高**（曲霉发酵是三方都没有的空白） | 低 |
| 6 | 纵向：熟成架 | 中（1 方块 + BE） | 中 | 中 |

### 13.7 验收判据（"深化"有没有做到，只看这 3 条）

1. **同一物种有 ≥2 条合理路线**（例：大麦 → 面粉 **或** 麦芽；亚麻 → 纤维 **或** 亚麻籽油）
2. **次产品有 ≥2 条去处**（不再全是堆肥）
3. **玩家需要在"现在做 / 以后做"之间做选择**（例：青割喂牲口 **vs** 等成熟收籽）

---

## 十四、附录

### 14.1 参考源规模一览（本工作区，1.21.1 NeoForge）

| 模组 | jar | 大小 | 条目 | 配方类型 |
|---|---|---|---|---|
| TFC | `TerraFirmaCraft-NeoForge-1.21.1-4.2.11.jar` | 62.3 MB | — | 20 类 |
| Firmalife | `Firmalife-NeoForge-1.21.1-3.0.14.jar` | 4.28 MB | 6,359 | 23 类 |
| AFC | `afc-2.1.3-1.21.1.jar` | 6.18 MB | 11,539 | 4 类 + 兼容层 |
| （借鉴）extradelight | `TerraFirmaGreg-Modern/mods/extradelight-1.1.5-all.jar` | 9.93 MB | 11,919 | 26 类 |
| （借鉴 ✅MIT）tfcwoodwork | `mods/tfcwoodwork-1.21.1-1.2.4.jar` | 0.73 MB | **1,091 文件**（jar 条目 1,221 = 文件 + **130 目录**） | 2 类（自研 `in_world` + 覆盖 TFC 的 4 类） |
| （借鉴）untamedwilds | `mods/untamedwilds-1.20.1-4.0.4.jar.disabled` | 2.76 MB | 2,230（**225 物种实体**）| — |

### 14.2 我们的 146 种植物去向

| 去向 | 数量 | 归属 |
|---|---|---|
| TFC 标签体系（汤 / 沙拉 / 三明治 / 果酱 / 腌制） | ~110 | **A** |
| Firmalife 体系（drying / vat / oven / spice / jarring） | ~70 | **A** |
| TFC 谷物四件套 | 14 | **A** |
| 新设备（蒸发 / 保冷 / 成型 / 熔化 / 炒锅） | 全部 | **B** |
| 物种覆盖（草莓 / 可可 / 葡萄 / 香料 / TFC 作物与灌木 / 坚果） | ~40 | **B** |
| 扩展域（茶 / 咖啡 / 药草 / 纤维 / 坚果 / hops） | ~20 | **B**（E1~E7）—— ⚠️ **E8 宠物 / 驯化已从 B 移出**，归 **C**（§6.7-E8） |

### 14.3 复现命令

```powershell
$v = 'D:\111\最强服务器\.minecraft\versions\Essential TerraFirmaCraft (TFC)'
Add-Type -AssemblyName System.IO.Compression.FileSystem

# 三模组配方类型 + 规模
foreach ($j in 'TerraFirmaCraft-NeoForge-1.21.1-4.2.11.jar','Firmalife-NeoForge-1.21.1-3.0.14.jar','afc-2.1.3-1.21.1.jar') {
  $zip = [System.IO.Compression.ZipFile]::OpenRead("$v\mods\$j")
  "=== $j ($($zip.Entries.Count) 条目) ==="
  $zip.Entries | Where-Object { $_.FullName -match '^data/[^/]+/recipe/.+\.json$' } |
    Group-Object { ($_.FullName -split '/')[3] } | Sort-Object Count -Descending | Select-Object -First 12
  $zip.Dispose()
}

# 关键事实核对
$zip = [System.IO.Compression.ZipFile]::OpenRead("$v\mods\TerraFirmaCraft-NeoForge-1.21.1-4.2.11.jar")
"TFC crate 条目 : $(@($zip.Entries | Where-Object { $_.FullName -match 'crate' }).Count)"      # 141 = 已有
"TFC acorn 条目 : $(@($zip.Entries | Where-Object { $_.FullName -match 'acorn' }).Count)"      # 0   = 需新增
"TFC oak/chestnut: $(@($zip.Entries | Where-Object { $_.FullName -match '(^|/)oak' }).Count) / $(@($zip.Entries | Where-Object { $_.FullName -match '(^|/)chestnut' }).Count)"

# 🛑 口径陷阱之二：jar 的 Entries **包含目录条目** —— 统计文件数必须先排除
#   实测：tfcwoodwork 的 1,221 个 Entries 里有 130 个是目录 ⇒ 真实文件只有 1,091
#   不排除的后果：每一层目录都被多算 1 条
#   （本文档 v14 初稿的 302 / 194 / 257 / 111 / 44 五个数字**全部因此偏高**，已更正）
$z = [System.IO.Compression.ZipFile]::OpenRead("$v\mods\tfcwoodwork-1.21.1-1.2.4.jar")
$files = $z.Entries | Where-Object { -not $_.FullName.EndsWith('/') }   # ← 关键就这一句
"tfcwoodwork 文件 $($files.Count) / 条目 $($z.Entries.Count)（其中目录 $($z.Entries.Count - $files.Count)）"
"  自研配方      : $(@($files | Where-Object { $_.FullName -like 'data/tfcwoodwork/recipe/*' }).Count)"        # 281
"    in_world    : $(@($files | Where-Object { $_.FullName -like 'data/tfcwoodwork/recipe/in_world/*' }).Count)"   # 240（= 12 类工序 × 20 种树）
#     ⚠️ 别写成 '*in_world*'：那会把 assets/.../jei/in_world_recipe.png 也算进来（得 241）
"  覆盖 TFC 配方 : $(@($files | Where-Object { $_.FullName -like 'data/tfc/recipe/*' }).Count)"                # 182
"  TFC 数据类型  : $(@($files | Where-Object { $_.FullName -like 'data/tfcwoodwork/tfc/*' }).Count)"           # 107（fuel 100）
"  标签覆盖      : $(@($files | Where-Object { $_.FullName -match '^data/(tfc|minecraft|c)/tags/' }).Count)"   # 11
"  class 文件    : $(@($files | Where-Object { $_.FullName -like '*.class' }).Count)"                          # 53（顶层 39 + 内部 14）
$z.Dispose()

# untamedwilds 的物种数（§7.3 写 225）
$z = [System.IO.Compression.ZipFile]::OpenRead("$v\mods\untamedwilds-1.20.1-4.0.4.jar.disabled")
$lf = $z.Entries | Where-Object { $_.FullName -eq 'assets/untamedwilds/lang/en_us.json' }
$sr = New-Object System.IO.StreamReader($lf.Open()); $lang = $sr.ReadToEnd() | ConvertFrom-Json; $sr.Close()
$ent = $lang.PSObject.Properties | Where-Object { $_.Name -match '^entity\.untamedwilds\.' -and $_.Name -notmatch '\.sciname$|command' }
"untamedwilds 物种实体: $($ent.Count)（带亚种后缀 $((@($ent | Where-Object { ($_.Name -split '\.')[-1] -match '_' })).Count)）"   # 225 / 199
$z.Dispose()

# 🛑 协议核实（§2.8 的硬性要求就是靠这条命令得出的，不是凭印象）
$probe = @(
  "$v\mods\tfcwoodwork-1.21.1-1.2.4.jar",
  "$v\mods\Aquaculture-1.21.1-2.7.21.jar.disabled",
  "$v\mods\untamedwilds-1.20.1-4.0.4.jar.disabled",
  'D:\111\最强服务器\.minecraft\versions\TerraFirmaGreg-Modern\mods\DragNs_Livestock_Overhaul-1.20.1-3.9.1.jar'
)
foreach ($f in $probe) {
  if (-not (Test-Path $f)) { "缺失: $f"; continue }
  $z = [System.IO.Compression.ZipFile]::OpenRead($f)
  $m = $z.Entries | Where-Object { $_.FullName -match 'META-INF/(neoforge\.)?mods\.toml' } | Select-Object -First 1
  $sr = New-Object System.IO.StreamReader($m.Open()); $c = $sr.ReadToEnd(); $sr.Close()
  $lic = (($c -split "`n") | Where-Object { $_ -match '^\s*license\s*=' } | Select-Object -First 1)
  "{0,-46} {1}" -f (Split-Path $f -Leaf), $(if ($lic) { $lic.Trim() } else { '(无 license 字段)' })
  $z.Dispose()
}
# 预期：tfcwoodwork = MIT · Aquaculture = All Rights Reserved · untamedwilds = GNU GPL · DragN = All Rights Reserved, DragN0007
# 本项目自身的协议在 src/main/templates/META-INF/neoforge.mods.toml 里（license = "MIT"）

# 🛑 配方数量的两个口径（本文档 v13 起以「内容口径」为准）
#   目录口径 = 配方文件所在子目录（Get-ChildItem 统计）—— 例 TFC recipe/pot/ 有 216 个文件
#   内容口径 = 读文件里的 "type" 字段        —— 例 type 为 tfc:pot 的只有 145 条
#   两者可能差异很大；另有 neoforge:false（条件包装）需展开才准确
$z = [System.IO.Compression.ZipFile]::OpenRead("$v\mods\TerraFirmaCraft-NeoForge-1.21.1-4.2.11.jar")
$stats = @{}
foreach ($e in $z.Entries) {
  if ($e.FullName -notmatch '^data/[a-z_]+/recipe/.+\.json$') { continue }
  $sr = New-Object System.IO.StreamReader($e.Open()); $x = $sr.ReadToEnd(); $sr.Close()
  $m = [regex]::Match($x, '"type"\s*:\s*"([^"]+)"')
  $tp = if ($m.Success) { $m.Groups[1].Value } else { '(no type)' }
  $stats[$tp] = 1 + ($stats[$tp] -as [int])
}
$stats.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 16
$z.Dispose()

# 🛑 straw 来源核对（教训：只查配方文件名会漏掉「掉落表」与「配方内容」两条路径）
#   ① 掉落表：13 种野生草（alternatives：剪刀→草；#tfc:tools/sharp → tfc:straw）
$z = [System.IO.Compression.ZipFile]::OpenRead("$v\mods\TerraFirmaCraft-NeoForge-1.21.1-4.2.11.jar")
$strawPlants = @()
foreach ($e in $z.Entries) {
  if ($e.FullName -notmatch 'loot_table/blocks/plant/.+\.json$') { continue }
  $sr = New-Object System.IO.StreamReader($e.Open()); $x = $sr.ReadToEnd(); $sr.Close()
  if ($x -match 'tfc:straw') { $strawPlants += (($e.FullName -split '/')[-1] -replace '\.json$','') }
}
"掉落表产 straw 的植物: $($strawPlants.Count) 种  ->  $($strawPlants -join ', ')"   # 应为 13
#   ② 配方内容：6 种谷物脱粒副产（tfc:extra_products modifier）
$z.Entries | Where-Object { $_.FullName -match 'recipe/crafting/food/.+_grain\.json$' } | ForEach-Object { ($_.FullName -split '/')[-1] }
#   ③ 合成：straw_from_alfalfa / straw_from_canola / straw_from_hay / straw(thatch)
$z.Entries | Where-Object { $_.FullName -match 'recipe/crafting/straw' } | ForEach-Object { ($_.FullName -split '/')[-1] }
$z.Dispose()
$zip = [System.IO.Compression.ZipFile]::OpenRead("$v\mods\Firmalife-NeoForge-1.21.1-3.0.14.jar")
"Firmalife fruit_leaf: $(@($zip.Entries | Where-Object { $_.FullName -match 'fruit_leaf' }).Count)"   # 养蚕饲料
$zip.Dispose()

# 本模组侧（草莓/可可应各为 0 = 漏掉的部分）
Get-ChildItem "$v\moddev\tfcfarmingplus\src" -Recurse -File | Where-Object { $_.Name -match 'strawberr|cocoa' }
```

---

*本文档随 A / B / C / D 四模组的实施与验证结果更新。下一步：§九 阶段 1（A 的零配方接入）与阶段 2（B 的草莓 / 可可接管）。*
