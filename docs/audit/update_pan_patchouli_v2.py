import json
from pathlib import Path

base = Path("mod_rebuild/tfcagricultureplus/src/main/resources/assets/tfc/patchouli_books/field_guide")
texts = {
    "en_us": {
        "title": "Pan cooking",
        "text": "The pan must sit above a lit TFC heat source. Add plant oil first (TFC/Firmalife oil bucket or bottle), then add up to eight food ingredients. Stir with a metal spatula; ingredients cook over time and burn if left unstirred. Take the finished dish with a plate. The number of servings equals the number of ingredients. Right-click a filled plate to eat one serving; sneak + right-click to place it. Breaking a placed dish returns the plate with its food data. A wooden or ceramic bowl can take one serving from a placed dish.",
    },
    "zh_cn": {
        "title": "炒锅料理",
        "text": "炒锅必须放在点燃的 TFC 热源上方。先加入植物油（TFC/Firmalife 油桶或油瓶），再逐份加入最多 8 种食材。用金属锅铲翻炒；食材会随时间烹饪，长时间不翻会焦。用盘子取出成品。份数等于加入的食材数量。右键装满的盘子食用一份；潜行+右键放置。打掉摆出的菜品会返还保留食物数据的盘子。木碗或陶碗可以从摆出的菜品中取一份。",
    },
}
for lang, text in texts.items():
    path = base / lang / "entries/agriculture_plus_kitchen/intro.json"
    data = json.loads(path.read_text(encoding="utf-8-sig"))
    for page in data["pages"]:
        if page.get("title") in ("Pan cooking", "炒锅料理"):
            page["title"] = text["title"]
            page["text"] = text["text"]
            break
    else:
        data["pages"].insert(1, {"type": "patchouli:text", "title": text["title"], "text": text["text"]})
    path.write_text(json.dumps(data, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    print(lang, "pages", len(data["pages"]))
