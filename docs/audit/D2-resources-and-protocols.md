# D2 资源与数据协议审查报告

> 日期：2026-10-28  
> 审查对象：`mod_rebuild/`（新版开发树）  
> 范围：A `tfcfarmingplus` 与 B `tfcagricultureplus` 的 `src/main/resources`，以及两者 `tools/` 中的资源合同/审计脚本  
> 方式：**只读**。除本报告与 `docs/audit/` 下的临时脚本/CSV 外，未修改任何源码、资源、构建文件或现有文档；未运行任何会写资源的生成器。  
> 证据：本目录下 `d2-*.csv`、`d2-*.txt`、`d2-index.json`，脚本见 §8。

---

## 0. 结论摘要

### 5 条最重要发现

1. **P0｜新构建会把 949 个模型的贴图引用回退成 TFC 占位，949 张自有贴图全部“失联”**。以已发布旧 jar（`mods/TFCFarmingPlus-NeoForge-...jar`）为基准，当前源码树有 **949 个模型**（`block/crop` 609、`block/dead_crop` 138、`block/wild_crop` 73、`item/seeds` 84、`item/food` 39、`item/fiber` 4、`cotton_boll`/`hops` 各 1）在旧 jar 中引用 `tfcfarmingplus:` 自有贴图，现在全部改成 `tfc:` 借用贴图；这 949 张自有贴图在当前树中**全部存在**（缺失 0）。按当前树构建出的 `artifacts/*.jar` 已确认携带回退后的模型（`d2-model-ref-regression.txt`）。
2. **P0｜275 分层时 6 个整瓜模型丢失了 `textures` 覆盖，游戏里会显示成 vanilla 西瓜**。`models/block/melon/{cantaloupe,winter_melon,bottle_gourd,rotten_*}.json` 现在只有 `{"parent":"minecraft:block/melon"}`；旧 jar 同名模型带有 `side`/`end` 自有贴图覆盖。12 张 `textures/block/melon/*_fruit_{side,top}.png` 因此全部无引用（死贴图）。
3. **P1｜B 有 389 个方块没有 loot table**：B 的 492 个 blockstate 只有 103 个方块有 `data/tfcagricultureplus/loot_table/blocks/*`（34 木×3 种 timber 料 + silkworm_rack）。全部案板/刀架/晾架/6 类厨房柜/石臼/顶层功能方块破坏后**不掉落任何物品**（除非另有代码覆写，Java 中未见 `getDrops` 覆写）。
4. **P1｜B 有 16 处模型贴图引用指向不存在的贴图**（Firmalife 面团路径写错、B 自有 `item/flint_pestle`/`item/food/cake_slice` 缺图、`whole_pie` 引用不存在的 `minecraft:block/pumpkin`），另有 1 个已注册物品 `food/pan_seasoned_vegetables` 完全没有 item 模型、其配方产出物在游戏内会是缺失模型。
5. **P1｜A 的 1130 张死贴图（≈241 KB）中 949 张是“等接入”的正式资产，不是垃圾**：死贴图总量 1,130 张（`textures/block` 965、`textures/item` 165），其中 949 张恰好是第 1 条回归里旧 jar 用到的贴图；其余 181 张属历史遗留（含 12 张 melon、5 张 plant、部分 food/seeds）。**清理风险很高**：按“未引用就删”处理会一次性删掉 84% 的自有作物美术。

### 问题清单（P0/P1/P2）

| 级别 | 编号 | 问题 | 数量/规模 | 建议动作 |
|---|---|---|---|---|
| P0 | R-1 | 949 个模型贴图回退 TFC 占位；新 jar 视觉回退 | 949 模型 / 949 贴图 / 65 个物种前缀 | 恢复模型贴图引用（从旧 jar 回写，或跑修正后的 `localize-textures.ps1`），再构建 |
| P0 | R-2 | 6 个瓜模型丢失 `textures` 覆盖，显示 vanilla 西瓜 | 6 模型 / 12 贴图 | 用旧 jar 版本恢复 6 个模型的 `textures` 块 |
| P1 | B-1 | B 389 个方块无 loot table | 389 / 492 | 补 `loot_table/blocks/<id>.json`（可脚本批量） |
| P1 | B-2 | B 16 处缺失贴图引用 | 16 | 改模型贴图路径（Firmalife 实际为 `*_flatbread_dough`；补 B 自有贴图；`whole_pie` 改用 `pumpkin_side/top`） |
| P1 | B-3 | `food/pan_seasoned_vegetables` 无 item 模型，配方产出缺失模型 | 1 物品 + 1 配方 | 补 `models/item/food/pan_seasoned_vegetables.json` |
| P1 | B-4 | 未声明 `afc` 依赖但注册/模型引用 AFC 树种与贴图 | 14 树种 | 在 `neoforge.mods.toml` 声明 afc（required 或 optional+条件跳过） |
| P2 | A-1 | A 缺 106 个方块 lang key（branch/growing_branch 98 + bush_cane 8） | 106 | 补 lang（技术方块，优先级低） |
| P2 | A-2 | A 5 个 rosette `dead_crop.*` lang key 无对应方块 | 5 | 删除或保留（无害冗余） |
| P2 | A-3 | A 的 3 个死模型（branch_fruit / cocoa_branch_fruit_{unripe,ripe}） | 3 | 归档（Java 0 引用） |
| P2 | A-4 | A 8 张贴图与 TFC 逐像素相同（strawberry 作物整套借用 TFC 灌木图） | 8 | 保持（占位）或重画（用户审美标准下应重画） |
| P2 | A-5 | A 6 个 `assets/tfc/models/block/crop/cabbage_age_*.json` 覆盖 TFC 原模型 | 6 | 保留（有意的跨模组覆盖），在文档标注 |
| P2 | B-5 | 2 个新增配方误放在 `data/tfc/recipe/`（tfc 命名空间） | 2 | 迁移到 `data/tfcagricultureplus/recipe/` |
| P2 | B-6 | 2 个 lang 值为空（`gui.tfcagricultureplus.silkworm_container`） | 2 | 补文案 |
| P2 | B-7 | 4 个物品缺 lang（flint_pestle、dried_ginger/napa_cabbage/turmeric） | 4 | 补 lang |
| P2 | B-8 | `log_pile`/`burning_log_pile` 的 blockstate 全部指向空模型，靠 BE renderer 渲染 | 64 变体×2 | 保持（设计），文档标注风险 |
| P2 | H-1 | 2,572 个文本文件为 CRLF；325 组完全重复文件（冗余 200,878 B） | 2572 / 325 组 | 统一 LF、去重（可选） |
| P2 | H-2 | 无 `pack.mcmeta`（NeoForge mod 资源包不强制，构建产物同样无） | — | 保持 |

