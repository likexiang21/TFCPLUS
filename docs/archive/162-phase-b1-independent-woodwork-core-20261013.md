# B-1：独立木工核心迁移首批交接

**日期：** 2026-10-13  
**状态：** 首批源码与资源迁移完成，B clean build 完成并部署；完整木料堆投掷实体、原版斧头 mixin 等行为仍在后续批次施工。

## 本批完成内容

- 从当前 `tfcwoodwork-1.21.1-1.2.4.jar` 核对 MIT 许可、240 条 `in_world` 配方、41 条工作台配方、燃料、食物、标签和掉落资源。
- 新增 B 自有树皮、韧皮、锯末、锯末汤、锯末面团和锯末面包注册；不再需要 `tfcwoodwork` 注册 ID。
- 新增 B 自有木工声音事件和声音资源。
- 将 240 条世界内木工配方转换到 B 的 `in_world` 协议，并扩展为 TFC 20 种木材和 AFC 14 种木材，共 408 条配方。
- 将 41 条工作台配方迁移到 B 命名空间，并为 AFC 木材生成对应配方；配方仍使用 `minecraft:crafting_*` 或 TFC advanced crafting 类型，可以由 TFC 工作台检索。
- 迁移 180 条 TFC 原版木工配方禁用覆盖，避免没有 TFC Woodworking 时出现原版木工配方并行。
- 迁移 B 自有燃料、食物、标签和木料掉落资源；B 的木料堆标签现覆盖 TFC 20 种和 AFC 14 种木材。
- 修改资源生成器，使以后生成木料模型时不再要求安装 TFC Woodworking JAR；模板改为读取 B 自有模板。
- TFC 木料去皮配方由 B 的 `in_world` 事件处理器接管，B 不在 Gradle 或 `mods.toml` 中依赖 TFC Woodworking。

## 本批验证

- B 边界和许可证门禁：通过。
- 迁移配方 JSON 解析检查：408 条世界内配方、69 条工作台配方和 180 条 TFC 禁用文件全部可解析。
- B 覆盖台账：201/201，通过。
- B `clean build --offline`：成功。
- 编译输出仅有既有 JEI `getIngredientVisibility()` 弃用警告。
- B 构建 JAR 与 `mods` 部署 JAR SHA-256：`BA344B6F33BE1466E453E9CAFEFDA5B7FEA7669DE0E8FE8E25A4C78744A68587`。

## 回滚与来源

- 迁移前源码和资源备份：`moddev/backups/phase-b-woodwork-migration-preedit-20261013/`。
- 迁移前 B JAR 备份：同一目录下的 `TFCAgriculturePlus-NeoForge-1.21.1-0.1.0.jar`。
- TFC Woodworking 反编译审计快照：`moddev/backups/tfcwoodwork-1.2.4-decompiled/`。
- MIT 许可和来源说明保留在 B 的 `META-INF/licenses`。

## 尚未声称完成的项目

- TFC Woodworking 的 `SHOOT_AS_BLOCK` 专用木料投掷实体及落地堆叠视觉。
- TFC Woodworking 的斧头 mixin 等价行为、工具冷却和随机耐久损耗细节。
- 木料堆自动向上吸入、自动分散和 TFC Woodworking 的 `COUNT_1_16` 可见层数模型。
- 不安装 TFC Woodworking 的独立实例 L3/L4 启动和用户实机验收。

下一批继续迁移木料堆实体行为和工具交互，再做无 TFC Woodworking 环境的启动验证。
