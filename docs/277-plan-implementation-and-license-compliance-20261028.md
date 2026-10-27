# 277 计划实现与开源协议履行审查报告

> 审查日期：2026-10-28（Asia/Shanghai）
> 审查对象：`mod_rebuild` 工作树；GitHub 分支 `mod-rebuild-20261027`（根目录 = `mod_rebuild` 内容，当前仍为 `58865795eb21741b769503161618c8c10c08fa57`）
> 重点：**① 计划实现情况；② 开源协议/许可证履行情况**
> 报告状态：**本地报告，未推送 GitHub**；待按报告完成修改后再随修改一起提交。
> 修复执行：2026-10-28 已按本报告完成协议/代码修复，见 [279 修复记录](279-protocol-code-fixes-20261028.md)；本文保留审查时快照。
> 取证辅助：D1 文档审查、D2 资源审查、D3 Java/工具审查；本报告在其基础上补充计划/许可证专项结论。

---

## 0. 摘要

### 0.1 结论

**计划实现：主线 AR0–AR4-AG 的“静态交付”大多完成，但 AR4-AH、整个 AR5、视觉长尾和最终验收未完成；工程重构 273/274/275 只完成了一部分，且 274/273 的现状描述与实测不一致。**
**开源协议履行：当前处于“许可证元数据互相矛盾 + 第三方义务未履行”的状态，不能按 MIT-only 发布。**

最关键的合规结论：

1. **项目根 `LICENSE.txt` 是 EUPL-1.2，A/B 的 `neoforge.mods.toml` 却都写 `license = "MIT"`；分支根目录又没有 `LICENSE` 文件。**
   - 这三个事实不能同时成立。
2. **大量 TFC/Firmalife 命名空间内容、TFC 逐像素贴图和“照抄 TFC”的代码注释已经进入 A/B 源码/资源，但没有 TFC 的 EUPL 许可文本、署名或来源登记。**
   - TFC 是 **EUPL-1.2（弱 copyleft）**，不是 MIT。
3. **B 的 TFC Woodworking 迁移做得相对规范**：JAR 内有 `tfcwoodwork-MIT.txt` 和 `timber-notice.txt`，这是目前唯一完整履行的第三方 MIT 义务。
4. **A 的 JAR 没有任何通用许可证/第三方声明；B 的 JAR 也只有 Woodworking 两页。**
   - 分支根目录同样没有 `LICENSE`/`NOTICE`/`THIRD_PARTY_NOTICES`。
5. **计划要求的许可证门禁没有覆盖 TFC/EUPL/Firmalife/Patchouli**：
   - B 的 `check-boundaries.ps1` 只扫 `extradelight`/`arr` 等受限模组；
   - TFC EUPL 风险在 126 号计划 §19 已写明，但从未落实到门禁或发布物。

### 0.2 风险等级

| 级别 | 数量 | 内容 |
|---|---:|---|
| P0 | 4 | 项目许可证自相矛盾/分支无 LICENSE；TFC EUPL 义务未履行；TFC 代码“照抄”注释与 MIT 声明冲突；TFC 逐像素贴图/书页/数据无授权链 |
| P1 | 5 | 第三方来源登记缺失；Firmalife/Patchouli/AFC 通知缺失；B AFC 依赖未声明；AR4-AH/AR5 未完成；6 整瓜模型回归 |
| P2 | 5 | authors 占位、无 SPDX/版权头；8 张 TFC 贴图来源未登记；A/B 命名空间衍生文件未登记；许可证门禁未覆盖；报告/计划状态未同步 |

---

## 1. 审查对象与事实基线

### 1.1 当前树与分支

- 当前分支 HEAD：`58865795eb21741b769503161618c8c10c08fa57`（根目录已扁平化为 `mod_rebuild`）；
- 本报告写入本地 `mod_rebuild/docs/277-...`，**未执行 git push**；
- 先前 276 号审查报告曾短暂推送、已回退；本报告不改变 `main` 和 `mod-rebuild-20261027`。

### 1.2 许可证/元数据实测

| 对象 | 实测 | 说明 |
|---|---|---|
| 工作区根 `LICENSE.txt` | **EUPL-1.2** | 欧洲公共许可证 1.2，弱 copyleft |
| 分支根 `LICENSE`/`NOTICE` | **不存在** | 扁平化后没有把根许可证带入分支 |
| A `neoforge.mods.toml` | `license = "MIT"` | 与根 EUPL 矛盾 |
| B `neoforge.mods.toml` | `license = "MIT"` | 与根 EUPL 矛盾 |
| A authors | `dsh` | 占位名，非版权人/组织 |
| B authors | `dsh` | 同上 |
| A JAR `META-INF/licenses` | **无** | 无通用许可/第三方声明 |
| B JAR `META-INF/licenses` | `tfcwoodwork-MIT.txt`、`timber-notice.txt` | 唯一完整履行的第三方 MIT 义务 |
| 源码 SPDX/版权头 | **0** | 无 SPDX、无 copyright |

