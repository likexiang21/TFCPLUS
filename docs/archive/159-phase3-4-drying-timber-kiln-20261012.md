# 阶段三、四：干燥架、木工与封窑修复交接

**日期：** 2026-10-12  
**状态：** 源码修改完成，A/B clean build 完成，JAR 已部署；L4 实机验收留给用户统一进行。  
**范围：** 用户要求一次完成阶段三和阶段四，暂不替代用户操作 Minecraft 客户端。

## 本批重新遵循的约束

- 重新核对了 `README.md`、`AGENTS.md`、`DEVELOPMENT_RULES.md`、`INBOX.md`、阶段 154～158 记录和《修改建议.txt》。
- 没有直接照抄示例模组业务代码。干燥架只调用 Firmalife 的公开 `DryingRecipe`、`FLConfig.SERVER.dryingTicks` 和 TFC 的公开容器/日历接口；木工只按 TFC Woodworking 的公开配方契约清理冲突入口。
- 能放置物品的方块继续统一使用 TFC `InventoryBlockEntity` / `TickableInventoryBlockEntity` 和标准物品能力。
- 封窑的完整点火、密封、等待和产炭画面验证仍由用户完成，本交接不把它写成已验收。

## 阶段三完成内容

### 1. 干燥架改为 Firmalife 正式配方路径

`DryingRackBlockEntity` 不再执行项目自定义的 `DryingRecipe`。输入、自动化插入和服务端处理都通过 Firmalife `DryingRecipe.getRecipe` 判定，完成时使用 Firmalife 配方的 `assemble` 结果，因此干燥食品、食物组件和 `firmalife:dried` 特性由 Firmalife 正式配方决定。

同时保留旧方块实体字段的读取兼容：旧 `content` 和 `progress` 数据可以迁移到新槽位和开始时间。雨天重置、室内时间加倍、完成后取出、破坏掉落和自动化侧能力均保留在服务端状态机中。

### 2. 移除旧自定义干燥入口

- 删除旧自定义干燥配方类型、序列化器、JEI 分类和三份旧 B 配方 JSON。
- 保留旧干燥物品注册用于旧存档读取，但不再生成新配方，并从 JEI 隐藏。
- `MyItems.allDriedFoods()` 不再把旧自定义干燥物品加入新创造页。
- Firmalife 类型的可可干燥资源继续保留，发酵链不变。

### 3. 案板和石臼状态修正

- 案板交互只在服务端修改方块实体，避免客户端预测造成重复放入、重复输出或耐久不同步。
- 石臼的放入、取出、消耗和每次研磨进度都显式标记同步，仍然使用 TFC 容器接口。

## 阶段四完成内容

### 1. TFC 木工冲突清理

- 删除 140 个针对 TFC 原木的项目自定义 `debark`、锯木、劈木和木料堆 in-world 配方。
- TFC 原木的当前加工入口交由已安装的 TFC Woodworking；AFC 木材的独立加工链保留。
- 更新木料资源生成器，使后续运行不会重新生成 TFC 冲突配方。
- `log_pile_logs` 当前只收录 AFC 自定义木料；TFC 自定义木料方块和物品注册仍保留给旧存档，但不再作为新木料堆入口。

### 2. 旧 TFC 木料入口隐藏

创造页和 JEI 动态隐藏全部 `tfcagricultureplus:debarked_log/*`、`debarked_half/*`、`debarked_quarter/*` 的 TFC 木材兼容物品。AFC 木材和真正可用的木料堆入口仍保留。

### 3. 木料堆接入 TFC 原版容器接口

`TimberPileBlockEntity` 现在继承 TFC `InventoryBlockEntity<ItemStackHandler>`，使用 TFC 的保存、同步、侧面物品能力和槽位回调。B 入口新增 `Capabilities.ItemHandler.BLOCK` 注册，自动化不再依赖项目私有的裸 `ItemStackHandler`。

### 4. 封窑批次逻辑修正

- 点燃任意一段木料堆时，向下找到整列底部，再把整列现有木料堆同步转换为燃烧木料堆；每段保留轴向、层数和四分之一原木质量。
- 燃烧完成时由最上方段作为批次协调者，避免多个方块实体对同一列重复结算。
- 产炭仍按本项目独立的四分之一原木质量公式计算，结果使用 TFC 原版木炭堆方块；没有复制 TFC 或示例模组的业务实现。

## 构建、部署和备份

- A `clean build`：成功。
- B 边界门禁：通过。
- B `verify-coverage-ledger.ps1`：201/201，通过。
- B `clean build --offline`：成功；仅有既有 JEI `getIngredientVisibility()` 弃用警告。
- A 构建并部署 JAR SHA-256：`6012D189BE4A91A5E1060421F7BEE7AB533D67F41B3E58BF39450A58ECAA9C6C`。
- B 构建并部署 JAR SHA-256：`CCD807B9D5438E402C86D4AEE3EE2263EB22AB41797982D466DD9DB8270B1E64`。
- 部署前 JAR 备份：`moddev/backups/defect-remediation-20261012-stage3-4-deploy/`。
- 阶段三删除资源的原始备份：`moddev/backups/defect-remediation-20261012-stage3-preedit/`。
- 阶段四删除木工冲突资源的原始备份：`moddev/backups/defect-remediation-20261012-stage4-preedit/`。

## 用户统一实机验收清单

1. Firmalife 干燥配方：可放入的原料、空槽/满槽、完成后输出、食物特性、雨天重置、室内时间、保存重载、破坏掉落和自动化插入/取出。
2. 案板：客户端不会重复放入或重复输出，配方输出、余料、跨手操作和刀具耐久正确。
3. 石臼：石杵每次敲击只推进一次，进度可同步，完成时消耗原料并产生正确输出。
4. TFC 木工：TFC 原木先去皮再进行 TFC Woodworking 的劈木/锯木流程；项目不再额外显示冲突的 TFC 木料配方。
5. AFC 木材：独立去皮、劈木、锯木和木料堆入口仍可用。
6. 木料堆：多段堆叠后从任意一段点火，整列同步进入燃烧状态；密封成功后只结算一次产炭；漏气时按预期中止。
7. 创造页、JEI 和 Patchouli：旧草莓、旧可可、旧自定义干燥物品和 TFC 兼容木料入口继续按既定隐藏策略处理。

本批只证明源码和构建层面的完成；上述画面、交互、存档兼容和封窑结果须以用户实际进入 Minecraft 后的观察为准。
