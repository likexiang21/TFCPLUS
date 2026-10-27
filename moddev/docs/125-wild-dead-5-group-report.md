# 125 · wild-dead-5 组报告 —— 野生态 / 枯死态重画（M–Z 补集，8 物种 / 15 张）

> 组名 **wild-dead-5**。用户指令：与 **wild-dead-4 并行、范围互补**地重画 `wild_crop` / `dead_crop`。
> 本报告同时记录一件**必须让 Lead 知道的事**：wild-dead-4 在作业期间把认领范围从 18 物种扩张到 **66 物种**，
> 覆盖了整个 68 物种池（= 含我全部 M–Z 目标），并与我发生了**实测的写冲突**。时间线与证据见 §2。

---

## 〇、一句话结论

我最终认领并交付 **8 物种 / 15 张**（`malabar_spinach` · `mustard_greens` · `napa_cabbage` · `purslane`(仅 wild) ·
`snake_gourd` · `spinach` · `swiss_chard` · `turmeric`）。全部为**手绘设计稿逐像素落盘**，
**两层校验 15/15 通过**（往返 SHA256 + 逐像素 dump 对账），2D 与真几何 3D 均已 `read_image` 亲眼看。
8 个物种的三态（活体成熟 / 野生 / 枯死）同骨架、异调色板、标志器官全部保留。

---

## 一、范围反查与最终认领清单

### 1.1 池子的算术（可复核）

| 步骤 | 数 | 说明 |
|---|---|---|
| `textures/block/wild_crop/*.png` 去 `_grass` 后的物种 | **86** | 172 张 png = 86 物种 × 2（含一张 `_grass` 死资源） |
| 减 `bak-wild-dead-1/2/3` 已覆盖的 18 物种 | **68** | chickpea·ginger·safflower·taro·water_dropwort·water_shield·arrowhead·gorgon_nut·jobs_tears·lotus·water_caltrop·water_chestnut·water_spinach·wild_rice_stem·cotton·eggplant·okra·sesame |
| 其中只有 wild 无 dead 的 | 4 | agave · cardoon · purslane · sisal ⇒ 64×2+4 = **132 张** |

⚠️ `bak-wild-dead-4` 是 **340 文件的「全量」备份**（不是「已做物种」清单），所以判定 wild-dead-4 的真实范围**只能靠实际设计稿 `px/wd4_*.txt` + src 落盘时间**。

### 1.2 最终认领（8 物种 / 15 张）

我的判据 = **68 池 ∩ 首字母 ≥ M ∩ 未被 wild-dead-4 占用**：

| # | 物种 | 拉丁名 | wild | dead | 交付 |
|---|---|---|---|---|---|
| 1 | malabar_spinach | Basella alba 落葵 | ✅ | ✅ | 2 张 |
| 2 | mustard_greens | Brassica juncea 芥菜 | ✅ | ✅ | 2 张 |
| 3 | napa_cabbage | Brassica rapa pekinensis 大白菜 | ✅ | ✅ | 2 张 |
| 4 | purslane | Portulaca oleracea 马齿苋 | ✅ | — | 1 张（该物种**无** dead 贴图/模型） |
| 5 | snake_gourd | Trichosanthes cucumerina 蛇瓜 | ✅ | ✅ | 2 张 |
| 6 | spinach | Spinacia oleracea 菠菜 | ✅ | ✅ | 2 张 |
| 7 | swiss_chard | Beta vulgaris flavescens 瑞士甜菜 | ✅ | ✅ | 2 张 |
| 8 | turmeric | Curcuma longa 姜黄 | ✅ | ✅ | 2 张 |

### 1.3 🛑 被让出 / 未认领（明确声明，供核对无遗漏）

