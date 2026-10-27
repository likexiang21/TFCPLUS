# 127 · extradelight 全面分析

> **用途**：为 B 模组（`tfcagricultureplus`）的**食品加工方向**提供完整的外部参照。
> **分析对象**：`extradelight` **两个版本** + 它的**兼容层** `extradelighttfc`。
> **方法**：**全部结论来自 jar 实测**（条目清单 / 配方 type / 标签 / BE-Menu 类），不靠推测。
> **关联文档**：[`126-b-module-implementation.md`](126-b-module-implementation.md)（B 实现子文档，§十一~§十八 是本分析的推导过程）
>
> **日期**：2026-09-29

---

## 一、分析对象与协议（🛑 先看这里）

| 对象 | 版本 | 大小 | 条目 | 协议 | 可借鉴程度 |
|---|---|---|---|---|---|
| `extradelight` | **2.6.6**（**1.21.1**） | 10.45 MB | **13,198** | 🛑 **`CC BY-NC-SA 4.0`** | ⚠️ **只借鉴玩法与设计思路** |
| `extradelight` | **1.1.5-all**（**1.20.1**） | 9.93 MB | **11,478** | 同上 | 同上 |
| **`extradelighttfc`** | **0.5.0-beta**（1.20.1） | **0.11 MB** | **122** | 🛑 **`Attribution-NonCommercial-ShareAlike 4.0`** | ⚠️ **只借鉴玩法**，但**方案思路极有价值** |

🛑 **协议红线（与主方案 §2.8 一致）**：
> CC BY-NC-SA 含**非商业**限制，与我们的 **MIT 不兼容**（MIT 允许商业使用，CC BY-NC-SA 不允许；且"相同方式共享"会传染）。
> ⇒ **可学**：设备清单 · 工序划分 · 配方结构思路 · 整合方案（游戏机制不受版权保护）。
> ⇒ 🛑 **不可做**：复制 JSON 配方 · 复制贴图/模型 · 复制 Java 代码。

---

## 二、资源规模（实测）

| 类别 | 2.6.6（1.21.1） | 备注 |
|---|---|---|
| `blockstates` | **822** | 全部方块 |
| `models/block` | **2,275** | 平均每方块 2.8 个模型 |
| `models/item` | **1,441** | **= 物品数** |
| `textures/block` | **1,021** | |
| `textures/item` | **823** | |
| `textures/gui` | **12** | ⚠️ **GUI 贴图极少** ⇒ 说明 GUI 界面很朴素 |
| `recipes` | **1,972** | |
| `loot_tables` | **801** | |
| `tags` | **41** | 见 §六 |
| `lang` | 11 | 多语言 |

⇒ ⭐ **美术量参考**：**822 方块 → 1,021 块贴图 + 823 物品贴图 ≈ 1,844 张**。
⇒ ⚠️ 这对我们的**美术估算（主方案 §9.0-D 的 ≈410 张）是重要参照** ——
但注意**我们不做装饰**（extradelight 的 286 个装饰方块贡献了大量贴图）。

---

## 三、方块全分类（822 个 → 10 类）

| # | 类别 | 数量 | 占比 | 我们学吗 |
|---|---|---|---|---|
| 1 | **装饰**（wallpaper · gingham · ribbon · wreath · molded · husk_doll · step_stool） | **286** | **35%** | 🛑 **不学**（主方案 §2.8：不借鉴装饰体系） |
| 2 | ⭐ **可放置食物**（整派/蛋糕/块/果冻/糖果/大餐/腌渍/巧克力盒…） | **203** | **25%** | ✅ **学**（→ 126 §十六） |
| 3 | ⭐ **厨房家具**（橱柜 · 水槽柜 · 刀具架 · 香料架 · 展示柜 · 果盘 · 野餐篮…） | **131** | **16%** | ✅ **学**（→ 126 §十七） |
| 4 | 建材（木/巧克力门 · 栅栏 · 台阶 · 半砖 · 柱子） | 67 | 8% | 🟡 只取"巧克力建材"的趣味（可选） |
| 5 | 作物/植物（9 种作物 + 野生 + 果树 + 花瓣） | 45 | 5% | 🟡 我们有 A 层的 86 种 |
| 6 | 储物（crate 木箱 · sack 麻袋） | 43 | 5% | ✅ **学**（散装储存） |
| 7 | 流体块（30+ 种酱汁/饮料） | 35 | 4% | ✅ **学**（→ 126 §13.4 手法 1） |
| 8 | ⭐⭐ **加工设备（有 BE）** | **19** | **2%** | ✅ **学**（→ 126 §十四） |
| 9 | ⭐ **挂晒/捆**（hanging_* 7 种 + corn bundle 3 种） | 10 | 1% | ✅ **学**（→ 126 §16.4） |
| 10 | ⭐ **模具/烤盘**（8 种） | **8** | **1%** | ✅ **学**（→ 126 §14.3） |

