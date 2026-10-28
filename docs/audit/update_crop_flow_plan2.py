from pathlib import Path

p = Path("mod_rebuild/docs/audit/generate_crop_flow_yield_plan.py")
t = p.read_text(encoding="utf-8")

# Additional flow overrides for crops with clearly different processing.
old = '''    "spinach": "leaf-preserve", "lettuce": "leaf-preserve",
}'''
new = '''    "spinach": "leaf-preserve", "lettuce": "leaf-preserve",
    "red_bell_pepper": "fruit-spice", "yellow_bell_pepper": "fruit-spice",
    "green_bean": "legume-dry", "lentil": "legume-dry",
    "onion": "root-spice", "garlic": "root-spice", "shallot": "root-spice",
    "beet": "root-starch",
}'''
if old not in t:
    raise SystemExit("flow block missing")
t = t.replace(old, new)

# Baseline per source, before table output.
old = '''for r in rows:
    flow = flow_override.get(r["crop"], profile_for_group[r["group"]])'''
new = '''for r in rows:
    if r["source"] == "TFC":
        if r["crop"] in ("red_bell_pepper", "yellow_bell_pepper"):
            r["baseline"] = "4–5 ×2（TFC 原值）"
        elif r["crop"] in ("melon", "pumpkin"):
            r["baseline"] = "果实方块 1–2 个（非 6–10 池）"
        else:
            r["baseline"] = "0–(6–10)，种子 1（部分 1–2）"
    else:
        r["baseline"] = "0–(6–10)，种子 1（个别 1–2）"
    flow = flow_override.get(r["crop"], profile_for_group[r["group"]])'''
if old not in t:
    raise SystemExit("baseline block missing")
t = t.replace(old, new)

# Add baseline column header.
t = t.replace('| # | 作物 | 来源/组 | 流程 profile | raw 目标 | seedBack | processed 目标 | 副产品目标 | 定制关键步骤 |',
              '| # | 作物 | 来源/组 | 流程 profile | 现有产率基线 | raw 目标 | seedBack | processed 目标 | 副产品目标 | 定制关键步骤 |')
t = t.replace('|---:|---|---|---|---|---|---|---|---|',
              '|---:|---|---|---|---|---|---|---|---|---|')
t = t.replace('f"| {i} | `{r[\'crop\']}` | {r[\'source\']}·{r[\'group\']} | `{r[\'flow\']}` | {r[\'raw\']} |',
              'f"| {i} | `{r[\'crop\']}` | {r[\'source\']}·{r[\'group\']} | `{r[\'flow\']}` | {r[\'baseline\']} | {r[\'raw\']} |')

p.write_text(t, encoding="utf-8")
print("generator patched")
