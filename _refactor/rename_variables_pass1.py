#!/usr/bin/env python3
"""Third pass: high-confidence variable/method renames in the rebuilt tree."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
A = ROOT / "tfcfarmingplus" / "src" / "main" / "java"
B = ROOT / "tfcagricultureplus" / "src" / "main" / "java"


def replace_word(path: Path, old: str, new: str):
    text = path.read_text(encoding="utf-8")
    new_text = re.sub(r"(?<![\w$])" + re.escape(old) + r"(?![\w$])", new, text)
    if new_text != text:
        path.write_text(new_text, encoding="utf-8", newline="\n")
        return True
    return False


def replace_text(path: Path, old: str, new: str):
    text = path.read_text(encoding="utf-8")
    new_text = text.replace(old, new)
    if new_text != text:
        path.write_text(new_text, encoding="utf-8", newline="\n")
        return True
    return False


def main() -> int:
    changed = []

    species = A / "io/github/likexiang21/tfcplus/farming/common/api/SpeciesLookup.java"
    if species.exists():
        replace_word(species, "SPECIES_BLOCKS", "speciesBlocks")
        replace_word(species, "SPECIES_NAMES", "speciesNames")
        replace_text(species, "86 作物 + 48 果树 + 12 灌木", "87 作物 + 49 树类 + 12 灌木")
        replace_text(species, "146 个", "148 个")
        changed.append(species)

    bushes = A / "io/github/likexiang21/tfcplus/farming/common/crop/FarmingBushes.java"
    if bushes.exists():
        replace_word(bushes, "TEA", "TEA_LIFECYCLE")
        changed.append(bushes)

    branch = A / "io/github/likexiang21/tfcplus/farming/common/block/FarmingFruitingBranchBlock.java"
    if branch.exists():
        replace_word(branch, "now", "currentState")
        changed.append(branch)

    debug = A / "io/github/likexiang21/tfcplus/farming/common/debug/FarmingDebugCommands.java"
    if debug.exists():
        replace_word(debug, "remembered", "lastPlacedPosition")
        replace_word(debug, "TAG", "DEBUG_PREFIX")
        replace_word(debug, "say", "sendMessage")
        changed.append(debug)

    silkworm = B / "io/github/likexiang21/tfcplus/agriculture/common/blockentity/SilkwormRackBlockEntity.java"
    if silkworm.exists():
        replace_word(silkworm, "fed", "feedSucceeded")
        replace_word(silkworm, "old", "previousItems")
        changed.append(silkworm)

    drying = B / "io/github/likexiang21/tfcplus/agriculture/common/blockentity/DryingRackBlockEntity.java"
    if drying.exists():
        replace_word(drying, "now", "currentTick")
        changed.append(drying)

    print(f"changed files: {len(set(changed))}")
    for path in sorted(set(changed)):
        print(path.relative_to(ROOT))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
