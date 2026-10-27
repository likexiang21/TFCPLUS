# 阶段二施工记录：B 设备与木工回归收口（2026-10-17）

## 本轮目标

养蚕箱问题已由用户实机确认解决，施工入口转到计划第二步：在不重新迁移木工内容的前提下，收紧 B 设备的容器契约，并为干燥架八件批量规则补上可重复执行的静态门禁。

## 本轮修改

### 干燥架批量入口统一

文件：

- `src/main/java/com/example/tfcfarmingplus/expansion/common/blockentities/DryingRackBlockEntity.java`

`insertCount` 现在先调用 `canAccept`，因此直接调用、鼠标交互和自动化插入都必须同时满足：

- 输入存在 Firmalife 干燥配方；
- 槽内为空，或物品和组件完全相同；
- 批次总数不超过 8；
- 当前批次尚未完成。

Firmalife 的 `copy_input` 输出会保留整批数量，因此 1 件和 8 件仍共用一个计时并输出对应数量。雨天重置、室内加倍、腐坏拒绝和保存字段没有改变。

### 新增静态门禁

文件：

- `tools/verify-drying-batch.ps1`

门禁检查八件上限、TFC/NeoForge 库存限制、同物品同组件判定、Firmalife 配方组装、鼠标入口、自动化入口和完成后取出条件。

## 已完成的静态检查

- `verify-drying-batch.ps1`：通过。
- `verify-container-contract.ps1`：通过。
- `verify-woodwork-flow.ps1`：通过，34 种 TFC/AFC 木种路线完整。
- `verify-workbench-recipes.ps1`：通过，配方可被 TFC 工作台菜单读取。
- `verify-optional-woodwork-compat.ps1`：通过，原 TFC Woodworking 可选。
- `verify-silkworm-chain.ps1`、`verify-silkworm-lifecycle.ps1`：通过。

## 构建与部署证据

- B 边界门禁、容器契约、木工流程、工作台配方、可选 TFC Woodworking 兼容、养蚕链和干燥架批量门禁均通过。
- 离线 Gradle `build` 成功；编译仅保留既有弃用 API 提示。
- 构建 JAR 与 `mods` 部署 JAR SHA-256 均为 `0FABE63EE9B425FBDE241EBECE23184638C399F24C9B5A72AE18C98FC67AF88D`。
- 部署前备份：`moddev/backups/c9-phase2-drying-contract-20261017-predeploy/`。

## 尚未宣称完成的项目

- 本轮尚未进行 Minecraft 实机测试；干燥架八件批量、混入不同物品、自动化余数和木工无原模组回归仍需用户实机确认。
- 封窑完整点火、封存、等待和取炭操作继续由用户手动验证。
- 离线构建已成功，部署哈希已在本记录的“构建与部署证据”中补录；这些证据仍不等同于 Minecraft 实机通过。

## 下一入口

构建成功后，用户优先验证干燥架 1 件/8 件同计时、不同物品拒绝和自动化插入取出，再验证移除 TFC Woodworking 后 B 木工 JEI 与完整路线。
