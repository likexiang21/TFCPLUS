from pathlib import Path
import re

src = Path("mod_rebuild/docs/289-crop-master-plan-20261028.md")
out = Path("mod_rebuild/docs/290-crop-flow-and-yield-balance-20261028.md")
lines = src.read_text(encoding="utf-8").splitlines()

rows = []
for line in lines:
    m = re.match(r"\|\s*\d+\s*\|\s*`([^`]+)`\s*\|\s*([^|]+?)\s*\|(.*)\|\s*$", line)
    if not m:
        continue
    crop = m.group(1)
    sg = m.group(2).strip()
    # source·group
    source, group = [x.strip() for x in sg.split("·", 1)]
    cells = [x.strip() for x in m.group(3).split("|")]
    # cells = main, by, prop, nursery, process, outlet, batch (trailing empty removed)
    cells = [x for x in cells if x != ""]
    if len(cells) < 7:
        raise SystemExit(f"parse failed {crop}: {cells}")
    main, by, prop, nursery, process, outlet, batch = cells[:7]
    rows.append(dict(crop=crop, source=source, group=group, main=main, by=by,
                     prop=prop, nursery=nursery, process=process, outlet=outlet, batch=batch))

if len(rows) != 116:
    raise SystemExit(f"expected 116 rows, got {len(rows)}")

profile_for_group = {
    "叶菜/茎菜": "leaf-preserve",
    "根/块茎/鳞茎": "root-starch",
    "谷物/禾本": "grain-mill",
    "豆类": "legume-dry",
    "油料": "oil-press",
    "纤维": "fiber-bast",
    "茄果/瓜类": "fruit-preserve",
    "香草/香料": "herb-dry",
    "特用": "special",
    "水生/其他": "water-grain",
    "浆果特例": "berry-runner",
    "叶菜/饲草": "leaf-forage",
    "豆类/油料": "legume-oil",
    "水生/纤维": "fiber-water",
}

profile = {
    "leaf-preserve": dict(
        raw="8–12 叶/球/茎", seed="1", processed="2–4 份腌/干/切丝",
        by="2–4 外叶/叶柄 → 堆肥/饲料",
        note="高含水：鲜重高、干重低；腌/干后重量下降，但必须保留主产品重量感"),
    "root-starch": dict(
        raw="4–8 根/块茎", seed="1 个种薯/种球或 1 粒种子", processed="1–2 份淀粉/粉/干片",
        by="1–2 皮渣/茎叶 → 饲料/堆肥",
        note="淀粉类应按出粉率折算；cassava/taro 必须先脱毒"),
    "grain-mill": dict(
        raw="6–10 穗/籽粒", seed="1–2 粒", processed="3–5 份面粉/米/麦芽",
        by="2–4 秸秆/糠麸 → 饲料/燃料/堆肥",
        note="带壳谷物先脱壳；麦类可制麦芽，稻类碾米"),
    "legume-dry": dict(
        raw="6–10 荚/豆", seed="1–2 粒", processed="2–4 份干豆/豆粉/豆制品",
        by="1–3 豆荚/秸秆 → 饲料/堆肥",
        note="鲜食豆与干豆分开；干豆先脱荚再浸泡"),
    "oil-press": dict(
        raw="4–8 单位油籽", seed="1–2 粒", processed="1–2 份油",
        by="1–2 油饼/粕 → 饲料/肥料",
        note="油料按含油率折算；不得把油饼算成油"),
    "fiber-bast": dict(
        raw="4–8 单位茎/叶", seed="1 粒或 1 段种茎", processed="2–4 份纤维",
        by="1–2 麻屑/叶渣 → 纸/堆肥/燃料",
        note="沤麻/打麻有重量损失；纤维产量按出麻率"),
    "fruit-preserve": dict(
        raw="4–8 个果", seed="1–2 粒", processed="1–3 份酱/干/粉/容器/纤维",
        by="1–2 果肉/瓜瓤/种子 → 饲料/油/堆肥",
        note="果类按可食率；瓜籽、络、容器是额外副产"),
    "herb-dry": dict(
        raw="4–6 单位叶/花", seed="1 粒", processed="1–2 份干香草/粉",
        by="1 茎叶渣 → 堆肥",
        note="干燥失水大；鲜用与干用分开计"),
    "special": dict(
        raw="按物种", seed="按物种", processed="按物种", by="按物种",
        note="不得套用大宗族链，必须逐物种"),
    "water-grain": dict(
        raw="4–8 单位水生器官", seed="1–2 粒/种茎", processed="1–2 份米/粉/菜",
        by="1–2 叶渣/根茎 → 堆肥/饲料",
        note="水生作物先排水/采割；稻类脱粒、莲类取藕/莲子"),
    "berry-runner": dict(
        raw="4–8 个浆果", seed="匍匐茎苗 1–2 株", processed="1–2 份果酱/果干",
        by="1 果渣 → 堆肥",
        note="匍匐茎繁殖优先；种子繁殖只作辅助"),
    "leaf-forage": dict(
        raw="6–10 单位草/种子", seed="1–2 粒", processed="2–4 份干草/饲料",
        by="1–2 秸秆 → 堆肥/燃料",
        note="饲草以干草计，不以鲜重计"),
    "legume-oil": dict(
        raw="6–10 豆/油籽", seed="1–2 粒", processed="2–4 份干豆/豆制品/油",
        by="1–2 荚/粕 → 饲料",
        note="大豆按豆制品与油两条出口；花生按油/坚果"),
    "fiber-water": dict(
        raw="4–8 单位茎/叶", seed="1 段根茎", processed="1–3 份纤维/纸",
        by="1–2 叶渣/根茎 → 堆肥",
        note="水生纤维先采割/沤制，再打麻"),
}

