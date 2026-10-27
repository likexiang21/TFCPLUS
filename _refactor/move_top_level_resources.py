#!/usr/bin/env python3
"""Move the remaining top-level A block models/textures into topic folders.

Only model/texture paths move; blockstate files and registry IDs stay put.
"""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
A = ROOT / "tfcfarmingplus/src/main/resources/assets/tfcfarmingplus"

MELON_MODELS = [
    "bottle_gourd",
    "cantaloupe",
    "rotten_bottle_gourd",
    "rotten_cantaloupe",
    "rotten_winter_melon",
    "winter_melon",
]
PLANT_MODELS = ["dead_rosette", "dead_rosette_young"]
TEXTURE_PREFIXES = [
    "bottle_gourd_fruit_",
    "cantaloupe_fruit_",
    "rotten_bottle_gourd_fruit_",
    "rotten_cantaloupe_fruit_",
    "rotten_winter_melon_fruit_",
    "winter_melon_fruit_",
]


def ref(key: str, old: str, new: str, text: str) -> str:
    return text.replace(f"tfcfarmingplus:block/{old}", f"tfcfarmingplus:block/{new}")


def main() -> int:
    model_dir = A / "models/block"
    melon_dir = model_dir / "melon"
    plant_dir = model_dir / "plant"
    melon_dir.mkdir(parents=True, exist_ok=True)
    plant_dir.mkdir(parents=True, exist_ok=True)
    for name in MELON_MODELS:
        src = model_dir / f"{name}.json"
        if src.exists():
            src.rename(melon_dir / src.name)
            print(f"model {name} -> melon/")
    for name in PLANT_MODELS:
        src = model_dir / f"{name}.json"
        if src.exists():
            src.rename(plant_dir / src.name)
            print(f"model {name} -> plant/")

    texture_dir = A / "textures/block"
    melon_texture_dir = texture_dir / "melon"
    melon_texture_dir.mkdir(parents=True, exist_ok=True)
    for png in sorted(texture_dir.glob("*.png")):
        if any(png.name.startswith(prefix) for prefix in TEXTURE_PREFIXES):
            png.rename(melon_texture_dir / png.name)
            print(f"texture {png.name} -> melon/")

    # Rewrite every JSON reference under assets/ and data/.
    for json_path in A.rglob("*.json"):
        text = json_path.read_text(encoding="utf-8")
        original = text
        for name in MELON_MODELS:
            text = ref("model", name, f"melon/{name}", text)
        for name in PLANT_MODELS:
            text = ref("model", name, f"plant/{name}", text)
        if text != original:
            json_path.write_text(text, encoding="utf-8", newline="\n")
            print(f"rewrote {json_path.relative_to(A)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
