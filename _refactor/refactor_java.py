#!/usr/bin/env python3
"""Rebuild Java tree for mod_rebuild.

Reads the copied old Java sources under mod_rebuild/<module>/src/main/java,
renames classes/files, moves them into the target package layout, rewrites
package/import references, and writes the new tree.

Default is a dry run. Pass --apply to write files.
"""
from __future__ import annotations

import argparse
import csv
import re
import sys
from pathlib import Path

MOD_REBUILD = Path(__file__).resolve().parents[1]
A_ROOT = MOD_REBUILD / "tfcfarmingplus" / "src" / "main" / "java"
B_ROOT = MOD_REBUILD / "tfcagricultureplus" / "src" / "main" / "java"

A_OLD_ROOT = "com.example.tfcfarmingplus"
B_OLD_ROOT = "com.example.tfcfarmingplus.expansion"
A_NEW_ROOT = "io.github.likexiang21.tfcplus.farming"
B_NEW_ROOT = "io.github.likexiang21.tfcplus.agriculture"

A_RENAME = {
    "MyBlockEntities": "FarmingBlockEntities",
    "MyBlocks": "FarmingBlocks",
    "MyBranchFruits": "FarmingBranchFruits",
    "MyBushes": "FarmingBushes",
    "MyClimateRanges": "FarmingClimateRanges",
    "MyCreativeTab": "FarmingCreativeTab",
    "MyCrops": "FarmingCrops",
    "MyDebugCommands": "FarmingDebugCommands",
    "MyFruitTrees": "FarmingFruitTrees",
    "MyItems": "FarmingItems",
    "MySpeciesApi": "SpeciesLookup",
    "MyWildCrops": "FarmingWildCrops",
    "MyBerryBushBlockEntity": "FarmingBerryBushBlockEntity",
    "MyDecayingBlockEntity": "FarmingDecayingBlockEntity",
    "MyBerryBushBlock": "FarmingBerryBushBlock",
    "MyClimbingCropBlock": "FarmingClimbingCropBlock",
    "MyCropBlock": "FarmingCropBlock",
    "MyDecayingBlock": "FarmingDecayingBlock",
    "MyDoubleCropBlock": "FarmingDoubleCropBlock",
    "MyFloodedCropBlock": "FarmingFloodedCropBlock",
    "MyFruitingBranchBlock": "FarmingFruitingBranchBlock",
    "MyFruitTreeLeavesBlock": "FarmingFruitTreeLeavesBlock",
    "MyFruitTreeSaplingBlock": "FarmingFruitTreeSaplingBlock",
    "MyGrowingFruitTreeBranchBlock": "FarmingGrowingFruitTreeBranchBlock",
    "MyPickableCropBlock": "FarmingPickableCropBlock",
    "MySeasonalPlantFix": "SeasonalPlantTimers",
    "MySpreadingBushBlock": "FarmingSpreadingBushBlock",
    "MySpreadingCaneBlock": "FarmingSpreadingCaneBlock",
    "MySpreadingCropBlock": "FarmingSpreadingCropBlock",
    "MyBushBlockItem": "FarmingBushBlockItem",
    "MyFruitTreeSaplingItem": "FarmingFruitTreeSaplingItem",
    "MySeedItem": "FarmingSeedItem",
}

A_COMMON_TARGET = {
    "MyBlockEntities": "common.registry",
    "MyBlocks": "common.registry",
    "MyBranchFruits": "common.tree",
    "MyBushes": "common.crop",
    "MyClimateRanges": "common.registry",
    "MyCreativeTab": "common.registry",
    "MyCrops": "common.crop",
    "MyDebugCommands": "common.debug",
    "MyFruitTrees": "common.tree",
    "MyItems": "common.registry",
    "MySpeciesApi": "common.api",
    "MyWildCrops": "common.crop",
    "FastGrow": "common.debug",
}

