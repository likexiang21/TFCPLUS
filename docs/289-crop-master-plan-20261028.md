# 289 作物主产品/副产品、育种育秧、初步加工总计划
> 日期：2026-10-28
> 性质：**计划**，不是实现；每一种作物都必须经过同一张矩阵。
> 依据：`117 §6.8`、`126 §12.11`、`126 §12.12`、`280 §11`。

## 0. 范围与口径
- A 实际 `crops-manifest.json`：**87 种**（文档旧称 86，差异需收敛）；- TFC 原版作物：**29 种**；- 合计 **116 条作物记录**；名称重复的物种（如草莓/卷心菜相关）按来源分别列出，避免把 A 与 TFC 的 ID 混用；- 每种作物必须有：主产品、副产品、繁殖方式、育苗/种子处理、初步加工、至少一个出口；- 没有“只换贴图/只掉种子”的条目。
## 1. 统一术语
| 术语 | 本计划含义 |
|---|---|
| 主产品 | 成熟收获的主要食物/材料/纤维/油料 |
| 副产品 | 秸秆、糠、荚、皮、油饼、种子、纤维渣等，必须有用途 |
| 繁殖 | 有性种子、块茎/鳞茎、根茎、扦插/分株、匍匐茎 |
| 育苗/种子处理 | 采种→干燥→筛选→浸种→催芽→拌种；或块茎/鳞茎分级催芽；或母株分株 |
| 初步加工 | 收获后到可储存/可进入下一链的第一段加工，不等于最终食品 |
| 出口 | 食物、调料、油、纤维、饲料、堆肥、纸、容器、酒等至少一项 |
## 2. 分组与全覆盖清单
| 组 | 数量 | 包含作物 | 统一主链 |
|---|---:|---|---|
| A·叶菜/茎菜 | 21 | spinach · lettuce · celery · kale · napa_cabbage · mustard_greens · broccoli · cauliflower · brussels_sprouts · swiss_chard · celtuce · garland_chrysanthemum · perilla · arugula · asparagus · rhubarb · artichoke · cardoon · purslane · water_spinach · malabar_spinach | 清洗→切/撕→盐渍→乳酸发酵→晒干；叶球类可切丝盐渍 |
| A·根/块茎/鳞茎 | 17 | turnip · parsnip · sunchoke · shallot · celeriac · salsify · ginger · turmeric · yacon · chicory_root · taro · water_chestnut · water_caltrop · lotus · arrowhead · gorgon_nut · yam | 清洗→去皮→切片→晒干/磨粉/沉淀淀粉；生姜/姜黄走香料链 |
| A·谷物/禾本 | 12 | millet · foxtail_millet · buckwheat · fonio · spelt · emmer · einkorn · pearl_millet · amaranth · quinoa · finger_millet · sorghum | 脱粒→扬场→磨粉；麦类可制麦芽；稻类可碾米 |
| A·豆类 | 9 | chickpea · faba_bean · lupin · adzuki · pea · cowpea · common_bean · winged_bean · pigeon_pea | 干燥→脱荚→浸泡→磨浆/煮制/发酵 |
| A·油料 | 4 | flax · sesame · safflower · sunflower | 清理→炒/烘→磨→蒸→制饼→压榨→过滤 |
| A·纤维 | 4 | hemp · ramie · cotton · sisal | 沤麻→打麻→梳麻→纺线→织布；棉：轧棉→梳棉→纺 |
| A·茄果/瓜类 | 10 | chili · eggplant · okra · winter_melon · loofah · bitter_melon · snake_gourd · chayote · bottle_gourd · cantaloupe | 清洗→切片/取籽→晒干/磨粉/腌制/熬酱；loofah 取络、葫芦掏空 |
| A·香草/香料 | 1 | chive | 采叶→干燥→研磨→过筛；鲜用 |
| A·特用 | 5 | agave · bambara_nut · fenugreek · hops · jobs_tears | 按物种各自链；不能批量套同一配方 |
| A·水生/其他 | 3 | wild_rice_stem · water_dropwort · water_shield | 采割→脱粒/晒干/剥壳；纤维类沤制/打麻 |
| A·浆果特例 | 1 | strawberry | 鲜食→果酱/果干/冰淇淋；不按灌木处理 |
| TFC·谷物/禾本 | 7 | barley · oat · rice · rye · wheat · maize · sugarcane | 脱粒→扬场→磨粉；麦类可制麦芽；稻类可碾米 |
| TFC·根/块茎/鳞茎 | 7 | beet · carrot · potato · radish · onion · garlic · cassava | 清洗→去皮→切片→晒干/磨粉/沉淀淀粉；生姜/姜黄走香料链 |
| TFC·豆类/油料 | 5 | soybean · peanut · canola · green_bean · lentil | 干燥→脱荚/清理→浸泡/压榨/磨浆 |
| TFC·叶菜/饲草 | 2 | cabbage · alfalfa | 叶菜：清洗→切→盐渍/发酵/晒干；饲草：晒干→打捆 |
| TFC·茄果/瓜类 | 6 | tomato · red_bell_pepper · yellow_bell_pepper · melon · pumpkin · squash | 清洗→切片/取籽→晒干/磨粉/腌制/熬酱；loofah 取络、葫芦掏空 |
| TFC·纤维 | 1 | jute | 沤麻→打麻→梳麻→纺线→织布；棉：轧棉→梳棉→纺 |
| TFC·水生/纤维 | 1 | papyrus | 采割→沤制→打麻→晾晒/造纸 |