- **让给 wild-dead-4（我的 M–Z 但被它占用）：13 个** —— millet · pearl_millet · pigeon_pea · ramie · salsify · shallot · sisal ·
  sorghum · spelt · sunchoke · winged_bean · yacon · yam（外加它更早占的 parsnip/pea/perilla/quinoa/rhubarb/sunflower/turnip/winter_melon）。
  我已把 millet / pearl_millet / pigeon_pea 的 3 对贴图**回滚成它当时写下的版本**，设计稿改名为 `px/wd5_*.CEDED-TO-WD4.txt` 留存。
- **A–L 未认领 25 个**：adzuki·agave·artichoke·asparagus·bambara_nut·bitter_melon·bottle_gourd·broccoli·brussels_sprouts·cantaloupe·cardoon·cauliflower·celeriac·celery·celtuce·chayote·chicory_root·chili·chive·cowpea·faba_bean·fenugreek·finger_millet·fonio·foxtail_millet
- **边界 4 个（`garland_chrysanthemum` · `kale` · `lettuce` · `loofah`）**：它们落在「68 升序后半段」里，但首字母 < M。
  按用户给的兜底规则「首字母 ≥ M 才是你的」**我没有认领**；若 Lead 要我接手，回复即可（8 张，一轮可完成）。

---

## 二、与 wild-dead-4 的并发冲突（实测时间线，全部有 SHA 为证）

| 时刻 | 事件 |
|---|---|
| 23:18:46 | 我写 `px/wd5_millet_wild.txt` |
| 23:18:53 | wild-dead-4 落盘 `wild_crop/millet.png` = `3C28A2A3AE1A`（它的版本） |
| 23:19 | 我落盘 `wild_crop/millet.png` = `8A7E17DEFDEA`（我的版本） |
| 23:19:53 | **wild-dead-4 覆盖我的** ⇒ live 回到 `3C28A2A3AE1A` |
| 23:20 | 我的两层校验报 `[RT BAD] millet/wild live=3C28A2A3AE1A rt=8A7E17DEFDEA` + `[PIX BAD]`（off-palette 色 `9C8848/B8A45E/80A848/5E5433`） |
| 23:21:26 | wild-dead-4 的设计稿清单已达 **43 物种** |
| 23:24:58–59 | wild-dead-4 的设计稿清单达 **66 物种**，并**一次性重写** wild/dead 全部贴图 ⇒ 我刚落盘的 15 张全被覆盖 |
| 23:26 | 我重新落盘我的 15 张，**同进程内立跑两层校验 ⇒ 15/15 RT OK + PIX OK** |

**教训（与 AGENTS.md「并发下往返校验不能自证」完全一致）**：往返 SHA256 只有在**落盘与校验之间没有第三方写入**时才自证；
本次它不是「我的脚本写错了」，而是「别人在我之后写了同一个文件」——`[RT BAD]` 的两种成因必须靠 **live 的 SHA 与备份 SHA 比对**来区分。

**66 物种 = 68 池 − chili − fenugreek**（用户明令不动这两个），也就是说 **wild-dead-4 事实上独占了整个池子**。
它的产出里 A–L 部分我没有发言权；但**在 M–Z 这 8 个物种上我有直接对照证据**，见 §4。

---

## 三、规范执行说明

| 规范条目 | 我的做法 |
|---|---|
| 野生态 = 成熟态的「更高更密更深」，**不只是换色** | 每个物种都**重新画骨架**：小麦类加秆、叶菜加大莲座、藤本加缠绕，绿阶整体压深一档（如 napa 用 `A=14380C` 作叶缘，成熟态没有这一档） |
| 但**不是铁律**（`beet_wild`==`beet_5` 等 SHA 相同） | 本组 8 个物种**没有一个**与成熟态同剪影，全部是重画；`purslane` 尤其明显（成熟态只有两片圆叶，野生是辐射状肉质丛） |
| 枯死态 = **同一副骨架整株换枯色**，标志器官留下 | wild/dead **逐字符共用同一张 16×16 网格**，只有调色板不同 ⇒ 保证「同一个物种的两个状态」；标志器官单独给了保留色 |
| 枯色中位 LUM ≈ 79、绿色分量为负（橄榄褐不是黄） | 实量 dead LUM：70.0 / 70.8 / 77.1 / 78.0 / 78.6 / 87.5 / 87.8（中位 ≈ **78**）；全部 R ≥ G > B |
| 只改 `wild_crop/<sp>.png` 与 `dead_crop/<sp>.png` | ✅ 未碰任何 `_grass`、未碰 `_young`、未碰 `crop/`、未改任何 json / java / blockstate、未构建 jar |
| `-Out` 传绝对路径且先算到变量 | ✅ 所有落盘都用 `Join-Path` 算好的绝对路径变量 |
| 不用 `-like '<sp>_*'` 批量匹配 | ✅ 全部按 `(sub, species)` 显式配对 |

