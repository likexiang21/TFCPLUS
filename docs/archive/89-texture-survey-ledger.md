# 89 · 贴图全量视觉验收台账

> **目的**：给「657 张全部视觉过一遍」留下**逐页可查的证据**，并把「哪些是废稿、哪些已合格」写死，
> 避免下一轮重复劳动或漏修。
>
> **方法**（判据 0：实际视觉反馈是第一标准）：
> 1. `contact.ps1 -Dir <src> -Filter '*.png' -Cols 6 -Scale 13 -PerPage 30 -Out px\CT-ALL.png`
>    ⇒ 657 张分成 **22 页**（`px/CT-ALL-p1..p22.png`），每页 30 张带文件名标签。
> 2. 每页 `read_image` 一次，**写出"我看到了什么"**，逐物种判 `✅ 合格 / ⚠️ 勉强 / ✗ 废稿`。
> 3. 判废的具体理由必须写下来（形状 / 颜色 / 结构），不能只写"不好"。
>
> **判废的典型形态**（本项目反复出现，见到即判废）：
> `方块拼贴` · `马赛克/规则色块阵列` · `对称圣诞树/蘑菇/弹弓等几何体` ·
> `悬空色块` · `中央 1 列贯穿 + 左右对称叶冠` · `大片纯色地毯` · `与相邻年龄形态断裂`。

---

## 页码索引

| 页 | 覆盖（字母序，每页 30 张） | 状态 |
|---|---|---|
| p1 | adzuki · agave_rosette(含 fruit) · amaranth · arrowhead_0-3 | ✅ 已看 |
| p2 | arrowhead_4/5 · artichoke · arugula · asparagus · bambara_nut · bitter_melon_0/1 | ✅ 已看 |
| p3 | bitter_melon_2-7 · bottle_gourd · broccoli_leafball · brussels_sprouts_0-3 | ✅ 已看 |
| p4 | brussels_sprouts_4-6 · buckwheat · cabbage_leafball · cantaloupe · cardoon_rosette | ✅ 已看 |
| p5 | cardoon_rosette · cauliflower_leafball · celeriac · celery · celtuce · chayote | ✅ 已看 |
| p6 | chayote · chickpea · chicory_root · chili_0-3 | ✅ 已看 |
| p7 | chili_4/5 · chive · cotton · eggplant · einkorn | ✅ 已看 |
| p8 | einkorn_7 · emmer · faba_bean · fenugreek · finger_millet_0/1 | ✅ 已看 |
| p9 | finger_millet_2-7 · flax · fonio · foxtail_millet | ✅ 已看 |
| p10 | foxtail_millet_7 · garland_chrysanthemum · ginger · gorgon_nut · hops | ✅ 已看 |
| p11 | hops_5-7 · jobs_tears · kale_leafball · kale_rosette | ✅ 已看 |
| p12 | kale_rosette_5 · leafball · leafball_leafball · lettuce_leafball · loofah | ✅ 已看 |
| p13 | loofah_3-7 · lotus · lupin · malabar_spinach | ✅ 已看 |
| p14 | malabar_spinach_3-7 · millet · mustard_greens · napa_cabbage_leafball_0-2 | ✅ 已看 |
| p15 | napa_cabbage_leafball_3-5+head · okra · parsnip · pearl_millet · perilla_0/1 | ✅ 已看 |
| p16 | perilla_2-5 · purslane_rosette · quinoa · ramie_0-4 | ✅ 已看 |
| p17 | ramie_4/5 · rhubarb · rosette · safflower · salsify | ✅ 已看 |
| p18 | salsify_5 · sesame · shallot · snake_gourd · spelt_0 | ✅ 已看 |
| p19 | spelt_1-7 · spinach · sunchoke · swiss_chard_0-3 | ✅ 已看 |
| p20 | swiss_chard_4/5 · taro · turmeric · turnip · water_caltrop · water_chestnut_0-2 | ✅ 已看 |
| p21 | water_chestnut_3-5 · water_dropwort · water_shield · water_spinach · wild_rice_stem · winter_melon_0-2 | ✅ 已看 |
| p22 | winter_melon_3-6+side · yacon · yam | ✅ 已看 |

> ✅✅ **22/22 页全部看过 —— 657 张已 100% 过目**（第 34 轮完成）。

---

## p1 观察记录（30 张）

| 贴图 | 判断 | 我看到了什么 |
|---|---|---|
| `adzuki_0/1` | ✗ | 2~3 个**绿色方块**，无植物形态 |
| `adzuki_2/3` | ✗ | "蘑菇"形（圆叶 + 细茎）；`_3` 顶部还有**悬空的黄色方块** |
| `adzuki_4` | ✗ | 同上 + 一根褐色细枝 |
| `adzuki_5` | ✅ | 满贴图的绿色细枝 + 黄/红豆荚点，可用 |
| `agave_rosette_0..5` | ⚠️ | 青灰色尖叶丛，颜色合理（龙舌兰是蓝灰），形态偏对称 |
| `agave_rosette_5_fruiting` | ⚠️ | 与 `_5` 几乎相同，看不出"结果" |
| `agave_rosette_fruit` | ✗ | **4 个模糊米色方块**（马赛克），不像果实 |
| `amaranth_0..3` | ✗ | 绿色"小树"（圆冠 + 细茎），4 张几乎一样 |
| `amaranth_4..7_bottom` | ✗ | **绿色"心形/V 形"几何大块** |
| `amaranth_4..7_top` | ✗ | **粉红"花"几何体 + 褐色圆心** |
| `arrowhead_0..3` | ✅ | 1px 细芽 → 点阵 → 叶丛（本会话重画） |

## p2 观察记录（30 张）

| 贴图 | 判断 | 我看到了什么 |
|---|---|---|
| `arrowhead_4/5` | ✅ | 高瘦叶丛 + 顶部白花（本会话重画） |
| `artichoke_0..2` | ⚠️ | 灰绿色"小树"（3~4 圆叶 + 茎） |
| `artichoke_3` | ⚠️ | 灰绿大块 |
| `artichoke_4/5` | ✗ | **两个巨大灰绿团块**（像云/棉花），不是朝鲜蓟 |
| `arugula_0/1` | ✅ | 绿色点阵 |
| `arugula_2..5` | ✅ | 叶丛 → 密叶丛 + 米色茎基 |
| `asparagus_0..5` | ✅ | **粗壮绿茎 + 白色尖端 + 褐色基座**，正是芦笋 |
| `bambara_nut_0/1` | ⚠️ | 绿色"棕榈/扇叶"形 |
| `bambara_nut_2/3` | ✗ | **对称"圣诞树"**（多层等距分枝） |
| `bambara_nut_4` | ⚠️ | 同上略疏 |
| `bambara_nut_5` | ✅ | 满贴图绿叶 + 黄/白豆荚点 |
| `bitter_melon_0/1` | ⚠️ | 绿块 + 茎 |
| `bitter_melon_0/1_stick` | ✅ | 褐色竖直杆 + 绿色小叶（攀爬架，合理） |

## p3 观察记录（30 张）