---

## 1. 审查范围与方法

- **本地资源**：A 5,922 文件 / 3,850,000 B；B 3,031 文件 / 1,084,754 B（`d2-category-stats.csv`）。
- **外部参照**（用于跨命名空间存在性判定）：TFC 4.2.11 jar（43,177 entries）、Firmalife 3.0.15（5,981）、afc 2.1.3（10,778）、vanilla 1.21.1 client-extra（15,250）、已发布旧 A jar（5,789）、artifacts 新 A jar（5,968）、旧 B jar（549）、artifacts 新 B jar（3,136）。索引见 `d2-index.json`。
- **口径与限制**：
  - “存在性”对 `tfc:`/`minecraft:`/`firmalife:`/`afc:` 以对应 jar 内资源路径为准（不反编译注册表）；
  - 对 `tfcfarmingplus:`/`tfcagricultureplus:` 以本地资源 + Java 静态提取的注册 ID 为准（提取规则见 `d2_refs.py` 的 `extract_registry`；`plant/*`、`wild_crop/*` 等变量拼接族采用族级规则校验）；
  - blockstate 属性覆盖以“变体结构 + TFC 同形状参考模板”判定，不反编译全部方块类；
  - 所有计数均可由 §8 的脚本复现。

---

## 2. 资源清单

### 2.1 A `tfcfarmingplus`（`d2-category-stats.csv`）

| 分类 | 文件数 | 字节 | 备注 |
|---|---:|---:|---|
| blockstates | 481 | 235,897 | crop 87 / dead_crop 82 / plant 218 / wild_crop 87 / 顶层 7 |
| models/block | 1,652 | 316,770 | 另有 6 个在 `assets/tfc/models/block/crop/`（覆盖 TFC） |
| models/item | 435 | 32,311 | fiber 4 / food 142 / plant 110 / seeds 87 / wild_crop 87 / 顶层 5 |
| textures/block | 1,487 | 403,686 | crop 882 / dead_crop 170 / fruit_tree 294 / melon 12 / plant 43 / wild_crop 86 |
| textures/item | 330 | 87,982 | fiber 4 / food 177 / plant 61 / seeds 86 / 顶层 2 |
| loot_table | 481 | 412,258 | `loot_table/blocks/**`，与 blockstate 1:1 |
| loot_modifiers | 50 | 10,655 | 果树树叶 → firmalife 掉落复用 |
| tags | 31 | 61,972 | 自有 2 / 注入 tfc 19、minecraft 4、c 5、firmalife 1 |
| lang | 2 | 68,373 | en_us/zh_cn 各 619 key |
| tfc/climate_range | 148 | 10,147 | 作物 + 果树 |
| tfc/food | 145 | 17,232 | 食物营养数据 |
| worldgen | 492 | 109,202 | configured 246 + placed 246 |
| patchouli_books | 26 | 2,005,981 | 覆盖 TFC 手册（en/zh 分类与条目 + 8 语言 wild_fruits） |
| data/firmalife | 156 | 77,534 | 果树 firmalife 数据 |
| **合计** | **5,922** | **3,850,000** | |

### 2.2 B `tfcagricultureplus`