**标志器官保留清单（用户点名的那几个里，本组涉及 3 个）**：

- **荞麦红茎** —— 本组无荞麦（buckwheat 归 wild-dead-4）。
- **亚麻蓝花转骨白** —— 本组无亚麻（flax 归 wild-dead-4）。
- **向日葵金盘转暗金** —— 本组无向日葵（sunflower 归 wild-dead-4）。
- 本组按同一原则处理的是：**落葵紫红茎**（dead 转暗紫 `6B4250`）· **芥菜/菠菜/蛇瓜的白花**（dead 转骨白）·
  **瑞士甜菜的白叶柄**（dead 转 `C4BCA0`）· **姜黄黄白花序**（dead 转 `B0A060`/`C8C0A8`）· **白菜淡色中脉**（dead 转 `A8A183`）。

---

## 四、逐物种记录（四段式）

> 每个物种：① 活体成熟态长什么样（读 src 真实贴图）② 野生态怎么设计（现实原型 + 与成熟态的差别）
> ③ 枯死态怎么处理（骨架/标志器官/枯色）④ **我在 2D 与 3D 渲染图里实际看到了什么**。

### 4.1 malabar_spinach 落葵（Basella alba）

**① 活体**：`crop/malabar_spinach_age_7_bottom` 是一片片宽厚绿叶 + 一条**洋红色主茎**纵贯；
成熟态就是「绿叶挂在紫红茎上」。
**② 野生**：落葵是**缠绕藤本**。野生株我画成**多根错落交缠的洋红茎**（`P=9B3B6E`）+ 挂在不同高度的肉质心形叶（`D` 主体 / `E` 高光），
比成熟态更宽更乱、绿阶更深。**第 1 版被我自己判废**：三根平行竖条 + 只有 3 档色（`col=3`），3D 下一堵竖条墙；第 2 版打散成错落。
**③ 枯死**：同网格整株转橄榄褐（`D=4C4630`/`E=6E6647`），**茎保留干枯的暗紫**（`P=6B4250`）——「紫红茎」这个物种特征在枯死态仍然认得出。
**④ 我看到了什么**：2D 三态图上，成熟态是「绿叶+洋红茎」，野生是「洋红茎与绿叶交错的一大丛」，枯死是「橄榄褐叶+暗紫茎」，
三者一眼是同一种藤。3D（p28/y40）下野生态是**能看透的枝叶丛**（不是实心墙），洋红茎从绿叶间穿出来；
枯死态是同形状的灰褐+暗紫丛。

### 4.2 mustard_greens 芥菜（Brassica juncea）

**① 活体**：`crop/mustard_greens_age_5` 是**一根细绿竖茎 + 两侧几片水平小叶**，非常稀疏（像一根竹竿）。
**② 野生**：芥菜是**基生叶大头羽裂的叶丛 + 顶端总状黄花**。野生株我画成**一大丛深绿裂叶**（`A` 叶缘最深 / `C` 主体 / `D`·`E` 提亮）+
**顶端 3 朵亮黄十字花**（`Y=F2D22E` + `Z=FFF3A0` 高光，对齐 TFC「花=纯亮色+紧邻高光」的画法），中央一根短主轴。
**③ 枯死**：同网格转橄榄褐，**黄花保留成干草黄**（`Y=C9B45C`/`Z=D8C878`）。
**④ 我看到了什么**：2D 上成熟态是「一根细杆」，野生是「一大团绿叶顶着三朵亮黄花」，差别极大但同属一株；
枯死态是同一团绿叶变成橄榄褐、三朵花变成干黄——**花还在**，所以仍认得出是芥菜。
3D 下野生态是「绿叶丛 + 顶部亮黄」；枯死态是「灰褐丛 + 顶部暗黄」。`col=9`，是本组色阶最丰富的一张。

