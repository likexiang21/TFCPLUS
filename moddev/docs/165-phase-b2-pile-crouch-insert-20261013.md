# B-2：木料堆潜行连续放入交接

**日期：** 2026-10-13  
**状态：** 源码修改完成，B clean build 完成并部署；尚未进行 Minecraft 实机验收。

## 本批完成内容

- 在 B 自有 `TimberPileBlock` 中补齐 TFC Woodworking 的潜行右键木料堆行为。
- 普通右键继续放入一件同类木料；潜行右键会持续消耗手中同类木料，先填充当前木料堆，再按容量规则向上创建并填充新的木料堆。
- 插入过程每轮重新定位纵向列目标，并复用 `TimberPileBlockEntity` 的 TFC `InventoryItemHandler`、木料体积限制和列整理逻辑。
- 超过 64 层纵向保护范围、未加载区块或无法继续插入时安全停止；已插入物品不会被重复扣除。
- 保留点燃木料堆的打火石和火焰弹交互，连续放入只作用于带有 B 木料标签的物品。

## 修改位置

- `moddev/tfcagricultureplus/src/main/java/com/example/tfcfarmingplus/expansion/common/timber/TimberPileBlock.java`
- 交互所使用的容量、整理和同步实现位于 `TimberPileBlockEntity.java`，详见 [docs/164](164-phase-b1-pile-settling-20261013.md)。

## 构建与静态检查

- B 边界和许可证门禁：通过。
- B `clean build --offline`：成功；仅保留既有 JEI API 弃用警告。
- B 覆盖台账：201/201，通过。
- B 配方资源 JSON：508 个文件全部可解析，`bad=0`。
- 构建 JAR 与 `mods` 部署 JAR SHA-256：`6A4DA2C5AD9434C4F7DAC3F0A9536304A3C24D240A0F6FA0701CDE57159A870E`。

## 后续待验收与开发

- 需要实机检查普通右键、潜行右键、跨堆填充、满列停止、创造模式和手中物品数量变化。
- 木料堆真实模型显示、破坏掉落、存档重载以及无 TFC Woodworking 环境加载仍未由本批标记为完成。
- 后续继续处理木工工具交互细节，并统一工作台、木料堆和其他可放置方块的自动化插入/取出审计。