| 分类 | 文件数 | 字节 | 备注 |
|---|---:|---:|---|
| blockstates | 492 | 218,531 | 34 木族 × 多个 + 21 石案板 + 15 臼 + 14 顶层 |
| models/block | 506 | 103,857 | timber 4 / 各族 34 / 顶层族若干 |
| models/item | 636 | 117,729 | bark 34 / bast 34 / 各族 34 / food 59 / 顶层 30 |
| textures/item | 57 | 16,782 | bark 20 / bast 20 / food 6 / 顶层 11（**无自有 textures/block，方块贴图复用 TFC**） |
| loot_table | 103 | 45,059 | 仅 timber 3×34 + silkworm_rack（见 P1 B-1） |
| recipe | 938 | 381,440 | 自有 756 + 禁用 TFC 182（其中 2 个是误放的 B 新配方） |
| tags | 24 | 20,276 | 自有 17 + 注入 tfc 2、minecraft 1、c 4 |
| lang | 2 | 103,629 | en/zh 各 718 key |
| tfc 数据 | 253 | 34,424 | food 64 / fuel 170 / item_heat 15 / item_size 4 |
| patchouli_books | 12 | 11,162 | 3 分类 + 3 条目 × en/zh |
| sounds | 3 | 29,778 | |
| META-INF/licenses | 2 | 1,302 | TFC Woodworking MIT + notice（**必须保留**） |
| **合计** | **3,031** | **1,084,754** | |

---

## 3. 死内容与占位内容

### 3.1 A：1,130 张死贴图 + 3 个死模型（`d2-A-issues.csv`）

按目录与体积：

| 资源 | 数量 | 体积 | 代表性文件 | 判定 |
|---|---:|---:|---|---|
| textures/block/crop | 716 | 154,237 B | `crop/sorghum_age_5_top.png`、`crop/ginger_age_2.png` | 949 回归的主体现：模型改用 `tfc:block/crop/{sugarcane,tomato,beet}_N`，自有图不再被引用 |
| textures/block/dead_crop | 149 | 29,330 B | `dead_crop/lupin.png` | 同上（模型改用 `tfc:block/{dead_crop,dead_crop_young}` 占位） |
| textures/block/wild_crop | 83 | 20,438 B | `wild_crop/hemp.png` | 同上（模型改用 `tfc:block/crop/*_wild`） |
| textures/block/melon | 12 | 3,909 B | `melon/cantaloupe_fruit_side.png` | **P0 R-2**：6 个瓜模型丢失 textures 覆盖 |
| textures/block/plant | 5 | 1,261 B | `plant/branch_fruit.png` | 3 个死模型的配套贴图 |
| textures/item/seeds | 84 | 16,511 B | `item/seeds/spinach.png` | 模型改用 `tfc:item/seeds/{lentil,beet,rice}` 占位 |
| textures/item/food | 75 | 19,986 B | `item/food/spinach.png` | 模型改用 `tfc:item/food/*` 占位（旧 jar 中为 `food/spinach` 等） |
| textures/item/fiber | 4 | 929 B | `item/fiber/flax.png` | 模型改用 `tfc:item/jute_fiber` |
| textures/item/{cotton_boll,hops} | 2 | 379 B | `item/cotton_boll.png` | 模型改用 `tfc:item/wool_yarn` / TFC 物品图 |

- **总计：1,130 张、246,980 B（≈241 KB）**；其中 **949 张可由旧 jar 的模型引用一一对上**（回归），其余 181 张为历史遗留。
- **3 个死模型**：`plant/branch_fruit.json`、`plant/cocoa_branch_fruit_unripe.json`、`plant/cocoa_branch_fruit_ripe.json`。Java 中 0 处引用（`branch_fruit`/`cocoa_branch_fruit` 检索为 0）；`cocoa_branch` 的 multipart 只引用 `cocoa_branch_{core,down,side,up}`。是“枝干果实改为 blockstate `fruit` 属性”之后未清理的旧几何。
- **占位/拷贝**：
  - 8 张 strawberry 作物贴图（**活贴图**，模型正在引用）与 TFC `berry_bush/*_strawberry_bush.png` **逐像素相同**（`d2-texture-summary.txt`）；即游戏内的草莓作物直接显示 TFC 灌木美术。
  - 2 张全透明贴图 `crop/broccoli_age_0.png`、`crop/kale_age_0.png`（colors=1、opaque=0）——均为死贴图（当前模型用 `broccoli_leafball_0`/`kale_rosette_0`），属占位残留；
  - 84 张色数 ≤3 的贴图中 61 张是死贴图；余 23 张是活贴图，多为苗期稀疏图（**不应按“低色数=占位”判废**，TFC 苗期本来就稀疏）。
- **重复/同构模型**：`d2-duplicates.csv` 中 A 的重复组主要是“同类模型的合法同构”（如 13 个 `*_age_0.json` 内容相同、不同物种共用贴图参数），不算冗余；真正可清理的是 3 个死模型与 5 个 rosette lang key。

### 3.2 B：0 死贴图，但有 16 处缺失引用与 1 个空模型

- B 的 58 张 PNG 全部被引用（`dead=0`）。
- `block/timber/pile_particle.json` 为 `{"textures":{"particle":...},"elements":[]}`，被 `log_pile`/`burning_log_pile` 的 64 个变体全部引用。**不是失效资源**：`TimberPileBlockEntityRenderer` 用 TFC `log_pile` 模型按 BE 渲染，方块本身模型只提供粒子贴图。风险：渲染器失效时方块不可见（P2 B-8）。
- 16 处 MISSING_TEXTURE 见 §4.2。

### 3.3 清理风险提示

