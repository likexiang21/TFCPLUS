import json
from pathlib import Path

metals = ["bismuth", "bismuth_bronze", "black_bronze", "bronze", "brass",
          "copper", "gold", "nickel", "rose_gold", "silver", "tin", "zinc",
          "sterling_silver", "wrought_iron", "cast_iron", "steel", "black_steel",
          "blue_steel", "red_steel"]
root = Path("mod_rebuild/tfcagricultureplus/src/main/resources")
assets = root / "assets/tfcagricultureplus"
data = root / "data/tfcagricultureplus"
model_dir = assets / "models/item/metal_can"
model_dir.mkdir(parents=True, exist_ok=True)
old = assets / "models/item/metal_can.json"
if old.exists():
    old.unlink()
for metal in metals:
    (model_dir / f"{metal}.json").write_text(json.dumps({
        "parent": "item/generated",
        "textures": {"layer0": f"tfc:item/metal/sheet/{metal}"},
    }, separators=(",", ":")), encoding="utf-8")
anvil = data / "recipe/anvil"
anvil.mkdir(parents=True, exist_ok=True)
heating = data / "recipe/heating/metal"
heating.mkdir(parents=True, exist_ok=True)
old_anvil = anvil / "metal_can.json"
if old_anvil.exists():
    old_anvil.unlink()
old_heat = heating / "metal_can.json"
if old_heat.exists():
    old_heat.unlink()
for metal in metals:
    (anvil / f"metal_can_{metal}.json").write_text(json.dumps({
        "type": "tfc:anvil",
        "ingredient": {"tag": f"c:sheets/{metal}"},
        "result": {"count": 1, "id": f"tfcagricultureplus:metal_can/{metal}"},
        "rules": ["hit_last", "punch_not_last", "draw_not_last"],
        "tier": 2,
    }, indent=2) + "\n", encoding="utf-8")
    (heating / f"metal_can_{metal}.json").write_text(json.dumps({
        "type": "tfc:heating",
        "ingredient": {"item": f"tfcagricultureplus:metal_can/{metal}"},
        "result_fluid": {"amount": 200, "id": f"tfc:metal/{metal}"},
        "temperature": 1535.0,
    }, indent=2) + "\n", encoding="utf-8")
print("generated", len(metals), "metal cans")
