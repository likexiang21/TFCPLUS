#!/usr/bin/env python3
"""Re-baseline source paths and hashes in copied tool JSON files."""
from __future__ import annotations

import csv
import hashlib
import json
from pathlib import Path

MOD_REBUILD = Path(__file__).resolve().parents[1]
MAPPING = MOD_REBUILD / "_refactor" / "java-mapping.csv"
TOOL_DIRS = [
    MOD_REBUILD / "tfcfarmingplus" / "tools",
    MOD_REBUILD / "tfcagricultureplus" / "tools",
]


def source_rel(path: str) -> str | None:
    marker = "src/main/java/"
    if marker in path:
        return path.split(marker, 1)[1]
    return None


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 256), b""):
            digest.update(chunk)
    return digest.hexdigest().upper()


def main() -> int:
    rows = []
    with MAPPING.open(encoding="utf-8", newline="") as handle:
        rows = list(csv.DictReader(handle))

    old_to_new_rel = {}
    old_to_new_full = {}
    new_src_module = {}
    for row in rows:
        old = row["old_path"].replace("\\", "/")
        new = row["new_path"].replace("\\", "/")
        old_src = source_rel(old)
        new_src = source_rel(new)
        if old_src and new_src:
            old_to_new_rel[old_src] = new_src
            new_src_module[new_src] = (
                "tfcfarmingplus" if row["module"] == "A" else "tfcagricultureplus"
            )
        old_to_new_full[old] = new
        old_to_new_full["moddev/" + old] = "mod_rebuild/" + new

    def map_string(value: str) -> str:
        value = value.replace("\\", "/")
        if value in old_to_new_rel:
            return old_to_new_rel[value]
        if value in old_to_new_full:
            return old_to_new_full[value]
        # Absolute or module-relative paths containing a known old path.
        for old, new in sorted(old_to_new_rel.items(), key=lambda item: len(item[0]), reverse=True):
            if value.endswith(old):
                return value[: -len(old)] + new
        return value

    def walk(obj, parent_key: str | None = None):
        if isinstance(obj, dict):
            result = {}
            for key, value in obj.items():
                new_key = map_string(key) if isinstance(key, str) else key
                if (
                    isinstance(value, str)
                    and len(value) == 64
                    and all(ch in "0123456789ABCDEFabcdef" for ch in value)
                    and isinstance(new_key, str)
                ):
                    rel = source_rel(new_key)
                    if rel is not None and rel in new_src_module:
                        module = new_src_module[rel]
                        candidate = MOD_REBUILD / module / "src" / "main" / "java" / rel
                        if candidate.exists():
                            result[new_key] = sha256(candidate)
                            continue
                result[new_key] = walk(value, new_key if isinstance(new_key, str) else None)
            return result
        if isinstance(obj, list):
            return [walk(item, parent_key) for item in obj]
        if isinstance(obj, str):
            return map_string(obj)
        return obj

    changed = []
    for root in TOOL_DIRS:
        for path in sorted(root.glob("*.json")):
            try:
                data = json.loads(path.read_text(encoding="utf-8"))
            except Exception as exc:  # noqa: BLE001
                print(f"SKIP {path}: {exc}")
                continue
            new_data = walk(data)
            # Absolute paths outside known source files: rebase workspace root.
            text = json.dumps(new_data, ensure_ascii=False, indent=2)
            text = text.replace("moddev", "mod_rebuild")
            if text != path.read_text(encoding="utf-8"):
                path.write_text(text + "\n", encoding="utf-8", newline="\n")
                changed.append(path)

    print(f"changed json files: {len(changed)}")
    for path in changed:
        print(path.relative_to(MOD_REBUILD))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
