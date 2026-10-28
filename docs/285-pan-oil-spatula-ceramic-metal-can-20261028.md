# 285 炒锅油路、锻造锅铲、预烧染色陶盘与金属罐

> 日期：2026-10-28
> 对应本轮用户要求：油罐复用 TFC 陶罐、锅铲 5 mB 取油、固态油、锻造锅铲头、无色+16 色预烧陶盘、TFC 木料堆复用、金属罐。

## 1. 已实现

### 1.1 油路

- 单次炒菜用油：**10 mB → 5 mB**，锅内油罐容量 5 mB；
- TFC 陶瓷罐（jug）扩展为可装油：`data/tfc/tags/fluid/usable_in_jug.json` 加入 `#c:plantoil` / `#firmalife:oils`；
- 手持锅铲、副手持陶罐/金属罐时右键锅：从副手容器转移 **5 mB** 油入锅；
- 也可直接用陶罐/金属罐右键锅（兼容原有流体交互）；
- 固态油：手持 `firmalife:food/butter` 右键空油锅，直接进入黄油油状态；
- 不同油会写入菜品 `oil` 字段，并附加对应 TFC food trait：
  - olive_oil / canola_oil / soybean_oil / butter_oil / cooking_oil；
  - 只做表现，不改变营养或保质期。

### 1.2 锅铲

- 木锅铲：2 份 `#tfc:lumber`；
- 金属锅铲：5 种铁类（锻铁/钢/黑钢/蓝钢/红钢）；
- 金属锅铲头由 **TFC anvil 从薄板锻造**：
  - 输入 `#c:sheets/<metal>` → `tfcagricultureplus:spatula_head/<metal>`；
- 锅铲 = 锅铲头 + `#c:rods/wooden`（木棍把手）；
- 旧“金属锭 + 木材”直接合成已移除。

### 1.3 陶盘

- 陶盘改为 **无色 + 16 色**，加木盘共 18 个变体；
- 制作链：
  1. 黏土打制 → 无色未烧陶盘；
  2. 无色未烧陶盘 + 染料 → 对应颜色未烧陶盘（烧前染色）；
  3. TFC `tfc:heating` 烧制 → 对应颜色陶盘；
- 陶盘不再用 TFC 碗转换；染色与烧制流程对齐 TFC 染色陶器。

### 1.4 金属罐

- `tfcagricultureplus:metal_can`，容量 **500 mB**；
- 介于 100 mB 陶瓷罐和 1000 mB 木桶之间；
- TFC `FluidContainerItem` 派生，**不会像陶罐一样损坏**；
- TFC anvil 由 `#c:sheets/wrought_iron` 锻造；
- 可加热熔融回收（`tfc:heating` → `tfc:metal/wrought_iron` 100 mB）；
- 已注册 `Capabilities.FluidHandler.ITEM`。

### 1.5 此前的渲染/容器修正

- 盘子 BER 渲染菜品原料；
- 炒锅 BER 渲染锅内食材；
- 9 个物品容器 BE 实现 `BContainer extends Container`。

## 2. 仍未完成

- **木料堆尚未真正改为复用 TFC `LogPileBlock` / `LogPileBlockEntity`**。当前仍是 B 自有 `TimberPileBlock` + TFC Woodworking 式行为适配；本轮没有做这个替换，不能宣称已完成。
- **仍无实机验证**：工作区缺少 `.tooling` 运行时，无法启动客户端。
- 贴图仍是占位；金属罐纹理暂借 TFC 金属桶纹理。

## 3. 构建

- Gradle clean build：BUILD SUCCESSFUL；
- 静态合同脚本：通过；
- 资源：490 blockstate、521 block model、668 item model、820 recipe、489 loot、51 TFC food、766 语言键；
- JAR：1,601,477 bytes；
- SHA-256：`7148E076166D398854E897EF541D377B4D10F04CFF6B1FC9619B4C50BA62BBAF`。