| 贴图 | 判断 | 我看到了什么 |
|---|---|---|
| `bitter_melon_2/3(±_stick)` | ⚠️ | 绿叶块 + 褐茎，结构对 |
| `bitter_melon_4..7_bottom` | ⚠️ | 绿叶块**带规则方形洞**（格栅感）+ 中央竖茎 |
| `bitter_melon_5/6_top` | ⚠️ | 同上 + 浅绿"瓜" |
| `bitter_melon_7_top` | ✅ | **橙红色熟瓜** |
| `bottle_gourd_0/1` | ⚠️ | 小绿块 |
| `bottle_gourd_2/3` | ⚠️ | 绿色"树/蘑菇" |
| `bottle_gourd_4/5` | ✗ | **"Y"形/弹弓状几何体** |
| `bottle_gourd_side` | ✅ | 浅绿葫芦果实侧视 |
| `broccoli_leafball_0..5` | ✗ | **灰绿小方块**，`_0` 只有几个像素 |
| `broccoli_leafball_head` | ✗ | **深绿底 + 规则排列的浅绿方块**（马赛克） |
| `brussels_sprouts_0..3` | ✗ | **黄褐色 + 绿的小块**，颜色不对（应全绿） |

## p4 观察记录（30 张）

| 贴图 | 判断 | 我看到了什么 |
|---|---|---|
| `brussels_sprouts_4/5` | ✗ | 深绿 + **亮黄绿色块堆**，颜色混乱 |
| `brussels_sprouts_6` | ✗ | 绿色几何体 + 黄色块 |
| `buckwheat_0..4` | ✗ | **橙色柱 + 绿色三角**（像"镰刀/半月"），完全不像荞麦 |
| `buckwheat_5..7` | ✗ | 橙色弯枝 + 白色方块（花），仍不像荞麦 |
| `cabbage_leafball_0` | ⚠️ | 仅 1 像素（TFC `cabbage_0` 也只有 3 像素，可接受） |
| `cabbage_leafball_1..5` | ✅ | 绿色"Y"→ 叶球，`_4/5` 有绿+黄绿叶球 |
| `cabbage_leafball_head` | ✗ | **亮绿底 + 规则深绿方块阵列**（马赛克） |
| `cantaloupe_0..3` | ⚠️ | 小绿点 → 绿色柱 |
| `cantaloupe_4/5` | ⚠️ | 两个"心形"绿叶 + 中央球，几何感强 |
| `cantaloupe_side` | ✗ | **米色/沙色马赛克**，完全不是甜瓜 |
| `cardoon_rosette_0..4` | ⚠️ | 灰绿对称尖叶丛（莲座几何特殊，暂可接受） |

---

## 专项 survey（非 CT-ALL 分页）

| 物种 | 判断 | 我看到了什么 |
|---|---|---|
| `asparagus_*` | ✅ | 见 p2 |
| `rhubarb_0` | ⚠️ | 两个绿块 + 红块 |
| `rhubarb_1/2` | ⚠️ | 绿"伞盖" + 红色柱柄 |
| `rhubarb_3/4/5` | ✗ | **巨大绿色椭圆"伞盖" + 3~4 根红色粗柱**（像"红蘑菇/降落伞"），不是叶片 |
| `celery_0/1` | ⚠️ | 几根绿细茎 + 褐色基部 |
| `celery_2..5` | ✗ | 出现**蓝绿色（青色）竖条**，与芹菜不符 |
| `celtuce_0..5` | ⚠️ | 中央粗柱（3~4px、边缘直线）+ 顶部叶；`_5` 顶部左右对称"翅膀" |
| `chicory_root_0` | ⚠️ | **两个带洞的方块** |
| `chicory_root_1..5` | ⚠️ | 绿叶丛 + 底部米白色根块（菊苣根是白的，可接受） |
| `turmeric_0` | ✗ | **几乎全是橙色土堆** |
| `turmeric_1..5` | ⚠️ | 大橙色土堆 + 绿茎叶（土堆占比过大，不像植物） |
| `chive_*` | ✅ | 本会话重画（TFC `garlic` 细管叶丛） |
| `perilla_*` | ✅ | 本会话重画（TFC `beet` 叶丛 + 暗紫红叶缘） |
| 水生 9 物种 | ✅ | 本会话完成 age0~6/7，全序列单调 + 2D/3D 验收 |

---

## p5 观察记录（30 张：cardoon_rosette_5/fruiting/fruit · cauliflower_leafball · celeriac · celery · celtuce · chayote_0）

| 贴图 | 判断 | 我看到了什么 |
|---|---|---|
| `cardoon_rosette_5` | ⚠️ | 灰绿**对称**叶片丛（两个 V 形叶 + 底部横条） |
| `cardoon_rosette_5_fruiting` | ⚠️ | 与 `_5` 几乎相同，看不出"结果" |
| `cardoon_rosette_fruit` | ✗ | **模糊米绿色块**（马赛克） |
| `cauliflower_leafball_0/1` | ⚠️ | 小白块 + 绿点 |
| `cauliflower_leafball_2..4` | ⚠️ | 绿叶 + **白色十字/块**（花菜白球对，但形状是十字） |
| `cauliflower_leafball_5` | ✅ | **白色"云朵"形花球** + 绿底，可接受 |
| `cauliflower_leafball_head` | ✗ | **米白底 + 稀疏浅绿方块**（马赛克） |
| `celeriac_0/1` | ⚠️ | 绿色小块点阵 |
| `celeriac_2/3` | ✅ | 绿叶丛 |
| `celeriac_4/5` | ✅ | 绿叶丛 + 底部米色根块（本会话已做） |
| `celery_0/1` | ⚠️ | 绿茎 + 褐基 |
| `celery_2..5` | ✗ | 出现**蓝绿色（青色）竖条** |
| `celtuce_0/1` | ⚠️ | 绿色"Y"形小叶 |
| `celtuce_2..4` | ⚠️ | 中央粗绿柱 + 顶部"环" |
| `celtuce_5` | ✗ | 中央柱 + **左右对称"翼"**（几何） |
| `chayote_0` | ✅ | 绿色小叶 + 茎 |
| `chayote_0_stick` | ✅ | 褐色杆 + 绿叶 |

---

## p6 观察记录（30 张：chayote_1~7 · chickpea · chicory_root · chili_0-3）

| 贴图 | 判断 | 我看到了什么 |
|---|---|---|
| `chayote_1..3` | ⚠️ | 绿色"心形/盾形"叶团 + 褐茎（叶是实心团块） |
| `chayote_1..3_stick` | ✅ | 褐色杆 + 绿叶（攀爬架） |
| `chayote_4..7_bottom/top` | ⚠️ | 叶团 + 茎 / 大叶片，佛手瓜攀爬结构对 |
| `chickpea_0/1` | ✅ | 2~3 个小绿块 |
| `chickpea_2..4` | ✅ | **竖直细枝 + 小叶**（鹰嘴豆形态） |
| `chickpea_5` | ✅ | 满贴图细枝 + 黄褐豆荚 |
| `chicory_root_0` | ⚠️ | 2 个绿块 |
| `chicory_root_1/2` | ⚠️ | 绿块 + 米色茎 |
| `chicory_root_3..5` | ✅ | 绿叶丛 + 底部米白根块（菊苣根是白的） |
| `chili_0..3` | ✅ | 绿色细枝 + 小叶（本会话重画） |