### 1.3 依赖许可证实测（读各依赖 JAR 的 `META-INF/neoforge.mods.toml`）

| 依赖 | 实测 license | 与本项目的关系 |
|---|---|---|
| TerraFirmaCraft 4.2.11 | **EUPL-1.2** | 必需依赖；A/B 均有 TFC 命名空间内容、TFC 贴图/模型/书页、源码“照抄”注释 |
| Firmalife 3.0.15 | **MIT** | A 有 157 个 `data/firmalife/**` 文件；B 依赖 Firmalife |
| afc 2.1.3 | **MIT** | B 的 `AFC_WOODS`/14 树种资源引用；B 的 mods.toml **未声明 afc** |
| TFC Woodworking 1.2.4 | **MIT** | B 迁移了 `in_world`/crafting/woodwork 数据与 timber 几何；MIT 通知已在 B JAR |
| Patchouli 1.21.1-93 | **CC BY-NC-SA 3.0** | A/B 的运行时手册依赖；项目未分发 Patchouli 本体，但需披露依赖许可证 |
| JEI 19.57.0.449 | **MIT** | B 可选依赖 |

> 说明：许可证判断以各 JAR 的 `license` 字段和项目根 `LICENSE.txt` 为证据；具体是否构成衍生作品、是否需要 EUPL 传染，属于法律判断，本报告只做工程合规审查，不替代法务意见。

---

## 2. 计划实现情况

### 2.1 真实计划在哪里

当前 `docs/README.md` 的“当前入口”列的是 271/272/273/274/275 等，但真正的主线计划在归档：

- `docs/archive/217-agriculture-repair-next-phase-plan-20261023.md`：AR0–AR5 总计划、当前状态、下一步 AR4-AH；
- `docs/archive/260-ar4v-visual-backlog-and-agriculture-status-20261026.md`：AR4-V 视觉待办、农业阶段状态、22 项 backlog；
- `docs/archive/126-b-module-implementation.md`：B 侧计划、§19 协议合规专章；
- `docs/archive/117-agriculture-redesign-plan.md`：拆分计划、§2.8 协议红线。

**计划实现审查的第一个问题不是“完了多少”，而是“当前权威计划不在当前入口”。** 217/260 被 `docs/README` 划成“archive 非当前规范”，而 273/274/275 只讲工程重构，导致读者无法从当前入口判断 AR4/AR5 到底完成到哪。

### 2.2 计划完成度总表

| 阶段 | 计划内容 | 文档自述 | 当前实测/判断 |
|---|---|---|---|
| AR0 | 农业现状与缺口台账 | 已完成静态基线 | **完成（静态）**；未改功能代码 |
| AR1-A | 草莓手册/资源 | 静态完成、构建部署、实机待确认 | **静态完成**；RuntimeVerified=false |
| AR1-B | 可可产物/旧树兼容 | 静态完成、构建部署、实机待确认 | **静态完成**；旧可可兼容有测试 |
| AR1-C | 35 单格 + 7 可重复采收 | 静态检查完成、实机待确认 | **静态完成**；87 形态矩阵存在 |
| AR1-D | 16 双格 + 11 攀爬 | 静态完成、实机待确认 | **静态完成**；仍有透明 PNG/A9 历史项 |
| AR1-E | 10 水生作物 | 静态完成、实机待确认 | **静态完成**；PNG/运行未验收 |
| AR1-F | 3 蔓延 + 整瓜 | 静态完成、实机待验 | **静态完成**；整瓜模型后续回归见 §2.4 |
| AR1-G | 5 莲座 | 静态完成、实机待验 | **静态完成**；未实机 |
| AR2-A…E | 产物/土壤/加工链 | 各批静态完成 | **静态完成**；完整长链仍缺（10 非小麦谷物磨粉、三油料榨油、菠萝麻纺织、酿酒等） |
| AR3-A…F | 果树/灌木/世界生成 | 各批静态完成、实机待验 | **静态完成**；49 树/12 灌木；跨季/根交/连冠/兼容仍缺 |
| AR4-A…AG | 视觉批次 | 大量 “静态交付、实机/美术未验” | **静态批次完成**；当前仍有 949 个模型使用 TFC 占位贴图、1,130 张死/未接入贴图 |
| AR4-AH | 芦笋完整显示链 | **下一步；尚未施工** | **未完成**：芦笋模型仍 `texture: tfc:block/crop/barley_*` |
| AR5 | 验证、交付、闭环 | **尚未开始** | **未开始**：无完整回归、无最终交付/回滚 |
| 273 工程重构 | 命名/目录/门禁 | 部分完成 | **部分**：`_vN` 69、缺 `docs/INDEX.md`/`STATUS.md`/`verify-naming/links/layout`；274/273 状态自相矛盾 |
| 274/275 | 重构记录/资源分层 | 274 自述资源逐字节一致；275 已移动模型/贴图 | **274 关键声明为假；275 移动了路径但未修 6 整瓜模型内容** |
| 126 §19 协议合规 | TFC EUPL、Patchouli CC、MIT 邻居 | 只写在计划里 | **门禁只扫受限模组命名空间；未落实 TFC/EUPL/通知** |

