# K1 厨房骨架首批施工记录（2026-10-18）

## 施工目标

在 K0 台账冻结后，先完成六类木制厨房家具的可放置、可存取、可保存和可自动化访问骨架。库存协议统一采用 TFC 的 `InventoryBlockEntity` 与 `BlockEntityContainer`，不把库存、进度或食品数据写入方块状态。

## 已完成内容

- 新增 `KitchenStorageBlockEntity`：9 格 `ItemStackHandler`，保存/同步沿用 TFC 基类，物品验证、槽位上限和破坏掉落集中在一个实现中。
- 新增 `KitchenStorageMenu` 和 `KitchenStorageScreen`：菜单使用 TFC `BlockEntityContainer` 与 `CallbackSlot`，玩家物品栏和快捷栏使用 TFC 菜单布局。
- 新增 `KitchenStorageBlock`：统一处理朝向、形状、右键打开菜单、玩家破坏掉落、替换和爆炸/活塞路径的移除兜底。
- 注册六个家具族：`counter_cabinet`、`half_cabinet`、`sink_cabinet`、`spice_rack`、`food_display`、`fruit_bowl`。每族覆盖 TFC/AFC 共 34 种木材，共 204 个独立方块 ID。
- 注册一个 `kitchen_storage` 方块实体类型和一个 `kitchen_storage` 菜单类型；204 个方块全部写入 `validBlocks`，避免放置时出现 Invalid block entity。
- 补齐六族方块状态、模型、物品模型、英文/中文语言和创造页入口。模型材质引用 TFC 木板贴图，未复制其它模组资源。
- 为 34 种木材和六类家具生成 204 条独立 `minecraft:crafting_shaped` 配方，JEI 可从对应 TFC/AFC 木板追溯到家具；新增中英文 Patchouli 厨房分类与入口。
- 将 `verify-kitchenware-ledger.ps1` 接入 `build-local.ps1`，作为 K1 构建前门禁。

## 静态验收

| 检查 | 结果 |
|---|---|
| K0/K1 台账门禁 | ✅ 通过 |
| B 边界与许可检查 | ✅ 通过 |
| 现有 TFC 容器、养蚕、木工门禁 | ✅ 通过 |
| 资源 JSON 解析 | ✅ 通过，2788 个 |
| K1 合成配方解析 | ✅ 通过，204 条 |
| Patchouli 覆盖台账 | ✅ 通过，213/213 |
| Gradle 离线构建 | ✅ 通过 |

第一次构建尝试受到本机 Gradle daemon 连接问题影响；随后改用工作区 JDK 21、离线依赖和受控构建环境后成功完成 `build`。编译器仅报告现有的 3 个 NeoForge/JEI 弃用警告，没有新增错误。

## 构建与部署证据

- 构建任务：`build --offline --no-daemon --console=plain`；结果：`BUILD SUCCESSFUL`。
- 部署文件：`mods/TFCAgriculturePlus-NeoForge-1.21.1-0.1.0.jar`。
- 部署 SHA-256：`A6B3AC469612F8A32BFFA22A746248AACB5A153392DC48F4791D9C4E37F5E605`。
- 本轮部署前备份：`moddev/backups/k1-recipes-patchouli-20261018-predeploy/`；首轮骨架包备份仍保留在 `moddev/backups/k1-kitchen-skeleton-20261018-predeploy/`。

## 尚待验证

- 无 `tfcwoodwork` 环境下的注册、菜单和 JEI 显示；
- 六类家具的放置、开箱、堆叠、取出、自动化、区块重载和破坏掉落；
- 半高柜、香料架、食品展示柜和果盘的实际模型比例；
- K1 通过后再进入 K2：调料 → 香料架 → 炒锅 → 可放置熟食。

本记录确认静态门禁、离线构建和部署完成；仍不替代用户的 Minecraft 实机验收。
