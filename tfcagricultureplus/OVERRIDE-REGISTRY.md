# 覆盖与跨命名空间文件台账

> 生成日期：2026-10-07。此表记录实际存在于两个项目资源目录、但不属于本模组命名空间的文件。代码独立实现规则不授权复制这些资源；每项仍需单独核对来源与许可。

## 当前摘要

| 所属 | 文件数 | 说明 |
|---|---:|---|
| A (`tfcfarmingplus`) | 217 | 既有接入、草莓盆栽桥接；10 种语言的草莓灌木手册覆盖及新增中英文草莓种植说明 |
| B (`tfcagricultureplus`) | 201 | 12份手册、1份Minecraft标签、184份TFC数据、4份公共标签；标签均使用追加语义 |
| **合计** | **418** | 2026-10-25 AR2-E扩大全部外部命名空间扫描后核实；先前230仅是漏扫范围内的数量 |

## 回滚规则

- 资源覆盖：移除台账中对应文件，邻居模组原文件恢复生效。
- 追加数据或标签：移除对应文件，不修改邻居 jar。
- B 自有方块、物品、方块实体和配方不属于本台账；卸载 B 可能使存档中的 B 独有内容丢失。
- 每次邻居模组升级后，重新运行 `tools/verify-coverage-ledger.ps1`，先处理新增同名冲突。

## 明细

