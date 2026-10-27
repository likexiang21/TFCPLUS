# 134 · 阶段 4 案板预处理小批次交接

日期：2026-10-07

## 本阶段设计决定

本批不扩展案板交互代码。沿用现有的一格承载、直接渲染、腐烂拒绝、成功加工扣 1 点耐久和 `ItemStackProvider` 输出流程，只增加确实有后续用途的食品预处理物。

| 原料 | 操作 | 产物 | 数量 | 后续用途 |
|---|---|---|---:|---|
| `tfcfarmingplus:food/ginger` | 切片 | `tfcagricultureplus:food/ginger_slices` | 2 | 调味、汤和沙拉候选原料 |
| `tfcfarmingplus:food/turmeric` | 切片 | `tfcagricultureplus:food/turmeric_slices` | 2 | 调味、汤和沙拉候选原料 |
| `tfcfarmingplus:food/napa_cabbage` | 切丝 | `tfcagricultureplus:food/napa_cabbage_shreds` | 3 | 沙拉和熟食候选原料 |

三条配方都使用 `tfc:copy_food`，会沿用输入食品的腐烂时间信息；`CuttingBoardRecipe.matches` 和交互层继续拒绝腐烂输入。新增食品有独立 TFC food 定义和创造模式入口。

## 文件变化

- `MyItems`：注册 3 个食品物品，并提供案板预处理物品列表。
- `MyCreativeTab`：加入 3 个预处理产物。
- `data/tfcagricultureplus/recipe/cutting_board/`：新增 3 个 JSON 配方。
- `data/tfcagricultureplus/tfc/food/`：新增 3 个食品定义。
- `assets/tfcagricultureplus/models/item/food/`：新增 3 个物品模型，引用 A 已有的对应食品纹理；没有复制示例模组业务代码或第三方代码。
- 中英文语言文件：新增 3 个产物名称。

## 构建检查

- B 边界与许可门禁：通过。
- B `clean assemble`：成功。
- jar 中案板配方总数：15 条，其中本批新增 3 条。
- 本批食品定义：3 条。
- 本批物品模型：3 条。
- 新增资源 JSON 解析：通过。
- 台账与跨命名空间资源：阶段 2 的 198 项核对保持通过。
- 构建及部署 jar SHA-256：`D63BD824718EFC1A5E7BCFD47E2EFB0640E3081CF865B04A59FA22C6CFA5DCE8`。
- 阶段开始前备份：`moddev/backups/phase4-board-foods-20261007/`。

## 尚未验收

- 未启动游戏，未验证三类案板实际放置、直接渲染、切割输出、耐久变化和腐烂提示。
- 未验证 JEI 客户端实际显示和配方同步。
- 未验证新切片/切丝产物进入后续汤、沙拉或调味配方；本阶段只建立候选原料出口。
- `verify-registry.ps1` 静态模式仍受循环注册限制；没有用旧运行日志替代本轮 jar 证据。
- 封窑完整玩家操作测试继续由用户自行完成。

## 下一步

阶段 5：先完成干燥架需求说明，再选择少量已有原料和产物实现持续加工试点，记录计时、装卸、保存恢复、破坏掉落和 JEI 行为。