**dead_*/rotten_* 的实际使用情况（不是死内容）**：A 的 `dead_crop/*` 82 个 blockstate 全部有模型引用、且在 481 份 loot table 覆盖范围内（0 缺失）；`wild_crop/*` 87 个同样全部使用；3 个 `rotten_{cantaloupe,winter_melon,bottle_gourd}` 单变体方块也被 blockstate 引用并各有掉落表。唯一问题是这 6 个“整瓜/腐烂瓜”模型都只有 `parent: minecraft:block/melon`（R-2），而不是资源未被使用。

- **不能按“未被引用就删”处理 A 的死贴图**：949/1,130 恰是待接入的正式资产；删除后即使回写模型也没有贴图可用。
- 可安全删除/归档的：3 个死模型、5 个 rosette `dead_crop.*` lang key、2 张全透明占位贴图（`broccoli_age_0`/`kale_age_0`，但需先确认不再作为 `X_age_N` 约定名保留）。
- **需先回写模型再评估**：A 的 949 张贴图；melon 12 张。

---

## 4. 协议检查

### 4.1 blockstate（A 481 / B 492）

- **JSON 可解析率 100%**（A/B 全部 blockstate 与模型均通过 `json.loads`；`d2-file-problems.csv` 无 `BAD_JSON`）。
- **变体结构完整，0 结构性问题**（`d2-blockstate-problems.csv` 为空）：
  - A 普通作物 `age=0..5/6`；双段 `age=0..N` + 高龄 `part=bottom/top`（与 TFC `crop/maize` 9 变体同构）；攀爬 `age×stick×part`（与 TFC `crop/tomato` 20 变体同构）；莲座 **12 变体（age 0-5 × fruiting false/true）**——历史 bug（kale 缺 fruiting）未复发；灌木 `lifecycle×stage` 12；甘蔗 `lifecycle×facing×stage` 48；死株/野生 `mature` 2；死双段 `mature+part` 3 结构；果树 `saplings=1..4`、leaves `lifecycle` 4、branch/growing_branch 为 multipart。
  - B 479 个 `facing` 变体全部覆盖 `north/east/south/west`；`log_pile`/`burning_log_pile` 为 `axis×layers(1..16)` 64 变体。
- 未发现“变体键属性名拼写错误/空值/重复键”；未发现变体数少于 TFC 同形状参考模板的情况。
- 唯一注意事项：A 的 `crop/*` 中双段/攀爬的**低龄单格段没有 `part`/`stick=true` 变体**，与 TFC 一致，不是缺失（早期审计若用“每个 age 都必须有 part”会误报，本报告已按 TFC 模板口径）。
- 275 文档要求“blockstate 只移动不改名”已遵守：`blockstates/` 无子目录搬动。

### 4.2 model / item model

- **parent 与引用存在性**：A/B 的 `models/block`、`models/item` 解析后 **MISSING_PARENT = 0、MISSING_MODEL = 0**（`d2-A-issues.csv`/`d2-B-issues.csv`）。
- **贴图引用**：
  - A：**MISSING_TEXTURE = 0**；8 条 `UNRESOLVED_TEXTURE_VAR` 均为**共享几何的合法变量**（`plant/trunk_{core,side,up,down}.json` 用 `#bark`，由 49 个 `*_branch_*.json` 在 parent 引用时提供 `bark`），不是缺陷。
  - B：**16 条 MISSING_TEXTURE**：
    - 12 条 `item/food/raw_{wheat,oat,barley,maize,rye,rice}_{naan,bun}` → `firmalife:item/food/{grain}_dough`（Firmalife 实际为 `*_flatbread_dough`，路径写错）；
    - `item/flint_pestle` → `tfcagricultureplus:item/flint_pestle`（B 无此贴图）；
    - `item/food/{chocolate,cream}_cake_slice` → `tfcagricultureplus:item/food/cake_slice`（B 无此贴图）；
    - `block/food/whole_pie` → `minecraft:block/pumpkin`（vanilla 只有 `pumpkin_side/top`）。
- **item model 覆盖**：
  - A：物品模型 435 个，静态提取物品 221 个；差集集中在果树/灌木等变量拼接族（人工核对见 `d2-placeholders-A.csv`），未发现真实“已注册无模型”的证据。
  - B：静态注册物品 150，**真实缺 item 模型 1 个**：`food/pan_seasoned_vegetables`（Java `AgricultureItems` 中有 `registerSimpleItem`，`models/item/food/` 无对应文件）；其配方 `pan/seasoned_vegetable_pan.json` 产出该物品 → 游戏内为缺失模型。
- **空模型/不可见模型**：B `block/timber/pile_particle`（`elements: []`，设计见 §3.2）；A 无。
- **元素协议**：A/B 自有 `elements` 模型中 **rotation.angle 全部合法**（-45/-22.5/0/22.5/45），**无零厚度面类型错配**（`ZERO_THICK_FACE_AXIS = 0`，即第 48 轮教训未重现），无越界 from/to 告警。

### 4.3 loot table

