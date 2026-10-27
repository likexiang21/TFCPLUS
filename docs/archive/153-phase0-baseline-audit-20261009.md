# 第 0 阶段：缺陷整改基线审计记录

**日期：** 2026-10-09  
**状态：** 阶段 0 已完成；尚未修改功能代码，尚未重新构建和部署  
**对应方案：** [`152-defect-remediation-master-plan-20261009.md`](152-defect-remediation-master-plan-20261009.md)

## 一、本阶段完成内容

1. 冻结原有新内容开发，整改范围限定为用户《修改建议.txt》提出的七组问题。
2. 备份 A/B 源码、当前部署 jar 和整改方案。
3. 从当前安装的 TFC、Firmalife、AFC 和 TFC Woodworking jar 中重新核对本轮涉及的真实资源。
4. 确认草莓和可可的两项用户决策：
   - 草莓灌木只禁止新世界自然生成，保留注册 ID 和旧存档兼容。
   - 可可发酵流程保留，原料改用 Firmalife 原版可可豆及其真实干燥结果。
5. 建立本记录和下一阶段使用的 canonical ID 台账。

## 二、备份位置与校验

```text
D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\backups\defect-remediation-20261009-phase0
```

备份内容包括：

- `tfcfarmingplus-src/`：A 源码和资源副本
- `tfcagricultureplus-src/`：B 源码和资源副本
- `TFCFarmingPlus-current.jar`
- `TFCAgriculturePlus-current.jar`
- `152-defect-remediation-master-plan-20261009.md`
- `MANIFEST.json`

当前部署产物基线：

| 文件 | SHA-256 |
|---|---|
| `TFCFarmingPlus-NeoForge-1.21.1-0.1.0.jar` | `3CA5B82D2072C55601D9FC46E5A7A98787D8E8B5BA3E43A6088FA8AAD5369E31` |
| `TFCAgriculturePlus-NeoForge-1.21.1-0.1.0.jar` | `DFB712EA268181C8A05E797967A8B97164184637522822C2A316D46E887C387A` |

## 三、已核对的邻居资源

### 3.1 TFC

- 汤标签：`c:foods/soup`
- 汤物品：
  - `tfc:food/grain_soup`
  - `tfc:food/fruit_soup`
  - `tfc:food/vegetables_soup`
  - `tfc:food/protein_soup`
  - `tfc:food/dairy_soup`
- 原版草莓：`tfc:food/strawberry`
- 原版草莓灌木：`tfc:plant/strawberry_bush`
- 草莓自然生成使用：
  - `tfc:plant/strawberry_bush`
  - `tfc:plant/strawberry_bush_patch`

当前 B 的 `seasonable_soups.json` 使用了不存在的 `tfc:food/vegetable_soup`，下一阶段必须改为真实的 `c:foods/soup`，不能只修拼写而继续维护一个不必要的窄标签。

### 3.2 Firmalife

已确认的可可基础 ID：

- `firmalife:plant/cocoa_sapling`
- `firmalife:plant/cocoa_branch`
- `firmalife:plant/cocoa_leaves`
- `firmalife:food/cocoa_beans`
- `firmalife:food/roasted_cocoa_beans`
- `firmalife:food/cocoa_powder`
- `firmalife:food/cocoa_butter`

已确认的可可配方入口：

- Firmalife 烤箱配方：`firmalife:food/cocoa_beans` → `firmalife:food/roasted_cocoa_beans`
- Firmalife 可可脂配方：使用 `firmalife:food/roasted_cocoa_beans`
- Firmalife 可可 plantable：使用 `firmalife:plant/cocoa_sapling` 和 `firmalife:food/cocoa_beans`

已确认的干燥契约：

- 配方类型：`firmalife:drying`
- 查询入口：`DryingRecipe.getRecipe(ItemStack)`
- 输出语义：`tfc:copy_input` 加 `firmalife:dried` trait
- 计时配置：`FLConfig.SERVER.dryingTicks`

### 3.3 TFC Woodworking

已确认该模组提供 20 种 TFC 木材的分段木工配方，主要类别包括：

- `axe/strip_log/`
- `axe/debark_log/`
- `axe/chop_log/`
- `axe/chop_log_half/`
- `saw/support/`
- `saw/lumber/`

下一阶段只允许在木工整改范围内使用用户明确授权的 TFC Woodworking 代码和现有配方；其他模块仍执行“不得直接照抄示例模组代码”的规则。

## 四、当前项目重复内容清单

### 4.1 A 项目

- `MyItems.java` 仍注册项目自有 `STRAWBERRY`。
- `MyCrops.java` 注册项目普通草莓作物和种子。
- `MyWildCrops.java` 注册项目野生草莓。
- 草莓掉落表仍指向项目自有食品，需要改为 `tfc:food/strawberry`。
- A 仍包含项目自有可可树、可可叶、可可枝和 `tfcfarmingplus:food/cocoa` 资源，需要接回 Firmalife。
- A 仍包含项目自有 `tfcfarmingplus:tfc/food/strawberry.json`，下一阶段删除活跃引用。

### 4.2 B 项目

- `MyItems.java` 仍注册项目自有草莓干和多组可可基础物品。
- 调味配方和 `seasonable_soups` 标签仍依赖错误的汤 ID。
- 干燥架仍依赖项目 `DryingRecipe` 和固定的项目专用干燥物品。
- 木工 `in_world` 目录仍存在与 TFC Woodworking 冲突的 TFC 木种配方。
- `TimberPileBlock`、`BurningTimberPileBlockEntity` 仍是当前封窑状态机的核心，下一阶段需要先做批次模型审计再决定接入 TFC 或独立修复。

## 五、下一阶段施工入口

下一阶段为“阶段 1：canonical ID 和资源引用整理”，施工顺序固定如下：

1. 为草莓、可可、汤、香料、干燥和木工建立逐项保留/删除/改写台账。
2. 先修资源引用和标签，再动 Java 注册和方块实体逻辑。
3. 关闭 `tfc:plant/strawberry_bush` 的新世界自然生成入口，但保留注册和旧存档读取。
4. 将草莓掉落改为 `tfc:food/strawberry`，删除项目草莓食品和草莓干活跃引用。
5. 将可可发酵输入改为 Firmalife 原版 ID，保留发酵中间物和密封桶流程。
6. 阶段 1 结束后才进入调味料和干燥架代码重构。

## 六、阶段门禁

阶段 1 未满足以下条件前，不得进行大规模删除：

- 每个待删除注册项已经完成全局引用搜索。
- 每个待替换输入输出都有已核实的 canonical ID。
- 草莓自然生成的覆盖方式不会注销 `tfc:plant/strawberry_bush`。
- 可可发酵输入、输出和后续 Firmalife 配方链已经画成单向数据流。
- 备份 `MANIFEST.json` 与源目录状态仍可复核。

## 七、2026-10-10 用户目标修订

- 草莓灌木除了关闭自然生成，还必须从创造模式物品栏、JEI 和 Patchouli 手册隐藏；注册 ID 继续保留。
- 可可不再按“删除 A 自有树体”的旧表述执行。种植、树体生长和采收沿用此前制作的“大花可可树”，施工时先核对它在 `MyFruitTrees`/`MyBranchFruits` 中的准确注册 ID。
- 可可的采收结果和后续加工基础物品仍改用 Firmalife 原版 ID；项目发酵流程保留。

后续施工以 `154-global-defect-audit-and-development-plan-20261010.md` 的新口径为准。
