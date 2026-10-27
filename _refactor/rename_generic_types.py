#!/usr/bin/env python3
"""Second pass: remove generic public type names from the rebuilt Java tree."""
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


def main() -> int:
    changed = []

    # A: nested record Tree -> FruitTreeDefinition.
    for path in A.rglob("*.java"):
        if replace_word(path, "Tree", "FruitTreeDefinition"):
            changed.append(path)
        text = path.read_text(encoding="utf-8")
        # Record component abbreviations only inside the tree definition.
        if path.name == "FarmingFruitTrees.java":
            text = text.replace("String en, String donor", "String englishName, String textureDonor")
            text = text.replace("tree.en()", "tree.englishName()")
            text = text.replace("tree.donor()", "tree.textureDonor()")
            text = text.replace("t.en()", "t.englishName()")
            text = text.replace("t.donor()", "t.textureDonor()")
            path.write_text(text, encoding="utf-8", newline="\n")

    # B: generic top-level/nested types.
    for path in B.rglob("*.java"):
        for old, new in (
            ("Action", "InWorldAction"),
            ("Motion", "InWorldMotion"),
            ("SoundInstance", "SoundSpec"),
            ("Kind", "StorageKind"),
        ):
            if replace_word(path, old, new):
                changed.append(path)

    # Rename Action.java -> InWorldAction.java.
    action = B / "io/github/likexiang21/tfcplus/agriculture/common/recipe/inworld/Action.java"
    if action.exists():
        target = action.with_name("InWorldAction.java")
        action.replace(target)
        changed.append(target)

    # Nested Input records: qualify in each recipe file, then fix external refs.
    recipe_inputs = {
        B / "io/github/likexiang21/tfcplus/agriculture/common/recipe/CuttingBoardRecipe.java": "CuttingBoardInput",
        B / "io/github/likexiang21/tfcplus/agriculture/common/recipe/MeltingRecipe.java": "MeltingInput",
        B / "io/github/likexiang21/tfcplus/agriculture/common/recipe/PanRecipe.java": "PanInput",
        B / "io/github/likexiang21/tfcplus/agriculture/common/recipe/inworld/InWorldComponents.java": "InWorldInput",
    }
    for path, new_name in recipe_inputs.items():
        if not path.exists():
            continue
        text = path.read_text(encoding="utf-8")
        text = re.sub(r"(?<![\w$])Input(?![\w$])", new_name, text)
        path.write_text(text, encoding="utf-8", newline="\n")
        changed.append(path)

    external = {
        "CuttingBoardRecipe.Input": "CuttingBoardRecipe.CuttingBoardInput",
        "MeltingRecipe.Input": "MeltingRecipe.MeltingInput",
        "PanRecipe.Input": "PanRecipe.PanInput",
        "InWorldComponents.Input": "InWorldComponents.InWorldInput",
    }
    for path in B.rglob("*.java"):
        text = path.read_text(encoding="utf-8")
        new_text = text
        for old, new in external.items():
            new_text = new_text.replace(old, new)
        if new_text != text:
            path.write_text(new_text, encoding="utf-8", newline="\n")
            changed.append(path)

    print(f"changed files: {len(set(changed))}")
    for path in sorted(set(changed)):
        print(path.relative_to(ROOT))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
