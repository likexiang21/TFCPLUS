# Third-Party Notices / 第三方来源与许可

本项目（TFCPlus：`tfcfarmingplus`、`tfcagricultureplus`）采用 **EUPL-1.2**。本文件登记与项目一起分发的第三方内容、依赖及其许可；项目源代码/资源如来自第三方，均在此列明。

> 本文件是工程合规记录，不构成法律意见；许可证原文以 `LICENSES/` 和上游发布物为准。

## 1. 项目自身许可

- 许可证：**European Union Public Licence v1.2（EUPL-1.2）**；
- 全文：根目录 `LICENSE`、`LICENSES/EUPL-1.2.txt`；
- 适用对象：本项目原创的 Java、JSON、模型、贴图、文档与工具（除非文件另有说明）。

## 2. TerraFirmaCraft（TFC）

| 项 | 内容 |
|---|---|
| 许可证 | **EUPL-1.2** |
| 上游 | https://github.com/TerraFirmaCraft/TerraFirmaCraft |
| 作者/版权 | AlcatrazEscapee 等 TFC 贡献者（以上游声明为准） |
| 项目使用方式 | 运行时依赖；通过公开 API/数据格式集成；少量 TFC 命名空间数据/书页/模型与贴图由项目修改或派生 |

涉及内容：

- A `assets/tfc/**`（32 个）与 `data/tfc/**`（19 个）；
- B `assets/tfc/**`（12 个）与 `data/tfc/**`（184 个）；
- A 10 个语言的 `patchouli_books/field_guide/*/entries/the_world/wild_fruits.json`（在 TFC 书页基础上修改）；
- A 6 个 `assets/tfc/models/block/crop/cabbage_age_*.json`（修改 TFC 模型覆盖）；
- A 8 张与 TFC 逐像素相同的 strawberry 作物贴图（见 `docs/THIRD-PARTY-ASSETS.md`）；
- B 182 个 `data/tfc/recipe/**` 禁用/覆盖文件；
- 项目源码中按 TFC 公开 API/行为参考实现的类（`docs/CODE-PROVENANCE.md`）。

TFC 的 EUPL-1.2 全文已随项目放在 `LICENSES/EUPL-1.2.txt`。项目不修改 TFC 的 JAR；上述内容以数据包/资源覆盖方式提供。若后续需要重新许可这些派生内容，必须先完成法务确认。

## 3. Firmalife

| 项 | 内容 |
|---|---|
| 许可证 | **MIT** |
| 上游 | https://github.com/eerussianguy/firmalife |
| 作者 | EERussianguy, Charnuz, Dodo, Indi, Peffern, Lumintorious |
| 项目使用方式 | 运行时依赖；A 的 157 个 `data/firmalife/**` 文件中 155 个为项目新增兼容数据，2 个修改自 Firmalife（`strawberry.json`、`buzzing_leaves.json`） |

MIT 许可要求保留版权和许可声明；相关文件/派生内容已在 `LICENSES/MIT-Firmalife.txt` 登记。

## 4. ArborFirmaCraft（afc）

| 项 | 内容 |
|---|---|
| 许可证 | **MIT** |
| 上游 | https://github.com/Therighthon/ArborFirmaCraft |
| 作者 | Therighthon |
| 项目使用方式 | B 运行时依赖/木材树种引用；B 不复制 afc 的资源文件 |

B 的 `neoforge.mods.toml` 必须声明 afc 依赖（见修复后的模板）；MIT 文本见 `LICENSES/MIT-afc.txt`。

## 5. Patchouli

| 项 | 内容 |
|---|---|
| 许可证 | **CC BY-NC-SA 3.0** |
| 上游 | https://github.com/VazkiiMods/Patchouli |
| 作者 | Vazkii |
| 项目使用方式 | A/B 的手册运行时依赖；项目只编写 Patchouli 书页 JSON，不复制 Patchouli 代码或本体资源 |

Patchouli 许可含非商业/相同方式共享条款；项目**不重新分发 Patchouli 本体**。分发整合包时必须另行核对 Patchouli 的许可。

## 6. TFC Woodworking

| 项 | 内容 |
|---|---|
| 许可证 | **MIT** |
| 上游 | https://github.com/uTa4u/TFC-Woodworking |
| 作者/版权 | uTa4u（Copyright (c) 2024） |
| 项目使用方式 | B 的 timber 几何/`in_world` 与 crafting 数据迁移；JAR 内已有 `tfcwoodwork-MIT.txt`、`timber-notice.txt` |

这是本项目第三方 MIT 履约的样板；完整 MIT 文本见 `tfcagricultureplus/src/main/resources/META-INF/licenses/tfcwoodwork-MIT.txt`。

## 7. JEI

| 项 | 内容 |
|---|---|
| 许可证 | **MIT** |
| 上游 | https://github.com/mezz/JustEnoughItems |
| 项目使用方式 | B 的可选运行时/编译依赖；不复制 JEI 代码或资源 |

## 8. 资源来源登记

第三方资源/派生资源的逐文件登记见：

- `docs/THIRD-PARTY-ASSETS.md`（TFC 8 张同像素贴图、TFC 书页/模型、Firmalife 兼容数据、TFC Woodworking 数据）；
- `docs/CODE-PROVENANCE.md`（源码来源、相似度审查、独立实现/参考范围）。

## 9. 维护规则

- 新增任何第三方代码/资源前，先登记来源、许可证、修改方式；
- 不得把 EUPL-1.2 派生内容单独标为 MIT；
- 不得删除本文件或 `LICENSES/`；
- 更换/重绘第三方资源后，更新对应条目和哈希；
- 发布 JAR 必须包含 `META-INF/licenses/` 内的 EUPL 文本与第三方通知。