| # | 所属 | 路径 | 类型 | 用途 | 回滚动作 |
|---:|---|---|---|---|---|
| 1 | A | `assets/tfc/models/block/crop/cabbage_age_0.json` | A resource override | TFC cabbage geometry sample | remove this file; neighbour content is restored |
| 2 | A | `assets/tfc/models/block/crop/cabbage_age_1.json` | A resource override | TFC cabbage geometry sample | remove this file; neighbour content is restored |
| 3 | A | `assets/tfc/models/block/crop/cabbage_age_2.json` | A resource override | TFC cabbage geometry sample | remove this file; neighbour content is restored |
| 4 | A | `assets/tfc/models/block/crop/cabbage_age_3.json` | A resource override | TFC cabbage geometry sample | remove this file; neighbour content is restored |
| 5 | A | `assets/tfc/models/block/crop/cabbage_age_4.json` | A resource override | TFC cabbage geometry sample | remove this file; neighbour content is restored |
| 6 | A | `assets/tfc/models/block/crop/cabbage_age_5.json` | A resource override | TFC cabbage geometry sample | remove this file; neighbour content is restored |
| 7 | A | `assets/tfc/patchouli_books/field_guide/en_us/categories/farming_plus.json` | A handbook override | TFC field guide entries for A content | remove this file; neighbour content is restored |
| 8 | A | `assets/tfc/patchouli_books/field_guide/en_us/entries/farming_plus/bushes.json` | A handbook override | TFC field guide entries for A content | remove this file; neighbour content is restored |
| 9 | A | `assets/tfc/patchouli_books/field_guide/en_us/entries/farming_plus/bushes_high.json` | A handbook override | TFC field guide entries for A content | remove this file; neighbour content is restored |
| 10 | A | `assets/tfc/patchouli_books/field_guide/en_us/entries/farming_plus/crops.json` | A handbook override | TFC field guide entries for A content | remove this file; neighbour content is restored |
| 11 | A | `assets/tfc/patchouli_books/field_guide/en_us/entries/farming_plus/fruit_trees.json` | A handbook override | TFC field guide entries for A content | remove this file; neighbour content is restored |
| 12 | A | `assets/tfc/patchouli_books/field_guide/en_us/entries/farming_plus/intro.json` | A handbook override | TFC field guide entries for A content | remove this file; neighbour content is restored |
| 13 | A | `assets/tfc/patchouli_books/field_guide/en_us/entries/farming_plus/wild_crops.json` | A handbook override | TFC field guide entries for A content | remove this file; neighbour content is restored |
| 14 | A | `assets/tfc/patchouli_books/field_guide/zh_cn/categories/farming_plus.json` | A handbook override | TFC field guide entries for A content | remove this file; neighbour content is restored |
| 15 | A | `assets/tfc/patchouli_books/field_guide/zh_cn/entries/farming_plus/bushes.json` | A handbook override | TFC field guide entries for A content | remove this file; neighbour content is restored |
| 16 | A | `assets/tfc/patchouli_books/field_guide/zh_cn/entries/farming_plus/bushes_high.json` | A handbook override | TFC field guide entries for A content | remove this file; neighbour content is restored |
| 17 | A | `assets/tfc/patchouli_books/field_guide/zh_cn/entries/farming_plus/crops.json` | A handbook override | TFC field guide entries for A content | remove this file; neighbour content is restored |
| 18 | A | `assets/tfc/patchouli_books/field_guide/zh_cn/entries/farming_plus/fruit_trees.json` | A handbook override | TFC field guide entries for A content | remove this file; neighbour content is restored |
| 19 | A | `assets/tfc/patchouli_books/field_guide/zh_cn/entries/farming_plus/intro.json` | A handbook override | TFC field guide entries for A content | remove this file; neighbour content is restored |
| 20 | A | `assets/tfc/patchouli_books/field_guide/zh_cn/entries/farming_plus/wild_crops.json` | A handbook override | TFC field guide entries for A content | remove this file; neighbour content is restored |
| 21 | A | `data/c/tags/item/foods/fruit.json` | additive neighbour tag | cross-mod classification or TFC recognition | remove this file; neighbour content is restored |
| 22 | A | `data/c/tags/item/foods/grain.json` | additive neighbour tag | cross-mod classification or TFC recognition | remove this file; neighbour content is restored |
| 23 | A | `data/c/tags/item/foods/vegetable.json` | additive neighbour tag | cross-mod classification or TFC recognition | remove this file; neighbour content is restored |
| 24 | A | `data/c/tags/item/seeds.json` | additive neighbour tag | cross-mod classification or TFC recognition | remove this file; neighbour content is restored |
| 25 | A | `data/firmalife/firmalife/plantable/adzuki.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 26 | A | `data/firmalife/firmalife/plantable/agave.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 27 | A | `data/firmalife/firmalife/plantable/amaranth.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 28 | A | `data/firmalife/firmalife/plantable/apricot.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 29 | A | `data/firmalife/firmalife/plantable/aronia.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 30 | A | `data/firmalife/firmalife/plantable/arrowhead.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 31 | A | `data/firmalife/firmalife/plantable/artichoke.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 32 | A | `data/firmalife/firmalife/plantable/arugula.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 33 | A | `data/firmalife/firmalife/plantable/asparagus.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 34 | A | `data/firmalife/firmalife/plantable/bambara_nut.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 35 | A | `data/firmalife/firmalife/plantable/bearberry.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 36 | A | `data/firmalife/firmalife/plantable/bilberry.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 37 | A | `data/firmalife/firmalife/plantable/bitter_melon.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 38 | A | `data/firmalife/firmalife/plantable/blackcurrant.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 39 | A | `data/firmalife/firmalife/plantable/broccoli.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 40 | A | `data/firmalife/firmalife/plantable/brussels_sprouts.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 41 | A | `data/firmalife/firmalife/plantable/buckwheat.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 42 | A | `data/firmalife/firmalife/plantable/cardoon.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 43 | A | `data/firmalife/firmalife/plantable/cauliflower.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 44 | A | `data/firmalife/firmalife/plantable/celeriac.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 45 | A | `data/firmalife/firmalife/plantable/celery.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 46 | A | `data/firmalife/firmalife/plantable/celtuce.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 47 | A | `data/firmalife/firmalife/plantable/chayote.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 48 | A | `data/firmalife/firmalife/plantable/chickpea.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 49 | A | `data/firmalife/firmalife/plantable/chicory_root.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 50 | A | `data/firmalife/firmalife/plantable/chili.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 51 | A | `data/firmalife/firmalife/plantable/chive.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 52 | A | `data/firmalife/firmalife/plantable/coffee.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 53 | A | `data/firmalife/firmalife/plantable/common_bean.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 54 | A | `data/firmalife/firmalife/plantable/cotton.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 55 | A | `data/firmalife/firmalife/plantable/cowpea.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 56 | A | `data/firmalife/firmalife/plantable/crabapple.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 57 | A | `data/firmalife/firmalife/plantable/crowberry.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 58 | A | `data/firmalife/firmalife/plantable/eggplant.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 59 | A | `data/firmalife/firmalife/plantable/einkorn.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 60 | A | `data/firmalife/firmalife/plantable/emmer.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 61 | A | `data/firmalife/firmalife/plantable/faba_bean.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 62 | A | `data/firmalife/firmalife/plantable/fenugreek.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 63 | A | `data/firmalife/firmalife/plantable/finger_millet.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 64 | A | `data/firmalife/firmalife/plantable/flax.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 65 | A | `data/firmalife/firmalife/plantable/fonio.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 66 | A | `data/firmalife/firmalife/plantable/foxtail_millet.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 67 | A | `data/firmalife/firmalife/plantable/fpt_almond.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 68 | A | `data/firmalife/firmalife/plantable/fpt_amla.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 69 | A | `data/firmalife/firmalife/plantable/fpt_apricot.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 70 | A | `data/firmalife/firmalife/plantable/fpt_avocado.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 71 | A | `data/firmalife/firmalife/plantable/fpt_bael.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 72 | A | `data/firmalife/firmalife/plantable/fpt_black_pepper.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 73 | A | `data/firmalife/firmalife/plantable/fpt_breadfruit.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 74 | A | `data/firmalife/firmalife/plantable/fpt_canistel.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 75 | A | `data/firmalife/firmalife/plantable/fpt_cherimoya.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 76 | A | `data/firmalife/firmalife/plantable/fpt_cornelian_cherry.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 77 | A | `data/firmalife/firmalife/plantable/fpt_crabapple.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 78 | A | `data/firmalife/firmalife/plantable/fpt_cupuacu.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 79 | A | `data/firmalife/firmalife/plantable/fpt_durian.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 80 | A | `data/firmalife/firmalife/plantable/fpt_grapefruit.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 81 | A | `data/firmalife/firmalife/plantable/fpt_guava.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 82 | A | `data/firmalife/firmalife/plantable/fpt_hawthorn.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 83 | A | `data/firmalife/firmalife/plantable/fpt_hazelnut.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 84 | A | `data/firmalife/firmalife/plantable/fpt_jabuticaba.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 85 | A | `data/firmalife/firmalife/plantable/fpt_jackfruit.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 86 | A | `data/firmalife/firmalife/plantable/fpt_jujube.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 87 | A | `data/firmalife/firmalife/plantable/fpt_kiwi.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 88 | A | `data/firmalife/firmalife/plantable/fpt_lime.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 89 | A | `data/firmalife/firmalife/plantable/fpt_longan.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 90 | A | `data/firmalife/firmalife/plantable/fpt_loquat.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 91 | A | `data/firmalife/firmalife/plantable/fpt_lychee.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 92 | A | `data/firmalife/firmalife/plantable/fpt_macadamia.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 93 | A | `data/firmalife/firmalife/plantable/fpt_mango.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 94 | A | `data/firmalife/firmalife/plantable/fpt_mangosteen.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 95 | A | `data/firmalife/firmalife/plantable/fpt_medlar.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 96 | A | `data/firmalife/firmalife/plantable/fpt_mulberry.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 97 | A | `data/firmalife/firmalife/plantable/fpt_papaya.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 98 | A | `data/firmalife/firmalife/plantable/fpt_pawpaw.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 99 | A | `data/firmalife/firmalife/plantable/fpt_pear.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 100 | A | `data/firmalife/firmalife/plantable/fpt_pecan.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 101 | A | `data/firmalife/firmalife/plantable/fpt_persimmon.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 102 | A | `data/firmalife/firmalife/plantable/fpt_pomegranate.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 103 | A | `data/firmalife/firmalife/plantable/fpt_quince.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 104 | A | `data/firmalife/firmalife/plantable/fpt_rambutan.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 105 | A | `data/firmalife/firmalife/plantable/fpt_sapodilla.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 106 | A | `data/firmalife/firmalife/plantable/fpt_sea_buckthorn.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 107 | A | `data/firmalife/firmalife/plantable/fpt_sorb.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 108 | A | `data/firmalife/firmalife/plantable/fpt_soursop.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 109 | A | `data/firmalife/firmalife/plantable/fpt_starfruit.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 110 | A | `data/firmalife/firmalife/plantable/fpt_tamarind.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 111 | A | `data/firmalife/firmalife/plantable/fpt_walnut.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 112 | A | `data/firmalife/firmalife/plantable/fpt_wampee.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 113 | A | `data/firmalife/firmalife/plantable/fpt_wax_apple.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 114 | A | `data/firmalife/firmalife/plantable/fpt_waxberry.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 115 | A | `data/firmalife/firmalife/plantable/garland_chrysanthemum.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 116 | A | `data/firmalife/firmalife/plantable/ginger.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 117 | A | `data/firmalife/firmalife/plantable/goji.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 118 | A | `data/firmalife/firmalife/plantable/gorgon_nut.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 119 | A | `data/firmalife/firmalife/plantable/haskap.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 120 | A | `data/firmalife/firmalife/plantable/hawthorn.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 121 | A | `data/firmalife/firmalife/plantable/hemp.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 122 | A | `data/firmalife/firmalife/plantable/hops.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 123 | A | `data/firmalife/firmalife/plantable/jobs_tears.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 124 | A | `data/firmalife/firmalife/plantable/jujube.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 125 | A | `data/firmalife/firmalife/plantable/kale.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 126 | A | `data/firmalife/firmalife/plantable/lettuce.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 127 | A | `data/firmalife/firmalife/plantable/lingonberry.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 128 | A | `data/firmalife/firmalife/plantable/loofah.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 129 | A | `data/firmalife/firmalife/plantable/loquat.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 130 | A | `data/firmalife/firmalife/plantable/lotus.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 131 | A | `data/firmalife/firmalife/plantable/lupin.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 132 | A | `data/firmalife/firmalife/plantable/malabar_spinach.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 133 | A | `data/firmalife/firmalife/plantable/medlar.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 134 | A | `data/firmalife/firmalife/plantable/millet.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 135 | A | `data/firmalife/firmalife/plantable/mulberry.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 136 | A | `data/firmalife/firmalife/plantable/mustard_greens.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 137 | A | `data/firmalife/firmalife/plantable/napa_cabbage.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 138 | A | `data/firmalife/firmalife/plantable/okra.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 139 | A | `data/firmalife/firmalife/plantable/parsnip.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 140 | A | `data/firmalife/firmalife/plantable/pawpaw.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 141 | A | `data/firmalife/firmalife/plantable/pea.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 142 | A | `data/firmalife/firmalife/plantable/pear.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 143 | A | `data/firmalife/firmalife/plantable/pearl_millet.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 144 | A | `data/firmalife/firmalife/plantable/perilla.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 145 | A | `data/firmalife/firmalife/plantable/persimmon.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 146 | A | `data/firmalife/firmalife/plantable/pigeon_pea.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 147 | A | `data/firmalife/firmalife/plantable/pomegranate.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 148 | A | `data/firmalife/firmalife/plantable/purslane.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 149 | A | `data/firmalife/firmalife/plantable/quince.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 150 | A | `data/firmalife/firmalife/plantable/quinoa.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 151 | A | `data/firmalife/firmalife/plantable/ramie.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 152 | A | `data/firmalife/firmalife/plantable/redcurrant.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 153 | A | `data/firmalife/firmalife/plantable/rhubarb.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 154 | A | `data/firmalife/firmalife/plantable/safflower.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 155 | A | `data/firmalife/firmalife/plantable/salsify.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 156 | A | `data/firmalife/firmalife/plantable/serviceberry.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 157 | A | `data/firmalife/firmalife/plantable/sesame.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 158 | A | `data/firmalife/firmalife/plantable/shallot.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 159 | A | `data/firmalife/firmalife/plantable/sisal.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 160 | A | `data/firmalife/firmalife/plantable/snake_gourd.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 161 | A | `data/firmalife/firmalife/plantable/sorghum.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 162 | A | `data/firmalife/firmalife/plantable/spelt.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 163 | A | `data/firmalife/firmalife/plantable/spinach.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 164 | A | `data/firmalife/firmalife/plantable/sunchoke.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 165 | A | `data/firmalife/firmalife/plantable/sunflower.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 166 | A | `data/firmalife/firmalife/plantable/swiss_chard.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 167 | A | `data/firmalife/firmalife/plantable/taro.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 168 | A | `data/firmalife/firmalife/plantable/tea.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 169 | A | `data/firmalife/firmalife/plantable/turmeric.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 170 | A | `data/firmalife/firmalife/plantable/turnip.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 171 | A | `data/firmalife/firmalife/plantable/water_caltrop.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 172 | A | `data/firmalife/firmalife/plantable/water_chestnut.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 173 | A | `data/firmalife/firmalife/plantable/water_dropwort.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 174 | A | `data/firmalife/firmalife/plantable/water_shield.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 175 | A | `data/firmalife/firmalife/plantable/water_spinach.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 176 | A | `data/firmalife/firmalife/plantable/wild_rice_stem.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 177 | A | `data/firmalife/firmalife/plantable/winged_bean.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 178 | A | `data/firmalife/firmalife/plantable/yacon.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 179 | A | `data/firmalife/firmalife/plantable/yam.json` | additive neighbour data | Firmalife planter bridge for A species | remove this file; neighbour content is restored |
| 180 | A | `data/firmalife/tags/block/buzzing_leaves.json` | additive neighbour tag | cross-mod classification or TFC recognition | remove this file; neighbour content is restored |
| 181 | A | `data/minecraft/tags/block/leaves.json` | additive neighbour tag | cross-mod classification or TFC recognition | remove this file; neighbour content is restored |
| 182 | A | `data/minecraft/tags/block/mineable/axe.json` | additive neighbour tag | cross-mod classification or TFC recognition | remove this file; neighbour content is restored |
| 183 | A | `data/minecraft/tags/block/mineable/hoe.json` | additive neighbour tag | cross-mod classification or TFC recognition | remove this file; neighbour content is restored |
| 184 | A | `data/minecraft/tags/item/leaves.json` | additive neighbour tag | cross-mod classification or TFC recognition | remove this file; neighbour content is restored |
| 185 | A | `data/tfc/tags/block/can_be_snow_piled.json` | additive neighbour tag | cross-mod classification or TFC recognition | remove this file; neighbour content is restored |
| 186 | A | `data/tfc/tags/block/crops.json` | additive neighbour tag | cross-mod classification or TFC recognition | remove this file; neighbour content is restored |
| 187 | A | `data/tfc/tags/block/fox_raidable.json` | additive neighbour tag | cross-mod classification or TFC recognition | remove this file; neighbour content is restored |
| 188 | A | `data/tfc/tags/block/fruit_tree_branches.json` | additive neighbour tag | cross-mod classification or TFC recognition | remove this file; neighbour content is restored |
| 189 | A | `data/tfc/tags/block/fruit_tree_leaves.json` | additive neighbour tag | cross-mod classification or TFC recognition | remove this file; neighbour content is restored |
| 190 | A | `data/tfc/tags/block/fruit_tree_saplings.json` | additive neighbour tag | cross-mod classification or TFC recognition | remove this file; neighbour content is restored |
| 191 | A | `data/tfc/tags/block/spreading_bushes.json` | additive neighbour tag | cross-mod classification or TFC recognition | remove this file; neighbour content is restored |
| 192 | A | `data/tfc/tags/block/spreading_bushes/living.json` | additive neighbour tag | cross-mod classification or TFC recognition | remove this file; neighbour content is restored |
| 193 | A | `data/tfc/tags/block/thorny_bushes.json` | additive neighbour tag | cross-mod classification or TFC recognition | remove this file; neighbour content is restored |
| 194 | A | `data/tfc/tags/item/wild_crops.json` | additive neighbour tag | cross-mod classification or TFC recognition | remove this file; neighbour content is restored |
| 195 | A | `data/tfc/tags/worldgen/placed_feature/feature/berry_bushes.json` | additive worldgen tag with targeted removal | append 12 project patches; remove only native strawberry bush patch | restore reviewed tag; deleting it also restores native strawberry generation |
| 196 | A | `data/tfc/tags/worldgen/placed_feature/feature/crops.json` | additive worldgen tag | include A configured features in TFC worldgen tags | remove this file; neighbour content is restored |
| 197 | A | `data/tfc/tags/worldgen/placed_feature/feature/fruit_trees.json` | additive worldgen tag | include A configured features in TFC worldgen tags | remove this file; neighbour content is restored |
| 198 | B | `data/minecraft/tags/block/mineable/axe.json` | additive neighbour tag | cross-mod classification or TFC recognition | remove this file; neighbour content is restored |
| 199 | A | `data/firmalife/firmalife/plantable/strawberry.json` | additive neighbour data | Firmalife planter bridge for A strawberry crop | remove this file; neighbour content is restored |
| 200 | A | `assets/tfc/patchouli_books/field_guide/en_us/entries/the_world/wild_fruits.json` | targeted neighbour book override | hide the disabled TFC strawberry bush entry while preserving the other TFC fruit entries | remove this file; the original TFC book entry is restored |
| 201 | A | `assets/tfc/patchouli_books/field_guide/zh_cn/entries/the_world/wild_fruits.json` | targeted neighbour book override | hide the disabled TFC strawberry bush entry while preserving the other TFC fruit entries | remove this file; the original TFC book entry is restored |
| 202 | B | `assets/tfc/patchouli_books/field_guide/en_us/categories/agriculture_plus_woodwork.json` | B handbook category override | add the independent B woodwork category to the TFC field guide | remove this file; the original book categories remain |
| 203 | B | `assets/tfc/patchouli_books/field_guide/en_us/entries/agriculture_plus_woodwork/intro.json` | B handbook entry override | document B-owned wood processing, timber piles and optional compatibility | remove this file; the original book entries remain |
| 204 | B | `assets/tfc/patchouli_books/field_guide/zh_cn/categories/agriculture_plus_woodwork.json` | B handbook category override | add the Chinese B woodwork category to the TFC field guide | remove this file; the original book categories remain |
| 205 | B | `assets/tfc/patchouli_books/field_guide/zh_cn/entries/agriculture_plus_woodwork/intro.json` | B handbook entry override | document B-owned wood processing, timber piles and optional compatibility | remove this file; the original book entries remain |
| 206 | B | `assets/tfc/patchouli_books/field_guide/en_us/categories/agriculture_plus_silkworm.json` | B handbook category override | add the C1 silkworm category to the TFC field guide | remove this file; the original book categories remain |
| 207 | B | `assets/tfc/patchouli_books/field_guide/en_us/entries/agriculture_plus_silkworm/intro.json` | B handbook entry override | document the C1 silkworm rack chain and TFC inventory contract | remove this file; the original book entries remain |
| 208 | B | `assets/tfc/patchouli_books/field_guide/zh_cn/categories/agriculture_plus_silkworm.json` | B handbook category override | add the Chinese C1 silkworm category to the TFC field guide | remove this file; the original book categories remain |
| 209 | B | `assets/tfc/patchouli_books/field_guide/zh_cn/entries/agriculture_plus_silkworm/intro.json` | B handbook entry override | document the Chinese C1 silkworm rack chain and TFC inventory contract | remove this file; the original book entries remain |
| 210 | B | `assets/tfc/patchouli_books/field_guide/en_us/categories/agriculture_plus_kitchen.json` | B handbook category override | add the K1 kitchen furniture category to the TFC field guide | remove this file; the original book categories remain |
| 211 | B | `assets/tfc/patchouli_books/field_guide/en_us/entries/agriculture_plus_kitchen/intro.json` | B handbook entry override | document the K1 furniture storage and crafting contract | remove this file; the original book entries remain |
| 212 | B | `assets/tfc/patchouli_books/field_guide/zh_cn/categories/agriculture_plus_kitchen.json` | B handbook category override | add the Chinese K1 kitchen furniture category to the TFC field guide | remove this file; the original book categories remain |
| 213 | B | `assets/tfc/patchouli_books/field_guide/zh_cn/entries/agriculture_plus_kitchen/intro.json` | B handbook entry override | document the Chinese K1 furniture storage and crafting contract | remove this file; the original book entries remain |

