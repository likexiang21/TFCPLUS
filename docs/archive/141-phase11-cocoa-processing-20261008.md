# 第 11 步：可可加工链扩展（2026-10-08）

## 新增闭环

```text
可可荚 → 可可豆 → 干可可豆 → 烘焙可可豆 → 可可粉
                                             ↓
                                      可可粉 + 糖
                                             ↓
                                          黑巧克力
```

- 烘焙：TFC `heating`，180°C，拒绝腐烂输入并复制食品信息。
- 粗磨：项目石臼配方，8 次敲击得到可可粉。
- 调制：原版无序合成接口，可可粉与糖得到黑巧克力。

## 交付内容

- 新增食品：`roasted_cocoa_beans`、`cocoa_powder`、`dark_chocolate`。
- 新增配方：heating 1 条、mortar 1 条、crafting 1 条。
- 新增食品数据、物品模型、项目自有贴图和中英文语言键。
- 创造标签页已包含完整可可中间产物与成品。

## 构建、验证与部署

- B boundary/license check：通过。
- 覆盖台账：198 项一致。
- 全部 B JSON：解析通过。
- B `clean build`：成功。
- 当前部署哈希：B `794A46E7F3C07B901C01C09BC55563DC628476C0D5E612611D5453255D216FD9`。
- A 保持第 9 步部署哈希：`993D6483A3DD7B965AD9BC05DF7A5A42E0A23C2632538EFECFD8549A759BFFEF`。
- 备份目录：`moddev/backups/phase10-runtime-phase11-cocoa-20261008/`。

## 验收边界

第 10 步已确认新配方随客户端进入世界并进入 JEI；具体鼠标交互和视觉表现仍需用户手动验收。封窑继续跳过。
