# B-1：木料堆容量整理与纵向续堆第三批交接

**日期：** 2026-10-13  
**状态：** 源码修改完成，B clean build 完成并部署；尚未进行无 TFC Woodworking 环境下的实机验收。

## 本批完成内容

- 木料堆的库存改用 TFC 的 `InventoryItemHandler` 容器接口，手动交互和能力管线共用同一套槽位校验。
- 每个槽位按物品体积计算容量：整木占 4 单位、半木占 2 单位、四分木占 1 单位；一个木料堆最多容纳 16 个单位，并且一个堆内只允许同一种木料。
- 同类木料放入木料堆后会按纵向列自动整理：低处优先填满，空槽和空的上层木料堆会被清理，超过容量的部分会作为掉落物保留。
- 从顶部取出或向上方木料堆继续放入时，列整理会再次执行，避免物品留在中间空层。
- 普通木料堆的显示层数继续使用 1～16 层；燃烧木料堆渲染直接读取同一层数，避免燃烧显示与库存数量产生偏差。
- 保留旧存档的 1～4 层状态读取能力，并兼容已有木料堆方块实体数据。

## 修改位置

- `moddev/tfcagricultureplus/src/main/java/com/example/tfcfarmingplus/expansion/common/timber/TimberPileBlockEntity.java`
- `moddev/tfcagricultureplus/src/main/java/com/example/tfcfarmingplus/expansion/client/TimberPileRenderer.java`
- `moddev/tfcagricultureplus/src/main/java/com/example/tfcfarmingplus/expansion/common/timber/TimberPileBlock.java`
- `moddev/tfcagricultureplus/src/main/resources/assets/tfcagricultureplus/blockstates/log_pile.json`
- `moddev/tfcagricultureplus/src/main/resources/assets/tfcagricultureplus/blockstates/burning_log_pile.json`

## 构建与静态检查

- B `clean build --offline`：成功；仅保留既有 JEI API 弃用警告。
- B 覆盖台账：201/201，通过。
- B 配方资源 JSON：508 个文件全部可解析，`bad=0`。
- 普通与燃烧木料堆状态资源均保留两个轴向、每轴 16 个层数变体。
- 构建 JAR 与 `mods` 部署 JAR SHA-256：`3FA3759FBCB295B9C360987B1EB1E3C0BCC8D3D9B9121A60596BB12AE35DC31E`。

## 尚未完成的验证与后续

- 本批尚未启动 Minecraft 实机验证；需要在不加载 TFC Woodworking 的配置下检查放入、取出、跨堆整理、满容量掉落、燃烧显示和存档重载。
- 木工斧头的 mixin 等价行为、工具冷却和随机耐久损耗仍属于后续 B-2 工作。
- 当前 `mods` 目录中的 B 包已更新；TFC Woodworking 原包仍可能存在于测试环境，实机验收时应确认配方和物品来源均来自 B 自有命名空间。