> 上表每个名字都必须在 §3 的逐作物矩阵中出现；任何名字缺失即计划不完整。
## 3. 逐作物矩阵（116 条）
| # | 作物 | 来源/组 | 主产品 | 副产品 | 繁殖 | 育苗/种子处理 | 初步加工 | 出口 | 批次 |
|---:|---|---|---|---|---|---|---|---|---|
| 1 | `spinach` | A·叶菜/茎菜 | 食用叶/叶球/茎（`tfcfarmingplus:food/spinach`）；水生叶菜按 A 现有产物 | 种子 + 外叶/叶柄/修整料 → 堆肥、饲料；纤维类副产（cardoon/artichoke） | 种子直播/育苗移栽；artichoke/cardoon/rhubarb/asparagus 用分株/冠芽 | 种子：采种→晒干→筛选→浸种/催芽→育苗盘→移栽；分株：母株→分株→育苗→定植 | 清洗→切/撕→盐渍→乳酸发酵→晒干；叶球类可切丝盐渍 | 沙拉、汤、腌菜、干菜、堆肥/饲料 | P1 |
| 2 | `lettuce` | A·叶菜/茎菜 | 食用叶/叶球/茎（`tfcfarmingplus:food/lettuce`）；水生叶菜按 A 现有产物 | 种子 + 外叶/叶柄/修整料 → 堆肥、饲料；纤维类副产（cardoon/artichoke） | 种子直播/育苗移栽；artichoke/cardoon/rhubarb/asparagus 用分株/冠芽 | 种子：采种→晒干→筛选→浸种/催芽→育苗盘→移栽；分株：母株→分株→育苗→定植 | 清洗→切/撕→盐渍→乳酸发酵→晒干；叶球类可切丝盐渍 | 沙拉、汤、腌菜、干菜、堆肥/饲料 | P1 |
| 3 | `celery` | A·叶菜/茎菜 | 食用叶/叶球/茎（`tfcfarmingplus:food/celery`）；水生叶菜按 A 现有产物 | 种子 + 外叶/叶柄/修整料 → 堆肥、饲料；纤维类副产（cardoon/artichoke） | 种子直播/育苗移栽；artichoke/cardoon/rhubarb/asparagus 用分株/冠芽 | 种子：采种→晒干→筛选→浸种/催芽→育苗盘→移栽；分株：母株→分株→育苗→定植 | 清洗→切/撕→盐渍→乳酸发酵→晒干；叶球类可切丝盐渍 | 沙拉、汤、腌菜、干菜、堆肥/饲料 | P1 |
| 4 | `kale` | A·叶菜/茎菜 | 食用叶/叶球/茎（`tfcfarmingplus:food/kale`）；水生叶菜按 A 现有产物 | 种子 + 外叶/叶柄/修整料 → 堆肥、饲料；纤维类副产（cardoon/artichoke） | 种子直播/育苗移栽；artichoke/cardoon/rhubarb/asparagus 用分株/冠芽 | 种子：采种→晒干→筛选→浸种/催芽→育苗盘→移栽；分株：母株→分株→育苗→定植 | 采叶→焯水/盐渍/晒干 | 蔬菜、干菜、腌菜 | P1 |
| 5 | `napa_cabbage` | A·叶菜/茎菜 | 食用叶/叶球/茎（`tfcfarmingplus:food/napa_cabbage`）；水生叶菜按 A 现有产物 | 种子 + 外叶/叶柄/修整料 → 堆肥、饲料；纤维类副产（cardoon/artichoke） | 种子直播/育苗移栽；artichoke/cardoon/rhubarb/asparagus 用分株/冠芽 | 种子：采种→晒干→筛选→浸种/催芽→育苗盘→移栽；分株：母株→分株→育苗→定植 | 切丝→盐渍→乳酸发酵→晒干 | 酸菜、泡菜、干菜 | P1 |
| 6 | `mustard_greens` | A·叶菜/茎菜 | 食用叶/叶球/茎（`tfcfarmingplus:food/mustard_greens`）；水生叶菜按 A 现有产物 | 种子 + 外叶/叶柄/修整料 → 堆肥、饲料；纤维类副产（cardoon/artichoke） | 种子直播/育苗移栽；artichoke/cardoon/rhubarb/asparagus 用分株/冠芽 | 种子：采种→晒干→筛选→浸种/催芽→育苗盘→移栽；分株：母株→分株→育苗→定植 | 清洗→切/撕→盐渍→乳酸发酵→晒干；叶球类可切丝盐渍 | 沙拉、汤、腌菜、干菜、堆肥/饲料 | P1 |
| 7 | `broccoli` | A·叶菜/茎菜 | 食用叶/叶球/茎（`tfcfarmingplus:food/broccoli`）；水生叶菜按 A 现有产物 | 种子 + 外叶/叶柄/修整料 → 堆肥、饲料；纤维类副产（cardoon/artichoke） | 种子直播/育苗移栽；artichoke/cardoon/rhubarb/asparagus 用分株/冠芽 | 种子：采种→晒干→筛选→浸种/催芽→育苗盘→移栽；分株：母株→分株→育苗→定植 | 采花球→焯水/冷冻/晒干 | 蔬菜、干菜 | P1 |
| 8 | `cauliflower` | A·叶菜/茎菜 | 食用叶/叶球/茎（`tfcfarmingplus:food/cauliflower`）；水生叶菜按 A 现有产物 | 种子 + 外叶/叶柄/修整料 → 堆肥、饲料；纤维类副产（cardoon/artichoke） | 种子直播/育苗移栽；artichoke/cardoon/rhubarb/asparagus 用分株/冠芽 | 种子：采种→晒干→筛选→浸种/催芽→育苗盘→移栽；分株：母株→分株→育苗→定植 | 采花球→焯水/腌渍/晒干 | 蔬菜、腌菜 | P1 |
| 9 | `brussels_sprouts` | A·叶菜/茎菜 | 食用叶/叶球/茎（`tfcfarmingplus:food/brussels_sprouts`）；水生叶菜按 A 现有产物 | 种子 + 外叶/叶柄/修整料 → 堆肥、饲料；纤维类副产（cardoon/artichoke） | 种子直播/育苗移栽；artichoke/cardoon/rhubarb/asparagus 用分株/冠芽 | 种子：采种→晒干→筛选→浸种/催芽→育苗盘→移栽；分株：母株→分株→育苗→定植 | 采芽球→焯水/烤/腌渍 | 蔬菜、腌菜 | P1 |
| 10 | `swiss_chard` | A·叶菜/茎菜 | 食用叶/叶球/茎（`tfcfarmingplus:food/swiss_chard`）；水生叶菜按 A 现有产物 | 种子 + 外叶/叶柄/修整料 → 堆肥、饲料；纤维类副产（cardoon/artichoke） | 种子直播/育苗移栽；artichoke/cardoon/rhubarb/asparagus 用分株/冠芽 | 种子：采种→晒干→筛选→浸种/催芽→育苗盘→移栽；分株：母株→分株→育苗→定植 | 清洗→切/撕→盐渍→乳酸发酵→晒干；叶球类可切丝盐渍 | 沙拉、汤、腌菜、干菜、堆肥/饲料 | P1 |
| 11 | `celtuce` | A·叶菜/茎菜 | 食用叶/叶球/茎（`tfcfarmingplus:food/celtuce`）；水生叶菜按 A 现有产物 | 种子 + 外叶/叶柄/修整料 → 堆肥、饲料；纤维类副产（cardoon/artichoke） | 种子直播/育苗移栽；artichoke/cardoon/rhubarb/asparagus 用分株/冠芽 | 种子：采种→晒干→筛选→浸种/催芽→育苗盘→移栽；分株：母株→分株→育苗→定植 | 清洗→切/撕→盐渍→乳酸发酵→晒干；叶球类可切丝盐渍 | 沙拉、汤、腌菜、干菜、堆肥/饲料 | P1 |
| 12 | `garland_chrysanthemum` | A·叶菜/茎菜 | 食用叶/叶球/茎（`tfcfarmingplus:food/garland_chrysanthemum`）；水生叶菜按 A 现有产物 | 种子 + 外叶/叶柄/修整料 → 堆肥、饲料；纤维类副产（cardoon/artichoke） | 种子直播/育苗移栽；artichoke/cardoon/rhubarb/asparagus 用分株/冠芽 | 种子：采种→晒干→筛选→浸种/催芽→育苗盘→移栽；分株：母株→分株→育苗→定植 | 清洗→切/撕→盐渍→乳酸发酵→晒干；叶球类可切丝盐渍 | 沙拉、汤、腌菜、干菜、堆肥/饲料 | P1 |
| 13 | `perilla` | A·叶菜/茎菜 | 食用叶/叶球/茎（`tfcfarmingplus:food/perilla`）；水生叶菜按 A 现有产物 | 种子 + 外叶/叶柄/修整料 → 堆肥、饲料；纤维类副产（cardoon/artichoke） | 种子直播/育苗移栽；artichoke/cardoon/rhubarb/asparagus 用分株/冠芽 | 种子：采种→晒干→筛选→浸种/催芽→育苗盘→移栽；分株：母株→分株→育苗→定植 | 清洗→切/撕→盐渍→乳酸发酵→晒干；叶球类可切丝盐渍 | 沙拉、汤、腌菜、干菜、堆肥/饲料 | P1 |
| 14 | `arugula` | A·叶菜/茎菜 | 食用叶/叶球/茎（`tfcfarmingplus:food/arugula`）；水生叶菜按 A 现有产物 | 种子 + 外叶/叶柄/修整料 → 堆肥、饲料；纤维类副产（cardoon/artichoke） | 种子直播/育苗移栽；artichoke/cardoon/rhubarb/asparagus 用分株/冠芽 | 种子：采种→晒干→筛选→浸种/催芽→育苗盘→移栽；分株：母株→分株→育苗→定植 | 清洗→切/撕→盐渍→乳酸发酵→晒干；叶球类可切丝盐渍 | 沙拉、汤、腌菜、干菜、堆肥/饲料 | P1 |
| 15 | `turnip` | A·根/块茎/鳞茎 | 食用根/块茎/鳞茎，或淀粉/粉（`tfcfarmingplus:food/turnip`） | 茎叶/皮渣 → 饲料、堆肥；种薯/种球/种瓣留种 | 种子（turnip/parsnip/celeriac/salsify/chicory/radish/carrot/beet）或块茎/鳞茎/根茎（其余） | 种子：采种→晒干→筛选→浸种→直播；块茎/鳞茎：愈伤→分级→直播 | 清洗→去皮→切片→晒干/磨粉/沉淀淀粉；生姜/姜黄走香料链 | 主食、淀粉、腌菜、干片、饲料、堆肥 | P1 |
| 16 | `parsnip` | A·根/块茎/鳞茎 | 食用根/块茎/鳞茎，或淀粉/粉（`tfcfarmingplus:food/parsnip`） | 茎叶/皮渣 → 饲料、堆肥；种薯/种球/种瓣留种 | 种子（turnip/parsnip/celeriac/salsify/chicory/radish/carrot/beet）或块茎/鳞茎/根茎（其余） | 种子：采种→晒干→筛选→浸种→直播；块茎/鳞茎：愈伤→分级→直播 | 清洗→去皮→切片→晒干/磨粉/沉淀淀粉；生姜/姜黄走香料链 | 主食、淀粉、腌菜、干片、饲料、堆肥 | P1 |
| 17 | `sunchoke` | A·根/块茎/鳞茎 | 食用根/块茎/鳞茎，或淀粉/粉（`tfcfarmingplus:food/sunchoke`） | 茎叶/皮渣 → 饲料、堆肥；种薯/种球/种瓣留种 | 块茎 | 种薯→分级→直播 | 清洗→去皮→切片→煮/烤/晒干 | 蔬菜、饲料、菊粉 | P1 |
| 18 | `shallot` | A·根/块茎/鳞茎 | 食用根/块茎/鳞茎，或淀粉/粉（`tfcfarmingplus:food/shallot`） | 茎叶/皮渣 → 饲料、堆肥；种薯/种球/种瓣留种 | 种子（turnip/parsnip/celeriac/salsify/chicory/radish/carrot/beet）或块茎/鳞茎/根茎（其余） | 种子：采种→晒干→筛选→浸种→直播；块茎/鳞茎：愈伤→分级→直播 | 清洗→去皮→切片→晒干/磨粉/沉淀淀粉；生姜/姜黄走香料链 | 主食、淀粉、腌菜、干片、饲料、堆肥 | P1 |
| 19 | `celeriac` | A·根/块茎/鳞茎 | 食用根/块茎/鳞茎，或淀粉/粉（`tfcfarmingplus:food/celeriac`） | 茎叶/皮渣 → 饲料、堆肥；种薯/种球/种瓣留种 | 种子（turnip/parsnip/celeriac/salsify/chicory/radish/carrot/beet）或块茎/鳞茎/根茎（其余） | 种子：采种→晒干→筛选→浸种→直播；块茎/鳞茎：愈伤→分级→直播 | 清洗→去皮→切片→晒干/磨粉/沉淀淀粉；生姜/姜黄走香料链 | 主食、淀粉、腌菜、干片、饲料、堆肥 | P1 |
| 20 | `salsify` | A·根/块茎/鳞茎 | 食用根/块茎/鳞茎，或淀粉/粉（`tfcfarmingplus:food/salsify`） | 茎叶/皮渣 → 饲料、堆肥；种薯/种球/种瓣留种 | 种子（turnip/parsnip/celeriac/salsify/chicory/radish/carrot/beet）或块茎/鳞茎/根茎（其余） | 种子：采种→晒干→筛选→浸种→直播；块茎/鳞茎：愈伤→分级→直播 | 清洗→去皮→切片→晒干/磨粉/沉淀淀粉；生姜/姜黄走香料链 | 主食、淀粉、腌菜、干片、饲料、堆肥 | P1 |
| 21 | `ginger` | A·根/块茎/鳞茎 | 食用根/块茎/鳞茎，或淀粉/粉（`tfcfarmingplus:food/ginger`） | 茎叶/皮渣 → 饲料、堆肥；种薯/种球/种瓣留种 | 根茎 | 种姜→催芽→切块→定植 | 清洗→去皮→切片→晒干→磨粉 | 香料、姜茶、腌姜 | P1 |
| 22 | `turmeric` | A·根/块茎/鳞茎 | 食用根/块茎/鳞茎，或淀粉/粉（`tfcfarmingplus:food/turmeric`） | 茎叶/皮渣 → 饲料、堆肥；种薯/种球/种瓣留种 | 根茎 | 种姜→催芽→切块→定植 | 清洗→煮/蒸→晒干→磨粉 | 香料、染料、咖喱 | P1 |
| 23 | `yacon` | A·根/块茎/鳞茎 | 食用根/块茎/鳞茎，或淀粉/粉（`tfcfarmingplus:food/yacon`） | 茎叶/皮渣 → 饲料、堆肥；种薯/种球/种瓣留种 | 块茎/分株 | 种薯→育苗→定植 | 清洗→去皮→切片→晒干/榨汁 | 蔬菜、糖浆 | P1 |
| 24 | `chicory_root` | A·根/块茎/鳞茎 | 食用根/块茎/鳞茎，或淀粉/粉（`tfcfarmingplus:food/chicory_root`） | 茎叶/皮渣 → 饲料、堆肥；种薯/种球/种瓣留种 | 种子（turnip/parsnip/celeriac/salsify/chicory/radish/carrot/beet）或块茎/鳞茎/根茎（其余） | 种子：采种→晒干→筛选→浸种→直播；块茎/鳞茎：愈伤→分级→直播 | 清洗→去皮→切片→晒干/磨粉/沉淀淀粉；生姜/姜黄走香料链 | 主食、淀粉、腌菜、干片、饲料、堆肥 | P1 |
| 25 | `millet` | A·谷物/禾本 | 谷物籽粒（`tfcfarmingplus:food/millet`；TFC 用 `tfc:food/millet`） | 秸秆、糠/麸、种子 → 饲料、堆肥、燃料、留种 | 种子 | 采种→晒干→筛选→浸种/催芽（可选）→直播 | 脱粒→扬场→磨粉；麦类可制麦芽；稻类可碾米 | 面粉/米饭/麦芽/酿酒/饲料/燃料 | P1 |
| 26 | `foxtail_millet` | A·谷物/禾本 | 谷物籽粒（`tfcfarmingplus:food/foxtail_millet`；TFC 用 `tfc:food/foxtail_millet`） | 秸秆、糠/麸、种子 → 饲料、堆肥、燃料、留种 | 种子 | 采种→晒干→筛选→浸种/催芽（可选）→直播 | 脱粒→扬场→磨粉；麦类可制麦芽；稻类可碾米 | 面粉/米饭/麦芽/酿酒/饲料/燃料 | P1 |
| 27 | `buckwheat` | A·谷物/禾本 | 谷物籽粒（`tfcfarmingplus:food/buckwheat`；TFC 用 `tfc:food/buckwheat`） | 秸秆、糠/麸、种子 → 饲料、堆肥、燃料、留种 | 种子 | 采种→晒干→筛选→浸种/催芽（可选）→直播 | 脱粒→扬场→磨粉；麦类可制麦芽；稻类可碾米 | 面粉/米饭/麦芽/酿酒/饲料/燃料 | P1 |
| 28 | `fonio` | A·谷物/禾本 | 谷物籽粒（`tfcfarmingplus:food/fonio`；TFC 用 `tfc:food/fonio`） | 秸秆、糠/麸、种子 → 饲料、堆肥、燃料、留种 | 种子 | 采种→晒干→筛选→浸种/催芽（可选）→直播 | 脱粒→扬场→磨粉；麦类可制麦芽；稻类可碾米 | 面粉/米饭/麦芽/酿酒/饲料/燃料 | P1 |
| 29 | `spelt` | A·谷物/禾本 | 谷物籽粒（`tfcfarmingplus:food/spelt`；TFC 用 `tfc:food/spelt`） | 秸秆、糠/麸、种子 → 饲料、堆肥、燃料、留种 | 种子 | 采种→晒干→筛选→浸种/催芽（可选）→直播 | 脱粒→扬场→磨粉；麦类可制麦芽；稻类可碾米 | 面粉/米饭/麦芽/酿酒/饲料/燃料 | P1 |
| 30 | `emmer` | A·谷物/禾本 | 谷物籽粒（`tfcfarmingplus:food/emmer`；TFC 用 `tfc:food/emmer`） | 秸秆、糠/麸、种子 → 饲料、堆肥、燃料、留种 | 种子 | 采种→晒干→筛选→浸种/催芽（可选）→直播 | 脱粒→扬场→磨粉；麦类可制麦芽；稻类可碾米 | 面粉/米饭/麦芽/酿酒/饲料/燃料 | P1 |
| 31 | `einkorn` | A·谷物/禾本 | 谷物籽粒（`tfcfarmingplus:food/einkorn`；TFC 用 `tfc:food/einkorn`） | 秸秆、糠/麸、种子 → 饲料、堆肥、燃料、留种 | 种子 | 采种→晒干→筛选→浸种/催芽（可选）→直播 | 脱粒→扬场→磨粉；麦类可制麦芽；稻类可碾米 | 面粉/米饭/麦芽/酿酒/饲料/燃料 | P1 |
| 32 | `pearl_millet` | A·谷物/禾本 | 谷物籽粒（`tfcfarmingplus:food/pearl_millet`；TFC 用 `tfc:food/pearl_millet`） | 秸秆、糠/麸、种子 → 饲料、堆肥、燃料、留种 | 种子 | 采种→晒干→筛选→浸种/催芽（可选）→直播 | 脱粒→扬场→磨粉；麦类可制麦芽；稻类可碾米 | 面粉/米饭/麦芽/酿酒/饲料/燃料 | P1 |
| 33 | `amaranth` | A·谷物/禾本 | 谷物籽粒（`tfcfarmingplus:food/amaranth`；TFC 用 `tfc:food/amaranth`） | 秸秆、糠/麸、种子 → 饲料、堆肥、燃料、留种 | 种子 | 采种→晒干→筛选→浸种/催芽（可选）→直播 | 脱粒→扬场→磨粉；麦类可制麦芽；稻类可碾米 | 面粉/米饭/麦芽/酿酒/饲料/燃料 | P1 |
| 34 | `quinoa` | A·谷物/禾本 | 谷物籽粒（`tfcfarmingplus:food/quinoa`；TFC 用 `tfc:food/quinoa`） | 秸秆、糠/麸、种子 → 饲料、堆肥、燃料、留种 | 种子 | 采种→晒干→筛选→浸种/催芽（可选）→直播 | 脱粒→扬场→磨粉；麦类可制麦芽；稻类可碾米 | 面粉/米饭/麦芽/酿酒/饲料/燃料 | P1 |
| 35 | `finger_millet` | A·谷物/禾本 | 谷物籽粒（`tfcfarmingplus:food/finger_millet`；TFC 用 `tfc:food/finger_millet`） | 秸秆、糠/麸、种子 → 饲料、堆肥、燃料、留种 | 种子 | 采种→晒干→筛选→浸种/催芽（可选）→直播 | 脱粒→扬场→磨粉；麦类可制麦芽；稻类可碾米 | 面粉/米饭/麦芽/酿酒/饲料/燃料 | P1 |
| 36 | `jobs_tears` | A·特用 | 薏米 | 糠/秸秆→饲料 | 种子 | 按物种各自处理；详见行内覆盖 | 脱壳→碾米→煮/磨粉 | 粮食、药食 | P2/P3 |
| 37 | `chickpea` | A·豆类 | 干豆或鲜荚（`tfcfarmingplus:food/chickpea`；TFC 用 `tfc:food/chickpea`） | 豆荚、秸秆、种子 → 饲料、堆肥、留种 | 种子 | 采种→晒干→筛选→浸种→直播 | 干燥→脱荚→浸泡→磨浆/煮制/发酵 | 豆制品、豆粉、豆酱、饲料 | P1 |
| 38 | `faba_bean` | A·豆类 | 干豆或鲜荚（`tfcfarmingplus:food/faba_bean`；TFC 用 `tfc:food/faba_bean`） | 豆荚、秸秆、种子 → 饲料、堆肥、留种 | 种子 | 采种→晒干→筛选→浸种→直播 | 干燥→脱荚→浸泡→磨浆/煮制/发酵 | 豆制品、豆粉、豆酱、饲料 | P1 |
| 39 | `lupin` | A·豆类 | 干豆或鲜荚（`tfcfarmingplus:food/lupin`；TFC 用 `tfc:food/lupin`） | 豆荚、秸秆、种子 → 饲料、堆肥、留种 | 种子 | 采种→晒干→筛选→浸种→直播 | 干燥→脱荚→浸泡→磨浆/煮制/发酵 | 豆制品、豆粉、豆酱、饲料 | P1 |
| 40 | `adzuki` | A·豆类 | 干豆或鲜荚（`tfcfarmingplus:food/adzuki`；TFC 用 `tfc:food/adzuki`） | 豆荚、秸秆、种子 → 饲料、堆肥、留种 | 种子 | 采种→晒干→筛选→浸种→直播 | 干燥→脱荚→浸泡→磨浆/煮制/发酵 | 豆制品、豆粉、豆酱、饲料 | P1 |
| 41 | `bambara_nut` | A·特用 | 豆类 | 豆荚/秸秆→饲料 | 种子 | 按物种各自处理；详见行内覆盖 | 干燥→脱荚→煮/磨粉 | 豆制品、豆粉 | P2/P3 |
| 42 | `fenugreek` | A·特用 | 种子香料 + 叶菜 + 芽菜 | 茎叶→饲料/堆肥 | 种子 | 按物种各自处理；详见行内覆盖 | 种子干燥→磨粉；叶鲜食/晒干；种子发芽 | 香料、蔬菜、芽菜 | P2/P3 |
| 43 | `flax` | A·油料 | 纤维 + 亚麻籽油 | 亚麻籽→油；麻屑→纸/填料 | 种子 | 采种→晒干→筛选→直播 | 沤麻→打麻→梳麻→纺线；种子→压榨 | 布、绳、纸、亚麻油 | P1 |
| 44 | `sesame` | A·油料 | 油籽 → 食用油（`tfcfarmingplus:food/sesame` / 油料产物） | 油饼/粕 → 饲料、肥料；部分纤维/秸秆 | 种子 | 采种→晒干→筛选→直播 | 清理→炒/烘→磨→蒸→制饼→压榨→过滤 | 食用油、油饼饲料、调味油 | P1 |
| 45 | `safflower` | A·油料 | 油籽 → 食用油（`tfcfarmingplus:food/safflower` / 油料产物） | 油饼/粕 → 饲料、肥料；部分纤维/秸秆 | 种子 | 采种→晒干→筛选→直播 | 清理→炒/烘→磨→蒸→制饼→压榨→过滤 | 食用油、油饼饲料、调味油 | P1 |
| 46 | `ramie` | A·纤维 | 韧皮纤维 | 麻屑→纸/堆肥；根茎可繁殖 | 根茎/分株 | 种子：采种→晒干→筛选→直播；无性：母株→扦插/分株→育苗→移栽 | 剥麻→沤麻→打麻→梳麻→纺线 | 布、绳、纸 | P2 |
| 47 | `chili` | A·茄果/瓜类 | 辣椒果实/辣椒粉 | 种子、辣椒秆→堆肥 | 种子 | 采种→晒干→筛选→育苗→移栽 | 鲜食/晒干→磨粉；发酵辣酱 | 调料、辣酱 | P1 |
| 48 | `eggplant` | A·茄果/瓜类 | 果实/蔬菜（`tfcfarmingplus:food/eggplant`） | 种子、果肉/瓜瓤 → 饲料/堆肥；loofah 纤维、bottle_gourd 容器、瓜籽油 | 种子；多数育苗后移栽 | 采种→晒干→筛选→浸种/催芽→育苗盘→移栽 | 清洗→切片/取籽→晒干/磨粉/腌制/熬酱；loofah 取络、葫芦掏空 | 蔬菜、香料、酱、籽油、洗具、容器 | P1 |
| 49 | `okra` | A·茄果/瓜类 | 果实/蔬菜（`tfcfarmingplus:food/okra`） | 种子、果肉/瓜瓤 → 饲料/堆肥；loofah 纤维、bottle_gourd 容器、瓜籽油 | 种子；多数育苗后移栽 | 采种→晒干→筛选→浸种/催芽→育苗盘→移栽 | 鲜食/晒干/腌渍 | 蔬菜、干菜、腌菜 | P1 |
| 50 | `cotton` | A·纤维 | 棉纤维 + 棉籽油 | 棉籽→油/饼；棉秆→燃料 | 种子 | 种子：采种→晒干→筛选→直播；无性：母株→扦插/分株→育苗→移栽 | 轧棉→梳棉→纺线；棉籽压榨 | 布、油、饲料 | P2 |
| 51 | `asparagus` | A·叶菜/茎菜 | 食用叶/叶球/茎（`tfcfarmingplus:food/asparagus`）；水生叶菜按 A 现有产物 | 种子 + 外叶/叶柄/修整料 → 堆肥、饲料；纤维类副产（cardoon/artichoke） | 冠芽/分株 | 母株→冠芽→育苗→定植 | 采嫩茎→焯水/晒干/腌渍 | 蔬菜、干菜 | P1 |
| 52 | `chive` | A·香草/香料 | 叶/花/种子（`tfcfarmingplus:food/chive`） | 种子、茎叶修整料 → 留种/堆肥 | 种子或分株 | 采种→晒干→筛选→育苗/直播 | 采叶→干燥→研磨→过筛；鲜用 | 调料、香草粉、腌渍、茶饮 | P2 |
| 53 | `rhubarb` | A·叶菜/茎菜 | 食用叶/叶球/茎（`tfcfarmingplus:food/rhubarb`）；水生叶菜按 A 现有产物 | 种子 + 外叶/叶柄/修整料 → 堆肥、饲料；纤维类副产（cardoon/artichoke） | 分株/冠芽 | 母株→分株→育苗→定植 | 采叶柄→去叶→糖渍/晒干 | 甜点、果酱 | P1 |
| 54 | `artichoke` | A·叶菜/茎菜 | 食用叶/叶球/茎（`tfcfarmingplus:food/artichoke`）；水生叶菜按 A 现有产物 | 种子 + 外叶/叶柄/修整料 → 堆肥、饲料；纤维类副产（cardoon/artichoke） | 分株/冠芽 | 母株→分株→育苗→定植 | 采花苞→蒸煮/腌渍 | 蔬菜、腌菜 | P1 |
| 55 | `taro` | A·根/块茎/鳞茎 | 食用根/块茎/鳞茎，或淀粉/粉（`tfcfarmingplus:food/taro`） | 茎叶/皮渣 → 饲料、堆肥；种薯/种球/种瓣留种 | 球茎/分株 | 种芋→催芽→定植 | 清洗→去皮→煮/蒸→制泥/晒干 | 主食、淀粉 | P1 |
| 56 | `water_chestnut` | A·根/块茎/鳞茎 | 食用根/块茎/鳞茎，或淀粉/粉（`tfcfarmingplus:food/water_chestnut`） | 茎叶/皮渣 → 饲料、堆肥；种薯/种球/种瓣留种 | 球茎 | 种球→浅水定植 | 采球→去皮→煮/磨粉 | 主食、淀粉 | P1 |
| 57 | `water_caltrop` | A·根/块茎/鳞茎 | 食用根/块茎/鳞茎，或淀粉/粉（`tfcfarmingplus:food/water_caltrop`） | 茎叶/皮渣 → 饲料、堆肥；种薯/种球/种瓣留种 | 种子/球茎 | 种球→浅水定植 | 采果→去壳→煮/磨粉 | 主食、淀粉 | P1 |
| 58 | `wild_rice_stem` | A·水生/其他 | 水生谷物 | 秸秆→饲料/编织 | 种子/分株 | 种子：采种→晒干→筛选→浅水直播；根茎：分株→定植 | 采穗→脱粒→碾米 | 粮食 | P2 |
| 59 | `lotus` | A·根/块茎/鳞茎 | 食用根/块茎/鳞茎，或淀粉/粉（`tfcfarmingplus:food/lotus`） | 茎叶/皮渣 → 饲料、堆肥；种薯/种球/种瓣留种 | 根茎（藕） | 种藕→浅水定植 | 采藕→去节→切片→煮/磨粉；莲子另收 | 蔬菜、淀粉、莲子 | P1 |
| 60 | `water_dropwort` | A·水生/其他 | 水生叶菜 | 茎叶渣→堆肥 | 分株/扦插 | 种子：采种→晒干→筛选→浅水直播；根茎：分株→定植 | 采嫩茎叶→焯水/晒干 | 蔬菜 | P2 |
| 61 | `water_spinach` | A·叶菜/茎菜 | 水生叶菜 | 茎叶渣→堆肥 | 种子/扦插 | 种子：采种→晒干→筛选→浸种/催芽→育苗盘→移栽；分株：母株→分株→育苗→定植 | 采嫩茎叶→焯水/晒干 | 蔬菜 | P1 |
| 62 | `arrowhead` | A·根/块茎/鳞茎 | 食用根/块茎/鳞茎，或淀粉/粉（`tfcfarmingplus:food/arrowhead`） | 茎叶/皮渣 → 饲料、堆肥；种薯/种球/种瓣留种 | 球茎 | 种球→浅水定植 | 采球→去皮→煮/晒干 | 蔬菜、淀粉 | P1 |
| 63 | `gorgon_nut` | A·根/块茎/鳞茎 | 食用根/块茎/鳞茎，或淀粉/粉（`tfcfarmingplus:food/gorgon_nut`） | 茎叶/皮渣 → 饲料、堆肥；种薯/种球/种瓣留种 | 种子 | 采种→浸种→浅水育苗→定植 | 采种→脱壳→煮/磨粉 | 粮食、淀粉 | P1 |
| 64 | `winter_melon` | A·茄果/瓜类 | 果实；种子 | 瓜籽→炒制/榨油；瓜瓤→饲料 | 种子 | 采种→晒干→筛选→浸种/催芽→育苗盘→移栽 | 果实→切块/熬酱/糖渍；瓜籽→洗净晒干 | 蔬菜、瓜酱、籽油 | P1 |
| 65 | `hops` | A·特用 | 啤酒花 | 藤蔓→堆肥/纤维 | 根茎/扦插 | 母株→根茎/扦插→搭架定植 | 采花→干燥→酿酒 | 啤酒 | P2/P3 |
| 66 | `loofah` | A·茄果/瓜类 | 嫩果食用 + 老果纤维 | 丝瓜络、种子 | 种子 | 采种→晒干→筛选→浸种/催芽→育苗盘→移栽 | 嫩果食用；老果泡水→去皮去籽→丝瓜络 | 蔬菜、洗具、过滤 | P1 |
| 67 | `bitter_melon` | A·茄果/瓜类 | 果实/蔬菜（`tfcfarmingplus:food/bitter_melon`） | 种子、果肉/瓜瓤 → 饲料/堆肥；loofah 纤维、bottle_gourd 容器、瓜籽油 | 种子；多数育苗后移栽 | 采种→晒干→筛选→浸种/催芽→育苗盘→移栽 | 清洗→切片/取籽→晒干/磨粉/腌制/熬酱；loofah 取络、葫芦掏空 | 蔬菜、香料、酱、籽油、洗具、容器 | P1 |
| 68 | `snake_gourd` | A·茄果/瓜类 | 果实/蔬菜（`tfcfarmingplus:food/snake_gourd`） | 种子、果肉/瓜瓤 → 饲料/堆肥；loofah 纤维、bottle_gourd 容器、瓜籽油 | 种子；多数育苗后移栽 | 采种→晒干→筛选→浸种/催芽→育苗盘→移栽 | 清洗→切片/取籽→晒干/磨粉/腌制/熬酱；loofah 取络、葫芦掏空 | 蔬菜、香料、酱、籽油、洗具、容器 | P1 |
| 69 | `yam` | A·根/块茎/鳞茎 | 食用根/块茎/鳞茎，或淀粉/粉（`tfcfarmingplus:food/yam`） | 茎叶/皮渣 → 饲料、堆肥；种薯/种球/种瓣留种 | 块茎/零余子 | 种薯→催芽→定植 | 清洗→去皮→煮/蒸/磨粉 | 主食、淀粉 | P1 |
| 70 | `malabar_spinach` | A·叶菜/茎菜 | 食用叶/叶球/茎（`tfcfarmingplus:food/malabar_spinach`）；水生叶菜按 A 现有产物 | 种子 + 外叶/叶柄/修整料 → 堆肥、饲料；纤维类副产（cardoon/artichoke） | 种子/扦插 | 种子：采种→晒干→筛选→浸种/催芽→育苗盘→移栽；分株：母株→分株→育苗→定植 | 采嫩茎叶→焯水/晒干 | 蔬菜 | P1 |
| 71 | `chayote` | A·茄果/瓜类 | 果实/蔬菜（`tfcfarmingplus:food/chayote`） | 种子、果肉/瓜瓤 → 饲料/堆肥；loofah 纤维、bottle_gourd 容器、瓜籽油 | 种子；多数育苗后移栽 | 采种→晒干→筛选→浸种/催芽→育苗盘→移栽 | 清洗→切片/取籽→晒干/磨粉/腌制/熬酱；loofah 取络、葫芦掏空 | 蔬菜、香料、酱、籽油、洗具、容器 | P1 |
| 72 | `bottle_gourd` | A·茄果/瓜类 | 嫩果食用 + 老果容器 | 种子、葫芦壳 | 种子 | 采种→晒干→筛选→浸种/催芽→育苗盘→移栽 | 嫩果食用；老果掏空→晾干→容器 | 蔬菜、容器、水瓢 | P1 |
| 73 | `cantaloupe` | A·茄果/瓜类 | 果实；种子 | 瓜籽→炒制/榨油；瓜瓤→饲料 | 种子 | 采种→晒干→筛选→浸种/催芽→育苗盘→移栽 | 果实→鲜食/果酱；瓜籽→洗净晒干 | 水果、果酱、籽油 | P1 |
| 74 | `water_shield` | A·水生/其他 | 水生叶菜/根 | 叶渣→堆肥 | 种子/分株 | 种子：采种→晒干→筛选→浅水直播；根茎：分株→定植 | 采叶/根→清洗→煮/晒干 | 蔬菜 | P2 |
| 75 | `cardoon` | A·叶菜/茎菜 | 食用叶/叶球/茎（`tfcfarmingplus:food/cardoon`）；水生叶菜按 A 现有产物 | 种子 + 外叶/叶柄/修整料 → 堆肥、饲料；纤维类副产（cardoon/artichoke） | 分株/种子 | 种子育苗或分株→定植 | 采叶柄→去筋→焯水/腌渍；纤维副产 | 蔬菜、纤维 | P1 |
| 76 | `agave` | A·特用 | 纤维 + 龙舌兰糖浆 | 叶渣→纤维/饲料；糖蜜 | 吸芽/种子 | 按物种各自处理；详见行内覆盖 | 割叶→刮纤维；烤心→压汁→熬糖浆 | 绳、布、糖浆 | P2/P3 |
| 77 | `purslane` | A·叶菜/茎菜 | 食用叶/叶球/茎（`tfcfarmingplus:food/purslane`）；水生叶菜按 A 现有产物 | 种子 + 外叶/叶柄/修整料 → 堆肥、饲料；纤维类副产（cardoon/artichoke） | 种子直播/育苗移栽；artichoke/cardoon/rhubarb/asparagus 用分株/冠芽 | 种子：采种→晒干→筛选→浸种/催芽→育苗盘→移栽；分株：母株→分株→育苗→定植 | 清洗→切/撕→盐渍→乳酸发酵→晒干；叶球类可切丝盐渍 | 沙拉、汤、腌菜、干菜、堆肥/饲料 | P1 |
| 78 | `pea` | A·豆类 | 干豆或鲜荚（`tfcfarmingplus:food/pea`；TFC 用 `tfc:food/pea`） | 豆荚、秸秆、种子 → 饲料、堆肥、留种 | 种子 | 采种→晒干→筛选→浸种→直播 | 干燥→脱荚→浸泡→磨浆/煮制/发酵 | 豆制品、豆粉、豆酱、饲料 | P1 |
| 79 | `cowpea` | A·豆类 | 干豆或鲜荚（`tfcfarmingplus:food/cowpea`；TFC 用 `tfc:food/cowpea`） | 豆荚、秸秆、种子 → 饲料、堆肥、留种 | 种子 | 采种→晒干→筛选→浸种→直播 | 干燥→脱荚→浸泡→磨浆/煮制/发酵 | 豆制品、豆粉、豆酱、饲料 | P1 |
| 80 | `common_bean` | A·豆类 | 干豆或鲜荚（`tfcfarmingplus:food/common_bean`；TFC 用 `tfc:food/common_bean`） | 豆荚、秸秆、种子 → 饲料、堆肥、留种 | 种子 | 采种→晒干→筛选→浸种→直播 | 干燥→脱荚→浸泡→磨浆/煮制/发酵 | 豆制品、豆粉、豆酱、饲料 | P1 |
| 81 | `winged_bean` | A·豆类 | 干豆或鲜荚（`tfcfarmingplus:food/winged_bean`；TFC 用 `tfc:food/winged_bean`） | 豆荚、秸秆、种子 → 饲料、堆肥、留种 | 种子 | 采种→晒干→筛选→浸种→直播 | 干燥→脱荚→浸泡→磨浆/煮制/发酵 | 豆制品、豆粉、豆酱、饲料 | P1 |
| 82 | `pigeon_pea` | A·豆类 | 干豆或鲜荚（`tfcfarmingplus:food/pigeon_pea`；TFC 用 `tfc:food/pigeon_pea`） | 豆荚、秸秆、种子 → 饲料、堆肥、留种 | 种子 | 采种→晒干→筛选→浸种→直播 | 干燥→脱荚→浸泡→磨浆/煮制/发酵 | 豆制品、豆粉、豆酱、饲料 | P1 |
| 83 | `sunflower` | A·油料 | 油籽 → 食用油（`tfcfarmingplus:food/sunflower` / 油料产物） | 油饼/粕 → 饲料、肥料；部分纤维/秸秆 | 种子 | 采种→晒干→筛选→直播 | 清理→炒/烘→磨→蒸→制饼→压榨→过滤 | 食用油、油饼饲料、调味油 | P1 |
| 84 | `hemp` | A·纤维 | 纤维 + 大麻籽油 | 麻屑/籽饼→饲料/建材/纸 | 种子 | 种子：采种→晒干→筛选→直播；无性：母株→扦插/分株→育苗→移栽 | 沤麻→打麻→梳麻→纺线；种子压榨 | 布、绳、纸、油 | P2 |
| 85 | `sorghum` | A·谷物/禾本 | 谷物籽粒（`tfcfarmingplus:food/sorghum`；TFC 用 `tfc:food/sorghum`） | 秸秆、糠/麸、种子 → 饲料、堆肥、燃料、留种 | 种子 | 采种→晒干→筛选→浸种/催芽（可选）→直播 | 脱粒→扬场→磨粉；麦类可制麦芽；稻类可碾米 | 面粉/米饭/麦芽/酿酒/饲料/燃料 | P1 |
| 86 | `sisal` | A·纤维 | 叶纤维 | 叶渣→堆肥/沼气 | 吸芽/分株 | 种子：采种→晒干→筛选→直播；无性：母株→扦插/分株→育苗→移栽 | 割叶→刮肉→晒干→梳麻→纺绳 | 绳、网、垫 | P2 |
| 87 | `strawberry` | A·浆果特例 | 浆果（`tfcfarmingplus:food/strawberry`） | 匍匐茎苗/种子；果渣 → 堆肥 | 匍匐茎分株为主，种子为辅 | 母株→匍匐茎苗→育苗→移栽 | 鲜食→果酱/果干/冰淇淋 | 鲜果、果酱、果干、甜点 | P1 |
| 88 | `alfalfa` | TFC·叶菜/饲草 | 饲草/种子 | 干草→饲料 | 种子 | 采种→晒干→筛选→直播 | 割草→晒干→打捆；种子清选 | 饲料、种子 | P1 |
| 89 | `barley` | TFC·谷物/禾本 | 谷物籽粒（`tfc:food/barley`；TFC 用 `tfc:food/barley`） | 秸秆、糠/麸、种子 → 饲料、堆肥、燃料、留种 | 种子 | 采种→晒干→筛选→浸种/催芽（可选）→直播 | 脱粒→扬场→磨粉；麦类可制麦芽；稻类可碾米 | 面粉/米饭/麦芽/酿酒/饲料/燃料 | P1 |
| 90 | `beet` | TFC·根/块茎/鳞茎 | 根/糖 | 叶/渣→饲料 | 种子（turnip/parsnip/celeriac/salsify/chicory/radish/carrot/beet）或块茎/鳞茎/根茎（其余） | 种子：采种→晒干→筛选→浸种→直播；块茎/鳞茎：愈伤→分级→直播 | 清洗→切片→煮/榨糖/腌渍 | 糖、蔬菜、饲料 | P1 |
| 91 | `cabbage` | TFC·叶菜/饲草 | 叶菜/饲草（TFC 现有产物） | 种子/秸秆 → 留种、饲料、堆肥 | 种子 | 采种→晒干→筛选→直播 | 切丝→盐渍→乳酸发酵→晒干 | 酸菜、泡菜、干菜 | P1 |
| 92 | `canola` | TFC·豆类/油料 | 油菜籽/菜籽油 | 豆荚/秸秆/油饼 → 饲料、堆肥 | 种子 | 采种→晒干→筛选→浸种→直播 | 干燥→清理→压榨→过滤 | 食用油、油饼饲料 | P1 |
| 93 | `carrot` | TFC·根/块茎/鳞茎 | 食用根/块茎/鳞茎，或淀粉/粉（`tfc:food/carrot`） | 茎叶/皮渣 → 饲料、堆肥；种薯/种球/种瓣留种 | 种子（turnip/parsnip/celeriac/salsify/chicory/radish/carrot/beet）或块茎/鳞茎/根茎（其余） | 种子：采种→晒干→筛选→浸种→直播；块茎/鳞茎：愈伤→分级→直播 | 清洗→去皮→切片→煮/晒干/腌渍 | 蔬菜、干菜 | P1 |
| 94 | `cassava` | TFC·根/块茎/鳞茎 | 食用根/块茎/鳞茎，或淀粉/粉（`tfc:food/cassava`） | 茎叶/皮渣 → 饲料、堆肥；种薯/种球/种瓣留种 | 茎段 | 种茎→切段→定植 | 去皮→磨浆→沉淀淀粉/发酵 | 淀粉、木薯粉 | P1 |
| 95 | `garlic` | TFC·根/块茎/鳞茎 | 食用根/块茎/鳞茎，或淀粉/粉（`tfc:food/garlic`） | 茎叶/皮渣 → 饲料、堆肥；种薯/种球/种瓣留种 | 蒜瓣 | 蒜瓣→分级→定植 | 干燥→去皮→切片→晒干/腌渍 | 调料、腌菜 | P1 |
| 96 | `green_bean` | TFC·豆类/油料 | 鲜荚/干豆 | 豆荚/秸秆/油饼 → 饲料、堆肥 | 种子 | 采种→晒干→筛选→浸种→直播 | 鲜食/晒干/脱荚 | 蔬菜、干豆 | P1 |
| 97 | `jute` | TFC·纤维 | 韧皮纤维 | 麻屑/种子→纸/饲料 | 种子 | 种子：采种→晒干→筛选→直播；无性：母株→扦插/分株→育苗→移栽 | 沤麻→打麻→梳麻→纺线/织袋 | 麻袋、绳、纸 | P2 |
| 98 | `lentil` | TFC·豆类/油料 | 干豆 | 豆荚/秸秆/油饼 → 饲料、堆肥 | 种子 | 采种→晒干→筛选→浸种→直播 | 干燥→脱荚→煮/磨粉 | 豆类、豆粉 | P1 |
| 99 | `maize` | TFC·谷物/禾本 | 谷物籽粒（`tfc:food/maize`；TFC 用 `tfc:food/maize`） | 秸秆、糠/麸、种子 → 饲料、堆肥、燃料、留种 | 种子 | 采种→晒干→筛选→浸种/催芽（可选）→直播 | 脱粒→扬场→磨粉；麦类可制麦芽；稻类可碾米 | 面粉/米饭/麦芽/酿酒/饲料/燃料 | P1 |
| 100 | `melon` | TFC·茄果/瓜类 | 果实；种子 | 瓜籽→炒制/榨油 | 种子；多数育苗后移栽 | 采种→晒干→筛选→浸种/催芽→育苗盘→移栽 | 鲜食/果酱；瓜籽洗净晒干 | 水果、籽油 | P1 |
| 101 | `oat` | TFC·谷物/禾本 | 谷物籽粒（`tfc:food/oat`；TFC 用 `tfc:food/oat`） | 秸秆、糠/麸、种子 → 饲料、堆肥、燃料、留种 | 种子 | 采种→晒干→筛选→浸种/催芽（可选）→直播 | 脱粒→扬场→磨粉；麦类可制麦芽；稻类可碾米 | 面粉/米饭/麦芽/酿酒/饲料/燃料 | P1 |
| 102 | `onion` | TFC·根/块茎/鳞茎 | 食用根/块茎/鳞茎，或淀粉/粉（`tfc:food/onion`） | 茎叶/皮渣 → 饲料、堆肥；种薯/种球/种瓣留种 | 种球/种子 | 种球→分级→定植；种子育苗 | 干燥→去皮→切片→晒干/腌渍 | 调料、腌菜 | P1 |
| 103 | `papyrus` | TFC·水生/纤维 | 纤维/纸 | 根茎/叶渣→堆肥 | 根茎/分株 | 母株→分株→浅水定植 | 割茎→剥皮→压片→晾干→纸 | 纸、编织 | P2 |
| 104 | `peanut` | TFC·豆类/油料 | 花生/花生油 | 豆荚/秸秆/油饼 → 饲料、堆肥 | 种子 | 采种→晒干→筛选→浸种→直播 | 干燥→脱壳→炒/压榨 | 坚果、油、花生酱 | P1 |
| 105 | `potato` | TFC·根/块茎/鳞茎 | 食用根/块茎/鳞茎，或淀粉/粉（`tfc:food/potato`） | 茎叶/皮渣 → 饲料、堆肥；种薯/种球/种瓣留种 | 种薯 | 种薯→催芽→切块→直播 | 清洗→去皮→煮/炸/淀粉 | 主食、淀粉 | P1 |
| 106 | `pumpkin` | TFC·茄果/瓜类 | 果实；种子 | 瓜籽→炒制/榨油；瓜肉→饲料 | 种子；多数育苗后移栽 | 采种→晒干→筛选→浸种/催芽→育苗盘→移栽 | 果实→煮/烤/熬酱；瓜籽洗净晒干 | 蔬菜、籽油、饲料 | P1 |
| 107 | `radish` | TFC·根/块茎/鳞茎 | 食用根/块茎/鳞茎，或淀粉/粉（`tfc:food/radish`） | 茎叶/皮渣 → 饲料、堆肥；种薯/种球/种瓣留种 | 种子（turnip/parsnip/celeriac/salsify/chicory/radish/carrot/beet）或块茎/鳞茎/根茎（其余） | 种子：采种→晒干→筛选→浸种→直播；块茎/鳞茎：愈伤→分级→直播 | 清洗→切片→腌渍/晒干 | 蔬菜、腌菜 | P1 |
| 108 | `red_bell_pepper` | TFC·茄果/瓜类 | 果实/蔬菜（`tfc:food/red_bell_pepper`） | 种子、果肉/瓜瓤 → 饲料/堆肥；loofah 纤维、bottle_gourd 容器、瓜籽油 | 种子；多数育苗后移栽 | 采种→晒干→筛选→浸种/催芽→育苗盘→移栽 | 鲜食→晒干→磨粉/烤制 | 蔬菜、香料 | P1 |
| 109 | `rice` | TFC·谷物/禾本 | 谷物籽粒（`tfc:food/rice`；TFC 用 `tfc:food/rice`） | 秸秆、糠/麸、种子 → 饲料、堆肥、燃料、留种 | 种子 | 采种→晒干→筛选→浸种/催芽（可选）→直播 | 脱粒→扬场→磨粉；麦类可制麦芽；稻类可碾米 | 面粉/米饭/麦芽/酿酒/饲料/燃料 | P1 |
| 110 | `rye` | TFC·谷物/禾本 | 谷物籽粒（`tfc:food/rye`；TFC 用 `tfc:food/rye`） | 秸秆、糠/麸、种子 → 饲料、堆肥、燃料、留种 | 种子 | 采种→晒干→筛选→浸种/催芽（可选）→直播 | 脱粒→扬场→磨粉；麦类可制麦芽；稻类可碾米 | 面粉/米饭/麦芽/酿酒/饲料/燃料 | P1 |
| 111 | `soybean` | TFC·豆类/油料 | 大豆 | 豆荚/秸秆/油饼 → 饲料、堆肥 | 种子 | 采种→晒干→筛选→浸种→直播 | 干燥→浸泡→磨浆→豆腐/豆酱/榨油 | 豆制品、油、饲料 | P1 |
| 112 | `squash` | TFC·茄果/瓜类 | 果实；种子 | 瓜籽→炒制/榨油；瓜肉→饲料 | 种子；多数育苗后移栽 | 采种→晒干→筛选→浸种/催芽→育苗盘→移栽 | 果实→煮/烤/熬酱；瓜籽洗净晒干 | 蔬菜、籽油、饲料 | P1 |
| 113 | `sugarcane` | TFC·谷物/禾本 | 甘蔗/糖 | 蔗渣→燃料/纸；糖蜜→发酵 | 蔗种/茎段 | 采种→晒干→筛选→浸种/催芽（可选）→直播 | 压榨→熬糖→糖蜜/朗姆 | 糖、糖蜜、酒 | P1 |
| 114 | `tomato` | TFC·茄果/瓜类 | 果实/蔬菜（`tfc:food/tomato`） | 种子、果肉/瓜瓤 → 饲料/堆肥；loofah 纤维、bottle_gourd 容器、瓜籽油 | 种子；多数育苗后移栽 | 采种→晒干→筛选→浸种/催芽→育苗盘→移栽 | 鲜食→晒干/熬酱/罐装 | 蔬菜、番茄酱、干番茄 | P1 |
| 115 | `wheat` | TFC·谷物/禾本 | 谷物籽粒（`tfc:food/wheat`；TFC 用 `tfc:food/wheat`） | 秸秆、糠/麸、种子 → 饲料、堆肥、燃料、留种 | 种子 | 采种→晒干→筛选→浸种/催芽（可选）→直播 | 脱粒→扬场→磨粉；麦类可制麦芽；稻类可碾米 | 面粉/米饭/麦芽/酿酒/饲料/燃料 | P1 |
| 116 | `yellow_bell_pepper` | TFC·茄果/瓜类 | 果实/蔬菜（`tfc:food/yellow_bell_pepper`） | 种子、果肉/瓜瓤 → 饲料/堆肥；loofah 纤维、bottle_gourd 容器、瓜籽油 | 种子；多数育苗后移栽 | 采种→晒干→筛选→浸种/催芽→育苗盘→移栽 | 鲜食→晒干→磨粉/烤制 | 蔬菜、香料 | P1 |

