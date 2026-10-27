"""Compose review sheets and export exact current assets to an isolated folder."""
from pathlib import Path
import io
import json
import math
import runpy
import shutil

from PIL import Image, ImageDraw, ImageFont

OUT = Path(__file__).resolve().parent
context = runpy.run_path(str(OUT / "collect-current-references.py"))
ROOT = context["ROOT"]
index = context["index"]
resource = context["resource"]
model = context["model"]
slot = context["slot"]

# Reopen archive handles closed by the inventory script.
for archive in context["archives"]:
    import zipfile
    reopened = zipfile.ZipFile(archive.filename)
    for key, entry in list(index.items()):
        if isinstance(entry, tuple) and entry[0] is archive:
            index[key] = (reopened, entry[1])


def read(key):
    entry = index[key]
    return entry.read_bytes() if isinstance(entry, Path) else entry[0].read(entry[1])


font = ImageFont.truetype("C:/Windows/Fonts/consola.ttf", 16)
pages = []


def sheet(name, cells, columns=6):
    width, height = 220, 266
    canvas = Image.new("RGB", (columns * width, math.ceil(len(cells) / columns) * height), (32, 33, 39))
    draw = ImageDraw.Draw(canvas)
    for i, (label, key) in enumerate(cells):
        x, y = (i % columns) * width, (i // columns) * height
        original = Image.open(io.BytesIO(read(key))).convert("RGBA")
        original = original.resize((192, 192), Image.Resampling.NEAREST)
        for yy in range(12):
            for xx in range(12):
                color = (63, 65, 71) if (xx + yy) % 2 else (45, 47, 53)
                draw.rectangle((x + 12 + xx * 16, y + 8 + yy * 16, x + 27 + xx * 16, y + 23 + yy * 16), fill=color)
        canvas.paste(original, (x + 12, y + 8), original)
        for line, text in enumerate(label.split("\n")):
            draw.text((x + 6, y + 204 + line * 19), text, font=font, fill=(230, 231, 205))
    canvas.save(OUT / name)
    pages.append({"File": name, "Cells": [{"Label": label, "Path": key, "Sha256": context["digest"](read(key))} for label, key in cells]})


for crop in ["chili", "fenugreek"]:
    cells = []
    for age in range(6):
        resolved = model(f"tfcfarmingplus:block/crop/{crop}_age_{age}")
        texture = slot("#crop", resolved["textures"])
        cells.append((f"CURRENT {crop} {age}\n{texture}", resource(texture, "textures", "png")))
    for age in range(6):
        texture = f"tfcfarmingplus:block/crop/{crop}_age_{age}"
        cells.append((f"STORED {crop} {age}\nnot current model", resource(texture, "textures", "png")))
    sheet(f"AR4K-{crop}-current-stored.png", cells)

sheet("AR4K-dead-bush-textures.png", [(f"stage{age} {part}\nCURRENT", resource(f"tfcfarmingplus:block/plant/dead_berry_bush_{age}_{part}", "textures", "png")) for age in range(3) for part in ["bush", "cane"]], 3)
sheet("AR4K-papaya-leaves.png", [(f"papaya {state}\nCURRENT full cube", resource(f"tfcfarmingplus:block/fruit_tree/papaya_{state}", "textures", "png")) for state in ["leaves", "dry_leaves", "flowering_leaves", "fruiting_leaves"]], 4)
seed_cells = []
for name in ["chili", "fenugreek", "hemp", "flax", "cotton", "ramie"]:
    resolved = model(f"tfcfarmingplus:item/seeds/{name}")
    texture = slot("#layer0", resolved["textures"])
    seed_cells.append((f"CURRENT {name}\n{texture}", resource(texture, "textures", "png")))
for name in ["chili", "fenugreek", "hemp", "flax", "cotton", "ramie"]:
    seed_cells.append((f"STORED {name}\nnot current model", resource(f"tfcfarmingplus:item/seeds/{name}", "textures", "png")))
sheet("AR4K-seeds-current-stored.png", seed_cells)

selected = [f"tfcfarmingplus:block/crop/{name}_age_{age}" for name in ["chili", "fenugreek"] for age in range(6)]
selected += [f"tfcfarmingplus:block/plant/dead_berry_bush_{age}" for age in range(3)]
selected += [f"tfcfarmingplus:block/plant/papaya_{state}" for state in ["leaves", "dry_leaves", "flowering_leaves", "fruiting_leaves"]]
keys = set()
for identifier in selected:
    resolved = model(identifier)
    keys.update(resolved["chain"])
    for value in resolved["textures"].values():
        keys.add(resource(slot(value, resolved["textures"]), "textures", "png"))
assets = OUT / "assets-current"
for key in sorted(keys):
    path = OUT / "assets-current" / key.removeprefix("assets/")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(read(key))
(OUT / "current-models.txt").write_text("\n".join(selected) + "\n", encoding="utf-8")
(OUT / "preview-sources.json").write_text(json.dumps({"Sheets": pages, "AssetFiles": [{"Path": key, "Origin": context["origin"](key), "Sha256": context["digest"](read(key))} for key in sorted(keys)], "Models": selected}, indent=2, ensure_ascii=False), encoding="utf-8")
print(f"Prepared {len(pages)} texture sheets and {len(selected)} current models from {len(keys)} exact assets.")
