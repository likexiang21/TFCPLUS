from pathlib import Path
import json

DOC = Path("mod_rebuild/docs/289-crop-master-plan-20261028.md")
manifest = json.loads(Path("mod_rebuild/tfcfarmingplus/tools/contracts/crops-manifest.json").read_text(encoding="utf-8"))["crops"]
a_names = [x["name"] for x in manifest]
a_flags = {x["name"]: x for x in manifest}

a_groups = {
    "叶菜/茎菜": ["spinach", "lettuce", "celery", "kale", "napa_cabbage", "mustard_greens", "broccoli",
                 "cauliflower", "brussels_sprouts", "swiss_chard", "celtuce", "garland_chrysanthemum",
                 "perilla", "arugula", "asparagus", "rhubarb", "artichoke", "cardoon", "purslane",
                 "water_spinach", "malabar_spinach"],
    "根/块茎/鳞茎": ["turnip", "parsnip", "sunchoke", "shallot", "celeriac", "salsify", "ginger",
                    "turmeric", "yacon", "chicory_root", "taro", "water_chestnut", "water_caltrop",
                    "lotus", "arrowhead", "gorgon_nut", "yam"],
    "谷物/禾本": ["millet", "foxtail_millet", "buckwheat", "fonio", "spelt", "emmer", "einkorn",
                 "pearl_millet", "amaranth", "quinoa", "finger_millet", "sorghum"],
    "豆类": ["chickpea", "faba_bean", "lupin", "adzuki", "pea", "cowpea", "common_bean",
             "winged_bean", "pigeon_pea"],
    "油料": ["flax", "sesame", "safflower", "sunflower"],
    "纤维": ["hemp", "ramie", "cotton", "sisal"],
    "茄果/瓜类": ["chili", "eggplant", "okra", "winter_melon", "loofah", "bitter_melon",
                 "snake_gourd", "chayote", "bottle_gourd", "cantaloupe"],
    "香草/香料": ["chive"],
    "特用": ["agave", "bambara_nut", "fenugreek", "hops", "jobs_tears"],
    "水生/其他": ["wild_rice_stem", "water_dropwort", "water_shield"],
    "浆果特例": ["strawberry"],
}
a_group_of = {n: g for g, names in a_groups.items() for n in names}
assert len(a_names) == len(a_group_of), (len(a_names), len(a_group_of), set(a_names) ^ set(a_group_of))

tfc_names = ["alfalfa", "barley", "beet", "cabbage", "canola", "carrot", "cassava", "garlic",
             "green_bean", "jute", "lentil", "maize", "melon", "oat", "onion", "papyrus",
             "peanut", "potato", "pumpkin", "radish", "red_bell_pepper", "rice", "rye",
             "soybean", "squash", "sugarcane", "tomato", "wheat", "yellow_bell_pepper"]
tfc_groups = {
    "谷物/禾本": ["barley", "oat", "rice", "rye", "wheat", "maize", "sugarcane"],
    "根/块茎/鳞茎": ["beet", "carrot", "potato", "radish", "onion", "garlic", "cassava"],
    "豆类/油料": ["soybean", "peanut", "canola", "green_bean", "lentil"],
    "叶菜/饲草": ["cabbage", "alfalfa"],
    "茄果/瓜类": ["tomato", "red_bell_pepper", "yellow_bell_pepper", "melon", "pumpkin", "squash"],
    "纤维": ["jute"],
    "水生/纤维": ["papyrus"],
}
tfc_group_of = {n: g for g, names in tfc_groups.items() for n in names}
assert len(tfc_names) == len(tfc_group_of), (len(tfc_names), len(tfc_group_of), set(tfc_names) ^ set(tfc_group_of))