## A ↔ B 基础覆盖台账

| 项目 | 实际状态 | 证据/入口 |
|---|---|---|
| A 物种查询 | **已修正**：87 作物 + 49 树类 + 12 灌木 = 148 个代表物种；只读、惰性构建 | `tfcfarmingplus/.../common/api/SpeciesLookup.java`；代表 ID 为 `crop/*`、`plant/*_tree_sapling`、`plant/*_bush` |
| B 读取 A | **尚未接入业务调用**；当前仅通过构建依赖 A jar | `tfcagricultureplus/build.gradle.kts`、`neoforge.mods.toml` |
| B 方块登记 | **242 个**：案板 89、刀具架 34、石臼 15、木料件/木堆 104 | `common/registry/AgricultureBlocks.java`、`common/timber/TimberBlocks.java` |
| B 配方登记 | **12 条案板食品切割、239 条 in_world、1 条 mortar 联调** | `src/main/resources/data/tfcagricultureplus/recipe/` |
| 覆盖试点 | 草莓普通作物接管已实现；可可完整重制已在 B 侧完成；均不覆盖邻居命名空间 | docs/130 阶段 2 与 117 §5.2 |

## 本阶段结论

- 台账覆盖当前实际文件；新增草莓种植盆桥接已登记，台账以当前实际文件为准。
- `SpeciesLookup` 的入口语义已与 148 个代表物种契约一致；B 后续若读取 A，只能使用此只读接口和正式注册表。
- 草莓/可可以及其他覆盖内容仍按后续阶段单独设计，不在本阶段直接改邻居命名空间。