flow_override = {
    "rice": "grain-rice", "wheat": "grain-malt", "barley": "grain-malt",
    "rye": "grain-malt", "oat": "grain-malt", "maize": "grain-mill",
    "cassava": "root-detox", "taro": "root-detox", "yam": "root-detox",
    "ginger": "root-spice", "turmeric": "root-spice",
    "soybean": "legume-oil", "peanut": "oil-press", "canola": "oil-press",
    "flax": "fiber-oil", "hemp": "fiber-oil", "cotton": "fiber-oil",
    "ramie": "fiber-bast", "sisal": "fiber-bast", "jute": "fiber-bast",
    "agave": "fiber-syrup",
    "loofah": "fruit-fiber", "bottle_gourd": "fruit-container",
    "winter_melon": "fruit-seed", "cantaloupe": "fruit-seed",
    "melon": "fruit-seed", "pumpkin": "fruit-seed", "squash": "fruit-seed",
    "chili": "fruit-spice", "tomato": "fruit-paste",
    "hops": "special-brew", "bambara_nut": "legume-dry",
    "fenugreek": "special-triple", "jobs_tears": "grain-mill",
    "sugarcane": "sugar", "alfalfa": "leaf-forage",
    "papyrus": "fiber-water", "cabbage": "leaf-preserve",
    "spinach": "leaf-preserve", "lettuce": "leaf-preserve",
    "red_bell_pepper": "fruit-spice", "yellow_bell_pepper": "fruit-spice",
    "green_bean": "legume-dry", "lentil": "legume-dry",
    "onion": "root-spice", "garlic": "root-spice", "shallot": "root-spice",
    "beet": "root-starch",
}