# Per-group defaults: main, byproduct, propagation, nursery/seed treatment, primary processing, outlet, batch.
info = {
    "叶菜/茎菜": dict(
        main="食用叶/叶球/茎（`tfcfarmingplus:food/<id>`）；水生叶菜按 A 现有产物",
        by="种子 + 外叶/叶柄/修整料 → 堆肥、饲料；纤维类副产（cardoon/artichoke）",
        prop="种子直播/育苗移栽；artichoke/cardoon/rhubarb/asparagus 用分株/冠芽",
        nursery="种子：采种→晒干→筛选→浸种/催芽→育苗盘→移栽；分株：母株→分株→育苗→定植",
        process="清洗→切/撕→盐渍→乳酸发酵→晒干；叶球类可切丝盐渍",
        outlet="沙拉、汤、腌菜、干菜、堆肥/饲料",
        batch="P1"),
    "根/块茎/鳞茎": dict(
        main="食用根/块茎/鳞茎，或淀粉/粉（`tfcfarmingplus:food/<id>`）",
        by="茎叶/皮渣 → 饲料、堆肥；种薯/种球/种瓣留种",
        prop="种子（turnip/parsnip/celeriac/salsify/chicory/radish/carrot/beet）或块茎/鳞茎/根茎（其余）",
        nursery="种子：采种→晒干→筛选→浸种→直播；块茎/鳞茎：愈伤→分级→直播",
        process="清洗→去皮→切片→晒干/磨粉/沉淀淀粉；生姜/姜黄走香料链",
        outlet="主食、淀粉、腌菜、干片、饲料、堆肥",
        batch="P1"),
    "谷物/禾本": dict(
        main="谷物籽粒（`tfcfarmingplus:food/<id>`；TFC 用 `tfc:food/<id>`）",
        by="秸秆、糠/麸、种子 → 饲料、堆肥、燃料、留种",
        prop="种子",
        nursery="采种→晒干→筛选→浸种/催芽（可选）→直播",
        process="脱粒→扬场→磨粉；麦类可制麦芽；稻类可碾米",
        outlet="面粉/米饭/麦芽/酿酒/饲料/燃料",
        batch="P1"),
    "豆类": dict(
        main="干豆或鲜荚（`tfcfarmingplus:food/<id>`；TFC 用 `tfc:food/<id>`）",
        by="豆荚、秸秆、种子 → 饲料、堆肥、留种",
        prop="种子",
        nursery="采种→晒干→筛选→浸种→直播",
        process="干燥→脱荚→浸泡→磨浆/煮制/发酵",
        outlet="豆制品、豆粉、豆酱、饲料",
        batch="P1"),
    "油料": dict(
        main="油籽 → 食用油（`tfcfarmingplus:food/<id>` / 油料产物）",
        by="油饼/粕 → 饲料、肥料；部分纤维/秸秆",
        prop="种子",
        nursery="采种→晒干→筛选→直播",
        process="清理→炒/烘→磨→蒸→制饼→压榨→过滤",
        outlet="食用油、油饼饲料、调味油",
        batch="P1"),
    "纤维": dict(
        main="纤维（韧皮/棉/叶纤维）",
        by="种子/油、麻屑/麻秆 → 饲料、堆肥、造纸、燃料",
        prop="种子（hemp/ramie/cotton/sisal）或根茎/分株（ramie 可无性）",
        nursery="种子：采种→晒干→筛选→直播；无性：母株→扦插/分株→育苗→移栽",
        process="沤麻→打麻→梳麻→纺线→织布；棉：轧棉→梳棉→纺",
        outlet="布料、绳子、纸张、油料副产品",
        batch="P2"),
    "茄果/瓜类": dict(
        main="果实/蔬菜（`tfcfarmingplus:food/<id>`）",
        by="种子、果肉/瓜瓤 → 饲料/堆肥；loofah 纤维、bottle_gourd 容器、瓜籽油",
        prop="种子；多数育苗后移栽",
        nursery="采种→晒干→筛选→浸种/催芽→育苗盘→移栽",
        process="清洗→切片/取籽→晒干/磨粉/腌制/熬酱；loofah 取络、葫芦掏空",
        outlet="蔬菜、香料、酱、籽油、洗具、容器",
        batch="P1"),
    "香草/香料": dict(
        main="叶/花/种子（`tfcfarmingplus:food/<id>`）",
        by="种子、茎叶修整料 → 留种/堆肥",
        prop="种子或分株",
        nursery="采种→晒干→筛选→育苗/直播",
        process="采叶→干燥→研磨→过筛；鲜用",
        outlet="调料、香草粉、腌渍、茶饮",
        batch="P2"),
    "特用": dict(
        main="按物种：纤维/糖浆/豆/啤酒花/谷物",
        by="按物种：油饼/糖蜜/纤维渣/秸秆",
        prop="按物种：种子/块茎/根茎/分株",
        nursery="按物种各自处理；详见行内覆盖",
        process="按物种各自链；不能批量套同一配方",
        outlet="按物种各自出口",
        batch="P2/P3"),
    "水生/其他": dict(
        main="水生谷物/叶菜/纤维",
        by="种子/根茎/叶渣 → 留种、饲料、堆肥",
        prop="种子或根茎/分株",
        nursery="种子：采种→晒干→筛选→浅水直播；根茎：分株→定植",
        process="采割→脱粒/晒干/剥壳；纤维类沤制/打麻",
        outlet="谷物、蔬菜、纤维/纸",
        batch="P2"),
    "浆果特例": dict(
        main="浆果（`tfcfarmingplus:food/strawberry`）",
        by="匍匐茎苗/种子；果渣 → 堆肥",
        prop="匍匐茎分株为主，种子为辅",
        nursery="母株→匍匐茎苗→育苗→移栽",
        process="鲜食→果酱/果干/冰淇淋；不按灌木处理",
        outlet="鲜果、果酱、果干、甜点",
        batch="P1"),
    "叶菜/饲草": dict(
        main="叶菜/饲草（TFC 现有产物）",
        by="种子/秸秆 → 留种、饲料、堆肥",
        prop="种子",
        nursery="采种→晒干→筛选→直播",
        process="叶菜：清洗→切→盐渍/发酵/晒干；饲草：晒干→打捆",
        outlet="食物/饲料",
        batch="P1"),
    "豆类/油料": dict(
        main="豆/油籽（TFC 现有产物）",
        by="豆荚/秸秆/油饼 → 饲料、堆肥",
        prop="种子",
        nursery="采种→晒干→筛选→浸种→直播",
        process="干燥→脱荚/清理→浸泡/压榨/磨浆",
        outlet="豆制品/食用油/饲料",
        batch="P1"),
    "水生/纤维": dict(
        main="纤维/纸（TFC 现有产物）",
        by="根茎/叶渣 → 堆肥、饲料",
        prop="分株/根茎",
        nursery="母株→分株→浅水定植",
        process="采割→沤制→打麻→晾晒/造纸",
        outlet="纤维、纸、编织",
        batch="P2"),
}
# Fix a syntax typo-prone default: replace later.
info["浆果特例"]["process"] = "鲜食→果酱/果干/冰淇淋；不按灌木处理"

