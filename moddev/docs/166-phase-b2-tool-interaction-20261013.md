# B-2：木工工具交互规则交接

**日期：** 2026-10-13  
**状态：** 源码修改完成，B clean build 完成并部署；尚未进行 Minecraft 实机验收。

## 本批完成内容

- B 的世界木工配方处理器增加工具冷却检查；冷却中的对应工具不会再次占用交互。
- 成功处理后按 TFC Woodworking 的规则计算随机耐久损耗：工具总耐久越高，单次处理消耗概率越低；创造模式不损耗。
- 按 TFC `LevelTier` 等级设置工具冷却：等级 0～6 对应 35、25、20、15、10、5、5 tick，并同步给对应工具标签中的可用工具。
- 成功处理后播放主手挥动动作，保留 B 自有声音、状态替换和产物投放流程。
- 增加五方向完整支撑检查，避免木工配方在被结构包围的方块上误触发；下方支撑不参与这项检查，保持原木正常放置后的处理路径。
- 所有逻辑仍由 B 的 `InWorldRecipeHandler`、B 自有配方和 B 自有注册 ID 执行，没有加入 TFC Woodworking 运行时类或依赖。

## 修改位置

- `moddev/tfcagricultureplus/src/main/java/com/example/tfcfarmingplus/expansion/common/recipe/inworld/InWorldRecipeHandler.java`

## 构建与静态检查

- B 边界和许可证门禁：通过。
- B `clean build --offline`：成功；仅保留既有 JEI API 弃用警告。
- B 覆盖台账：201/201，通过。
- B 配方资源 JSON：508 个文件全部可解析，`bad=0`。
- 构建 JAR 与 `mods` 部署 JAR SHA-256：`2F53A13C8E45ABD420E7D00D142C7CE28C7D2EEBF6265B973ABD1A90C43848FC`。

## 待实机确认

- 木料去皮、去树皮、劈木、锯木时的耐久变化和冷却时长。
- 被墙体或其他完整方块包围时是否正确拒绝处理；普通地面放置的原木是否仍可正常处理。
- 创造模式、工具损坏、切换同类工具和快速连续点击时的交互占用。