### 2.3 贴图验收状态：全部待重绘，历史“完成”声明无效

**用户 2026-10-28 明确：**

- 贴图问题要求之后**全面重绘**；
- 之前声称“已经完成/已验收”的贴图内容，**实际上不合格**；
- 因此不得再用现有贴图作为验收基准，也不得把任何当前贴图标记为最终合格。

据此修正前面的判断：

- 949 张“旧 JAR 曾用”的 A 贴图**不是最终资产**，只是重绘参考；修复模型引用它们不等于完成美术；
- 1,130 张死贴图、6 张低色数图、26 组重复图、B 的 57 张 item 图，全部进入“待重绘/未验收”范围；
- 6 个整瓜模型的问题仍要修（模型结构/贴图槽），但贴图本身也要重绘；
- 清理策略必须服从“先重绘、后删除”；在替换与验收前，当前被引用贴图必须保留，未引用贴图可先归档/保留参考。

### 2.4 已完成的“计划项”与未完成边界

**可以确认完成（静态层面）的项目：**

- 87 项作物/49 项树/12 灌木的登记与资源骨架；
- 481 个 A blockstate、1,652 个 block model、435 个 item model；
- A 的 481 个 loot 与 blockstate 1:1；
- A worldgen configured/placed 闭环；
- B 的 492 blockstate、1,137 个已引用模型、756 个配方（其中 409 in_world）；
- B 的容器/粮食/水果/in-world/kitchenware/drying/silkworm 等静态 verify 通过；
- A/B `gradle build --offline` 成功；artifacts 与新构建产物 class 一致。

**不能确认完成的计划项：**

- **全部 RuntimeVerified=false**：没有实机加载、没有真实种植/交互/掉落验证；
- **AR4-AH 未施工**：芦笋六龄、野生、枯株、盆栽仍借 TFC barley 贴图；
- **AR5 未开始**：没有最终回归清单、交付哈希、回滚点；
- **视觉长尾**：949 个模型仍是 TFC 占位；1,130 张死贴图全部进入重绘范围，其中 949 张仅作旧版参考，不是最终资产；
- **6 整瓜模型**：计划 106 号明确记录已修为“自包含立方体 + 各自贴图”，当前源码却只有 `{"parent":"minecraft:block/melon"}`（见 §2.5）；
- **273 的验收条件**：`_vN` 69 张（目标 0）、编号重复 8 组 + 153/155/156/157 四组 md/json 同号、`docs/INDEX.md`/`STATUS.md`/`verify-naming|links|layout.ps1` 全部不存在；
- **许可合规**：见 §3，未完成。

### 2.5 计划/实现的具体偏差

#### 偏差 A：6 个整瓜模型回归（P1，计划已声称修复）

计划 106 号/工作区用户裁决记录：

> “`models/block/{winter_melon,cantaloupe,bottle_gourd,rotten_*}.json` 原本只有 `{"parent":"minecraft:block/melon"}`、没有任何贴图覆盖 ⇒ 冬瓜/哈密瓜/葫芦/三种腐烂瓜全是同一个 vanilla 西瓜外观。已由 Lead 改成自包含立方体模型 + 各物种自己的 `_fruit_side`/`_fruit_top` 贴图。”

当前源码实测：

```json
{"parent":"minecraft:block/melon"}
```

6 个模型均只有这一行；旧部署 JAR 中同名模型带 `textures.side/end/particle` 覆盖；12 张 `textures/block/melon/*_fruit_{side,top}.png` 全部无引用。

- 影响：整瓜/腐烂瓜显示 vanilla 西瓜；
- 与计划：**计划记录“已修”，源码没有**；属于实现回归/未落地；
- 与 275 关系：275 只移动了这些父模型到 `melon/`，未检查 `textures` 内容；**移动不是根因，但 275 的分层验收未发现回归**。

#### 偏差 B：949 个模型使用 TFC 占位贴图（P1，计划已知但未完成）

计划 249/260 已明确：

- 77 种作物栽培仅取 TFC 纹理（260 当前盘点为 74 种“可见面”）；87 个种子模型取 TFC 素材；盆栽同类；
- AR4 是“静态交付，实机/最终美术未验”。

