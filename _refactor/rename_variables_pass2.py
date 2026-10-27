#!/usr/bin/env python3
"""Fourth pass: file-scoped variable renames in the rebuilt tree."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
A = ROOT / "tfcfarmingplus" / "src" / "main" / "java"
B = ROOT / "tfcagricultureplus" / "src" / "main" / "java"


def replace_word(path: Path, old: str, new: str):
    text = path.read_text(encoding="utf-8")
    if re.search(r"(?<![\w$])" + re.escape(new) + r"(?![\w$])", text):
        print(f"SKIP (target exists): {path.name}: {new}")
        return False
    new_text = re.sub(r"(?<![\w$])" + re.escape(old) + r"(?![\w$])", new, text)
    if new_text != text:
        path.write_text(new_text, encoding="utf-8", newline="\n")
        return True
    return False


def replace_literal(path: Path, old: str, new: str):
    text = path.read_text(encoding="utf-8")
    new_text = text.replace(old, new)
    if new_text != text:
        path.write_text(new_text, encoding="utf-8", newline="\n")
        return True
    return False


def main() -> int:
    changed = []

    # A client stream builders.
    client = A / "io/github/likexiang21/tfcplus/farming/client/TFCFarmingPlusClient.java"
    if client.exists() and replace_word(client, "out", "blockStream"):
        changed.append(client)

    # A BE registration concat helper.
    be = A / "io/github/likexiang21/tfcplus/farming/common/registry/FarmingBlockEntities.java"
    if be.exists():
        for old, new in (("a", "blocks"), ("out", "resultBlocks"), ("at", "offset")):
            if replace_word(be, old, new):
                changed.append(be)

    # A fruit tree registration loop.
    trees = A / "io/github/likexiang21/tfcplus/farming/common/tree/FarmingFruitTrees.java"
    if trees.exists():
        replace_literal(trees, "final FruitTreeDefinition t : TREES", "final FruitTreeDefinition treeDefinition : TREES")
        for suffix in ("name()", "lifecycle()", "floweringColor()"):
            replace_literal(trees, "t." + suffix, "treeDefinition." + suffix)
        for old, new in (("n", "speciesName"), ("cl", "climateReference"), ("h", "holder"), ("out", "blockList")):
            if replace_word(trees, old, new):
                changed.append(trees)

    # A debug command locals.
    debug = A / "io/github/likexiang21/tfcplus/farming/common/debug/FarmingDebugCommands.java"
    if debug.exists():
        for old, new in (
            ("p", "candidatePos"),
            ("ref", "climateReference"),
            ("ok", "canGrow"),
            ("m", "hydrationMethod"),
        ):
            if replace_word(debug, old, new):
                changed.append(debug)

    # A renderer/math offsets.
    leaves = A / "io/github/likexiang21/tfcplus/farming/common/block/FarmingFruitTreeLeavesBlock.java"
    if leaves.exists():
        for old, new in (("dx", "offsetX"), ("dz", "offsetZ")):
            if replace_word(leaves, old, new):
                changed.append(leaves)

    # B block registration/event locals.
    blocks = B / "io/github/likexiang21/tfcplus/agriculture/common/registry/AgricultureBlocks.java"
    if blocks.exists():
        for old, new in (("out", "droppedStack"), ("be", "blockEntity"), ("s", "stack")):
            if replace_word(blocks, old, new):
                changed.append(blocks)

    # B items/tools/rendering locals.
    for path, pairs in (
        (B / "io/github/likexiang21/tfcplus/agriculture/common/registry/AgricultureItems.java", (("h", "holder"),)),
        (B / "io/github/likexiang21/tfcplus/agriculture/common/blockentity/KnifeRackBlockEntity.java", (("s", "stack"),)),
        (B / "io/github/likexiang21/tfcplus/agriculture/client/renderer/KnifeRackBlockEntityRenderer.java", (("loc", "textureOffset"),)),
        (B / "io/github/likexiang21/tfcplus/agriculture/client/renderer/TimberPileBlockEntityRenderer.java", (("dx", "offsetX"), ("dy", "offsetY"))),
        (B / "io/github/likexiang21/tfcplus/agriculture/common/blockentity/CookingPanBlockEntity.java", (("out", "extractedStack"),)),
        (B / "io/github/likexiang21/tfcplus/agriculture/common/blockentity/DryingRackBlockEntity.java", (("out", "extractedStack"),)),
        (B / "io/github/likexiang21/tfcplus/agriculture/common/blockentity/MortarBlockEntity.java", (("out", "extractedStack"),)),
        (B / "io/github/likexiang21/tfcplus/agriculture/common/recipe/MeltingRecipe.java", (("out", "foodResult"),)),
        (B / "io/github/likexiang21/tfcplus/agriculture/common/timber/TimberPileBlock.java", (("out", "extractedStack"), ("y", "yOffset"))),
    ):
        if not path.exists():
            continue
        for old, new in pairs:
            if replace_word(path, old, new):
                changed.append(path)

    # B kitchen storage fields/accessors.
    kitchen = B / "io/github/likexiang21/tfcplus/agriculture/common/block/KitchenStorageBlock.java"
    if kitchen.exists():
        for old, new in (("id", "storageId"), ("kind", "storageKind")):
            if replace_word(kitchen, old, new):
                changed.append(kitchen)
        replace_literal(kitchen, "public String storageId()", "public String storageId()")
    if blocks.exists():
        replace_literal(blocks, "kind.id()", "kind.storageId()")

    # B timber piece kind.
    piece = B / "io/github/likexiang21/tfcplus/agriculture/common/timber/TimberPieceBlock.java"
    piece_registry = B / "io/github/likexiang21/tfcplus/agriculture/common/timber/TimberBlocks.java"
    if piece.exists() and replace_word(piece, "kind", "pieceKind"):
        changed.append(piece)
        if piece_registry.exists():
            replace_literal(piece_registry, "piece.kind", "piece.pieceKind")

    # B in-world action/component serialized keys.
    action = B / "io/github/likexiang21/tfcplus/agriculture/common/recipe/inworld/InWorldAction.java"
    if action.exists() and replace_word(action, "key", "serializedName"):
        changed.append(action)
    components = B / "io/github/likexiang21/tfcplus/agriculture/common/recipe/inworld/InWorldComponents.java"
    if components.exists():
        if replace_word(components, "key", "serializedName"):
            changed.append(components)
        if replace_word(components, "tag", "toolTag"):
            changed.append(components)

    # B silkworm data helper.
    silkworm = B / "io/github/likexiang21/tfcplus/agriculture/common/silkworm/SilkwormData.java"
    if silkworm.exists():
        if replace_word(silkworm, "day", "currentDay"):
            changed.append(silkworm)
        if replace_word(silkworm, "tag", "compoundTag"):
            changed.append(silkworm)
    rack = B / "io/github/likexiang21/tfcplus/agriculture/common/blockentity/SilkwormRackBlockEntity.java"
    if rack.exists():
        replace_literal(rack, "SilkwormData.currentDay(level)", "SilkwormData.currentDay(level)")

    print(f"changed files: {len(set(changed))}")
    for path in sorted(set(changed)):
        print(path.relative_to(ROOT))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