B_RENAME = {
    "MyBlockEntities": "AgricultureBlockEntities",
    "MyBlocks": "AgricultureBlocks",
    "MyCreativeTab": "AgricultureCreativeTab",
    "MyFoodTraits": "AgricultureFoodTraits",
    "MyItems": "AgricultureItems",
    "MyMenuTypes": "AgricultureMenuTypes",
    "MyRecipeSerializers": "AgricultureRecipeSerializers",
    "MyRecipeTypes": "AgricultureRecipeTypes",
    "MyTags": "AgricultureTags",
    "MyWoodworkingSounds": "WoodworkingSounds",
    "MyJeiPlugin": "AgricultureJeiPlugin",
    "SawdustSoupBowl": "SawdustSoupBowlItem",
    "KnifeBlockBlockEntityRenderer": "KnifeRackBlockEntityRenderer",
    "KnifeBlockBlockEntity": "KnifeRackBlockEntity",
    "KnifeBlockBlock": "KnifeRackBlock",
    "TimberPileRenderer": "TimberPileBlockEntityRenderer",
}

B_COMMON_TARGET = {
    "AdultSilkwormItem": "common.item",
    "BakingOvenRules": "common.kitchen",
    "CookingPanBlock": "common.block",
    "CuttingBoardInteractions": "common.interaction",
    "CuttingBoardLeftClickHandler": "common.interaction",
    "DebugValidation": "common.debug",
    "DoughFormingInteractions": "common.interaction",
    "DoughFormingTableBlock": "common.block",
    "DryingRackBlock": "common.block",
    "DryingRackInteractions": "common.interaction",
    "KitchenStorageBlock": "common.block",
    "MeltingPotBlock": "common.block",
    "MeltingPotInteractions": "common.interaction",
    "MortarInteractions": "common.interaction",
    "MyBlockEntities": "common.registry",
    "MyBlocks": "common.registry",
    "MyCreativeTab": "common.registry",
    "MyFoodTraits": "common.registry",
    "MyItems": "common.registry",
    "MyTags": "common.registry",
    "MyWoodworkingSounds": "common.registry",
    "PanInteractions": "common.interaction",
    "PlaceableFoodBlock": "common.block",
    "SawdustSoupBowl": "common.item",
    "SilkwormContainerEvents": "common.silkworm",
    "SilkwormData": "common.silkworm",
    "SilkwormEggDrops": "common.silkworm",
    "SilkwormRackBlock": "common.block",
    "SilkwormRackInteractions": "common.interaction",
}

B_RENDERERS = {"CuttingBoardBlockEntityRenderer", "KnifeBlockBlockEntityRenderer", "TimberPileRenderer"}
B_SCREENS = {"KitchenStorageScreen", "SilkwormRackScreen"}


def read_package_and_class(path: Path) -> tuple[str, str]:
    text = path.read_text(encoding="utf-8")
    match = re.search(r"(?m)^\s*package\s+([\w.]+);", text)
    if not match:
        raise RuntimeError(f"missing package declaration: {path}")
    return match.group(1), path.stem


def target_a(old_pkg: str, name: str) -> tuple[str, str]:
    new_name = A_RENAME.get(name, name)
    if old_pkg == A_OLD_ROOT:
        return A_NEW_ROOT, new_name
    if old_pkg == A_OLD_ROOT + ".client":
        return A_NEW_ROOT + ".client", new_name
    if old_pkg == A_OLD_ROOT + ".common":
        if name not in A_COMMON_TARGET:
            raise RuntimeError(f"A common class without target package: {name}")
        return A_NEW_ROOT + "." + A_COMMON_TARGET[name], new_name
    if old_pkg == A_OLD_ROOT + ".common.blockentities":
        return A_NEW_ROOT + ".common.blockentity", new_name
    if old_pkg == A_OLD_ROOT + ".common.blocks":
        if name == "MySeasonalPlantFix":
            return A_NEW_ROOT + ".common.support", new_name
        return A_NEW_ROOT + ".common.block", new_name
    if old_pkg == A_OLD_ROOT + ".common.items":
        return A_NEW_ROOT + ".common.item", new_name
    raise RuntimeError(f"unmapped A package: {old_pkg} / {name}")