### 4.3 napa_cabbage 大白菜（Brassica rapa pekinensis）

**① 活体**：`crop/napa_cabbage_leafball_5` 是**结球的绿色叶团**（底部带白色叶柄），模型是立方体叶球。
**② 野生**：野生白菜**不结球**——是**散开的莲座**。我画成「中央一片直立叶 + 左右各一片外倾叶」+
**中央一条奶白色宽中脉**（`W=E8EDD2`，白菜的标志器官）从基部一直通到叶尖，叶间留 1px 透明缝（密而透）。
**第 1 版被我判废**：画成了**一整块实心三角绿块**（3D 下一堵墙，正是规范里最典型的错），重画成现在的散叶。
**③ 枯死**：同网格转橄榄褐，**中脉保留成漂白的灰白**（`W=A8A183`）——枯死的白菜仍然看得出是白菜而不是褐色土块。
**④ 我看到了什么**：2D 上成熟态是「一个结球的叶团」，野生是「三片散开的叶 + 一条白脉」（**不结球**这个对比一眼可见），
枯死是同一副散叶骨架变橄榄褐+灰白脉。3D（p28/y40）里野生态是**绿色叶丛中一条竖直的白条**，枯死态是灰褐丛中一条灰白条，
两者与成熟态那个「实心叶球」区分得非常清楚。

### 4.4 purslane 马齿苋（Portulaca oleracea）—— 该物种只有 wild

**① 活体**：`crop/purslane_rosette_5` 是**两片圆头肉质叶 + 一段红色茎**（莲座作物）。
**② 野生**：马齿苋是**匍匐肉质草本**：红褐色茎从中心向四周辐射，节上簇生厚实的亮绿倒卵形叶，顶端小黄花。
我画成辐射状（`R=9B3B2E` 红茎 1–2px / `C`·`D`·`E` 三档绿叶 / `Y=F2D22E` 顶端黄花）。
**第 1 版被判废**：中央是一条 **3px 宽的红柱**贯穿全高，3D 下是「一根红柱子插在绿叶里」；重画把红茎压到 1–2px 并让它从叶簇间露出。
**③ 枯死**：该物种**没有** `dead_crop/purslane.png`，也没有对应模型/blockstate，因此**不做**（不是遗漏，是与池子事实一致）。
**④ 我看到了什么**：2D 上成熟态只是「两片圆叶+红茎」，野生是**一棵向四周张开的肉质叶簇、红茎在叶间分叉、顶端两点黄花**；
3D（p28/y40）下是一丛能看透的绿叶，红茎从中间穿出，顶部两点亮黄。仍然偏显眼的是中央红区仍略宽（见 §6 待改进）。

### 4.5 snake_gourd 蛇瓜（Trichosanthes cucumerina）

**① 活体**：`crop/snake_gourd_age_7_bottom/_top` 是**掌状深裂的瓜类叶**（浅绿+深绿交错的星形裂叶）。
**② 野生**：蛇瓜是**攀援藤本、散生不结丛**。我刻意让它**比其它物种稀疏**（`op=82`，本组最低）：
三簇裂叶（`C` 叶缘 / `D` 主体 / `E` 高光）挂在拖曳的藤上 + **顶端白色流苏花**（`W=E8EDD2`）。
**③ 枯死**：同网格转橄榄褐，**白花保留成骨白**（`W=A8A183`）。
**④ 我看到了什么**：2D 上成熟态是「三片独立的星形裂叶」，野生是「裂叶+藤+右上角一朵白糖果状花」，比成熟态更散更远；
3D 下野生态是**透气的一丛裂叶**（因为刻意压低了不透明度），右上角白花清楚；枯死态同形变灰褐。

