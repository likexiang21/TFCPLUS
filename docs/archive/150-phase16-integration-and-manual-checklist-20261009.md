# 第 16 步：跨批次整合与实机验证清单（2026-10-09）

## 自动检查结果

- A 资源交叉引用校验通过：481 个 blockstate、2073 个模型、481 个掉落表、246 个 configured/placed feature、435 个物品模型。
- B 边界与许可检查通过。
- B 覆盖台账通过：199 行与 199 个外部文件一致，邻居标签均为追加式。
- B 第 15 步 jar 已部署，SHA-256 为 `DFB712EA268181C8A05E797967A8B97164184637522822C2A316D46E887C387A`。
- 未执行 Minecraft 实机操作；本文件把待用户手动确认的项目集中列出。

## 手动验证顺序

### A. 启动与加载

1. 启动实例并进入测试存档 `tfctest`。
2. 确认没有 `Unable to load model`、`Missing textures`、`Unknown registry key` 或数据包加载失败。
3. 确认 A、B 两个模组均出现在模组列表中。
4. 进入世界后执行一次资源重载，确认没有新增红色报错。

### B. 第 14 步草莓闭环

5. 获取草莓种子并种植，确认普通作物能够生长。
6. 采收成熟草莓，确认收获物、种子返还和掉落数量符合预期。
7. 放置野生草莓，确认野生植株可加载且外观正常。
8. 将鲜草莓放到干燥架，确认进度、完成状态、取出和食品数据传递正常。

### C. 第 15 步调味入口

9. 在 JEI 中搜索蔬菜汤、姜粉、姜黄粉、黑胡椒粉和调味汤。
10. 用任一种 B 香料粉给蔬菜汤调味，确认配方能够完成。
11. 查看成品 tooltip，确认出现 `Seasoned` / `调味`，并且原汤的营养和新鲜度保持。
12. 再次给已经调味的汤操作，确认不会重复添加 trait 或消耗材料。
13. 使用腐烂汤或腐烂香料粉，确认配方拒绝输入且不会错误消耗。
14. 退出并重新进入世界，确认调味 trait 和食品数据保存。

### D. 已有交互回归

15. 案板：放入原料、使用刀具、取出产物，确认占用、空板、刀具耐久和腐烂输入提示。
16. 石臼：放入香料、使用对应石杵、完成多次敲击，确认进度、产物和石杵耐久。
17. 干燥架：确认空架、进行中、完成、腐烂输入和取出提示。
18. 创造标签页：确认新增草莓、干草莓、香料粉、调味相关物品均可找到。

### E. 旧存档回归

19. 使用旧测试存档副本加载，不要直接覆盖唯一存档。
20. 确认旧世界区块、已有作物、已有容器和旧食品仍可读取。
21. 确认退出重进后没有丢失食品组件、方块实体内容或配方进度。

## 记录方式

每项记录“通过 / 失败 / 未测试”，失败项附截图、日志时间和复现步骤。封窑功能本清单不包含，继续由用户单独处理。

## Minecraft 测试启动路径（清单末尾）

项目启动脚本：
`D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tools\launch-client.ps1`

在 PowerShell 中从项目根目录执行：
`powershell.exe -NoProfile -ExecutionPolicy Bypass -File "D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tools\launch-client.ps1" -QuickPlay "tfctest"`

脚本当前使用的 Minecraft 实例目录：
`D:\111\最强服务器\.minecraft\versions\Essential TerraFirmaCraft (TFC)`

测试结束后关闭本次实例：
`powershell.exe -NoProfile -ExecutionPolicy Bypass -File "D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)\moddev\tools\stop-own-client.ps1"`