# Crop-specific overrides for main/byproduct/propagation/process/outlet (kept short).
over = {
    "asparagus": dict(prop="冠芽/分株", nursery="母株→冠芽→育苗→定植", process="采嫩茎→焯水/晒干/腌渍", outlet="蔬菜、干菜"),
    "artichoke": dict(prop="分株/冠芽", nursery="母株→分株→育苗→定植", process="采花苞→蒸煮/腌渍", outlet="蔬菜、腌菜"),
    "cardoon": dict(prop="分株/种子", nursery="种子育苗或分株→定植", process="采叶柄→去筋→焯水/腌渍；纤维副产", outlet="蔬菜、纤维"),
    "rhubarb": dict(prop="分株/冠芽", nursery="母株→分株→育苗→定植", process="采叶柄→去叶→糖渍/晒干", outlet="甜点、果酱"),
    "strawberry": dict(prop="匍匐茎分株为主，种子为辅", nursery="母株→匍匐茎苗→育苗→移栽", process="鲜食→果酱/果干/冰淇淋", outlet="鲜果、果酱、果干、甜点"),
    "ginger": dict(prop="根茎", nursery="种姜→催芽→切块→定植", process="清洗→去皮→切片→晒干→磨粉", outlet="香料、姜茶、腌姜"),
    "turmeric": dict(prop="根茎", nursery="种姜→催芽→切块→定植", process="清洗→煮/蒸→晒干→磨粉", outlet="香料、染料、咖喱"),
    "sunchoke": dict(prop="块茎", nursery="种薯→分级→直播", process="清洗→去皮→切片→煮/烤/晒干", outlet="蔬菜、饲料、菊粉"),
    "yacon": dict(prop="块茎/分株", nursery="种薯→育苗→定植", process="清洗→去皮→切片→晒干/榨汁", outlet="蔬菜、糖浆"),
    "taro": dict(prop="球茎/分株", nursery="种芋→催芽→定植", process="清洗→去皮→煮/蒸→制泥/晒干", outlet="主食、淀粉"),
    "water_chestnut": dict(prop="球茎", nursery="种球→浅水定植", process="采球→去皮→煮/磨粉", outlet="主食、淀粉"),
    "water_caltrop": dict(prop="种子/球茎", nursery="种球→浅水定植", process="采果→去壳→煮/磨粉", outlet="主食、淀粉"),
    "lotus": dict(prop="根茎（藕）", nursery="种藕→浅水定植", process="采藕→去节→切片→煮/磨粉；莲子另收", outlet="蔬菜、淀粉、莲子"),
    "arrowhead": dict(prop="球茎", nursery="种球→浅水定植", process="采球→去皮→煮/晒干", outlet="蔬菜、淀粉"),
    "gorgon_nut": dict(prop="种子", nursery="采种→浸种→浅水育苗→定植", process="采种→脱壳→煮/磨粉", outlet="粮食、淀粉"),
    "yam": dict(prop="块茎/零余子", nursery="种薯→催芽→定植", process="清洗→去皮→煮/蒸/磨粉", outlet="主食、淀粉"),
    "flax": dict(main="纤维 + 亚麻籽油", by="亚麻籽→油；麻屑→纸/填料", prop="种子", process="沤麻→打麻→梳麻→纺线；种子→压榨", outlet="布、绳、纸、亚麻油"),
    "hemp": dict(main="纤维 + 大麻籽油", by="麻屑/籽饼→饲料/建材/纸", prop="种子", process="沤麻→打麻→梳麻→纺线；种子压榨", outlet="布、绳、纸、油"),
    "cotton": dict(main="棉纤维 + 棉籽油", by="棉籽→油/饼；棉秆→燃料", prop="种子", process="轧棉→梳棉→纺线；棉籽压榨", outlet="布、油、饲料"),
    "sisal": dict(main="叶纤维", by="叶渣→堆肥/沼气", prop="吸芽/分株", process="割叶→刮肉→晒干→梳麻→纺绳", outlet="绳、网、垫"),
    "ramie": dict(main="韧皮纤维", by="麻屑→纸/堆肥；根茎可繁殖", prop="根茎/分株", process="剥麻→沤麻→打麻→梳麻→纺线", outlet="布、绳、纸"),
    "agave": dict(main="纤维 + 龙舌兰糖浆", by="叶渣→纤维/饲料；糖蜜", prop="吸芽/种子", process="割叶→刮纤维；烤心→压汁→熬糖浆", outlet="绳、布、糖浆"),
    "loofah": dict(main="嫩果食用 + 老果纤维", by="丝瓜络、种子", prop="种子", process="嫩果食用；老果泡水→去皮去籽→丝瓜络", outlet="蔬菜、洗具、过滤"),
    "bottle_gourd": dict(main="嫩果食用 + 老果容器", by="种子、葫芦壳", prop="种子", process="嫩果食用；老果掏空→晾干→容器", outlet="蔬菜、容器、水瓢"),
    "winter_melon": dict(main="果实；种子", by="瓜籽→炒制/榨油；瓜瓤→饲料", prop="种子", process="果实→切块/熬酱/糖渍；瓜籽→洗净晒干", outlet="蔬菜、瓜酱、籽油"),
    "cantaloupe": dict(main="果实；种子", by="瓜籽→炒制/榨油；瓜瓤→饲料", prop="种子", process="果实→鲜食/果酱；瓜籽→洗净晒干", outlet="水果、果酱、籽油"),
    "chili": dict(main="辣椒果实/辣椒粉", by="种子、辣椒秆→堆肥", prop="种子", nursery="采种→晒干→筛选→育苗→移栽", process="鲜食/晒干→磨粉；发酵辣酱", outlet="调料、辣酱"),
    "okra": dict(process="鲜食/晒干/腌渍", outlet="蔬菜、干菜、腌菜"),
    "bambara_nut": dict(main="豆类", by="豆荚/秸秆→饲料", prop="种子", process="干燥→脱荚→煮/磨粉", outlet="豆制品、豆粉"),
    "fenugreek": dict(main="种子香料 + 叶菜 + 芽菜", by="茎叶→饲料/堆肥", prop="种子", process="种子干燥→磨粉；叶鲜食/晒干；种子发芽", outlet="香料、蔬菜、芽菜"),
    "hops": dict(main="啤酒花", by="藤蔓→堆肥/纤维", prop="根茎/扦插", nursery="母株→根茎/扦插→搭架定植", process="采花→干燥→酿酒", outlet="啤酒"),
    "jobs_tears": dict(main="薏米", by="糠/秸秆→饲料", prop="种子", process="脱壳→碾米→煮/磨粉", outlet="粮食、药食"),
    "wild_rice_stem": dict(main="水生谷物", by="秸秆→饲料/编织", prop="种子/分株", process="采穗→脱粒→碾米", outlet="粮食"),
    "water_dropwort": dict(main="水生叶菜", by="茎叶渣→堆肥", prop="分株/扦插", process="采嫩茎叶→焯水/晒干", outlet="蔬菜"),
    "water_shield": dict(main="水生叶菜/根", by="叶渣→堆肥", prop="种子/分株", process="采叶/根→清洗→煮/晒干", outlet="蔬菜"),
    "water_spinach": dict(main="水生叶菜", by="茎叶渣→堆肥", prop="种子/扦插", process="采嫩茎叶→焯水/晒干", outlet="蔬菜"),
    "malabar_spinach": dict(prop="种子/扦插", process="采嫩茎叶→焯水/晒干", outlet="蔬菜"),
    "kale": dict(process="采叶→焯水/盐渍/晒干", outlet="蔬菜、干菜、腌菜"),
    "napa_cabbage": dict(process="切丝→盐渍→乳酸发酵→晒干", outlet="酸菜、泡菜、干菜"),
    "broccoli": dict(process="采花球→焯水/冷冻/晒干", outlet="蔬菜、干菜"),
    "cauliflower": dict(process="采花球→焯水/腌渍/晒干", outlet="蔬菜、腌菜"),
    "brussels_sprouts": dict(process="采芽球→焯水/烤/腌渍", outlet="蔬菜、腌菜"),
    "cabbage": dict(process="切丝→盐渍→乳酸发酵→晒干", outlet="酸菜、泡菜、干菜"),
    "alfalfa": dict(main="饲草/种子", by="干草→饲料", prop="种子", process="割草→晒干→打捆；种子清选", outlet="饲料、种子"),
    "sugarcane": dict(main="甘蔗/糖", by="蔗渣→燃料/纸；糖蜜→发酵", prop="蔗种/茎段", process="压榨→熬糖→糖蜜/朗姆", outlet="糖、糖蜜、酒"),
    "jute": dict(main="韧皮纤维", by="麻屑/种子→纸/饲料", prop="种子", process="沤麻→打麻→梳麻→纺线/织袋", outlet="麻袋、绳、纸"),
    "papyrus": dict(main="纤维/纸", by="根茎/叶渣→堆肥", prop="根茎/分株", process="割茎→剥皮→压片→晾干→纸", outlet="纸、编织"),
    "beet": dict(main="根/糖", by="叶/渣→饲料", process="清洗→切片→煮/榨糖/腌渍", outlet="糖、蔬菜、饲料"),
    "carrot": dict(process="清洗→去皮→切片→煮/晒干/腌渍", outlet="蔬菜、干菜"),
    "potato": dict(prop="种薯", nursery="种薯→催芽→切块→直播", process="清洗→去皮→煮/炸/淀粉", outlet="主食、淀粉"),
    "onion": dict(prop="种球/种子", nursery="种球→分级→定植；种子育苗", process="干燥→去皮→切片→晒干/腌渍", outlet="调料、腌菜"),
    "garlic": dict(prop="蒜瓣", nursery="蒜瓣→分级→定植", process="干燥→去皮→切片→晒干/腌渍", outlet="调料、腌菜"),
    "radish": dict(process="清洗→切片→腌渍/晒干", outlet="蔬菜、腌菜"),
    "cassava": dict(prop="茎段", nursery="种茎→切段→定植", process="去皮→磨浆→沉淀淀粉/发酵", outlet="淀粉、木薯粉"),
    "tomato": dict(process="鲜食→晒干/熬酱/罐装", outlet="蔬菜、番茄酱、干番茄"),
    "red_bell_pepper": dict(process="鲜食→晒干→磨粉/烤制", outlet="蔬菜、香料"),
    "yellow_bell_pepper": dict(process="鲜食→晒干→磨粉/烤制", outlet="蔬菜、香料"),
    "melon": dict(main="果实；种子", by="瓜籽→炒制/榨油", process="鲜食/果酱；瓜籽洗净晒干", outlet="水果、籽油"),
    "pumpkin": dict(main="果实；种子", by="瓜籽→炒制/榨油；瓜肉→饲料", process="果实→煮/烤/熬酱；瓜籽洗净晒干", outlet="蔬菜、籽油、饲料"),
    "squash": dict(main="果实；种子", by="瓜籽→炒制/榨油；瓜肉→饲料", process="果实→煮/烤/熬酱；瓜籽洗净晒干", outlet="蔬菜、籽油、饲料"),
    "green_bean": dict(main="鲜荚/干豆", process="鲜食/晒干/脱荚", outlet="蔬菜、干豆"),
    "lentil": dict(main="干豆", process="干燥→脱荚→煮/磨粉", outlet="豆类、豆粉"),
    "soybean": dict(main="大豆", process="干燥→浸泡→磨浆→豆腐/豆酱/榨油", outlet="豆制品、油、饲料"),
    "peanut": dict(main="花生/花生油", process="干燥→脱壳→炒/压榨", outlet="坚果、油、花生酱"),
    "canola": dict(main="油菜籽/菜籽油", process="干燥→清理→压榨→过滤", outlet="食用油、油饼饲料"),
}

