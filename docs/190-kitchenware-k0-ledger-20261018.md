# K0 厨具台账与接口冻结记录（2026-10-18）

## 目标

本记录是额外厨具系统的施工入口。K0 只冻结注册、容器、配方和资源边界，不改变当前游戏功能；K1 才开始新增厨房骨架方块。

## 现有 B 容器基线

| 系统 | 当前注册范围 | 当前方块实体 | 接口状态 |
|---|---:|---|---|
| 木制案板 | 34 木材 | `CuttingBoardBlockEntity` | TFC `InventoryBlockEntity` |
| 石制案板 | 21 岩石 | `CuttingBoardBlockEntity` | TFC `InventoryBlockEntity` |
| 原木案板 | 34 木材 | `CuttingBoardBlockEntity` | TFC `InventoryBlockEntity` |
| 刀具架 | 34 木材 | `KnifeBlockBlockEntity` | TFC `InventoryBlockEntity` |
| 石臼 | 15 岩石 | `MortarBlockEntity` | TFC `InventoryBlockEntity` |
| 干燥架 | 34 木材 | `DryingRackBlockEntity` | TFC `TickableInventoryBlockEntity` |
| 养蚕箱 | 1 | `SilkwormRackBlockEntity` | TFC `TickableInventoryBlockEntity` |
| 木料堆/闷烧木料堆 | 1 + 1 | `TimberPileBlockEntity` / `BurningTimberPileBlockEntity` | TFC 库存或日历计时基类 |

## K1 厨房骨架注册台账

以下名称为 B 自有命名空间的计划 ID；六类首批家具已进入 K1 实现，其余保留后续批次：

| 计划 ID | 类型 | 材质展开 | 容器/交互 | 状态 |
|---|---|---|---|---|
| `counter_cabinet` | 橱柜台面 | 34 木材 | 9 格储物 + 台面预留 | K1 已实现 |
| `half_cabinet` | 半高柜 | 34 木材 | 9 格储物 | K1 已实现 |
| `sink_cabinet` | 水槽柜 | 34 木材 | 9 格储物 + 清洗预留 | K1 已实现 |
| `spice_rack` | 香料架 | 34 木材 | 9 格储物与展示预留 | K1 已实现 |
| `food_display` | 食品展示柜 | 34 木材 | 9 格储物与展示预留 | K1 已实现 |
| `fruit_bowl` | 果盘/糖果碗 | 34 木材 | 9 格储物与分餐预留 | K1 已实现 |
| `jar_display` | 罐展示架 | 单例 | 罐装食品展示 | 待开发 |
| `picnic_basket` | 野餐篮 | 单例 | 可移动储物 | 待开发 |
| `chocolate_box` | 巧克力盒 | 单例 | 巧克力储物 | 待开发 |
| `fondue` | 巧克力火锅 | 4 个状态/单例机制 | 蘸食与分餐 | 待开发 |

木材材质使用 `MyBlocks.TFC_WOODS + AFC_WOODS` 的 34 项清单；需要石材台面时使用 `MyBlocks.TFC_ROCKS` 的 21 项清单。库存、食品份数、保鲜和加工进度都放入方块实体，不放入方块状态。

## K2/K3 设备与可放置食品台账

| 批次 | 内容 | 设计入口 |
|---|---|---|
| K2 | 蒸发浓缩器、面团成型台、熔化锅、炒锅、`in_world` | 独立方块实体或配方类型；优先复用 TFC/Firmalife 容器 |
| K2 | 整派、整蛋糕、奶酪块、黄油块、糖块、果冻块 | 统一可切分食品方块实体 |
| K3 | 熟成架、保冷设施、油料压榨机、研钵、大餐方块、漏斗/龙头 | 在 K1/K2 容器契约稳定后开发 |
| K3 | 腌渍坛、挂晒串、野餐篮、巧克力盒、巧克力火锅 | 可放置食品与摆盘链 |

## 接口冻结规则

1. 所有储物或可放置物品的方块必须使用 TFC `InventoryBlockEntity` 或 `TickableInventoryBlockEntity`。
2. 自动化统一通过 TFC/NeoForge 物品能力访问，手动交互和自动化插入共用同一项物品校验。
3. 破坏、爆炸、活塞替换、区块重载和菜单关闭都必须保留或掉落内容物。
4. 方块状态只保存朝向、开合、展示状态等视觉状态；不得保存库存、进度、食品组件或保鲜时间。
5. 新配方必须在台账中写明真实输入、输出、容器返还、工具耐久、腐坏判定和用途。
6. Extra Delight、Firmalife 和其它模组只提供玩法与公开接口参考，不复制其代码、JSON、模型或贴图。

## K0 / K1 出口

- 现有 8 类 B 容器基线已登记。
- K1 厨房骨架计划 ID、材质展开和接口已冻结。
- K2/K3 设备与可放置食品已分批登记。
- 静态门禁 `verify-kitchenware-ledger.ps1`、B 现有容器门禁和资源解析均通过；K1 已完成离线构建并部署。
- K1 JAR（含 204 条合成配方和 Patchouli 入口）SHA-256：`A6B3AC469612F8A32BFFA22A746248AACB5A153392DC48F4791D9C4E37F5E605`；本轮部署前备份：`moddev/backups/k1-recipes-patchouli-20261018-predeploy/`。
- 下一步先做 K1 实机验证，再进入 K2 炒锅与调味垂直切片。
