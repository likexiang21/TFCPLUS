from pathlib import Path

exact = (
    '"item.tfcagricultureplus.food.cocoa_beans":',
    '"item.tfcagricultureplus.food.cocoa_nibs":',
    '"item.tfcagricultureplus.food.roasted_cocoa_beans":',
    '"item.tfcagricultureplus.food.cocoa_powder":',
    '"item.tfcagricultureplus.food.dark_chocolate":',
    '"item.tfcagricultureplus.food.cake_slice":',
    '"item.tfcagricultureplus.food.butter_slice":',
    '"item.tfcagricultureplus.material.dough":',
    '"block.tfcagricultureplus.dough_forming_table":',
    '"block_entity.tfcagricultureplus.dough_forming_table":',
    '"jei.tfcagricultureplus.category.dough":',
    '"block.tfcagricultureplus.melting_pot":',
    '"block_entity.tfcagricultureplus.melting_pot":',
    '"message.tfcagricultureplus.melting_pot.started":',
    '"message.tfcagricultureplus.melting_pot.empty":',
    '"message.tfcagricultureplus.melting_pot.invalid":',
    '"jei.tfcagricultureplus.category.melting":',
    '"block.tfcagricultureplus.whole_cake":',
)
base = Path("mod_rebuild/tfcagricultureplus/src/main/resources/assets/tfcagricultureplus/lang")
for name in ("en_us.json", "zh_cn.json"):
    path = base / name
    lines = path.read_text(encoding="utf-8").splitlines(keepends=True)
    kept = [line for line in lines if not any(key in line for key in exact)]
    path.write_text("".join(kept), encoding="utf-8")
    print(name, "removed", len(lines) - len(kept), "lines")