for n in a_names + tfc_names:
    if n not in over and n not in a_group_of and n not in tfc_group_of:
        raise SystemExit("missing placement " + n)

lines = []
lines.append("# 289 作物主产品/副产品、育种育秧、初步加工总计划\n")
lines.append("> 日期：2026-10-28\n")
lines.append("> 性质：**计划**，不是实现；每一种作物都必须经过同一张矩阵。\n")
lines.append("> 依据：`117 §6.8`、`126 §12.11`、`126 §12.12`、`280 §11`。\n")
lines.append("\n## 0. 范围与口径\n")
lines.append("- A 实际 `crops-manifest.json`：**87 种**（文档旧称 86，差异需收敛）；")
lines.append("- TFC 原版作物：**29 种**；")
lines.append("- 合计 **116 条作物记录**；名称重复的物种（如草莓/卷心菜相关）按来源分别列出，避免把 A 与 TFC 的 ID 混用；")
lines.append("- 每种作物必须有：主产品、副产品、繁殖方式、育苗/种子处理、初步加工、至少一个出口；")
lines.append("- 没有“只换贴图/只掉种子”的条目。\n")
lines.append("## 1. 统一术语\n")
lines.append("| 术语 | 本计划含义 |\n|---|---|\n| 主产品 | 成熟收获的主要食物/材料/纤维/油料 |\n| 副产品 | 秸秆、糠、荚、皮、油饼、种子、纤维渣等，必须有用途 |\n| 繁殖 | 有性种子、块茎/鳞茎、根茎、扦插/分株、匍匐茎 |\n| 育苗/种子处理 | 采种→干燥→筛选→浸种→催芽→拌种；或块茎/鳞茎分级催芽；或母株分株 |\n| 初步加工 | 收获后到可储存/可进入下一链的第一段加工，不等于最终食品 |\n| 出口 | 食物、调料、油、纤维、饲料、堆肥、纸、容器、酒等至少一项 |\n")