def target_b(old_pkg: str, name: str) -> tuple[str, str]:
    new_name = B_RENAME.get(name, name)
    if old_pkg == B_OLD_ROOT:
        return B_NEW_ROOT, new_name
    if old_pkg == B_OLD_ROOT + ".client":
        if name in B_RENDERERS:
            return B_NEW_ROOT + ".client.renderer", new_name
        if name in B_SCREENS:
            return B_NEW_ROOT + ".client.screen", new_name
        return B_NEW_ROOT + ".client", new_name
    if old_pkg == B_OLD_ROOT + ".common":
        if name not in B_COMMON_TARGET:
            raise RuntimeError(f"B common class without target package: {name}")
        return B_NEW_ROOT + "." + B_COMMON_TARGET[name], new_name
    if old_pkg == B_OLD_ROOT + ".common.blockentities":
        return B_NEW_ROOT + ".common.blockentity", new_name
    if old_pkg == B_OLD_ROOT + ".common.container":
        if name == "MyMenuTypes":
            return B_NEW_ROOT + ".common.registry", new_name
        return B_NEW_ROOT + ".common.menu", new_name
    if old_pkg == B_OLD_ROOT + ".common.recipe":
        return B_NEW_ROOT + ".common.recipe", new_name
    if old_pkg == B_OLD_ROOT + ".common.recipe.inworld":
        return B_NEW_ROOT + ".common.recipe.inworld", new_name
    if old_pkg == B_OLD_ROOT + ".common.timber":
        return B_NEW_ROOT + ".common.timber", new_name
    if old_pkg == B_OLD_ROOT + ".compat.jei":
        return B_NEW_ROOT + ".compat.jei", new_name
    if old_pkg == B_OLD_ROOT + ".mixin":
        return B_NEW_ROOT + ".mixin", new_name
    raise RuntimeError(f"unmapped B package: {old_pkg} / {name}")


def collect(root: Path, module: str, target_fn):
    entries = []
    for path in sorted(root.rglob("*.java")):
        old_pkg, name = read_package_and_class(path)
        new_pkg, new_name = target_fn(old_pkg, name)
        entries.append(
            {
                "module": module,
                "old_path": path,
                "old_pkg": old_pkg,
                "old_name": name,
                "new_pkg": new_pkg,
                "new_name": new_name,
                "old_fqcn": f"{old_pkg}.{name}",
                "new_fqcn": f"{new_pkg}.{new_name}",
            }
        )
    return entries


def replace_word(text: str, old: str, new: str) -> str:
    return re.sub(r"(?<![\w$])" + re.escape(old) + r"(?![\w$])", new, text)


def code_only(text: str) -> str:
    """Remove comments and string/char literals before scanning for type usages."""
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    text = re.sub(r"//[^\n]*", "", text)
    text = re.sub(r'"(?:\\.|[^"\\])*"', '""', text)
    text = re.sub(r"'(?:\\.|[^'\\])*'", "''", text)
    return text


