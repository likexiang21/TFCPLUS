# Third-Party Assets / 第三方资源登记

> 状态：工程合规记录；许可证原文见 `LICENSES/` 与 `THIRD_PARTY_NOTICES.md`。
> 说明：所有现有贴图后续全面重绘；重绘替换后应更新本表。

## 1. TFC（EUPL-1.2）

### 1.1 逐像素相同的 TFC 贴图（8 张）

来源：`TerraFirmaCraft-NeoForge-1.21.1-4.2.11.jar` 的 `assets/tfc/textures/block/berry_bush/*`。

| 项目文件 | TFC 源文件 |
|---|---|
| `tfcfarmingplus/src/main/resources/assets/tfcfarmingplus/textures/block/crop/strawberry_age_0.png` | `tfc:block/berry_bush/strawberry_bush` |
| `.../strawberry_age_1.png` | 同上 |
| `.../strawberry_age_2.png` | `tfc:block/berry_bush/flowering_strawberry_bush` |
| `.../strawberry_age_3.png` | 同上 |
| `.../strawberry_age_4.png` | `tfc:block/berry_bush/fruiting_strawberry_bush` |
| `.../strawberry_age_5.png` | 同上 |
| `.../strawberry_dead.png` | `tfc:block/berry_bush/dry_strawberry_bush` |
| `.../strawberry_dead_young.png` | 同上 |

处置：按 EUPL-1.2 保留 TFC 许可/署名；全面重绘后替换并更新本表。

### 1.2 TFC 书页（10 个语言）

TFC `field_guide` 的 `the_world/wild_fruits.json` 被项目修改/补译，位于：

`assets/tfc/patchouli_books/field_guide/{en_us,ja_jp,ko_kr,pt_br,ru_ru,tr_tr,uk_ua,zh_cn,zh_hk,zh_tw}/entries/the_world/wild_fruits.json`

处置：EUPL-1.2 归属 TFC；项目修改部分在文件历史/提交中可追溯。

### 1.3 TFC 模型（6 个）

`assets/tfc/models/block/crop/cabbage_age_0..5.json`：项目基于 TFC 模型的资源覆盖。

### 1.4 TFC 数据/命名空间文件

- A：`data/tfc/**` 19 个（标签/配方/数据覆盖）；
- B：`data/tfc/**` 184 个（其中 182 个配方禁用/覆盖）；
- 处置：EUPL-1.2；不得单方面改标 MIT。

## 2. Firmalife（MIT）

A 的 157 个 `data/firmalife/**`：

- 155 个项目新增兼容数据（`firmalife/plantable/*.json` 等）；
- 2 个修改自 Firmalife：`data/firmalife/firmalife/plantable/strawberry.json`、`data/firmalife/tags/block/buzzing_leaves.json`；
- 处置：MIT 文本 `LICENSES/MIT-Firmalife.txt`；修改文件保留来源说明。

## 3. TFC Woodworking（MIT）

B 的 timber 几何/数据来自 TFC Woodworking 1.2.4（uTa4u）：

- 数据：`data/tfcagricultureplus/recipe/in_world/*`、crafting/woodwork 相关；
- 几何：`TimberPieceBlock` 等（源码注释已注明）；
- 已被 JAR 收录：`META-INF/licenses/tfcwoodwork-MIT.txt`、`timber-notice.txt`。

## 4. afc（MIT）

B 引用 14 个 AFC 树种资源，不复制 AFC 资源；`neoforge.mods.toml` 需声明依赖。MIT 文本 `LICENSES/MIT-afc.txt`。

## 5. Patchouli（CC BY-NC-SA 3.0）

运行时手册依赖；项目只提供书页 JSON，不复制 Patchouli 本体/资源。分发说明必须披露该依赖。

## 6. 项目原创资源

除上述条目外，A/B 的模型/贴图/JSON/书页为项目原创或由项目生成；在全面重绘前均为**未验收占位态**，不能声称最终美术完成。

## 7. 维护

- 任何新第三方资源先登记来源、许可证、修改方式；
- 重绘/替换后更新哈希和条目；
- 删除任何第三方资源前确认不再被运行/构建/合同引用。