## 4. 培育/育秧专项计划
### 4.1 六环节（117 §6.8）
1. 留种/采种：有性（种子）+ 无性（块茎/鳞茎/根茎/扦插/分株/匍匐茎）；母株性状用 DataComponent 标记；
2. 育苗：育苗盘/苗床方块 + BE；温湿度影响成活；
3. 移栽：`in_world` 手持苗右键耕地，校验土壤/气候，缓苗期；
4. 生长管理：间苗、培土、搭架、打顶、除草、施肥；
5. 收获：主产品 + 次产品；未成熟破坏补偿；
6. 留种循环：成熟株留种/扦插闭环。
### 4.2 九道种子加工（126 §12.12）
采种 → 种子干燥 → 选种/筛种 → 浸种 → 催芽 → 拌种 → 扦插/分株 → 育苗 → 移栽。

### 4.3 作物繁殖方式分组
| 繁殖方式 | 作物 |
|---|---|
| 有性种子 | A:millet · A:foxtail_millet · A:buckwheat · A:fonio · A:spelt · A:emmer · A:einkorn · A:pearl_millet · A:amaranth · A:quinoa · A:finger_millet · A:jobs_tears · A:chickpea · A:faba_bean · A:lupin · A:adzuki · A:bambara_nut · A:fenugreek · A:flax · A:sesame · A:safflower · A:chili · A:eggplant · A:okra · A:cotton · A:water_caltrop · A:gorgon_nut · A:winter_melon · A:loofah · A:bitter_melon · A:snake_gourd · A:chayote · A:bottle_gourd · A:cantaloupe · A:agave · A:pea · A:cowpea · A:common_bean · A:winged_bean · A:pigeon_pea · A:sunflower · A:hemp · A:sorghum · TFC:alfalfa · TFC:barley · TFC:cabbage · TFC:canola · TFC:green_bean · TFC:jute · TFC:lentil · TFC:maize · TFC:melon · TFC:oat · TFC:peanut · TFC:pumpkin · TFC:red_bell_pepper · TFC:rice · TFC:rye · TFC:soybean · TFC:squash · TFC:tomato · TFC:wheat · TFC:yellow_bell_pepper |
| 块茎/鳞茎/根茎/种薯 | A:turnip · A:parsnip · A:sunchoke · A:shallot · A:celeriac · A:salsify · A:ginger · A:turmeric · A:chicory_root · A:water_chestnut · A:lotus · A:arrowhead · A:yam · TFC:beet · TFC:carrot · TFC:cassava · TFC:garlic · TFC:onion · TFC:potato · TFC:radish · TFC:sugarcane |
| 扦插/分株/匍匐茎/冠芽 | A:spinach · A:lettuce · A:celery · A:kale · A:napa_cabbage · A:mustard_greens · A:broccoli · A:cauliflower · A:brussels_sprouts · A:swiss_chard · A:celtuce · A:garland_chrysanthemum · A:perilla · A:arugula · A:yacon · A:ramie · A:asparagus · A:chive · A:rhubarb · A:artichoke · A:taro · A:wild_rice_stem · A:water_dropwort · A:water_spinach · A:hops · A:malabar_spinach · A:water_shield · A:cardoon · A:purslane · A:sisal · A:strawberry · TFC:papyrus |

