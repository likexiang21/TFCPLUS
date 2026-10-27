"""Inventory actual item-model layers and compose review pages without editing art."""
from collections import Counter
from functools import lru_cache
from pathlib import Path
import csv
import hashlib
import io
import json
import math
import zipfile

from PIL import Image, ImageDraw, ImageFont

ROOT = Path.cwd()
OUT = Path(__file__).resolve().parent
RES = ROOT / "moddev/tfcfarmingplus/src/main/resources"
index = {}
archives = []
collisions = []


def sha(data):
    return hashlib.sha256(data).hexdigest().upper()


def canonical(identifier):
    return identifier if ":" in identifier else "minecraft:" + identifier


def key(identifier, kind, extension):
    namespace, path = canonical(identifier).split(":", 1)
    return f"assets/{namespace}/{kind}/{path}.{extension}"


for path in sorted((ROOT / "mods").glob("*.jar")) + [Path("D:/TFC农业重置/.tooling/game/versions/1.21.1/1.21.1.jar")]:
    archive = zipfile.ZipFile(path)
    archives.append(archive)
    for name in archive.namelist():
        if name.startswith("assets/") and name.endswith((".png", ".json")):
            index.setdefault(name, (archive, name))
for module in ["tfcfarmingplus", "tfcagricultureplus"]:
    resources = ROOT / f"moddev/{module}/src/main/resources"
    for path in sorted((resources / "assets").rglob("*")):
        if path.is_file():
            name = path.relative_to(resources).as_posix()
            if name in index and isinstance(index[name], Path):
                collisions.append(name)
            index[name] = path


def read(name):
    source = index[name]
    return source.read_bytes() if isinstance(source, Path) else source[0].read(source[1])


def origin(name):
    source = index[name]
    return str(source.relative_to(ROOT)) if isinstance(source, Path) else source[0].filename + "!/" + source[1]


@lru_cache(None)
def resolve(identifier):
    identifier = canonical(identifier)
    if identifier.startswith("minecraft:builtin/"):
        return {"textures": {}, "chain": [], "root": identifier}
    name = key(identifier, "models", "json")
    data = json.loads(read(name).decode("utf-8-sig"))
    parent = resolve(data["parent"]) if data.get("parent") else {"textures": {}, "chain": []}
    return dict(parent) | data | {"textures": parent["textures"] | data.get("textures", {}), "chain": [name] + parent["chain"]}


def atlas(value, textures):
    seen = set()
    while value.startswith("#"):
        if value in seen:
            raise ValueError("Cyclic item texture alias")
        seen.add(value)
        value = textures[value[1:]]
    return canonical(value)


language = json.loads((RES / "assets/tfcfarmingplus/lang/zh_cn.json").read_text(encoding="utf-8-sig"))
records = []
for family in ["food", "seeds"]:
    for path in sorted((RES / f"assets/tfcfarmingplus/models/item/{family}").glob("*.json")):
        identifier = f"tfcfarmingplus:item/{family}/{path.stem}"
        model = resolve(identifier)
        layers = [atlas(value, model["textures"]) for slot, value in sorted(model["textures"].items()) if slot.startswith("layer")]
        if len(layers) != 1 or model.get("elements"):
            raise ValueError("This review requires a single generated layer: " + identifier)
        current = key(layers[0], "textures", "png")
        stored = f"assets/tfcfarmingplus/textures/item/{family}/{path.stem}.png"
        records.append({"Family": family, "Name": path.stem, "ChineseName": language.get(f"item.tfcfarmingplus.{family}.{path.stem}", path.stem),
                        "Model": identifier, "ModelOrigin": origin(key(identifier, "models", "json")), "ModelSha256": sha(read(key(identifier, "models", "json"))),
                        "ParentChain": model["chain"], "CurrentTexture": layers[0], "CurrentOrigin": origin(current), "CurrentSha256": sha(read(current)),
                        "StoredTexture": stored if stored in index else None, "StoredSha256": sha(read(stored)) if stored in index else None,
                        "CurrentEqualsStoredBytes": stored in index and read(current) == read(stored), "VisualAccepted": False, "RuntimeVerified": False})

