# 281 清理 B 遗留干燥物品

> 日期：2026-10-28
> 背景：B 早期自建干燥产物被 Firmalife 的 `firmalife:drying` + `firmalife:dried` FoodTrait 取代；原 5 个 `dried_*` 物品成为隐藏 legacy ID。
> 用户指令：**清理掉。**

## 1. 已删除的物品 ID

```text
tfcagricultureplus:food/dried_ginger
tfcagricultureplus:food/dried_turmeric
tfcagricultureplus:food/dried_napa_cabbage
tfcagricultureplus:food/dried_strawberry
tfcagricultureplus:food/dried_cocoa_beans
```

## 2. 同步删除的内容

- `AgricultureItems` 中 5 个 `DeferredHolder` 注册；
- `allDriedFoods()`（原本已返回空列表）；
- `AgricultureCreativeTab` 的干燥物品遍历（原本不会显示）；
- JEI 隐藏列表中的 5 个 ID；
- `assets/tfcagricultureplus/models/item/food/dried_*.json`（5 个）；
- `assets/tfcagricultureplus/textures/item/food/dried_cocoa_beans.png`；
- `data/tfcagricultureplus/tfc/food/dried_*.json`（5 个）；
- `en_us.json` / `zh_cn.json` 中的 dried_cocoa_beans、dried_strawberry 语言键（其余 3 个原本无语言键）。

## 3. 保留的内容

- `data/tfcagricultureplus/recipe/drying/cocoa_beans.json`（原 `dried_cocoa_beans.json`）：
  - 仍使用 `firmalife:drying`；
  - 输入 `firmalife:food/cocoa_beans`；
  - 输出 `firmalife:food/cocoa_beans` + `firmalife:dried` trait；
  - 不产出任何 B `dried_*` 物品。
- Firmalife 的 canonical dried trait 体系保持不动。

## 4. 存档影响

- 旧存档中已存在的上述 5 个物品在加载时会变成未知物品并丢失；
- 这是用户明确要求清理后的预期结果；
- 未提供旧 ID → Firmalife 物品的自动迁移。

## 5. 验证

- B 已重新构建成功；
- 新产物（本批为中间产物）：`artifacts/TFCAgriculturePlus-NeoForge-1.21.1-0.1.0.jar`，1,549,208 bytes，SHA-256 `8CA72596A5813D6BA72E52E4C0A735BF2A373A85B3AD188B03EA8C73A70619BB`；
- 随后 282 又清理旧厨房/旧可可内容，最终产物见 282（1,507,294 bytes / `4B38BBE4...`）。
- JAR 内不再包含任何 `dried_*` 资源；仅保留 `recipe/drying/cocoa_beans.json`（Firmalife canonical cocoa 干燥）；
- 全树对 `dried_*` / `DRIED_*` / `allDriedFoods` 的引用为 0；
- B `verify-container-contract`、`verify-grain-food-processing`、`verify-vegetable-beverage-processing`、`check-boundaries` 均通过；
- 许可证门禁通过。

## 6. 相关文档

- 早期问题记录：`docs/archive/152-defect-remediation-master-plan-20261009.md`；
- 旧 ID 审计：`docs/archive/218-agriculture-audit-baseline-20261023.md` AR0-05；
- 代码来源/许可：`docs/279-protocol-code-fixes-20261028.md`。
