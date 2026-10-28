#!/usr/bin/env python3
"""Audit A/B ownership of TFC crop resources.

Run from the workspace root. Read-only.
"""
from pathlib import Path

A = Path("mod_rebuild/tfcfarmingplus/src/main/resources")
B = Path("mod_rebuild/tfcagricultureplus/src/main/resources")

a_crop = sorted(p for p in (A / "assets/tfc/models/block/crop").glob("*.json")) if (A / "assets/tfc/models/block/crop").exists() else []
b_crop = sorted(p for p in (B / "assets/tfc/models/block/crop").glob("*.json")) if (B / "assets/tfc/models/block/crop").exists() else []
a_book = sorted(p for p in (A / "assets/tfc/patchouli_books").rglob("*") if p.is_file()) if (A / "assets/tfc/patchouli_books").exists() else []
b_book = sorted(p for p in (B / "assets/tfc/patchouli_books").rglob("*") if p.is_file()) if (B / "assets/tfc/patchouli_books").exists() else []
a_tags = sorted(p for p in (A / "data/tfc/tags").rglob("*.json")) if (A / "data/tfc/tags").exists() else []
b_tags = sorted(p for p in (B / "data/tfc/tags").rglob("*.json")) if (B / "data/tfc/tags").exists() else []

a_crop_rel = {p.relative_to(A).as_posix() for p in a_crop}
b_crop_rel = {p.relative_to(B).as_posix() for p in b_crop}
print(f"A TFC crop model files: {len(a_crop)}")
for p in sorted(a_crop_rel):
    print("  A", p)
print(f"B TFC crop model files: {len(b_crop)}")
for p in sorted(b_crop_rel):
    print("  B", p)
print(f"A TFC Patchouli files: {len(a_book)}; B TFC Patchouli files: {len(b_book)}")
print(f"A TFC tag files: {len(a_tags)}; B TFC tag files: {len(b_tags)}")
print(f"Current exact A/B crop-model path overlap: {len(a_crop_rel & b_crop_rel)}")
print("Future B 29-crop target collision:")
for name in ["cabbage_age_0.json", "cabbage_age_1.json", "cabbage_age_2.json", "cabbage_age_3.json", "cabbage_age_4.json", "cabbage_age_5.json"]:
    rel = "assets/tfc/models/block/crop/" + name
    print(f"  {rel}: {'A owns, B target would collide' if rel in a_crop_rel else 'A does not own'}")
