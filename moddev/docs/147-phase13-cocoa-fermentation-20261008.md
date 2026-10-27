# 第 13 步：可可发酵流程（2026-10-08）

## 设计

本批只增加一个中间物和一条公开 TFC 密封桶配方，不新增方块或自定义桶状态。

~~~
可可荚 → 可可豆 → 干可可豆 --(250 mB 水，密封 24000 tick)→ 发酵可可豆
发酵可可豆 --(180°C 加热)→ 烘焙可可豆 → 可可碎 → 可可粉 → 黑巧克力
~~~

- 密封桶输入带 tfc:not_rotten，腐烂的干可可豆不会被消耗。
- 发酵可可豆保留低营养食品数据，便于 TFC 的腐烂判断和加热阶段复制新鲜度；它仍然不是成品用途。
- 烘焙配方改为只接受发酵可可豆，并继续使用 tfc:copy_food 保留食品数据。
- 实机鼠标验收按用户要求暂缓；本批只做 JSON、边界、构建和部署校验。

## 改动文件

- MyItems.java：注册发酵可可豆并加入创造页可可列表。
- recipe/barrel_sealed/ferment_cocoa_beans.json：密封桶发酵配方。
- recipe/heating/roasted_cocoa_beans.json：加热入口改为发酵可可豆。
- models/item/food/fermented_cocoa_beans.json 与双语语言键：补齐资源闭环。

## 待后续确认

- 用户实机确认密封桶 UI、时间进度和取出行为。
- 若发现平衡问题，再单独调整水量、时长或产量，不与草莓批次混改。

## 构建与部署

- Java 21：Microsoft OpenJDK 21.0.12.1（仅用于本次项目构建）。
- B build：BUILD SUCCESSFUL。
- 边界与许可检查：通过。
- 覆盖台账：198 行与 198 个外部资源一致。
- 可可新增 JSON：解析通过。
- 部署 jar：TFCAgriculturePlus-NeoForge-1.21.1-0.1.0.jar，SHA-256 83DC375783D1A32D92DEE3F8F0E9B9AEFCD356CCD75CCAA235D70F21AF1A74BC。
- 实机客户端与鼠标交互：按用户要求暂缓，封窑跳过。
