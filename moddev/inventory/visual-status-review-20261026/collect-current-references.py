"""Read current source and installed dependencies; write review evidence only.

This is a reference inventory, not a visual quality or runtime acceptance test.
Run from the instance root. No game files, textures or protected labs are edited.
"""
from collections import Counter
from functools import lru_cache
from pathlib import Path
import csv
import hashlib
import io
import json
import zipfile

from PIL import Image

ROOT = Path.cwd()
OUT = Path(__file__).resolve().parent
MODULES = ["tfcfarmingplus", "tfcagricultureplus"]
RESOURCES = [ROOT / f"moddev/{module}/src/main/resources" for module in MODULES]
archives = []
index = {}
conflicts = []


def digest(data):
    return hashlib.sha256(data).hexdigest().upper()


def save(name, value):
    (OUT / name).write_text(json.dumps(value, ensure_ascii=False, indent=2), encoding="utf-8")


def canonical(identifier):
    return identifier if ":" in identifier else "minecraft:" + identifier


def resource(identifier, kind, extension):
    namespace, path = canonical(identifier).split(":", 1)
    return f"assets/{namespace}/{kind}/{path}.{extension}"


def read(path):
    entry = index[path]
    return entry.read_bytes() if isinstance(entry, Path) else entry[0].read(entry[1])


def origin(path):
    entry = index[path]
    return str(entry.relative_to(ROOT)) if isinstance(entry, Path) else entry[0].filename + "!/" + path


def document(path):
    return json.loads(read(path).decode("utf-8-sig"))


for jar in sorted((ROOT / "mods").glob("*.jar")) + [Path("D:/TFC农业重置/.tooling/game/versions/1.21.1/1.21.1.jar")]:
    archive = zipfile.ZipFile(jar)
    archives.append(archive)
    for path in archive.namelist():
        if path.startswith("assets/") and path.endswith((".json", ".png")):
            index.setdefault(path, (archive, path))

# Explicit source overrides: B over A in this inventory. Record collisions rather
# than claiming that arbitrary external resource-pack ordering is verified.
for module, root in zip(MODULES, RESOURCES):
    for path in sorted((root / "assets").rglob("*")):
        if path.is_file():
            key = path.relative_to(root).as_posix()
            if key in index and isinstance(index[key], Path):
                conflicts.append({"path": key, "previous": origin(key), "next": str(path.relative_to(ROOT))})
            index[key] = path


@lru_cache(None)
def model(identifier):
    identifier = canonical(identifier)
    path = resource(identifier, "models", "json")
    data = document(path)
    parent = data.get("parent")
    inherited = model(canonical(parent)) if parent and not parent.startswith("builtin/") else {}
    result = dict(inherited)
    result.update(data)
    result["textures"] = dict(inherited.get("textures", {})) | data.get("textures", {})
    result["chain"] = [path] + inherited.get("chain", [])
    return result


def slot(value, textures):
    seen = set()
    while value.startswith("#"):
        if value in seen:
            raise ValueError("Texture alias cycle: " + value)
        seen.add(value)
        value = textures[value[1:]]
    return canonical(value)


def applications(value, condition=""):
    if isinstance(value, dict):
        if "model" in value:
            yield condition, value
        elif "variants" in value:
            for state, application in value["variants"].items():
                yield from applications(application, state)
        elif "multipart" in value:
            for part in value["multipart"]:
                yield from applications(part["apply"], json.dumps(part.get("when", {}), sort_keys=True))
    elif isinstance(value, list):
        for child in value:
            yield from applications(child, condition)


states = sorted(p.relative_to(RESOURCES[0]).as_posix() for p in (RESOURCES[0] / "assets").rglob("blockstates/**/*.json"))
states.append("assets/tfc/blockstates/crop/cabbage.json")
references = []
errors = []
used_textures = set()
for state in states:
    for condition, application in applications(document(state)):
        identifier = canonical(application["model"])
        try:
            resolved = model(identifier)
            values = set()
            for element in resolved.get("elements", []):
                for face in element.get("faces", {}).values():
                    values.add(slot(face["texture"], resolved["textures"]))
            # Generated item models have layers rather than element faces.
            if not values:
                for key, value in resolved.get("textures", {}).items():
                    if key.startswith("layer"):
                        values.add(slot(value, resolved["textures"]))
            for texture in values:
                key = resource(texture, "textures", "png")
                if key not in index:
                    raise KeyError(key)
                used_textures.add(key)
            references.append({"Blockstate": state, "Condition": condition, "Application": application,
                               "Model": identifier, "Chain": resolved["chain"], "Elements": len(resolved.get("elements", [])),
                               "Textures": sorted(values), "VisualAccepted": False, "RuntimeVerified": False})
        except (KeyError, ValueError) as error:
            errors.append({"Blockstate": state, "Model": identifier, "Error": str(error)})

