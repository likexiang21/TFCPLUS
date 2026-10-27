#!/usr/bin/env python3
"""Extract the four nested block classes from AgricultureBlocks into files."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REGISTRY = ROOT / "tfcagricultureplus/src/main/java/io/github/likexiang21/tfcplus/agriculture/common/registry/AgricultureBlocks.java"
BLOCK_DIR = ROOT / "tfcagricultureplus/src/main/java/io/github/likexiang21/tfcplus/agriculture/common/block"
PACKAGE = "io.github.likexiang21.tfcplus.agriculture.common.block"


def remove_comments_strings(text: str) -> str:
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    text = re.sub(r"//[^\n]*", "", text)
    text = re.sub(r'"(?:\\.|[^"\\])*"', '""', text)
    text = re.sub(r"'(?:\\.|[^'\\])*'", "''", text)
    return text


def find_class_block(text: str, name: str):
    match = re.search(r"public\s+static\s+class\s+" + re.escape(name) + r"\b[^{]*\{", text)
    if not match:
        raise RuntimeError(f"class not found: {name}")
    brace_start = text.find("{", match.start())
    depth = 0
    in_string = False
    in_char = False
    in_line = False
    in_block = False
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
    between = text[end + 2 : start]
    if between.strip():
        return start
    return marker


def main() -> int:
    text = REGISTRY.read_text(encoding="utf-8")
    imports = re.findall(r"(?m)^import\s+[\w.]+;", text)
    # Keep all imports; add the registry reference for static helpers.
    imports = sorted(set(imports) | {"import io.github.likexiang21.tfcplus.agriculture.common.registry.AgricultureBlocks;"})

    classes = ["CuttingBoardBlock", "LogCuttingBoardBlock", "KnifeRackBlock", "MortarBlock"]
    spans = []
    for name in classes:
        start, end = find_class_block(text, name)
        start = preceding_javadoc(text, start)
        spans.append((start, end, name))

    # Remove from the registry from the end so offsets remain valid.
    for start, end, name in sorted(spans, key=lambda item: item[0], reverse=True):
        text = text[:start] + text[end:]
    # Collapse extra blank lines left behind.
    text = re.sub(r"\n{3,}", "\n\n", text)

    for start, end, name in spans:
        # Recompute the class text from the original copy by finding it again is no longer
        # possible after removal; spans were collected before removal, so re-read old text.
        original = REGISTRY.read_text(encoding="utf-8")
        s, e = find_class_block(original, name)
        s = preceding_javadoc(original, s)
        block = original[s:e]
        block = block.replace(f"public static class {name}", f"public class {name}", 1)
        block = re.sub(r"(?<![\w$])FACING(?![\w$])", "AgricultureBlocks.FACING", block)
        block = re.sub(r"(?<![\w$])dropContentsOnBreak(?![\w$])", "AgricultureBlocks.dropContentsOnBreak", block)
        content = (
            f"package {PACKAGE};\n\n"
            + "\n".join(sorted(set(imports)))
            + "\n\n"
            + block.rstrip()
            + "\n"
        )
        target = BLOCK_DIR / f"{name}.java"
        target.write_text(content, encoding="utf-8", newline="\n")
        print("wrote", target.relative_to(ROOT))

    # Registry now needs imports for the extracted classes.
    needed = {
        f"import {PACKAGE}.{name};" for name in classes
    }
    existing = set(re.findall(r"(?m)^import\s+[\w.]+;", text))
    missing = sorted(needed - existing)
    if missing:
        # Insert after the package line, keeping imports grouped by the existing block.
        first_import = re.search(r"(?m)^import\s+", text)
        if first_import:
            text = text[: first_import.start()] + "\n".join(missing) + "\n" + text[first_import.start() :]
        else:
            text = re.sub(r"(?m)^(package\s+[\w.]+;)\s*", r"\1\n\n" + "\n".join(missing) + "\n\n", text, count=1)
    REGISTRY.write_text(text, encoding="utf-8", newline="\n")
    print("updated", REGISTRY.relative_to(ROOT))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