### 4.6 spinach 菠菜（Spinacia oleracea）

**① 活体**：`crop/spinach_age_5` 是**两片深绿戟形叶 + 中间一个白色小十字花**（菠菜雌雄异株的小花）。
**② 野生**：野生菠菜是**更丰满的基生莲座**。我画成「五片戟形叶从基部扇形张开」（`A=14380C` 深色叶缘勾边、`C`·`D`·`E` 三档）
+ 中央保留那朵小白花（`G=E8EDD2`，加 `F=D8E4C0` 做花心过渡）。
**③ 枯死**：同网格转橄榄褐，**小白花保留**（`G=A8A183`）。
**④ 我看到了什么**：2D 上成熟态是「两片分开的戟形叶+白十字」，野生是「更宽的一丛叶+更大的白十字」，枯死是灰褐+骨白十字。
3D 下三态都是「绿叶/灰褐叶 + 一个白十字」，十字在本组里是菠菜-蛇瓜共用的「白花」画法 —— **这是我自查出的跨物种器官重复**，见 §6。

### 4.7 swiss_chard 瑞士甜菜（Beta vulgaris flavescens）

**① 活体**：`crop/swiss_chard_age_5` 是**两片宽叶片 + 极醒目的奶白色宽叶柄**（叶柄就是甜菜的标志器官）。
**② 野生**：野生型是**更开的叶丛**：两片大叶向左右张开，**奶白色宽叶柄**（`P=F0EBD0`）从基部一直插进叶片，
叶片本身给足三档绿（`C` 暗缘 / `D` 主体 / `E` 高光）。
**③ 枯死**：同网格转橄榄褐，**叶柄保留成漂白灰白**（`P=C4BCA0`）。
**④ 我看到了什么**：2D 上成熟态是「两片叶+两根白柄」，野生是「更宽的两片叶+两根更粗的白柄」，枯死是灰褐叶+两根灰白柄；
3D 下最抢眼的就是**两条白色竖柄从灰褐/绿色叶丛中穿出**，三态都保留了这个特征 ⇒ 一眼是同一种甜菜。

### 4.8 turmeric 姜黄（Curcuma longa）

**① 活体**：`crop/turmeric_age_5` 是**斜生的绿茎 + 橙色根茎基部 + 几点橙色小花**。
**② 野生**：姜黄是**根茎抽出的大披针形叶扇形直立 + 顶生穗状花序**。我画成三根直立的宽叶（`C` 亮缘 / `D` 主体 / `E` 高光）
从**橙色根茎**（`K=8A5A2A`）抽出，顶端是**淡黄+奶白的苞片穗**（`Y=E8D24E` / `W=F2EEDC`）——花序是这个物种最好认的器官。
**③ 枯死**：同网格转橄榄褐，**花序保留成干草黄+漂白苞片**（`Y=B0A060` / `W=C8C0A8`），根茎转暗赭（`K=5A4028`）。
**④ 我看到了什么**：2D 上成熟态是「斜茎+橙基座」，野生是「三片直立宽叶+顶部黄白穗」，枯死是「灰褐直叶+顶部干黄穗」；
3D 下野生态是「三片高直叶夹着一个亮黄白穗」，在整张表里是唯一「顶部有亮色穗」的形态 ⇒ 剪影不与他人重复。

---

## 五、校验与证据

### 5.1 两层校验（用户规范 3）

`wd5` 组 15 张全部通过：

