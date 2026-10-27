# K3 果冻块与统一可放置食品切片（2026-10-19）

## 本轮目标

继续 K3，将 Firmalife/TFC 原版果酱接入统一可放置食品接口，形成可放置、可分食、可保存的果冻块。

## 已完成

1. 新增 `jelly_block` 方块和 `food/jelly_slice` 切片物品。
2. 新增配方：4 个带有 `tfc:foods/jam` 标签的原版果酱合成 1 个果冻块；不复制或重注册 Firmalife/TFC 的果酱物品。
3. 果冻块使用统一 `PlaceableFoodBlockEntity`，保存 6 份余量；空手右键逐份取出果冻切片，拆除时掉落剩余切片。
4. 新增 TFC 食品数据、方块状态、方块/物品模型、中文/英文语言、创造栏入口和 Patchouli 中英文手册页。
5. 将果冻块加入 `PLACEABLE_FOOD` 的有效方块列表，继续使用 TFC `InventoryBlockEntity<ItemStackHandler>` 容器契约。

## 约束复核

- 没有复制 Firmalife、TFC 或示例模组代码；只复用原版果酱标签作为配方输入。
- 果冻块与整派、整蛋糕、整奶酪、黄油块共用 TFC 方块实体注册、能力、保存和破坏掉落路径。
- 本轮没有启动 Minecraft；果酱标签实际匹配、果冻块配方、放置、6 次分餐、保存/读档、拆除掉落、JEI 和手册仍待实机验证。

## 静态验证

- B 边界、工作台、容器、养蚕、木工、世界内配方、厨具台账门禁：通过。
- 资源 JSON：2834 个，解析失败 0 个。
- 完整离线 `build`：通过；仅保留项目已有 JEI 弃用警告。

## 部署

- 部署包：[TFCAgriculturePlus-NeoForge-1.21.1-0.1.0.jar](../../mods/TFCAgriculturePlus-NeoForge-1.21.1-0.1.0.jar)
- SHA-256：`AE96142B8456349FC6437AD2A0F389083C3AB16083C9CD96DE307356A76CF502`
- 部署前备份：`moddev/backups/k3-jelly-block-20261019-114119/`

## 后续工作

K3 可放置食品现在覆盖整派、整蛋糕、整奶酪、黄油块和果冻块。下一步应整理统一的 K3 实机验证清单，重点核对 `tfc:foods/jam` 标签在当前 Firmalife 组合下的实际配方匹配，再决定进入新的厨具切片。
