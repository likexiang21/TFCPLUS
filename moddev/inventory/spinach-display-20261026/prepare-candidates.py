"""Prepare isolated source-based display candidates; never write runtime sources."""
from pathlib import Path
import copy
import hashlib
import json
import zipfile

ROOT = Path.cwd()
OUT = Path(__file__).resolve().parent
SOURCE = ROOT / "moddev/tfcfarmingplus/src/main/resources"
NAMESPACE = "assets/tfcfarmingplus/"
candidates = {}


def bind(texture):
    return {"parent": "minecraft:block/crop", "textures": {"crop": texture}}


for age in range(6):
    candidates[NAMESPACE + f"models/block/crop/spinach_age_{age}.json"] = bind(f"tfcfarmingplus:block/crop/spinach_age_{age}")
candidates[NAMESPACE + "models/block/wild_crop/spinach.json"] = {"parent": "tfcfarmingplus:block/crop/spinach_age_5"}
candidates[NAMESPACE + "models/block/wild_crop/spinach_young.json"] = {"parent": "tfcfarmingplus:block/crop/spinach_age_1"}
for suffix in ["", "_young"]:
    candidates[NAMESPACE + f"models/block/dead_crop/spinach{suffix}.json"] = bind(f"tfcfarmingplus:block/dead_crop/spinach{suffix}")
wild_state = json.loads((SOURCE / (NAMESPACE + "blockstates/wild_crop/spinach.json")).read_text(encoding="utf-8-sig"))
wild_state["variants"]["mature=false"]["model"] = "tfcfarmingplus:block/wild_crop/spinach_young"
candidates[NAMESPACE + "blockstates/wild_crop/spinach.json"] = wild_state
for item in ["seeds", "food"]:
    candidates[NAMESPACE + f"models/item/{item}/spinach.json"] = {"parent": "minecraft:item/generated", "textures": {"layer0": f"tfcfarmingplus:item/{item}/spinach"}}
planter_key = "data/firmalife/firmalife/plantable/spinach.json"
planter = json.loads((SOURCE / planter_key).read_text(encoding="utf-8-sig"))
planter["textures"] = [f"tfcfarmingplus:block/crop/spinach_age_{age}" for age in range(6)]
candidates[planter_key] = planter
# Exclude only the obsolete flower region while preserving leaf UV scale.
with zipfile.ZipFile("D:/TFC农业重置/.tooling/game/versions/1.21.1/1.21.1.jar") as client:
    native = json.loads(client.read("assets/minecraft/models/block/crop.json"))
for key in [NAMESPACE + "models/block/crop/spinach_age_5.json", NAMESPACE + "models/block/dead_crop/spinach.json"]:
    elements = copy.deepcopy(native["elements"])
    for element in elements:
        element["to"][1] -= 5
        for face in element["faces"].values():
            face["uv"][1] += 5
    candidates[key]["elements"] = elements
candidates[NAMESPACE + "models/item/food/spinach.json"]["textures"]["layer0"] = "tfcfarmingplus:item/food/kale"
candidates[NAMESPACE + "models/item/seeds/spinach.json"]["textures"]["layer0"] = "tfc:item/seeds/lentil"
candidates[planter_key]["textures"][-1] = "tfcfarmingplus:block/crop/spinach_age_4"
for key, value in candidates.items():
    path = OUT / "candidate-resources" / key
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, separators=(",", ":")) + "\n", encoding="utf-8")
(OUT / "runtime-files.json").write_text(json.dumps(sorted(candidates), indent=2), encoding="utf-8")

archives = [zipfile.ZipFile(ROOT / "mods/TerraFirmaCraft-NeoForge-1.21.1-4.2.11.jar"), zipfile.ZipFile("D:/TFC农业重置/.tooling/game/versions/1.21.1/1.21.1.jar")]
origins = []


def read(key, phase):
    candidate = OUT / "candidate-resources" / key
    source = SOURCE / key
    if phase == "candidate" and candidate.is_file():
        return candidate.read_bytes(), str(candidate.relative_to(ROOT))
    if source.is_file():
        return source.read_bytes(), str(source.relative_to(ROOT))
    for archive in archives:
        if key in archive.namelist():
            return archive.read(key), archive.filename + "!/" + key
    raise FileNotFoundError(key)


def export(identifier, phase, seen):
    if identifier.startswith("builtin/"):
        return
    if ":" not in identifier:
        identifier = "minecraft:" + identifier
    namespace, path = identifier.split(":", 1)
    key = f"assets/{namespace}/models/{path}.json"
    if key in seen:
        return
    seen.add(key)
    data, origin = read(key, phase)
    target = OUT / ("assets-" + phase) / key.removeprefix("assets/")
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(data)
    origins.append({"Phase": phase, "Resource": key, "Origin": origin, "Sha256": hashlib.sha256(data).hexdigest().upper()})
    model = json.loads(data.decode("utf-8-sig"))
    if model.get("parent"):
        export(model["parent"], phase, seen)
    for texture in model.get("textures", {}).values():
        if texture.startswith("#"):
            continue
        if ":" not in texture:
            texture = "minecraft:" + texture
        namespace, path = texture.split(":", 1)
        key = f"assets/{namespace}/textures/{path}.png"
        data, origin = read(key, phase)
        target = OUT / ("assets-" + phase) / key.removeprefix("assets/")
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
        origins.append({"Phase": phase, "Resource": key, "Origin": origin, "Sha256": hashlib.sha256(data).hexdigest().upper()})


for phase in ["before", "candidate"]:
    identifiers = []
    for form in ["crop", "wild_crop", "dead_crop"]:
        key = NAMESPACE + f"blockstates/{form}/spinach.json"
        state = json.loads(read(key, phase)[0].decode("utf-8-sig"))
        for application in state["variants"].values():
            identifiers.append(application["model"])
    seen = set()
    for identifier in identifiers:
        export(identifier, phase, seen)
    (OUT / (phase + "-models.txt")).write_text("\n".join(identifiers) + "\n", encoding="utf-8")
(OUT / "preview-sources.json").write_text(json.dumps(origins, ensure_ascii=False, indent=2), encoding="utf-8")
for archive in archives:
    archive.close()
print(f"Prepared {len(candidates)} candidate JSONs; ten block-state models per phase.")