## p7 观察记录（30 张：chili_4/5 · chive · cotton · eggplant · einkorn）

| 贴图 | 判断 | 我看到了什么 |
|---|---|---|
| `chili_4/5` | ✅ | 绿叶丛 + **红色辣椒** |
| `chive_0..5` | ✅ | 细管叶丛（本会话重画，TFC `garlic` 骨架） |
| `cotton_0..2` | ✅ | 绿色小叶丛 |
| `cotton_3..5_bottom/top` | ⚠️ | **4 根等距竖直茎 + 规则白棉桃**（结构对，但"栅栏化"） |
| `eggplant_0..5` | ✅ | 绿色叶丛 + **紫色茄子** |
| `einkorn_0..7` | ✅ | 细叶谷物，绿 → **金黄麦穗**（r21 版本） |

---

## p8 观察记录（30 张：einkorn_7 · emmer · faba_bean · fenugreek · finger_millet_0/1）

| 贴图 | 判断 | 我看到了什么 |
|---|---|---|
| `einkorn_7` | ✅ | 金黄麦穗（r21） |
| `emmer_0..7`(±`_bottom/_top`) | ✅ | 绿色 → **金黄麦子**，穗形清晰，双段结构 |
| `faba_bean_0..2` | ⚠️ | 绿色小叶团 |
| `faba_bean_3..5`(±`_bottom/_top`) | ✅ | 绿色茎 + **白色花簇** + 叶（蚕豆形态） |
| `fenugreek_0..5` | ✅ | 绿色小叶丛（`_5` 密叶丛） |
| `finger_millet_0/1` | ✅ | 绿色细茎 |

## p9 观察记录（30 张：finger_millet_2-7 · flax · fonio · foxtail_millet）

| 贴图 | 判断 | 我看到了什么 |
|---|---|---|
| `finger_millet_2..6` | ⚠️ | 绿色细茎 + 顶部弯钩（像"手杖"），形态单调但正确 |
| `finger_millet_7` | ✅ | 绿茎 + 顶部 **3 根褐色"手指"**（指状分叉穗） |
| `flax_0/1` | ✅ | 绿色小点 |
| `flax_2..5` | ⚠️ | 绿叶丛 + 顶部**淡蓝"十字/菱形块"**（亚麻花是蓝的，但形状几何） |
| `fonio_0..7`(±双段) | ✅ | 绿色 → **金黄细穗**谷物 |
| `foxtail_millet_0..4` | ✅ | 绿色细茎 |
| `foxtail_millet_5..7_top` | ✅ | **金黄色"毛绒狐狸尾"穗** |

## p10 观察记录（30 张：foxtail_millet_7 · garland_chrysanthemum · ginger · gorgon_nut · hops）

| 贴图 | 判断 | 我看到了什么 |
|---|---|---|
| `foxtail_millet_7`(±双段) | ✅ | 绿茎 + 金黄尾穗 |
| `garland_chrysanthemum_0..2` | ⚠️ | 绿色小点 |
| `garland_chrysanthemum_3..5` | ⚠️ | 绿色细枝 + 顶部**黄色"十字/星形"花**（形状几何） |
| `ginger_0` | ✗ | **褐色土堆 + 一根绿芽** |
| `ginger_1..5` | ✗ | 褐色土堆 + **空心菱形叶片**（几何形状 + 土堆过大） |
| `gorgon_nut_0..5` | ✗ | **青灰色"云朵/团块"占满贴图中央**（完全不像水生植物） |
| `hops_0..3`(±`_stick`) | ✅ | 绿色"爪形/三叉"叶 + 褐茎 |
| `hops_4..7`(±双段) | ✅ | 绿色叶 + 褐茎 |

## p11 观察记录（30 张：hops_5-7 · jobs_tears · kale_leafball · kale_rosette）

| 贴图 | 判断 | 我看到了什么 |
|---|---|---|
| `hops_5..7`(±双段) | ✅ | 绿藤 + 褐茎，`_7_top` 有浅绿花球 |
| `jobs_tears_0/1` | ✅ | 绿色小点 |
| `jobs_tears_2/3` | ⚠️ | **绿色圆球**（像小花椰菜），奇怪 |
| `jobs_tears_4..7_bottom` | ✅ | 绿色细枝丛 |
| `jobs_tears_5..7_top` | ✅ | 竖直茎 + **灰白色"串珠"**（薏米硬粒） |
| `kale_leafball_0..3` | ⚠️ | 青灰色"叶丛" |
| `kale_leafball_4/5` | ✅ | 青灰绿叶丛 |
| `kale_leafball_head` | ✗ | **青灰色 L 形块**，不像叶球 |
| `kale_rosette_0..5` | ⚠️ | 深绿色"圆形叶球"，中央一个深色洞（像"甜甜圈/眼睛"） |

---

## p12 观察记录（30 张：kale_rosette_5 · leafball · leafball_leafball · lettuce_leafball · loofah）

| 贴图 | 判断 | 我看到了什么 |
|---|---|---|
| `kale_rosette_5` / `_5_fruiting` | ⚠️ | 深绿"圆环"（中央深色洞）；`_fruiting` 与 `_5` 几乎相同 |
| `leafball_0..5` | ⚠️ | 青灰绿叶丛，`_3~5` 有"方块 + 竖茎"结构 |
| `leafball_head` | ✗ | **青灰 L 形块**（已修，见下） |
| `leafball_leafball_*`(7) | ☠️ | **死贴图**（无模型引用，AGENTS.md 已记录，不投入人力） |
| `lettuce_leafball_0..5` | ✅ | 绿色叶丛，`_5` 是"菱形叶" |
| `lettuce_leafball_head` | ✗ | **黄绿底 + 方块阵列（马赛克）**（已修） |
| `loofah_0..3`(±`_stick`) | ✅ | 绿色藤 + 褐茎（丝瓜攀爬） |

## p13 观察记录（30 张：loofah_3-7 · lotus · lupin · malabar_spinach）

| 贴图 | 判断 | 我看到了什么 |
|---|---|---|
| `loofah_3..7`(±双段) | ✅ | 绿藤 + 褐茎 |
| `lotus_0..7` | ✅ | 实心圆叶 → 叶丛 → **粉花**（本会话重画） |
| `lupin_0..2` | ✅ | 绿色小叶丛 |
| `lupin_3/4` | ✅ | 绿茎 + **紫色花穗** |
| `lupin_5` | ⚠️ | 大蓝紫"塔形"花序（颜色对，形状偏几何） |
| `malabar_spinach_*`(±`_stick`) | ✅ | 褐色杆 + 绿色圆叶 + **紫红色茎**（落葵特征） |

---

## p14 观察记录（30 张：malabar_spinach_3-7 · millet · mustard_greens · napa_cabbage_leafball_0-2）

