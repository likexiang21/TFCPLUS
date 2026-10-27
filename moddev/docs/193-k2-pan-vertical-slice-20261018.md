# K2 炒锅与调味垂直切片施工记录（2026-10-18）

## 施工范围

本批按厨具计划完成第一条独立烹饪链：

`TFC 汤（pan_inputs） + 研磨香料（ground_spices） → 炒锅状态机 → 炒制调味蔬菜`

用户要求暂时跳过 Minecraft 实机验证，本记录只确认源码、资源、静态门禁和离线构建。

## 已完成内容

### 1. 炒锅方块与 TFC 容器契约

- 新增 `cooking_pan` 方块和方块物品，采用低矮金属形状与独立朝向状态。
- 新增 `CookingPanBlockEntity`，继承 TFC `TickableInventoryBlockEntity`。
- 三个槽位固定为：食物输入、调料输入、熟食输出；库存、计时、翻炒次数和完成状态都保存在方块实体 NBT，不写入 blockstate。
- 方块移除、替换和破坏时统一掉落三个槽位内容。
- 自动化能力使用同一套槽位校验：食物和调料各只能放一份，输出只有完成后才能取出。

### 2. 独立状态机

- 空手右键炒锅会执行一次翻炒。
- 只有食物和调料都存在、并匹配有效配方时才开始计时。
- 当前配方要求三次翻炒和 100 tick 烹饪时间；计时每 20 tick 检查一次，空闲炒锅不轮询。
- 配方完成后复制食物的新鲜度/腐坏状态到输出，并清空两个输入槽。
- 输入腐坏、配方失效或状态不完整时，清除调料、重置进度，保留主食物供玩家取回。
- 区块重载会恢复计时、翻炒次数和完成状态。

### 3. 配方、JEI 和手册

- 新增独立 `tfcagricultureplus:pan` 配方类型和序列化器，提供双输入 Ingredient、输出 ItemStack、烹饪时间和翻炒次数字段。
- 新增配方：`recipe/pan/seasoned_vegetable_pan.json`。
- 新增输入标签：`foods/pan_inputs`，当前包含蔬菜汤、谷物汤和水果汤；调料沿用现有 `foods/ground_spices`。
- 新增输出物品 `food/pan_seasoned_vegetables` 及 TFC 食物数据。
- 新增 JEI 炒锅分类、配方催化剂和双输入展示。
- 中英文 Patchouli 厨房条目已加入炒锅操作、失败处理和 TFC 容器说明。
- 中英文语言已加入方块、输出物品、交互提示和 JEI 文案。

## 静态验证

| 检查 | 结果 |
|---|---|
| B 边界与许可证 | 通过 |
| TFC 容器契约 | 通过 |
| 养蚕生命周期与后处理 | 通过 |
| 独立木工与可选 TFC Woodworking 兼容 | 通过 |
| K0/K1 厨具台账 | 通过 |
| 覆盖台账 | 通过，213/213 |
| 资源 JSON 解析 | 通过，2794 个 |
| `compileJava` | 通过，仅保留原有 JEI 弃用警告 |
| 完整离线 `build` | 通过 |
| JAR 内容检查 | 通过，包含炒锅类、PanRecipe、JEI 分类、方块状态、配方和标签 |

## 构建与部署

- 构建任务：`build --offline --no-daemon --console=plain`。
- 部署文件：`mods/TFCAgriculturePlus-NeoForge-1.21.1-0.1.0.jar`。
- 部署 JAR SHA-256：`9DB90562FD3FCCB722F439499A3A0F9B322325F40D52898C4CDCF2A1B42D2839`。
- 部署前备份：`moddev/backups/k2-pan-vertical-slice-20261018-predeploy/`。

## 尚待实机验证

- 炒锅模型比例、碰撞箱和朝向显示；
- 食物和调料鼠标放入、三次翻炒、计时完成和取出；
- 腐坏输入、错误输入和中途破坏的物品安全性；
- 区块重载后计时恢复；
- JEI 双输入配方、创造栏和 Patchouli 显示；
- 炒锅与 K1 家具、案板、石臼、干燥架同时存在时的联合回归。

本批没有启动 Minecraft，也没有把任何实机项目标记为通过。