当前 D2 实测：

- 949 个模型（609 crop + 138 dead_crop + 73 wild_crop + 84 seeds + 39 food + 4 fiber + 2）在旧部署 JAR 中引用 A 自有贴图，当前改成 `tfc:` 借用；
- 949 张自有贴图全部仍在树中，但无模型引用；
- 当前 artifacts 已按这个占位态构建。

判断：

- **这不是“凭空回退”，而是计划中的视觉长尾尚未完成**；
- 但它与 274 的“资源逐字节与旧树一致”相矛盾，也说明 **AR4 不能标完成**；
- 当前分支是“生成器占位态”，不是最终美术态。

#### 偏差 C：AR4-AH 芦笋未施工（P1，计划明确下一步）

计划 217 的下一步：

> “AR4-AH：芦笋（asparagus）完整显示链审查与必要修复，预期复杂 5/5。当前成熟模型仍借用 barley_5……”

当前实测：

- `models/block/crop/asparagus_age_0.json` → `{"parent":"block/crop","textures":{"crop":"tfc:block/crop/barley_0"}}`
- `asparagus_age_5` → `barley_5`；
- 芦笋资源/语言/掉落都已存在，但**视觉是占位**。

因此 AR4 的“下一片”没有完成，不能把 AR4 标为完成。

#### 偏差 D：273 工程验收未达成（P1）

273 目标中的最低验收项：

- 运行时资源 `_vN` = 0：实际 **69 张**（A）；
- `docs/INDEX.md`/`STATUS.md`：不存在；
- `verify-naming.ps1`/`verify-links.ps1`/`verify-layout.ps1`：不存在；
- `blockstates`/`models/block`/`textures/block` 分类镜像：只做了 models/textures，blockstates 未动（blockstate 路径与注册 ID 绑定，273 自己也注明不能直接搬）；
- 编号重复/文档同号：实际仍有 8 组重复 + 153/155/156/157 四组 md/json 同号；
- 274 的“245 个 .ps1”实际为 **161**；“226 个归档文件”实际为 **244 份旧文档 + README**（顶层索引只列 226 个顶层文件，18 个嵌套文件未入索引）；
- 274 §2 “资源逐字节与旧树一致、唯一差异是 B mixins”被实测推翻：A 5,922 中 10 改 + 20 路径迁移；B 3,031 中 163 改 + 18 迁移。

结论：273 是“部分完成”，不是“已验收”。

#### 偏差 E：计划状态与文档入口不一致（P1）

- 真正的计划在 217/260，当前入口却把它们当非规范；
- 272 记录“暂停开发、等待用户恢复”，此后 273/274/275 和两次构建发生，没有恢复记录；
- 271/272 的 JAR 哈希（A `F16EA381...`、B `EC9B98AD...`）与当前 artifacts（A `386834A1...`、B `97B961DB...`）不一致；
- 实例 `mods/` 仍是 2026-10-05 旧 JAR，未部署当前构建；
- 274/README 只写大小，没有当前 SHA-256、部署位置、回滚点。

#### 偏差 F：B 的内容/协议缺口不在 AR 计划内（P1，补充发现）

- B 389/492 个方块无 loot table（只有 103 个有）；
- B 16 处模型贴图引用缺失；
- `food/pan_seasoned_vegetables` 无 item 模型；
- B 未声明 afc 依赖，却注册/引用 14 个 AFC 树种；
- 这些不属于 A 的 AR 计划，但属于 B 的交付/协议完整性，应在“最终闭环”前处理。

---

## 3. 开源协议/许可证履行情况

### 3.1 项目自身许可证：EUPL 与 MIT 冲突

**实测：**

- `D:\...\LICENSE.txt`：**EUPL-1.2** 全文（工作区根）；
- 分支根 `mod_rebuild`：**没有 LICENSE/NOTICE/COPYING**；
- A/B `src/main/templates/META-INF/neoforge.mods.toml`：**`license = "MIT"`**；
- `authors = "dsh"`，不是版权人；
- A/B JAR：A 无任何 license 文件；B 只有 `tfcwoodwork-MIT.txt`/`timber-notice.txt`。

**判断：**

1. 如果项目按根 `LICENSE.txt` 采用 EUPL-1.2，则 `mods.toml` 的 MIT 声明错误；应改为 EUPL-1.2，并在 JAR/分支根附 EUPL 全文。
2. 如果项目想按 MIT 发布，则根 `LICENSE.txt` 错误，且必须确认没有 TFC 衍生内容；当前显然有 TFC 命名空间内容、TFC 书页/模型/贴图和“照抄 TFC”的代码注释，**不能单方面 MIT-only**。
3. 分支根没有许可证文本，任何下载/分发对象都无法从分支内确认授权；这是发布阻断项。