## 5. 实施批次
| 批次 | 内容 | 验收 |
|---|---|---|
| P0 | 矩阵/ID/标签/产物映射；选 1 个物种打通全链 | 每个字段有值；无死端 |
| P1 | 种子处理（干燥/筛选/浸种/催芽/拌种）+ 育苗盘 + 移栽 | 6 环节可执行；缓苗/成活有数据 |
| P2 | 各族初步加工（脱粒/脱荚/磨粉/压榨/盐渍/发酵/晒干/沤麻） | 每族至少 1 条完整链；主+副产物 |
| P3 | 86+29 全作物覆盖与副产物出口 | 每个作物通过 §3 行验收 |
| P4 | TFC 29 的视觉/资源覆盖与 B 行为接入 | 不影响存档；掉落不减少 |

## 6. 每作物验收表
每个作物必须同时满足：
1. 主产品与副产品存在；
2. 繁殖方式明确（有性/无性）；
3. 育苗或种子处理路径明确；
4. 至少一条初步加工；
5. 至少一个出口；
6. 不减少原掉落；
7. 不出现“只有种子/只能生吃”的死端。

## 7. 未决问题
1. A 实际 87 种与文档 86 种的差异必须收敛（本计划按 87 列）。
2. TFC 29 与 A 87 是否共用同一套六环节，还是 TFC 29 只做资源覆盖。
3. 种子处理/育苗盘/移栽是 B 自有方块，还是扩展 TFC 作物行为；必须定 API。
4. TFC 种子是 TFC 物品，处理后的种子是 B 新物品还是 DataComponent；需定 ID/迁移。
5. “生产链”覆盖 86 还是 29+86，必须先定，否则无法排期。
6. 所有新产物/副产物必须有真实出口；不能为凑矩阵新增无用途物品。