# Group summary
lines.append("## 2. 分组与全覆盖清单\n")
lines.append("| 组 | 数量 | 包含作物 | 统一主链 |\n|---|---:|---|---|\n")
for g, names in a_groups.items():
    lines.append(f"| A·{g} | {len(names)} | {' · '.join(names)} | {info.get(g, info['叶菜/茎菜'])['process']} |\n")
for g, names in tfc_groups.items():
    lines.append(f"| TFC·{g} | {len(names)} | {' · '.join(names)} | {info.get(g, info['谷物/禾本'])['process']} |\n")
lines.append("\n> 上表每个名字都必须在 §3 的逐作物矩阵中出现；任何名字缺失即计划不完整。\n")

lines.append("## 3. 逐作物矩阵（116 条）\n")
lines.append("| # | 作物 | 来源/组 | 主产品 | 副产品 | 繁殖 | 育苗/种子处理 | 初步加工 | 出口 | 批次 |\n")
lines.append("|---:|---|---|---|---|---|---|---|---|---|\n")

idx = 0
for source, names, group_of in (("A", a_names, a_group_of), ("TFC", tfc_names, tfc_group_of)):
    for n in names:
        idx += 1
        g = group_of[n]
        base = dict(info[g])
        base.update(over.get(n, {}))
        main = base.get("main", "按物种现有产物").replace("<id>", n)
        if source == "TFC":
            main = main.replace("tfcfarmingplus:", "tfc:")
        by = base.get("by", "按物种现有副产物")
        prop = base.get("prop", "种子")
        nursery = base.get("nursery", "采种→晒干→筛选→浸种/催芽→直播")
        process = base.get("process", "清洗→初加工")
        outlet = base.get("outlet", "按物种现有用途")
        batch = base.get("batch", "P1")
        lines.append(f"| {idx} | `{n}` | {source}·{g} | {main} | {by} | {prop} | {nursery} | {process} | {outlet} | {batch} |\n")