## AR1-A 草莓手册补全（2026-10-23）

既有第 200、201 项中英文 `wild_fruits.json` 已在此次施工前存在，但遗漏草莓日历行，且删除两页后没有重排冬青莓与蔓越莓的跳转页码。本批修复这两项，并补齐其余八种语言；新增独立的中英文草莓种植条目，将原版草莓果实和项目种子引向作物说明。覆盖只改手册资源，不修改第三方 JAR 或游戏业务代码。来源为当前 TFC 4.2.11 资源，指纹、允许路径、生成与校验方式见 `tfcfarmingplus/tools/strawberry-guide-policy.json` 及 219 号交接。

| # | 所属 | 路径 | 类型 | 目的 | 回滚 |
|---|---|---|---|---|---|
| 214 | A | `assets/tfc/patchouli_books/field_guide/tr_tr/entries/the_world/wild_fruits.json` | targeted neighbour book override | remove only the strawberry bush pages, calendar row and obsolete jumps; preserve Turkish content | remove this file; TFC book content returns |
| 215 | A | `assets/tfc/patchouli_books/field_guide/ja_jp/entries/the_world/wild_fruits.json` | targeted neighbour book override | remove only the strawberry bush pages, calendar row and obsolete jumps; preserve Japanese content | remove this file; TFC book content returns |
| 216 | A | `assets/tfc/patchouli_books/field_guide/uk_ua/entries/the_world/wild_fruits.json` | targeted neighbour book override | remove only the strawberry bush pages, calendar row and obsolete jumps; preserve Ukrainian content | remove this file; TFC book content returns |
| 217 | A | `assets/tfc/patchouli_books/field_guide/ru_ru/entries/the_world/wild_fruits.json` | targeted neighbour book override | remove only the strawberry bush pages, calendar row and obsolete jumps; preserve Russian content | remove this file; TFC book content returns |
| 218 | A | `assets/tfc/patchouli_books/field_guide/zh_hk/entries/the_world/wild_fruits.json` | targeted neighbour book override | remove only the strawberry bush pages, calendar row and obsolete jumps; preserve Hong Kong Chinese content | remove this file; TFC book content returns |
| 219 | A | `assets/tfc/patchouli_books/field_guide/ko_kr/entries/the_world/wild_fruits.json` | targeted neighbour book override | remove only the strawberry bush pages, calendar row and obsolete jumps; preserve Korean content | remove this file; TFC book content returns |
| 220 | A | `assets/tfc/patchouli_books/field_guide/pt_br/entries/the_world/wild_fruits.json` | targeted neighbour book override | remove only the strawberry bush pages, calendar row and obsolete jumps; preserve Brazilian Portuguese content | remove this file; TFC book content returns |
| 221 | A | `assets/tfc/patchouli_books/field_guide/zh_tw/entries/the_world/wild_fruits.json` | targeted neighbour book override | remove only the strawberry bush pages, calendar row and obsolete jumps; preserve Taiwan Chinese content | remove this file; TFC book content returns |
| 222 | A | `assets/tfc/patchouli_books/field_guide/en_us/entries/farming_plus/strawberry.json` | additive neighbour book entry | document the cultivated and wild crop; map canonical TFC fruit and project seed to the crop guide | remove this file and restore the previous item-jump policy |
| 223 | A | `assets/tfc/patchouli_books/field_guide/zh_cn/entries/farming_plus/strawberry.json` | additive neighbour book entry | document the cultivated and wild crop in Chinese; map canonical TFC fruit and project seed to the crop guide | remove this file and restore the previous item-jump policy |
| 224 | A | `data/c/tags/item/foods.json` | additive food tag | append reviewed nut group to native food/meal entry; keep existing members | remove this file; native tag members remain |
| 225 | A | `data/tfc/tags/item/usable_in_soup.json` | additive food tag | append reviewed nut group to native food/meal entry; keep existing members | remove this file; native tag members remain |
| 226 | A | `data/tfc/tags/item/usable_in_salad.json` | additive food tag | append reviewed nut group to native food/meal entry; keep existing members | remove this file; native tag members remain |
| 227 | A | `data/tfc/tags/item/usable_in_sandwich.json` | additive food tag | append reviewed nut group to native food/meal entry; keep existing members | remove this file; native tag members remain |