| 贴图 | 判断 | 我看到了什么 |
|---|---|---|
| `malabar_spinach_3..7`(±双段) | ✅ | 褐色杆 + 绿圆叶 + **紫红茎**（落葵） |
| `millet_0..3` | ✅ | 绿色细茎 |
| `millet_4..7`(±双段) | ✅ | 绿色茎 + **褐色穗** |
| `mustard_greens_0..5` | ✅ | 绿色叶丛（本会话重画） |
| `napa_cabbage_leafball_0..2` | ⚠️ | 绿色小点 |

## p15 观察记录（30 张：napa_cabbage_3-5+head · okra · parsnip · pearl_millet · perilla_0/1）

| 贴图 | 判断 | 我看到了什么 |
|---|---|---|
| `napa_cabbage_leafball_3/4` | ⚠️ | 绿叶丛 |
| `napa_cabbage_leafball_5` | ⚠️ | 一个大的浅绿矩形块 + 米色底部 |
| `napa_cabbage_leafball_head` | ✗ → 已修 | ⚠️ **本页是第 23 轮快照**，显示的还是旧马赛克；实际已在第 30 轮重画 |
| `okra_0..5` | ✅ | 绿色茎 + 叶（`_5` 有星形叶） |
| `parsnip_0..5` | ✅ | 本会话重画 |
| `pearl_millet_0..4` | ✅ | 绿色细茎 |
| `pearl_millet_5..7`(±双段) | ✅ | 绿色茎 + **褐色"纺锤形"穗** |
| `perilla_0/1` | ✅ | 本会话重画（绿丛 + 暗紫红） |

> ⚠️⚠️ **重要**：`CT-ALL-p*.png` 全部生成于**第 23 轮**，是**快照**。
> 第 24~31 轮修复过的贴图在此仍显示旧状。**判读时必须以本台账的「已修复清单」为准**，
> 不要因为快照里还是马赛克就重复返工。

---

## p16 观察记录（30 张：perilla_2-5 · purslane_rosette · quinoa · ramie_0-4）

| 贴图 | 判断 | 我看到了什么 |
|---|---|---|
| `perilla_2..5` | ✅ | 绿丛 + 暗紫红（本会话重画） |
| `purslane_rosette_0..5` | ✅ | **浅绿叶片 + 褐色茎**（马齿苋） |
| `purslane_rosette_5_fruiting` | ⚠️ | 与 `_5` 几乎相同，看不出结果 |
| `purslane_rosette_fruit` | ✗ → 已修 | **模糊绿色方块（马赛克）** |
| `quinoa_0..3` | ✅ | 绿色小叶丛 |
| `quinoa_4..7`(±双段) | ✅ | 绿茎叶 + **橙红色穗**（藜麦特征） |
| `ramie_0..2` | ✅ | 绿色小叶丛 |
| `ramie_3..5`(±双段) | ✅ | 绿色茎叶（苎麻） |

## p17 观察记录（30 张：ramie_4/5 · rhubarb · rosette · safflower · salsify）

| 贴图 | 判断 | 我看到了什么 |
|---|---|---|
| `ramie_4/5` | ✅ | 绿色茎叶 |
| `rhubarb_0~2` | ✗ → 已修 | 绿块 + 红块 / 绿色圆伞 + 红色柱 |
| `rhubarb_3/4/5` | ✗ → 已修 | **巨大绿色椭圆伞盖 + 3~4 根红色粗柱**（像"红蘑菇/降落伞"） |
| `rosette_0..5` | ✅ | 青绿色细茎丛（莲座作物） |
| `rosette_5_fruiting` | ✅ | 绿茎 + 中央浅绿球 |
| `rosette_dead` / `rosette_dead_young` | ✅ | 褐黄色枯茎 |
| `rosette_fruit` | ✗ → 已修 | **模糊绿色方块（马赛克）** |
| `safflower_0..5` | ✅ | 绿色叶丛 + **橙红色花**（花的形状偏"十字"） |
| `salsify_0..5` | ✅ | 绿色叶丛 + **白色根**（婆罗门参） |

> ⚠️ **第二个系统性同源问题**：**所有莲座类的 `_fruit` 都是同一套马赛克生成器刷的**
> （`rosette_fruit` / `purslane_rosette_fruit` / `agave_rosette_fruit` / `cardoon_rosette_fruit`）。
> 第 27 轮修了 2 张，本轮补齐剩余 2 张 ⇒ **莲座 `_fruit` 4/4 完成** ✓

---

## p18 观察记录（30 张：salsify_5 · sesame · shallot · snake_gourd · spelt_0）

| 贴图 | 判断 | 我看到了什么 |
|---|---|---|
| `salsify_5` | ✅ | 绿叶丛 + 白根 |
| `sesame_0..2` | ✅ | 绿色小茎丛 |
| `sesame_3..5` | ⚠️ | **对称"圣诞树"形**（黄绿点排列规整） |
| `shallot_0..5` | ✅ | 绿色茎，`_5` 有**粉色鳞茎** |
| `snake_gourd_*`(±`_stick`/双段) | ✅ | **绿色掌状叶 + 褐杆**（蛇瓜攀爬） |
| `spelt_0` | ✅ | 金黄幼苗 |

## p19 观察记录（30 张：spelt_1-7 · spinach · sunchoke · swiss_chard_0-3）

| 贴图 | 判断 | 我看到了什么 |
|---|---|---|
| `spelt_1..7`(±双段) | ✅ | **黄绿色麦子 + 褐色穗** |
| `spinach_0..5` | ✅ | 本会话重画 |
| `sunchoke_0..2` | ✅ | 绿色"菊芋"形 |
| `sunchoke_3..5`(±双段) | ✅ | 绿色掌状叶 + 茎，`_5_top` 有**黄色花朵** |
| `swiss_chard_0..3` | ✅ | 本会话重画（`_3` 有红/黄叶脉） |

> **p18/p19 无新废稿** —— 说明谷物（`spelt`）、豆类、叶菜、根菜各族均已达标。

---

## p20 观察记录（30 张：swiss_chard_4/5 · taro · turmeric · turnip · water_caltrop · water_chestnut_0-2）

| 贴图 | 判断 | 我看到了什么 |
|---|---|---|
| `swiss_chard_4/5` | ✅ | 本会话重画（彩叶脉） |
| `taro_0..6` | ✅ | 本会话重画（矮胖叶丛 + 褐块根 + 心形大叶） |
| `turmeric_0` | ✗ → 已修 | **橙色土堆 + 一根小绿芽** |
| `turmeric_1..5` | ✗ → 已修 | **橙色土堆 + 绿色菱形空心叶**（几何） |
| `turnip_0..5` | ✅ | 本会话重画（叶丛 + 紫色根） |
| `water_caltrop_0..5` | ✅ | 本会话重画（红褐茎 + 菱角） |
| `water_chestnut_0..2` | ✅ | 本会话重画（2px 细管 → 粗管） |

## p21 观察记录（30 张：water_chestnut_3-5 · 水生族其余 · winter_melon_0-2）

