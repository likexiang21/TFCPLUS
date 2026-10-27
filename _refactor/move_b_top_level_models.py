#!/usr/bin/env python3
"""Move B top-level block models into their family folders.

Blockstate/registry IDs stay unchanged; only model references are rewritten.
"""
from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "tfcagricultureplus/src/main/resources/assets/tfcagricultureplus"

MAPPING = {
    "cooking_pan": "cooking_pan/cooking_pan",
    "dough_forming_table": "dough_forming_table/dough_forming_table",
    "melting_pot": "melting_pot/melting_pot",
    "cutting_board": "cutting_board/cutting_board",
    "knife_block": "knife_block/knife_block",
    "log_cutting_board": "log_cutting_board/log_cutting_board",
    "mortar": "mortar/mortar",
    "silkworm_rack_stage0": "silkworm_rack/stage0",
    "silkworm_rack_stage1": "silkworm_rack/stage1",
    "silkworm_rack_stage2": "silkworm_rack/stage2",
    "butter_block": "food/butter_block",
    "chocolate_cake": "food/chocolate_cake",
    "cream_cake": "food/cream_cake",
    "jelly_block": "food/jelly_block",
    "sugar_block": "food/sugar_block",
    "whole_cake": "food/whole_cake",
    "whole_cheese": "food/whole_cheese",
    "whole_pie": "food/whole_pie",
}


def main() -> int:
    model_root = ASSETS / "models/block"
    for old, new in MAPPING.items():
        source = model_root / f"{old}.json"
        if not source.exists():
            print(f"MISSING {old}")
            continue
        target = model_root / f"{new}.json"
        target.parent.mkdir(parents=True, exist_ok=True)
        source.rename(target)
        print(f"{old}.json -> {new}.json")

    for json_path in ASSETS.rglob("*.json"):
        text = json_path.read_text(encoding="utf-8")
        original = text
        for old, new in MAPPING.items():
            text = text.replace(f"tfcagricultureplus:block/{old}", f"tfcagricultureplus:block/{new}")
        if text != original:
            json_path.write_text(text, encoding="utf-8", newline="\n")
            print(f"rewrote {json_path.relative_to(ASSETS)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