lines.append("\n## 4. 培育/育秧专项计划\n")
lines.append("### 4.1 六环节（117 §6.8）\n")
lines.append("1. 留种/采种：有性（种子）+ 无性（块茎/鳞茎/根茎/扦插/分株/匍匐茎）；母株性状用 DataComponent 标记；\n")
lines.append("2. 育苗：育苗盘/苗床方块 + BE；温湿度影响成活；\n")
lines.append("3. 移栽：`in_world` 手持苗右键耕地，校验土壤/气候，缓苗期；\n")
lines.append("4. 生长管理：间苗、培土、搭架、打顶、除草、施肥；\n")
lines.append("5. 收获：主产品 + 次产品；未成熟破坏补偿；\n")
lines.append("6. 留种循环：成熟株留种/扦插闭环。\n")
lines.append("### 4.2 九道种子加工（126 §12.12）\n")
lines.append("采种 → 种子干燥 → 选种/筛种 → 浸种 → 催芽 → 拌种 → 扦插/分株 → 育苗 → 移栽。\n")
lines.append("\n### 4.3 作物繁殖方式分组\n")
lines.append("| 繁殖方式 | 作物 |\n|---|---|\n")
seed_names = []
tuber_names = []
cut_names = []
for n in a_names:
    prop = over.get(n, {}).get("prop", info[a_group_of[n]]["prop"])
    if "种子" in prop and "块茎" not in prop and "分株" not in prop and "扦插" not in prop and "根茎" not in prop and "匍匐" not in prop:
        seed_names.append("A:" + n)
    elif "匍匐" in prop or "扦插" in prop or "分株" in prop or "冠芽" in prop:
        cut_names.append("A:" + n)
    else:
        tuber_names.append("A:" + n)