trees = []
for state in states:
    if "/plant/" not in state or not state.endswith("_leaves.json"):
        continue
    cases = [row for row in references if row["Blockstate"] == state]
    for case in cases:
        resolved = model(case["Model"])
        elements = resolved.get("elements", [])
        cube = len(elements) == 1 and elements[0]["from"] == [0, 0, 0] and elements[0]["to"] == [16, 16, 16] and len(elements[0].get("faces", {})) == 6
        trees.append({"Species": Path(state).stem.removesuffix("_leaves"), "Lifecycle": case["Condition"],
                      "Model": case["Model"], "FullCubeGeometry": cube, "Textures": case["Textures"],
                      "VisualAccepted": False, "RuntimeVerified": False})

manifest = json.loads((ROOT / "moddev/tfcfarmingplus/tools/crops-manifest.json").read_text(encoding="utf-8-sig"))["crops"]
crop_rows = []
seams = []
for crop in manifest:
    name = crop["name"]
    state = f"assets/tfcfarmingplus/blockstates/crop/{name}.json"
    cases = [row for row in references if row["Blockstate"] == state]
    textures = sorted({texture for row in cases for texture in row["Textures"]})
    seed_key = resource(f"tfcfarmingplus:item/seeds/{name}", "models", "json")
    seed_model = model(f"tfcfarmingplus:item/seeds/{name}") if seed_key in index else None
    seed_textures = sorted({slot(v, seed_model["textures"]) for k, v in seed_model["textures"].items() if k.startswith("layer")}) if seed_model else []
    crop_rows.append({"Name": name, "Double": crop["double"], "Climb": crop["climb"],
                      "ModelApplications": len(cases), "Models": sorted({row["Model"] for row in cases}),
                      "Textures": textures, "SeedModel": seed_key if seed_model else None, "SeedTextures": seed_textures,
                      "VisualAccepted": False, "RuntimeVerified": False})
    for texture in textures:
        if not texture.endswith("_bottom"):
            continue
        top = texture.removesuffix("_bottom") + "_top"
        if top not in textures:
            continue
        bottom_image = Image.open(io.BytesIO(read(resource(texture, "textures", "png")))).convert("RGBA")
        top_image = Image.open(io.BytesIO(read(resource(top, "textures", "png")))).convert("RGBA")
        if bottom_image.size != (16, 16) or top_image.size != (16, 16):
            raise ValueError("Unexpected paired texture size")
        def visible(pixel):
            return pixel if pixel[3] else (0, 0, 0, 0)
        differences = [x for x in range(16) if visible(bottom_image.getpixel((x, 0))) != visible(top_image.getpixel((x, 15)))]
        seams.append({"Species": name, "Bottom": texture, "Top": top, "DifferentColumns": differences,
                      "Status": "定位线索；须核几何UV并整株查看，非自动缺陷判定", "VisualAccepted": False})

source_textures = [p.relative_to(RESOURCES[0]).as_posix() for p in (RESOURCES[0] / "assets/tfcfarmingplus/textures").rglob("*.png")]
model_json = [p for root in RESOURCES for p in (root / "assets").rglob("models/**/*.json")]
all_literal_texture_refs = set()
for path in model_json:
    for value in json.loads(path.read_text(encoding="utf-8-sig")).get("textures", {}).values():
        if not value.startswith("#"):
            all_literal_texture_refs.add(resource(value, "textures", "png"))
texture_rows = [{"Path": key, "Sha256": digest(read(key)), "DeclaredInSourceModel": key in all_literal_texture_refs,
                 "UsedByScannedBlockstates": key in used_textures} for key in sorted(source_textures)]
save("blockstate-references.json", {"Scope": "A source-declared blockstates plus actual native cabbage blockstate; not registration proof or external-pack verification", "Blockstates": len(states), "Applications": references, "SourceCollisions": conflicts, "Findings": errors})
save("tree-leaf-cubes.json", {"Cases": trees, "Species": len({row["Species"] for row in trees}), "NonCubeCases": [row for row in trees if not row["FullCubeGeometry"]]})
save("crop-visual-references.json", {"Crops": crop_rows, "LivePairedTextures": seams})
save("texture-provenance.json", texture_rows)
summary = {"Blockstates": len(states), "ModelApplications": len(references), "UnresolvedApplications": len(errors),
           "CropSpecies": len(crop_rows), "TallSpecies": sum(row["Double"] or row["Climb"] for row in crop_rows),
           "TreeSpecies": len({row["Species"] for row in trees}), "TreeLeafCases": len(trees),
           "NonCubeTreeLeafCases": sum(not row["FullCubeGeometry"] for row in trees),
           "SourcePNG": len(source_textures), "LivePairedTextures": len(seams),
           "PairedTextureBoundaryDifferences": sum(bool(row["DifferentColumns"]) for row in seams),
           "MissingOwnSeedModels": [row["Name"] for row in crop_rows if not row["SeedModel"]],
           "SeedTextureNamespaces": dict(Counter(texture.split(":")[0] for row in crop_rows for texture in row["SeedTextures"])),
           "VisualAccepted": False, "RuntimeVerified": False}
save("reference-summary.json", summary)
for archive in archives:
    archive.close()
print(json.dumps(summary, ensure_ascii=False))
if errors:
    raise SystemExit(1)
