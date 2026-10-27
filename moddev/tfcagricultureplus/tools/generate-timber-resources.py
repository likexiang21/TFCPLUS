"""Generate material variants using licensed shared geometry and installed material IDs."""
import base64
import json
import re
import zipfile
from pathlib import Path

project = Path(__file__).resolve().parents[1]
instance = project.parent.parent
resources = project / "src/main/resources"
namespace = "tfcagricultureplus"
source = (project / "src/main/java/com/example/tfcfarmingplus/expansion/common/MyBlocks.java").read_text(encoding="utf-8")
woods = {}
for origin in ("TFC", "AFC"):
    body = re.search(rf'{origin}_WOODS = List.of\((.*?)\);', source, re.S).group(1)
    woods.update({wood: origin.lower() if origin == "AFC" else "tfc" for wood in re.findall(r'"([a-z_]+)"', body)})
jars = [zipfile.ZipFile(path) for path in (instance / "mods").glob("*.jar")]
entries = {name: jar for jar in jars for name in jar.namelist()}

def write(relative, value):
    path = resources / relative
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

def load(name):
    return json.loads(entries[name].read(name))

for kind in ("debarked_log", "debarked_half", "debarked_quarter"):
    template = json.loads((resources / f"assets/{namespace}/models/block/timber/{kind}.json").read_text(encoding="utf-8"))
    write(f"assets/{namespace}/models/block/timber/{kind}.json", template)

