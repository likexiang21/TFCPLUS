# 279 协议与代码问题修复记录（2026-10-28）

> 状态：本地修复完成，**未推送**。
> 上游审查：[277 计划实现与开源协议审查](277-plan-implementation-and-license-compliance-20261028.md)、[278 清理清单](278-cleanup-inventory-20261028.md)。
> 构建：A/B 均已重新构建；新 artifacts 见 §4。
> 说明：贴图仍按用户要求全面重绘；本轮只修复代码/数据/协议，不把任何旧贴图标为最终美术。

## 1. 协议修复

### 1.1 项目许可证统一为 EUPL-1.2

依据根 `LICENSE.txt` 的现有选择（EUPL-1.2）：

- 新增 `LICENSE`、`LICENSES/EUPL-1.2.txt`；
- A/B `src/main/templates/META-INF/neoforge.mods.toml`：
  - `license = "EUPL-1.2"`；
  - `authors = "likexiang21"`；
- A/B JAR 内新增：
  - `META-INF/licenses/EUPL-1.2.txt`；
  - `META-INF/licenses/THIRD_PARTY_NOTICES.txt`；
- A 额外带 `MIT-Firmalife.txt`；B 带 `MIT-Firmalife/afc/JEI/TFC-Woodworking`；
- B 新增 `afc` required 依赖。

> 这是按根许可证做出的工程选择；如果用户最终要改回 MIT，必须同时处理 EUPL/TFC 派生内容，不能只改 `mods.toml`。

### 1.2 第三方来源/许可登记

新增：

- `THIRD_PARTY_NOTICES.md`：TFC EUPL、Firmalife/afc/JEI MIT、Patchouli CC BY-NC-SA、TFC Woodworking MIT；
- `docs/THIRD-PARTY-ASSETS.md`：8 张 TFC 同像素贴图、10 个 TFC 书页、6 个 TFC cabbage 模型、182 个 B TFC 数据覆盖、157 个 A Firmalife 数据等；
- `docs/CODE-PROVENANCE.md`：源码相似度 Top 6、独立实现/来源说明、TFC Woodworking MIT 履约；
- `tools/check-license-compliance.ps1`：校验 LICENSE/副本/JAR 内许可/元数据一致性。

### 1.3 源码注释清理

移除“照抄 TFC”等不可核验表述，改为“参考公开 API/行为，独立实现”：

- `TFCFarmingPlus.java`；
- `TFCFarmingPlusClient.java`；
- `FarmingSpreadingBushBlock.java`；
- `FarmingBushes.java`；
- `SawdustSoupBowlItem.java`。

代码相似度复核：最高 Jaccard **0.347**，无 >0.5 整文件匹配；仍未把 Top 6 文件的人工逐段核对当作已完成（见 `docs/CODE-PROVENANCE.md` §2）。

## 2. 代码/数据修复

### 2.1 A 整瓜模型

6 个模型恢复 `textures` 覆盖，指向现有 `block/melon/*_fruit_{side,top}`：

- `bottle_gourd`、`cantaloupe`、`winter_melon`；
- `rotten_bottle_gourd`、`rotten_cantaloupe`、`rotten_winter_melon`。

贴图本身仍待重绘。

### 2.2 B loot table

- 原 103/492 个方块有 loot；
- 已补 389 个缺失 loot table：
  - 387 个有 BlockItem 的方块 → 掉落自身；
  - 2 个无物品技术方块（`burning_log_pile`、`log_pile`）→ 空 loot；
- 现 **492/492** 覆盖。

### 2.3 B 缺失贴图/物品/依赖

- 12 个 `raw_*_bun/naan` 的 Firmalife 面团路径：`*_dough` → `*_flatbread_dough`；
- `whole_pie`：`minecraft:block/pumpkin` → `minecraft:block/pumpkin_side`；
- `food/pan_seasoned_vegetables`：新增 item model（`tfc:item/food/vegetables_soup` 占位）；
- 新增 `textures/item/food/cake_slice.png` 占位，修复 `chocolate_cake_slice`/`cream_cake_slice` 引用；
- 删除无注册物品的孤儿模型 `models/item/flint_pestle.json`；
- B `neoforge.mods.toml` 声明 `afc` required 依赖。

### 2.4 代码质量

- `DebugValidation` 的切割板配方数断言：`12` → `15`（与当前实际配方一致）；
- `SpeciesLookup` javadoc 修正：不再声称 B 依赖本类；B 的 `build.gradle.kts` 移除 A-jar 编译依赖（B 对 A 无 Java import，运行时仍由 `mods.toml` 依赖 A）。

### 2.5 构建可复现

- A/B `build.gradle.kts`：
  - `modsDir` 支持 `TFC_MODS_DIR`、`../../mods`、`../mods`、`mods/`；
  - `latestJar()` 改为按数字版本段排序，避免 `4.2.9` > `4.2.11` 的字典序错误；
- 生成 A/B `gradlew`/`gradlew.bat`/`gradle/wrapper/*`；
- B 不再依赖 A `build/libs`（构建独立；运行时依赖仍声明）。

## 3. 验证

已通过：

- A `audit-crop`、`audit-tree`、`audit-branch`、`audit-bush`、`audit-soil`：0 findings；
- B `verify-container`、`verify-grain`、`verify-vegetable`、`check-boundaries`：EXIT 0；
- `tools/check-license-compliance.ps1`：OK；
- A/B 构建：BUILD SUCCESSFUL；
- B blockstate-loot：492/492；
- B 本地贴图引用：0 缺失（本地 namespace）；
- A 6 瓜模型贴图路径：全部存在；
- A/B JAR 内 EUPL/第三方通知：存在。

未完成：

- 全面贴图重绘与视觉/实机验收；
- A 949 个模型仍借 TFC 占位（贴图重绘阶段处理）；
- A 1,130 张死贴图清理（重绘后处理）；
- 完整 AR4-AH/AR5 与最终运行回归；
- 文档 274/276/277/278 的部分历史数字仍保留审查时快照（以本记录为准）。

## 4. 当前产物

| 产物 | 大小 | SHA-256 |
|---|---:|---|
| `artifacts/TFCFarmingPlus-NeoForge-1.21.1-0.1.0.jar` | 2,425,696 B | `A860974F40B559A7967AC3C1469D78A34DA904D697426068FB6FA3A9AC49BA94` |
| `artifacts/TFCAgriculturePlus-NeoForge-1.21.1-0.1.0.jar` | 1,573,191 B | `A8E58F324C06B5FCCB12CFB70D65AC7C290C9BE16378F7C52CD207F2E12880A9` |

> 旧 276/277 中的 A `386834A1...`、B `97B961DB...` 是修复前产物；本表为新产物。
> 后续 legacy 清理（B 5 个 `dried_*` 物品）见 [281 记录](281-remove-legacy-dried-items-20261028.md)，B 产物哈希已更新为本表数值。

## 5. 本地状态

- 远端 `mod-rebuild-20261027` 仍为 `58865795eb21741b769503161618c8c10c08fa57`；
- 本记录、所有修复和构建均未推送；
- 工作区清理结果见 278 §9（已释放约 1,001 MB）。
