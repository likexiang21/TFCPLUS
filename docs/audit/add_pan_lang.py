from pathlib import Path
import json

lang = Path("mod_rebuild/tfcagricultureplus/src/main/resources/assets/tfcagricultureplus/lang")
variants = [
    "wood", "ceramic_white", "ceramic_orange", "ceramic_magenta", "ceramic_light_blue",
    "ceramic_yellow", "ceramic_lime", "ceramic_pink", "ceramic_gray", "ceramic_light_gray",
    "ceramic_cyan", "ceramic_purple", "ceramic_blue", "ceramic_brown", "ceramic_green",
    "ceramic_red", "ceramic_black",
]
plate_en = {"wood": "Wooden Plate", "ceramic_white": "White Ceramic Plate", "ceramic_orange": "Orange Ceramic Plate",
            "ceramic_magenta": "Magenta Ceramic Plate", "ceramic_light_blue": "Light Blue Ceramic Plate",
            "ceramic_yellow": "Yellow Ceramic Plate", "ceramic_lime": "Lime Ceramic Plate",
            "ceramic_pink": "Pink Ceramic Plate", "ceramic_gray": "Gray Ceramic Plate",
            "ceramic_light_gray": "Light Gray Ceramic Plate", "ceramic_cyan": "Cyan Ceramic Plate",
            "ceramic_purple": "Purple Ceramic Plate", "ceramic_blue": "Blue Ceramic Plate",
            "ceramic_brown": "Brown Ceramic Plate", "ceramic_green": "Green Ceramic Plate",
            "ceramic_red": "Red Ceramic Plate", "ceramic_black": "Black Ceramic Plate"}
plate_zh = {"wood": "木盘", "ceramic_white": "白色陶盘", "ceramic_orange": "橙色陶盘",
            "ceramic_magenta": "品红色陶盘", "ceramic_light_blue": "淡蓝色陶盘",
            "ceramic_yellow": "黄色陶盘", "ceramic_lime": "黄绿色陶盘",
            "ceramic_pink": "粉红色陶盘", "ceramic_gray": "灰色陶盘",
            "ceramic_light_gray": "淡灰色陶盘", "ceramic_cyan": "青色陶盘",
            "ceramic_purple": "紫色陶盘", "ceramic_blue": "蓝色陶盘",
            "ceramic_brown": "棕色陶盘", "ceramic_green": "绿色陶盘",
            "ceramic_red": "红色陶盘", "ceramic_black": "黑色陶盘"}