**结论：P0。不能以“MIT”发布当前树，直到完成许可证选择并统一所有元数据。**

### 3.2 TFC（EUPL-1.2）义务

TFC 是 **EUPL-1.2**，弱 copyleft。项目与 TFC 的关系不是“只调用 API”这么简单：

| 内容 | 实测 | 风险 |
|---|---|---|
| `assets/tfc/**` | A 51 个（32 assets + 19 data），B 196 个（12 assets + 184 data） | 含修改过的 TFC 模型、书页、配方禁用文件；可能是衍生作品 |
| TFC Patchouli 书页 | A 10 个语言的 `the_world/wild_fruits.json` | 从 TFC 内容修改/派生，无 TFC 通知 |
| TFC cabbage 模型 | A 6 个 `assets/tfc/models/block/crop/cabbage_age_*.json` | 覆盖/修改 TFC 模型，无通知 |
| TFC 逐像素贴图 | A 8 张 strawberry 作物贴图与 TFC 逐像素相同 | **直接复制 TFC 资产**，无 EUPL 通知/来源登记 |
| TFC 数据 | A `data/tfc/**`、B 182 个 `data/tfc/recipe/**` 禁用/覆盖文件 | 修改 TFC 数据；需 EUPL 说明 |
| 代码注释 | A `TFCFarmingPlus.java`、`TFCFarmingPlusClient.java`、`FarmingSpreadingBushBlock.java`、`FarmingBushes.java` 出现“照抄 TFC” | 若实际复制代码，EUPL 义务触发；同时违反 `DEVELOPMENT_RULES` §一.1 |

**EUPL 的最低义务（工程口径，不是法律意见）：**

- 保留版权声明和许可证声明；
- 以 EUPL-1.2 分发衍生作品（或取得兼容许可）；
- 提供对应源代码/修改说明（项目本身有源码，但缺声明和来源登记）；
- 在分发物中包含 EUPL 文本；
- 不得把 EUPL 衍生部分单方面改成 MIT。

**当前状态：未履行。** 没有 TFC 的 `LICENSE`/`NOTICE`，没有 TFC 版权行，没有 `THIRD_PARTY_NOTICES`，没有来源/修改登记。

### 3.3 TFC 代码“照抄”注释

源码中直接写“照抄 TFC”的至少有：

| 文件 | 行 | 原文 |
|---|---:|---|
| `TFCFarmingPlus.java` | 31 | “注册体系完全照抄 TFC 的形态” |
| `TFCFarmingPlusClient.java` | 28 | “客户端注册 —— 全部照抄 TFC 的 ClientEventHandler” |
| `FarmingSpreadingBushBlock.java` | 41 | “构造器照抄 TFC FruitBlocks.SpreadingBush.createBush() 的参数顺序” |
| `FarmingBushes.java` | 196 | “属性完全照抄 TFC FruitBlocks.StationaryBush.create()” |
| `SawdustSoupBowlItem.java` | 11 | “B-owned copy of the licensed sawdust soup bowl return behavior” |

这些注释至少说明代码形态来自 TFC/受许可代码。无论代码相似度多少，**当前项目不能同时声称 MIT-only 且保留这些来源**。

**代码相似度复核（Lead 2026-10-28）：**

用 5-gram token Jaccard 对 A/B 全部 123 个 Java 文件与 `de_moddev/src-ref/TFC-decompiled`（1,672 文件）、`Firmalife`（2,199 文件）做自动比对（脚本：`docs/audit/code_similarity.py`）：

| 相似度 | 项目文件 | 最相似的反编译文件 |
|---:|---|---|
| 0.347 | `FarmingCropBlock.java` | TFC `DefaultCropBlock.java` |
| 0.293 | `FarmingSpreadingCaneBlock.java` | TFC `DeadBananaPlantBlock.java` |
| 0.273 | `FarmingSeedItem.java` | TFC `SeedItem.java` |
| 0.270 | `FarmingSpreadingBushBlock.java` | TFC `DeadBananaPlantBlock.java` |
| 0.265 | `FarmingBerryBushBlock.java` | TFC `DeadBananaPlantBlock.java` |
| 0.226 | `FarmingGrowingFruitTreeBranchBlock.java` | Firmalife `FLGrowingFruitTreeBranchBlock.java` |

判断：

- 自动比对**没有发现 >0.5 的整文件级相似复制**，最高 0.347；
- 这只能说明“未发现大段逐字复制”，**不能证明合规**；Top 5 仍建议人工逐类核对（构造器/状态机/回调）；
- “照抄 TFC”注释本身已构成来源声明，必须改为可核验的“参考 API/独立实现”说明，或按 EUPL 合规处理；
- 处理完成前，不能把代码整体标为 MIT-only。

处理选项：