### 3.1 ⭐⭐ 最重要的一条结论

> 🎯 **加工设备只占 2%（19 个），而装饰占 35%、食物占 25%、家具占 16%。**
>
> ⇒ **extradelight 的"丰富"不是靠设备堆出来的** —— 设备是**骨架**，真正的体量在
> **「可放置食物 + 厨房家具 + 装饰」**。
> ⇒ 这正是 126 §13.4 的结论：**"丰富食品"靠"流体 + 中间产物 + 一物多用"，不靠堆方块**。
> ⇒ 同时也说明：⚠️ **如果我们不学它的装饰，方块数天然会少很多** —— 这是**有意的取舍**。

---

## 四、物品全分类（1,441 个）

| # | 类别 | 数量 | 说明 |
|---|---|---|---|
| 1 | ⭐ **工具** | **253** | ⚠️ 含刀具 · 搅拌器 · 擀面杖 · 擦丝器 · 模具 · 烤盘（部分与方块重叠） |
| 2 | **糖果/甜点** | **185** | 巧克力 · 软糖 · 棉花糖 · 太妃糖 · 糖霜 · 各种蛋糕 |
| 3 | **成品菜** | **149** | 炖菜 · 派 · 面包 · 沙拉 · 咖喱 · 烤肉 |
| 4 | **食材/原料** | **141** | 面粉 · 玉米面 · 面包糠 · 黄油 · 奶酪 · 盐 · 酵母 · 面团 · 蛋 · 奶 · 糖 · 可可 · 咖啡 · 茶 · 果酱 |
| 5 | **饮料** | **74** | 果汁 · 苹果酒 · 柠檬水 · 奶昔 · 热可可 |
| 6 | **加工中间品** | **62** | ⭐ **切片/擦丝/切碎/捣泥/研磨/酱/汁/高汤** |
| 7 | 种子/作物 | 13 | extradelight 自己的 9 种作物 |
| — | 其它（砖块 · 装饰 · 杂项） | ~564 | — |

⇒ ⭐ **第 1 名是"工具"（253 个）** ⇒ 印证"**手持工具**"是食品模组的重要组成（126 §13.8）。
⇒ ⭐ **第 6 名的"加工中间品"（62 个）** ⇒ 印证"**中间产物是深度的来源**"（126 §11.5 原则 1）。

---

## 五、⭐ 功能方块权威清单（**按 BE / Menu 判定，不按名字**）

### 5.1 全部 22 个 BlockEntity

