from pathlib import Path

keys = (
    "item.tfcagricultureplus.food.dried_cocoa_beans",
    "item.tfcagricultureplus.food.dried_strawberry",
    "item.tfcagricultureplus.food.dried_ginger",
    "item.tfcagricultureplus.food.dried_turmeric",
    "item.tfcagricultureplus.food.dried_napa_cabbage",
)
base = Path("mod_rebuild/tfcagricultureplus/src/main/resources/assets/tfcagricultureplus/lang")
for name in ("en_us.json", "zh_cn.json"):
    path = base / name
    lines = path.read_text(encoding="utf-8").splitlines(keepends=True)
    kept = [line for line in lines if not any(('"' + key + '"') in line for key in keys)]
    path.write_text("".join(kept), encoding="utf-8")
    print(name, "removed", len(lines) - len(kept), "lines")