extra_profile = {
    "grain-rice": dict(raw="6–10 穗", seed="1–2 粒", processed="3–5 份米/米粉", by="2–4 秸秆/糠", note="先脱粒，再砻谷/碾米；不得直接出米粉"),
    "grain-malt": dict(raw="6–10 穗", seed="1–2 粒", processed="3–5 份面粉/麦芽", by="2–4 秸秆/糠", note="麦芽需浸泡→发芽→烘干；面粉需磨粉"),
    "root-detox": dict(raw="4–8 块根", seed="1 段种茎/种芋", processed="1–2 份淀粉/粉", by="1–2 皮渣/茎叶", note="cassava/taro/yam 必须先去毒（浸泡/煮熟/发酵）"),
    "root-spice": dict(raw="4–6 根茎", seed="1 段种姜/种芋", processed="1–2 份干粉/香料", by="1 茎叶渣", note="生姜/姜黄走香料链，不走淀粉主链"),
    "fiber-oil": dict(raw="4–8 茎/籽", seed="1–2 粒", processed="2–3 份纤维 + 1–2 份油", by="1–2 麻屑/油饼", note="一作物双主产：纤维 + 油料"),
    "fiber-syrup": dict(raw="4–8 叶/心", seed="1 吸芽", processed="2–4 份纤维 + 1–2 糖浆", by="1–2 叶渣/糖蜜", note="先割叶取纤维；另烤心压汁熬糖"),
    "fruit-fiber": dict(raw="4–8 果", seed="1–2 粒", processed="嫩果 2–4 份 + 老果纤维 1–2 份", by="种子/果渣", note="嫩果与老果分两次收；纤维是第二主产"),
    "fruit-container": dict(raw="4–8 果", seed="1–2 粒", processed="嫩果 2–4 份 + 老果容器 1–2 个", by="种子/壳", note="老果掏空晾干做容器；不能全部当食物"),
    "fruit-seed": dict(raw="4–8 果", seed="1–2 粒", processed="2–4 份果肉/酱 + 1–2 份瓜籽", by="瓜瓤/皮 → 饲料/堆肥", note="瓜籽是副产油料；按取籽率折算"),
    "fruit-spice": dict(raw="4–8 果", seed="1–2 粒", processed="1–2 份干辣椒/辣椒粉", by="辣椒秆/种子 → 堆肥", note="鲜食与干制分开；干制后按失水率折算"),
    "fruit-paste": dict(raw="4–8 果", seed="1–2 粒", processed="1–2 份番茄酱/干番茄", by="果皮/籽 → 堆肥/饲料", note="熬酱需去水；干制按失水率"),
    "special-brew": dict(raw="4–8 花", seed="1 段根茎", processed="1–2 份干啤酒花", by="藤蔓 → 堆肥/纤维", note="花干燥后用于啤酒；藤蔓另有纤维出口"),
    "special-triple": dict(raw="4–6 株", seed="1–2 粒", processed="种子香料/叶菜/芽菜三选", by="茎叶/种皮", note="一物三用；必须分别建三条出口"),
    "sugar": dict(raw="6–10 茎", seed="1 段蔗种", processed="2–4 份糖/糖蜜", by="蔗渣 → 燃料/纸", note="压榨→熬糖；蔗渣与糖蜜都要有出口"),
    "fiber-water": dict(raw="4–8 茎", seed="1 段根茎", processed="1–3 份纤维/纸", by="叶渣/根茎", note="采割→沤制→打麻/造纸"),
}

for r in rows:
    if r["source"] == "TFC":
        if r["crop"] in ("red_bell_pepper", "yellow_bell_pepper"):
            r["baseline"] = "4–5 ×2（TFC 原值）"
        elif r["crop"] in ("melon", "pumpkin"):
            r["baseline"] = "果实方块 1–2 个（非 6–10 池）"
        else:
            r["baseline"] = "0–(6–10)，种子 1（部分 1–2）"
    else:
        r["baseline"] = "0–(6–10)，种子 1（个别 1–2）"
    flow = flow_override.get(r["crop"], profile_for_group[r["group"]])
    r["flow"] = flow
    p = profile.get(flow, extra_profile.get(flow, profile["special"]))
    # explicit overrides beat profile defaults
    r["raw"] = p["raw"]; r["seed"] = p["seed"]; r["processed"] = p["processed"]
    r["by_yield"] = p["by"]; r["yield_note"] = p["note"]

