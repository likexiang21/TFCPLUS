#!/usr/bin/env python3
"""Read-only static checks for the rebuilt Java tree."""
from __future__ import annotations

import re
import sys
from pathlib import Path

MOD_REBUILD = Path(__file__).resolve().parents[1]
ROOTS = {
    "A": MOD_REBUILD / "tfcfarmingplus" / "src" / "main" / "java",
    "B": MOD_REBUILD / "tfcagricultureplus" / "src" / "main" / "java",
}
NEW_ROOTS = {
    "A": "io.github.likexiang21.tfcplus.farming",
    "B": "io.github.likexiang21.tfcplus.agriculture",
}


def code_only(text: str) -> str:
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    text = re.sub(r"//[^\n]*", "", text)
    text = re.sub(r'"(?:\\.|[^"\\])*"', '""', text)
    text = re.sub(r"'(?:\\.|[^'\\])*'", "''", text)
    return text


def project_files(root: Path):
    for path in sorted(root.rglob("*.java")):
        text = path.read_text(encoding="utf-8")
        package_match = re.search(r"(?m)^\s*package\s+([\w.]+);", text)
        if not package_match:
            yield path, text, None, None
            continue
        package = package_match.group(1)
        type_match = re.search(
            r"(?m)^(?:public\s+|final\s+|abstract\s+|sealed\s+|non-sealed\s+)*(?:class|interface|enum|record)\s+(\w+)",
            text,
        )
        type_name = type_match.group(1) if type_match else None
        yield path, text, package, type_name


def main() -> int:
    errors: list[str] = []
    warnings: list[str] = []
    all_entries = {}
    for module, root in ROOTS.items():
        entries = []
        for path, text, package, type_name in project_files(root):
            if package is None:
                errors.append(f"{module}: missing package {path}")
                continue
            if type_name is None:
                errors.append(f"{module}: missing public top-level type {path}")
                continue
            if path.stem != type_name:
                errors.append(f"{module}: file/type mismatch {path}: {type_name}")
            expected = root / Path(*package.split(".")) / (type_name + ".java")
            if path.resolve() != expected.resolve():
                errors.append(f"{module}: package/path mismatch {path} expected {expected}")
            if not package.startswith(NEW_ROOTS[module]):
                errors.append(f"{module}: old/wrong package {package} in {path}")
            entries.append((path, text, package, type_name))
        all_entries[module] = entries

    for module, entries in all_entries.items():
        simple_to_fqcn = {type_name: f"{package}.{type_name}" for _, _, package, type_name in entries}
        fqcn_set = set(simple_to_fqcn.values())
        duplicates = sorted({name for name in simple_to_fqcn if list(simple_to_fqcn).count(name) > 1})
        if duplicates:
            warnings.append(f"{module}: duplicate simple names (set build lost detail): {duplicates}")

        for path, text, package, own_name in entries:
            body = code_only(text)
            if "com.example.tfcfarmingplus" in text:
                errors.append(f"{module}: old package reference in {path}")
            if re.search(r"\bMy[A-Z]\w*\b", body):
                errors.append(f"{module}: old My-class identifier in {path}")
            imports = set(re.findall(r"(?m)^\s*import\s+([\w.]+);", text))
            for imported in imports:
                if imported.startswith(NEW_ROOTS[module]):
                    parts = imported.split(".")
                    found = False
                    for end in range(len(parts), 0, -1):
                        candidate = ROOTS[module] / Path(*parts[:end]).with_suffix(".java")
                        if candidate.exists():
                            found = True
                            break
                    if not found:
                        errors.append(f"{module}: project import target missing {imported} in {path.name}")
            for simple, fqcn in simple_to_fqcn.items():
                if simple == own_name:
                    continue
                if fqcn.rsplit(".", 1)[0] == package:
                    continue
                if re.search(r"(?<![\w$])" + re.escape(simple) + r"(?![\w$])", body):
                    if fqcn not in imports:
                        # A same-file nested type can share a name; report as missing import candidate.
                        errors.append(f"{module}: missing import {fqcn} used by {path.name}")
    print(f"errors = {len(errors)}")
    for error in errors[:200]:
        print("ERROR", error)
    print(f"warnings = {len(warnings)}")
    for warning in warnings[:50]:
        print("WARN", warning)
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
