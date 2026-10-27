#!/usr/bin/env python3
"""Static contract check for the B cooking-pan recipe set.

Checks:
- recipes parse and contain the required fields;
- the pan input tag resolves and every recipe food is accepted by it;
- the spice tag is non-empty;
- every referenced item has an item model in B/TFC/Firmalife;
- there are at least 14 real recipes with at least 10 distinct results.
"""
from __future__ import annotations

import json
import sys
import zipfile
from pathlib import Path

B_ROOT = Path(__file__).resolve().parents[1]
WORKSPACE = B_ROOT.parent.parent
DATA = B_ROOT / "src/main/resources/data/tfcagricultureplus"
ASSETS = B_ROOT / "src/main/resources/assets/tfcagricultureplus"
PAN_DIR = DATA / "recipe/pan"
TAGS = DATA / "tags/item"

errors: list[str] = []


def fail(message: str) -> None:
    errors.append(message)


def read_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def tag_values(tag_id: str, seen: set[str] | None = None) -> set[str]:
    """Resolve a B item tag to concrete item IDs; nested #tags are expanded."""
    if seen is None:
        seen = set()
    if tag_id in seen:
        return set()
    seen.add(tag_id)
    ns, path = tag_id.split(":", 1)
    if ns != "tfcagricultureplus":
        fail(f"unsupported tag namespace in pan check: {tag_id}")
        return set()
    tag_path = TAGS / f"{path}.json"
    if not tag_path.exists():
        fail(f"missing tag file: {tag_id}")
        return set()
    values = read_json(tag_path).get("values", [])
    out: set[str] = set()
    for value in values:
        if value.startswith("#"):
            out |= tag_values(value[1:], seen)
        else:
            out.add(value)
    return out


def model_exists(item_id: str) -> bool:
    ns, path = item_id.split(":", 1)
    b_model = ASSETS / "models/item" / f"{path}.json"
    if ns == "tfcagricultureplus":
        return b_model.exists()
    for jar_name, namespace in (
        ("TerraFirmaCraft-NeoForge-1.21.1-4.2.11.jar", "tfc"),
        ("Firmalife-NeoForge-1.21.1-3.0.15.jar", "firmalife"),
    ):
        if ns != namespace:
            continue
        jar_path = WORKSPACE / "mods" / jar_name
        if not jar_path.exists():
            fail(f"missing jar for model check: {jar_path}")
            return False
        with zipfile.ZipFile(jar_path) as jar:
            return f"assets/{ns}/models/item/{path}.json" in jar.namelist()
    if ns == "minecraft":
        return True
    fail(f"unknown namespace for model check: {item_id}")
    return False


recipes = []
for path in sorted(PAN_DIR.glob("*.json")):
    try:
        recipe = read_json(path)
    except Exception as exc:  # noqa: BLE001
        fail(f"{path.name}: invalid JSON: {exc}")
        continue
    if recipe.get("type") != "tfcagricultureplus:pan":
        fail(f"{path.name}: wrong type {recipe.get('type')!r}")
    for field in ("food", "spice", "result"):
        if field not in recipe:
            fail(f"{path.name}: missing {field}")
    try:
        if int(recipe.get("cook_ticks", 0)) < 1:
            fail(f"{path.name}: cook_ticks must be positive")
        if int(recipe.get("required_stirs", 0)) < 1:
            fail(f"{path.name}: required_stirs must be positive")
    except (TypeError, ValueError):
        fail(f"{path.name}: cook_ticks/required_stirs must be integers")
    recipes.append((path, recipe))

if len(recipes) < 14:
    fail(f"expected at least 14 pan recipes, found {len(recipes)}")

pan_inputs = tag_values("tfcagricultureplus:foods/pan_inputs")
spices = tag_values("tfcagricultureplus:foods/ground_spices")
if not pan_inputs:
    fail("pan_inputs tag resolved to no items")
if not spices:
    fail("ground_spices tag resolved to no items")

results: set[str] = set()
inputs: set[str] = set()
for path, recipe in recipes:
    food = recipe.get("food", {})
    if "item" in food:
        recipe_foods = {food["item"]}
    elif "tag" in food:
        recipe_foods = tag_values(food["tag"])
    else:
        fail(f"{path.name}: food must be item or tag")
        continue
    if not recipe_foods:
        fail(f"{path.name}: food resolved to no items")
    for item in recipe_foods:
        inputs.add(item)
        if item not in pan_inputs:
            fail(f"{path.name}: food {item} is not in pan_inputs")
    spice = recipe.get("spice", {})
    if "tag" in spice:
        resolved_spices = tag_values(spice["tag"])
    elif "item" in spice:
        resolved_spices = {spice["item"]}
    else:
        fail(f"{path.name}: spice must be item or tag")
        continue
    for item in resolved_spices:
        if item not in spices:
            fail(f"{path.name}: spice {item} is not in ground_spices")
    result = recipe.get("result", {})
    result_id = result.get("id")
    if not result_id:
        fail(f"{path.name}: result.id missing")
        continue
    results.add(result_id)
    if not model_exists(result_id):
        fail(f"{path.name}: result model missing for {result_id}")
    for item in recipe_foods | resolved_spices:
        if not model_exists(item):
            fail(f"{path.name}: input model missing for {item}")

if len(results) < 10:
    fail(f"expected at least 10 distinct pan results, found {len(results)}")
if len(inputs) < 15:
    fail(f"expected at least 15 distinct pan input items, found {len(inputs)}")

print(f"pan recipes={len(recipes)} inputs={len(inputs)} results={len(results)}")
print(f"pan_inputs={len(pan_inputs)} ground_spices={len(spices)}")
if errors:
    for error in errors:
        print(f"[FAIL] {error}")
    sys.exit(1)
print("[OK] pan recipe contract passed; runtime cooking behavior remains unverified")