- A：`loot_table/blocks` 481 个，与 481 blockstate **1:1 全覆盖**；`loot_modifiers` 50 个引用的 `loot_table_id` 与 `firmalife:blocks/fruit_leaves` 均存在；掉落物 `name`（`tfcfarmingplus:food/*`、`seeds/*`、`minecraft:stick` 等）抽查与 `models/item` 一致。
- A 的 function/condition 类型全部在 TFC/vanilla 白名单内（`tfc:crop_yield_uniform` 等）。
- B：**103/492**，缺 389（P1 B-1）；缺失清单与族分布见 `d2-data-summary.txt`：
  - `cutting_board/*` 55（34 木 + 21 石）
  - `counter_cabinet/*`、`drying_rack/*`、`food_display/*`、`fruit_bowl/*`、`half_cabinet/*`、`knife_block/*`、`log_cutting_board/*`、`sink_cabinet/*`、`spice_rack/*` 各 34（9 族共 306）
  - `mortar/*` 15
  - 顶层 13：`burning_log_pile`、`butter_block`、`chocolate_cake`、`cooking_pan`、`cream_cake`、`dough_forming_table`、`jelly_block`、`melting_pot`、`sugar_block`、`whole_cake`、`whole_cheese`、`whole_pie`、`whole_cake`
  - `log_pile`/`burning_log_pile` 有 BE 库存回收逻辑（空手取回），可视为设计；其余功能方块破坏不掉落会丢材料。
- 另：B 的 `data/tfcagricultureplus/tfc/food/pan_seasoned_vegetables.json` 引用 `tfcagricultureplus:food/pan_seasoned_vegetables`，与 B-3 同一物品。

### 4.4 tags

- A 31 + B 24 个 tag 全部可解析，**values 引用 0 缺失**（`MISSING_TAG`/`MISSING_ID` 均为 0）：
  - A 的 `#tfc:...`/`#c:...` 注入、B 的 `#tfc:log_pile_logs` 追加均有效；
  - 未发现空 tag、自引用、重复值。
- 注入型 tag（如 A 的 `data/tfc/tags/block/crops.json`、`fruit_tree_branches/leaves/saplings`；B 的 `data/minecraft/tags/block/mineable/axe.json`）使用 `replace:false`，属增量注入，安全。
- **风险点**：B 的 `mineable/axe` 由 `generate-timber-resources.py` 生成器直接改写，重跑生成器需要 workspace 的 `.tooling/reference/tfcwoodwork-license.json`（当前 `mod_rebuild` 未复制 `.tooling`）→ 生成链不可复现（P2，见 §6）。

### 4.5 lang

- A：`en_us` 与 `zh_cn` 各 619 key，**key 集合完全一致**；缺 106 个 `block.*`（`plant/*_branch` 98 + `*_bush_cane` 8，均为技术方块）；5 个冗余 `block.tfcfarmingplus.dead_crop.{cardoon,agave,purslane,kale,sisal}`（莲座作物无 per-crop 死株方块）。
- B：各 718 key，**集合一致**；缺 4 个物品 lang（`flint_pestle`、`food/dried_ginger`、`food/dried_napa_cabbage`、`food/dried_turmeric`）；2 个空值（`gui.tfcagricultureplus.silkworm_container` en/zh 均为空）。
- 3 个 `item.tfcfarmingplus.{winter_melon,bottle_gourd,cantaloupe}` 不是孤儿：它们是瓜方块物品，用 `item.*` 键显示正确（审计脚本的“同名 blockstate 才排除”口径误报，已人工甄别）。

### 4.6 recipe（仅 B）

- 938 个 recipe JSON **全部可解析**；type 分布：`tfcagricultureplus:in_world` 409、`minecraft:crafting_shaped` 277、禁用 TFC 配方 180（无 type，仅 `neoforge:conditions:{"type":"neoforge:false"}`）、`tfcagricultureplus:cutting_board` 15、`firmalife:oven` 15、`food_mixing_bowl` 13、`tfc:knapping` 7、`advanced_shapeless_crafting` 4、`mortar` 4、其余各 1~3。
- **自定义 type 与 Java 注册一致**（5 种：`in_world`/`cutting_board`/`food_mixing_bowl`/`mortar`/`pan`；`AgricultureRecipeTypes`/`Serializers` 中注册），无未知自定义 type。
- 必填字段启发式检查：`in_world` 全部含 `input_state/tool/result_state`；`shaped` 全部含 `pattern/key/result`；0 缺字段。
- **禁用 TFC 配方有效性**：182 个 `data/tfc/recipe/**` 文件中 180 个是“仅 `neoforge:conditions`”的禁用文件，**其路径全部在 TFC jar 中真实存在**（0 个无效目标）；另 2 个 `data/tfc/recipe/{heating,pot}/sawdust_bread.json` 不是禁用文件，而是 B 自己新增的 TFC type 配方**误放在 `data/tfc/` 命名空间**（P2 B-5；TFC jar 中无同名文件，配方 ID 会被注册为 `tfc:*`）。
- **引用完整性**：11 条 `MISSING_REF` 中 10 条是 tag 引用（`#tfcagricultureplus:foods/...`、`#tfcfarmingplus:materials/plant_fibers`），按 tag 复核均存在；唯一真实缺失是 `food/pan_seasoned_vegetables`（P1 B-3）。

### 4.7 worldgen（仅 A）

- configured_feature 246、placed_feature 246，**引用闭环 0 缺失、0 未被引用**：
  - `plant/*_tree`（49）引用 `tfc:fruit_trees` + `state: tfcfarmingplus:plant/*_growing_branch`；
  - `plant/wild_crop/*` 单株 + `*_patch` 配对，placed 引用 configured 全部存在；
  - placement type 全部为 `minecraft:*`/`tfc:*` 已知类型。