1. **按 EUPL-1.2 发布**：保留来源/修改说明，附 EUPL 文本，接受弱 copyleft；或
2. **独立重写**：按 `DEVELOPMENT_RULES` 要求重新设计，保留行为/ID/兼容性，删除“照抄”来源；或
3. 取得 TFC 作者对 MIT 再许可的书面授权（不现实，需用户/法务确认）。

当前没有任何一项被记录为已完成。

### 3.4 TFC Woodworking（MIT）：当前唯一做对的部分

- B 的 JAR 含 `META-INF/licenses/tfcwoodwork-MIT.txt`（Copyright (c) 2024 uTa4u，MIT 全文）；
- 含 `timber-notice.txt`（来源 GitHub/版权/说明）；
- 源码注释 `TimberPieceBlock`、`TimberPileBlockEntity`、`AgricultureItems` 写明 MIT 来源；
- 这满足 MIT 的“保留版权声明和许可声明”要求。

**结论：B 的 Woodworking 迁移是正面样板；应把同一标准推广到 TFC/Firmalife/Patchouli/AFC。**

### 3.5 Firmalife（MIT）

A 有 **157 个 `data/firmalife/**` 文件**：

- 其中 155 个是项目新增的 `firmalife/plantable/*` 等，不是 Firmalife JAR 原文件；
- 2 个是修改 Firmalife 已有文件（`strawberry.json`、`buzzing_leaves.json`）；
- 项目还使用 Firmalife API/设备。

判断：

- 若这些文件是项目独立编写的，**不必然需要复制 MIT 通知**；
- 但 2 个修改文件和任何从 Firmalife 派生的内容，应保留 Firmalife 的 MIT 版权/许可声明；
- 当前没有任何 Firmalife 通知或来源登记。

**结论：P1，需来源登记；如为独立编写，在 THIRD_PARTY_NOTICES 中说明“Firmalife-namespace 数据为项目原创/兼容数据”即可。**

### 3.6 Patchouli（CC BY-NC-SA 3.0）

- A/B 以运行时依赖方式使用 Patchouli；
- A/B 的 `assets/tfc/patchouli_books/field_guide/**` 是 **TFC 手册内容/项目新增页**，不是 Patchouli 的代码/资源；
- 项目未分发 Patchouli 本体；
- 但手册内容依赖 Patchouli，README/发布说明没有写 Patchouli 的 CC BY-NC-SA 3.0 依赖声明。

判断：

- **没有发现复制 Patchouli 代码/资源的证据**，不触发其 SA 义务；
- 但应披露“手册依赖 Patchouli（CC BY-NC-SA 3.0）”，避免用户误以为全部 MIT；
- 若未来分发整合包，需注意 Patchouli 的非商业条款。

**结论：P1 文档披露，不是当前代码侵权。**

### 3.7 AFC（MIT）

- B 注册/引用 14 个 AFC 树种资源，但没有在 `neoforge.mods.toml` 声明 `afc` 依赖；
- 没有复制 AFC 资源到 B 树（B 无 AFC 命名空间文件），只是引用 `afc:` 贴图/木材；
- AFC 是 MIT，API 引用本身不要求通知；但**依赖未声明是协议/运行完整性问题**（缺 AFC 时资源/创造页不完整）。

**结论：P1；补依赖声明和 AFC MIT 说明。**

### 3.8 A/B 产物内的许可证

| JAR | 通用 LICENSE | 第三方通知 | 结论 |
|---|---|---|---|
| A | 无 | 无 | **不合规**（至少缺项目许可证和 TFC 通知） |
| B | 无 | `tfcwoodwork-MIT`、`timber-notice` | 部分合规（Woodworking 对；TFC/Firmalife/AFC/Patchouli 缺） |

`mods.toml` 的 `license="MIT"` 是元数据字符串，不等于许可证文本；MIT 还要求版权声明，当前 `authors="dsh"` 无法满足。

### 3.9 来源/许可登记缺失

`DEVELOPMENT_RULES.md` §一.8 要求：

> “历史衍生内容的来源与许可说明继续保留……模型、贴图、音效等资源另行登记来源与复用方式。”

当前：

- 只有 B 的 2 个 Woodworking 文件；
- 没有 `THIRD_PARTY_NOTICES.md`、`LICENSES/`、`asset-provenance.json`；
- 没有登记 TFC 8 张逐像素贴图、TFC 10 个书页、6 个 cabbage 模型、B 182 个 TFC 数据覆盖、A 157 个 Firmalife 命名空间文件；
- 没有登记“照抄 TFC”的代码来源；
- 没有登记 `SawdustSoupBowlItem` 的“licensed behavior”来源。

**结论：P0/P1，无法证明履行，也无法在收到第三方质询时快速响应。**

### 3.10 协议门禁

