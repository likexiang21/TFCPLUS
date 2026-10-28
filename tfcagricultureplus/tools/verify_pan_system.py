#!/usr/bin/env python3
"""Static contract check for the dynamic pan / plate / bowl system."""
from __future__ import annotations

import json
import sys
from pathlib import Path

B = Path(__file__).resolve().parents[1]
RES = B / "src/main/resources"
ASSETS = RES / "assets/tfcagricultureplus"
DATA = RES / "data/tfcagricultureplus"
errors: list[str] = []

variants = [
    "wood", "ceramic", "ceramic_white", "ceramic_orange", "ceramic_magenta", "ceramic_light_blue",
    "ceramic_yellow", "ceramic_lime", "ceramic_pink", "ceramic_gray", "ceramic_light_gray",
    "ceramic_cyan", "ceramic_purple", "ceramic_blue", "ceramic_brown", "ceramic_green",
    "ceramic_red", "ceramic_black",
]


def need(path: Path) -> None:
    if not path.exists():
        errors.append(f"missing {path.relative_to(B)}")


def read_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


state = read_json(ASSETS / "blockstates/serving_plate.json")
for variant in variants:
    if variant not in state.get("variants", {}):
        errors.append(f"plate state missing {variant}")
    need(ASSETS / f"models/block/plate/{variant}.json")
    need(ASSETS / f"models/item/plate/{variant}.json")
    need(ASSETS / f"textures/block/plate/{variant}.png")

need(ASSETS / "models/item/bowl/wood.json")
need(ASSETS / "models/item/bowl/ceramic.json")
for material in ("wood", "wrought_iron", "steel", "black_steel", "blue_steel", "red_steel"):
    need(ASSETS / f"models/item/spatula/{material}.json")
    need(DATA / f"recipe/crafting/spatula_{material}.json")
for material in ("wrought_iron", "steel", "black_steel", "blue_steel", "red_steel"):
    need(ASSETS / f"models/item/spatula_head/{material}.json")
    need(DATA / f"recipe/anvil/spatula_head_{material}.json")

pan = B / "src/main/java/io/github/likexiang21/tfcplus/agriculture/common/blockentity/CookingPanBlockEntity.java"
text = pan.read_text(encoding="utf-8")
for token in ("IHeatable", "OIL_REQUIRED", "oilTank", "addIngredient", "stir", "serve", "FluidTank"):
    if token not in text:
        errors.append(f"pan missing token {token}")

# The old fixed pan recipe type/data must not be present.
if (B / "src/main/java/io/github/likexiang21/tfcplus/agriculture/common/recipe/PanRecipe.java").exists():
    errors.append("old PanRecipe.java still exists")
for path in (DATA / "recipe").rglob("*.json"):
    if path.parent.name == "pan":
        errors.append(f"old static pan recipe remains: {path.relative_to(B)}")

# Every recipe JSON must parse; new plate/bowl/spatula recipes must exist.
need(DATA / "recipe/crafting/plate_wood.json")
need(DATA / "recipe/knapping/ceramic/unfired_plate.json")
need(DATA / "recipe/heating/ceramic/unfired_plate.json")
need(DATA / "recipe/heating/ceramic/white_unfired_plate.json")
need(ASSETS / "models/item/metal_can.json")
need(DATA / "recipe/anvil/metal_can.json")
need(DATA / "recipe/heating/metal/metal_can.json")
need(DATA / "tags/fluid/metal_can_fluids.json")
need(DATA / "recipe/crafting/bowl_wood.json")
need(DATA / "recipe/crafting/bowl_ceramic.json")
for path in (DATA / "recipe").rglob("*.json"):
    try:
        read_json(path)
    except Exception as exc:  # noqa: BLE001
        errors.append(f"invalid recipe {path.relative_to(B)}: {exc}")

if errors:
    for error in errors:
        print(f"[FAIL] {error}")
    sys.exit(1)
print("[OK] dynamic pan/plate/bowl/spatula static contract passed")
