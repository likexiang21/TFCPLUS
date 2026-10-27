# 阶段 2 P1：TFC 容器接口第一批重构（2026-10-10）

## 本批范围

本批只处理案板、石臼和干燥架的容器层。没有改变配方内容、交互按键或干燥计时规则，也没有声称完成实机验收。

## 已完成

- `CuttingBoardBlockEntity` 改为继承 TFC `InventoryBlockEntity<ItemStackHandler>`，使用 TFC 的 `defaultInventory(1)` 建立单槽库存。
- `MortarBlockEntity` 改为同一套 TFC 单槽库存；研磨进度仍是本项目独立的业务状态。
- `DryingRackBlockEntity` 改为继承 TFC `TickableInventoryBlockEntity<ItemStackHandler>`；干燥进度、完成标志和天气规则仍由本项目维护。
- B 在 `RegisterCapabilitiesEvent` 中为案板、原木案板、刀架、石臼、干燥架注册 `Capabilities.ItemHandler.BLOCK`，自动化访问统一经过 TFC 的 `getSidedInventory`。
- 刀架也已改为 TFC `InventoryBlockEntity<ItemStackHandler>`，四个单件槽位和白名单校验保留。
- 干燥架对 Firmalife 配方优先调用公开 `DryingRecipe.getRecipe(ItemStack)` 和 `FLConfig.SERVER.dryingTicks`；没有 Firmalife 配方时才回退到 B 的旧配方类型。
- 案板耐久字段 `uses_left` 保留；旧版 `on_board` NBT 在库存为空时迁移到槽 0。
- 石臼和干燥架旧版 `content` NBT 在库存为空时迁移到槽 0。
- 新写入由 TFC `InventoryBlockEntity` 统一保存为 `inventory`，不再新增项目自定义物品保存协议。
- 案板、刀架和石臼增加 `onRemove` 掉落兜底，方块被爆炸、活塞替换或其他非玩家路径移除时不会静默吞掉槽内物品；玩家破坏路径仍由 `playerWillDestroy` 处理，二次调用因槽位已清空而不会重复掉落。

## 设计边界

这不是复制 TFC 的业务实现。代码只复用 TFC 公开的库存基类、标准 item capability 和库存回调；案板耐久、石臼研磨次数、干燥天气与配方状态仍由本项目自己的类维护。

## 检查结果

- 已检查案板、石臼、干燥架的交互调用，生产路径改读 TFC 槽位，不再依赖旧的私有物品字段。
- 保留了旧 NBT 迁移分支，避免旧区块中的 `content/on_board` 直接丢失。
- A 静态资源校验、B 边界检查和 B 覆盖台账检查均已通过。
- 本批没有进行 Minecraft 实机测试；新 jar 已准备好交给用户启动客户端验证。
- Gradle 环境已修复：使用工作区 JDK 21、系统完整 Gradle 缓存和离线构建，A/B `clean build` 均成功。
- `gradle.properties` 的构建堆上限统一为 `-Xmx1G`，避免低内存环境启动构建守护进程失败。
- 新 jar 已部署到 `mods`：A SHA-256 `EC7E510BCA2D45BB6EFB8ACBE1D90B939468003701BC2631CFA123C8437250A4`；B SHA-256 `625B43F1112ACFA917E255468FBB72E5712711718DA168545DC7B1154F60F8D8`。

## 下一步

1. 复核案板、石臼和干燥架的自动化插入/取出、爆炸和替换掉落，补齐服务器权威和满背包路径。
2. 逐项清理其余旧项目干燥物品和配方，确认没有重复的 Firmalife 基础物品入口。
3. 为所有接口变更准备实机清单；用户手动验证通过后，才进入蚕架设计。蚕架从第一行代码起使用同一套 TFC 容器接口。
