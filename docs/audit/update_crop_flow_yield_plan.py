from pathlib import Path

p = Path("mod_rebuild/docs/audit/generate_crop_flow_yield_plan.py")
t = p.read_text(encoding="utf-8")

# 1. Add TFC-specific actual raw yields after the generic tweaks.
old = '''for r in rows:
    if r["crop"] in yield_tweaks:
        raw, seed, processed, by = yield_tweaks[r["crop"]]
        r["raw"] = raw; r["seed"] = seed; r["processed"] = processed; r["by_yield"] = by

'''
new = '''for r in rows:
    if r["crop"] in yield_tweaks:
        raw, seed, processed, by = yield_tweaks[r["crop"]]
        r["raw"] = raw; r["seed"] = seed; r["processed"] = processed; r["by_yield"] = by

# TFC raw drops are preserve-as-is. Do not raise them to A-profile targets.
for r in rows:
    if r["source"] == "TFC":
        if r["crop"] in ("red_bell_pepper", "yellow_bell_pepper"):
            r["raw"] = "4–5（TFC 原值，双池）"
            r["processed"] = "1–2 份干椒/椒粉"
        elif r["crop"] in ("melon", "pumpkin"):
            r["raw"] = "1–2 个果实（果实方块，不是 6–10 作物池）"
            r["processed"] = "1–3 份果肉/酱 + 1–2 份瓜籽"
        else:
            r["raw"] = "6–10（TFC 原值）"

'''
if old not in t:
    raise SystemExit("tweaks block missing")
t = t.replace(old, new)

# 2. Fix mass-conservation statement.
t = t.replace('"约束 2：processed + byproduct <= raw（质量不凭空增加）\\n"',
              '"约束 2：processed <= raw（主产品加工不凭空增加；副产品来自秸秆/皮/荚等非主产部位）\\n"')

# 3. Add crop-specific key steps for more crops.
old_key = '''    elif r["crop"] in ("agave",):
        key = "叶纤维与心糖浆分开：" + key
'''
new_key = '''    elif r["crop"] in ("agave",):
        key = "叶纤维与心糖浆分开：" + key
    elif r["crop"] in ("wheat", "barley", "rye", "oat"):
        key = "先脱粒/扬场，麦类另走麦芽：" + key
    elif r["crop"] == "rice":
        key = "先脱粒、砻谷、碾米：" + key
    elif r["crop"] in ("maize", "sorghum", "millet", "foxtail_millet", "pearl_millet", "finger_millet"):
        key = "脱粒→去壳/磨粉；秸秆另收：" + key
    elif r["crop"] in ("chickpea", "faba_bean", "lupin", "adzuki", "pea", "cowpea",
                       "common_bean", "winged_bean", "pigeon_pea", "green_bean", "lentil"):
        key = "先脱荚/浸泡，豆类去毒/磨浆：" + key
    elif r["crop"] in ("turnip", "parsnip", "celeriac", "salsify", "chicory_root", "radish", "carrot", "beet"):
        key = "先去皮/切片，再晒干或沉淀淀粉：" + key
    elif r["crop"] in ("sunchoke", "shallot", "onion", "garlic", "potato", "yacon", "water_chestnut", "water_caltrop", "lotus", "arrowhead", "gorgon_nut"):
        key = "先分级/催芽或去壳，再煮/磨粉：" + key
    elif r["crop"] in ("broccoli", "cauliflower", "brussels_sprouts", "cabbage", "napa_cabbage", "kale"):
        key = "先切分/盐渍，叶球类可发酵：" + key
'''
if old_key not in t:
    raise SystemExit("key block missing")
t = t.replace(old_key, new_key)

# 4. Add source column note in table section.
t = t.replace('lines_out.append("\\n## 4. 逐作物流程与产量表（116 条）\\n")',
              'lines_out.append("\\n## 4. 逐作物流程与产量表（116 条）\\n")\n'
              'lines_out.append("> TFC 行 raw 保留 TFC 原值；A 行按 profile 目标调整，原始掉落改动需单独评审。\\n")')

p.write_text(t, encoding="utf-8")
print("generator updated")
