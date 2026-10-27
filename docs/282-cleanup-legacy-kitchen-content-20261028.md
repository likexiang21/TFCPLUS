# 282 清理 B 旧厨房/旧可可内容

> 日期：2026-10-28
> 依据：`docs/archive/204-k3-dough-board-and-kitchen-rework-plan-20261020.md` §2.1/§7/§8，`207` 的旧内容下线决定。
> 用户指令：清理其他标记为旧内容的部分；并更正 B 还负责 TFC 农作物重做（见 280 §11）。

## 1. 已删除的旧内容

### 1.1 旧面团成型系统

- `tfcagricultureplus:dough_forming_table` 方块、BlockItem、BlockEntity、交互；
- `dough` RecipeType、RecipeSerializer；
- `DoughFormingTableBlock`、`DoughFormingTableBlockEntity`、`DoughFormingInteractions`、`DoughRecipe`、`DoughSerializer`；
- blockstate、block/item model、loot table、语言键；
- JEI `dough` 类型、分类类、隐藏 ID；
- 物品能力注册。

### 1.2 旧融化锅

- `tfcagricultureplus:melting_pot` 方块、BlockItem、BlockEntity、交互；
- `melting` RecipeType、RecipeSerializer；
- `MeltingPotBlock`、`MeltingPotBlockEntity`、`MeltingPotInteractions`、`MeltingRecipe`、`MeltingSerializer`；
- blockstate、block/item model、loot table、语言键；
- JEI `melting` 类型、分类类、隐藏 ID；
- 物品能力注册；
- `foods/melting_powders` 标签。

### 1.3 旧通用面团

- `tfcagricultureplus:material/dough` 物品、模型、语言、JEI 隐藏 ID。

### 1.4 旧黄油片与旧整蛋糕

- `tfcagricultureplus:food/butter_slice` 物品、模型、食物数据、语言、创造页、JEI 隐藏 ID；
- 整黄油分餐改为输出 Firmalife 原版 `firmalife:food/butter`；
- `tfcagricultureplus:whole_cake` 方块、BlockItem、blockstate、block/item model、loot table、语言、创造页无入口；
- 旧 `tfcagricultureplus:food/cake_slice` 物品、模型、食物数据、语言、创造页；
- **保留** `textures/item/food/cake_slice.png`：奶油蛋糕/巧克力蛋糕切片模型仍引用它。

### 1.5 旧可可物品

删除以下 B 平行注册及资源：

```text
tfcagricultureplus:food/cocoa_beans
tfcagricultureplus:food/cocoa_nibs
tfcagricultureplus:food/roasted_cocoa_beans
tfcagricultureplus:food/cocoa_powder
tfcagricultureplus:food/dark_chocolate
```

保留：

- `tfcagricultureplus:food/fermented_cocoa_beans`（发酵中间物）；
- Firmalife canonical 配方：
  - `barrel_sealed/ferment_cocoa_beans.json`；
  - `drying/cocoa_beans.json`；
  - `heating/roasted_cocoa_beans.json`；
  - `mortar/cocoa_powder.json`；
- `fermented_cocoa_beans` 的模型贴图改用 `firmalife:item/food/cocoa_beans`，避免依赖已删除的 B 贴图。

## 2. 存档影响

以下旧内容在旧存档中会变成未知方块/物品：

- `dough_forming_table`、`melting_pot`、`whole_cake` 方块；
- `material/dough`、`food/butter_slice`、`food/cake_slice`、5 个旧可可物品。

本轮按用户明确要求硬删除注册，不做旧 ID 迁移。旧存档若仍保留这些内容，加载后会丢失或变成未知 ID。

## 3. 清理后数量

| 项 | 数量 |
|---|---:|
| blockstate | **489** |
| block model | **503** |
| item model | **620** |
| item texture | **52** |
| recipe | **756** |
| loot table | **489** |
| TFC food 定义 | **52** |
| en_us / zh_cn 语言键 | **698 / 698** |

## 4. 构建与验证

- B `gradle build --offline`：**BUILD SUCCESSFUL**；
- `verify-container-contract`：通过；
- `verify-grain-food-processing`：通过；
- `verify-vegetable-beverage-processing`：通过；
- `check-boundaries`：通过；
- 许可证门禁：通过；
- 全资源 JSON 解析：0 失败。

最终 B 产物：

```text
artifacts/TFCAgriculturePlus-NeoForge-1.21.1-0.1.0.jar
1,507,294 bytes
SHA-256 4B38BBE42B9F893372688D2ECC3C10CAA6272896997220EAC62B7C5C3AB92945
```

## 5. 农作物重做更正

原 280 报告遗漏了 B 的 **TFC 29 种作物 + 11 种浆果灌木重做**；已补充到 280 §11：

- 该部分属于 B（`126` A2），不是 A；
- 当前 B 在 `assets/tfc/` 只有 Patchouli 手册，没有作物/浆果覆盖资源或方块实现；
- 当前完成度：**0**；
- 后续应作为独立批次，包含资源覆盖、方块行为、野外生成、标签、掉落、手册、贴图重绘。

## 6. 相关文档

- 旧厨房计划：`docs/archive/204-k3-dough-board-and-kitchen-rework-plan-20261020.md`；
- 旧内容实施记录：`docs/archive/207-k3-dough-board-confirmation-implementation-20261021.md`；
- B 差距报告（含作物重做更正）：`docs/280-b-implementation-gap-vs-tech-docs-20261028.md`。