| BE | 对应方块 | 我们是否已纳入 |
|---|---|---|
| `ChillerBlockEntity` + **`ChillableBlockEntity`** | 冷藏柜 + **可冷藏接口** | ✅ §9.2 #8 |
| `OvenBlockEntity` | 烤箱 | ✅ B4 覆盖 |
| `MeltingPotBlockEntity` | 熔化锅 | ✅ §9.2 #4 |
| `MixingBowlBlockEntity` | 搅拌碗 | ♻️ 用 Firmalife 的 |
| `MortarBlockEntity` | 研钵 | ✅ §9.2 #10 |
| `JuicerBlockEntity` | 榨汁机 | ✅ §9.2 #9 |
| `EvaporatorBlockEntity` | 蒸发器 | ✅ §9.2 #2 |
| `DryingRackBlockEntity` | 干燥架 | ✅ §13.10 |
| `VatBlockEntity` | 发酵桶 | ♻️ 用 Firmalife 的 |
| `KegBlockEntity` | 小桶 | ♻️ 用 Firmalife 的 |
| **`JarBlockEntity`** | 罐 | ♻️ 用 TFC 的 |
| `FunnelBlockEntity` | 漏斗 | ✅ §9.2 #12 |
| `TapBlockEntity` | 龙头 | ✅ §9.2 #12 |
| ⭐ **`CounterCabinetBlockEntity`** | **橱柜台面** | ✅ **§十七 补上** |
| ⭐ **`SinkCabinetBlockEntity`** | **水槽柜** | ✅ §十七 |
| ⭐ **`KnifeBlockEntity`** | **刀具架** | ✅ §十七 |
| ⭐ **`FruitBowlBlockEntity`** | **果盘** | ✅ §十七 |
| ⭐ **`JarDisplayBlockEntity`** | 罐展示架 | ✅ §十七（判为 P3） |
| ⭐ **`PicnicBasketBlockEntity`** | **野餐篮** | ✅ §十七（P2） |
| ⭐ **`ChocolateBoxBlockEntity`** | 巧克力盒 | ✅ §十七（P3） |
| `CornHuskDollBlockEntity` | 玉米皮娃娃 | ❌ 装饰，不做 |

### 5.2 全部 14 对 Menu/Screen（**有 GUI 的方块**）

`Chiller` · **`CounterCabinet`** · **`DoughShaping`** · **`FoodDisplay`** · **`KnifeBlock`** · `MeltingPot` ·
`MixingBowl` · `Oven` · **`PicnicBasket`** · **`SinkCabinet`** · **`SpiceRack`** · `Styleable` · `Vat` · **`Wreath`**

⇒ 🆕 **方法**：**"有 Menu/Screen = 有 GUI = 功能方块"** ——
这比按名字筛选可靠（126 §17.6 的教训就是**我用名字把 7 个家具误判为装饰**）。
⚠️ `StyleableMenu`/`StyleableScreen` 是一个**通用"可自定义外观"的 GUI**（用于橱柜等的样式切换）。

---

## 六、⭐ 标签体系（41 个 ⇒ **它自己的分类逻辑**）

### 6.1 ⭐⭐ `item/processed/*`（**22 个**）—— 最重要的发现

```
processed/apple · beetroot · cabbage · carrot · chili · citrus · cucumber · fruit · garlic ·
ginger · grapefruit · lemon · lime · melon · onion · orange · potato · produce · tomato ·
vegetable · pickled/cucumber
```

⇒ 🎯 **它对每一种基础食材都做了"加工形态"标签** ——
意味着有**一整套"食材预处理"体系**（切片 · 擦丝 · 切碎 · 捣泥…）。
⇒ 🆕 **对我们的启示**：**§十二的"案板"（切）不应该是"一个配方"，而是"每种食材的加工形态"** ——
即 **N 种食材 × M 种处理 = 大量中间产物**（§四 的"加工中间品 62 个"就是这么来的）。

### 6.2 功能性标签（**配方输入的抽象**）

| 标签 | 含义 | 对我们的价值 |
|---|---|---|
| ⭐ **`frying_oil`** | 可用于**油炸**的油 | 🆕 **油炸是一道我们漏了的工序**（用 `pot` + 油） |
| ⭐ **`makes_stock`** | 可熬**高汤**的原料 | 🆕 高汤链（骨头/蔬菜 → broth） |
| ⭐ **`sweetener`** | **甜味剂**（抽象：糖/蜂蜜/糖浆都算） | 🆕 **抽象标签**让配方不绑定具体物品 ⭐ |
| `baking_trays` | 可用的烤盘 | 模具通用化 |
| `candy_bowl_valid` / `chocolate_box_valid` | 可放入糖果碗/巧克力盒的 | 容器内容物 |
| `chilling_items` | 可冷藏的 | 冷藏通用化 |
| `egg_or_yolk` | 蛋或蛋黄 | 蛋制品 |
| `jelly` / `jelly_ingredient` | 果冻 / 果冻原料 | 果冻链 |
| `broth` | 高汤 | — |
| `chocolate_bar_filling` / `chocolate_truffle_filling` | 巧克力填充 | — |
| `marmalade_ingredient` | 果酱原料 | — |
| `riceball_filling` | 饭团馅 | ⭐ 说明有**饭团** |
| `toast_or_bread_slice` / `toast_topping` | 吐司 / 吐司配料 | ⭐ **动态吐司**（`dynamic_toast` 配方） |
| `corn_dim_confiscate` | （玉米相关，含义待考） | — |
| `fluid/lemon_or_lime_juice` | 柠檬/青柠汁 | 流体标签 |
| `banner_pattern/citrus` | 旗帜图案 | 装饰 |