## AR1-B 既有覆盖内容修订（2026-10-23）

本批不新增跨命名空间路径，台账仍为 A 210、B 13、合计 223。既有 `fpt_cupuacu.json` 盆栽桥接改产 `firmalife:food/cocoa_beans`；既有中英文 `farming_plus/fruit_trees.json` 仅修正大花可可的采收说明、展示与退休果实映射。源文件、兼容处理、生成器输出限制、检查与回滚证据见 220 号交接。基础可可加工继续归 Firmalife，B 发酵中间物继续保留。

## AR1-C 既有采收说明修订（2026-10-23）

本批只修改既有中英文 `farming_plus/crops.json` 的七种可采摘作物操作说明，共 14 页，明确空手右键采摘保留植株与破坏拔除的区别。页面数量、跳转和其他内容保留，没有新增跨命名空间路径；合计仍为 223。审查矩阵、工具和交付记录见 221 号交接。

## AR1-D 既有高秆作物说明修订（2026-10-23）

本批继续修改既有中英文 `farming_plus/crops.json`，共27＋27个双格/攀爬物种文字页，修正形态、上方空间、右键下半株搭架和破坏采收说明。页数、锚点、顺序、跳转及所有非文字字段不变，没有新增跨命名空间路径，台账仍为223项。游戏修复、生成器草稿核对、未通过的既有透明PNG体检项及交付证据见222号交接。B代码和JAR未修改。

## AR1-E 既有水生作物说明修订（2026-10-23）

本批修改既有中英文 `farming_plus/crops.json` 和 `farming_plus/wild_crops.json`，四份文件各10个文字页，说明先开垦、备好淡水水源再播种，以及野生浅水条件。页数、锚点、跳转和非文字字段不变，跨命名空间路径不新增，台账仍为223项。A命名空间内的20份单株生成数据另按223号交接记录；B代码和JAR未修改。

## AR1-F 整瓜流程说明及既有分类标签修订（2026-10-23）

既有中英文 `farming_plus/crops.json` 共六个文字页改为“收回整瓜、已有案板一瓜四片、继承新鲜度”，页数、跳转和其他字段不变。既有A资源 `data/c/tags/item/foods/fruit.json` 仅追加三种切片；仍为追加合并，不新增跨命名空间路径，台账保持223项。A整瓜食品、掉落与实体修复见224号交接；B三份案板配方只读核对，B代码和JAR未改。

## AR1-G 莲座六龄与结果态说明修订（2026-10-23）

既有中英文farming_plus/crops.json各修改五个文字页和五个图示页，共20页。图示明确六个未结果阶段及最终结果态；操作说明同步侧芽返种、死亡即时掉落和剑麻材料属性。页数、锚点、顺序及跳转保留，图示mapping有意更新。没有新增跨命名空间路径，台账仍为223项。详见225号交接；B资源/代码/JAR未改。

## AR3-A 既有果树说明与水果分类修订（2026-10-23）

A既有中英文farming_plus/fruit_trees.json各修订14个温带文字页，共28页，说明实际等待提示、季节条件和花果月份；页数、图示与跳转保持原值。既有data/c/tags/item/foods/fruit.json在原13项之后追加14种温带果实，保持replace:false。无新增跨命名空间路径，仍为223项。共享Java修复、独立实现说明和实机清单见226号交接；B源码/资源/JAR未改，整派复数标签引用登记AR2-A。

## AR2-A 既有厨房手册与草稿回退修订（2026-10-23）

B既有中英文agriculture_plus_kitchen/intro.json各在原五页之后追加水果整派页，补整派和切片的页码映射，旧页内容保留。A水果活动标签未改，只有gen-tags模板移除退休项目草莓的草稿条目；成员语义集合已与活动源27项对齐。无新增跨命名空间路径，台账仍为223项。B自身命名空间新增整派食品定义并修配方/食品记录，详见227号交接；本批B JAR哈希已更新。

## AR3-B 既有热带果树说明与水果分类修订（2026-10-23）

A既有中英文farming_plus/fruit_trees.json各修订14个热带文字页，原98页结构、图示、锚点和跳转保留；既有data/c/tags/item/foods/fruit.json追加14种热带果实，共41项，replace:false不变。无新增跨命名空间路径，台账仍223项。自然初始生长桥接、独立实现来源和生成/实机证据见228号交接；B代码、资源和AR2-A JAR版本不变。

## AR3-C 坚果用途接入（2026-10-24）

A新增四份邻居标签：c:foods及TFC汤/沙拉/三明治可用配料，均replace:false，仅引用项目自有foods/nuts分类；不覆盖邻居原成员。新增五种坚果分类属于A自身命名空间，不计入本表。A当前214项，B仍13项，合计227项。既有中英文fruit_trees各改五个坚果文字页，页数/图示/跳转不变。食品数值与Java未改，详见229号交接。

## AR3-D 既有树干结果说明与水果分类（2026-10-24）

A既有中英文fruit_trees各改六个树干结果文字页，图示/跳转/98页结构保留；既有c:foods/fruit追加五种普通枝干果实，成员共46项，replace:false。无新增跨命名空间路径，台账仍A214＋B13＝227项。六份枝干掉落表属于A自身命名空间。可可策略及共享代码修复见230号交接；B游戏代码、资源与JAR未改。

## AR3-E 其余果树及黑胡椒说明（2026-10-24）

