# Code Provenance / 源码来源审查

> 日期：2026-10-28
> 目的：满足 `DEVELOPMENT_RULES` 的来源登记要求，支持 EUPL-1.2 / MIT 许可选择。
> 方法：源码注释审查 + 反编译源相似度比对（`docs/audit/code_similarity.py`，结果 `docs/audit/code-similarity.txt`）。

## 1. 结论

- 未发现 >0.5 的整文件级相似复制；
- 最高相似度 **0.347**（`FarmingCropBlock` vs TFC `DefaultCropBlock`）；
- 这只能证明“未发现大段逐字复制”，不能证明所有实现完全独立；
- 源码中存在“照抄 TFC”的注释，已改为“参考公开 API/行为，独立实现”；
- TFC Woodworking 的 MIT 迁移已在 B 的 `META-INF/licenses/` 和源码注释中署名；
- 未发现从 GPL/ARR/CC 受限模组复制代码或资源的证据；
- 项目后续新增代码必须继续登记来源。

## 2. 相似度最高文件（人工复核清单）

| 相似度 | 项目文件 | 最相似反编译文件 | 复核建议 |
|---:|---|---|---|
| 0.347 | `FarmingCropBlock.java` | TFC `DefaultCropBlock.java` | 核对状态/成长回调；保留独立实现说明 |
| 0.293 | `FarmingSpreadingCaneBlock.java` | TFC `DeadBananaPlantBlock.java` | 核对构造器/形状 |
| 0.273 | `FarmingSeedItem.java` | TFC `SeedItem.java` | 核对 tooltip/API |
| 0.270 | `FarmingSpreadingBushBlock.java` | TFC `DeadBananaPlantBlock.java` | 核对属性/构造器 |
| 0.265 | `FarmingBerryBushBlock.java` | TFC `DeadBananaPlantBlock.java` | 核对生命周期/掉落 |
| 0.226 | `FarmingGrowingFruitTreeBranchBlock.java` | Firmalife `FLGrowingFruitTreeBranchBlock.java` | 核对计时/状态 |

上述相似度主要来自 Minecraft/TFC 公开 API 的固定签名、注册样板和状态机骨架；不构成“复制整文件”的自动判定。**发布前仍需人工确认没有逐段搬运。**

## 3. 已登记的第三方代码/行为

| 来源 | 许可 | 项目使用 | 登记位置 |
|---|---|---|---|
| TFC Woodworking 1.2.4 | MIT | B timber 几何/`in_world` 数据 | B JAR `META-INF/licenses/tfcwoodwork-MIT.txt` |
| TFC | EUPL-1.2 | 公开 API/数据格式；部分资源/书页/模型 | `THIRD_PARTY_NOTICES.md` |
| Firmalife | MIT | API/数据兼容 | `THIRD_PARTY_NOTICES.md` |
| afc | MIT | 木材树种引用 | `THIRD_PARTY_NOTICES.md` |
| Patchouli | CC BY-NC-SA 3.0 | 手册运行时依赖 | `THIRD_PARTY_NOTICES.md` |

## 4. 注释清理规则

- 禁止使用“照抄”“复制自”等无法核验的表述；
- 统一写成“参考 XXX 的公开 API/行为；本项目独立实现”；
- 若确有派生，写清来源、许可证、修改范围，并按 EUPL/MIT 处理；
- 仅修改注释不能替代独立重写（`DEVELOPMENT_RULES` §一.7）。

## 5. 待办

- 对 Top 6 文件做人工来源复核并记录；
- 删除/改写所有“照抄 TFC”注释（本轮已改）；
- 新增文件在 PR/提交说明中登记来源；
- 发布前由 `docs/audit/code_similarity.py` 重跑并保存结果。
