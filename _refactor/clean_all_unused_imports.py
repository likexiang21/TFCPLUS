#!/usr/bin/env python3
"""Remove unused non-static, non-wildcard imports from all rebuilt Java files."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ROOTS = [
    ROOT / "tfcfarmingplus/src/main/java",
    ROOT / "tfcagricultureplus/src/main/java",
]


def clean(path: Path) -> int:
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
    return len(removed)


def main() -> int:
    total = 0
    files = 0
    for root in ROOTS:
        for path in root.rglob("*.java"):
            count = clean(path)
            if count:
                files += 1
                total += count
                print(f"{path.name}: -{count}")
    print(f"removed {total} imports from {files} files")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