⇒ ⭐ **`sweetener` 这个"抽象标签"最值得学**：它让配方**不绑定具体物品** ——
糖、蜂蜜、糖浆、枫糖**都能当甜味剂** ⇒ 🆕 **我们的 §十五 品类 1（糖）应当也定义这样的抽象标签**。

---

## 七、配方类型全表（**两个版本对比**）

### 7.1 1.21.1 版（2.6.6）—— 19 种

| 类型 | 条数 | 工序 |
|---|---|---|
| `oven` | **518** | 烘焙 |
| `feast` | **120** | 大餐 |
| `mixing_bowl` | 108 | 搅拌 |
| `farmersdelight:cutting` | 106 | 切（砧板） |
| `mortar` | 35 | 研磨 |
| `smoking`/`smelting`/`campfire_cooking` | 33×3 | 烟熏/熔炼/营火 |
| `vat` | 21 | 发酵 |
| `dough_shaping` | 21 | 面团成型 |
| `tool_on_block` | 15 | **手持 + 方块** |
| `chiller` | 12 | 冷藏 |
| `juicer` | 11 | 榨汁 |
| `melting_pot` | 11 | 熔化 |
| `drying_rack` | 10 | 干燥 |
| `dynamic_toast` | 7 | 动态吐司 |
| `evaporator` | 1 | 蒸发 |

### 7.2 1.20.1 版（1.1.5-all）—— 26 种 ⇒ ⭐ **独有 3 种**

| 类型 | 1.20.1 | 1.21.1 | 🆕 价值 |
|---|---|---|---|
| ⭐⭐ **`bottle_fluid`** | **37** | ❌ **无** | **把流体装进瓶子**（果汁/酱汁/油可携带） |
| ⭐ **`dynamic_jam`** | **12** | ❌ **无** | 动态果酱（按原料算） |
| ⭐ **`flour_dough`** | 1 | ❌ **无** | **面粉 + 水 → 面团**（通用转换） |
| `chiller` | **74** | 12 | ⚠️ **冷藏配方多 6 倍** ⇒ 印证冷藏是重要品类 |
| `dough_shaping` | **37** | 21 | — |
| `farmersdelight:cooking` | **132** | （自家锅） | 借 FD 的锅 |
| `neoforge:mod_loaded` | 209 | — | **条件加载**（配方按模组存在与否生效）⭐ |

⇒ ⭐ **`neoforge:mod_loaded`（209 条）值得学**：它让**配方可以"按邻居是否存在"条件生效** ——
这对我们"**兼容 firmalifehardcore / 有则让位**"的策略（126 §3.5）**直接有用**。

---

## 八、Java 架构（关键机制类）

### 8.1 配方类（每类三件套）

`XxxRecipe` + `XxxRecipeBuilder` + `XxxRecipeCategory`（JEI 分类）+ （部分）`XxxRecipeWrapper`
⇒ 覆盖：`Chiller` · `DoughShaping` · `DryingRack` · `Evaporator` · `Feast` · `FlourDough` · `Juicer` · `MeltingPot` · `MixingBowl` · `BottleFluidRegistry` · `DynamicJam` · `DynamicToast`

### 8.2 ⭐ 动态食物体系（8 个类）

```
DynamicFoodChildBakedGeometry      ← 动态几何（子）
DynamicFoodParentBakedGeometry     ← 动态几何（父）
DynamicFoodGeometryLoader          ← 几何加载器
DynamicFoodUnbakedGeometry         ← 未烘焙几何
DynamicFoodItemOverrides           ← ⭐ 物品模型覆写（按成分换贴图）
DynamicItemComponent               ← 数据组件
DynamicItemInterpreter             ← ⭐ 解释器（读成分 → 决定外观/营养）
DynamicJam / DynamicJamRecipe / DynamicToast / DynamicToastRecipe
```