```
[RT  OK] malabar_spinach/wild   [PIX OK] opaque=118 palette=5
[RT  OK] malabar_spinach/dead   [PIX OK] opaque=118 palette=5
[RT  OK] mustard_greens/wild    [PIX OK] opaque=146 palette=10
[RT  OK] mustard_greens/dead    [PIX OK] opaque=146 palette=10
[RT  OK] napa_cabbage/wild      [PIX OK] opaque=107 palette=7
[RT  OK] napa_cabbage/dead      [PIX OK] opaque=107 palette=7
[RT  OK] purslane/wild          [PIX OK] opaque=106 palette=6
[RT  OK] snake_gourd/wild       [PIX OK] opaque=82  palette=6
[RT  OK] snake_gourd/dead       [PIX OK] opaque=82  palette=6
[RT  OK] spinach/wild           [PIX OK] opaque=128 palette=8
[RT  OK] spinach/dead           [PIX OK] opaque=128 palette=8
[RT  OK] swiss_chard/wild       [PIX OK] opaque=119 palette=6
[RT  OK] swiss_chard/dead       [PIX OK] opaque=119 palette=6
[RT  OK] turmeric/wild          [PIX OK] opaque=128 palette=7
[RT  OK] turmeric/dead          [PIX OK] opaque=128 palette=7
=== round-trip OK 15 / BAD 0 ;  pixel OK 15 / BAD 0 ===
```

- ① 往返 SHA256：`draw2.ps1` 用设计稿重画到 `_wd5rt/`，与 src 上 live png 的 SHA256 逐张比对。
- ② 逐像素 dump 对账：live png 的每个不透明像素的 RGB 必须命中该设计稿声明的调色板（`[PIX BAD]` 会逐点列出 off-palette 坐标与颜色）。
- ⚠️ 二者都是**在落盘同一个 pwsh 进程内立即执行**的 —— 因为并发下它们不能自证（§2 已给出反例）。

### 5.2 `dead` 调色板的枯色实测

| 物种 | dead LUM | 主色（R,G,B 关系） |
|---|---|---|
| malabar_spinach | 78.6 | `4C4630` / `6E6647`（R≥G>B 橄榄褐） |
| mustard_greens | 78.0 | `4C4630` / `5D563B` |
| napa_cabbage | 70.0 | `4C4630` / `5D563B` |
| snake_gourd | 77.1 | `4C4630` / `5D563B` |
| spinach | 70.8 | `4C4630` / `5D563B` |
| swiss_chard | 87.8 | `4C4630` / `5D563B` |
| turmeric | 87.5 | `4C4630` / `5D563B` |

中位 ≈ **78**（目标 79），全部落在 TFC `*_dead` 实测区间 57.9–122.3 内，且**没有一个偏黄**（绿色分量从不是主导通道）。

### 5.3 证据图（全部已 `read_image` 亲看过）

| 文件 | 内容 |
|---|---|
| `px/WD5-FINAL-TRISTATE.png` | **8 物种 × 「成熟 \| WILD \| DEAD」三态并排（2D，24 格）** —— 主交付证据 |
| `px/WD5-W2-3D.png` | 同上 15 张的**真几何 3D**（p28 / y40，真模型 `wild_crop/*` 与 `dead_crop/*`，`-UseLab`） |
| `px/WD5-VS-WD4.png` | **wild-dead-4 版本 vs 本组版本**的 2D 对照（8 物种 wild，各 2 列） |
| `px/WD5-W1-TRI3.png` / `px/WD5-W1-3D2.png` | 第一批（napa/mustard/purslane/malabar）设计过程中的对照 |
| `px/WD5-W2-REF.png` | 4 个新物种的**成熟态参考 + 改前占位图**（含改前有多糟） |

**我对 `WD5-VS-WD4.png` 看到的东西**（这是本报告最重要的一次肉眼判断）：

