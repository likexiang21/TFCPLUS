# 交接摘要（上下文压缩）

## 项目位置
* 工程：`moddev/tfcfarmingplus/`（ModDevGradle，MC 1.21.1 / NeoForge 21.1.233 / TFC 4.2.10 / Firmalife 3.0.14 / Patchouli 93）
* modId `tfcfarmingplus`，中文名 `TFC农业+`，jar `TFCFarmingPlus-NeoForge-1.21.1-0.1.0.jar`
* 游戏目录：`versions/Essential TerraFirmaCraft (TFC)/`，存档 `saves/tfctest`（用户亲手建的，可用）
* 构建：`gradle.bat build --no-daemon --console=plain`（工程路径含空格/括号，javac 输出是 GBK 乱码，用 Select-String 过滤）
* 启动验证：`moddev/tools/launch-client.ps1 -QuickPlay tfctest`（会自动关独占全屏 + 把窗口最大化）

## 当前状态（已验证）
* **批次 3 全部完成**：44 种作物，游戏内「我方模组 0 告警/错误、mapping 警告 0、全局资源错误 0」
* 结构：叶菜 8 + 蔬菜块根 14 + 谷物 12 + 豆类 6 + 油料纤维 4 = 44
* 灌木 10 种：矮丛 4（`bushes`）+ 蔓生 6（`bushes_high`），蔓生另有 6 个藤蔓方块
* 手册 5 个条目（intro / 矮丛灌木 / 蔓生灌木 / 作物 44 / 野生作物 44），crops 90 页、映射 86 项、与原版冲突 0
* 标签：mineable/hoe 147、crops 129、wild_crops 43、c:seeds 43、c:foods/vegetable 30、grain 12、fruit 10
* 资源：blockstate 151 / 模型 576 / 掉落表 150 / configured+placed feature 108+108 / 物品模型 150
* jar 479,167 字节

## 下一批：批次 4（设计已定，未实施）
见 `70-crop-implementation-plan.md` §3.3 与 §10。要点：

1. **8 种可采摘耕地作物**（`MyPickableCropBlock`，已存在）：辣椒/茄子/秋葵/棉花/芦笋/韭菜/大黄/洋蓟
2. **2 种灌丛**（**不是**耕地作物）：茶 `plant/tea_bush`、咖啡 `plant/coffee_bush`，走浆果灌木那一套
3. **新建物品**：亚麻→`fiber/flax`、苎麻→`fiber/ramie`、棉花→`cotton_boll`（非食物，有模型有 lang、无食物数据）
4. **茶/咖啡先放占位物品** `tea_leaf` / `coffee_bean`
5. `gen-crops.ps1` 的 `prod` 需支持三形式（缺省食物 / 含冒号=外部 / 不含冒号=自家非食物物品），改四处 + 同步 `$noFoodCrops`

## 工具链（全部在 `tfcfarmingplus/tools/`）
| 脚本 | 作用 |
|---|---|
| `gen-crops.ps1` | **作物生成器**（数据表驱动，改这里加作物）|
| `gen-high-bushes.ps1` | 蔓生灌木的主丛+藤蔓资源 |
| `gen-dead-and-wild-bushes.ps1` | 枯萎方块 + 灌木/野生作物世界生成 |
| `gen-tags.ps1` | **全部标签的唯一来源**（含 `$noFoodCrops`）|
| `gen-firmalife-plantable.ps1` | Firmalife 种植盆数据 |
| `gen-patchouli-book.ps1` | 手册正文（`$crops` 表 + 类别逻辑）；**末尾带闭合标记自检** |
| `polish-book.ps1` | 手册 `read_by_default`/`sortnum`/跳转映射（`$noFoodCrops` 要同步）|
| `verify.ps1` / `verify-book.ps1` | 静态交叉引用校验 |

**导出顺序**：gen-crops → gen-high-bushes → gen-dead-and-wild-bushes → gen-tags → gen-firmalife-plantable → gen-patchouli-book → polish-book → verify ×2 → build → 安装 → 启动验证

