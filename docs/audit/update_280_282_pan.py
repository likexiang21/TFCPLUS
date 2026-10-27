from pathlib import Path

docs = Path("mod_rebuild/docs")
p280 = docs / "280-b-implementation-gap-vs-tech-docs-20261028.md"
t = p280.read_text(encoding="utf-8")
repls = [
    (
        "- 烹饪：K2 炒锅、K3 案板确认/可放置食物、搅拌碗/烤炉/干燥/石臼等加工链已落地；",
        "- 烹饪：K2 炒锅已从 1 条占位扩为 14 条配方、K3 案板确认/可放置食物、搅拌碗/烤炉/干燥/石臼等加工链已落地；但 K2/K3 都未实机；",
    ),
    (
        "- 当前数据量：清理旧内容后为 489 blockstate、503 block model、620 item model、756 recipe、489 loot、52 TFC food 定义、698 item lang keys（旧面团/融化锅/旧可可/旧蛋糕/旧黄油已清理，见 282）。",
        "- 当前数据量：清理旧内容并扩展炒锅后为 489 blockstate、503 block model、620 item model、769 recipe、489 loot、52 TFC food 定义、698 item lang keys（旧面团/融化锅/旧可可/旧蛋糕/旧黄油已清理，见 282；炒锅 14 条，见 283）。",
    ),
    (
        "**K2：实际完成静态；未实机。**",
        "**K2：已从“单一占位配方”扩展为 14 条真实配方，但仍未实机，不能标为完成。**\n"
        "原 `193` 只是 K2 垂直切片；此前把“1 条配方 + 静态构建”写成完成是不合格的，已按 283 更正。",
    ),
    (
        "- K2 pan 1 条 → 实际 1；",
        "- K2 pan：原 1 条占位 → 实际 14 条（仍非最终完成）；",
    ),
    (
        "**B 的木工、K1 厨房家具、K2 炒锅、K3 大部分加工/可放置食物、养蚕全流程，已经达到或超过 129/130 的早期目标；",
        "**B 的木工、K1 厨房家具、K2 炒锅（已从 1 条占位扩为 14 条，但未实机）、K3 大部分加工/可放置食物、养蚕全流程，已经达到或超过 129/130 的早期目标；",
    ),
]
for old, new in repls:
    if old not in t:
        raise SystemExit(f"missing 280 text: {old[:60]}")
    t = t.replace(old, new)

k2_old = """实际：

- `CookingPanBlock`/`CookingPanBlockEntity`/`PanInteractions`；
- 3 槽、计时、搅拌、完成、腐烂拒绝、NBT 保存；
- 1 个 pan 配方（`seasoned_vegetable_pan`）；
- 2 个 tag（pan_inputs/ground_spices）；
- JEI pan 分类；
- Patchouli 厨房入口存在。
"""
k2_new = """实际：

- `CookingPanBlock`/`CookingPanBlockEntity`/`PanInteractions`；
- 3 槽、计时、搅拌、完成、腐烂拒绝、NBT 保存；
- **14 个 pan 配方**（2026-10-28 扩展，原先只有 1 个 `seasoned_vegetable_pan` 占位配方）：
  - 8 种生肉 + 香料 → 对应 TFC 熟肉；
  - 4 种生鱼 + 香料 → 对应 TFC 熟鱼；
  - 蔬菜汤/谷物汤/水果汤 + 香料 → 调味蔬菜；
  - 5 种生蔬菜 + 香料 → 调味蔬菜；
- pan 输入标签解析后 20 个输入物品；ground_spices 3 个；
- 输出自动附加 `tfcagricultureplus:seasoned` trait；
- JEI pan 分类、Patchouli 炒锅页。
"""
if k2_old not in t:
    raise SystemExit("missing 280 K2 block")
t = t.replace(k2_old, k2_new)
p280.write_text(t, encoding="utf-8")
print("280 updated", len(t))

p282 = docs / "282-cleanup-legacy-kitchen-content-20261028.md"
t = p282.read_text(encoding="utf-8")
old_recipe = "| recipe | **756** |"
new_recipe = "| recipe | **769** |"
if old_recipe not in t:
    raise SystemExit("missing 282 recipe row")
t = t.replace(old_recipe, new_recipe)
old_art = """最终 B 产物：

```text
artifacts/TFCAgriculturePlus-NeoForge-1.21.1-0.1.0.jar
1,507,294 bytes
SHA-256 4B38BBE42B9F893372688D2ECC3C10CAA6272896997220EAC62B7C5C3AB92945
```"""
new_art = """最终 B 产物（283 炒锅扩展后）：

```text
artifacts/TFCAgriculturePlus-NeoForge-1.21.1-0.1.0.jar
1,513,040 bytes
SHA-256 7E0521F2C268BD6E43C690368E2136C44BA3B58C57166D1B6811B3FA99458374
```"""
if old_art not in t:
    raise SystemExit("missing 282 artifact block")
t = t.replace(old_art, new_art)
p282.write_text(t, encoding="utf-8")
print("282 updated", len(t))