B `tools/scripts/verify/check-boundaries.ps1` §19.4 只做：

- 扫资源不得出现 `extradelight|extradelighttfc|dragn|aquaculture|cuisine|untamedwilds|survivorsdelight|firmalifeenhance|butchery`；
- 扫 mods.toml 不得依赖上述受限模组。

它**不检查**：

- 项目根/分支根是否有 `LICENSE`；
- `mods.toml license` 是否与 `LICENSE` 一致；
- 是否有 TFC/Firmalife/AFC/Patchouli 通知；
- TFC 命名空间文件/贴图/书页是否有来源登记；
- `_vN`/第三方资产是否有授权；
- JAR 内是否含许可证文本。

**结论：计划 126 §19.4 写了“协议门禁”，实际只实现了受限模组黑名单，TFC/EUPL 主风险没有门禁。**

### 3.11 无用内容分类与清理清单

用户已要求对无用内容归类分析，为后续“工作区简洁/文件尺寸”清理提供依据。详细清单见：

- [278 工作区无用内容归类与清理清单](278-cleanup-inventory-20261028.md)
- 机器可读清单：`docs/audit/cleanup-candidates.csv`
- **执行结果**：2026-10-28 已执行第一批清理，删除 58,015 个文件、释放约 **1,001 MB**（`.probe` 695.8→18.91 MB，`de_moddev` 358.6→49.63 MB，`mod_rebuild` 41.4→27.07 MB）；详见 278 §9。

核心分类：

| 类别 | 主要对象 | 规模 | 处置方向 |
|---|---|---:|---|
| 贴图预览/分析 | `.probe/texture-design/px` | 26,924 文件 / **654.7 MB** | 保留最终参考后删除 |
| 旧反编译/演示/构建 | `de_moddev/` | 40,192 文件 / **358.6 MB** | 许可证取证后归档/删除 |
| 旧开发树/证据 | `moddev/` | 10,185 文件 / 45.5 MB | 回滚期后整体归档 |
| 游戏世界存档 | `simplebackups/` | 331.5 MB | **用户数据，不能当废弃备份删** |
| 分支死贴图 | A 1,130 张 | 约 241 KB | 全面重绘验收后清理 |
| 死工具数据 | `_tags-baseline`、无引用 `texture-jobs-*`、TextureAverage/Stats | 约 24 文件 | 可先删 |
| 兼容 wrapper | A 49 + B 17 | 66 文件 | 迁移调用后删 |
| 历史生成器 | `gen-*-textures`、`localize-*`、`repair-*` 等 | 约 30 脚本 | 重绘新管线替换后归档 |

> 清理必须服从：**贴图先重绘并验收，再删旧贴图/旧生成器；被模型引用的当前贴图在替换前不能删；本轮不执行删除。**

---

## 4. 计划实现与协议履行的交叉结论

| 计划项 | 计划要求 | 实际 | 结论 |
|---|---|---|---|
| 117 §2.8 | TFC=EUPL-1.2，不能按 MIT 照搬 | 根 EUPL、mods.toml MIT、无通知 | **冲突未解决** |
| 126 §19 | TFC EUPL 风险；写 B README/手册注明 | 无 README/手册声明 | **未履行** |
| 126 §19.4 | 协议合规门禁 | 仅受限模组黑名单 | **部分/无效** |
| DEVELOPMENT_RULES §一.1/7/8 | 禁止直接照抄代码；来源登记 | 代码有“照抄”注释；无登记 | **违反** |
| 2026-10-28 贴图指令 | 全部贴图重绘；历史“完成”声明无效 | 949/1,130 仍为占位/未接入；6 整瓜回归 | **全部待重绘** |
| AR4-AH | 芦笋完整显示链 | 仍借 TFC barley | **未施工** |
| AR5 | 完整回归/交付/回滚 | 未开始 | **未完成** |
| 106 整瓜 | 自包含立方体 + 各自贴图 | 6 模型只有 parent | **回归/未落地** |
| 249/260 视觉 | 949 占位/22 项 backlog | 仍存在 | **未完成** |
| 273 验收 | `_vN`=0、INDEX/STATUS、verify 脚本 | `_vN`=69、缺文件 | **未达成** |
| 274 记录 | 资源逐字节一致、唯一差异 B mixins | 实测有 10+20/163+18 改动 | **记录错误** |

---

## 5. 建议的处置顺序

### 5.1 P0（发布/推送前必须完成）

1. **确定项目许可证**
   - 建议以根 `LICENSE.txt` 的 **EUPL-1.2** 为准（与 TFC 衍生风险一致）；
   - 或由用户/法务确认可 MIT-only，并删除/独立重写所有 TFC 衍生内容；
   - 统一 `LICENSE`、`mods.toml license`、JAR 内许可证、README/发布说明。
