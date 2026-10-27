# 阶段 2 P0：草莓、可可和汤入口规范化（2026-10-10）

## 本批目标

本批先解决会造成内容重复、配方入口错误和玩家可见入口冲突的 ID 问题。所有修改前的文件已保存到：

`moddev/backups/defect-remediation-20261010-phase2-preedit/`

## 已完成的修改

### 草莓

- A 的普通草莓作物和野生草莓作物现在都掉落 `tfc:food/strawberry`。
- Firmalife 种植盆桥接也改为产出 `tfc:food/strawberry`。
- `tfcfarmingplus:food/strawberry` 的注册暂时保留用于旧存档兼容，但已从 A 创造页移除；后续 JEI 入口由 B 的可选 JEI 插件隐藏。
- TFC 原版 `tfc:plant/strawberry_bush` 保留注册，只从 TFC berry bush 世界生成标签移除 `tfc:plant/strawberry_bush_patch`，因此只禁止新世界自然生成，不改动原版方块注册和旧存档方块。
- TFC Patchouli 英文和中文的野生水果条目覆盖文件已生成，删除草莓灌木页面、展示方块和对应配方映射；原版其他水果内容保留。

### 可可

- 当前项目认定的“大花可可树”是 A 的 `cupuacu` 树。
- `cupuacu` 枝干和树叶采收现在从运行时注册表解析并产出 `firmalife:food/cocoa_beans`。
- 旧 `cocoa` 树注册名保留，但其生命周期不再进入结果期，也不再作为可可生产入口。
- B 的干燥配方改为对 Firmalife 可可豆添加 `firmalife:dried` 特性，仍使用 B 现有的干燥架配方入口。
- 密封桶发酵保留，输入改为带 `firmalife:dried` 特性的 Firmalife 可可豆，输出仍是 B 的发酵中间物。
- 发酵后的加热产物改为 `firmalife:food/roasted_cocoa_beans`；研磨产物改为 `firmalife:food/cocoa_powder`。
- 删除了旧的切板可可豆复制配方、旧可可碎配方和旧 B 黑巧克力配方，避免一份原料存在两套重复入口；Firmalife 自带后续巧克力流程继续负责官方 ID。
- 旧 B 可可物品注册仍保留作兼容，但不再进入 B 创造页；JEI 中也隐藏已废弃的重复物品。

### 调味汤

- `tfcagricultureplus:foods/seasonable_soups` 改为引用 `#c:foods/soup`，因此包括 TFC 标签中的谷物、果物、蔬菜、蛋白质和乳制汤。
- 调味结果仍复制原汤并添加 `tfcagricultureplus:seasoned` 特性。

## 自动检查

- A `verify.ps1`：通过，资源交叉引用全部有效。
- B `check-boundaries.ps1`：通过。
- B `verify-coverage-ledger.ps1`：通过，201 个外部资源文件与台账一致。
- 新增和修改的 Patchouli、世界生成标签、干燥及发酵 JSON：逐文件解析通过。
- 本批没有进行 Minecraft 实机验证，也没有部署新 jar。
- 已找到 Gradle 8.8 分发包并尝试执行 A `clean build`，但当前沙盒的 Java 运行环境在 Gradle 启动阶段无法加载 `native-platform.dll`；因此 A/B clean build 尚未完成，未生成或部署新 jar。删除资源后的 clean build 仍是下一次可构建环境中的硬门禁。

## 尚未完成的 P0/P1 工作

1. 将 B 的案板、石臼、干燥架方块实体统一改为 TFC 原版公开容器接口，并保留旧存档内容迁移路径。
2. 对 B 干燥架改为直接消费 Firmalife drying recipe API，避免自定义 drying recipe type 与 Firmalife drying mat 形成两套状态机。
3. 完成草莓灌木的 JEI、创造页和 Patchouli 实机确认。
4. 完成 `cupuacu → Firmalife 可可豆 → 干燥特性 → 密封桶发酵` 的实机确认。
5. 将 B 养蚕加入 B 部分开发矩阵，并从设计开始使用 TFC 原版容器接口。

下一批入口是“容器接口重构和旧存档状态迁移设计”，不是继续增加新的食品种类。