## 必须记住的陷阱
1. **锚点唯一性**：改代码/脚本前先 `Matches(anchor).Count == 1`，否则 throw。这几轮几乎所有事故都源于锚点不唯一或不匹配。
2. **不要凭记忆写锚点**：先 `Get-Content` 打印实际行，再据实构造。
3. **按函数范围清理**，别只看行的形状（合法行与误插行可能长得一样）。
4. **破坏性操作前先备份**（`.bak`），本目录**没有 git**。
5. `.ps1` 存盘必须 **UTF-8 带 BOM**（write 工具写的是无 BOM，PS 5.1 会按 GBK 解码中文路径）。
6. PowerShell 正则里 `$` 是行尾锚点 → 匹配含 `$` 的字面量请用 `.Contains()`。
7. 数组**中间行必须带尾逗号、末行必须不带**（改完做一次通用复查）。
8. Patchouli 闭合必须是 `` `$() ``；`tfc:table` 是双页类型需落在偶数索引并配一对空页；文字页要在偶数索引才能与多块页同跨页。
9. 手写锚点里的反引号/`$` 一律用**单引号**字符串。

## 已知的非问题
* JEI 查找历史缓存可能残留已删物品（`config/jei/world/local/tfctest/lookupHistory.json`），是 UI 缓存不是模组错误。
* `saves` 目录曾有段时间是空的，导致 `-QuickPlay` 静默退回主菜单 —— 判断「是否真进世界」要看日志里的 `Preparing start region`。

---

## ⚠️ 待修复的不一致（重要，下次开工第一件事）

### 现状

`gen-crops.ps1` 被**恢复到了一个较早的备份**（337 行）—— 那是「豆类完成、油料开始之前」的版本。后果：

| 项 | 状态 |
|---|---|
| 脚本里的作物表 | 只有 **40 种**（缺 flax / sesame / safflower / ramie）|
| 脚本对 `prod` / `prodTex` / `noFood` / `ownItem` 的支持 | **全部没有** |
| 已生成的资源文件（4 套 climate/loot 等）| **仍在**（跑脚本不会删旧文件）|
| Java 侧的 4 种作物 | **仍在** |
| **当前 jar** | **完整 44 种，游戏内已验证 0 错误** ✅ |

**结论**：当前构建产物是好的，但**脚本与资源不同步** —— 再跑一次 `gen-crops.ps1` 不会重新生成那 4 种油料。

### 下次要做的事

把油料部分重建进 `gen-crops.ps1`：

1. **数据表加 4 行**（flax / sesame / safflower / ramie），字段见本文档前面的 §10 与 `70-…-plan.md` §3.3；
   麻类要带 `prod='fiber/flax'` / `prod='fiber/ramie'` + `zhProd` / `enProd`，芝麻红花只带 `prodTex='tfc:item/canola'`
2. **prod 三形式变量块**（约 13 行）：缺省=自家食物物品 / 含冒号=外部物品 / 不含冒号=自家非食物物品
3. **四处条件改写**：食物数据 `if (-not $external -and -not $noFood)`、产物模型 `if ($ownItem)`、
   食物 lang `if ($ownItem -and -not $noFood)`、非食物产物 lang 写 `item.<ns>.<prod 转点号>`
4. 复核 `gen-tags.ps1` 的 `$noFoodCrops` 是否仍含 `flax, ramie`（这一步当时成功写入、未回退）

### 操作方法（血泪总结，务必遵守）

1. **先打印实际内容**：`Get-Content gen-crops.ps1` 找到 `$npk = $c['npk'] -split '/'` 那一行及后 5 行，**据实**构造锚点
2. **断言再动手**：每个锚点先 `Matcher.Count == 1`；数组先断言 `$list.Count`、关键行 `.Contains()` 校验
3. **严格降序**：大行号先改（插入行会让更大行号漂移）
4. **每步验语法**：`[Parser]::ParseFile`，通过再走下一步
5. **别用行号硬编码**：本次两次失败都因为按记忆里的行号操作（实测 337→338 行、且内容也不对）
6. **恢复备份前先确认备份内容**：本次就是「用一个更早的备份覆盖了更新的版本」，反而丢掉了油料那 4 行
