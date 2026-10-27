# B-3 / B-4：工作台与容器契约门禁交接

**日期：** 2026-10-13  
**状态：** 契约审计和门禁完成，B clean build 完成并部署；尚未进行 Minecraft 实机验收。

## 工作台契约

- 核对 B 自有木工工作台配方共 69 条：68 条 `minecraft:crafting_shaped`，1 条 `tfc:advanced_shapeless_crafting`。
- 所有配方都属于 TFC `TFCWorkbenchContainer` 继承的 `CraftingMenu` 可检索范围，没有自定义配方类型，也没有 `tfcwoodwork:` 运行时 ID。
- 所有有序配方图案均不超过 3×3；高级 TFC 配方没有写入不被其 CODEC 接受的 `category` 或 `group` 字段。
- 工作台有效范围继续由 TFC 的 `#tfc:workbenches` 标签和 8 格距离规则负责；B 不新增替代菜单。
- 新增 `tools/verify-workbench-recipes.ps1`，并接入 `build-local.ps1`，以后配方契约破坏会在编译前停止。

## 容器契约

- 案板、石臼、刀架、干燥架和木料堆均使用 TFC `InventoryBlockEntity` 或 `TickableInventoryBlockEntity` 作为方块实体基类。
- 案板和石臼显式增加空槽/非空物品校验；自动化插入与鼠标放入共用 TFC `InventoryItemHandler` 的合法性回调。
- 干燥架继续保留 8 个相同物品共用一个计时器的自动化视图；完成前禁止自动化取出，完成后才允许输出。
- 所有存储型方块均具备槽位容量策略、物品合法性策略、注册表绑定和 `onRemove` 掉落路径。
- 新增 `tools/verify-container-contract.ps1`，并接入 `build-local.ps1`。

## 构建与静态检查

- B 边界和许可证门禁：通过。
- 工作台配方门禁：69 条全部通过。
- 容器契约门禁：全部通过。
- B `clean build --offline`：成功；仅保留既有 JEI API 弃用警告。
- B 覆盖台账：201/201，通过。
- B 配方资源 JSON：508 个文件全部可解析，`bad=0`。
- 构建 JAR 与 `mods` 部署 JAR SHA-256：`52D0FE0BE941C0CD207E35F8F30BCEFFE8C686D0EDF49A034D6FE54D43B1698F`。

## 下一阶段

- 进入 B-5 显示、兼容与构建收尾：统一检查 JEI、创造页、Patchouli、独立实例边界和重复配方显示。
- 继续保留实机验证清单，不能把静态门禁结果代替用户在 Minecraft 中的最终验收。
