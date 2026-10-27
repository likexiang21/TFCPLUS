#!/usr/bin/env python3
"""Check that every tfcfarmingplus:block/... reference resolves to a model or texture."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "tfcfarmingplus/src/main/resources/assets/tfcfarmingplus"
MODELS = ASSETS / "models/block"
TEXTURES = ASSETS / "textures/block"

missing = {}
for json_path in ASSETS.rglob("*.json"):
    text = json_path.read_text(encoding="utf-8")
    for ref in re.findall(r"tfcfarmingplus:block/([a-z0-9_/]+)", text):
        if ref.endswith(".png"):
            continue
        if (MODELS / f"{ref}.json").exists() or (TEXTURES / f"{ref}.png").exists():
            continue
        missing.setdefault(str(json_path.relative_to(ASSETS)), set()).add(ref)

print("missing model/texture refs:", len(missing))
for path, refs in sorted(missing.items()):
    for ref in sorted(refs):
        print(f"  {path}: {ref}")
