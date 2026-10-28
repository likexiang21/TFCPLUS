from pathlib import Path

p = Path("mod_rebuild/tfcagricultureplus/tools/verify_pan_system.py")
t = p.read_text(encoding="utf-8")
t = t.replace('    "wood", "ceramic_white",', '    "wood", "ceramic", "ceramic_white",')
t = t.replace('need(DATA / "recipe/heating/ceramic/plate_ceramic_white.json")',
              'need(DATA / "recipe/heating/ceramic/unfired_plate.json")\n'
              'need(DATA / "recipe/heating/ceramic/white_unfired_plate.json")')
old = '''for material in ("wood", "wrought_iron", "steel", "black_steel", "blue_steel", "red_steel"):
    need(ASSETS / f"models/item/spatula/{material}.json")
    need(DATA / f"recipe/crafting/spatula_{material}.json")
'''
new = '''for material in ("wood", "wrought_iron", "steel", "black_steel", "blue_steel", "red_steel"):
    need(ASSETS / f"models/item/spatula/{material}.json")
    need(DATA / f"recipe/crafting/spatula_{material}.json")
for material in ("wrought_iron", "steel", "black_steel", "blue_steel", "red_steel"):
    need(ASSETS / f"models/item/spatula_head/{material}.json")
    need(DATA / f"recipe/anvil/spatula_head_{material}.json")
'''
if old not in t:
    raise SystemExit("spatula block missing")
t = t.replace(old, new)
t = t.replace('need(DATA / "recipe/crafting/bowl_wood.json")',
              'need(ASSETS / "models/item/metal_can.json")\n'
              'need(DATA / "recipe/anvil/metal_can.json")\n'
              'need(DATA / "recipe/heating/metal/metal_can.json")\n'
              'need(DATA / "tags/fluid/metal_can_fluids.json")\n'
              'need(DATA / "recipe/crafting/bowl_wood.json")')
p.write_text(t, encoding="utf-8")
print("verifier updated")
