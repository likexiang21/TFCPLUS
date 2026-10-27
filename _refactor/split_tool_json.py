#!/usr/bin/env python3
"""Split A tools JSON into contracts/ and data/, then update path references."""
from __future__ import annotations

import re
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TOOLS = ROOT / "tfcfarmingplus" / "tools"
CONTRACTS = TOOLS / "contracts"
DATA = TOOLS / "data"


def classify(name: str) -> str:
    if name.endswith("-contract.json") or name.endswith("-policy.json") or name.endswith("-manifest.json"):
        return "contracts"
    if name == "reviewed-item-icon-routes.json":
        return "contracts"
    if name.endswith("-display-files.json"):
        return "data"
    if name.startswith("texture-jobs") or name.startswith("fruit-texture-jobs"):
        return "data"
    raise RuntimeError(f"unclassified tools JSON: {name}")


def main() -> int:
    CONTRACTS.mkdir(exist_ok=True)
    DATA.mkdir(exist_ok=True)
    mapping = {}
    for path in sorted(TOOLS.glob("*.json")):
        subdir = classify(path.name)
        target = (CONTRACTS if subdir == "contracts" else DATA) / path.name
        shutil.move(str(path), str(target))
        mapping[path.name] = subdir
        print(f"{path.name} -> {subdir}/")

    # Rewrite simple Join-Path references in active scripts (not archive).
    path_re = re.compile(r"(Join-Path\s+\$(?:PSScriptRoot|module|liveModule)\s+['\"](?:tools/)?)([^'\"\r\n]+\.json)(['\"])")
    for script in sorted(TOOLS.rglob("*.ps1")):
        if "archive" in script.parts:
            continue
        text = script.read_text(encoding="utf-8")
        changed = False
        def repl(match: re.Match[str]) -> str:
            nonlocal changed
            filename = match.group(2)
            subdir = mapping.get(filename)
            if not subdir:
                return match.group(0)
            changed = True
            return f"{match.group(1)}{subdir}/{filename}{match.group(3)}"
        text = path_re.sub(repl, text)
        # Dynamic display contracts/files.
        text = text.replace('(Join-Path $PSScriptRoot "${Species}-display-contract.json")',
                            '(Join-Path $PSScriptRoot "contracts/${Species}-display-contract.json")')
        text = text.replace('(Join-Path $PSScriptRoot "${Species}-display-files.json")',
                            '(Join-Path $PSScriptRoot "data/${Species}-display-files.json")')
        if changed or "${Species}" in text:
            script.write_text(text, encoding="utf-8", newline="\n")
            print("updated", script.relative_to(TOOLS))

    # Archive script sits in tools/archive and must point one level up.
    archive = TOOLS / "archive" / "20260923-generate-trunk-fruit-models.ps1"
    if archive.exists():
        text = archive.read_text(encoding="utf-8")
        text = text.replace(
            "Join-Path $PSScriptRoot 'fruit-texture-jobs.json'",
            "Join-Path (Split-Path $PSScriptRoot -Parent) 'data/fruit-texture-jobs.json'",
        )
        archive.write_text(text, encoding="utf-8", newline="\n")
        print("updated", archive.relative_to(TOOLS))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