- 结论：A 的 worldgen 数据协议健康。

### 4.8 TFC 数据（climate_range / food / fuel / item_heat / item_size）

- A：148 climate_range + 145 food，字段结构与 TFC 同 codec 文件一致；`CLIMATE_MISSING=49` 是**误报**——TFC 自身的 `climate_range/crop/cassava.json` 也缺 `max_hydration` 等字段（可选字段），A 的树 climate 只写必需的温度/湿度是合法的。
- B：253 个 tfc 数据（fuel 170 / food 64 / item_heat 15 / item_size 4），字段抽检与 TFC 一致；唯一引用问题是 `food/pan_seasoned_vegetables`（B-3）。

### 4.9 元数据（B mixin / mods.toml / AT）

- B `tfcagricultureplus.mixins.json`：`package=io.github.likexiang21.tfcplus.agriculture.mixin`、`mixins=["OvenTopBlockEntityMixin"]`，对应 Java 文件存在（`MISSING_MIXIN_CLASS=0`）。
- A/B 的 `neoforge.mods.toml` 均由 `src/main/templates` 经 Gradle `expand` 生成：A 声明 tfc/patchouli/neoforge/minecraft 4 个依赖；B 声明 tfcfarmingplus/tfc/firmalife/patchouli/neoforge/minecraft + jei(optional) 7 个依赖，并声明 mixin config。
- **无 access transformer 文件**（全树 `*.cfg`/`*_at.cfg` 为 0），构建也未引用 → 与“无 AT”一致，不存在悬空 AT。
- **B 未声明 `afc` 依赖**，但 `AFC_WOODS` 14 树种被注册、模型引用 `afc:block/wood/...` 贴图、配方引用 afc 物品（P1 B-4）。
- `pack.mcmeta` 缺失：NeoForge mod 资源包不需要，旧/新构建产物同样没有 —— 仅记录，不算问题。

### 4.10 命名、大小写、编码、无关文件

- **路径大小写**：资源路径无大写字母（`UPPERCASE_PATH` 仅命中 `META-INF/licenses/*.txt`，非资源路径，忽略）。
- **非 ASCII 路径**：0。
- **BOM / 非法 JSON / 0 字节文件**：0（`d2-file-problems.csv` 只有 CRLF）。
- **CRLF**：2,572 个文本文件为 CRLF（JSON 解析不受影响，属格式统一问题，P2 H-1）。
- **无关文件**：无 `.DS_Store`/`Thumbs.db`/`*.zip`/`*.bak`/`preview`/临时图。
- **完全重复文件**：325 组（冗余 200,878 B），主要是 B 的 180 份禁用配方（68 B 同内容）、A 的 49 份相同果树掉落表（292 B）、A 的若干同构模型 —— 见 `d2-duplicates.csv`；均属模板化重复，不是错误。
- A 的 `build.gradle.kts` 里有 `exclude("assets/tfcfarmingplus/textures.zip")`，但源码树中**不存在**该 zip（历史遗留排除项，无害）。

### 4.11 tools 资源合同 / 审计脚本（`d2-contracts.csv`）

- **A 的 8 份 display-contract + reviewed-item-icon-routes**：
  - 全部 `*Sha256` 基线共 **407 个受保护文件（贴图/模型/数据/Java 源码）存在且 SHA256 匹配，mismatch=0、missing=0**；
  - `reviewed-item-icon-routes.json` 的 81 张受保护贴图 + 41 份 FoodData SHA 全匹配，44 条图标路由路径全部存在；
  - `crops-manifest.json` 87 物种对应的 `crop/<name>`、`dead_crop/<name>`（莲座除外）blockstate 全存在（缺失 0）；
  - `fruit-trees-manifest.json` 49 树种的 `plant/<name>_{sapling,leaves,branch,growing_branch}` blockstate 全存在（缺失 0）。
- **B 的 verify/audit 脚本**：`tools/` 下 20 个 verify 脚本与 `scripts/` 中的资源路径引用，0 处指向不存在的文件。
- **关键结论（流程缺陷）**：合同全绿**并不代表美术正确**。display-contract 的 `ReviewedJsonSha256` 目前绑定的正是**当前树的 TFC 占位版模型**（因此 R-1 的 949 个回退不会被合同发现）。建议合同增加两条断言：
  1. `models/block/crop/**` 的 `textures` 值必须全部是 `tfcfarmingplus:` 命名空间（禁止 `tfc:` 借用，白名单除外）；
  2. 受保护贴图清单与“模型实际引用的贴图集合”做交集校验——贴图存在但无模型引用时报警（本轮 1,130 张死贴图会被立即发现）。
- 合同/清单本身与当前树一致，可继续作为生成与审计基线；**不要**把合同 SHA “重新基线”到回退后的模型上（那等于给回归盖章）。

---

## 5. 保留 / 删除 / 迁移矩阵