mineable = []
pieces = []
for wood, origin in woods.items():
    material = load(f"assets/{origin}/models/block/wood/stripped_log/{wood}.json")["textures"]
    for texture in material.values():
        domain, path = texture.split(":")
        assert f"assets/{domain}/textures/{path}.png" in entries, texture
    names = {}
    for index, kind in enumerate(("debarked_log", "debarked_half", "debarked_quarter")):
        name = f"{kind}/{wood}"
        names[kind] = f"{namespace}:{name}"
        # Only AFC pieces are active in this module's log-pile tag. TFC wood
        # remains registered for legacy stacks, while TFC Woodworking owns its
        # current processing and pile inputs.
        if origin == "afc":
            pieces.append(names[kind])
        mineable.append(names[kind])
        write(f"assets/{namespace}/models/block/{name}.json", {
            "parent": f"{namespace}:block/timber/{kind}",
            "textures": {"side": material["side"], "top": material["end"], "inner": material["side"], "particle": material["side"]}})
        write(f"assets/{namespace}/models/item/{name}.json", {"parent": f"{namespace}:block/{name}"})
        write(f"assets/{namespace}/blockstates/{name}.json", {"variants": {
            f"facing={facing}": {"model": f"{namespace}:block/{name}", "y": rotation}
            for facing, rotation in (("north", 0), ("east", 90), ("south", 180), ("west", 270))}})
        write(f"data/{namespace}/loot_table/blocks/{name}.json", {"type": "minecraft:block", "pools": [{
            "rolls": 1, "entries": [{"type": "minecraft:item", "name": names[kind]}],
            "conditions": [{"condition": "minecraft:survives_explosion"}]}]})
        # Fuel duration follows mass, preventing splitting from increasing total burn time.
        fuel = load(f"data/tfc/tfc/fuel/{wood}_logs.json")
        fuel = {key: value for key, value in fuel.items() if not key.startswith("__")}
        fuel["ingredient"] = {"item": names[kind]}
        fuel["duration"] = max(1, int(fuel["duration"]) // (1 << index))
        write(f"data/{namespace}/tfc/fuel/{kind}_{wood}.json", fuel)
    if origin == "tfc":
        continue
    recipes = [
        ("debark", f"{origin}:wood/stripped_log/{wood}", "axe", names["debarked_log"], []),
        ("split_log", names["debarked_log"], "axe", "minecraft:air", [(names["debarked_half"], 2)]),
        ("split_half", names["debarked_half"], "axe", "minecraft:air", [(names["debarked_quarter"], 2)]),
        ("saw_half", names["debarked_half"], "saw", "minecraft:air", [(f"{origin}:wood/support/{wood}", 4)]),
        ("saw_quarter", names["debarked_quarter"], "saw", "minecraft:air", [(f"{origin}:wood/lumber/{wood}", 2)])]
    for stage, input_block, tool, result, extras in recipes:
        write(f"data/{namespace}/recipe/in_world/timber_{stage}_{wood}.json", {
            "type": f"{namespace}:in_world", "input_state": {"block": input_block}, "tool": tool,
            "result_state": {"Name": result},
            "result_items": [{"item": {"id": item, "count": count}, "action": "drop_above"} for item, count in extras]})

write(f"data/{namespace}/tags/item/log_pile_logs.json", {"replace": False, "values": ["#tfc:log_pile_logs"] + pieces})
axe_path = resources / "data/minecraft/tags/block/mineable/axe.json"
axe_tag = json.loads(axe_path.read_text(encoding="utf-8")) if axe_path.exists() else {"replace": False, "values": []}
axe_tag["values"] = list(dict.fromkeys(axe_tag["values"] + mineable + [f"{namespace}:log_pile"]))
write("data/minecraft/tags/block/mineable/axe.json", axe_tag)
for pile in ("log_pile", "burning_log_pile"):
    write(f"assets/{namespace}/blockstates/{pile}.json", {"variants": {"": {"model": f"{namespace}:block/timber/pile_particle"}}})
write(f"assets/{namespace}/models/block/timber/pile_particle.json", {"textures": {"particle": "tfc:block/wood/log/oak"}, "elements": []})

for language in ("en_us", "zh_cn"):
    path = resources / f"assets/{namespace}/lang/{language}.json"
    data = json.loads(path.read_text(encoding="utf-8"))
    for wood in woods:
        existing = data[f"block.{namespace}.log_cutting_board.{wood}"]
        label = existing.removesuffix("原木案板").removesuffix("原木砧板").strip() if language == "zh_cn" else wood.replace("_", " ").title()
        for kind, en, cn in (("debarked_log", "Debarked Log", "去皮原木"), ("debarked_half", "Split Log Half", "半木"), ("debarked_quarter", "Split Log Quarter", "四分木")):
            data[f"block.{namespace}.{kind}.{wood}"] = f"{label}{cn}" if language == "zh_cn" else f"{label} {en}"
    data[f"block.{namespace}.log_pile"] = "木料堆" if language == "zh_cn" else "Timber Pile"
    data[f"block.{namespace}.burning_log_pile"] = "闷烧木料堆" if language == "zh_cn" else "Burning Timber Pile"
    data[f"tooltip.{namespace}.timber.pile"] = "潜行放置成木料堆；右键添加，空手取回。整木/半木/四分木按体积计量。" if language == "zh_cn" else "Sneak-place a pile; use to add, empty hand to retrieve. Logs, halves and quarters retain their volume."
    write(f"assets/{namespace}/lang/{language}.json", data)

workspace = next(parent for parent in project.parents if (parent / ".tooling/reference/tfcwoodwork-license.json").exists())
license_data = json.loads((workspace / ".tooling/reference/tfcwoodwork-license.json").read_text(encoding="utf-8-sig"))
notice = resources / "META-INF/licenses/tfcwoodwork-MIT.txt"
notice.parent.mkdir(parents=True, exist_ok=True)
notice.write_bytes(base64.b64decode(license_data["content"]))
(resources / "META-INF/licenses/timber-notice.txt").write_text(
    "Shared timber geometry adapted from TFC Woodworking 1.2.4, copyright (c) 2024 uTa4u.\n"
    "Source: https://github.com/uTa4u/TFC-Woodworking\n"
    "See tfcwoodwork-MIT.txt. Material textures are referenced from TFC/ArborFirmaCraft, not redistributed.\n", encoding="utf-8")
print(f"Generated {len(pieces)} active AFC pile pieces, {len(pieces)//3*5} in-world recipes and two pile states.")