def rewrite_file(entry, old_entries, new_simple_to_fqcn):
    text = entry["old_path"].read_text(encoding="utf-8")

    # 1. Fully-qualified old classes first.
    for other in sorted(old_entries, key=lambda e: len(e["old_fqcn"]), reverse=True):
        text = text.replace(other["old_fqcn"], other["new_fqcn"])

    # 2. Simple class names, longest first.
    for other in sorted(old_entries, key=lambda e: len(e["old_name"]), reverse=True):
        if other["old_name"] != other["new_name"]:
            text = replace_word(text, other["old_name"], other["new_name"])

    # 3. Package root replacements for wildcard imports / remaining references.
    if entry["module"] == "B":
        text = text.replace(B_OLD_ROOT, B_NEW_ROOT)
        text = text.replace(A_OLD_ROOT, A_NEW_ROOT)
    else:
        text = text.replace(A_OLD_ROOT, A_NEW_ROOT)

    # 4. Force the exact package declaration.
    text, n = re.subn(
        r"(?m)^\s*package\s+[\w.]+;",
        f"package {entry['new_pkg']};",
        text,
        count=1,
    )
    if n != 1:
        raise RuntimeError(f"cannot rewrite package: {entry['old_path']}")

    # 5. Normalize existing imports and drop emptied internal wildcard lines.
    lines = text.splitlines()
    import_lines = [line for line in lines if line.strip().startswith("import ")]
    body_without_imports = "\n".join(
        line for line in lines if not line.strip().startswith("import ")
    )
    code_body = code_only(body_without_imports)

    imports = set()
    for line in import_lines:
        stripped = line.strip()
        if stripped.startswith("import "):
            imports.add(stripped)

    # Add imports for moved/renamed project classes actually used in code.
    for simple, fqcn in new_simple_to_fqcn.items():
        if simple == entry["new_name"]:
            continue
        if fqcn.rsplit(".", 1)[0] == entry["new_pkg"]:
            continue
        if re.search(r"(?<![\w$])" + re.escape(simple) + r"(?![\w$])", code_body):
            imports.add(f"import {fqcn};")

    imports = sorted(imports)
    # Keep the original import area position: after package declaration, before first type.
    package_index = next(i for i, line in enumerate(lines) if line.strip().startswith("package "))
    remaining = [
        line
        for i, line in enumerate(lines)
        if i > package_index and not line.strip().startswith("import ")
    ]
    while remaining and not remaining[0].strip():
        remaining.pop(0)
    while remaining and not remaining[-1].strip():
        remaining.pop()
    cleaned = lines[: package_index + 1] + [""] + imports
    if imports:
        cleaned.append("")
    cleaned.extend(remaining)
    text = "\n".join(cleaned).rstrip() + "\n"

    new_path = (
        Path(MOD_REBUILD)
        / ("tfcfarmingplus" if entry["module"] == "A" else "tfcagricultureplus")
        / "src"
        / "main"
        / "java"
        / Path(*entry["new_pkg"].split("."))
        / (entry["new_name"] + ".java")
    )
    return text, new_path


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()

    a_entries = collect(A_ROOT, "A", target_a)
    b_entries = collect(B_ROOT, "B", target_b)

    for module, entries in (("A", a_entries), ("B", b_entries)):
        names = {}
        for entry in entries:
            if entry["new_name"] in names:
                raise RuntimeError(
                    f"{module} duplicate new simple name: {entry['new_name']} "
                    f"({names[entry['new_name']]} vs {entry['new_fqcn']})"
                )
            names[entry["new_name"]] = entry["new_fqcn"]
        print(f"{module}: {len(entries)} classes")

    a_simple = {e["new_name"]: e["new_fqcn"] for e in a_entries}
    b_simple = {e["new_name"]: e["new_fqcn"] for e in b_entries}

    outputs = []
    for entry, entries, simple_map in (
        *((e, a_entries, a_simple) for e in a_entries),
        *((e, b_entries, b_simple) for e in b_entries),
    ):
        text, new_path = rewrite_file(entry, entries, simple_map)
        outputs.append((entry, new_path, text))

    print(f"planned output files: {len(outputs)}")
    old_names = sorted({e["old_name"] for e in (*a_entries, *b_entries) if e["old_name"].startswith("My")})
    print(f"remaining old My-class names in mapping: {len(old_names)}")
    for name in old_names:
        print(f"  ! {name}")

    if not args.apply:
        print("dry run; pass --apply to write")
        return 0

    mapping_path = MOD_REBUILD / "_refactor" / "java-mapping.csv"
    mapping_path.parent.mkdir(parents=True, exist_ok=True)
    with mapping_path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.writer(handle)
        writer.writerow(["module", "old_pkg", "old_name", "new_pkg", "new_name", "old_path", "new_path"])
        for entry, new_path, _ in outputs:
            writer.writerow(
                [
                    entry["module"],
                    entry["old_pkg"],
                    entry["old_name"],
                    entry["new_pkg"],
                    entry["new_name"],
                    str(entry["old_path"].relative_to(MOD_REBUILD)),
                    str(new_path.relative_to(MOD_REBUILD)),
                ]
            )

    for entry, new_path, text in outputs:
        new_path.parent.mkdir(parents=True, exist_ok=True)
        new_path.write_text(text, encoding="utf-8", newline="\n")
    print(f"wrote {len(outputs)} files")
    print(f"mapping: {mapping_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