| 类别 | 处理 | 依据 |
|---|---|---|
| A/B 全部 `blockstates/*.json` | **必须保留，不可改名/移动** | 路径 = 方块注册 ID，改动破坏存档与模型解析 |
| A 的 949 张“回归”死贴图 | **保留并回写模型引用** | 旧 jar 证明其被使用；是用户美术成果 |
| A 的 melon 12 张贴图 + 6 个模型 | **保留；恢复模型 textures 覆盖** | P0 R-2 |
| A 的 181 张历史遗留死贴图 | **归档（不删源码树）** 或接入 | 详见 `d2-A-issues.csv` |
| A 的 3 个死模型 | **可删除/归档** | Java 0 引用、blockstate 0 引用 |
| A 的 5 个 rosette dead_crop lang key | 可删除 | 无对应方块 |
| A 的 6 个 `assets/tfc/models/block/crop/cabbage_age_*` | **保留**（覆盖目标存在，有效） | 跨模组覆盖，需文档标注；改路径会让覆盖失效 |
| A 的 patchouli 26 文件 | **保留**；修改需同步 TFC 手册版本 | 566 个 `tfcfarmingplus:` 引用全部存在 |
| B 的 180 个禁用 TFC 配方 | **必须保留**（路径与 TFC 一致） | 180 有效 + 2 误放新增；删除会导致 TFC 原配方回来 |
| B 的 2 个误放配方 | **迁移**到 `data/tfcagricultureplus/recipe/{heating,pot}/` | 配方 ID 变为 `tfcagricultureplus:*`，影响小 |
| B 的 389 个无 loot 方块 | **补 loot table**（不涉及 ID 迁移） | 需与方块 ID 同名 |
| B 的 `META-INF/licenses/*` | **必须保留** | TFC Woodworking MIT 许可要求 |
| B 的 AFC 树种相关资源 | 保留；补 `afc` 依赖声明 | P1 B-4 |
| A/B 的 blockstates 变体 | 保留现状（0 结构问题） | — |

---

## 6. 与文档计划的偏差

1. **275 号文档（资源路径分层）**
   - 已完成且验证通过的部分：A 的 6 个 `melon/` 模型 + 12 张 `melon/` 贴图、2 个 `plant/dead_rosette*`、B 的 18 个族目录模型——**引用完整（0 missing parent/model/texture）**；`artifacts/` 新 jar 与源码树**逐文件一致**（A 模型 2087=2087）。
   - **偏差**：275 只“移动路径”，未校验移动后的**内容**。6 个 melon 模型在移动时使用了只有 `parent` 的占位版本（旧 jar 的 `textures` 覆盖丢失）→ 见 P0 R-2。建议 275 补一条验证：移动后比对文件内容 SHA 与移动前一致。
2. **A 的贴图/几何历史**
   - 旧 jar（用户上一实机版本）中 754/765 个 crop 模型引用自有贴图；当前树 609 个 crop 模型引用 TFC 占位 —— 即当前树回到了“贴图已画完但模型未 localize”的中间态。结合 `gen-crops.ps1` 第 586 行注释“作物模型（借用 TFC 贴图占位）”与 `localize-textures.ps1` 的幂等设计，可以判定：**当前树是 gen-crops 的输出态，尚未跑 localize**；`moddev` 旧树与 `mod_rebuild` 同为该状态（不是复制/275 引入，而是旧树本身未跑最后一步）。
   - 74/275 文档中“资源 SHA 与旧树一致”成立（复制无偏差），但“旧树=已发布 jar”不成立（旧 jar 构建后旧树又被 gen-crops 重跑过）。
   - 与 AGENTS.md 第 48 轮记录（“瓜类 P0 已修复为自包含立方体 + 自有贴图”）不一致：当前树仍是 vanilla melon parent 版本 → 说明该修复未随旧树保留（或修复只在旧 jar 构建中）。
3. **A 的莲座/叶球几何历史**：blockstate 12 变体完整、共享几何变量合法，未见第 48 轮教训复发（无零厚度面错配、无 UV/角度告警）。
4. **工具合同/审计脚本与回退的关系**：`tools/contracts` 的 407 个 SHA 基线在**当前树**上全部匹配（`d2-contracts.csv` 0 问题），但当前树的 949 个模型是 TFC 占位版——即合同基线是在模型回退之后重新建立的，**门禁无法发现 R-1**。这与 274 号文档“合同已重新基线、0 个哈希不匹配”的结论一致，但需要补一句：重新基线只能保证“与当前树一致”，不能保证“与已发布美术一致”。

---

## 7. 建议动作

### P0（构建前必须处理）
1. **恢复 949 个模型的贴图引用**：以 `mods/TFCFarmingPlus-...jar` 为基准，把 `models/block/{crop,dead_crop,wild_crop}` 与 `models/item/{seeds,food,fiber,cotton_boll,hops}` 的 `textures` 改回 `tfcfarmingplus:` 自有路径（清单：`d2-model-ref-regression-list.csv`）。或修好 `localize-textures.ps1` 的命名规则后重跑（注意它当前生成 `X_N` 而现有贴图是 `X_age_N`，需先对齐命名，否则仍接不上）。
2. **恢复 6 个 melon 模型的 `textures` 覆盖**（旧 jar 版本：`side`/`end`/`particle` 指向 `tfcfarmingplus:block/melon/*_fruit_{side,top}`），使 12 张贴图重新有效。
3. 在构建后增加静态门禁：`artifacts` jar 的 crop 模型 `tfc:` 引用数应为 0（当前为 609），否则视为回归。

