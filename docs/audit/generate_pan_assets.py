from pathlib import Path
import json
from PIL import Image, ImageDraw

root = Path("mod_rebuild/tfcagricultureplus/src/main/resources")
assets = root / "assets/tfcagricultureplus"
variants = [
    "wood", "ceramic_white", "ceramic_orange", "ceramic_magenta", "ceramic_light_blue",
    "ceramic_yellow", "ceramic_lime", "ceramic_pink", "ceramic_gray", "ceramic_light_gray",
    "ceramic_cyan", "ceramic_purple", "ceramic_blue", "ceramic_brown", "ceramic_green",
    "ceramic_red", "ceramic_black",
]
colors = {
    "wood": (128, 92, 52),
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
tex_dir = assets / "textures/block/plate"
model_dir = assets / "models/block/plate"
item_dir = assets / "models/item/plate"
states_dir = assets / "blockstates"
for d in (tex_dir, model_dir, item_dir, states_dir, assets / "models/item/bowl", assets / "models/item/spatula"):
    d.mkdir(parents=True, exist_ok=True)

for vid in variants:
    base = colors[vid]
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # A small plate seen from above: outer rim, inner depression, tiny highlight.
    d.ellipse((1, 2, 14, 13), fill=(base[0] // 2, base[1] // 2, base[2] // 2, 255))
    d.ellipse((2, 3, 13, 12), fill=(*base, 255))
    rim = (min(255, base[0] + 35), min(255, base[1] + 35), min(255, base[2] + 35), 255)
    d.ellipse((3, 4, 12, 11), outline=rim, width=1)
    inner = (max(0, base[0] - 20), max(0, base[1] - 20), max(0, base[2] - 20), 255)
    d.ellipse((4, 5, 11, 10), fill=inner)
    d.point((6, 5), fill=(255, 255, 255, 180))
    img.save(tex_dir / f"{vid}.png")
    model = {
        "parent": "block/block",
        "textures": {"0": f"tfcagricultureplus:block/plate/{vid}", "particle": f"tfcagricultureplus:block/plate/{vid}"},
        "elements": [{
            "from": [1, 0, 1], "to": [15, 1, 15],
            "faces": {
                "north": {"uv": [1, 0, 15, 1], "texture": "#0"},
                "east": {"uv": [1, 0, 15, 1], "texture": "#0"},
                "south": {"uv": [1, 0, 15, 1], "texture": "#0"},
                "west": {"uv": [1, 0, 15, 1], "texture": "#0"},
                "up": {"uv": [1, 1, 15, 15], "texture": "#0"},
                "down": {"uv": [1, 1, 15, 15], "texture": "#0"},
            },
        }],
    }
    (model_dir / f"{vid}.json").write_text(json.dumps(model, separators=(",", ":")), encoding="utf-8")
    (item_dir / f"{vid}.json").write_text(json.dumps({"parent": f"tfcagricultureplus:block/plate/{vid}"}, separators=(",", ":")), encoding="utf-8")

state = {"variants": {vid: {"model": f"tfcagricultureplus:block/plate/{vid}"} for vid in variants}}
(states_dir / "serving_plate.json").write_text(json.dumps(state, separators=(",", ":")), encoding="utf-8")
(assets / "models/item/bowl/wood.json").write_text(
    json.dumps({"parent": "item/generated", "textures": {"layer0": "tfc:block/wooden_bowl"}}, separators=(",", ":")), encoding="utf-8")
(assets / "models/item/bowl/ceramic.json").write_text(
    json.dumps({"parent": "item/generated", "textures": {"layer0": "tfc:item/ceramic/bowl"}}, separators=(",", ":")), encoding="utf-8")
for material in ("copper", "bismuth_bronze", "bronze", "wrought_iron", "steel", "black_steel"):
    (assets / f"models/item/spatula/{material}.json").write_text(
        json.dumps({"parent": "item/handheld",
                    "textures": {"layer0": f"tfc:item/metal/knife/{material}"}}, separators=(",", ":")), encoding="utf-8")

# ---- recipes ----
recipes = root / "data/tfcagricultureplus/recipe"
recipes.mkdir(parents=True, exist_ok=True)
crafting = recipes / "crafting"
crafting.mkdir(exist_ok=True)
(crafting / "plate_wood.json").write_text(json.dumps({
    "type": "minecraft:crafting_shapeless",
    "ingredients": [{"tag": "tfc:lumber"}],
    "result": {"id": "tfcagricultureplus:plate/wood", "count": 1},
}, indent=2) + "\n", encoding="utf-8")
(crafting / "plate_ceramic_white.json").write_text(json.dumps({
    "type": "minecraft:crafting_shapeless",
    "ingredients": [{"item": "tfc:ceramic/bowl"}],
    "result": {"id": "tfcagricultureplus:plate/ceramic_white", "count": 1},
}, indent=2) + "\n", encoding="utf-8")
dye = {
    "orange": "orange_dye", "magenta": "magenta_dye", "light_blue": "light_blue_dye",
    "yellow": "yellow_dye", "lime": "lime_dye", "pink": "pink_dye", "gray": "gray_dye",
    "light_gray": "light_gray_dye", "cyan": "cyan_dye", "purple": "purple_dye",
    "blue": "blue_dye", "brown": "brown_dye", "green": "green_dye", "red": "red_dye",
    "black": "black_dye",
}
for color, dye_item in dye.items():
    (crafting / f"plate_ceramic_{color}.json").write_text(json.dumps({
        "type": "minecraft:crafting_shapeless",
        "ingredients": [{"item": "tfcagricultureplus:plate/ceramic_white"}, {"item": f"minecraft:{dye_item}"}],
        "result": {"id": f"tfcagricultureplus:plate/ceramic_{color}", "count": 1},
    }, indent=2) + "\n", encoding="utf-8")
(crafting / "bowl_wood.json").write_text(json.dumps({
    "type": "minecraft:crafting_shapeless",
    "ingredients": [{"tag": "tfc:lumber"}, {"tag": "tfc:lumber"}],
    "result": {"id": "tfcagricultureplus:bowl/wood", "count": 1},
}, indent=2) + "\n", encoding="utf-8")
(crafting / "bowl_ceramic.json").write_text(json.dumps({
    "type": "minecraft:crafting_shapeless",
    "ingredients": [{"item": "tfc:ceramic/bowl"}],
    "result": {"id": "tfcagricultureplus:bowl/ceramic", "count": 1},
}, indent=2) + "\n", encoding="utf-8")
metals = {"copper": "copper", "bismuth_bronze": "bismuth_bronze", "bronze": "bronze",
          "wrought_iron": "wrought_iron", "steel": "steel", "black_steel": "black_steel"}
for mat in metals:
    (crafting / f"spatula_{mat}.json").write_text(json.dumps({
        "type": "minecraft:crafting_shapeless",
        "ingredients": [{"item": f"tfc:metal/ingot/{mat}"}, {"tag": "tfc:lumber"}],
        "result": {"id": f"tfcagricultureplus:spatula/{mat}", "count": 1},
    }, indent=2) + "\n", encoding="utf-8")
print("generated plate variants", len(variants), "assets")
