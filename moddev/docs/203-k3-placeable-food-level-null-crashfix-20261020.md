# K3 可放置整黄油放置崩溃修复记录（2026-10-20）

## 1. 用户反馈与报告位置

用户在 PCL 启动的 Minecraft 客户端中尝试放置整黄油时，客户端直接无响应并崩溃。原始报告目录为：

`C:\Users\asus\Desktop\错误报告-2026-10-20_9.39.44\`

本次重点检查了该目录中的 `debug.log`，并以报告中的完整调用链作为修复依据。

## 2. 已确认的根因

崩溃不是黄油配方、模型或 JEI 条目造成的，而是统一可放置食品方块实体在构造阶段提前修改 TFC 物品处理器造成的。

`PlaceableFoodBlockEntity` 原先在构造函数中执行：

```java
inventory.setStackInSlot(0, new ItemStack(wholeItem()));
```

TFC 的 `InventoryBlockEntity` 会在物品处理器内容变化时立即执行同步。方块实体刚由 `newBlockEntity` 创建时还没有附加到世界，随后同步路径调用 `BlockEntity.getLevel().registryAccess()`，因此得到空指针。

报告中的关键调用链为：

```text
ClientboundBlockEntityDataPacket.create
TFCBlockEntity.getUpdatePacket
TFCBlockEntity.sendVanillaUpdatePacket
TFCBlockEntity.markForSync
InventoryBlockEntity.setAndUpdateSlots
InventoryItemHandler.onContentsChanged
ItemStackHandler.setStackInSlot
PlaceableFoodBlockEntity.<init>
PlaceableFoodBlock.newBlockEntity
```

这会影响所有复用该方块实体的可放置整块食品，包括整黄油、整派、整蛋糕、整奶酪、果冻块和糖块。

## 3. 已实施的修复

- 删除构造函数中对 `inventory.setStackInSlot` 的提前写入。
- 保留 TFC `InventoryBlockEntity<ItemStackHandler>` 继承关系、方块实体注册和物品处理器能力接口，符合项目对可放置物品方块必须使用 TFC 容器接口的要求。
- 继续使用方块类型和 `servings` 字段保存食品种类及剩余份数；整块物品不需要重复存入内部槽位。
- 保留取用、拆除掉落、保存和读取逻辑；这些操作均发生在方块实体已附加到世界之后。
- 在源码中加入注释，明确禁止在构造阶段触发 TFC 同步。

## 4. 构建与部署结果

- B 静态边界、木工、养蚕、容器契约和资源检查通过。
- Java 编译通过。
- 完整离线构建通过：`BUILD SUCCESSFUL`。
- 仅保留项目已有的过时 API 提示，没有新增编译错误。
- 修复后的 JAR：
  `moddev/tfcagricultureplus/build/libs/TFCAgriculturePlus-NeoForge-1.21.1-0.1.0.jar`
- SHA-256：`F44124744CC9AA664EE3BBB00983C158A0AF3CFA8747B928424D9BD9E1C12362`
- 已部署到工作区运行目录：
  `mods/TFCAgriculturePlus-NeoForge-1.21.1-0.1.0.jar`
- 已同步到 PCL 短路径测试目录：
  `PCL_TFC/mods/TFCAgriculturePlus-NeoForge-1.21.1-0.1.0.jar`
- 旧 JAR 备份目录：
  `backups/placeable-food-crashfix-20261020-094842/`

## 5. 待用户实机验证

本轮完成了报告定位、代码修复、构建和 JAR 部署，但没有代替用户启动客户端进行实机回归。请优先验证：

1. 在 PCL 中放置整黄油，确认不再崩溃。
2. 空手右键整黄油，确认每次取出一份黄油切片。
3. 放置整派、整蛋糕、整奶酪、果冻块和糖块，确认它们也不会触发同类崩溃。
4. 拆除尚有余量的可放置食品，确认剩余切片正常掉落。
5. 保存并重新进入世界，确认份数仍然正确。

如果仍然出现崩溃，请提供新的 `debug.log` 中从 `FATAL` 开始的完整调用链，以便判断是否存在另一条放置路径。