⇒ ⭐⭐ **核心机制**：**食物按"成分"动态决定外观与属性** ——
所以 extradelight 能做到"**任意食材 + 任意面包 = 对应的三明治**"。
⇒ 🆕 **对我们的启示**：我们的 §十五 品类 10（三明治/汉堡/披萨）**需要这个机制**才能"任意组合"。
⚠️ 但它**实现复杂**（8 个类 + 几何加载器）⇒ 🆕 **建议我们第一版只做"固定配方"**，动态化留待后续。

### 8.3 与其它模组的联动

`CreateCrushingRecipes` · `CreateMixingRecipes` ⇒ ⚠️ **与 Create（机械动力）联动**
⇒ 🆕 印证 126 §13.9：**"基于动力装置的加工"是有先例的**（Create 是动力 mod）。

---

## 九、⭐ `extradelighttfc`（**"食品模组 × TFC"的现成范例**）

> 0.11 MB / 122 条目，但它**专门解决我们最核心的问题**：**外来食品如何与 TFC 共存**。
> 完整分析见 126 §十八，此处只列骨架。

| # | 手法 | 实测证据 |
|---|---|---|
| **1** | **动态食物适配器** | `DynamicFoodCalculator` · `DynamicFoodContext$Phase` · `FoodModifierRegistry` · `MixingDynamicFoodAdapter` · `OvenDynamicFoodAdapter` |
| **2** | **注册 TFC 食物数据** | `data/extradelighttfc/tfc/food_items/*.json`（**15 个**）⭐ **`feasts` 与 `feast_items` 分开** |
| **3** | **酱汁注册成 `tfc:drinkable`** | `tfc/drinkables/{bbq_sauce,lemon,orange,tomato}.json` |
| **4** | **mixin 改 TFC 设备**（11 个） | ⭐ **`BarrelBlockEntityMixin`** · `RecipeFeastMixin` · `JuicerBlockMixin` · `RecipeManager_FDFilterMixin` · `fancy_tank/*` |
| **5** | ⭐⭐ **用 TFC 的 `anvil` 打造模具** | `recipes/anvil/{baking_tray,loaf_pan,pie_dish,sheet,square_pan}.json` |
| 附 | 其它配方 | `cutting/*`（8）· `juicer/*`（8）· `cooking/*`（4）· `mixing/*`（3，含黄油/打发奶油）· `oven/*`（9） |

⇒ ⭐⭐ **第 5 条对我们最直接**：**模具不是合成的，是"打"出来的** ⇒
**126 §14.3 的 6 个模具应走 TFC `anvil` 配方**（符合 TFC 设定 + 零新配方类型）。

---

## 十、核心机制总结（**五条**）

| # | 机制 | 说明 | 我们是否采纳 |
|---|---|---|---|
| **1** | ⭐⭐ **模具体系** | **一份面糊 + 8 种模具 = 8 类食物**（`loaf_pan`/`pie_dish`/`square_pan`/`muffin_tray`/`sheet`/`bar_mold`/`tray`/`baking_tray`） | ✅ **采纳**（126 §14.3，6 个模具） |
| **2** | ⭐⭐ **feast（大餐）** | **一道菜 = 一个可放置方块，可切分共享**（120 条配方） | ✅ **采纳**（126 §16.2，`CuttableFoodBlock`） |
| **3** | ⭐ **食材加工形态** | `processed/*`（22 个标签）—— 每种食材的切片/擦丝/捣泥 | ✅ **采纳**（案板 + `in_world`） |
| **4** | ⭐ **发酵引子** | `yeast_pot`（酵母）· `vinegar_pot`（醋母）—— **活的、可传代** | ✅ **采纳**（126 §14.4） |
| **5** | ⭐ **抽象标签** | `sweetener` · `frying_oil` · `makes_stock` —— 配方不绑定具体物品 | ✅ **采纳**（126 §十五） |

---

## 十一、🛑 明确**不学**的部分

| 部分 | 规模 | 不学的理由 |
|---|---|---|
| **装饰**（wallpaper · gingham · ribbon · wreath · molded · doll） | **286 方块（35%）** | 主方案 §2.8 已定：**不借鉴装饰体系** |
| **16 色变体**（巧克力盒/姜饼/果冻/丝带） | ~70 方块 | 纯颜色变体，**灌水** |
| **建材**（巧克力门/栅栏/台阶） | 67 方块 | 与食品加工无关 |
| **动态几何体系**（8 个类） | — | ⚠️ 复杂度高，**第一版不做** |