font = ImageFont.truetype("C:/Windows/Fonts/msyh.ttc", 18)
small = ImageFont.truetype("C:/Windows/Fonts/consola.ttf", 13)
pages = []
for family in ["food", "seeds"]:
    group = [row for row in records if row["Family"] == family]
    for page in range(math.ceil(len(group) / 9)):
        subset = group[page * 9:(page + 1) * 9]
        canvas = Image.new("RGB", (3 * 488, 3 * 324 + 30), (28, 30, 35))
        draw = ImageDraw.Draw(canvas)
        draw.text((5, 2), f"{family} page {page + 1}: LEFT actual model / RIGHT stored PNG; 14x", font=small, fill="white")
        cells = []
        for cell, row in enumerate(subset):
            x, y = (cell % 3) * 488, (cell // 3) * 324 + 30
            draw.text((x + 3, y), f"{page * 9 + cell + 1:03} {row['ChineseName']} / {row['Name']}", font=font, fill=(238, 235, 210))
            sources = [key(row["CurrentTexture"], "textures", "png"), row["StoredTexture"]]
            for side, source in enumerate(sources):
                left, top = x + 4 + side * 240, y + 30
                for yy in range(14):
                    for xx in range(14):
                        draw.rectangle((left + xx * 16, top + yy * 16, left + xx * 16 + 15, top + yy * 16 + 15), fill=(51, 54, 60) if (xx + yy) % 2 else (40, 42, 48))
                if source:
                    sprite = Image.open(io.BytesIO(read(source))).convert("RGBA").resize((224, 224), Image.Resampling.NEAREST)
                    canvas.paste(sprite, (left, top), sprite)
                else:
                    draw.text((left + 10, top + 80), "NO STORED PNG", font=small, fill="white")
            for line, label in enumerate([row["CurrentTexture"], "stored: " + (row["Name"] if row["StoredTexture"] else "missing")]):
                draw.text((x + 3, y + 258 + line * 20), label, font=small, fill=(211, 220, 233))
            cells.append({"Index": page * 9 + cell + 1, "Name": row["Name"], "ChineseName": row["ChineseName"], "CurrentTexture": row["CurrentTexture"]})
        filename = f"AR4O-{family}-p{page + 1:02}.png"
        canvas.save(OUT / filename)
        pages.append({"File": filename, "Cells": cells})

summary = {"ModelFiles": len(records), "FoodModels": sum(row["Family"] == "food" for row in records),
           "SeedModels": sum(row["Family"] == "seeds" for row in records), "StoredPNGAvailable": sum(bool(row["StoredTexture"]) for row in records),
           "CurrentNamespace": dict(Counter(row["CurrentTexture"].split(":")[0] for row in records)), "SourceCollisions": collisions,
           "ReviewPages": len(pages), "Scope": "A food/seeds model conventions, not proof of every Java registration or external resource-pack order",
           "VisualAccepted": False, "RuntimeVerified": False}
for filename, value in [("item-icon-references.json", records), ("review-pages.json", pages), ("reference-summary.json", summary)]:
    (OUT / filename).write_text(json.dumps(value, ensure_ascii=False, indent=2), encoding="utf-8")
with (OUT / "item-icon-references.csv").open("w", encoding="utf-8-sig", newline="") as stream:
    writer = csv.DictWriter(stream, fieldnames=["Family", "Name", "ChineseName", "CurrentTexture", "CurrentOrigin", "CurrentEqualsStoredBytes", "VisualAccepted", "RuntimeVerified"])
    writer.writeheader()
    writer.writerows({key: row[key] for key in writer.fieldnames} for row in records)
for archive in archives:
    archive.close()
print(json.dumps(summary, ensure_ascii=False))
