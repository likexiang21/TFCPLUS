import json
from pathlib import Path
from PIL import Image, ImageDraw

root = Path("mod_rebuild/tfcagricultureplus/src/main/resources")
assets = root / "assets/tfcagricultureplus"
data = root / "data/tfcagricultureplus"
colors = {
    "ceramic": (225, 226, 216),
    "ceramic_white": (235, 235, 225),
    "ceramic_orange": (230, 126, 34),
    "ceramic_magenta": (199, 78, 189),
    "ceramic_light_blue": (58, 175, 217),
    "ceramic_yellow": (249, 198, 39),
    "ceramic_lime": (128, 199, 31),
    "ceramic_pink": (243, 139, 170),
    "ceramic_gray": (73, 82, 86),
    "ceramic_light_gray": (154, 161, 161),
    "ceramic_cyan": (22, 156, 156),
    "ceramic_purple": (137, 50, 184),
    "ceramic_blue": (60, 68, 170),
    "ceramic_brown": (131, 84, 50),
    "ceramic_green": (94, 124, 22),
    "ceramic_red": (176, 46, 38),
    "ceramic_black": (29, 29, 33),
}
variants = ["wood"] + list(colors)
tex_dir = assets / "textures/block/plate"
model_dir = assets / "models/block/plate"
item_dir = assets / "models/item/plate"
for d in (tex_dir, model_dir, item_dir):
    d.mkdir(parents=True, exist_ok=True)
for vid in variants:
    base = (128, 92, 52) if vid == "wood" else colors[vid]
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0)); d = ImageDraw.Draw(img)
    d.ellipse((1, 2, 14, 13), fill=(base[0] // 2, base[1] // 2, base[2] // 2, 255))
    d.ellipse((2, 3, 13, 12), fill=(*base, 255))
    d.ellipse((3, 4, 12, 11), outline=(min(255, base[0] + 35), min(255, base[1] + 35), min(255, base[2] + 35), 255), width=1)
    d.ellipse((4, 5, 11, 10), fill=(max(0, base[0] - 20), max(0, base[1] - 20), max(0, base[2] - 20), 255))
    d.point((6, 5), fill=(255, 255, 255, 180))
    img.save(tex_dir / f"{vid}.png")
    model = {"parent": "block/block",
             "textures": {"0": f"tfcagricultureplus:block/plate/{vid}", "particle": f"tfcagricultureplus:block/plate/{vid}"},
             "elements": [{"from": [1, 0, 1], "to": [15, 1, 15],
                           "faces": {"north": {"uv": [1, 0, 15, 1], "texture": "#0"}, "east": {"uv": [1, 0, 15, 1], "texture": "#0"},
                                     "south": {"uv": [1, 0, 15, 1], "texture": "#0"}, "west": {"uv": [1, 0, 15, 1], "texture": "#0"},
                                     "up": {"uv": [1, 1, 15, 15], "texture": "#0"}, "down": {"uv": [1, 1, 15, 15], "texture": "#0"}}}]}
    (model_dir / f"{vid}.json").write_text(json.dumps(model, separators=(",", ":")), encoding="utf-8")
    (item_dir / f"{vid}.json").write_text(json.dumps({"parent": f"tfcagricultureplus:block/plate/{vid}"}, separators=(",", ":")), encoding="utf-8")
(assets / "blockstates/serving_plate.json").write_text(
    json.dumps({"variants": {vid: {"model": f"tfcagricultureplus:block/plate/{vid}"} for vid in variants}}, separators=(",", ":")), encoding="utf-8")

# unfired plate models (17: colorless + 16 colors), all share the unfired-bowl placeholder texture
uf = assets / "models/item/ceramic"; uf.mkdir(parents=True, exist_ok=True)
for vid in colors:
    suffix = "unfired_plate" if vid == "ceramic" else f"{vid.removeprefix('ceramic_')}_unfired_plate"
    (uf / f"{suffix}.json").write_text(json.dumps({"parent": "item/generated", "textures": {"layer0": "tfc:item/ceramic/unfired_bowl"}}, separators=(",", ":")), encoding="utf-8")

# heating recipes: each unfired plate -> matching plate
heat = data / "recipe/heating/ceramic"; heat.mkdir(parents=True, exist_ok=True)
for vid in colors:
    suffix = "unfired_plate" if vid == "ceramic" else f"{vid.removeprefix('ceramic_')}_unfired_plate"
    (heat / f"{suffix}.json").write_text(json.dumps({
        "type": "tfc:heating",
        "ingredient": {"item": f"tfcagricultureplus:ceramic/{suffix}"},
        "result_item": {"count": 1, "id": f"tfcagricultureplus:plate/{vid}"},
        "temperature": 1399.0,
    }, indent=2) + "\n", encoding="utf-8")

# colorless unfired plate -> dyed unfired plate (pre-firing coloring, like TFC vessels)
craft = data / "recipe/crafting/ceramic"; craft.mkdir(parents=True, exist_ok=True)
for vid, col in colors.items():
    if vid == "ceramic":
        continue
    color = vid.removeprefix("ceramic_")
    suffix = f"{color}_unfired_plate"
    (craft / f"{suffix}.json").write_text(json.dumps({
        "type": "minecraft:crafting_shapeless", "category": "misc",
        "ingredients": [{"item": f"minecraft:{color}_dye"}, {"item": "tfcagricultureplus:ceramic/unfired_plate"}],
        "result": {"count": 1, "id": f"tfcagricultureplus:ceramic/{suffix}"},
    }, indent=2) + "\n", encoding="utf-8")

# Remove old single-color heating recipe
old = heat / "plate_ceramic_white.json"
if old.exists():
    old.unlink()
print("ceramic plate variants", len(colors), "total plate variants", len(variants))