| 贴图 | 判断 | 我看到了什么 |
|---|---|---|
| `water_chestnut_3..5` | ✅ | 本会话重画（竖管丛） |
| `water_dropwort_0..5` | ✅ | 本会话重画（羽状叶丛） |
| `water_shield_0..5` | ✅ | 本会话重画（矮叶丛 + 红褐水下茎） |
| `water_spinach_0..5` | ✅ | 本会话重画（匍匐横茎） |
| `wild_rice_stem_0..5` | ✅ | 本会话重画（细叶丛 + 顶部黄穗） |
| `winter_melon_0/1` | ⚠️ | 绿色"十字/T"形 |
| `winter_melon_2` | ⚠️ | 绿色"鸟/叶"形 |

## p22 观察记录（27 张：winter_melon_3-6+side · yacon · yam）

| 贴图 | 判断 | 我看到了什么 |
|---|---|---|
| `winter_melon_3` | ⚠️ | 绿色"蘑菇/伞"形 |
| `winter_melon_4/5` | ⚠️ | **巨大的绿色"W"形叶**（像翅膀） |
| `winter_melon_6` | ⚠️ | 褐色竖直茎 + 黄绿点 |
| `winter_melon_side` | ⚠️ | **深绿球体 + 白色月牙边**（白边突兀） |
| `yacon_0..5` | ✅ | 本会话重画（叶丛 + 米色根） |
| `yam_0..7`(±`_stick`/双段) | ✅ | 绿色藤 + 褐色块茎 + 褐杆（山药攀爬） |

---

## 进度

- ✅✅ **全量视觉验收完成：657 / 657（100%）** —— 22 页 + 专项 survey 全部 `read_image` 过目
- ✅ 已修复：**100 张**（见下节修复记录）
- ⚠️ 判废待修剩余：`bottle_gourd_4/5`(6) —— 唯一剩下的 ✗ 级；其余为 ⚠️ 级「勉强可接受」
- 已判废待重画（累计）：`bottle_gourd_4/5` · `turmeric_0~5` · `kale_leafball_head`(死贴图，可能直接删)
- ✅ **已修复（累计 94 张）：`buckwheat`(8) · `amaranth`(12) · `broccoli_leafball`(7) ·
  `brussels_sprouts`(7) · `agave_rosette_fruit` · `cantaloupe_side` · `cabbage_leafball_head` ·
  `cauliflower_leafball_head` · `cardoon_rosette_fruit` · `celery`(6) · `adzuki`(6) ·
  `lettuce_leafball_head` · `napa_cabbage_leafball_head` · `leafball_head` · `ginger`(6) ·
  `gorgon_nut`(6) · `bambara_nut`(6) · `rhubarb`(6) · `rosette_fruit` ·
  `purslane_rosette_fruit` · `celtuce`(6) · `artichoke`(6)** —— 见下节。
- ⚠️ 勉强（暂留，若有余力再修）：`agave_rosette_0~5` · `artichoke_0~3` · `bambara_nut_0/1` ·
  `bitter_melon_2~7` · `bottle_gourd_0~3` · `cantaloupe_0~5` · `cardoon_rosette_0~5` ·
  `cauliflower_leafball_0~4` · `celeriac_0/1` · `celtuce_0~4` · `chicory_root_*` · `turmeric_1~5` ·
  `chayote_*` · `cotton_3~5` · `finger_millet_2~6` · `flax_2~5` ·
  `garland_chrysanthemum_3~5` · `jobs_tears_2/3` · `kale_rosette_*` · `lupin_5`

> **判废第一梯队（下轮优先）**：`gorgon_nut`(6) · `rhubarb_3/4/5` · `turmeric`(土堆过大) ·
> `celtuce_5` · `artichoke_4/5` · `bottle_gourd_4/5` · `bambara_nut_2/3`

---

---

## 生长序列单调性 · 全量核验（第 35 轮新增）

**口径**：对 82 个物种，按 `sp_N`（单层）与 `sp_N_bottom + sp_N_top`（双段，两半相加）
统计每档 opaque，逐档比较是否**单调不减**。

| 阶段 | 单调 | 非单调 |
|---|---|---|
| 首次核验 | 70 | **12** |
| 第一批修复后 | 73 | **9** |
| 第二批修复后 | **78** | **4** |

**剩余 4 个全部属于「不计入」类别**（详见下）—— **可修的非单调已归零** ✓

**首轮 12 个非单调**：`agave_rosette` · `chili` · `eggplant` · `kale_leafball` · `kale_rosette` ·
`leafball` · `loofah` · `lotus` · `purslane_rosette` · `sesame` · `snake_gourd` · `winter_melon`。
本轮已修 `chili_5` · `eggplant_5` · `sesame_3` · `snake_gourd_7` · `loofah_7`。

**剩余 9 个（下轮处理）**：