common_en = {
    "item.tfcagricultureplus.bowl.wood": "Wooden Bowl",
    "item.tfcagricultureplus.bowl.ceramic": "Ceramic Bowl",
    "item.tfcagricultureplus.spatula.copper": "Copper Spatula",
    "item.tfcagricultureplus.spatula.bismuth_bronze": "Bismuth Bronze Spatula",
    "item.tfcagricultureplus.spatula.bronze": "Bronze Spatula",
    "item.tfcagricultureplus.spatula.wrought_iron": "Wrought Iron Spatula",
    "item.tfcagricultureplus.spatula.steel": "Steel Spatula",
    "item.tfcagricultureplus.spatula.black_steel": "Black Steel Spatula",
    "item.tfcagricultureplus.pan_dish.meat": "Meat Stir-fry",
    "item.tfcagricultureplus.pan_dish.fish": "Fish Stir-fry",
    "item.tfcagricultureplus.pan_dish.vegetable": "Vegetable Stir-fry",
    "item.tfcagricultureplus.pan_dish.grain": "Grain Stir-fry",
    "item.tfcagricultureplus.pan_dish.fruit": "Fruit Stir-fry",
    "item.tfcagricultureplus.pan_dish.dairy": "Dairy Stir-fry",
    "item.tfcagricultureplus.pan_dish.mixed": "Mixed Stir-fry",
    "item.tfcagricultureplus.pan_quality.poor": "Poor",
    "item.tfcagricultureplus.pan_quality.plain": "Plain",
    "item.tfcagricultureplus.pan_quality.good": "Good",
    "item.tfcagricultureplus.pan_quality.perfect": "Perfect",
    "tooltip.tfcagricultureplus.dish.servings": "Servings: %s",
    "tooltip.tfcagricultureplus.dish.score": "Quality score: %s",
    "tooltip.tfcagricultureplus.dish.more": "and %s more ingredients",
    "message.tfcagricultureplus.pan.no_heat": "The pan needs a TFC heat source below",
    "message.tfcagricultureplus.pan.no_oil": "Add plant oil before cooking",
    "message.tfcagricultureplus.pan.empty": "The pan is empty",
    "message.tfcagricultureplus.pan.contents": "Ingredients: %s, oil: %s mB",
    "message.tfcagricultureplus.pan.full": "The pan is full",
    "message.tfcagricultureplus.pan.not_ready": "The dish is not ready yet",
    "message.tfcagricultureplus.pan.not_ingredient": "That item is not a food ingredient",
}
common_zh = {
    "item.tfcagricultureplus.bowl.wood": "木碗",
    "item.tfcagricultureplus.bowl.ceramic": "陶碗",
    "item.tfcagricultureplus.spatula.copper": "铜锅铲",
    "item.tfcagricultureplus.spatula.bismuth_bronze": "铋青铜锅铲",
    "item.tfcagricultureplus.spatula.bronze": "青铜锅铲",
    "item.tfcagricultureplus.spatula.wrought_iron": "锻铁锅铲",
    "item.tfcagricultureplus.spatula.steel": "钢锅铲",
    "item.tfcagricultureplus.spatula.black_steel": "黑钢锅铲",
    "item.tfcagricultureplus.pan_dish.meat": "炒肉",
    "item.tfcagricultureplus.pan_dish.fish": "炒鱼",
    "item.tfcagricultureplus.pan_dish.vegetable": "炒蔬菜",
    "item.tfcagricultureplus.pan_dish.grain": "炒谷物",
    "item.tfcagricultureplus.pan_dish.fruit": "炒水果",
    "item.tfcagricultureplus.pan_dish.dairy": "炒奶制品",
    "item.tfcagricultureplus.pan_dish.mixed": "什锦小炒",
    "item.tfcagricultureplus.pan_quality.poor": "劣质",
    "item.tfcagricultureplus.pan_quality.plain": "普通",
    "item.tfcagricultureplus.pan_quality.good": "良好",
    "item.tfcagricultureplus.pan_quality.perfect": "完美",
    "tooltip.tfcagricultureplus.dish.servings": "份数：%s",
    "tooltip.tfcagricultureplus.dish.score": "品质评分：%s",
    "tooltip.tfcagricultureplus.dish.more": "另有 %s 种原料",
    "message.tfcagricultureplus.pan.no_heat": "锅下需要有 TFC 热源",
    "message.tfcagricultureplus.pan.no_oil": "烹饪前需要加入植物油",
    "message.tfcagricultureplus.pan.empty": "锅里没有食材",
    "message.tfcagricultureplus.pan.contents": "原料：%s，油：%s mB",
    "message.tfcagricultureplus.pan.full": "锅已装满",
    "message.tfcagricultureplus.pan.not_ready": "菜品还未完成",
    "message.tfcagricultureplus.pan.not_ingredient": "该物品不是可用食材",
}

for lang_name, common, plates in (("en_us.json", common_en, plate_en), ("zh_cn.json", common_zh, plate_zh)):
    path = lang / lang_name
    data = json.loads(path.read_text(encoding="utf-8-sig"))
    for vid in variants:
        data[f"item.tfcagricultureplus.plate.{vid}"] = plates[vid]
    data.update(common)
    # Preserve the project's pretty per-line language layout.
    lines = [f'  {json.dumps(k, ensure_ascii=False)}: {json.dumps(v, ensure_ascii=False)}' for k, v in data.items()]
    path.write_text("{\n" + ",\n".join(lines) + "\n}\n", encoding="utf-8")
    print(lang_name, len(data))
