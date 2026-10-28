import json
from pathlib import Path

root = Path("mod_rebuild/tfcagricultureplus/src/main/resources")
assets = root / "assets/tfcagricultureplus"
data = root / "data/tfcagricultureplus"
model_dir = assets / "models/block/lumber_pile"
model_dir.mkdir(parents=True, exist_ok=True)
for count in range(1, 17):
    elements = []
    for layer in range(count):
        elements.append({
            "from": [1, layer, 1], "to": [15, layer + 1, 15],
            "faces": {
                "north": {"uv": [1, 0, 15, 1], "texture": "#0"},
                "east": {"uv": [1, 0, 15, 1], "texture": "#0"},
                "south": {"uv": [1, 0, 15, 1], "texture": "#0"},
                "west": {"uv": [1, 0, 15, 1], "texture": "#0"},
                "up": {"uv": [1, 1, 15, 15], "texture": "#0"},
                "down": {"uv": [1, 1, 15, 15], "texture": "#0"},
            },
        })
    model = {
        "parent": "block/block",
        "textures": {"0": "tfc:block/wood/planks/oak", "particle": "tfc:block/wood/planks/oak"},
        "elements": elements,
    }
    (model_dir / f"lumber_pile_{count}.json").write_text(json.dumps(model, separators=(",", ":")), encoding="utf-8")
variants = {}
for axis in ("x", "z"):
    for count in range(1, 17):
        variants[f"axis={axis},count={count}"] = {"model": f"tfcagricultureplus:block/lumber_pile/lumber_pile_{count}"}
(assets / "blockstates/lumber_pile.json").write_text(json.dumps({"variants": variants}, separators=(",", ":")), encoding="utf-8")
(assets / "models/item/lumber_pile.json").write_text(json.dumps({"parent": "tfcagricultureplus:block/lumber_pile/lumber_pile_4"}, separators=(",", ":")), encoding="utf-8")
loot = {
    "type": "minecraft:block",
    "pools": [{
        "rolls": 1,
        "entries": [{"type": "minecraft:item", "name": "tfcagricultureplus:lumber_pile"}],
        "conditions": [{"condition": "minecraft:survives_explosion"}],
    }],
}
(data / "loot_table/blocks/lumber_pile.json").write_text(json.dumps(loot, indent=2) + "\n", encoding="utf-8")
recipe = {
    "type": "minecraft:crafting_shapeless",
    "ingredients": [{"tag": "tfc:lumber"}, {"tag": "tfc:lumber"}, {"tag": "tfc:lumber"}, {"tag": "tfc:lumber"}],
    "result": {"id": "tfcagricultureplus:lumber_pile", "count": 1},
}
(data / "recipe/crafting/lumber_pile.json").write_text(json.dumps(recipe, indent=2) + "\n", encoding="utf-8")
print("lumber pile assets generated")
