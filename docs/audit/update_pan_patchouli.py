import json
from pathlib import Path

base = Path("mod_rebuild/tfcagricultureplus/src/main/resources/assets/tfc/patchouli_books/field_guide")
updates = {
    "en_us": {
        "page0": "Kitchen furniture and the pan use TFC inventory block entities. The mixing bowl is provided by Firmalife and remains the entry point for fluids, flour, eggs and sweeteners.",
        "pan_title": "Pan cooking",
        "pan_text": "The pan has two inputs: one food and one project ground spice. Right-click to insert the food, then the spice; right-click empty-handed to stir. After the required stirs and cooking time, right-click empty-handed to take the finished dish. Current recipes: vegetable/grain/fruit soup + spice -> pan-seasoned vegetables; eight raw meats + spice -> their cooked meat; four raw fish + spice -> their cooked fish; five raw vegetables + spice -> pan-seasoned vegetables.",
        "page4": "Use a knife for cupcakes, bagels, buns and noodles. Fifteen unbaked foods count continuous time above 400 C in a Firmalife oven; cooling below the threshold resets progress. Use one butter block on a baked cake base for a cream cake, or a Firmalife chocolate blend for a chocolate cake. The old dough forming table, melting pot, generic dough and butter slice have been removed from the current version.",
    },
    "zh_cn": {
        "page0": "厨房家具和炒锅使用 TFC 容器。搅拌碗由 Firmalife 提供，仍是液体、面粉、鸡蛋和甜味剂的入口。",
        "pan_title": "炒锅料理",
        "pan_text": "炒锅有两个输入：一份食物和一份本模组的研磨香料。右键放入食物，再右键放入香料；空手右键翻炒，达到配方要求的次数并等待烹饪时间后，空手右键取出成品。当前配方：蔬菜汤/谷物汤/水果汤加香料 → 调味蔬菜；8 种生肉加香料 → 对应熟肉；4 种生鱼加香料 → 对应熟鱼；5 种生蔬菜加香料 → 调味蔬菜。",
        "page4": "使用小刀制作纸杯蛋糕、贝果、小圆面包和面条。15 种未烘焙食物在 Firmalife 烤炉中累计 400°C 以上的时间；温度下降会重置进度。用一份黄油块涂抹烤好的蛋糕底可制作奶油蛋糕，或用 Firmalife 巧克力混合物制作巧克力蛋糕。旧面团成型台、融化锅、通用面团和旧黄油片已从当前版本删除。",
    },
}
for lang, text in updates.items():
    path = base / lang / "entries/agriculture_plus_kitchen/intro.json"
    data = json.loads(path.read_text(encoding="utf-8-sig"))
    pages = data["pages"]
    pages[0]["text"] = text["page0"]
    pages[4]["text"] = text["page4"]
    if not any(page.get("title") == text["pan_title"] for page in pages):
        pages.insert(1, {
            "type": "patchouli:text",
            "title": text["pan_title"],
            "text": text["pan_text"],
        })
    path.write_text(json.dumps(data, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    print(lang, "pages", len(data["pages"]))