# Crop-specific yield adjustments for known high/low density.
yield_tweaks = {
    "cabbage": ("8–12 叶球", "1", "2–4 份酸菜/干菜", "3–4 外叶"),
    "napa_cabbage": ("8–12 叶球", "1", "2–4 份酸菜/干菜", "3–4 外叶"),
    "kale": ("8–12 叶", "1", "2–3 份干菜/腌菜", "2–3 外叶"),
    "spinach": ("8–12 叶", "1", "2–4 份干菜/腌菜", "2–4 外叶"),
    "potato": ("4–8 块茎", "1 个种薯", "2–4 份淀粉/薯制品", "1–2 皮渣"),
    "cassava": ("4–8 块根", "1 段种茎", "1–3 份淀粉", "1–2 皮渣/叶"),
    "wheat": ("6–10 穗", "1–2 粒", "3–5 份面粉", "2–4 秸秆/糠"),
    "barley": ("6–10 穗", "1–2 粒", "3–5 份麦芽/面粉", "2–4 秸秆/糠"),
    "rice": ("6–10 穗", "1–2 粒", "3–5 份米", "2–4 秸秆/糠"),
    "soybean": ("6–10 荚", "1–2 粒", "2–4 份豆制品/油", "1–2 豆荚/粕"),
    "peanut": ("4–8 荚", "1–2 粒", "1–2 份油 + 2–3 份坚果", "1–2 花生饼"),
    "canola": ("4–8 荚", "1–2 粒", "1–2 份油", "1–2 菜籽饼"),
    "flax": ("4–8 茎", "1–2 粒", "1–2 份油 + 2–3 份纤维", "1–2 麻屑/油饼"),
    "cotton": ("4–8 株", "1–2 粒", "2–3 份纤维 + 1–2 份棉籽油", "1–2 棉籽饼"),
    "sugarcane": ("6–10 茎", "1 段蔗种", "2–4 份糖/糖蜜", "2–4 蔗渣"),
    "chili": ("4–8 果", "1–2 粒", "1–2 份干辣椒/辣椒粉", "1–2 辣椒秆/种子"),
    "tomato": ("4–8 果", "1–2 粒", "1–2 份番茄酱/干番茄", "1–2 果皮/籽"),
    "melon": ("4–8 果", "1–2 粒", "2–4 份果肉/酱 + 1–2 份瓜籽", "1–2 瓜瓤"),
    "pumpkin": ("4–8 果", "1–2 粒", "2–4 份果肉 + 1–2 份瓜籽", "1–2 瓜瓤"),
    "loofah": ("4–8 果", "1–2 粒", "嫩果 2–4 份 + 老果纤维 1–2 份", "1–2 种子/果渣"),
    "bottle_gourd": ("4–8 果", "1–2 粒", "嫩果 2–4 份 + 老果容器 1–2 个", "1–2 种子/壳"),
    "hops": ("4–8 花", "1 段根茎", "1–2 份干啤酒花", "1 藤蔓/叶"),
    "agave": ("4–8 叶/心", "1 吸芽", "2–4 份纤维 + 1–2 糖浆", "1–2 叶渣/糖蜜"),
    "fenugreek": ("4–6 株", "1–2 粒", "1–2 份香料 + 2–4 份叶菜/芽菜", "1–2 茎叶/种皮"),
    "onion": ("6–10（TFC 原值）", "1 粒种子/1 个种球", "1–2 份干洋葱/洋葱粉", "1–2 皮/叶"),
    "garlic": ("6–10（TFC 原值）", "1 个蒜瓣", "1–2 份干蒜/蒜粉", "1 皮/叶"),
    "shallot": ("4–8 个鳞茎", "1 个种球", "1–2 份干葱/葱粉", "1 皮/叶"),
}
for r in rows:
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