A既有中英文fruit_trees各修改九个文字页，合计18页；98页结构、图示、锚点和跳转不变。既有c:foods/fruit追加八种普通果实，46→54项，replace:false；黑胡椒不追加此水果加工标签，沿用现有B调味链。黑胡椒成熟枝掉落属于A自身命名空间。没有新增跨命名空间路径，仍A214＋B13＝227项。B游戏代码、资源和JAR不变。详细证据、兼容边界与待实机项目见231号交接。

## AR3-F 灌木和自然生成标签（2026-10-24）

既有berry_bushes标签由replace:true整表覆盖改为replace:false追加12种项目灌木，仅通过NeoForge remove移除tfc:plant/strawberry_bush_patch；保留TFC、Firmalife及其他相邻标签成员。此标签仍是原表195号路径，没有增加覆盖路径，总数仍A214＋B13＝227。中英文bushes/bushes_high四文件各修订简介及各物种文字，共28页；原页数、日历、图示、锚点与跳转保持。具体语义、数据包优先级边界及待实机项目见234号交接。B游戏代码、资源及JAR不改。

## AR2-B 整瓜堆肥入口与养分说明（2026-10-24）

A新增一份原生高档绿料追加标签，replace:false，仅加入冬瓜、葫芦和哈密瓜整瓜。现有中英文farming_plus/intro各由1页增至3页，保留原简介索引并增加养分和堆肥页，同时修正总作物数和果实采收位置描述。台账增至A215＋B13＝228；B游戏代码、资源和JAR未改。见235号交接。

| # | 所属 | 路径 | 类型 | 用途 | 回滚动作 |
|---:|---|---|---|---|---|
| 228 | A | `data/tfc/tags/item/compost_greens/high.json` | additive compost tag | accept three project whole melons as native high green compost material | remove this file to remove the added whole-melon compost inputs |

## AR2-C 非食品农业材料接入（2026-10-25）

A新增两份TFC堆肥追加标签：四种现有麻纤维及棉铃为高档棕料，啤酒花为低档绿料，均replace:false。植物纤维分类属于A自身命名空间，三份新加工配方属于B自身命名空间，不计入本表。既有中英文farming_plus/intro保留前三页并各追加材料用途页。总数A217＋B13＝230。B仅新增原生织机/合成配方，不新增或覆写原生物品、设备及配方ID；详见236号交接。

| # | 所属 | 路径 | 类型 | 用途 | 回滚动作 |
|---:|---|---|---|---|---|
| 229 | A | `data/tfc/tags/item/compost_browns/high.json` | additive compost tag | four harvested plant fibers and cotton bolls as high brown compost material | remove this file to remove the added material compost inputs |
| 230 | A | `data/tfc/tags/item/compost_greens/low.json` | additive compost tag | existing hops as low green compost material | remove this file to remove the added hops compost input |

## AR2-D 谷物分类、加工和搅拌碗食品历史（2026-10-25）

既有A的c:foods/grain与vegetable移正高粱分类，中英文intro各追加两页，均为既有覆盖路径。B三份新手磨配方及13份原有面团配方使用自有命名空间；新增序列化器仍继承原生RecipeType与JEI入口，不覆盖第三方配方。总数仍A217＋B13＝230。没有新增物品、基础面团或世界NBT；成对部署和待实机清单见237号交接。

## AR2-E 分类、基础用途与台账漏扫更正（2026-10-25）

A现有低档绿料标签追加茶叶、咖啡豆，并追加中英文两页用途说明。B新增公共蔬菜标签，接回姜片、姜黄片、白菜丝的原生餐食/堆肥候选用途。没有改动旧食品、木工配方或注册。

旧检查只扫描B的assets/tfc与data/minecraft，漏掉既有184份data/tfc和3份data/c；历史“230与全部资源一致”结论作废，旧记录保留供追溯。本次登记187份既有漏项和1份新标签，实际A217＋B201＝418份；不能把187份历史漏项写成新覆盖。本检查改为扫描两模组assets/data下全部非自身命名空间，纳入构建入口。下表对既有漏项的回滚说明仅解释影响，并非要求删除用户已验收的木工内容。