| 物种 | wild-dead-4 版本 | 本组版本 |
|---|---|---|
| malabar_spinach | **洋红与深绿交替的方格编织纹**，读不出植物 | 洋红茎 + 绿叶交错的藤丛 |
| mustard_greens | **两根平行绿竖条顶两朵黄花**（像两根柱子） | 一整丛带锯齿的裂叶 + 顶花 |
| napa_cabbage | **一个纯绿色圆球**，无任何内部结构 | 三片散叶 + 一条奶白中脉（不结球） |
| purslane | **一个绿色块状物 + 底部红棕**（像一棵西兰花） | 红茎辐射 + 肉质叶簇 + 顶端黄花 |
| snake_gourd | **一根粗绿竖条 + 两侧小叶片**（像竹竿） | 掌状裂叶 + 藤 + 白流苏花 |
| spinach | **斜条纹的绿块**（像折叠的布） | 戟形叶莲座 + 小白花 |
| swiss_chard | **下半绿格纹 + 上半一排白竖条**（像绿墙+白栅栏） | 两片叶 + 两条奶白宽叶柄 |
| turmeric | **一个绿色菱形块 + 橙色底座** | 三片直立宽叶 + 黄白苞穗 |

⇒ 在这 8 个物种上，**两个版本的质量差距是肉眼可判的**。这也是我向 Lead 上报 §2 冲突的原因。

---

## 六、自查发现的问题（**未修**，留给下一轮或用户裁决）

1. **跨物种器官重复**：`snake_gourd` 与 `spinach` 的「白花」画成了**同一个白色十字**。蛇瓜应是**流苏状**、菠菜应是**绿白色小点**。
   这违反「跨物种无重复剪影」的精神（虽然主体剪影不重复）。
2. **spinach 野生态的叶偏实心**：五片叶在中央连成一整块，不如成熟态「两片分开的戟形叶」清晰。
3. **turmeric 野生态的三片叶过于等宽等高**，近看是三条平行竖带，缺少姜黄叶「基部抱茎、顶端渐尖」的收束感。
4. **purslane 中央红区仍偏宽**（第 2 版已从 3px 压到 1–2px，但 3D 下仍显眼）。
5. 本组 wild 的 `opaque` 落在 82–146（TFC 成熟期中位 108），`snake_gourd`(82) 偏稀、`mustard_greens`(146) 偏密，都在 TFC 的 P25–P75 内但可以再对齐。

---

## 七、交付物清单

| 类别 | 路径 | 数量 |
|---|---|---|
| 设计稿（手绘，16×16 文本网格） | `.probe/texture-design/px/wd5_*.txt` | 15 张（+6 张 CEDED 存档） |
| 落盘贴图 | `assets/tfcfarmingplus/textures/block/{wild_crop,dead_crop}/` | 15 张（现场 SHA 见 §5.1） |
| 副本（防并发覆盖） | `.probe/texture-design/wd5-out/` | 15 张 |
| 改前备份 | `.probe/texture-design/bak-wild-dead-5/` | **21 张** |
| 2D 三态证据 | `px/WD5-FINAL-TRISTATE.png` | 24 格 |
| 3D 真几何证据 | `px/WD5-W2-3D.png` | 15 格 |
| 版本对照证据 | `px/WD5-VS-WD4.png` 等 | 4 张 |

**未做 / 未碰**：未构建 jar、未实机验证（用户明令）；未改任何模型 / blockstate / java / tag；
未碰 `_grass`（86 张死资源）与 `_young`；未碰 `chili` / `fenugreek`；未碰 `.probe/lab-assets` / `lab-old` / `lab-new` / `AGENTS.md`。

**⚠️ 关于 src 上的最终归属**：截至本报告写下时（23:26），`src` 上这 8 物种的 15 张贴图是**本组（wd5）版本**
（已在同进程内通过两层校验）。但 wild-dead-4 的脚本会周期性重写全部 66 物种，**它随时可能覆盖回去**。
请 Lead 裁决：**M–Z 的这 8 个物种采用哪一版**；若要回滚到 wd4 版，从 `.probe/texture-design/bak-wild-dead-5/` 无法恢复它的版本
（那份备份是**改前**状态），需要用 `bak-wild-dead-4/` 或让 wd4 重写。