### P1（本迭代应处理）
4. B 补 389 个方块的 loot table（可脚本生成与 blockstate 同名的自掉落表）。
5. B 修 16 处贴图路径；补 `food/pan_seasoned_vegetables` item 模型。
6. B 在 `neoforge.mods.toml` 声明 `afc` 依赖（或在 Java 中按 `modLoaded` 条件注册 AFC 树种并跳过其资源查询）。
7. B 的 `gui.tfcagricultureplus.silkworm_container` 补文案；补 4 个物品 lang。
8. **更新资源合同断言**（`tools/contracts` 与 verify 脚本）：增加“crop 模型贴图必须为自有命名空间”与“受保护贴图必须被模型引用”两条检查，防止 R-1/R-2 类回退再次通过门禁；合同 SHA 不要重新基线到回退后的模型上。

### P2（择机）
8. 清理 A 的 3 个死模型、5 个 rosette lang key、2 张全透明占位贴图（在 R-1/R-2 完成后）。
9. 迁移 B 的 2 个误放配方到 `data/tfcagricultureplus/recipe/`。
10. 统一 2,572 个 CRLF 为 LF；清理 325 组重复文件（可选）。
11. 文档登记：`assets/tfc` 覆盖 TFC 模型（cabbage 6 个）与 patchouli 手册覆盖的维护责任；`log_pile` 依赖 BE renderer。
12. 补 `mod_rebuild` 的 `.tooling/reference/` 或改造 `generate-timber-resources.py` 的许可证读取，使 B 资源生成可复现。

---

## 8. 附录：脚本与证据

所有脚本/CSV 位于 `mod_rebuild/docs/audit/`（只读运行，未写资源）：

| 脚本 | 产物 | 内容 |
|---|---|---|
| `d2_inventory.py` | `d2-category-stats.csv`、`d2-inventory.csv`、`d2-file-problems.csv`、`d2-duplicates.csv`、`d2-inventory-report.txt` | 分类计数/体积、BOM/CRLF/JSON/命名卫生、重复文件、目录分布 |
| `d2_index.py` | `d2-index.json` | 本地资源 SHA256 + 外部 jar/vanilla 资源索引 + 外部贴图 SHA |
| `d2_refs.py` | `d2-refs.csv`、`d2-A-issues.csv`、`d2-B-issues.csv`、`d2-all-issues.csv`、`d2-summary.txt` | 引用图、死资源、missing parent/model/texture、零厚度面/旋转角、注册 gap |
| `d2_textures.py` | `d2-textures.csv`、`d2-texture-dups.csv`、`d2-texture-summary.txt` | PNG 尺寸/色数/透明度、与 TFC/Firmalife/vanilla 逐像素相同、重复、源码树 vs 旧/新 jar |
| `d2_placeholders.py` | `d2-placeholders-A.csv`、`d2-placeholders-B.csv`、`d2-placeholder-summary.txt` | “模型引用 TFC 占位 × 同物种自有贴图死亡”交叉 |
| `d2_regression.py` | `d2-model-ref-regression.csv/.txt`、`d2-model-ref-regression-list.csv` | 当前树 vs 已发布旧 jar 的模型贴图引用回归清单 |
| `d2_data.py` | `d2-data-rows.csv`、`d2-data-problems.csv`、`d2-data-summary.txt` | loot/tags/lang/recipe/worldgen/TFC 数据/元数据 |
| `d2_blockstates.py` | `d2-blockstates.csv`、`d2-blockstate-problems.csv`、`d2-blockstate-summary.txt` | blockstate 变体解析、属性覆盖、与 TFC 形状模板对比 |
| `d2_contracts.py` | `d2-contracts.csv`、`d2-contracts-summary.txt` | tools/contracts 的 SHA 基线（407 文件）、图标路由、物种清单与当前资源一致性 |

复现命令（Python 3 + Pillow；按顺序）：

```powershell
$py = "C:\Users\Lenovo\.dsh\dsh-runtimes\dsh-primary-runtime\dependencies\python\python.exe"
$root = "D:\111\最强服务器\.minecraft\versions\Essential TerraFirmaCraft (TFC)\mod_rebuild"
& $py "$root\docs\audit\d2_index.py"
& $py "$root\docs\audit\d2_inventory.py"
& $py "$root\docs\audit\d2_refs.py"
& $py "$root\docs\audit\d2_textures.py"
& $py "$root\docs\audit\d2_placeholders.py"
& $py "$root\docs\audit\d2_regression.py"
& $py "$root\docs\audit\d2_data.py"
& $py "$root\docs\audit\d2_blockstates.py"
& $py "$root\docs\audit\d2_contracts.py"
```

**口径限制**：
- 注册 ID 为静态提取（正则 + helper 规则），果树/灌木/`plant/*` 等拼接族用族级规则核对，不作为逐 ID 权威；
- 外部命名空间的“存在性”基于 jar 内资源路径，不反编译注册表；
- 未运行构建、未启动游戏，因此本文所有“游戏内表现”判断均为静态推断（如无 loot = 不掉落：依据 MC 默认 `Block.getDrops` 行为，Java 中未见覆写）。
