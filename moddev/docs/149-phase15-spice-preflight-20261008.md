# 第 15 步：香料调味入口实现（2026-10-09）

## 已确认

- 姜粉、姜黄粉和黑胡椒粉已有 A/B 产物与石臼配方。
- TFC 公开 FoodTrait 目前包含 salted、brined、pickled、preserved、grilled、wild、canned 等已有语义。
- 当前没有可直接表示“调味/辛香”的公开 trait；把 salted 借作 spicy 会改变食品语义。

## 本步已实现

- B 新增 `MyFoodTraits`，通过 TFC `FoodTraits.KEY` 注册自有 `tfcagricultureplus:seasoned`。
- `seasoned` 的衰减系数为 `1.0`，只作为调味准备标记，不改变原食品衰减速度。
- 新增 `seasoned_vegetable_soup.json`：蔬菜汤 + 任一种 B 香料粉 → 调味汤；使用 `copy_input` 和 `add_trait`，保留原食品营养、新鲜度和食品组件。
- 新增追加式标签 `foods/ground_spices` 与 `foods/seasonable_soups`，不替换 TFC 原标签。
- 新增中英文 FoodTrait 提示文本。

## 验证与交付

- B `build-local.ps1 -Offline`：`BUILD SUCCESSFUL`。
- 新增 JSON 解析通过。
- B 边界与许可检查通过；覆盖台账仍为 199 项。
- 已部署：`mods/TFCAgriculturePlus-NeoForge-1.21.1-0.1.0.jar`。
- SHA-256：`DFB712EA268181C8A05E797967A8B97164184637522822C2A316D46E887C387A`。
- 实机鼠标交互、封窑和视觉验收按用户要求继续暂缓。

## 后续建议

下一批先由用户手动确认调味汤的 JEI 显示、食品 tooltip、重复调味拒绝和腐烂输入拒绝，再决定是否扩展到沙拉或更多香料组合。
