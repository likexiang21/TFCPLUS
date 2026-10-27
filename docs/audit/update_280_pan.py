from pathlib import Path

p = Path("mod_rebuild/docs/280-b-implementation-gap-vs-tech-docs-20261028.md")
lines = p.read_text(encoding="utf-8").splitlines()
start = next(i for i, line in enumerate(lines) if line.startswith("- `CookingPanBlock`/`CookingPanBlockEntity`/`PanInteractions`"))
end = next(i for i in range(start, len(lines)) if lines[i].startswith("**K2："))
new = [
    "- `CookingPanBlock`/`CookingPanBlockEntity`/`PanInteractions`；",
    "- 2026-10-28 后期已重写为 Cuisine Delight 式动态系统（284）：",
    "  - TFC 热源判定 + 100 mB 油 + 8 个食材槽；",
    "  - 每个食材独立生/熟/过熟/焦糊计时；",
    "  - 锅铲翻炒；",
    "  - 按食材组成动态生成 TFC FoodData、份数、类别和评分；",
    "  - 盘子/碗承装与分餐。",
    "",
]
lines[start:end] = new
text = "\n".join(lines)
text = text.replace(
    "- K2 pan：原 1 条占位 → 实际 14 条（仍非最终完成）；",
    "- K2 pan：原 1 条占位 → 动态多食材系统（284），仍未实机；",
)
p.write_text(text, encoding="utf-8")
print("updated 280", start, end)
