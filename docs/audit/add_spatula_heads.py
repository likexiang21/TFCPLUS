import json
from pathlib import Path

root = Path("mod_rebuild/tfcagricultureplus/src/main/resources")
assets = root / "assets/tfcagricultureplus"
data = root / "data/tfcagricultureplus"
metals = ["wrought_iron", "steel", "black_steel", "blue_steel", "red_steel"]
head_dir = assets / "models/item/spatula_head"
head_dir.mkdir(parents=True, exist_ok=True)
recipe_dir = data / "recipe/anvil"
recipe_dir.mkdir(parents=True, exist_ok=True)
craft_dir = data / "recipe/crafting"
for metal in metals:
    (head_dir / f"{metal}.json").write_text(json.dumps({
        "parent": "item/generated",
        "textures": {"layer0": f"tfc:item/metal/knife_blade/{metal}"},
    }, separators=(",", ":")), encoding="utf-8")
    (recipe_dir / f"spatula_head_{metal}.json").write_text(json.dumps({
        "type": "tfc:anvil",
        "ingredient": {"tag": f"c:sheets/{metal}"},
        "result": {"count": 1, "id": f"tfcagricultureplus:spatula_head/{metal}"},
        "rules": ["hit_last", "punch_not_last", "draw_not_last"],
        "tier": 2,
    }, indent=2) + "\n", encoding="utf-8")
    (craft_dir / f"spatula_{metal}.json").write_text(json.dumps({
        "type": "minecraft:crafting_shapeless",
        "ingredients": [{"item": f"tfcagricultureplus:spatula_head/{metal}"}, {"tag": "c:rods/wooden"}],
        "result": {"id": f"tfcagricultureplus:spatula/{metal}", "count": 1},
    }, indent=2) + "\n", encoding="utf-8")
print("spatula heads/recipes done")
