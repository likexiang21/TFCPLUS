from pathlib import Path
import re

base = Path("mod_rebuild/tfcagricultureplus/src/main/java/io/github/likexiang21/tfcplus/agriculture/common")
files = [
    base / "blockentity/CuttingBoardBlockEntity.java",
    base / "blockentity/DryingRackBlockEntity.java",
    base / "blockentity/KitchenStorageBlockEntity.java",
    base / "blockentity/KnifeRackBlockEntity.java",
    base / "blockentity/MortarBlockEntity.java",
    base / "blockentity/PlaceableFoodBlockEntity.java",
    base / "blockentity/SilkwormRackBlockEntity.java",
    base / "blockentity/CookingPanBlockEntity.java",
    base / "timber/TimberPileBlockEntity.java",
]
for path in files:
    text = path.read_text(encoding="utf-8")
    if "implements BContainer" in text:
        continue
    text = text.replace("package io.github.likexiang21.tfcplus.agriculture.common",
                        "package io.github.likexiang21.tfcplus.agriculture.common", 1)
    # Insert import after the package statement.
    text = re.sub(r"(package [^\n]+;\n)", r"\1\nimport io.github.likexiang21.tfcplus.agriculture.common.container.BContainer;\n", text, count=1)
    # Add the interface to the first class declaration.
    text = re.sub(r"(public (?:final )?class \w+ extends [^{]+)\{", r"\1 implements BContainer {", text, count=1)
    # Insert adapter before the final class closing brace.
    idx = text.rfind("}")
    adapter = "\n    @Override public net.neoforged.neoforge.items.IItemHandler bItemHandler() { return inventory; }\n"
    text = text[:idx] + adapter + text[idx:]
    path.write_text(text, encoding="utf-8")
    print("adapted", path.name)
