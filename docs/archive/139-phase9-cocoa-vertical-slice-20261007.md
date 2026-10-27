# 第 9 步：可可首批加工闭环（2026-10-07）

## 独立设计

本批没有复制示例模组或 Firmalife 的业务代码，只参考已有公开配方接口和本项目已验证的案板、干燥架、石臼状态契约。

第一批只冻结一条可验证的小闭环：

```text
可可树结果的可可荚
    → 案板切开（2 个可可豆）
    → 干燥架（3600 tick，得到干可可豆）
    → 石臼粗磨（6 次敲击，得到可可碎）
```

烘焙、发酵、可可脂和巧克力混合没有提前伪装成已完成内容，留给后续批次。

## A：可可树

- `MyFruitTrees` 新增 `cocoa`，温度范围 18–40°C，生命周期含结果期。
- `MyBranchFruits` 新增第 8 个老茎结果物种 cocoa。
- 新增可可树的方块状态、模型、掉落表、气候数据、食品定义、语言键和项目自有像素贴图。
- 果树台账从 48 个增加到 49 个，叶掉落 modifier 同步增加。

## B：加工内容

- 新增物品：`food/cocoa_beans`、`food/dried_cocoa_beans`、`food/cocoa_nibs`。
- 新增配方：案板切豆、干燥架晒豆、石臼粗磨。
- 三个产物都有独立食品数据、物品模型、贴图和中英文语言键，并加入创造标签页。

## 构建与部署

- A boundary/resource verification：通过。
- B boundary/license check：通过。
- B 覆盖台账：198 项保持一致。
- A/B `clean build`：均成功。
- 当前部署 jar：
  - A：`993D6483A3DD7B965AD9BC05DF7A5A42E0A23C2632538EFECFD8549A759BFFEF`
  - B：`EB5D84D308E3067E5F2DB17BAA86A9EDAC1018BA5003038FD0A09B541B3A0B33`
- 本批备份：`moddev/backups/phase8-fix-phase9-cocoa-20261007/`。

## 后续状态

- 第 10 步已完成新 jar 的隔离世界启动、数据重载和 JEI 回归；详见 `moddev/docs/140-phase10-runtime-regression-20261008.md`。
- 第 11 步已完成烘焙、可可粉和黑巧克力链；详见 `moddev/docs/141-phase11-cocoa-processing-20261008.md`。
- 案板、干燥架和石臼的鼠标交互仍由用户手动验证；封窑继续跳过。
