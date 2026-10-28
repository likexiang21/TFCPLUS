from pathlib import Path

p = Path("mod_rebuild/tfcagricultureplus/tools/verify_pan_system.py")
t = p.read_text(encoding="utf-8")
t = t.replace('need(ASSETS / "models/item/metal_can.json")\n'
              'need(DATA / "recipe/anvil/metal_can.json")\n'
              'need(DATA / "recipe/heating/metal/metal_can.json")\n'
              'need(DATA / "tags/fluid/metal_can_fluids.json")',
              'metal_cans = ("bismuth", "bismuth_bronze", "black_bronze", "bronze", "brass",\n'
              '              "copper", "gold", "nickel", "rose_gold", "silver", "tin", "zinc",\n'
              '              "sterling_silver", "wrought_iron", "cast_iron", "steel", "black_steel",\n'
              '              "blue_steel", "red_steel")\n'
              'for metal in metal_cans:\n'
              '    need(ASSETS / f"models/item/metal_can/{metal}.json")\n'
              '    need(DATA / f"recipe/anvil/metal_can_{metal}.json")\n'
              '    need(DATA / f"recipe/heating/metal/metal_can_{metal}.json")\n'
              'need(DATA / "tags/fluid/metal_can_fluids.json")')
p.write_text(t, encoding="utf-8")
print("metal can verifier updated")
