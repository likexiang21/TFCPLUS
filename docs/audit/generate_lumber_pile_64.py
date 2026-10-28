import json
from pathlib import Path

root = Path("mod_rebuild/tfcagricultureplus/src/main/resources")
assets = root / "assets/tfcagricultureplus"
model_dir = assets / "models/block/lumber_pile"
if model_dir.exists():
    for path in model_dir.glob("*.json"):
        path.unlink()
model_dir.mkdir(parents=True, exist_ok=True)
# Match TimberBlocks.WOODS: every TFC/AFC debarked-piece wood, plus oak.
woods = sorted(p.stem for p in (assets / "models/item/debarked_half").glob("*.json"))
if "oak" not in woods:
    woods.append("oak")
woods = sorted(set(woods))
variants = {}
for wood in woods:
    texture = f"tfc:block/wood/planks/{wood}"
    for count in range(1, 65):
        height = count / 4.0
        model = {
            "parent": "block/block",
            "textures": {"0": texture, "particle": texture},
            "elements": [{
                "from": [1, 0, 1], "to": [15, height, 15],
                "faces": {
                    "north": {"uv": [1, 0, 15, 16], "texture": "#0"},
                    "east": {"uv": [1, 0, 15, 16], "texture": "#0"},
                    "south": {"uv": [1, 0, 15, 16], "texture": "#0"},
                    "west": {"uv": [1, 0, 15, 16], "texture": "#0"},
                    "up": {"uv": [1, 0, 15, 14], "texture": "#0"},
                    "down": {"uv": [1, 2, 15, 16], "texture": "#0"},
                },
            }],
        }
        (model_dir / f"{wood}_{count}.json").write_text(json.dumps(model, separators=(",", ":")), encoding="utf-8")
        for axis in ("x", "z"):
            variants[f"wood={wood},axis={axis},count={count}"] = {
                "model": f"tfcagricultureplus:block/lumber_pile/{wood}_{count}"
            }
(assets / "blockstates/lumber_pile.json").write_text(json.dumps({"variants": variants}, separators=(",", ":")), encoding="utf-8")
print("lumber pile variants", len(variants), "woods", len(woods))