lines_out = []
lines_out.append("# 290 作物流程定制与产量平衡计划（对 289 的修订）\n")
lines_out.append("> 日期：2026-10-28\n")
lines_out.append("> 性质：**计划**，不是实现。\n")
lines_out.append("> 针对 289 的不足：289 的流程按族套模板；本计划为每一种作物指定**流程 profile + 产量目标 + 平衡规则**。\n")
lines_out.append("> 依据：`117 §6.8`、`126 §12.11/§12.12`、`289`。\n")
lines_out.append("\n## 1. 产量基线（实测）\n")
lines_out.append("当前 A 与 TFC 的普通作物掉落表几乎完全一致：\n")
lines_out.append("- 主产品：`tfc:crop_yield_uniform`，`min=0`，`max=uniform(6,10)`；")
lines_out.append("- 种子：通常 1 个，部分作物 1–2 个；")
lines_out.append("- 红/黄甜椒：两组 `min=1`、`max=uniform(4,5)`；")
lines_out.append("- melon/pumpkin：不走作物 age 掉落，走果实方块掉落；")
lines_out.append("- 当前所有普通作物**没有按物种区分产率**，这正是需要平衡的地方。\n")
lines_out.append("因此本计划原则：\n")
lines_out.append("1. **不先大改原始掉落**（尤其 TFC，避免存档/兼容冲击）；")
lines_out.append("2. 先用**加工转化率、副产物比例、种子返还**做平衡；")
lines_out.append("3. 原始掉落确实需要改时，只改 B 自有 A 作物，并保留旧值作为回滚基线。\n")
lines_out.append("\n## 2. 平衡公式与验收带\n")
lines_out.append("对每次收获定义：\n")
lines_out.append("```text\n"
                 "raw        = 主产品原始产量（单位）\n"
                 "seedBack   = 返还种子/种薯数\n"
                 "processed  = 初加工后主产品单位\n"
                 "byproduct  = 副产品单位\n"
                 "\n"
                 "约束 1：seedBack >= 1（种子作物；无性繁殖按 1 个种薯/段计）\n"
                 "约束 2：processed <= raw（主产品加工不凭空增加；副产品来自秸秆/皮/荚等非主产部位）\n"
                 "约束 3：processed >= 1（每个作物必须有可用的初加工主产物）\n"
                 "约束 4：byproduct >= 1（每个作物必须有副产品出口）\n"
                 "```\n")
lines_out.append("平衡原则：\n")
lines_out.append("- **高营养密度/高价值**（油料、豆类、香料）→ processed 单位低、副产物价值高；\n")
lines_out.append("- **高水量/低密度**（叶菜、根菜）→ 鲜重 raw 高、干重 processed 低；\n")
lines_out.append("- **纤维/油料双主产** → 纤维与油各自有独立产量，不可互相替代；\n")
lines_out.append("- **TFC 原版不降低 raw 产量**；B 只调整加工转化率与副产物；\n")
lines_out.append("- 所有产量目标以 20 次收获的均值/区间验收，不用单次极值。\n")

lines_out.append("\n## 3. 流程 profile 总表\n")
lines_out.append("| profile | 适用作物 | raw 目标 | seedBack | processed | 副产品 | 平衡要点 |\n|---|---|---|---|---|---|---|\n")
for pname in ["leaf-preserve", "root-starch", "grain-mill", "grain-rice", "grain-malt",
              "legume-dry", "oil-press", "fiber-bast", "fiber-oil", "fiber-syrup",
              "fruit-preserve", "fruit-fiber", "fruit-container", "fruit-seed",
              "fruit-spice", "fruit-paste", "herb-dry", "water-grain", "berry-runner",
              "leaf-forage", "legume-oil", "fiber-water", "special-brew", "special-triple",
              "sugar", "special"]:
    p = profile.get(pname, extra_profile.get(pname, profile["special"]))
    crops = [r["crop"] for r in rows if r["flow"] == pname]
    if crops:
        lines_out.append(f"| `{pname}` | {' · '.join(crops)} | {p['raw']} | {p['seed']} | {p['processed']} | {p['by']} | {p['note']} |\n")