⇒ 🎯 **取舍后的参照价值**：**822 方块里我们真正学的是 ≈ 60 个**（19 设备 + 8 模具 + 203 食物中的代表 + 131 家具中的 7 个 + 10 挂晒）。
⇒ ⭐ **这印证了 126 §十七的结论：实际"方块类"≈ 18~20 个，其余是注册项与数据变体。**

---

## 十二、对 B 模组的启示汇总（**已全部并入 126**）

| # | 启示 | 落到 126 的哪节 |
|---|---|---|
| 1 | ⭐⭐ **模具走 TFC `anvil` 打造** | §14.3 |
| 2 | ⭐⭐ **可切分食物方块**（feast + 整派/整蛋糕/原料块） | §16.2 / §16.3 |
| 3 | ⭐ **厨房家具家族**（橱柜台面 · 半层柜 · 水槽柜 · 刀具架 · 香料架 · 展示柜 · 果盘） | §十七 |
| 4 | ⭐ **发酵引子**（酵母罐 / 醋母罐，可传代） | §14.4 |
| 5 | ⭐ **每项新食物注册 `tfc/food_items/*.json`**；**"整体/份"分文件** | §15.3 |
| 6 | ⭐ **酱汁可注册成 `tfc:drinkable`** | §15.2 品类 8 |
| 7 | 🆕 补 **`bottle_fluid`** / **`dynamic_jam`** / **`flour_dough`** 三个配方类型 | §14.6 |
| 8 | 🆕 学 **`neoforge:mod_loaded`** 做"按邻居存在与否条件生效" | §3.5 |
| 9 | 🆕 **抽象标签**（`sweetener` · `frying_oil` · `makes_stock`） | §十五 |
| 10 | 🆕 **油炸**是一道漏了的工序（`frying_oil` 标签 + `pot`） | §十二（补） |
| 11 | ⚠️ **不要学它的运行时动态食物适配器** —— 我们用静态 `FoodTrait` 更简单 | §10.2 A3 |
| 12 | 🛑 **不学装饰/16 色变体/动态几何** | §2.8 |

---

## 十三、📌 本次分析的方法论（**三条可复用**）

| # | 方法 | 为什么 |
|---|---|---|
| **1** | ⭐ **按 BE/Menu/Screen 判定功能方块**，不按名字 | 126 §17 的教训：我用名字把 7 个家具误判为装饰 |
| **2** | ⭐ **看同一个模组的所有 MC 版本** | 1.20.1 比 1.21.1 **多 3 个配方类型**（`bottle_fluid` 等） |
| **3** | ⭐ **看它的兼容/附属模组** | `extradelighttfc`（0.11 MB）**信息密度最高** —— 它专门解决"如何与 TFC 结合" |

🆕 **第四条**（本次新增）：
| **4** | ⭐ **看它的 `tags`**，尤其是 `processed/*` 这类**"加工形态"标签** | 它揭示了**设计者的分类逻辑**（比读代码快） |

---

## 十四、统计口径说明（可复现）

| 结论 | 口径 | 复现方式 |
|---|---|---|
| 13,198 条目 | **内容口径**（排除目录条目） | 读 zip `Entries` 并过滤 `EndsWith('/')` |
| 822 blockstate | `assets/extradelight/blockstates/**` 文件数 | — |
| 1,441 物品 | `assets/extradelight/models/item/**` 文件数 | ⚠️ 与"注册物品数"可能有差（有些物品无模型） |
| 19 种配方类型 | 读 `data/extradelight/recipe/**` 的 `type` 字段 | — |
| 22 个 BE | `*BlockEntity.class`（排除内部类 `$`） | — |
| 14 对 Menu/Screen | `*Menu.class` / `*Screen.class` | — |

⚠️ **已知局限**：
- 物品分类（§四）用的是**名称正则**，**会有误判**（如"工具 253"可能把模具算进去了）
- 方块分类（§三）的**类别会重叠**（小计 847 > 822）
- `lang` 里的键与注册 ID 可能有偏差
