#!/usr/bin/env python3
"""Remove imports whose simple names never appear in a selected Java file."""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FILES = [
    ROOT / "tfcagricultureplus/src/main/java/io/github/likexiang21/tfcplus/agriculture/common/block/CuttingBoardBlock.java",
    ROOT / "tfcagricultureplus/src/main/java/io/github/likexiang21/tfcplus/agriculture/common/block/LogCuttingBoardBlock.java",
    ROOT / "tfcagricultureplus/src/main/java/io/github/likexiang21/tfcplus/agriculture/common/block/KnifeRackBlock.java",
    ROOT / "tfcagricultureplus/src/main/java/io/github/likexiang21/tfcplus/agriculture/common/block/MortarBlock.java",
    ROOT / "tfcagricultureplus/src/main/java/io/github/likexiang21/tfcplus/agriculture/common/recipe/CuttingBoardSerializer.java",
    ROOT / "tfcagricultureplus/src/main/java/io/github/likexiang21/tfcplus/agriculture/common/recipe/DoughSerializer.java",
    ROOT / "tfcagricultureplus/src/main/java/io/github/likexiang21/tfcplus/agriculture/common/recipe/FoodMixingBowlSerializer.java",
    ROOT / "tfcagricultureplus/src/main/java/io/github/likexiang21/tfcplus/agriculture/common/recipe/MeltingSerializer.java",
    ROOT / "tfcagricultureplus/src/main/java/io/github/likexiang21/tfcplus/agriculture/common/recipe/MortarSerializer.java",
    ROOT / "tfcagricultureplus/src/main/java/io/github/likexiang21/tfcplus/agriculture/common/recipe/PanSerializer.java",
    ROOT / "tfcagricultureplus/src/main/java/io/github/likexiang21/tfcplus/agriculture/common/recipe/inworld/InWorldSerializer.java",
    ROOT / "tfcagricultureplus/src/main/java/io/github/likexiang21/tfcplus/agriculture/common/recipe/AgricultureRecipeSerializers.java",
]


def main() -> int:
    for path in FILES:
        text = path.read_text(encoding="utf-8")
        lines = text.splitlines()
        import_lines = [line for line in lines if line.startswith("import ") and line.endswith(";")]
        body = "\n".join(line for line in lines if not (line.startswith("import ") and line.endswith(";")))
        keep = []
        removed = []
        for line in import_lines:
            name = line[len("import ") : -1].strip()
            if name.startswith("static ") or name.endswith(".*"):
                keep.append(line)
                continue
            simple = name.rsplit(".", 1)[-1]
            if re.search(r"(?<![\w$])" + re.escape(simple) + r"(?![\w$])", body):
                keep.append(line)
            else:
                removed.append(line)
        if removed:
            new_lines = [line for line in lines if line not in removed]
            path.write_text("\n".join(new_lines) + "\n", encoding="utf-8", newline="\n")
            print(f"{path.name}: removed {len(removed)} unused imports")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
