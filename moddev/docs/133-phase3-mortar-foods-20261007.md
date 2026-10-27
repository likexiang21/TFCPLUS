# 133 · 阶段 3 石臼食品研磨小批次交接

日期：2026-10-07

## 本阶段设计决定

本批只做干磨，不引入流体、GUI 或持续 tick。石臼是一格容器，研磨由玩家手持石杵重复敲击完成；`grind_time` 的单位是敲击次数，不是未参与执行的展示字段。

本批原料全部来自 A 已有、可正常获得的食品：

| 原料 | 产物 | 敲击次数 | 食品处理 |
|---|---|---:|---|
| `tfcfarmingplus:food/ginger` | `tfcagricultureplus:food/ground_ginger` | 4 | 用 TFC `updateFoodFromPrevious` 保留原料创建时间 |
| `tfcfarmingplus:food/turmeric` | `tfcagricultureplus:food/ground_turmeric` | 4 | 同上 |
| `tfcfarmingplus:food/black_pepper` | `tfcagricultureplus:food/ground_black_pepper` | 3 | 同上 |

产物有独立 TFC 食品定义，可直接食用，并已加入 B 创造模式页。后续调味链可继续把它们作为原料。

## 实现变化

- 新增 `MortarInteractions`，把放入、取出、研磨、腐烂拒绝、耐久和产出集中到本项目自己的交互流程。
- `MortarBlock` 同时处理空手和持物右键；石杵不再只在空手入口中被识别。
- `MortarBlockEntity` 保存 `grind_progress`，区块重新加载后继续本次研磨；更换或取出原料会清零进度。
- `MortarRecipe` 拒绝腐烂输入；输出使用 `FoodCapability.updateFoodFromPrevious`，没有食品能力的输入使用 `setCreatedNow`。
- 移除旧 `link_test_limestone` 联调配方；原文件保存在阶段备份中，不进入正式 jar。
- 为三个产物增加物品注册、食品数据、模型、语言键。模型复用 A 已有食品纹理作为 B 的显示来源，没有复制示例模组业务代码。
- JEI 石臼分类现在显示“敲击次数”，与 `grind_time` 的实际单位一致。

## 构建检查

- B 边界与许可门禁：通过。
- B `clean assemble`：成功。
- jar 中正式 `mortar` 配方：3 条。
- jar 中对应食品定义：3 条。
- jar 中对应物品模型：3 条。
- 资源 JSON 解析：通过。
- `verify-coverage-ledger.ps1`：通过（198 条台账与资源树一致）。
- `verify-registry.ps1` 静态模式：未作为本批验收依据；它只能提取 5 个字面量注册 ID，会把 Java 循环注册的既有 242 个变体误报为未注册，并提示应使用 `-FromLog`。本轮未启动游戏，未生成可用于新 jar 的运行日志。
- 构建及部署 jar SHA-256：`7750A3A7FABF73F6D2E235444DF7941156C9FC88CEACD7D6254806CD2786883C`。
- 阶段开始前备份：`moddev/backups/phase3-mortar-20261007/`。

## 尚未验收

- 未启动游戏，未验证正常放置石臼、放入原料、连续敲击、输出领取、耐久变化和重新加载后的进度。
- 未验证 JEI 实际显示和客户端配方同步；JEI 分类代码已经存在并会读取新的配方管理器内容。
- 未验证腐烂输入和无配方输入的画面提示。
- 封窑完整玩家操作测试继续由用户自行完成。

## 下一步

阶段 4：从现有作物和食品中选择下一小批案板预处理配方，先核对原料、产物用途、腐烂传递和案板耐久，再实现资源与配方。