2. **补 TFC EUPL 合规包**
   - `THIRD_PARTY_NOTICES.md`：TFC 版权/EUPL-1.2/来源 URL/修改说明；
   - `LICENSES/EUPL-1.2.txt`；
   - 明确 8 张逐像素 TFC 贴图、10 个 TFC 书页、6 个 cabbage 模型、B 182 个 TFC 数据覆盖的来源与授权；
   - 若不能合规，替换/独立重写这些内容。
3. **处理“照抄 TFC”代码**
   - 逐个文件登记来源与相似性；
   - 选择 EUPL 合规或按 `DEVELOPMENT_RULES` 独立重写；
   - 删除误导性的“MIT-only”声明。
4. **分支根/产物加许可证**
   - 分支根 `LICENSE`、`NOTICE`/`THIRD_PARTY_NOTICES`；
   - A/B JAR 内 `META-INF/licenses/` 完整；
   - `authors` 改为真实版权人/组织（用户确认后）。

### 5.2 P1（发布前）

1. 补 Firmalife/Patchouli/AFC/TFC Woodworking 的通知/来源登记；B Woodworking 已经是正确样板；
2. B `neoforge.mods.toml` 声明 afc（required 或 optional+条件处理）；
3. 恢复 6 个整瓜模型的自包含 `textures`；
4. 完成 AR4-AH（芦笋）、AR5（回归/交付/回滚）；
5. 修 274/273 的现状描述，建立 `PLAN.md`/`STATUS.md`/`INDEX.md`；
6. 把真实计划 217/260 上提到当前入口，归档 190/219/220/233/271/272；
7. 补协议门禁：LICENSE/元数据一致性、TFC 命名空间来源、JAR 内 license 文件、第三方通知完整性；
8. **全面贴图重绘**：按用户 2026-10-28 指令重新验收，删除“已完成/已验收”旧结论；重绘完成前不得宣布视觉完成。

### 5.3 P2（后续）

- SPDX/版权头；2026-10-28 之后的来源登记；
- 清理 `_vN` 运行时命名（69 张）；
- 统一编号/文档同号；
- 修复 `ARCHIVE-INDEX` 的 226 vs 244/18 嵌套文件；
- 补 A 106 个技术方块 lang、B 空 lang/缺 lang；
- 清理死资源：**949 张旧贴图仅作重绘参考，不是最终资产；全面重绘验收后再清理**；
- 按 278 号清单分批清理工作区（`.probe` 预览、`de_moddev`、旧备份、死工具数据）。

---

## 6. 结论

**计划层面：主线静态工程完成度高，但 AR4-AH/AR5/视觉长尾/最终验收未完成；工程重构 273/274/275 只完成部分，当前文档不能作为“已完成”依据。**

**贴图层：用户 2026-10-28 已明确所有贴图全面重绘，此前声称完成的内容不合格；现有 949/1,130 张仅是占位/参考，不是最终资产，任何“贴图已完成”的旧结论全部作废。**

**许可证层面：当前树不满足开源协议履行要求，不能发布：**

- 项目自身许可证 EUPL vs MIT 矛盾，分支根无 LICENSE；
- TFC EUPL 来源内容/代码/逐像素资产无许可文本/署名/来源登记；
- 只有 B 的 TFC Woodworking MIT 通知是完整履行的；
- Firmalife/Patchouli/AFC 通知或依赖声明缺失；
- 协议门禁未覆盖主要风险。

**建议：先按 §5.1 完成许可证与来源链，再完成 AR4-AH/AR5 和 6 整瓜回归；所有修改完成后再一起提交，不在当前阶段推送。**

---

## 7. 取证与状态

- 本报告：`docs/277-plan-implementation-and-license-compliance-20261028.md`（本地）；
- 清理清单：[278-cleanup-inventory-20261028.md](278-cleanup-inventory-20261028.md)、`docs/audit/cleanup-candidates.csv`；
- 清理执行：2026-10-28 已删除 58,015 个文件、释放约 **1,001 MB**；清单见 `docs/audit/cleanup-execution-20261028*.csv`，结果见 278 §9；
- 代码相似度脚本：`docs/audit/code_similarity.py`；结果：`docs/audit/code-similarity.txt`；
- 支撑报告：`docs/276-full-content-audit-20261028.md`、`docs/audit/D1-D3`（本地）；
- 远端状态：`main=c272e8e1...`，`mod-rebuild-20261027=5886579...`，**本报告/清理均未推送**；
- 本地未推送的审查辅助改动：4 处工具断链修复（`audit-soil`/`audit-bush`/`audit-branch` 的 generator/旧变量名，B `verify-vegetable` 的 manifest/类路径）、文档索引更新，以及本轮清理；**未改 Java、资源或构建配置**。
