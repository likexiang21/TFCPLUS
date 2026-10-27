# K3 面团成型与可放置整派垂直切片（2026-10-18）

## 本轮目标

本轮继续 K3，先把“面粉 → 面团 → 整派 → 分餐”做成可独立验证的第一条厨具链。实机验证按当前计划暂缓，施工完成后由后续统一验收。

## 已完成

1. 新增 `tfcagricultureplus:dough` 配方类型和序列化器。
2. 新增面团成型台 `dough_forming_table`。它使用 TFC `InventoryBlockEntity<ItemStackHandler>`，输入槽和输出槽均保存、同步并支持自动化能力；鼠标流程为放入面粉、空手成型、空手取出面团。
3. 面粉入口使用 `c:foods/flour`，因此 TFC 和 Firmalife 已注册的面粉都可以接入，不重新声明或复制原版面粉。
4. 新增独立中间物 `material/dough`，由成型台输出，并通过 TFC 食品能力传递输入的新鲜度。
5. 新增 `whole_pie` 可放置整派方块和 `placeable_food` TFC 方块实体。整派的剩余份数存储在方块实体，不写入 blockstate；空手右键取出一份 `food/pie_slice`，剩余份数归零后移除方块，拆除时按剩余份数掉落切片，避免丢失食物数量。
6. 新增整派合成配方：面团、甜味剂和水果标签组成整派。该配方使用原版 shaped recipe，JEI 可显示从面粉到面团再到整派的链条。
7. 新增面团 JEI 分类和成型台催化剂；新增中英文名称、提示、方块状态、模型和物品模型。

## 约束复核

- 没有复制示例模组业务代码；配方、方块实体和交互均按本项目已有 TFC 容器基线独立实现。
- 面团台和整派都注册了 TFC 方块实体与物品能力，库存和剩余份数不放入 blockstate。
- 没有启动 Minecraft，也没有宣称 JEI、鼠标交互、保存/读档或破坏掉落已经通过实机验证。

## 静态验证

- B 边界、工作台、容器、养蚕、木工、世界内配方、厨具台账门禁：通过。
- 资源 JSON：2805 个，解析失败 0 个。
- `compileJava`：通过；保留项目原有 JEI `getIngredientVisibility()` 弃用警告。
- 完整离线 `build`：通过。

## 部署

- 部署包：[TFCAgriculturePlus-NeoForge-1.21.1-0.1.0.jar](../../mods/TFCAgriculturePlus-NeoForge-1.21.1-0.1.0.jar)
- SHA-256：`54A410E80ECFDB42C70C1A6551B5B8F32C4D76ED69D7F39A07850D0BDD500CE2`
- 最终部署前备份：`moddev/backups/k3-dough-pie-finalfix-predeploy-20261018-192049/`

## 后续工作

实机验证时重点检查：成型台放入/成型/取出、面粉标签覆盖、整派放置、8 次分餐、剩余份数保存、拆除掉落、JEI 配方链和 Patchouli 入口。下一轮 K3 再扩展整蛋糕、奶酪块、黄油块和果冻块，并统一切分/取用规则。
