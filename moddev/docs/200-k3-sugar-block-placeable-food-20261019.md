# K3 糖块与统一可放置食品切片（2026-10-19）

## 本轮目标

继续 K3，补齐总设计中的糖块内容，并把原版甜味剂接入统一可放置食品接口。

## 已完成

1. 新增 `sugar_block` 方块和 `food/sugar_piece` 食品小份。
2. 新增配方：4 个带有 `tfc:foods/sweeteners` 标签的原版甜味剂合成 1 个糖块；不复制或重注册 TFC/Firmalife 的甜味剂。
3. 糖块使用统一 `PlaceableFoodBlockEntity`，保存 8 份余量；空手右键逐份取出糖块小份，拆除时掉落剩余小份。
4. 新增 TFC 食品数据、方块状态、方块/物品模型、中文/英文语言、创造栏入口和 Patchouli 中英文手册页。
5. 将糖块加入 `PLACEABLE_FOOD` 有效方块列表，继续使用 TFC `InventoryBlockEntity<ItemStackHandler>` 容器契约。

## 约束复核

- 没有复制 Firmalife、TFC 或示例模组代码；只复用原版甜味剂标签作为配方输入。
- 糖块与整派、整蛋糕、整奶酪、黄油块、果冻块共用 TFC 方块实体注册、能力、保存和破坏掉落路径。
- 本轮没有启动 Minecraft；甜味剂标签实际匹配、糖块配方、放置、8 次分餐、保存/读档、拆除掉落、JEI 和手册仍待实机验证。

## 静态验证

- B 边界、工作台、容器、养蚕、木工、世界内配方、厨具台账门禁：通过。
- 资源 JSON：2840 个，解析失败 0 个。
- 完整离线 `build`：通过；仅保留项目已有 JEI 弃用警告。

## 部署

- 部署包：[TFCAgriculturePlus-NeoForge-1.21.1-0.1.0.jar](../../mods/TFCAgriculturePlus-NeoForge-1.21.1-0.1.0.jar)
- SHA-256：`213F657F391EB52D16473B61FD946C4639CE6CF608A7C2B0D1E492ED0E9546D9`
- 部署前备份：`moddev/backups/k3-sugar-block-20261019-121052/`

## 后续工作

K3 可放置食品现在覆盖整派、整蛋糕、整奶酪、黄油块、果冻块和糖块。下一步应生成统一 K3 实机验证清单，并重点检查 `tfc:foods/sweeteners` 与 `tfc:foods/jam` 在当前 Firmalife 组合下的 JEI 展示和配方匹配。
