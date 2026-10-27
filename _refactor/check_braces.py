#!/usr/bin/env python3
"""Check Java brace balance while ignoring comments and literals."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
bad = []
for root in (ROOT / "tfcfarmingplus/src/main/java", ROOT / "tfcagricultureplus/src/main/java"):
    for path in root.rglob("*.java"):
        text = path.read_text(encoding="utf-8")
        depth = 0
        i = 0
        in_string = in_char = in_line = in_block = False
        valid = True
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
                if depth < 0:
                    valid = False
                    break
            i += 1
        if not valid or depth != 0:
            bad.append((path.relative_to(ROOT).as_posix(), depth))
print("brace issues:", len(bad))
for item in bad[:30]:
    print(item)
