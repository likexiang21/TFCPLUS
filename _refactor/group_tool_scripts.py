#!/usr/bin/env python3
"""Group A/B tool entry scripts into scripts/{generate,audit,verify}.

The original root .ps1 names remain as compatibility wrappers.  Moved scripts
resolve the tools root through TFC_TOOLS_ROOT, set by the wrapper, so the
existing relative contract/data/source paths keep working.
"""
from __future__ import annotations

import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
A = ROOT / "tfcfarmingplus" / "tools"
B = ROOT / "tfcagricultureplus" / "tools"

# A: move entry scripts; shared helpers stay at the tools root.
A_AUDIT = [
    "audit-branch-fruit-contracts.ps1",
    "audit-bush-contracts.ps1",
    "audit-celery-display.ps1",
    "audit-celtuce-display.ps1",
    "audit-chili-display.ps1",
    "audit-crop-contracts.ps1",
    "audit-fenugreek-display.ps1",
    "audit-item-icon-routes.ps1",
    "audit-leaf-vegetable-models.ps1",
    "audit-leafball-support.ps1",
    "audit-reviewed-crop-display.ps1",
    "audit-rhubarb-display.ps1",
    "audit-rosette-dead-consumers.ps1",
    "audit-rosette-fruit-support.ps1",
    "audit-seedling-texture-contracts.ps1",
    "audit-soil-contracts.ps1",
    "audit-spinach-display.ps1",
    "audit-sunflower-display.ps1",
    "audit-swiss-chard-display.ps1",
    "audit-texture-content.ps1",
    "audit-texture-uniqueness.ps1",
    "audit-tree-contracts.ps1",
]
A_GENERATE = [
    "gen-branch-fruits.ps1",
    "gen-crop-textures.ps1",
    "gen-crops.ps1",
    "gen-dead-and-wild-bushes.ps1",
    "gen-double-crop-textures.ps1",
    "gen-firmalife-plantable.ps1",
    "gen-food-textures.ps1",
    "gen-fruit-trees.ps1",
    "gen-item-textures.ps1",
    "gen-leafball-hand.ps1",
    "gen-leafball-models.ps1",
    "gen-leafball-textures.ps1",
    "gen-melon-skins.ps1",
    "gen-patchouli-book.ps1",
    "gen-pixelart-textures.ps1",
    "gen-plant-textures.ps1",
    "gen-rosette-models.ps1",
    "gen-rosette-textures.ps1",
    "gen-seed-textures.ps1",
    "gen-sunflower-disc.ps1",
    "gen-tags.ps1",
    "gen-wild-injection.ps1",
    "generate-vegetable-crop-models.ps1",
    "generate-wild-crop-patches.ps1",
]
A_VERIFY = ["healthcheck.ps1", "verify.ps1", "verify-book.ps1"]

B_VERIFY = [
    "check-boundaries.ps1",
    "verify-agricultural-materials.ps1",
    "verify-container-contract.ps1",
    "verify-coverage-ledger.ps1",
    "verify-drying-batch.ps1",
    "verify-fruit-processing.ps1",
    "verify-grain-food-processing.ps1",
    "verify-in-world-codec.ps1",
    "verify-kitchenware-ledger.ps1",
    "verify-optional-woodwork-compat.ps1",
    "verify-registry.ps1",
    "verify-silkworm-chain.ps1",
    "verify-silkworm-lifecycle.ps1",
    "verify-vegetable-beverage-processing.ps1",
    "verify-woodwork-flow.ps1",
    "verify-workbench-recipes.ps1",
]
B_GENERATE = ["migrate-tfcwoodwork.ps1"]


def wrapper(tools: Path, relative: str) -> str:
    return (
        "# Compatibility wrapper; the maintained script lives under scripts/.\n"
        "$env:TFC_TOOLS_ROOT = $PSScriptRoot\n"
        f"& (Join-Path $PSScriptRoot '{relative}') @args\n"
        "exit $LASTEXITCODE\n"
    )


def move_group(tools: Path, category: str, names: list[str]) -> None:
    target_dir = tools / "scripts" / category
    target_dir.mkdir(parents=True, exist_ok=True)
    for name in names:
        source = tools / name
        if not source.exists():
            print(f"MISSING {tools.name}/{name}")
            continue
        target = target_dir / name
        text = source.read_text(encoding="utf-8")
        text = text.replace("$PSScriptRoot", "$env:TFC_TOOLS_ROOT")
        target.write_text(text, encoding="utf-8-sig", newline="\n")
        wrapper_text = wrapper(tools, f"scripts/{category}/{name}")
        source.write_text(wrapper_text, encoding="utf-8-sig", newline="\n")
        print(f"{tools.name}/{name} -> scripts/{category}/{name} (+ wrapper)")


def main() -> int:
    move_group(A, "audit", A_AUDIT)
    move_group(A, "generate", A_GENERATE)
    move_group(A, "verify", A_VERIFY)
    move_group(B, "verify", B_VERIFY)
    move_group(B, "generate", B_GENERATE)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
