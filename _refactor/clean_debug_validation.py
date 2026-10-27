#!/usr/bin/env python3
"""Clean the opt-in debug validation class."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PATH = ROOT / "tfcagricultureplus/src/main/java/io/github/likexiang21/tfcplus/agriculture/common/debug/DebugValidation.java"


def word(text: str, old: str, new: str) -> str:
    return re.sub(r"(?<![\w$])" + re.escape(old) + r"(?![\w$])", new, text)


def main() -> int:
    text = PATH.read_text(encoding="utf-8")

    # Method names first; string messages containing bare words are preserved unless they are calls.
    text = re.sub(r"\bcheck\(", "require(", text)
    text = re.sub(r"\brun\(", "runChecks(", text)
    text = re.sub(r"\bitem\(", "createItemStack(", text)
    text = re.sub(r"\bboard\(", "getCuttingBoard(", text)
    text = re.sub(r"\buse\(", "simulateUse(", text)
    text = re.sub(r"\bplace\(", "simulatePlace(", text)
    text = re.sub(r"\bdrops\(", "countDrops(", text)
    text = re.sub(r"\.executes\(context->runChecks\(", ".executes(context->runChecks(", text)

    # Field and local names.
    text = word(text, "checks", "passedChecks")
    text = word(text, "original", "originalGameType")
    text = word(text, "main", "previousMainHand")
    text = word(text, "off", "previousOffHand")
    text = word(text, "board", "cuttingBoard")
    text = word(text, "food", "foodStack")
    text = word(text, "nbt", "savedTag")
    text = word(text, "before", "previousCount")
    text = text.replace("filter(e->", "filter(entity->")
    text = text.replace("e.getItem()", "entity.getItem()")

    PATH.write_text(text, encoding="utf-8", newline="\n")
    print("updated", PATH.relative_to(ROOT))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