for n in tfc_names:
    prop = over.get(n, {}).get("prop", info[tfc_group_of[n]]["prop"])
    if "种子" in prop and all(x not in prop for x in ("块茎", "分株", "扦插", "根茎", "匍匐", "种球", "蒜瓣", "种薯", "蔗种")):
        seed_names.append("TFC:" + n)
    elif any(x in prop for x in ("分株", "扦插", "匍匐", "冠芽")):
        cut_names.append("TFC:" + n)
    else:
        tuber_names.append("TFC:" + n)
lines.append("| 有性种子 | " + " · ".join(seed_names) + " |\n")
lines.append("| 块茎/鳞茎/根茎/种薯 | " + " · ".join(tuber_names) + " |\n")
lines.append("| 扦插/分株/匍匐茎/冠芽 | " + " · ".join(cut_names) + " |\n")

lines.append("\n## 5. 实施批次\n")
lines.append("| 批次 | 内容 | 验收 |\n|---|---|---|\n")
lines.append("| P0 | 矩阵/ID/标签/产物映射；选 1 个物种打通全链 | 每个字段有值；无死端 |\n")
lines.append("| P1 | 种子处理（干燥/筛选/浸种/催芽/拌种）+ 育苗盘 + 移栽 | 6 环节可执行；缓苗/成活有数据 |\n")
lines.append("| P2 | 各族初步加工（脱粒/脱荚/磨粉/压榨/盐渍/发酵/晒干/沤麻） | 每族至少 1 条完整链；主+副产物 |\n")
lines.append("| P3 | 86+29 全作物覆盖与副产物出口 | 每个作物通过 §3 行验收 |\n")
lines.append("| P4 | TFC 29 的视觉/资源覆盖与 B 行为接入 | 不影响存档；掉落不减少 |\n")
lines.append("\n## 6. 每作物验收表\n")
lines.append("每个作物必须同时满足：\n")
lines.append("1. 主产品与副产品存在；\n2. 繁殖方式明确（有性/无性）；\n3. 育苗或种子处理路径明确；\n4. 至少一条初步加工；\n5. 至少一个出口；\n6. 不减少原掉落；\n7. 不出现“只有种子/只能生吃”的死端。\n")

lines.append("\n## 7. 未决问题\n")
lines.append("1. A 实际 87 种与文档 86 种的差异必须收敛（本计划按 87 列）。\n")
lines.append("2. TFC 29 与 A 87 是否共用同一套六环节，还是 TFC 29 只做资源覆盖。\n")
lines.append("3. 种子处理/育苗盘/移栽是 B 自有方块，还是扩展 TFC 作物行为；必须定 API。\n")
lines.append("4. TFC 种子是 TFC 物品，处理后的种子是 B 新物品还是 DataComponent；需定 ID/迁移。\n")
lines.append("5. “生产链”覆盖 86 还是 29+86，必须先定，否则无法排期。\n")
lines.append("6. 所有新产物/副产物必须有真实出口；不能为凑矩阵新增无用途物品。\n")

DOC.write_text("".join(lines), encoding="utf-8")
print("wrote", DOC, "rows", idx, "bytes", DOC.stat().st_size)
