# 阶段 1：工具门禁与版本基线

**日期：** 2026-10-10  
**范围：** 全局整改计划阶段 1  
**状态：** 工具修复完成；内容资源仍有明确待修项；未构建、未部署、未进行实机验收。

## 本阶段已完成

1. 修复 A 模组 `verify.ps1` 的 JSON 解析兼容性。
   - PowerShell 7 使用原生 `-AsHashtable -Depth`。
   - Windows PowerShell 5.1 使用递归 `PSCustomObject → Hashtable` 转换。
   - 后续资源检查不再因为不支持 `-AsHashtable` 在入口处中止。
2. 修复 A 模组 `audit-texture-content.ps1` 的绘图库兼容性。
   - 使用运行时可用的 `System.Drawing.Common`，并回退到旧版 `System.Drawing`。
   - 自动加入当前绘图库的引用程序集。
   - 将内嵌 C# 的泛型列表改为 `ArrayList`，兼容当前 PowerShell 运行时。
3. 将 A 模组 `healthcheck.ps1` 的构建/部署一致性检查升级为 SHA-256 比对。
4. 修复 B 模组两个木料堆 blockstate 的空属性键。
   - `log_pile.json` 和 `burning_log_pile.json` 现在覆盖 `axis=x/z` 与 `layers=1..4` 的全部状态组合。

## 实际门禁结果

### A `verify.ps1`

- 模型索引：16,444
- 贴图索引：7,122
- configured feature：936
- placed feature：920
- 已校验 blockstate：481
- 已校验模型：2,073
- 已校验掉落表：481
- 结果：资源交叉引用通过。

### A `healthcheck.ps1`

- 资源交叉引用：通过。
- jar 一致性：通过。
- build jar 与已部署 jar SHA-256 均为：
  `3CA5B82D2072C55601D9FC46E5A7A98787D8E8B5BA3E43A6088FA8AAD5369E31`
- 贴图唯一率：发现 25 组重复贴图，保留为后续视觉审计项。
- 贴图内容：发现 2 张空图和 1 张可疑幼苗图：
  - `textures/block/crop/broccoli_age_0.png`
  - `textures/block/crop/kale_age_0.png`
  - `textures/block/crop/lettuce_age_0.png`（2 个不透明像素）
- 健康检查当前结果：1 项需要处理，原因是空贴图，不是检查器崩溃。

### B 静态门禁

- `check-boundaries.ps1`：通过。
- `verify-coverage-ledger.ps1`：通过，台账 199 行与扫描文件 199 项一致。
- `verify-registry.ps1` 静态模式：当前只能提取字面量注册，循环注册的案板、干燥架、刀架和木料堆会形成大量静态假阳性；后续必须使用启动日志的 runtime 模式或补充循环注册台账，不能把该静态结果当作运行时注册失败。

## 当前依赖基线

| 组件 | 当前记录版本 |
|---|---|
| Minecraft | 1.21.1 |
| NeoForge | 21.1.x，构建时以当前 Gradle 环境为准 |
| TerraFirmaCraft | 4.2.11 |
| Firmalife | 3.0.15 |
| AFC | 2.1.3 |
| TFC Woodworking | 1.2.4 |

依赖的完整 jar 清单和 hash 以当前实际运行目录重新读取为准；本阶段不把历史文档中的旧版本当作 API 依据。

## 未在本阶段处理的内容

- 空贴图暂未自动覆盖。它们已经被工具准确列为失败项，下一批按 TFC 同族视觉标准逐张处理。
- 草莓隐藏、草莓掉落统一、可可 Firmalife ID、调味汤、Firmalife 干燥架和完整容器接口重构尚未开始。
- 没有构建新 jar、没有部署新 jar、没有启动 Minecraft、没有进行封窑实机验证。

## 下一阶段入口

进入阶段 2 前，先补充当前依赖 jar 的可追溯 manifest，然后按以下顺序施工：

1. 草莓注册保留、自然生成关闭、创造/JEI/Patchouli 隐藏、作物和野生草莓掉落改为 `tfc:food/strawberry`。
2. 核对并保留现有大花可可树种植/生长/采收实现，采收结果接 Firmalife 可可豆。
3. 清理重复可可基础物品，保留 B 的发酵流程。
4. 修复调味汤标签和干燥架的公开 API 接入。

