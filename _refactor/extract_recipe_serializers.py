#!/usr/bin/env python3
"""Extract nested recipe serializer classes into top-level files."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RECIPE = ROOT / "tfcagricultureplus/src/main/java/io/github/likexiang21/tfcplus/agriculture/common/recipe"
PACKAGE = "io.github.likexiang21.tfcplus.agriculture.common.recipe"
INWORLD = RECIPE / "inworld"

TARGETS = {
    "CuttingBoardRecipe": ("CuttingBoardSerializer", RECIPE),
    "DoughRecipe": ("DoughSerializer", RECIPE),
    "FoodMixingBowlRecipe": ("FoodMixingBowlSerializer", RECIPE),
    "MeltingRecipe": ("MeltingSerializer", RECIPE),
    "MortarRecipe": ("MortarSerializer", RECIPE),
    "PanRecipe": ("PanSerializer", RECIPE),
    "InWorldRecipe": ("InWorldSerializer", INWORLD),
}


def find_class_block(text: str, name: str):
    match = re.search(r"public\s+static\s+final\s+class\s+" + re.escape(name) + r"\b[^{]*\{", text)
    if not match:
        raise RuntimeError(f"class not found: {name}")
    brace_start = text.find("{", match.start())
    depth = 0
    in_string = in_char = in_line = in_block = False
    i = brace_start
    while i < len(text):
        ch = text[i]
        nxt = text[i + 1] if i + 1 < len(text) else ""
        if in_line:
            if ch == "\n":
                in_line = False
        elif in_block:
            if ch == "*" and nxt == "/":
                in_block = False
                i += 1
        elif in_string:
            if ch == "\\":
                i += 1
            elif ch == '"':
                in_string = False
        elif in_char:
            if ch == "\\":
                i += 1
            elif ch == "'":
                in_char = False
        elif ch == "/" and nxt == "/":
            in_line = True
            i += 1
        elif ch == "/" and nxt == "*":
            in_block = True
            i += 1
        elif ch == '"':
            in_string = True
        elif ch == "'":
            in_char = True
        elif ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                return match.start(), i + 1
        i += 1
    raise RuntimeError(f"unclosed class: {name}")


def preceding_javadoc(text: str, start: int) -> int:
    marker = text.rfind("/**", 0, start)
    if marker < 0:
        return start
    end = text.find("*/", marker)
    if end < 0:
        return start
    if text[end + 2 : start].strip():
        return start
    return marker


def main() -> int:
    serializers = {}
    for recipe_name, (serializer_name, directory) in TARGETS.items():
        path = directory / f"{recipe_name}.java"
        text = path.read_text(encoding="utf-8")
        start, end = find_class_block(text, serializer_name)
        start = preceding_javadoc(text, start)
        block = text[start:end]

        # Rebuild the recipe file without the nested serializer.
        new_text = text[:start] + text[end:]
        new_text = re.sub(r"\n{3,}", "\n\n", new_text)
        path.write_text(new_text, encoding="utf-8", newline="\n")

        # Build the extracted top-level class.
        block = block.replace(f"public static final class {serializer_name}", f"public final class {serializer_name}", 1)
        if serializer_name == "InWorldSerializer":
            block = re.sub(r"(?<![\w$])CODEC(?![\w$])", "InWorldRecipe.CODEC", block)
            block = re.sub(r"(?<![\w$])STREAM_CODEC(?![\w$])", "InWorldRecipe.STREAM_CODEC", block)
        block = re.sub(r"(?m)^    ", "", block)
        imports = re.findall(r"(?m)^import\s+[\w.]+;", text)
        package = f"{PACKAGE}.inworld" if directory == INWORLD else PACKAGE
        imports = sorted({imp for imp in imports if not imp.startswith(f"import {package}.")})
        content = f"package {package};\n\n" + "\n".join(imports) + "\n\n" + block.rstrip() + "\n"
        target = directory / f"{serializer_name}.java"
        target.write_text(content, encoding="utf-8", newline="\n")
        serializers[recipe_name] = (serializer_name, package)
        print("wrote", target.relative_to(ROOT))

    # Update registrations.
    registry = RECIPE / "AgricultureRecipeSerializers.java"
    text = registry.read_text(encoding="utf-8")
    simple = {
        "MortarRecipe.MortarSerializer": "MortarSerializer",
        "PanRecipe.PanSerializer": "PanSerializer",
        "DoughRecipe.DoughSerializer": "DoughSerializer",
        "MeltingRecipe.MeltingSerializer": "MeltingSerializer",
        "CuttingBoardRecipe.CuttingBoardSerializer": "CuttingBoardSerializer",
        "FoodMixingBowlRecipe.FoodMixingBowlSerializer": "FoodMixingBowlSerializer",
    }
    for old, new in simple.items():
        text = text.replace(old, new)
    text = text.replace(
        "io.github.likexiang21.tfcplus.agriculture.common.recipe.inworld.InWorldRecipe.InWorldSerializer",
        "io.github.likexiang21.tfcplus.agriculture.common.recipe.inworld.InWorldSerializer",
    )
    registry.write_text(text, encoding="utf-8", newline="\n")
    print("updated", registry.relative_to(ROOT))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