| 物种 | 序列 | 性质 |
|---|---|---|
| `agave_rosette` | 133/130/132/121/134/123 | **莲座类**：4 片叶片，op 波动 ±10%，**几何特性**（视觉生长正常） |
| `purslane_rosette` | 132/143/132/133/128/132 | 同上 |
| `kale_rosette` | 143/150/143/152/161/145 | 同上 |
| `kale_leafball` | 65/108/134/149/157/128 | **死贴图**（无模型引用），不投入 |
| `leafball` | 61/108/136/150/175/147 | 设计稿缺失（只有 PNG），需反向重建后加密 `_5` |
| `loofah` | 40/44/60/61/123/**122**/156/235 | `_5`=122 仅比 `_4` 少 1 ⇒ 加密 `_5` |
| `lotus` | 10/30/72/86/94/121/**118**/**120** | `_6/_7`（开花期）需加密 |
| `sesame` | 14/23/70/99/**82**/89 | 本轮加密 `_3` 后 `_4` 落后 ⇒ 需同步加密 `_4/_5` |
| `winter_melon` | 12/**11**/54/**45**/126/126/**69** | `_1`/`_3`/`_6` 三处需加密 |

> ⚠️ **莲座类的 op 单调性不是有效判据**：它是 4 片旋转叶片的几何，
> op 只反映叶片宽度而不反映"生长"。**这 3 个应以视觉复核为准**（已看过，生长正常），
> 不要为了凑 op 去改动它们。

---

## 交付验证（第 37 轮）

### 全量审计（`.probe/texture-design/audit-all.ps1`）

| 项 | 结果 |
|---|---|
| 贴图总数 | **657** ✓ |
| 尺寸非 16×16 | **0** ✓ |
| `asym = 0`（镜像对称，硬约束禁止） | 1 → **0**（修了 `winter_melon_0`）✓ |
| 平均 asym | 38.4（TFC 基准 42.3） |
| 色数 > 8 | 35 张 —— ⚠️ **不算问题**：TFC 色数中位 **7**、P75 **19**，该判据已过时 |
| LUM 出 110~140 | 359 张 —— ⚠️ **不算问题**：真基准是 LUM 中位 **100.2**（AGENTS.md 已订正为「基准 123 是错的」） |
| opaque < 60 | 23 张（幼苗期，早已接受） |

### 项目校验（`tools/verify.ps1`）

- **修复前：4 个问题** —— `broccoli_age_0/1`、`lettuce_age_0/1` 这 4 个模型的贴图槽 `"1": ""`
  是**空字符串**（历史生成器遗留，`elements` 里根本没引用 `#1`）
- **修复后：`结果: 全部交叉引用有效，未发现问题`** ✓
- 索引：模型 16116 / 贴图 6846 / configured_feature 907 / placed_feature 891
- 已校验：blockstate 413 / 模型 1745 / 掉落表 412 / configured_feature 217 / placed_feature 217 /
  物品模型 375

## 修复记录

### 第 36 轮 · 剩余非单调修复（8 个物种）+ **3D 并排对比（目标要求项）**

**单调性修复（第二批）**：`sesame_4/5` · `lotus_6/7` · `winter_melon_1/3/6` · `leafball_5` ·
`loofah_5/6/7` —— 全部用"**从 PNG 反向重建自包含设计稿 → `overlay` 自身错位加密 → 双段再同步接缝**"
的流程处理。复验：**78 单调 / 4 非单调**（剩余 4 个均为「不计入」类别），**接缝 72 对齐 / 0 错位** ✓

⚠️ **加密是有副作用的**：`overlay` 让叶块变粗。`loofah` 就出现过
`_5`(204) > `_6`(156) 的**反超**，需要再加密 `_6`、再给 `_7` 补一层才恢复单调。
**下轮若要精修，应改用"逐像素补几根细芽"而不是整体 overlay。**

### 3D 并排对比（`px/CALIB-3D-OURS-vs-TFC.png`）

**方法与 TFC 完全同条件**：
- 同一模型 `minecraft:block/crop`（TFC 原版作物用的就是它）
- 同一渲染器 `render-tfc.ps1`（我方用 `lab-render.ps1`，底层同一套）
- 同一相机 `-PitchDeg 28 -YawDeg 40 -Scale 16 -NoTint`
- 输出尺寸与包围盒完全一致：`canvas=260px` · `faces=4/4` · `bbox X[2.34,13.66] Y[0,16] inside-block OK`

**我看到了什么**：

| 组 | 我方 | TFC 原版 | 判断 |
|---|---|---|---|
| `rhubarb_5` vs `beet_5` | 绿叶冠 + 底部红色叶柄（红较散） | 绿叶冠 + 底部红色根块（红更成块） | 结构相同 ⚠️ 红底偏散 |
| `taro_5` vs `cassava_5` | 绿叶冠 + 褐色块根 | 绿叶冠 + 褐色树干 + 块根 | **非常接近** ✓ |
| `wild_rice_stem_5` vs `rice_5` | 细叶丛 + 黄绿穗 | 细叶丛（均匀绿） | ✓ 我方穗更黄（有意为之） |
| `chive_5` vs `garlic_4` | **较粗的绿色茎叶** | **细长的绿色叶 + 浅绿球茎** | ⚠️ **我方的叶偏粗** |

**结论**：**渲染管线已完全可比**（目标项达成）；风格同源（高频细节 + 离散色阶 + 十字几何）。
**已知差距**：我方加密过的成熟期叶块**比 TFC 偏粗偏密** —— 这是 `overlay` 加密的副作用，
是**下一轮精修的唯一方向**（应改为"补细芽"而非整体叠加）。

### 第 35 轮 · `bottle_gourd`(6) + 生长单调性修复（第一批）

**`bottle_gourd`**（最后一处 ✗ 级废稿）：判废理由是 `_4/5` 是**"Y 形弹弓"几何体**。
改用 **`melon_0..5`**（此前未使用的参考）⇒ 绿藤叶丛 + 浅绿瓜形 ✓ 密度 6/15/30/43/70/105。
第一版调色板过亮（LUM 154~170），调暗到 `B=7AA84A,d=5C8836,s=426A22,g=2E5016`（LUM 102~115）✓

**单调性修复（第一批 5 个物种）**：

| 物种 | 问题 | 处理 |
|---|---|---|
| `chili_5` | 69 < 85 | `overlay` 加密 ⇒ 108 ✓ |
| `eggplant_5` | 81 < 87 | `overlay` 加密 ⇒ 121 ✓ |
| `sesame_3` | 68 < 70 | 设计稿是**旧格式**（引用外部调色板 `sesame_c` + 镜像对称约束）⇒ **从 PNG 反向重建自包含设计稿**后加密 ⇒ 99 ✓ |
| `snake_gourd_7` | 178 < 191 | 同上（旧格式：无调色板行 + 空格分组）⇒ 反向重建（bottom/top **共用同一调色板**）后加密 ⇒ 165+136=301 ✓ |
| `loofah_7` | 153 < 156 | 同上 ⇒ 108+127=235 ✓ |

**🛑 本轮发现的两个数据问题**：
1. **设计稿有两种命名风格**（`CHILI-5.txt` 大写连字符 / `sesame_3.txt` 小写下划线），
   **且有第三种"旧格式"**（无调色板行、用空格分组、镜像对称产物）——
   旧格式**不能被 `overlay.ps1` 处理**，必须先**从 PNG 反向重建自包含设计稿**。
2. **双段贴图反向重建时，`_bottom` 与 `_top` 必须共用同一调色板映射**，
   否则接缝行的字符含义不同 ⇒ 接缝必然错位。本轮已按此处理，复验 **72 对齐 / 0 错位** ✓

**验收**：`px/CT-bottle-gourd2.png`（含旧版对比）。

### 第 34 轮 · `turmeric`(6) —— 最后一处 ✗ 级废稿

**判废理由**：`turmeric_0` 是**橙色土堆 + 一根小绿芽**、`_1~5` 是**橙色土堆 + 绿色菱形空心叶**（几何形状 + 土堆过大）。

**修法**：`potato_0..5`（**此前未被任何物种使用的参考**，符合第 33 轮建立的"参考骨架全局分配"规矩）
+ 调色板 `B=6CB33A,d=4E8C28,s=35661A,g=244A10,k=8A5A1A`
（`k` 放第 3 档 = 地下根茎的位置）⇒ **绿色枝叶 + 底部橙色根茎** ✓
密度 `10/15/26/39/45/59` ✓ 单调。

**验收**：`px/CT-turmeric.png`、`px/CHK-turmeric-3d.png`。

### 第 33 轮 · `celtuce`(6) + `artichoke`(6)

**判废理由**：`celtuce_5` 是**中央柱 + 左右对称"翼"**（几何）；`artichoke_4/5` 是**两个巨大灰绿团块**（像"云/棉花"）。

**修法（含一次参考冲突的纠正）**：

| 物种 | 第一版参考 | 问题 | 最终参考 | 结果 |
|---|---|---|---|---|
| `celtuce_0..5` | `cabbage` | **与 `broccoli_leafball` op 完全相同**（3/10/15/19/34/45）✗ 同形 | **`canola_0..5`** | 茎 + 顶部扇叶 ✓ 密度 15/31/67/103/126/156 |
| `artichoke_0..5` | `beet` | 与 `rhubarb` 同形 ✗ | **`squash_0..5`** | 灰绿大叶 + **紫花苞** ✓ 密度 5/16/35/72/102/125 |

**🛑 教训：参考骨架要全局分配，不能只看"形态像"**。
本项目已用掉的 TFC 参考：
`einkorn`→buckwheat · `emmer`→（emmer 本身）· `cassava`→taro/arrowhead/ginger ·
`beet`→lotus/water_shield/water_caltrop(?)/rhubarb/莲座 `_fruit` · `cabbage`→叶球类与 `_head` ·
`carrot`→water_dropwort · `sugarcane`→water_chestnut/amaranth · `rice`→wild_rice_stem ·
`garlic`→chive · `lentil`→adzuki · `soybean`→brussels_sprouts/bambara_nut ·
`melon_side`→cantaloupe_side · `squash`→artichoke · `canola`→celtuce。
**下轮选参考前先查这张表，避免两个物种撞同一个骨架。**

**验收**：`px/CT-r33b.png`、`px/CHK-r33-3d.png`。

### 第 32 轮 · `rhubarb`(6) + 莲座 `_fruit` 收尾（2 张）

**判废理由**：`rhubarb_3/4/5` 是**巨大的绿色椭圆伞盖 + 3~4 根红色粗柱**（像"红蘑菇/降落伞"）；
`rosette_fruit` / `purslane_rosette_fruit` 是**模糊色块（马赛克）**。

**修法**：

| 贴图 | TFC 参考 | 结果 |
|---|---|---|
| `rhubarb_0..5` | `beet_0..5` | **绿叶丛 + 底部红色叶柄** ✓ 密度 15/30/72/89/110/116 |
| `rosette_fruit` | `beet_5` + 填满 | 青绿底 + 浅青块 ✓ op=256 |
| `purslane_rosette_fruit` | `peanut_5` + 填满 | 浅绿颗粒 ✓ op=256 |

**🛑 第 4 次验证"调色板档位 = 颜色面积"**：
`rhubarb` 第一版把红色 `r=C03A2A`（LUM 85）放在第 2 档 ⇒ **1/3 像素是红色**（像"红绿格子布"）✗；
改成 `r=7A1A10`（LUM 46，**最暗档**）⇒ 红色只落在叶柄 ✓。
（前三次：第 22 轮 `chive`/`perilla` · 第 24 轮 `buckwheat` · 第 30 轮 `ginger`）

**验收**：`px/CT-rhubarb2.png`、`px/CHK-r32-3d.png`、`px/CT-all-rosette-fruits.png`（4 张 `_fruit` 并排）。

### 第 31 轮 · `gorgon_nut`(6) + `bambara_nut`(6)

**判废理由**：`gorgon_nut_0~5` 全部是**青灰色"云朵/团块"占满贴图中央**（完全不像水生植物）；
`bambara_nut_0/1` 是绿色"棕榈/扇叶"形、`_2/3` 是对称"圣诞树"。

**修法**：

| 物种 | TFC 参考 | 调色板 | 结果 |
|---|---|---|---|
| `gorgon_nut_0..5` | `beet_0..5` | 青绿 + `p=9A6AB8`（紫，第 3 档） | 绿叶丛 → **散布紫花** ✓ 密度 15/30/72/89/110/116 |
| `bambara_nut_0..5` | `soybean_0..5`（**与 `adzuki` 的 `lentil` 不同**，避免同形） | 绿 + `k=7A5A2A`（第 3 档，褐荚） | 绿枝叶 + 褐斑 ✓ |

**🛑 `soybean` 骨架的 `_3/4/5` 几乎相同**（46/49/50）⇒ `bambara_nut` 的后期生长看不出来。
用 `overlay`（自身错位 3px）给 `_5` 加密 ⇒ `5/19/27/46/49/80` ✓ 单调。
**这是第 26 轮 `brussels_sprouts` 同一问题的第二次出现** ——
**凡用 `soybean` 骨架的作物，`_3~5` 段都必须主动拉开密度**。

**验收**：`px/CT-r31.png`、`px/CHK-r31-3d.png`。

### 第 30 轮 · 叶球类 `_head` 收尾（3 张）+ `ginger`(6)

**判废理由**：p10 看到 `ginger_1~5` 是**褐色土堆 + 空心菱形叶片**（几何形状 + 土堆过大）；
p12 看到 `lettuce_leafball_head` 是**黄绿底 + 方块阵列（马赛克）**、`leafball_head` 是**青灰 L 形块**。

**发现系统性问题**：**所有叶球类的 `_head` 都是同一套"马赛克"生成器刷的** ——
本项目 6 个叶球物种（broccoli / cabbage / cauliflower / lettuce / napa_cabbage / leafball）
的 `_head` 全部中招。第 26/27 轮已修 3 张，本轮补齐剩余 3 张 ✓

| 贴图 | TFC 参考 | 效果 |
|---|---|---|
| `lettuce_leafball_head` | `beet_5` | 黄绿底 + 有机块 |
| `napa_cabbage_leafball_head` | `peanut_5` | 浅绿颗粒 |
| `leafball_head` | `beet_5` | 青灰绿底 + 块 |
| `ginger_0..5` | `cassava_0..5` | 绿枝叶 + 褐根茎（替代"空心菱形叶"） |

**🛑 本轮又验证了一次"调色板档位 = 颜色面积"**：
`ginger` 第一版把根茎色 `k=9A7A3A`（LUM 124）放在第 4 档 ⇒ **满图褐色斑点**（像斑点狗）✗；
改成 `k=4A2A10`（LUM 47，**最暗档**）⇒ 褐色只在茎干 ✓。
**这是第 22/24 轮同一条规律的第三次复现。**

**验收**：`px/CT-all-heads.png`（6 张 `_head` 并排，互可区分）、`px/CT-ginger2.png`、`px/CHK-ginger-3d.png`。

### 第 28 轮 · `adzuki`（6 张，红豆）

**判废理由**（p1）：`_0/1` 是**绿色方块**、`_2/3` 是"蘑菇"形且 `_3` 顶部有**悬空的黄色方块**。

**修法**：TFC `lentil` 同为 6 档豆类 ⇒ `transplant`，调色板 `B=7ECB45,d=5CA82E,s=3E7A1E,g=2A5A12,r=9A4230`
（`r` 落在第 2 暗档 = 茎/荚的位置）⇒ **细枝 + 叶 + 红褐豆荚**。

- 密度 `16/31/60/73/90/110` ✓ 单调；LUM 108~137 ✓
- ⚠️ 已知：`_4/5` 只用到 **2 档色**（`lentil_4/5` 骨架本身亮度集中），但视觉上是"深绿枝叶 + 亮绿高光"，
  可接受。

**验收**：`px/CT-adzuki-final.png`、`px/CHK-adzuki-3d.png`。

### 第 27 轮 · "马赛克类" 5 张 + `celery` 6 张

**判废理由**：`agave_rosette_fruit` = 4 个模糊米色方块；`cardoon_rosette_fruit` = 模糊米绿色块；
`cantaloupe_side` = 米色/沙色马赛克；`cabbage_leafball_head` = 亮绿底 + 规则深绿方块阵列；
`cauliflower_leafball_head` = 米白底 + 稀疏浅绿方块；`celery_2~5` = **蓝绿色竖条**（颜色错误）。

**统一修法**：`transplant` + **填满所有透明像素**（`_head`/`_side`/`_fruit` 都是方块贴图，
**六面共享 ⇒ 必须全铺满**，op 必须 = 256）。

| 贴图 | TFC 参考 | 调色板要点 |
|---|---|---|
| `cantaloupe_side` | `melon_side` | 深橄榄底 + 米色网纹（甜瓜皮） |
| `cabbage_leafball_head` | `beet_5` | 深绿底 + 亮绿有机块 |
| `cauliflower_leafball_head` | `peanut_5` | 米白/浅绿颗粒（花球） |
| `cardoon_rosette_fruit` | `beet_5` | 绿 + **紫**鳞片（朝鲜蓟花苞） |
| `agave_rosette_fruit` | `beet_5` | 青灰绿 |
| `celery_0..5` | `beet_0..5` | 纯绿（**去掉蓝绿**） |

**🛑 两个坑**：

1. **`cabbage_5` 只有 45 个不透明像素** ⇒ 填满后 90% 是纯深绿、只剩中央一小块 ✗
   （第一版 `cardoon_rosette_fruit` 就是这样）。**方块贴图的参考必须选 op ≥ 100 的密集贴图**
   （`beet_5`=116、`peanut_5`=158）。
2. `peanut_5` 的细碎小叶 + 填满 ⇒ 有"色块阵列"感；`beet_5` 的叶丛更有机。
   `agave_rosette_fruit` 改用 `beet_5` 后改善（仍列 ⚠️ 可接受）。

**验收**：`px/CT-mosaic-final.png`、`px/CT-NEW-mosaic.png`（含 celery 0-5）。

### 第 26 轮 · `broccoli_leafball`(7) + `brussels_sprouts`(7)

**判废理由**（p3）：`broccoli_leafball_0~5` 是**灰绿小方块**（`_0` 只有几个像素）；
`broccoli_leafball_head` 是**深绿底 + 规则排列的浅绿方块**（马赛克）；
`brussels_sprouts_0~3` 是**黄褐色 + 绿的小块**（颜色不对，应全绿），`_4~6` 是**亮黄绿色块堆**。

**修法**：

| 物种 | TFC 参考 | 说明 |
|---|---|---|
| `broccoli_leafball_0..5` | `cabbage_0..5` | 同为叶球类，年龄数完全匹配 |
| `broccoli_leafball_head` | `alfalfa_5` + 自身错位叠加 + **填满所有洞** | `_head` 是中心立方体**六面共享**的贴图 ⇒ **必须全铺满**（op=256） |
| `brussels_sprouts_0..6` | `soybean_0..6` | 直立茎 + 沿茎侧枝（抱子甘蓝的形态），7 档匹配 |

**🛑 三个坑**：

1. **调色板过暗**：第一版 `broccoli_leafball` 的 LUM 只有 55~82、`_0` 甚至 `col=1`（单色）。
   换亮绿（`B=7ECB45,d=5CA82E,s=3E7A1E,g=2A5A12`）后到 74~117 ✓。
2. **`soybean` 骨架左右完全镜像** ⇒ `brussels_sprouts_3~6` 像"鱼骨/圣诞树"。
   修法：**自身错位叠加**（`overlay ShiftX 3`）打破对称。
3. **overlay 会破坏单调性**：`_3`~`_6` 全叠加后得到 `46/82/80/86`（`_5` < `_4`）✗。
   改成**只对 `_5/6` 叠加** ⇒ `5/19/27/46/49/80/86` ✓ 单调。

**验收**：`px/CT-NEW-brassica4.png`、`px/CHK-brassica-3d.png`。

### 第 25 轮 · `amaranth`（12 张，苋菜）

**判废理由**（p1）：`_0~3` 是「绿色小树」（圆冠 + 细茎，4 张几乎一样）；
`_4~7_bottom` 是**绿色"心形/V 形"几何大块**；`_4~7_top` 是**粉红几何"花"**。

**修法**：TFC `sugarcane` 的年龄结构与我方 `amaranth` **完全一致**（0-3 单层 + 4-7 双段），
且是直立高秆 ⇒ 逐张 `transplant`（含 `_bottom`/`_top`）：

| 步骤 | 内容 |
|---|---|
| 1. 骨架 | `sugarcane_0..3` + `sugarcane_4..7_bottom/top` |
| 2. 调色板 | `B=6CB33A,d=4E8C28,s=35661A,g=244A10,r=8A2A2A` ⇒ `r` 落在第 2 档（**茎的位置**）⇒ **红褐茎**（红苋特征） |
| 3. 穗 | 脚本把 `_top` 的**顶部 3 行全部改红 + 再 2 行隔点改红** ⇒ **顶部大团圆锥花序** |
| 4. 接缝 | `seam-audit -Fix` + **同步设计稿**（`_top` 第 15 行 := `_bottom` 第 0 行）⇒ **72 对齐 / 0 错位** |

**🛑 本轮踩的坑**：`seam-audit -Fix` **只改 PNG，不改设计稿** ——
下次从设计稿重渲染接缝又会错。**必须手工把 `_top` 设计稿的第 15 行同步成 `_bottom` 的第 0 行**
（本轮已同步 4 对，并把这条写进流程）。

**密度**：单层 `27/70/121/158` ✓；双段内部 `_bottom` 递减（159→154→146→141）、
`_top` 递增（55→94→133→171）—— 这是"生长自下而上"的正确表现。

**验收**：`px/CT-NEW-amaranth3.png`（2D 12 张）、`px/CHK-amaranth-3d.png`（3D，顶部红穗明显）。

### 第 24 轮 · `buckwheat`（8 张，荞麦）

**判废理由**（p4）：`_0~4` 是「**橙色柱 + 绿色三角**」（像镰刀/半月），`_5~7` 是「橙色弯枝 + 白色方块」，
完全不是荞麦。

**修法**：按 docs/88 既定计划复用 **`einkorn` r21 骨架**（同为 8 档单层谷物），逐张 `transplant`：

| 版本 | 调色板（按亮度排序） | 结果 |
|---|---|---|
| v1 | `k,g,s,r,d,B,w`（`r` 在第 4 档） | 红褐占 1/3 ⇒ 像"枯草花斑" ✗ |
| v2 | 把 `r` 压到第 3 档 | **更糟**：暗部两个红褐 ⇒ 整张偏棕 ✗ |
| v3 | **`r` 作为唯一最暗档** | ✓ 红褐只出现在茎 ⇒ 红茎 + 绿叶 + 顶端白花，符合荞麦 |
| v4 | `_3/4/5` 再做 `overlay`（自身 ⊕ 自身，X 偏 2px） | ✓ **叶变宽**，与 einkorn 的"细长斜叶"区分开 |

**关键教训**：**transplant 的调色板排序就是"颜色的面积分布"** ——
把一个颜色放在第 N 档，它就占第 N 档亮度的那些像素。荞麦的红茎必须放在**最暗档**（茎的位置），
放在中间档就会变成"整片棕色"。

**密度**（TFC `rye`/`wheat` 基准 7/16/33/58/79/104/126/139）：
`6/14/46/95/117/148/150/156` ✓ 单调。

**验收**：`px/CT-buckwheat-vs-einkorn2.png`（上=荞麦 / 下=einkorn，形态与颜色均可区分）、
`px/CHK-buckwheat-3d.png`（3D）。
