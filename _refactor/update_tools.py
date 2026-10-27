#!/usr/bin/env python3
"""Point copied tool scripts at the rebuilt package/class/file layout."""
from __future__ import annotations

import csv
import re
from pathlib import Path

MOD_REBUILD = Path(__file__).resolve().parents[1]
MAPPING = MOD_REBUILD / "_refactor" / "java-mapping.csv"
A_TOOLS = MOD_REBUILD / "tfcfarmingplus" / "tools"
B_TOOLS = MOD_REBUILD / "tfcagricultureplus" / "tools"


def read_mapping():
    with MAPPING.open(encoding="utf-8", newline="") as handle:
        return list(csv.DictReader(handle))


def add(mapping, old, new):
    if old and old != new:
        mapping[old] = new


def build(rows):
    module_rows = {"A": [], "B": []}
    for row in rows:
        module_rows[row["module"]].append(row)

    path_all = {}
    common = {"A": {}, "B": {}}
    names = {"A": {}, "B": {}}

    for module, entries in module_rows.items():
        for row in entries:
            old_path = row["old_path"].replace("\\", "/")
            new_path = row["new_path"].replace("\\", "/")
            add(path_all, old_path, new_path)
            add(path_all, "moddev/" + old_path, "mod_rebuild/" + new_path)
            add(path_all, old_path.replace("/", "\\"), new_path.replace("/", "\\"))
            add(
                path_all,
                ("moddev/" + old_path).replace("/", "\\"),
                ("mod_rebuild/" + new_path).replace("/", "\\"),
            )
            if "/common/" in old_path and "/common/" in new_path:
                old_rel = old_path.split("/common/", 1)[1]
                new_rel = new_path.split("/common/", 1)[1]
                add(common[module], old_rel, new_rel)
                add(common[module], old_rel.replace("/", "\\"), new_rel.replace("/", "\\"))
            add(names[module], row["old_name"], row["new_name"])

    # Root replacements.
    roots = [
        ("com.example.tfcfarmingplus.expansion", "io.github.likexiang21.tfcplus.agriculture"),
        ("com.example.tfcfarmingplus", "io.github.likexiang21.tfcplus.farming"),
    ]
    for old, new in roots:
        add(path_all, old, new)
        add(path_all, old.replace(".", "/"), new.replace(".", "/"))
        add(path_all, old.replace(".", "\\"), new.replace(".", "\\"))

    add(path_all, "KnifeBlockBlock", "KnifeRackBlock")

    # Cross-module unique names: tools in A sometimes read B sources and vice versa.
    cross_a = {k: v for k, v in names["A"].items() if k not in names["B"]}
    cross_b = {k: v for k, v in names["B"].items() if k not in names["A"]}

    def ordered(mapping):
        return sorted(mapping.items(), key=lambda item: len(item[0]), reverse=True)

    return {
        "path_all": ordered(path_all),
        "common": {k: ordered(v) for k, v in common.items()},
        "names": {k: ordered(v) for k, v in names.items()},
        "cross_a": ordered(cross_a),
        "cross_b": ordered(cross_b),
    }


def apply(path: Path, repls: list[tuple[str, str]]):
    encoding = "utf-8-sig" if path.suffix.lower() == ".ps1" else "utf-8"
    text = path.read_text(encoding=encoding)
    new_text = text
    for old, new in repls:
        if old in new_text:
            new_text = new_text.replace(old, new)
    if new_text != text:
        path.write_text(new_text, encoding=encoding, newline="\n")
        return True
    return False


def main() -> int:
    rows = read_mapping()
    data = build(rows)
    changed = []

    orders = {
        "A": data["path_all"] + data["common"]["A"] + data["names"]["A"] + data["cross_b"],
        "B": data["path_all"] + data["common"]["B"] + data["names"]["B"] + data["cross_a"],
    }
    # De-duplicate while keeping longest-first order within each stream.
    for module, root in (("A", A_TOOLS), ("B", B_TOOLS)):
        repls = []
        seen = set()
        for old, new in orders[module]:
            if old not in seen:
                seen.add(old)
                repls.append((old, new))
        repls.append(("moddev", "mod_rebuild"))
        for path in sorted(root.rglob("*")):
            if path.is_file() and path.suffix.lower() in {".ps1", ".py"}:
                if apply(path, repls):
                    changed.append(path)

    print(f"changed tool files: {len(changed)}")
    for path in changed:
        print(path.relative_to(MOD_REBUILD))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