lines_out.append("\n## 4. 逐作物流程与产量表（116 条）\n")
lines_out.append("> TFC 行 raw 保留 TFC 原值；A 行按 profile 目标调整，原始掉落改动需单独评审。\n")
lines_out.append("| # | 作物 | 来源/组 | 流程 profile | 现有产率基线 | raw 目标 | seedBack | processed 目标 | 副产品目标 | 定制关键步骤 |\n")
lines_out.append("|---:|---|---|---|---|---|---|---|---|---|\n")
for i, r in enumerate(rows, 1):
    key = r["process"]
    # crop-specific key step if the crop has a known special processing
    if r["crop"] in ("cassava", "taro", "yam"):
        key = "先去毒（浸泡/煮熟/发酵）→" + key
    elif r["crop"] in ("flax", "hemp", "cotton"):
        key = "纤维与油料双线：" + key
    elif r["crop"] in ("loofah", "bottle_gourd"):
        key = "嫩果/老果分收：" + key
    elif r["crop"] in ("ginger", "turmeric"):
        key = "先干燥/蒸煮再磨粉：" + key
    elif r["crop"] in ("chili", "tomato"):
        key = "鲜食/干制/酱三条出口：" + key
    elif r["crop"] in ("melon", "pumpkin", "squash", "cantaloupe", "winter_melon"):
        key = "果肉与瓜籽分开：" + key
    elif r["crop"] in ("hops",):
        key = "先干燥后酿酒：" + key
    elif r["crop"] in ("sugarcane",):
        key = "压榨→熬糖，蔗渣另出口：" + key
    elif r["crop"] in ("agave",):
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
    lines_out.append(f"| {i} | `{r['crop']}` | {r['source']}·{r['group']} | `{r['flow']}` | {r['baseline']} | {r['raw']} | {r['seed']} | {r['processed']} | {r['by_yield']} | {key} |\n")

lines_out.append("\n## 5. 实施批次\n")
lines_out.append("| 批次 | 内容 | 产出 |\n|---|---|---|\n")
lines_out.append("| P0 | 116 条 profile / 产量带落表；选 1 个代表作物做全链样板 | 数据表 |\n")
lines_out.append("| P1 | 种子返还、育苗、移栽、缓苗；按 profile 验证 seedBack | 可种植闭环 |\n")
lines_out.append("| P2 | 每个 profile 的初加工设备与配方；按 raw/processed/byproduct 平衡 | 每条 profile 至少 1 条完整链 |\n")
lines_out.append("| P3 | 116 条逐作物覆盖与产量实测；调整转化率 | 全作物矩阵 |\n")
lines_out.append("| P4 | TFC 29 资源层接入；不降低 raw 产量 | 视觉+行为兼容 |\n")

lines_out.append("\n## 6. 每作物验收\n")
lines_out.append("每个作物必须通过：\n")
lines_out.append("1. `raw` 落在该行目标带；\n")
lines_out.append("2. `seedBack >= 1`（或等价的种薯/种茎）；\n")
lines_out.append("3. `processed >= 1` 且 `processed + byproduct <= raw`；\n")
lines_out.append("4. 副产品有至少一个真实出口；\n")
lines_out.append("5. 20 次收获均值/区间在带内；\n")
lines_out.append("6. 与相邻同类作物相比，单位营养/价值不出现数量级失衡。\n")

lines_out.append("\n## 7. 未决问题\n")
lines_out.append("1. 是否允许修改 A 的原始掉落表；TFC 29 的 raw 掉落建议不动。\n")
lines_out.append("2. 叶菜/根菜的 raw 目标带是否按现实鲜重比例，还是按 TFC 现有 6–10 统一值。\n")
lines_out.append("3. 油料/纤维双主产的产率如何分账（纤维与油是否共用同一 raw）。\n")
lines_out.append("4. 种子返还：种子 1 个是否够维持扩张，还是需要 1–2 个保底。\n")
lines_out.append("5. TFC 29 资源覆盖与 B 生产/培育链的行为层如何合并。\n")

out.write_text("".join(lines_out), encoding="utf-8")
print("wrote", out, "rows", len(rows), "bytes", out.stat().st_size)
