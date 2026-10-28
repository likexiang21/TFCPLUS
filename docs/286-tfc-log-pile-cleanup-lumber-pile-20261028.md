# 286 清理 B 木料堆、半/四分原木并入 TFC 原木堆、新增木板堆

> 日期：2026-10-28
> 用户要求：清理 B 自有木料堆；四分/二分原木直接进 TFC 原木堆；另做木板（lumber）堆砌方块，一方块一组，带模型。

## 1. 删除 B 自有木料堆

以下内容已删除，不再注册：

- `TimberPileBlock`
- `TimberPileBlockEntity`
- `BurningTimberPileBlockEntity`
- `TimberPileBlockEntityRenderer`
- `tfcagricultureplus:log_pile` / `burning_log_pile` 方块与 BE
- 对应 blockstate、模型、掉落表、B 的 `log_pile_logs` 标签
- `DebugValidation` 中依赖旧木料堆的测试代码

保留的是 B 的木材**分块**：

```text
tfcagricultureplus:debarked_log/<wood>
tfcagricultureplus:debarked_half/<wood>
tfcagricultureplus:debarked_quarter/<wood>
```

## 2. 半原木/四分原木直接进入 TFC 原木堆

新增数据标签：

```text
data/tfc/tags/item/log_pile_logs.json
```

把 B 的：

```text
tfcagricultureplus:debarked_half/<wood>
tfcagricultureplus:debarked_quarter/<wood>
```

加入 TFC 的 `tfc:log_pile_logs` 标签。

因此：

- 不再需要 B 自己的木料堆；
- 半原木/四分原木可以直接右键放进 **TFC 原版 `tfc:log_pile`**；
- 由 TFC 的 `LogPileBlock` / `LogPileBlockEntity` 负责插入、取出、叠高和燃烧逻辑；
- 没有新增“半原木专用木堆”这类内容。

## 3. 新增木板堆 `lumber_pile`

新增方块：

```text
tfcagricultureplus:lumber_pile
```

规则：

- **1 个方块可存放 1 组（64 个）TFC 木板**；
- 右键放入手持木板，空手右键取出；
- 潜行右键一次放入/取出一组；
- 状态 `axis` + `count`：
  - `count` 1–16；
  - 每 4 个木板对应 1 层模型，共 16 层；
- 使用烘焙方块模型显示堆叠层数，不是 BER；
- 打掉方块会掉落内部木板 + 木板堆方块物品；
- 方块实体实现 `BContainer`，同时暴露原版 `Container` 和 NeoForge 物品能力；
- 方块物品配方：4 个 `#tfc:lumber` → 1 个空木板堆方块；
- 方块物品、创造栏、语言、模型、blockstate、掉落表均已补齐。

## 4. 验证

- Gradle clean build：**BUILD SUCCESSFUL**
- `verify_pan_system.py`：通过
- 容器契约、粮食、蔬菜、边界、许可证静态门禁：通过
- 全资源 JSON：0 解析失败
- 资源统计：489 blockstate、536 block model、687 item model、857 recipe、488 loot、51 TFC food、784 语言键

## 5. 产物

```text
artifacts/TFCAgriculturePlus-NeoForge-1.21.1-0.1.0.jar
1,602,662 bytes
SHA-256 D136ADB90BC68FD2A0119BC552DD57A8EB289B08C3ED311AB36C479C99C3A15B
```

## 6. 仍未做

- 没有 Minecraft 实机验证（当前环境缺少 `.tooling` 运行时）；
- 木板堆纹理使用 TFC 橡木木板占位，未按木材变体区分；
- 木板堆配方（4 木板换空容器）是临时方案，可按需要改成其他造价。