| # | 所属 | 路径 | 类型 | 用途 | 回滚动作 |
|---:|---|---|---|---|---|
| 231 | B | `data/c/tags/item/foods.json` | existing additive tag | previously omitted existing B public or TFC tag | historical file: removing it undoes existing B integration; preserve during AR2-E rollback |
| 232 | B | `data/c/tags/item/foods/bread.json` | existing additive tag | previously omitted existing B public or TFC tag | historical file: removing it undoes existing B integration; preserve during AR2-E rollback |
| 233 | B | `data/c/tags/item/foods/dough.json` | existing additive tag | previously omitted existing B public or TFC tag | historical file: removing it undoes existing B integration; preserve during AR2-E rollback |
| 234 | B | `data/c/tags/item/foods/vegetable.json` | additive food tag | three existing prepared vegetables retain native meal and compost entry | remove this new tag to undo AR2-E prepared vegetable classification |
| 235 | B | `data/tfc/recipe/crafting/wood/fence/acacia.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 236 | B | `data/tfc/recipe/crafting/wood/fence/ash.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 237 | B | `data/tfc/recipe/crafting/wood/fence/aspen.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 238 | B | `data/tfc/recipe/crafting/wood/fence/birch.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 239 | B | `data/tfc/recipe/crafting/wood/fence/blackwood.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 240 | B | `data/tfc/recipe/crafting/wood/fence/chestnut.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 241 | B | `data/tfc/recipe/crafting/wood/fence/douglas_fir.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 242 | B | `data/tfc/recipe/crafting/wood/fence/hickory.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 243 | B | `data/tfc/recipe/crafting/wood/fence/kapok.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 244 | B | `data/tfc/recipe/crafting/wood/fence/mangrove.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 245 | B | `data/tfc/recipe/crafting/wood/fence/maple.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 246 | B | `data/tfc/recipe/crafting/wood/fence/oak.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 247 | B | `data/tfc/recipe/crafting/wood/fence/palm.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 248 | B | `data/tfc/recipe/crafting/wood/fence/pine.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 249 | B | `data/tfc/recipe/crafting/wood/fence/rosewood.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 250 | B | `data/tfc/recipe/crafting/wood/fence/sequoia.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 251 | B | `data/tfc/recipe/crafting/wood/fence/spruce.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 252 | B | `data/tfc/recipe/crafting/wood/fence/sycamore.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 253 | B | `data/tfc/recipe/crafting/wood/fence/white_cedar.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 254 | B | `data/tfc/recipe/crafting/wood/fence/willow.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 255 | B | `data/tfc/recipe/crafting/wood/log_fence/acacia.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 256 | B | `data/tfc/recipe/crafting/wood/log_fence/ash.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 257 | B | `data/tfc/recipe/crafting/wood/log_fence/aspen.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 258 | B | `data/tfc/recipe/crafting/wood/log_fence/birch.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 259 | B | `data/tfc/recipe/crafting/wood/log_fence/blackwood.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 260 | B | `data/tfc/recipe/crafting/wood/log_fence/chestnut.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 261 | B | `data/tfc/recipe/crafting/wood/log_fence/douglas_fir.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 262 | B | `data/tfc/recipe/crafting/wood/log_fence/hickory.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 263 | B | `data/tfc/recipe/crafting/wood/log_fence/kapok.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 264 | B | `data/tfc/recipe/crafting/wood/log_fence/mangrove.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 265 | B | `data/tfc/recipe/crafting/wood/log_fence/maple.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 266 | B | `data/tfc/recipe/crafting/wood/log_fence/oak.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 267 | B | `data/tfc/recipe/crafting/wood/log_fence/palm.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 268 | B | `data/tfc/recipe/crafting/wood/log_fence/pine.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 269 | B | `data/tfc/recipe/crafting/wood/log_fence/rosewood.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 270 | B | `data/tfc/recipe/crafting/wood/log_fence/sequoia.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 271 | B | `data/tfc/recipe/crafting/wood/log_fence/spruce.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 272 | B | `data/tfc/recipe/crafting/wood/log_fence/sycamore.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 273 | B | `data/tfc/recipe/crafting/wood/log_fence/white_cedar.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 274 | B | `data/tfc/recipe/crafting/wood/log_fence/willow.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 275 | B | `data/tfc/recipe/crafting/wood/lumber/acacia_from_logs.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 276 | B | `data/tfc/recipe/crafting/wood/lumber/acacia_from_planks.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 277 | B | `data/tfc/recipe/crafting/wood/lumber/ash_from_logs.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 278 | B | `data/tfc/recipe/crafting/wood/lumber/ash_from_planks.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 279 | B | `data/tfc/recipe/crafting/wood/lumber/aspen_from_logs.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 280 | B | `data/tfc/recipe/crafting/wood/lumber/aspen_from_planks.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 281 | B | `data/tfc/recipe/crafting/wood/lumber/birch_from_logs.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 282 | B | `data/tfc/recipe/crafting/wood/lumber/birch_from_planks.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 283 | B | `data/tfc/recipe/crafting/wood/lumber/blackwood_from_logs.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 284 | B | `data/tfc/recipe/crafting/wood/lumber/blackwood_from_planks.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 285 | B | `data/tfc/recipe/crafting/wood/lumber/chestnut_from_logs.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 286 | B | `data/tfc/recipe/crafting/wood/lumber/chestnut_from_planks.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 287 | B | `data/tfc/recipe/crafting/wood/lumber/douglas_fir_from_logs.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 288 | B | `data/tfc/recipe/crafting/wood/lumber/douglas_fir_from_planks.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 289 | B | `data/tfc/recipe/crafting/wood/lumber/hickory_from_logs.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 290 | B | `data/tfc/recipe/crafting/wood/lumber/hickory_from_planks.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 291 | B | `data/tfc/recipe/crafting/wood/lumber/kapok_from_logs.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 292 | B | `data/tfc/recipe/crafting/wood/lumber/kapok_from_planks.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 293 | B | `data/tfc/recipe/crafting/wood/lumber/mangrove_from_logs.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 294 | B | `data/tfc/recipe/crafting/wood/lumber/mangrove_from_planks.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 295 | B | `data/tfc/recipe/crafting/wood/lumber/maple_from_logs.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 296 | B | `data/tfc/recipe/crafting/wood/lumber/maple_from_planks.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 297 | B | `data/tfc/recipe/crafting/wood/lumber/oak_from_logs.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 298 | B | `data/tfc/recipe/crafting/wood/lumber/oak_from_planks.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 299 | B | `data/tfc/recipe/crafting/wood/lumber/palm_from_logs.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 300 | B | `data/tfc/recipe/crafting/wood/lumber/palm_from_planks.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 301 | B | `data/tfc/recipe/crafting/wood/lumber/pine_from_logs.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 302 | B | `data/tfc/recipe/crafting/wood/lumber/pine_from_planks.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 303 | B | `data/tfc/recipe/crafting/wood/lumber/rosewood_from_logs.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 304 | B | `data/tfc/recipe/crafting/wood/lumber/rosewood_from_planks.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 305 | B | `data/tfc/recipe/crafting/wood/lumber/sequoia_from_logs.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 306 | B | `data/tfc/recipe/crafting/wood/lumber/sequoia_from_planks.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 307 | B | `data/tfc/recipe/crafting/wood/lumber/spruce_from_logs.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 308 | B | `data/tfc/recipe/crafting/wood/lumber/spruce_from_planks.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 309 | B | `data/tfc/recipe/crafting/wood/lumber/sycamore_from_logs.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 310 | B | `data/tfc/recipe/crafting/wood/lumber/sycamore_from_planks.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 311 | B | `data/tfc/recipe/crafting/wood/lumber/white_cedar_from_logs.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 312 | B | `data/tfc/recipe/crafting/wood/lumber/white_cedar_from_planks.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 313 | B | `data/tfc/recipe/crafting/wood/lumber/willow_from_logs.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 314 | B | `data/tfc/recipe/crafting/wood/lumber/willow_from_planks.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 315 | B | `data/tfc/recipe/crafting/wood/planks/acacia_slab.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 316 | B | `data/tfc/recipe/crafting/wood/planks/acacia_stairs.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 317 | B | `data/tfc/recipe/crafting/wood/planks/ash_slab.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 318 | B | `data/tfc/recipe/crafting/wood/planks/ash_stairs.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 319 | B | `data/tfc/recipe/crafting/wood/planks/aspen_slab.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 320 | B | `data/tfc/recipe/crafting/wood/planks/aspen_stairs.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 321 | B | `data/tfc/recipe/crafting/wood/planks/birch_slab.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 322 | B | `data/tfc/recipe/crafting/wood/planks/birch_stairs.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 323 | B | `data/tfc/recipe/crafting/wood/planks/blackwood_slab.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 324 | B | `data/tfc/recipe/crafting/wood/planks/blackwood_stairs.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 325 | B | `data/tfc/recipe/crafting/wood/planks/chestnut_slab.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 326 | B | `data/tfc/recipe/crafting/wood/planks/chestnut_stairs.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 327 | B | `data/tfc/recipe/crafting/wood/planks/douglas_fir_slab.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 328 | B | `data/tfc/recipe/crafting/wood/planks/douglas_fir_stairs.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 329 | B | `data/tfc/recipe/crafting/wood/planks/hickory_slab.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 330 | B | `data/tfc/recipe/crafting/wood/planks/hickory_stairs.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 331 | B | `data/tfc/recipe/crafting/wood/planks/kapok_slab.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 332 | B | `data/tfc/recipe/crafting/wood/planks/kapok_stairs.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 333 | B | `data/tfc/recipe/crafting/wood/planks/mangrove_slab.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 334 | B | `data/tfc/recipe/crafting/wood/planks/mangrove_stairs.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 335 | B | `data/tfc/recipe/crafting/wood/planks/maple_slab.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 336 | B | `data/tfc/recipe/crafting/wood/planks/maple_stairs.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 337 | B | `data/tfc/recipe/crafting/wood/planks/oak_slab.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 338 | B | `data/tfc/recipe/crafting/wood/planks/oak_stairs.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 339 | B | `data/tfc/recipe/crafting/wood/planks/palm_slab.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 340 | B | `data/tfc/recipe/crafting/wood/planks/palm_stairs.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 341 | B | `data/tfc/recipe/crafting/wood/planks/pine_slab.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 342 | B | `data/tfc/recipe/crafting/wood/planks/pine_stairs.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 343 | B | `data/tfc/recipe/crafting/wood/planks/rosewood_slab.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 344 | B | `data/tfc/recipe/crafting/wood/planks/rosewood_stairs.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 345 | B | `data/tfc/recipe/crafting/wood/planks/sequoia_slab.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 346 | B | `data/tfc/recipe/crafting/wood/planks/sequoia_stairs.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 347 | B | `data/tfc/recipe/crafting/wood/planks/spruce_slab.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 348 | B | `data/tfc/recipe/crafting/wood/planks/spruce_stairs.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 349 | B | `data/tfc/recipe/crafting/wood/planks/sycamore_slab.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 350 | B | `data/tfc/recipe/crafting/wood/planks/sycamore_stairs.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 351 | B | `data/tfc/recipe/crafting/wood/planks/white_cedar_slab.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 352 | B | `data/tfc/recipe/crafting/wood/planks/white_cedar_stairs.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 353 | B | `data/tfc/recipe/crafting/wood/planks/willow_slab.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 354 | B | `data/tfc/recipe/crafting/wood/planks/willow_stairs.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 355 | B | `data/tfc/recipe/crafting/wood/support/acacia.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 356 | B | `data/tfc/recipe/crafting/wood/support/ash.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 357 | B | `data/tfc/recipe/crafting/wood/support/aspen.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 358 | B | `data/tfc/recipe/crafting/wood/support/birch.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 359 | B | `data/tfc/recipe/crafting/wood/support/blackwood.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 360 | B | `data/tfc/recipe/crafting/wood/support/chestnut.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 361 | B | `data/tfc/recipe/crafting/wood/support/douglas_fir.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 362 | B | `data/tfc/recipe/crafting/wood/support/hickory.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 363 | B | `data/tfc/recipe/crafting/wood/support/kapok.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 364 | B | `data/tfc/recipe/crafting/wood/support/mangrove.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 365 | B | `data/tfc/recipe/crafting/wood/support/maple.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 366 | B | `data/tfc/recipe/crafting/wood/support/oak.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 367 | B | `data/tfc/recipe/crafting/wood/support/palm.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 368 | B | `data/tfc/recipe/crafting/wood/support/pine.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 369 | B | `data/tfc/recipe/crafting/wood/support/rosewood.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 370 | B | `data/tfc/recipe/crafting/wood/support/sequoia.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 371 | B | `data/tfc/recipe/crafting/wood/support/spruce.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 372 | B | `data/tfc/recipe/crafting/wood/support/sycamore.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 373 | B | `data/tfc/recipe/crafting/wood/support/white_cedar.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 374 | B | `data/tfc/recipe/crafting/wood/support/willow.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 375 | B | `data/tfc/recipe/crafting/wood/trapdoor/acacia.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 376 | B | `data/tfc/recipe/crafting/wood/trapdoor/ash.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 377 | B | `data/tfc/recipe/crafting/wood/trapdoor/aspen.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 378 | B | `data/tfc/recipe/crafting/wood/trapdoor/birch.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 379 | B | `data/tfc/recipe/crafting/wood/trapdoor/blackwood.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 380 | B | `data/tfc/recipe/crafting/wood/trapdoor/chestnut.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 381 | B | `data/tfc/recipe/crafting/wood/trapdoor/douglas_fir.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 382 | B | `data/tfc/recipe/crafting/wood/trapdoor/hickory.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 383 | B | `data/tfc/recipe/crafting/wood/trapdoor/kapok.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 384 | B | `data/tfc/recipe/crafting/wood/trapdoor/mangrove.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 385 | B | `data/tfc/recipe/crafting/wood/trapdoor/maple.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 386 | B | `data/tfc/recipe/crafting/wood/trapdoor/oak.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 387 | B | `data/tfc/recipe/crafting/wood/trapdoor/palm.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 388 | B | `data/tfc/recipe/crafting/wood/trapdoor/pine.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 389 | B | `data/tfc/recipe/crafting/wood/trapdoor/rosewood.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 390 | B | `data/tfc/recipe/crafting/wood/trapdoor/sequoia.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 391 | B | `data/tfc/recipe/crafting/wood/trapdoor/spruce.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 392 | B | `data/tfc/recipe/crafting/wood/trapdoor/sycamore.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 393 | B | `data/tfc/recipe/crafting/wood/trapdoor/white_cedar.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 394 | B | `data/tfc/recipe/crafting/wood/trapdoor/willow.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 395 | B | `data/tfc/recipe/crafting/wood/wood/acacia.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 396 | B | `data/tfc/recipe/crafting/wood/wood/ash.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 397 | B | `data/tfc/recipe/crafting/wood/wood/aspen.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 398 | B | `data/tfc/recipe/crafting/wood/wood/birch.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 399 | B | `data/tfc/recipe/crafting/wood/wood/blackwood.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 400 | B | `data/tfc/recipe/crafting/wood/wood/chestnut.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 401 | B | `data/tfc/recipe/crafting/wood/wood/douglas_fir.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 402 | B | `data/tfc/recipe/crafting/wood/wood/hickory.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 403 | B | `data/tfc/recipe/crafting/wood/wood/kapok.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 404 | B | `data/tfc/recipe/crafting/wood/wood/mangrove.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 405 | B | `data/tfc/recipe/crafting/wood/wood/maple.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 406 | B | `data/tfc/recipe/crafting/wood/wood/oak.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 407 | B | `data/tfc/recipe/crafting/wood/wood/palm.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 408 | B | `data/tfc/recipe/crafting/wood/wood/pine.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 409 | B | `data/tfc/recipe/crafting/wood/wood/rosewood.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 410 | B | `data/tfc/recipe/crafting/wood/wood/sequoia.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 411 | B | `data/tfc/recipe/crafting/wood/wood/spruce.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 412 | B | `data/tfc/recipe/crafting/wood/wood/sycamore.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 413 | B | `data/tfc/recipe/crafting/wood/wood/white_cedar.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 414 | B | `data/tfc/recipe/crafting/wood/wood/willow.json` | existing recipe disable | existing false-condition file disables upstream wood crafting; B provides independent woodworking | historical file: removing it restores the upstream recipe; preserve during AR2-E rollback |
| 415 | B | `data/tfc/recipe/heating/sawdust_bread.json` | existing foreign recipe addition | existing sawdust food recipe in the TFC namespace; no same-path upstream recipe | historical file: removing it removes the existing sawdust recipe; preserve during AR2-E rollback |
| 416 | B | `data/tfc/recipe/pot/sawdust_bread.json` | existing foreign recipe addition | existing sawdust food recipe in the TFC namespace; no same-path upstream recipe | historical file: removing it removes the existing sawdust recipe; preserve during AR2-E rollback |
| 417 | B | `data/tfc/tags/item/compost_browns/low.json` | existing additive tag | previously omitted existing B public or TFC tag | historical file: removing it undoes existing B integration; preserve during AR2-E rollback |
| 418 | B | `data/tfc/tags/item/firepit_fuel.json` | existing additive tag | previously omitted existing B public or TFC tag | historical file: removing it undoes existing B integration; preserve during AR2-E rollback |
